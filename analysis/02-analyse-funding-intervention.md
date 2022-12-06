---
title: "Analyse funding intervention"
format: 
  html:
    code-fold: true
execute:
  keep-md: true
---


::: {.cell}

:::


# Effect of sharing incentive
There are multiple parameters varied in this experiment. For now we compare
Gini and share of sharers for low and medium funded share, holding network type
constant.


::: {.cell}

```{.r .cell-code}
no_network <- df %>% 
  filter(network == "none", funded_share == 25)

pdata <- no_network %>% 
  group_by(step, sharing_incentive) %>% 
  summarise(mean_gini = mean(resources_gini),
            mean_sharing = mean(perc_sharing))

p1 <- pdata %>%  
  ggplot(aes(step, mean_gini, colour = as.factor(sharing_incentive))) +
  geom_line() +
    labs(colour = "Incentive for sharing data",
       y = "Gini of resources")

p2 <- pdata %>%  
  ggplot(aes(step, mean_sharing, colour = as.factor(sharing_incentive))) +
  geom_line() +
  labs(colour = "Incentive for sharing data",
       y = "% of groups sharing data") 

p1 / p2 +
  plot_layout(guides = "collect") & theme(legend.position = "top")
```

::: {.cell-output-display}
![Gini index and % of groups sharing data dependant on funding incentive. The share of teams being funded is fixed at 25%.](02-analyse-funding-intervention_files/figure-html/fig-vary-sharing-incentive-1.png){#fig-vary-sharing-incentive width=864}
:::
:::


This is very interesting. The incentive for sharing data has a substantial 
influence on whether agents share data or not. With no incentive, only about 25%
of groups share data (which is still high? They "should not" share data, given
that it is costly?). However, once incentives are higher than 0.2, differences
are not strong any more in how many groups share (between 62 and 75% of teams).

However, there is a substanial effect on the Gini. Stronger incentives lead to
more equitable resource distributions. Why is that? Presumably there is more 
mixing: some groups are successful with, and some without sharing data, and this
changes. When there is no incentive, than there is probably more path dependency
in funding.

# Interact funded share and funding incentive

::: {.cell}

```{.r .cell-code}
no_network <- df %>% 
  filter(network == "none")

pdata <- no_network %>% 
  select(run_number, sharing_incentive, funded_share, step, perc_sharing, 
         resources_gini) %>% 
  group_by(sharing_incentive, funded_share, step) %>% 
  summarise(mean_gini = mean(resources_gini),
            mean_sharing = mean(perc_sharing)) %>% 
  pivot_longer(c(mean_gini, mean_sharing)) %>% 
  mutate(sharing_incentive = as.factor(sharing_incentive))

p_gini <- pdata %>% 
  filter(name == "mean_gini") %>% 
  ggplot(aes(step, value, colour = sharing_incentive)) +
  geom_line() +
  facet_wrap(vars(funded_share), ncol = 1) +
  labs(y = "Mean Gini")

p_sharing <- pdata %>% 
  filter(name == "mean_sharing") %>% 
  ggplot(aes(step, value, colour = sharing_incentive)) +
  geom_line() +
  facet_wrap(vars(funded_share), ncol = 1) +
  labs(y = "Mean % of teams sharing data")

p_sharing + p_gini +
  plot_layout(guides = "collect") +
  plot_annotation(tag_levels = "A") &
  theme(legend.position = "top")
```

::: {.cell-output-display}
![Effect of funding incentive on (A) rate of sharing and (B) Gini coefficient. The rows represent the varying rate of funded teams in %. Uniform starting distribution.](02-analyse-funding-intervention_files/figure-html/fig-incentive-funded-share-1.png){#fig-incentive-funded-share width=960}
:::
:::


The results are fascinating. First, a high incentive for sharing, as implemented
in our model, does not seem either (a) necessary nor (b) the best strategy to
achieve high sharing.

Considering the case of 10% teams funded each round: Sharing uptake is equally 
quick regardless of incentive. Sharing has a higher equilibrium the higher the
sharing incentive is. Equity is higher (lower Gini) for higher sharing 
incentives. The same is true for the case of 25% funded teams, however the share
of teams sharing data is higher. This is likely a result of more teams coming 
into contact with the funder. Interestingly, although the rate of teams sharing
data under no incentive is similar across both cases, equity is higher for the
case of 25% funded teams. (Ok, this is trivial -> more teams are receiving 
funding -> more equality).

However, once we consider the case of 50% of teams being funded each round,
dynamics change substantially. Gini is lower, in line with more teams being
funded. Higher incentives still lead to higher rates of sharing over the long
term. The rate of uptake however is very different and much slower for higher
sharing incentives. When taken to its extreme (80% of teams funded each round),
uptake of sharing is so slow it does not really happen within the 3000
iterations.

One open question to investigate is why equity is higher for higher sharing
incentives. This might be because there might be more randomness in how 
proposals are evaluated. But this needs to be checked in greater detail, i.e., 
how this edge case works in the nitty-gritty details.

# Network effects
Investigate network effects for cases of 10% and 50% funded teams.


::: {.cell}

```{.r .cell-code}
pdata <- df %>% 
  filter(funded_share %in% c(10, 50)) %>% 
  select(run_number, sharing_incentive, funded_share, step, perc_sharing, 
         resources_gini, network) %>% 
  group_by(sharing_incentive, funded_share, network, step) %>% 
  summarise(mean_gini = mean(resources_gini),
            mean_sharing = mean(perc_sharing)) %>% 
  pivot_longer(c(mean_gini, mean_sharing)) %>% 
  mutate(sharing_incentive = as.factor(sharing_incentive))

p_gini <- pdata %>% 
  filter(name == "mean_gini", funded_share == 10) %>% 
  ggplot(aes(step, value, colour = sharing_incentive)) +
  geom_line() +
  facet_wrap(vars(network), ncol = 1) +
  labs(y = "Mean Gini")

p_sharing <- pdata %>% 
  filter(name == "mean_sharing", funded_share == 10) %>% 
  ggplot(aes(step, value, colour = sharing_incentive)) +
  geom_line() +
  facet_wrap(vars(network), ncol = 1) +
  labs(y = "Mean % of teams sharing data")

p_sharing + p_gini +
  plot_layout(guides = "collect") +
  plot_annotation(tag_levels = "A") &
  theme(legend.position = "top")
```

::: {.cell-output-display}
![Effect of funding incentive on (A) rate of sharing and (B) Gini coefficient. The rows represent the network configurations. Uniform starting distribution. 10% funded teams.](02-analyse-funding-intervention_files/figure-html/fig-incentive-network-10perc-1.png){#fig-incentive-network-10perc width=960}
:::
:::

::: {.cell}

```{.r .cell-code}
p_gini <- pdata %>% 
  filter(name == "mean_gini", funded_share == 50) %>% 
  ggplot(aes(step, value, colour = sharing_incentive)) +
  geom_line() +
  facet_wrap(vars(network), ncol = 1) +
  labs(y = "Mean Gini")

p_sharing <- pdata %>% 
  filter(name == "mean_sharing", funded_share == 50) %>% 
  ggplot(aes(step, value, colour = sharing_incentive)) +
  geom_line() +
  facet_wrap(vars(network), ncol = 1) +
  labs(y = "Mean % of teams sharing data")

p_sharing + p_gini +
  plot_layout(guides = "collect") +
  plot_annotation(tag_levels = "A") &
  theme(legend.position = "top")
```

::: {.cell-output-display}
![Effect of funding incentive on (A) rate of sharing and (B) Gini coefficient. The rows represent the network configurations. Uniform starting distribution. 50% funded teams.](02-analyse-funding-intervention_files/figure-html/fig-incentive-network-50perc-1.png){#fig-incentive-network-50perc width=960}
:::
:::



In a general sense, the presence of networks leads to lower sharing rates in the
long run. For the case of 10% funded teams, there is a strong pendulum at first,
with sharing going up and down. In the long run, all sharing incentives lead to
relatively low sharing rates (below 30%). Might it be that the network effect
trumps the utility assessment that each team does? If I implemented it 
correctly, network and utility effect should be equally strong. 

For the case of 50% funded teams, sharing uptake is much slower. This is likely
driven to some extent because sharing is at 0 when starting the simulation. This
is on purpose and represents a realistic scenario.

# Uptake across quartiles

# Open questions

- Why is a higher sharing incentive leading to lower Gini? 
