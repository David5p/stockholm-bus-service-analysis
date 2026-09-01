# stockholm-bus-service-analysis
SQL and Tableau analysis of Stockholm bus service frequency by route, time of day, and weekday vs weekend.

## Introduction

This project analyses scheduled Stockholm bus service using SL timetable data for the service period from 18 August to 12 December 2026.

The analysis investigates how scheduled bus service varies by route, time of day, and weekday versus weekend.

The project uses SQL in Google BigQuery for data exploration and analysis, with Tableau used to create the final dashboard.

## Business Question

**How does scheduled Stockholm bus service frequency vary by route, time of day, and weekday versus weekend?**

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

The Monday–Sunday fields in the `calendar` table were checked but did not contain active service records in this dataset. I therefore used calendar_dates, which provides the actual dates associated with each service ID, and classified these dates as weekdays or weekends.

### Handling timetable times

Scheduled departure times were stored as text. The hour component was extracted and converted to a numeric value so departures could be grouped into hourly time periods.

GTFS allows times to extend beyond 24:00:00. For example, `27:52:00` represents 03:52 on the following calendar day, while still being associated with the service day that began the previous day. This convention is useful for representing overnight public transport services.

These extended times were retained in the analysis so that overnight services remained associated with their original GTFS service day.

### Measuring service frequency

Service frequency was measured using the average number of scheduled departures per operating day. This approach was chosen because the main objective was to compare how the level of scheduled bus service varies by route, hour and weekday versus weekend.

For the hourly analysis, an implied headway was calculated by dividing 60 minutes by the average number of scheduled departures within each hour. This provides a simple, consistent measure for comparing hourly service levels across routes and day types.

This is an implied average rather than the actual interval between consecutive buses. Calculating actual scheduled intervals would require comparing each individual departure time with the next departure. This was outside the scope of this analysis, which focuses on overall scheduled service levels by hour.





