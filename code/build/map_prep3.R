## Reads in and processes data on LA Metro station and track locations,
## mergint to 1990 tracts and 2010 tracts
rm(list = ls())

library(sp)
library(rgeos)
library(raster)
library(sf)
library(tidyverse)
library(rgdal)
library(dplyr)
library(Matrix)
#library(gdata)
library(ggplot2)

###############
## FUNCTIONS ##

remove.bad.geography <- function(shapefile, epsg) {
  require(rgdal)
  require(rgeos)
  require(sp)
  
  temp_st <- readOGR(shapefile)
  cleaned_st <- gBuffer(temp_st, byid=TRUE, width=0)
  if (sum(gIsValid(cleaned_st, byid=TRUE)==FALSE)==0) {
    cleaned_sf <- st_as_sf(cleaned_st, stringsAsFactors=FALSE) %>%
      st_transform(epsg)
    return(cleaned_sf)
  } else {
    print("Could not clean geographies")
  }
  
  # Reference:
  # https://gis.stackexchange.com/questions/163445/r-solution-for-topologyexception-input-geom-1-is-invalid-self-intersection-er/163480#163480
}

##############

# Pull in relevant data, define to appropriate projection
geogpath <- "C:/Dropbox/Dropbox/Data_Projects/JMP/Data/Geographies/"
datapath <- "C:/Dropbox/Dropbox/Data_Projects/JMP/Simulations/data/"
metropath <- "C:/Dropbox/Dropbox/Data_Projects/JMP/Data/Metro/"
oldmaps <- "C:/Dropbox/Dropbox/Data_Projects/JMP/Data/OldMaps/"
#geogpath <- "D:/Current_Research/JMP/Data/Geographies/"
#datapath <- "D:/Current_Research/JMP/Simulations/data/"
#metropath <- "D:/Current_Research/JMP/Data/Metro/"
#oldmaps <- "D:/Current_Research/JMP/Data/OldMaps/"
CAepsg <- "+init=epsg:3310" # California Albers in meters

# This function ensures that there are no self-intersecting rings
caTract1990 <- remove.bad.geography(paste(geogpath, "CA_tract_1990.shp", sep = ""), CAepsg)

# Trim data to remove excess tracts
soCalTract1990 <- caTract1990 %>% 
  filter(NHGISCTY=="0370" | NHGISCTY=="0590" | NHGISCTY=="0650" | NHGISCTY=="0710" | NHGISCTY=="1110")

rm(caTract1990)

# Make a conformable name
soCalTract1990$namelen <- apply(soCalTract1990,2,nchar)[,3]
soCalTract1990$tract_id <- substring(soCalTract1990$GISJOIN,3)
soCalTract1990$tract_id[soCalTract1990$namelen==12] <- paste(soCalTract1990$tract_id[soCalTract1990$namelen==12],"00", sep = "")

soCalTract1990 <- within(soCalTract1990, rm(namelen)) 
soCalTract1990 <- rename(soCalTract1990, "tract_w"="tract_id")

# Read in workplace data
soCalTract1990 <- read.csv(paste(datapath,"pow.csv", sep=""), header=TRUE) %>%
  merge(soCalTract1990, ., all.x = TRUE)

# Read in residential data
soCalTract1990 <- rename(soCalTract1990, "tract_h"="tract_w")
soCalTract1990 <- read.csv(paste(datapath,"res.csv", sep=""), header=TRUE) %>%
  merge(soCalTract1990, ., all.x = TRUE)
soCalTract1990 <- rename(soCalTract1990, "tract_id"="tract_h")

tractlist <- soCalTract1990$tract_id
N <- length(tractlist)

# wage <- soCalTract1990$wagePOW
# tran00_w <- soCalTract1990$tran00_w
# tran05_w <- soCalTract1990$tran05_w
# cdist_w <- soCalTract1990$cent_distance1999_w
# hval <- soCalTract1990$hval_50
# tran00_h <- soCalTract1990$tran00_h
# tran05_h <- soCalTract1990$tran05_h
# cdist_h <- soCalTract1990$cent_distance1999_h

# Read in flow data
# flow_data <- read.csv(paste(datapath,"flows.csv", sep=""), header=TRUE)
# 
# flowmat <- Matrix(0, N, N, sparse=TRUE)
# tmat00 <- Matrix(0, N, N, sparse=TRUE)
# tmat05 <- Matrix(0, N, N, sparse=TRUE)
# 
# for (i in 1:nrow(flow_data)) {
#   rnum <- grep(flow_data$tract_h[i], tractlist)
#   cnum <- grep(flow_data$tract_w[i], tractlist)
#   
#   flowmat[rnum,cnum] <- flow_data$wtflow5b[i]
#   tmat00[rnum,cnum] <- flow_data$tran00_cc[i]
#   tmat05[rnum,cnum] <- flow_data$tran05_cc[i]
# }

#gdata::keep(wage, tran00_w, tran05_w, cdist_w, hval, tran00_h, tran05_h, cdist_h, flowmat, tmat00, tmat05, sure=TRUE)   

######################
## Additional Details
#####################

