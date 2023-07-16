# Goal: re-aggregate data with Gini, to confirm our prior findings

library(sparklyr)
library(dplyr)
library(arrow)
library(here)

Sys.setenv(SPARK_HOME = "/home/tklebel/spark-3.4.0-bin-hadoop3/")
Sys.setenv(HADOOP_HOME = "/home/hadoop/hadoop-3.3.1")
Sys.setenv(HADOOP_CONF_DIR = "/home/hadoop/hadoop-3.3.1/etc/hadoop")
Sys.setenv(YARN_HOME = "/home/hadoop/hadoop-3.3.1")
Sys.setenv(YARN_CONF_DIR = "/home/hadoop/hadoop-3.3.1/etc/hadoop")
Sys.setenv(JAVA_HOME="/usr/lib/jvm/java-1.11.0-openjdk-amd64")

config <- spark_config()
config$spark.executor.cores <- 5
config$spark.executor.instances <- 20
config$spark.executor.memory <- "20G"

sc <- spark_connect(master = "yarn", config = config,
                    app_name = "aggregate_ginis")

no_network <- spark_read_parquet(
  sc, "no_network",
  path = "/tklebel/data_sharing_abm/vary_incentives_individuals_no_network_re_arranged.parquet",
  memory = FALSE
)

# we only need to group by run_number and step. All the other input variables
# are uniform within each run. We can thus take the distinct set across 
# run_number, step, max...utility, fundedshare, sharingincentive, and join the
# summarised dataset from the left.

aggregate_stats <- function(grouped_df) {
  
  # convert gini to local_function from inequ::Gini
  gini <- function (x, corr = FALSE, na.rm = TRUE) {
    if (!na.rm && any(is.na(x))) 
      return(NA_real_)
    x <- as.numeric(na.omit(x))
    n <- length(x)
    x <- sort(x)
    G <- sum(x * 1L:n)
    G <- 2 * G/sum(x) - (n + 1L)
    if (corr) 
      G/(n - 1L)
    else G/n
  }
  
  dplyr::summarise(grouped_df, resources_gini = gini(resources),
                   total_funding_gini = gini(total_funding),
                   perc_sharing = mean(as.numeric(shared_data)))
}

ginis <- no_network %>% 
  spark_apply(
    aggregate_stats,
    group_by = c("run_number", "step"),
    columns = list(
      run_number = "integer",
      step = "integer",
      resources_gini = "double",
      total_funding_gini = "double",
      perc_sharing = "double"
    ),
    memory = FALSE)

aggregated_no_network <- no_network %>% 
  distinct(run_number, step, maxinitialutility, fundedshare, sharingincentive) %>% 
  left_join(ginis)

spark_write_parquet(aggregated_no_network,
                    path = "/tklebel/data_sharing_abm/vary_incentives_individuals_no_network_aggregated.parquet")

spark_disconnect(sc)
