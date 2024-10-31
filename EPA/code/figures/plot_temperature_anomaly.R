##########################
#################  library
##########################

## clear workspace
rm(list = ls())
gc()

## This function will check if a package is installed, and if not, install it
list.of.packages <- c('magrittr','tidyverse',
                      'arrow',
                      'ggplot2','ggrepel','ggpubr',
                      'showtext')
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, repos = "http://cran.rstudio.com/")
lapply(list.of.packages, library, character.only = TRUE)

##########################
#################### parts
##########################

## colorblind friendly palette from http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/
colors = c("#000000", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#999999") ## no pink

## add fonts
font_add_google("Quattrocento Sans", "sans-serif")
showtext_auto()

## function to prepare data for plots
plot.data = function(x) {
  x %>% 
    group_by(year, gas) %>%
    summarise(mean = mean(value),
              med  = median(value),
              min  = min(value),
              max  = max(value),
              q01  = quantile(value,.01),
              q05  = quantile(value,.05),
              q95  = quantile(value,.95),
              q99  = quantile(value,.99),
              .groups = 'drop')
}

##########################
####################  data
##########################

## from EPA/code/run_mimifair.jl
fair = 
  left_join(read_parquet('../GIVE/output/mimifair/save_list/CO2-2030-SSP245/results/model_1/global_temperature_norm.parquet') %>%
              rename(year     = time, 
                     baseline = 2, 
                     trial    = trialnum) %>%
              filter(year>2019) %>%
              mutate(gas = 'co2'),
            read_parquet('../GIVE/output/mimifair/save_list/CO2-2030-SSP245/results/model_2/global_temperature_norm.parquet') %>%
              rename(year      = time, 
                     perturbed = 2, 
                     trial     = trialnum) %>%
              filter(year > 2019) %>%
              mutate(gas = 'co2')) %>%
  mutate(value = perturbed - baseline) %>%
  select(year, gas, trial, value) %>% 
  plot.data %>%
  mutate(labels   = case_when(year == 2300 ~ paste0('FaIR 1.6.2'), 
                              T            ~ ''),
         group    = paste0('FaIR 1.6.2'),
         version  = 'FaIR 1.6.2',
         scenario = 'ssp245')

## hector
hector = 
  left_join(  
    read_csv('output/external_data/hector/Hector_pulse_exp.csv',
             show_col_types = F) %>% 
      filter(between(year, 2020, 2300)) %>% 
      separate(scenario, c('scenario', 'gas')) %>% 
      filter(scenario == 'SSP245',
             is.na(gas),
             variable == 'Tgav') %>% 
      filter(is.na(gas)) %>% 
      rename(temp.baseline = value) %>% 
      select(-gas),
    read_csv('output/external_data/hector/Hector_pulse_exp.csv',
             show_col_types = F) %>% 
      filter(between(year, 2020, 2300)) %>% 
      separate(scenario, c('scenario', 'gas')) %>% 
      filter(scenario == 'SSP245',
             gas      == 'CO2',
             variable == 'Tgav') %>% 
      rename(temp.perturbed = value)
  ) %>% 
  mutate(gas        = tolower(gas),
         scenario   = tolower(scenario),
         temp.delta = case_when(year >= 2030 ~ (temp.perturbed-temp.baseline)/10, 
                                T            ~ 0)) %>% 
  mutate(version = 'HECTOR 2.5',
         labels  = case_when(year == 2300 ~ paste0('HECTOR 2.5','\n', toupper(scenario)), 
                             T            ~ ''),
         group   = paste0(gas,'\n','HECTOR 2.5','\n', scenario))

## magicc
magicc = 
  left_join(
    ## perturbed
    read_csv('output/external_data/magicc/2021_10_06_073341_magicc-pulse-deltas.csv',
             show_col_types = F) %>% 
      separate(scenario, c('scenario', 'gas')) %>% 
      filter(!is.na(gas)) %>% 
      pivot_longer(!c(climate_model, model, quantile, region, scenario, gas, unit, variable), 
                   names_to  = 'year',
                   values_to = 'temp.delta'),
    ## baseline
    read_csv('output/external_data/magicc/2021_10_06_073341_magicc-pulse-deltas.csv',
             show_col_types = F) %>% 
      separate(scenario, c('scenario', 'gas')) %>% 
      filter(is.na(gas)) %>% 
      pivot_longer(!c(climate_model, model, quantile, region, scenario, gas, unit, variable), 
                   names_to  = 'year',
                   values_to = 'temp.baseline') %>% 
      select(-gas)
  ) %>% 
  mutate(year = as.numeric(year), 
         gas  = tolower(gas)) %>% 
  filter(between(year, 2020, 2300),
         gas      == 'co2',
         quantile == 0.5,
         scenario == 'ssp245') %>% 
  mutate(version = 'MAGICC 7.5.3',
         labels  = case_when(year == 2300 ~ paste0('MAGICC 7.5.3','\n', toupper(scenario)), 
                             T ~ ''),
         group   = paste0(gas,'\n','MAGICC 7.5.3','\n', scenario))

##########################
####################  plot
##########################

ggplot() +
  ## fair mean and median
  geom_line(data = fair, 
            aes(x        = year, 
                y        = mean, 
                color    = version, 
                group    = group, 
                linetype = version), 
            size = 1) +
  geom_line(data = fair, 
            aes(x        = year, 
                y        = med, 
                color    = version, 
                group    = group, 
                linetype = 'longdashed'), 
            size = 1) +
  ## fair uncertainty
  geom_ribbon(data = fair,
              aes(x    = year, 
                  ymin = q05, 
                  ymax = q95, 
                  fill = 'grey30'), 
              color       = NA, 
              linetype    = 'dotted',
              alpha       = 0.15, 
              show.legend = F) +
  geom_ribbon(data = fair,
              aes(x    = year, 
                  ymin = q01, 
                  ymax = q99, 
                  fill = 'grey30'), 
              color       = NA, 
              linetype    = 'dotted',
              alpha       = 0.1, 
              show.legend = F) +
  ## magicc
  geom_line(data = magicc, 
            aes(x        = year, 
                y        = temp.delta, 
                color    = version, 
                group    = group, 
                linetype = version), 
            size = 1) + 
  ## hector
  geom_line(data = hector, 
            aes(x        = year, 
                y        = temp.delta, 
                color    = version, 
                group    = group, 
                linetype = version), 
            size = 1) + 
  ## plot formatting
  annotation_custom(
    grob = grid::rectGrob(gp = grid::gpar(col = NA, fill = "white")),
    xmin = 2300
  ) +
  scale_color_manual(values = colors) +
  scale_fill_manual(values = colors) +
  scale_x_continuous(breaks = c(2020, 2050, 2100, 2150, 2200, 2250, 2300), 
                     limits = c(2020, 2300),
                     labels = c(2020, '', 2100, '', 2200, '', 2300)) +
  scale_y_continuous(breaks = scales::pretty_breaks(n = 6))+
  labs(x         = 'Year',
       y         = c(expression(paste('Temperature Anomaly from 1GtC in 2030'))),
       color     = '',
       linetype  = '',
       group     = '',
       fill      = '') +
  theme_minimal() + 
  theme(legend.position  = 'bottom',
        legend.title     = element_text(size=14, color='grey20'),
        legend.text      = element_text(size=14, color='grey20'),
        legend.key.size  = unit(0.75, 'cm'),
        legend.margin    = margin(0, 0, 0, 0),
        axis.title       = element_text(size=14),
        axis.text        = element_text(size=14),
        axis.line.x      = element_line(color = "black"),
        axis.ticks.x     = element_line(color = "black", size=1),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(color='grey70', linetype="dotted"),
        panel.grid.minor = element_blank(),
        plot.caption     = element_text(size=11, hjust=0.5),
        plot.title       = element_text(size=14, hjust=0.5),
        text             = element_text(family="sans-serif", color='grey20')) + 
  guides(linetype = 'none')

ggsave(paste0('output/figures/temp_anomaly_by_climate_model_co2.svg'), 
       width  = 9, 
       height = 6)

## end of script. have a great day!
