#' Run the Sunburst Demo App
#'
#' Launches an example Shiny application that demonstrates the sunburst widget.
#'
#' @param ... Additional arguments passed to \code{\link[shiny]{runApp}}.
#'
#' @return This function does not return; it runs the Shiny app.
#' @export
run_app <- function(...) {
  app_dir <- system.file("shiny", package = "sunburstShinyWidget")
  if (app_dir == "") {
    stop("Could not find the demo app directory. Try re-installing the package.")
  }
  shiny::runApp(app_dir, ...)
}
