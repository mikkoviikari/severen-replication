** Make a time series picture of LA Metro ridership
clear
insheet using "./data/Ridership/cleaned_rail.csv", c 

destring blueline redline greenline goldline expoline total, i(",") replace
replace total=. if total==0
drop if yr==.

gen moyr = ym(yr, month) 
format moyr %tm 
tsset moyr

rename total totalridership

local lines blueline redline greenline goldline expoline totalridership

foreach v of local lines {
	replace `v' = `v'/1000
}


gen totrid_3ma = (L.totalridership + totalridership + F.totalridership) / 3
gen totrid_11ma = (L5.totalridership + L4.totalridership + L3.totalridership + L2.totalridership + L.totalridership + totalridership + F.totalridership + F2.totalridership + F3.totalridership + F4.totalridership + F5.totalridership) / 11
gen totrid_12ma = (0.5*L6.totalridership + L5.totalridership + L4.totalridership + L3.totalridership + L2.totalridership + L.totalridership + totalridership + F.totalridership + F2.totalridership + F3.totalridership + F4.totalridership + F5.totalridership + 0.5*F6.totalridership) / 12

		
*twoway  tsline blueline redline greenline if tin(1990m1, 2000m4), ///
*	graphregion(color(white)) xti("Month") yti("Average Weekday Boardings (thousands/day)") title("Rail Ridership")

tempfile s1 s2
twoway tsline totalridership, ///
	saving("`s1'", replace) fysize(44) ///
	xti("Month") yti("Av. Weekday Boardings" "(1000s/day)") title("A. Total Rail Ridership")
twoway tsline blueline redline greenline goldline expoline, ///
	saving("`s2'", replace) lcolor(blue red green gold ltblue) lp(solid solid solid solid solid) ///
	legend(rows(1) label(1 "Blue") label(2 "Red/Purple") label(3 "Green") label(4 "Gold") label(5 "Expo"))  ///
	xti("Month") yti("Av. Weekday Boardings" "(1000s/day)") title("B. Ridership by Line") legend(pos(6)) fysize(56)
gr combine "`s1'" "`s2'", col(1) xcommon iscale(0.9) imargins(0 0 0 0)
gr export "./figures/ridership_long.png", replace

tempfile t1 t2
twoway tsline totalridership if tin(1990m1, 2000m4), ///
	saving("`t1'", replace) fysize(44) ///
	xti("Month") yti("Av. Weekday Boardings" "(1000s/day)") title("A. Total Rail Ridership")
twoway tsline blueline redline greenline if tin(1990m1, 2000m4), ///
	saving("`t2'", replace) lcolor(blue red green ) lp(solid solid solid) ///
	legend(rows(1) label(1 "Blue") label(2 "Red/Purple") label(3 "Green"))  ///
	xti("Month") yti("Av. Weekday Boardings" "(1000s/day)") title("B. Ridership by Line") legend(pos(6)) fysize(56)
gr combine "`t1'" "`t2'", col(1) xcommon  iscale(0.9) imargins(0 0 0 0)
gr export "./figures/ridership_short.png", replace