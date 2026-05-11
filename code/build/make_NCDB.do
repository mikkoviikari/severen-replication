** Read in NCDB data from 1970-2010 and standardize

clear

local 	din		"D:\Current_Research\JMP\Data\NCDB"
local 	dout 	"D:\Current_Research\JMP\Analysis\Data_Storage"
local 	ddata 	"D:\Current_Research\JMP\Analysis\Data_Storage"
local 	ddis 	"D:\Current_Research\JMP\Data\Distances"


****** First, read in key data *******
**************************************

insheet using "./data/NCDB/LA MSA Data 1.csv"
format 	areakey %14.0f

keep 	areakey arealand county cousub

tempfile keydata
save "`keydata'", replace
clear

****** Now bring in each year *******
*************************************

*******************
/*** 1970 Data ***/

insheet using "./data/NCDB/LA MSA Data 2.csv"
format 	areakey %14.0f

foreach v of varlist trctpop7-trvlot7 {
	local 	newv = subinstr("`v'", "7", "", .)
	rename 	`v' `newv'
}

rename 	educ87  educ8
rename 	educ117 educ11
rename 	educ127 educ12
rename 	educ157 educ15
rename 	educ167 educ16

foreach v of varlist educpp7-rentrto7 {
	local 	newv = subinstr("`v'", "7", "", .)
	rename 	`v' `newv'
}

gen 	year = 1970

tempfile data70
save 	"`data70'", replace
clear

*******************
/*** 1980 Data ***/

insheet using "./data/NCDB/LA MSA Data 3.csv"
format 	areakey %14.0f

foreach v of varlist trctpop8-trvlot8n {
	local 	newv = subinstr("`v'", "8", "", .)
	rename 	`v' `newv'
}

rename 	educ88  educ8
rename 	educ118 educ11
rename 	educ128 educ12
rename 	educ158 educ15
rename 	educ168 educ16

foreach v of varlist educpp8-rentrto8 {
	local 	newv = subinstr("`v'", "8", "", .)
	rename 	`v' `newv'
}

gen 	year = 1980

tempfile data80
save 	"`data80'", replace
clear

*******************
/*** 1990 Data ***/

insheet using "./data/NCDB/LA MSA Data 4.csv"
format 	areakey %14.0f

foreach v of varlist trctpop9-trvlot9n {
	local 	newv = subinstr("`v'", "9", "", .)
	rename 	`v' `newv'
}

rename 	educ89  educ8
rename 	educ119 educ11
rename 	educ129 educ12
rename 	educ159 educ15
rename 	educa9  educa
rename 	educ169 educ16

replace educ15 	= educ15+educa
drop 	educa

foreach v of varlist educpp9-rentrto9 {
	local 	newv = subinstr("`v'", "9", "", .)
	rename 	`v' `newv'
}

gen 	year = 1990

tempfile data90
save 	"`data90'", replace
clear

*******************
/*** 2000 Data ***/

insheet using "./data/NCDB/LA MSA Data 5.csv"
format 	areakey %14.0f

foreach v of varlist trctpop0-trvlot0n {
	local 	newv = subinstr("`v'", "0", "", .)
	rename 	`v' `newv'
}

rename 	educ80 educ8
rename 	educ110 educ11
rename 	educ120 educ12
rename 	educ150 educ15
rename 	educa0 educa
rename 	educ160 educ16

replace educ15 = educ15+educa
drop 	educa

foreach v of varlist educpp0-rentrto0 {
	local 	newv = subinstr("`v'", "0", "", .)
	rename 	`v' `newv'
}

gen 	year = 2000

tempfile data00
save 	"`data00'", replace
clear

*******************
/*** 2010 Data ***/

*Read in 2006-10 ACS, then supplment with first five columns from 2010 Census*

insheet using "./data/NCDB/LA MSA Data 6.csv"
format 	areakey %14.0f

foreach v of varlist shr1ad-rentrto1a {
	local 	newv = subinstr("`v'", "1a", "", .)
	rename 	`v' `newv'
}

