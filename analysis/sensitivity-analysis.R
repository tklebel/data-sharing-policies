library(sparklyr)
library(dplyr)
library(here)
library(ggplot2)
# library(arrow)

# Port forwarding for better UI access:
#   ssh -L 4040:localhost:4040 username@your-server
# Then access the UI at http://localhost:4040 on your local machine

# Configuration optimized for 36-core, 128GB machine
options(sparklyr.log.console = TRUE)
conf <- spark_config()

# Memory settings - optimized for 128GB RAM
conf$spark.driver.memory <- "110g"
conf$`sparklyr.shell.driver-memory` <- "110g"
conf$spark.driver.maxResultSize <- "20g"

# Parallelism settings - optimized for 36 cores
conf$spark.sql.files.maxPartitionBytes <- "256m"
conf$spark.sql.shuffle.partitions <- 360
conf$spark.default.parallelism <- 72

# Keep adaptive query execution enabled
conf$spark.sql.adaptive.enabled <- "true"
conf$spark.sql.adaptive.coalescePartitions.enabled <- "true"
conf$spark.sql.adaptive.skewJoin.enabled <- "true"
conf$spark.sql.adaptive.skewJoin.skewedPartitionFactor <- 5
conf$spark.sql.adaptive.skewJoin.skewedPartitionThresholdInBytes <- "512m"

# Memory and shuffle optimization
conf$spark.sql.shuffle.spill <- "true"
conf$spark.shuffle.spill.compress <- "true"
conf$spark.shuffle.compress <- "true"
conf$spark.shuffle.file.buffer <- "1m"
conf$spark.memory.fraction <- 0.8
conf$spark.memory.storageFraction <- 0.3

# Broadcast join optimization
conf$spark.sql.autoBroadcastJoinThreshold <- "256m"

# Serialization settings
conf$spark.serializer <- "org.apache.spark.serializer.KryoSerializer"
conf$spark.kryo.registrationRequired <- "false"
conf$spark.kryo.unsafe <- "true"

# Speculation settings
conf$spark.speculation <- "true"
conf$spark.speculation.multiplier <- 1.5
conf$spark.speculation.quantile <- 0.9
conf$spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version <- "2"

# Off-heap memory settings
conf$spark.memory.offHeap.enabled <- "true"
conf$spark.memory.offHeap.size <- "20g"

# Connect using 32 cores (leaving 4 for system)
sc <- spark_connect(master = "local[32]", config = conf, version = "3.5.0")

# read the data
overview_set <- spark_read_parquet(sc, name = "overview_set_costs_cap", 
                               path = "outputs/sharing-costs-sensitivity.parquet/",
                               memory = TRUE)

summarised_table <- overview_set %>%
    # head(200) %>%
    group_by(sharingcostscap, sharingincentive, network, fundedshare, step) %>%
  summarise(n = n(),
            mean_gini = mean(gini_resources_of_turtles),
            sd_gini = sd(gini_resources_of_turtles),
            mean_cumulative_gini = mean(gini_totalfunding_of_turtles),
            sd_cumulative_gini = sd(gini_totalfunding_of_turtles),
            mean_sharing = mean(sharing),
            sd_sharing = sd(sharing)) %>% 
    collect()

summarised_table %>% 
  filter(network == "none") %>% 
  ggplot(aes(step, mean_sharing, colour = as.factor(sharingcostscap), group = sharingcostscap)) +
  geom_line() +
  facet_grid(rows = vars(fundedshare),
             cols = vars(sharingincentive))

ggsave("analysis/sensitivity_plot.png", width = 15, height = 15)
  
# only for low incentives (up to .3) there are meaningful differences. 
# high costs dont really make a difference, but there is more to explore between
# costs of 0 and .1

summarised_table %>% 
  filter(network == "none") %>% 
  ggplot(aes(step, mean_gini, colour = as.factor(sharingcostscap),
             group = sharingcostscap)) +
  geom_line() +
  facet_grid(rows = vars(fundedshare),
             cols = vars(sharingincentive))

