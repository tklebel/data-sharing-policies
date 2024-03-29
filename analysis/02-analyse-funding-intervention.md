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


All plotted data represents the average over 50 runs per condition.

# Effect of funder selectivity

::: {.cell}

```{.r .cell-code}
no_network <- df %>% 
  filter(network == "none")
  
no_network_unif_dist <- no_network %>% 
  filter(init_dist == "uniform", max_initial_utility == -3)


pdata <- no_network_unif_dist %>% 
  filter(sharing_incentive == .4) %>% 
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

::: {.cell-output-display}
![Gini index and % of groups sharing data dependent on grant size. Funding incentive is fixed at 0.4.](02-analyse-funding-intervention_files/figure-html/fig-vary-share-of-funded-teams-1.png){#fig-vary-share-of-funded-teams width=576}
:::
:::

The above is very interesting: we are not changing incentives, however sharing 
rate still varies widely. This is a consequence of how exposed agents are to
the funding agency. A little counterintuitively, a low rate of funded teams leads 
to quicker uptake of data sharing. With 50% of teams being funded, uptake is 
much slower, but reaches higher levels overall (up to 70% of teams, compared to
about 50% of teams for 15% funded teams). If almost everyone is funded (85% 
funded teams), uptake seems to be low.

All of this is when starting out with quite low settings on individual utility.
Since the simulation depends strongly on this initial setting (see baseline 
report), a higher initial effort setting also leads to higher sharing under very
un-competitive funding regimes. This is part of a broader dynamic that I have 
explored interactively: stronger incentives/wider share of funded teams are able
to push sharing higher up, but only under the precondition that teams are 
already sharing. Introducing strong incentives or wide dissemination of funding
that is tied to sharing without teams already sharing data leads to low rates,
presumably because the cost of taking up sharing is too high in an environment
where others are not sharing and still being funded. Competition seems therefore
necessary to ignite the behaviour desired by the policy.

Regarding the inequality of total resources (panel B in 
@fig-vary-share-of-funded-teams), his is obviously tied to funding selectivity
to some extent. Interestingly, with 50% of teams being funded, inequality drops
in the first part of the run, but rises again later. The same is true to a 
lesser extent for the more competitive version. One potential explanation, to be
confirmed down below: as data sharing is being taken up, inequality declines 
because there are multiple ways of receiving funding (by sharing or non-sharing),
but this initial re-arranging loses its force once teams are separated into more
and less successful clusters, where in the long run, more successful clusters
share data (under the incentives regime).

# Effect of sharing incentive

::: {.cell}

```{.r .cell-code}
no_network <- df %>% 
  filter(network == "none", funded_share == .15, max_initial_utility == -3)

pdata <- no_network %>% 
  group_by(step, sharing_incentive) %>% 
  summarise(mean_gini = mean(resources_gini),
            mean_cumulative_gini = mean(total_funding_gini),
            mean_sharing = mean(perc_sharing)) %>% 
  collect()

p1 <- pdata %>%  
  ggplot(aes(step, mean_gini, colour = as.factor(sharing_incentive))) +
  geom_line() +
  labs(colour = "Incentive for sharing data",
       y = "Gini of current resources")

p2 <- pdata %>%  
  ggplot(aes(step, mean_cumulative_gini, colour = as.factor(sharing_incentive))) +
  geom_line() +
  labs(colour = "Incentive for sharing data",
       y = "Gini of total resources")

p3 <- pdata %>%  
  ggplot(aes(step, mean_sharing, colour = as.factor(sharing_incentive))) +
  geom_line() +
  labs(colour = "Incentive for sharing data",
       y = "% of groups sharing data") 

p1 / p2 / p3 +
  plot_layout(guides = "collect") +
  plot_annotation(tag_levels = "A") & theme(legend.position = "top")
