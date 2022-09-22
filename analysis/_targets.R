library(targets)
library(tarchetypes)

source("R/functions.R")

options(tidyverse.quiet = TRUE)
tar_option_set(packages = c("scales", "tidyverse", "hrbrthemes"))

list(
  # baseline file -----------
  tar_target(
    baseline_file,
    "../outputs/data_sharing_policies baseline-table-2.csv",
    format = "file"
  ),
  tar_target(
    baseline,
    read_experiments(baseline_file), 
    format = "feather"
  ),
  tar_quarto(baseline_report, "01-analyse-baseline.qmd")
)
