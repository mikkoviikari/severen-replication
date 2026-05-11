# Uses data from LA output, counterfactual simulations

##First Generate Holder Data 4 work places, 5 residential places
## Work places are indexed across columns, and residential places by row

rm(list=ls())

load("./output/welfare/la_data_2000_v202012.RData")

################################
## Load functions
################################

library(dplyr)
library(xtable)
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

p.agg <- p
p.agg$mu <- 0.0710
p.agg$eta <- 0.1553

lam.dyn <- lam
lam.dyn$D00 <- 0.112
lam.dyn$D02 <- 0.091

A1.1 <- eqSolve_RemoveTransit(p, lam, vecs, mats, t, congestion = FALSE, GenEqbm = FALSE)
A1.2 <- eqSolve_RemoveTransit(p, lam, vecs, mats, t, congestion = FALSE, GenEqbm = TRUE)
A1.3 <- eqSolve_RemoveTransit(p.agg, lam, vecs, mats, t, congestion = FALSE, GenEqbm = TRUE)

A2.1 <- addLoss(eqSolve_RemoveTransit(p, lam.dyn, vecs, mats, t, congestion = FALSE, GenEqbm = FALSE, addmode = TRUE), A1.1)
A2.2 <- addLoss(eqSolve_RemoveTransit(p, lam.dyn, vecs, mats, t, congestion = FALSE, addmode = TRUE), A1.2)
A2.3 <- addLoss(eqSolve_RemoveTransit(p.agg, lam.dyn, vecs, mats, t, congestion = FALSE, addmode = TRUE), A1.3)

A3.1 <- eqSolve_RemoveTransit(p, lam, vecs, mats, t, congestion = TRUE, GenEqbm = FALSE)
A3.2 <- eqSolve_RemoveTransit(p, lam, vecs, mats, t, congestion = TRUE, GenEqbm = TRUE)
A3.3 <- eqSolve_RemoveTransit(p.agg, lam, vecs, mats, t, congestion = TRUE, GenEqbm = TRUE)

A4.1 <- addLoss(eqSolve_RemoveTransit(p, lam.dyn, vecs, mats, t, congestion = FALSE, GenEqbm = FALSE, addmode = TRUE), A3.1)
A4.2 <- addLoss(eqSolve_RemoveTransit(p, lam.dyn, vecs, mats, t, congestion = FALSE, addmode = TRUE), A3.2)
A4.3 <- addLoss(eqSolve_RemoveTransit(p.agg, lam.dyn, vecs, mats, t, congestion = FALSE, addmode = TRUE), A3.3)

lamB <- lam
lamB.dyn <- lam.dyn
lamB$D00 <- 0
lamB$D02 <- 0
lamB$B <- 0.05
lamB.dyn$B <- 0.05

B1.1 <- addLoss(eqSolve_RemoveTransit(p, lamB, vecs, mats, t, congestion = FALSE, GenEqbm = FALSE, addmode = TRUE), A1.1)
B1.2 <- addLoss(eqSolve_RemoveTransit(p, lamB, vecs, mats, t, congestion = FALSE, addmode = TRUE), A1.2)
B1.3 <- addLoss(eqSolve_RemoveTransit(p.agg, lamB, vecs, mats, t, congestion = FALSE, addmode = TRUE), A1.3)

B2.1 <- addLoss(eqSolve_RemoveTransit(p, lamB.dyn, vecs, mats, t, congestion = FALSE, GenEqbm = FALSE, addmode = TRUE), A1.1)
B2.2 <- addLoss(eqSolve_RemoveTransit(p, lamB.dyn, vecs, mats, t, congestion = FALSE, addmode = TRUE), A1.2)
B2.3 <- addLoss(eqSolve_RemoveTransit(p.agg, lamB.dyn, vecs, mats, t, congestion = FALSE, addmode = TRUE), A1.3)

B3.1 <- addLoss(eqSolve_RemoveTransit(p, lamB, vecs, mats, t, congestion = FALSE, GenEqbm = FALSE, addmode = TRUE), A3.1)
B3.2 <- addLoss(eqSolve_RemoveTransit(p, lamB, vecs, mats, t, congestion = FALSE, addmode = TRUE), A3.2)
B3.3 <- addLoss(eqSolve_RemoveTransit(p.agg, lamB, vecs, mats, t, congestion = FALSE, addmode = TRUE), A3.3)

B4.1 <- addLoss(eqSolve_RemoveTransit(p, lamB.dyn, vecs, mats, t, congestion = FALSE, GenEqbm = FALSE, addmode = TRUE), A3.1)
B4.2 <- addLoss(eqSolve_RemoveTransit(p, lamB.dyn, vecs, mats, t, congestion = FALSE, addmode = TRUE), A3.2)
B4.3 <- addLoss(eqSolve_RemoveTransit(p.agg, lamB.dyn, vecs, mats, t, congestion = FALSE, addmode = TRUE), A3.3)

lamC <- lam
lamC.dyn <- lam.dyn
lamC$D00 <- 0
lamC$D02 <- 0
lamC$C <- -0.3297
lamC.dyn$C <- -0.3297

t.parttest <- t 
t.parttest$maxiter <- 1
testC <- eqSolve_RemoveTransit(p, lamC, vecs, mats, t.parttest, congestion = FALSE, GenEqbm = TRUE, addmode = TRUE)

C1.1 <- addLoss(eqSolve_RemoveTransit(p, lamC, vecs, mats, t, congestion = FALSE, GenEqbm = FALSE, addmode = TRUE), A1.1)
C1.2 <- addLoss(eqSolve_RemoveTransit(p, lamC, vecs, mats, t, congestion = FALSE, addmode = TRUE), A1.2)
C1.3 <- addLoss(eqSolve_RemoveTransit(p.agg, lamC, vecs, mats, t, congestion = FALSE, addmode = TRUE), A1.3)

