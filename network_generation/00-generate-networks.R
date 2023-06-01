library(igraph)
library(ggraph)
library(tidygraph)
library(tidyverse)


sw <- sample_smallworld(dim = 1, size = 100, nei = 2, p = .01)

# good setting for moderate clustering is nei = 5 and p = .01
# higher p leads to lower clustering coefficient

transitivity(sample_smallworld(dim = 1, size = 100, nei = 10, p = .2))

transitivity(sw)
mean_distance(sw)

# sw <- simplify(sw)

ggraph(sw, "stress") +
  geom_edge_link() +
  geom_node_point()


# it is clear I cannot get to the desired topology with a pure generator
# what we need is to create multiple small world networks, and then to link
# them via preferential attachment. 

# simulate physics -----
# few clusters, those quite dense. Question: also a lot of collaboration or not?
physics_setup <- tibble(
  n_dim = rep(1, 4),
  dim_size = c(10, 20, 30, 30),
  order = c(3, 4, 4, 6),
  p_rewire = c(.05, .05, .01, .005)
)
physics_setup

physics_graphs <- pmap(physics_setup, play_smallworld)
physics <- bind_graphs(physics_graphs)

physics %>% 
  ggraph() +
  geom_edge_link() +
  geom_node_point()

physics %>% 
  transitivity()

# now we need to add edges via preferential attachement

new_p <- sample_pa(100, start.graph = physics, out.pref = TRUE, m = 5, power = 3,
                   directed = FALSE) %>% 
  as_tbl_graph()

new_p %>% 
  ggraph("stress") +
  geom_edge_link() +
  geom_node_point()

new_p %>% 
  transitivity()
physics %>% transitivity()

# the above generates something that looks reasonable
# would need to visualise some properties of the nodes, e.g. in degree or 
# something else

new_p %>% 
  activate(nodes) %>% 
  mutate(group = group_louvain()) %>% 
  ggraph("kk") +
  geom_edge_link() +
  geom_node_point(aes(colour = as.factor(group)), size = 3) +
  theme_graph()


# however, this is still not ideal. ideally, we'd only add edges, but not nodes


# try with fewer initial edges, adding more edges via BA model -> this does not
# work well (with setting seed_size = 60. leads to lower transitivity, but this
# might be fine for some disciplines?)
seed_size <- 60
base_rewire <- .01
physics_setup <- tibble(
  n_dim = rep(1, 4),
  dim_size = c(seed_size * .1, seed_size * .2, seed_size * .35, seed_size * .4),
  order = c(3, 4, 4, 5), # neighborhood size
  p_rewire = c(base_rewire, base_rewire, base_rewire * .2, base_rewire * .15)
)

physics_graphs <- pmap(physics_setup, play_smallworld)
physics <- bind_graphs(physics_graphs)

new_p <- sample_pa(100, start.graph = physics, out.pref = TRUE, m = 10, power = 3,
                   directed = FALSE) %>% 
  as_tbl_graph()

new_p %>% 
  activate(nodes) %>% 
  mutate(group = group_infomap(),
         degree = centrality_degree(),
         page_rank = centrality_pagerank()) %>% 
  ggraph("kk") +
  geom_edge_link() +
  geom_node_point(aes(colour = as.factor(group),
                      size = page_rank)) +
  theme_graph()
# the current issue is that most added edges appear in the largest and densest
# component
# a solution could be to have more but smaller groups
new_p %>% transitivity()
physics %>% transitivity()


# bipartite ----
# bp <- sample_bipartite(50, 50, p = .1)
bp <- sample_bipartite(50, 50, type = "gnm", m = 400)
tidy_bp <- as_tbl_graph(bp)


transitivity(bp)
mean_distance(bp)

ggraph(bp, "bipartite") +
  geom_edge_link() +
  geom_node_point()
# transitivity is zero for these kinds of networks - not what we want
# todo: look at what vincent said in more detail

# add some random edges
n_new_edges <- 100
random_edges <- tibble(
  from = c(sample(1:50, n_new_edges / 2), sample(51:100, n_new_edges / 2)),
  to = c(sample(1:50, n_new_edges / 2), sample(51:100, n_new_edges / 2)),
)

with_random_edges <- tidy_bp %>% 
  bind_edges(random_edges)

with_random_edges %>% 
  transitivity(type = "global")
with_random_edges %>% 
  activate(nodes) %>% 
  mutate(local_clustering = local_transitivity()) %>% 
  as_tibble() %>% 
  summarise(mean_local_clust = mean(local_clustering))


with_random_edges %>% 
  ggraph("bipartite") +
  geom_edge_link()

with_random_edges %>% 
  ggraph("kk") +
  geom_edge_link() +
  geom_node_point()


