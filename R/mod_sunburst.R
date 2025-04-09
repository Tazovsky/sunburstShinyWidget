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
    col_widths = c(2, 7, 3, 12),
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
      full_screen = TRUE,
      bslib::card_header("Sunburst plot"),
      # plotly::plotlyOutput(ns("plot"))
      sunburstShinyWidgetOutput(ns("sunburst_plot"))
    ),
    bslib::card(
      full_screen = FALSE,
      bslib::card_header("Path details"),
      DT::DTOutput(ns("selectedCohorts")),
    ),
    bslib::card(
      full_screen = FALSE,
      bslib::card_body(
        DT::DTOutput(ns("click_data"))
      ),
      bslib::card_footer(
        downloadButton(outputId = ns("downloadSelectedCohorts"), label = "Download Table")
      )
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
sunburstServer <- function(id,
                           chartData,
                           design,
                           btn_font_size = "14px",
                           show_colors_in_table = FALSE,
                           steps_table_export_name = reactive(NULL),
                           n_steps = reactive(5L)) {

  eventCodes <- chartData$eventCodes %>% dplyr::bind_rows()

  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    output$sunburst_plot <- renderSunburstShinyWidget({
      sunburstShinyWidget(chartData, design)
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

    click_data <- reactive(input$sunburst_plot_click_data)
    pathway <- reactive(input$sunburst_plot_click_data$pathway)

    observeEvent(click_data(), {
      click_data <- req(click_data())

      btns_df <- click_data$pathway %>%
        lapply(function(path) {
          df <- path$names %>%
            dplyr::bind_rows() %>%
            dplyr::rowwise() %>%
            dplyr::mutate(btns = customActionButton(
              session$ns(paste0(name, "-", as.character(as.integer(Sys.time())))), name, color, btn_font_size) %>% as.character())

          tibble::tibble(Name = paste0(df$btns, collapse = " "),
                         Remain = path$count)
        }) %>%
        dplyr::bind_rows()

      totalPathways <- click_data$data$cohortPathways[[1]]$summary$totalPathways

      btns_df <- add_remain_and_diff_cols(btns_df, totalPathways)

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

      # output$click_data <- DT::renderDT({
      #   event_code_table
      # })

    })

    observeEvent(input$sunburst_plot_chart_colors, {
      print("input$sunburst_plot_chart_colors")
    })

    observeEvent(input$sunburst_plot_chart_data_converted, {
      chart_data <- req(input$sunburst_plot_chart_data_converted)
      getPathwayGroupDatatable(ns("sunburst_plot"), chartData, n_steps())
      print("chart_data$eventCohorts")
    })


    event_codes_and_btns <- eventReactive(input$sunburst_plot_chart_data_converted$eventCodes, {
      ev_codes <- req(input$sunburst_plot_chart_data_converted$eventCodes) %>%
        dplyr::bind_rows()

      ev_codes  %>%
        rowwise() %>%
        mutate(buttons = match_color(name, ev_codes))
    })

    steps_table <- reactiveVal()
    observeEvent(list(input$sunburst_plot_pathway_group_datatable, event_codes_and_btns()), {
      pathway_group_dt <- req(input$sunburst_plot_pathway_group_datatable)
      print("input$sunburst_plot_pathway_group_datatable")
      event_codes <- req(event_codes_and_btns())

      if (length(pathway_group_dt) > 1) {
        stop("pathway_group_dt length is greater than 1")
      }

      pg <- pathway_group_dt[[1]]

      df <- pg$data %>%
        lapply(function(x) {
          x$path <- x$path %>% unlist() %>% head(n_steps()) %>% paste0(collapse = "-")
          x
        }) %>%
        dplyr::bind_rows() %>%
        dplyr::mutate(path2 = strsplit(path, "-")) %>%
        dplyr::rowwise()

      if (show_colors_in_table) {
        df <- df %>%
          dplyr::mutate(Step = list(purrr::map(path2, function(pth) {
            event_codes %>%
              dplyr::filter(as.character(code) == as.character(pth)) %>%
              dplyr::pull(buttons)

          }))) %>%
          tidyr::unnest_wider(Step, names_sep = " ") %>%
          tidyr::unnest_wider(path2, names_sep = "") %>%
          dplyr::arrange(dplyr::across(dplyr::matches("^path2[0-9]+")))
      } else {
        df <- df %>%
          dplyr::mutate(Step = list(purrr::map(path2, function(pth) {
            event_codes %>%
              dplyr::filter(as.character(code) == as.character(pth)) %>%
              dplyr::pull(name)
          }))) %>%
          tidyr::unnest_wider(Step, names_sep = " ") %>%
          tidyr::unnest_wider(path2, names_sep = "") %>%
          dplyr::arrange(dplyr::across(dplyr::matches("^path2[0-9]+")))
      }


      df2render <- df %>%
        dplyr::mutate(personCount = scales::comma(personCount)) %>%
        dplyr::select(dplyr::starts_with("Step"), personCount)

      steps_table(df2render)

      browser()

      output$click_data <- DT::renderDT(
        df2render,
        rownames = FALSE,
        # colnames = NULL,
        escape = FALSE#,
        # options = list(dom = "t")
        , options = list(
          paging = TRUE,         # Enable pagination
          pageLength = 10,       # Number of rows per page
          lengthMenu = c(10, 15, 20, 50),  # Dropdown menu for rows per page
          searching = TRUE       # Enable search box
        )
      )
    })

    output$downloadSelectedCohorts <- downloadHandler(
      filename = function() {
        x <- req(input$sunburst_plot_chart_data_converted)
        if (isTruthy(steps_table_export_name())) {
          steps_table_export_name()
        } else {
          paste0(gsub("\\s", "_", x$cohortPathways[[1]]$targetCohortName), "_steps_table.csv")
        }
      },
      content = function(file) {
        utils::write.csv(steps_table(), file)
      }
    )


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


#' match_color
#'
#' @param x
#' @param eventCodes
#'
#' @return data.frame
#' @export
#'
match_color <- function(x, eventCodes) {
  event_names <- x %>%
    strsplit(",") %>%
    unlist()

  colors <- event_names %>%
    purrr::map(function(nm) {
      eventCodes %>%
        dplyr::filter(name == nm) %>%
        dplyr::pull(color)
    }) %>%
    unlist()

  event_names %>%
    length() %>%
    seq_len() %>%
    lapply(function(i) {
      customActionButton(as.character(as.integer(Sys.time())), event_names[i], colors[i], font_size = "10px") %>% as.character()
    }) %>%
    unlist() %>%
    paste0(collapse = ",")

}


#' add_remain_and_diff_cols
#'
#' @param btns_df
#' @param totalPathways
#'
#' @return data.frame
#' @export
#'
add_remain_and_diff_cols <- function(btns_df, totalPathways) {
  btns_df$Diff <- abs(c(totalPathways - btns_df$Remain[1], diff(btns_df$Remain)))
  btns_df$Diff_percent <- round((btns_df$Diff / totalPathways) * 100, 1)
  btns_df$Remain_percent <- round((btns_df$Remain / totalPathways) * 100, 1)
  btns_df$Diff <- paste0(scales::comma(btns_df$Diff), " (", btns_df$Diff_percent, "%)")
  btns_df$Remain <- paste0(scales::comma(btns_df$Remain), " (", btns_df$Remain_percent, "%)")
  btns_df$Remain_percent <- NULL
  btns_df$Diff_percent <- NULL
  btns_df
}
