##############################################
#######################
## Wrapper functions ##
#######################
##############################################

#######################
# Checks for multiple equilibria
eqCheck <- function(p) {
  if ((1-p$zet)*p$psi/(1+p$psi) <= (1+p$eps*(1-p$alpha))/(2*p$eps*(1+p$eps)*(1-p$alpha))) {
    meq <-"Parameters imply single equilbrium; largest eigenvalue is "
  } else {
    meq <-"Caution: parameters imply multiple equilbria; largest eigenvalue is "
  }
  beig <- abs(eigValues(p$alpha,p$eps,p$psi,p$zet)) %>% max
  message(meq,beig)
  return(beig)
}

# ######################
# Wrapper to solves for the (nearest) equilibrium

eqSolve_RemoveTransit <- function(p, lam, vecs, mats, t, congestion, skipopen=TRUE, GenEqbm=TRUE, addmode=FALSE) {
  # Removes transit infrastructure and finds counterfactual equilibrium  
  
  N <- dim(mats$flowmat)[1] # Total unique locations (may be greater than either residential or workplace locations)
  p$nepszet <- -1*p$eps*(1-p$zet)
  
  times <- mats$timemat
  
  cf.0 <- as.matrix(mats$flowmat) 
  cf.0[cf.0==0] <- NA
  
  W.0 <- vecs$wage
  W.0[W.0==0] <- NA
  
  Q.0 <- vecs$hval
  Q.0[Q.0==0] <- NA
  
  checkmat <- rv2m(W.0) * cv2m(Q.0)
  cf.0[is.na(checkmat)] <- NA
  
  tt00 <- as.matrix(mats$tt00)
  tt02 <- as.matrix(mats$tt02)
  tt25 <- as.matrix(mats$tt25)
  
  # Estimate hat vector: A,B,C,D,E
  A.hat <- exp(lam$A * vecs$dd_05km)
  B.hat <- exp(lam$B * vecs$dd_05km)
  C.hat <- exp(lam$C * vecs$tran00)
  D.hat <- exp(lam$D00*tt00 + lam$D02*tt02 + lam$D25*tt25)
  E.hat <- exp(lam$E * vecs$dd_05km)
  
  A.hat[is.na(W.0)] <- NA
  B.hat[is.na(Q.0)] <- NA
  C.hat[is.na(Q.0)] <- NA
  E.hat[is.na(W.0)] <- NA
  
  if (congestion == "TRUE") {
    #tau.hat <- exp(p.epskappa*lam.tau*XXX*near20*travcost) # Congestion
    #tchangemat <- lam$cong_lt250*as.matrix(mats$sh_lt250) + lam$cong_250_1k*as.matrix(mats$sh_250_1k) + lam$cong_1k_2k*as.matrix(mats$sh_1k_2k) + lam$cong_2k_4k*as.matrix(mats$sh_2k_4k)
    #tau.hat <- exp(p$epskappa*tchangemat) 
    #tau.hat[is.na(tau.hat)] <- 1
    #tau.hat[tau.hat>1] <- 1
    #BED.hat <- cv2m(B.hat)*rv2m(E.hat)*D.hat*tau.hat
    tchangemat <- exp( matrix(0,N,N) + lam$cong_lt250*as.matrix(mats$sh_lt250) + lam$cong_250_500*as.matrix(mats$sh_250_500) +
                         lam$cong_500_1k*as.matrix(mats$sh_500_1k) + lam$cong_1k_2k*as.matrix(mats$sh_1k_2k) + 
                         lam$cong_2k_4k*as.matrix(mats$sh_2k_4k) )
    
    tau.hat <- tchangemat^p$epskappa
    tau.hat[is.na(tau.hat)] <- 1
    tau.hat[tau.hat>1] <- 1
    BED.hat <- cv2m(B.hat)*rv2m(E.hat)*D.hat*tau.hat

  } else {
    BED.hat <- cv2m(B.hat)*rv2m(E.hat)*D.hat
  }
  
  print("Summary of input changes: Ahat, Bhat, BEDhat")
  print(summary(A.hat))
  print(summary(B.hat))
  print(summary(as.vector(BED.hat)))
  
  cf.0[is.na(BED.hat)] <- NA
  
  # Turn flows into shares
  pi.0 <- cf.0 / sum(cf.0, na.rm = TRUE)
  
  if (missing(GenEqbm) | GenEqbm==TRUE) {
    out <- eqSolver(N, pi.0, W.0, Q.0, A.hat, BED.hat, C.hat, times, p, t, skipopen, addmode)
  } else if (GenEqbm==FALSE) {
    out <- eqSolverPartial(N, pi.0, W.0, Q.0, A.hat, BED.hat, C.hat, times, p, t, addmode)
  }
  
  return(out)
}

