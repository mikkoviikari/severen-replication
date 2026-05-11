## Master script

rm(list = ls())

# Define project directory
cdir <- getwd()  # set working directory to project root before running

###########################
## BELOW THIS POINT, code should just run ##

setwd(cdir)

library(dplyr)
library(purrr)
library(sf)
library(Matrix)

CAepsg <- "+init=epsg:3310"

soCalTract90 <- st_read("./data/Geographies/CA_tract_1990.shp", quiet = TRUE) %>%
  st_make_valid() %>%
  st_transform(CAepsg) %>%
  filter(NHGISCTY=="0370" | NHGISCTY=="0590" | NHGISCTY=="0650" | NHGISCTY=="0710" | NHGISCTY=="1110")

####### Code Calls #######

source("./code/welfare/prep_simdata.R")
source("./code/welfare/run_welfare_main.R")
source("./code/welfare/run_welfare_bootstrap.R")