```

::: {.cell-output-display}
![Gini index and % of groups sharing data dependant on funding incentive. The share of teams being funded is fixed at 15%.](02-analyse-funding-intervention_files/figure-html/fig-vary-sharing-incentive-1.png){#fig-vary-sharing-incentive width=576}
:::
:::

This underlines the point from above about inequality first declining and then
rising again. Under competitive funding (15% of teams receiving funding), 
incentives lead to a strong difference in uptake, mainly contrasting low 
incentives (0 and 0.2) which lead to 20-30% of teams sharing, and all higher
settings, which lead to 50% of teams sharing.

Interestingly, higher incentives do not lead to higher sharing beyond this 
bound. This is likely a result of funding selectivity and the insufficient reach
of the funding body to all teams. It is also likely (but have not confirmed)
that under these settings, a bimodal resources distribution arises, which also
leads to bimodal proposals, and thus, a separation of teams that are able to 
acquire funding in principle, and those who are not (and subsequently are too 
far away from ever sharing data, that they can also not get there, because 
elevating effort is too costly without any funding).

This might point to the need of targeted support to teams that currently are not
sharing at all, and don't have the means to take it up on their own. This also
speaks to our research in ON-MERRIT: with policies and incentives for Open Data, there 
might be the danger of creating two worlds: one with and one without funding and
data sharing. Up to this point, this is not tied to initial resources. 
But given a costly activity (sharing data), this could very well lead to a 
situation where some teams simply are not able to take up data sharing due to a
lack of resources, which precludes them from gaining further resources.


One key question is why stronger incentives to share data lead to
more equitable resource distributions. Presumably there is more 
mixing: some groups are successful with, and some without sharing data, and this
changes. When there is no incentive, there is more path dependency
in funding.

The overall setup is still not representative of what I would perceive as "true"
agent behaviour: If there was an incentive, agents would know it and potentially
adapt. From ON-MERRIT and the literature, we assume this is easier for 
high-resource actors. This type of interaction is precluded from our model.

Here, data sharing might be more an alternative strategy to success: if sharing 
is rewarded, teams with lower resources (= prestige and publication track record)
have equal chances of getting funding simply by starting to share data.

# Interact funded share and funding incentive

::: {.cell}

```{.r .cell-code}
no_network <- df %>% 
  filter(network == "none", max_initial_utility == -3)

pdata <- no_network %>% 
  select(run_number, sharing_incentive, funded_share, step, perc_sharing, 
         resources_gini, total_funding_gini) %>% 
  group_by(sharing_incentive, funded_share, step) %>% 
  summarise(mean_gini = mean(resources_gini),
            mean_cumulative_gini = mean(total_funding_gini),
            mean_sharing = mean(perc_sharing)) %>% 
  collect() %>% 
  pivot_longer(c(mean_gini, mean_cumulative_gini, mean_sharing)) %>% 
  mutate(sharing_incentive = as.factor(sharing_incentive))

p_gini <- pdata %>% 
  filter(name == "mean_gini") %>% 
  ggplot(aes(step, value, colour = sharing_incentive)) +
  geom_line() +
  facet_wrap(vars(funded_share), ncol = 1) +
  labs(y = "Mean Gini of current resources")

p_gini_total <- pdata %>% 
  filter(name == "mean_cumulative_gini") %>% 
  ggplot(aes(step, value, colour = sharing_incentive)) +
  geom_line() +
  facet_wrap(vars(funded_share), ncol = 1) +
  labs(y = "Mean Gini of total resources")

p_sharing <- pdata %>% 
  filter(name == "mean_sharing") %>% 
  ggplot(aes(step, value, colour = sharing_incentive)) +
  geom_line() +
  facet_wrap(vars(funded_share), ncol = 1) +
  labs(y = "Mean % of teams sharing data")

p_sharing + p_gini + p_gini_total +
  plot_layout(guides = "collect") +
  plot_annotation(tag_levels = "A") &
  theme(legend.position = "top")
