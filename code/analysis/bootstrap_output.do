use 	"./output/bs_allparams_sim.dta", clear

sum *, d

** Remove disallowed parameter values **
keep if eps>0 & psi>0

** Sample from remaining values to get B=400

set seed 61686
sample 400, c

sum *, d
sort _id

outsheet * using "./output/welfare/bootstrap_params.csv", c replace
