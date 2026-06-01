## Map: tract-level amenity (Theta_h) and productivity (Omega_w).
##
## Two panels side by side using the linear-with-transit (lin_wT) spec, year 2000.

rm(list=ls())
setwd("/Users/mikko.viikari/Projects/severen")

library(Matrix)
library(dplyr)
library(ggplot2)
library(scales)
library(patchwork)

## ── Data ─────────────────────────────────────────────────────────────────────
df_raw <- read.csv("./tracts-1.csv") %>%
  filter(yr == 1)

df_prod <- df_raw %>%
  select(tract_id = tract_w, value = Omega_w_lin_wT) %>%
  distinct(tract_id, .keep_all = TRUE) %>%
  mutate(tract_id = as.character(tract_id))

df_amen <- df_raw %>%
  select(tract_id = tract_h, value = Theta_h_lin_wT) %>%
  distinct(tract_id, .keep_all = TRUE) %>%
  mutate(tract_id = as.character(tract_id))

## ── Spatial reference ─────────────────────────────────────────────────────────
geo <- read.csv("./output/coastal_indicator.csv") %>%
  mutate(tract_id = as.character(tract_id))

CBD_lat <- 34.0537; CBD_lon <- -118.2428
geo$dist_cbd_km <- sqrt((geo$lon - CBD_lon)^2 * cos(34.05*pi/180)^2 +
                         (geo$lat - CBD_lat)^2) * 111

load("./output/welfare/la_data_2000_v202012.RData")
station_df <- data.frame(
  tract_id     = as.character(tractlist),
  near_station = as.integer(vecs$tran00 == 1 | vecs$tran02 == 1),
  stringsAsFactors = FALSE
)

join_geo <- function(df) {
  df %>%
    left_join(geo %>% select(tract_id, lat, lon), by = "tract_id") %>%
    left_join(station_df, by = "tract_id") %>%
    filter(!is.na(lat), !is.na(value))
}

df_prod <- join_geo(df_prod)
df_amen <- join_geo(df_amen)

## ── Plot helper ───────────────────────────────────────────────────────────────
asp <- 1 / cos(34.05 * pi / 180)

make_map <- function(df, title_str) {
  cap <- max(abs(quantile(df$value, c(0.02, 0.98), na.rm = TRUE)))
  stn <- df %>% filter(near_station == 1)

  ggplot() +
    geom_point(data = df %>% filter(near_station == 0),
               aes(x = lon, y = lat,
                   colour = pmin(pmax(value, -cap), cap)),
               size = 0.55, alpha = 0.75) +
    scale_colour_gradient2(
      low = "#c23b22", mid = "grey93", high = "#1a6faf",
      midpoint = 0, limits = c(-cap, cap),
      name = "log FE", oob = scales::squish
    ) +
    geom_point(data = stn,
               aes(x = lon, y = lat, fill = value),
               shape = 21, size = 3.2, stroke = 0.6, colour = "grey20") +
    scale_fill_gradient2(
      low = "#c23b22", mid = "grey93", high = "#1a6faf",
      midpoint = 0, limits = c(-cap, cap),
      name = "log FE", oob = scales::squish, guide = "none"
    ) +
    annotate("point", x = CBD_lon, y = CBD_lat,
             shape = 8, size = 3.5, colour = "black", stroke = 1.2) +
    annotate("text", x = CBD_lon + 0.022, y = CBD_lat + 0.03,
             label = "CBD", size = 3, fontface = "bold") +
    labs(title = title_str, x = NULL, y = NULL) +
    coord_fixed(ratio = asp) +
    theme_minimal(base_size = 10) +
    theme(plot.title       = element_text(size = 11, face = "bold", hjust = 0.5),
          legend.position  = "right",
          legend.key.height = unit(1.1, "cm"),
          panel.grid       = element_line(colour = "grey88", linewidth = 0.3),
          axis.text        = element_text(size = 7))
}

p_prod <- make_map(df_prod, "Productivity (Omega_w)")
p_amen <- make_map(df_amen, "Amenity (Theta_h)")

p_out <- (p_prod + p_amen) +
  plot_annotation(
    title    = "Tract-level productivity and amenity: LA metro (year 2000)",
    subtitle = paste0("Linear model with transit (lin_wT). ",
                      "Circles = station tracts. Red = low, blue = high."),
    caption  = "Source: Severen. Colour scale capped at 2nd–98th percentile of each variable.",
    theme    = theme(
      plot.title    = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 9, colour = "grey30"),
      plot.caption  = element_text(size = 8, colour = "grey50")
    )
  )

ggsave("./output/welfare/map_amenity_productivity.pdf",
       p_out, width = 13, height = 6.5)
ggsave("./output/welfare/map_amenity_productivity.png",
       p_out, width = 13, height = 6.5, dpi = 180)

cat("\nSaved: output/welfare/map_amenity_productivity.pdf\n")
cat("Saved: output/welfare/map_amenity_productivity.png\n")
