-- ------------------
-- add a unique key to source table
-- ------------------
ALTER TABLE temp.fiss_density
ADD COLUMN IF NOT EXISTS fiss_density_id SERIAL PRIMARY KEY;

-- ------------------
-- extract distinct locations within BC
-- ------------------
DROP TABLE IF EXISTS temp.fiss_density_distinct;

CREATE TABLE temp.fiss_density_distinct
(
  fiss_density_distinct_id serial primary key,
  density_ids integer[],
  watershed_group_code text,
  geom geometry(Point, 3005)
);


INSERT INTO temp.fiss_density_distinct
(
  density_ids,
  watershed_group_code,
  geom
)

-- aggregate based on unique coordinates.
-- we could aggregate based on a spatial cluster but that doesn't seem necessary
WITH aggregated AS
(
  SELECT
    array_agg(fiss_density_id) as density_ids,
    ST_Transform(ST_SetSRID(ST_MakePoint(utm_easting, utm_northing), 32600 + utm_zone::integer), 3005) as geom
  FROM temp.fiss_density
  GROUP BY utm_zone, utm_easting, utm_northing
)

-- join to watershed groups, thus dumping points that are not actually in BC
SELECT
  a.density_ids,
  b.watershed_group_code,
  a.geom
FROM aggregated a
INNER JOIN whse_basemapping.fwa_watershed_groups_subdivided b
ON ST_Intersects(a.geom, b.geom);

-- index the geoms
CREATE INDEX ON temp.fiss_density_distinct USING gist (geom);


-- ------------------
-- join to streams
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
