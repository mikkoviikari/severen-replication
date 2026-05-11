********************************************
** 1) Create all bootstrap replications ****

use		"./output/intermediate/bstractlist.dta", clear

** Set B = 410 so that we can throw out up to 10 epsilon/psi that are out of range **
set seed 9371
local	bnum = 410

** Using wild-bootstrap style Gamma-distributed weights and method in Menzel (2020)

foreach n of numlist 1/`bnum' {
	quietly gen bwt_pow_`n' = rgamma(4,0.5) - 2
}

foreach n of numlist 1/`bnum' {
	quietly gen bwt_res_`n' = rgamma(4,0.5) - 2
}

order 	bwt_pow_* bwt_res_*, seq
order 	tract, first

sort 	tract
quietly compress

save		"./output/intermediate/bsweights.dta", replace


*****************************************
** 2A) Bootstrap flow effects  **********

clear
capture erase "./output/intermediate/bs_flows_all.dta"
capture erase "./output/intermediate/bs_flows_sim.dta"
capture erase "./output/intermediate/bs_flows_per.dta"

save 	"./output/intermediate/bs_flows_all.dta", emptyok
save 	"./output/intermediate/bs_flows_sim.dta", emptyok
save 	"./output/intermediate/bs_flows_per.dta", emptyok

use 	"./output/flows_prepped_small.dta", clear
do 		"./code/analysis/finalflowcleaning.do"

keep 	tract_?  lflowB	tt00_cc tt02_cc tt25_cc centHwy05_cc centHwy10_cc pairid tr_h_yr tr_w_yr yr csbXcsbXyr Sim10_tr_lo_cc PER10_tr_lo_cc

reghdfe lflowB	tt00_cc tt02_cc tt25_cc `hwy', a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
gen  	s1 = e(sample)
reghdfe lflowB	tt00_cc tt02_cc tt25_cc `hwy' if Sim10_tr_lo_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
gen  	s2 = e(sample)
reghdfe lflowB	tt00_cc tt02_cc tt25_cc `hwy' if PER10_tr_lo_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
gen  	s3 = e(sample)

keep if s1==1 | s2==1 | s3==1

local dvars lflowB tt00_cc tt02_cc tt25_cc centHwy05_cc centHwy10_cc

foreach x of local dvars {
	gen D_`x' = D.`x'
}
	
