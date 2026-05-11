 ## Tract to metro/transit/road distances and adjacencies using 1990 and 2010 census tract definitions

###### Geographies #####

# Generate centroids
soCalCentroid90 = st_centroid(soCalTract90)
soCalCentroid10 = st_centroid(soCalTract10)

######## Metro Data #######
# Prep metro station data
allStations2015 <- st_read("./data/Metro/RailStations0715/Stations_All_0715.shp") %>%
  st_transform(CAepsg) %>% 
  merge(read.csv("./data/Metro/allstations2015_data_small.csv"))

allStations2000 <- allStations2015 %>%
  filter(LINE=="Blue" | LINE=="BLUE/EXPO" | LINE=="Red" | LINE=="Red/Purple" | LINE=="Purple" | LINE=="Green")

allStations1999 <- allStations2000 %>%
  filter(STOPNUM!=80201 & STOPNUM!=80202 & STOPNUM!=80203)

st_write(allStations1999, "./output/mapping/stations_1999.shp", delete_layer = TRUE)

######## Distances #######

soCalTract90$distance1999 <- st_distance(soCalTract90, allStations1999) %>%
  apply(1,min)

i99 <- st_nearest_feature(soCalTract90, allStations1999)
soCalTract90$blueline1999   <- allStations1999$blueline[i99]
soCalTract90$redline1999    <- allStations1999$redline[i99]
soCalTract90$purpleline1999 <- allStations1999$purpleline[i99]
soCalTract90$greenline1999  <- allStations1999$greenline[i99]
soCalTract90$yropen_nearest1999  <- allStations1999$yearopen[i99]

i99_t10 <- st_nearest_feature(soCalTract10, allStations1999)
soCalTract10$blueline1999   <- allStations1999$blueline[i99_t10]
soCalTract10$redline1999    <- allStations1999$redline[i99_t10]
soCalTract10$purpleline1999 <- allStations1999$purpleline[i99_t10]
soCalTract10$greenline1999  <- allStations1999$greenline[i99_t10]

soCalTract90$distance2000 <- st_distance(soCalTract90, allStations2000) %>%
  apply(1,min)
soCalTract90$distance2015 <- st_distance(soCalTract90, allStations2015) %>%
  apply(1,min)
soCalTract10$distance1999 <- st_distance(soCalTract10, allStations1999) %>%
  apply(1,min)
soCalTract10$distance2000 <- st_distance(soCalTract10, allStations2000) %>%
  apply(1,min)
soCalTract10$distance2015 <- st_distance(soCalTract10, allStations2015) %>%
  apply(1,min)

soCalTract90$cent_distance1999 <- st_distance(soCalCentroid90, allStations1999) %>%
  apply(1,min)
soCalTract10$cent_distance1999 <- st_distance(soCalCentroid10, allStations1999) %>%
  apply(1,min)

soCalTract90$cent_distance2015 <- st_distance(soCalCentroid90, allStations2015) %>%
  apply(1,min)
soCalTract10$cent_distance2015 <- st_distance(soCalCentroid10, allStations2015) %>%
  apply(1,min)

# Read in metro lines (tracks), and clean to 1999
blueLines2015 <- st_read("./data/Metro/RailLines0614/BlueLine0412.shp") %>%
  st_transform(CAepsg)
blueLines2015 <- subset(blueLines2015, select=-c(LINE, Feet))

greenLines2015 <- st_read("./data/Metro/RailLines0614/GreenLine0412.shp") %>%
  st_transform(CAepsg)
greenLines2015$PATH_ID <- 101:(100+nrow(greenLines2015))
greenLines2015 <- subset(greenLines2015, select=-c(MTFCC, Feet))

rpLines2015 <- st_read("./data/Metro/RailLines0614/RPLines0414.shp") %>%
  st_transform(CAepsg)
rpLines2015$PATH_ID <- 201:(200+nrow(rpLines2015))
rpLines2015 <- subset(rpLines2015, select=-c(FNODE_, TNODE_, LPOLY_, RPOLY_, LENGTH, line))

allLinesPre <- rbind(blueLines2015, greenLines2015, rpLines2015)

allLines <- allLinesPre %>%
  filter(PATH_ID!=206 & PATH_ID!=207 & PATH_ID!=208 & PATH_ID!=210 & PATH_ID!=211 & PATH_ID!=220 & PATH_ID!=221)  

# Distances from tracts to lines
soCalTract90$tracks_distance1999 <- st_distance(soCalTract90, allLines) %>%
  apply(1,min)
soCalTract10$tracks_distance1999 <- st_distance(soCalTract10, allLines) %>%
  apply(1,min)

###### Highway Confounders ########

# Read in highways
I105 <- st_read("./data/I105/I105.shp") %>%
  st_transform(CAepsg)
