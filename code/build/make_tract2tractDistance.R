## Tract to tract distances and adjacencies using 1990 census tract definitions

#############

soCalCentroid90 = st_centroid(soCalTract90)

plot(soCalTract90[1])
plot(soCalCentroid90[1], col = 'red', add = TRUE, cex = .5)

centroidDistanceMatrix <- st_distance(soCalCentroid90)
adjMatrix              <- st_intersects(soCalTract90, soCalTract90, sparse = FALSE)
rookAdjMatrix          <- st_relate(soCalTract90, soCalTract90, pattern = "F***1****", sparse = FALSE)
# Find rook-type neighbors: https://github.com/r-spatial/sf/issues/234


N  <- (nrow(soCalCentroid90))
N2 <- (nrow(soCalCentroid90))^2
tract90_OD_distance <- data.frame(tract_o  = character(N2),
                                  tract_d  = character(N2),
                                  distance = numeric(N2),
                                  adjall   = logical(N2),
                                  adjrook  = logical(N2),
                                  stringsAsFactors = FALSE)
      
tract90_OD_distance$tract_o[1:N] <- rep(as.character(soCalCentroid90$GISJOIN[[1]]), N)
tract90_OD_distance$tract_d[1:N] <- as.character(soCalCentroid90$GISJOIN)

for (i in 1:nrow(soCalCentroid90)) {
  tract90_OD_distance$tract_o[((i-1)*N+1):(i*N)]  <- rep(as.character(soCalCentroid90$GISJOIN[[i]]), N)
  tract90_OD_distance$tract_d[((i-1)*N+1):(i*N)]  <- as.character(soCalCentroid90$GISJOIN)
  tract90_OD_distance$distance[((i-1)*N+1):(i*N)] <- centroidDistanceMatrix[ ,i]
  tract90_OD_distance$adjall[((i-1)*N+1):(i*N)]   <- adjMatrix[ ,i]
  tract90_OD_distance$adjrook[((i-1)*N+1):(i*N)]  <- rookAdjMatrix[ ,i]
}

write.csv(tract90_OD_distance, file = "./output/intermediate/tract_distance_adj.csv")
