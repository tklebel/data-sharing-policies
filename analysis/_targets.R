library(targets)
library(tarchetypes)
library(arrow)

source("R/functions.R")

options(tidyverse.quiet = TRUE)
tar_option_set(packages = c("scales", "tidyverse", "hrbrthemes"))

list(
  # baseline file -----------
  tar_target(
    baseline_file,
    "../outputs/baseline.csv",
    format = "file"
  ),
  tarchetypes::tar_quarto(baseline_report, "01-analyse-baseline.qmd"),
  # funding intervention -----------
  tar_target(
    intervention_file,
    "../outputs/data_sharing_policies vary_incentives-table-5.csv",
    format = "file"
  ),
  tarchetypes::tar_quarto(funding_intervention, "02-analyse-funding-intervention.qmd"),
  # funding intervention -----------
  tar_target(
    selectivity_file,
    "../outputs/data_sharing_policies funder-selectivity-table-2.csv",
    format = "file"
  ),
  tarchetypes::tar_quarto(funder_selectivity, "03-analyse-funder-selectivity.qmd"),
  # retaining individual level data ------
  tar_target(
    individual_level_file,
    "../outputs/data_sharing_policies baseline_individual_level_data-table 2.csv",
    format = "file"
  )
)
