# https://shiny.posit.co/blog/posts/bslib-dashboards/#hello-dashboards

library(shiny)
library(bslib)
library(dplyr)
pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)


# Setup -------------------------------------------------------------------

chartData <- jsonlite::read_json("dev/chartData.json")
design <- jsonlite::read_json("dev/design.json")
eventCodes <- chartData$eventCodes %>% dplyr::bind_rows()

# UI ----------------------------------------------------------------------

ui <- page_sidebar(
  title = "Sunburst plot",
  sidebar = sidebar(
    open = FALSE
  ),

  bslib::nav_panel(
    "Plot",
    sunburstUI("sunburst_plot")
  )

)

# Server ------------------------------------------------------------------

server <- function(input, output) {
  sunburstServer("sunburst_plot", chartData, design)
}


# Shiny App ---------------------------------------------------------------

shinyApp(ui, server)
