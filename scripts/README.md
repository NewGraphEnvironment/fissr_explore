# fiss_density

Tie locations of FISS density sites to stream segments then report on:

- modelled channel width
- modelled discharge
- precip in watershed
- elevation in watershed
- BEC zones in watershed

Future considerations include perhaps:
- forest cover
- geology
- channel confinement
- Variable Infiltration Capacity (VIC-GL) model inputs

# Requirements

- fwapg (postgres/gdal/etc)
- csvkit
- psql2csv
- rasterstats
- jq
- BC DEM tif on local drive

# Usage

To run the scripts and create output csv files:

    make

# Outputs

## fiss_density_distinct

n=28,308

Temp table of unique locations (not exported). From 45,206 source records.

## fiss_density_events.csv

n=54599

Distinct fiss density points, each joined to all streams (up to 20) within 200m.
Join these distinct locations back to source `fiss_density.csv` using values in `density_ids`.

## fiss_density_pts.geojson

n=18,443

This is fiss_density_events converted to points on the 'best' matching stream.
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