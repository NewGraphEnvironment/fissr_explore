-- bec overlay
drop table if exists temp.fiss_density_watersheds_bec;

create table temp.fiss_density_watersheds_bec as

select
  b.fiss_density_watersheds_id,
  a.zone,
  a.subzone,
  a.variant,
  a.phase,
  a.natural_disturbance,
  a.map_label,
  a.bgc_label,
  coalesce((sum(ST_Area(a.geom)) FILTER (WHERE ST_CoveredBy(a.geom, b.geom)) / 10000), 0) +
  coalesce((sum(ST_Area(ST_Intersection(a.geom, b.geom))) FILTER (WHERE NOT ST_CoveredBy(a.geom, b.geom)) / 10000), 0) as area_ha
from whse_forest_vegetation.bec_biogeoclimatic_poly as a
inner join temp.fiss_density_watersheds as b
on (ST_Intersects(a.geom, b.geom) and not ST_Touches(a.geom, b.geom))
group by
  b.fiss_density_watersheds_id,
  a.zone,
  a.subzone,
  a.variant,
  a.phase,
  a.natural_disturbance,
  a.map_label,
  a.bgc_label;
