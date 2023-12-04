# The Social Cost of Greenhouse Gases
This repo provides replication instructions for estimating the social cost of greenhouse gases (SC-GHGs) as outlined in the "Report on the Social Cost of Greenhouse Gases: Estimates Incorporating Recent Scientific Advances" developed by the U.S. Environmental Protection Agency (EPA). For more information about the report and peer review process, see [EPA's SC-GHG website](https://www.epa.gov/environmental-economics/scghg). 

SC-GHG estimation for each gas in each emissions year comes from three equally-weighted damage modules. The three damage modules are:

1. a subnational-scale, sectoral damage function based on the Data-driven Spatial Climate Impact Model (DSCIM) developed by the Climate Impact Lab ([CIL 2023](DSCIM/DSCIM_User_Manual.pdf)). 

2. a country-scale, sectoral damage function (based on the Greenhouse Gas Impact Value Estimator (GIVE) model developed under RFF’s Social Cost of Carbon Initiative ([Rennert et al. 2022b](https://www.nature.com/articles/s41586-022-05224-9)), 

3. a meta-analysis-based damage function (based on [Howard and Sterner 2017](https://link.springer.com/article/10.1007/s10640-017-0166-z)). 

All other modules (i.e., socioeconomics, climate, and discounting) are consistent across the damage modules. 

# Requirements
1. *Julia* is free and available for download [here](https://julialang.org/). Estimation of the SC-GHGs for the [`GIVE`](#the-greenhouse-gas-impact-value-estimator-give) and [`Meta-Analysis`](#the-meta-analysis) damage modules was performed on Julia 1.6. While newer versions of *Julia* are compatible with all the code (e.g., 1.7 or 1.8), the random number generators were updated and results might not be identical due to random differences in the random parameters underlying the Monte Carlo runs of GIVE and the Meta-Analysis. Install *Julia* and ensure that it can be invoked (ran) from where the replication repository is to be cloned ("in your path"). 

2. *R* is free and available for download [here](https://www.r-project.org/). The *RStudio* integrated development environment is useful for replication, it is free and available for download [here](https://www.rstudio.com/products/rstudio/). *R* is used to replicate the term structure in [Bauer and Rudebusch (2021)](https://direct.mit.edu/rest/article-abstract/doi/10.1162/rest_a_01109/107405/The-Rising-Cost-of-Climate-Change-Evidence-from?redirectedFrom=fulltext) and the discounting parameters $\rho$ and $\eta$ derived in [Newell, Pizer, and Prest (2022)](https://www.journals.uchicago.edu/doi/10.1086/718145). *R* is also used to collect the estimates from each damage module and create [a table of unrounded annual SC-GHGs](EPA/output/scghg_annual.csv). 

3. *Anaconda* is free and available for download [here](https://www.anaconda.com/). Other distributions can be used, too, such as [miniconda](https://docs.conda.io/en/latest/miniconda.html), or [mamba](https://mamba.readthedocs.io/en/latest/). Regardless of the user's desired distribution, *conda* packages are used to perform estimation of the [`DSCIM`](#the-data-driven-spatial-climate-impact-model-dscim) damage module. 

4. Optional: *Github* is free and available for download [here](https://github.com/git-guides/install-git). *Github* is used to house this repository and by installing and using it to clone the repository one will simplify the replication procedure. However, a user could also simply download a zipped file version of this repository, unzip in the desired location, and follow the replication procedures outlined below.

# Getting Started
Begin by cloning or downloading a copy of this repository. This can be done by clicking on the green "code" button in this repository and following those instructions, or by navigating in the terminal via the command line to the desired location of the cloned repository and then typing: 

```
git clone https://github.com/USEPA/sc-ghg.git
```

Alternatively, you can make a `fork` of this repository and work from the fork in the same way. This allows for development on the `fork` while preserving its relationship with this repository.

# Estimating the SC-GHGs
Estimation of the three damage modules and their SC-GHGs is outlined below. For convenience, this repository already includes the completed model runs (in each damage module's `output` subdirectory), the full distributions of their estimates (in each damage module's `output\full_distributions` subdirectory), and [the final table](/EPA/output/scghg_annual.csv) of annual SC-GHGs.

## The Data-driven Spatial Climate Impact Model (DSCIM)
Replicating the estimates from DSCIM can be done by following the steps outlined here. Begin by opening a terminal and navigating via the command line to the location of the cloned respository from the step [above](#getting-started). Note, DSCIM requires the `conda` library. Ensure that the `conda` library is available from the command line ("in your path"). A typical user will install `Anaconda`, open a terminal, navigate via the command line to the location of this cloned repository, and proceed to the [DSCIM](DSCIM) subdirectory by typing:

```
cd DSCIM
```

Next, set up an environment with

```
conda env create -f environment.yml
```

and then activate the environment with

```
conda activate dscim-epa
```

With the environment setup and active, the next step is to download required input data into the local directory. From the command line type:

```
python scripts/directory_setup.py
```

Note that this will download several gigabytes of data and may take several minutes, depending on your connection speed.

After setting up your environment and the input data, you can run SC-GHG calculations under different conditions with

```bash
python scripts/command_line_scghg.py
```

and follow the on-screen prompts. When the selector is a carrot (`>`), you may only select one option. Use the arrow keys on your keyboard to highlight your desired option and click enter to submit. When you are presented with `X` and `o` selectors, you may use the spacebar to select (`X`) or deselect (`o`) then click enter to submit once you have chosen your desired number of parameters. Once you have completed all of the options, the DSCIM run will begin.

**Note:** Estimation time for the DSCIM damage module with a single gas and single emissions year takes approximately 1 minute (varies by machine). 

## The Greenhouse Gas Impact Value Estimator (GIVE)
Replicating the estimates from GIVE can be done by following the steps outlined here and assumes that the user has downloaded and installed *Julia*. Begin by opening a terminal and navigating via the command line to the location of the cloned respository (as outlined [above](#getting-started)). Then, navigate to the [code](GIVE/code) subdirectory by typing:

```
cd GIVE\code
```

The directory `GIVE\code` should be the current location of the terminal. This directory includes two replication scripts: `estimate_give_scghg.jl` and `estimate_give_scghg_parallel.jl`. 

### Estimate a single gas and single emissions year
To estimate the SC-GHG for one gas (e.g., $CO_2$) for one emissions year (e.g., 2020), open the script `estimate_give_scghg.jl` to select the year (line 29) and the gas (line 35). Save the changes (re-save the file). Then, on the command line, type:

```
julia estimate_give_scghg.jl
```

**Note:** Estimation time for the GIVE damage module using 10,000 Monte Carlo draws for a single gas and single emissions year takes approximately 7 hours (varies by machine). 

### Estimate multiple gases and/or multiple emissions years in parallel
If the replication machine has more than one processor available (e.g., CPU, core), they can be put to use with the script `estimate_give_scghg_parallel.jl`. Each `gas + emissions year` pair requires 1 processor. Around line 81 is the command `addprocs()`. Select the desired number of processors to allocate. There are 21 total pairs (3 gases and 7 emissions years), which is the default number requested in the code. Then, on the command line, type:

```
julia estimate_give_scghg_parallel.jl
```

**Note:** Estimation time for the GIVE damage module using 10,000 Monte Carlo draws for each `gas + emissions year` pair (one pair per processor) takes approximately 8 hours per pair (varies by machine). Estimation time can take longer if running many `gas + emissions year` pairs at once (in parallel). On some machines, when running all 21 `gas + emissions year` pairs, estimation time has taken up to 14 hours per pair. In general, running all 3 gases and 7 emissions year pairs (21 in total) requires over 175 processor-hours (varies by machine). Users should plan to allocate 5GB of memory per processor.   

## The Meta-Analysis
Replicating the estimates from the Meta-Analysis can be done by following the steps outlined here and assumes that the user has downloaded and installed *Julia*. Begin by opening a terminal and navigating via the command line to the location of the cloned repository (as outlined [above](#getting-started)). Then, navigate to the [code](Meta-Analysis/code) subdirectory by typing:

```
cd Meta-Analysis\code
```

The directory `Meta-Analysis\code` should be the current location in the terminal. This directory includes two replication scripts: `estimate_meta_analysis_scghg.jl` and `estimate_meta_analysis_scghg_parallel.jl`. 

### Estimate a single gas and single emissions year
To estimate the SC-GHG for one gas (e.g., $CO_2$) for one emissions year (e.g., 2020), open the script `estimate_meta_analysis_scghg.jl` to select the year (line 29) and the gas (line 35). Save the selection. Then, on the command line, type:

```
julia estimate_meta_analysis_scghg.jl
```

**Note:** Estimation time for the Meta-Analysis damage module using 10,000 Monte Carlo draws for a single gas and single emissions year takes approximately 3 hours (varies by machine). 

### Estimate multiple gases and/or multiple emissions years in parallel
If the replication machine has more than one processor available (e.g., CPU, core), they can be put to use with the script `estimate_meta_analysis_scghg_parallel.jl`. Each `gas + emissions year` pair requires 1 processor. Around line 81 is the command `addprocs()`. Select the desired number of processors to allocate. There are 21 total pairs (3 gases and 7 emissions years), which is the default number requested in the code. Then, on the command line, type:

```
julia estimate_meta_analysis_scghg_parallel.jl
```

**Note:** Estimation time for the Meta-Analysis damage module using 10,000 Monte Carlo draws for each `gas + emissions year` pair (one pair per processor) takes approximately 3 hours per pair (varies by machine). Estimation time can take longer if running many `gas + emissions year` pairs at once (in parallel). On some machines, when running all 21 `gas + emissions year` pairs, estimation time has taken up to 4 hours per pair. In general, running the model for all 3 gases and 7 emissions year pairs (21 in total) requires over 60 processor-hours (varies by machine). Users should plan to allocate approximately 3GB of memory per processor.   

# Compiling SC-GHG Estimates and Producing the Annual Tables
This repository already includes all estimates from running the three damage modules outlined above, located in the `output` subdirectory under each module's folder. The combined final estimates (simple averages across the three damage modules) are also already included in this repository under the [EPA](EPA) directory [`EPA\output\scghg_annual.csv`](/EPA/output/scghg_annual.csv). A user can replicate this averaging and interpolation to recover the annual SC-GHGs by using the *R* code provided in the [EPA](EPA) directory. Begin by navigating to the [EPA](EPA) directory in the file explorer (or equivalent). Open the *R* project titled `EPA.Rproj`. Then, naviate to the [code](EPA/code) subdirectory and open `compile_scghgs.R`. All remaining steps are documented in the code. 

# Replicating the Bauer and Rudebusch (2021) Term Structures and Newell, Pizer, and Prest (2022) Preference Parameters
This repository already includes the term structure and calibrated $\rho$ and $\eta$ parameters, located in the [EPA\output\discounting](EPA/output/discounting) subdirectory in the file [calibrated_rho_eta.csv](EPA/output/discounting/calibrated_rho_eta.csv). The replication code for these is also included in the [EPA](/EPA) directory. Navigate to the [EPA](/EPA/) directory in the file explorer or equivalent. Open the *R* project titled `EPA.Rproj`. Then, naviate to the [code](EPA/code) subdirectory and open the desired script. The script `replicate_bauer_and_rudebusch_term_structures.R` produces the term structure that is then used in the calibration of $\rho$ and $\eta$ in `calibrate_rho_and_eta.R`. All remaining steps are documented in the code. 

# Additional Information
DSCIM is a product of [The Climate Impact Lab](https://impactlab.org/) in collaboration with [The Rhodium Group](https://rhg.com/). Addional information on DSCIM, including additional functionality, can be found in the user manual ([CIL 2023](DSCIM/CIL_DSCIM_User_Manual.pdf)) and in the [README](DSCIM/README.md) within the [DSCIM](DSCIM) subdirectory.

Both the GIVE and Meta-Analysis estimates are performed using the [MimiGIVE](https://github.com/rffscghg/MimiGIVE.jl) model, published by [Rennert et al. (2022b)](https://www.nature.com/articles/s41586-022-05224-9) as a product of the [Social Cost of Carbon Initiative](https://www.rff.org/topics/scc/social-cost-carbon-initiative/), a collaborative effort led by [Resources for the Future](https://www.rff.org/) and the [Energy Resources Group](https://erg.berkeley.edu/) at the University of California Berkeley. Additional functionality within this model can be found in the [MimiGIVE](https://github.com/rffscghg/MimiGIVE.jl) repository.

# License
The software code contained within this repository is made available under the [MIT license](http://opensource.org/licenses/mit-license.php). Any data and figures are made available under the [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/) license.

# Citations
Bauer, M.D. and G.D. Rudebusch. 2021. The rising cost of climate change: evidence from the bond market. _The Review of Economics and Statistics_.

Carleton, T., A. Jina, M. Delgado, M. Greenstone, T. Houser, S. Hsiang, A. Hultgren, R. Kopp, K. McCusker, I. Nath, J. Rising, A. Ashwin, H Seo, A. Viaene, J. Yaun, A. Zhang. 2022. Valuing the Global Mortality Consequences of Climate Change Accounting for Adaptation Costs and Benefits. _The Quarterly Journal of Economics._ 

Climate Impact Lab (CIL). 2023. Data-driven Spatial Climate Impact Model User Manual, Version 092023-EPA.

Howard, P., and T. Sterner. 2017. Few and Not So Far Between: A Meta-Analysis of Climate Damage Estimates. _Environmental and Resource Economics_.

Newell, R., W. Pizer, and B. Prest. 2022. A Discounting Rule for the Social Cost of Carbon. _Journal of the Association of Environmental and Resource Economists_.

Rennert, K., F. Errickson, B. Prest, L. Rennels, R. Newell, W. Pizer, C. Kingdon, J. Wingenroth, R. Cooke, B. Parthum, D. Smith, K. Cromar, D. Diaz, F. Moore, U. Müller, R. Plevin, A. Raftery, H. Ševčíková, H. Sheets, J. Stock, T. Tan, M. Watson, T. Wong, and D. Anthoff. 2022b. Comprehensive Evidence Implies a Higher Social Cost of CO2. _Nature_.

Rode, A., T. Carleton, M. Delgado, M. Greenstone, T. Houser, S. Hsiang, A. Hultgren, A. Jina, R.E. Kopp, K.E. McCusker, and I. Nath. 2021. Estimating a social cost of carbon for global energy consumption. _Nature_.
