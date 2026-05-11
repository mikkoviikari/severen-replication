** Makes wage and employment data from CTPP Part 2 for 1990 and 2000
clear

local 	din90 	"./data/CTPP/1990"
local 	din00 	"./data/CTPP/2000"
local 	dout	"./output/intermediate"
local 	dx		"./output/crosswalks"

*************************************************
/* Prep wage data for both years (BG for 2000) */
*************************************************

/* Median Data, 1990 */
insheet using "`din90'/833855872_T_CTPP_URBAN_2\833855872_U211.csv"

keep if countyw==37 | countyw==59 | countyw==65 | countyw==71 | countyw==111

gen 	double tract1990 = 600000000000 + countyw*10000000 + taztrw
format 	tract1990 %14.0f

gen 	wagePOW = u211_01

keep 	placew tract1990 wagePOW

tempfile wage90_med   			
save 	"`wage90_med'", replace    
clear

/* Average Wage, 1990 */
insheet using "`din90'/833855872_T_CTPP_URBAN_2\833855872_U212.csv"

keep if countyw==37 | countyw==59 | countyw==65 | countyw==71 | countyw==111

gen 	double tract1990 = 600000000000 + countyw*10000000 + taztrw
format 	tract1990 %14.0f
gen 	wagePOW_ave = u212_01

keep 	placew tract1990 wagePOW_ave

merge 	1:1 tract1990 place using "`wage90_med'"
drop 	_merge

tempfile wage90   			
save 	"`wage90'", replace    
clear

/* Median Data, 2000 */
insheet using "`din00'/1027008915_T_CTPP2000_PART2_TAB47TO66/1027008915_P2-047.csv", c

keep if county==37 | county==59 | county==65 | county==71 | county==111

gen 	double bg2000 = 6000000000000 + county*100000000 + tract*10 + blkgrp
format 	bg2000 %14.0f

rename 	tab47x1 wagePOW
keep 	bg2000 wagePOW

tempfile wage00_med   			
save 	"`wage00_med'", replace    
clear

/* Average Wage, 2000 */
insheet using "`din00'/1027008915_T_CTPP2000_PART2_TAB47TO66/120787376_P2-063.csv", c

keep if county==37 | county==59 | county==65 | county==71 | county==111

gen 	double bg2000 = 6000000000000 + county*100000000 + tract*10 + blkgrp
format 	bg2000 %14.0f

rename 	tab63x1 wagePOW_agg
keep 	bg2000 wagePOW_agg

merge 	1:1 bg2000 using "`wage00_med'"
drop 	_merge

tempfile wage00   			
save 	"`wage00'", replace    
clear


*******************************************************
/* Prep employment data for both years (BG for 2000) */
*******************************************************

/* Employment, 2000 */
insheet using "`din00'/1027008915_T_CTPP2000_PART2_TAB1TO17\1027008915_P2-004.csv", c

keep if county==37 | county==59 | county==65 | county==71 | county==111

gen 	double bg2000 = 6000000000000 + county*100000000 + tract*10 + blkgrp
format 	bg2000 %14.0f

rename 	tab4x1 empPOW
keep 	bg2000 empPOW

/* Merge with wage data */
merge 	1:1 bg2000 using "`wage00'"
drop 	_merge

gen		wagePOW_ave = wagePOW_agg/empPOW

sum 	empPOW [aw=empPOW]
sum 	wagePOW [aw=empPOW]
sum 	wagePOW_ave [aw=empPOW]

/* Translate to 1990 Geographies */
merge 	1:m bg2000 using "`dx'/Xwalk_2000BG-1990Tract_sums", keepusing(wt tract1990)
drop if _merge!=3
drop 	_merge
order	bg2000, first

gen 	w_empPOW = wt * empPOW

collapse (rawsum) w_empPOW (sum) wagePOW_agg (mean) wagePOW wagePOW_ave [aw=w_empPOW], by(tract1990)
gen 	wagePOW_ave2 = wagePOW_agg/w_empPOW
drop	wagePOW_agg

rename 	w_empPOW empPOW

sum 	empPOW [aw=empPOW]
sum 	wagePOW [aw=empPOW]
sum 	wagePOW_ave [aw=empPOW]
sum 	wagePOW_ave2 [aw=empPOW]

replace empPOW = round(empPOW)
replace wagePOW = round(wagePOW)
replace wagePOW_ave = round(wagePOW_ave)
drop 	wagePOW_ave2

gen 	yr = 1

compress

tempfile wagempPOW2000  			/* create a temporary file */
save 	"`wagempPOW2000'", replace 	/* save memory into the temporary file */
clear

/* Employment, 1990 */
insheet using "`din90'/833855872_T_CTPP_URBAN_2/833855872_U203.csv", c
keep if countyw==37 | countyw==59 | countyw==65 | countyw==71 | countyw==111

gen 	double tract1990 = 600000000000 + countyw*10000000 + taztrw
format 	tract1990 %14.0f

gen 	empPOW = u203_0101
gen		emp_manu = u203_0105 + u203_0106

keep 	placew tract1990 empPOW emp_manu

merge 	1:1 placew tract1990 using "`wage90'"
drop 	_merge

sum empPOW 		[aw=empPOW], d
sum wagePOW 	[aw=empPOW], d
sum wagePOW_ave [aw=empPOW], d

replace wagePOW = . 	if wagePOW==.
replace wagePOW_ave = . if wagePOW_ave==.

collapse (rawsum) empPOW  emp_manu (mean) wagePOW wagePOW_ave [aw=empPOW], by(tract1990)
gen 	yr = 0

gen 	p_manu90 = emp_manu/empPOW
drop	emp_manu

** Bring all POW data together, both years
append 	using "`wagempPOW2000'"

bys yr: sum empPOW 		[aw=empPOW], d
bys yr: sum wagePOW 	[aw=empPOW], d
bys yr: sum wagePOW_ave [aw=empPOW], d

replace wagePOW 	= wagePOW * 1.67 		if yr==0
replace wagePOW 	= wagePOW * 1.27 		if yr==1
replace wagePOW_ave = wagePOW_ave * 1.67 	if yr==0
replace wagePOW_ave = wagePOW_ave * 1.27 	if yr==1

bys yr: sum empPOW 		[aw=empPOW], d
bys yr: sum wagePOW 	[aw=empPOW], d
bys yr: sum wagePOW_ave [aw=empPOW], d

** Note, one high value wagePOW in year 1990 has 9 employees and no 2000 values: 600370297199
		
save "`dout'/empPOW_all", replace 
clear
