---
title: "Baseline analysis"
format: 
  html:
    code-fold: true
  #pdf: default
execute:
  keep-md: true
---


::: {.cell}

:::


# Effect of grant size


::: {.cell}

```{.r .cell-code}
no_network <- df %>% 
  filter(network == "none")
  
no_network_unif_dist <- no_network %>% 
  filter(init_dist == "uniform",
         max_initial_utilitiy == -4)


pdata <- no_network_unif_dist %>% 
  group_by(step, funded_share) %>% 
  summarise(mean_gini = mean(resources_gini),
            mean_cumulative_gini = mean(total_funding_gini),
            mean_sharing = mean(perc_sharing)) %>% 
  collect()

p1 <- pdata %>%  
  ggplot(aes(step, mean_gini, colour = as.factor(funded_share))) +
  geom_line() +
    labs(colour = "% of groups receiving funding",
       y = "Gini of current resources")

p2 <- pdata %>%  
  ggplot(aes(step, mean_cumulative_gini, colour = as.factor(funded_share))) +
  geom_line() +
    labs(colour = "% of groups receiving funding",
       y = "Gini of total resources")

p3 <- pdata %>%  
  ggplot(aes(step, mean_sharing, colour = as.factor(funded_share))) +
  geom_line() +
  labs(colour = "% of groups receiving funding",
       y = "% of groups sharing data") 

p1 / p2 / p3 +
  plot_layout(guides = "collect") +
  plot_annotation(tag_levels = "A") & theme(legend.position = "top")
```

::: {.cell-output .cell-output-stderr}
```
Warning: Removed 5 rows containing missing values (`geom_line()`).
```
:::

