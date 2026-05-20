## Counterfactual spatial equilibrium under alternative housing supply elasticity.
##
## Calibrates housing supply costs (c_n) and location amenities (A_n) from the
## observed 2000 LA equilibrium, then solves for the new equilibrium at a
## different psi — letting both housing prices AND population re-sort.
##
## NOTE ON NOTATION: c_n here is the housing supply cost shifter (the intercept
## of the supply curve). This is NOT the commuting parameter kappa_n in Severen
## (2021), which is the semi-elasticity of commuting with respect to travel time
## and enters the location-choice/gravity equation (epskappa = -0.239 in the
## welfare model). Conflating the two would be wrong; they are separate objects.
##
## Supply:  Q_n = c_n * N_n^(1/psi)      [c_n = housing supply cost shifter]
## Demand:  N_n = A_n * exp(eps * (ln W_n - alpha * ln Q_n))   [closed city]
##
## Calibration at psi_0 = 1.602:
##   c_n = Q_n^0 / N_n^0^(1/psi_0)       [i.e. ln_c_n = lhval - (1/psi_0)*ldens]
##   A_n = N_n^0 / exp(eps * (ln W_n^0 - alpha * ln Q_n^0))
##
## Wages W_n are held fixed (partial wage equilibrium — relaxing this would
## require the full Severen GE model). Population is held fixed (closed city).
##
## Outputs:
##   output/welfare/psi_counterfactual.csv   — tract-level results
##   output/welfare/psi_counterfactual.pdf   — spatial maps

rm(list=ls())
setwd("/Users/mikko.viikari/Projects/severen")
library(dplyr)

## ── Parameters ────────────────────────────────────────────────────────────────
psi_0   <- 1.602   # baseline (paper's calibrated value)
alpha   <- 0.640   # housing expenditure share
eps     <- 2.180   # Frechet dispersion (labour location elasticity)

## ── 1. Load tract-level data ──────────────────────────────────────────────────
pairs <- read.csv("./tracts-1.csv")

tracts <- pairs %>%
  filter(yr == 1) %>%
  group_by(tract_h) %>%
  slice(1) %>%
  ungroup() %>%
  select(tract_h, lhval, ldens, lwage, owners90, tran00_h, distance1999_h,
         county_h) %>%
  filter(!is.na(lhval), !is.na(ldens), !is.na(lwage), owners90 > 0)

geo <- read.csv("./output/coastal_indicator.csv") %>%
  select(tract_id, lat, lon, dist_coast_m, area_km2)

tracts <- tracts %>%
  left_join(geo, by = c("tract_h" = "tract_id")) %>%
  filter(!is.na(lat))

cat("Tracts:", nrow(tracts), "\n")

## ── 2. Calibrate supply cost c_n and amenity A_n at psi_0 ───────────────────

tracts <- tracts %>%
  mutate(
    ln_c = lhval - (1/psi_0) * ldens,
    ln_A     = ldens - eps * (lwage - alpha * lhval),
    N0       = exp(ldens),   # baseline density (index)
    Q0       = exp(lhval),   # baseline housing price (index)
    W0       = exp(lwage)    # baseline wage (index)
  )

# Verify calibration: predict density from calibrated A_n and W_n, Q_n
tracts <- tracts %>%
  mutate(
    ldens_check = ln_A + eps * (lwage - alpha * lhval),
    resid_calib = ldens - ldens_check
  )
cat("Calibration check — residual (should be ~0): max |resid| =",
    round(max(abs(tracts$resid_calib)), 8), "\n\n")

## ── 3. Solve equilibrium at a new psi (closed-city fixed-point iteration) ─────

