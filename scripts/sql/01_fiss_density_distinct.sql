-- ------------------
-- extract distinct locations within BC
-- ------------------
DROP TABLE IF EXISTS temp.fiss_density_distinct;

CREATE TABLE temp.fiss_density_distinct
(
  fiss_density_distinct_id serial primary key,
  fiss_density_ids integer[],
  watershed_group_code text,
  geom geometry(Point, 3005)
);


INSERT INTO temp.fiss_density_distinct
(
  fiss_density_ids,
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