---
title: "Analysis of funder selectivity: individual level data"
format: 
  html:
    code-fold: true
  #pdf: default
execute:
  keep-md: true
---



Research questions:

-   Are always the same teams receiving funding?
-   Are those that are being funded also those that share data?
-   Are those that share data / receive funding more or less central in the
    network?


::: {.cell}

:::


# Are always the same teams receiving funding?


::: {.cell}

```{.r .cell-code}
# we did not store whether a given team was funded, and it is quite 
# time-consuming to re-run everything. We can compute this (with quite some
# effort) by checking if their total funding increased or not.

# check funding progress
funding_status <- fragmented %>% 
  filter(sharingincentive == .4,
         # we can restrict this to steps above 2000, since we are interested in
         # the equilibrium state here
         step >= 2000)
```
:::

::: {.cell}

```{.r .cell-code}
# lagged model for funding

regression_results <- funding_status %>% 
  # it also fails currently, no idea why
  ml_logistic_regression(funded ~ initial_resources + funded_lag) 
```
:::

::: {.cell}

```{.r .cell-code}
print(regression_results)
```
:::


There seems to be a massive effect of the lagged funding status, if we take a
global look at all funding incentive settings.


::: {.cell}

```{.r .cell-code}
correlations <- funding_status %>% 
  group_by(maxinitialutility, fundedshare) %>% 
  summarise(cor_funding = cor(as.numeric(funded), as.numeric(funded_lag)),
            cor_init_resources = cor(as.numeric(funded), as.numeric(initial_resources))) %>% 
  collect()
```

::: {.cell-output .cell-output-stderr}
```
`summarise()` has grouped output by "maxinitialutility". You can override using
the `.groups` argument.
```
:::
:::

::: {.cell}

```{.r .cell-code}
correlations %>% 
  arrange(maxinitialutility, fundedshare) %>% 
  knitr::kable()
```

::: {.cell-output-display}
| maxinitialutility| fundedshare| cor_funding| cor_init_resources|
|-----------------:|-----------:|-----------:|------------------:|
|                -4|         0.1|   0.9542113|          0.0106203|
|                -4|         0.2|   0.9588905|         -0.0576242|
|                -4|         0.3|   0.9528467|         -0.1407019|
|                -4|         0.4|   0.9544672|         -0.2778403|
|                -4|         0.5|   0.9525710|         -0.3824903|
|                -4|         0.6|   0.9507971|         -0.2691963|
|                 4|         0.1|   0.9442191|          0.0844402|
|                 4|         0.2|   0.9535090|          0.1629669|
|                 4|         0.3|   0.9560221|          0.1500305|
|                 4|         0.4|   0.9551332|          0.1648794|
|                 4|         0.5|   0.9543237|          0.1068485|
|                 4|         0.6|   0.9516042|          0.0736735|
:::
:::

::: {.cell}

```{.r .cell-code}
correlations %>% 
  ggplot(aes(fundedshare, cor_funding, 
             colour = as.factor(maxinitialutility))) +
  geom_line() +
  geom_point()
```

::: {.cell-output-display}
![](04-funder-selectivity-individual-data_files/figure-html/unnamed-chunk-7-1.png){width=672}
:::
:::


The correlation between current and previous funding status is very high - there
seems to be almost complete path dependency, once the simulation has entered the
equilibrium state.


::: {.cell}

```{.r .cell-code}
correlations %>% 
  ggplot(aes(fundedshare, cor_init_resources, 
             colour = as.factor(maxinitialutility))) +
  geom_line() +
  geom_point()
```

::: {.cell-output-display}
![](04-funder-selectivity-individual-data_files/figure-html/unnamed-chunk-8-1.png){width=672}
:::
:::


Interestingly, the correlation with initial resources is much lower. For uniform
initial utility, it is relatively low across all funding selectivity settings.

For low initial utility, this is not true, and there is actually a negative
correlation. This lends credence to our initial hypothesis: teams with initially
higher resources (presumably, to be confirmed below) share less data, and thus
are less successful under the incentive regime.

## No network


::: {.cell}

```{.r .cell-code}
funding_status_no_network <- no_network %>% 
  filter(sharingincentive == .4,
         # we can restrict this to steps above 2000, since we are interested in
         # the equilibrium state here
         step >= 2000)
```
:::

::: {.cell}

```{.r .cell-code}
regression_results <- funding_status_no_network %>% 
  # it also fails currently, no idea why
  ml_logistic_regression(funded ~ initial_resources + funded_lag) 
```
:::

::: {.cell}

```{.r .cell-code}
print(regression_results)
```
:::


With the baseline without a network, there is equally a strong influence of path
dependency. Initial resources have a slightly stronger role than in the case of
the fragmented network.


::: {.cell}

```{.r .cell-code}
correlations_no_network <- funding_status_no_network %>% 
  group_by(maxinitialutility, fundedshare) %>% 
  summarise(cor_funding = cor(as.numeric(funded), as.numeric(funded_lag)),
            cor_init_resources = cor(as.numeric(funded), as.numeric(initial_resources))) %>% 
  collect()
```

::: {.cell-output .cell-output-stderr}
```
`summarise()` has grouped output by "maxinitialutility". You can override using
the `.groups` argument.
```
:::
:::

