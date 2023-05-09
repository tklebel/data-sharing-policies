library(targets)
library(tarchetypes)
library(arrow)

source("R/functions.R")

options(tidyverse.quiet = TRUE)
tar_option_set(packages = c("scales", "tidyverse", "hrbrthemes"))

list(
  # baseline file -----------
  # tar_target(
  #   baseline_file,
  #   "../outputs/data_sharing_policies baseline-table.csv",
  #   format = "file"
  # ),
  tarchetypes::tar_quarto(baseline_report, "01-analyse-baseline.qmd"),
  # funding intervention -----------
  # tar_target(
  #   intervention_file,
  #   "../outputs/data_sharing_policies vary_incentives-table.csv",
  #   format = "file"
  # ),
  tarchetypes::tar_quarto(funding_intervention, "02-analyse-funding-intervention.qmd")
)
