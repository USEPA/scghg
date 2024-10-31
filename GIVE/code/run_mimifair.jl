######################################
############################  preamble
######################################

## set the environment
using Pkg;
Pkg.activate(joinpath(@__DIR__, ".."));

## instantiate the environment
Pkg.instantiate();

## precompile
using Mimi, MimiGIVE, Random, CSV, DataFrames, Statistics;

######################################
##################### model parameters
######################################

## set random seed for monte carlo 
seed = 42;

## set number of monte carlo draws
n = 10000;

## set emissions year
year = 2030;

## choose gas
gas = :CO2;

## set named list of discount rates
discount_rates = 
    [
        (label = "2.0% Ramsey", prtp = exp(0.001972641)-1, eta  = 1.244459020)
    ];

## choose the model objects that you would like to save by uncommenting the lines (optional).
save_list = 
    [
        (:TempNorm_1850to1900, :global_temperature_norm),    # Global surface temperature anomaly (K) from preinudstrial
    ];

## read the series of rffsp-fair pairings. these were randomly selected pairings. read GIVE documentation for other functionality.
fair_parameter_set_ids = CSV.File(joinpath(@__DIR__, "../input/rffsp_fair_sequence.csv"))["fair_id"][1:n];

######################################
############################ run model
######################################
       
## set random seed
Random.seed!(seed);

## get model 
m = MimiGIVE.get_model(socioeconomics_source = :SSP, 
                       SSP_scenario = "SSP245");

## turn off damage sectors for speed since we only want MimiFAIRv1_6_2        
update_param!(m, :DamageAggregator, :include_ag, false)
update_param!(m, :DamageAggregator, :include_cromar_mortality, false)
update_param!(m, :DamageAggregator, :include_slr, false)
update_param!(m, :DamageAggregator, :include_energy, false)
update_param!(m, :DamageAggregator, :include_hs_damage, true)
update_param!(m, :hs_damage, :specification, 7) ## need to have one damage sector on for GIVE to run, this one is computationally fast
update_param!(m, :hs_damage, :effects, :base)

## specify output directory if save_list (above) is not empty (uncomment the next line)
output_dir = joinpath(@__DIR__, "../output/mimifair/save_list/$gas-$year-SSP245")

## run model
Random.seed!(seed);
MimiGIVE.compute_scc(m, 
                     n                       = n , 
                     gas                     = gas, 
                     year                    = year, 
                     discount_rates          = discount_rates, 
                     fair_parameter_set      = :deterministic,           
                     fair_parameter_set_ids  = fair_parameter_set_ids,    
                     save_list               = save_list,                
                     output_dir              = output_dir);              
       
## end of script, have a great day.
