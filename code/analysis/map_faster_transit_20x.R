## Map: population change under 20× faster Metro Rail.
##
## Runs the full GE model at speed multiplier = 20, then maps tract-level
## residential population changes across LA.

rm(list=ls())
setwd("/Users/mikko.viikari/Projects/severen")

library(Matrix)
library(dplyr)
library(ggplot2)
library(sf)
library(scales)
source("./code/welfare/simcode_functions.R")

## ── Parameters ────────────────────────────────────────────────────────────────
p <- list(alpha=0.640, eps=2.180, zet=0.65, psi=1.602, epskappa=-0.239,
          mu=0, eta=0, deltaA=0.3617, deltaB=0.7595)
lam <- list(A=0,B=0,C=0,E=0, D00=-0.149,D02=-0.128,D25=0,
            cong_lt250=0.150,cong_250_500=0.189,
            cong_500_1k=0,cong_1k_2k=0,cong_2k_4k=0)
t.ctrl <- list(convcrit=0.00001, updatewt=0.8, tuningwt=0.5, maxiter=50)

load("./output/welfare/la_data_2000_v202012.RData")

## ── Spatial data ──────────────────────────────────────────────────────────────
geo <- read.csv("./output/coastal_indicator.csv") %>%
  mutate(tract_id = as.character(tract_id))

CBD_lat <- 34.0537; CBD_lon <- -118.2428
geo$dist_cbd_km <- sqrt((geo$lon - CBD_lon)^2 * cos(34.05*pi/180)^2 +
                         (geo$lat - CBD_lat)^2) * 111

tract_df <- data.frame(tract_id=tractlist, stringsAsFactors=FALSE) %>%
  left_join(geo %>% select(tract_id, lat, lon, dist_cbd_km), by="tract_id") %>%
  mutate(
    near_station = as.integer(vecs$tran00 == 1 | vecs$tran02 == 1),
    station_2000 = as.integer(vecs$tran00 == 1),
    station_2002 = as.integer(vecs$tran02 == 1)
  )

## ── Run 20× simulation ────────────────────────────────────────────────────────
cat("Running 20× speed simulation...\n")
s <- 20
p$nepszet <- -1 * p$eps * (1 - p$zet)
N <- dim(mats$flowmat)[1]

cf.0 <- as.matrix(mats$flowmat); cf.0[cf.0==0] <- NA
W.0  <- vecs$wage;  W.0[W.0==0] <- NA
Q.0  <- vecs$hval;  Q.0[Q.0==0] <- NA
cf.0[is.na(rv2m(W.0) * cv2m(Q.0))] <- NA

A.hat <- rep(1,N); A.hat[is.na(W.0)] <- NA
B.hat <- rep(1,N); B.hat[is.na(Q.0)] <- NA
C.hat <- rep(1,N); C.hat[is.na(Q.0)] <- NA
E.hat <- rep(1,N); E.hat[is.na(W.0)] <- NA

tt00 <- as.matrix(mats$tt00); tt02 <- as.matrix(mats$tt02)
mult  <- s - 1
D.hat <- exp(-lam$D00 * mult * tt00 - lam$D02 * mult * tt02)

BED.hat <- cv2m(B.hat) * rv2m(E.hat) * D.hat
cf.0[is.na(BED.hat)] <- NA
pi.0 <- cf.0 / sum(cf.0, na.rm=TRUE)

res <- eqSolver(N, pi.0, W.0, Q.0, A.hat, BED.hat, C.hat,
                times=mats$timemat, p=p, t=t.ctrl,
                skipopen=TRUE, addmode=TRUE)

cat(sprintf("Welfare: $%.1fM (aggregate annual)\n", res$closed.dollarbenefit))

## ── Assemble tract data ───────────────────────────────────────────────────────
map_df <- tract_df %>%
  mutate(
    lN_hat = log(res$N.hat),
    lQ_hat = log(res$Q.hat),
    lW_hat = log(res$W.hat)
  ) %>%
  filter(!is.na(lat))

# Station centroids for overlay
stations <- map_df %>% filter(near_station == 1)

cat(sprintf("\nPopulation change:\n"))
cat(sprintf("  Near station (n=%d): mean %+.1f%%\n",
            sum(map_df$near_station), 100*mean(exp(map_df$lN_hat[map_df$near_station==1])-1, na.rm=TRUE)))
