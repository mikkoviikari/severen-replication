## Read in land use data and merge with tracts

###########################

# This function ensures that there are no self-intersecting rings

soCalLU <- remove.bad.geography("./data/SCAG/SCAG_LU.shp", CAepsg)

# Intersect to 1990 tracts

tracts90_LU_opp <- st_intersection(soCalTract90, soCalLU)

within(as.data.frame(tracts90_LU_opp), rm(geometry)) %>% 
  write.csv(file = "./output/intermediate/tracts90_LU.csv")

