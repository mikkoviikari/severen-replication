## Map: population and price change at 2x vs 20x faster Metro Rail.
##
## Four panels: population (top) and housing price (bottom) at 2x and 20x speed.

rm(list=ls())
setwd("/Users/mikko.viikari/Projects/severen")

library(Matrix)
library(dplyr)
library(ggplot2)
library(scales)
library(patchwork)
source("./code/welfare/simcode_functions.R")

## ── Parameters ────────────────────────────────────────────────────────────────
p <- list(alpha=0.640, eps=2.180, zet=0.65, psi=1.602, epskappa=-0.239,
          mu=0, eta=0, deltaA=0.3617, deltaB=0.7595,
          nepszet=-2.180*(1-0.65))
lam <- list(A=0,B=0,C=0,E=0, D00=-0.149,D02=-0.128,D25=0,
            cong_lt250=0.150,cong_250_500=0.189,
            cong_500_1k=0,cong_1k_2k=0,cong_2k_4k=0)
t.c <- list(convcrit=0.00001, updatewt=0.8, tuningwt=0.5, maxiter=50)

load("./output/welfare/la_data_2000_v202012.RData")

## ── Spatial reference ─────────────────────────────────────────────────────────
geo <- read.csv("./output/coastal_indicator.csv") %>%
  mutate(tract_id = as.character(tract_id))
CBD_lat <- 34.0537; CBD_lon <- -118.2428
geo$dist_cbd_km <- sqrt((geo$lon-CBD_lon)^2*cos(34.05*pi/180)^2 +
                         (geo$lat-CBD_lat)^2)*111

tract_df <- data.frame(tract_id=tractlist, stringsAsFactors=FALSE) %>%
  left_join(geo %>% select(tract_id,lat,lon,dist_cbd_km), by="tract_id") %>%
  mutate(near_station = as.integer(vecs$tran00==1 | vecs$tran02==1))

## ── Shared matrix setup ───────────────────────────────────────────────────────
cf.0 <- as.matrix(mats$flowmat); cf.0[cf.0==0] <- NA
W.0  <- vecs$wage; W.0[W.0==0] <- NA
Q.0  <- vecs$hval; Q.0[Q.0==0] <- NA
cf.0[is.na(rv2m(W.0)*cv2m(Q.0))] <- NA
N <- length(W.0)

A.hat <- rep(1,N); A.hat[is.na(W.0)] <- NA
B.hat <- rep(1,N); B.hat[is.na(Q.0)] <- NA
C.hat <- B.hat; E.hat <- A.hat

tt00 <- as.matrix(mats$tt00); tt02 <- as.matrix(mats$tt02)

run_speed <- function(s) {
  cat("Running", s, "x speed...\n")
  mult  <- s - 1
  D.hat <- exp(-lam$D00*mult*tt00 - lam$D02*mult*tt02)
  BED   <- cv2m(B.hat)*rv2m(E.hat)*D.hat
  cf    <- cf.0; cf[is.na(BED)] <- NA
  pi.0  <- cf / sum(cf, na.rm=TRUE)
  res   <- eqSolver(N, pi.0, W.0, Q.0, A.hat, BED, C.hat,
                    mats$timemat, p, t.c, skipopen=TRUE, addmode=TRUE)
  cat(sprintf("  welfare $%.0f/person\n", res$closed.dollarbenefit))
  list(Q.hat=res$Q.hat, N.hat=res$N.hat,
       welfare=res$closed.dollarbenefit, speed=s)
}

res2  <- run_speed(2)
res20 <- run_speed(20)

## ── Assemble ──────────────────────────────────────────────────────────────────
make_df <- function(res) {
  tract_df %>%
    mutate(lN = log(res$N.hat),
           lQ = log(res$Q.hat),
           speed = res$speed) %>%
    filter(!is.na(lat))
}

df2  <- make_df(res2)
df20 <- make_df(res20)
stations <- df20 %>% filter(near_station==1)

