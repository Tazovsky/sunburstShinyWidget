#' sunburstUI
#'
#' @param id
#'
#' @return
#' @export
#' @rdname sunburst
#' @import bslib shiny
sunburstUI <- function(id) {
  ns <- NS(id)
  bslib::layout_columns(
    col_widths = c(3, 6, 3, 12),
    bslib::card(
      full_screen = FALSE,
      bslib::card_header("Legend"),
      tags$strong("Target Cohort"),
      uiOutput(ns("legend_target_cohort")),
      bslib::nav_spacer(),

      tags$strong("Event Cohorts"),
      DT::DTOutput(ns("legend_event_cohorts"))
    ),
    bslib::card(
      full_screen = FALSE,
      bslib::card_header("Sunburst plot"),
      # plotly::plotlyOutput(ns("plot"))
      sunburstAtlasOutput(ns("sunburst_plot"))
    ),
    bslib::card(
      full_screen = FALSE,
      bslib::card_header("Path details"),
      DT::DTOutput(ns("selectedCohorts"))
    ),
    bslib::card(
      full_screen = FALSE,
      DT::DTOutput(ns("click_data"))
    ),
  )

}


#' sunburstServer
#'
#' @param id
#' @param json_path
#' @param step_col_prefix
#' @param .delim
#'
#' @return
#' @export
#' @rdname sunburst
sunburstServer <- function(id, chartData, design, btn_font_size = "14px") {

  eventCodes <- chartData$eventCodes %>% dplyr::bind_rows()

  moduleServer(id, function(input, output, session) {


    output$sunburst_plot <- renderSunburstAtlas({
      sunburstAtlas(chartData, design)
    })


    observeEvent(input$sunburst_plot_chart_data_converted, {

      x <- req(input$sunburst_plot_chart_data_converted)
      x$cohortPathways[[1]]$targetCohortCount
      info <- x$cohortPathways[[1]]

      output$legend_target_cohort <- renderUI({
        tags$div(
          tags$span(info$targetCohortName),
          tags$br(),
          tags$ul(
            tags$li(glue::glue("Target cohort count: {info$targetCohortCount}")),
            tags$li(glue::glue("Persons with pathways count: {info$personsReported}")),
            tags$li(glue::glue("Persons with pathways portion: {info$personsReportedPct}"))
          )
        )
      })

    })
    event_cohorts <- reactive({
      req(input$sunburst_plot_chart_data_converted$eventCohorts) %>%
        dplyr::bind_rows()
    })

    observeEvent(event_cohorts(), {

      btns <- event_cohorts() %>%
        nrow() %>%
        seq_len() %>%
        lapply(function(rowid) {
          x <-  event_cohorts() %>% dplyr::slice(rowid)
          customActionButton(inputId = session$ns(paste0("cohortBtn-", x$code)),
                             label = x$name,
                             color = x$color,
                             font_size = btn_font_size) %>%
            as.character()
        }) %>%
        dplyr::tibble()

      output$legend_event_cohorts <- DT::renderDT(btns,
                                                  rownames = FALSE,
                                                  colnames = NULL,
                                                  escape = FALSE,
                                                  options = list(dom = "t"))
    })

    pathway <- reactive(input$sunburst_plot_click_data$pathway)

    observeEvent(pathway(), {
      btns_df <- req(pathway()) %>%
        lapply(function(path) {
          df <- path$names %>%
            dplyr::bind_rows() %>%
            dplyr::rowwise() %>%
            dplyr::mutate(btns = customActionButton(
              session$ns(paste0(name, "-", as.character(as.integer(Sys.time())))), name, color, btn_font_size) %>% as.character())

          tibble::tibble(Name = paste0(df$btns, collapse = " "),
                         Count = path$count)
        }) %>%
        dplyr::bind_rows()

      btns_df <- btns_df %>%
        dplyr::mutate(Count = sprintf("%s (%s%%)", Count, round(Count / sum(Count) * 100, 2)))

      output$selectedCohorts <- DT::renderDT(btns_df,
                                             rownames = TRUE,
                                             # colnames = TRUE,
                                             escape = FALSE,
                                             options = list(dom = "t"))

    })

    observeEvent(input$sunburst_plot_click_data, {
      click_event <- req(input$sunburst_plot_click_data)
      event_code <- as.integer(click_event$d$name)
      children <- click_event$d$children
      data <- click_event$data
      pathway <- click_event$pathway

      event_code_table <- eventCodes %>%
        dplyr::filter(code == event_code) %>%
        dplyr::mutate(name = strsplit(name, ",")) %>%
        tidyr::unnest_longer(col = name)

      req(nrow(event_code_table) >= 1)

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


  })
}


#' customActionButton
#'
#' @param inputId
#' @param label
#' @param color
#'
#' @return shiny::actionButton
#' @export
#'
customActionButton <- function(inputId, label, color, font_size = "10px") {
  shiny::actionButton(inputId, shiny::tags$strong(label), style = glue::glue("background-color: {color}; font-size: {font_size};'"))
}
