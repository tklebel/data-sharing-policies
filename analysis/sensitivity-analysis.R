library(sparklyr)
library(dplyr)
library(here)
library(ggplot2)
library(arrow)

# Port forwarding for better UI access:
#   ssh -L 4040:localhost:4040 username@your-server
# Then access the UI at http://localhost:4040 on your local machine
# Simple configuration - minimal settings to avoid conflicts
options(sparklyr.log.console = TRUE)

conf <- spark_config()

# Memory allocation - scaled proportionally (75% of available RAM)
conf$spark.driver.memory <- "96g"                    # From 48g to 96g
conf$`sparklyr.shell.driver-memory` <- "96g"         # From 48g to 96g

# Increase result size limit proportionally
conf$spark.driver.maxResultSize <- "16g"             # From 8g to 16g

# File processing adjustments
conf$spark.sql.files.maxPartitionBytes <- "256m"     # Keeping same (good balance)
conf$spark.sql.shuffle.partitions <- 224             # From 112 to 224 (8 × cores)

# Keeping these adaptive settings (they work well)
conf$spark.sql.adaptive.enabled <- "true"
conf$spark.sql.adaptive.coalescePartitions.enabled <- "true"
conf$spark.sql.adaptive.skewJoin.enabled <- "true"

# Keeping disk spillage settings (crucial for large files)
conf$spark.sql.shuffle.spill <- "true"
conf$spark.shuffle.spill.compress <- "true"
conf$spark.shuffle.compress <- "true"
conf$spark.shuffle.file.buffer <- "1m"

# Slightly increased broadcast threshold
conf$spark.sql.autoBroadcastJoinThreshold <- "128m"  # From 64m to 128m

# Keeping serialization settings
conf$spark.serializer <- "org.apache.spark.serializer.KryoSerializer"

# Keeping speculative execution settings
conf$spark.speculation <- "true"
conf$spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version <- "2"

# Use arrow for faster file transfer
conf$spark.sql.execution.arrow.enabled <- "true"
conf$spark.sql.execution.arrow.maxRecordsPerBatch <- "100000"  # Adjust based on your memory

# CPU settings - using same proportion of cores but more total
sc <- spark_connect(master = "local[28]", config = conf, version = "3.5.0")

# read the data
overview_set <- spark_read_parquet(sc, name = "overview_set_costs_cap", 
                               path = "outputs/sharing-costs-sensitivity.parquet/",
                               memory = FALSE)

summarised_table <- overview_set %>%
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
  collect()

arrow::write_csv_arrow(summarised_table_high_res, "interim_outputs/sharing_cap_high_res.csv")

summarised_table_high_res %>% 
  filter(network == "none") %>% 
  ggplot(aes(step, mean_sharing, colour = as.factor(sharingcostscap), group = sharingcostscap)) +
  geom_line() +
  facet_grid(rows = vars(fundedshare),
             cols = vars(sharingincentive))
ggsave("analysis/sensitivit_high_res.png", width = 15, height = 15)

spark_disconnect(sc)
