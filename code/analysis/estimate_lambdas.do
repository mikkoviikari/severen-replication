use 	"./output/powFEs", clear
drop if mi(pairid)
gen one = 1

****************************
/* Create Variables		  */
****************************

gen		dd_1km = max(1000-distance1999_h,0)/1000
replace dd_1km = 0 if yr==0

gen		dd_05km = max(500-distance1999_h,0)/500
replace dd_05km = 0 if yr==0

xtset 	pairid yr

gen 	Dlempdens = Dlemp-Dllandw

** Define Elasticities **
local 	eps 		= 2.180
local 	psi 		= 1.602
local	eps_zeta 	= -1*`eps'*(1-0.65)
display `eps_zeta'
local 	alpha 		= 0.64-1

** Recover Structural Residuals **
gen 	DE_hat 		= DOmega_w_pmlall_noT - `eps'*Dlwage

gen 	DC_hat 		= Dlhval - `psi'*Dlthc_dens

gen 	DB_hat 		= DTheta_h_pmlall_noT_dtr - `eps_zeta'*Dlhval_dtr
gen 	DB_hat_Agg		= DTheta_h_pmlall_noT_dtr - `eps_zeta'*Dlhval_dtr - 0.1553*DAgg3_RES_dtr
gen 	DB_hat_AggFar 	= DTheta_h_pmlall_noT_dtr - `eps_zeta'*Dlhval_dtr - 0.1553*DAgg1_RES_dtr

gen		DA_hat		= Dlwage - `alpha'*Dlempdens
gen		DA_hat_Agg		= Dlwage - `alpha'*Dlempdens - 0.0710*DAgg3_POW_dtr
gen		DA_hat_AggFar	= Dlwage - `alpha'*Dlempdens - 0.0710*DAgg1_POW_dtr

****************
** MAIN TERMS **
****************

/*
preserve 

local 	hwycont centHwy05_cc centHwy10_cc L.lhhi L.p_hsgr90 L.p_manu90
reghdfe	DB_hat dd_05km `hwycont' M_w90 M_e90 if OWN==1 & tc_hval==0, a(csubXyr_h) vce(robust) 
reghdfe	DB_hat_Agg dd_05km `hwycont' M_w90 M_e90 if OWN==1 & tc_hval==0, a(csubXyr_h) vce(robust) 


local 	hwycont centHwy05_cc centHwy10_cc L.lhhi L.p_hsgr90 L.p_manu90
reghdfe	DA_hat dd_05km `hwycont' if OWN==1,  a(csubXyr_h) vce(robust) 
reghdfe	DA_hat_Agg dd_05km `hwycont' if OWN==1, a(csubXyr_h) vce(robust) 

local 	hwycont centHwy05_cc centHwy10_cc L.lhhi L.p_hsgr90 L.p_manu90
reghdfe	DE_hat 	dd_05km `hwycont' if OWN==1, a(csubXyr_h) vce(robust) 

restore
*/

local tn table6a1
capture erase ./tables/`tn'.csv

local 	hwycont centHwy05_cc centHwy10_cc L.lhhi L.p_hsgr90 L.p_manu90

foreach tval in dd_05km dd_1km {
	reghdfe	DA_hat 	`tval' `hwycont' if OWN==1, a(csubXyr_h) vce(robust)     
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c1_`tval') all

	reghdfe	DA_hat 	`tval' `hwycont' if OWN==1 & PER10_tr_h==1, a(csubXyr_h) vce(robust) 
    store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c2_`tval') all
	
	reghdfe	DA_hat 	`tval' `hwycont' if OWN==1 & Sal10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c3_`tval') all
	
	reghdfe	DA_hat 	`tval' `hwycont' if OWN==1 & Sim10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c4_`tval') all
}

table_from_tpl, t(./tables/table6a.tex) r(./tables/`tn'.csv) o(./tables/filled_`tn'.tex)

local tn table6a2
capture erase ./tables/`tn'.csv

local 	hwycont centHwy05_cc centHwy10_cc L.lhhi L.p_hsgr90 L.p_manu90

foreach tval in dd_05km dd_1km {
	reghdfe	DA_hat_Agg 	`tval' `hwycont' if OWN==1, a(csubXyr_h) vce(robust)     
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c1_`tval') all

	reghdfe	DA_hat_Agg 	`tval' `hwycont' if OWN==1 & PER10_tr_h==1, a(csubXyr_h) vce(robust) 
    store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c2_`tval') all
	
	reghdfe	DA_hat_Agg 	`tval' `hwycont' if OWN==1 & Sal10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c3_`tval') all
	
	reghdfe	DA_hat_Agg 	`tval' `hwycont' if OWN==1 & Sim10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c4_`tval') all
}

table_from_tpl, t(./tables/table6a.tex) r(./tables/`tn'.csv) o(./tables/filled_`tn'.tex)