```

::: {.cell-output-display}
![Effect of funding incentive on (A) rate of sharing, (B) Gini of current resources and (C) Gini of total resources. The rows represent the varying rate of funded teams in %. Uniform starting distribution, max initial utility set to -3.](02-analyse-funding-intervention_files/figure-html/fig-incentive-funded-share-1.png){#fig-incentive-funded-share width=1152}
:::
:::

The results are fascinating. First, a high incentive for sharing, as implemented
in our model, does not seem either (a) necessary nor (b) the best strategy to
achieve high sharing.

Considering the case of 15% teams funded each round: Sharing uptake is equally 
quick regardless of incentive. Sharing has a higher equilibrium the higher the
sharing incentive is. Equity is higher (lower Gini) for higher sharing 
incentives. 

However, once we consider the case of 50% of teams being funded each round,
dynamics change substantially. Gini is lower, in line with more teams being
funded. Only a moderate sharing incentive (.4) is leading to high rates of
data sharing. Higher incentives lead to much lower sharing (below 10%).

This provides an explanation to the above hypothesis of two success pathways:
randomness. Looking at the right middle panel, we see that with high incentives
(funding derived mainly from effort sharing data), Gini of total resources 
approaches zero. This is because only a very low fraction is actually sharing 
data. The funding decision is therefore mainly driven by the noise in proposal
generation (proposal-sigma).

Lower rates of funder selectivity (85% funded teams) lead to lower inequality, 
but also to low rates of sharing data. One explanation might be that beyond a 
certain point, low funding rates are not able to offset the costs of data 
sharing (lower funder selectivity also leads to lower individual grants, given
that the total funding amount is fixed).


> A remaining question is therefore to investigate and explain why equity is 
higher for higher sharing incentives: is it randomness or is it the alternative
successful pathway case?

# Network effects
Investigate network effects for cases of 15% and 50% funded teams with low 
initial utility.


::: {.cell}

```{.r .cell-code}
pdata <- df %>% 
  filter(funded_share %in% c(.15, .5), max_initial_utility == -3) %>% 
  select(run_number, sharing_incentive, funded_share, step, perc_sharing, 
         resources_gini, network, total_funding_gini) %>% 
  group_by(sharing_incentive, funded_share, network, step) %>% 
  summarise(mean_gini = mean(resources_gini),
            mean_cumulative_gini = mean(total_funding_gini),
            mean_sharing = mean(perc_sharing)) %>% 
  collect() %>% 
  pivot_longer(c(mean_gini, mean_cumulative_gini, mean_sharing)) %>% 
  mutate(sharing_incentive = as.factor(sharing_incentive))

p_gini <- pdata %>% 
  filter(name == "mean_gini", funded_share == .15) %>% 
  ggplot(aes(step, value, colour = sharing_incentive)) +
  geom_line() +
  facet_wrap(vars(network), ncol = 1) +
  labs(y = "Mean Gini of current resources")

p_gini_total <- pdata %>% 
  filter(name == "mean_cumulative_gini", funded_share == .15) %>% 
  ggplot(aes(step, value, colour = sharing_incentive)) +
  geom_line() +
  facet_wrap(vars(network), ncol = 1) +
  labs(y = "Mean Gini of total resources")

p_sharing <- pdata %>% 
  filter(name == "mean_sharing", funded_share == .15) %>% 
  ggplot(aes(step, value, colour = sharing_incentive)) +
  geom_line() +
  facet_wrap(vars(network), ncol = 1) +
  labs(y = "Mean % of teams sharing data")

p_sharing + p_gini + p_gini_total +
  plot_layout(guides = "collect") +
  plot_annotation(tag_levels = "A") &
  theme(legend.position = "top")
