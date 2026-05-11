****************************
/* Prep county subdiv data */
****************************
clear

insheet using "./output/crosswalks/tracts90CountySubs.csv", c

gen 	tractlen = strlen(gisjoin1)
gen	 	tract1990 = gisjoin1
replace	tract1990 = gisjoin1 + "00" if tractlen==12
drop 	tractlen

destring tract1990, replace i("G")
format  tract1990 %14.0f

keep if nhgiscty==370 | nhgiscty==590 | nhgiscty==650 | nhgiscty==710 | nhgiscty==1110 

keep 	tract1990 nhgiscty cousub90
rename	nhgiscty 	county
rename 	cousub90	cousub	

local 	addobs = _N + 3
set obs `addobs'

replace tract1990 = 600370702900 if _n==2551
replace county = 370 if _n==2551
replace cousub = 91705 if _n==2551

replace tract1990 = 600370599100 if _n==2552
replace county = 370 if _n==2552
replace cousub = 91706 if _n==2552

replace tract1990 = 601110003694 if _n==2553
replace county = 1110 if _n==2553
replace cousub = 92310 if _n==2553

replace county = county/10

compress 
save "./output/crosswalks/subcounty2tracts", replace
clear