##############################################
##################################
## Equilbrium solving function ##
##################################
##############################################


## General Equilibrium 
eqSolver <- function(N, pi.0, W.0, Q.0, A.hat, BED.hat, C.hat, times, p, t, skipopen, addmode) {
  
  maxeigen <- eqCheck(p)
  
  # Perform initial update and declare initial values
  U.hat.i <- rep.int(1,N)
  O.hat.i <- rep.int(1,N)
  W.hat.i <- rep.int(1,N)
  Q.hat.i <- rep.int(1,N)
  pi.hat.i <- pcfUpdate(BED.hat, pi.0, W.hat.i, Q.hat.i, O.hat.i, p$eps, p$nepszet, p$eta)
  N.hat.i <- 1
  
  convdiff <- 100
  iter <- 0
  t.ticker <- 1
  switch.to.small <- 0
  
  pi.N <- sum(!is.na(as.vector(pi.hat.i)))
  W.N <- sum(!is.na(A.hat))
  Q.N <- sum(!is.na(C.hat))
  
  # Main updating loop
  while ((convdiff > t$convcrit) & (iter < t$maxiter)) {
    
    # Values to measure convergence against, also used to update
    Uh0 <- U.hat.i
    Oh0 <- O.hat.i
    Qh0 <- Q.hat.i
    Wh0 <- W.hat.i
    pih0 <- pi.hat.i
    
    convdiff0 <- convdiff
    
    # Candidates for updating
    if ((p$mu!=0) | (p$eta!=0)) {
      U.hat.i <- uUpdate(times, pi.0, W.0, pi.hat.i, p$deltaA)
      O.hat.i <- oUpdate(times, pi.0, Q.0, pi.hat.i, p$deltaB)
    } else {
      U.hat.i <- 1
      O.hat.i <- 1
    }
    Q.hat.i <- qUpdate(C.hat, pi.0, W.0, Q.0, pi.hat.i, W.hat.i, N.hat.i, p$psi)
    W.hat.i <- wUpdate(A.hat, pi.0, W.0, pi.hat.i, N.hat.i, U.hat.i, p$alpha, p$mu) 
    pi.hat.i <- pcfUpdate(BED.hat, pi.0, W.hat.i, Q.hat.i, O.hat.i, p$eps, p$nepszet, p$eta)
    
    diff.pi = sum(abs(pi.hat.i - pih0), na.rm = TRUE)/pi.N
    diff.W = sum(abs(W.hat.i - Wh0), na.rm = TRUE)/W.N
    diff.Q = sum(abs(Q.hat.i - Qh0), na.rm = TRUE)/Q.N
    
    convdiff <- max(diff.pi, diff.W, diff.Q)
    
    # Smaller steps if not converging.
    if ((convdiff0-convdiff>0) & (switch.to.small!=1)) {
      if (iter>=2) {
        U.hat.i <- (1-t$updatewt)*Uh0 + t$updatewt*U.hat.i
        O.hat.i <- (1-t$updatewt)*Oh0 + t$updatewt*O.hat.i
        Q.hat.i <- (1-t$updatewt)*Qh0 + t$updatewt*Q.hat.i
        W.hat.i <- (1-t$updatewt)*Wh0 + t$updatewt*W.hat.i
        pi.hat.i <- (1-t$updatewt)*pih0 + t$updatewt*pi.hat.i
      }
      
      iter<- iter+1
      print(sprintf("Closed city conv. criteria is %.5f with %d iterations complete.", convdiff, iter))
    } else {
      switch.to.small <- 1
      
      if (convdiff0-convdiff<0) {
        t.tune <- t$tuningwt^(t.ticker)
        t.ticker <- t.ticker+1
      }
      
      U.hat.i <- (1-t.tune)*Uh0 + t.tune*U.hat.i
      O.hat.i <- (1-t.tune)*Oh0 + t.tune*O.hat.i
      Q.hat.i <- (1-t.tune)*Qh0 + t.tune*Q.hat.i
      W.hat.i <- (1-t.tune)*Wh0 + t.tune*W.hat.i
      pi.hat.i <- (1-t.tune)*pih0 + t.tune*pi.hat.i
      
      iter<- iter+1
      print(sprintf("Closed city conv. criteria is %.5f with %d iterations complete (small steps, %d).", convdiff, iter, t.ticker))
    }
  }
  
  # Benefit in percent/100
  #print(1-welfCalc(62,62,BED.hat, pi.hat.i, W.hat.i, Q.hat.i, p.eps, p.nepszet))
  out.calcs <- welfCalc2(N, BED.hat, pi.hat.i, W.hat.i, Q.hat.i, p$eps, p$nepszet)
  if (addmode==TRUE) {
    out.closed.percentloss <- out.calcs$welfave - 1
    out.closed.percentbenefit <- 1- (1/out.calcs$welfave)
  } else {
    out.closed.percentloss <- 1-out.calcs$welfave
    out.closed.percentbenefit <- (1/out.calcs$welfave) - 1
  }
  
  
  # Benefit in millions of dollars
  #print((1-welfCalc(5,2,BED.hat, pi.hat.i, W.hat.i, Q.hat.i, p.eps, p.nepszet))*31563*6.73)
  out.closed.dollarbenefit <- out.closed.percentbenefit*31563*6.73
  if (iter>=t$maxiter) {
    out.closed.converged <- FALSE
  } else {
    out.closed.converged <- TRUE
  }
  
  if (skipopen==FALSE) {
    convdiff <- 100
    iter <- 0
    
    while ((convdiff > t$convcrit) & (iter < t$maxiter)) {
      
      # Values to measure convergence against, also used to update
      Qh0 <- Q.hat.i
      Wh0 <- W.hat.i
      pih0 <- pi.hat.i
      Nh0 <- N.hat.i
      
      convdiff0 <- convdiff
      
      # Candidates for updating (disallow agglomeration in open city)
      U.hat.i <- 1
      O.hat.i <- 1
      
      Q.hat.i <- qUpdate(C.hat, pi.0, W.0, Q.0, pi.hat.i, W.hat.i, N.hat.i, p$psi)
      W.hat.i <- wUpdate(A.hat, pi.0, W.0, pi.hat.i, N.hat.i, U.hat.i, p$alpha, p$mu) 
      pi.hat.i <- pcfUpdate(BED.hat, pi.0, W.hat.i, Q.hat.i, O.hat.i, p$eps, p$nepszet, p$eta)
      N.hat.i <- nbarUpdate(A.hat, BED.hat, C.hat, pi.0, W.0, pi.hat.i, p$alpha, p$eps, p$psi, p$zet, p$nepszet)
      
      diff.pi = sum(abs(pi.hat.i - pih0), na.rm = TRUE)/pi.N
      diff.W = sum(abs(W.hat.i - Wh0), na.rm = TRUE)/W.N
      diff.Q = sum(abs(Q.hat.i - Qh0), na.rm = TRUE)/Q.N
      diff.N <- abs(N.hat.i - Nh0)
      
      convdiff <- max(diff.pi, diff.W, diff.Q, diff.N)
      
      # Smaller steps if not converging.
      if ((convdiff0-convdiff>0) & (switch.to.small!=1)) {
        Q.hat.i <- (1-t$updatewt)*Qh0 + t$updatewt*Q.hat.i
        W.hat.i <- (1-t$updatewt)*Wh0 + t$updatewt*W.hat.i
        pi.hat.i <- (1-t$updatewt)*pih0 + t$updatewt*pi.hat.i
        N.hat.i <- (1-t$updatewt)*Nh0 + t$updatewt*N.hat.i
        
        iter<- iter+1
        print(sprintf("Open city conv. criteria is %.5f with %d iterations complete.", convdiff, iter))
      } else {
        switch.to.small <- 1
        
        if (convdiff0-convdiff<0) {
          t.tune <- t$tuningwt^(t.ticker)
          t.ticker <- t.ticker+1
        }
        
        Q.hat.i <- (1-t.tune)*Qh0 + t.tune*Q.hat.i
        W.hat.i <- (1-t.tune)*Wh0 + t.tune*W.hat.i
        pi.hat.i <- (1-t.tune)*pih0 + t.tune*pi.hat.i
        N.hat.i <- (1-t.tune)*Nh0 + t.tune*N.hat.i
        
        iter<- iter+1
        print(sprintf("Open city conv. criteria is %.5f with %d iterations complete (small steps, %d).", convdiff, iter, t.ticker))
      }
    }
    
    if (addmode==TRUE) {
      out.open.poploss <- N.hat.i - 1
      out.open.popgain <- 1 - (1/N.hat.i)
    } else {
      out.open.poploss <- 1-N.hat.i
      out.open.popgain <- (1/N.hat.i) - 1
    }
    
    if (iter>=t$maxiter) {
      out.open.converged <- FALSE
    } else {
      out.open.converged <- TRUE
    }
    
    ## Save results to output list
    # Residential population hat: colSums over workplaces (rows) for each residence (col)
    N_res_hat <- colSums(pi.0 * pi.hat.i, na.rm=TRUE) / colSums(pi.0, na.rm=TRUE)
    out <- list(closed.percentloss = out.closed.percentloss,
                closed.percentbenefit = out.closed.percentbenefit,
                closed.percentbenefit.sd = out.calcs$welfsd,
                closed.dollarbenefit = out.closed.dollarbenefit,
                closed.converged = out.closed.converged,
                open.poploss = out.open.poploss,
                open.popgain = out.open.popgain,
                open.converged = out.open.converged,
                diff.pi = diff.pi,
                diff.W = diff.W,
                diff.Q = diff.Q,
                maxeigen = maxeigen,
                Q.hat   = Q.hat.i,   # tract housing price change (ratio vs baseline)
                W.hat   = W.hat.i,   # tract wage change (ratio vs baseline)
                N.hat   = N_res_hat) # residential pop change (ratio vs baseline)
  } else {
    N_res_hat <- colSums(pi.0 * pi.hat.i, na.rm=TRUE) / colSums(pi.0, na.rm=TRUE)
    out <- list(closed.percentloss = out.closed.percentloss,
                closed.percentbenefit = out.closed.percentbenefit,
                closed.percentbenefit.sd = out.calcs$welfsd,
                closed.dollarbenefit = out.closed.dollarbenefit,
                closed.converged = out.closed.converged,
                diff.pi = diff.pi,
                diff.W = diff.W,
                diff.Q = diff.Q,
                maxeigen = maxeigen,
                Q.hat   = Q.hat.i,
                W.hat   = W.hat.i,
                N.hat   = N_res_hat)
  }
  print(summary(rowSums(pi.0 * pi.hat.i, na.rm = TRUE)/rowSums(pi.0, na.rm = TRUE)))
  return(out)
}

