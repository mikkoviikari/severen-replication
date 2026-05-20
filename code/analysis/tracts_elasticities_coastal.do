/* Coastal vs. inland housing supply elasticity (psi) split.
   Preferred spec: c2 from tracts_elasticities.do
     ivreg2 Dlhval (Dldens = O_e90_noK_5) if tc_hval==0 [aw=owners90], robust first
   Coastal = within 5 km of Pacific coastline (output/coastal_indicator.csv).

   NOTE: The Bartik instrument is very weak for the coastal group (KP F ≈ 0.2,
   N ≈ 188 in estimation sample). The coastal psi estimate is not reliable.
   The instrument fails because the coastal strip has too few tracts for
   cross-industry variation to identify the Bartik shock.
   See tracts_elasticities_density.do for a split where the instrument works.  */

use "./output/powFEs", clear

* Merge geographic indicators
preserve
    import delimited "./output/coastal_indicator.csv", clear varnames(1)
    rename tract_id tract_w
    keep tract_w dist_coast_m coastal lon lat
    tempfile geo
    save `geo'
restore
merge m:1 tract_w using `geo', keep(master match) nogen

di "Estimation sample (tc_hval==0) by coastal group:"
tab coastal if tc_hval==0

* ── COASTAL (<5 km) — instrument too weak, results descriptive only ──────────
di _newline "COASTAL (<5 km from Pacific):"
ivreg2 Dlhval (Dldens = O_e90_noK_5) if tc_hval==0 & coastal==1 ///
    [aw=owners90], robust first
di "psi (coastal):"
nlcom (1/_b[Dldens])

* ── INLAND (>=5 km) — instrument adequate ────────────────────────────────────
di _newline "INLAND (>=5 km from Pacific):"
ivreg2 Dlhval (Dldens = O_e90_noK_5) if tc_hval==0 & coastal==0 ///
    [aw=owners90], robust first
di "psi (inland):"
nlcom (1/_b[Dldens])
