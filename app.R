######################################
## Shiny Docs                       ##
## Document PDF Browser for Shiny   ##
## Example: Sheet Music             ##
## Written by: Colby T. Ford, Ph.D. ##
######################################

library(shiny)
library(shinymaterial)
library(dplyr)
library(DT)

## UI
ui <- material_page(
  tags$link(
    rel = "stylesheet", 
    href="https://fonts.googleapis.com/css?family=Pacifico&display=swap"
  ),
  tags$style("h1{font-family: 'Pacifico'; color: #ffffff; text-align: center}"),
  title = h1("Shiny Music"),
  h1(icon("music", lib = "font-awesome"), "Shiny Music", icon("play", lib = "font-awesome")),
  nav_bar_color = "black",
  background_color = "blue-grey darken-4",
  font_color = "white",
  include_nav_bar = FALSE,
  material_row(
    material_column(width = 1),
    material_column(width = 10,
                    dataTableOutput("tbl", width = "100%"),
                    HTML('<br><footer align="center"><font color="white">All files sourced from <a href="pianoette.szm.com" target="_blank">pianoette.szm.com</a>. All example files Copyright &copy their respective owners.<br>By using this demo Shiny application, no ownership or rights are implied.</font></footer>')
                    ),
    material_column(width = 1)
  )
  
)


## SERVER
server <- function(input, output) {
   sheetmusic <- read.csv("sheetmusic.csv")
   sm_dt <- datatable(sheetmusic %>% select(artist, songhtml),
                      colnames = c("Artist", "Song"),
                      #class = "hover",
                      escape = c(TRUE, FALSE),
                      rownames = FALSE,
                      style = "default",
                      options = list(pageLength = 25,
                                     initComplete = JS(
                                       "function(settings, json) {",
                                       "$(this.api().table().header()).css({'background-color': '#546e7a', 'color': '#ffffff'});",
                                       "}")
                                     )
                      )
   
   output$tbl = renderDataTable(sm_dt)
}

# Run the application 
shinyApp(ui = ui, server = server)

# files <- list.files("www/sheetmusic/")
# rsconnect::deployApp(appFiles = files, appName = "ShinyMusic", upload = TRUE)
