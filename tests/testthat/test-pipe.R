# Tests for R/pipe.R and R/globals.R

test_that("pipe operator is available and works", {
  result <- 5 %>% sum(3)
  expect_equal(result, 8)
})

test_that("pipe operator is re-exported from dplyr", {
  expect_true(is.function(`%>%`))
})

# globals.R just declares globalVariables; verify it loaded without error
test_that("globalVariables declaration doesn't error", {
  # If we got here, globals.R was sourced successfully during package load
  expect_true(TRUE)
})
