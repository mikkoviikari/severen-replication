* DiD pretrend analysis in NCDB data

use 	"./output/ncdb_tractdata.dta", clear

****** Define useful variables **********
*****************************************

gen allin = 1

/* Pre trends FEs */

local samples allin Sim05_tr Sal05_tr PER05_tr 

foreach s of local samples {

	capture erase ./results/pretrends/`s'.csv

	reghdfe lemp	c.dd##c.time 	if year<1995 & `s'==1, a(areakey csubXyr) cluster(areakey)
	store_est_tpl using ./results/pretrends/`s'.csv, coef(c.dd#c.time) name(c1) all
	
	reghdfe lnhh	c.dd##c.time 	if year<1995 & `s'==1, a(areakey csubXyr) cluster(areakey)
	store_est_tpl using ./results/pretrends/`s'.csv, coef(c.dd#c.time) name(c2) all
	
	reghdfe lhhi 	c.dd##c.time 	if year<1995 & `s'==1, a(areakey csubXyr) cluster(areakey)
	store_est_tpl using ./results/pretrends/`s'.csv, coef(c.dd#c.time) name(c3) all

	reghdfe lhvalave c.dd##c.time 	if year<1995 & `s'==1, a(areakey csubXyr) cluster(areakey)
	store_est_tpl using ./results/pretrends/`s'.csv, coef(c.dd#c.time) name(c4) all
	
	reghdfe shrcol 	c.dd##c.time 	if year<1995 & `s'==1, a(areakey csubXyr) cluster(areakey)
	store_est_tpl using ./results/pretrends/`s'.csv, coef(c.dd#c.time) name(c5) all
	
	reghdfe povrat 	c.dd##c.time 	if year<1995 & `s'==1, a(areakey csubXyr) cluster(areakey)
	store_est_tpl using ./results/pretrends/`s'.csv, coef(c.dd#c.time) name(c6) all

	reghdfe shrmove c.dd##c.time 	if year<1995 & `s'==1, a(areakey csubXyr) cluster(areakey)
	store_est_tpl using ./results/pretrends/`s'.csv, coef(c.dd#c.time) name(c7) all
	
	reghdfe shrnocar c.dd##c.time 	if year<1995 & `s'==1, a(areakey csubXyr) cluster(areakey)
	store_est_tpl using ./results/pretrends/`s'.csv, coef(c.dd#c.time) name(c8) all
	
	reghdfe shrauto c.dd##c.time 	if year<1995 & `s'==1, a(areakey csubXyr) cluster(areakey)
	store_est_tpl using ./results/pretrends/`s'.csv, coef(c.dd#c.time) name(c9) all
	
	*ppmlhdfe auto	c.dd##c.time 	if year<1995 & `s'==1 & trvlpbd>0, a(areakey csubXyr) cluster(areakey)
	*store_est_tpl using ./results/pretrends/`s'.csv, coef(c.dd#c.time) name(c10) all

	reghdfe shrtransit c.dd##c.time 	if year<1995 & `s'==1, a(areakey csubXyr) cluster(areakey)
	store_est_tpl using ./results/pretrends/`s'.csv, coef(c.dd#c.time) name(c10) all

	*ppmlhdfe trvlpbn c.dd##c.time 	if year<1995 & `s'==1 & trvlpbd>0, a(areakey csubXyr) cluster(areakey)
	*store_est_tpl using ./results/pretrends/`s'.csv, coef(c.dd#c.time) name(c12) all
}

table_from_tpl, t(./tables/tablef1.tex) r(./results/pretrends/allin.csv) o(./tables/filled_tablef1A.tex)
table_from_tpl, t(./tables/tablef1.tex) r(./results/pretrends/Sim05_tr.csv) o(./tables/filled_tablef1B.tex)
table_from_tpl, t(./tables/tablef1.tex) r(./results/pretrends/Sal05_tr.csv) o(./tables/filled_tablef1C.tex)
table_from_tpl, t(./tables/tablef1.tex) r(./results/pretrends/PER05_tr.csv) o(./tables/filled_tablef1D.tex)
