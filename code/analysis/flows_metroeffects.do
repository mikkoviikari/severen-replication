* Analysis 

clear

use 	"./output/flows_prepped_small.dta"

do 		"./code/analysis/finalflowcleaning.do"

/* Codebook for sample groups:
VVVdd_SS_h (w) and VVVdd_SS_LL_cc
	VVV: Sim, Sal, PER, Control group is Subway Plan Immediate, Subway Plan All, or PER Lines
	dd: 05, 10, with 500 or 1000 meters
	SS: st, tr, treated are near stations or near tracks
	LL: lo, ti, loose network (all interactions) or tight networks (separate treated and control interactions)
	
	_st_lo_ and _tr_lo_ not too different
	_st_ti_ looses power
*/

************************
/* Summary Statistics (Table 1, part of Panel A)*/
************************

sum 	wtflow5a if yr==0 & LA==1 [aw=wtflow5a]
local 	wsuml = r(sum_w)
* Total is 746167 workers (x5 to get employed population)

sum 	wtflow5a if yr==0 & fut_tran00_h==1 & LA==1 [aw=wtflow5a]
local	ct_00l_h = r(sum_w)/`wsuml'
sum 	wtflow5a if yr==0 & fut_tran00_w==1 & LA==1 [aw=wtflow5a]
local	ct_00l_w = r(sum_w)/`wsuml'
sum 	wtflow5a if yr==0 & fut_tran00_cc & LA==1 [aw=wtflow5a]
local	ct_00l_cc = r(sum_w)/`wsuml'

sum 	wtflow5a if yr==0 & fut_tran05_h==1 & LA==1 [aw=wtflow5a]
local	sh_05l_h = r(sum_w)/`wsuml'
sum 	wtflow5a if yr==0 & fut_tran05_w==1 & LA==1 [aw=wtflow5a]
local	sh_05l_w = r(sum_w)/`wsuml'
sum 	wtflow5a if yr==0 & fut_tran05_cc==1 & LA==1 [aw=wtflow5a]
local	sh_05l_cc = r(sum_w)/`wsuml'

display `ct_00l_h'
display `ct_00l_w'
display `ct_00l_cc'

display `sh_05l_h'
display `sh_05l_w'
display `sh_05l_cc'


sum 	wtflow5a if yr==0 [aw=wtflow5a]
local 	wsum = r(sum_w)
* Total is 1301079 workers (x5 to get employed population)

sum 	wtflow5a if yr==0 & fut_tran00_h==1 [aw=wtflow5a]
local	ct_00_h = r(sum_w)/`wsum'
sum 	wtflow5a if yr==0 & fut_tran00_w==1 [aw=wtflow5a]
local	ct_00_w = r(sum_w)/`wsum'
sum 	wtflow5a if yr==0 & fut_tran00_cc==1 [aw=wtflow5a]
local	ct_00_cc = r(sum_w)/`wsum'

sum 	wtflow5a if yr==0 & fut_tran05_h==1 [aw=wtflow5a]
local	sh_05_h = r(sum_w)/`wsum'
sum 	wtflow5a if yr==0 & fut_tran05_w==1 [aw=wtflow5a]
local	sh_05_w = r(sum_w)/`wsum'
sum 	wtflow5a if yr==0 & fut_tran05_cc==1 [aw=wtflow5a]
local	sh_05_cc = r(sum_w)/`wsum'

display `ct_00_h'
display `ct_00_w'
display `ct_00_cc'

display `sh_05_h'
display `sh_05_w'
display `sh_05_cc'


******************************************************
/* 0. Sandbox 									    */
******************************************************


******************************************************
/* 1. Reduced form work, estimating effect on flows */
******************************************************

estimates clear 

****************************
/* TABLE 2 */

local tn table2
capture erase ./tables/`tn'.csv

local hwy centHwy05_cc centHwy10_cc

reghdfe lflowB 	tt00_cc							, a(pairid tr_h_yr tr_w_yr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c1_00) all

reghdfe lflowB 	tt00_cc tt02_cc tt25_cc			, a(pairid tr_h_yr tr_w_yr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c2_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c2_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c2_25) all

reghdfe lflowB	tt00_cc tt02_cc tt25_cc `hwy'	, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c3_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c3_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c3_25) all

