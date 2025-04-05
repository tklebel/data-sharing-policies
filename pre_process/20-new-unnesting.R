library(sparklyr)
library(dplyr)
library(here)
library(ggplot2)

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

# Read the full parquet file
parquet_df <- spark_read_parquet(sc, "sharing_costs_individuals",
                                 path = "outputs/sharing-costs-sensitivity-individuals.parquet",
                                 memory = FALSE)

# Register as a table - using the full dataset
sdf_register(parquet_df, "sharing_costs_individuals_full")

# Define SQL query using the full dataset table
sql <- "
WITH cleaned_data AS (
  SELECT 
    *,
    regexp_replace(regexp_replace(individualdata, '^\\\\[\\\\[', ''), '\\\\]\\\\]$', '') AS clean_data
  FROM sharing_costs_individuals_full
)
SELECT 
  t.`run_number`, 
  t.`sharingcostscap`,
  t.`sharingincentive`,
  t.`network`,
  t.`fundedshare`,
  t.`datasharing`,
  t.`step`,
  cast(split(s.item, ' ')[0] as double) as who,
  cast(split(s.item, ' ')[1] as double) as initial_resources,
  cast(split(s.item, ' ')[2] as double) as resources,
  cast(split(s.item, ' ')[3] as double) as total_funding,
  cast(split(s.item, ' ')[4] as double) as effort,
  CASE WHEN split(s.item, ' ')[5] = 'true' THEN true ELSE false END as shared_data,
  CASE WHEN split(s.item, ' ')[6] = 'true' THEN true ELSE false END as shared_data_lag,
  CASE WHEN split(s.item, ' ')[7] = 'true' THEN true ELSE false END as funded,
  CASE WHEN split(s.item, ' ')[8] = 'true' THEN true ELSE false END as funded_lag
FROM 
  cleaned_data t
LATERAL VIEW 
  explode(split(clean_data, '\\\\] \\\\[')) s AS item
"

# Execute SQL using Spark's native SQL interface
result <- spark_session(sc) %>%
  invoke("sql", sql) %>%
  sdf_register("re_arranged")

# Write to production parquet file (not test)
spark_write_parquet(
  tbl(sc, "re_arranged"),
  path = "outputs/sharing-costs-sensitivity-individuals_re_arranged.parquet",
  mode = "overwrite",
  partition_by = "network"
)

# Print summary to confirm success
cat("Processing complete! Full dataset transformation finished.\n")


spark_disconnect(sc)