## Partial Equilibrium
eqSolverPartial <- function(N, pi.0, W.0, Q.0, A.hat, BED.hat, C.hat, times, p, t, addmode) {
  
  maxeigen <- eqCheck(p)
  
  # Perform initial update and declare initial values
  N.hat.i <- 1
  U.hat.i <- rep.int(1,N)
  O.hat.i <- rep.int(1,N)
  W.hat.i <- wUpdate(A.hat, pi.0, W.0, matrix(1,N,N), N.hat.i, U.hat.i, p$alpha, p$mu)
  Q.hat.i <- qUpdate(C.hat, pi.0, W.0, Q.0, matrix(1,N,N), rep.int(1,N), N.hat.i, p$psi)
  pi.hat.i <- pcfUpdate(BED.hat, pi.0, rep.int(1,N), rep.int(1,N), O.hat.i, p$eps, p$nepszet, p$eta)
  
  
  # Benefit in percent/100
  #print(1-welfCalc(62,62,BED.hat, pi.hat.i, W.hat.i, Q.hat.i, p.eps, p.nepszet))
  out.calcs <- welfCalc2(N, BED.hat, pi.hat.i, W.hat.i, Q.hat.i, p$eps, p$nepszet)
  
  if (addmode==TRUE) {
    out.closed.percentloss <- out.calcs$welfave - 1
    out.closed.percentbenefit <- 1 - (1/out.calcs$welfave)
  } else {
    out.closed.percentloss <- 1-out.calcs$welfave
    out.closed.percentbenefit <- (1/out.calcs$welfave) - 1 
  }
  
  # Benefit in millions of dollars
  #print((1-welfCalc(5,2,BED.hat, pi.hat.i, W.hat.i, Q.hat.i, p.eps, p.nepszet))*31563*6.73)
  out.closed.dollarbenefit <- out.closed.percentbenefit*31563*6.73

  out.closed.converged <- TRUE

  out <- list(closed.percentloss = out.closed.percentloss,
              closed.percentbenefit = out.closed.percentbenefit,
              closed.percentbenefit.sd = out.calcs$welfsd,
              closed.dollarbenefit = out.closed.dollarbenefit,
              closed.converged = out.closed.converged,
              maxeigen = maxeigen)
  print(summary(rowSums(pi.0 * pi.hat.i, na.rm = TRUE)/rowSums(pi.0, na.rm = TRUE)))
  return(out)
}


