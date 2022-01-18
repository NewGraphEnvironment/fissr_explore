
##Get output of channel width equations with R so we can conmapre with sql
library(tidyverse)
library(data.table)


fiss_density_pts <- read_csv("data/fiss_density_pts.csv",
                             col_types =cols(
                               fiss_density_distinct_id = col_double(),
                               fiss_density_ids = col_character(),
                               distance_to_stream = col_double(),
                               stream_order = col_double(),
                               stream_order_parent = col_double(),
                               stream_magnitude = col_double(),
                               gradient = col_double(),
                               map = col_double(),
                               map_upstream = col_double(),
                               upstream_area_ha = col_double(),
                               channel_width = col_double(),
                               channel_width_source = col_character(),
                               mad_m3s = col_double(),
                               bcalbers_x = col_double(),
                               bcalbers_y = col_double()
                             ))

##define parameters from
# channel-width-21 https://www.poissonconsulting.ca/temporary-hidden-link/1792764180/channel-width-21/
# channel-width-21b https://www.poissonconsulting.ca/temporary-hidden-link/859859031/channel-width-21b/
b0_21 <- -2.2383120
bArea_21	<- 0.3121556
bPrecipitation_21 <- 0.6546995
b0_21b <- 0.3071300
bDischarge_21b <- 0.4577882

fiss_density_pts_cw <- fiss_density_pts %>%
  mutate(
    upstream_area_km = upstream_area_ha/100,
    map_upstream_m = map_upstream/1000, ##convert mm to m
    map_upstream_2021 = map_upstream/10,  ##this was divided by 10 in the poisson code https://github.com/poissonconsulting/channel-width-21/blob/main/clean-data.R
    cw_modelled_21 = exp(b0_21 + (bArea_21 * log(upstream_area_km))  + (bPrecipitation_21 * log(map_upstream_2021))),
    cw_modelled_21b = exp(b0_21b + bDischarge_21b * (log(upstream_area_km) + log(map_upstream_m)))
  )

fiss_density_pts_cw_compare <- fiss_density_pts_cw %>%
    dplyr::relocate(c(channel_width, channel_width_source), .after = cw_modelled_21b) %>%
  mutate(cw_diff21_perc = abs((cw_modelled_21 - channel_width)/channel_width) * 100,
         cw_diff21b_perc = abs((cw_modelled_21b - channel_width)/channel_width) * 100)

compare_measured <- fiss_density_pts_cw_compare %>%
  filter(channel_width_source %ilike% 'Field' & upstream_area_km < 100)

compare_modelled <- fiss_density_pts_cw_compare %>%
  filter(channel_width_source %ilike% 'Modelled' & upstream_area_km < 100)


compare_measured_sum <- compare_measured %>%
  summarise(cw_diff21_mean = mean(cw_diff21_perc, na.rm = T),
            cw_diff21_median = median(cw_diff21_perc, na.rm = T),
            cw_diff21b_mean = mean(cw_diff21b_perc, na.rm = T),
            cw_diff21b_median = median(cw_diff21b_perc, na.rm = T))

compare_modelled_sum <- compare_modelled %>%
  summarise(cw_diff21_mean = mean(cw_diff21_perc, na.rm = T),
            cw_diff21_median = median(cw_diff21_perc, na.rm = T),
            cw_diff21b_mean = mean(cw_diff21b_perc, na.rm = T),
            cw_diff21b_median = median(cw_diff21b_perc, na.rm = T))


##burn at csv of the values so we can compare to sql
fiss_density_pts_cw %>%
  readr::write_csv(file = 'data/fiss_density_pts_channel_width.csv')
