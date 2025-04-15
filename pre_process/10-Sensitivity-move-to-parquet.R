library(sparklyr)
library(dplyr)
library(here)

# Port forwarding for better UI access:
#   ssh -L 4040:localhost:4040 mcmc
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

# ## Sharing costs  ------
# 
# sensitive <- spark_read_csv(sc, "sensitivity",
#                             path = here("outputs/sharing-costs-sensitivity.csv"),
#                             memory = TRUE)
# 
# # initialnorm = 0
# # resourcedist = uniform
# # applicationpenalty = 0.05
# # proposalsigma ) 0.15
# # nteams = 100
# # thirdpartyfundingratio = 2
# #
# 
# core_set <- sensitive %>%
#   select(run_number, step, sharingcostscap, sharingincentive, network,
#          fundedshare, sharing, gini_resources_of_turtles, gini_totalfunding_of_turtles)
# 
# 
# spark_write_parquet(core_set, "outputs/sharing-costs-sensitivity.parquet",
#                     mode = "overwrite",
#                     partition_by = c("network", "fundedshare")
# )

# # Sensitivity high-res ------
# 
# sensitive <- spark_read_csv(sc, "sensitivity",
#                             path = here("outputs/sharing-costs-sensitivity_high_res.csv"),
#                             memory = TRUE)
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
#   select(run_number, step, sharingcostscap, sharingincentive, network, 
#          fundedshare, sharing, gini_resources_of_turtles, gini_totalfunding_of_turtles)
# 
# 
# spark_write_parquet(core_set, "outputs/sharing-costs-sensitivity_high_res.parquet",
#                     mode = "overwrite",
#                     partition_by = c("network", "fundedshare")
# )

# # sigma sensitivity --------------------------
# sigma <- spark_read_csv(sc, "sigma",
#                             path = here("outputs/sigma-sensitivity.csv"),
#                             memory = TRUE)
# 
# # initialnorm = 0
# # resourcedist = uniform
# # applicationpenalty = 0.05
# # proposalsigma = 0.15
# # nteams = 100
# # thirdpartyfundingratio = 2
# #
# 
# core_set <- sigma %>%
#   select(run_number, step, proposalsigma, sharingincentive, network, fundedshare,
#          sharing, gini_resources_of_turtles, gini_totalfunding_of_turtles)
# 
# 
# spark_write_parquet(core_set, "outputs/sigma-sensitivity.parquet",
#                     mode = "overwrite",
#                     partition_by = c("network", "fundedshare")
# )
# 
# # gain sensitivity -------------
# gain <- spark_read_csv(sc, "gain",
#                             path = here("outputs/gain-sensitivity.csv"),
#                             memory = TRUE)
# 
# # initialnorm = 0
# # resourcedist = uniform
# # applicationpenalty = 0.05
# # proposalsigma = 0.15
# # nteams = 100
# # thirdpartyfundingratio = 2
# #
# 
# core_set <- gain %>%
#   select(run_number, step, gain, sharingincentive, network, fundedshare,
#          sharing, gini_resources_of_turtles, gini_totalfunding_of_turtles)
# 
# 
# spark_write_parquet(core_set, "outputs/gain-sensitivity.parquet",
#                     mode = "overwrite",
#                     partition_by = c("network", "fundedshare")
# )


spark_disconnect(sc)
