library(sparklyr)
library(dplyr)
library(here)
library(ggplot2)

# Port forwarding for better UI access:
#   ssh -L 4040:localhost:4040 username@your-server
# Then access the UI at http://localhost:4040 on your local machine
# Simple configuration - minimal settings to avoid conflicts
options(sparklyr.log.console = TRUE)


# conf <- spark_config()
# conf$spark.driver.memory <- "45g"
# conf$`sparklyr.shell.driver-memory` <- '30G'
# conf$`sparklyr.shell.executor-memory` <- '30G'
# 
# # Connect using Spark 3.5.0 explicitly
# sc <- spark_connect(master = "local[8]", config = conf, version = "3.5.0")
# # Check JVM settings 
# system("jps -lvm")




conf <- spark_config()


# Memory allocation - more conservative to allow for spillage
conf$spark.driver.memory <- "48g"
conf$`sparklyr.shell.driver-memory` <- "48g"

# Critical for large files - increase sort spillage threshold
conf$spark.driver.maxResultSize <- "8g"  # Prevent large collect() operations from failing

# File processing for large files
conf$spark.sql.files.maxPartitionBytes <- "256m"  # Balance between parallelism and overhead
conf$spark.sql.shuffle.partitions <- 112  # 8 × cores for complex operations on big data
conf$spark.sql.adaptive.enabled <- "true"  # Crucial for large data processing
conf$spark.sql.adaptive.coalescePartitions.enabled <- "true"
conf$spark.sql.adaptive.skewJoin.enabled <- "true"

# Disk spillage settings (crucial for large files)
conf$spark.sql.shuffle.spill <- "true"
conf$spark.shuffle.spill.compress <- "true"
conf$spark.shuffle.compress <- "true"
conf$spark.shuffle.file.buffer <- "1m"  # Larger buffer for better I/O performance

# Smaller broadcast threshold helps with join operations on large data
conf$spark.sql.autoBroadcastJoinThreshold <- "64m"

# Serialization (faster but uses more memory)
conf$spark.serializer <- "org.apache.spark.serializer.KryoSerializer"

# Enable speculative execution for long-running tasks
conf$spark.speculation <- "true"

conf$spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version <- "2"

# CPU settings - use most of your cores but leave some headroom
sc <- spark_connect(master = "local[14]", config = conf, version = "3.5.0")

spark_web(sc)


# sensitive <- spark_read_csv(sc, "sensitivity",
#                             path = here("outputs/sharing-costs-sensitivity.csv.bz2"),
#                             memory = FALSE)


# initialnorm = 0
# resourcedist = uniform
# applicationpenalty = 0.05
# proposalsigma ) 0.15
# nteams = 100
# thirdpartyfundingratio = 2
# 

# core_set <- sensitive %>% 
#   select(run_number, step, sharingcostscap, sharingincentive, network, fundedshare, datasharing, sharing) 
#   

# summarised_table <- core_set %>%
#   # head(200) %>% 
#   group_by(sharingcostscap, sharingincentive, network, fundedshare, step) %>%
#   summarise(n = n(),
#             mean_sharing = mean(sharing),
#             sd_sharing = sd(sharing)) %>%
#   collect()


# spark_write_parquet(core_set, "outputs/sharing-costs-sensitivity.parquet",
#                     mode = "overwrite",
#                     partition_by = c("network", "sharingcostscap")
# )



core_set <- spark_read_parquet(sc, name = "core_set_costs_cap", 
                               path = "outputs/sharing-costs-sensitivity.parquet/",
                               memory = FALSE)

summarised_table <- core_set %>%
    # head(200) %>%
    group_by(sharingcostscap, sharingincentive, network, fundedshare, step) %>%
    summarise(n = n(),
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

spark_disconnect(sc)
