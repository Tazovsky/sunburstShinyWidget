# Tests for R/run_app.R

test_that("run_app errors when app directory is not found", {
  mockery::stub(run_app, "system.file", "")
  expect_error(
    run_app(),
    "Could not find the demo app directory"
  )
})

test_that("run_app finds the demo app directory via system.file", {
  # Verify the inst/shiny directory exists in the source tree
  inst_shiny <- file.path(testthat::test_path(), "..", "..", "inst", "shiny")
  expect_true(
    dir.exists(inst_shiny),
    label = "demo app directory should exist in inst/shiny"
  )
})

test_that("run_app calls shiny::runApp with the app directory", {
  captured_dir <- NULL
  mockery::stub(run_app, "system.file", "/fake/path/to/shiny")
  mockery::stub(run_app, "shiny::runApp", function(appDir, ...) {
    captured_dir <<- appDir
  })

  run_app()
  expect_equal(captured_dir, "/fake/path/to/shiny")
})

test_that("run_app passes extra arguments to shiny::runApp", {
  captured_args <- NULL
  mockery::stub(run_app, "system.file", "/fake/path")
  mockery::stub(run_app, "shiny::runApp", function(appDir, ...) {
    captured_args <<- list(...)
  })

  run_app(port = 3838, launch.browser = FALSE)
  expect_equal(captured_args$port, 3838)
  expect_false(captured_args$launch.browser)
})