foreach smp of numlist 1/3 {
	foreach x of local dvars {
		sum D_`x' if s`smp'==1
		local mean_s`smp'_`x' = r(mean)
	
		bys tract_h: egen s`smp'_D_h_`x' = mean(D_`x') if s`smp'==1
		bys tract_w: egen s`smp'_D_w_`x' = mean(D_`x') if s`smp'==1
	}

	foreach x of local dvars {
		gen s`smp'_DD_`x' = D_`x' - s`smp'_D_h_`x' - s`smp'_D_w_`x' + `mean_s`smp'_`x'' if s`smp'==1
	}
}

** INSERT CODE TO SAVE DD RESULTS

local tn tablediff2
capture erase ./tables/`tn'.csv

reghdfe s1_DD_lflowB	s1_DD_tt00_cc s1_DD_tt02_cc s1_DD_tt25_cc s1_DD_centHwy05_cc s1_DD_centHwy10_cc ///
			if s1==1, a(csbXcsbXyr, savefe) res(s1_DD_resid) vce(cluster tract_h tract_w)
predict s1_DD_xhatbeta, xbd
store_est_tpl using ./tables/`tn'.csv, coef(s1_DD_tt00_cc) name(c1_00) all
store_est_tpl using ./tables/`tn'.csv, coef(s1_DD_tt02_cc) name(c1_02) all
store_est_tpl using ./tables/`tn'.csv, coef(s1_DD_tt25_cc) name(c1_25) all

reghdfe s2_DD_lflowB	s2_DD_tt00_cc s2_DD_tt02_cc s2_DD_tt25_cc s2_DD_centHwy05_cc s2_DD_centHwy10_cc ///
			if s2==1, a(csbXcsbXyr, savefe) res(s2_DD_resid) vce(cluster tract_h tract_w)
predict s2_DD_xhatbeta, xbd	
store_est_tpl using ./tables/`tn'.csv, coef(s2_DD_tt00_cc) name(c3_00) all
store_est_tpl using ./tables/`tn'.csv, coef(s2_DD_tt02_cc) name(c3_02) all
store_est_tpl using ./tables/`tn'.csv, coef(s2_DD_tt25_cc) name(c3_25) all

reghdfe s3_DD_lflowB	s3_DD_tt00_cc s3_DD_tt02_cc s3_DD_tt25_cc s3_DD_centHwy05_cc s3_DD_centHwy10_cc ///
			if s3==1, a(csbXcsbXyr, savefe) res(s3_DD_resid) vce(cluster tract_h tract_w)
predict s3_DD_xhatbeta, xbd
store_est_tpl using ./tables/`tn'.csv, coef(s3_DD_tt00_cc) name(c2_00) all
store_est_tpl using ./tables/`tn'.csv, coef(s3_DD_tt02_cc) name(c2_02) all
store_est_tpl using ./tables/`tn'.csv, coef(s3_DD_tt25_cc) name(c2_25) all

table_from_tpl, t(./tables/`tn'.tex) r(./tables/`tn'.csv) o(./tables/filled_`tn'.tex)




drop __hdfe1__
keep if yr==1

rename 	tract_h tract
merge m:1 tract using "./output/intermediate/bsweights.dta", keepusing(bwt_res_*)
rename 	tract tract_h
drop 	_merge
	
rename 	tract_w tract
merge m:1 tract using "./output/intermediate/bsweights.dta", keepusing(bwt_pow_*)
rename	tract tract_w
drop 	_merge
	
foreach n of numlist 1/`bnum' {	
	gen 	bwt = bwt_res_`n'*bwt_pow_`n'
	
	gen 	yhat1 = s1_DD_xhatbeta + bwt*s1_DD_resid
	gen 	yhat2 = s2_DD_xhatbeta + bwt*s2_DD_resid
	gen 	yhat3 = s3_DD_xhatbeta + bwt*s3_DD_resid
	
	reghdfe yhat1	s1_DD_tt00_cc s1_DD_tt02_cc s1_DD_tt25_cc s1_DD_centHwy05_cc s1_DD_centHwy10_cc ///
					if s1==1, a(csbXcsbXyr) 
	regsave s1_DD_tt00_cc s1_DD_tt02_cc s1_DD_tt25_cc using "./output/intermediate/bs_flows_all.dta", append pval autoid
	
	reghdfe yhat2	s2_DD_tt00_cc s2_DD_tt02_cc s2_DD_tt25_cc s2_DD_centHwy05_cc s2_DD_centHwy10_cc ///
					if s2==1, a(csbXcsbXyr) 
	regsave s2_DD_tt00_cc s2_DD_tt02_cc s2_DD_tt25_cc using "./output/intermediate/bs_flows_sim.dta", append pval autoid
	
	reghdfe yhat3	s3_DD_tt00_cc s3_DD_tt02_cc s3_DD_tt25_cc s3_DD_centHwy05_cc s3_DD_centHwy10_cc ///
					if s3==1, a(csbXcsbXyr) 
	regsave s3_DD_tt00_cc s3_DD_tt02_cc s3_DD_tt25_cc using "./output/intermediate/bs_flows_per.dta", append pval autoid		
	
	drop bwt yhat?
}

clear


*****************************************
** 2B) Bootstrap elasticities  **********

clear
capture erase "./output/intermediate/bs_elast_eps.dta"
capture erase "./output/intermediate/bs_elast_psi.dta"

save 	"./output/intermediate/bs_elast_eps.dta", emptyok
save 	"./output/intermediate/bs_elast_psi.dta", emptyok

use 	"./output/powFEs", clear

drop 	tract_h
rename 	tract_w tract

keep 	tract DOmega_w_pmlall_noT Dlwage M_w90 wpop90 Dlhval Dlthc_dens O_e90_noK_5 csubXyr_w owners90 tc_hval

merge m:1 tract using "./output/intermediate/bsweights.dta", keepusing(bwt_*)
drop if _merge!=3 /*No associated data*/
drop 	_merge

gen one = 1

** Reminder of what the IV regressions are and adjustment factors
ivreghdfe DOmega_w_pmlall_noT (Dlwage=M_w90) [aw=wpop90], a(csubXyr_w)
gen		u1_factor_eps = sqrt(e(N) / e(df_r))
gen		u2_factor_eps = sqrt( e(N) / (e(df_r)-1) )
gen		eps = _b[Dlwage]
gen		s_eps = (e(sample)==1)

