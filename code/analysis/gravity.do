use 	"./output/flows_prepped_small.dta", clear

do 		"./code/analysis/finalflowcleaning.do"

gen ltt = ln(tt_here)
gen ltt_obs = ln(travtime_all)

gen	speed_stln = (distance*60)/(travtime_all*1000) if travtime_all<99 & travtime_all>0 & distance<100000

local tn tablegrav
capture erase ./tables/`tn'.csv

** One Step
preserve 
	drop if speed_stln > (80/0.62137)
	
	reghdfe lflowB 	ltt_obs	tt00_cc tt02_cc tt25_cc			, a(tr_h_yr tr_w_yr) vce(cluster pairid tract_h tract_w) 		/* Col 1 */
	store_est_tpl using ./tables/`tn'.csv, coef(ltt_obs) name(ltt_1) all
	
	reghdfe lflowB 	ltt_obs	tt00_cc tt02_cc tt25_cc			, a(pairid tr_h_yr tr_w_yr) vce(cluster pairid tract_h tract_w)	/* Col 2 */
	store_est_tpl using ./tables/`tn'.csv, coef(ltt_obs) name(ltt_2) all
restore

reghdfe lflowB 	ltt	tt00_cc tt02_cc tt25_cc, a(tr_h_yr tr_w_yr) vce(cluster pairid tract_h tract_w)							/* Col 3 */
store_est_tpl using ./tables/`tn'.csv, coef(ltt) name(ltt_3) all

** Two Step 
reghdfe lflowB 	tt00_cc tt02_cc tt25_cc	, a(pairFE=pairid tr_h_yr tr_w_yr) vce(cluster pairid tract_h tract_w)

reghdfe pairFE ltt if yr==0, noa vce(cluster tract_h tract_w)																/* Col 5 */
store_est_tpl using ./tables/`tn'.csv, coef(ltt) name(ltt_4) all

preserve 
	drop if speed_stln > (80/0.62137)
	reghdfe pairFE ltt_obs i.yr, noa vce(cluster pairid tract_h tract_w)													/* Col 4 */
	store_est_tpl using ./tables/`tn'.csv, coef(ltt_obs) name(ltt_5) all
restore


use 	"./output/flows_prepped_all.dta", clear

gen ltt = ln(tt_here)
gen ltt_obs = ln(travtime_all)
gen	speed_stln = (distance*60)/(travtime_all*1000) if travtime_all<99 & travtime_all>0 & distance<100000

** Two Step 

ppmlhdfe wtflow5b tt00_cc tt02_cc tt25_cc, a(pairid tr_h_yr tr_w_yr, savefe) vce(cluster pairid) acceleration(sd)
gen		pairFE = __hdfe1__

reghdfe pairFE ltt if yr==0, noa vce(cluster tract_h tract_w)																/* Col 7 */
store_est_tpl using ./tables/`tn'.csv, coef(ltt) name(ltt_6) all

preserve 
	drop if speed_stln > (80/0.62137)
	reghdfe pairFE ltt_obs i.yr, noa vce(cluster pairid tract_h tract_w)													/* Col 6 */
	store_est_tpl using ./tables/`tn'.csv, coef(ltt_obs) name(ltt_7) all
restore

local tn tablegrav
table_from_tpl, t(./tables/`tn'.tex) r(./tables/`tn'.csv) o(./tables/filled_`tn'.tex)