local tn table6b1
capture erase ./tables/`tn'.csv

local 	hwycont centHwy05_cc centHwy10_cc L.lhhi L.p_hsgr90 L.p_manu90

foreach tval in dd_05km dd_1km {
	reghdfe	DB_hat 	`tval' `hwycont' if OWN==1 & tc_hval==0, a(csubXyr_h) vce(robust)     
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c1_`tval') all

	reghdfe	DB_hat 	`tval' `hwycont' if OWN==1 & tc_hval==0 & PER10_tr_h==1, a(csubXyr_h) vce(robust) 
    store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c2_`tval') all
	
	reghdfe	DB_hat 	`tval' `hwycont' if OWN==1 & tc_hval==0 & Sal10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c3_`tval') all
	
	reghdfe	DB_hat 	`tval' `hwycont' if OWN==1 & tc_hval==0 & Sim10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c4_`tval') all
}

table_from_tpl, t(./tables/table6a.tex) r(./tables/`tn'.csv) o(./tables/filled_`tn'.tex)

local tn table6b2
capture erase ./tables/`tn'.csv

local 	hwycont centHwy05_cc centHwy10_cc L.lhhi L.p_hsgr90 L.p_manu90

foreach tval in dd_05km dd_1km {
	reghdfe	DB_hat_Agg 	`tval' `hwycont' if OWN==1 & tc_hval==0, a(csubXyr_h) vce(robust)     
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c1_`tval') all

	reghdfe	DB_hat_Agg 	`tval' `hwycont' if OWN==1 & tc_hval==0 & PER10_tr_h==1, a(csubXyr_h) vce(robust) 
    store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c2_`tval') all
	
	reghdfe	DB_hat_Agg 	`tval' `hwycont' if OWN==1 & tc_hval==0 & Sal10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c3_`tval') all
	
	reghdfe	DB_hat_Agg 	`tval' `hwycont' if OWN==1 & tc_hval==0 & Sim10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c4_`tval') all
}

table_from_tpl, t(./tables/table6b.tex) r(./tables/`tn'.csv) o(./tables/filled_`tn'.tex)


** Checking for Other Agglomeration Effects **

local tn tablef7a
capture erase ./tables/`tn'.csv

local 	hwycont centHwy05_cc centHwy10_cc L.lhhi L.p_hsgr90 L.p_manu90

foreach tval in dd_05km dd_1km {
	reghdfe	DA_hat_AggFar 	`tval' `hwycont' if OWN==1, a(csubXyr_h) vce(robust)     
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c1_`tval') all

	reghdfe	DA_hat_AggFar 	`tval' `hwycont' if OWN==1 & PER10_tr_h==1, a(csubXyr_h) vce(robust) 
    store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c2_`tval') all
	
	reghdfe	DA_hat_AggFar 	`tval' `hwycont' if OWN==1 & Sal10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c3_`tval') all
	
	reghdfe	DA_hat_AggFar 	`tval' `hwycont' if OWN==1 & Sim10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c4_`tval') all
}

table_from_tpl, t(./tables/table6a.tex) r(./tables/`tn'.csv) o(./tables/filled_`tn'.tex)

local tn tablef7b
capture erase ./tables/`tn'.csv

local 	hwycont centHwy05_cc centHwy10_cc L.lhhi L.p_hsgr90 L.p_manu90

foreach tval in dd_05km dd_1km {
	reghdfe	DB_hat_AggFar 	`tval' `hwycont' if OWN==1 & tc_hval==0, a(csubXyr_h) vce(robust)     
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c1_`tval') all

	reghdfe	DB_hat_AggFar 	`tval' `hwycont' if OWN==1 & tc_hval==0 & PER10_tr_h==1, a(csubXyr_h) vce(robust) 
    store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c2_`tval') all
	
	reghdfe	DB_hat_AggFar 	`tval' `hwycont' if OWN==1 & tc_hval==0 & Sal10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c3_`tval') all
	
	reghdfe	DB_hat_AggFar 	`tval' `hwycont' if OWN==1 & tc_hval==0 & Sim10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c4_`tval') all
}

table_from_tpl, t(./tables/table6b.tex) r(./tables/`tn'.csv) o(./tables/filled_`tn'.tex)


