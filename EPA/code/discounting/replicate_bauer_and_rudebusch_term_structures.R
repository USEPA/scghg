## written by: US EPA, National Center for Environmental Economics; September 2022
## generate the Bauer and Rudebush (2020) term structures for various starting rates

##########################
#################  library
##########################

## clear workspace
rm(list = ls())
gc()

## this function will check if a package is installed, and if not, install it
list.of.packages <- c('tidyverse')
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, repos = "http://cran.rstudio.com/")
lapply(list.of.packages, library, character.only = TRUE)

##########################
#################### parts
##########################

## near term starting rates
r0s = c(0.015, 0.02, 0.025)

## simulate rates for N=10,000 trials out tt=500 years
N  = 1e4
tt = 500

# set seed to be used
set.seed(1)

## set up array to store results
start_rates <- paste0(r0s*100, "%")
ce.store = 
  array(NA, 
        dim      = c(tt, length(r0s)),
        dimnames = list(1:tt, start_rates))

##########################
###################### run
##########################

## use inverse gamma distribution (the BR prior distribution), calibrated to match the provided posterior quantiles
## this is used to adjust the inverse gamma to match the provided BR posterior
adj.factor = (1.003*0.2047/0.10)^2 
sig        = sqrt(1/rgamma(N, shape=100/2, scale=0.04*(100+2)/2)*adj.factor)/100 

## generate innovations/shocks (epsilon)
set.seed(1)
head(rnorm(tt*N, 0, sig)) ## check values
eps = matrix(NA, nrow = tt, ncol = N)
for (t in 1:tt) eps[t,] = rnorm(N, 0, sig)

## the first period has no shock to fix starting point
eps[1,] = 0 

## accumulated shocks
eps.cum = apply(eps, 2, cumsum)

## recover path for each starting rate
for (i in 1:length(r0s)) {
  
  ## starting rate
  r0 = r0s[i]
  
  ## add shock
  r = r0 + eps.cum
  
  ## impose the constraint that average rates cannot be negative.
  DF = apply(r, 2, function(x) exp(-cumsum(x)))
  
  ## find the minimum
  DF = pmin(DF, 1)
  
  ## get the mean
  E.DF = apply(DF, 1, mean)
  
  ## recover term structures
  ce.store[,i] = log(E.DF)/-c(1:tt)
}

## export
ce.store %>% 
  as_tibble %>% 
  write_csv('output/discounting/bauer_and_rudebusch_term_structures.csv')

## end of script, have a great day.