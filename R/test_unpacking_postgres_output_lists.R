#quick test to see if we can unpack the array into a list then unnest
#https://stackoverflow.com/questions/64862758/convert-a-string-with-curly-brackets-to-a-nested-list-object

library(data.table)

fiss_density_pts <- read_csv("data/fiss_density_pts.csv")


##wondering if this might work if we can get rid of 'c(' when there is only one item. Doubt it.
##Prob better to export as another format or in long format with each event as a row
test <- fiss_density_pts %>%
  mutate(fiss_density_ids = stringr::str_replace_all(fiss_density_ids, '\\{', 'c('),
         fiss_density_ids = stringr::str_replace_all(fiss_density_ids, '\\}', ')'),
         fiss_density_ids = as.list(fiss_density_ids)
         ) %>%
  tidyr::unnest(fiss_density_ids)



##this is from the link but we cannot do the 'parse' step.
test2 <- fiss_density_pts %>%
  mutate(fiss_density_ids = gsub("\\{([^{]+)\\}", "c(\\1)", fiss_density_ids))
# fiss_density_ids2 = gsub("([a-zA-Z]\\w+)", "'\\1'", fiss_density_ids2), #quotes the words that start with a letter
         fiss_density_ids = gsub("\\{", "list(", fiss_density_ids), ##outer lists
         fiss_density_ids = gsub("\\}", ")", fiss_density_ids),
         fiss_density_ids = as.list(fiss_density_ids))
         fiss_density_ids= eval(fiss_density_ids)) %>%
  tidyr::unnest(fiss_density_ids)


 ##this one works when packaged as geojson and unpacked with sf....
 wshds <- sf::read_sf('https://www.hillcrestgeo.ca/outgoing/public/fiss_density_watersheds.geojson')

 wshds_df <- wshds %>%
   sf::st_drop_geometry() %>%
 unnest(fiss_density_distinct_ids)
