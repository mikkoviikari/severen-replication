# Generate centroids
soCalTract2010 <- remove.bad.geography("./data/Geographies/CA_tract_2010.shp", CAepsg) %>% 
  filter(COUNTYFP10=="037" | COUNTYFP10=="059" | COUNTYFP10=="065" | COUNTYFP10=="071" | COUNTYFP10=="111")

soCalCentroid10 = st_centroid(soCalTract2010)

# Prep metro station data
allStations2015 <- st_read("./data/Metro/RailStations0715/Stations_All_0715.shp") %>%
  st_transform(CAepsg)

allStations2000 <- allStations2015 %>%
  filter(LINE=="Blue" | LINE=="BLUE/EXPO" | LINE=="Red" | LINE=="Red/Purple" | LINE=="Purple" | LINE=="Green")


# Distances between metro stations and tracts
soCalTract2010$distance2000 <- st_distance(soCalTract2010, allStations2000) %>%
  apply(1,min)
soCalTract2010$distance2015 <- st_distance(soCalTract2010, allStations2015) %>%
  apply(1,min)

soCalTract2010$cent_distance2000 <- st_distance(soCalCentroid10, allStations2000) %>%
  apply(1,min)
soCalTract2010$cent_distance2015 <- st_distance(soCalCentroid10, allStations2015) %>%
  apply(1,min)

# Read in old maps
lines1925All <- st_read("./data/OldMaps/Both1925Lines_notPER.shp") %>%
  st_transform(CAepsg)
lines1925Immediate <- st_read("./data/OldMaps/ImmediateConstr.shp") %>%
  st_transform(CAepsg)
linesPER <- st_read("./data/OldMaps/PER_All_LA_1925.shp") %>%
  st_transform(CAepsg)

# Distances from tracts to old map lines
soCalTract2010$distance_lines1925All <- st_distance(soCalTract2010, lines1925All) %>%
  apply(1,min)
soCalTract2010$distance_lines1925Immediate <- st_distance(soCalTract2010, lines1925Immediate) %>%
  apply(1,min)
soCalTract2010$distance_linesPER <- st_distance(soCalTract2010, linesPER) %>%
  apply(1,min)

# Read in metro lines (tracks)
blueLines2015 <- st_read("./data/Metro/RailLines0614/BlueLine0412.shp")  %>%
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

exLines2015 <- st_read("./data/Metro/RailLines0614/ExpoLine0512.shp") %>%
  st_transform(CAepsg)
exLines2015$PATH_ID <- 301:(300+nrow(exLines2015))
exLines2015 <- subset(exLines2015, select=-c(NAME, ID, PHASE, Lenth))

goldLines2015 <- st_read("./data/Metro/RailLines0614/GoldLineApr12.shp") %>%
  st_transform(CAepsg)
goldLines2015$PATH_ID <- 401:(400+nrow(goldLines2015))
goldLines2015 <- subset(goldLines2015, select=-c(FNODE_, TNODE_, LENGTH))

allLines <- rbind(blueLines2015, greenLines2015, rpLines2015, exLines2015, goldLines2015)

soCalTract2010$tracks_distance2015 <- st_distance(soCalTract2010, allLines) %>%
  apply(1,min)


within(as.data.frame(soCalTract2010), rm(geometry)) %>% 
  write.csv(file = "./output/intermediate/stationRoads_distances_tr10_LEHDLODES.csv")



