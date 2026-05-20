/* Interacted IV: test whether psi differs between core and fringe counties.
   Instead of splitting the sample (which kills the Bartik instrument), we
   interact both the endogenous regressor and the instrument with a fringe
   indicator, then recover group-specific psi from a single full-sample IV.

   Core   = LA (37) + Orange (59)
   Fringe = Riverside (65) + San Bernardino (71) + Ventura (111)

   Model:
     Dlhval = a + b_core*Dldens + b_fringe*(Dldens*fringe) + e
   Instruments: O_e90_noK_5, O_e90_noK_5 * fringe
   (just-identified: 2 endogenous regressors, 2 excluded instruments)

   psi_core  = 1 / b_core
   psi_fringe = 1 / (b_core + b_fringe)
   H0: psi_core == psi_fringe  <=>  b_fringe == 0  */

use "./output/powFEs", clear

gen fringe = (county_w == 65 | county_w == 71 | county_w == 111)

di "Estimation sample (tc_hval==0) by group:"
tab fringe if tc_hval==0

* Interaction terms
gen Dldens_fringe      = Dldens       * fringe
gen O_e90_noK_5_fringe = O_e90_noK_5 * fringe

* ── Main interacted IV ───────────────────────────────────────────────────────
di _newline "=== Interacted IV (full sample, both groups) ==="
ivreg2 Dlhval fringe (Dldens Dldens_fringe = O_e90_noK_5 O_e90_noK_5_fringe) ///
    if tc_hval==0 [aw=owners90], robust first

* Group-specific psi
di _newline "psi (core = LA + Orange):"
nlcom (1/_b[Dldens])

di _newline "psi (fringe = Riverside + SB + Ventura):"
nlcom (1/(_b[Dldens] + _b[Dldens_fringe]))

* Test b_fringe == 0: do the two groups have different psi?
di _newline "Test: H0 b_fringe==0 (equal psi across groups):"
test Dldens_fringe = 0

* ── Robustness: LA/Orange split within core ─────────────────────────────────
di _newline "=== Within-core check: LA vs Orange ==="
gen orange = (county_w == 59)
gen Dldens_orange      = Dldens       * orange
gen O_e90_noK_5_orange = O_e90_noK_5 * orange

ivreg2 Dlhval orange (Dldens Dldens_orange = O_e90_noK_5 O_e90_noK_5_orange) ///
    if tc_hval==0 & fringe==0 [aw=owners90], robust first

di _newline "psi (LA):"
nlcom (1/_b[Dldens])

di _newline "psi (Orange):"
nlcom (1/(_b[Dldens] + _b[Dldens_orange]))

test Dldens_orange = 0
