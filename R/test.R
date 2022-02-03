density_pts <- sf::read_sf('data/fiss_density_pts.geojson') %>%
  unnest(fiss_density_ids)

density_pts %>%
  distinct(fiss_density_ids) %>%
  dim()



density <- readr::read_csv('data/fiss_density.csv')


##we want to confirm that the duplicate sites (diff species at same site) were run through sql scripts and that we do not need to rejoin outputs somehow
density_dups <- density %>%
  group_by(key) %>%
  mutate(dup = row_number() > 1) %>%
  ungroup() %>%
  filter(dup == T)
  # distinct(key, .keep_all = T)

##grab some examples of dups to view
dups_ex <- density_dups %>%
  head()

##556 and 557 are example
test <- density_pts %>% select(fiss_density_ids)

names_density_pts <- names(density_pts)

test_dim <- function(test_var){
  # test_var <- enquo(test_var)
  density_pts %>%
    distinct(!! sym(test_var)) %>%
    dim()
}

test <- names_density_pts %>%
  map(test_dim) %>%
  purrr::set_names(nm = names_density_pts) %>%
  bind_rows()

density_pts %>%
  distinct(fiss_density_ids) %>%
  dim()