cat(sprintf("  Elsewhere  (n=%d): mean %+.1f%%\n",
            sum(!map_df$near_station), 100*mean(exp(map_df$lN_hat[map_df$near_station==0])-1, na.rm=TRUE)))
cat(sprintf("  Top 10 gaining tracts (lN_hat):\n"))
print(map_df %>% arrange(desc(lN_hat)) %>%
      select(tract_id, lat, lon, dist_cbd_km, near_station, lN_hat) %>%
      head(10), digits=3)

## ── Figure: metro-wide map + zoomed corridor ──────────────────────────────────

# Background tracts: cap colour scale at +/-15% so the -3% haze
# doesn't compress the palette; station tracts drawn on top at full range.
bg_cap <- 0.15
asp    <- 1 / cos(34.05 * pi / 180)   # lon/lat aspect for LA

subtitle_txt <- sprintf(
  "Full GE model  |  Welfare: $%.0fM aggregate annual  |  Circles = station tracts (n=%d, avg %+.0f%%)",
  res$closed.dollarbenefit, sum(map_df$near_station),
  100 * mean(exp(map_df$lN_hat[map_df$near_station == 1]) - 1, na.rm=TRUE))

base_map <- function(df, stn, pt_sz=0.75) {
  ggplot() +
    geom_point(data = df %>% filter(near_station == 0),
               aes(x=lon, y=lat,
                   colour = pmin(pmax(lN_hat, -bg_cap), bg_cap)),
               size=pt_sz, alpha=0.8) +
    scale_colour_gradient2(
      low="#c23b22", mid="grey93", high="#1a6faf",
      midpoint=0, limits=c(-bg_cap, bg_cap),
      labels=function(x) sprintf("%+.0f%%", 100*(exp(x)-1)),
      name="Pop. change\n(background)",
      oob=scales::squish
    ) +
    # Station tracts on top: filled dot coloured by actual gain
    geom_point(data=stn,
               aes(x=lon, y=lat, fill=lN_hat),
               shape=21, size=pt_sz*4, stroke=0.6, colour="grey20") +
    scale_fill_gradient2(
      low="#c23b22", mid="grey93", high="#1a6faf",
      midpoint=0,
      labels=function(x) sprintf("%+.0f%%", 100*(exp(x)-1)),
      name="Pop. change\n(station tracts)"
    ) +
    # CBD marker
    annotate("point", x=CBD_lon, y=CBD_lat,
             shape=8, size=4, colour="black", stroke=1.4) +
    annotate("text",  x=CBD_lon+0.025, y=CBD_lat+0.03,
             label="CBD", size=3.5, fontface="bold") +
    coord_fixed(ratio=asp) +
    theme_minimal(base_size=11) +
    theme(panel.grid     = element_line(colour="grey88", linewidth=0.3),
          axis.text      = element_text(size=8),
          legend.key.height = unit(1.1, "cm"))
}

# Full metro area
p_full <- base_map(map_df, stations) +
  labs(x="Longitude", y="Latitude")

# Zoom: station corridor
zx <- c(-118.45, -117.85); zy <- c(33.72, 34.25)
stn_z <- stations %>% filter(lon >= zx[1], lon <= zx[2],
                               lat >= zy[1], lat <= zy[2])
p_zoom <- base_map(
    map_df %>% filter(lon >= zx[1], lon <= zx[2],
                       lat >= zy[1], lat <= zy[2]),
    stn_z, pt_sz=1.4) +
  coord_fixed(xlim=zx, ylim=zy, ratio=asp) +
  labs(x="Longitude", y=NULL,
       title="Station corridor (zoomed)")

library(patchwork)
p_out <- (p_full | p_zoom) +
  plot_layout(guides="collect") +
  plot_annotation(
    title    = "Population change: 20x faster Metro Rail",
    subtitle = subtitle_txt,
    caption  = "Background scale capped at +/-15%. Station tracts (circles) shown at full range. Red = loss, Blue = gain.",
    theme    = theme(
      plot.title    = element_text(face="bold", size=14),
      plot.subtitle = element_text(size=9,  colour="grey35"),
      plot.caption  = element_text(size=8,  colour="grey50")
    )
  )

ggsave("./output/welfare/map_faster_transit_20x.pdf",
       p_out, width=14, height=7)
ggsave("./output/welfare/map_faster_transit_20x.png",
       p_out, width=14, height=7, dpi=180)

cat("\nSaved: output/welfare/map_faster_transit_20x.pdf\n")
cat("Saved: output/welfare/map_faster_transit_20x.png\n")
