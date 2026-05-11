## Match census tracts to county subdivisions

##############

# This function ensures that there are no self-intersecting rings

countySubs <- remove.bad.geography("./data/Geographies/US_cty_sub_1990Consolidated.shp", CAepsg)

# Find centroids
soCalCentroid90 = st_centroid(soCalTract90)
soCalCentroid10 = st_centroid(soCalTract10)

# Intersect subdivisions with tract centroids
# useful reference: https://gis.stackexchange.com/questions/140504/extracting-intersection-areas-in-r
tracts90CountySubs <- st_intersection(countySubs, soCalCentroid90)
setdiff(soCalCentroid90$GISJOIN, tracts90CountySubs$GISJOIN.1)
# "G06003707029" merge to 91705, "G06003705991" merge to 91706, "G0601110003604" merge to 92310

tracts10CountySubs <- st_intersection(countySubs, soCalCentroid10)
setdiff(soCalCentroid10$GISJOIN, tracts10CountySubs$GISJOIN.1)
# "G0600370702901" merge to 91705, "G0600370599100" merge to 91706, "G0601110003612"merge to 92310 

within(as.data.frame(tracts90CountySubs), rm(geometry)) %>% 
  write.csv(file = "./output/crosswalks/tracts90CountySubs.csv")
within(as.data.frame(tracts10CountySubs), rm(geometry)) %>% 
  write.csv(file = "./output/crosswalks/tracts10CountySubs.csv")

