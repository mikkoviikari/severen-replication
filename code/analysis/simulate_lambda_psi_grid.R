## 2D sensitivity: transit effect (lambda scale) × housing supply elasticity (psi)
##
## Rows: lambda_scale — multiplier on D00 and D02 (the semi-elasticities of
##   transit proximity on commuting costs). lambda_scale=1 reproduces the paper's
##   IV estimates. lambda_scale=2 means transit is twice as valuable to commuters.
##
## Columns: psi — housing supply elasticity. psi=1.602 is the paper's baseline.
##   Higher psi = more elastic supply = prices rise less, population resorbs more.
##
## The interaction of interest: stronger transit effects (high lambda) drive bigger
## spatial reallocation of residents toward transit corridors. More elastic supply
## (high psi) allows that reallocation to happen — inelastic supply chokes it off
## and the welfare gain accrues as price premia instead.
##
## Welfare metric: dollar_benefit = pct_welfare_gain × mean_annual_wage × 6.73M workers
##   This is aggregate annual welfare in USD millions for the 5-county LA area.
##   The paper's baseline ($94M) corresponds to lambda_scale=1, psi=1.602.
##
## Output: output/welfare/lambda_psi_grid.pdf + .csv

.libPaths(c("C:/Users/mikva/R/win-library/4.6", .libPaths()))
rm(list = ls())
setwd("C:/Users/mikva/severen")

library(Matrix)
library(dplyr)
source("./code/welfare/simcode_functions.R")

## ── Baseline parameters ───────────────────────────────────────────────────────
p.base <- list(alpha    = 0.640,
               eps      = 2.180,
               zet      = 0.65,
               psi      = 1.602,
               epskappa = -0.239,
               mu       = 0,
               eta      = 0,
               deltaA   = 0.3617,
               deltaB   = 0.7595)

lam.base <- list(A = 0, B = 0, C = 0, E = 0,
                 D00 = -0.149, D02 = -0.128, D25 = 0,
                 cong_lt250 = 0.150, cong_250_500 = 0.189,
                 cong_500_1k = 0, cong_1k_2k = 0, cong_2k_4k = 0)

t.ctrl <- list(convcrit = 0.00001, updatewt = 0.8, tuningwt = 0.5, maxiter = 50)

load("./output/welfare/la_data_2000_v202012.RData")

## ── Grid ──────────────────────────────────────────────────────────────────────
# lambda_scale: multiplier on D00 and D02
lambda_grid <- c(0.25, 0.5, 1.0, 1.5, 2.0, 3.0)
psi_grid    <- c(0.5, 1.0, 1.602, 2.0, 3.0, 4.0)

total_runs  <- length(lambda_grid) * length(psi_grid)
cat(sprintf("Running %d × %d = %d model runs...\n\n",
            length(lambda_grid), length(psi_grid), total_runs))

## ── Run grid ──────────────────────────────────────────────────────────────────
results <- vector("list", total_runs)
k <- 0

for (ls in lambda_grid) {
  for (pv in psi_grid) {
    k <- k + 1
    cat(sprintf("[%2d/%d]  lambda_scale=%.2f  psi=%.3f  ... ",
                k, total_runs, ls, pv))

    p   <- p.base;   p$psi    <- pv
    lam <- lam.base; lam$D00  <- lam.base$D00 * ls
                     lam$D02  <- lam.base$D02 * ls

    res <- tryCatch(
      eqSolve_RemoveTransit(p, lam, vecs, mats, t.ctrl,
                            congestion = FALSE, skipopen = TRUE),
      error = function(e) { cat("ERROR:", conditionMessage(e), "\n"); NULL }
    )

    if (!is.null(res)) {
      cat(sprintf("welfare = $%.2fM (aggregate annual)\n", res$closed.dollarbenefit))
      results[[k]] <- data.frame(
        lambda_scale   = ls,
        psi            = pv,
        dollar_benefit = res$closed.dollarbenefit,
        pct_benefit    = 100 * res$closed.percentbenefit,
        # Spatial dispersion of price and population responses
        sd_lQ          = sd(log(res$Q.hat), na.rm = TRUE),
        sd_lN          = sd(log(res$N.hat), na.rm = TRUE),
        mean_lQ_inner  = mean(log(res$Q.hat)[vecs$dd_05km == 1], na.rm = TRUE),
        mean_lN_inner  = mean(log(res$N.hat)[vecs$dd_05km == 1], na.rm = TRUE)
      )
    } else {
      results[[k]] <- data.frame(
        lambda_scale = ls, psi = pv,
        dollar_benefit = NA, pct_benefit = NA,
        sd_lQ = NA, sd_lN = NA,
        mean_lQ_inner = NA, mean_lN_inner = NA
      )
    }
  }
}

