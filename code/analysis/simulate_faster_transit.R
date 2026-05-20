## Counterfactual: LA Metro Rail at higher speeds.
##
## Starting from the calibrated 2000 baseline (transit already in place),
## asks: what if Metro Rail trains were s× faster?
##
## The shock is an additional travel-time improvement applied on top of the
## existing transit benefit. For speed multiplier s:
##
##   D.hat[i,j] = exp( (s-1) * |lam$D00| * tt00[i,j]
##                   + (s-1) * |lam$D02| * tt02[i,j] )
##
## At s=1: D.hat = 1 (no change — current transit).
## At s=2: D.hat ≈ 1.16 for 2000-line OD pairs, ≈ 1.14 for 2002-extension pairs.
## (Symmetric to the remove-transit D.hat ≈ 0.86–0.88 in the baseline.)
##
## Full GE model: endogenous wages (agglomeration), amenities (deltaA/B),
## commuting network (2552×2552 flow matrix). Closed- and open-city welfare.
##
## Outputs:
##   output/welfare/faster_transit.csv   — tract-level results
##   output/welfare/faster_transit.pdf   — three-panel figure

rm(list=ls())
setwd("/Users/mikko.viikari/Projects/severen")

library(Matrix)
library(dplyr)
source("./code/welfare/simcode_functions.R")

## ── Parameters (identical to run_welfare_main.R) ──────────────────────────────
p <- list(alpha    = 0.640,
          eps      = 2.180,
          zet      = 0.65,
          psi      = 1.602,
          epskappa = -0.239,
          mu       = 0,
          eta      = 0,
          deltaA   = 0.3617,
          deltaB   = 0.7595)

lam <- list(A=0, B=0, C=0, E=0,
            D00=-0.149, D02=-0.128, D25=0,
            cong_lt250=0.150, cong_250_500=0.189,
            cong_500_1k=0, cong_1k_2k=0, cong_2k_4k=0)

t.ctrl <- list(convcrit=0.00001, updatewt=0.8, tuningwt=0.5, maxiter=50)

load("./output/welfare/la_data_2000_v202012.RData")

## ── Spatial reference ─────────────────────────────────────────────────────────
geo <- read.csv("./output/coastal_indicator.csv") %>%
  mutate(tract_id = as.character(tract_id))

CBD_lat <- 34.0537; CBD_lon <- -118.2428
geo$dist_cbd_km <- sqrt((geo$lon - CBD_lon)^2 * cos(34.05*pi/180)^2 +
                         (geo$lat - CBD_lat)^2) * 111

tract_df <- data.frame(tract_id = tractlist, stringsAsFactors=FALSE) %>%
  left_join(geo %>% select(tract_id, lat, lon, dist_cbd_km, dist_coast_m),
            by="tract_id") %>%
  mutate(
    tran00 = vecs$tran00,   # within 500m of 2000-line station
    tran02 = vecs$tran02,   # within 500m of 2002-extension station
    near_station = as.integer(tran00 == 1 | tran02 == 1)
  )

cat("Tracts with spatial coords:", sum(!is.na(tract_df$lat)), "\n")
cat("Near-station tracts (tran00 or tran02):", sum(tract_df$near_station, na.rm=TRUE), "\n\n")

## ── GE solver wrapper for speed-up shock ─────────────────────────────────────
## Mirrors eqSolve_RemoveTransit but applies D.hat > 1 (better commuting).
## addmode=TRUE: welfare = 1 - 1/welfave (benefit of the added speed).

solve_speedup <- function(speed_mult, p, lam, vecs, mats, t.ctrl) {
  p$nepszet <- -1 * p$eps * (1 - p$zet)
  N <- dim(mats$flowmat)[1]

  cf.0 <- as.matrix(mats$flowmat); cf.0[cf.0 == 0] <- NA
  W.0  <- vecs$wage;  W.0[W.0 == 0] <- NA
  Q.0  <- vecs$hval;  Q.0[Q.0 == 0] <- NA
  cf.0[is.na(rv2m(W.0) * cv2m(Q.0))] <- NA

  # Level-shift hats (all zero in baseline lam)
  A.hat <- exp(lam$A * vecs$dd_05km); A.hat[is.na(W.0)] <- NA
  B.hat <- exp(lam$B * vecs$dd_05km); B.hat[is.na(Q.0)] <- NA
  C.hat <- exp(lam$C * vecs$tran00);  C.hat[is.na(Q.0)] <- NA
  E.hat <- exp(lam$E * vecs$dd_05km); E.hat[is.na(W.0)] <- NA

  tt00 <- as.matrix(mats$tt00)
  tt02 <- as.matrix(mats$tt02)

  # Speed-up: negate lam$D signs so D.hat > 1 for affected pairs
  # Extra improvement = (speed_mult - 1) × current improvement
  mult  <- speed_mult - 1
  D.hat <- exp(-lam$D00 * mult * tt00 - lam$D02 * mult * tt02)

  BED.hat <- cv2m(B.hat) * rv2m(E.hat) * D.hat
  cf.0[is.na(BED.hat)] <- NA
  pi.0 <- cf.0 / sum(cf.0, na.rm=TRUE)

  eqSolver(N, pi.0, W.0, Q.0, A.hat, BED.hat, C.hat,
           times    = mats$timemat,
           p        = p,
           t        = t.ctrl,
           skipopen = FALSE,
           addmode  = TRUE)
}

