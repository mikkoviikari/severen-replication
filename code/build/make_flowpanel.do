** Combines 1990 and 2000 flows and distances
clear

*********************************
/* Merge flows from both years */

use 	"./output/intermediate/flows2000ctpp"
rename 	tract1990_O tract_h
rename 	tract1990_D tract_w

append  using "./output/intermediate/flows1990ctpp"
gen 	year = 0
replace year = 1 if yr==2000
drop 	yr

sort 	tract_w tract_h year
egen 	pairid = group(tract_w tract_h)

xtset 	pairid year
bys pairid: egen tobs = count(wtflow_all)

** Check unique numbers
sum 	wtflow_all [aw=wtflow_all] if year==0
sum 	wtflow_all [aw=wtflow_all] if year==1
sum 	wtflow_all [aw=wtflow_all] if tobs==2 & year==0
sum 	wtflow_all [aw=wtflow_all] if tobs==2 & year==1

tsfill, full
bys pairid: egen double tract_w2 = mean(tract_w)
bys pairid: egen double tract_h2 = mean(tract_h)

drop 	tract_w tract_h
rename 	tract_w2 tract_w
rename 	tract_h2 tract_h
format 	tract* %14.0f

tempfile tractflows
save "`tractflows'", replace
clear

**********************************
/* Prep distances and adjacency */
clear

insheet using "./output/intermediate/travelmat_here.csv", c n

destring traveltime, replace i("NA")
drop 	distance costfactor

gen 	tractlen_o = strlen(origindex)
gen 	tractlen_d = strlen(destindex)
replace origindex = origindex+"00" if tractlen_o==12
replace destindex = destindex+"00" if tractlen_d==12
drop 	tractlen_o tractlen_d

rename 	origindex tract_o
rename 	destindex tract_d
rename 	traveltime tt_here

replace	tt_here = tt_here/60 // Put into minutes.decimal

destring tract_o tract_d, replace i("G")
format 	tract_o tract_d %14.0f

tempfile here_dis
save 	"`here_dis'", replace
clear 

insheet using "./output/intermediate/tract_distance_adj.csv", c

gen 	adjacent = 1
replace adjacent = 0 if adjall=="FALSE"
gen 	rook_adj = 1
replace rook_adj = 0 if adjrook=="FALSE"

drop 	v1 adjall adjrook

gen 	tractlen_o = strlen(tract_o)
gen 	tractlen_d = strlen(tract_d)
replace tract_o = tract_o+"00" if tractlen_o==12
replace tract_d = tract_d+"00" if tractlen_d==12
drop 	tractlen_o tractlen_d

destring tract_o tract_d, replace i("G")
format 	tract_o tract_d %14.0f

merge 1:1 tract_o tract_d using "`here_dis'"
drop 	_merge

rename  tract_o tract_h
rename  tract_d tract_w
compress

tempfile tractdis
save "`tractdis'", replace

gen 	year = 0
append using "`tractdis'"

replace	year = 1 if mi(year)
compress

**********************************
/* Merge flows onto distances */

merge 	1:1 tract_w tract_h year using "`tractflows'"
drop if _merge==2
drop	_merge

drop 	pairid
sort 	tract_w tract_h year
egen 	pairid = group(tract_w tract_h)
xtset 	pairid year

/* Check how we did before dealing with the noise
twoway (kdensity wtflow_all if year==0 & wtflow_all<100 [aw=wtflow_all], bw(10)) ///
		(kdensity wtflow_all if year==1 & wtflow_all<100 [aw=wtflow_all], bw(10))
*/

gen 	wtflow5a = round(wtflow_all/5)
replace wtflow5a = . if wtflow5a==0

gen 	wttemp  	= wtflow_all
replace wttemp 		= 4 if wttemp<4 & wttemp>=1
gen 	wtflow5b 	= round(wttemp/5)
replace wtflow5b 	= . if wtflow5b==0
drop 	wttemp

bys pairid: egen tobs5a = count(wtflow5a)
bys pairid: egen tobs5b = count(wtflow5b)

tab tobs5?

/*
** Summary on what this cleaning does
sum wtflow5a [aw=wtflow5a] if year==0
sum wtflow5a [aw=wtflow5a] if year==1

sum wtflow5a [aw=wtflow5a] if tobs==2 & year==0
sum wtflow5a [aw=wtflow5a] if tobs==2 & year==1

sum wtflow5b [aw=wtflow5b] if year==0
sum wtflow5b [aw=wtflow5b] if year==1

sum wtflow5b [aw=wtflow5b] if tobs==2 & year==0
sum wtflow5b [aw=wtflow5b] if tobs==2 & year==1
*/

local wvarnames wtflow_drivealone wtflow_carpool_eq2 wtflow_carpool_geq3 wtflow_bus wtflow_transit wtflow_other wtflow_workhome

