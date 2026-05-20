## Spatial equilibrium under different housing supply elasticities (psi).
##
## Simple supply-demand model:
##   Supply: Δln(P_n) = (1/ψ) × Δln(N_n)         [inverse supply curve]
##   Demand: Δln(N_n) = γ·D_n  −  η·Δln(P_n)     [downward sloping demand]
##
## Solving:
##   Δln(P_n) = γ·D_n  /  (1 + η·ψ)      [price absorbs less of the shock as ψ↑]
##   Δln(N_n) = ψ·γ·D_n / (1 + η·ψ)      [quantity absorbs more of the shock as ψ↑]
##
## Demand shock D_n = O_e90_noK_5 (Bartik employment shock at each tract).
## η = 1 (demand elasticity assumption; results scale but ratios are invariant to η).
##
## Outputs:
##   output/welfare/spatial_eqbm_psi.pdf   — four-panel figure
##   output/welfare/spatial_eqbm_psi.csv   — tract-level simulation results

rm(list=ls())
setwd("/Users/mikko.viikari/Projects/severen")

library(dplyr)

## ── 1. Load and clean data ────────────────────────────────────────────────────

pairs <- read.csv("./tracts-1.csv")

# Tract-level data: deduplicate on tract_w (Bartik shock is a workplace variable)
tracts <- pairs %>%
  filter(yr == 1) %>%                       # yr=0 has owners90 all NA
  group_by(tract_w) %>%
  slice(1) %>%
  ungroup() %>%
  select(tract_w, O_e90_noK_5, owners90, tran00_w, distance1999_w, county_w) %>%
  filter(!is.na(O_e90_noK_5), owners90 > 0)

# Merge spatial coordinates
geo <- read.csv("./output/coastal_indicator.csv") %>%
  select(tract_id, lat, lon, dist_coast_m, area_km2)

tracts <- tracts %>%
  left_join(geo, by = c("tract_w" = "tract_id")) %>%
  filter(!is.na(lat))

cat("Tracts in simulation:", nrow(tracts), "\n")
cat("Transit tracts (tran00=1):", sum(tracts$tran00_w == 1, na.rm=TRUE), "\n")
cat("Demand shock (O_e90_noK_5): mean =", round(mean(tracts$O_e90_noK_5),4),
    " SD =", round(sd(tracts$O_e90_noK_5),4), "\n\n")

## ── 2. Simulation ─────────────────────────────────────────────────────────────

psi_grid <- c(0.25, 0.5, 0.75, 1.0, 1.25, 1.602, 2.0, 3.0, 4.0, 6.0)
eta      <- 1      # housing demand elasticity

D <- tracts$O_e90_noK_5
dist_km <- tracts$distance1999_w / 1000   # metres → km

# Normalise: scale so SD(ΔlnP) at ψ=1.602 matches SD(Dlhval) in observed data
sd_observed <- sd(pairs$Dlhval[!is.na(pairs$Dlhval)], na.rm=TRUE)
sd_at_base  <- sd(D / (1 + eta * 1.602), na.rm=TRUE)
scale_D     <- sd_observed / sd_at_base   # so units are comparable to observed data

D_scaled <- D * scale_D

summary_rows <- list()

for (psi in psi_grid) {
  dP <- D_scaled / (1 + eta * psi)        # price change
  dN <- psi * D_scaled / (1 + eta * psi)  # density change

  transit <- tracts$tran00_w == 1 & !is.na(tracts$tran00_w)

  # Transit premium: mean change near stations vs. far
  price_near   <- mean(dP[transit],  na.rm=TRUE)
  price_far    <- mean(dP[!transit], na.rm=TRUE)
  density_near <- mean(dN[transit],  na.rm=TRUE)
  density_far  <- mean(dN[!transit], na.rm=TRUE)

  # Correlation with distance (negative = near-transit gets more)
  cor_price   <- cor(dP, dist_km, use="complete.obs")
  cor_density <- cor(dN, dist_km, use="complete.obs")

  summary_rows[[length(summary_rows)+1]] <- data.frame(
    psi               = psi,
    sd_price          = sd(dP, na.rm=TRUE),
    sd_density        = sd(dN, na.rm=TRUE),
    transit_price_prem   = price_near   - price_far,
    transit_density_prem = density_near - density_far,
    cor_price_dist    = cor_price,
    cor_density_dist  = cor_density
  )
}

smry <- bind_rows(summary_rows)
cat("Summary statistics by psi:\n")
print(smry, digits=4)

## ── 3. Tract-level data for maps ─────────────────────────────────────────────

# Save simulated values at three representative psi values
psi_low  <- 0.5
psi_base <- 1.602
psi_high <- 4.0

map_data <- tracts %>%
  mutate(
    dP_low  = D_scaled / (1 + eta * psi_low),
    dN_low  = psi_low  * D_scaled / (1 + eta * psi_low),
    dP_base = D_scaled / (1 + eta * psi_base),
    dN_base = psi_base * D_scaled / (1 + eta * psi_base),
    dP_high = D_scaled / (1 + eta * psi_high),
    dN_high = psi_high * D_scaled / (1 + eta * psi_high),
    dist_km = distance1999_w / 1000
  )

write.csv(map_data %>% select(tract_w, lat, lon, dist_km, tran00_w,
                               dP_low, dN_low, dP_base, dN_base, dP_high, dN_high),
          "./output/welfare/spatial_eqbm_psi.csv", row.names=FALSE)

## ── 4. Figure ─────────────────────────────────────────────────────────────────

pdf("./output/welfare/spatial_eqbm_psi.pdf", width=11, height=9)
par(mfrow=c(2,2), mar=c(4.5, 4.5, 3.5, 1.5))

