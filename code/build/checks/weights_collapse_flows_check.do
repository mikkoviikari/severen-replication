* Make crosswalked flows 2000 CTPP
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

rename 	t301c1 	flow_all
rename 	t308c1_1 travtime_all

keep flow_all travtime_all tract2000_D tract2000_O

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


local 	flowvars flow_all 
local 	varticks all 
local 	timevars travtime_all 

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
	collapse (rawsum) wtflow_`v' (mean) travtime_`v' [iw=wtflow_`v'] , by(tract1990_O tract1990_D)
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

local 	varticks all 
foreach v of local varticks {
	sum wtflow_`v' 
	sum travtime_`v' 
}