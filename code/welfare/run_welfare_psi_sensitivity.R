## Welfare sensitivity to housing supply elasticity (psi).
##
## Varies psi over a grid while holding all other parameters at their
## baseline values (run_welfare_main.R). Produces:
##   output/welfare/psi_sensitivity.csv   — welfare metrics by psi
##   output/welfare/psi_sensitivity.pdf   — two-panel figure
##
## The baseline is psi=1.602 (paper's calibrated value, median of bootstrap).
## The bootstrap 5th–95th percentile range is roughly [0.9, 2.6].

rm(list=ls())
setwd("/Users/mikko.viikari/Projects/severen")

load("./output/welfare/la_data_2000_v202012.RData")

library(Matrix)   # must be attached before mats$flowmat (dgCMatrix) is accessed
library(dplyr)
source("./code/welfare/simcode_functions.R")

## ── Baseline parameters (identical to run_welfare_main.R) ───────────────────
p.base <- list(alpha     = 0.640,
               eps       = 2.180,
               zet       = 0.65,
               psi       = 1.602,   # will be overridden in loop
               epskappa  = -0.239,
               mu        = 0,
               eta       = 0,
               deltaA    = 0.3617,
               deltaB    = 0.7595)

lam <- list(A=0, B=0, C=0, E=0,
            D00=-0.149, D02=-0.128, D25=0,
            cong_lt250=0.150, cong_250_500=0.189,
            cong_500_1k=0, cong_1k_2k=0, cong_2k_4k=0)

t <- list(convcrit=0.00001, updatewt=0.8, tuningwt=0.5, maxiter=50)

## ── Psi grid ─────────────────────────────────────────────────────────────────
## Centred on the baseline 1.602; spans the bootstrap 5th–95th range and beyond
psi_grid <- c(0.5, 0.75, 1.0, 1.25, 1.5, 1.602, 1.75, 2.0, 2.5, 3.0, 4.0)

## ── Run simulations ──────────────────────────────────────────────────────────
cat("Running", length(psi_grid), "simulations...\n")

results <- lapply(psi_grid, function(psi_val) {
  cat("  psi =", psi_val, "\n")
  p <- p.base
  p$psi <- psi_val

  # Check stability condition first
  cond <- (1 - p$zet) * p$psi / (1 + p$psi)
  cond2 <- (1 + p$eps * (1 - p$alpha)) / (2 * p$eps * (1 + p$eps) * (1 - p$alpha))
  stable <- cond <= cond2

  if (!stable) {
    cat("    WARNING: stability condition may not hold at psi =", psi_val, "\n")
  }

  res <- tryCatch(
    eqSolve_RemoveTransit(p, lam, vecs, mats, t, congestion=FALSE, skipopen=FALSE),
    error = function(e) {
      cat("    ERROR at psi =", psi_val, ":", conditionMessage(e), "\n")
      NULL
    }
  )
  if (is.null(res)) return(NULL)

  data.frame(
    psi             = psi_val,
    pct_benefit     = 100 * res$closed.percentbenefit,
    dollar_benefit  = res$closed.dollarbenefit,
    pop_gain_pct    = 100 * res$open.popgain,
    baseline        = (abs(psi_val - 1.602) < 1e-6)
  )
})

out <- bind_rows(Filter(Negate(is.null), results))
write.csv(out, "./output/welfare/psi_sensitivity.csv", row.names=FALSE)
cat("\nResults:\n")
print(out)

## ── Figure ───────────────────────────────────────────────────────────────────
pdf("./output/welfare/psi_sensitivity.pdf", width=9, height=4.5)
par(mfrow=c(1,2), mar=c(4,4.5,3,1))

# Panel A: % welfare benefit
plot(out$psi, out$pct_benefit, type="b", pch=19, col="steelblue",
     xlab=expression(psi ~ "(housing supply elasticity)"),
     ylab="Welfare gain (% of income)",
     main="(a) Welfare benefit — closed city",
     las=1)
abline(v=1.602, lty=2, col="grey50")
text(1.602, min(out$pct_benefit, na.rm=TRUE),
     " baseline\n psi=1.602", adj=c(0,0), cex=0.75, col="grey40")

# Mark bootstrap 5th–95th range
bs <- read.csv("./output/welfare/bootstrap_params.csv")
q5  <- quantile(bs$psi, 0.05)
q95 <- quantile(bs$psi, 0.95)
rect(q5, par("usr")[3], q95, par("usr")[4],
     col=adjustcolor("steelblue", 0.12), border=NA)
legend("topright", legend="Bootstrap 5–95%", fill=adjustcolor("steelblue",0.25),
       border=NA, bty="n", cex=0.8)

# Panel B: $ welfare benefit
plot(out$psi, out$dollar_benefit, type="b", pch=19, col="darkred",
     xlab=expression(psi ~ "(housing supply elasticity)"),
     ylab="Welfare gain (USD millions, aggregate annual)",
     main="(b) Welfare benefit — dollar value",
     las=1)
abline(v=1.602, lty=2, col="grey50")
rect(q5, par("usr")[3], q95, par("usr")[4],
     col=adjustcolor("darkred", 0.10), border=NA)

dev.off()
cat("Saved: output/welfare/psi_sensitivity.pdf\n")
cat("Saved: output/welfare/psi_sensitivity.csv\n")
