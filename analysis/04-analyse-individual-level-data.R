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
config$spark.executor.instances <- 15
config$spark.executor.memory <- "15G"

sc <- spark_connect(master = "yarn", config = config,
                    app_name = "analyse_data")


no_network <- spark_read_parquet(
  sc, "no_network",
  path = "/tklebel/data_sharing_abm/vary_incentives_individuals_no_network_re_arranged.parquet",
  memory = TRUE
)

# validate that we got more rows by the factor of 100 (pivoting 100 individuals)
not_arranged <- spark_read_parquet(
  sc, "not_arranged",
  path = "/tklebel/data_sharing_abm/vary_incentives_individuals_no_network.parquet",
  memory = FALSE
)


identical(
  {not_arranged %>% 
    sdf_nrow()} * 100,
  no_network %>% 
    sdf_nrow() 
)

# this is very crude:
# explore if in later stages of simulation there is a correlation between initial
# resources and whether respondents share data or not
all_cors <- no_network %>% 
  filter(step >= 2000, !is.na(initial_resources), !is.na(data_sharing)) %>% 
  group_by(fundedshare, sharingincentive) %>% mutate(data_sharing = as.integer(data_sharing)) %>% 
  summarise(cor = cor(initial_resources, data_sharing)) %>% 
  collect()

spark_disconnect(sc)