reghdfe lflowB	tt00_cc tt02_cc tt25_cc `hwy'	if PER10_tr_lo_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c4_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c4_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c4_25) all

reghdfe lflowB	tt00_cc tt02_cc tt25_cc `hwy'	if Sal10_tr_lo_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c5_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c5_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c5_25) all

reghdfe lflowB	tt00_cc tt02_cc tt25_cc `hwy'	if Sim10_tr_lo_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c6_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c6_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c6_25) all

reghdfe lflowB	tt??_cc_same `hwy'	if evertreated05_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c7_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c7_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c7_25) all

reghdfe lflowB	tt??_cc_same `hwy'	if tranccsample==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c8_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c8_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c8_25) all


table_from_tpl, t(./tables/`tn'.tex) r(./tables/`tn'.csv) o(./tables/filled_`tn'.tex)


****************************
/* TABLE 2 PPML */
local tn table2ppml
capture erase ./tables/`tn'.csv

local hwy centHwy05_cc centHwy10_cc

ppmlhdfe wtflow5b 	tt00_cc							, a(pairid tr_h_yr tr_w_yr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c1_00) all

ppmlhdfe wtflow5b 	tt00_cc tt02_cc tt25_cc			, a(pairid tr_h_yr tr_w_yr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c2_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c2_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c2_25) all

ppmlhdfe wtflow5b	tt00_cc tt02_cc tt25_cc `hwy'	, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c3_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c3_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c3_25) all

ppmlhdfe wtflow5b	tt00_cc tt02_cc tt25_cc `hwy'	if PER10_tr_lo_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c4_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c4_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c4_25) all

ppmlhdfe wtflow5b	tt00_cc tt02_cc tt25_cc `hwy'	if Sal10_tr_lo_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c5_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c5_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c5_25) all

ppmlhdfe wtflow5b	tt00_cc tt02_cc tt25_cc `hwy'	if Sim10_tr_lo_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c6_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c6_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c6_25) all

ppmlhdfe wtflow5b	tt??_cc_same `hwy'	if evertreated05_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c7_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c7_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c7_25) all

ppmlhdfe wtflow5b	tt??_cc_same `hwy'	if tranccsample==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c8_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c8_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c8_25) all

table_from_tpl, t(./tables/table2.tex) r(./tables/`tn'.csv) o(./tables/filled_`tn'.tex)

estimates clear

************************
** Specification Tests **

** Define variables
gen 	years_open = 0
replace years_open = 2000 - max(yropen_nearest1999_h, yropen_nearest1999_w) if tran05_cc==1
replace years_open = . if yropen_nearest1999_h==. | yropen_nearest1999_w==.

gen		years_open_cen = years_open - 5

gen 	flowzero = 0
replace flowzero = 1 if lflowB!=.

/* Does treatment predict 0s? */ /* Length of time open */

local tn tablef2
capture erase ./tables/`tn'.csv

local hwy centHwy05_cc centHwy10_cc

reghdfe flowzero tt00_cc tt02_cc tt25_cc, a(tr_h_yr tr_w_yr pairid) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c1_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c1_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c1_25) all

reghdfe flowzero tt00_cc tt02_cc tt25_cc `hwy', a(tr_h_yr tr_w_yr pairid csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c2_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c2_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c2_25) all

reghdfe flowzero tt00_cc tt02_cc tt25_cc `hwy' if Sim10_tr_lo_cc==1, a(tr_h_yr tr_w_yr pairid csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c3_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c3_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c3_25) all

reghdfe lflowB 	tt00_cc	tt02_cc tt25_cc years_open, a(tr_h_yr tr_w_yr pairid) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c4_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c4_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c4_25) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c4_yr) all

reghdfe lflowB 	tt00_cc	tt02_cc tt25_cc years_open `hwy', a(tr_h_yr tr_w_yr pairid csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c5_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c5_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c5_25) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c5_yr) all

reghdfe lflowB 	tt00_cc tt02_cc tt25_cc 1.tt00_cc#c.years_open_cen 1.tt02_cc#c.years_open_cen 1.tt25_cc#c.years_open_cen `hwy', a(tr_h_yr tr_w_yr pairid csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c6_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c6_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c6_25) all
store_est_tpl using ./tables/`tn'.csv, coef(1.tt00_cc#c.years_open_cen) name(c6_yr00) all
store_est_tpl using ./tables/`tn'.csv, coef(1.tt02_cc#c.years_open_cen) name(c6_yr02) all
store_est_tpl using ./tables/`tn'.csv, coef(1.tt25_cc#c.years_open_cen) name(c6_yr25) all

reghdfe lflowB 	tt00_cc	tt02_cc tt25_cc years_open `hwy' if Sim10_tr_lo_cc==1, a(tr_h_yr tr_w_yr pairid csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c7_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c7_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c7_25) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c7_yr) all

reghdfe lflowB 	tt00_cc tt02_cc tt25_cc 1.tt00_cc#c.years_open_cen 1.tt02_cc#c.years_open_cen 1.tt25_cc#c.years_open_cen `hwy' if Sim10_tr_lo_cc==1, a(tr_h_yr tr_w_yr pairid csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c8_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c8_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c8_25) all
store_est_tpl using ./tables/`tn'.csv, coef(1.tt00_cc#c.years_open_cen) name(c8_yr00) all
store_est_tpl using ./tables/`tn'.csv, coef(1.tt02_cc#c.years_open_cen) name(c8_yr02) all
store_est_tpl using ./tables/`tn'.csv, coef(1.tt25_cc#c.years_open_cen) name(c8_yr25) all


table_from_tpl, t(./tables/`tn'.tex) r(./tables/`tn'.csv) o(./tables/filled_`tn'.tex)

****************************
** SAME LINE

local tn tablef4
capture erase ./tables/`tn'.csv

local hwy centHwy05_cc centHwy10_cc

reghdfe lflowB 	tt00_cc_same tt00_cc_nots, a(tr_h_yr tr_w_yr pairid) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc_same) name(c1_00s) all
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc_nots) name(c1_00n) all

