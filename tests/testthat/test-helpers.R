# Tests for pure helper functions in R/mod_sunburst.R
# Functions: add_remain_and_diff_cols, customActionButton, match_color

# ---------- add_remain_and_diff_cols ----------

test_that("add_remain_and_diff_cols computes correct Diff and Remain with fixture data", {
  result <- add_remain_and_diff_cols(fixture_btns_df, totalPathways = 200)

  # First row: Diff = abs(200 - 100) = 100, Diff% = 50%, Remain = 100 (50%)

  expect_equal(result$Diff[1], "100 (50%)")
  expect_equal(result$Remain[1], "100 (50%)")

  # Second row: Diff = abs(100 - 60) = 40, Diff% = 20%, Remain = 60 (30%)
  expect_equal(result$Diff[2], "40 (20%)")
  expect_equal(result$Remain[2], "60 (30%)")

  # Third row: Diff = abs(60 - 25) = 35, Diff% = 17.5%, Remain = 25 (12.5%)
  expect_equal(result$Diff[3], "35 (17.5%)")
  expect_equal(result$Remain[3], "25 (12.5%)")
})

test_that("add_remain_and_diff_cols removes intermediate percent columns", {
  result <- add_remain_and_diff_cols(fixture_btns_df, totalPathways = 200)
  expect_false("Diff_percent" %in% names(result))
  expect_false("Remain_percent" %in% names(result))
})

test_that("add_remain_and_diff_cols preserves original columns", {
  result <- add_remain_and_diff_cols(fixture_btns_df, totalPathways = 200)
  expect_true("Name" %in% names(result))
  expect_equal(result$Name, c("Step1", "Step2", "Step3"))
})

test_that("add_remain_and_diff_cols works with single row", {
  single_row <- dplyr::tibble(Name = "Only", Remain = 80)
  result <- add_remain_and_diff_cols(single_row, totalPathways = 100)

  # Diff = abs(100 - 80) = 20, Diff% = 20%
  expect_equal(result$Diff, "20 (20%)")
  expect_equal(result$Remain, "80 (80%)")
})

test_that("add_remain_and_diff_cols formats large numbers with comma separators", {
  big_df <- dplyr::tibble(Name = c("A", "B"), Remain = c(50000, 25000))
  result <- add_remain_and_diff_cols(big_df, totalPathways = 100000)

  expect_match(result$Diff[1], "50,000")
  expect_match(result$Remain[1], "50,000")
  expect_match(result$Remain[2], "25,000")
})

test_that("add_remain_and_diff_cols handles Remain equal to totalPathways", {
  df <- dplyr::tibble(Name = "Full", Remain = 500)
  result <- add_remain_and_diff_cols(df, totalPathways = 500)

  # Diff = abs(500 - 500) = 0, Diff% = 0%
  expect_equal(result$Diff, "0 (0%)")
  expect_equal(result$Remain, "500 (100%)")
})

test_that("add_remain_and_diff_cols handles Remain exceeding totalPathways", {
  df <- dplyr::tibble(Name = "Over", Remain = 150)
  result <- add_remain_and_diff_cols(df, totalPathways = 100)

  # Diff = abs(100 - 150) = 50, Diff% = 50%
  expect_equal(result$Diff, "50 (50%)")
  # Remain% = 150/100 * 100 = 150%
  expect_equal(result$Remain, "150 (150%)")
})

test_that("add_remain_and_diff_cols does not modify input data frame", {
  original <- dplyr::tibble(Name = c("A", "B"), Remain = c(80, 40))
  original_copy <- original
  add_remain_and_diff_cols(original, totalPathways = 100)
  expect_equal(original, original_copy)
})

test_that("add_remain_and_diff_cols handles empty data frame", {
  empty_df <- dplyr::tibble(Name = character(0), Remain = numeric(0))
  result <- add_remain_and_diff_cols(empty_df, totalPathways = 100)
  expect_equal(nrow(result), 0)
  expect_true("Diff" %in% names(result))
  expect_true("Remain" %in% names(result))
})

test_that("add_remain_and_diff_cols with totalPathways = 0 produces Inf/NaN", {
  df <- dplyr::tibble(Name = "A", Remain = 50)
  result <- add_remain_and_diff_cols(df, totalPathways = 0)
  # Division by zero: Diff_percent and Remain_percent become Inf or NaN
  # The function still returns without error, but percentages are Inf/NaN
  expect_type(result$Diff, "character")
  expect_type(result$Remain, "character")
  expect_match(result$Diff, "Inf|NaN")
  expect_match(result$Remain, "Inf")
})

test_that("add_remain_and_diff_cols with NA in Remain column", {
  df <- dplyr::tibble(Name = c("A", "B"), Remain = c(100, NA))
  result <- add_remain_and_diff_cols(df, totalPathways = 200)
  # NA propagates through arithmetic; formatted result will contain "NA"
  expect_type(result$Diff, "character")
  expect_type(result$Remain, "character")
  expect_match(result$Remain[2], "NA")
})

