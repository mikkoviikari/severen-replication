# Prepare data for simulations #
##############

soCalTract1990 <- soCalTract90 

# Make a conformable name
soCalTract1990$namelen <- apply(soCalTract1990,2,nchar)[,3]
soCalTract1990$tract_id <- substring(soCalTract1990$GISJOIN,3)
soCalTract1990$tract_id[soCalTract1990$namelen==12] <- paste(soCalTract1990$tract_id[soCalTract1990$namelen==12],"00", sep = "")

soCalTract1990<- soCalTract1990 %>%
  filter(tract_id!=601110003604) # This tract has no data from Stata import.

soCalTract1990 <- within(soCalTract1990, rm(namelen)) %>%
  rename("tract_w"="tract_id")

# Read in workplace data
soCalTract1990 <- read.csv("./output/welfare/pow.csv", header=TRUE) %>%
  merge(soCalTract1990, ., all.x = TRUE)

# Read in residential data
soCalTract1990 <- rename(soCalTract1990, "tract_h"="tract_w")
soCalTract1990 <- read.csv("./output/welfare/res.csv", header=TRUE) %>%
  merge(soCalTract1990, ., all.x = TRUE) %>%
  rename("tract_id"="tract_h")

tractlist <- soCalTract1990$tract_id
N <- length(tractlist)

# Double check codes are self-consistent 
table(soCalTract1990$tran00_w==soCalTract1990$tran00_h)
table(soCalTract1990$tran02_w==soCalTract1990$tran02_h)
table(soCalTract1990$tran05_w==soCalTract1990$tran05_h)

# Vector Data
wage <- soCalTract1990$wagePOW
hval <- soCalTract1990$hval_50
tran00 <- soCalTract1990$tran00_w
tran02 <- soCalTract1990$tran02_w
tran05 <- soCalTract1990$tran05_w
cdist <- soCalTract1990$cent_distance1999_h
pdist <- soCalTract1990$distance1999_h
dd_05km <- pmax(500-soCalTract1990$distance1999_h,0)/500

# STATA definitions
#gen		dd_05km = max(500-distance1999_h,0)/500
#replace dd_05km = 0 if yr==0

# Flow and Travel Time Data, mapped to same order for vector-matrix operations
time_data <- read.csv("./output/welfare/times.csv", header=TRUE)
flow_data <- read.csv("./output/welfare/flows.csv", header=TRUE)

timemat <- matrix(NA, N, N)

flowmat <- Matrix(0, N, N, sparse=FALSE)
shline_lt250 <- Matrix(0,N,N, sparse=FALSE)
shline_250_500 <- Matrix(0,N,N, sparse=FALSE)
shline_500_1000 <- Matrix(0,N,N, sparse=FALSE)
shline_1000_2000 <- Matrix(0,N,N, sparse=FALSE)
shline_2000_4000 <- Matrix(0,N,N, sparse=FALSE)
travcost <- Matrix(0, N, N, sparse=FALSE)
tt00 <- Matrix(0, N, N, sparse=FALSE)
tt02 <- Matrix(0, N, N, sparse=FALSE)
tt25 <- Matrix(0, N, N, sparse=FALSE)

# Time matrix indexing
rnum_t <- match(time_data$tract_h, tractlist)
cnum_t <- match(time_data$tract_w, tractlist)

timemat[cbind(rnum_t,cnum_t)] <- time_data$tt_here


# Flow matrices indexing
rnum_f <- match(flow_data$tract_h, tractlist)
cnum_f <- match(flow_data$tract_w, tractlist)

flowmat[cbind(rnum_f,cnum_f)] <- flow_data$wtflow5b

tt00[cbind(rnum_f,cnum_f)] <- flow_data$tt00_cc
tt02[cbind(rnum_f,cnum_f)] <- flow_data$tt02_cc
tt25[cbind(rnum_f,cnum_f)] <- flow_data$tt25_cc

