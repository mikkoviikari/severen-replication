* Develop definitions for analysis

clear

**************************************************
/* Make primary outcome and treatment variables */
**************************************************

local 	dlist 	flows_wcovars_small flows_wcovars_all

foreach file of local dlist {

	use 	"./output/intermediate/`file'", clear

	rename	year yr

	replace yr = 0 if yr==1990
	replace yr = 1 if yr==2000

	sort 	pairid yr

	local odvec h w 

	foreach v of local odvec {

	/* Proximity to transit, h and w */

		gen		tran00_`v'	= ((distance1999_`v'==0 | cent_distance1999_`v'<500) & yr==1) 
		gen		tran02_`v'	= (distance1999_`v'<250 & yr==1)
		gen		tran05_`v'	= (distance1999_`v'<500 & yr==1)
		gen		tran10_`v'	= (distance1999_`v'<1000 & yr==1)

		gen 	ever_treated05_`v' = (distance1999_`v'<500)
		gen 	ever_treated10_`v' = (distance1999_`v'<1000)

		/* Make non-overlapping versions */

		gen		tt00_`v' = tran00_`v'

		gen		tt02_`v' = tran02_`v'
		replace tt02_`v' = 0 if tt00_`v'==1

		gen 	tt05_`v' = tran05_`v'
		replace tt05_`v' = 0 if tt00_`v'==1

		gen 	tt25_`v' = tran05_`v'
		replace tt25_`v' = 0 if tt00_`v'==1 | tt02_`v'==1

		gen 	tt10_`v' = tran10_`v'
		replace tt10_`v' = 0 if tt00_`v'==1 | tt02_`v'==1 | tt05_`v'==1

		/* Track Distance */

		gen		ever_track05_`v'	= (tracks_distance1999_`v'<500)
		gen		ever_track10_`v'	= (tracks_distance1999_`v'<1000)

		if ("`file'"=="flows_wcovars_small") {
			/* Proximity to controls, h and w */
			   
			gen 	SubplanImm05_`v' = (distance_lines1925immediate_`v'<500)  
			gen 	SubplanImm10_`v' = (distance_lines1925immediate_`v'<1000)

			gen 	Subplan05_`v' = (distance_lines1925all_`v'<500)   
			gen 	Subplan10_`v' = (distance_lines1925all_`v'<1000)

			gen 	PERplan05_`v' = (distance_linesper_`v'<500)  
			gen 	PERplan10_`v' = (distance_linesper_`v'<1000)


			/* Defining samples */
			local nvec		 05 10
			foreach n of local nvec {
				
				gen 	Sim`n'_st_`v' = (SubplanImm`n'_`v'==1 | ever_treated`n'_`v'==1)
				gen 	Sal`n'_st_`v' = (Subplan`n'_`v'==1 | ever_treated`n'_`v'==1)
				gen 	PER`n'_st_`v' = (PERplan`n'_`v'==1 | ever_treated`n'_`v'==1)

				gen 	Sim`n'_tr_`v' = (SubplanImm`n'_`v'==1 | ever_track`n'_`v'==1)
				gen 	Sal`n'_tr_`v' = (Subplan`n'_`v'==1 | ever_track`n'_`v'==1)
				gen 	PER`n'_tr_`v' = (PERplan`n'_`v'==1 | ever_track`n'_`v'==1)
				
				gen 	Sim`n'_st_`v'_ex = cond( (SubplanImm`n'_`v'==1) + (ever_treated`n'_`v'==1) == 1, 1, 0)
				gen 	Sal`n'_st_`v'_ex = cond( (Subplan`n'_`v'==1) + (ever_treated`n'_`v'==1) == 1, 1, 0)
				gen 	PER`n'_st_`v'_ex = cond( (PERplan`n'_`v'==1) + (ever_treated`n'_`v'==1) == 1, 1, 0)

				gen 	Sim`n'_tr_`v'_ex = cond( (SubplanImm`n'_`v'==1) + (ever_track`n'_`v'==1) == 1, 1, 0)
				gen 	Sal`n'_tr_`v'_ex = cond( (Subplan`n'_`v'==1) + (ever_track`n'_`v'==1) == 1, 1, 0)
				gen 	PER`n'_tr_`v'_ex = cond( (PERplan`n'_`v'==1) + (ever_track`n'_`v'==1) == 1, 1, 0)

			}
		}
	}

	bys yr: sum tran??_h tran??_w if OWN==1
	tab tran00_h tran02_h if OWN==1 & yr==1
	tab tran02_h tran05_h if OWN==1 & yr==1

	if ("`file'"=="flows_wcovars_small") {
		bys yr: sum Sim??_??_? Sim??_??_?_ex Sal??_??_? Sal??_??_?_ex PER??_??_? PER??_??_?_ex
	}

	/* Treatment Variables: Connections */

	gen		tran00_cc	= tran00_h * tran00_w
	gen		tran02_cc	= tran02_h * tran02_w
	gen		tran05_cc	= tran05_h * tran05_w
	gen		tran10_cc	= tran10_h * tran10_w

	bys yr: sum tran??_cc 

	*Make non-overlapping versions

	gen		tt00_cc = tran00_cc

	gen		tt02_cc = tran02_cc
	replace tt02_cc = 0 if tt00_cc==1

	gen 	tt05_cc = tran05_cc
	replace tt05_cc = 0 if tt00_cc==1

	gen 	tt25_cc = tran05_cc
	replace tt25_cc = 0 if tt00_cc==1 | tt02_cc==1

	gen 	tt10_cc = tran10_cc
	replace tt10_cc = 0 if tt00_cc==1 | tt02_cc==1 | tt05_cc==1

	tab tran00_cc tran02_cc if yr==1
	tab tran02_cc tran05_cc if yr==1

	tab tt00_cc tt02_cc if yr==1
	tab tt02_cc tt25_cc if yr==1

	/* Groups for Connections */
	if ("`file'"=="flows_wcovars_small") {
		local controlnet Sim Sal PER
		local tranORstat tr st
		local nvec		 05 10

		foreach ssp of local controlnet {
			foreach ts of local tranORstat {
				foreach n of local nvec {
					gen `ssp'`n'_`ts'_lo_cc = `ssp'`n'_`ts'_h * `ssp'`n'_`ts'_w
				}
			}
		}

		foreach ssp of local controlnet {
			foreach ts of local tranORstat {
				foreach n of local nvec {
					gen `ssp'`n'_`ts'_lo_cc_ex = `ssp'`n'_`ts'_h_ex * `ssp'`n'_`ts'_w_ex
				}
			}
		}

		foreach n of local nvec {
			gen Sim`n'_st_ti_cc = ((SubplanImm`n'_h==1 & SubplanImm`n'_w==1) | (ever_treated`n'_h==1 & ever_treated`n'_w==1))
			gen Sal`n'_st_ti_cc = ((Subplan`n'_h==1 & Subplan`n'_w==1) | (ever_treated`n'_h==1 & ever_treated`n'_w==1))
			gen PER`n'_st_ti_cc = ((PERplan`n'_h==1 & PERplan`n'_w==1) | (ever_treated`n'_h==1 & ever_treated`n'_w==1))
			
			gen Sim`n'_tr_ti_cc = ((SubplanImm`n'_h==1 & SubplanImm`n'_w==1) | (ever_track`n'_h==1 & ever_track`n'_w==1))
			gen Sal`n'_tr_ti_cc = ((Subplan`n'_h==1 & Subplan`n'_w==1) | (ever_track`n'_h==1 & ever_track`n'_w==1))
			gen PER`n'_tr_ti_cc = ((PERplan`n'_h==1 & PERplan`n'_w==1) | (ever_track`n'_h==1 & ever_track`n'_w==1))
		}

		foreach n of local nvec {
			gen 	Sim`n'_st_ti_cc_ex = Sim`n'_st_ti_cc
			replace Sim`n'_st_ti_cc_ex = 0 if ((SubplanImm`n'_h==1 | SubplanImm`n'_w==1) & (ever_treated`n'_h==1 | ever_treated`n'_w==1))==1
			gen 	Sal`n'_st_ti_cc_ex = Sal`n'_st_ti_cc
			replace Sal`n'_st_ti_cc_ex = 0 if ((Subplan`n'_h==1 | Subplan`n'_w==1) & (ever_treated`n'_h==1 | ever_treated`n'_w==1))==1
			gen 	PER`n'_st_ti_cc_ex = PER`n'_st_ti_cc
			replace PER`n'_st_ti_cc_ex = 0 if ((PERplan`n'_h==1 | PERplan`n'_w==1) & (ever_treated`n'_h==1 | ever_treated`n'_w==1))==1
			
			gen 	Sim`n'_tr_ti_cc_ex = Sim`n'_tr_ti_cc
			replace Sim`n'_tr_ti_cc_ex = 0 if ((SubplanImm`n'_h==1 | SubplanImm`n'_w==1) & (ever_track`n'_h==1 | ever_track`n'_w==1))==1
			gen 	Sal`n'_tr_ti_cc_ex = Sal`n'_tr_ti_cc
			replace Sal`n'_tr_ti_cc_ex = 0 if ((Subplan`n'_h==1 | Subplan`n'_w==1) & (ever_track`n'_h==1 | ever_track`n'_w==1))==1
			gen 	PER`n'_tr_ti_cc_ex = PER`n'_tr_ti_cc
			replace PER`n'_tr_ti_cc_ex = 0 if ((PERplan`n'_h==1 | PERplan`n'_w==1) & (ever_track`n'_h==1 | ever_track`n'_w==1))==1
		}

		bys yr: sum Sim??_??_??_cc Sim??_??_??_cc_ex Sal??_??_??_cc Sal??_??_??_cc_ex PER??_??_??_cc PER??_??_??_cc_ex

		drop 	SubplanImm??_? Subplan??_? PERplan??_? ever_treated??_? ever_track??_?
	}
	
	/* Codebook VVVdd_SS_o and VVVdd_SS_LL_cc
	VVV: Sim, Sal, PER, Control group is Subway Plan Immediate, Subway Plan All, or PER Lines
	dd: 05, 10, with 500 or 1000 meters
	SS: st, tr, treated are near stations or near tracks
	LL: lo, ti, loose network (all interactions) or tight networks (separate treated and control interactions)
	*/

	/* Covariates: I105 */

	gen 	centHwy05_h = 0
	gen 	centHwy10_h = 0
	gen 	centHwy15_h = 0

	replace centHwy05_h = 1 if distance_i105_h<500 & yr==1
	replace centHwy10_h = 1 if distance_i105_h<1000 & yr==1
	replace centHwy15_h = 1 if distance_i105_h<1500 & yr==1

	gen 	centHwy05_w = 0
	gen 	centHwy10_w = 0
	gen 	centHwy15_w = 0

	replace centHwy05_w = 1 if distance_i105_w<500 & yr==1
	replace centHwy10_w = 1 if distance_i105_w<1000 & yr==1
	replace centHwy15_w = 1 if distance_i105_w<1500 & yr==1

	gen		centHwy05_cc = centHwy05_h * centHwy05_w
	gen		centHwy10_cc = centHwy10_h * centHwy10_w
	gen		centHwy15_cc = centHwy15_h * centHwy15_w

	/* Additional utilities */

	egen 	tr_h_yr = group(tract_h yr)
	egen 	tr_w_yr = group(tract_w yr)

	xtset 	pairid yr

	sort 	pairid yr

	/* Defining useful variables in logs*/

	if ("`file'"=="flows_wcovars_small") {
		gen 	lemp 	= ln(empPOW)
		gen 	lres	= ln(empRES)
		gen 	lreshh	= ln(tothh)
		gen 	lwage	= ln(wagePOW)
		gen 	lwageave = ln(wagePOW_ave)
		gen 	lhval 	= ln(hval_50)
		gen		lhvalntc = ln(hval_nTC)
		gen 	lpopres	= ln(totpop)
		gen 	llandr	= ln(land_res_h)
		gen 	llandw 	= ln(land_prod_w)
		gen 	llandc 	= ln(land_consmptn_w)
		gen 	ldens	= ln(totpop/land_res_h)
		gen		lhhi	= ln(hhiRES)					
	}
	
	replace travtime_all = 99 if travtime_all>99 & travtime_all != .

	replace wtflow5a = 1000 if wtflow5a>1000 & wtflow5a!=.
	replace wtflow5b = 1000 if wtflow5b>1000 & wtflow5b!=.

	gen		lflowA 	= ln(wtflow5a)
	gen		lflowB 	= ln(wtflow5b)

	/* Subcounty by year fixed effects */

	egen 	csubXyr_h 	= group(cousub_h yr)
	egen 	csubXyr_w 	= group(cousub_w yr)
	egen 	csbXcsbXyr 	= group(csubXyr_h csubXyr_w)

	drop if csbXcsbXyr==. /* Islands */

	******************************
	/* Other useful variables */
	******************************

	xtset pairid yr

	gen DlflowB = D.lflowB
	gen Dtravtime = D.travtime_all

	if ("`file'"=="flows_wcovars_small") {
		*********************************************************
		/* Trimming ( _trm _dtr ) and winsorizing ( _wnr _dwr) */
		*********************************************************

		local 	housvars 	lhval lpopres lres lreshh ldens lhhi llandr
		local 	powvars 	lemp lwage llandw llandc

		/* In Levels */
		foreach v of local housvars {
			winsor2 `v' if OWN==1, cuts(1 99) suffix(_wnr_Tmp) by(yr)
			winsor2 `v' if OWN==1, cuts(1 99) suffix(_trm_Tmp) by(yr) trim
			bys tract_h yr: egen `v'_wnr = mean(`v'_wnr_Tmp)
			bys tract_h yr: egen `v'_trm = mean(`v'_trm_Tmp)
			replace `v'_wnr=. if `v'==. 
			replace `v'_trm=. if `v'==. 
		}

		foreach v of local powvars {
			winsor2 `v' if OWN==1, cuts(1 99) suffix(_wnr_Tmp) by(yr)
			winsor2 `v' if OWN==1, cuts(1 99) suffix(_trm_Tmp) by(yr) trim
			bys tract_w yr: egen `v'_wnr = mean(`v'_wnr_Tmp)
			bys tract_w yr: egen `v'_trm = mean(`v'_trm_Tmp)
			replace `v'_wnr=. if `v'==. 
			replace `v'_trm=. if `v'==. 
		}

		drop *_Tmp

		/* In Differences */

		xtset pairid yr

		foreach v of local housvars {
			gen 	D`v' = D.`v'
			winsor2 D`v' if OWN==1, cuts(1 99) suffix(_dwr_Tmp)
			winsor2 D`v' if OWN==1, cuts(1 99) suffix(_dtr_Tmp) trim
		}

		foreach v of local powvars {
			gen 	D`v' = D.`v'
			winsor2 D`v' if OWN==1, cuts(1 99) suffix(_dwr_Tmp)
			winsor2 D`v' if OWN==1, cuts(1 99) suffix(_dtr_Tmp) trim
		}

		foreach v of local housvars {
			bys tract_h yr: egen D`v'_dwr = mean(D`v'_dwr_Tmp)
			bys tract_h yr: egen D`v'_dtr = mean(D`v'_dtr_Tmp)
		}

		foreach v of local powvars {
			bys tract_w yr: egen D`v'_dwr = mean(D`v'_dwr_Tmp)
			bys tract_w yr: egen D`v'_dtr = mean(D`v'_dtr_Tmp)
		}

		drop *_Tmp

		******************************
		/* Housing value top code adjustment */
		******************************

		xtset pairid yr

		/* Housing prices in LA did not increase by national CPI change 1.67/1.27 */
		/* Use same top code on price, 500001 */

		gen 	Dlhval2 	= D.lhvalntc
		gen 	lhval50 	= L.hval_50
		gen		tc_dhval	= 0
		replace tc_dhval 	= 1 if Dlhval2==.
		replace tc_dhval 	= 1 if hval_50>=500001 & hval_50!=.
		replace tc_dhval 	= 1 if lhval50>=500001 & lhval50!=.

		gen 	tc_hval 	= 0
		replace tc_hval 	= 1 if hval_50>=500001 & hval_50!=.

		drop 	Dlhval2 lhval50

		******************************
		/* Total Housing Consumption */
		******************************

		gen Dlthc = Dlhhi_dtr + Dlpopres_dtr
		gen Dlthc_dens = Dlhhi_dtr + Dlpopres_dtr - Dllandr
	}
	
	******************************
	/* Any additional data prep */
	******************************

	compress

	xtset pairid yr

	if ("`file'"=="flows_wcovars_small") {
		save	"./output/flows_prepped_small.dta", replace
	}
	else if ("`file'"=="flows_wcovars_all") {
		save	"./output/flows_prepped_all.dta", replace
	}
	clear
}

use 	"./output/flows_prepped_small.dta", clear

merge 1:1 tract_h tract_w yr using "./output/intermediate/instruments_aggs.dta", keepus(M_* O_* X_* F_* Agg*)
drop	if _merge==2
drop	_merge

save, replace
