library(targets)
library(tarchetypes)

source("R/functions.R")

options(tidyverse.quiet = TRUE)
tar_option_set(packages = c("scales", "tidyverse", "hrbrthemes"))

list(
  # baseline file -----------
  tar_target(
    baseline_file,
    "../outputs/data_sharing_policies baseline-table-3.csv",
    format = "file"
  ),
  tar_target(
    baseline,
    read_experiments(baseline_file),
    format = "feather"
  ),
  tar_target(
    baseline_selection,
    select_baseline(baseline),
    format = "feather"
  ),
  tarchetypes::tar_quarto(baseline_report, "01-analyse-baseline.qmd")
)
