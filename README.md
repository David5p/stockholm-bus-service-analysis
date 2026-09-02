# stockholm-bus-service-analysis
SQL and Tableau analysis of Stockholm bus service frequency by route, time of day, and weekday vs weekend.

## Project Overview

**Project type:** SQL + Tableau portfolio project
**Data:** SL GTFS scheduled timetable data
**Tools:** Google BigQuery, SQL, Tableau
**Focus:** Bus service frequency by route, hour, and weekday/weekend

## Introduction

This project analyses scheduled Stockholm bus service using SL timetable data for the service period from 18 August to 12 December 2026.

The analysis investigates how scheduled bus service varies by route, time of day, and weekday versus weekend.

The project uses SQL in Google BigQuery for data exploration and analysis, with Tableau used to create the final dashboard.

## Business Question

**How does scheduled Stockholm bus service frequency vary by route, time of day, and weekday versus weekend?**

## Key Insights
- Route 160 had the highest average scheduled service at approximately 272 departures per operating day.
- Scheduled service varied substantially by time of day, with higher levels during peak periods.
- Weekday service was generally stronger than weekend service, particularly during commuter hours.
- Some routes had significantly different operating patterns between weekdays and weekends, including routes that did not operate on weekends

## Objectives

The analysis aims to:

- Identify which Stockholm bus routes provide the highest level of scheduled service.
- Examine how scheduled bus departures vary throughout the day.
- Compare scheduled bus service between weekdays and weekends.
- Investigate how operating days and service patterns differ between individual routes.


## Data

This project uses SL GTFS timetable data for Stockholm public transport, covering the service period from 18 August to 12 December 2026.

The dataset contains additional GTFS tables, including `agency`, `attributions`, `booking_rules`, `feed_info`, `shapes` and `transfers`. These were explored as part of understanding the dataset but were not required for the analysis.

The analysis focuses on bus services and uses the following GTFS tables:

- `routes` — contains route information such as route number, route name and transport type.
- `trips` — contains scheduled trip patterns and their associated service IDs.
- `stop_times` — contains scheduled arrival and departure times for each stop on a trip.
- `stops` — contains information about stops, including stop names.
- `calendar_dates` — contains the dates on which each service ID operates.


## Data Selection

The data was selected because it provides scheduled timetable information that can be used to investigate bus service levels across routes, times of day and different days of the week.

I first explored the available public transport data to understand the different transport modes and table relationships. Bus services were then identified using the GTFS `route_type` value for bus services (`700`).

## Tools

- **Google BigQuery** — used for SQL data exploration, transformation and analysis.
- **SQL** — used to join tables, calculate scheduled service measures and investigate weekday/weekend patterns.
- **Tableau** — used to create the final dashboard and visualize scheduled bus service frequency.
- **GitHub** — used to document and present the project.

## Data Preparation & Methodology

The analysis involved several steps to prepare the GTFS timetable data for analysis.

### Identifying bus services

The `routes` table was used to identify bus services using `route_type = 700` as the data contains all transport. Route IDs were then linked to the `trips` table to identify the scheduled trips associated with each bus route.

### Expanding scheduled trips across service dates

GTFS trips are associated with a `service_id` rather than an individual date. The `calendar_dates` table was joined to `trips` using `service_id` to identify the dates on which each scheduled trip operates.

This means that trip counts after this join represent **scheduled trip occurrences**, rather than unique trip definitions.

### Measuring scheduled departures

The first stop of each trip (`stop_sequence = 1`) was used to identify the scheduled departure time for each trip. This provides a consistent starting point for comparing when scheduled trips begin across routes and dates.

### Weekday and weekend classification

The weekday/weekend classification was derived from the actual service date in `calendar_dates`.

Dates were classified as:

- **Weekday** — Monday to Friday
- **Weekend** — Saturday and Sunday

The Monday–Sunday fields in the `calendar` table were checked but did not contain active service records in this dataset. I therefore used `calendar_dates`, which provides the actual dates associated with each service ID, and classified these dates as weekdays or weekends.

### Handling timetable times

Scheduled departure times were stored as text. The hour component was extracted and converted to a numeric value so departures could be grouped into hourly time periods.

GTFS allows times to extend beyond 24:00:00. For example, `27:52:00` represents 03:52 on the following calendar day, while still being associated with the service day that began the previous day. This convention is useful for representing overnight public transport services.

These extended times were retained in the analysis so that overnight services remained associated with their original GTFS service day.

### Measuring service frequency

Service frequency was measured using the average number of scheduled departures per operating day. This approach was chosen because the main objective was to compare how the level of scheduled bus service varies by route, hour and weekday versus weekend.

For the hourly analysis, an implied headway was calculated by dividing 60 minutes by the average number of scheduled departures within each hour. This provides a simple, consistent measure for comparing hourly service levels across routes and day types.

This is an implied average rather than the actual interval between consecutive buses. Calculating actual scheduled intervals would require comparing each individual departure time with the next departure. This was outside the scope of this analysis, which focuses on overall scheduled service levels by hour.

## SQL Analysis

SQL was used in Google BigQuery to explore the dataset, prepare the data and calculate the measures used in the analysis.

### 1. Identifying bus services

Bus routes were identified using the GTFS `route_type` value of `700`.
This was the first step in narrowing the dataset to the bus services relevant to the business question.

[View SQL query](sql/identify_bus_routes.sql)