##############################################
##################################
## Numeric processing functions ##
##################################
##############################################

###################################
addLoss <- function(addedWelf, lostWelf) {
  welf.percent <- ((1 + addedWelf$closed.percentloss) / ( 1- lostWelf$closed.percentloss)) - 1
  welf.dollar <- 31563*6.73*welf.percent
  
  out <- list(closed.percentbenefit = welf.percent,
              closed.dollarbenefit = welf.dollar)
  
  return(out)
}

##################################
pcfUpdate <- function(BEDmat, pi0, Whati, Qhati, Ohati, eps, zeps, eta) {
  #print(summary( (Qhati^zeps) * (Ohati^eta) ))
  pmat <- (BEDmat * (rv2m(Whati)^eps) * cv2m( (Qhati^zeps) * (Ohati^eta)) ) / sum(pi0 * BEDmat * (rv2m(Whati)^eps) * cv2m( (Qhati^zeps) * (Ohati^eta)), na.rm = TRUE)
  pmat[is.na(pi0)] <- NA
  return(pmat)
}                       

##################################
qUpdate <- function(Cmat, pi0, W0, Q0, pihati, Whati, Nhati, psi) {
  ipsi <- 1/(1+psi)
  qvec <- ((Cmat*(Nhati^psi))^ipsi) * (rowSums(pi0 * pihati * rv2m(W0) * rv2m(Whati) , na.rm = TRUE) / rowSums(pi0 * rv2m(W0), na.rm = TRUE))^(psi*ipsi)
  qvec[is.na(Q0)] <- NA
  return(qvec)
}