## ── Shared colour caps ────────────────────────────────────────────────────────
# Use 20x scale as reference so the two maps are directly comparable
pop_cap   <- max(abs(quantile(df20$lN, c(0.01,0.99), na.rm=TRUE)))
price_cap <- max(abs(quantile(df20$lQ, c(0.01,0.99), na.rm=TRUE)))
asp       <- 1/cos(34.05*pi/180)

## ── Plotting helper ───────────────────────────────────────────────────────────
one_panel <- function(df, var, cap, pal_name, legend_title, speed_val, welfare) {
  stn <- df %>% filter(near_station==1)

  # colour label formatter
  fmt <- function(x) sprintf("%+.0f%%", 100*(exp(x)-1))

  ggplot() +
    geom_point(data = df %>% filter(near_station==0),
               aes(x=lon, y=lat,
                   colour=pmin(pmax(.data[[var]], -cap), cap)),
               size=0.55, alpha=0.75) +
    scale_colour_gradient2(
      low="#c23b22", mid="grey93", high="#1a6faf",
      midpoint=0, limits=c(-cap, cap),
      labels=fmt, name=legend_title, oob=scales::squish
    ) +
    geom_point(data=stn,
               aes(x=lon, y=lat, fill=.data[[var]]),
               shape=21, size=3.2, stroke=0.6, colour="grey20") +
    scale_fill_gradient2(
      low="#c23b22", mid="grey93", high="#1a6faf",
      midpoint=0, limits=c(-cap, cap),
      labels=fmt, name=legend_title, oob=scales::squish,
      guide="none"      # suppress duplicate legend
    ) +
    annotate("point", x=CBD_lon, y=CBD_lat,
             shape=8, size=3.5, colour="black", stroke=1.2) +
    annotate("text", x=CBD_lon+0.022, y=CBD_lat+0.03,
             label="CBD", size=3, fontface="bold") +
    labs(subtitle=sprintf("%dx speed  |  $%.0f/person", speed_val, welfare),
         x=NULL, y=NULL) +
    coord_fixed(ratio=asp) +
    theme_minimal(base_size=10) +
    theme(plot.subtitle  = element_text(size=9, colour="grey30", hjust=0.5),
          legend.position = "right",
          legend.key.height = unit(1.1,"cm"),
          panel.grid      = element_line(colour="grey88", linewidth=0.3),
          axis.text       = element_text(size=7))
}

p_N2  <- one_panel(df2,  "lN", pop_cap,   "RdBu", "Pop.\nchange", 2,  res2$welfare)
p_N20 <- one_panel(df20, "lN", pop_cap,   "RdBu", "Pop.\nchange", 20, res20$welfare)
p_Q2  <- one_panel(df2,  "lQ", price_cap, "RdBu", "Price\nchange", 2,  res2$welfare)
p_Q20 <- one_panel(df20, "lQ", price_cap, "RdBu", "Price\nchange", 20, res20$welfare)

## ── Combine ───────────────────────────────────────────────────────────────────
layout <- "
AB
CD
"

p_out <- (p_N2 + p_N20 + p_Q2 + p_Q20) +
  plot_layout(design=layout, guides="collect") +
  plot_annotation(
    title   = "Effect of faster Metro Rail: 2x vs 20x speed",
    subtitle= paste0("Top row: residential population change  |  ",
                     "Bottom row: housing price change\n",
                     "Circles = station tracts (n=94). ",
                     "Colour scale fixed to 20x range for direct comparison."),
    caption = "Full GE model. Relative to current transit baseline. Red = loss, Blue = gain.",
    theme   = theme(
      plot.title    = element_text(face="bold", size=14),
      plot.subtitle = element_text(size=9, colour="grey30"),
      plot.caption  = element_text(size=8, colour="grey50")
    )
  )

ggsave("./output/welfare/map_faster_transit_compare.pdf",
       p_out, width=13, height=11)
ggsave("./output/welfare/map_faster_transit_compare.png",
       p_out, width=13, height=11, dpi=180)

cat("\nSaved: output/welfare/map_faster_transit_compare.pdf\n")
cat("Saved: output/welfare/map_faster_transit_compare.png\n")