## ── Speed grid ────────────────────────────────────────────────────────────────
speed_grid <- c(1.0, 1.25, 1.5, 2.0, 3.0)

cat("Running", length(speed_grid), "simulations...\n")

results_list <- lapply(speed_grid, function(s) {
  cat("\n====  speed multiplier =", s, " ====\n")

  if (s == 1.0) {
    # Baseline: no change
    return(tract_df %>% mutate(
      speed      = 1.0,
      lQ.hat     = 0,
      lW.hat     = 0,
      lN.hat     = 0,
      welfare_pct    = 0,
      welfare_dollar = 0,
      open_popgain   = 0
    ))
  }

  res <- tryCatch(
    solve_speedup(s, p, lam, vecs, mats, t.ctrl),
    error = function(e) { cat("  ERROR:", conditionMessage(e), "\n"); NULL }
  )
  if (is.null(res)) return(NULL)

  cat(sprintf("  welfare: %.4f%% ($%.2f/person)  |  open-city pop gain: %.4f%%\n",
              100 * res$closed.percentbenefit,
              res$closed.dollarbenefit,
              100 * res$open.popgain))

  tract_df %>%
    mutate(
      speed          = s,
      lQ.hat         = log(res$Q.hat),
      lW.hat         = log(res$W.hat),
      lN.hat         = log(res$N.hat),
      welfare_pct    = 100 * res$closed.percentbenefit,
      welfare_dollar = res$closed.dollarbenefit,
      open_popgain   = 100 * res$open.popgain
    )
})

res_all <- bind_rows(Filter(Negate(is.null), results_list))

