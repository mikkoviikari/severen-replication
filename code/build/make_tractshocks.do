* Create local demand shocks for California, using non CA data

clear

local 	dCTPP	"D:\Current_Research\JMP\Data\CTPP\1990"
local	dout 	"D:\Current_Research\JMP\Analysis\Data_Storage"

/*************************************
** Create changes in national aves, **
** excluding California 			**
*************************************/

use 	"./data/IPUMS/ipums_1980-0610_all"

keep if year==1990 | year==2000

drop if statefip==6

drop if incwage==0

gen 	indCTPP_sic = 0
*replace indCTPP_sic = 1 if ind1990>= & ind1990<=

replace indCTPP_sic = 2 	if ind1990>=0 	& ind1990<=39		// Ag Forestry Fisheries
replace indCTPP_sic = 3 	if ind1990>=40 	& ind1990<=59		// Mining
replace indCTPP_sic = 4 	if ind1990>=60 	& ind1990<=99		// Construction
replace indCTPP_sic = 5 	if ind1990>=100 & ind1990<=229		// Manufacturing, non-durable
replace indCTPP_sic = 6 	if ind1990>=230 & ind1990<=399		// Manufacturing, durable
replace indCTPP_sic = 7	 	if ind1990>=400 & ind1990<=439		// Transportation
replace indCTPP_sic = 8 	if ind1990>=440 & ind1990<=499		// Com and other Pub Utilities		
replace indCTPP_sic = 9 	if ind1990>=500 & ind1990<=579		// Wholesale trade
replace indCTPP_sic = 10 	if ind1990>=580 & ind1990<=699		// Retail trad
replace indCTPP_sic = 11	if ind1990>=700 & ind1990<=720		// Finance Insur Real Estate
replace indCTPP_sic = 12 	if ind1990>=721 & ind1990<=760 		// Business and Repair
replace indCTPP_sic = 13 	if ind1990>=761 & ind1990<=799		// Personal services
replace indCTPP_sic = 14 	if ind1990>=800 & ind1990<=811		// Entertainment recreation
replace indCTPP_sic = 15 	if ind1990>=812 & ind1990<=840		// Health
replace indCTPP_sic = 16 	if ind1990>=842 & ind1990<=860		// Educational 
replace indCTPP_sic = 17 	if ind1990>=861 & ind1990<=899		// Other professional
replace indCTPP_sic = 17 	if ind1990==841						// Other professional
replace indCTPP_sic = 18 	if ind1990>=900 & ind1990<=939		// Public Admin
replace indCTPP_sic = 19 	if ind1990>=940 & ind1990<=960		// Armed Forces

collapse (mean) wage_AVE=incwage (rawsum) count_TOT=perwt [fw=perwt], by(year indCTPP_sic)

recast 	long count_TOT
format 	count_TOT %10.0gc
sort 	indCTPP_sic year

replace wage_AVE = wage_AVE*1.67 if year==1990
replace wage_AVE = wage_AVE*1.27 if year==2000

xtset indCTPP_sic year

gen 	cwage_90 = .
replace cwage_90 = ((wage_AVE - L10.wage_AVE) / L10.wage_AVE) if year==2000
gen 	cemp_90 = .
replace cemp_90 = ((count_TOT - L10.count_TOT) / L10.count_TOT) if year==2000

replace cwage_90=0 	if year==1990
replace cemp_90=0 	if year==1990
keep 	year indCTPP_sic cwage_90 cemp_90

reshape wide cwage_90 cemp_90, i(year) j(indCTPP_sic)
rename 	year yr

tempfile shocks   
save 	"`shocks'"  
clear


/*************************************
** Create changes including NorCal, **
** excluding SoCal and nearby ctys  **
*************************************/

use 	"./data/IPUMS/ipums_1980-0610_all"

keep if year==1990 | year==2000

drop if metarea==0 & statefip==6 	// Drop out-of-MSA in CA
drop if metarea==68					// Drop Bakersfield
drop if metarea==448				// Drop LA
drop if metarea==678				// Drop Riverside
drop if metarea==732				// Drop San Diego
drop if metarea==747				// Drop Santa Barbara
drop if metarea==873				// Drop Ventura