shline_lt250[cbind(rnum_f,cnum_f)] <- flow_data$shline_nearmetro250
shline_250_500[cbind(rnum_f,cnum_f)] <- flow_data$shline_nearmetro_500_250
shline_500_1000[cbind(rnum_f,cnum_f)] <- flow_data$shline_nearmetro_1000_500
shline_1000_2000[cbind(rnum_f,cnum_f)] <- flow_data$shline_nearmetro_2000_1000
shline_2000_4000[cbind(rnum_f,cnum_f)] <- flow_data$shline_nearmetro_4000_2000

travcost[cbind(rnum_f,cnum_f)] <- flow_data$tt_dyn

# This replaces NAs on diagonal with 0s
diag(shline_lt250) <-0
diag(shline_250_500) <-0
diag(shline_500_1000) <-0
diag(shline_1000_2000) <-0
diag(shline_2000_4000) <-0

vecs = list(wage=wage, hval=hval, cdist=cdist, tran00=tran00, tran02=tran02, tran05=tran05, dd_05km=dd_05km)
mats = list(timemat=timemat, flowmat=flowmat, travcost=travcost, tt00=tt00, tt02=tt02, tt25=tt25,
            sh_lt250=shline_lt250, sh_250_500=shline_250_500, sh_500_1k=shline_500_1000, sh_1k_2k=shline_1000_2000, sh_2k_4k=shline_2000_4000)

gdata::keep(tractlist, vecs, mats, sure=TRUE)
save(tractlist, vecs, mats, file = "./output/welfare/la_data_2000_v202012.RData")



#gdata::keep(wage, tran00_w, tran05_w, cdist_w, hval, tran00_h, tran05_h, cdist_h, flowmat, tmat00, tmat05, tractlist, sure=TRUE)   

#save(wage, tran00_w, tran05_w, cdist_w, hval, tran00_h, tran05_h, cdist_h, flowmat, tmat00, tmat05, tractlist, file = "./output/welfare/la_data_1990_2000.RData")

# for (i in 1:nrow(flow_data)) {
#   rnum <- grep(flow_data$tract_h[i], tractlist)
#   cnum <- grep(flow_data$tract_w[i], tractlist)
#   
#   flowmat[rnum,cnum] <- flow_data$wtflow5b[i]
#   
#   tt00[rnum,cnum] <- flow_data$tt00_cc[i]
#   tt02[rnum,cnum] <- flow_data$tt02_cc[i]
#   tt25[rnum,cnum] <- flow_data$tt25_cc[i]
#   
#   shline_lt250[rnum,cnum] <- flow_data$shline_nearmetro250[i]
#   shline_250_1000[rnum,cnum] <- flow_data$shline_nearmetro_1000_250[i]
#   shline_1000_2000[rnum,cnum] <- flow_data$shline_nearmetro_2000_1000[i]
#   shline_4000_2000[rnum,cnum] <- flow_data$shline_nearmetro_4000_2000[i]
#   
#   travcost[rnum,cnum] <- flow_data$tt_dyn[i]
# }

#tmat00 <- Matrix(0, N, N, sparse=FALSE)
#tmat05 <- Matrix(0, N, N, sparse=FALSE)
#tt00 <- Matrix(0, N, N, sparse=TRUE)
#tt02 <- Matrix(0, N, N, sparse=TRUE)
#tt25 <- Matrix(0, N, N, sparse=TRUE)

# tmat00[rnum,cnum] <- flow_data$tran00_cc[i]
# tmat05[rnum,cnum] <- flow_data$tran05_cc[i]
# tt00[rnum,cnum] <- flow_data$tt00_cc[i]
# tt02[rnum,cnum] <- flow_data$tt02_cc[i]
# tt25[rnum,cnum] <- flow_data$tt25_cc[i]
# near20[rnum,cnum] <- flow_data$neartracks_20[i]

