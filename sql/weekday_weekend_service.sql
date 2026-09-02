### Weekday and Weekend Service ###
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
