use 	"./output/flows_final_lehd.dta", clear

***********************
/* Variable Creation */
***********************

gen 	stayer00 = 0
replace stayer00 = 1 if L.tt00_cc == 1

tab 	tt00_cc stayer00 if yr==0
tab 	tt00_cc stayer00 if yr==1

gen 	stayer02 = 0
replace stayer02 = 1 if L.tt02_cc == 1

tab 	tt02_cc stayer02 if yr==0
tab 	tt02_cc stayer02 if yr==1

gen 	stayer25 = 0
replace stayer25 = 1 if L.tt25_cc == 1

tab 	tt25_cc stayer25 if yr==0
tab 	tt25_cc stayer25 if yr==1


gen 	stayer05 = 0
replace stayer05 = 1 if L.tran05_cc == 1

***********************
/* Regressions */
***********************


local tn table8
capture erase ./tables/`tn'.csv

local hwy centHwy05_cc centHwy10_cc

reghdfe lflow 	tt00_cc tt02_cc tt25_cc	stayer05		, a(pairid tr_h_yr tr_w_yr) vce(cluster pairid h_tr w_tr)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c1_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c1_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c1_25) all
store_est_tpl using ./tables/`tn'.csv, coef(stayer05) name(s1_05) all

reghdfe lflow 	tt00_cc tt02_cc tt25_cc	stayer00 stayer02 stayer25, a(pairid tr_h_yr tr_w_yr) vce(cluster pairid h_tr w_tr)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c2_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c2_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c2_25) all
store_est_tpl using ./tables/`tn'.csv, coef(stayer00) name(s2_00) all
store_est_tpl using ./tables/`tn'.csv, coef(stayer02) name(s2_02) all
store_est_tpl using ./tables/`tn'.csv, coef(stayer25) name(s2_25) all

reghdfe lflow	tt00_cc tt02_cc tt25_cc stayer00 stayer02 stayer25, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid h_tr w_tr)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c3_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c3_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c3_25) all
store_est_tpl using ./tables/`tn'.csv, coef(stayer00) name(s3_00) all
store_est_tpl using ./tables/`tn'.csv, coef(stayer02) name(s3_02) all
store_est_tpl using ./tables/`tn'.csv, coef(stayer25) name(s3_25) all

reghdfe lflow	tt00_cc tt02_cc tt25_cc stayer00 stayer02 stayer25 if PER10_tr_lo_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid h_tr w_tr)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c4_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c4_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c4_25) all
store_est_tpl using ./tables/`tn'.csv, coef(stayer00) name(s4_00) all
store_est_tpl using ./tables/`tn'.csv, coef(stayer02) name(s4_02) all
store_est_tpl using ./tables/`tn'.csv, coef(stayer25) name(s4_25) all

reghdfe lflow	tt00_cc tt02_cc tt25_cc stayer00 stayer02 stayer25 if Sal10_tr_lo_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid h_tr w_tr)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c5_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c5_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c5_25) all
store_est_tpl using ./tables/`tn'.csv, coef(stayer00) name(s5_00) all
store_est_tpl using ./tables/`tn'.csv, coef(stayer02) name(s5_02) all
store_est_tpl using ./tables/`tn'.csv, coef(stayer25) name(s5_25) all

reghdfe lflow	tt00_cc tt02_cc tt25_cc stayer00 stayer02 stayer25 if Sim10_tr_lo_cc==1, a(pairid tr_h_yr tr_w_yr csbXcsbXyr) vce(cluster pairid h_tr w_tr)
store_est_tpl using ./tables/`tn'.csv, coef(tt00_cc) name(c6_00) all
store_est_tpl using ./tables/`tn'.csv, coef(tt02_cc) name(c6_02) all
store_est_tpl using ./tables/`tn'.csv, coef(tt25_cc) name(c6_25) all
store_est_tpl using ./tables/`tn'.csv, coef(stayer00) name(s6_00) all
store_est_tpl using ./tables/`tn'.csv, coef(stayer02) name(s6_02) all
store_est_tpl using ./tables/`tn'.csv, coef(stayer25) name(s6_25) all

table_from_tpl, t(./tables/`tn'.tex) r(./tables/`tn'.csv) o(./tables/filled_`tn'.tex)

est clear
