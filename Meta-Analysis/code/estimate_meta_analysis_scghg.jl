######################################
############################  preamble
######################################

## set the environment
using Pkg;
Pkg.activate(joinpath(@__DIR__, ".."));

## instantiate the environment
Pkg.instantiate();

## precompile
using Mimi, MimiGIVE, MimiRFFSPs, DataDeps, Random, CSV, DataFrames, Statistics;

## automatically download data dependancies (rffsps)
datadep"rffsps_v5"

######################################
##################### model parameters
######################################

## set random seed for monte carlo 
seed = 42;

## set number of monte carlo draws
n = 10000;

## set emissions year
year = 2020;

## choose damage sectors
damages = :meta_analysis;

## choose gas
gas = :CO2;

## set named list of discount rates
discount_rates = 
    [
        (label = "1.5% Ramsey", prtp = exp(0.000091496)-1, eta  = 1.016010261),
        (label = "2.0% Ramsey", prtp = exp(0.001972641)-1, eta  = 1.244459020),
        (label = "2.5% Ramsey", prtp = exp(0.004618785)-1, eta  = 1.421158057)
    ];

## choose the model objects that you would like to save by uncommenting the lines (optional).
save_list = 
    [
        # (:Socioeconomic, :co2_emissions),                    # Emissions (GtC/yr)
        # (:Socioeconomic, :ch4_emissions),                    # Emissions (GtCH4/yr)
        # (:Socioeconomic, :n2o_emissions),                    # Emissions (GtN2O/yr)
        # (:Socioeconomic, :population),                       # Country-level population (millions of persons)
        # (:Socioeconomic, :population_global),                # Global population (millions of persons)
        # (:Socioeconomic, :gdp_global),                       # Global GDP (billions of USD $2005/yr)
        # (:PerCapitaGDP, :global_pc_gdp),                     # Global per capita GDP (thousands of USD $2005/yr)
        # (:TempNorm_1850to1900, :global_temperature_norm),    # Global surface temperature anomaly (K) from preinudstrial
        # (:co2_cycle, :co2),                                  # Total atmospheric concentrations (ppm)
        # (:ch4_cycle, :CH₄),                                  # Total atmospheric concentrations (ppb)
        # (:n2o_cycle, :N₂O),                                  # Total atmospheric concentrations (ppb)
        # (:OceanPH, :pH),                                     # Ocean pH levels
        # (:OceanHeatAccumulator, :del_ohc_accum),             # Accumulated Ocean heat content anomaly
        # (:global_sea_level, :sea_level_rise),                # Total sea level rise from all components (includes landwater storage for projection periods) (m)
        # (:DamageAggregator, :total_damage_share),            # Total damages as a share of global GDP 
    ];

## specify your output directory for the save_list items. comment out if save_list is empty
# output_dir = joinpath(@__DIR__, "../output/save_list/$gas-$sector-$year-n$n")

## read the series of rffsp-fair pairings. these were randomly selected pairings. read GIVE documentation for other functionality.
fair_parameter_set_ids = CSV.File(joinpath(@__DIR__, "../input/rffsp_fair_sequence.csv"))["fair_id"][1:n];
rffsp_sampling_ids     = CSV.File(joinpath(@__DIR__, "../input/rffsp_fair_sequence.csv"))["rffsp_id"][1:n];

## GIVE results are in 2005 USD, this is the price deflator to bring the results to 2020 USD. accessed 09/13/2022. source: https://apps.bea.gov/iTable/iTable.cfm?reqid=19&step=3&isuri=1&select_all_years=0&nipa_table_list=13&series=a&first_year=2005&last_year=2020&scale=-99&categories=survey&thetable=
pricelevel_2005_to_2020 = 113.648/87.504;

######################################
####################### estimate scghg
######################################

## set random seed
Random.seed!(seed);

## get model 
m = MimiGIVE.get_model();

## specify meta analysis damages 
update_param!(m, :DamageAggregator, :include_ag, false)
update_param!(m, :DamageAggregator, :include_cromar_mortality, false)
update_param!(m, :DamageAggregator, :include_slr, false)
update_param!(m, :DamageAggregator, :include_energy, false)
update_param!(m, :DamageAggregator, :include_hs_damage, true)
update_param!(m, :hs_damage, :specification, 7)
update_param!(m, :hs_damage, :effects, :base)

## estimate scghg
results = 
    MimiGIVE.compute_scc(m, 
                        n                       = n , 
                        gas                     = gas, 
                        year                    = year, 
                        pulse_size              = 0.0001,                   ## scales the defalut pulse size of 1Gt to 100k metric tons 
                        certainty_equivalent    = true,                     
                        fair_parameter_set      = :deterministic,           ## optionally read the rffsp-fair parameter sequence from file
                        fair_parameter_set_ids  = fair_parameter_set_ids,   ## optionally read the rffsp-fair parameter sequence from file
                        rffsp_sampling          = :deterministic,           ## optionally read the rffsp-fair parameter sequence from file
                        rffsp_sampling_ids      = rffsp_sampling_ids,       ## optionally read the rffsp-fair parameter sequence from file
                        discount_rates          = discount_rates, 
                        # save_list               = save_list,                ## comment out if save_list is empty
                        # output_dir              = output_dir,               ## comment out if save_list is empty
                        save_cpc                = true)                      ## must be true to recover certainty equivalent scghgs

######################################
####################### export results
######################################

## blank data
scghgs = DataFrame(sector = String[], discount_rate = String[], trial = Int[], scghg = Int[]);
    
## populate data
for (k, v) in results[:scc]
    for (i, sc) in enumerate(v.ce_sccs)
        push!(scghgs, (sector = String(k.sector), discount_rate = k.dr_label, trial = i, scghg = round(Int, sc*pricelevel_2005_to_2020)))
    end
end

## export full distribution    
scghgs |> save(joinpath(@__DIR__, "../output/scghgs/full_distributions/$gas/sc-$gas-$damages-$year-n$n.csv"));

## collapse to the certainty equivalent scghgs
scghgs_mean = combine(groupby(scghgs, [:sector, :discount_rate]), :scghg => (x -> round(Int, mean(x))) .=> :scghg)

## export average scghgs    
scghgs_mean |> save(joinpath(@__DIR__, "../output/scghgs/sc-$gas-$damages-$year.csv"));

## end of script, have a great day.