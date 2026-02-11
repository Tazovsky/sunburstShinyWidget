# Tests for htmlwidgets bindings in R/sunburstShinyWidget.R

# --- sunburstShinyWidget() ---------------------------------------------------

test_that("sunburstShinyWidget returns an htmlwidget with correct class", {
  w <- sunburstShinyWidget(
    data = list(records = list()),
    design = list(maxDepth = 5)
  )
  expect_s3_class(w, "sunburstShinyWidget")
  expect_s3_class(w, "htmlwidget")
})

test_that("sunburstShinyWidget stores data and design in x", {
  mock_data <- list(records = list(list(path = "1-2-end", personCount = 10)))
  mock_design <- list(maxDepth = 3, cohortId = 99)

  w <- sunburstShinyWidget(data = mock_data, design = mock_design)
  expect_identical(w$x$data, mock_data)
  expect_identical(w$x$design, mock_design)
})

test_that("sunburstShinyWidget passes custom width, height, elementId", {
  w <- sunburstShinyWidget(
    data = list(),
    design = list(),
    width = 600,
    height = 400,
    elementId = "my-sunburst"
  )
  expect_equal(w$width, 600)
  expect_equal(w$height, 400)
  expect_equal(w$elementId, "my-sunburst")
})

test_that("sunburstShinyWidget defaults width/height/elementId to NULL", {
  w <- sunburstShinyWidget(data = list(), design = list())
  expect_null(w$width)
  expect_null(w$height)
  expect_null(w$elementId)
})

test_that("sunburstShinyWidget works with sample fixture data", {
  skip_if(is.null(sample_chartData), "sample_chartData not available")
  skip_if(is.null(sample_design), "sample_design not available")

  w <- sunburstShinyWidget(data = sample_chartData, design = sample_design)
  expect_s3_class(w, "htmlwidget")
  expect_identical(w$x$data, sample_chartData)
  expect_identical(w$x$design, sample_design)
})

test_that("sunburstShinyWidget x contains only data and design", {
  w <- sunburstShinyWidget(data = list(a = 1), design = list(b = 2))
  expect_named(w$x, c("data", "design"))
})

# --- sunburstShinyWidgetOutput() ----------------------------------------------

test_that("sunburstShinyWidgetOutput returns a shiny tag", {
  tag <- sunburstShinyWidgetOutput("test_output")
  expect_true(inherits(tag, "shiny.tag") || inherits(tag, "shiny.tag.list"))
})

test_that("sunburstShinyWidgetOutput uses default dimensions", {
  tag <- sunburstShinyWidgetOutput("test_output")
  html <- as.character(tag)
  expect_match(html, "100%")
  expect_match(html, "400px")
})

test_that("sunburstShinyWidgetOutput respects custom dimensions", {
  tag <- sunburstShinyWidgetOutput("test_output", width = "50%", height = "200px")
  html <- as.character(tag)
  expect_match(html, "50%")
  expect_match(html, "200px")
})

test_that("sunburstShinyWidgetOutput embeds the outputId", {
  tag <- sunburstShinyWidgetOutput("my_sunburst_output")
  html <- as.character(tag)
  expect_match(html, "my_sunburst_output")
})

# --- renderSunburstShinyWidget() ----------------------------------------------

test_that("renderSunburstShinyWidget returns a function (render output)", {
  render_fn <- renderSunburstShinyWidget(
    sunburstShinyWidget(data = list(), design = list())
  )
  expect_true(is.function(render_fn))
})

test_that("renderSunburstShinyWidget works with quoted = TRUE", {
  expr <- quote(sunburstShinyWidget(data = list(), design = list()))
  render_fn <- renderSunburstShinyWidget(expr, quoted = TRUE)
  expect_true(is.function(render_fn))
})

test_that("renderSunburstShinyWidget result is a callable shiny render function", {
  render_fn <- renderSunburstShinyWidget(
    sunburstShinyWidget(data = list(), design = list())
  )
  expect_true(is.function(render_fn))
  # htmlwidgets render functions are plain functions; the class is on the
  # output object they produce, not on the render function itself
})
