** Make crosswalked flows 2000 CTPP
clear
local 	din 	"./data/CTPP/2000"
local 	dout	"./output/intermediate"
local 	dx		"./output/crosswalks"

insheet using "`din'/351437754_T_CTPP2000_PART3_STATEMPO.csv", c

keep if county==37 | county==59 | county==65 | county==71 | county==111
keep if qpowco==37 | qpowco==59 | qpowco==65 | qpowco==71 | qpowco==111
keep 	county qpowco tract qpowtract t301c1-t306c18 t308c?_1

gen double tract2000_D = 600000000000 + qpowco*10000000 + qpowtract
gen double tract2000_O = 600000000000 + county*10000000 + tract
format 	tract2000_D tract2000_O %14.0f

gen 	flow_carpool_geq3 = t306c4 + t306c5 + t306c6 + t306c7
gen 	flow_transit 	  = t306c9 + t306c10 + t306c11 + t306c12
gen		flow_other 		  = t306c13 + t306c14 + t306c15 + t306c16 + t306c17
rename 	t301c1 	flow_all
rename  t306c2 	flow_drivealone
rename  t306c3 	flow_carpool_eq2
rename  t306c8 	flow_bus
rename  t306c18	flow_workhome

order 	county qpowco tract qpowtract flow_all flow_drivealone flow_carpool_eq2 ///
			flow_carpool_geq3 flow_bus flow_transit flow_other flow_workhome, first

drop t306*

rename 	t308c1_1 travtime_all
rename 	t308c2_1 travtime_drivealone
rename 	t308c3_1 travtime_carpool_eq2
rename 	t308c4_1 travtime_carpool_geq3
rename 	t308c5_1 travtime_bus
rename 	t308c6_1 travtime_transit
rename 	t308c7_1 travtime_other
rename 	t308c8_1 travtime_workhome

drop if flow_all==0
drop county tract qpowco qpowtract

local 	varticks all drivealone carpool_eq2 carpool_geq3 bus transit other workhome

foreach v of local varticks {
	sum flow_`v' [aw=flow_`v']
	sum travtime_`v' [aw=flow_`v']
}
* This gives 6,512,355 workers, average travel time 28.29 minutes (sd 21.57)

rename 	tract2000_D tract2000
joinby 	tract2000 using "`dx'/Xwalk_2000Tract-1990Tract_sums"

rename 	tract2000 tract2000_D
rename 	tract1990 tract1990_D
rename 	wt wt_D

rename 	tract2000_O tract2000
joinby 	tract2000 using "`dx'/Xwalk_2000Tract-1990Tract_sums"

rename 	tract2000 tract2000_O
rename 	tract1990 tract1990_O
rename 	wt wt_O

gen 	wt = wt_O*wt_D

drop nhgisst nhgiscty gisjoin2 shape_area shape_len nhgisst1 nhgiscty1 gisjoin21 shape_area1 shape_len1 area iarea

local 	flowvars flow_all flow_drivealone flow_carpool_eq2 flow_carpool_geq3 flow_bus flow_transit flow_other flow_workhome
local 	varticks all drivealone carpool_eq2 carpool_geq3 bus transit other workhome
local 	timevars travtime_all travtime_drivealone travtime_carpool_eq2 travtime_carpool_geq3 travtime_bus travtime_transit travtime_other travtime_workhome

foreach v of varlist `flowvars' {
	gen wt`v' = wt * `v'
}

foreach v of local varticks {
	replace travtime_`v' = . if travtime_`v'==0 & flow_`v'==0
}

tempfile masterflow
save "`masterflow'", replace

local i = 1

foreach v of local varticks {
	collapse (rawsum) wtflow_`v' (mean) travtime_`v' [aw=wtflow_`v'] , by(tract1990_O tract1990_D)
	if `i'==1 {
		save "`dout'/flows2000ctpp", replace
		clear
	}
	else {
		tempfile varcollapsed
		save "`varcollapsed'", replace
		clear
		
		use "`dout'/flows2000ctpp"
		merge 1:1 tract1990_O tract1990_D using "`varcollapsed'", keepusing(wtflow_`v' travtime_`v')
		drop if _merge==2
		drop _merge
		
		save "`dout'/flows2000ctpp", replace
		clear
	}
	
	local i = `i' + 1
	display `i'
	
	use "`masterflow'"
}
 
clear
use "`dout'/flows2000ctpp"

local 	varticks all drivealone carpool_eq2 carpool_geq3 bus transit other workhome
foreach v of local varticks {
	sum wtflow_`v' [aw=wtflow_`v']
	sum travtime_`v' [aw=wtflow_`v']
}

gen yr = 2000

sum wtflow_all [aw=wtflow_all]
* This gives 6,510,572 workers, a loss of about 0.0002%
* Total pairs: 464,469

sum wtflow_all if wtflow_all>=1 [aw=wtflow_all]
* Retains 99.8% of workers, 6,495,147
* Total pairs: 394,090 

sum wtflow_all if wtflow_all>=2.5 [aw=wtflow_all]
* Retains 99.5% of workers, 6,479,686
* Total pairs: 384,692 

save "`dout'/flows2000ctpp", replace
clear
