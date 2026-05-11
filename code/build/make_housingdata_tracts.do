** Makes housing detail data
clear

local 	din90	"./data\HousingDetails\nhgis0064_csv"
local 	din00 	"./data\HousingDetails\nhgis0071_csv"
local 	dinemp	"./data\HousingDetails\nhgis0069_csv"
local 	dinpop	"./data\HousingDetails\nhgis0070_csv"
local 	dinedr	"./data\HousingDetails\nhgis0072_csv"
local 	dout	"./output/intermediate"
local 	dx		"./output/crosswalks"

*************************************
****** 1990 tract data **************
*************************************

/* Residential Employment Numbers */

insheet using "`dinemp'/nhgis0069_ds123_1990_tract.csv", c
gen 	tractlen = strlen(gisjoin)
gen	 	tract1990 = gisjoin
replace	tract1990 = gisjoin + "00" if tractlen==12
drop 	tractlen

destring tract1990, replace i("G")
format  tract1990 %14.0f

keep if statea==6
keep if countya==37 | countya==59 | countya==65 | countya==71 | countya==111

egen 	resemp = rowtotal(e4p0??)
rename	e4u001 med_reshhi

keep 	tract1990 resemp med_reshhi

tempfile tr90_resemp
save 	"`tr90_resemp'", replace
clear

/* Quartiles of value from SF1 file */

insheet using "`din90'/nhgis0064_ds120_1990_tract.csv", c
gen 	tractlen = strlen(gisjoin)
gen	 	tract1990 = gisjoin
replace	tract1990 = gisjoin + "00" if tractlen==12
drop 	tractlen

destring tract1990, replace i("G")
format  tract1990 %14.0f

keep if statea==6
keep if countya==37 | countya==59 | countya==65 | countya==71 | countya==111

rename 	ess001 hval_25
rename 	est001 hval_50
rename 	esu001 hval_75
rename 	es5001 rent_25
rename 	es6001 rent_50
rename 	es7001 rent_75
	
rename 	es1001 nhu_owner
rename	es1002 nhu_renter

gen		tot_hunits = nhu_owner + nhu_renter

keep 	tract1990 hval_* rent_* nhu_* tot_hunits

tempfile tr90_values
save 	"`tr90_values'", replace
clear

/* Race in 1990 */

insheet using "`dinedr'/nhgis0072_ds120_1990_tract.csv", c
gen 	tractlen = strlen(gisjoin)
gen	 	tract1990 = gisjoin
replace	tract1990 = gisjoin + "00" if tractlen==12
drop 	tractlen

destring tract1990, replace i("G")
format  tract1990 %14.0f

keep if statea==6
keep if countya==37 | countya==59 | countya==65 | countya==71 | countya==111

gen		p_black90 = euy002 / (euy001 + euy002 + euy003 + euy004 + euy005)

keep 	tract1990 p_black90

tempfile tr90_race
save 	"`tr90_race'", replace
clear

/* Education in 1990 */

insheet using "`dinedr'/nhgis0072_ds123_1990_tract.csv", c
gen 	tractlen = strlen(gisjoin)
gen	 	tract1990 = gisjoin
replace	tract1990 = gisjoin + "00" if tractlen==12
drop 	tractlen

destring tract1990, replace i("G")
format  tract1990 %14.0f

keep if statea==6
keep if countya==37 | countya==59 | countya==65 | countya==71 | countya==111

gen		p_hsgr90 	= (e33003 + e33004 + e33005 + e33006 + e33007) / (e33001 + e33002 + e33003 + e33004 + e33005 + e33006 + e33007)
gen		p_colgr90   = (e33006 + e33007) / (e33001 + e33002 + e33003 + e33004 + e33005 + e33006 + e33007)

keep 	tract1990 p_hsgr90 p_colgr90

tempfile tr90_edu
save 	"`tr90_edu'", replace
clear

/* Population data */

insheet using "`dinpop'/nhgis0070_ds120_1990_tract.csv", c
gen 	tractlen = strlen(gisjoin)
gen	 	tract1990 = gisjoin
replace	tract1990 = gisjoin + "00" if tractlen==12
drop 	tractlen

destring tract1990, replace i("G")
format  tract1990 %14.0f

keep if statea==6
keep if countya==37 | countya==59 | countya==65 | countya==71 | countya==111

rename 	et1001 totpop

keep 	tract1990 totpop

/* Merging with other data */

merge 	1:1 tract1990 using "`tr90_values'"
drop 	_merge
merge 	1:1 tract1990 using "`tr90_resemp'"
drop 	_merge
merge 	1:1 tract1990 using "`tr90_race'"
drop 	_merge
merge 	1:1 tract1990 using "`tr90_edu'"
drop 	_merge

foreach v of varlist hval_?? rent_?? med_reshhi {
	replace `v' = . if `v'==0
}

gen 	year = 1990

replace hval_25 = . if hval_25==9999
replace hval_50 = . if hval_50==9999
replace hval_75 = . if hval_75==9999

replace rent_25	= . if rent_25==99
replace rent_50	= . if rent_50==99
replace rent_75	= . if rent_75==99

tempfile tract90_all
save 	"`tract90_all'", replace
clear


*************************************
****** 2000 tract data **************
*************************************

/* Employment Numbers */

insheet using "`dinemp'/nhgis0069_ds151_2000_tract.csv", c
gen 	tractlen = strlen(gisjoin)
gen	 	tract2000 = gisjoin
replace	tract2000 = gisjoin + "00" if tractlen==12
drop 	tractlen

destring tract2000, replace i("G")
format  tract2000 %14.0f

keep if statea==6
keep if countya==37 | countya==59 | countya==65 | countya==71 | countya==111

rename 	gmf001 resemp
rename	gmy001 med_reshhi

