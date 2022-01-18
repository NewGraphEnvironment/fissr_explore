-- Output event table includes all potential matches within 200m.
-- How do we filter these to find the best match?
-- This is tricky because while choosing the closest match with a relatively tight
-- tolerance (10-50m) does narrow down the results and removes poor matches, it does
-- not eliminate the common source of error where a gps point is taken on a large 
-- stream at a small trib, and the gps point ends up being much closer to the 
-- mapped location of the small trib. 

-- In absence of good additional data to relate the points to given streams 
-- (eg, stream name, watershed code), we can simply drop records where there
-- is some uncertainty. 
-- So, 
--   - find all points where there is a stream within 50m
--   - from those points, find points that have another stream matched within 100m
--   - keep only points that have:
--         + no other stream within 100m
--         + are within 10m of first stream matched and 2nd stream matched is more than 60m away
--         + the 2nd stream matched is more than 80m away (ie match 1 within 10-20m and match 2 90-100m away)
-- This is crude but helps retain some more records for analysis (17308 vs 14898 where only 1 match within 100m).

-- TODO - compare stream order and channel width for points where matching is uncertain

DROP TABLE IF EXISTS temp.fiss_density_pts;

CREATE TABLE temp.fiss_density_pts AS

WITH closest_within_50m AS 
(
  SELECT DISTINCT ON (fiss_density_distinct_id)
    fiss_density_distinct_id,
    linear_feature_id,
    blue_line_key,
    downstream_route_measure,
    distance_to_stream,
    watershed_group_code,
    stream_order
  FROM temp.fiss_density_events
  WHERE distance_to_stream <= 50
  ORDER BY fiss_density_distinct_id, distance_to_stream asc
),

-- relate above to the next closest matches under 100m
closest_within_50_and_100 AS
(
  SELECT DISTINCT ON (a.fiss_density_distinct_id)
    a.fiss_density_distinct_id,
    a.linear_feature_id,
    a.blue_line_key,
    a.downstream_route_measure,
    a.stream_order,
    a.distance_to_stream,
    a.watershed_group_code,
    b.fiss_density_distinct_id as other_id,
    b.distance_to_stream as other_dist
  FROM closest_within_50m a
  LEFT OUTER JOIN temp.fiss_density_events b 
  ON a.fiss_density_distinct_id = b.fiss_density_distinct_id
  AND a.distance_to_stream < b.distance_to_stream
  AND b.distance_to_stream < 100
  ORDER BY a.fiss_density_distinct_id, b.distance_to_stream asc
),
-- Recs in above with no other_id value are automatically kept - there is only 
-- one stream within 100m and it is closer than 50m
-- Where there IS another crossing within 100m, we'll retain records where
-- closest stream is < 10m away from point and 2nd closest is >60m, OR
-- if the distance of 2nd match is more than 80m from dist of first match
-- This will still be error prone if a gps point is taken near a small trib... but
-- should be fairly robust otherwise and retains 17k rows, about 60% of the data.
records_to_retain AS
(
  SELECT
    a.fiss_density_distinct_id,
    a.linear_feature_id,
    a.blue_line_key,
    a.downstream_route_measure,
    a.stream_order,
    a.distance_to_stream,
    a.watershed_group_code,
    b.fiss_density_ids
  FROM closest_within_50_and_100 a
  INNER JOIN temp.fiss_density_distinct b
  ON a.fiss_density_distinct_id = b.fiss_density_distinct_id
  WHERE other_id IS NULL
  OR (distance_to_stream < 10 and other_dist >= 60)
  OR ABS(other_dist - distance_to_stream) >= 80
),

-- join back to source table, add basic stream info, create geoms
pts as
(
  SELECT DISTINCT ON (a.fiss_density_distinct_id)
    a.fiss_density_distinct_id,
    a.fiss_density_ids,
    a.linear_feature_id,
    a.blue_line_key,
    a.downstream_route_measure,
    s.wscode_ltree,
    s.localcode_ltree,
    a.watershed_group_code,
    a.distance_to_stream,
    postgisftw.FWA_LocateAlong(a.blue_line_key, a.downstream_route_measure)::geometry(PointZM, 3005) as geom
  FROM records_to_retain a
  INNER JOIN whse_basemapping.fwa_stream_networks_sp s
  ON a.linear_feature_id = s.linear_feature_id
  ORDER BY a.fiss_density_distinct_id
),


-- find order of parent stream
parent_order AS
(
  SELECT DISTINCT ON (a.fiss_density_distinct_id)
    a.fiss_density_distinct_id,
    p.stream_order as stream_order_parent
  from pts a
  left outer join whse_basemapping.fwa_stream_networks_sp p
  on a.wscode_ltree = p.localcode_ltree
  where p.blue_line_key = p.watershed_key
  order by a.fiss_density_distinct_id, p.downstream_route_measure desc
)

SELECT
  a.fiss_density_distinct_id,
  a.fiss_density_ids,
  a.linear_feature_id,
  a.blue_line_key,
  a.downstream_route_measure,
  s.wscode_ltree,
  s.localcode_ltree,
  a.watershed_group_code,
  a.distance_to_stream,
  s.stream_order,
  b.stream_order_parent,
  s.stream_magnitude,
  s.gradient,
  p.map,
  p.map_upstream,
  ua.upstream_area_ha,
  cw.channel_width,
  cw.channel_width_source,
  d.mad_m3s,
  a.geom
FROM pts a
LEFT OUTER JOIN bcfishpass.discharge_pcic d
ON a.linear_feature_id = d.linear_feature_id
INNER JOIN whse_basemapping.fwa_stream_networks_sp s
ON a.linear_feature_id = s.linear_feature_id
LEFT OUTER JOIN bcfishpass.mean_annual_precip p
ON s.wscode_ltree = p.wscode_ltree
AND s.localcode_ltree = p.localcode_ltree
LEFT OUTER JOIN parent_order b
ON a.fiss_density_distinct_id = b.fiss_density_distinct_id
LEFT OUTER JOIN bcfishpass.channel_width cw
ON a.linear_feature_id = cw.linear_feature_id
LEFT OUTER JOIN whse_basemapping.fwa_streams_watersheds_lut l
ON s.linear_feature_id = l.linear_feature_id
INNER JOIN whse_basemapping.fwa_watersheds_upstream_area ua
ON l.watershed_feature_id = ua.watershed_feature_id;