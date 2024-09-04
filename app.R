library(shinydashboard)
library(shiny)
pkgload::load_all(".")


header <- dashboardHeader(
  title = "Sunburst app"
)

body <- dashboardBody(
  fluidRow(
    column(width = 9,
           # box(width = NULL, solidHeader = TRUE,
           #     tags$div(id = "sunburstplot")
           # )#,
           box(width = NULL,
               sunburstAtlasOutput("sunburst_plot")
               )
    )
  )
)

ui <- dashboardPage(
  header,
  dashboardSidebar(disable = TRUE),
  body
)

server <- function(input, output, session) {

  output$sunburst_plot <- renderSunburstAtlas({
    data <- jsonlite::read_json("dev/chartData.json")
    design <- jsonlite::read_json("dev/design.json")
    sunburstAtlas(data, design)
  })

}

shinyApp(ui = ui, server = server)
