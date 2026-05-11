** Makes housing detail data
clear

local 	din		"./data/TranspoDetails"
local 	dout	"./output/intermediate"
local 	dx		"./output/crosswalks"

*************************************
****** 1990 tract data **************
*************************************

/* Commuting */

insheet using "`din'/nhgis0084_csv/nhgis0084_ds123_1990_tract.csv", c
gen 	tractlen = strlen(gisjoin)
gen	 	tract1990 = gisjoin
replace	tract1990 = gisjoin + "00" if tractlen==12
drop 	tractlen

destring tract1990, replace i("G")
format  tract1990 %14.0f

keep if statea==6
keep if countya==37 | countya==59 | countya==65 | countya==71 | countya==111

egen 	totcomm = rowtotal(e3u*)
keep 	tract1990 totcomm year e3u*

gen 	n_drive = e3u001 + e3u002
gen		n_alltrans = e3u003 + e3u004 + e3u005 + e3u006 + e3u007 + e3u008
gen		n_bus = e3u003
gen 	n_metro = e3u005

drop 	e3u*

tempfile tr90_totcomm
save 	"`tr90_totcomm'", replace
clear


*************************************
****** 2000 block group data ********
*************************************

/* Commuting high level */

insheet using "`din'/nhgis0084_csv/nhgis0084_ds151_2000_tract.csv", c
gen 	tractlen = strlen(gisjoin)
gen	 	tract2000 = gisjoin
replace	tract2000 = gisjoin + "00" if tractlen==12
drop 	tractlen

destring tract2000, replace i("G")
format  tract2000 %14.0f

keep if statea==6
keep if countya==37 | countya==59 | countya==65 | countya==71 | countya==111

egen 	totcomm = rowtotal(gj9*)
keep 	tract2000 totcomm year gj9*

tempfile tr00_totcomm
save 	"`tr00_totcomm'", replace
clear

/* Commuting transit */

insheet using "`din'/nhgis0085_csv/nhgis0085_ds151_2000_tract.csv", c
gen 	tractlen = strlen(gisjoin)
gen	 	tract2000 = gisjoin
replace	tract2000 = gisjoin + "00" if tractlen==12
drop 	tractlen

destring tract2000, replace i("G")
format  tract2000 %14.0f

keep if statea==6
keep if countya==37 | countya==59 | countya==65 | countya==71 | countya==111

egen 	tottrans = rowtotal(gkb*)
keep 	tract2000 tottrans year gkb*

merge 1:1 tract2000 using "`tr00_totcomm'"
drop	_merge 


gen 	n_drive = gj9001
gen		n_alltrans = gj9002
gen		n_bus = gkb001
gen 	n_metro = gkb003

drop 	gj9* gkb*

sum totcomm
sum totcomm [aw=totcomm]

/* Merge with cross walk */
merge 	1:m tract2000 using "`dx'/Xwalk_2000Tract-1990Tract_sums", keepusing(tract1990 wt)
rename	tract1990 tract90
drop 	_merge

foreach var of varlist n_* tot* {
	replace `var' = `var'*wt
}

collapse (sum) n_* tot*, by(tract90)

sum totcomm
sum totcomm [aw=totcomm]

rename tract90 tract1990
gen year=2000

**********************
/* Append from 1990 */
**********************

append 	using "`tr90_totcomm'"

order 	tract1990 year, first
sort 	tract1990 year

rename	tract1990 tract90

rename tract90 tract_h
gen 	yr = 0 if year==1990
replace	yr = 1 if year==2000
drop year tottrans

save "`dout'/transitdetail_panel_restracts", replace
clear

