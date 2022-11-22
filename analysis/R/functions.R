read_experiments <- function(path) {
  read_csv(path, skip = 6) %>% 
    tibble(.name_repair = "universal") %>% 
    mutate(across(contains("gini"), as.numeric))
}

select_baseline <- function(df) {
  df %>% 
    select(run_number = .run.number., init_dist = resources.dist, network, 
           funded_share = funded.share, step = .step., 
           resources_gini = gini..resources..of.teams,
           mean_effort = mean..effort..of.teams, perc_sharing = ..sharing,
           mean_funds_q1 = mean.funding.within.teams.with..initial.resources.quantile....q1..,
           mean_funds_q2 = mean.funding.within.teams.with..initial.resources.quantile....q2..,
           mean_funds_q3 = mean.funding.within.teams.with..initial.resources.quantile....q3..,
           mean_funds_q4 = mean.funding.within.teams.with..initial.resources.quantile....q4..,
           )
}

select_intervention <- function(df) {
  df %>% 
    select(run_number = .run.number., init_dist = resources.dist, network, 
           sharing_incentive = sharing.incentive,
           funded_share = funded.share, step = .step., 
           resources_gini = gini..resources..of.teams,
           mean_effort = mean..effort..of.teams, perc_sharing = ..sharing,
           mean_funds_q1 = mean.funding.within.teams.with..initial.resources.quantile....q1..,
           mean_funds_q2 = mean.funding.within.teams.with..initial.resources.quantile....q2..,
           mean_funds_q3 = mean.funding.within.teams.with..initial.resources.quantile....q3..,
           mean_funds_q4 = mean.funding.within.teams.with..initial.resources.quantile....q4..,
    )
}