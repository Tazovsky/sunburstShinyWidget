# Tests for R/callJS.R

test_that("callJS constructs method name and sends message via session", {
  # Create a mock session that captures the sendCustomMessage call
  sent_method <- NULL
  sent_message <- NULL
  mock_session <- list(
    sendCustomMessage = function(type, message) {
      sent_method <<- type
      sent_message <<- message
    }
  )

  # Mock getDefaultReactiveDomain to return our mock session
  mockery::stub(callJS, "shiny::getDefaultReactiveDomain", mock_session)

  # callJS uses parent.frame(1) to capture caller arguments, so we need to
  # call it from a function that has the expected arguments
  caller <- function(id, method) {
    callJS()
  }

  result <- caller(id = "my-widget", method = "doSomething")

  expect_equal(sent_method, "sunburstShinyWidget:doSomething")
  expect_equal(sent_message$id, "my-widget")
  expect_equal(sent_message$method, "doSomething")
  expect_equal(result, "my-widget")
})

test_that("callJS filters out symbol arguments from parent frame", {
  sent_message <- NULL
  mock_session <- list(
    sendCustomMessage = function(type, message) {
      sent_message <<- message
    }
  )

  mockery::stub(callJS, "shiny::getDefaultReactiveDomain", mock_session)

  caller <- function(id, method, extra_data) {
    callJS()
  }

  caller(id = "w1", method = "testMethod", extra_data = list(a = 1))

  expect_equal(sent_message$id, "w1")
  expect_equal(sent_message$method, "testMethod")
  expect_equal(sent_message$extra_data, list(a = 1))
})

test_that("callJS returns the id from the message", {
  mock_session <- list(
    sendCustomMessage = function(type, message) {}
  )

  mockery::stub(callJS, "shiny::getDefaultReactiveDomain", mock_session)

  caller <- function(id, method) {
    callJS()
  }

  result <- caller(id = "widget-123", method = "anyMethod")
  expect_equal(result, "widget-123")
})
