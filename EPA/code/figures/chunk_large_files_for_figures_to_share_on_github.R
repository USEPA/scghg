##########################
#################  library
##########################

## clear workspace
rm(list = ls())
gc()

## this function will check if a package is installed, and if not, install it
list.of.packages <- c('magrittr','tidyverse','data.table','arrow',
                      'stringi')
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, repos = "http://cran.rstudio.com/")
lapply(list.of.packages, library, character.only = TRUE)

##########################
###################  parts
##########################

## function to compress temperatures
compress_temperatures <- function(x) {
  write_parquet(fread(x)[time >= 1900], file.path(path, 'global_temperature_norm.parquet'))
}

##########################
################## process
##########################

## paths to subdirectories
paths = grep('model', list.dirs('../GIVE/output/mimifair/save_list/CO2-2030-SSP245/results/'), value = T)

for (path in paths){
  
  files = list.files(path, pattern = '.csv', full.names = T)
  
  for (file in files){
    
    if (basename(file) == 'TempNorm_1850to1900_global_temperature_norm.csv') {
      compress_temperatures(file)
    }
  }
}

## end of script, have a great day. 