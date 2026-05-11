rm(list=ls())

load("./output/welfare/la_data_2000_v202012.RData")

bs_params <- read.csv("./output/welfare/bootstrap_params.csv", header=TRUE)

################################
## Load functions
################################

library(dplyr)
source("./code/welfare/simcode_functions.R")

################################
## Inputs
################################

p <- list(alpha=0.640,
          zet=0.65,
          epskappa=-0.22,
          mu=0,
          eta=0,
          deltaA=0.3617,
          deltaB=0.7595)

lam <- list(A=0,
            B=0,
            C=0,
            E=0,
            D25=0,
            cong_lt250 = 0.150,
            cong_250_500 = 0.189,
            cong_500_1k = 0,
            cong_1k_2k = 0,
            cong_2k_4k = 0)

t <- list(convcrit=0.00005,
          updatewt=0.8, 
          tuningwt=0.5,
          maxiter =50 )

#########
## Data

p_bs <- as_tibble(lapply(as.data.frame(p), rep, 400))
p_bs[["eps"]] <- bs_params$eps
p_bs[["psi"]] <- bs_params$psi
p_bs[["id"]] <- bs_params$X_id

lam_bs <- as_tibble(lapply(as.data.frame(lam), rep, 400))
lam_bs[["D00"]] <- -1*bs_params$coef0
lam_bs[["D02"]] <- -1*bs_params$coef2
lam_bs[["id"]] <- bs_params$X_id


main.base <- map2(transpose(p_bs), transpose(lam_bs), eqSolve_RemoveTransit, vecs, mats, t, congestion = FALSE, skipopen = FALSE)

save(main.base, file = "./output/welfare/welfare_bootstrapped_outcomes.RData")

load("./output/welfare/welfare_bootstrapped_outcomes.RData")

bsvals<-transpose(main.base)

quantile(unlist(p_bs$eps), probs = c(0.025,0.5,0.975))
quantile(unlist(p_bs$psi), probs = c(0.025,0.5,0.975))

quantile(unlist(lam_bs$D00), probs = c(0.025,0.5,0.975))
quantile(unlist(lam_bs$D02), probs = c(0.025,0.5,0.975))

100*quantile(unlist(bsvals$closed.percentbenefit), probs = c(0.025,0.5,0.975))
quantile(unlist(bsvals$closed.dollarbenefit), probs = c(0.025,0.5,0.975))
100*quantile(unlist(bsvals$open.popgain), probs = c(0.025,0.5,0.975))
