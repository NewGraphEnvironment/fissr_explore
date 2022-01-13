-- Create geoms of watersheds upstream of pts
-- Write to a new table to keep the geoms on hand, they take several hours to generate
-- Do not generate watersheds for points on order 8 streams or greater

DROP TABLE IF EXISTS temp.fiss_density_watersheds;


CREATE TABLE temp.fiss_density_watersheds
(
  fiss_density_watersheds_id serial primary key,
  fiss_density_distinct_ids integer[],
  geom geometry(MultiPolygon, 3005)
);


INSERT INTO temp.fiss_density_watersheds
(
  fiss_density_distinct_ids,
  geom
)

-- find watershed codes of stream segments with order >=8
-- (We can't just get order from the stream records because side channels can have order less than the main channel.
-- eg, channel on north side of Tree Island under Port Mann bridge is coded as order 5 but entire Fraser is upstream)
WITH order8rivs AS
(
  SELECT DISTINCT ON (wscode_ltree)
      wscode_ltree,
      localcode_ltree,
      gnis_name,
      stream_order,
      watershed_group_code
  FROM whse_basemapping.fwa_stream_networks_sp
  WHERE stream_order >= 8
  AND localcode_ltree IS NOT NULL
  ORDER BY wscode_ltree, localcode_ltree desc
),

pts AS
(
  SELECT
    array_agg(fiss_density_distinct_id) as fiss_density_distinct_ids,
    p.wscode_ltree,
    p.localcode_ltree
  FROM temp.fiss_density_pts p
-- join to wscodes of streams of order > 8
  LEFT OUTER JOIN order8rivs b
  ON p.wscode_ltree = b.wscode_ltree
  AND p.localcode_ltree < b.localcode_ltree
-- do not include segments with watershed code of order > 8
  WHERE b.wscode_ltree IS NULL
  GROUP BY p.wscode_ltree, p.localcode_ltree
)

SELECT
  a.fiss_density_distinct_ids,
  ST_Multi(ST_Union(b.geom))::geometry(MultiPolygon, 3005) as geom
FROM pts a
INNER JOIN whse_basemapping.fwa_watersheds_poly b 
ON FWA_Upstream(a.wscode_ltree, a.localcode_ltree, b.wscode_ltree, b.localcode_ltree)
GROUP BY a.fiss_density_distinct_ids;

CREATE INDEX ON temp.fiss_density_watersheds USING GIST (geom);

ALTER TABLE temp.fiss_density_watersheds ADD COLUMN area_ha double precision;
UPDATE temp.fiss_density_watersheds SET area_ha = ST_Area(geom) / 10000;