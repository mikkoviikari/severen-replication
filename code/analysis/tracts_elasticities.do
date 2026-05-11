use 	"./output/powFEs", clear

gen one = 1

*==================================*
** Epsilon - Labor supply elast   **

*************************************	
/* Breusch-Pagan-type test for heteroskedasticity (expected because some tracts have very few workers) */
reg 	DOmega_w_pmlyby_noT_dtr Dlwage_dtr, robust
predict h_resids, r
gen 	h_resids2 = h_resids^2
gen		h_inverse = 1/wpop90

reg		h_resids2 h_inverse
reg		h_resids2 h_inverse, robust
drop 	h_resids h_resids2 h_inverse
**************************************

********************************
** Verify ivreg2 == ivreghdfe **
ivreg2 		DOmega_w_pmlyby_noT (Dlwage=M_w90) [aw=wpop90], robust
ivreghdfe 	DOmega_w_pmlyby_noT (Dlwage=M_w90) [aw=wpop90], a(one) robust
********************************


local tna table4a
local tnf table4f
capture erase ./tables/`tna'.csv
capture erase ./tables/`tnf'.csv


ivreghdfe 	DOmega_w_lin_noT (Dlwage=M_w90) [aw=wpop90], a(one) robust first
store_est_tpl using ./tables/`tna'.csv, coef(Dlwage) name(c1) all
local kpval = e(widstat)
insert_into_file using ./tables/`tnf'.csv, key(c1_kpval) value(`kpval') format(%5.1f)
ivreghdfe 	DOmega_w_lin_noT (Dlwage=M_w90) [aw=wpop90], a(one) first
local cdval = e(widstat)
insert_into_file using ./tables/`tnf'.csv, key(c1_cdval) value(`cdval') format(%5.1f)
gen			t_samp = ( e(sample)==1 )
reghdfe 	Dlwage M_w90 [aw=wpop90] if t_samp==1, a(one) vce(robust)
store_est_tpl using ./tables/`tnf'.csv, coef(M_w90) name(c1) all
drop 		t_samp

ivreghdfe 	DOmega_w_lin_noT (Dlwage=M_w90) [aw=wpop90], a(csubXyr_w) robust first
store_est_tpl using ./tables/`tna'.csv, coef(Dlwage) name(c2) all
local kpval = e(widstat)
insert_into_file using ./tables/`tnf'.csv, key(c2_kpval) value(`kpval') format(%5.1f)
ivreghdfe 	DOmega_w_lin_noT (Dlwage=M_w90) [aw=wpop90], a(csubXyr_w) first
local cdval = e(widstat)
insert_into_file using ./tables/`tnf'.csv, key(c2_cdval) value(`cdval') format(%5.1f)
gen			t_samp = ( e(sample)==1 )
reghdfe 	Dlwage M_w90 [aw=wpop90] if t_samp==1, a(csubXyr_w) vce(robust)
store_est_tpl using ./tables/`tnf'.csv, coef(M_w90) name(c2) all
drop 		t_samp


ivreghdfe 	DOmega_w_pmlyby_noT (Dlwage=M_w90) [aw=wpop90], a(one) robust first
store_est_tpl using ./tables/`tna'.csv, coef(Dlwage) name(c3) all
local kpval = e(widstat)
insert_into_file using ./tables/`tnf'.csv, key(c3_kpval) value(`kpval') format(%5.1f)
ivreghdfe 	DOmega_w_pmlyby_noT (Dlwage=M_w90) [aw=wpop90], a(one) first
local cdval = e(widstat)
insert_into_file using ./tables/`tnf'.csv, key(c3_cdval) value(`cdval') format(%5.1f)
gen			t_samp = ( e(sample)==1 )
reghdfe 	Dlwage M_w90 [aw=wpop90] if t_samp==1, a(one) vce(robust)
store_est_tpl using ./tables/`tnf'.csv, coef(M_w90) name(c3) all
drop 		t_samp

ivreghdfe 	DOmega_w_pmlyby_noT (Dlwage=M_w90) [aw=wpop90], a(csubXyr_w) robust first
store_est_tpl using ./tables/`tna'.csv, coef(Dlwage) name(c4) all
local kpval = e(widstat)
insert_into_file using ./tables/`tnf'.csv, key(c4_kpval) value(`kpval') format(%5.1f)
ivreghdfe 	DOmega_w_pmlyby_noT (Dlwage=M_w90) [aw=wpop90], a(csubXyr_w) first
local cdval = e(widstat)
insert_into_file using ./tables/`tnf'.csv, key(c4_cdval) value(`cdval') format(%5.1f)
gen			t_samp = ( e(sample)==1 )
reghdfe 	Dlwage M_w90 [aw=wpop90] if t_samp==1, a(csubXyr_w) vce(robust)
store_est_tpl using ./tables/`tnf'.csv, coef(M_w90) name(c4) all
drop 		t_samp


ivreghdfe 	DOmega_w_pmlall_noT (Dlwage=M_w90) [aw=wpop90], a(one) robust first
store_est_tpl using ./tables/`tna'.csv, coef(Dlwage) name(c5) all
local kpval = e(widstat)
insert_into_file using ./tables/`tnf'.csv, key(c5_kpval) value(`kpval') format(%5.1f)
ivreghdfe 	DOmega_w_pmlall_noT (Dlwage=M_w90) [aw=wpop90], a(one) first
local cdval = e(widstat)
insert_into_file using ./tables/`tnf'.csv, key(c5_cdval) value(`cdval') format(%5.1f)
gen			t_samp = ( e(sample)==1 )
reghdfe 	Dlwage M_w90 [aw=wpop90] if t_samp==1, a(one) vce(robust)
store_est_tpl using ./tables/`tnf'.csv, coef(M_w90) name(c5) all
drop 		t_samp

ivreghdfe 	DOmega_w_pmlall_noT (Dlwage=M_w90) [aw=wpop90], a(csubXyr_w) robust first
store_est_tpl using ./tables/`tna'.csv, coef(Dlwage) name(c6) all
local kpval = e(widstat)
insert_into_file using ./tables/`tnf'.csv, key(c6_kpval) value(`kpval') format(%5.1f)
ivreghdfe 	DOmega_w_pmlall_noT (Dlwage=M_w90) [aw=wpop90], a(csubXyr_w) first
local cdval = e(widstat)
insert_into_file using ./tables/`tnf'.csv, key(c6_cdval) value(`cdval') format(%5.1f)
gen			t_samp = ( e(sample)==1 )
reghdfe 	Dlwage M_w90 [aw=wpop90] if t_samp==1, a(csubXyr_w) vce(robust)
store_est_tpl using ./tables/`tnf'.csv, coef(M_w90) name(c6) all
drop 		t_samp


table_from_tpl, t(./tables/`tna'.tex) r(./tables/`tna'.csv) o(./tables/filled_`tna'.tex)
table_from_tpl, t(./tables/`tnf'.tex) r(./tables/`tnf'.csv) o(./tables/filled_`tnf'.tex)

est clear


** Additional Analysis: Which Sectors ok?

/*
ivreghdfe 	DOmega_w_pmlall_noT (Dlwage=M_w90) [aw=wpop90], a(one) robust 

preserve
	drop s_ind_02
	ivreghdfe 	DOmega_w_pmlall_noT (Dlwage=s_ind_??) [aw=wpop90], a(one) robust 
restore

preserve
	drop s_ind_09 s_ind_13 s_ind_18
	ivreghdfe 	DOmega_w_pmlall_noT (Dlwage=s_ind_??) [aw=wpop90], a(one) robust 
restore
	
preserve
	drop s_ind_02
	ivreghdfe 	DOmega_w_pmlall_noT (Dlwage=s_ind_??) [aw=wpop90], a(one) robust liml
	btsls, z(s_ind_??) x(Dlwage) y(DOmega_w_pmlall_noT) ktype("liml") weight_var(wpop90)
	return list
	local b_est = r(beta)
	return scalar b_est = `b_est'
	di `b_est'
	*return scalar b_bar_2sls_1 = `b_bar_2sls_1'
restore	
		
foreach n of numlist 3/9 {
preserve
	drop s_ind_02
	drop s_ind_0`n'
	qui ivreghdfe 	DOmega_w_pmlall_noT (Dlwage=s_ind_??) [aw=wpop90], a(one) robust 
	local hanj = e(jp)
	di `hanj'
restore 
}

foreach n of numlist 10/18 {
preserve
	drop s_ind_02
	drop s_ind_`n'
	qui ivreghdfe 	DOmega_w_pmlall_noT (Dlwage=s_ind_??) [aw=wpop90], a(one) robust 
	local hanj = e(jp)
	di `hanj'
restore 
} */

*************************************
** HOUSING Supply ELASTICITY (psi) ** 
*************************************
/* without saving
ivreg2 	Dlhval 			(Dldens = O_e90_5) 		if tc_hval==0 [aw=owners90], robust first
ivreg2 	Dlhval 			(Dldens = O_e90_noK_5) 	if tc_hval==0 [aw=owners90], robust first
ivreg2 	Dlhval 			Dllandr (Dlthc = O_e90_5)  		if tc_hval==0 [aw=owners90], robust first
ivreg2 	Dlhval 			Dllandr (Dlthc = O_e90_noK_5)  	if tc_hval==0 [aw=owners90], robust first
ivreg2 	Dlhval 			(Dlthc_dens = O_e90_5)  		if tc_hval==0 [aw=owners90], robust first
ivreg2 	Dlhval 			(Dlthc_dens = O_e90_noK_5)  	if tc_hval==0 [aw=owners90], robust first
*/

local tna table5a
local tnf table5f
capture erase ./tables/`tna'.csv
capture erase ./tables/`tnf'.csv

local r c1
ivreg2 	Dlhval 			(Dldens = O_e90_5) 		if tc_hval==0 [aw=owners90], robust first
gen		t_samp = ( e(sample)==1 )
local 	kpval = e(widstat)
store_est_tpl using ./tables/`tna'.csv, coef(Dldens) name(`r') all
insert_into_file using ./tables/`tnf'.csv, key(`r'_kpval) value(`kpval') format(%5.1f)
nlcom 	(1/_b[Dldens]), post
store_est_tpl using ./tables/`tna'.csv, coef(_nl_1) name(`r'_elast) all
reghdfe 	Dldens O_e90_5 if t_samp==1 & tc_hval==0 [aw=owners90], a(one) vce(robust)
store_est_tpl using ./tables/`tnf'.csv, coef(O_e90_5) name(`r') all
ivreg2 	Dlhval 			(Dldens = O_e90_5) 		if tc_hval==0 [aw=owners90], first
local 	cdval = e(widstat)
insert_into_file using ./tables/`tnf'.csv, key(`r'_cdval) value(`cdval') format(%5.1f)
drop 		t_samp

