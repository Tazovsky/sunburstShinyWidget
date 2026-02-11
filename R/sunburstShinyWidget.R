#' Create a Sunburst Shiny Widget
#'
#' Creates an interactive sunburst plot as an HTML widget.
#'
#' @param data A list containing the chart data.
#' @param design A list containing the design configuration.
#' @param width Widget width (a valid CSS unit or a number).
#' @param height Widget height (a valid CSS unit or a number).
#' @param elementId An optional element ID for the widget.
#'
#' @return An \code{htmlwidget} object.
#' @import htmlwidgets
#'
#' @export
sunburstShinyWidget <- function(data, design, width = NULL, height = NULL, elementId = NULL) {

  # forward options using x
  x = list(
    data = data,
    design = design
  )

  # create widget
  widget <- htmlwidgets::createWidget(
    name = 'sunburstShinyWidget',
    x,
    width = width,
    height = height,
    package = 'sunburstShinyWidget',
    elementId = elementId
  )

  # jquery <- htmltools::htmlDependency(
  #   "jquery", version = "3.4.1",
  #   src = list(href = "https://cdnjs.cloudflare.com/ajax/libs/jquery/3.4.1/"),
  #   script = "jquery.min.js"
  # )

  # requirejs <- htmltools::htmlDependency(
  #   "requirejs", version = "2.3.3",
  #   src = list(href = "https://cdnjs.cloudflare.com/ajax/libs/require.js/2.3.3"),
  #   # head = list(`data-main` = "./main"),
  #   head = tags$head(`data-main`="main", src="require.js"),
  #   script = "require.min.js"
  # )
  # widget$dependencies <- c(list(requirejs))

  return(widget)
}

#' Shiny bindings for sunburstShinyWidget
#'
#' Output and render functions for using sunburstShinyWidget within Shiny
#' applications and interactive Rmd documents.
#'
#' @param outputId output variable to read from
#' @param width,height Must be a valid CSS unit (like \code{'100\%'},
#'   \code{'400px'}, \code{'auto'}) or a number, which will be coerced to a
#'   string and have \code{'px'} appended.
#' @param expr An expression that generates a sunburstShinyWidget
#' @param env The environment in which to evaluate \code{expr}.
#' @param quoted Is \code{expr} a quoted expression (with \code{quote()})? This
#'   is useful if you want to save an expression in a variable.
#'
#' @name sunburstShinyWidget-shiny
#'
#' @export
sunburstShinyWidgetOutput <- function(outputId, width = '100%', height = '400px'){
  htmlwidgets::shinyWidgetOutput(outputId, 'sunburstShinyWidget', width, height, package = 'sunburstShinyWidget')
}

#' @rdname sunburstShinyWidget-shiny
#' @export
renderSunburstShinyWidget <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) { expr <- substitute(expr) } # force quoted
  htmlwidgets::shinyRenderWidget(expr, sunburstShinyWidgetOutput, env, quoted = TRUE)
}