reghdfe lflowB 	tt??_cc_same tt??_cc_nots, a(tr_h_yr tr_w_yr pairid) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc_same) name(c2_00s) all
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc_nots) name(c2_00n) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc_same) name(c2_02s) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc_nots) name(c2_02n) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc_same) name(c2_25s) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc_nots) name(c2_25n) all

reghdfe lflowB 	tt??_cc_same tt??_cc_nots `hwy', a(tr_h_yr tr_w_yr pairid csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc_same) name(c3_00s) all
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc_nots) name(c3_00n) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc_same) name(c3_02s) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc_nots) name(c3_02n) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc_same) name(c3_25s) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc_nots) name(c3_25n) all

reghdfe lflowB 	tt??_cc_same tt??_cc_nots `hwy' if PER10_tr_lo_cc==1, a(tr_h_yr tr_w_yr pairid csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc_same) name(c4_00s) all
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc_nots) name(c4_00n) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc_same) name(c4_02s) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc_nots) name(c4_02n) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc_same) name(c4_25s) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc_nots) name(c4_25n) all

reghdfe lflowB 	tt??_cc_same tt??_cc_nots `hwy' if Sal10_tr_lo_cc==1, a(tr_h_yr tr_w_yr pairid csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc_same) name(c5_00s) all
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc_nots) name(c5_00n) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc_same) name(c5_02s) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc_nots) name(c5_02n) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc_same) name(c5_25s) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc_nots) name(c5_25n) all

reghdfe lflowB 	tt??_cc_same tt??_cc_nots `hwy' if Sim10_tr_lo_cc==1, a(tr_h_yr tr_w_yr pairid csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc_same) name(c6_00s) all
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc_nots) name(c6_00n) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc_same) name(c6_02s) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc_nots) name(c6_02n) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc_same) name(c6_25s) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc_nots) name(c6_25n) all