ivreghdfe Dlhval (Dlthc_dens = O_e90_noK_5) if tc_hval==0 [aw=owners90], a(one)
gen		u1_factor_psi = sqrt(e(N) / e(df_r))
gen		u2_factor_psi = sqrt( e(N) / (e(df_r)-1) )
gen		psi = _b[Dlthc_dens]
gen		s_psi = (e(sample)==1)

** Setup similar to the WRE bootstrap Davidson and ManKinnon (2010) but that ///
** uses the wild-bootstrap style Gamma-distributed weights in Menzel (2020)

gen		DOmega_eps_imposed = DOmega_w_pmlall_noT - eps*Dlwage
gen		Dlhval_psi_imposed = Dlhval - psi*Dlthc_dens

reghdfe DOmega_eps_imposed if s_eps==1 [aw=wpop90], a(csubXyr_w, savefe) resid(uhat1_eps)
predict xhat1_eps, xbd
drop 	__hdfe1__

reghdfe Dlwage M_w90 uhat1_eps if s_eps==1 [aw=wpop90], a(csubXyr_w, savefe) resid(tmp_uhat2prep)
predict tmp_xhat2_eps, xbd
gen		xhat2_eps = tmp_xhat2_eps - _b[uhat1_eps]*uhat1_eps
gen 	uhat2_eps = Dlwage - xhat2_eps
drop 	tmp_uhat2prep __hdfe1__

reghdfe Dlhval_psi_imposed if tc_hval==0 & s_psi==1 [aw=owners90], a(one, savefe) resid(uhat1_psi)
predict xhat1_psi, xbd
drop 	__hdfe1__

reghdfe Dlthc_dens O_e90_noK_5 uhat1_psi if tc_hval==0 & s_psi==1 [aw=owners90], a(one, savefe) resid(tmp_uhat2prep)
predict tmp_xhat2_psi, xbd
gen		xhat2_psi = tmp_xhat2_psi - _b[uhat1_psi]*uhat1_psi
gen 	uhat2_psi = Dlthc_dens - xhat2_psi
drop 	tmp_uhat2prep  __hdfe1__
    
local	bnum = 410
foreach n of numlist 1/`bnum' {
	
	gen 	y2hat_eps = xhat2_eps + u2_factor_eps*uhat2_eps*bwt_pow_`n'
	gen		y1hat_eps = eps*y2hat_eps + xhat1_eps + u1_factor_eps*uhat1_eps*bwt_pow_`n'

	gen 	y2hat_psi = xhat2_psi + u2_factor_psi*uhat2_psi*bwt_res_`n'
	gen		y1hat_psi = psi*y2hat_psi + xhat1_psi + u1_factor_psi*uhat1_psi*bwt_res_`n'
	
	ivreghdfe y1hat_eps (y2hat_eps=M_w90) if s_eps==1 [aw=wpop90], a(csubXyr_w) 
	regsave y2hat_eps using "./output/intermediate/bs_elast_eps.dta", append pval autoid /*Note pvalues meaningless*/
	
	ivreghdfe y1hat_psi (y2hat_psi=O_e90_noK_5) if tc_hval==0 & s_psi==1 [aw=owners90], a(one)
	regsave y2hat_psi using "./output/intermediate/bs_elast_psi.dta", append pval autoid /*Note pvalues meaningless*/	
	
	drop y?hat_* 
}

**************************
** 3) Cleaning  **********

tempfile eps psi

use 	"./output/intermediate/bs_elast_eps.dta", clear
keep 	coef _id
rename	coef eps
save	"`eps'", replace

use 	"./output/intermediate/bs_elast_psi.dta", clear
keep 	coef _id
rename	coef psi
save	"`psi'", replace

local 	flist all sim per

foreach f of local flist {
	use 	"./output/intermediate/bs_flows_`f'.dta", clear

	gen 	dist = 0 if strpos(var, "tt00_cc")>0
	replace dist = 2 if strpos(var, "tt02_cc")>0
	replace dist = 5 if strpos(var, "tt25_cc")>0
	keep 	dist coef _id

	reshape wide coef, i(_id) j(dist)
	merge 1:1 _id using "`eps'"
	drop	_merge
	merge 1:1 _id using "`psi'"
	drop	_merge
	save	"./output/bs_allparams_`f'", replace
}