```

::: {.cell-output-display}
![Effect of funding incentive on (A) rate of sharing and (B) Gini coefficient. The rows represent the network configurations. Uniform starting distribution. 15% funded teams.](02-analyse-funding-intervention_files/figure-html/fig-incentive-network-15perc-1.png){#fig-incentive-network-15perc width=1152}
:::
:::


These results from @fig-incentive-network-15perc are again fascinating. The 
top row is identical to the above figures. Introduction networks has in a broad
sense two effects:

1. sharing uptake is more responsive to incentives 
2. For high incentive settings, there is a lot of alternation between high and 
low rates of sharing.

Regarding (1), this is presumably because agents are now able to "learn" from 
their peers and therefore adapt collectively. This also goes in the opposite 
direction, in that with no to low incentives, sharing is very low.

Regarding (2), the fluctuations can be interpreted more easily when watching the
simulation unfold. Given sufficient incentives, sharing is being taken up. Since
all agents are connected via a few nodes (Small world example), sharing diffuses
to all agents. However, high effort is too costly to be sustained without 
funding. Once everyone shares, some agents stop sharing again because it is too
costly. Over time, this dance approaches a long-term equilibrium: To find a set
of connected teams that is equal to 15% of teams, and can therefore be funded
over the long term. If such a cluster is found, the simulation becomes much more 
stable (see the green line for .4 incentives: it also swings widely initially,
but stabilises. The instances of .6 incentives still exhibit variation, but
approach a similar but higher local equilibrium).

In terms of inequality of total resources, the network conditions behave
quite similar to the one without networks. Inequality of current resources is 
volatile and linked to the alternating extreme points of sharing/non-sharing.


::: {.cell}

```{.r .cell-code}
p_gini <- pdata %>% 
  filter(name == "mean_gini", funded_share == .5) %>% 
  ggplot(aes(step, value, colour = sharing_incentive)) +
  geom_line() +
  facet_wrap(vars(network), ncol = 1) +
  labs(y = "Mean Gini of current resources")

p_gini_total <- pdata %>% 
  filter(name == "mean_cumulative_gini", funded_share == .5) %>% 
  ggplot(aes(step, value, colour = sharing_incentive)) +
  geom_line() +
  facet_wrap(vars(network), ncol = 1) +
  labs(y = "Mean Gini of total resources")

p_sharing <- pdata %>% 
  filter(name == "mean_sharing", funded_share == .5) %>% 
  ggplot(aes(step, value, colour = sharing_incentive)) +
  geom_line() +
  facet_wrap(vars(network), ncol = 1) +
  labs(y = "Mean % of teams sharing data")

p_sharing + p_gini + p_gini_total +
  plot_layout(guides = "collect") +
  plot_annotation(tag_levels = "A") &
  theme(legend.position = "top")
```

::: {.cell-output-display}
![Effect of funding incentive on (A) rate of sharing and (B) Gini coefficient. The rows represent the network configurations. Uniform starting distribution. 50% funded teams.](02-analyse-funding-intervention_files/figure-html/fig-incentive-network-50perc-1.png){#fig-incentive-network-50perc width=1152}
:::
:::


It is surprising how different the results of 50% funded teams are to those with
15% funded teams, also in a qualitative sense: there are no alternating extremes
here. Sharing uptake is quick for medium incentives (.4 and .6), and settles at 
about the share of teams being funded (50%). 

Total inequality of resources exhibits similar patterns as above: very high 
incentives lead to *very* low inequality, which can be equated to purely random
funding. However, with medium incentives and network effects, randomness does
not take over, at least not in the long run: after an initial drop in inequality,
it rises again somewhat. This is tied to the uptick in sharing: while the
rate of sharing is rising quickly, inequality goes down. I suspect this is due
to the two pathways to success, but this is still to be confirmed. Once sharing
tops out and teams settle into either sharing or not sharing, inequality rises 
again.

# Success across quartiles

::: {.cell}

```{.r .cell-code}
group_success <- df %>% 
  filter(max_initial_utility == -3, network == "none") %>% 
  group_by(step, sharing_incentive, funded_share) %>% 
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
  facet_grid(rows = vars(sharing_incentive),
             cols = vars(funded_share)) +
  guides(colour = guide_legend(reverse = TRUE)) +
  labs(y = "Total funding acquired", colour = "Initial resource quantile") +
  theme(legend.position = "top") +
  coord_cartesian(ylim = c(0, 100))
