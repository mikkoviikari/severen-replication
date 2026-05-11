rm(list = ls())

# Define project directory
cdir <- "C:/Dropbox/Dropbox/Data_Projects/JMP_RR/"

setwd(cdir)

library(sp)
library(rgeos)
library(raster)
library(sf)
library(tidyverse)
library(rgdal)
library(gdata)
library(data.table)

source("./code/build/local_r_functions.R")

CAepsg <- "+init=epsg:3310" # California Albers in meters

####### Set Up Geography #######

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

allLines <- rbind(blueLines2015, greenLines2015, rpLines2015) %>%
  filter(PATH_ID!=206 & PATH_ID!=207 & PATH_ID!=208 & PATH_ID!=210 & PATH_ID!=211 & PATH_ID!=220 & PATH_ID!=221) 

# Read in highway
I105 <- st_read("./data/I105/I105.shp") %>%
  st_transform(CAepsg)

# Create buffers

allLines.250 <- st_buffer(allLines, dist = 250) %>%
  st_union()
allLines.500 <- st_buffer(allLines, dist = 500) %>%
  st_union()
allLines.1000 <- st_buffer(allLines, dist = 1000) %>%
  st_union()
allLines.2000 <- st_buffer(allLines, dist = 2000) %>%
  st_union()
allLines.4000 <- st_buffer(allLines, dist = 4000) %>%
  st_union()

I105.250 <- st_buffer(I105, dist = 250) %>%
  st_union()
I105.1000 <- st_buffer(I105, dist = 1000) %>%
  st_union()

####### Read In #######

npts <- 2553
oo_all <- data.table(orig=rep(as.character(""), npts^2), 
                     dest=rep(as.character(""), npts^2),
                     time=rep(as.integer(NA), npts^2),
                     dist=rep(as.numeric(NA), npts^2),
                     length=rep(as.numeric(NA), npts^2),
                     length_lineb_250=rep(as.numeric(NA), npts^2),
                     length_lineb_500=rep(as.numeric(NA), npts^2),
                     length_lineb_1000=rep(as.numeric(NA), npts^2),
                     length_lineb_2000=rep(as.numeric(NA), npts^2),
                     length_lineb_4000=rep(as.numeric(NA), npts^2),
                     length_hiwyb_250=rep(as.numeric(NA), npts^2),
                     length_hiwyb_1000=rep(as.numeric(NA), npts^2))

nrup <- 1

for (orig in 1:npts) {
  
  # Do this for each orig set
  oo <- st_read(paste0("./output/routes/o",orig,".shp")) %>%
    st_transform(CAepsg) 
  
  if (nrow(oo)>0) {
  
  oo$length <- st_length(oo)
  
  # Do this for each variable
  for (buff in c(250,500,1000,2000,4000)){
    fn <- paste0("allLines.",buff)
    
    oo_buff <- st_intersection(oo, get(fn))
    vn <- paste0("length_lineb_",buff) 
    
    oo_buff <- oo_buff %>%
      mutate(!!vn := st_length(oo_buff)) %>%
      st_drop_geometry() %>%
      subset(select = -c(time,dist,length))
    oo <- left_join(oo, oo_buff)
  }
  
  for (buff in c(250,1000)){
    fn <- paste0("I105.",buff)
    
    oo_buff <- st_intersection(oo, get(fn))
    vn <- paste0("length_hiwyb_",buff) 
    
    oo_buff <- oo_buff %>%
      mutate(!!vn := st_length(oo_buff)) %>%
      st_drop_geometry() %>%
      subset(select = -c(time,dist,length))
    oo <- left_join(oo, oo_buff)
  }
  ##
  
  oo <- oo %>% st_drop_geometry() %>% as.data.table()
  
  nrup1 <- nrup + nrow(oo) - 1
  
  oo_all[nrup:nrup1,] <- oo
  
  nrup <- nrup1 + 1
  }
}

oo_allc <- na.omit(oo_all, cols=c("time","dist"))

write.csv(oo_allc, file = "./output/intermediate/routes_bufferedprepped.csv")

