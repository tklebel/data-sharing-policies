source("renv/activate.R")
library(sparklyr)
library(arrow)
library(dplyr)

Sys.setenv(SPARK_HOME = "/home/tklebel/spark-3.4.0-bin-hadoop3/")
Sys.setenv(HADOOP_HOME = "/home/hadoop/hadoop-3.3.1")
Sys.setenv(HADOOP_CONF_DIR = "/home/hadoop/hadoop-3.3.1/etc/hadoop")
Sys.setenv(YARN_HOME = "/home/hadoop/hadoop-3.3.1")
Sys.setenv(YARN_CONF_DIR = "/home/hadoop/hadoop-3.3.1/etc/hadoop")
Sys.setenv(JAVA_HOME="/usr/lib/jvm/java-1.11.0-openjdk-amd64")

config <- spark_config()
config$spark.executor.cores <- 5
config$spark.executor.instances <- 38
config$spark.executor.memory <- "15G"
config$spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version <- 2

options(sparklyr.log.console = FALSE)

sc <- spark_connect(master = "yarn", config = config,
                    app_name = "convert_to_parquet")

# spark_read_csv(sc, name = "source_csv",
#                path = "/tklebel/data_sharing_abm/vary_incentives_individuals_no_network.csv.bz2",
#                memory = FALSE)
# 
# temp_df <- tbl(sc, "source_csv")
# 
# # drop data that is redundant
# selected_cols <- temp_df %>%
#   select(run_number, step, maxinitialutility, fundedshare, sharingincentive,
#          individualdata)
# 
# spark_write_parquet(
#   selected_cols,
#   path = "/tklebel/data_sharing_abm/vary_incentives_individuals_no_network.parquet",
#   mode = "overwrite"
# )


# # random network
# spark_read_csv(sc, name = "source_csv",
#                path = "/tklebel/data_sharing_abm/vary_incentives_individuals_random_network.csv.bz2",
#                memory = FALSE)
# 
# temp_df <- tbl(sc, "source_csv")
# 
# # drop data that is redundant
# selected_cols <- temp_df %>%
  # select(run_number, step, maxinitialutility, fundedshare, sharingincentive, 
  #        individualdata)
# 
# spark_write_parquet(
#   selected_cols,
#   path = "/tklebel/data_sharing_abm/vary_incentives_individuals_random_network.parquet",
#   mode = "overwrite"
# )
# 
# fragmented network
spark_read_csv(sc, name = "source_csv",
              path = "/tklebel/data_sharing_abm/vary_incentives_individuals_fragmented.csv.bz2",
              memory = FALSE)

temp_df <- tbl(sc, "source_csv")

#  drop data that is redundant
selected_cols <- temp_df %>%
  select(run_number, step, maxinitialutility, fundedshare, sharingincentive,
         individualdata)

spark_write_parquet(
 selected_cols,
 path = "/tklebel/data_sharing_abm/vary_incentives_individuals_fragmented.parquet",
 mode = "overwrite"
)


# # clustered network
# spark_read_csv(sc, name = "source_csv",
#                path = "/tklebel/data_sharing_abm/vary_incentives_individuals_clustered.csv.bz2",
#                memory = FALSE)
# 
# temp_df <- tbl(sc, "source_csv")
# 
# # drop data that is redundant
# selected_cols <- temp_df %>%
#   select(run_number, step, maxinitialutility, fundedshare, sharingincentive,
#          individualdata)
# 
# spark_write_parquet(
#   selected_cols,
#   path = "/tklebel/data_sharing_abm/vary_incentives_individuals_clustered.parquet",
#   mode = "overwrite"
# )



spark_disconnect(sc)
