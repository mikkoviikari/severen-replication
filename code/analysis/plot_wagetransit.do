
use "./data/WageTransit/wagetransit.dta", clear

keep if county==370

** TRANSIT AND INCOME

gen transit = 0
replace transit=1 if tranwork==30 | tranwork==31 | tranwork==32 | tranwork==33 | tranwork==34

tab year transit
keep if hhincome>0
gen lhhincome = ln(hhincome)

gen train = 0
replace train = 1 if tranwork==32 | tranwork==33 | tranwork==34


egen centile80 = cut(hhincome) if year==1980, g(100) 
egen centile90 = cut(hhincome) if year==1990, g(100) 
egen centile00 = cut(hhincome) if year==2000, g(100) 
egen centile10 = cut(hhincome) if year==2012, g(100) 

tempfile g1 g2
twoway (lpoly transit centile90) || (lpoly transit centile00, lp(dash)), saving("`g1'", replace) ///
	graphregion(color(white)) xti("") yti("Pr(Use any transit)") title("Commuters Using Any Transit") ///
	legend(off) fysize(44)
twoway (lpoly train centile90) || (lpoly train centile00, lp(dash)), saving("`g2'", replace) ///
	graphregion(color(white)) xti("Centile of Household Income") yti("Pr(Use any 'train')") title("Commuters Using Rail") ///
	legend(pos(6) row(1) label(1 "in 1990") label(2 "in 2000")) fysize(56)
gr combine "`g1'" "`g2'", col(1) xcommon graphregion(color(white)) iscale(0.8) ysize(6) imargin(0 0 0 0) 
gr export "./figures/wagetransit.png", replace 
gr export "./figures/wagetransit.pdf", replace 

