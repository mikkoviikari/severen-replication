use 	"./output/powFEs", clear
drop if mi(pairid)
gen one = 1 

** TESTING 
/*
sum Omega_w_pmlall_noT_trm  lwage_trm if yr==0
corr Omega_w_pmlall_noT_trm  lwage_trm if yr==0, covariance

** Define Elasticities **
local 	eps 		= 2.903

** Recover Structural Residuals **
gen 	E_hat 		= Omega_w_pmlall_noT - `eps'*lwage if yr==1

corr lwage E_hat if yr==1, covariance 

local 	eps 		= 2.180
reg lwage E_hat if yr==1, robust 
test E_hat = -1/(2*`eps')
**/

** Useful for dropping collinear FEs
bys csubXyr_w: egen ncFE=count(one) if yr==1

local tnc table4compareARSW
capture erase ./tables/`tnc'.csv

** TABLE 3 Panel C

** Reg 1
capture drop E_hat

ivreghdfe 	DOmega_w_lin_noT (Dlwage=M_w90) [aw=wpop90], a(one) robust 
gen	E_hat = Omega_w_lin_noT - _b[Dlwage]*lwage
local estar = _b[Dlwage]

gmm	///
	(eq1: DOmega_w_lin_noT- {eps}*Dlwage - {b0}) ///
	(eq2: lwage - {rho}*E_hat - {c0}) if yr==1 [aw=wpop90], ///
	instruments(eq1: M_w90) ///
	instruments(eq2: E_hat) ///
	onestep winitial(identity) vce(cluster tract_w) 
local bval=_b[rho:_cons]
insert_into_file using ./tables/`tnc'.csv, key(b1) value(`bval') 
test [rho]_cons = -1/(2*`estar')
local sval = r(p)
insert_into_file using ./tables/`tnc'.csv, key(s1) value(`sval') 
nlcom (ratio1: [rho]_cons) (ratio2: -1/(2*[eps]_cons)), post	
test _b[ratio1] = _b[ratio2]
local pval = r(p)
insert_into_file using ./tables/`tnc'.csv, key(c1) value(`pval') 

** Reg 2
capture drop E_hat 
capture drop csubFE

ivreghdfe 	DOmega_w_lin_noT (Dlwage=M_w90) [aw=wpop90], a(csubXyr_w) robust
egen csubFE = group(csubXyr_w) if yr==1 & ncFE!=1 & e(sample)==1
gen	E_hat = Omega_w_lin_noT - _b[Dlwage]*lwage if e(sample)==1
local estar = _b[Dlwage]

gmm	///
	(eq1: DOmega_w_lin_noT- {eps}*Dlwage - {xb:ibn.csubFE}) ///
	(eq2: lwage - {rho}*E_hat - {c0}) if yr==1 [aw=wpop90], ///
	instruments(eq1: M_w90 ibn.csubFE, noconstant) ///
	instruments(eq2: E_hat) ///
	onestep winitial(unadjusted, independent) vce(cluster tract_w) 
local bval=_b[rho:_cons]
insert_into_file using ./tables/`tnc'.csv, key(b2) value(`bval') 
test [rho]_cons = -1/(2*`estar')
local sval = r(p)
insert_into_file using ./tables/`tnc'.csv, key(s2) value(`sval') 
nlcom (ratio1: [rho]_cons) (ratio2: -1/(2*[eps]_cons)), post	
test _b[ratio1] = _b[ratio2]
local pval = r(p)
insert_into_file using ./tables/`tnc'.csv, key(c2) value(`pval') 

** Reg 3
capture drop E_hat

ivreghdfe 	DOmega_w_pmlyby_noT (Dlwage=M_w90) [aw=wpop90], a(one) robust
gen	E_hat = Omega_w_pmlyby_noT - _b[Dlwage]*lwage
local estar = _b[Dlwage]

gmm	///
	(eq1: DOmega_w_pmlyby_noT- {eps}*Dlwage - {b0}) ///
	(eq2: lwage - {rho}*E_hat - {c0}) if yr==1 [aw=wpop90], ///
	instruments(eq1: M_w90) ///
	instruments(eq2: E_hat) ///
	onestep winitial(unadjusted, independent) vce(cluster tract_w) 
local bval=_b[rho:_cons]
insert_into_file using ./tables/`tnc'.csv, key(b3) value(`bval') 
test [rho]_cons = -1/(2*`estar')
local sval = r(p)
insert_into_file using ./tables/`tnc'.csv, key(s3) value(`sval') 
nlcom (ratio1: [rho]_cons) (ratio2: -1/(2*[eps]_cons)), post	
test _b[ratio1] = _b[ratio2]
local pval = r(p)
insert_into_file using ./tables/`tnc'.csv, key(c3) value(`pval')

** Reg 4
capture drop E_hat 
capture drop csubFE

ivreghdfe 	DOmega_w_pmlyby_noT (Dlwage=M_w90) [aw=wpop90], a(csubXyr_w) robust
egen csubFE = group(csubXyr_w) if yr==1 & ncFE!=1 & e(sample)==1
gen	E_hat = Omega_w_pmlyby_noT - _b[Dlwage]*lwage if e(sample)==1
local estar = _b[Dlwage]