```

::: {.cell-output-display}
![Mean total resources by initial resource quantile with no network. Higher quantiles (e.g., q4) had initially higher levels of funding. Max initial utility is fixed at -3. Columns represent cases of funder selectivity. Rows represent varying sharing incentives. Y-Axis is trunced to reveal aspects at earlier stages in the simulations.](02-analyse-funding-intervention_files/figure-html/fig-resources-by-quantile-no-networks-1.png){#fig-resources-by-quantile-no-networks width=768}
:::
:::

The above @fig-resources-by-quantile-no-networks might provide tentative answers
on the question of randomness vs. two-pathways to success. Most relevantly, the
case of low funder selectivity (15% funded teams) and moderate incentives (.4):
Initially, the top quartile (which had the most resources when starting out) is
more successful. However, it soon gets overtaken by the middle two quartiles.
This might be evidence to the fact that these quartiles take up sharing and
are therefore successful (to be confirmed below).

Given that these effects are stronger with the presence of networks, it is
particularly interesting to observe the small-world network case in 
@fig-resources-by-quantile-small-world: with moderate incentives, there seems
to be indeed a switch: lower resourced quartiles take up sharing as an 
alternative strategy and are more successful on the longer term. This is 
restricted to the middle quartiles for the case of 15% funded teams (e.g., by 
limited funder reach), but goes to a complete switch of resources among 
quartiles with 50% of funded teams.

It should be noted that this whole upheaval does not lead to a complete reversal,
and thus similar levels of inequality as if no team was sharing data. Quite the 
opposite, resources seem to be split more equally across quartiles, which is 
also reflected in the lower Gini coefficients for total resources.


::: {.cell}

```{.r .cell-code}
group_success <- df %>% 
  filter(max_initial_utility == -3, network == "random") %>% 
  group_by(step, sharing_incentive, funded_share) %>% 
  summarise(across(contains("mean_funds"), .fns = mean)) %>% 
  collect()

pdata <- group_success %>% 
  pivot_longer(contains("mean_funds"), names_to = "quantile",
               names_pattern = ".*_(q\\d)")

pdata %>% 
  ggplot(aes(step, value, colour = quantile)) +
  geom_line() +
  facet_grid(rows = vars(sharing_incentive),
             cols = vars(funded_share)) +
  guides(colour = guide_legend(reverse = TRUE)) +
  labs(y = "Total funding acquired", colour = "Initial resource quantile") +
  theme(legend.position = "top") +
  coord_cartesian(ylim = c(0, 100))
```

::: {.cell-output-display}
![Mean total resources by initial resource quantile with no network. Higher quantiles (e.g., q4) had initially higher levels of funding. Max initial utility is fixed at -3. Random network. Columns represent cases of funder selectivity. Rows represent varying sharing incentives. Y-Axis is trunced to reveal aspects at earlier stages in the simulations.](02-analyse-funding-intervention_files/figure-html/fig-resources-by-quantile-random-network-1.png){#fig-resources-by-quantile-random-network width=768}
:::
:::

::: {.cell}

```{.r .cell-code}
group_success <- df %>% 
  filter(max_initial_utility == -3, network == "random") %>% 
  group_by(step, sharing_incentive, funded_share) %>% 
  summarise(across(contains("mean_funds"), .fns = mean)) %>% 
  collect()

pdata <- group_success %>% 
  pivot_longer(contains("mean_funds"), names_to = "quantile",
               names_pattern = ".*_(q\\d)")

pdata %>% 
  ggplot(aes(step, value, colour = quantile)) +
  geom_line() +
  facet_grid(rows = vars(sharing_incentive),
             cols = vars(funded_share)) +
  guides(colour = guide_legend(reverse = TRUE)) +
  labs(y = "Total funding acquired", colour = "Initial resource quantile") +
  theme(legend.position = "top") +
  coord_cartesian(ylim = c(0, 100))
