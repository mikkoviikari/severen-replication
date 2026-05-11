** Use to build crosswalks
clear
local 	din 	"./output/crosswalks/"
local 	dout	"./output/crosswalks/"

** Makes Crosswalks for 2000 Tract data to 1990 Tract data for summing to 1990
insheet using 	"`din'/caTract90XTr00_sums_raw.csv", c

rename 	gisjoint_90 tract1990
rename 	gisjoint_00 tract2000
drop 	v1 near_fid near_dist 
drop 	if area==0

gen 	percentage= iarea/shape_area1
drop if percentage<0.005

gen 	tractlen = strlen(tract1990)
replace tract1990=tract1990+"00" if tractlen==12
drop 	tractlen

bys tract2000: egen newp = total(percentage)
replace percentage = percentage/newp
drop 	newp
rename 	percentage wt
order 	tract2000 tract1990 wt

destring tract2000 tract1990, replace i("G")
format 	tract2000 tract1990 %14.0f

keep if nhgiscty==370 | nhgiscty==590 | nhgiscty==650 | nhgiscty==710 | nhgiscty==1110 | ///
		nhgiscty1==370 | nhgiscty1==590 | nhgiscty1==650 | nhgiscty1==710 | nhgiscty1==1110

save "`dout'/Xwalk_2000Tract-1990Tract_sums", replace
clear


** Makes Crosswalks for 2000 BG data to 1990 Tract data for summing to 1990
insheet using 	"`din'/caTract90XBg00_sums_raw.csv", c

rename 	gisjoint_90 tract1990
rename 	gisjoinbg_00 bg2000
drop 	v1 near_fid near_dist 
drop 	if area==0

bys bg2000: egen bg_area = total(area)
gen 	percentage = iarea/bg_area
drop if percentage<0.005

gen 	tractlen = strlen(tract1990)
replace tract1990=tract1990+"00" if tractlen==12
drop 	tractlen

bys bg2000: egen newp = total(percentage)
replace percentage = percentage/newp
drop 	newp
rename 	percentage wt
order 	bg2000 tract1990 wt

destring bg2000 tract1990, replace i("G")
format 	bg2000 tract1990 %14.0f

keep if nhgiscty==370 | nhgiscty==590 | nhgiscty==650 | nhgiscty==710 | nhgiscty==1110 | ///
		fipsstco==6037 | fipsstco==6059 | fipsstco==6065 | fipsstco==6071 | fipsstco==6111

save "`dout'/Xwalk_2000BG-1990Tract_sums", replace
clear


** Makes Crosswalks for 2000 Tract data to 1990 Tract data for averaging to 1990
insheet using 	"`din'/caTract90XTr00_aves_raw.csv", c

rename 	gisjoint_90 tract1990
rename 	gisjoint_00 tract2000
drop 	v1 near_fid near_dist 
drop 	if area==0

gen 	percentage= iarea/shape_area1
drop if percentage<0.005

gen 	tractlen = strlen(tract1990)
replace tract1990=tract1990+"00" if tractlen==12
drop 	tractlen

bys tract1990: egen newp = total(percentage)
replace percentage = percentage/newp
drop 	newp
rename 	percentage wt
order 	tract2000 tract1990 wt

destring tract2000 tract1990, replace i("G")
format 	tract2000 tract1990 %14.0f

keep if nhgiscty==370 | nhgiscty==590 | nhgiscty==650 | nhgiscty==710 | nhgiscty==1110 | ///
		nhgiscty1==370 | nhgiscty1==590 | nhgiscty1==650 | nhgiscty1==710 | nhgiscty1==1110

save "`dout'/Xwalk_2000Tract-1990Tract_aves", replace
clear


** Makes Crosswalks for 2000 BG data to 1990 Tract data for averaging to 1990
insheet using 	"`din'/caTract90XBg00_aves_raw.csv", c

rename 	gisjoint_90 tract1990
rename 	gisjoinbg_00 bg2000
drop 	v1 near_fid near_dist 
drop 	if area==0

gen 	percentage = iarea/shape_area
drop if percentage<0.005

gen 	tractlen = strlen(tract1990)
replace tract1990=tract1990+"00" if tractlen==12
drop 	tractlen

bys tract1990: egen newp = total(percentage)
replace percentage = percentage/newp
drop 	newp
rename 	percentage wt
order 	bg2000 tract1990 wt

destring bg2000 tract1990, replace i("G")
format 	bg2000 tract1990 %14.0f

keep if nhgiscty==370 | nhgiscty==590 | nhgiscty==650 | nhgiscty==710 | nhgiscty==1110 | ///
		fipsstco==6037 | fipsstco==6059 | fipsstco==6065 | fipsstco==6071 | fipsstco==6111

save "`dout'/Xwalk_2000BG-1990Tract_aves", replace
clear
