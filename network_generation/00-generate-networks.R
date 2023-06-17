library(igraph)
library(ggraph)
library(tidygraph)
library(tidyverse)
library(ggtext)

extrafont::loadfonts(device = "win")


plot_graph <- function(graph, layout = "stress") {
  graph %>% 
    activate(nodes) %>% 
    mutate(group = group_louvain(),
           degree = centrality_degree(),
           page_rank = centrality_pagerank()) %>% 
    ggraph(layout) +
    geom_edge_link() +
    geom_node_point(aes(colour = as.factor(group),
                        size = page_rank)) +
    theme_graph() +
    theme(legend.position = "none")
}

summarise_graph <- function(graph) {
  clustering <- graph %>% transitivity()
  mean_distance <- graph %>% mean_distance()
  
  graph %>%   
    activate(nodes) %>% 
    mutate(degree = centrality_degree()) %>% 
    as_tibble() %>% 
    summarise(avg_degree = mean(degree),
              clustering = clustering, mean_dist = mean_distance)
}



plot_degree <- function(graph) {
  degree_dist <- graph %>% 
    activate(nodes) %>% 
    mutate(degree = centrality_degree(mode = "total")) %>% 
    as_tibble() %>% 
    count(degree)
  
  
  degree_dist %>% 
    ggplot(aes(degree, n)) +
    geom_point() +
    geom_line() +
    theme_bw() +
    labs(x = "number of collaborators *k* (degree)",
         y = "number of teams with *k* collaborators") +
    theme(axis.title.x = ggtext::element_markdown(),
          axis.title.y = ggtext::element_markdown())
}




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
  ggraph() +
  geom_edge_link() +
  geom_node_point(aes(colour = as.factor(group)), size = 3) +
  theme_graph()


# however, this is still not ideal. ideally, we'd only add edges, but not nodes


# try with fewer initial edges, adding more edges via BA model -> this does not
# work well (with setting seed_size = 60. leads to lower transitivity, but this
# might be fine for some disciplines?)
seed_size <- 40
base_rewire <- .001
physics_setup <- tibble(
  n_dim = rep(1, 3),
  dim_size = c(seed_size * .2, seed_size * .35, seed_size * .5),
  order = c(2, 3, 4), # neighborhood size
  p_rewire = c(base_rewire, base_rewire * .2, base_rewire * .15)
)

physics_graphs <- pmap(physics_setup, play_smallworld)
physics <- bind_graphs(physics_graphs)

new_p <- sample_pa(100, start.graph = physics, out.pref = TRUE, m = 5, power = 1,
                   directed = FALSE) %>% 
  as_tbl_graph()

plot_graph(new_p)
# the current issue is that most added edges appear in the largest and densest
# component
# a solution could be to have more but smaller groups
summarise_graph(new_p)
plot_degree(new_p)

# two new approaches to try:
# - add edges to a few random nodes, and only then add scale free edges
# - generate second network with more clusters


# fragmented network ------
seed_size <- 90
base_rewire <- .001
fragmented_setup <- tibble(
  n_dim = rep(1, 7),
  dim_size = round(
    c(seed_size * .1, seed_size * .1, seed_size * .2, seed_size * .3,
               seed_size * .05, seed_size * .1, seed_size * .15)
    ),
  order = c(2, 3, 3, 4, 4, 5, 5), # neighborhood size
  p_rewire = c(base_rewire, base_rewire, base_rewire, base_rewire,
               base_rewire * .2, base_rewire * .15, base_rewire * .1)
)

fragmented_graphs <- pmap(fragmented_setup, play_smallworld)
fragmented <- bind_graphs(fragmented_graphs)

new_frag <- sample_pa(100, start.graph = fragmented, out.pref = TRUE, m = 5,
                      power = 1, directed = FALSE) %>% 
  as_tbl_graph()

plot_graph(new_frag)
summarise_graph(new_frag)
plot_degree(new_frag)
# the neighborhood size seems to be too large, there is too much clustering
# (but this might fit well to physics?)
# 

# besides:
# the algorithm does not work as anticipated. edges are only added for nodes
# that are added. but I wanted to add edges to existing nodes too. will have to
# do this myself
# pseudo-code
# pick random node
# pick another node according to degree (same algorithm as in barbasi albert)
# create edge from random to second node. this should start introducing some
# further clustering
# 
# if this is not leading to enough clustering, either the probability would need
# to be skewed (similar to the power argument above), or we would need to pick
# a couple of nodes ahead of time, and add many more edges to them

# islands algorithm
islandic <- play_islands(5, 25, p_within = .4, m_between = 4)
summarise_graph(islandic)
plot_graph(islandic)

islandic %>% 
  activate(nodes) %>% 
  mutate(degree = centrality_degree()) %>% 
  as_tibble() %>% 
  summarise(avg_degree = mean(degree))


# the islandic approach is too barebone. The clustered thing that I currently
# get in both other approaches is fine. Just need an additional one that has
# much lower clustering, and lower degree, i.e., a more disconnected network
# 
# what might also be missing is the power-law aspect would need to look at the
# degree distribution and make such a plot? or can the value be calculated?


# plot degree distribution
new_frag %>% degree()
plot_degree(new_frag)


# diagnostics work now
# next step:
# create algorithm for addition of edges via preferential attachment

# start with one of the graphs that we have
fragmented

# select a node
from <- sample(1:90, size = 1)

# compute probability
p <- fragmented %>% 
  mutate(degree = centrality_degree(mode = "total"),
         p = degree / sum(degree)) %>% 
  pull(p)
to <- sample(1:90, 1, replace = TRUE, prob = p)

fragmented %>% 
  bind_edges(tibble(from = from, to = to))


add_edge_preferential <- function(graph, n_new_edges = 1) {
  # select a node
  from <- sample(seq_along(graph), size = 1)
  
  # compute probability
  p <- graph %>% 
    mutate(degree = centrality_degree(mode = "total"),
           p = degree / sum(degree)) %>% 
    pull(p)
  # NEED TO AVOID DRAWING THE SAME NODE, TO AVOID LOOPS
  to <- sample(seq_along(graph), size = n_new_edges, replace = TRUE, prob = p)
  
  graph %>% 
    bind_edges(tibble(from = from, to = to))
}

rerun_addition <- function(graph, times = 10, n_new_edges = 1) {
  tick <- 0
  out <- graph
  while (tick < times) {
    tick <- tick + 1
    out <- add_edge_preferential(out, n_new_edges = n_new_edges)
  }
  out
}

added_edges <- rerun_addition(fragmented, times = 5, n_new_edges = 15)
added_edges <- rerun_addition(added_edges, times = 5, n_new_edges = 5)
added_edges <- rerun_addition(added_edges, times = 20, n_new_edges = 1)
summarise_graph(added_edges)
plot_graph(added_edges)
plot_degree(added_edges) 
plot_degree(fragmented)

map(1:10, add_edge_preferential(fragmented))

add
fragmented %>% 
  add_edge_preferential(n_new_edges = 20)


g <- sample_pa(1000) %>% 
  as_tbl_graph()
plot_degree(g) +
  scale_y_log10() +
  scale_x_log10()
summarise_graph(g)
g %>% 
  ggraph("stress") +
  geom_node_point() +
  geom_edge_link()
  
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


