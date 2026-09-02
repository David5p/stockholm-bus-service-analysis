### Hourly Service ###
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
