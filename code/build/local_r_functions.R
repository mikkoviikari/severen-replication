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