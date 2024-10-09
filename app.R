library(shiny)
library(bslib)
library(dplyr)
pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)


# Setup -------------------------------------------------------------------

data_dir <- "data"
chartData <- jsonlite::read_json(file.path(data_dir, "chartData.json"))
design <- jsonlite::read_json(file.path(data_dir, "design.json"))
eventCodes <- chartData$eventCodes %>% dplyr::bind_rows()

# UI ----------------------------------------------------------------------

ui <- page_sidebar(
  title = "Sunburst plot",
  sidebar = sidebar(
    open = FALSE
  ),

  bslib::nav_panel(
    "Plot",
    tagList(
      shiny.info::version(as.character(packageVersion("sunburstShinyWidget")), position = "bottom right"),
      sunburstUI("sunburst_plot")
    )
  )

)

# Server ------------------------------------------------------------------

server <- function(input, output) {
  sunburstServer("sunburst_plot", chartData, design)
}


# Shiny App ---------------------------------------------------------------

shinyApp(ui, server)
