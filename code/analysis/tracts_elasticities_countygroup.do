/* County-group housing supply elasticity (psi) split.
   Core    = Los Angeles (37) + Orange (59)     — dense, built-up, heavily zoned
   Fringe  = Riverside (65) + San Bernardino (71) + Ventura (111)
             — lower density, more developable land

   Both groups are large and industrially diverse, so the Bartik instrument
   should have adequate within-group variation (unlike the coastal and
   low-density splits where instrument strength collapsed).

   Preferred spec follows c2 from tracts_elasticities.do:
     ivreg2 Dlhval (Dldens = O_e90_noK_5) if tc_hval==0 [aw=owners90], robust first */

use "./output/powFEs", clear

* Define county groups (county_w = 3-digit numeric county FIPS)
gen core_county = (county_w == 37 | county_w == 59)    // LA + Orange

di "Estimation sample (tc_hval==0) by county group:"
di "  Core    = LA (37) + Orange (59)"
di "  Fringe  = Riverside (65) + San Bernardino (71) + Ventura (111)"
tab county_w if tc_hval==0
tab core_county if tc_hval==0

* ── CORE (LA + Orange) — expect low psi: built-up, restrictive zoning ─────────
di _newline "CORE (LA + Orange County):"
ivreg2 Dlhval (Dldens = O_e90_noK_5) if tc_hval==0 & core_county==1 ///
    [aw=owners90], robust first
di "psi (core):"
nlcom (1/_b[Dldens])

* ── FRINGE (Riverside + San Bernardino + Ventura) — expect high psi ───────────
di _newline "FRINGE (Riverside + San Bernardino + Ventura):"
ivreg2 Dlhval (Dldens = O_e90_noK_5) if tc_hval==0 & core_county==0 ///
    [aw=owners90], robust first
di "psi (fringe):"
nlcom (1/_b[Dldens])

* ── Individual counties — gradient check ──────────────────────────────────────
di _newline "=== Individual county estimates ==="
foreach c in 37 59 65 71 111 {
    di _newline "County `c':"
    ivreg2 Dlhval (Dldens = O_e90_noK_5) if tc_hval==0 & county_w==`c' ///
        [aw=owners90], robust
    di "psi (county `c'):"
    nlcom (1/_b[Dldens])
}
