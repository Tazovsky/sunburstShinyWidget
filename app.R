library(shinydashboard)
library(shiny)
library(dplyr)
pkgload::load_all(".")

chartData <- jsonlite::read_json("dev/chartData.json")
design <- jsonlite::read_json("dev/design.json")
eventCodes <- chartData$eventCodes %>% dplyr::bind_rows()

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
               DT::DTOutput("click_data")
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
    sunburstAtlas(chartData, design)
  })

  observeEvent(input$sunburst_plot_click_data, {
    click_event <- req(input$sunburst_plot_click_data)

    event_code <- as.integer(click_event$d$name)
    children <- click_event$d$children
    data <- click_event$data

    event_code_table <- eventCodes %>% dplyr::filter(code == event_code)
    print(event_code_table)
    output$click_data <- DT::renderDT({
      event_code_table
    })
  })

  observeEvent(input$sunburst_plot_chart_colors, {
    print(input$sunburst_plot_chart_colors)
  })

  observeEvent(input$sunburst_plot_chart_data_converted, {
    chart_data <- req(input$sunburst_plot_chart_data_converted)
    print(chart_data$eventCohorts)
  })

}

shinyApp(ui = ui, server = server)