C2.1 <- addLoss(eqSolve_RemoveTransit(p, lamC.dyn, vecs, mats, t, congestion = FALSE, GenEqbm = FALSE, addmode = TRUE), A1.1)
C2.2 <- addLoss(eqSolve_RemoveTransit(p, lamC.dyn, vecs, mats, t, congestion = FALSE, addmode = TRUE), A1.2)
C2.3 <- addLoss(eqSolve_RemoveTransit(p.agg, lamC.dyn, vecs, mats, t, congestion = FALSE, addmode = TRUE), A1.3)

C3.1 <- addLoss(eqSolve_RemoveTransit(p, lamC, vecs, mats, t, congestion = FALSE, GenEqbm = FALSE, addmode = TRUE), A3.1)
C3.2 <- addLoss(eqSolve_RemoveTransit(p, lamC, vecs, mats, t, congestion = FALSE, addmode = TRUE), A3.2)
C3.3 <- addLoss(eqSolve_RemoveTransit(p.agg, lamC, vecs, mats, t, congestion = FALSE, addmode = TRUE), A3.3)

C4.1 <- addLoss(eqSolve_RemoveTransit(p, lamC.dyn, vecs, mats, t, congestion = FALSE, GenEqbm = FALSE, addmode = TRUE), A3.1)
C4.2 <- addLoss(eqSolve_RemoveTransit(p, lamC.dyn, vecs, mats, t, congestion = FALSE, addmode = TRUE), A3.2)
C4.3 <- addLoss(eqSolve_RemoveTransit(p.agg, lamC.dyn, vecs, mats, t, congestion = FALSE, addmode = TRUE), A3.3)


lamA <- lam
lamA.dyn <- lam.dyn
lamA$D00 <- 0
lamA$D02 <- 0
lamA$A <- 0.04
lamA.dyn$A <- 0.04

D1.1 <- addLoss(eqSolve_RemoveTransit(p, lamA, vecs, mats, t, congestion = FALSE, GenEqbm = FALSE, addmode = TRUE), A1.1)
D1.2 <- addLoss(eqSolve_RemoveTransit(p, lamA, vecs, mats, t, congestion = FALSE, addmode = TRUE), A1.2)
D1.3 <- addLoss(eqSolve_RemoveTransit(p.agg, lamA, vecs, mats, t, congestion = FALSE, addmode = TRUE), A1.3)

D2.1 <- addLoss(eqSolve_RemoveTransit(p, lamA.dyn, vecs, mats, t, congestion = FALSE, GenEqbm = FALSE, addmode = TRUE), A1.1)
D2.2 <- addLoss(eqSolve_RemoveTransit(p, lamA.dyn, vecs, mats, t, congestion = FALSE, addmode = TRUE), A1.2)
D2.3 <- addLoss(eqSolve_RemoveTransit(p.agg, lamA.dyn, vecs, mats, t, congestion = FALSE, addmode = TRUE), A1.3)

D3.1 <- addLoss(eqSolve_RemoveTransit(p, lamA, vecs, mats, t, congestion = FALSE, GenEqbm = FALSE, addmode = TRUE), A3.1)
D3.2 <- addLoss(eqSolve_RemoveTransit(p, lamA, vecs, mats, t, congestion = FALSE, addmode = TRUE), A3.2)
D3.3 <- addLoss(eqSolve_RemoveTransit(p.agg, lamA, vecs, mats, t, congestion = FALSE, addmode = TRUE), A3.3)

D4.1 <- addLoss(eqSolve_RemoveTransit(p, lamA.dyn, vecs, mats, t, congestion = FALSE, GenEqbm = FALSE, addmode = TRUE), A3.1)
D4.2 <- addLoss(eqSolve_RemoveTransit(p, lamA.dyn, vecs, mats, t, congestion = FALSE, addmode = TRUE), A3.2)
D4.3 <- addLoss(eqSolve_RemoveTransit(p.agg, lamA.dyn, vecs, mats, t, congestion = FALSE, addmode = TRUE), A3.3)



modelmat <- matrix(NA,16,4)

cl <- c("A","B","C","D")
ttl <- c("","\\quad + Dynamic Effect (through 2015)", "Congestion Effect", "Dynamic \\& Congestion Effects")
k <- 1
for (c in cl) {
  for (j in 1:4) {  
    modelmat[k,1] <- ttl[j]
    for (i in 2:4) {
      dn <- paste(c,j,".", i-1,sep = "")
      est <- get(dn)
      modelmat[k,i] <- 100*est$closed.percentbenefit
    }
    k <- k+1
  }
}

mm <- as.data.frame(modelmat, stringsAsFactors=FALSE)
mm <- mm %>%
  transform(V2 = as.numeric(V2)) %>%
  transform(V3 = as.numeric(V3)) %>%
  transform(V4 = as.numeric(V4)) 

xtable(mm, booktabs = TRUE, digits=5)
  
print(xtable(mm, booktabs = TRUE, digits=5), include.rownames = FALSE, file="./output/welfare/extensions.tex")

## Check 
lamE00 <- lam
lamE00$D00 <- 0.149
lamE00$D02 <- 0.128
lamE00$E <- 0.05
lamB00 <- lamE00
lamB00$B <- 0.05
lamB00$E <- 0

E1.A <- eqSolve_RemoveTransit(p, lamE00, vecs, mats, t, congestion = FALSE, GenEqbm = FALSE)
E1.B <- eqSolve_RemoveTransit(p, lamB00, vecs, mats, t, congestion = FALSE, GenEqbm = FALSE)
