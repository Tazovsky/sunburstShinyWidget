library(shinydashboard)
library(shiny)
pkgload::load_all(".")


header <- dashboardHeader(
  title = "Sunburst app"
)

body <- dashboardBody(
  fluidRow(
    column(width = 9,
           box(
             width = NULL, solidHeader = FALSE,
             sunburstAtlasOutput("sunburst_plot")
           ),
           box(width = NULL, solidHeader = TRUE,
               uiOutput("click_data")
           )#,
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

  observeEvent(input$sunburst_plot_click_data, {
    click_event <- req(input$sunburst_plot_click_data)
    print(click_event)

    output$click_data <- renderUI({
      shiny::HTML(click_event$d)
    })
  })


}

shinyApp(ui = ui, server = server)
