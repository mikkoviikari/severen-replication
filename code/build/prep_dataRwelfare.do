clear
use 	"./output/flows_prepped_all.dta"

local 	flvars tt_here
outsheet tract_w tract_h `flvars' using "./output/welfare/times.csv" if yr==1, c replace

clear
use 	"./output/flows_prepped_small.dta"

gen		neartracks_20 = (tracks_distance1999_h<2000 & tracks_distance1999_w<2000 & yr==1)

gen 	neartracks_40 = (tracks_distance1999_h<4000 & tracks_distance1999_w<4000 & yr==1)
replace neartracks_40 = 0 if neartracks_20==1

gen		dd_h = max(500-distance1999_h,0)/500
replace dd_h = 0 if yr==0

gen		dd_w = max(500-distance1999_w,0)/500
replace dd_w = 0 if yr==0

merge m:1 tract_h tract_w using "./output/routeproximity.dta"
drop if _merge==2
drop _merge

gen 	shline_nearmetro_500_250 = shline_nearmetro500 - shline_nearmetro250
gen 	shline_nearmetro_1000_500 = shline_nearmetro1000 - shline_nearmetro500
gen 	shline_nearmetro_2000_1000 = shline_nearmetro2000 - shline_nearmetro1000
gen 	shline_nearmetro_4000_2000 = shline_nearmetro4000 - shline_nearmetro2000

local 	flvars 		wtflow5b travtime_all tt_dyn tt_here tran00_cc tran02_cc tran05_cc ///
			tt00_cc tt02_cc tt25_cc distance1999_? tracks_distance1999_? neartracks_?? ///
			shline_nearmetro250 shline_nearmetro_500_250 shline_nearmetro_1000_500 shline_nearmetro_2000_1000 shline_nearmetro_4000_2000
outsheet tract_w tract_h `flvars' using "./output/welfare/flows.csv" if yr==1, c replace

keep if OWN==1

bys pairid: egen nobs_w = count(lwage)

local 	powvars 	wagePOW tran00_w tran02_w tran05_w tt00_w tt02_w tt25_w ///
			Sim??_??_w Sal??_??_w PER??_??_w distance1999_w cent_distance1999_w ///
			tracks_distance1999_w dd_w
outsheet tract_w `powvars' using "./output/welfare/pow.csv" if yr==1, c replace

bys pairid: egen nobs_h = count(lhval)

local 	resvars 	hval_50 tran00_h tran02_h tran05_h tt00_h tt02_h tt25_h ///
			Sim??_??_h Sal??_??_h PER??_??_h distance1999_h cent_distance1999_h ///
			tracks_distance1999_h dd_h
outsheet tract_h `resvars' using "./output/welfare/res.csv" if yr==1, c replace
clear