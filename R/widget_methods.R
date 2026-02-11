#' Get Pathway Group Data Table
#'
#' Sends a custom message to the sunburst widget to retrieve pathway group data.
#'
#' @param id The namespaced widget output ID.
#' @param pathwayAnalysisDTO A list containing the pathway analysis data.
#' @param pathLength An integer specifying the pathway length.
#'
#' @return The widget element ID (invisibly).
#' @export
getPathwayGroupDatatable <- function(id, pathwayAnalysisDTO, pathLength) {
  method <- "getPathwayGroupDatatable"
  callJS()
}
