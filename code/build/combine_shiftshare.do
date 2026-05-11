* Merge shocks to trimmed sample and develop instruments 

clear

***********************************
/* Create Agglmoeration Measures */
***********************************

use 	"./output/intermediate/flows_wcovars_all.dta"

/* Use decay values of agglomeration as in ARSW (meters-scale) */
/* Vary at multiples of this value */
/* _noW is without self */

local i = 1
foreach val of numlist 0.5 0.75 1 1.25 1.5 {
	gen 	dwgt	= exp(tt_here * (-1*`val'*0.3617)) //

	bys tract_h year: egen AG_temp = total(dwgt * empPOW/((land_res_w + land_prod_w)/1000000))
	gen 	Agg`i'_POW 	= ln(AG_temp) if OWN==1
	drop 	AG_temp dwgt
	
	local i = `i' + 1
}

local i = 1
foreach val of numlist 0.5 0.75 1 1.25 1.5 {
	gen 	dwgt	= exp(tt_here * (-1*`val'*0.7595)) //
	
	bys tract_w year: egen AG_temp = total(dwgt * empRES/((land_res_h + land_prod_h)/1000000))
	gen 	Agg`i'_RES 	= ln(AG_temp) if OWN==1
	drop 	AG_temp dwgt
	
	local i = `i' + 1
}

rename 	year yr

keep if OWN==1
tempfile workplace_agg
save	"`workplace_agg'", replace


*************************************
/* Prep data for merge, then merge */
*************************************
use 	"./output/intermediate/flows_wcovars_small.dta"

order 	tract_w tract_h year pairid, first
rename 	year yr

merge 	m:1 tract_w yr using "./output/intermediate/shocks_all1990-2000.dta", keepusing(M_e90 M_w90)
drop if _merge!=3 & OWN!=1
drop 	_merge 
	
keep 	pairid tract_? yr tt_* M_e90 M_w90 OWN wtflow5a wtflow5b

*********************************
/* Create Instruments Measures */
*********************************

tempfile mainfile
save 	"`mainfile'", replace

drop if yr==2000

tempfile year0file
save 	"`year0file'", replace
clear

use 	"`mainfile'"
drop if yr==1990

** M_ are instruments for Labor Supply elasticity
** O_ are instruments for Housing Supply elasticity
** X_ are instruments for Housing Demand elasticity (not used anymore :( -- mean referees no likely)
** F_ are instruments for Labor Demand elasticity (not used anymore :( -- mean referees no likely)
** _noK excludes itself in the shift-share creation for O, X, F

/* Range goes from ln(rho)=-7.5 to ln(rho)=-3.5 in 9 increments */

local i = 1
local rangerho 0.000553 0.000912 0.001503 0.002479 0.004087 ///
				0.006738 0.011109 0.018316 0.0302 
				
foreach d of numlist `rangerho' {
	gen 	dwgt 		= exp(tt_here * (-1*`d'))

	gen 	O_temp 		= dwgt * M_w90
	bys tract_h yr: egen O_unwgt = total(O_temp)
	bys tract_h yr: egen O_norm  = total(dwgt)
	gen 	O_w90_`i' 	= O_unwgt/O_norm

	gen 	Oe_temp 	= dwgt * M_e90
	bys tract_h yr: egen Oe_unwgt = total(Oe_temp)
	gen 	O_e90_`i' 	= Oe_unwgt/O_norm
	
	replace O_temp 		= 0 if OWN==1
	gen 	dwgt_noK	= dwgt
	replace dwgt_noK 	= 0 if OWN==1
	bys tract_h yr: egen O_unwgt_noK = total(O_temp)
	bys tract_h yr: egen O_norm_noK  = total(dwgt_noK)
	gen 	O_w90_noK_`i' = O_unwgt_noK/O_norm_noK
	
	replace Oe_temp 	= 0 if OWN==1
	bys tract_h yr: egen Oe_unwgt_noK = total(Oe_temp)
	gen 	O_e90_noK_`i' = Oe_unwgt_noK/O_norm_noK
	
	gen 	X_temp 		= dwgt * M_w90
	bys tract_h yr: egen X_unwgt = total(X_temp)
	bys tract_h yr: egen X_norm  = total(dwgt)
	gen 	X_w90_`i' 	= (X_unwgt - dwgt*M_w90)/(X_norm - dwgt)

	gen 	Xe_temp 	= dwgt * M_e90
	bys tract_h yr: egen Xe_unwgt = total(Xe_temp)
	gen 	X_e90_`i' 	= (Xe_unwgt - dwgt*M_e90)/(X_norm - dwgt)
	
	gen 	F_temp 		= dwgt * O_w90_noK_`i'
	bys tract_w yr: egen F_unwgt = total(F_temp)
	bys tract_w yr: egen F_norm  = total(dwgt)
	gen 	F_w90_`i' 	= F_unwgt/F_norm
	
	gen 	Fe_temp 	= dwgt * O_e90_noK_`i'
	bys tract_w yr: egen Fe_unwgt = total(Fe_temp)
	gen 	F_e90_`i' 	= Fe_unwgt/F_norm

	drop dwgt O_temp O_unwgt O_norm Oe_temp Oe_unwgt dwgt_noK O_unwgt_noK  ///
		O_norm_noK Oe_unwgt_noK X_temp X_unwgt X_norm Xe_temp Xe_unwgt ///
		F_temp Fe_temp F_unwgt Fe_unwgt F_norm	
		
	local i = `i' + 1
}

append 	using "`year0file'"

foreach v of numlist 1/9 {
	replace O_w90_`v' 	= 0 if yr==1990
	replace O_e90_`v'	= 0 if yr==1990
	replace O_w90_noK_`v' = 0 if yr==1990
	replace O_e90_noK_`v' = 0 if yr==1990
	replace X_w90_`v' 	= 0 if yr==1990 
	replace X_e90_`v' 	= 0 if yr==1990 
	replace F_w90_`v' 	= 0 if yr==1990 
	replace F_e90_`v' 	= 0 if yr==1990
}

sum M_w90 M_e90 if yr==2000, d

sum O_w90_? if yr==2000 & OWN==1, d
sum O_e90_? if yr==2000 & OWN==1, d

sum O_w90_noK_? if yr==2000 & OWN==1, d
sum O_e90_noK_? if yr==2000 & OWN==1, d

sum X_w90_? if yr==2000, d
sum X_e90_? if yr==2000, d

sum F_w90_? if yr==2000, d
sum F_e90_? if yr==2000, d

merge m:1 tract_w yr using "`workplace_agg'", keepus(Agg*)
drop	_merge

replace yr = 0 if yr==1990
replace yr = 1 if yr==2000

compress

save "./output/intermediate/instruments_aggs.dta", replace
clear