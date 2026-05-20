## Monocentric city simulation: how psi shapes the spatial equilibrium.
##
## Classic Alonso-Muth-Mills setup:
##   Demand falls with distance from CBD — workers pay more to live close
##   to the centre to save on commuting costs.
##   D_n = exp(-delta * dist_CBD_n)   [exponential distance decay]
##
## Supply-demand equilibrium at each tract:
##   Δln(P_n) = D_n / (1 + η·ψ)       [price absorbs 1/(1+ηψ) of shock]
##   Δln(N_n) = ψ·D_n / (1 + η·ψ)    [density absorbs ψ/(1+ηψ) of shock]
##
## η = 1 (demand elasticity); delta tuned so demand halves every ~10 km.
##
## The key result: higher ψ flattens the price gradient and steepens the
## density gradient. In the limit ψ→∞, prices are uniform across space and
## all spatial variation is in density (Hong Kong / Singapore model).
## In the limit ψ→0, density is uniform and all variation is in prices
## (San Francisco model).
##
## Outputs:
##   output/welfare/monocentric_psi.pdf   — four-panel figure
##   output/welfare/monocentric_psi.csv   — tract-level simulation

rm(list=ls())
setwd("/Users/mikko.viikari/Projects/severen")
library(dplyr)

## ── 1. Tract data and CBD distance ───────────────────────────────────────────

geo <- read.csv("./output/coastal_indicator.csv")

# Downtown LA: City Hall approximately
CBD_lat <- 34.0537
CBD_lon <- -118.2428

# Haversine distance in km
haversine_km <- function(lat1, lon1, lat2, lon2) {
  R <- 6371
  phi1 <- lat1 * pi/180;  phi2 <- lat2 * pi/180
  dphi <- (lat2 - lat1) * pi/180
  dlam <- (lon2 - lon1) * pi/180
  a <- sin(dphi/2)^2 + cos(phi1)*cos(phi2)*sin(dlam/2)^2
  2 * R * asin(sqrt(a))
}

geo$dist_cbd_km <- haversine_km(geo$lat, geo$lon, CBD_lat, CBD_lon)

cat("Distance to CBD (km): mean =", round(mean(geo$dist_cbd_km),1),
    " range =", round(range(geo$dist_cbd_km),1), "\n")

## ── 2. Demand function: D_n = exp(-delta * dist_CBD) ─────────────────────────

# delta = log(2)/10 means demand halves every 10 km — standard for US cities
delta <- log(2) / 10
geo$D <- exp(-delta * geo$dist_cbd_km)

## ── 3. Simulation ─────────────────────────────────────────────────────────────

psi_grid <- c(0.25, 0.5, 1.0, 1.602, 2.0, 4.0, 8.0)
eta      <- 1

# Normalise D so SD(ΔlnP) at ψ=1.602 = 0.10 (roughly observed in LA data)
target_sd <- 0.10
D_raw     <- geo$D
scale_D   <- target_sd / sd(D_raw / (1 + eta * 1.602))
D         <- D_raw * scale_D

cat("Demand D: mean =", round(mean(D),3), " SD =", round(sd(D),3), "\n\n")

# Build simulation results
sim <- geo %>% select(tract_id, lat, lon, dist_cbd_km, dist_coast_m, area_km2)

for (psi in psi_grid) {
  sim[[paste0("dP_", psi)]] <- D / (1 + eta * psi)
  sim[[paste0("dN_", psi)]] <- psi * D / (1 + eta * psi)
}

write.csv(sim, "./output/welfare/monocentric_psi.csv", row.names=FALSE)

## ── 4. Summary statistics ─────────────────────────────────────────────────────

smry <- lapply(psi_grid, function(psi) {
  dP <- D / (1 + eta * psi)
  dN <- psi * D / (1 + eta * psi)
  data.frame(
    psi         = psi,
    sd_price    = sd(dP),
    sd_density  = sd(dN),
    # Price at 0-5km vs 20-30km ring
    price_inner = mean(dP[geo$dist_cbd_km < 5]),
    price_outer = mean(dP[geo$dist_cbd_km > 20 & geo$dist_cbd_km < 30]),
    dens_inner  = mean(dN[geo$dist_cbd_km < 5]),
    dens_outer  = mean(dN[geo$dist_cbd_km > 20 & geo$dist_cbd_km < 30])
  )
}) %>% bind_rows() %>%
  mutate(price_gradient = price_inner - price_outer,
         dens_gradient  = dens_inner  - dens_outer)

cat("Summary:\n")
print(smry %>% select(psi, sd_price, sd_density, price_gradient, dens_gradient),
      digits=3)