::: {.cell-output-display}
![Gini index and % of groups sharing data dependent on grant size](01-analyse-baseline_files/figure-html/fig-vary-share-of-funded-teams-1.png){#fig-vary-share-of-funded-teams width=864}
:::
:::


Both Gini indexes (Panels A and B of @fig-vary-share-of-funded-teams) are very
stable after an initial adaptation, and reflect the general level of selectivity
of research funding: low selectivity leads to low inequality of resources and
vice versa.

The percentage of teams sharing data is not affected by the selectivity of
funding. Regardless of funding selectivity, about 20% of agents share data in 
the long run. 

> Is this an expected finding based on the model setup? Given that there are 
costs to sharing data, shouldn't all teams stop sharing?

## Effect of initial utility levels

::: {.cell}

```{.r .cell-code}
no_network <- df %>% 
  filter(network == "none")
  
no_network_unif_dist <- no_network %>% 
  filter(init_dist == "uniform", funded_share == 50)


pdata <- no_network_unif_dist %>% 
  group_by(step, max_initial_utilitiy) %>% 
  summarise(mean_gini = mean(resources_gini),
            mean_cumulative_gini = mean(total_funding_gini),
            mean_sharing = mean(perc_sharing)) %>% 
  collect()

p1 <- pdata %>%  
  ggplot(aes(step, mean_gini, colour = as.factor(max_initial_utilitiy))) +
  geom_line() +
  labs(colour = "Initial utilitily",
       y = "Gini of current resources")

p2 <- pdata %>%  
  ggplot(aes(step, mean_cumulative_gini, colour = as.factor(max_initial_utilitiy))) +
  geom_line() +
  labs(colour = "Initial utilitily",
       y = "Gini of total resources")

p3 <- pdata %>%  
  ggplot(aes(step, mean_sharing, colour = as.factor(max_initial_utilitiy))) +
  geom_line() +
  labs(colour = "Initial utilitily",
       y = "% of groups sharing data") 

p1 / p2 / p3 +
  plot_layout(guides = "collect") +
  plot_annotation(tag_levels = "A") & theme(legend.position = "top")
```

::: {.cell-output .cell-output-stderr}
```
Warning: Removed 5 rows containing missing values (`geom_line()`).
```
:::

::: {.cell-output-display}
![Gini index and % of groups sharing data dependent on initial utility](01-analyse-baseline_files/figure-html/fig-vary-utility-1.png){#fig-vary-utility width=864}
:::
:::


Initial utility settings have no meaningful effect on the equality of resources.
Data sharing is initially higher for higher initial utility, which is as 
expected. However, it is unclear why data sharing occurs at all, given that 
there are no incentives and data sharing is a costly activity.


## Comparing network effects


::: {.cell}

```{.r .cell-code}
uniform <- df %>% 
  filter(init_dist == "uniform", max_initial_utilitiy == 4)

pdata <- uniform %>% 
  select(run_number, network, funded_share, step, perc_sharing, resources_gini,
         total_funding_gini) %>% 
  group_by(network, funded_share, step) %>% 
  summarise(mean_gini = mean(resources_gini),
            mean_cumulative_gini = mean(total_funding_gini),
            mean_sharing = mean(perc_sharing)) %>% 
  collect() %>% 
  pivot_longer(c(mean_gini, mean_sharing, mean_cumulative_gini))

p_gini <- pdata %>% 
  filter(name == "mean_cumulative_gini") %>% 
  ggplot(aes(step, value, colour = network)) +
  geom_line() +
  facet_wrap(vars(funded_share), ncol = 1) +
  labs(y = "Mean Gini of total resources")

p_sharing <- pdata %>% 
  filter(name == "mean_sharing") %>% 
  ggplot(aes(step, value, colour = network)) +
  geom_line() +
  facet_wrap(vars(funded_share), ncol = 1) +
  labs(y = "Mean % of teams sharing data")

p_sharing + p_gini +
  plot_layout(guides = "collect") +
  plot_annotation(tag_levels = "A") &
  theme(legend.position = "top")
```

::: {.cell-output .cell-output-stderr}
```
Warning: Removed 3 rows containing missing values (`geom_line()`).
```
:::

::: {.cell-output-display}
![Effect of networks on (A) rate of sharing and (B) Gini coefficient of total resources. The rows represent the varying rate of funded teams in %. Uniform starting distribution, uniform initial utility (up to 4).](01-analyse-baseline_files/figure-html/fig-network-effect-1.png){#fig-network-effect width=960}
:::
:::


The red lines in @fig-network-effect correspond to @fig-vary-share-of-funded-teams.
It is clear that with network effects and without any incentives, data sharing
is very low. This is unaffected by the funder selectivity.
The Gini of total resources is therefore stable across different rates of funder
selectivity. 

## Effect on success of different groups


::: {.cell}

```{.r .cell-code}
group_success <- df %>% 
  filter(max_initial_utilitiy %in% c(-4, 0, 4)) %>% 
  group_by(step, funded_share, max_initial_utilitiy) %>% 
  summarise(across(contains("mean_funds"), .fns = mean)) %>% 
  collect()
```
:::

::: {.cell}

```{.r .cell-code}
pdata <- group_success %>% 
  pivot_longer(contains("mean_funds"), names_to = "quantile",
               names_pattern = ".*_(q\\d)")

pdata %>% 
  ggplot(aes(step, value, colour = quantile)) +
  geom_line() +
  facet_grid(rows = vars(funded_share),
             cols = vars(max_initial_utilitiy)) +
  guides(colour = guide_legend(reverse = TRUE)) +
  labs(y = "Total funding acquired", colour = "Initial resource quantile") +
  theme(legend.position = "top")
```

::: {.cell-output-display}
![Mean total resources by initial resource quantile with no network. Higher quantiles (e.g., q4) had initially higher levels of funding.](01-analyse-baseline_files/figure-html/fig-resources-by-quantile-1.png){#fig-resources-by-quantile width=768}
:::
:::

With the current settings on randomness in the proposal generation
(proposal-sigma = 0.15), the distribution of resources exhibits dynamics of 
cumulative advantage under selective funding regimes. With only 10% of teams
being receiving funding each round, teams that initially had more funding than
others (fourth quantile, "q4") acquire substantially more funding over the
course of the simulation. This effect is much weaker for less selective funding
regimes.


Below we provide the same for a random
network (@fig-resources-by-quantile-random-network), and for a small-world
network (@fig-resources-by-quantile-small-world-network). Without having 
compared them precisely, results look identical. (To establish this more 
formally, one could restructure the plots and directly compare the network vs.
non-network part).


::: {.cell}

```{.r .cell-code}
group_success <- df %>% 
  filter(network == "random", max_initial_utilitiy %in% c(-4, 0, 4)) %>% 
  group_by(step, funded_share, max_initial_utilitiy) %>% 
  summarise(across(contains("mean_funds"), .fns = mean)) %>% 
  collect()

pdata <- group_success %>% 
  pivot_longer(contains("mean_funds"), names_to = "quantile",
               names_pattern = ".*_(q\\d)")

pdata %>% 
  ggplot(aes(step, value, colour = quantile)) +
  geom_line() +
  facet_grid(rows = vars(funded_share),
             cols = vars(max_initial_utilitiy)) +
  guides(colour = guide_legend(reverse = TRUE)) +
  labs(y = "Total funding acquired", colour = "Initial resource quantile") +
  theme(legend.position = "top")
```

::: {.cell-output-display}
![Mean resources by initial resource quantile with random network](01-analyse-baseline_files/figure-html/fig-resources-by-quantile-random-network-1.png){#fig-resources-by-quantile-random-network width=768}
:::
:::

::: {.cell}

```{.r .cell-code}
group_success <- df %>% 
  filter(network == "small-world", max_initial_utilitiy %in% c(-4, 0, 4)) %>% 
  group_by(step, funded_share, max_initial_utilitiy) %>% 
  summarise(across(contains("mean_funds"), .fns = mean)) %>% 
  collect()

pdata <- group_success %>% 
  pivot_longer(contains("mean_funds"), names_to = "quantile",
               names_pattern = ".*_(q\\d)")

pdata %>% 
  ggplot(aes(step, value, colour = quantile)) +
  geom_line() +
  facet_grid(rows = vars(funded_share),
             cols = vars(max_initial_utilitiy)) +
  guides(colour = guide_legend(reverse = TRUE)) +
  labs(y = "Total funding acquired", colour = "Initial resource quantile") +
  theme(legend.position = "top")
```

::: {.cell-output-display}
![Mean resources by initial resource quantile with small-world network](01-analyse-baseline_files/figure-html/fig-resources-by-quantile-small-world-network-1.png){#fig-resources-by-quantile-small-world-network width=768}
:::
:::


## Which quantiles share data?

::: {.cell}

```{.r .cell-code}
team_sharing <- df %>% 
  filter(network == "none", max_initial_utilitiy %in% c(-4, 0, 4)) %>% 
  group_by(step, funded_share, max_initial_utilitiy) %>% 
  summarise(across(contains("data_sharing"), .fns = mean)) %>% 
  collect()

pdata <- team_sharing %>% 
  pivot_longer(contains("data_sharing"), names_to = "quantile",
               names_pattern = ".*_(q\\d)")

pdata %>% 
  ggplot(aes(step, value, colour = quantile)) +
  geom_line(alpha = .8) +
  facet_grid(rows = vars(funded_share),
             cols = vars(max_initial_utilitiy)) +
  guides(colour = guide_legend(reverse = TRUE)) +
  labs(y = "% of teams sharing data", colour = "Initial resource quantile") +
  theme(legend.position = "top")
```

::: {.cell-output-display}
![Mean % of teams sharing by initial resource quantile with no network. Rows represent the % of teams receiving sharing.](01-analyse-baseline_files/figure-html/fig-sharing-by-quantile-no-network-1.png){#fig-sharing-by-quantile-no-network width=768}
:::
:::



There are no big differences visible in @fig-sharing-by-quantile-no-network 
regarding which teams take up sharing. If anything, under competitive funding,
top and bottom quartiles are sharing data less initially, but this largely 
equals out over time (except for the top right box, with competitive funding and
completely uniform initial utility). 

There are somewhat larger differences for the case of non-competitive funding
(bottom row), but given that this is quite an unrealistic case, I don't think
it is meaningful to discuss this further.
