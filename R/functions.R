


##funciton ot find a string in your directory from https://stackoverflow.com/questions/45502010/is-there-an-r-version-of-rstudios-find-in-files

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


##function to trim up sheet and get names (was previously source from altools package)
at_trim_xlsheet2 <- function(df, column_last = ncol(df)) {
  df %>%
    dplyr::select(1:column_last) %>% ##get rid of the extra columns.  should be more abstract
    janitor::row_to_names(which.max(complete.cases(.))) %>%
    janitor::clean_names() %>%
    janitor::remove_empty(., which = "rows")
}



####------my_kable-------------------------------
my_kable_scroll <- function(dat, caption_text = '', font = font_set){
  dat %>%
    kable(caption = caption_text, booktabs = T) %>%
    kableExtra::kable_styling(c("condensed", "responsive"),
                              full_width = T,
                              font_size = font) %>%
    kableExtra::scroll_box(width = "100%", height = "500px")
}

my_tab_overview <- function(dat, caption_text = '', font = font_set){
  dat %>%
    kable(caption = caption_text, booktabs = T) %>%
    kableExtra::kable_styling(c("condensed", "responsive"), full_width = T, font_size = font) %>%
    kableExtra::column_spec(column = c(9), width_min = '1.5in') %>%
    kableExtra::column_spec(column = c(5), width_min = '1.0in', width_max = '1.0in')
}

my_tab_overview_scroll <- function(dat, caption_text = '', font = font_set){
  dat %>%
    kable(caption = caption_text, booktabs = T) %>%
    kableExtra::kable_styling(c("condensed"),
                              full_width = T,
                              font_size = font) %>%
    kableExtra::column_spec(column = c(9), width_min = '1.5in') %>%
    kableExtra::column_spec(column = c(5), width_max = '1in') %>%
    kableExtra::scroll_box(width = "100%", height = "500px")
}


my_kable_scroll_no_height <- function(dat, caption_text = ''){
  dat %>%
    kable(caption = caption_text, booktabs = T) %>%
    kableExtra::kable_styling(c("condensed"), full_width = T, font_size = 11) %>%
    kableExtra::scroll_box(width = "100%")
}



my_kable <- function(dat, caption_text = '', font = font_set){
  dat %>%
    kable(caption = caption_text, booktabs = T) %>%
    kableExtra::kable_styling(c("condensed", "responsive"),
                              full_width = T,
                              font_size = font)
    # kableExtra::scroll_box(width = "100%", height = "500px")
}


get_img <- function(site = my_site, photo = my_photo){
  jpeg::readJPEG(paste0('data/photos/', site, '/', photo))
}

get_img_path_abs <- function(site = my_site, photo = my_photo){
  stub <- 'https://github.com/NewGraphEnvironment/fish_passage_elk_2020_reporting/blob/master/'
  paste0(stub, 'data/photos/', site, '/', photo)
}

get_img_path <- function(site = my_site, photo = my_photo){
  paste0('data/photos/', site, '/', photo)
}



##here is a shot at a function to pull a photo based on a string subset
pull_photo_by_str <- function(site_id = my_site, str_to_pull = 'barrel'){
  list.files(path = paste0(getwd(), '/data/photos/', site_id), full.names = T) %>%
    stringr::str_subset(., str_to_pull) %>%
    basename()
}


##############this is for making kmls
make_kml_col <- function(df){
  df %>%
    mutate(`PSCIS ID` = as.integer(`PSCIS ID`),
           `Modelled ID` = as.integer(`Modelled ID`),
           color = case_when(Priority == 'high' ~ 'red',
                             Priority == 'no fix' ~ 'green',
                             Priority == 'moderate' ~ 'yellow',
                             T ~ 'grey'),
           # shape = case_when(Priority == 'high' ~ 'http://maps.google.com/mapfiles/kml/pushpin/red-pushpin.png',
           #                   Priority == 'no fix' ~ 'http://maps.google.com/mapfiles/kml/pushpin/grn-pushpin.png',
           #                   Priority == 'moderate' ~ 'http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png',
           #                   T ~ 'http://maps.google.com/mapfiles/kml/pushpin/wht-pushpin.png'),
           shape = case_when(Priority == 'high' ~ 'http://maps.google.com/mapfiles/kml/paddle/red-blank.png',
                             Priority == 'no fix' ~ 'http://maps.google.com/mapfiles/kml/paddle/grn-blank.png',
                             Priority == 'moderate' ~ 'http://maps.google.com/mapfiles/kml/paddle/ylw-blank.png',
                             T ~ 'http://maps.google.com/mapfiles/kml/paddle/wht-blank.png'),
           color = plotKML::col2kml(color),
           site_id = case_when(!is.na(`PSCIS ID`) ~ paste('PSCIS ', `PSCIS ID`),
                               is.na(`PSCIS ID`) ~ paste0('Modelled ', `Modelled ID`)),
           label = paste0(site_id, '-', Priority),
           `Image link` = case_when(!is.na(`Image link`) ~ cell_spec('crossing', "html", link = `Image link`),
                                    T ~ `Image link`)) %>%
    select(site_id, Priority, label, color, shape, everything())
  # mutate(across(where(is.numeric), round(.,2)))

}

## add a line to the function to make the comments column wide enough
make_html_tbl <- function(df) {
  # df2 <- df %>%
  #   dplyr::mutate(`Image link` = cell_spec('crossing', "html", link = `Image link`))
  df2 <- select(df, -shape, -color, -label) %>% janitor::remove_empty()
  df %>%
    mutate(html_tbl = knitr::kable(df2, 'html', escape = F) %>%
             kableExtra::row_spec(0:nrow(df2), extra_css = "border: 1px solid black;") %>% # All cells get a border
             kableExtra::row_spec(0, background = "yellow") %>%
             kableExtra::column_spec(column = ncol(df2) - 1, width_min = '0.5in') %>%
             kableExtra::column_spec(column = ncol(df2), width_min = '4in')
    )
}


openHTML <- function(x) browseURL(paste0('file://', file.path(getwd(), x)))