solve_equilibrium <- function(psi_new, tracts, max_iter=2000, tol=1e-7, damp=0.05) {
  ln_c <- tracts$ln_c
  ln_A     <- tracts$ln_A
  lW       <- tracts$lwage
  N_total  <- sum(exp(tracts$ldens))  # fixed total population

  # Start from baseline
  lQ <- tracts$lhval
  lN <- tracts$ldens

  for (iter in 1:max_iter) {
    lQ_old <- lQ

    # Demand: N_n = A_n * exp(eps * (lW_n - alpha * lQ_n)), normalised
    lN_raw  <- ln_A + eps * (lW - alpha * lQ)
    # log-sum-exp trick for numerical stability
    lN_raw_c <- lN_raw - max(lN_raw)
    N_raw   <- exp(lN_raw_c)
    lN      <- lN_raw_c - log(sum(N_raw)) + log(N_total)

    # Supply: Q_n = c_n * N_n^(1/psi)
    lQ_new <- ln_c + (1/psi_new) * lN

    # Damped update (critical for stability when eps is large)
    lQ <- (1 - damp) * lQ + damp * lQ_new

    # Convergence
    conv <- max(abs(lQ - lQ_old))
    if (conv < tol) break
  }

  if (iter == max_iter) warning("Did not converge at psi=", psi_new)

  data.frame(
    tract_h  = tracts$tract_h,
    lhval_cf = lQ,
    ldens_cf = lN,
    dlhval   = lQ - tracts$lhval,   # change in log price
    dldens   = lN - tracts$ldens,   # change in log density
    psi      = psi_new,
    converged = (iter < max_iter),
    iters     = iter
  )
}

# Run for a range of psi values
psi_grid <- c(0.5, 0.75, 1.0, 1.25, 1.602, 2.0, 3.0, 4.0, 6.0)

results <- lapply(psi_grid, function(psi_val) {
  res <- solve_equilibrium(psi_val, tracts)
  cat(sprintf("psi=%5.3f: converged=%s (%d iters)  ",
              psi_val, res$converged[1], res$iters[1]))
  cat(sprintf("mean dP=%+.4f  mean dN=%+.4f\n",
              mean(res$dlhval), mean(res$dldens)))
  res
})

res_all <- bind_rows(results)

## ── 4. Summary statistics by psi ─────────────────────────────────────────────

smry <- res_all %>%
  group_by(psi) %>%
  summarise(
    mean_dP   = mean(dlhval),
    sd_dP     = sd(dlhval),
    mean_dN   = mean(dldens),
    sd_dN     = sd(dldens),
    # price change in inner ring (merge back spatial info)
    .groups = "drop"
  )

# Add spatial breakdown
tracts_spatial <- tracts %>%
  mutate(
    dist_cbd_km = sqrt((lon - (-118.2428))^2*cos(34.05*pi/180)^2 +
                        (lat - 34.0537)^2) * 111,
    inner = dist_cbd_km < 10,
    outer = dist_cbd_km > 25
  )

smry_rings <- res_all %>%
  left_join(tracts_spatial %>% select(tract_h, dist_cbd_km, inner, outer),
            by="tract_h") %>%
  group_by(psi) %>%
  summarise(
    dP_inner = mean(dlhval[inner], na.rm=TRUE),
    dP_outer = mean(dlhval[outer], na.rm=TRUE),
    dN_inner = mean(dldens[inner], na.rm=TRUE),
    dN_outer = mean(dldens[outer], na.rm=TRUE),
    .groups="drop"
  )

## ── 5. Save tract-level results for three key psi values ─────────────────────
out_csv <- res_all %>%
  filter(psi %in% c(0.5, 1.602, 4.0)) %>%
  left_join(tracts %>% select(tract_h, lat, lon, distance1999_h,
                               tran00_h, county_h, lhval, ldens, lwage),
            by="tract_h")

write.csv(out_csv, "./output/welfare/psi_counterfactual.csv", row.names=FALSE)

## ── 6. Figure ─────────────────────────────────────────────────────────────────
tracts_aug <- tracts %>%
  mutate(
    dist_cbd_km = sqrt((lon - (-118.2428))^2 * cos(34.05*pi/180)^2 +
                        (lat - 34.0537)^2) * 111
  )

res_plot <- res_all %>%
  left_join(tracts_aug %>% select(tract_h, lat, lon, dist_cbd_km,
                                   ldens, lhval, owners90), by="tract_h")

pal_psi  <- colorRampPalette(c("steelblue","grey70","darkred"))(length(psi_grid))
xseq     <- seq(0, 60, by=0.5)

loess_line <- function(y, x, xnew, span=0.4) {
  ok <- !is.na(x) & !is.na(y)
  y_ok <- y[ok]; x_ok <- x[ok]
  lo <- loess(y_ok ~ x_ok, span=span)
  predict(lo, data.frame(x_ok=xnew))
}

pdf("./output/welfare/psi_counterfactual.pdf", width=11, height=9)
par(mfrow=c(2,2), mar=c(4.5, 4.5, 3.5, 1.5))

