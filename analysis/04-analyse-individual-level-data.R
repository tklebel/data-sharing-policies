library(sparklyr)
library(arrow)
library(dplyr)
library(ggplot2)

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
  filter(step >= 2000, !is.na(initial_resources), !is.na(shared_data)) %>% 
  group_by(fundedshare, sharingincentive, maxinitialutility) %>% 
  mutate(shared_data = as.integer(shared_data)) %>% 
  summarise(cor = cor(initial_resources, shared_data)) %>% 
  collect()
all_cors

all_cors %>%
  ggplot(aes(sharingincentive, cor, colour = as.factor(fundedshare))) +
  geom_line(aes(group = as.factor(fundedshare))) +
  geom_point() +
  facet_wrap(vars(maxinitialutility))


# to which extent are initial resources determining final funding?
cumulation <- no_network %>% 
  filter(step == 3000) %>% 
  group_by(fundedshare, sharingincentive, maxinitialutility) %>% 
  summarise(cor = cor(initial_resources, total_funding)) %>% 
  collect()
cumulation

cumulation %>%
  ggplot(aes(sharingincentive, cor, colour = as.factor(fundedshare))) +
  geom_line(aes(group = as.factor(fundedshare))) +
  geom_point() +
  facet_wrap(vars(maxinitialutility))
# that is interesting. Higher sharing incentive seems to lead to less determinism
# but why is path dependency so strong with a low sharing incentive?

all_cumulation <- no_network %>% 
  filter(step == 3000) %>% 
  collect()

all_cumulation %>% 
  filter(fundedshare == .5, sharingincentive == 0, maxinitialutility == 4) %>% 
  slice_sample(n = 1000) %>% 
  ggplot(aes(initial_resources, total_funding)) +
  geom_jitter(alpha = .4)
# simply because there is complete separation: low initial resources lead to 
# never receiving extra funding

spark_disconnect(sc)


