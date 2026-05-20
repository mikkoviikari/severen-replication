# Housing Supply Elasticity (ψ) — Summary of Findings

## 1. Estimation

The baseline Severen (2021) estimate of ψ = 1.602 comes from structural calibration of the
GE model. Using reduced-form IV (Bartik Bartik employment shock `O_e90_noK_5` as instrument
for log density change in the housing price regression), we recover ψ ≈ 0.46 (= 1/β̂ where
β̂ ≈ 2.17 from `ivreg2 Dlhval (Dldens = O_e90_noK_5)`). The two numbers measure related but
distinct objects: the structural ψ is a supply-curve slope in the GE equilibrium; the IV ψ
is a reduced-form price-to-density elasticity estimated from observed variation.

### Heterogeneous ψ — all splits fail

Every attempt to estimate ψ separately for geographic or density subgroups failed due to
instrument weakness. The Bartik shock requires cross-tract industry variation to work; in
any subgroup (coastal vs. inland, high vs. low 1990 density, core vs. fringe counties) that
variation collapses and the first-stage F-statistic falls to < 4. The pooled ψ ≈ 0.46 is
the most reliable available estimate.

Scripts: `code/analysis/tracts_elasticities_coastal.do`,
         `code/analysis/tracts_elasticities_density.do`,
         `code/analysis/tracts_elasticities_countygroup.do`,
         `code/analysis/tracts_elasticities_interacted.do`

---

## 2. Welfare sensitivity to ψ — remarkably flat

Running the full Severen GE model (endogenous wages, amenities, commuting network) across
ψ ∈ {0.5, 0.75, 1.0, 1.25, 1.5, 1.602, 1.75, 2.0, 2.5, 3.0, 4.0}:

| ψ   | Welfare ($/person) | Open-city pop gain |
|-----|--------------------|--------------------|
| 0.5 | $93.79             | +0.10%             |
| 1.602 (baseline) | $93.55 | +0.09%        |
| 4.0 | $93.38             | +0.08%             |

**Range: $0.41 over an 8× variation in ψ (< 0.5% relative).**

Transit welfare is essentially invariant to housing supply elasticity. The reason: LA Metro
Rail's welfare gain is dominated by commuting time savings (a direct travel cost reduction),
not by housing market effects. Supply elasticity determines how the housing market absorbs
demand shocks, but it has little bearing on the commuting surplus itself.

Script: `code/welfare/run_welfare_psi_sensitivity.R`

### Why the λ_C result (44–140% amplification) does not contradict this

The paper's finding that easing land-use constraints near stations would amplify Metro Rail's
welfare effect by 44–140% is about a **different parameter**: λ_C is a direct supply shift
(upzoning) at specific station tracts, not a change in the economy-wide supply slope ψ.
The amplification comes from transit-housing complementarity at affected stations — more
residents can sort near stations when supply is freed, capturing more of the commuting
benefit. This is a level shift in supply at a few tracts, not a slope change everywhere.

---

## 3. Spatial equilibrium under alternative ψ — calibrated counterfactual

`code/analysis/simulate_psi_counterfactual.R` calibrates tract-level housing supply costs
c_n and amenities A_n from the observed 2000 equilibrium at ψ_0 = 1.602, then solves the
closed-city fixed-point at alternative ψ values (wages held fixed).

**Note on notation:** c_n here is the housing supply cost shifter — the intercept of the
supply curve Q_n = c_n · N_n^(1/ψ). This is distinct from the commuting parameter κ_n in
Severen (2021), which is the semi-elasticity of commuting with respect to travel time
(epskappa = −0.239 in the welfare model).

Key spatial result: the price change at each tract is proportional to its baseline log
density (r ≈ ±1.0). Denser inner-city tracts change **less** than sparse suburban tracts
because the supply-curve rotation effect is proportional to ln(N_n), which is smaller in
magnitude for dense tracts. In other words, ψ changes matter proportionally more for
outer, lower-density suburbs than for the dense urban core.

Limitation: This is a partial equilibrium model (wages and commuting patterns fixed).
Re-solving the full GE model under a different permanent ψ would require re-calibrating
all structural parameters — not feasible with the hat-algebra framework.

Script: `code/analysis/simulate_psi_counterfactual.R`

---

## 4. Monocentric city simulation (Alonso-Muth-Mills)

`code/analysis/simulate_monocentric_psi.R` illustrates the textbook mechanism cleanly
using exponential CBD-distance demand D_n = exp(−δ · dist_CBD):

- **Low ψ (SF model):** steep housing price gradient, flat population density gradient
- **High ψ (Singapore model):** flat price gradient, steep density gradient
- In the limit ψ → ∞: prices uniform, all spatial variation in density
- In the limit ψ → 0: density uniform, all spatial variation in prices

This provides intuition for the empirical results but uses synthetic rather than actual
demand shocks.

---

## 5. Full GE spatial simulation — transit response under different ψ

`code/analysis/simulate_ge_psi_spatial.R` extracts tract-level Q.hat, W.hat, N.hat from
the full GE solver across ψ values. This answers: *how does the spatial pattern of the
transit welfare response change with ψ?*

Key findings (inner <10km from CBD vs. outer >25km):

| ψ   | Price drop, inner | Price drop, outer | Pop loss, inner |
|-----|-------------------|-------------------|-----------------|
| 0.5 | −0.104%           | −0.010%           | −0.100%         |
| 1.602 | −0.168%         | −0.016%           | −0.091%         |
| 4.0 | −0.201%           | −0.019%           | −0.087%         |

- Higher ψ **amplifies** the price response to transit (prices near stations swing more)
- Higher ψ **dampens** the population response (sorting is less disrupted)
- The inner/outer price gradient steepens with ψ — transit is more spatially concentrated
  in its price effects when supply is elastic
- Wage effects are nearly identical across ψ values

**Clarification:** This simulation still conditions on the transit shock (removing Metro
Rail). It answers "how does transit's effect differ across ψ?" not "what does LA look like
under a different ψ?" The latter would require re-estimating the full structural model.