cols        <- c("steelblue", "darkred")
psi_palette <- colorRampPalette(c("steelblue","grey60","darkred"))(nrow(smry))
baseline_psi <- 1.602

# ── Panel A: Price dispersion vs density dispersion trade-off ─────────────────
# As psi rises, the shock shifts from price to quantity
plot(smry$sd_price, smry$sd_density,
     col=psi_palette, pch=19, cex=1.6,
     xlab="SD of price change across tracts",
     ylab="SD of density change across tracts",
     main="(a) Price-vs-density dispersion trade-off", las=1)
# Label each point with its psi
text(smry$sd_price, smry$sd_density,
     labels=formatC(smry$psi, digits=3, flag=" "), cex=0.65,
     pos=ifelse(smry$sd_price > median(smry$sd_price), 2, 4))
# Mark baseline
idx_base <- which.min(abs(smry$psi - baseline_psi))
points(smry$sd_price[idx_base], smry$sd_density[idx_base],
       pch=1, cex=2.8, col="black", lwd=2)
legend("topright", legend=c("Paper baseline (ψ=1.602)", "Low ψ → high prices",
                              "High ψ → high density"),
       pch=c(1,19,19), col=c("black",cols[1],cols[2]), pt.cex=c(2,1.5,1.5),
       bty="n", cex=0.8)

# ── Panel B: Supply frontier for a typical tract ──────────────────────────────
# For the median demand shock D_med, trace (ΔlnP, ΔlnN) as ψ varies
D_med <- median(D_scaled, na.rm=TRUE)
psi_fine <- seq(0.1, 8, by=0.05)
dP_frontier <- D_med / (1 + eta * psi_fine)
dN_frontier <- psi_fine * D_med / (1 + eta * psi_fine)

plot(dP_frontier, dN_frontier, type="l", lwd=2.5, col="grey30",
     xlab=expression(Delta * "ln(Price)"),
     ylab=expression(Delta * "ln(Density)"),
     main="(b) Supply frontier: price-density trade-off\n(median demand shock, η = 1)",
     las=1)
# Mark key psi values
mark_psis <- c(0.5, 1.0, 1.602, 2.0, 4.0)
for (pv in mark_psis) {
  px <- D_med / (1 + eta * pv)
  py <- pv * D_med / (1 + eta * pv)
  points(px, py, pch=19, col="steelblue", cex=1.4)
  text(px, py, labels=bquote(psi == .(pv)), cex=0.72, pos=4)
}
abline(h=D_med, lty=3, col="grey60")   # ψ→∞ limit (all absorbed as quantity)
abline(v=D_med, lty=3, col="grey60")   # ψ→0  limit (all absorbed as price)
text(D_med*0.05, D_med*0.97, "all quantity\n(ψ→∞)", cex=0.7, col="grey40", adj=0)
text(D_med*0.97, D_med*0.05, "all price\n(ψ→0)", cex=0.7, col="grey40", adj=1)

# ── Panel C: Price gradient vs transit distance — compare ψ=0.5 vs ψ=4.0 ─────
xseq <- seq(0, 50, by=0.5)
lo_p_low  <- loess(dP_low  ~ dist_km, data=map_data, span=0.5)
lo_p_high <- loess(dP_high ~ dist_km, data=map_data, span=0.5)

plot(map_data$dist_km, map_data$dP_low,
     col=adjustcolor(cols[1], 0.2), pch=19, cex=0.45,
     xlim=c(0, 50),
     ylim=range(c(map_data$dP_low, map_data$dP_high), na.rm=TRUE),
     xlab="Distance to nearest station (km)",
     ylab=expression(Delta * "ln(Price)"),
     main="(c) Housing price gradient", las=1)
points(map_data$dist_km, map_data$dP_high,
       col=adjustcolor(cols[2], 0.2), pch=19, cex=0.45)
lines(xseq, predict(lo_p_low,  data.frame(dist_km=xseq)), col=cols[1], lwd=2.5)
lines(xseq, predict(lo_p_high, data.frame(dist_km=xseq)), col=cols[2], lwd=2.5)
legend("bottomright",
       legend=c(expression(psi == 0.5 ~ "(prices absorb shocks)"),
                expression(psi == 4.0 ~ "(quantities absorb shocks)")),
       col=cols, lwd=2, bty="n", cex=0.82)

# ── Panel D: Density gradient vs transit distance ─────────────────────────────
lo_n_low  <- loess(dN_low  ~ dist_km, data=map_data, span=0.5)
lo_n_high <- loess(dN_high ~ dist_km, data=map_data, span=0.5)

plot(map_data$dist_km, map_data$dN_low,
     col=adjustcolor(cols[1], 0.2), pch=19, cex=0.45,
     xlim=c(0, 50),
     ylim=range(c(map_data$dN_low, map_data$dN_high), na.rm=TRUE),
     xlab="Distance to nearest station (km)",
     ylab=expression(Delta * "ln(Density)"),
     main="(d) Population density gradient", las=1)
points(map_data$dist_km, map_data$dN_high,
       col=adjustcolor(cols[2], 0.2), pch=19, cex=0.45)
lines(xseq, predict(lo_n_low,  data.frame(dist_km=xseq)), col=cols[1], lwd=2.5)
lines(xseq, predict(lo_n_high, data.frame(dist_km=xseq)), col=cols[2], lwd=2.5)
legend("bottomright",
       legend=c(expression(psi == 0.5), expression(psi == 4.0)),
       col=cols, lwd=2, bty="n", cex=0.82)

dev.off()
cat("\nSaved: output/welfare/spatial_eqbm_psi.pdf\n")
cat("Saved: output/welfare/spatial_eqbm_psi.csv\n")