drop if incwage==0

gen 	indCTPP_sic = 0
*replace indCTPP_sic = 1 if ind1990>= & ind1990<=

replace indCTPP_sic = 2 	if ind1990>=0 	& ind1990<=39		// Ag Forestry Fisheries
replace indCTPP_sic = 3 	if ind1990>=40 	& ind1990<=59		// Mining
replace indCTPP_sic = 4 	if ind1990>=60 	& ind1990<=99		// Construction
replace indCTPP_sic = 5 	if ind1990>=100 & ind1990<=229		// Manufacturing, non-durable
replace indCTPP_sic = 6 	if ind1990>=230 & ind1990<=399		// Manufacturing, durable
replace indCTPP_sic = 7	 	if ind1990>=400 & ind1990<=439		// Transportation
replace indCTPP_sic = 8 	if ind1990>=440 & ind1990<=499		// Com and other Pub Utilities		
replace indCTPP_sic = 9 	if ind1990>=500 & ind1990<=579		// Wholesale trade
replace indCTPP_sic = 10 	if ind1990>=580 & ind1990<=699		// Retail trad
replace indCTPP_sic = 11	if ind1990>=700 & ind1990<=720		// Finance Insur Real Estate
replace indCTPP_sic = 12 	if ind1990>=721 & ind1990<=760 		// Business and Repair
replace indCTPP_sic = 13 	if ind1990>=761 & ind1990<=799		// Personal services
replace indCTPP_sic = 14 	if ind1990>=800 & ind1990<=811		// Entertainment recreation
replace indCTPP_sic = 15 	if ind1990>=812 & ind1990<=840		// Health
replace indCTPP_sic = 16 	if ind1990>=842 & ind1990<=860		// Educational 
replace indCTPP_sic = 17 	if ind1990>=861 & ind1990<=899		// Other professional
replace indCTPP_sic = 17 	if ind1990==841						// Other professional
replace indCTPP_sic = 18 	if ind1990>=900 & ind1990<=939		// Public Admin
replace indCTPP_sic = 19 	if ind1990>=940 & ind1990<=960		// Armed Forces

collapse (mean) wage_AVE=incwage (rawsum) count_TOT=perwt [fw=perwt], by(year indCTPP_sic)

recast 	long count_TOT
format 	count_TOT %10.0gc
sort 	indCTPP_sic year

replace wage_AVE = wage_AVE*1.67 if year==1990
replace wage_AVE = wage_AVE*1.27 if year==2000

xtset 	indCTPP_sic year

gen 	cwage_CA90 = .
replace cwage_CA90 = ((wage_AVE - L10.wage_AVE) / L10.wage_AVE) if year==2000
gen 	cemp_CA90 = .
replace cemp_CA90 = ((count_TOT - L10.count_TOT) / L10.count_TOT) if year==2000

replace cwage_CA90=0 	if year==1990
replace cemp_CA90=0 	if year==1990
keep 	year indCTPP_sic cwage_CA90 cemp_CA90

reshape wide cwage_CA90 cemp_CA90, i(year) j(indCTPP_sic)
rename 	year yr

tempfile shocksCA    /* create a temporary file */
save 	"`shocksCA'"      /* save memory into the temporary file */
clear


**** Ex ante workers by industry ********
*****************************************

insheet using "./data/CTPP/1990/833855872_T_CTPP_URBAN_2/833855872_U203.csv", c
keep if countyw==37 | countyw==59 | countyw==65 | countyw==71 | countyw==111

foreach n of numlist 1/9 {
	rename u203_010`n' pop_POW0`n'
}
foreach n of numlist 10/19 {
	rename u203_01`n' pop_POW`n'
}

keep 	placew countyw taztrw pop_POW*
collapse (sum) pop_POW*, by(taztrw countyw) // Deals with tract remnants crossing Places

gen 	double tract_w = 600000000000 + 10000000*countyw + taztrw
format 	tract_w %12.0f

drop 	countyw taztrw

gen 	yr1 = 1990
gen 	yr2 = 2000

reshape long yr, i(tract_w) j(year)
drop 	year
order 	tract_w yr, first


**** Merge together **********
******************************

