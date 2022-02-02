drop table if exists temp.fiss_density_barriers;
create table temp.fiss_density_barriers as

with all_pscis as
(
  select
    p.*,
    a.final_score as pscis_final_score
  from bcfishpass.pscis p
  inner join whse_fish.pscis_assessment_svw a
  on p.stream_crossing_id = a.stream_crossing_id
),

major_dams as (
  select
    pts.fiss_density_distinct_id,
    array_agg(d.barriers_majordams_id) filter (where d.barriers_majordams_id is not null) as barriers_majordams_dnstr
  from temp.fiss_density_pts pts
  inner join bcfishpass.barriers_majordams d
  on fwa_downstream(
      pts.blue_line_key,
      pts.downstream_route_measure,
      pts.wscode_ltree,
      pts.localcode_ltree,
      d.blue_line_key,
      d.downstream_route_measure,
      d.wscode_ltree,
      d.localcode_ltree,
      false,
      1
  )
group by pts.fiss_density_distinct_id
),

falls as
(
  select
    pts.fiss_density_distinct_id,
    array_agg(f.barriers_falls_id) filter (where f.barriers_falls_id is not null) as barriers_falls_dnstr
  from temp.fiss_density_pts pts
    inner join bcfishpass.barriers_falls f
on fwa_downstream(
    pts.blue_line_key,
    pts.downstream_route_measure,
    pts.wscode_ltree,
    pts.localcode_ltree,
    f.blue_line_key,
    f.downstream_route_measure,
    f.wscode_ltree,
    f.localcode_ltree,
    false,
    1
) and pts.watershed_group_code = f.watershed_group_code
group by pts.fiss_density_distinct_id
),

subsurface as

(

 select
    pts.fiss_density_distinct_id,
    array_agg(s.barriers_subsurfaceflow_id) filter (where s.barriers_subsurfaceflow_id is not null) as barriers_subsurfaceflow_dnstr
  from temp.fiss_density_pts pts
inner join bcfishpass.barriers_subsurfaceflow s
on fwa_downstream(
    pts.blue_line_key,
    pts.downstream_route_measure,
    pts.wscode_ltree,
    pts.localcode_ltree,
    s.blue_line_key,
    s.downstream_route_measure,
    s.wscode_ltree,
    s.localcode_ltree,
    false,
    1
) and pts.watershed_group_code = s.watershed_group_code
group by pts.fiss_density_distinct_id
),

gradient as

(
 select
    pts.fiss_density_distinct_id,
    array_agg(g.gradient_class) filter (where g.gradient_class is not null) as barriers_gradient_dnstr
  from temp.fiss_density_pts pts
inner join bcfishpass.gradient_barriers g
on fwa_downstream(
    pts.blue_line_key,
    pts.downstream_route_measure,
    pts.wscode_ltree,
    pts.localcode_ltree,
    g.blue_line_key,
    g.downstream_route_measure,
    g.wscode_ltree,
    g.localcode_ltree,
    false,
    1
) and pts.watershed_group_code = g.watershed_group_code
group by pts.fiss_density_distinct_id
),

anthropogenic as
(
 select
    pts.fiss_density_distinct_id,
    array_agg(a.barriers_anthropogenic_id) filter (where a.barriers_anthropogenic_id is not null) as barriers_anthropogenic_dnstr
  from temp.fiss_density_pts pts
inner join bcfishpass.barriers_anthropogenic a
on fwa_downstream(
    pts.blue_line_key,
    pts.downstream_route_measure,
    pts.wscode_ltree,
    pts.localcode_ltree,
    a.blue_line_key,
    a.downstream_route_measure,
    a.wscode_ltree,
    a.localcode_ltree,
    false,
    1
) and pts.watershed_group_code = a.watershed_group_code
group by pts.fiss_density_distinct_id
),


barriers_pscis as

(
select
    pts.fiss_density_distinct_id,
    array_agg(pb.barriers_pscis_id) filter (where pb.barriers_pscis_id is not null) as barriers_pscis_dnstr
  from temp.fiss_density_pts pts
  inner join bcfishpass.barriers_pscis pb
on fwa_downstream(
    pts.blue_line_key,
    pts.downstream_route_measure,
    pts.wscode_ltree,
    pts.localcode_ltree,
    pb.blue_line_key,
    pb.downstream_route_measure,
    pb.wscode_ltree,
    pb.localcode_ltree,
    false,
    1
) and pts.watershed_group_code = pb.watershed_group_code
group by pts.fiss_density_distinct_id
),

all_pscis_dnstr as

(
select
    pts.fiss_density_distinct_id,
    array_agg(pa.stream_crossing_id) filter (where pa.stream_crossing_id is not null) as all_pscis_dnstr,
    array_agg(pa.pscis_final_score) as all_pscis_scores_dnstr
  from temp.fiss_density_pts pts
inner join all_pscis pa
on fwa_downstream(
    pts.blue_line_key,
    pts.downstream_route_measure,
    pts.wscode_ltree,
    pts.localcode_ltree,
    pa.blue_line_key,
    pa.downstream_route_measure,
    pa.wscode_ltree,
    pa.localcode_ltree,
    false,
    1
) and pts.watershed_group_code = pa.watershed_group_code
group by pts.fiss_density_distinct_id
)

select distinct
  pts.fiss_density_distinct_id,
  major_dams.barriers_majordams_dnstr,
  falls.barriers_falls_dnstr,
  subsurface.barriers_subsurfaceflow_dnstr,
  gradient.barriers_gradient_dnstr,
  anthropogenic.barriers_anthropogenic_dnstr,
  barriers_pscis.barriers_pscis_dnstr,
  all_pscis_dnstr.all_pscis_dnstr,
  all_pscis_dnstr.all_pscis_scores_dnstr
from temp.fiss_density_pts pts
left outer join major_dams on pts.fiss_density_distinct_id = major_dams.fiss_density_distinct_id
left outer join falls on pts.fiss_density_distinct_id = falls.fiss_density_distinct_id
left outer join subsurface on pts.fiss_density_distinct_id = subsurface.fiss_density_distinct_id
left outer join gradient on pts.fiss_density_distinct_id = gradient.fiss_density_distinct_id
left outer join anthropogenic on pts.fiss_density_distinct_id = anthropogenic.fiss_density_distinct_id
left outer join barriers_pscis on pts.fiss_density_distinct_id = barriers_pscis.fiss_density_distinct_id
left outer join all_pscis_dnstr on pts.fiss_density_distinct_id = all_pscis_dnstr.fiss_density_distinct_id;

alter table temp.fiss_density_barriers add primary key (fiss_density_distinct_id);