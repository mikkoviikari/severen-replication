/* High vs. low 1990 housing density split.
   Density = owners90 / area_km2 (homeowners per km², predetermined in 1990).
   Median split on full tract sample; estimation restricted to tc_hval==0.

   Hypothesis: high-density tracts are already built-up → inelastic supply → low psi.
               low-density tracts have room to expand  → elastic supply   → high psi.  */

use "./output/powFEs", clear

* Merge tract area
preserve
    import delimited "./output/coastal_indicator.csv", clear varnames(1)
    rename tract_id tract_w
    keep tract_w area_km2 lon lat
    tempfile geo
    save `geo'
restore
merge m:1 tract_w using `geo', keep(master match) nogen

* 1990 housing density: homeowners per km²
gen dens90 = owners90 / area_km2

* Median split (full sample — density is a geographic characteristic)
sum dens90, detail
local med = r(p50)
gen high_dens90 = (dens90 >= `med') if !mi(dens90)

di "Median 1990 density: `med' owners/km²"
di "Estimation sample (tc_hval==0) by density group:"
tab high_dens90 if tc_hval==0

* ── HIGH density (>= median) — expect low psi ───────────────────────────────
di _newline "HIGH 1990 density (>= median, already built-up):"
ivreg2 Dlhval (Dldens = O_e90_noK_5) if tc_hval==0 & high_dens90==1 ///
    [aw=owners90], robust first
di "psi (high density):"
nlcom (1/_b[Dldens])

* ── LOW density (< median) — expect high psi ────────────────────────────────
di _newline "LOW 1990 density (< median, room to build):"
ivreg2 Dlhval (Dldens = O_e90_noK_5) if tc_hval==0 & high_dens90==0 ///
    [aw=owners90], robust first
di "psi (low density):"
nlcom (1/_b[Dldens])

* ── Quartile gradient ────────────────────────────────────────────────────────
di _newline "=== Quartile split (Q1 = least dense, Q4 = most dense) ==="
xtile dens90_q = dens90, nq(4)
forvalues q = 1/4 {
    di _newline "Quartile `q':"
    ivreg2 Dlhval (Dldens = O_e90_noK_5) if tc_hval==0 & dens90_q==`q' ///
        [aw=owners90], robust
    di "psi (Q`q'):"
    nlcom (1/_b[Dldens])
}
