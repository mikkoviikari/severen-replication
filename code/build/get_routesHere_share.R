## Get routing data ##

rm(list = ls())

# Define project directory
cdir <- "C:/Dropbox/Dropbox/Data_Projects/JMP_RR/"

setwd(cdir)

library(rgeos)
library(raster)
library(sf)
library(tidyverse)
library(rgdal)
library(gdata)
library(hereR)
library(data.table)

CAepsg <- "+init=epsg:3310" # California Albers in meters ## SET TO WHATEVER IS BEST FOR YOUR GEOG/HERE

####### Main Geography #######

soCalTract90 <- st_read() %>% st_transform(CAepsg)

set_key("PUT YOUR API HERE")

## Initialize

Nmax <- dim(geogcent)[1]
maxiter <- ceiling(Nmax/15)*ceiling(Nmax/100)
mat_all <- data.table(
  origIndex=rep(character(),Nmax^2),
  destIndex=rep(character(),Nmax^2),
  distance=rep(0,Nmax^2),
  travelTime=rep(0,Nmax^2),
  costFactor=rep(0,Nmax^2))

for (iter_o in 1:ceiling(Nmax/15)) {
  for (iter_d in 1:ceiling(Nmax/100)) {
    
    if (iter_o==1 & iter_d==1) {
      ii_base <- 1
      itrack <- 1
    } else {
      ii_base <- max_ii + 1
    }
    
    cat(itrack, "of", maxiter, "\r")
    
    if (((15*iter_o)<=Nmax) & ((100*iter_d)<=Nmax)) {
      max_o <- (15*iter_o)
      max_d <- (100*iter_d)
      max_ii <- ii_base + 1500 - 1
    } else if (((15*iter_o)<=Nmax) & ((100*iter_d)>Nmax)) {
      max_o <- (15*iter_o)
      max_d <- Nmax
      max_ii <- ii_base + (15*(Nmax - 100*(iter_d-1))) - 1
    } else if (((15*iter_o)>Nmax) & ((100*iter_d)<=Nmax)) {
      max_o <- Nmax
      max_d <- (100*iter_d)
      max_ii <- ii_base + (100*(Nmax - 15*(iter_o-1))) - 1
    } else {
      max_o <- Nmax
      max_d <- Nmax
      max_ii <- ii_base + (((Nmax - 15*(iter_o-1)))*((Nmax - 100*(iter_d-1)))) - 1
    }
    
    mat_r <- route_matrix(
      origin = geogcent[(15*(iter_o-1)+1):max_o,],
      destination = geogcent[(100*(iter_d-1)+1):max_d,]
    ) %>%
      subset(select=-c(departure,arrival))
    
    mat_r$origIndex <- geogcent$GISJOIN[(15*(iter_o-1) + as.numeric(mat_r$origIndex))]
    mat_r$destIndex <- geogcent$GISJOIN[(100*(iter_d-1) + as.numeric(mat_r$destIndex))]
    
    mat_all[ii_base:max_ii, c("origIndex","destIndex","distance","travelTime","costFactor") := mat_r]

    itrack <- itrack+1
  }
}

write_csv(mat_all, "./output/intermediate/travelmat_here.csv", append=FALSE, col_names=TRUE)