table_from_tpl, t(./tables/`tn'.tex) r(./tables/`tn'.csv) o(./tables/filled_`tn'.tex)

		
estimates clear

****************************
** Bin-by-Bin

tab ttbin_h ttbin_w

local tn tablef5
capture erase ./tables/`tn'.csv

local hwy centHwy05_cc centHwy10_cc

reghdfe lflowB 	i.ttbin_h##i.ttbin_w `hwy' , a(tr_h_yr tr_w_yr pairid csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(1.ttbin_h#1.ttbin_w) name(c1_00) all
store_est_tpl using ./tables/`tn'.csv, coef(2.ttbin_h#1.ttbin_w) name(c1_20) all
store_est_tpl using ./tables/`tn'.csv, coef(5.ttbin_h#1.ttbin_w) name(c1_50) all
store_est_tpl using ./tables/`tn'.csv, coef(1.ttbin_h#2.ttbin_w) name(c1_02) all
store_est_tpl using ./tables/`tn'.csv, coef(2.ttbin_h#2.ttbin_w) name(c1_22) all
store_est_tpl using ./tables/`tn'.csv, coef(5.ttbin_h#2.ttbin_w) name(c1_52) all
store_est_tpl using ./tables/`tn'.csv, coef(1.ttbin_h#5.ttbin_w) name(c1_05) all
store_est_tpl using ./tables/`tn'.csv, coef(2.ttbin_h#5.ttbin_w) name(c1_25) all
store_est_tpl using ./tables/`tn'.csv, coef(5.ttbin_h#5.ttbin_w) name(c1_55) all