# ── Panel A: Price change vs distance from CBD ────────────────────────────────
dP_rng <- range(res_plot$dlhval, na.rm=TRUE)
plot(NA, xlim=c(0,60), ylim=dP_rng,
     xlab="Distance from CBD (km)",
     ylab=expression(Delta * "ln(Housing price)  vs  baseline ψ=1.602"),
     main="(a) Counterfactual housing price change", las=1)
abline(h=0, lty=2, col="grey50")
for (i in seq_along(psi_grid)) {
  sub <- res_plot[res_plot$psi == psi_grid[i], ]
  lo  <- loess_line(sub$dlhval, sub$dist_cbd_km, xseq)
  lines(xseq, lo, col=pal_psi[i], lwd=2.2)
}
legend("bottomright", legend=paste("ψ =", psi_grid),
       col=pal_psi, lwd=2, bty="n", cex=0.78)
text(1, dP_rng[1]*0.9, "prices fall\n(more elastic)", col="darkred",
     cex=0.75, adj=0)
text(1, dP_rng[2]*0.85, "prices rise\n(less elastic)", col="steelblue",
     cex=0.75, adj=0)

# ── Panel B: Density change vs distance from CBD ──────────────────────────────
dN_rng <- range(res_plot$dldens, na.rm=TRUE)
plot(NA, xlim=c(0,60), ylim=dN_rng,
     xlab="Distance from CBD (km)",
     ylab=expression(Delta * "ln(Population density)  vs  baseline ψ=1.602"),
     main="(b) Counterfactual density change", las=1)
abline(h=0, lty=2, col="grey50")
for (i in seq_along(psi_grid)) {
  sub <- res_plot[res_plot$psi == psi_grid[i], ]
  lo  <- loess_line(sub$dldens, sub$dist_cbd_km, xseq)
  lines(xseq, lo, col=pal_psi[i], lwd=2.2)
}
legend("topright", legend=paste("ψ =", psi_grid),
       col=pal_psi, lwd=2, bty="n", cex=0.78)

# ── Panel C: Price change vs baseline density (who benefits most?) ────────────
sub_high <- res_plot[res_plot$psi == 4.0, ]
sub_low  <- res_plot[res_plot$psi == 0.5, ]
plot(sub_high$ldens, sub_high$dlhval,
     pch=19, cex=0.4, col=adjustcolor("darkred", 0.3),
     xlab="Baseline log density (ln owners/km²)",
     ylab=expression(Delta * "ln(Price)"),
     main="(c) Price change vs baseline density\n(who benefits from more elastic supply?)",
     las=1)
points(sub_low$ldens, sub_low$dlhval,
       pch=19, cex=0.4, col=adjustcolor("steelblue", 0.3))
# Regression lines
abline(lm(dlhval ~ ldens, data=sub_high), col="darkred",  lwd=2.5)
abline(lm(dlhval ~ ldens, data=sub_low),  col="steelblue", lwd=2.5)
abline(h=0, lty=2, col="grey50")
legend("topright",
       legend=c(expression(psi==4.0~"(prices fall most in dense tracts)"),
                expression(psi==0.5~"(prices rise most in dense tracts)")),
       col=c("darkred","steelblue"), lwd=2, bty="n", cex=0.8)

# ── Panel D: Aggregate stats by psi ──────────────────────────────────────────
agg <- res_all %>%
  left_join(tracts_aug %>% select(tract_h, dist_cbd_km, owners90), by="tract_h") %>%
  group_by(psi) %>%
  summarise(
    pop_wt_dP = weighted.mean(dlhval, owners90, na.rm=TRUE),
    pop_wt_dN = weighted.mean(dldens, owners90, na.rm=TRUE),
    .groups="drop"
  )

ylim_agg <- range(c(agg$pop_wt_dP, agg$pop_wt_dN))
plot(agg$psi, agg$pop_wt_dP, type="b", pch=19, col="steelblue", lwd=2,
     ylim=ylim_agg,
     xlab=expression(psi),
     ylab="Population-weighted mean change (log pts)",
     main="(d) Metro-wide price and density change vs ψ", las=1)
lines(agg$psi, agg$pop_wt_dN, type="b", pch=17, col="darkred", lwd=2)
abline(h=0, lty=2, col="grey50")
abline(v=1.602, lty=2, col="grey80")
legend("right",
       legend=c("Housing prices", "Population density"),
       col=c("steelblue","darkred"), pch=c(19,17), lwd=2, bty="n", cex=0.9)

dev.off()
cat("\nSaved: output/welfare/psi_counterfactual.pdf\n")
cat("Saved: output/welfare/psi_counterfactual.csv\n")
