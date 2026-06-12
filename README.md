# Severen (2021) — LA Metro Rail Replication

Replication code and extended analysis for **Severen (2021), "Commuting, Labor, and
Housing Market Effects of Mass Transportation: Welfare and Identification"**
(*Review of Economics and Statistics*).

The original paper estimates the general-equilibrium welfare effects of the 1990–2002
Los Angeles Metro Rail build-out on commuting flows, wages, and housing prices across
2,552 census tracts in the five-county LA metro area. This repository replicates the
full pipeline and adds extensions on housing-supply (ψ) sensitivity and
amplified-connectivity ("faster-transit") counterfactuals.

> **Convention note:** throughout, ψ follows the paper's convention of an **inverse**
> housing supply elasticity (the slope of price on quantity). The baseline ψ = 1.602
> implies a housing supply elasticity of 1/ψ = 0.624 — i.e., supply is inelastic.
> Higher ψ = less elastic supply. Welfare figures are **aggregate annual** amounts for
> the five-county area (the paper's "$94 million in annual benefits"), not per-person.

---

## Computational requirements

Original environment: Windows 10 Enterprise (64-bit), Intel Core i7-8700 @ 3.20 GHz,
16.0 GB RAM. At least **8 GB RAM** recommended (some Stata data files are very large).

Required software:

- **Stata v16.0** or later (MP recommended for large flow regressions)
- **R v3.6** or later
- **Python 3** or later (to execute stata-tex table output)
- **Java Virtual Machine (JVM)** and **Graphhopper** — only needed if rebuilding
  travel time matrices from scratch (takes ~1 week; see original README for details).
  Pre-computed route files are included in the Harvard Dataverse release.

---

## Prerequisites

### Stata packages

Install all required packages once:

```stata
do setup.do
```

This installs: `blindschemes`, `estout`, `reghdfe`, `ppmlhdfe`, `ftools`, `gtools`,
`winsor2`, `ivreg2`, `ivreghdfe`, `ranktest`, `regsave`, `coefplot`, `binsreg`,
and `stata-tex` (from [https://github.com/paulnov/stata-tex](https://github.com/paulnov/stata-tex)).

> **Note:** When running stata-tex, make sure Dropbox or other file-syncing utilities
> are inactive. stata-tex edits files in place and sync conflicts can cause errors.

### R packages

```r
install.packages(c(
  "Matrix", "dplyr", "tidyr", "ggplot2", "scales", "patchwork",
  "sf", "rnaturalearth", "data.table", "xtable"
))
```

---

## Data

Raw data and intermediate outputs are **not included** in this repository (gitignored).
Download the following three archives from the Harvard Dataverse and unpack them into
the project root:

> **[https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/SWCGSP](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/SWCGSP)**

| Archive | Unpack into | Contents |
|---|---|---|
| `data.tar.gz` | `data/` | All raw input data |
| `output_main.tar.gz` | `output/` | Main intermediate `.dta` files used by the analysis scripts |
| `output_other.tar.gz` | `output/` | Additional intermediate files (crosswalks, route proximity, welfare inputs) |

```bash
mkdir -p data output
tar -xzf data.tar.gz         -C data/
tar -xzf output_main.tar.gz  -C output/
tar -xzf output_other.tar.gz -C output/
```

> **Note on NCDB:** The Neighborhood Change Database (used for pre-trends analysis,
> Appendix Table H2) is licensed and **not included in the Dataverse release**.
> To obtain access contact Geolytics:
> P.O. Box 5336, Somerville, NJ 08876 · T: 800-577-6717 · questions@geolytics.com

---

## Repository structure

```
severen/
├── code/
│   ├── build/         # Stata + R scripts: raw data → analytical datasets
│   ├── analysis/      # Stata + R scripts: estimation, simulation, maps
│   ├── welfare/       # R scripts: GE equilibrium solver and counterfactuals
│   ├── bartik-weight/ # Rotemberg weight diagnostics for the Bartik instrument
│   └── tablecode/     # stata-tex table generation (see tablecode/README.md)
├── tables/            # LaTeX table templates and filled results
├── figures/           # Output maps and figures
├── results/           # Preliminary model results (called by analysis scripts)
├── notes/             # Extended analysis notes (psi_findings.md)
├── master.do          # Stata entry point — runs full build + analysis pipeline
├── profile.do         # Environment settings — called automatically by master.do
└── setup.do           # Stata package installer (run once)
```

---

## Running the replication

The intended path is to replicate from the **intermediate analytical datasets**,
which are distributed separately as `output/output_main.tar.gz` and
`output/output_other.tar.gz`. Unpack both into `output/` before proceeding.

> If you need to rebuild from raw data, first run
> `code/build/index_rbuildscripts.R` (set `cdir`) and then `master.do` lines 19–48
> to regenerate the intermediate files, then continue with the steps below.

### Step 1 — Install Stata packages (one-time)

```stata
do setup.do
```

### Step 2 — Econometric analysis

Open `master.do` (which automatically calls `profile.do` to set environment variables)
and execute **lines 57–81**:

```stata
do master.do   // lines 57-81
```

Key outputs by table:

| Table / Figure | Script |
|---|---|
| Figure 1 | `code/build/map_prep3.R` |
| Figure 2 | `code/analysis/plot_wagetransit.do` |
| Figure 3 | `code/analysis/plot_flowdensity_ptreatment.do` |
| Table 1 (Panel A) | `code/analysis/flows_metroeffects.do` |
| Table 1 (Panel B) | `code/analysis/flows_lehdthrough2015.do` |
| Table 2 | `code/analysis/flows_congestion.do` |
| Table 3 (Panels A–B) | `code/analysis/tracts_elasticities.do` |
| Table 3 (Panel C) | `code/analysis/comparison_FEs_vs_wage.do` |
| Table 4 | `code/analysis/tracts_elasticities.do` |
| Table 5 | `code/analysis/estimate_lambdas.do` |
| Table 6 | `code/welfare/run_welfare_main.R` + `run_welfare_bootstrap.R` |
| Table E1 | `code/analysis/bootstrap_run.do` |
| Table F1 | `code/analysis/gravity.do` |
| Table H2 | `code/analysis/test_ncdbpretrends.do` |
| Tables H7–H8 | `code/analysis/epsilon_shiftshareanalysis*.do` |
| Tables H9–H12 | `code/analysis/estimate_lambdas.do` |
| Table H13 | `code/welfare/run_welfare_extended.R` |

Also produces `output/welfare/la_data_2000_v202012.RData` — GE model inputs required
by all R welfare scripts.

### Step 3 — GE welfare analysis (R)

```r
# Set cdir to your project root first
source("code/welfare/index_rwelfarescripts.R")
```

Runs the full general-equilibrium welfare model (hat-algebra, Dekle-Eaton-Kortum 2008).
Main outputs:
- Closed-city and open-city welfare gains from Metro Rail (~$94 million per year,
  aggregate, for the five-county area — roughly $14 per worker)
- PDF/PNG figures for all GE counterfactuals

---

## Extended analyses

The following scripts extend the original paper. All require
`output/welfare/la_data_2000_v202012.RData` from Step 2.

### Housing supply (ψ) sensitivity

#### Geographic covariates

```bash
Rscript code/analysis/make_coastal_split.R
```

Produces `output/coastal_indicator.csv`: tract-level coastal distance, coastal
indicator, land area (km²), and WGS84 centroids. Required by subsequent ψ scripts
and Stata splits.

#### Welfare across the ψ grid

```bash
Rscript code/welfare/run_welfare_psi_sensitivity.R
```

Re-solves the full GE model at each ψ on a grid from 0.5 to 4.0 and records the
closed-city welfare gain. Output: `output/welfare/psi_sensitivity.csv` + `.pdf`.
Key result: aggregate welfare is essentially invariant to ψ (varies by ~$0.4M
across the full grid, around the $93.55M baseline).

#### Full GE spatial simulation across ψ

```bash
Rscript code/analysis/simulate_ge_psi_spatial.R
```

Runs `eqSolve_RemoveTransit()` across ψ ∈ {0.5, 0.75, 1.0, 1.25, 1.602, 2.0, 3.0, 4.0}
and extracts tract-level Q̂, Ŵ, N̂. Output: `output/welfare/ge_psi_spatial.csv`

#### λ × ψ interaction grid

```bash
Rscript code/analysis/simulate_lambda_psi_grid.R
```

2D sensitivity: re-solves the GE model over a grid of the transit commuting-effect
multiplier (scaling λ_D00, λ_D02) crossed with ψ, and plots aggregate annual welfare
($M) as a heatmap. Welfare scales roughly linearly in the λ multiplier; the ψ effect
is small and the two are close to separable.
Output: `output/welfare/lambda_psi_grid.csv` + `.pdf`

#### Partial-equilibrium spatial counterfactuals

```bash
Rscript code/analysis/simulate_psi_counterfactual.R
Rscript code/analysis/simulate_spatial_eqbm_psi.R
```

Calibrate tract-level housing supply costs and amenities from the 2000 equilibrium
at ψ₀ = 1.602, then solve closed-city fixed points under alternative ψ values with
wages held fixed. Outputs: `output/welfare/psi_counterfactual.csv`,
`output/welfare/spatial_eqbm_psi.csv`.
**Caveat:** these auxiliary scripts parameterize the supply curve as Q = c·N^(1/ψ),
treating ψ as the supply elasticity proper — the *opposite* of the paper's
inverse-elasticity convention used by the GE model. Interpret their ψ direction
accordingly (see convention note at top).

#### Monocentric city illustration

```bash
Rscript code/analysis/simulate_monocentric_psi.R
```

Textbook Alonso-Muth-Mills model illustrating how supply conditions split a local
demand shock between prices and quantities. **Caveat:** like the PE scripts above,
this script uses ψ as the supply elasticity proper (ΔlnN = ψ·D/(1+ηψ)), so within
the script low ψ = steep price gradient — the opposite direction from the paper's
convention. Output: `output/welfare/monocentric_psi.csv`

#### Heterogeneous ψ IV estimates (Stata)

Requires `powFEs.dta` (Step 2) and `output/coastal_indicator.csv` (above).

```stata
stata-mp -b do code/analysis/tracts_elasticities_coastal.do
stata-mp -b do code/analysis/tracts_elasticities_density.do
stata-mp -b do code/analysis/tracts_elasticities_countygroup.do
```

- **Coastal split**: Bartik instrument is too weak for coastal tracts (KP F ≈ 0.2,
  N = 188); inland (93% of tracts) gives ψ̂ ≈ 0.49 with KP F = 9.89 — the most
  nearly reliable sub-sample result.
- **Density split**: median split on 1990 homeowner density. First stages are weak
  (KP F = 1.83 high-density, 7.46 low-density — both below 10). Point estimates
  ψ̂ ≈ 0.44 (high-density) and 0.49 (low-density), both well below the pooled 1.602.
- **County groups**: core (LA + Orange) vs. fringe (Riverside + San Bernardino +
  Ventura); KP F = 3.24 and 1.93 respectively — too weak for inference.

See `notes/psi_findings.md` for a full summary.

### Amplified-connectivity ("faster-transit") counterfactuals

```bash
# Welfare, price map, and population sorting at multipliers 1.25×–3×
Rscript code/analysis/simulate_faster_transit.R

# Spatial map: population change at multiplier 20× (extreme upper bound)
Rscript code/analysis/map_faster_transit_20x.R

# Four-panel comparison: population + price at 2× vs 20×
Rscript code/analysis/map_faster_transit_compare.R
```

The counterfactual scales the structural commuting disutility parameters
λ_D00 and λ_D02 — estimated from a DiD on binary Metro connectivity indicators
— by multiplier s, applying (s−1) additional units of the observed commuting
benefit to all connected OD pairs. It does not compute new travel times.

Key result: doubling the estimated commuting benefit (s=2) adds $105 million/year
in aggregate welfare, rising roughly linearly to $223 million/year at s=3. This
pattern is consistent with network coverage being the binding constraint — only
94/2,552 tracts (3.7%) are near stations, and just ~0.8% of commuters travel on
Metro-connected OD pairs — rather than the per-pair magnitude of the benefit,
though a direct test would require simulating network expansion, which these
scripts do not do.

---

## Notes on the GE model

The welfare model (`code/welfare/simcode_functions.R`) uses hat-algebra: it solves for
**proportional changes** from the calibrated 2000 baseline, not absolute levels.

Three important limitations:

1. **ψ counterfactuals**: Changing ψ alone with no demand shock produces trivial
   Q̂ = Ŵ = N̂ = 1. The scripts here answer "how does the transit removal response
   change with ψ?" — not "what does LA look like under a different ψ?" The latter
   requires re-estimating all structural parameters from scratch.

2. **Coverage constraint**: The transit shock only affects OD pairs crossing the Metro
   corridor (λ_D00, λ_D02 parameters). Only ~0.8% of commuters travel on
   Metro-connected OD pairs (0.04% of all OD pairs), so amplifying the per-pair
   benefit moves aggregate welfare roughly linearly and modestly. This is consistent
   with network coverage, rather than per-pair benefit size, limiting aggregate gains,
   though no expansion counterfactual is simulated.

3. **ψ convention mismatch in auxiliary scripts**: The GE model and the paper define
   ψ as an inverse supply elasticity (higher ψ = less elastic). The auxiliary
   partial-equilibrium and monocentric scripts (`simulate_psi_counterfactual.R`,
   `simulate_spatial_eqbm_psi.R`, `simulate_monocentric_psi.R`) parameterize supply
   the other way around (ψ as the elasticity proper). Comparisons across the two
   families of scripts should flip the ψ direction.

---

## Citation

Severen, Christopher (2021). "Commuting, Labor, and Housing Market Effects of Mass
Transportation: Welfare and Identification." *Review of Economics and Statistics*,
forthcoming. [https://doi.org/10.1162/rest_a_01037](https://doi.org/10.1162/rest_a_01037)