local r c2
ivreg2 	Dlhval 			(Dldens = O_e90_noK_5) 	if tc_hval==0 [aw=owners90], robust first
gen		t_samp = ( e(sample)==1 )
local 	kpval = e(widstat)
store_est_tpl using ./tables/`tna'.csv, coef(Dldens) name(`r') all
insert_into_file using ./tables/`tnf'.csv, key(`r'_kpval) value(`kpval') format(%5.1f)
nlcom 	(1/_b[Dldens]), post
store_est_tpl using ./tables/`tna'.csv, coef(_nl_1) name(`r'_elast) all
reghdfe 	Dldens O_e90_noK_5 if t_samp==1 & tc_hval==0 [aw=owners90], a(one) vce(robust)
store_est_tpl using ./tables/`tnf'.csv, coef(O_e90_noK_5) name(`r') all
ivreg2 	Dlhval 			(Dldens = O_e90_noK_5) 		if tc_hval==0 [aw=owners90], first
local 	cdval = e(widstat)
insert_into_file using ./tables/`tnf'.csv, key(`r'_cdval) value(`cdval') format(%5.1f)
drop 		t_samp


local r c3
ivreg2 	Dlhval 			Dllandr (Dlthc = O_e90_5)  		if tc_hval==0 [aw=owners90], robust first
gen		t_samp = ( e(sample)==1 )
local 	kpval = e(widstat)
store_est_tpl using ./tables/`tna'.csv, coef(Dlthc) name(`r'_hc) all
store_est_tpl using ./tables/`tna'.csv, coef(Dllandr) name(`r'_land) all
insert_into_file using ./tables/`tnf'.csv, key(`r'_kpval) value(`kpval') format(%5.1f)
nlcom 	(1/_b[Dlthc]) (_b[Dlthc]/_b[Dllandr]), post
store_est_tpl using ./tables/`tna'.csv, coef(_nl_1) name(`r'_elast) all
store_est_tpl using ./tables/`tna'.csv, coef(_nl_2) name(`r'_spectest) all
test _nl_2=-1
local pneg1 = r(p)
insert_into_file using ./tables/`tna'.csv, key(`r'_pneg1) value(`pneg1')
reghdfe 	Dlthc O_e90_5 if t_samp==1 & tc_hval==0 [aw=owners90], a(one) vce(robust)
store_est_tpl using ./tables/`tnf'.csv, coef(O_e90_5) name(`r') all
ivreg2 	Dlhval 			Dllandr (Dlthc = O_e90_5)		if tc_hval==0 [aw=owners90], first
local 	cdval = e(widstat)
insert_into_file using ./tables/`tnf'.csv, key(`r'_cdval) value(`cdval') format(%5.1f)
drop 		t_samp

