*net install binsreg, from("https://raw.githubusercontent.com/nppackages/binsreg/master/stata") replace
clear

use 	"./output/flows_prepped_small.dta"

do 		"./code/analysis/finalflowcleaning.do"

drop O_* X_* F_*

************************
/* Summary Statistics */
************************



gen		wtflow_all10 = min(wtflow_all, 1000) if !mi(wtflow_all)
gen lflowC = ln(wtflow_all10)

sum	lflowC if yr==0 & lflowC>0 & OWN!=1, d
sum lflowC if yr==0 & Sal10_tr_lo_cc==1 & lflowC>0 & OWN!=1, d


*preserve
	keep if yr==0 & Sim10_tr_lo_cc==1 & lflowC>0 & OWN!=1 & !mi(lflowC)

	
	** HERE 
	
	local bins 200
	
	gquantiles qflow =  lflowC, xtile nquantiles(`bins')
	bys qflow: egen qflow_x = mean(lflowC)
	
	gen meanval = .
	gen ci_upper = .
	gen ci_lower = .
	
	levelsof qflow, local(lvls)
	foreach q of local lvls {
		ci means fut_tran05_cc if qflow==`q'
		replace meanval = r(mean) if qflow==`q'
		replace ci_lower = r(lb) if qflow==`q' 
		replace ci_upper = r(ub) if qflow==`q'
	}
	
	bys qflow: gen key = (_n==1)
	kdensity lflowC, gen(x h) bw(0.25)
	
	/*
	twoway (hist lflowC, discrete color(ltblue%50) frac) || ///
			(lpolyci fut_tran05_cc lflowC, nofit alc(gs14%50) fc(gs14%50)) || ///
			(lpoly fut_tran05_cc lflowC, lc(orange)) || ///
			(scatter meanval qflow_x if key==1, ms(Oh) mc(black)) || ///
			(rcap ci_lower ci_upper qflow_x if key==1, lc(gs12)), ///
			xscale(r(1 7)) ylab(, nogrid) xlab(, nogrid) ///
			yti("Pr(Treated) and Density") xti("ln(Flow in 1990)") ///
			legend(pos(6) row(1) order(1 "Density (fraction of flows)" 4 "Percent treated (binned)" 3 "Percent treated (smoothed)")) 
	
	twoway (kdensity lflowC, color(ltblue%50) bw(0.25)) || ///
			(lpolyci fut_tran05_cc lflowC, nofit alc(gs14%50) fc(gs14%50)) || ///
			(lpoly fut_tran05_cc lflowC, lc(orange)) || ///
			(scatter meanval qflow_x if key==1, ms(Oh) mc(black)) || ///
			(rcap ci_lower ci_upper qflow_x if key==1, lc(gs12)), ///
			xscale(r(1 7)) ylab(, nogrid) xlab(, nogrid) ///
			yti("Pr(Treated) and Density") xti("ln(Flow in 1990)") ///
			legend(pos(6) row(1) order(1 "Density (fraction of flows)" 4 "Percent treated (binned)" 3 "Percent treated (smoothed)")) 
	*/		
	twoway (kdensity lflowC, color(ltblue%50) bw(0.25)) || ///
			(lpoly fut_tran05_cc lflowC, lc(orange)) || ///
			(scatter meanval qflow_x if key==1, ms(Oh) mc(black)) || ///
			(rcap ci_lower ci_upper qflow_x if key==1, lc(gs12)), ///
			xscale(r(1 7)) ylab(, nogrid) xlab(, nogrid) ///
			yti("Pr(Treated) and Density") xti("ln(Flow in 1990)") ///
			legend(pos(6) row(1) order(1 "Density (fraction of flows)" 3 "Percent treated (0.5% bins)" 2 "Percent treated (smoothed)")) 
			
	graph export "./figures/treatment_density.pdf", replace		
*restore


