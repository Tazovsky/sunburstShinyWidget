library(shiny)
library(bslib)
library(dplyr)

data_dir <- system.file("shiny", "data", package = "sunburstShinyWidget")
chartData <- jsonlite::read_json(file.path(data_dir, "chartData.json"))
design <- jsonlite::read_json(file.path(data_dir, "design.json"))
eventCodes <- chartData$eventCodes %>% dplyr::bind_rows()

ui <- page_sidebar(
  title = "Sunburst plot",
  sidebar = sidebar(
    open = FALSE
  ),

  bslib::nav_panel(
    "Plot",
    tagList(
      sunburstUI("sunburst_plot")
    )
  )

)

server <- function(input, output) {
  sunburstServer("sunburst_plot", chartData, design)
}

shinyApp(ui, server)