NHS <- st_read("./data/I105/CA_NHS_trim.shp") %>%
  st_transform(CAepsg)
majorRoads <- st_read("./data/I105/CA_AllMajor_trim.shp") %>%
  st_transform(CAepsg)

# Distances from tracts to confounders
soCalTract90$distance_I105 <- st_distance(soCalTract90, I105) %>%
  apply(1,min)
soCalTract90$distance_NHS <- st_distance(soCalTract90, NHS) %>%
  apply(1,min)
soCalTract90$distance_Roads <- st_distance(soCalTract90, majorRoads) %>%
  apply(1,min)

###### Old Maps ########

# Read in old maps
lines1925All <- st_read("./data/OldMaps/Both1925Lines_notPER.shp") %>%
  st_transform(CAepsg)
lines1925Immediate <- st_read("./data/OldMaps/ImmediateConstr.shp") %>%
  st_transform(CAepsg)
linesPER <- st_read("./data/OldMaps/PER_All_LA_1925.shp") %>%
  st_transform(CAepsg)

st_write(lines1925All, "./output/mapping/plan1925_lines.shp", delete_layer = TRUE)

# Distances from tracts to old map lines
soCalTract90$distance_lines1925All <- st_distance(soCalTract90, lines1925All) %>%
  apply(1,min)
soCalTract90$distance_lines1925Immediate <- st_distance(soCalTract90, lines1925Immediate) %>%
  apply(1,min)
soCalTract90$distance_linesPER <- st_distance(soCalTract90, linesPER) %>%
  apply(1,min)
soCalTract10$distance_lines1925All <- st_distance(soCalTract10, lines1925All) %>%
  apply(1,min)
soCalTract10$distance_lines1925Immediate <- st_distance(soCalTract10, lines1925Immediate) %>%
  apply(1,min)
soCalTract10$distance_linesPER <- st_distance(soCalTract10, linesPER) %>%
  apply(1,min)

###### Accidental Treatment, etc. ########

blue_list <- c(80113, 80114, 80115, 80116, 80117, 80118, 80119)
red_list <- c(80204, 80205, 80206, 80207, 80208)
green_list <- c(80301, 80302, 80303, 80304)
acci_list <- c(blue_list, red_list, green_list)

allStations1999 <- allStations1999 %>%
  mutate(acci_treat = STOPNUM %in% acci_list)

unbuiltStations <- st_read("./data/ThreeShocks/UnbuiltStations.shp") %>%
  st_transform(CAepsg)

unbuiltLines <- st_read("./data/ThreeShocks/UnbuiltLines.shp") %>%
  st_transform(CAepsg)


# Is nearest tract accidentially treated?
soCalTract90$acci_treat   <- allStations1999$acci_treat[i99]

soCalTract10$acci_treat   <- allStations1999$acci_treat[i99_t10]

# distance unbuilt station
soCalTract90$unbuilt_stdist <- st_distance(soCalTract90, unbuiltStations) %>%
  apply(1,min)
i_unbuilt <- st_nearest_feature(soCalTract90, unbuiltStations)
soCalTract90$unbuilt_group   <- unbuiltStations$Line[i_unbuilt]

soCalTract10$unbuilt_stdist <- st_distance(soCalTract10, unbuiltStations) %>%
  apply(1,min)
i_unbuilt <- st_nearest_feature(soCalTract10, unbuiltStations)
soCalTract10$unbuilt_group   <- unbuiltStations$Line[i_unbuilt]

soCalTract90$unbuilt_stdist_cent <- st_distance(soCalCentroid90, unbuiltStations) %>%
  apply(1,min)
i_unbuilt <- st_nearest_feature(soCalCentroid90, unbuiltStations)
soCalTract90$unbuilt_group_cent   <- unbuiltStations$Line[i_unbuilt]

soCalTract10$unbuilt_stdist_cent <- st_distance(soCalCentroid10, unbuiltStations) %>%
  apply(1,min)
i_unbuilt <- st_nearest_feature(soCalCentroid10, unbuiltStations)
soCalTract10$unbuilt_group_cent   <- unbuiltStations$Line[i_unbuilt]

# distance unbuilt line
soCalTract90$unbuilt_lidist <- st_distance(soCalTract90, unbuiltLines) %>%
  apply(1,min)

soCalTract10$unbuilt_lidist <- st_distance(soCalTract10, unbuiltLines) %>%
  apply(1,min)


###### Save ########

within(as.data.frame(soCalTract90), rm(geometry)) %>% 
  write.csv(file = "./output/intermediate/stationRoads_distances_tracts1990.csv")
within(as.data.frame(soCalTract10), rm(geometry)) %>% 
  write.csv(file = "./output/intermediate/stationRoads_distances_tracts2010.csv")

