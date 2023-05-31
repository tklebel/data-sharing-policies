read_experiments <- function(path) {
  read_csv(path, skip = 6) %>% 
    tibble(.name_repair = "universal") %>% 
    mutate(across(contains("gini"), as.numeric))
}

setup_schema <- schema(
  `[run number]` = int64(), `initial-norm` = int64(), b_norm = int64(), 
  `sharing-incentive` = float64(), `application-penalty` = float64(), 
  `resources-dist` = utf8(), `proposal-sigma` = float64(), 
  `n-teams` = int64(), `third-party-funding-ratio` = int64(), 
  `utility-change` = float64(), b_utility = int64(), network = utf8(), 
  `funded-share` = float64(),`data-sharing?` = bool(), 
  `max-initial-utility` = int64(), `[step]` = int64(), 
  `gini [resources] of teams` = float64(), `gini [total-funding] of teams` = float64(), 
  `mean [effort] of teams` = float64(), `%-sharing` = int64(), 
  `mean-funding-within teams with [initial-resources-quantile = "q1"]` = float64(), 
  `mean-funding-within teams with [initial-resources-quantile = "q2"]` = float64(), 
  `mean-funding-within teams with [initial-resources-quantile = "q3"]` = float64(), 
  `mean-funding-within teams with [initial-resources-quantile = "q4"]` = float64(),
  `data-sharing-within teams with [initial-resources-quantile = "q1"]` = float64(), 
  `data-sharing-within teams with [initial-resources-quantile = "q2"]` = float64(), 
  `data-sharing-within teams with [initial-resources-quantile = "q3"]` = float64(), 
  `data-sharing-within teams with [initial-resources-quantile = "q4"]` = float64()
)

select_baseline <- function(df) {
  df %>% 
    select(run_number = `[run number]`, init_dist = `resources-dist`, network, 
           proposal_sigma = `proposal-sigma`,
           funded_share = `funded-share`, step = `[step]`, 
           max_initial_utility = `max-initial-utility`,
           resources_gini = `gini [resources] of teams`,
           total_funding_gini = `gini [total-funding] of teams`,
           mean_effort = `mean [effort] of teams`, perc_sharing = `%-sharing`,
           mean_funds_q1 = `mean-funding-within teams with [initial-resources-quantile = "q1"]`,
           mean_funds_q2 = `mean-funding-within teams with [initial-resources-quantile = "q2"]`,
           mean_funds_q3 = `mean-funding-within teams with [initial-resources-quantile = "q3"]`,
           mean_funds_q4 = `mean-funding-within teams with [initial-resources-quantile = "q4"]`,
           data_sharing_q1 = `data-sharing-within teams with [initial-resources-quantile = "q1"]`,
           data_sharing_q2 = `data-sharing-within teams with [initial-resources-quantile = "q2"]`,
           data_sharing_q3 = `data-sharing-within teams with [initial-resources-quantile = "q3"]`,
           data_sharing_q4 = `data-sharing-within teams with [initial-resources-quantile = "q4"]`,
    )
}

select_intervention <- function(df) {
  df %>% 
    select(run_number = `[run number]`, init_dist = `resources-dist`, network, 
           proposal_sigma = `proposal-sigma`,
           sharing_incentive = `sharing-incentive`,
           max_initial_utility = `max-initial-utility`,
           funded_share = `funded-share`, step = `[step]`, 
           resources_gini = `gini [resources] of teams`,
           total_funding_gini = `gini [total-funding] of teams`,
           mean_effort = `mean [effort] of teams`, perc_sharing = `%-sharing`,
           mean_funds_q1 = `mean-funding-within teams with [initial-resources-quantile = "q1"]`,
           mean_funds_q2 = `mean-funding-within teams with [initial-resources-quantile = "q2"]`,
           mean_funds_q3 = `mean-funding-within teams with [initial-resources-quantile = "q3"]`,
           mean_funds_q4 = `mean-funding-within teams with [initial-resources-quantile = "q4"]`,
           data_sharing_q1 = `data-sharing-within teams with [initial-resources-quantile = "q1"]`,
           data_sharing_q2 = `data-sharing-within teams with [initial-resources-quantile = "q2"]`,
           data_sharing_q3 = `data-sharing-within teams with [initial-resources-quantile = "q3"]`,
           data_sharing_q4 = `data-sharing-within teams with [initial-resources-quantile = "q4"]`
    )
}