keep 	tract2000 resemp med_reshhi

tempfile tr00_resemp
save 	"`tr00_resemp'", replace
clear


/* Quartiles of value */

insheet using "`din00'/nhgis0071_ds151_2000_tract.csv", c
gen 	tractlen = strlen(gisjoin)
gen	 	tract2000 = gisjoin
replace	tract2000 = gisjoin + "00" if tractlen==12
drop 	tractlen

destring tract2000, replace i("G")
format  tract2000 %14.0f

keep if statea==6
keep if countya==37 | countya==59 | countya==65 | countya==71 | countya==111

rename 	gb6001 hval_25
rename 	gb7001 hval_50
rename 	gb8001 hval_75
rename 	gbf001 rent_25
rename 	gbg001 rent_50
rename 	gbh001 rent_75
	
rename 	f9c001 nhu_owner
rename	f9c002 nhu_renter

replace rent_25=. if rent_25==99
replace rent_50=. if rent_50==99
replace rent_75=. if rent_75==99

replace hval_25=. if hval_25==9999
replace hval_50=. if hval_50==9999
replace hval_75=. if hval_75==9999

gen		tot_hunits = nhu_owner + nhu_renter

keep 	tract2000 hval_* rent_* nhu_* tot_hunits

tempfile tr00_values
save 	"`tr00_values'", replace
clear

/* Population data */

insheet using "`dinpop'/nhgis0070_ds146_2000_tract.csv", c
gen 	tractlen = strlen(gisjoin)
gen	 	tract2000 = gisjoin
replace	tract2000 = gisjoin + "00" if tractlen==12
drop 	tractlen

destring tract2000, replace i("G")
format  tract2000 %14.0f

keep if statea==6
keep if countya==37 | countya==59 | countya==65 | countya==71 | countya==111

rename 	fl5001 totpop

keep 	tract2000 totpop

/* Merging with other data */

merge 	1:1 tract2000 using "`tr00_values'"
drop 	_merge
merge 	1:1 tract2000 using "`tr00_resemp'"
drop 	_merge

foreach v of varlist hval_?? rent_?? med_reshhi {
	replace `v' = . if `v'==0
}

/* Merge with cross walk */
merge 	1:m tract2000 using "`dx'/Xwalk_2000Tract-1990Tract_sums", keepusing(tract1990 wt)
rename	tract1990 tract90
drop 	_merge

gen 	w_tothh		 = wt * tot_hunits
gen 	w_nhu_owner  = wt * nhu_owner
gen 	w_nhu_renter = wt * nhu_renter
gen 	w_resemp 	 = wt * resemp
gen 	w_totpop 	 = wt * totpop

tempfile tract00_all
save 	"`tract00_all'", replace

collapse (rawsum) w_nhu_owner (mean) hval_25 hval_50 hval_75 [aw=w_nhu_owner], by(tract90)
tempfile tract00_oo
save 	"`tract00_oo'", replace
clear 

use 	"`tract00_all'"
collapse (rawsum) w_nhu_renter (mean) rent_25 rent_50 rent_75 [aw=w_nhu_renter], by(tract90)
tempfile tract00_ro
save 	"`tract00_ro'", replace
clear

use 	"`tract00_all'"
collapse (rawsum) w_resemp (mean) med_reshhi [aw=w_resemp], by(tract90)
tempfile tract00_e0
save 	"`tract00_e0'", replace
clear

use 	"`tract00_all'"
collapse (rawsum) w_totpop w_tothh, by(tract90)

merge 1:1 tract90 using "`tract00_oo'"
drop _merge

merge 1:1 tract90 using "`tract00_ro'"
drop _merge

merge 1:1 tract90 using "`tract00_e0'"
drop _merge

foreach v of varlist w_totpop w_tothh w_nhu_owner w_nhu_renter hval_25 hval_50 hval_75 rent_25 rent_50 rent_75 w_resemp med_reshhi {
	replace `v' = round(`v')
}

rename 	w_totpop	totpop
rename 	w_tothh		 tothh
rename 	w_nhu_owner  nhu_owner
rename	w_nhu_renter nhu_renter
rename 	w_resemp 	 resemp

/* Top code to 657480 = round(500000*1.67/1.27) for housing*/
/* Top code to 1315 = round(1000*1.67/1.27) for housing*/
foreach n of numlist 25 50 75 {
	replace hval_`n' = 657480 if hval_`n'>657480 & !mi(hval_`n')
	replace rent_`n' = 1315 if rent_`n'>1315 & !mi(rent_`n')
}

gen 	year = 2000
rename 	tract90 tract1990

**********************
/* Append from 1990 */
**********************

append 	using "`tract90_all'"

order 	tract1990 year, first
sort 	tract1990 year

replace tothh = tot_hunits if year==1990
drop	tot_hunits

rename 	resemp empRES
rename	med_reshhi hhiRES

xtset tract1990 year
scatter hval_50 L10.hval_50
scatter rent_50 L10.rent_50

gen		hval_nTC = hval_50
replace hval_nTC = . if (hval_50==500001 & year==1990) | (hval_50==657480 & year==2000)

gen		rent_nTC = rent_50
replace rent_nTC = . if (rent_50==1001 & year==1990) | (rent_50==1315 & year==2000)

xtset tract1990 year
scatter hval_nTC L10.hval_nTC
scatter rent_nTC L10.rent_nTC

rename	tract1990 tract90

**********************
/* Adjust for inflation */
**********************

foreach v of varlist hval_25 hval_50 hval_75 rent_25 rent_50 rent_75 hval_nTC rent_nTC {
	replace `v'	= `v' * 1.67 		if year==1990
	replace `v'	= `v' * 1.27 		if year==2000
}

save "`dout'/housingdetail_panel_tracts", replace
clear

