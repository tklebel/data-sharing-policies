library(sparklyr)
library(dplyr)
library(here)
library(ggplot2)

# Port forwarding for better UI access:
#   ssh -L 4040:localhost:4040 mcmc
# Then access the UI at http://localhost:4040 on your local machine

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

# CPU settings - using same proportion of cores but more total
sc <- spark_connect(master = "local[28]", config = conf, version = "3.5.0")

## Initial sensitivity check

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
#   select(run_number, step, sharingcostscap, sharingincentive, network, fundedshare, sharing) 
#   

# spark_write_parquet(core_set, "outputs/sharing-costs-sensitivity.parquet",
#                     mode = "overwrite",
#                     partition_by = c("network", "sharingcostscap")
# )

## Sensitivity high-res

# sensitive <- spark_read_csv(sc, "sensitivity",
#                             path = here("outputs/sharing-costs-sensitivity_high_res.csv.bz2"),
#                             memory = FALSE)
# 
# # initialnorm = 0
# # resourcedist = uniform
# # applicationpenalty = 0.05
# # proposalsigma = 0.15
# # nteams = 100
# # thirdpartyfundingratio = 2
# # 
# 
# core_set <- sensitive %>%
#   select(run_number, step, sharingcostscap, sharingincentive, network, fundedshare, sharing)
# 
# 
# spark_write_parquet(core_set, "outputs/sharing-costs-sensitivity_high_res.parquet",
#                     mode = "overwrite",
#                     partition_by = c("network", "fundedshare")
# )


spark_disconnect(sc)
