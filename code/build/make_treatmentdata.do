**************************
/* Prep treatments data */
**************************
clear

insheet using "./output/intermediate/stationRoads_distances_tracts1990.csv", c

gen 	tractlen = strlen(gisjoin)
gen	 	tract1990 = gisjoin
replace	tract1990 = gisjoin + "00" if tractlen==12
drop 	tractlen

destring tract1990, replace i("G")
format  tract1990 %14.0f

keep if nhgiscty==370 | nhgiscty==590 | nhgiscty==650 | nhgiscty==710 | nhgiscty==1110 

keep 	tract1990 distance1999 distance2000 distance2015 cent_distance1999 cent_distance2015 ///
			tracks_distance1999 distance_i105 distance_nhs distance_roads ///
			distance_lines1925all distance_lines1925immediate distance_linesper ///
			blueline1999 redline1999 purpleline1999 greenline1999 yropen_nearest1999 ///
			acci_treat unbuilt_stdist unbuilt_group unbuilt_lidist unbuilt_stdist_cent unbuilt_group_cent

order 	tract1990, first

replace acci_treat = "1" if acci_treat=="TRUE"
replace acci_treat = "0" if acci_treat=="FALSE"
destring acci_treat, replace

browse if unbuilt_group!=unbuilt_group_cent // All are far 
replace unbuilt_group="" if unbuilt_group!=unbuilt_group_cent

gen		unbuilt_redpurple = (unbuilt_group=="Red/Purple")
gen		unbuilt_rgreen = (unbuilt_group=="Green")

drop 	unbuilt_group unbuilt_group_cent

foreach v of varlist distance1999-distance_linesper {
	replace `v' = round(`v')
}

compress

save "./output/intermediate/treatment_data", replace
clear