##################################
wUpdate <- function(Amat, pi0, W0, pihati, Nhati, Uhati, alpha, mu) {
  #print(summary(Amat)) # 10 missings <- PROBLEM IS THAT NA^0 == 1
  #print(summary(Uhati)) # 12 missings
  # 10 missings below
  #print(summary(Amat*(Uhati^mu))) # Bad 12 NAs, Good 10 NAs
  #print(summary((colSums(pi0 * pihati, na.rm = TRUE) / colSums(pi0, na.rm = TRUE))^(alpha-1))) # Bad 10 NAs, Good 10 NAs
  
  wvec <- (Nhati^(alpha-1))* t(t(Amat*(Uhati^mu)) * (colSums(pi0 * pihati, na.rm = TRUE) / colSums(pi0, na.rm = TRUE))^(alpha-1))
  wvec[is.na(W0)] <- NA
  return(wvec)
}

##################################
uUpdate <- function(tt, pi0, W0, pihati, dA) {
  uvec <- rowSums(rv2m(colSums(pi0 * pihati, na.rm = TRUE)) * exp(-1*dA*tt), na.rm = TRUE) / rowSums(rv2m(colSums(pi0, na.rm = TRUE)) * exp(-1*dA*tt), na.rm = TRUE)
  uvec[is.na(uvec)] <- 1 # 2 additional locations that did not receive travel times
  uvec[is.na(W0)] <- NA
  return(uvec)
}

