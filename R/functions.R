


##funciton to find a string in your directory from https://stackoverflow.com/questions/45502010/is-there-an-r-version-of-rstudios-find-in-files

fif <- function(what, where=".", in_files="\\.[Rr]$", recursive = TRUE,
                ignore.case = TRUE) {
  fils <- list.files(path = where, pattern = in_files, recursive = recursive)
  found <- FALSE
  file_cmd <- Sys.which("file")
  for (fil in fils) {
    if (nchar(file_cmd) > 0) {
      ftype <- system2(file_cmd, fil, TRUE)
      if (!grepl("text", ftype)[1]) next
    }
    contents <- readLines(fil)
    res <- grepl(what, contents, ignore.case = ignore.case)
    res <- which(res)
    if (length(res) > 0) {
      found <-  TRUE
      cat(sprintf("%s\n", fil), sep="")
      cat(sprintf(" % 4s: %s\n", res, contents[res]), sep="")
    }
  }
  if (!found) message("(No results found)")
}


##mini function to change column names to lower case
names_to_lower <- function(dat){
  dat %>%
    purrr::set_names(nm = stringr::str_to_lower(names(dat)))
}


##function to transform to another coodinate system and pull out the x and y
utm_to_coord <- function(dat, crs_to = 3005){
  crs_from = 26900 + dat %>% slice(1) %>% pull(utm_zone) ##we are assuming that the utm_zone is the same for all rows
  dat %>%
    sf::st_as_sf(coords = c('utm_easting', 'utm_northing'), crs = crs_from , remove = F) %>%
    sf::st_transform(crs = crs_to) %>%
    mutate(x = st_coordinates(.)[,1],
           y = st_coordinates(.)[,2]) %>%
    sf::st_drop_geometry()
}