## ── Summary ───────────────────────────────────────────────────────────────────
smry <- res_all %>%
  group_by(speed) %>%
  summarise(
    welfare_dollar  = first(welfare_dollar),
    open_popgain    = first(open_popgain),
    mean_lQ_station = mean(lQ.hat[near_station == 1], na.rm=TRUE),
    mean_lQ_other   = mean(lQ.hat[near_station == 0], na.rm=TRUE),
    mean_lN_station = mean(lN.hat[near_station == 1], na.rm=TRUE),
    mean_lN_other   = mean(lN.hat[near_station == 0], na.rm=TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    station_price_premium = mean_lQ_station - mean_lQ_other,
    station_pop_premium   = mean_lN_station - mean_lN_other
  )

cat("\n── Summary by speed multiplier ──\n")
print(smry %>% select(speed, welfare_dollar, open_popgain,
                       station_price_premium, station_pop_premium),
      digits=4)

## ── Inner/outer ring breakdown ────────────────────────────────────────────────
smry_rings <- res_all %>%
  filter(!is.na(dist_cbd_km)) %>%
  mutate(ring = case_when(
    dist_cbd_km <  10 ~ "inner (<10km)",
    dist_cbd_km <= 25 ~ "middle",
    TRUE              ~ "outer (>25km)"
  )) %>%
  group_by(speed, ring) %>%
  summarise(mean_lQ = mean(lQ.hat, na.rm=TRUE),
            mean_lN = mean(lN.hat, na.rm=TRUE),
            .groups="drop")

cat("\n── Price and population change by ring ──\n")
print(smry_rings %>% tidyr::pivot_wider(names_from=ring,
                                         values_from=c(mean_lQ, mean_lN)),
      digits=4)

## ── Save CSV ──────────────────────────────────────────────────────────────────
write.csv(
  res_all %>% select(tract_id, speed, lat, lon, dist_cbd_km, near_station,
                     lQ.hat, lW.hat, lN.hat, welfare_dollar, open_popgain),
  "./output/welfare/faster_transit.csv", row.names=FALSE
)
cat("\nSaved: output/welfare/faster_transit.csv\n")

## ── Figure ────────────────────────────────────────────────────────────────────
pal   <- colorRampPalette(c("grey70", "steelblue", "darkblue"))(length(speed_grid))
xseq  <- seq(0, 60, by=0.5)
speed_labels <- paste0(speed_grid, "×")

loess_sm <- function(d, var, span=0.4) {
  y <- d[[var]]; x <- d$dist_cbd_km
  ok <- !is.na(x) & !is.na(y) & is.finite(y)
  y_ok <- y[ok]; x_ok <- x[ok]
  predict(loess(y_ok ~ x_ok, span=span), data.frame(x_ok=xseq))
}

pdf("./output/welfare/faster_transit.pdf", width=11, height=9)
par(mfrow=c(2,2), mar=c(4.5, 4.5, 3.5, 1.5))

# ── Panel A: Welfare vs speed multiplier ──────────────────────────────────────
smry_nob <- smry[smry$speed > 1, ]
barplot(smry_nob$welfare_dollar,
        names.arg = paste0(smry_nob$speed, "x"),
        col       = pal[-1],
        border    = NA,
        xlab      = "Speed multiplier",
        ylab      = "Welfare gain (USD per person)",
        main      = "(a) Transit welfare gain vs speed",
        las       = 1)
# Mark baseline welfare (current transit)
baseline_wel <- 93.55   # from run_welfare_main.R
abline(h = baseline_wel, lty=2, col="grey40")
text(0.5, baseline_wel * 1.005, sprintf(" current transit ($%.0f)", baseline_wel),
     adj=0, cex=0.8, col="grey40")

# ── Panel B: Spatial price map — lQ.hat vs CBD distance ───────────────────────
sub_list <- lapply(speed_grid, function(s)
  res_all[res_all$speed == s & !is.na(res_all$dist_cbd_km), ])

ylim_Q <- range(sapply(sub_list[-1], function(d)
  range(loess_sm(d, "lQ.hat"), na.rm=TRUE)), na.rm=TRUE)

plot(NA, xlim=c(0,60), ylim=ylim_Q,
     xlab="Distance from CBD (km)",
     ylab=expression(Delta * "ln(Housing price)"),
     main="(b) Spatial price map\n(gain relative to current transit)",
     las=1)
abline(h=0, lty=2, col="grey50")
for (i in seq_along(speed_grid)) {
  lo <- loess_sm(sub_list[[i]], "lQ.hat")
  lines(xseq, lo, col=pal[i], lwd=2.2)
}
legend("topright", legend=speed_labels, col=pal, lwd=2, bty="n", cex=0.82,
       title="Speed")
text(2, ylim_Q[2]*0.55,
     "Prices rise most\nnear CBD & stations",
     cex=0.75, col="darkblue", adj=0)

# ── Panel C: Population sorting — lN.hat vs CBD distance ─────────────────────
ylim_N <- range(sapply(sub_list[-1], function(d)
  range(loess_sm(d, "lN.hat"), na.rm=TRUE)), na.rm=TRUE)

plot(NA, xlim=c(0,60), ylim=ylim_N,
     xlab="Distance from CBD (km)",
     ylab=expression(Delta * "ln(Residential population)"),
     main="(c) Population sorting\n(gain relative to current transit)",
     las=1)
abline(h=0, lty=2, col="grey50")
for (i in seq_along(speed_grid)) {
  lo <- loess_sm(sub_list[[i]], "lN.hat")
  lines(xseq, lo, col=pal[i], lwd=2.2)
}
legend("topright", legend=speed_labels, col=pal, lwd=2, bty="n", cex=0.82,
       title="Speed")

# ── Panel D: Station vs non-station premium vs speed ─────────────────────────
smry_plot <- smry[smry$speed > 1, ]

ylim_prem <- range(c(smry_plot$station_price_premium,
                      smry_plot$station_pop_premium), na.rm=TRUE)

plot(smry_plot$speed, smry_plot$station_price_premium,
     type="b", pch=19, col="steelblue", lwd=2,
     xlim=c(1, max(speed_grid)),
     ylim=ylim_prem,
     xlab="Speed multiplier",
     ylab="Station minus non-station (log pts)",
     main="(d) Station proximity premium\nvs speed multiplier",
     las=1)
lines(smry_plot$speed, smry_plot$station_pop_premium,
      type="b", pch=17, col="darkred", lwd=2)
abline(h=0, lty=2, col="grey50")
legend("topleft",
       legend=c("Housing price premium", "Population premium"),
       col=c("steelblue","darkred"), pch=c(19,17), lwd=2, bty="n", cex=0.9)

dev.off()
cat("Saved: output/welfare/faster_transit.pdf\n")