** Checking for Other Changes **

local tn tablef7c
capture erase ./tables/`tn'.csv

local 	hwycont centHwy05_cc centHwy10_cc L.lhhi L.p_hsgr90 L.p_manu90

foreach tval in dd_05km dd_1km {
	reghdfe	DC_hat 	`tval' `hwycont' if OWN==1 & tc_hval==0, a(csubXyr_h) vce(robust)     
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c1_`tval') all

	reghdfe	DC_hat 	`tval' `hwycont' if OWN==1 & tc_hval==0 & PER10_tr_h==1, a(csubXyr_h) vce(robust) 
    store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c2_`tval') all
	
	reghdfe	DC_hat 	`tval' `hwycont' if OWN==1 & tc_hval==0 & Sal10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c3_`tval') all
	
	reghdfe	DC_hat 	`tval' `hwycont' if OWN==1 & tc_hval==0 & Sim10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c4_`tval') all
}

table_from_tpl, t(./tables/table6a.tex) r(./tables/`tn'.csv) o(./tables/filled_`tn'.tex)


local tn tablef7e
capture erase ./tables/`tn'.csv

local 	hwycont centHwy05_cc centHwy10_cc L.lhhi L.p_hsgr90 L.p_manu90

foreach tval in dd_05km dd_1km {
	reghdfe	DE_hat 	`tval' `hwycont' if OWN==1, a(csubXyr_h) vce(robust)     
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c1_`tval') all

	reghdfe	DE_hat 	`tval' `hwycont' if OWN==1 & PER10_tr_h==1, a(csubXyr_h) vce(robust) 
    store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c2_`tval') all
	
	reghdfe	DE_hat 	`tval' `hwycont' if OWN==1 & Sal10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c3_`tval') all
	
	reghdfe	DE_hat 	`tval' `hwycont' if OWN==1 & Sim10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c4_`tval') all
}

table_from_tpl, t(./tables/table6b.tex) r(./tables/`tn'.csv) o(./tables/filled_`tn'.tex)



****************************
/* OTHER CHECKS */
****************************

** Land Use **
local tn tablef8a
capture erase ./tables/`tn'.csv

local 	hwycont centHwy05_cc centHwy10_cc L.lhhi L.p_hsgr90 L.p_manu90

foreach tval in dd_05km dd_1km {
	reghdfe	Dllandr_dtr 	`tval' `hwycont' if OWN==1, a(csubXyr_h) vce(robust)     
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c1_`tval') all

	reghdfe	Dllandr_dtr 	`tval' `hwycont' if OWN==1 & PER10_tr_h==1, a(csubXyr_h) vce(robust) 
    store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c2_`tval') all
	
	reghdfe	Dllandr_dtr 	`tval' `hwycont' if OWN==1 & Sal10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c3_`tval') all
	
	reghdfe	Dllandr_dtr 	`tval' `hwycont' if OWN==1 & Sim10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c4_`tval') all
}

table_from_tpl, t(./tables/table6a.tex) r(./tables/`tn'.csv) o(./tables/filled_`tn'.tex)

** HHI ** 
local tn tablef8b
capture erase ./tables/`tn'.csv

local 	hwycont centHwy05_cc centHwy10_cc L.lhhi L.p_hsgr90 L.p_manu90

foreach tval in dd_05km dd_1km {
	reghdfe	Dlhhi_dtr 	`tval' `hwycont' if OWN==1, a(csubXyr_h) vce(robust)     
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c1_`tval') all

	reghdfe	Dlhhi_dtr 	`tval' `hwycont' if OWN==1 & PER10_tr_h==1, a(csubXyr_h) vce(robust) 
    store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c2_`tval') all
	
	reghdfe	Dlhhi_dtr 	`tval' `hwycont' if OWN==1 & Sal10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c3_`tval') all
	
	reghdfe	Dlhhi_dtr 	`tval' `hwycont' if OWN==1 & Sim10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c4_`tval') all
}

table_from_tpl, t(./tables/table6b.tex) r(./tables/`tn'.csv) o(./tables/filled_`tn'.tex)

 
** Hedonics **

local 	hwycont centHwy05_cc centHwy10_cc L.lhhi L.p_hsgr90 L.p_manu90