##################################
oUpdate <- function(tt, pi0, Q0, pihati, dB) {
  ovec <- colSums(cv2m(rowSums(pi0 * pihati, na.rm = TRUE)) * exp(-1*dB*tt), na.rm = TRUE) / colSums(cv2m(rowSums(pi0, na.rm = TRUE)) * exp(-1*dB*tt), na.rm = TRUE)
  ovec[is.na(ovec)] <- 1 # 1 additional location that did not receive travel times
  ovec[is.na(Q0)] <- NA
  return(ovec)
}

##################################
nbarUpdate <- function(Amat, BEDmat, Cmat, pi0, W0, pihati, alpha, eps, psi, zeta, zeps) {
  finalexp <- (1+psi)/(eps*(1+psi-alpha*(1+zeta*psi)))
  topline <- pi0 * BEDmat * rv2m( Amat * (colSums(pi0 * pihati, na.rm = TRUE) / colSums(pi0, na.rm = TRUE))^(alpha-1))^eps
  botline <- (cv2m(Cmat * (rowSums(pi0 * pihati * rv2m(W0) * rv2m(Amat * (colSums(pi0 * pihati, na.rm = TRUE) / colSums(pi0, na.rm = TRUE))^(alpha-1)) , na.rm = TRUE) / rowSums(pi0 * rv2m(W0), na.rm = TRUE))^psi))^(zeps/(1+psi))
  output <- sum(topline*botline, na.rm=TRUE)^finalexp
  return(output)
}

##################################
welfCalc <- function(i, j, BEDmat, pihat, What, Qhat, eps, zeps) {
  welf <- ((BEDmat[i,j] * (What[j]^eps) * (Qhat[i]^zeps)) / (pihat[i,j]))^(1/eps)
  return(welf)
}

##################################
welfCalc2 <- function(N, BEDmat, pihat, What, Qhat, eps, zeps) {
  
  welf <- (BEDmat * (rv2m(What)^eps) * (cv2m(Qhat)^zeps) / pihat)^(1/eps)
  
  #welf <- as.vector(rep.int(NA,N))
  #for (i in 1:N) {
  #  welf[i] <- ((BEDmat[i,i] * (What[i]^eps) * (Qhat[i]^zeps)) / (pihat[i,i]))^(1/eps)
  #}
  
  welfave <- mean(welf, na.rm = TRUE)
  welfsd <- sd(welf, na.rm = TRUE)
  
  welfout <- list(welfave=welfave,
                  welfsd=welfsd )
  
  return(welfout)
}

##################################
eigValues <- function(alpha, eps, psi, zeta) {
  ea <- eps*(1-alpha)
  zeps <- eps*(1-zeta)
  ipsi <- (1+psi)/psi
  e1a <- (eps+1)*(1-alpha)
  
  valvec <- c( ea/(1+ea), 0, ea/(1+ea), e1a/(1+ea), 
               1/(1+ea), 0, 1/(1+ea), e1a/(1+ea), 
               0, zeps/(zeps+ipsi), 0, 0,
               0, zeps/(zeps+ipsi), 0, 0)
  
  Amat <- matrix(abs(valvec), 4, 4)
  return(eigen(Amat)$values)
}

##############################################
##############################
## Numeric Helper Functions ##
##############################
##############################################

##############################
addLevel <- function(x, newlevel=NULL) {
  if(is.factor(x)) return(factor(x, levels=c(levels(x), newlevel)))
  return(x)
}

##############################
rv2m <- function(vec) {
  # Read in a vector, interpret as row, return square matrix of row replicates
  matrix(vec,nrow=length(vec),ncol=length(vec),byrow=TRUE)
}            

##############################
cv2m <- function(vec) {
  # Read in a vector, interpret as column, return square matrix of column replicates
  matrix(vec,nrow=length(vec),ncol=length(vec))
}     