### 2. Calculating scheduled service by route

The `routes`, `trips` and `calendar_dates` tables were joined to calculate the total number of scheduled trip occurrences, operating days and average scheduled trips per operating day for each bus route.
This addresses the first part of the business question by identifying which routes provide the highest overall level of scheduled service.

```sql
SELECT 
  r.route_short_name,
  COUNT(*) AS trip_count,
  COUNT(DISTINCT(serviceid1.date)) AS operating_days,
  SAFE_DIVIDE(
    COUNT(*),
    COUNT(DISTINCT serviceid1.date)
  ) AS avg_trips_per_day
FROM `sltraffik.stockholm_transport.calendar_dates` AS serviceid1
JOIN `sltraffik.stockholm_transport.trips` AS serviceid2
  ON serviceid1.service_id = serviceid2.service_id
JOIN `sltraffik.stockholm_transport.routes` AS r
  ON serviceid2.route_id = r.route_id
WHERE r.route_type = 700
GROUP BY r.route_short_name
ORDER BY avg_trips_per_day DESC;
```

### 3. Calculating hourly scheduled service

The first stop of each trip (stop_sequence = 1) was used to identify the scheduled departure time. The departure hour was then extracted so scheduled service could be compared across different times of day.
This addresses the time-of-day part of the business question by showing how scheduled service varies throughout the day for each route.

```sql
SELECT 
  r.route_short_name,
  CAST(SUBSTR(st.departure_time, 1, 2) AS INT64) AS hour_extracted,
  COUNT(*) AS departures,
  COUNT(DISTINCT cd.date) AS operating_days,
  SAFE_DIVIDE(
    COUNT(*),
    COUNT(DISTINCT cd.date)
  ) AS avg_departures_per_day
FROM `sltraffik.stockholm_transport.routes` AS r
JOIN `sltraffik.stockholm_transport.trips` AS t
  ON r.route_id = t.route_id
JOIN `sltraffik.stockholm_transport.stop_times` AS st
  ON st.trip_id = t.trip_id
JOIN `sltraffik.stockholm_transport.calendar_dates` AS cd
  ON cd.service_id = t.service_id
WHERE r.route_type = 700
  AND st.stop_sequence = 1
GROUP BY r.route_short_name, hour_extracted
ORDER BY r.route_short_name, hour_extracted;
```

### 4. Comparing weekday and weekend service

The service date was classified as either a weekday or weekend. This allowed scheduled departures to be compared by hour and day type.
This directly addresses the weekday versus weekend part of the business question and shows whether scheduled service levels change depending on the day type.

```sql
SELECT
  CAST(SUBSTR(st.departure_time, 1, 2) AS INT64) AS scheduled_departure_hour,

  CASE
    WHEN EXTRACT(DAYOFWEEK FROM PARSE_DATE('%Y%m%d', cd.date)) = 1
      OR EXTRACT(DAYOFWEEK FROM PARSE_DATE('%Y%m%d', cd.date)) = 7
      THEN 'Weekend'
    ELSE 'Weekday'
  END AS day_type,

  COUNT(*) AS departures,

  COUNT(DISTINCT cd.date) AS operating_days,

  SAFE_DIVIDE(
    COUNT(*),
    COUNT(DISTINCT cd.date)
  ) AS avg_departures_per_day,

  SAFE_DIVIDE(
    60,
    COUNT(*) / COUNT(DISTINCT cd.date)
  ) AS implied_headway_minutes

FROM `sltraffik.stockholm_transport.routes` AS r

JOIN `sltraffik.stockholm_transport.trips` AS t
  ON r.route_id = t.route_id

JOIN `sltraffik.stockholm_transport.stop_times` AS st
  ON st.trip_id = t.trip_id

JOIN `sltraffik.stockholm_transport.calendar_dates` AS cd
  ON cd.service_id = t.service_id

WHERE r.route_type = 700
  AND st.stop_sequence = 1

GROUP BY 
  scheduled_departure_hour,
  day_type

ORDER BY 
  scheduled_departure_hour,
  day_type,
  implied_headway_minutes;
```

 ## Tableau Dashboard

The Tableau dashboard provides two complementary views of scheduled bus service.

The bar chart ranks the top 15 routes by average scheduled trips per operating day, showing which routes have the highest overall scheduled service.

The heatmap shows how scheduled departures are distributed across hours of the day, with weekday and weekend patterns shown separately.

Together, the visualizations show how scheduled bus service varies by route, time of day and day type.

![Stockholm Bus Service Dashboard](StockholmBusServiceFrequency.png)

## Key Findings

### 1. Highest overall service

Route 160 had the highest average number of scheduled trips per operating day, at approximately 272 trips per day during the timetable period.

### 2. Service varies by hour

Scheduled bus departures varied considerably throughout the day. High-frequency routes did not maintain the same level of service during every hour, with differences between peak and off-peak periods.

### 3. Weekday service is stronger

Scheduled bus service was substantially higher on weekdays than weekends, particularly during morning and afternoon periods.
This may reflect higher expected travel demand during typical weekday commuter periods, when more people travel to and from work or education.

### 4. Routes can have different service patterns

Bus routes did not necessarily operate with the same pattern throughout the week. For example, Route 827 operated on weekdays but not weekends, while UL805 showed differences in operating hours and scheduled frequency between weekdays and weekends.






