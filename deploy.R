files <- paste0("www/", list.files("www/", recursive = TRUE))
rsconnect::deployApp(appName = "ShinyMusic",
                     appTitle = "Shiny Music",
                     appFiles = files,
                     upload = TRUE)
