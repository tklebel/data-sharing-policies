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

## Sensitivity analysis
The repo also contains outputs and analysis notebooks for the sensitivity analysis.
The analysis was done in Spark due to the large file sizes. We share three "packages"
of data that we used for the sensitivity analysis:

- gain-sensitivity-data.tar.bz2
- sigma-sensitivity-data.tar.bz2
- costs-sensitivity-data.tar.bz2

These archives contain two files each: a general file for the sensitivity analysis,
and one with individual-level data. Both are stored as `.parquet` files. 

They are already processed (similar to step 2 above), so can be readily analysed
using the files `10-Figure-1-sensitivity.qmd`, `10-Figure-2-sensitivity.qmd`, 
and `10-Figure-3-sensitivity.qmd` which are available under `analysis`. 

