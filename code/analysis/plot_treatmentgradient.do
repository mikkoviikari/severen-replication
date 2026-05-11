set scheme plotplainblind
tempfile g_all g_sim

use		"./results/metroeffects/gradientreatment.dta", clear

drop if perim_threshold>1200

gen	p500_upper = b+1.97*se if cent_threshold==500
gen	p500_lower = b-1.97*se if cent_threshold==500
	
twoway (rarea p500_upper p500_lower perim_threshold if cent_threshold==500, col(bluishgray%40) lc(gs16)) || ///
		(line b perim_threshold if cent_threshold==0, lc("0 255 0") lp(dash)) || ///
		(line b perim_threshold if cent_threshold==100, lc("0 204 0") lp(dash)) || ///
		(line b perim_threshold if cent_threshold==200, lc("0 153 0") lp(dash)) || ///
		(line b perim_threshold if cent_threshold==300, lc("0 102 0") lp(dash)) || ///
		(line b perim_threshold if cent_threshold==400, lc("0 51 0") lp(dash)) || ///
		(line b perim_threshold if cent_threshold==600, lc("0 0 255") lp(-)) || ///
		(line b perim_threshold if cent_threshold==700, lc("0 0 204") lp(-)) || ///
		(line b perim_threshold if cent_threshold==800, lc("0 0 153") lp(-)) || ///
		(line b perim_threshold if cent_threshold==900, lc("0 0 102") lp(-)) || ///
		(line b perim_threshold if cent_threshold==1000, lc("0 0 51") lp(-)) || ///
		(line b perim_threshold if cent_threshold==500, lc(black) lp(solid)), ///
		xtitle("") xlab(0 400 800 1200) ///
		ytitle("Estimate of" "1[(d{ij}<C OR d{ij}<P) AND yr=2000]") yline(0, lc(black) lp(solid)) ///
		legend(off) ///
		subtitle("A. All Tract Pairs") saving("`g_all'")

use		"./results/metroeffects/gradientreatment_sim.dta", clear

drop if perim_threshold>1200

gen	p500_upper = b+1.97*se if cent_threshold==500
gen	p500_lower = b-1.97*se if cent_threshold==500
	
twoway (rarea p500_upper p500_lower perim_threshold if cent_threshold==500, col(bluishgray%40) lc(gs16)) || ///
		(line b perim_threshold if cent_threshold==0, lc("0 255 0") lp(dash)) || ///
		(line b perim_threshold if cent_threshold==100, lc("0 204 0") lp(dash)) || ///
		(line b perim_threshold if cent_threshold==200, lc("0 153 0") lp(dash)) || ///
		(line b perim_threshold if cent_threshold==300, lc("0 102 0") lp(dash)) || ///
		(line b perim_threshold if cent_threshold==400, lc("0 51 0") lp(dash)) || ///
		(line b perim_threshold if cent_threshold==600, lc("0 0 255") lp(-)) || ///
		(line b perim_threshold if cent_threshold==700, lc("0 0 204") lp(-)) || ///
		(line b perim_threshold if cent_threshold==800, lc("0 0 153") lp(-)) || ///
		(line b perim_threshold if cent_threshold==900, lc("0 0 102") lp(-)) || ///
		(line b perim_threshold if cent_threshold==1000, lc("0 0 51") lp(-)) || ///
		(line b perim_threshold if cent_threshold==500, lc(black) lp(solid)), ///
		xtitle("P = Perimeter threshold (m)") xlab(0 400 800 1200) ///
		ytitle("Estimate of" "1[(d{ij}<C OR d{ij}<P) AND yr=2000]") yline(0, lc(black) lp(solid)) yscale(titlegap(*29)) ///
		leg(pos(6) row(2) order(0 "C = Centroid Dist:" 0 "" 2 "0m" 3 "100m" 4 "200m" 5 "300m" 6 "400m" 12 "500m" 1 "500m 95%CI" 7 "600m" 8 "700m" 9 "800m" 10 "900m" 11 "1000m")) ///
		subtitle("B. Immediate 1925 Plan") saving("`g_sim'") fysize(64)

graph combine "`g_all'" "`g_sim'", c(1) ysize(6) xsize(5) imargin(0)
graph export "./figures/distance_combos.png", replace	

graph combine "`g1'" "`g2'", c(1) ysize(6) xsize(5) imargin(0)	
