### Identify Bus routes ###
SELECT 
  route_type,
  route_short_name, 
  route_long_name
FROM `sltraffik.stockholm_transport.routes`
WHERE route_type = 700
ORDER BY route_short_name;
