### Service by Route ###
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