merge 	m:1 yr using "`shocks'"
drop 	_merge
sort 	tract_w yr

foreach q of numlist 2/9 {
	gen s90_ind_0`q' = pop_POW0`q'/pop_POW01
}
foreach q of numlist 10/19 {
	gen s90_ind_`q' = pop_POW`q'/pop_POW01
} 

gen 	M_w90 = s90_ind_02*cwage_902 + s90_ind_03*cwage_903 + s90_ind_04*cwage_904 + ///
				s90_ind_05*cwage_905 + s90_ind_06*cwage_906 + s90_ind_07*cwage_907 + ///
				s90_ind_08*cwage_908 + s90_ind_09*cwage_909 + s90_ind_10*cwage_9010 + ///
				s90_ind_11*cwage_9011 + s90_ind_12*cwage_9012 + s90_ind_13*cwage_9013 + ///
				s90_ind_14*cwage_9014 + s90_ind_15*cwage_9015 + s90_ind_16*cwage_9016 + ///
				s90_ind_17*cwage_9017 + s90_ind_18*cwage_9018 + s90_ind_19*cwage_9019

gen 	M_e90 = s90_ind_02*cemp_902 + s90_ind_03*cemp_903 + s90_ind_04*cemp_904 + ///
				s90_ind_05*cemp_905 + s90_ind_06*cemp_906 + s90_ind_07*cemp_907 + ///
				s90_ind_08*cemp_908 + s90_ind_09*cemp_909 + s90_ind_10*cemp_9010 + ///
				s90_ind_11*cemp_9011 + s90_ind_12*cemp_9012 + s90_ind_13*cemp_9013 + ///
				s90_ind_14*cemp_9014 + s90_ind_15*cemp_9015 + s90_ind_16*cemp_9016 + ///
				s90_ind_17*cemp_9017 + s90_ind_18*cemp_9018 + s90_ind_19*cemp_9019			

merge 	m:1 yr using "`shocksCA'"
drop	 _merge
sort 	tract_w yr

gen 	M_w90CA = s90_ind_02*cwage_CA902 + s90_ind_03*cwage_CA903 + s90_ind_04*cwage_CA904 + ///
				s90_ind_05*cwage_CA905 + s90_ind_06*cwage_CA906 + s90_ind_07*cwage_CA907 + ///
				s90_ind_08*cwage_CA908 + s90_ind_09*cwage_CA909 + s90_ind_10*cwage_CA9010 + ///
				s90_ind_11*cwage_CA9011 + s90_ind_12*cwage_CA9012 + s90_ind_13*cwage_CA9013 + ///
				s90_ind_14*cwage_CA9014 + s90_ind_15*cwage_CA9015 + s90_ind_16*cwage_CA9016 + ///
				s90_ind_17*cwage_CA9017 + s90_ind_18*cwage_CA9018 + s90_ind_19*cwage_CA9019

gen 	M_e90CA = s90_ind_02*cemp_CA902 + s90_ind_03*cemp_CA903 + s90_ind_04*cemp_CA904 + ///
				s90_ind_05*cemp_CA905 + s90_ind_06*cemp_CA906 + s90_ind_07*cemp_CA907 + ///
				s90_ind_08*cemp_CA908 + s90_ind_09*cemp_CA909 + s90_ind_10*cemp_CA9010 + ///
				s90_ind_11*cemp_CA9011 + s90_ind_12*cemp_CA9012 + s90_ind_13*cemp_CA9013 + ///
				s90_ind_14*cemp_CA9014 + s90_ind_15*cemp_CA9015 + s90_ind_16*cemp_CA9016 + ///
				s90_ind_17*cemp_CA9017 + s90_ind_18*cemp_CA9018 + s90_ind_19*cemp_CA9019			
	
sum 	M_* 	if yr==2000, d

drop 	pop_POW??

rename *90* **

rename 	M_w M_w90
rename 	M_e M_e90
rename 	M_wCA M_w90CA
rename 	M_eCA M_e90CA

save "./output/intermediate/shocks_byindustry", replace

drop 	s_ind* cwage_* cemp_* cwage_CA* cemp_CA*			

save "./output/intermediate/shocks_all1990-2000", replace

clear
