#' callJS
#'
#' See: https://deanattali.com/blog/htmlwidgets-tips/
#'
#' @return id
#'
callJS <- function() {
  message <- Filter(function(x) !is.symbol(x), as.list(parent.frame(1)))
  session <- shiny::getDefaultReactiveDomain()
  method <- paste0("sunburstShinyWidget:", message$method)
  session$sendCustomMessage(method, message)
  return(message$id)
}
