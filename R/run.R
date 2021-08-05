##this is for as we work through

preview_chapter('0100-intro.Rmd')



##to build both a paged html version and a gitbook follow the steps below

#######################################################################################
##change your VErsion #

##go to the index.Rmd and change gitbook_on <- TRUE
#################################################################################################

rmarkdown::render_site(output_format = 'bookdown::gitbook',
                       encoding = 'UTF-8')



#################################################################################################
##go to the index.Rmd and change gitbook_on <- FALSE
#################################################################################################

# ##   then make our printable pdf
# rmarkdown::render_site(output_format = 'pagedown::html_paged',
#                        encoding = 'UTF-8')
# ##  move it to the docs folder so that it can be seen by the download button
# # file.rename('Bulkley.html', 'docs/Bulkley.html')
#
# ##now we need to print the docs/Elk.html file to Elk.pdf with chrome.  We should automate this step.  Do in browser for now
# openHTML('docs/Template.html')





##########################################make Phase 1 appendix seperately
#################################################################################################
##we need a workflow to print the Phase 1 attachment
files_to_move <- list.files(pattern = ".Rmd$") %>%
  stringr::str_subset(., 'index|Bulkley|0600', negate = T)
files_destination <- paste0('hold/', files_to_move)

##move the files
mapply(file.rename, from = files_to_move, to = files_destination)



##this is hacky but hash out the following from the functions.R file print_tab_summary_all function
# kableExtra::add_footnote(label = '<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>', escape = F, notation = 'none')

##   then make our printable pdf
rmarkdown::render_site(output_format = 'pagedown::html_paged', encoding = 'UTF-8')

##  move it to the docs folder so that it can be in the same place as the report
file.rename('Bulkley.html', 'docs/Attachment_3_Phase_1_Data_and_Photos.html')

##move the files from the hold file back to the main file
mapply(file.rename, from = files_destination, to = files_to_move)

#print the attachment to pdf
openHTML('docs/Attachment_3_Phase_1_Data_and_Photos_prep.html')

##now get rid of the first 10 pages
length <- pdftools::pdf_length(paste0(getwd(), "/docs/Attachment_3_Phase_1_Data_and_Photos_prep.pdf"))

pdftools::pdf_subset(paste0(getwd(), "/docs/Attachment_3_Phase_1_Data_and_Photos_prep.pdf"),
           pages = 11:length, output = paste0(getwd(), "/docs/Attachment_3_Phase_1_Data_and_Photos.pdf"))

##clean out the old file
file.remove(paste0(getwd(), "/docs/Attachment_3_Phase_1_Data_and_Photos_prep.pdf"))
file.remove(paste0(getwd(), "/docs/Attachment_3_Phase_1_Data_and_Photos_prep.html"))

