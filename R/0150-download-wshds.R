##download the geojson, read in and burn to csv
url <- 'https://www.hillcrestgeo.ca/outgoing/public/fiss_density_watersheds.geojson'
destfile <- 'data/fiss_density_watersheds.geojson'
download.file(url, destfile, quiet = FALSE, mode = "wb")

wshds <- sf::read_sf('https://www.hillcrestgeo.ca/outgoing/public/fiss_density_watersheds.geojson')
