## Full GE spatial simulation: how does the transit welfare response vary with psi?
##
## Runs eqSolve_RemoveTransit (the complete Severen GE model) at each psi value
## and extracts tract-level equilibrium vectors: housing price change Q.hat,
## wage change W.hat, and residential population change N.hat.
##
## The question answered: *given transit infrastructure is removed, how does the
## spatial pattern of price, wage, and population adjustment depend on psi?*
## This is the full GE version with:
##   - Endogenous wages (agglomeration: alpha parameter)
##   - Endogenous amenities (deltaA, deltaB parameters)
##   - Full commuting network (N×N flow matrix)
##
## Total metro population is held fixed (closed city). Open-city population
## change is also computed (skipopen=FALSE).
##
## Outputs:
##   output/welfare/ge_psi_spatial.csv   -- tract-level results across psi grid
##   output/welfare/ge_psi_spatial.pdf   -- spatial figures

rm(list=ls())
setwd("/Users/mikko.viikari/Projects/severen")

library(Matrix)
library(dplyr)
source("./code/welfare/simcode_functions.R")

## ── Baseline parameters (identical to run_welfare_main.R) ────────────────────
p.base <- list(alpha     = 0.640,
               eps       = 2.180,
               zet       = 0.65,
               psi       = 1.602,
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

load("./output/welfare/la_data_2000_v202012.RData")

## ── Spatial merge key ─────────────────────────────────────────────────────────
geo <- read.csv("./output/coastal_indicator.csv") %>%
  mutate(tract_id = as.character(tract_id))

# Compute CBD distance (Pythagorean approximation, consistent with other scripts)
CBD_lat <- 34.0537; CBD_lon <- -118.2428
geo$dist_cbd_km <- sqrt((geo$lon - CBD_lon)^2 * cos(34.05*pi/180)^2 +
                         (geo$lat - CBD_lat)^2) * 111

tract_df <- data.frame(
  tract_id = tractlist,
  idx      = seq_along(tractlist),
  stringsAsFactors = FALSE
) %>%
  left_join(geo %>% select(tract_id, lat, lon, dist_cbd_km, dist_coast_m),
            by = "tract_id")

cat("Tracts with spatial coords:", sum(!is.na(tract_df$lat)), "of", nrow(tract_df), "\n\n")

## ── Psi grid ──────────────────────────────────────────────────────────────────
psi_grid <- c(0.5, 0.75, 1.0, 1.25, 1.602, 2.0, 3.0, 4.0)

## ── Run simulations ───────────────────────────────────────────────────────────
cat("Running", length(psi_grid), "full GE simulations...\n")

results_list <- lapply(psi_grid, function(psi_val) {
  cat("\n====  psi =", psi_val, " ====\n")
  p <- p.base
  p$psi <- psi_val

  res <- tryCatch(
    eqSolve_RemoveTransit(p, lam, vecs, mats, t,
                          congestion=FALSE, skipopen=FALSE),
    error = function(e) {
      cat("  ERROR:", conditionMessage(e), "\n")
      NULL
    }
  )
  if (is.null(res)) return(NULL)

  cat(sprintf("  welfare: %.4f%% ($%.2f/person)\n",
              100*res$closed.percentbenefit, res$closed.dollarbenefit))
  cat(sprintf("  open city pop gain: %.4f%%\n", 100*res$open.popgain))

  # Assemble tract-level data frame
  tract_df %>%
    mutate(
      psi      = psi_val,
      Q.hat    = res$Q.hat,         # housing price ratio (cf/baseline)
      W.hat    = res$W.hat,         # wage ratio
      N.hat    = res$N.hat,         # residential pop ratio
      lQ.hat   = log(res$Q.hat),    # log change in housing price
      lW.hat   = log(res$W.hat),    # log change in wage
      lN.hat   = log(res$N.hat),    # log change in residential population
      pct_benefit   = 100 * res$closed.percentbenefit,
      dollar_benefit = res$closed.dollarbenefit,
      open_popgain  = 100 * res$open.popgain
    )
})

res_all <- bind_rows(Filter(Negate(is.null), results_list))
cat("\nTotal tract-psi obs:", nrow(res_all), "\n")

## ── Summary by psi ────────────────────────────────────────────────────────────
smry <- res_all %>%
  group_by(psi) %>%
  summarise(
    mean_lQ  = mean(lQ.hat, na.rm=TRUE),
    sd_lQ    = sd(lQ.hat,   na.rm=TRUE),
    mean_lW  = mean(lW.hat, na.rm=TRUE),
    sd_lW    = sd(lW.hat,   na.rm=TRUE),
    mean_lN  = mean(lN.hat, na.rm=TRUE),
    sd_lN    = sd(lN.hat,   na.rm=TRUE),
    pct_benefit    = first(pct_benefit),
    dollar_benefit = first(dollar_benefit),
    open_popgain   = first(open_popgain),
    .groups = "drop"
  )

cat("\nSummary:\n")
print(smry %>% select(psi, mean_lQ, sd_lQ, mean_lW, sd_lW, pct_benefit, dollar_benefit),
      digits=4)

## ── Spatial breakdown: inner (<10km) vs outer (>25km) ────────────────────────
smry_rings <- res_all %>%
  filter(!is.na(dist_cbd_km)) %>%
  mutate(ring = case_when(
    dist_cbd_km < 10 ~ "inner",
    dist_cbd_km > 25 ~ "outer",
    TRUE             ~ "middle"
  )) %>%
  group_by(psi, ring) %>%
  summarise(
    mean_lQ = mean(lQ.hat, na.rm=TRUE),
    mean_lN = mean(lN.hat, na.rm=TRUE),
    .groups="drop"
  )

cat("\nSpatial breakdown (inner <10km, outer >25km):\n")
print(smry_rings %>% tidyr::pivot_wider(names_from=ring,
                                         values_from=c(mean_lQ, mean_lN)),
      digits=4)

## ── Save CSV ──────────────────────────────────────────────────────────────────
write.csv(res_all %>% select(tract_id, psi, lat, lon, dist_cbd_km,
                              lQ.hat, lW.hat, lN.hat,
                              pct_benefit, dollar_benefit, open_popgain),
          "./output/welfare/ge_psi_spatial.csv", row.names=FALSE)
cat("\nSaved: output/welfare/ge_psi_spatial.csv\n")

## ── Figure ────────────────────────────────────────────────────────────────────
pal  <- colorRampPalette(c("steelblue","grey60","darkred"))(length(psi_grid))
xseq <- seq(0, 60, by=0.5)

loess_line <- function(y, x, xnew, span=0.4) {
  ok <- !is.na(x) & !is.na(y) & is.finite(y)
  y_ok <- y[ok]; x_ok <- x[ok]
  lo <- loess(y_ok ~ x_ok, span=span)
  predict(lo, data.frame(x_ok=xnew))
}

pdf("./output/welfare/ge_psi_spatial.pdf", width=11, height=9)
par(mfrow=c(2,2), mar=c(4.5, 4.5, 3.5, 1.5))

# ── Panel A: Housing price response vs CBD distance ───────────────────────────
sub_list <- lapply(psi_grid, function(pv) res_all[res_all$psi == pv & !is.na(res_all$dist_cbd_km), ])

# Use loess smooths at baseline psi to set y-range (avoids outlier-driven limits)
get_loess_range <- function(d_list, var) {
  lvals <- lapply(d_list, function(d) {
    y <- d[[var]]; x <- d$dist_cbd_km
    ok <- !is.na(x) & !is.na(y) & is.finite(y)
    if (sum(ok) < 10) return(NULL)
    predict(loess(y[ok] ~ x[ok], span=0.4), data.frame(`x[ok]`=xseq))
  })
  range(unlist(lvals), na.rm=TRUE)
}

loess_vals <- function(d, var, span=0.4) {
  y <- d[[var]]; x <- d$dist_cbd_km
  ok <- !is.na(x) & !is.na(y) & is.finite(y)
  y_ok <- y[ok]; x_ok <- x[ok]
  predict(loess(y_ok ~ x_ok, span=span), data.frame(x_ok=xseq))
}

ylim_Q <- range(sapply(sub_list, function(d) range(loess_vals(d, "lQ.hat"), na.rm=TRUE)), na.rm=TRUE)

plot(NA, xlim=c(0,60), ylim=ylim_Q,
     xlab="Distance from CBD (km)",
     ylab=expression(Delta * "ln(Housing price)  [transit removal]"),
     main="(a) Housing price response to transit removal", las=1)
abline(h=0, lty=2, col="grey50")
abline(v=c(10,25), lty=3, col="grey80")
for (i in seq_along(psi_grid)) {
  lines(xseq, loess_vals(sub_list[[i]], "lQ.hat"), col=pal[i], lwd=2.2)
}
legend("bottomright", legend=paste("psi =", psi_grid),
       col=pal, lwd=2, bty="n", cex=0.75)
text(1, ylim_Q[2]*0.85,
     "Higher price drop = transit\nvalued more when supply inelastic",
     cex=0.7, col="steelblue", adj=0)

# ── Panel B: Residential population response vs CBD distance ──────────────────
ylim_N <- range(sapply(sub_list, function(d) range(loess_vals(d, "lN.hat"), na.rm=TRUE)), na.rm=TRUE)

plot(NA, xlim=c(0,60), ylim=ylim_N,
     xlab="Distance from CBD (km)",
     ylab=expression(Delta * "ln(Population)  [transit removal]"),
     main="(b) Residential population response to transit removal", las=1)
abline(h=0, lty=2, col="grey50")
abline(v=c(10,25), lty=3, col="grey80")
for (i in seq_along(psi_grid)) {
  lines(xseq, loess_vals(sub_list[[i]], "lN.hat"), col=pal[i], lwd=2.2)
}
legend("topright", legend=paste("psi =", psi_grid),
       col=pal, lwd=2, bty="n", cex=0.75)

# ── Panel C: Wage response vs CBD distance ────────────────────────────────────
ylim_W <- range(sapply(sub_list, function(d) range(loess_vals(d, "lW.hat"), na.rm=TRUE)), na.rm=TRUE)

plot(NA, xlim=c(0,60), ylim=ylim_W,
     xlab="Distance from CBD (km)",
     ylab=expression(Delta * "ln(Wage)  [transit removal]"),
     main="(c) Wage response to transit removal", las=1)
abline(h=0, lty=2, col="grey50")
abline(v=c(10,25), lty=3, col="grey80")
for (i in seq_along(psi_grid)) {
  lines(xseq, loess_vals(sub_list[[i]], "lW.hat"), col=pal[i], lwd=2.2)
}
legend("topright", legend=paste("psi =", psi_grid),
       col=pal, lwd=2, bty="n", cex=0.75)

# ── Panel D: Welfare and spatial dispersion vs psi ────────────────────────────
par(mar=c(4.5, 4.5, 3.5, 4.5))
plot(smry$psi, smry$dollar_benefit, type="b", pch=19, col="steelblue", lwd=2,
     xlab=expression(psi ~ "(housing supply elasticity)"),
     ylab="Transit welfare gain ($/person)",
     main="(d) Welfare and spatial dispersion vs psi", las=1)
abline(v=1.602, lty=2, col="grey50")

par(new=TRUE)
plot(smry$psi, smry$sd_lQ, type="b", pch=17, col="darkred", lwd=2,
     axes=FALSE, xlab="", ylab="")
axis(4, col.axis="darkred", col="darkred", las=1)
mtext("SD of price response (log pts)", side=4, line=3, col="darkred", cex=0.8)

legend("topright",
       legend=c("Transit welfare ($/person)", "SD of price response"),
       col=c("steelblue","darkred"), pch=c(19,17), lwd=2, bty="n", cex=0.8)

dev.off()
cat("Saved: output/welfare/ge_psi_spatial.pdf\n")
