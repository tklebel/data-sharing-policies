source("renv/activate.R")

library(sparklyr)
library(arrow)
library(dplyr)

source("R/functions.R")

Sys.setenv(SPARK_HOME = "/home/tklebel/spark-3.4.0-bin-hadoop3/")
Sys.setenv(HADOOP_HOME = "/home/hadoop/hadoop-3.3.1")
Sys.setenv(HADOOP_CONF_DIR = "/home/hadoop/hadoop-3.3.1/etc/hadoop")
Sys.setenv(YARN_HOME = "/home/hadoop/hadoop-3.3.1")
Sys.setenv(YARN_CONF_DIR = "/home/hadoop/hadoop-3.3.1/etc/hadoop")
Sys.setenv(JAVA_HOME="/usr/lib/jvm/java-1.11.0-openjdk-amd64")

config <- spark_config()
config$spark.executor.cores <- 4
config$spark.executor.instances <- 38
config$spark.executor.memory <- "15G"
config$spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version <- 2
config$spark.speculation <- TRUE # add speculation to remove tasks that take too long
config$spark.speculation.multiplier <- 2
config$spark.executor.memoryOverheadFactor <- .2 # default is .1 - this is probably not needed
config$spark.speculation.quantile <- .4
# options(sparklyr.log.console = TRUE)

sc <- spark_connect(master = "yarn", config = config,
                    app_name = "pivot_columns")


# parquet_df <- spark_read_parquet(
#   sc, "parquet_df",
#   path = "/tklebel/data_sharing_abm/vary_incentives_individuals_no_network.parquet",
#   memory = FALSE,
# )
# 
# 
# # pivot data
# re_arranged <- parquet_df %>%
#   spark_apply(f = re_arrange, memory = FALSE)
# 
# 
# spark_write_parquet(
#   re_arranged,
#   path = "/tklebel/data_sharing_abm/vary_incentives_individuals_no_network_re_arranged.parquet",
#   mode = "overwrite"
#   # partition_by = c("fundedshare", "sharingincentive")
# )


# cat("processing random network\n")
# 
# parquet_df <- spark_read_parquet(
#   sc, "parquet_df",
#   path = "/tklebel/data_sharing_abm/vary_incentives_individuals_random_network.parquet",
#   memory = FALSE,
# )
# 
# 
# # pivot data
# re_arranged <- parquet_df %>%
#   spark_apply(f = re_arrange, memory = FALSE)
# 
# 
# spark_write_parquet(
#   re_arranged,
#   path = "/tklebel/data_sharing_abm/vary_incentives_individuals_random_network_re_arranged.parquet",
#   mode = "overwrite"
#   # partition_by = c("fundedshare", "sharingincentive")
# )

cat("processing fragmented network\n")

parquet_df <- spark_read_parquet(
 sc, "parquet_df",
 path = "/tklebel/data_sharing_abm/vary_incentives_individuals_fragmented.parquet",
 memory = FALSE,
)


# pivot data
re_arranged <- parquet_df %>%
 spark_apply(f = re_arrange, memory = FALSE)


spark_write_parquet(
 re_arranged,
 path = "/tklebel/data_sharing_abm/vary_incentives_individuals_fragmented_re_arranged.parquet",
 mode = "overwrite"
 # partition_by = c("fundedshare", "sharingincentive")
)


# cat("processing clustered network\n")
# 
# parquet_df <- spark_read_parquet(
#   sc, "parquet_df",
#   path = "/tklebel/data_sharing_abm/vary_incentives_individuals_clustered.parquet",
#   memory = FALSE,
# )
# 
# 
# # pivot data
# re_arranged <- parquet_df %>%
#   spark_apply(f = re_arrange, memory = FALSE)
# 
# 
# spark_write_parquet(
#   re_arranged,
#   path = "/tklebel/data_sharing_abm/vary_incentives_individuals_clustered_re_arranged.parquet",
#   mode = "overwrite"
#   # partition_by = c("fundedshare", "sharingincentive")
# )


spark_disconnect(sc)
cat("Done")