replace educ15 = educ15+educa
drop 	educa

tempfile prep10
save 	"`prep10'", replace
clear

insheet using "./data/NCDB/LA MSA Data 8.csv"
format 	areakey %14.0f

rename 	trctpop1 	trctpop
rename 	shr1d 		shrd
rename 	shrwht1 	shrwht
rename 	shrblk1		shrblk

keep 	areakey trctpop shrd shrwht shrblk

merge 	1:1 areakey using "`prep10'"
drop 	_merge

gen 	year = 2010

****** Bring in (append) all years *******
******************************************

append 	using "`data00'"
append 	using "`data90'"
append 	using "`data80'"
append 	using "`data70'"

merge 	m:1 areakey using "`keydata'"
drop 	_merge

order 	areakey year arealand county cousub, first
bys year: sum trctpop [aw=trctpop]

sort 	areakey year

tempfile tractncdb_panel
save 	"`tractncdb_panel'", replace
clear


*************************************
****** Treatment Information ********
*************************************

insheet using "./output/intermediate/stationRoads_distances_tracts2010.csv", c

gen 	double areakey 	= 6*1000000000 + countyfp10*1000000 + name10*100 
format  areakey %14.0f
replace areakey = round(areakey)

keep 	areakey distance1999 distance2000 distance2015 cent_distance1999 tracks_distance1999 ///
			distance_lines1925all distance_lines1925immediate distance_linesper ///
			unbuilt_stdist unbuilt_stdist_cent unbuilt_lidist acci_treat ///
			unbuilt_group blueline1999 redline1999 purpleline1999 greenline1999

replace acci_treat = "1" if acci_treat=="TRUE"
replace acci_treat = "0" if acci_treat=="FALSE"
destring acci_treat, replace

tempfile treatmentdata
save 	"`treatmentdata'", replace
clear
			
*************************************
****** Supporting Information *******
*************************************

/* County Subdivisions */

insheet using "./output/crosswalks/tracts10CountySubs.csv", c

gen 	double areakey 	= 6*1000000000 + countyfp10*1000000 + name10*100 
format  areakey %14.0f

keep 	cousub90 areakey
replace areakey = round(areakey)

tempfile countysubs
save 	"`countysubs'", replace
clear

*************************************
****** Merge and Define Vars ********
*************************************

use "`tractncdb_panel'"

merge 	m:1 areakey using "`countysubs'"
drop 	_merge

merge 	m:1 areakey using "`treatmentdata'"
drop 	_merge

/* Variables of interest named like main files */

gen		dd = max(500-distance1999,0)/500


/*
gen		rec_tran00	= 0
gen		rec_tran02	= 0
gen		rec_tran05	= 0
gen		rec_tran10	= 0

replace	rec_tran00  = 1 if distance1999==0 | cent_distance1999<500 
replace rec_tran02	= 1 if distance1999<250 
replace rec_tran05	= 1 if distance1999<500
replace rec_tran10	= 1 if distance1999<1000


gen		tt00 = rec_tran00

gen		tt02 = rec_tran02
replace tt02 = 0 if tt00==1

gen 	tt05 = tran05_`v'
replace tt05 = 0 if tt00_`v'==1

gen 	tt25 = tran05_`v'
replace tt25 = 0 if tt00_`v'==1 | tt02_`v'==1

gen 	tt10 = tran10_`v'
replace tt10_`v' = 0 if tt00_`v'==1 | tt02_`v'==1 | tt05_`v'==1
*/

gen 	ever_treated05	 = (distance1999<500)
gen 	ever_treated10	 = (distance1999<1000)

gen		ever_track05	= (tracks_distance1999<500)
gen		ever_track10	= (tracks_distance1999<1000)

/* Proximity to controls, h and w */
   
gen 	SubplanImm05 = (distance_lines1925immediate<500)  
gen 	SubplanImm10 = (distance_lines1925immediate<1000)