```

::: {.cell-output-display}
![Mean total resources by initial resource quantile with no network. Higher quantiles (e.g., q4) had initially higher levels of funding. Max initial utility is fixed at -3. Small-world network. Columns represent cases of funder selectivity. Rows represent varying sharing incentives. Y-Axis is trunced to reveal aspects at earlier stages in the simulations.](02-analyse-funding-intervention_files/figure-html/fig-resources-by-quantile-small-world-1.png){#fig-resources-by-quantile-small-world width=768}
:::
:::


## Which quantiles share data?

::: {.cell}

```{.r .cell-code}
team_sharing <- df %>% 
  filter(funded_share %in% c(.15, .5), max_initial_utility == -3,
         sharing_incentive == .4) %>% 
  group_by(step, funded_share, network) %>% 
  summarise(across(contains("data_sharing"), .fns = mean)) %>% 
  collect()

pdata <- team_sharing %>% 
  pivot_longer(contains("data_sharing"), names_to = "quantile",
               names_pattern = ".*_(q\\d)")

pdata %>% 
  ggplot(aes(step, value, colour = quantile)) +
  geom_line(alpha = .8) +
  facet_grid(rows = vars(funded_share),
             cols = vars(network)) +
  guides(colour = guide_legend(reverse = TRUE)) +
  labs(y = "% of teams sharing data", colour = "Initial resource quantile") +
  theme(legend.position = "top")
```

::: {.cell-output-display}
![Mean % of teams sharing by initial resource quantile by network type. Rows represent the % of teams receiving sharing. Max initial utility is fixed at -3, sharing incentive is fixed at .4.](02-analyse-funding-intervention_files/figure-html/fig-sharing-by-quantile-1.png){#fig-sharing-by-quantile width=768}
:::
:::


@fig-sharing-by-quantile seems to confirm the hypothesis of the two-pathway 
model: This is particularly visible in the case of 50% funded teams and 
small-world networks. Here, the bottom quartiles (i.e., the poorest) take up
sharing more quickly and to a much larger extent. Given that 
@fig-resources-by-quantile-small-world above showed an initial advantage of 
total resources for higher resourced quartiles, this complements the picture:
Initially, top teams do not share data and are still successful. Lower resourced
teams are able to be successful through increasing their sharing effort, 
outperforming the better resourced actors over time. 

It should be noted that these patterns emerge, despite the fact that we 
initialise the model without any correlation or clustering in resources 
according to the networks. That is: all networks have low and high resourced 
networks at the start. If we had stratification, with some clusters with high
resources and others with low resources, we might see this more strongly or not
at all -> interesting follow up question.

# Summary
- Incentives lead to higher data sharing in our model.
- Funder selectivity is an additionally important determinant of the diffusion 
of practices: with no selectivity, the policy does not have an effect. Likewise,
if selectivity is high, the effect is also small.
- Introducing data sharing incentives might open up alternative pathways to 
success: taking up data sharing might be a successful strategy for low-resourced
actors to gain an advantage.

Theoretically, one could make two competing arguments: with Bourdieu
(homo academicus), one could argue that high-prestige actors are too slow and 
hesitant to change their ways/habitus. Alternatively, arguing with Rogers 
(Diffusion of innovation), better resourced actors would be leaders of 
innovation.

Our results align with what could be postulated with Bourdieu. However, this 
ignores
the potential that high-profile actors take strategic action: embarking on data
sharing, knowing that this will be important in the future. Furthermore, our 
model ignores scaling effects: that more resources might make it easier to take
up sharing. Still, I'm intrigued by the fact that what we expected (negative 
effect of data sharing on inequality) did not in fact emerge, but the opposite.


# Limitations
There are many limitations, but currently there are two that stand out to me:

- Max initial utilitiy is uniform. It might be better to model this with skewed
distributions: case (a) - majority low effort but some high effort, case (b) the
opposite, case (c) normal distribution.
- Correlation between clustering and resources. The above analysis raises the 
interesting question what would happen if resources were tied to network 
position. 