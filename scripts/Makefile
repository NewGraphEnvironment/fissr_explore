.PHONY: all clean

INPUT_FILE=../data/fiss_density.csv
GENERATED_FILES = fiss_density.csv fiss_density_distinct.csv fiss_density_events.csv fiss_density_pts.geojson fiss_density_watersheds.geojson #elev.csv bec.csv
PSQL_CMD=psql $(DATABASE_URL) -v ON_ERROR_STOP=1

# Make all targets
all: $(GENERATED_FILES)

fiss_density.csv: $(INPUT_FILE)
	$(PSQL_CMD) -c "DROP TABLE IF EXISTS temp.fiss_density"
	csvsql --db $(DATABASE_URL) --table fiss_density --insert $< --db-schema temp
	$(PSQL_CMD) -c "ALTER TABLE temp.fiss_density ADD COLUMN IF NOT EXISTS fiss_density_id SERIAL PRIMARY KEY;"
	psql2csv "SELECT * FROM temp.fiss_density" > $@

fiss_density_distinct.csv: fiss_density.csv
	$(PSQL_CMD) -f sql/01_fiss_density_distinct.sql
	psql2csv "SELECT * FROM temp.fiss_density_distinct" > $@

fiss_density_events.csv: fiss_density_distinct.csv
	$(PSQL_CMD) -f sql/02_fiss_density_events.sql
	psql2csv "SELECT * FROM temp.fiss_density_events" > $@

fiss_density_pts.geojson: fiss_density_events.csv
	$(PSQL_CMD) -f sql/03_fiss_density_pts.sql
	ogr2ogr -f GeoJSON $@ -a_srs EPSG:3005 \
	"PG:$(DATABASE_URL?application_name=foo)" \
	-sql "SELECT * FROM temp.fiss_density_pts"

fiss_density_watersheds.geojson: fiss_density_pts.geojson
	$(PSQL_CMD) -f sql/04_fiss_density_watersheds.sql
	ogr2ogr -f GeoJSON $@ -a_srs EPSG:3005 \
	"PG:$(DATABASE_URL?application_name=foo)" \
	-sql "SELECT \
        fiss_density_watersheds_id, \
        fiss_density_distinct_ids, \
        ST_Multi(ST_SimplifyPreserveTopology(geom, 20))::geometry(MultiPolygon, 3005) as geom \
      FROM \
      temp.fiss_density_watersheds"

# precipitation
# map.csv: fiss_density_watersheds.geojson
# 	wget --trust-server-names -qNP data http://raster.climatebc.ca/download/Normal_1981_2010MSY/Normal_1981_2010_annual.zip
# 	unzip -qun data/Normal_1981_2010_annual.zip -d data/climatebc
# 	# resample/warp the precip data to match DEM raster resolution (don't bother aligning for now)
# 	gdalwarp data/climatebc/map data/mean_annual_precip.tif -overwrite -t_srs EPSG:3005 -of COG -co COMPRESS=DEFLATE -tr 25 25
# 	fio cat $< | parallel \
#       --pipe \
#       "rio -q zonalstats \
#         -r mean_annual_precip.tif \
#         --prefix 'map_' \
#         2>/dev/null" | \
#     jq '.features[].properties | [.fiss_density_watersheds_id, .map_min, .map_max, .map_mean]' | \
#     jq -r --slurp '.[] | @csv' > $@

# elevation
elev.csv: fiss_density_watersheds.geojson
	fio cat $< | parallel \
	  --pipe \
	  "rio -q zonalstats \
	    -r ~/data/bc/raster/dem/bc_dem.tif \
	    --prefix 'elev_' \
	    2>/dev/null" | \
	jq '.features[].properties | [.fiss_density_watersheds_id, .elev_min, .elev_max, .elev_mean]' | \
	jq -r --slurp '.[] | @csv' > $@
	#gsed  -i 'fiss_density_watersheds_id,elev_min,elev_max,elev_mean' $@

# bec zones
bec.csv: fiss_density_watersheds.geojson
	$(PSQL_CMD) -f sql/04_fiss_density_watersheds_bec.sql
	psql2csv "SELECT * FROM temp.fiss_density_watersheds_bec" > $@

clean:
	rm -Rf $(GENERATED_FILES)