local r c4
ivreg2 	Dlhval 			Dllandr (Dlthc = O_e90_noK_5)  	if tc_hval==0 [aw=owners90], robust first
gen		t_samp = ( e(sample)==1 )
local 	kpval = e(widstat)
store_est_tpl using ./tables/`tna'.csv, coef(Dlthc) name(`r'_hc) all
store_est_tpl using ./tables/`tna'.csv, coef(Dllandr) name(`r'_land) all
insert_into_file using ./tables/`tnf'.csv, key(`r'_kpval) value(`kpval') format(%5.1f)
nlcom 	(1/_b[Dlthc]) (_b[Dlthc]/_b[Dllandr]), post
store_est_tpl using ./tables/`tna'.csv, coef(_nl_1) name(`r'_elast) all
store_est_tpl using ./tables/`tna'.csv, coef(_nl_2) name(`r'_spectest) all
test _nl_2=-1
local pneg1 = r(p)
insert_into_file using ./tables/`tna'.csv, key(`r'_pneg1) value(`pneg1')
reghdfe 	Dlthc O_e90_noK_5 if t_samp==1 & tc_hval==0 [aw=owners90], a(one) vce(robust)
store_est_tpl using ./tables/`tnf'.csv, coef(O_e90_noK_5) name(`r') all
ivreg2 	Dlhval 			Dllandr (Dlthc = O_e90_noK_5)		if tc_hval==0 [aw=owners90], first
local 	cdval = e(widstat)
insert_into_file using ./tables/`tnf'.csv, key(`r'_cdval) value(`cdval') format(%5.1f)
drop 		t_samp


