# Tests for R/widget_methods.R

test_that("getPathwayGroupDatatable calls callJS with correct parameters", {
  sent_method <- NULL
  sent_message <- NULL
  mock_session <- list(
    sendCustomMessage = function(type, message) {
      sent_method <<- type
      sent_message <<- message
    }
  )

  mockery::stub(getPathwayGroupDatatable, "callJS", function() {
    # Replicate what callJS does but with our mock
    message <- Filter(function(x) !is.symbol(x), as.list(parent.frame(1)))
    method <- paste0("sunburstShinyWidget:", message$method)
    mock_session$sendCustomMessage(method, message)
    return(message$id)
  })

  dto <- list(cohortId = 1, combos = list())
  result <- getPathwayGroupDatatable(
    id = "ns-sunburst",
    pathwayAnalysisDTO = dto,
    pathLength = 5
  )

  expect_equal(sent_method, "sunburstShinyWidget:getPathwayGroupDatatable")
  expect_equal(sent_message$id, "ns-sunburst")
  expect_equal(sent_message$pathwayAnalysisDTO, dto)
  expect_equal(sent_message$pathLength, 5)
  expect_equal(result, "ns-sunburst")
})

test_that("getPathwayGroupDatatable sets method to 'getPathwayGroupDatatable'", {
  # Simpler test: just verify the method variable is set correctly inside
  captured_method <- NULL
  mockery::stub(getPathwayGroupDatatable, "callJS", function() {
    msg <- as.list(parent.frame(1))
    captured_method <<- msg$method
    return(msg$id)
  })

  getPathwayGroupDatatable(id = "w1", pathwayAnalysisDTO = list(), pathLength = 3)
  expect_equal(captured_method, "getPathwayGroupDatatable")
})
