####################################
## Sheet Music Scraper            ##
## By: Colby T. Ford, Ph.D.       ##
####################################

## Load in libraries
library(dplyr)
library(rvest)
library(stringr)

### Step 1: Scrape from PIANOETTE.SZM.COM
## Get all links from pianoette pages

allpages <- paste0("http://pianotte.szm.com/",LETTERS,".htm")

pianoette_set <- data.frame(source = character(0),
                            title = character(0),
                            host_link = character(0),
                            pdf_link = character(0))

## Loop through each page and grab any link to dohost.co

for (page in 1:length(allpages)) {
  current_page <- allpages[page]
  
  cat("Scraping page:", current_page, "\n")
  
  pianoette_page <- read_html(current_page)
  
  pianoette_titles <- pianoette_page %>% 
    html_nodes("a") %>% 
    html_text()
  
  pianoette_links <- pianoette_page %>% 
    html_nodes("a") %>% 
    html_attr('href')
  
  current_set <- data.frame(source = rep(current_page, length(pianoette_titles)),
                            title = pianoette_titles,
                            host_link = pianoette_links,
                            pdf_link = NA)
  
  pianoette_set <- current_set %>%
    filter(str_detect(host_link, 'dohost.co')) %>% 
    rbind(pianoette_set)
}

### Step 2: Scrape from DOHOST.CO
## Loop through each dohost link found on pianoette, follow the redirect, and look for .pdf links
for (page in 1:nrow(pianoette_set)){
  current_page <- as.character(pianoette_set$host_link[page])
  
  ## Clean up between iterations
  if (exists("dohost_first_page")){
    rm(dohost_first_page) ## Clean up between iterations
  }
  if (exists("dohost_redirect_page")){
    rm(dohost_redirect_page)
  }
  
  cat(page, ". Scraping page:", current_page, "\n")
  
  ## See if the first page works
  tryCatch(
    dohost_first_page <- read_html(current_page), 
    error = function(e){NA}    # a function that returns NA regardless of what it's passed
  )
  
  if (exists("dohost_first_page")){
    url_pattern <- "http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+"
    
    ## Capture redirect
    dohost_redirect_url <- xml_attrs(xml_child(xml_child(dohost_first_page, 1), 4))[["content"]] %>% 
      str_extract(url_pattern)
    
    ## See if the redirect page works
    tryCatch(
      dohost_redirect_page <- read_html(dohost_redirect_url),
      error = function(e){NA}    # a function that returns NA regardless of what it's passed
    )
    
    if (exists("dohost_redirect_page")){
      
      dohost_links <- dohost_redirect_page %>% 
        html_nodes("a") %>% 
        html_attr('href') %>% 
        data.frame()
      
      colnames(dohost_links) <- "host_links"
      
      ## Only report first .pdf link
      pdf_links <- dohost_links %>%
        filter(str_detect(host_links, '.pdf'))
      
      pianoette_set$pdf_link[page] <- as.character(pdf_links[1,])
    }
  }
}

## Split title column into song and artist and extract filename
library(tidyr)
music_set <- pianoette_set %>%
  separate(title, c("song", "artist"), sep = "-|–", remove = TRUE) %>% 
  mutate(song = str_trim(str_to_title(song), side = "both"),
         artist = str_trim(str_to_title(artist), side = "both"),
         filename = str_extract(pdf_link, "(?:[^/][\\d\\w\\.\\-]+)$(?<=(?:.pdf))"),
         filepath = paste0("/sheetmusic/", str_extract(pdf_link, "(?:[^/][\\d\\w\\.\\-]+)$(?<=(?:.pdf))")),
         songhtml = paste0("<a href=\"", filepath,"\" target=\"_blank\">", song,"</a>"),
         pdf_linkhtml = paste0("<a href=\"", pdf_link,"\" target=\"_blank\">", song,"</a>")) %>% 
  arrange(artist, song)


### Step 3: Download PDFs
for(pdf in 1:nrow(music_set)){
  fileloc <- paste0("www/", music_set$filepath[pdf])
  cat(pdf, ". Downloading:", music_set$filename[pdf], "\n")
  
  ## See if the download works
  tryCatch(
    download.file(music_set$pdf_link[pdf], fileloc, quiet = TRUE),
    error = function(e){NA}    # a function that returns NA regardless of what it's passed
  )
}

## Save final table
readr::write_csv(music_set, "sheetmusic.csv")