foreach v of varlist `wvarnames' {
	gen 	wttemp_`v'  = `v'
	replace wttemp_`v' = 4 if wttemp_`v'<4 & wttemp_`v'>=1
	gen 	`v'5b = round(wttemp_`v'/5)
	drop 	wttemp_`v'
}

compress

replace wtflow5a = 0 if wtflow5a==.
replace wtflow5b = 0 if wtflow5b==.

*****************************
/* Merge in distance files */

rename tract_w tract_POW
rename tract_h tract_RES

merge 	m:1 tract_POW tract_RES using "./data/Dynamap/tract_times"
drop if _merge!=3 // Merges fine! 0!=3
drop 	_merge

rename 	total_cost travcost
rename 	total_length travlen

rename  tract_POW tract_w
rename  tract_RES tract_h 

** Make OWN indicators
g byte 	OWN = 0 
replace	OWN = 1 if tract_w==tract_h

*****************************
/* Clean up */
rename 	travcost	tt_dyn	

order pairid year tract_h tract_w distance adjacent rook_adj tt_dyn tt_here ///
	wtflow_all wtflow_drivealone wtflow_carpool_eq2 wtflow_carpool_geq3 wtflow_bus wtflow_transit wtflow_other wtflow_workhome ///
	travtime_all travtime_drivealone travtime_carpool_eq2 travtime_carpool_geq3 travtime_bus travtime_transit travtime_other travtime_workhome ///
	wtflow5a wtflow5b wtflow_drivealone5b wtflow_carpool_eq25b wtflow_carpool_geq35b wtflow_bus5b wtflow_transit5b wtflow_other5b wtflow_workhome5b, ///
	first

label var distance 				"Centroid Distance (m)"
label var adjacent 				"Tracts Adjacent"
label var rook_adj 				"Tracts Rook Adjacent"
label var tt_dyn 				"Travel Time Dyn (minutes)"
label var tt_here 				"Travel Time HERE (minutes)"
label var wtflow_all 			"Raw Total Flow (do not compare 1990/2000)"
label var wtflow_drivealone 	"Raw Drive Alone Flow (do not compare 1990/2000)"
label var wtflow_carpool_eq2 	"Raw 2p Carpool Flow (do not compare 1990/2000)"
label var wtflow_carpool_geq3 	"Raw 3p or more Carpool Flow (do not compare 1990/2000)"
label var wtflow_bus 			"Raw Bus Flow (do not compare 1990/2000)"
label var wtflow_transit 		"Raw Transit Flow (do not compare 1990/2000)"
label var wtflow_other 			"Raw Other Flow (do not compare 1990/2000)"
label var wtflow_workhome 		"Raw Work at home Flow (do not compare 1990/2000)"
label var travtime_all 			"Reported Time, Total (minutes)"
label var travtime_drivealone 	"Reported Time, Drive Alone (minutes)"
label var travtime_carpool_eq2 	"Reported Time, 2p Carpool (minutes)"
label var travtime_carpool_geq3 "Reported Time, 3p or more Carpool (minutes)"
label var travtime_bus 			"Reported Time, Bus (minutes)"
label var travtime_transit 		"Reported Time, Transit (minutes)"
label var travtime_other 		"Reported Time, Other (minutes)"
label var travtime_workhome 	"Reported Time, Work at home (minutes)"
label var wtflow5a 				"Cleaned Flow, Total (method A /5)"
label var wtflow5b 				"Cleaned Flow, Total (method B /5)"
label var wtflow_drivealone5b 	"Cleaned Flow, Drive Alone (method B /5)"
label var wtflow_carpool_eq25b 	"Cleaned Flow, 2p Carpool (method B /5)"
label var wtflow_carpool_geq35b "Cleaned Flow, 3p or more Carpool (method B /5)"
label var wtflow_bus5b 			"Cleaned Flow, Bus (method B /5)"
label var wtflow_transit5b 		"Cleaned Flow, Transit (method B /5)"
label var wtflow_other5b 		"Cleaned Flow, Other (method B /5)"
label var wtflow_workhome5b 	"Cleaned Flow, Work at home (method B /5)"

compress

*scatter tt_dyn tt_here if year==1 & OWN!=1 & distance<50000, msize(vtiny) m(O)
*scatter tt_here distance  if year==1 & OWN!=1 & distance<50000, msize(vtiny) m(O)

preserve
	gen 	wtfloworig = wtflow_all
	gen		ttall = travtime_all
	drop 	travtime_* wtflow_*
	rename	wtfloworig wtflow_all
	rename	ttall travtime_all
	save "./output/intermediate/flowpanel_all", replace
restore
	
drop if tobs5a==0 & tobs5b==0 & OWN==0
drop 	tobs5?

save "./output/intermediate/flowpanel_small", replace

clear
