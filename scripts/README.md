# scripts

sql/shell scripts to:

1. Reference input FISS density sites to FWA streams

2. At the site locations, report on:

    - stream order
    - gradient
    - modelled channel width
    - modelled discharge
    - precip in watershed
    - barriers/potential barriers downstream
    - elevation in watershed
    - BEC zones in watershed


Future considerations:

- forest cover
- geology
- channel confinement
- Variable Infiltration Capacity (VIC-GL) model inputs
- other


# Requirements

- fwapg
- bcfishpass
- csvsql
- psql2csv
- rasterstats
- jq
- BC DEM tif on local drive


# Usage

Presuming all requirements are available, run the scripts and create output csv files with `make`:

    $ make


# Outputs

## fiss_density_distinct

n=28,308

Aggregation of the 45,206 input points into unique locations.
Use this to relates source `fiss_density_id` values to `fiss_denstity_distinct_id` values in below tables.


## fiss_density_pts.csv

n=18,443

Matching of input points to the 'best' matching FWA stream.
'best' is difficult to determine - 'closest' is generally error prone and there is no good data included for QA of matching (eg stream name).
We could retain only records where we are more confident about the matching - just one stream within 100m or so of the point.
But this is a bit conservative - instead:

- find all points where there is a stream within 50m
- from those points, find points that have another stream matched within 100m
- keep only points that have:
    + no other stream within 100m
    + are within 10m of first stream matched and 2nd stream matched is more than 60m away
    + the 2nd stream matched is more than 80m away (ie match 1 within 10-20m and match 2 90-100m away)
This is crude but helps retain some more records for analysis (17308 vs 14898 where only 1 match within 100m).


## barriers.csv

List of barrier features downstream of distinct density points.

| column   | description |
| ---------| ------------|
| barriers_majordams_dnstr | ID(s) of major (hydro) dam downstream                     |
| barriers_falls_dnstr     | ID(s) of FISS falls >= 5m or FWA falls downstream         |
| barriers_subsurface_dnstr | ID(s) of FWA subsurface flow segments downstream |
| barriers_gradient_dnstr   | ID(s) of gradient barriers of given percent slope downstream (5/7/10/15/20/25/30) |
| barriers_anthropogenic_dnstr | aggregated_crossings_id(s) of all known/modelled anthropogenic barriers or potential barriers downstream |
| barriers_pscis_dnstr       | stream_crossing_id(s) of all assessed barriers downstream |
| all_pscis_dnstr        | stream_crossing_id(s) of all pscis records downstream
| all_pscis_scores_dnstr | pscis barrier scores of all pscis assessments downstream (NULL for open bottom strucures)

NOTE: only barriers within the same watershed group as the source point are reported on, with the exception of `majordams_dnstr`

## fiss_density_watersheds.geojson

n=13,795

Watersheds upstream of fiss_density_pts.geojson, based on `FWA_WatershedAtMeasure()`.
- only one watershed is generated per unique watershed code in the source points (join back to `fiss_density_pts.geojson` using values in
  `fiss_density_distinct_ids`)
- watersheds are not generated for points on 8th order streams and greater

Key attributes included:

- distance_to_stream
- stream_order
- stream_magnitude
- map (mean annual precip at the point location)
- map_upstream (area weighted upstream mean annual precipitation)
- mad_m3s (mean annual discharge)

Note that map_upstream and mad_m3s are modelled data that has not been extensively QA'ed. Also, these values will be incorrect for streams with contributing areas outside of BC.

## elev.csv

Basic elevation stats for the watershed - min/max/mean elevation.

## bec.csv

Area (hectares) of each BEC zone found in the watersheds.