::: {.cell}

```{.r .cell-code}
correlations_no_network %>% 
  arrange(maxinitialutility, fundedshare) %>% 
  knitr::kable()
```

::: {.cell-output-display}
| maxinitialutility| fundedshare| cor_funding| cor_init_resources|
|-----------------:|-----------:|-----------:|------------------:|
|                -4|         0.1|   0.8121845|          0.0065602|
|                -4|         0.2|   0.9023002|         -0.0471462|
|                -4|         0.3|   0.9373384|         -0.1178397|
|                -4|         0.4|   0.9501977|         -0.0499509|
|                -4|         0.5|   0.9527413|         -0.0145661|
|                -4|         0.6|   0.8737687|         -0.0212698|
|                 4|         0.1|   0.9861305|          0.3249158|
|                 4|         0.2|   0.9906219|          0.3626612|
|                 4|         0.3|   0.9908658|          0.2900537|
|                 4|         0.4|   0.9783700|          0.1799073|
|                 4|         0.5|   0.9671437|          0.0382707|
|                 4|         0.6|   0.9707301|         -0.0082824|
:::
:::

::: {.cell}

```{.r .cell-code}
correlations_no_network %>% 
  ggplot(aes(fundedshare, cor_funding, 
             colour = as.factor(maxinitialutility))) +
  geom_line() +
  geom_point()
```

::: {.cell-output-display}
![](04-funder-selectivity-individual-data_files/figure-html/unnamed-chunk-14-1.png){width=672}
:::
:::


Correlations for funding lag are similarly very high. However, behaviour is
different between max-initial-utility, comparing to the case of the fragmented
network. Here, correlations are higher for maxinitalutility = 4, but lower
otherwise.


::: {.cell}

```{.r .cell-code}
correlations_no_network %>% 
  ggplot(aes(fundedshare, cor_init_resources, 
             colour = as.factor(maxinitialutility))) +
  geom_line() +
  geom_point()
```

::: {.cell-output-display}
![](04-funder-selectivity-individual-data_files/figure-html/unnamed-chunk-15-1.png){width=672}
:::
:::


These correlations are stronger, i.e., more positive, as indicated by the
regression: without networks, initial resources play a stronger role in who
getes funded, especially if funding is very selective.

# Are those that are being funded also those that share data?


::: {.cell}

```{.r .cell-code}
funding_vs_sharing <- funding_status %>% 
  group_by(maxinitialutility, fundedshare) %>% 
  summarise(cor_funding_sharing = cor(as.numeric(funded), as.numeric(shared_data)),
            cor_sharing_lag = cor(as.numeric(shared_data), as.numeric(shared_data_lag))) %>% 
  collect()
```

::: {.cell-output .cell-output-stderr}
```
`summarise()` has grouped output by "maxinitialutility". You can override using
the `.groups` argument.
```
:::
:::

::: {.cell}

```{.r .cell-code}
funding_vs_sharing %>% 
  ggplot(aes(fundedshare, cor_funding_sharing, 
             colour = as.factor(maxinitialutility))) +
  geom_line() +
  geom_point()
```

::: {.cell-output-display}
![](04-funder-selectivity-individual-data_files/figure-html/unnamed-chunk-17-1.png){width=672}
:::
:::


Generally speaking, those that are being funded are also those that share data,
in this instance. The correlation is stronger for less selective regimes. What
does this indicate? Maybe the broader reach of the funding agency, if many teams
are being funded? But wouldn't it be the case that if funding is more selective,
only those that are funded also share data, because it is too costly otherwise?
But maybe it is the opposite: if funding is very selective, not many teams can
afford to share data, and thus not many do. If funding is less selective, more
teams share data, and thus, generally, those being funded are also more often
those which share data. Does this make sense?


::: {.cell}

```{.r .cell-code}
funding_vs_sharing %>% 
  ggplot(aes(fundedshare, cor_sharing_lag, 
             colour = as.factor(maxinitialutility))) +
  geom_line() +
  geom_point()
```

::: {.cell-output-display}
![](04-funder-selectivity-individual-data_files/figure-html/unnamed-chunk-18-1.png){width=672}
:::
:::


The correlation between sharing, and the shared lag (whether teams keep sharing
data) is also quite high, and the graph looks very similar to the one right
above. This implies that there is path dependency around sharing, where teams
share data and receive funding, while others do neither.

# Are those that share data / receive funding more or less central in the network?

HIGHLY INTERESTING OBSERVATION: in the fragmented network, it is mostly those
teams which are not well-connected that keep sharing data (in line with the
general finding that no network leads to more sharing than having a network.
Those that are closer to having no network (low degree) are thus more likely to
share). Is it then also those that receive more funding? Need to compare with
centrality measures.

This might be the reason, why the means that we show are much smoother for the
fragmented network, compared to the clustered, and especially the random
network: in the fragmented network, the types of nodes sharing data are quite
similar across runs, because there is a strong difference in degree between the
nodes. In the clustered, and more so in the random network, there are not so big
differences in degree, and thus there is more variability in who shares.


::: {.cell}

```{.r .cell-code}
spark_disconnect(sc)
```
:::