## Subcounties ##
LAsubcty <- remove.bad.geography(paste(geogpath, "US_cty_sub_1990Consolidated.shp", sep = ""), CAepsg) %>%
  filter(COUNTY=="06037")

# Prep metro station data
allStations2015 <- st_read(paste(metropath, "RailStations0715/", "Stations_All_0715.shp", sep = "")) %>%
  st_transform(CAepsg)

allStations2016 <- st_read(paste(metropath, "Stations_All_0316/", "Stations_All_0316.shp", sep = "")) %>%
  st_transform(CAepsg)

allStations2000 <- allStations2015 %>%
  filter(LINE=="Blue" | LINE=="BLUE/EXPO" | LINE=="Red" | LINE=="Red/Purple" | LINE=="Purple" | LINE=="Green")

allStations1999 <- allStations2000 %>%
  filter(STOPNUM!=80201 & STOPNUM!=80202 & STOPNUM!=80203)

# Read in metro lines (tracks), and clean to 1999
blueLines2015 <- st_read(paste(metropath, "RailLines0614/", "BlueLine0412.shp", sep = "")) %>%
  st_transform(CAepsg)
blueLines2015 <- subset(blueLines2015, select=-c(LINE, Feet))

greenLines2015 <- st_read(paste(metropath, "RailLines0614/", "GreenLine0412.shp", sep = "")) %>%
  st_transform(CAepsg)
greenLines2015$PATH_ID <- 101:(100+nrow(greenLines2015))
greenLines2015 <- subset(greenLines2015, select=-c(MTFCC, Feet))

rpLines2015 <- st_read(paste(metropath, "RailLines0614/", "RPLines0414.shp", sep = "")) %>%
  st_transform(CAepsg)
rpLines2015$PATH_ID <- 201:(200+nrow(rpLines2015))
rpLines2015 <- subset(rpLines2015, select=-c(FNODE_, TNODE_, LPOLY_, RPOLY_, LENGTH, line))

allLinesPre <- rbind(blueLines2015, greenLines2015, rpLines2015)

allLines <- allLinesPre %>%
  filter(PATH_ID!=206 & PATH_ID!=207 & PATH_ID!=208 & PATH_ID!=210 & PATH_ID!=211 & PATH_ID!=220 & PATH_ID!=221)  

# Read in old maps
lines1925All <- st_read(paste(oldmaps, "Both1925Lines_notPER.shp", sep = "")) %>%
  st_transform(CAepsg)
lines1925Immediate <- st_read(paste(oldmaps, "ImmediateConstr.shp", sep = "")) %>%
  st_transform(CAepsg)
linesPER <- st_read(paste(oldmaps, "PER_All_LA_1925.shp", sep = "")) %>%
  st_transform(CAepsg)

######################
## To make map for central LA
#####################

sct <- soCalTract1990

## Treatment definition
sct$tc00 <- (sct$distance1999_h==0 | sct$cent_distance1999_h<500)
sct$tc02 <- (sct$distance1999_h<250 & sct$tc00!=TRUE) 
sct$tc05 <- (sct$distance1999_h<500 & sct$tc00!=TRUE & sct$tc02!=TRUE) 


sct$trstatSim[sct$tc00==TRUE] <- 0
sct$trstatSim[sct$tc02==TRUE] <- 1
sct$trstatSim[sct$tc05==TRUE] <- 2
sct$trstatSim[sct$Sim10_tr_h==1 & sct$tc00==FALSE & sct$tc02==FALSE & sct$tc05==FALSE] <- 3
sct$trstatSim[sct$Sal10_tr_h==1 & sct$tc00==FALSE & sct$tc02==FALSE & sct$tc05==FALSE & sct$Sim10_tr_h==0] <- 4
sct$trstatSim[is.na(sct$trstatSim)] <- 5

sct$trstatSal[sct$tc00==TRUE] <- 0
sct$trstatSal[sct$tc02==TRUE] <- 1
sct$trstatSal[sct$tc05==TRUE] <- 2
sct$trstatSal[sct$Sal10_tr_h==1 & sct$tc00==FALSE & sct$tc02==FALSE & sct$tc05==FALSE] <- 3
sct$trstatSal[is.na(sct$trstatSal)] <- 4

sct$trstatPER[sct$tc00==TRUE] <- 0
sct$trstatPER[sct$tc02==TRUE] <- 1
sct$trstatPER[sct$tc05==TRUE] <- 2
sct$trstatPER[sct$PER10_tr_h==1 & sct$tc00==FALSE & sct$tc02==FALSE & sct$tc05==FALSE] <- 3
sct$trstatPER[is.na(sct$trstatPER)] <- 4


## Bounding Box
mapRange <- c(range(st_coordinates(sct)[,1]),range(st_coordinates(sct)[,2]))
mapRange2 <- c(140000, 180000, -472000, -429000)

windows()