local r c5
ivreg2 	Dlhval 			(Dlthc_dens = O_e90_5)  		if tc_hval==0 [aw=owners90], robust first
gen		t_samp = ( e(sample)==1 )
local 	kpval = e(widstat)
store_est_tpl using ./tables/`tna'.csv, coef(Dlthc_dens) name(`r') all
insert_into_file using ./tables/`tnf'.csv, key(`r'_kpval) value(`kpval') format(%5.1f)
nlcom 	(1/_b[Dlthc_dens]), post
store_est_tpl using ./tables/`tna'.csv, coef(_nl_1) name(`r'_elast) all
reghdfe 	Dlthc_dens O_e90_5 if t_samp==1 & tc_hval==0 [aw=owners90], a(one) vce(robust)
store_est_tpl using ./tables/`tnf'.csv, coef(O_e90_5) name(`r') all
ivreg2 	Dlhval 			(Dlthc_dens = O_e90_5) 			if tc_hval==0 [aw=owners90], first
local 	cdval = e(widstat)
insert_into_file using ./tables/`tnf'.csv, key(`r'_cdval) value(`cdval') format(%5.1f)
drop 		t_samp

local r c6
ivreg2 	Dlhval 			(Dlthc_dens = O_e90_noK_5)  	if tc_hval==0 [aw=owners90], robust first
gen		t_samp = ( e(sample)==1 )
local 	kpval = e(widstat)
store_est_tpl using ./tables/`tna'.csv, coef(Dlthc_dens) name(`r') all
insert_into_file using ./tables/`tnf'.csv, key(`r'_kpval) value(`kpval') format(%5.1f)
nlcom 	(1/_b[Dlthc_dens]), post
store_est_tpl using ./tables/`tna'.csv, coef(_nl_1) name(`r'_elast) all
reghdfe 	Dlthc_dens O_e90_noK_5 if t_samp==1 & tc_hval==0 [aw=owners90], a(one) vce(robust)
store_est_tpl using ./tables/`tnf'.csv, coef(O_e90_noK_5) name(`r') all
ivreg2 	Dlhval 			(Dlthc_dens = O_e90_noK_5) 			if tc_hval==0 [aw=owners90], first
local 	cdval = e(widstat)
insert_into_file using ./tables/`tnf'.csv, key(`r'_cdval) value(`cdval') format(%5.1f)
drop 		t_samp

