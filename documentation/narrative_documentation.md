---
title: Data Sharing and Funding Competition Model
date: 2025-05-28
output: pdf_document
---
 
## Overview and Purpose

This agent-based model simulates the dynamics of data sharing practices among academic research teams competing for funding. The model explores how different funding schemes (competitive large grants vs. distributive small grants) and data sharing incentives affect the long-term uptake of data sharing practices in scientific communities.

## Entities, State Variables, and Scales

### Agents
- **Research teams** (default n=100): Represent academic groups that conduct research and compete for funding

### Agent State Variables
- `resources`: Current funding/capital level
- `initial-resources`: Starting resource level
- `individual-utility`: Agent's propensity to share data (ranges from -5 to +5)
- `effort`: Calculated effort to share data
- `inv_effort`: Inverse logit transformation of effort (probability on [0,1])
- `shared-data?`: Boolean indicating if data was shared this round
- `funded?`: Boolean indicating if funded this round
- `descriptive-norm`: Social influence from network neighbors
- `proposal-strength`: Quality of submitted proposal
- `total-funding`: Cumulative funding received over simulation

### Global Parameters
- `sharing-incentive` (α): Weight of data sharing in proposal evaluation (0-0.7)
- `funded-share`: Proportion of teams receiving funding each round (0.1-0.6)
- `proposal-sigma`: Standard deviation of proposal quality (default 0.15)
- `utility-change`: Increment for utility updates (default 0.03)
- `sharing-costs-cap` (λ): Maximum cost of sharing as proportion of base funding (default 0.1)
- `gain` (g): Gain factor for effort calculation (default 1)
- `network`: Type of collaboration network (none/random/clustered/fragmented)

### Temporal Scale
- Discrete time steps (default 3000 rounds)

## Process Overview and Scheduling

Each time step follows this sequence:

1. **Update indices**: Store previous round values
2. **Data sharing decision**: Teams decide whether to share data based on:
   - Individual utility
   - Network influence (if applicable)
   - Costs deducted from resources
3. **Proposal generation**: Teams create proposals with strength based on:
   - Normalized resources
   - Data sharing effort (weighted by sharing-incentive)
4. **Funding allocation**: 
   - All teams receive base funding
   - Top teams ranked by proposal strength receive additional funding
5. **Utility update**: Teams adjust their data sharing propensity based on outcomes
6. **Network influence update**: Teams adjust behavior based on neighbors' actions

## Design Concepts

### Decision Making
Teams make stochastic data sharing decisions using:
```
p = 1 / (1 + exp(-g * e))
```
where `e` is effort based on individual utility and social norms.

### Learning
Teams use reinforcement learning: utility increases if (shared data AND gained resources) OR (didn't share AND didn't gain resources); otherwise utility decreases.

### Social Influence
In network scenarios, teams incorporate neighbors' behavior:
```
d = (Σ neighbors who shared / total neighbors) - 0.5
e = (utility + d) / 2
```

### Competition
Teams compete for limited funding based on proposal quality, creating trade-offs between investing in data sharing vs. maintaining competitiveness.

## Initialization

- Teams start with uniformly distributed resources
- Initial utility set to -4 (low data sharing propensity)
- Networks loaded from pre-generated GML files if specified
- Initial descriptive norm set to 0

## Submodels

### Data Sharing Cost
```
cost = λ * β * p
```
where λ is cost cap, β is base funding rate, and p is sharing probability.

### Proposal Strength
```
μ = (1 - α) * R_normalized + α * e
proposal_strength ~ Normal(μ, σ)
```

### Funding Distribution
- Base funding: Each team receives 1/n units
- Competitive funding: Top teams (based on funded-share) split additional funding pool
- Application penalty: 5% resource reduction for all teams

### Resource Dynamics
- Teams that successfully share data may see resources increase from funding
- Sharing costs reduce resources proportionally to effort
- Path dependency emerges from cumulative advantages

## Model Variants

The model supports different network topologies to represent various scientific community structures:
- **No network**: Teams act independently
- **Random network**: Erdős–Rényi random graph
- **Clustered network**: High clustering coefficient representing tight-knit communities
- **Fragmented network**: Low degree, long path lengths representing isolated groups

## Key Outputs

- Percentage of teams sharing data
- Gini coefficient of resource distribution
- Mean effort levels
- Path dependency measures (correlation between funding and initial resources)

## Pseudo code
```
setup:
  if network:
    load pre-generated network file with agents
  else:
    create n agents 

  for each agent:
    initialize agent attributes

main simulation:
  while t < T:
    increment time
    update indices
      
    # share data
    for each agent:
        calculate effort
        calculate inverse effort
        calculate shared-data? based on inverse effort
        decrease resources based on inverse effort
  
    # generate proposals
    for each agent:
        calculate proposal strength based on normalized resources and inverse effort

    # allocate funding
    for each agent:
        increase resources for all agents (base funding)
        calculate n-grants
        sort agents based on proposal-strength
        select top-teams based on n-grants
        calculate funding-per-team
        distribute funding to top-teams

    # update utility
    for each agent:
        if shared-data? and resources increased or not shared-data? and resources not increased:
            increase individual-utility
        else:
            decrease individual-utility
    
    # update network influence
    for each agent:
        calculate descriptive-norm based on sharing within link-neighbors

```