## Narrow, 1925 Lines
g1a <- ggplot() + 
  geom_sf(data=sct, aes(fill=as.factor(sct$trstatSim)), color = "gray82") + 
  scale_fill_manual(values=c("dodgerblue3","dodgerblue","cadetblue3","goldenrod1","lightgoldenrod1","white"), 
                    labels = c("Contains Station", "Station<250m", "Station<500m","Control: Immediate 1925","Control: All 1925",""),
                    name = "Census Tracts",
                    guide = guide_legend(override.aes=list(linetype = "blank", pch = NA))) +
  theme_minimal() + 
  geom_sf(data=allLines, aes(color="A"), lwd=1.2, show.legend = "line") +
  geom_sf(data=lines1925All, aes(color="B"), linetype="dashed", lwd=1, show.legend = "line") +
  scale_color_manual(values = c("A" =  "mediumvioletred", "B" = "olivedrab"), 
                     labels = c("Metro Lines (by 1999)", "1925 Plan Proposed Lines"),
                     name = "Lines",
                     guide = guide_legend(override.aes=list(pch = NA))) +
  geom_sf(data=allStations1999, aes(alpha="X1"), color="green", shape=16, size=2, show.legend = "point") +
  #geom_sf(data=allStations1999, aes(alpha="X1"), color="black", shape=20, size=1, show.legend = "point") +
  geom_sf(data=allStations1999, aes(alpha="X1"), color="black", shape=21, size=2, fill=NA, show.legend = "point") +
  scale_alpha_manual(values = c("X1" =  1), 
                     labels = c("Stations (by 1999)"),
                     name = "Stations",
                     guide = guide_legend(override.aes=list(linetype = "blank"))) +
  geom_sf(data=LAsubcty, fill=NA, color = "black") +
  coord_sf(xlim=mapRange2[c(1:2)], ylim=mapRange2[c(3:4)])

g1a


g2a <- ggplot() + 
  geom_sf(data=sct, aes(fill=as.factor(sct$trstatSal)), color = "gray82") + 
  scale_fill_manual(values=c("dodgerblue3","dodgerblue","cadetblue1","goldenrod1","white"), 
                    labels = c("OD00", "OD25", "OD50","Control",""),
                    name = "Census Tracts",
                    guide = guide_legend(override.aes=list(linetype = "blank", pch = NA))) +
  theme_minimal() + 
  geom_sf(data=allLines, aes(color="A"), lwd=1.2, show.legend = "line") +
  geom_sf(data=lines1925All, aes(color="B"), linetype="dashed", lwd=1, show.legend = "line") +
  scale_color_manual(values = c("A" =  "mediumvioletred", "B" = "olivedrab"), 
                     labels = c("Metro Lines (by 1999)", "1925 Plan Proposed Lines"),
                     name = "Lines",
                     guide = guide_legend(override.aes=list(pch = NA))) +
  geom_sf(data=allStations1999, aes(alpha="X1"), color="green", shape=16, size=2, show.legend = "point") +
  #geom_sf(data=allStations1999, aes(alpha="X1"), color="black", shape=20, size=1, show.legend = "point") +
  geom_sf(data=allStations1999, aes(alpha="X1"), color="black", shape=21, size=2, fill=NA, show.legend = "point") +
  scale_alpha_manual(values = c("X1" =  1), 
                     labels = c("Stations (by 1999)"),
                     name = "Stations",
                     guide = guide_legend(override.aes=list(linetype = "blank"))) +
  geom_sf(data=LAsubcty, fill=NA, color = "black") +
  coord_sf(xlim=mapRange2[c(1:2)], ylim=mapRange2[c(3:4)])

g2a


g3a <- ggplot() + 
  geom_sf(data=sct, aes(fill=as.factor(sct$trstatPER)), color = "gray82") + 
  scale_fill_manual(values=c("dodgerblue3","dodgerblue","cadetblue1","goldenrod1","white"), 
                    labels = c("Contains Station", "Station<250m", "Station<500m","Control: PER Lines",""),
                    name = "Census Tracts",
                    guide = guide_legend(override.aes=list(linetype = "blank", pch = NA))) +
  theme_minimal() + 
  geom_sf(data=allLines, aes(color="A"), lwd=1.2, show.legend = "line") +
  geom_sf(data=linesPER, aes(color="B"), linetype="dashed", lwd=1, show.legend = "line") +
  scale_color_manual(values = c("A" =  "mediumvioletred", "B" = "olivedrab"), 
                     labels = c("Metro Lines (by 1999)", "PER Lines (1925)"),
                     name = "Lines",
                     guide = guide_legend(override.aes=list(pch = NA))) +
  geom_sf(data=allStations1999, aes(alpha="X1"), color="green", shape=16, size=2, show.legend = "point") +
  #geom_sf(data=allStations1999, aes(alpha="X1"), color="black", shape=20, size=1, show.legend = "point") +
  geom_sf(data=allStations1999, aes(alpha="X1"), color="black", shape=21, size=2, fill=NA, show.legend = "point") +
  scale_alpha_manual(values = c("X1" =  1), 
                     labels = c("Stations (by 1999)"),
                     name = "Stations",
                     guide = guide_legend(override.aes=list(linetype = "blank"))) +
  geom_sf(data=LAsubcty, fill=NA, color = "black") +
  coord_sf(xlim=mapRange2[c(1:2)], ylim=mapRange2[c(3:4)])

g3a








