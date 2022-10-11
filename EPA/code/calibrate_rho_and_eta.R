## written by: US EPA, National Center for Environmental Economics; September 2022
## calibrates Ramsey formula rho and eta for any given starting rate using RFF-SPs

##########################
#################  library
##########################

## clear workspace
rm(list = ls())
gc()

## this function will check if a package is installed, and if not, install it
list.of.packages <- c('tidyverse', 'data.table', 
                      'arrow',
                      'progress')
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, repos = "http://cran.rstudio.com/")
lapply(list.of.packages, library, character.only = TRUE)

##########################
###################  parts
##########################

## set random seed
set.seed(1)

## number of years over which to optimize eta
n.yrs = 10

## function to return term structure for a given rho/eta pair
findrho = function(eta, 
                   g     = global_growth_percap, 
                   r.target, 
                   n.yrs = na.yrs) {
  disc.facts.g = exp(-eta*apply(g[1:n.yrs,], 2, cumsum))                        ## n.yrs x B
  e.df.g       = apply(disc.facts.g, 1, mean)                                   ## expected discount factor for each year
  r.ce.g       = log(e.df.g) * -1/c(1:n.yrs)
  rho          = r.target - r.ce.g                                              ## for each year, find the rho that works
  rho          = mean(rho)
  return(rho)
}

## function to calculate the fitted CE term structure for any eta/rho pair
calc_scc_ce = function(eta, 
                       rho          = NULL, 
                       g            = global_growth_percap, 
                       return.items = 'all', 
                       n.yrs        = n.yrs,
                       B            = ncol(g), 
                       target.ce) {
  
  if (is.null(rho)) rho = findrho(eta, 
                                  g        = g, 
                                  n.yrs    = n.yrs, 
                                  r.target = round(target.ce[1], 3))
  
  ## compute r = rho + eta*g for each period and state
  r.temp = rho + eta*g
  
  ## compute discount factor for each year and draw (cumsum discounts for each year through t)
  disc.factors     = exp(-apply(r.temp, 2, cumsum))
  r.ce.path        = -log(apply(disc.factors, 1, mean))/1:nrow(disc.factors)
  names(r.ce.path) = rownames(disc.factors)
  
  if (return.items == 'rce') return(r.ce = r.ce.path)
  if (return.items == 'all') {
    return(list(r.ce = data.table(year        = rownames(g), 
                                  r.ce        = r.ce.path, 
                                  r.ce.target = target.ce[1:nrow(g)]),
                rho = rho, 
                eta = eta))
  }
}

## distance function
NP_MWS_ce_dist = function(eta, 
                          target.ce, 
                          n.yrs      = n.yrs, 
                          match.rate = T, ...) {
  ce.temp = 
    calc_scc_ce(eta, 
                return.items = 'rce', 
                n.yrs        = n.yrs, 
                target.ce    = target.ce, 
                ...)
  
  if (match.rate == TRUE) {
    mse = mean((ce.temp - target.ce[1:length(ce.temp)])^2)
  } else {
    DF.fit    = exp(-c(1:length(ce.temp))*ce.temp)
    DF.target = exp(-c(1:length(ce.temp))*(target.ce[1:length(ce.temp)]))
    mse       = mean((DF.fit - DF.target )^2)
  }
  return(mse)
}

##########################
##################### data
##########################

## read in the bauer and rudebusch term structures from replicate_bauer_and_rudebusch_term_structures.R, 
ce.BR = 
  read_csv('output/discounting/bauer_and_rudebusch_term_structures.csv', show_col_types = F)[-1,] %>% 
  as.matrix

## read in RFF-SPs and calculate year-on-year growth rates
full.yoy.g =
  read_parquet('input/rffsp_global.parquet') %>% 
  arrange(rffsp.id, year) %>% 
  group_by(rffsp.id) %>%
  mutate(ypc    = gdp/pop,
         ypc.gr = log(ypc/lag(ypc))) %>%
  select(rffsp.id,year,ypc.gr) %>%
  pivot_wider(names_from  = rffsp.id,
              values_from = ypc.gr) %>%
  select(-year) %>% 
  slice(-1)

## output vector for each term structure
output = 
  array(list(), 
        dim      = c(dim(ce.BR)[2]),
        dimnames = dimnames(ce.BR)[2])

## minimization loop used to calibrate values
for (r in 1:dim(output)) {
  
  ## solve for optimal eta
  sol.temp = 
    nlm(NP_MWS_ce_dist, 
        target.ce = ce.BR[, r], 
        1.3,
        n.yrs     = n.yrs, 
        iterlim   = 1e3, 
        gradtol   = 1e-6,
        g         = full.yoy.g)
  
  ## test
  if (sol.temp$code >= 4) {message(paste(m, r, ' failed')); next}
  
  ## output term structure for optimal eta
  ce.fit = 
    calc_scc_ce(sol.temp$estimate, 
                target.ce = ce.BR[,r], 
                n.yrs     = n.yrs,
                g         = full.yoy.g)
  
  ## find eta when rho is truncated at zero
  if (ce.fit$rho < 0) {
    unconstrained.rho = ce.fit$rho
    unconstrained.eta = ce.fit$eta
    
    eta.grid.temp = seq(0, 2, by = 0.01)
    
    near.term.diff <- function(eta) {
      near.term.g.ce = log(apply(exp(-eta*apply(full.yoy.g[1:n.yrs,], 2, cumsum)), 1, mean)) * -1/c(1:n.yrs)
      return(mean((near.term.g.ce - ce.BR[1:n.yrs,r])^2))
    }
    
    ntd     = sapply(eta.grid.temp, near.term.diff)
    eta.opt = eta.grid.temp[which.min(ntd)]
    
    ce.fit = 
      calc_scc_ce(eta.opt,rho = 0, 
                  target.ce   = ce.BR[,r], 
                  n.yrs       = n.yrs,
                  g           = full.yoy.g)
    ce.fit$unconstrained.rho = unconstrained.rho
    ce.fit$unconstrained.eta = unconstrained.eta
  }
  
  ## save sum of squared errors
  ce.fit$sse = sol.temp$minimum
  
  ## relay results
  output[[r]] = ce.fit
}

## results matrix
results = 
  sapply(output, function(x) c(x$rho, x$eta)) %>% 
  as_tibble %>% 
  mutate(parameter = c('rho','eta')) %>% 
  relocate(parameter)

## export
results %>% 
  write_csv('output/discounting/calibrated_rho_eta.csv')

## end of script, have a great day.