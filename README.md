# Data and Code for "The paradox of competition: How funding models could undermine the uptake of data sharing practices"

This repository contains simulation code, simulation output and analysis code and output for the above preprint. 

The model was coded in NetLogo, and is available from the file `data_sharing_policies.nlogo`.

Code for the generation of the networks is available in the self-contained notebook `network_generation/00-network-generation.qmd`. 

The analysis pipeline consisted of multiple steps:

1. Run the model using the scripts in `batch_commands`.
2. Pre-process the output files from the simulation to prepare them for analysis in Spark (files `01-move-to-parquet.R` and `02-pivot-columns.R` in `pre-process`).
3. Analyse various parts of the model with the analysis notebooks in `analysis`.

Due to size constraints we share the outputs from steps (1) and (3). The intermediate
files from step (2) are larger than the files from step (1), and contain the same
content.

A short note on naming conventions. In the paper, we speak of four types of 
networks, but the names are slightly different than in the code. This is just
because the naming became more precise over the course of the analysis. The 
mapping between the output files and the reported networks is as follows:

1. "vary_incentives.csv.bz2" = No network.
2. "vary_incentives_individuals_clustered.csv.bz2" = high clustering.
3. "vary_incentives_individuals_fragmented.csv.bz2" = low clustering.
4. "vary_incentives_individuals_random network.csv.bz2" = random network.


