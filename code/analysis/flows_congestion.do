******************************************************
/* Congestion Analysis */
******************************************************

clear

use 	"./output/flows_prepped_small.dta"
do 		"./code/analysis/finalflowcleaning.do"

** MERGE **
drop 	O_* M_* F_* X_* Agg*

merge m:1 tract_h tract_w using "./output/routeproximity.dta"
drop if _merge==2
drop _merge

unab vlist: shline_*
foreach v of varlist `vlist' {
	replace `v' = `v' * yr
}

** Variable Prep **
gen 	shline_nearmetro_1000_250 = shline_nearmetro1000 - shline_nearmetro250
gen 	shline_nearmetro_2000_1000 = shline_nearmetro2000 - shline_nearmetro1000
gen 	shline_nearmetro_4000_2000 = shline_nearmetro4000 - shline_nearmetro2000

gen 	shline_nearhiwy_1000_250 = shline_nearhiwy1000 - shline_nearhiwy250

gen 	shline_nearmetro_500_250 = shline_nearmetro500 - shline_nearmetro250
gen 	shline_nearmetro_1000_500 = shline_nearmetro1000 - shline_nearmetro500

gen		len_nearmetro250 = length*shline_nearmetro250/1000
gen		len_nearmetro_1000_250 = length*shline_nearmetro_1000_250/1000
gen		len_nearmetro_2000_1000 = length*shline_nearmetro_2000_1000/1000
gen		len_nearmetro_4000_2000 = length*shline_nearmetro_4000_2000/1000

gen 	len_nearhiwy250 = length*shline_nearhiwy250/1000
gen 	len_nearhiwy_1000_250 = length*shline_nearhiwy_1000_250/1000

** Time prep and quality control **
gen tt_all = travtime_all
gen tt_dr = travtime_drivealone

gen	ltt_all = ln(tt_all)
gen	ltt_dr= ln(tt_dr)

gen	speed_stln = (distance*60)/(tt_all*1000) if tt_all<99 & tt_all>0 & distance<100000

gen 	mpm_all = (tt_all) / (length*0.000621371) if tt_all<99 & tt_all>0 & length<100000
gen 	mpm_dr 	= (tt_dr) / (length*0.000621371) if tt_all<99 & tt_all>0 & length<100000

gen 	lmpm_all = ln(mpm_all)
gen 	lmpm_dr = ln(mpm_dr)


*****************************************
** Output - Limit to reasonable speeds **

preserve
/* TABLE 3 */
drop if speed_stln > (80/0.62137) // Drop if over 80mph