foreach tval in dd_05km dd_1km {
	reghdfe	Dlhval_dtr 	`tval' `hwycont' if OWN==1 & tc_hval==0, a(csubXyr_h) vce(robust)     
	reghdfe	Dlhval_dtr 	`tval' `hwycont' if OWN==1 & tc_hval==0 & PER10_tr_h==1, a(csubXyr_h) vce(robust) 
	reghdfe	Dlhval_dtr 	`tval' `hwycont' if OWN==1 & tc_hval==0 & Sal10_tr_h==1, a(csubXyr_h) vce(robust)
	reghdfe	Dlhval_dtr 	`tval' `hwycont' if OWN==1 & tc_hval==0 & Sim10_tr_h==1, a(csubXyr_h) vce(robust)

}

** Commute Behavior **

merge 1:1 tract_h yr using "./output/intermediate/transitdetail_panel_restracts"
drop if _merge==2
drop	_merge

gen	 sh_drive = n_drive / totcomm
gen  sh_alltrans = n_alltran/totcomm
gen  sh_metro = n_metro/totcomm
gen  sh_metro_c = sh_metro
replace sh_metro_c = 0 if yr==0

xtset 	pairid yr

local tn tablef9
capture erase ./tables/`tn'.csv

local 	hwycont centHwy05_cc centHwy10_cc L.lhhi L.p_hsgr90 L.p_manu90

foreach tval in dd_05km dd_1km {
	reghdfe	D.sh_metro 	`tval' `hwycont' if OWN==1 & tc_hval==0, a(csubXyr_h) vce(robust)     
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c1_`tval') beta format(%5.4f)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c1_`tval') se format(%5.4f)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c1_`tval') n format(%5.0f)

	reghdfe	D.sh_metro 	`tval' `hwycont' if OWN==1 & tc_hval==0 & PER10_tr_h==1, a(csubXyr_h) vce(robust) 
    store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c2_`tval') beta format(%5.4f)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c2_`tval') se format(%5.4f)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c2_`tval') n format(%5.0f)

	reghdfe	D.sh_metro 	`tval' `hwycont' if OWN==1 & tc_hval==0 & Sal10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c3_`tval') beta format(%5.4f)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c3_`tval') se format(%5.4f)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c3_`tval') n format(%5.0f)

	reghdfe	D.sh_metro 	`tval' `hwycont' if OWN==1 & tc_hval==0 & Sim10_tr_h==1, a(csubXyr_h) vce(robust)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c4_`tval') beta format(%5.4f)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c4_`tval') se format(%5.4f)
	store_est_tpl using ./tables/`tn'.csv, coef(`tval') name(c4_`tval') n format(%5.0f)

}
table_from_tpl, t(./tables/table6b.tex) r(./tables/`tn'.csv) o(./tables/filled_`tn'.tex)



local 	hwycont centHwy05_cc centHwy10_cc L.lhhi L.p_hsgr90 L.p_manu90

foreach tval in dd_05km dd_1km {
	reghdfe	D.sh_drive 	`tval' `hwycont' if OWN==1 & tc_hval==0, a(csubXyr_h) vce(robust)     
	reghdfe	D.sh_drive 	`tval' `hwycont' if OWN==1 & tc_hval==0 & PER10_tr_h==1, a(csubXyr_h) vce(robust) 
	reghdfe	D.sh_drive 	`tval' `hwycont' if OWN==1 & tc_hval==0 & Sal10_tr_h==1, a(csubXyr_h) vce(robust)
	reghdfe	D.sh_drive 	`tval' `hwycont' if OWN==1 & tc_hval==0 & Sim10_tr_h==1, a(csubXyr_h) vce(robust)
}

local 	hwycont centHwy05_cc centHwy10_cc L.lhhi L.p_hsgr90 L.p_manu90

foreach tval in dd_05km dd_1km {
	reghdfe	D.sh_alltrans 	`tval' `hwycont' if OWN==1 & tc_hval==0, a(csubXyr_h) vce(robust)     
	reghdfe	D.sh_alltrans	`tval' `hwycont' if OWN==1 & tc_hval==0 & PER10_tr_h==1, a(csubXyr_h) vce(robust) 
	reghdfe	D.sh_alltrans	`tval' `hwycont' if OWN==1 & tc_hval==0 & Sal10_tr_h==1, a(csubXyr_h) vce(robust)
	reghdfe	D.sh_alltrans 	`tval' `hwycont' if OWN==1 & tc_hval==0 & Sim10_tr_h==1, a(csubXyr_h) vce(robust)
}