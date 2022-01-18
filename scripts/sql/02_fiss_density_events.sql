-- ------------------
-- join distinct locations to streams
-- ------------------
DROP TABLE IF EXISTS temp.fiss_density_events;

CREATE TABLE temp.fiss_density_events AS
WITH candidates AS
 ( SELECT
    pt.fiss_density_distinct_id,
    nn.linear_feature_id,
    nn.wscode_ltree,
    nn.localcode_ltree,
    nn.fwa_watershed_code,
    nn.local_watershed_code,
    nn.blue_line_key,
    nn.length_metre,
    nn.downstream_route_measure,
    nn.upstream_route_measure,
    nn.stream_order,
    nn.distance_to_stream,
    nn.watershed_group_code,
    ST_LineMerge(nn.geom) AS geom
  FROM temp.fiss_density_distinct as pt
  CROSS JOIN LATERAL
  (SELECT
     str.linear_feature_id,
     str.wscode_ltree,
     str.localcode_ltree,
     str.fwa_watershed_code,
     str.local_watershed_code,
     str.blue_line_key,
     str.length_metre,
     str.downstream_route_measure,
     str.upstream_route_measure,
     str.stream_order,
     str.watershed_group_code,
     str.geom,
     ST_Distance(str.geom, pt.geom) as distance_to_stream
    FROM whse_basemapping.fwa_stream_networks_sp AS str
    WHERE str.localcode_ltree IS NOT NULL
    AND NOT str.wscode_ltree <@ '999'
    ORDER BY str.geom <-> pt.geom
    LIMIT 20) as nn
  WHERE nn.distance_to_stream < 200
)

SELECT DISTINCT ON (fiss_density_distinct_id, blue_line_key)
  c.fiss_density_distinct_id,
  c.linear_feature_id,
  c.wscode_ltree,
  c.localcode_ltree,
  c.fwa_watershed_code,
  c.local_watershed_code,
  c.blue_line_key,
  c.stream_order,
  CEIL(
    GREATEST(c.downstream_route_measure,
      FLOOR(
        LEAST(c.upstream_route_measure,
          (ST_LineLocatePoint(c.geom, ST_ClosestPoint(c.geom, pts.geom)) * c.length_metre) + c.downstream_route_measure
  )))) as downstream_route_measure,
  c.distance_to_stream,
  c.watershed_group_code
FROM candidates c
INNER JOIN temp.fiss_density_distinct pts ON c.fiss_density_distinct_id = pts.fiss_density_distinct_id
ORDER BY c.fiss_density_distinct_id, c.blue_line_key, c.distance_to_stream;