## ── 5. Figure ─────────────────────────────────────────────────────────────────

# Colour ramp: blue=low psi (price city), red=high psi (density city)
pal  <- colorRampPalette(c("steelblue","#aaaaaa","darkred"))(length(psi_grid))
xseq   <- seq(0, 55, by=0.5)
dist_v <- geo$dist_cbd_km        # plain vector for loess

pdf("./output/welfare/monocentric_psi.pdf", width=11, height=9)
par(mfrow=c(2,2), mar=c(4.5, 4.5, 3.5, 1.5))

loess_line <- function(y, x, xnew, span=0.35) {
  lo <- loess(y ~ x, span=span)
  predict(lo, data.frame(x=xnew))
}

# ── Panel A: Price gradient vs distance from CBD ─────────────────────────────
dP_range <- range(sapply(psi_grid, function(psi) D/(1+eta*psi)))
plot(NA, xlim=c(0,55), ylim=dP_range,
     xlab="Distance from CBD (km)", ylab=expression(Delta*"ln(Price)"),
     main="(a) Housing price gradient", las=1)
for (i in seq_along(psi_grid)) {
  psi <- psi_grid[i]
  dP  <- D / (1 + eta * psi)
  lines(xseq, loess_line(dP, dist_v, xseq), col=pal[i], lwd=2.2)
}
legend("topright", legend=paste("ψ =", psi_grid),
       col=pal, lwd=2, bty="n", cex=0.8)
text(2,  dP_range[2]*0.97, "expensive centre\n(SF model)", cex=0.75, col="steelblue", adj=0)
text(40, dP_range[1]*1.1,  "uniform prices\n(Singapore model)", cex=0.75, col="darkred", adj=0)

# ── Panel B: Density gradient vs distance from CBD ───────────────────────────
dN_range <- range(sapply(psi_grid, function(psi) psi*D/(1+eta*psi)))
plot(NA, xlim=c(0,55), ylim=dN_range,
     xlab="Distance from CBD (km)", ylab=expression(Delta*"ln(Density)"),
     main="(b) Population density gradient", las=1)
for (i in seq_along(psi_grid)) {
  psi <- psi_grid[i]
  dN  <- psi * D / (1 + eta * psi)
  lines(xseq, loess_line(dN, dist_v, xseq), col=pal[i], lwd=2.2)
}
legend("topright", legend=paste("ψ =", psi_grid),
       col=pal, lwd=2, bty="n", cex=0.8)
text(2,  dN_range[2]*0.97, "sparse centre\n(low ψ)", cex=0.75, col="steelblue", adj=0)
text(15, dN_range[2]*0.75, "dense centre\n(high ψ)", cex=0.75, col="darkred", adj=0)

# ── Panel C: Price-density dispersion frontier ────────────────────────────────
plot(smry$sd_price, smry$sd_density,
     type="b", pch=19, cex=1.5, col="grey30", lwd=1.5,
     xlab="SD of price change (spatial dispersion)",
     ylab="SD of density change (spatial dispersion)",
     main="(c) Dispersion trade-off frontier", las=1)
for (i in seq_along(psi_grid)) {
  points(smry$sd_price[i], smry$sd_density[i], pch=19, col=pal[i], cex=1.8)
  text(smry$sd_price[i], smry$sd_density[i],
       labels=paste0("ψ=", psi_grid[i]), cex=0.72,
       pos=ifelse(smry$sd_price[i] > median(smry$sd_price), 2, 4))
}
# Mark baseline
idx <- which(psi_grid == 1.602)
points(smry$sd_price[idx], smry$sd_density[idx], pch=1, cex=3, lwd=2.5, col="black")

# ── Panel D: Price gradient strength vs psi  (inner-outer ring difference) ────
ylim_d <- range(c(smry$price_gradient, smry$dens_gradient)) * c(0.9, 1.1)
plot(smry$psi, smry$price_gradient, type="b", pch=19, col="steelblue", lwd=2,
     ylim=ylim_d,
     xlab=expression(psi), ylab="Inner ring (0-5km) minus outer ring (20-30km)",
     main="(d) Spatial gradient strength vs ψ", las=1)
lines(smry$psi, smry$dens_gradient, type="b", pch=17, col="darkred", lwd=2)
abline(h=0, lty=3, col="grey50")
abline(v=1.602, lty=2, col="grey60")
legend("right",
       legend=c("Price gradient (falls with ψ)", "Density gradient (rises with ψ)"),
       col=c("steelblue","darkred"), pch=c(19,17), lwd=2, bty="n", cex=0.85)

dev.off()
cat("\nSaved: output/welfare/monocentric_psi.pdf\n")