summarised_table %>% 
  filter(network == "none") %>% 
  ggplot(aes(step, mean_cumulative_gini, colour = as.factor(sharingcostscap),
             group = sharingcostscap)) +
  geom_line() +
  facet_grid(rows = vars(fundedshare),
             cols = vars(sharingincentive))

# higher resolution
high_res_set <- spark_read_parquet(sc, name = "high_res_set", 
                                   path = "outputs/sharing-costs-sensitivity_high_res.parquet/",
                                   memory = FALSE)

summarised_table_high_res <- high_res_set %>%
  # head(200) %>%
  group_by(sharingcostscap, sharingincentive, network, fundedshare, step) %>%
  summarise(n = n(),
            mean_sharing = mean(sharing),
            sd_sharing = sd(sharing)) %>%
  spark_write_parquet("interim_outputs/sharing_cap_high_res.parquet")

arrow::write_csv_arrow(summarised_table_high_res, "interim_outputs/sharing_cap_high_res.csv")

summarised_table_high_res %>% 
  filter(network == "none") %>% 
  ggplot(aes(step, mean_sharing, colour = as.factor(sharingcostscap), group = sharingcostscap)) +
  geom_line() +
  facet_grid(rows = vars(fundedshare),
             cols = vars(sharingincentive))
ggsave("analysis/sensitivit_high_res.png", width = 15, height = 15)


# Sigma sensitivity -----
sigma_sensitivity <- spark_read_parquet(sc, "sigma_sensitivity",
                                        path = "outputs/sigma-sensitivity.parquet",
                                        memory = FALSE)

sigma_sensitivity_local <- sigma_sensitivity %>%
  # head(200) %>%
  group_by(proposalsigma, sharingincentive, network, fundedshare, step) %>%
  summarise(n = n(),
            mean_sharing = mean(sharing),
            sd_sharing = sd(sharing)) %>%
  collect()

sigma_sensitivity_local %>% 
  filter(network == "none") %>% 
  ggplot(aes(step, mean_sharing, colour = as.factor(proposalsigma), group = proposalsigma)) +
  geom_line() +
  facet_grid(rows = vars(fundedshare),
             cols = vars(sharingincentive))

ggsave("analysis/sigma_exploration.png", width = 15, height = 15)



## Analyse individual level data -----
sharing_costs_individuals <- spark_read_parquet(sc, name = "sharing_costs_individuals",
                                                path = "outputs/sharing-costs-sensitivity-individuals_re_arranged.parquet/",
                                                memory = TRUE)

# Effort development
no_network_intervention <- sharing_costs_individuals %>% 
  filter(fundedshare == .1, network == "fragmented")

no_network_effort <- no_network_intervention %>% 
  group_by(step, sharingincentive, sharingcostscap, funded) %>% 
  summarise(mean_effort = mean(effort),
            sd_effort = sd(effort)) %>% 
  collect()




# better_pal <- colorspace::sequential_hcl(5, palette = "Viridis")

no_network_effort %>% 
  mutate(
    funded = factor(
      funded, levels = c(TRUE, FALSE),
      labels = c("Funded teams", "Unfunded teams")
    ),
    sharingincentive = paste0(
      "Incentive: ", scales::percent(sharingincentive)
    )) %>% 
  ggplot(aes(step, mean_effort, group = as.factor(sharingcostscap))) +
  geom_ribbon(aes(ymin = mean_effort - sd_effort,
                  ymax = mean_effort + sd_effort), 
              fill = "grey40", alpha = .05, show.legend = FALSE) +
  geom_line(aes(y = mean_effort, colour = as.factor(sharingcostscap))) +
  facet_grid(vars(sharingincentive),
             vars(funded)) +
  # coord_cartesian(xlim = c(0, 1500)) +
  # scale_colour_manual(values = c(better_pal[2], better_pal[4])) +
  theme(legend.position = c(.85, .15)) +
  labs(y = "Effort of teams", x = NULL, colour = NULL)

# overall, this output figure (difference between funded and unfunded teams)
# is not very sensitive to the sharing costs. Only the case with 30% incentives
# shows a case where teams are sensitive to costs (faster uptake with no costs,
# but long-term lower effort)
# In network scenarios, no costs lead to higher effort, particularly also among
# the unfunded teams.

spark_disconnect_all()
