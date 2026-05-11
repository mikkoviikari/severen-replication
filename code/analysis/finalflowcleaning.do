*finalflowcleaning

xtset pairid yr

gen 	fut_tran00_h  = F.tran00_h
gen		fut_tran00_w  = F.tran00_w
gen		fut_tran00_cc = F.tran00_cc

gen 	fut_tran05_h  = F.tran05_h
gen		fut_tran05_w  = F.tran05_w
gen		fut_tran05_cc = F.tran05_cc

gen 	LA = 0
replace	LA = 1 if county_h==37 & county_w==37

/* Line interactions prep */

gen 	blue_cc 	= blueline1999_h * blueline1999_w * tran05_cc
gen 	red_cc 		= redline1999_h * redline1999_w * tran05_cc
gen 	purple_cc 	= purpleline1999_h * purpleline1999_w * tran05_cc
gen 	green_cc 	= greenline1999_h * greenline1999_w * tran05_cc
gen 	rp_cc 		= (red_cc==1 | purple_cc==1)
gen 	same_line 	= (rp_cc==1 | blue_cc==1 | green_cc==1)

tab 	blue_cc tran05_cc if yr==1
tab 	red_cc tran05_cc if yr==1
tab 	purple_cc tran05_cc if yr==1
tab 	green_cc tran05_cc if yr==1
tab 	rp_cc tran05_cc  if yr==1
tab 	same_line tran05_cc  if yr==1

local 	nums 00 02 25

foreach n of local nums {
	gen	byte 	tt`n'_cc_same = tt`n'_cc
	replace 	tt`n'_cc_same = 0 if same_line!=1

	gen	byte	tt`n'_cc_nots = tt`n'_cc
	replace 	tt`n'_cc_nots = 0 if same_line==1
}

gen 	tranccsample = 1 if tran05_cc==1
replace tranccsample = 1 if F.tran05_cc==1

gen 	evertreated05_cc = 1 if ( (distance2015_h<500 & distance2015_w<500) | ///
									(cent_distance2015_h<500 & distance2015_w<500) | ///
									(distance2015_h<500 & cent_distance2015_w<500) | ///
									(cent_distance2015_h<500 & cent_distance2015_w<500))
gen 	evertreated10_cc = 1 if ( (distance2015_h<1000 & distance2015_w<1000) | ///
									(cent_distance2015_h<1000 & distance2015_w<1000) | ///
									(distance2015_h<1000 & cent_distance2015_w<1000) | ///
									(cent_distance2015_h<1000 & cent_distance2015_w<1000))
									
/* Interactions of bins */

gen		ttbin_h = 0
replace ttbin_h = 1 if tt00_h==1
replace ttbin_h = 2 if tt02_h==1 
replace ttbin_h = 5 if tt25_h==1

gen		ttbin_w = 0
replace ttbin_w = 1 if tt00_w==1
replace ttbin_w = 2 if tt02_w==1 
replace ttbin_w = 5 if tt25_w==1 

compress