schema_funder_selectivity <- schema(
  `[run number]` = int64(), `initial-norm` = int64(), b_norm = int64(), 
  `sharing-incentive` = float64(), `application-penalty` = float64(), 
  `resources-dist` = utf8(), `proposal-sigma` = float64(), 
  `n-teams` = int64(), `third-party-funding-ratio` = int64(), 
  `utility-change` = float64(), b_utility = int64(), network = utf8(), 
  `funded-share` = float64(),`data-sharing?` = bool(), 
  `max-initial-utility` = int64(), `[step]` = int64(), 
  `gini [resources] of teams` = float64(), `gini [total-funding] of teams` = float64(), 
  `mean [effort] of teams` = float64(), `%-sharing` = int64()
)

select_funder_selectivity <- function(df) {
  df %>% 
    select(run_number = `[run number]`, 
           max_initial_utility = `max-initial-utility`,
           funded_share = `funded-share`, step = `[step]`, 
           resources_gini = `gini [resources] of teams`,
           total_funding_gini = `gini [total-funding] of teams`,
           mean_effort = `mean [effort] of teams`, perc_sharing = `%-sharing`
    )
}


schema_individual_level_data <- schema(
  `[run number]` = int64(), `initial-norm` = int64(), b_norm = int64(), 
  `sharing-incentive` = float64(), `application-penalty` = float64(), 
  `resources-dist` = utf8(), `proposal-sigma` = float64(), 
  `n-teams` = int64(), `third-party-funding-ratio` = int64(), 
  `utility-change` = float64(), b_utility = int64(), network = utf8(), 
  `funded-share` = float64(),`data-sharing?` = bool(), 
  `max-initial-utility` = int64(), `[step]` = int64(),
  `individual-data` = string()
)



unnest_individual_data <- function(df, col = `individual-data`) {
  num_cols <- c("who", "initial_resources", "resources", "total_funding",
                "effort")
  logi_col <- "data_sharing"
  all_cols <- c(num_cols, logi_col)
  
  df %>% 
    mutate(ind_data = str_remove_all({{col}}, "(^\\[\\[)|(\\]\\]$)")) %>% 
    separate(ind_data, paste0("team", 1:100), sep = "\\] \\[") %>% 
    pivot_longer(starts_with("team"), names_to = "team", values_to = "vals") %>% 
    separate(vals, all_cols, sep = "\\s") %>% 
    mutate(across(all_of(num_cols), as.numeric),
           across(all_of(logi_col), as.logical)) %>% 
    select(-team, -`individual-data`)
}


re_arrange <- function(df) {
  num_cols <- c("who", "initial_resources", "resources", "total_funding",
                "effort")
  logi_col <- "data_sharing"
  all_cols <- c(num_cols, logi_col)
  
  df <- dplyr::mutate(df, ind_data = stringr::str_remove_all(individualdata, "(^\\[\\[)|(\\]\\]$)"))
  df <- tidyr::separate(df, ind_data, paste0("team", 1:100), sep = "\\] \\[")
  df <- tidyr::pivot_longer(df, tidyselect::starts_with("team"), names_to = "team", values_to = "vals")
  df <- tidyr::separate(df, vals, all_cols, sep = "\\s")
  df <- dplyr::mutate(df, dplyr::across(tidyselect::all_of(num_cols), as.numeric),
                      dplyr::across(tidyselect::all_of(logi_col), as.logical))
  df <- dplyr::select(df, -team, -individualdata)
  df
}

