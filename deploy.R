files <- paste0("www/", list.files("www/", recursive = TRUE))
rsconnect::deployApp(appTitle = "Shiny Music")