table_from_tpl, t(./tables/`tna'.tex) r(./tables/`tna'.csv) o(./tables/filled_`tna'.tex)
table_from_tpl, t(./tables/`tnf'.tex) r(./tables/`tnf'.csv) o(./tables/filled_`tnf'.tex)

/*
nlcom _b[Dlthc]/_b[Dllandr]
nlcom _b[Dlthc]/_b[Dllandr]+1
*/

** Differences over rho ** 

estimates clear

foreach n of numlist 1/8 {

	local val = -8.0 + `n'*0.5
	gen Dldens_`n'=Dldens
	la var  Dldens_`n' "`val'"
	eststo est_`n': ivreg2 	Dlhval 			(Dldens_`n' = O_e90_noK_`n') if tc_hval==0 [aw=owners90], robust
	
}

set scheme plotplainblind
coefplot est_*, mcolor(sky) msymbol(O) drop(_cons) vertical  yline(0, lcolor(black)) ///
	legend(off) ciopts(recast(rcap) color(sky)) ///
	xtitle("Value of ln({&rho})") ytitle("{&psi}", angle(180))

graph export	"./figures/psi_across_rho.png", replace

estimates clear

/*
** INCLUDING subcounty fixed effects doesn't work so well, likely muddles signals
ivreghdfe	Dlhval 			Dllandr (Dlthc = O_e90_5)  if tc_hval==0 [aw=owners90], a(csubXyr_h) robust
ivreghdfe 	Dlhval 			Dllandr (Dlthc = O_e90_noK_5)  if tc_hval==0 [aw=owners90], a(csubXyr_h) robust

reghdfe Dldens O_e90_5 if tc_hval==0 [aw=owners90], a(one) vce(robust) 
reghdfe Dldens O_e90_5 if tc_hval==0 [aw=owners90], a(csubXyr_h) vce(robust) // weak first stage
*/