local tn table3
capture erase ./tables/`tn'.csv
			
reghdfe ltt_all	shline_nearmetro250 shline_nearmetro_500_250 shline_nearmetro_1000_500 shline_nearmetro_2000_1000 shline_nearmetro_4000_2000 ///
				shline_nearhiwy250 shline_nearhiwy_1000_250 tt00_cc tt02_cc tt25_cc, ///
				a(pairid tr_h_yr tr_w_yr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(shline_nearmetro250) name(no_250_all) all
store_est_tpl using ./tables/`tn'.csv, coef(shline_nearmetro_500_250) name(no_500_all) all
store_est_tpl using ./tables/`tn'.csv, coef(shline_nearmetro_1000_500) name(no_1000_all) all
store_est_tpl using ./tables/`tn'.csv, coef(shline_nearmetro_2000_1000) name(no_2000_all) all
store_est_tpl using ./tables/`tn'.csv, coef(shline_nearmetro_4000_2000) name(no_4000_all) all

reghdfe ltt_all	shline_nearmetro250 shline_nearmetro_500_250 shline_nearmetro_1000_500 shline_nearmetro_2000_1000 shline_nearmetro_4000_2000 ///
				shline_nearhiwy250 shline_nearhiwy_1000_250 tt00_cc tt02_cc tt25_cc, ///
				a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(shline_nearmetro250) name(fe_250_all) all				
store_est_tpl using ./tables/`tn'.csv, coef(shline_nearmetro_500_250) name(fe_500_all) all
store_est_tpl using ./tables/`tn'.csv, coef(shline_nearmetro_1000_500) name(fe_1000_all) all
store_est_tpl using ./tables/`tn'.csv, coef(shline_nearmetro_2000_1000) name(fe_2000_all) all
store_est_tpl using ./tables/`tn'.csv, coef(shline_nearmetro_4000_2000) name(fe_4000_all) all
				
reghdfe ltt_dr	shline_nearmetro250 shline_nearmetro_500_250 shline_nearmetro_1000_500 shline_nearmetro_2000_1000 shline_nearmetro_4000_2000 ///
				shline_nearhiwy250 shline_nearhiwy_1000_250 tt00_cc tt02_cc tt25_cc, ///
				a(pairid tr_h_yr tr_w_yr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(shline_nearmetro250) name(no_250_dr) all				
store_est_tpl using ./tables/`tn'.csv, coef(shline_nearmetro_500_250) name(no_500_dr) all
store_est_tpl using ./tables/`tn'.csv, coef(shline_nearmetro_1000_500) name(no_1000_dr) all
store_est_tpl using ./tables/`tn'.csv, coef(shline_nearmetro_2000_1000) name(no_2000_dr) all
store_est_tpl using ./tables/`tn'.csv, coef(shline_nearmetro_4000_2000) name(no_4000_dr) all

reghdfe ltt_dr	shline_nearmetro250 shline_nearmetro_500_250 shline_nearmetro_1000_500 shline_nearmetro_2000_1000 shline_nearmetro_4000_2000 ///
				shline_nearhiwy250 shline_nearhiwy_1000_250 tt00_cc tt02_cc tt25_cc, ///
				a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(shline_nearmetro250) name(fe_250_dr) all				
store_est_tpl using ./tables/`tn'.csv, coef(shline_nearmetro_500_250) name(fe_500_dr) all
store_est_tpl using ./tables/`tn'.csv, coef(shline_nearmetro_1000_500) name(fe_1000_dr) all
store_est_tpl using ./tables/`tn'.csv, coef(shline_nearmetro_2000_1000) name(fe_2000_dr) all
store_est_tpl using ./tables/`tn'.csv, coef(shline_nearmetro_4000_2000) name(fe_4000_dr) all	


local tn table3	
table_from_tpl, t(./tables/`tn'.tex) r(./tables/`tn'.csv) o(./tables/filled_`tn'.tex)
	
estimates clear 
restore

** Robust to dropping not dropping such observations
					
reghdfe ltt_all	shline_nearmetro250 shline_nearmetro_500_250 shline_nearmetro_1000_500 shline_nearmetro_2000_1000 shline_nearmetro_4000_2000 ///
					shline_nearhiwy250 shline_nearhiwy_1000_250 tt00_cc tt02_cc tt25_cc, ///
					a(pairid tr_h_yr tr_w_yr) vce(cluster pairid tract_h tract_w)
reghdfe ltt_all	shline_nearmetro250 shline_nearmetro_500_250 shline_nearmetro_1000_500 shline_nearmetro_2000_1000 shline_nearmetro_4000_2000 ///
					shline_nearhiwy250 shline_nearhiwy_1000_250 tt00_cc tt02_cc tt25_cc, ///
					a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
reghdfe ltt_dr	shline_nearmetro250 shline_nearmetro_500_250 shline_nearmetro_1000_500 shline_nearmetro_2000_1000 shline_nearmetro_4000_2000 ///
					shline_nearhiwy250 shline_nearhiwy_1000_250 tt00_cc tt02_cc tt25_cc, ///
					a(pairid tr_h_yr tr_w_yr) vce(cluster pairid tract_h tract_w)
reghdfe ltt_dr	shline_nearmetro250 shline_nearmetro_500_250 shline_nearmetro_1000_500 shline_nearmetro_2000_1000 shline_nearmetro_4000_2000 ///
					shline_nearhiwy250 shline_nearhiwy_1000_250 tt00_cc tt02_cc tt25_cc, ///
					a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)








