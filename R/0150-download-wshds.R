##download the geojson, read in and burn to csv without the geom info


url <- 'https://www.hillcrestgeo.ca/outgoing/public/fiss_density_watersheds.geojson'
destfile <- 'data/fiss_density_watersheds.geojson'
download.file(url, destfile, quiet = FALSE, mode = "wb")

wshds <- sf::read_sf('https://www.hillcrestgeo.ca/outgoing/public/fiss_density_watersheds.geojson')

wshds_df <- wshds %>%
  sf::st_drop_geometry() %>%
  unnest(fiss_density_distinct_ids)


##burn the df as a csv to make easy connections later on.
wshds_df %>%
  readr::write_csv(file = 'data/fiss_density_wshds_keys.csv')