grid_df <- bind_rows(results)

write.csv(grid_df, "./output/welfare/lambda_psi_grid.csv", row.names = FALSE)
cat("\nSaved: output/welfare/lambda_psi_grid.csv\n\n")

## ── Figure ────────────────────────────────────────────────────────────────────

# Reshape to matrices for image/contour plots
make_mat <- function(var) {
  m <- matrix(NA, nrow = length(lambda_grid), ncol = length(psi_grid),
              dimnames = list(as.character(lambda_grid),
                              as.character(round(psi_grid, 3))))
  for (i in seq_along(lambda_grid))
    for (j in seq_along(psi_grid))
      m[i, j] <- grid_df$dollar_benefit[
        grid_df$lambda_scale == lambda_grid[i] & grid_df$psi == psi_grid[j]]
  m
}

mat_welfare <- make_mat("dollar_benefit")

# Colour palette: low = cool blue, high = warm red
n_col  <- 256
pal    <- colorRampPalette(c("#2c7bb6", "#abd9e9", "#ffffbf", "#fdae61", "#d7191c"))(n_col)

# Axis labels
lam_labels <- paste0(lambda_grid, "x")
psi_labels <- as.character(round(psi_grid, 3))
psi_labels[psi_labels == "1.602"] <- "1.602*"

# Mark the baseline cell
base_i <- which(lambda_grid == 1.0)
base_j <- which(round(psi_grid, 3) == 1.602)

pdf("./output/welfare/lambda_psi_grid.pdf", width = 10, height = 8)
layout(matrix(c(1, 2), 1, 2), widths = c(4, 1))

## ── Panel 1: heatmap ──────────────────────────────────────────────────────────
par(mar = c(5.5, 5.5, 4, 1))

zlim <- range(mat_welfare, na.rm = TRUE)
image(seq_along(lambda_grid), seq_along(psi_grid), mat_welfare,
      zlim  = zlim,
      col   = pal,
      xaxt  = "n", yaxt = "n",
      xlab  = "Lambda scale  (multiplier on D00, D02)",
      ylab  = "Psi  (housing supply elasticity)",
      main  = "Transit welfare gain ($M, aggregate annual)\nacross lambda scale and psi")

axis(1, at = seq_along(lambda_grid), labels = lam_labels, cex.axis = 0.95)
axis(2, at = seq_along(psi_grid),    labels = psi_labels, las = 1, cex.axis = 0.85)

# Thin grid lines between cells
abline(h = seq(0.5, length(psi_grid) + 0.5),    col = "white", lwd = 0.6)
abline(v = seq(0.5, length(lambda_grid) + 0.5), col = "white", lwd = 0.6)

# Baseline cell outline
rect(base_i - 0.5, base_j - 0.5, base_i + 0.5, base_j + 0.5,
     border = "black", lwd = 2.5)

# Cell values — pick text colour by the luminance of each cell's fill colour
cell_text_col <- function(val) {
  idx <- max(1, min(n_col, round((val - zlim[1]) / diff(zlim) * (n_col - 1)) + 1))
  rgbv <- col2rgb(pal[idx]) / 255
  lum  <- 0.299 * rgbv[1] + 0.587 * rgbv[2] + 0.114 * rgbv[3]
  if (lum > 0.6) "grey10" else "white"
}

for (i in seq_along(lambda_grid))
  for (j in seq_along(psi_grid))
    if (!is.na(mat_welfare[i, j]))
      text(i, j, sprintf("$%.1fM", mat_welfare[i, j]),
           cex = 0.72, col = cell_text_col(mat_welfare[i, j]))

mtext("Boxed cell = paper baseline (lambda scale 1x, psi = 1.602, marked * on axis)",
      side = 1, line = 4.5, cex = 0.8, col = "grey30")

## ── Panel 2: colour bar ───────────────────────────────────────────────────────
par(mar = c(5.5, 0.5, 4, 3.5))

color_bar_vals <- seq(zlim[1], zlim[2], length.out = n_col)
image(1, color_bar_vals,
      matrix(color_bar_vals, 1, n_col),
      col  = pal,
      xaxt = "n", yaxt = "n", xlab = "", ylab = "",
      main = "$M")
axis(4, las = 1, cex.axis = 0.85)
box()

dev.off()
cat("Saved: output/welfare/lambda_psi_grid.pdf\n")
