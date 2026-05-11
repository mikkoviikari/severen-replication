** Bring in Land Use data for 1990, 1993 and 2001

clear

************************
/* Prep land use data */
************************

/* Land use data for all years */

insheet using "./output/intermediate/tracts90_LU.csv", c

gen 	tractlen = strlen(gisjoin)
gen	 	tract1990 = gisjoin
replace	tract1990 = gisjoin + "00" if tractlen==12
drop 	tractlen

destring tract1990, replace i("G")
format  tract1990 %14.0f

keep if nhgiscty==370 | nhgiscty==590 | nhgiscty==650 | nhgiscty==710 | nhgiscty==1110 

rename	area_ area_lu

keep	tract1990 area_lu lu90 lu93 lu01 lu05

tempfile lu_master
save "`lu_master'", replace

/* Get 1990 data */
collapse (sum) area_lu, by(lu90 tract1990)

bys tract1990: egen	totarea = total(area_lu)
gen		year = 1990

reshape wide area, i(tract1990) j(lu90)

tempfile lu_1990
save "`lu_1990'", replace
clear

/* Get 1993 data */
use 	"`lu_master'"
collapse (sum) area, by(lu93 tract1990)

bys tract1990: egen	totarea = total(area)
gen		year = 1993

reshape wide area, i(tract1990) j(lu93)

tempfile lu_1993
save "`lu_1993'", replace
clear

/* Get 2001 data */
use 	"`lu_master'"
collapse (sum) area, by(lu01 tract1990)

bys tract1990: egen	totarea = total(area)
gen		year = 2001

reshape wide area, i(tract1990) j(lu01)

tempfile lu_2001
save "`lu_2001'", replace
clear

/* Get 2005 data */
use 	"`lu_master'"
collapse (sum) area, by(lu05 tract1990)

bys tract1990: egen	totarea = total(area)
gen		year = 2005

reshape wide area, i(tract1990) j(lu05)

tempfile lu_2005
save "`lu_2005'", replace

/* Append */

append using "`lu_1990'"
append using "`lu_1993'"
append using "`lu_2001'"

order 	tract1990 year totarea, first
sort 	tract1990 year

egen	checkarea = rowtotal(area_*)

order 	tract1990 year totarea checkarea, first

***********************
/* Make useful codes */
***********************

keep if year==1990 | year==2001
replace	year = 2000 if year==2001

egen	area_res 		= rowtotal(area_lu11??)
egen	area_comPmil	= rowtotal(area_lu12??)
egen	area_mil		= rowtotal(area_lu127?)
egen	area_ind		= rowtotal(area_lu13??)
egen	area_transutil	= rowtotal(area_lu14??)

egen 	area_prod		= rowtotal(area_comPmil area_ind area_lu1500)
egen	area_amen		= rowtotal(area_lu18??)
egen	area_constr		= rowtotal(area_lu17??)

gen 	adjProd 		= 0
replace adjProd 		= 0.5*area_lu1600 if area_lu1600!=.
replace adjProd 		= adjProd - area_mil if area_mil!=.

gen 	adjRes 			= 0
replace adjRes 			= 0.5*area_lu1600 if area_lu1600!=.

gen		area_resAll 	= area_res + adjRes
gen		area_prodAll	= area_prod + adjProd

egen	area_consmptn	= rowtotal(area_lu122?)
replace area_consmptn	= area_consmptn + area_lu1232 if area_lu1232!=.

keep 	tract1990 year area_prodAll area_resAll area_amen area_consmptn area_constr	totarea
drop	area_amen

rename 	area_prodAll 	land_prod
rename	area_resAll 	land_res
rename 	area_consmptn	land_consmptn
rename 	area_constr		land_constr

save "./output/intermediate/landusepanel", replace
clear

