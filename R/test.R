density_pts <- sf::read_sf('data/fiss_density_pts.geojson') %>%
  unnest(fiss_density_ids)


density <- readr::read_csv('data/fiss_density.csv')


##there are full on duplicates of everything in that file but then the number of distinct rows is not the same as the number of fiss_density_ids
density_pts %>%
  distinct(fiss_density_ids) %>%
  dim()


##we want to confirm that the duplicate sites (diff species at same site) were run through sql scripts and that we do not need to rejoin outputs somehow
density_dups <- density %>%
  group_by(key) %>%
  mutate(dup = row_number() > 1) %>%
  ungroup() %>%
  filter(dup == T)
  # distinct(key, .keep_all = T)

##hmm - looks like multiple species were run through the sql


##explore distinct events for each of the columns of fiss_density_pts.geojson

names_density_pts <- names(density_pts)

##build function to test
test_dim <- function(test_var){
  density_pts %>%
    distinct(!! sym(test_var)) %>%
    dim()
}


##make a dataframe with results for all columns
test <- names_density_pts %>%
  map(test_dim) %>%
  purrr::set_names(nm = names_density_pts) %>%
  bind_rows()