*************************************************
** Housing Demand Elasticity (epsilon(1-zeta)) **
*************************************************


preserve
	use "./output/flows_prepped_small.dta", clear

	local te tablee1
	capture erase ./tables/`te'.csv
	
	local r c1
	ivreghdfe DlflowB 			(Dlhval_dtr=X_e90_5), a(tr_w_yr) robust
	gen		t_samp = ( e(sample)==1 )
	local 	kpval = e(widstat)
	store_est_tpl using ./tables/`te'.csv, coef(Dlhval_dtr) name(`r') all
	insert_into_file using ./tables/`te'.csv, key(`r'_kpval) value(`kpval') format(%5.1f)
	ivreghdfe DlflowB 			(Dlhval_dtr=X_e90_5), a(tr_w_yr)
	local 	cdval = e(widstat)
	insert_into_file using ./tables/`te'.csv, key(`r'_cdval) value(`cdval') format(%5.1f)
	reghdfe 	Dlhval_dtr X_e90_5 if t_samp==1, a(tr_w_yr) vce(robust)
	store_est_tpl using ./tables/`te'.csv, coef(X_e90_5) name(`r'_first) all
	drop 		t_samp

	local r c2
	ivreghdfe DlflowB Dtravtime	(Dlhval_dtr=X_e90_5), a(tr_w_yr) robust
	gen		t_samp = ( e(sample)==1 )
	local 	kpval = e(widstat)
	store_est_tpl using ./tables/`te'.csv, coef(Dlhval_dtr) name(`r') all
	insert_into_file using ./tables/`te'.csv, key(`r'_kpval) value(`kpval') format(%5.1f)
	ivreghdfe DlflowB Dtravtime (Dlhval_dtr=X_e90_5), a(tr_w_yr)
	local 	cdval = e(widstat)
	insert_into_file using ./tables/`te'.csv, key(`r'_cdval) value(`cdval') format(%5.1f)
	reghdfe 	Dlhval_dtr X_e90_5 Dtravtime if t_samp==1, a(tr_w_yr) vce(robust)
	store_est_tpl using ./tables/`te'.csv, coef(X_e90_5) name(`r'_first) all
	drop 		t_samp
	
	local r c3
	ivreghdfe DlflowB 			(Dlhval_dtr=X_e90_5) if OWN!=1, a(tr_w_yr) robust
	gen		t_samp = ( e(sample)==1 )
	local 	kpval = e(widstat)
	store_est_tpl using ./tables/`te'.csv, coef(Dlhval_dtr) name(`r') all
	insert_into_file using ./tables/`te'.csv, key(`r'_kpval) value(`kpval') format(%5.1f)
	ivreghdfe DlflowB 			(Dlhval_dtr=X_e90_5) if OWN!=1, a(tr_w_yr)
	local 	cdval = e(widstat)
	insert_into_file using ./tables/`te'.csv, key(`r'_cdval) value(`cdval') format(%5.1f)
	reghdfe 	Dlhval_dtr X_e90_5 if t_samp==1 & OWN!=1, a(tr_w_yr) vce(robust)
	store_est_tpl using ./tables/`te'.csv, coef(X_e90_5) name(`r'_first) all
	drop 		t_samp
	
	table_from_tpl, t(./tables/`te'.tex) r(./tables/`te'.csv) o(./tables/filled_`te'.tex)

restore

estimates clear
	
*************************************************
/* Structural work, estimating alpha */
*************************************************

gen 	Dlempdens = Dlemp_dtr-Dllandw_dtr

