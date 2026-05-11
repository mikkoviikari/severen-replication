## Overlay geographies to make 1990 geographies

##############

# This function ensures that there are no self-intersecting rings
caTract90 <- remove.bad.geography("./data/Geographies/CA_tract_1990.shp", CAepsg)
caTract00 <- remove.bad.geography("./data/Geographies/CA_tract_2000.shp", CAepsg)
caBlkGrp00 <- remove.bad.geography("./data/Geographies/CA_blck_grp_2000.shp", CAepsg)

names(caTract90)[names(caTract90) == 'GISJOIN'] <- 'GISJOINt_90'
names(caTract00)[names(caTract00) == 'GISJOIN'] <- 'GISJOINt_00'
names(caBlkGrp00)[names(caBlkGrp00) == 'GISJOIN'] <- 'GISJOINbg_00'

# Intersect to 1990 tracts
# useful reference: https://gis.stackexchange.com/questions/140504/extracting-intersection-areas-in-r
caTract90XTr00_sums <- st_intersection(caTract90, caTract00)
caTract90XBg00_sums <- st_intersection(caTract90, caBlkGrp00)
caTract90XTr00_aves <- st_intersection(caTract00, caTract90)
caTract90XBg00_aves <- st_intersection(caBlkGrp00, caTract90)

# Add area (meters^2)
caTract90XTr00_sums <- caTract90XTr00_sums %>% 
  mutate(iarea = st_area(.) %>% as.numeric())
caTract90XBg00_sums <- caTract90XBg00_sums %>% 
  mutate(iarea = st_area(.) %>% as.numeric())
caTract90XTr00_aves <- caTract90XTr00_aves %>% 
  mutate(iarea = st_area(.) %>% as.numeric())
caTract90XBg00_aves <- caTract90XBg00_aves %>% 
  mutate(iarea = st_area(.) %>% as.numeric())

# Output
within(as.data.frame(caTract90XTr00_sums), rm(geometry)) %>% 
  write.csv(file = "./output/crosswalks/caTract90XTr00_sums_raw.csv")

within(as.data.frame(caTract90XBg00_sums), rm(geometry)) %>% 
  write.csv(file = "./output/crosswalks/caTract90XBg00_sums_raw.csv")

within(as.data.frame(caTract90XTr00_aves), rm(geometry)) %>% 
  write.csv(file = "./output/crosswalks/caTract90XTr00_aves_raw.csv")

within(as.data.frame(caTract90XBg00_aves), rm(geometry)) %>% 
  write.csv(file = "./output/crosswalks/caTract90XBg00_aves_raw.csv")

  
            

