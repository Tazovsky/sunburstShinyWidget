# Helper: load sample data fixtures for tests
# These are used across multiple test files

library(dplyr)

# Load real sample data from the package's data/ directory
data_dir <- file.path(testthat::test_path(), "..", "..", "data")

if (dir.exists(data_dir)) {
  sample_chartData <- jsonlite::fromJSON(
    file.path(data_dir, "chartData.json"),
    simplifyVector = FALSE
  )
  sample_design <- jsonlite::fromJSON(
    file.path(data_dir, "design.json"),
    simplifyVector = FALSE
  )
} else {
  sample_chartData <- NULL
  sample_design <- NULL
}

# Minimal eventCodes fixture (as a data frame, like bind_rows() produces)
fixture_eventCodes <- dplyr::tibble(
  code = c(1L, 2L, 4L, 3L, 6L),
  name = c("Glipizide-txp", "Metformin-txp", "Simvastatin-txp",
           "Glipizide-txp,Metformin-txp", "Metformin-txp,Simvastatin-txp"),
  isCombo = c(FALSE, FALSE, FALSE, TRUE, TRUE),
  color = c("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd")
)

# Minimal btns_df fixture for add_remain_and_diff_cols tests
fixture_btns_df <- dplyr::tibble(
  Name = c("Step1", "Step2", "Step3"),
  Remain = c(100, 60, 25)
)