gen 	Subplan05 = (distance_lines1925all<500)   
gen 	Subplan10 = (distance_lines1925all<1000)

gen 	PERplan05 = (distance_linesper<500)  
gen 	PERplan10 = (distance_linesper<1000)

/* Proximity to accidentally treated locations */
** UNSUCCESSFUL **
/*
gen 	treat_accident05 = (distance1999<500) & (acci_treat==1)
gen 	treat_accident10 = (distance1999<1000) & (acci_treat==1)

gen 	untreat_accident05 = (unbuilt_stdist<500) | (unbuilt_lidist<500)
gen 	untreat_accident10 = (unbuilt_stdist<1000) | (unbuilt_lidist<500)
*/

/* Defining samples */
local nvec		 05 10
foreach n of local nvec {
	
	gen 	Sim`n'_st = (SubplanImm`n'==1 | ever_treated`n'==1)
	gen 	Sal`n'_st = (Subplan`n'==1 | ever_treated`n'==1)
	gen 	PER`n'_st = (PERplan`n'==1 | ever_treated`n'==1)

	gen 	Sim`n'_tr = (SubplanImm`n'==1 | ever_track`n'==1)
	gen 	Sal`n'_tr = (Subplan`n'==1 | ever_track`n'==1)
	gen 	PER`n'_tr = (PERplan`n'==1 | ever_track`n'==1)
	
	*gen 	Acci`n' = (treat_accident`n'==1 | untreat_accident`n'==1)
}

/* Accident Groups */
/*
local nvec		 05 10
foreach n of local nvec {
	gen 	grp_Acci`n' = 1 if (unbuilt_group=="Red/Purple" | redline1999==1 | purpleline1999==1) & Acci`n'==1
	replace grp_Acci`n' = 2 if (unbuilt_group=="Green" | greenline1999==1) & Acci`n'==1
	replace grp_Acci`n' = 3 if (unbuilt_lidist<500 | blueline1999==1) & Acci`n'==1
} */

*************************************
****** Clean + Extra vars    ********
*************************************

egen 	csubXyr 	= group(cousub90 year)

xtset areakey year

gen 	lpop	= ln(trctpop)
gen 	lnhh	= ln(numhhs)
gen 	lemp  	= ln(wrcntyd)
gen		shrnocar = nocar / shrd
gen		shrsame = smhsern / smhserd
gen 	shrhsg	= (educ12 + educ15 + educ16) / educpp
gen 	shrcol	= educ16 / educpp
gen		shrauto = auto / trvlpbd
gen		shrtransit = trvlpbn / trvlpbd

gen 	lhhi 	= ln(avhhin)
gen 	lfami 	= ln(favinc)

gen 	lhunits = ln(tothsun)

gen		lhvalave = ln(aggval/spownoc) if aggval!=.
gen		lrentave = ln(aggrent/sprntoc) if aggrent!=.

gen 	lnmedval = ln(mdvalhs)

gen 	shrmove = smhsen / smhsed

gen 	lpubtran = ln(trvlpbn)
gen 	hyspubtran = ln(trvlpbn + sqrt((trvlpbn^2) + 1))

gen 	time = 0
replace	time = 1 if year==1980
replace	time = 2 if year==1990
replace	time = 3 if year==2000
replace	time = 4 if year==2010



/* clean up variables */

foreach v of varlist shrd-unemptn {
	replace `v'=. if `v'==-999
}

gen	numhhs_is0 = (numhhs==0)
gen	numhhs_ism = mi(numhhs)

gen	pop_is0 = (trctpop==0)
gen	pop_ism = mi(trctpop)

foreach v of varlist shrd-unemptn {
	replace `v'=. if pop_is0==1
	replace `v'=. if pop_ism==1
}

foreach v of varlist nocar car1 car2 car3 car tothsun-rentrto {
	replace `v'=. if numhhs_is0==1
	replace `v'=. if numhhs_ism==1
}

xtset areakey time
compress

save "./output/ncdb_tractdata", replace
clear
