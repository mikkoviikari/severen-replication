# Uses data from LA output, counterfactual simulations

##First Generate Holder Data 4 work places, 5 residential places
## Work places are indexed across columns, and residential places by row

rm(list=ls())

load("./output/welfare/la_data_2000_v202012.RData")

################################
## Load functions
################################

library(dplyr)
source("./code/welfare/simcode_functions.R")

################################
## Inputs
################################

p <- list(alpha=0.640,
          eps=2.180,
          zet=0.65,
          psi=1.602,
          epskappa=-0.239,
          mu=0,
          eta=0,
          deltaA=0.3617,
          deltaB=0.7595)

lam <- list(A=0,
            B=0,
            C=0,
            E=0,
            D00=-0.149,
            D02=-0.128,
            D25=0,
            cong_lt250 = 0.150,
            cong_250_500 = 0.189,
            cong_500_1k = 0,
            cong_1k_2k = 0,
            cong_2k_4k = 0)

t <- list(convcrit=0.00001,
          updatewt=0.8, 
          tuningwt=0.5,
          maxiter =50 ) 

#########
## Data
##

main.base <- eqSolve_RemoveTransit(p, lam, vecs, mats, t, congestion = FALSE, skipopen = FALSE)
main.cong <- eqSolve_RemoveTransit(p, lam, vecs, mats, t, congestion = TRUE, skipopen = TRUE)

p.agg <- p
p.agg$mu <- 0.0710
p.agg$eta <- 0.1553
  
main.agg <- eqSolve_RemoveTransit(p.agg, lam, vecs, mats, t, congestion = FALSE, skipopen = TRUE)

lam.dyn <- lam
lam.dyn$D00 <- 0.112
lam.dyn$D02 <- 0.091

tmp.main.dyn <- eqSolve_RemoveTransit(p, lam.dyn, vecs, mats, t, congestion = FALSE, skipopen = TRUE, addmode = TRUE)

main.dyn <- addLoss(tmp.main.dyn, main.base)

# To REPORT
main.base$closed.percentbenefit
main.base$closed.dollarbenefit
main.base$open.popgain

main.cong$closed.dollarbenefit
main.dyn$closed.dollarbenefit
main.agg$closed.dollarbenefit