local te tablee2
capture erase ./tables/`te'.csv


local r c1
ivreg2 	Dlwage_dtr 					(Dlemp_dtr=F_w90_5), robust
gen		t_samp = ( e(sample)==1 )
local 	kpval = e(widstat)
store_est_tpl using ./tables/`te'.csv, coef(Dlemp_dtr) name(`r'_emp) all
insert_into_file using ./tables/`te'.csv, key(`r'_kpval) value(`kpval') format(%5.1f)
reghdfe Dlemp_dtr F_w90_5 if t_samp==1, a(one) vce(robust)
store_est_tpl using ./tables/`te'.csv, coef(F_w90_5) name(`r'_first) all
ivreg2 	Dlwage_dtr 					(Dlemp_dtr=F_w90_5)
local 	cdval = e(widstat)
insert_into_file using ./tables/`te'.csv, key(`r'_cdval) value(`cdval') format(%5.1f)
drop 		t_samp

local r c2
ivreg2 	Dlwage_dtr M_w90 			(Dlemp_dtr=F_w90_5), robust
gen		t_samp = ( e(sample)==1 )
local 	kpval = e(widstat)
store_est_tpl using ./tables/`te'.csv, coef(Dlemp_dtr) name(`r'_emp) all
insert_into_file using ./tables/`te'.csv, key(`r'_kpval) value(`kpval') format(%5.1f)
reghdfe Dlemp_dtr F_w90_5 M_w90  if t_samp==1, a(one) vce(robust)
store_est_tpl using ./tables/`te'.csv, coef(F_w90_5) name(`r'_first) all
ivreg2 	Dlwage_dtr M_w90			(Dlemp_dtr=F_w90_5)
local 	cdval = e(widstat)
insert_into_file using ./tables/`te'.csv, key(`r'_cdval) value(`cdval') format(%5.1f)
drop 		t_samp

local r c3
ivreg2 	Dlwage_dtr M_w90 Dllandw_dtr	(Dlemp_dtr=F_w90_5), robust
gen		t_samp = ( e(sample)==1 )
local 	kpval = e(widstat)
store_est_tpl using ./tables/`te'.csv, coef(Dlemp_dtr) name(`r'_emp) all
store_est_tpl using ./tables/`te'.csv, coef(Dllandw_dtr) name(`r'_land) all
insert_into_file using ./tables/`te'.csv, key(`r'_kpval) value(`kpval') format(%5.1f)
nlcom 	(_b[Dlemp_dtr]/_b[Dllandw_dtr]), post
store_est_tpl using ./tables/`te'.csv, coef(_nl_1) name(`r'_spectest) all
test _nl_1=-1
local pneg1 = r(p)
insert_into_file using ./tables/`te'.csv, key(`r'_pneg1) value(`pneg1')
reghdfe Dlemp_dtr F_w90_5 M_w90 Dllandw_dtr  if t_samp==1, a(one) vce(robust)
store_est_tpl using ./tables/`te'.csv, coef(F_w90_5) name(`r'_first) all
ivreg2 	Dlwage_dtr M_w90 Dllandw_dtr 	(Dlemp_dtr=F_w90_5)
local 	cdval = e(widstat)
insert_into_file using ./tables/`te'.csv, key(`r'_cdval) value(`cdval') format(%5.1f)
drop 		t_samp

local r c4
ivreg2 	Dlwage_dtr M_w90 	(Dlempdens=F_w90_5), robust
gen		t_samp = ( e(sample)==1 )
local 	kpval = e(widstat)
store_est_tpl using ./tables/`te'.csv, coef(Dlempdens) name(`r'_dens) all
insert_into_file using ./tables/`te'.csv, key(`r'_kpval) value(`kpval') format(%5.1f)
reghdfe Dlempdens F_w90_5 M_w90   if t_samp==1, a(one) vce(robust)
store_est_tpl using ./tables/`te'.csv, coef(F_w90_5) name(`r'_first) all
ivreg2 	Dlwage_dtr M_w90	(Dlempdens=F_w90_5)
local 	cdval = e(widstat)
insert_into_file using ./tables/`te'.csv, key(`r'_cdval) value(`cdval') format(%5.1f)
drop 		t_samp


table_from_tpl, t(./tables/`te'.tex) r(./tables/`te'.csv) o(./tables/filled_`te'.tex)

estimates clear

**************
/* File end */
**************

clear


