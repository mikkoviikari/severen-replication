## Master script

rm(list = ls())

# Define project directory
cdir <- "C:/Dropbox/Dropbox/Data_Projects/JMP_RR/"

###########################
## BELOW THIS POINT, code should just run ##

setwd(cdir)

library(sp)
library(rgeos)
library(raster)
library(sf)
library(tidyverse)
library(rgdal)
library(gdata)

source("./code/build/local_r_functions.R")

CAepsg <- "+init=epsg:3310" # California Albers in meters

####### Main Geography #######

soCalTract90 <- remove.bad.geography("./data/Geographies/CA_tract_1990.shp", CAepsg) %>%
  filter(NHGISCTY=="0370" | NHGISCTY=="0590" | NHGISCTY=="0650" | NHGISCTY=="0710" | NHGISCTY=="1110")

# This function ensures that there are no self-intersecting rings
soCalTract10 <- remove.bad.geography("./data/Geographies/CA_tract_2010.shp", CAepsg) %>% 
  filter(COUNTYFP10=="037" | COUNTYFP10=="059" | COUNTYFP10=="065" | COUNTYFP10=="071" | COUNTYFP10=="111")

####### Code Calls #######

source("./code/build/make_geoCrossWalk.R")
keep(cdir, CAepsg, soCalTract90, soCalTract10, remove.bad.geography, sure=TRUE)

source("./code/build/make_subcountyCrossWalk.R")
keep(cdir, CAepsg, soCalTract90, soCalTract10, remove.bad.geography, sure=TRUE)

source("./code/build/make_tract2tractDistance.R")
keep(cdir, CAepsg, soCalTract90, soCalTract10, remove.bad.geography, sure=TRUE)

source("./code/build/make_tract2stationDistance.R")
keep(cdir, CAepsg, soCalTract90, soCalTract10, remove.bad.geography, sure=TRUE)

source("./code/build/make_tract2stationLEHD.R")
keep(cdir, CAepsg, soCalTract90, soCalTract10, remove.bad.geography, sure=TRUE)

source("./code/build/make_landuseScag.R")
keep(cdir, CAepsg, soCalTract90, soCalTract10, remove.bad.geography, sure=TRUE)

WORK IN hereR scripts

"./code/build/get_routesHere.R"

"./graphhopper/la-1/la_routingscripts.R"
"./code/build/prep_routing.R"
