## Geographic tract characteristics for heterogeneous psi analysis.
## Outputs output/coastal_indicator.csv with:
##   tract_id     — 14-digit numeric, matches tract_w in powFEs.dta
##   dist_coast_m — distance to nearest coastline segment (metres, CA Albers)
##   coastal      — 1 if dist_coast_m < 5000, else 0
##   area_km2     — tract land area in km² (CA Albers)
##   lon, lat     — WGS84 centroid coordinates for Kepler.gl

library(sf)
library(dplyr)
library(rnaturalearth)

setwd("/Users/mikko.viikari/Projects/severen")
CAepsg <- "EPSG:3310"

# 1. Load and filter 1990 tract shapefile (5-county LA metro)
soCalTract90 <- st_read("./data/Geographies/CA_tract_1990.shp", quiet = TRUE) %>%
  st_make_valid() %>%
  st_transform(CAepsg) %>%
  filter(NHGISCTY %in% c("0370", "0590", "0650", "0710", "1110")) %>%
  mutate(
    namelen  = nchar(GISJOIN),
    tract_id = substring(GISJOIN, 3),
    tract_id = ifelse(namelen == 12, paste0(tract_id, "00"), tract_id)
  )

cat("Tracts loaded:", nrow(soCalTract90), "\n")

# 2. Tract area (km²) and centroids
soCalTract90$area_km2 <- as.numeric(st_area(soCalTract90)) / 1e6
centroids             <- st_centroid(soCalTract90)

# 3. Distance to Pacific coastline
coastline <- ne_coastline(scale = "medium", returnclass = "sf") %>%
  st_transform(CAepsg) %>%
  st_crop(st_bbox(soCalTract90) + c(-50000, -50000, 50000, 50000))

cat("Computing distances...\n")
soCalTract90$dist_coast_m <- apply(st_distance(centroids, coastline), 1, min) %>%
  as.numeric()
soCalTract90$coastal <- as.integer(soCalTract90$dist_coast_m < 5000)

# 4. Centroid lon/lat (WGS84) for Kepler.gl
coords <- st_coordinates(st_transform(centroids, "EPSG:4326"))
soCalTract90$lon <- coords[, 1]
soCalTract90$lat <- coords[, 2]

# 5. Export
out <- soCalTract90 %>%
  st_drop_geometry() %>%
  select(tract_id, dist_coast_m, coastal, area_km2, lon, lat) %>%
  mutate(tract_id = as.numeric(tract_id))

write.csv(out, "./output/coastal_indicator.csv", row.names = FALSE)
cat("Coastal (<5km):", sum(out$coastal), "of", nrow(out),
    sprintf("(%.1f%%)\n", 100 * mean(out$coastal)))
cat("Area range (km²): min =", round(min(out$area_km2), 2),
    "  max =", round(max(out$area_km2), 2), "\n")
cat("Saved: output/coastal_indicator.csv\n")