# ---------- customActionButton ----------

test_that("customActionButton returns a shiny.tag", {
  btn <- customActionButton("test-id", "My Label", "#ff0000")
  expect_s3_class(btn, "shiny.tag")
})

test_that("customActionButton includes the correct background-color in style", {
  btn <- customActionButton("test-id", "Click", "#1f77b4")
  html <- as.character(btn)
  expect_match(html, "background-color: #1f77b4", fixed = TRUE)
})

test_that("customActionButton uses default font_size of 10px", {
  btn <- customActionButton("test-id", "Click", "red")
  html <- as.character(btn)
  expect_match(html, "font-size: 10px", fixed = TRUE)
})

test_that("customActionButton uses custom font_size when provided", {
  btn <- customActionButton("test-id", "Click", "red", font_size = "20px")
  html <- as.character(btn)
  expect_match(html, "font-size: 20px", fixed = TRUE)
})

test_that("customActionButton wraps label in <strong> tag", {
  btn <- customActionButton("test-id", "My Label", "blue")
  html <- as.character(btn)
  expect_match(html, "<strong>My Label</strong>", fixed = TRUE)
})

test_that("customActionButton sets the correct id attribute", {
  btn <- customActionButton("my-button-id", "Label", "green")
  html <- as.character(btn)
  expect_match(html, 'id="my-button-id"', fixed = TRUE)
})

test_that("customActionButton produces a button element", {
  btn <- customActionButton("btn1", "Go", "#000")
  html <- as.character(btn)
  expect_match(html, "<button ")
})

test_that("customActionButton with NULL color includes NULL in style", {
  btn <- customActionButton("id", "label", NULL)
  html <- as.character(btn)
  expect_s3_class(btn, "shiny.tag")
  expect_match(html, "<button ")
})

test_that("customActionButton with special characters in label", {
  btn <- customActionButton("id", "<b>bold</b>", "#fff")
  html <- as.character(btn)
  expect_s3_class(btn, "shiny.tag")
  # The label is wrapped in <strong>, and Shiny escapes HTML in tag content
  expect_match(html, "<strong>")
})

# ---------- match_color ----------

test_that("match_color returns HTML for a single event name", {
  result <- match_color("Glipizide-txp", fixture_eventCodes)
  expect_type(result, "character")
  expect_match(result, "Glipizide-txp", fixed = TRUE)
  expect_match(result, "#1f77b4", fixed = TRUE)
  # Single name means no comma separator in output
  expect_false(grepl(",<button", result, fixed = TRUE))
})

test_that("match_color returns comma-separated HTML buttons for combo names", {
  result <- match_color("Metformin-txp,Simvastatin-txp", fixture_eventCodes)
  expect_match(result, "Metformin-txp", fixed = TRUE)
  expect_match(result, "Simvastatin-txp", fixed = TRUE)
  expect_match(result, "#ff7f0e", fixed = TRUE)  # Metformin color
  expect_match(result, "#2ca02c", fixed = TRUE)  # Simvastatin color
  # Two buttons separated by comma
  expect_match(result, ",", fixed = TRUE)
})

test_that("match_color output contains button HTML elements", {
  result <- match_color("Glipizide-txp", fixture_eventCodes)
  expect_match(result, "<button ")
  expect_match(result, "background-color:")
})

test_that("match_color uses the correct color per event name", {
  # Metformin-txp is code=2, color=#ff7f0e
  result <- match_color("Metformin-txp", fixture_eventCodes)
  expect_match(result, "#ff7f0e", fixed = TRUE)

  # Simvastatin-txp is code=4, color=#2ca02c
  result2 <- match_color("Simvastatin-txp", fixture_eventCodes)
  expect_match(result2, "#2ca02c", fixed = TRUE)
})

test_that("match_color produces one button per event name", {
  result <- match_color("Glipizide-txp,Metformin-txp,Simvastatin-txp", fixture_eventCodes)
  # Count the number of <button occurrences
  n_buttons <- lengths(regmatches(result, gregexpr("<button ", result)))
  expect_equal(n_buttons, 3)
})

test_that("match_color with non-existent name produces button with NA color", {
  result <- match_color("NonExistent-txp", fixture_eventCodes)
  # color lookup returns character(0), which becomes NA after unlist
  expect_type(result, "character")
  expect_match(result, "<button ")
  expect_match(result, "NonExistent-txp", fixed = TRUE)
  expect_match(result, "background-color: NA", fixed = TRUE)
})

test_that("match_color with empty string returns empty string", {
  # Empty name matches no rows, so colors is character(0).
  # lapply over seq_len(1) calls customActionButton with colors[1]=NA,
  # but unlist() on the result collapses to character(0), giving "".
  result <- match_color("", fixture_eventCodes)
  expect_type(result, "character")
  expect_equal(result, "")
})
