** Make LEHD lfow data in 2002 and 2015
clear

**************************
** Get FLOWS Data Going **
**************************

********************
/* Prep 2002 data */

insheet using "./data/LEHD/ca_od_main_JT00_2002.csv", c

format 	w_geocode h_geocode %14.0f

gen double w_bg = floor(w_geocode/1000)
gen double h_bg = floor(h_geocode/1000)

format 	w_bg h_bg %12.0f

gen county_w = floor(w_geocode/10000000000) - 6000
gen county_h = floor(h_geocode/10000000000) - 6000
keep if county_w==37 | county_w==59 | county_w==65 | county_w==71 | county_w==111
keep if county_h==37 | county_h==59 | county_h==65 | county_h==71 | county_h==111

collapse (sum) s000, by(w_bg h_bg)

rename s000 flows
gen yr = 0

tempfile lehdflow_2002
save "`lehdflow_2002'", replace

clear

********************
/* Prep 2015 data */

insheet using "./data/LEHD/ca_od_main_JT00_2015.csv", c

format 	w_geocode h_geocode %14.0f

gen double w_bg = floor(w_geocode/1000)
gen double h_bg = floor(h_geocode/1000)

format 	w_bg h_bg %12.0f

gen county_w = floor(w_geocode/10000000000) - 6000
gen county_h = floor(h_geocode/10000000000) - 6000
keep if county_w==37 | county_w==59 | county_w==65 | county_w==71 | county_w==111
keep if county_h==37 | county_h==59 | county_h==65 | county_h==71 | county_h==111

collapse (sum) s000, by(w_bg h_bg)

rename s000 flows
gen yr = 1

*************************
/* Merge in both years */

append using "`lehdflow_2002'"
sort w_bg h_bg yr

egen 	double pairid = group(w_bg h_bg)

xtset 	pairid yr
bys pairid: egen tobs = count(flow)

** Check unique numbers
sum 	flow [aw=flow] if yr==0
sum 	flow [aw=flow] if yr==1
sum 	flow [aw=flow] if tobs==2 & yr==0
sum 	flow [aw=flow] if tobs==2 & yr==1

** BG analysis throws away between one third half of units, so go with tracts
drop pairid tobs

gen 	double w_tr = floor(w_bg/10)
gen		double h_tr = floor(h_bg/10)
format 	w_tr h_tr %12.0f

collapse (sum) flows, by(w_tr h_tr yr)

sort w_tr h_tr yr

egen 	double pairid = group(w_tr h_tr)

xtset 	pairid yr
bys pairid: egen tobs = count(flow)

** Check unique numbers
sum 	flow [aw=flow] if yr==0
sum 	flow [aw=flow] if yr==1
sum 	flow [aw=flow] if tobs==2 & yr==0
sum 	flow [aw=flow] if tobs==2 & yr==1

compress
tsfill, full

replace flows=0 if flows==.

bys pairid: egen double tract_w2 = mean(w_tr)
bys pairid: egen double tract_h2 = mean(h_tr)

drop 	w_tr h_tr
rename 	tract_w2 w_tr
rename 	tract_h2 h_tr
format 	?_tr %14.0f

tempfile lehdflows
save "`lehdflows'", replace
clear

*************************************
****** Treatment Information ********
*************************************

insheet using "./output/intermediate/stationRoads_distances_tr10_LEHDLODES.csv", c

gen 	double tr 	= 6*1000000000 + countyfp10*1000000 + name10*100 
format  tr %14.0f
replace tr = round(tr)

keep 	tr distance2000 distance2015 cent_distance2000 cent_distance2015 ///
			distance_lines1925all distance_lines1925immediate distance_linesper ///
			tracks_distance2015

tempfile treatmentdata
save 	"`treatmentdata'", replace
clear
			
*************************************
****** Supporting Information *******
*************************************

/* County Subdivisions */
insheet using "./output/crosswalks/tracts10CountySubs.csv", c

gen 	double tr  	= 6*1000000000 + countyfp10*1000000 + name10*100 
format  tr %14.0f

keep 	cousub90 tr 
replace tr  = round(tr )

tempfile countysubs
save 	"`countysubs'", replace
clear


*************************************
****** Merge and Define Vars ********
*************************************

use "`lehdflows'"

rename w_tr tr

merge 	m:1 tr using "`treatmentdata'"
drop	if _merge==2
drop 	_merge

merge 	m:1 tr using "`countysubs'"
drop	if _merge==2
drop 	_merge

local 	tvars distance2000 distance2015 cent_distance2000 cent_distance2015 distance_lines1925all distance_lines1925immediate distance_linesper tracks_distance2015 cousub90
foreach v of varlist `tvars' {
	rename `v' `v'_w
}

rename 	tr w_tr
rename 	h_tr tr

merge 	m:1 tr using "`treatmentdata'"
drop	if _merge==2
drop 	_merge

merge 	m:1 tr using "`countysubs'"
drop	if _merge==2
drop 	_merge

foreach v of varlist `tvars' {
	rename `v' `v'_h
}

rename 	tr h_tr

*************************
/* More useful pieces  */

gen		OWN = 0 
replace	OWN = 1 if w_tr==h_tr

*****************************
/* More define treatments  */

sort 	pairid yr

local odvec h w 

foreach v of local odvec {

/* Proximity to transit, h and w */

	gen 	tran00_`v'	= 0
	gen 	tran02_`v'	= 0
	gen 	tran05_`v'	= 0
	gen 	tran10_`v'	= 0
	
	replace tran00_`v'	= 1 if ((distance2000_`v'==0 | cent_distance2000_`v'<500) & yr==0) 
	replace tran02_`v'	= 1 if (distance2000_`v'<250 & yr==0)
	replace tran05_`v'	= 1 if (distance2000_`v'<500 & yr==0)
	replace tran10_`v'	= 1 if (distance2000_`v'<1000 & yr==0)
	
	replace tran00_`v'	= 1 if ((distance2015_`v'==0 | cent_distance2015_`v'<500) & yr==1) 
	replace tran02_`v'	= 1 if (distance2015_`v'<250 & yr==1)
	replace tran05_`v'	= 1 if (distance2015_`v'<500 & yr==1)
	replace tran10_`v'	= 1 if (distance2015_`v'<1000 & yr==1)

	gen 	ever_treated05_`v' = (distance2015_`v'<500)
	gen 	ever_treated10_`v' = (distance2015_`v'<1000)

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

	gen		ever_track05_`v'	= (tracks_distance2015_`v'<500)
	gen		ever_track10_`v'	= (tracks_distance2015_`v'<1000)

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

bys yr: sum tran??_h tran??_w if OWN==1
tab tran00_h tran02_h if OWN==1 & yr==1
tab tran02_h tran05_h if OWN==1 & yr==1

bys yr: sum Sim??_??_? Sim??_??_?_ex Sal??_??_? Sal??_??_?_ex PER??_??_? PER??_??_?_ex

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


/* Additional utilities */

egen 	tr_h_yr = group(h_tr yr)
egen 	tr_w_yr = group(w_tr yr)

xtset 	pairid yr
sort 	pairid yr

/* Defining useful variables in logs*/

gen		lflow 	= ln(flow)

/* Subcounty by year fixed effects */

egen 	csubXyr_h 	= group(cousub90_h yr)
egen 	csubXyr_w 	= group(cousub90_w yr)
egen 	csbXcsbXyr 	= group(csubXyr_h csubXyr_w)

drop if csbXcsbXyr==. /* Islands */

compress

save 	"./output/flows_final_lehd.dta", replace