gmm	///
	(eq1: DOmega_w_pmlyby_noT- {eps}*Dlwage - {xb:ibn.csubFE}) ///
	(eq2: lwage - {rho}*E_hat - {c0}) if yr==1 [aw=wpop90], ///
	instruments(eq1: M_w90 ibn.csubFE, noconstant) ///
	instruments(eq2: E_hat) ///
	onestep winitial(unadjusted, independent) vce(cluster tract_w) coeflegend
local bval=_b[rho:_cons]
insert_into_file using ./tables/`tnc'.csv, key(b4) value(`bval') 
test [rho]_cons = -1/(2*`estar')
local sval = r(p)
insert_into_file using ./tables/`tnc'.csv, key(s4) value(`sval') 
nlcom (ratio1: [rho]_cons) (ratio2: -1/(2*[eps]_cons)), post	
test _b[ratio1] = _b[ratio2]
local pval = r(p)
insert_into_file using ./tables/`tnc'.csv, key(c4) value(`pval') 

** Reg 5
capture drop E_hat

ivreghdfe 	DOmega_w_pmlall_noT (Dlwage=M_w90) [aw=wpop90], a(one) robust
gen	E_hat = Omega_w_pmlall_noT - _b[Dlwage]*lwage
local estar = _b[Dlwage]

gmm	///
	(eq1: DOmega_w_pmlall_noT- {eps}*Dlwage - {b0}) ///
	(eq2: lwage - {rho}*E_hat - {c0}) if yr==1 [aw=wpop90], ///
	instruments(eq1: M_w90) ///
	instruments(eq2: E_hat) ///
	onestep winitial(unadjusted, independent) vce(cluster tract_w) 
local bval=_b[rho:_cons]
insert_into_file using ./tables/`tnc'.csv, key(b5) value(`bval') 
test [rho]_cons = -1/(2*`estar')
local sval = r(p)
insert_into_file using ./tables/`tnc'.csv, key(s5) value(`sval') 
nlcom (ratio1: [rho]_cons) (ratio2: -1/(2*[eps]_cons)), post	
test _b[ratio1] = _b[ratio2]
local pval = r(p)
insert_into_file using ./tables/`tnc'.csv, key(c5) value(`pval') 

** Reg 6
capture drop E_hat 
capture drop csubFE

ivreghdfe 	DOmega_w_pmlall_noT (Dlwage=M_w90) [aw=wpop90], a(csubXyr_w) robust
egen csubFE = group(csubXyr_w) if yr==1 & ncFE!=1 & e(sample)==1
gen	E_hat = Omega_w_pmlall_noT - _b[Dlwage]*lwage if e(sample)==1
local estar = _b[Dlwage]

gmm	///
	(eq1: DOmega_w_pmlall_noT- {eps}*Dlwage - {xb:ibn.csubFE}) ///
	(eq2: lwage - {rho}*E_hat - {c0}) if yr==1 [aw=wpop90], ///
	instruments(eq1: M_w90 ibn.csubFE, noconstant) ///
	instruments(eq2: E_hat) ///
	onestep winitial(unadjusted, independent) vce(cluster tract_w) coeflegend
local bval=_b[rho:_cons]
insert_into_file using ./tables/`tnc'.csv, key(b6) value(`bval') 
test [rho]_cons = -1/(2*`estar')
local sval = r(p)
insert_into_file using ./tables/`tnc'.csv, key(s6) value(`sval') 
nlcom (ratio1: [rho]_cons) (ratio2: -1/(2*[eps]_cons)), post	
test _b[ratio1] = _b[ratio2]
local pval = r(p)
insert_into_file using ./tables/`tnc'.csv, key(c6) value(`pval') 



table_from_tpl, t(./tables/`tnc'.tex) r(./tables/`tnc'.csv) o(./tables/filled_`tnc'.tex)


** Figure D1

reg Omega_w_pmlall_noT_trm  lwage_trm if yr==0, robust 
reg Omega_w_pmlall_noT_trm  lemp_trm if yr==0, robust 

twoway (scatter Omega_w_pmlall_noT_trm lwage_trm if yr==0) || ///
	(lfit Omega_w_pmlall_noT_trm lwage_trm if yr==0, lc(red)), ///
	ytitle("{&omega}{sub:jt} in 1990 (from panel gravity estimator)") xtitle("ln(1990 Wage)") name(g1, replace) ///
	legend(off) text(0.8 9.9 "{&epsilon} = 0.173" "R{sup:2} = 0.005", c(red) place(w))  

twoway (scatter Omega_w_pmlall_noT_trm lemp_trm if yr==0) || ///
	(lfit Omega_w_pmlall_noT_trm lemp_trm if yr==0, lc(red)), ///
	ytitle("") xtitle("ln(1990 Workplace Employment)") name(g2, replace) ///
	legend(off) text(0.8 5.5 "{&epsilon} = 0.305" "R{sup:2} = 0.396", c(red) place(w)) 	

graph combine g1 g2, row(1) ycommon xsize(8) iscale(1)
graph export "./figures/what_is_omega.png", replace	
