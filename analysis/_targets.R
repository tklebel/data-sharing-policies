library(targets)
library(tarchetypes)
library(dplyr)
library(arrow)

source("R/functions.R")

options(tidyverse.quiet = TRUE)
#tar_option_set(packages = c("scales", "tidyverse", "hrbrthemes"))


  # # baseline file -----------
  # tar_target(
  #   baseline_file,
  #   "../outputs/baseline.csv",
  #   format = "file"
  # ),
  # tarchetypes::tar_quarto(baseline_report, "01-analyse-baseline.qmd"),
  # # funding intervention -----------
  # tar_target(
  #   intervention_file,
  #   "../outputs/data_sharing_policies vary_incentives-table-5.csv",
  #   format = "file"
  # ),
  # tarchetypes::tar_quarto(funding_intervention, "02-analyse-funding-intervention.qmd"),
  # # funding intervention -----------
  # tar_target(
  #   selectivity_file,
  #   "../outputs/data_sharing_policies funder-selectivity-table-2.csv",
  #   format = "file"
  # ),
  # tarchetypes::tar_quarto(funder_selectivity, "03-analyse-funder-selectivity.qmd"),
  # # retaining individual level data ------
  # tar_target(
  #   individual_level_file,
  #   "../outputs/data_sharing_policies baseline_individual_level_data-table 2.csv",
  #   format = "file"
  # )
funder_selectivity_values <- tibble::tibble(
  sharing_incentive = seq(0, .7, by = .1)
)

target1 <- tar_quarto_rep(funder_selectivity,
                          "analysis/03-analyse-funder-selectivity.qmd",
                          execute_params = funder_selectivity_values)

individual_data_values <- funder_selectivity_values 

target2 <- tar_quarto_rep(individual_data,
                          "analysis/04-funder-selectivity-individual-data.qmd",
                          execute_params = individual_data_values)


list(target1, target2)
