use 	"./output/flows_prepped_all.dta", clear

** FEs estimated via PPML, yr by yr **

ppmlhdfe wtflow5b tt_dyn if yr==0 & distance<100000, a(Theta_h_yrTemp=tr_h_yr Omega_w_yrTemp=tr_w_yr) vce(cluster pairid) acceleration(sd)

bys tr_w_yr: egen Omega_w_pmlyby_noT0 = mean(Omega_w_yrTemp)
bys tr_h_yr: egen Theta_h_pmlyby_noT0 = mean(Theta_h_yrTemp)

drop 	Omega_w_yrTemp Theta_h_yrTemp

ppmlhdfe wtflow5b tt_dyn if yr==1 & distance<100000, a(Theta_h_yrTemp=tr_h_yr Omega_w_yrTemp=tr_w_yr) vce(cluster pairid) acceleration(sd)

bys tr_w_yr: egen Omega_w_pmlyby_noT1 = mean(Omega_w_yrTemp)
bys tr_h_yr: egen Theta_h_pmlyby_noT1 = mean(Theta_h_yrTemp)

drop 	Omega_w_yrTemp Theta_h_yrTemp

gen 	Omega_w_pmlyby_noT=Omega_w_pmlyby_noT0 if yr==0
gen 	Theta_h_pmlyby_noT=Theta_h_pmlyby_noT0 if yr==0
replace Omega_w_pmlyby_noT=Omega_w_pmlyby_noT1 if yr==1
replace Theta_h_pmlyby_noT=Theta_h_pmlyby_noT1 if yr==1

drop 	Omega_w_pmlyby_noT0 Omega_w_pmlyby_noT1 Theta_h_pmlyby_noT0 Theta_h_pmlyby_noT1

** FEs estimated via PPML, all panel **

ppmlhdfe wtflow5b, a(Theta_h_yrTemp=tr_h_yr Omega_w_yrTemp=tr_w_yr pairid) vce(cluster pairid) 

bys tr_w_yr: egen Omega_w_pmlall_noT = mean(Omega_w_yrTemp)
bys tr_h_yr: egen Theta_h_pmlall_noT = mean(Theta_h_yrTemp)

drop 	Omega_w_yrTemp Theta_h_yrTemp

ppmlhdfe wtflow5b tt00_cc tt02_cc tt25_cc, a(Theta_h_yrTemp=tr_h_yr Omega_w_yrTemp=tr_w_yr pairid) vce(cluster pairid) 

bys tr_w_yr: egen Omega_w_pmlall_wT = mean(Omega_w_yrTemp)
bys tr_h_yr: egen Theta_h_pmlall_wT = mean(Theta_h_yrTemp)

drop 	Omega_w_yrTemp Theta_h_yrTemp

** Clean and prep to merge **

keep if OWN==1
keep 	pairid yr Omega_* Theta_*

tempfile FEs_ppml
save	"`FEs_ppml'", replace
clear

***********************************
** FEs estimated from log(flows) **

use 	"./output/flows_prepped_small.dta", clear

reghdfe lflowB, a(Theta_h_yrTemp=tr_h_yr Omega_w_yrTemp=tr_w_yr pairid) vce(cluster pairid) 

bys tr_w_yr: egen Omega_w_lin_noT = mean(Omega_w_yrTemp)
bys tr_h_yr: egen Theta_h_lin_noT = mean(Theta_h_yrTemp)

drop 	Omega_w_yrTemp Theta_h_yrTemp

reghdfe lflowB tt00_cc tt02_cc tt25_cc, a(Theta_h_yrTemp=tr_h_yr Omega_w_yrTemp=tr_w_yr pairid) vce(cluster pairid) 

bys tr_w_yr: egen Omega_w_lin_wT = mean(Omega_w_yrTemp)
bys tr_h_yr: egen Theta_h_lin_wT = mean(Theta_h_yrTemp)

drop 	Omega_w_yrTemp Theta_h_yrTemp

keep if OWN==1

** Combine all FEs

merge 1:1 pairid yr using "`FEs_ppml'"


drop _merge

corr Omega_* if yr==0
corr Omega_* if yr==1

preserve
	use "./output/intermediate/shocks_byindustry.dta", clear
	replace yr=0 if yr==1990
	replace yr=1 if yr==2000
	tempfile shocks
	save "`shocks'", replace
restore

merge 1:1 tract_w yr using "`shocks'"
drop 	_merge

**************
** Cleaning **

xtset 	tract_w yr

local vars Omega_w_lin_noT Omega_w_lin_wT Omega_w_pmlall_noT Omega_w_pmlall_wT Omega_w_pmlyby_noT Theta_h_lin_noT Theta_h_lin_wT Theta_h_pmlall_noT Theta_h_pmlall_wT Theta_h_pmlyby_noT 

foreach v of local vars {
	winsor2 `v' if OWN==1, cuts(1 99) suffix(_wnr)
	winsor2 `v' if OWN==1, cuts(1 99) suffix(_trm) trim

	gen 	D`v' = D.`v'
	winsor2 D`v' if OWN==1, cuts(1 99) suffix(_dwr)
	winsor2 D`v' if OWN==1, cuts(1 99) suffix(_dtr) trim
}

local agg Agg1_POW Agg2_POW Agg3_POW Agg4_POW Agg5_POW Agg1_RES Agg2_RES Agg3_RES Agg4_RES Agg5_RES

foreach v of local agg {
	gen 	D`v' = D.`v'
	winsor2 D`v' if OWN==1, cuts(1 99) suffix(_dwr)
	winsor2 D`v' if OWN==1, cuts(1 99) suffix(_dtr) trim
}

gen wpop90 = L.empPOW
gen tothh90 = L.tothh
gen owners90 = L.nhu_owner

save "./output/powFEs", replace
clear