reghdfe lflowB 	i.ttbin_h##i.ttbin_w `hwy' if Sim10_tr_lo_cc==1, a(tr_h_yr tr_w_yr pairid csbXcsbXyr) vce(cluster pairid tract_h tract_w)
store_est_tpl using ./tables/`tn'.csv, coef(1.ttbin_h#1.ttbin_w) name(c2_00) all
store_est_tpl using ./tables/`tn'.csv, coef(2.ttbin_h#1.ttbin_w) name(c2_20) all
store_est_tpl using ./tables/`tn'.csv, coef(5.ttbin_h#1.ttbin_w) name(c2_50) all
store_est_tpl using ./tables/`tn'.csv, coef(1.ttbin_h#2.ttbin_w) name(c2_02) all
store_est_tpl using ./tables/`tn'.csv, coef(2.ttbin_h#2.ttbin_w) name(c2_22) all
store_est_tpl using ./tables/`tn'.csv, coef(5.ttbin_h#2.ttbin_w) name(c2_52) all
store_est_tpl using ./tables/`tn'.csv, coef(1.ttbin_h#5.ttbin_w) name(c2_05) all
store_est_tpl using ./tables/`tn'.csv, coef(2.ttbin_h#5.ttbin_w) name(c2_25) all
store_est_tpl using ./tables/`tn'.csv, coef(5.ttbin_h#5.ttbin_w) name(c2_55) all

table_from_tpl, t(./tables/`tn'.tex) r(./tables/`tn'.csv) o(./tables/filled_`tn'.tex)

		
estimates clear


****************************
** Commuting Composition
** Too much rounding to be useful...

gen 	sh_drive = min(1, (wtflow_drivealone5b + wtflow_carpool_eq25b + wtflow_carpool_geq35b) / wtflow5b) if !mi(wtflow5b, wtflow_drivealone5b, wtflow_carpool_eq25b, wtflow_carpool_geq35b)

gen 	sh_metro = min(1, (wtflow_transit5b / wtflow5b) ) if !mi(wtflow5b, wtflow_transit5b)

local hwy centHwy05_cc centHwy10_cc
reghdfe sh_drive 	tt00_cc							, a(pairid tr_h_yr tr_w_yr) vce(cluster pairid tract_h tract_w)
reghdfe sh_drive 	tt00_cc tt02_cc tt25_cc			, a(pairid tr_h_yr tr_w_yr) vce(cluster pairid tract_h tract_w)
reghdfe sh_drive	tt00_cc tt02_cc tt25_cc `hwy'	, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
reghdfe sh_drive	tt00_cc tt02_cc tt25_cc `hwy'	if PER10_tr_lo_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
reghdfe sh_drive	tt00_cc tt02_cc tt25_cc `hwy'	if Sal10_tr_lo_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
reghdfe sh_drive	tt00_cc tt02_cc tt25_cc `hwy'	if Sim10_tr_lo_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
reghdfe sh_drive	tt??_cc_same `hwy'	if evertreated05_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
reghdfe sh_drive	tt??_cc_same `hwy'	if tranccsample==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)

local hwy centHwy05_cc centHwy10_cc
reghdfe sh_metro 	tt00_cc							, a(pairid tr_h_yr tr_w_yr) vce(cluster pairid tract_h tract_w)
reghdfe sh_metro 	tt00_cc tt02_cc tt25_cc			, a(pairid tr_h_yr tr_w_yr) vce(cluster pairid tract_h tract_w)
reghdfe sh_metro	tt00_cc tt02_cc tt25_cc `hwy'	, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
reghdfe sh_metro	tt00_cc tt02_cc tt25_cc `hwy'	if PER10_tr_lo_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
reghdfe sh_metro	tt00_cc tt02_cc tt25_cc `hwy'	if Sal10_tr_lo_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
reghdfe sh_metro	tt00_cc tt02_cc tt25_cc `hwy'	if Sim10_tr_lo_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
reghdfe sh_metro	tt??_cc_same `hwy'	if evertreated05_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
reghdfe sh_metro	tt??_cc_same `hwy'	if tranccsample==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)


******************************************************
/* Robstness to various distances */
******************************************************

tempname grad_treatments
postfile `grad_treatments' cent_threshold perim_threshold p_treat b se using "./results/metroeffects/gradientreatment.dta", replace

foreach d of numlist 0(100)1000 {
	foreach n of numlist 0(50)1500 {
		g byte	tran_h	= ((distance1999_h<=`n' | cent_distance1999_h<`d') & yr==1) 
		g byte	tran_w	= ((distance1999_w<=`n' | cent_distance1999_w<`d') & yr==1) 
		g byte	tran_cc = tran_h*tran_w
		
		sum	tran_cc if yr==1, meanonly
		local ptreat = r(mean)

		local hwy centHwy05_cc centHwy10_cc
		reghdfe lflowB	tran_cc `hwy', a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
		
		post `grad_treatments' (`d') (`n') (`ptreat') (`=_b[tran_cc]') (`=_se[tran_cc]')
		
		drop 	tran_h tran_w tran_cc
	}
}

postclose `grad_treatments'

tempname grad_treatments_sim
postfile `grad_treatments_sim' cent_threshold perim_threshold p_treat b se using "./results/metroeffects/gradientreatment_sim.dta", replace

foreach d of numlist 0(100)1000 {
	foreach n of numlist 0(50)1500 {
		g byte	tran_h	= ((distance1999_h<=`n' | cent_distance1999_h<`d') & yr==1) 
		g byte	tran_w	= ((distance1999_w<=`n' | cent_distance1999_w<`d') & yr==1) 
		g byte	tran_cc = tran_h*tran_w
		
		sum	tran_cc if yr==1, meanonly
		local ptreat = r(mean)

		local hwy centHwy05_cc centHwy10_cc
		reghdfe lflowB	tran_cc `hwy'	if Sim10_tr_lo_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid tract_h tract_w)
		
		post `grad_treatments_sim' (`d') (`n') (`ptreat') (`=_b[tran_cc]') (`=_se[tran_cc]')
		
		drop 	tran_h tran_w tran_cc
	}
}

postclose `grad_treatments_sim'


