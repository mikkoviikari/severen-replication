** Make flows 1990 CTPP
clear
local 	din 	"./data/CTPP/1990"
local 	dout	"./output/intermediate"

insheet using "`din'/351437754_T_CTPP_URBAN_3.csv", c

keep if sumlevr==992 & sumlevw==992
keep if stater==6 & statew==6
keep if countyr==37 | countyr==59 | countyr==65 | countyr==71 | countyr==111
keep if countyw==37 | countyw==59 | countyw==65 | countyw==71 | countyw==111

keep countyr countyw taztrw taztrr u301_01* u307_01*

gen double tract90_D = 600000000000 + countyw*10000000 + taztrw
gen double tract90_O = 600000000000 + countyr*10000000 + taztrr
format tract90_D tract90_O %14.0f

drop countyr countyw taztrr taztrw

** CHECKS THESE VALUES; COMPARE below **
foreach n of numlist 1/9 {
	sum u301_010`n' [aw=u301_010`n']
	sum u307_010`n' [aw=u301_010`n']
}

foreach n of numlist 10/19 {
	sum u301_01`n' [aw=u301_01`n']
	sum u307_01`n' [aw=u301_01`n']
}
**

*First, need to deal with census tracts that span places*

foreach n of numlist 1/9 {
	gen uWgtSum_0`n' = u301_010`n' * u307_010`n'
}
foreach n of numlist 10/19 {
	gen uWgtSum_`n' = u301_01`n' * u307_01`n'
}

* This gets rid of cities intersected with tracts
collapse (sum) u301_0101-u301_0119 uWgtSum_01-uWgtSum_19, by(tract90_D tract90_O)

foreach n of numlist 1/9 {
	gen u307_010`n' = uWgtSum_0`n' / u301_010`n'
	replace u307_010`n'=0 if u307_010`n'==.
}
foreach n of numlist 10/19 {
	gen u307_01`n' = uWgtSum_`n' / u301_01`n'
	replace u307_01`n'=0 if u307_01`n'==.
}
drop uWgtSum_*

** CHECKS THESE VALUES; COMPARE to above **

foreach n of numlist 1/9 {
	sum u301_010`n' [aw=u301_010`n']
	sum u307_010`n' [aw=u301_010`n']
}

foreach n of numlist 10/19 {
	sum u301_01`n' [aw=u301_01`n']
	sum u307_01`n' [aw=u301_01`n']
}
**

gen 	wtflow_all 		= u301_0101
gen 	wtflow_drivealone = u301_0102
gen 	wtflow_carpool_eq2 = u301_0103
gen 	wtflow_carpool_geq3 = u301_0104 + u301_0105 + u301_0106 + u301_0107 + ///
							  u301_0108 + u301_0109
gen 	wtflow_bus 		= u301_0110
gen 	wtflow_transit 	= u301_0111 + u301_0112 + u301_0113 + u301_0114
gen 	wtflow_other 	= u301_0115 + u301_0116 + u301_0117 + u301_0118 + u301_0119

*Need to pre-create weighted average time for transit uses*
gen 	travtime_all 		= u307_0101
gen 	travtime_drivealone = u307_0102
gen 	travtime_carpool_eq2 = u307_0103
gen 	travtime_carpool_geq3 = (u301_0104*u307_0104 + u301_0105*u307_0105 + ///
								 u301_0106*u307_0106 + u301_0107*u307_0107 + ///
								 u301_0108*u307_0108 + u301_0109*u307_0109) ///
								 / wtflow_carpool_geq3
gen 	travtime_bus 		= u307_0110
gen 	travtime_transit 	= (u301_0111*u307_0111 + u301_0112*u307_0112 + ///
							   u301_0113*u307_0113 + u301_0114*u307_0114) ///
							   / wtflow_transit
gen 	travtime_other 		= (u301_0115*u307_0115 + u301_0116*u307_0116 + ///
							   u301_0117*u307_0117 + u301_0118*u307_0118 + ///
							   u301_0119*u307_0119) / wtflow_other

drop u30*

local 	varticks all drivealone carpool_eq2 carpool_geq3 bus transit other
foreach v of local varticks {
	replace travtime_`v' = . if travtime_`v'==0 & wtflow_`v'==0
	replace travtime_`v' = travtime_`v'/10
}

/* Interesting plots
gen lflow_all = ln(wtflow_all)
scatter wtflow_all travtime_all
scatter lflow_all travtime_all
hist travtime_all [aw=wtflow_all]
*/

sum wtflow_all [aw=wtflow_all]

rename tract90_O tract_h
rename tract90_D tract_w

save "`dout'/flows1990ctpp", replace
clear
