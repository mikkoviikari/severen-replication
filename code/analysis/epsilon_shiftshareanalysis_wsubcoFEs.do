clear
import delim using "./output/crosswalks/ind.csv"
save	"./output/crosswalks/ind", replace
clear

use 	"./output/powFEs", clear
gen one = 1

ivreghdfe 	DOmega_w_pmlall_noT (Dlwage=M_w90) [aw=wpop90], a(csubXyr_w) robust first

keep if e(sample)==1
drop cwage_CA*

local 	ind_stub s_ind_
foreach v of varlist `ind_stub'* {
	local 	newv = regexr("`v'", "_0", "_")
	rename `v' `newv'
} 

** Sample Cleaning **

keep if yr==1
drop if mi(Dlwage)
drop if mi(DOmega_w_pmlall_noT)
drop if mi(M_w90)
drop if mi(wpop90)

** Double Check Shares add to 1 **
egen s_ind_total = rowtotal(s_ind_*)

sum s_ind_total
drop s_ind_total

** Reweight cwages see IIIB in G-PSS**
sum cwage_*
egen m_cwage = rowmean(cwage_*)

foreach v of varlist cwage_* {
	replace `v' = `v'-m_cwage
} 

drop m_cwage

** make the cosub things into variables 
tab csubXyr_w, gen(subcty_contr_)
drop subcty_contr_1

**********************************
preserve
	drop s_ind_2
		overid_chao, z(s_ind_? s_ind_??) x(Dlwage) y(DOmega_w_pmlall_noT) weight_var(wpop90) absorb(csubXyr_w)
	* IV
	ivreghdfe 	DOmega_w_pmlall_noT (Dlwage=M_w90) [aw=wpop90], a(csubXyr_w) robust 
	local est_IV_b = string(_b[Dlwage], "%9.3f")
	local est_IV_se = string(_se[Dlwage], "%9.3f")
	
	* All shares 
	ivreghdfe 	DOmega_w_pmlall_noT (Dlwage=s_ind_? s_ind_??) [aw=wpop90], a(csubXyr_w) robust 
	local est_mIV_b = string(_b[Dlwage], "%9.3f")
	local est_mIV_se = string(_se[Dlwage], "%9.3f")
	local est_mIV_j = string(e(j), "%9.1f")
	local est_mIV_jp = string(e(jp), "%9.2f")
	
	* liml
	ivreghdfe 	DOmega_w_pmlall_noT (Dlwage=s_ind_? s_ind_??) [aw=wpop90], a(csubXyr_w) robust liml
	local est_LIML_b = string(_b[Dlwage], "%9.3f")
	local est_LIML_se = string(_se[Dlwage], "%9.3f")
	local est_LIML_j = string(e(j), "%9.1f")
	local est_LIML_jp = string(e(jp), "%9.2f")
	
	* MBTSLS
	btsls, z(s_ind_? s_ind_??) x(Dlwage) y(DOmega_w_pmlall_noT) ktype("mbtsls") weight_var(wpop90) absorb(csubXyr_w)
	*return list
	local est_mbtsls_b = string(r(beta), "%9.3f")
	
	*HFUL
	overid_chao, z(s_ind_? s_ind_??) x(Dlwage) y(DOmega_w_pmlall_noT) weight_var(wpop90) absorb(csubXyr_w)
	*return list
	local est_hful_b = string(r(delta), "%9.3f")
	local est_hful_j = string(r(T), "%9.1f")
	local est_hful_jp = string(r(p), "%9.2f")
restore	

** SEs for MBTSLS and HFUL
preserve
	drop s_ind_2
	
	bootstrap t=r(beta), rep(400): btsls, z(s_ind_? s_ind_??) x(Dlwage) y(DOmega_w_pmlall_noT) ktype("mbtsls") weight_var(wpop90) absorb(csubXyr_w)
	local est_mbtsls_se = string(_se[t], "%9.3f")

	capture noisily bootstrap t=r(delta), rep(400): overid_chao, z(s_ind_? s_ind_??) x(Dlwage) y(DOmega_w_pmlall_noT) weight_var(wpop90) absorb(csubXyr_w)
	capture noisily local est_hful_se = string(_se[t], "%9.3f")
restore	

**********************************
** Macros **

local 	ind_stub 	s_ind_
local	weight 		wpop90
local 	growth_stub cwage_
local	x 			Dlwage
local 	y 			DOmega_w_pmlall_noT
local 	z 			M_w90
local 	controls 	subcty_contr_*

foreach var of varlist `ind_stub'* {
	if regexm("`var'", "`ind_stub'(.*)") {
		local ind = regexs(1) 
		display `ind'
		}
	tempvar temp
	gen `temp' = `var' * `growth_stub'`ind'
	qui regress `x' `temp' `controls' [aw=`weight'], robust
	local pi_`ind' = _b[`temp']
	qui test `temp'
	local F_`ind' = r(F)
	qui regress `y' `temp' `controls' [aw=`weight'], robust
	local gamma_`ind' = _b[`temp']
	drop `temp'
	}

foreach var of varlist `ind_stub'6 `ind_stub'7 `ind_stub'11 `ind_stub'15 `ind_stub'9 {
	if regexm("`var'", "`ind_stub'(.*)") {
		local ind = regexs(1) 
		}
	tempvar temp
	qui gen `temp' = `var' * `growth_stub'`ind'
	ch_weak, p(.05) beta_range(-20(.1)20)   y(`y') x(`x') z(`temp') weight(`weight') absorb(csubXyr_w)
	disp r(beta_min) ,  r(beta_max)
	local ci_min_`ind' =string( r(beta_min), "%9.2f")
	local ci_max_`ind' = string( r(beta_max), "%9.2f")
	disp "`ind', `beta_`ind'', `t_`ind'', [`ci_min_`ind'', `ci_max_`ind'']"
	drop `temp'
	}


preserve
	keep `ind_stub'* tract_w `weight'
	
	reshape long `ind_stub', i(tract_w) j(ind)
	gen `ind_stub'pop = `ind_stub'*`weight'
	collapse (sd) `ind_stub'sd = `ind_stub' (rawsum) `ind_stub'pop `weight' [aw=`weight'], by(ind)
	tempfile tmp
	save `tmp'
restore


bartik_weight, z(`ind_stub'*) x(`x') weightstub(`growth_stub'*) y(`y') weight_var(`weight') absorb(csubXyr_w)

mat beta = r(beta)
mat alpha = r(alpha)
mat gamma = r(gam)
mat pi = r(pi)
mat G = r(G)
desc `ind_stub'*, varlist
local varlist r(varlist)
display `varlist'

clear
svmat beta  // Industry specific IV estimates
svmat alpha // Weights
svmat gamma
svmat pi
svmat G		// Just `growth_stub'

gen ind = _n+1

** FIRST TIME THROUGH: Stop here and look at weights (alpha) and assign to spot+1 highest **

/** Calculate Panel C: Variation across years in alpha **/
total alpha1
mat b = e(b)
local sum_alpha = string(b[1,1], "%9.3f")


sum alpha1 
local mean_alpha = string(r(mean), "%9.3f")


merge 1:1 ind using `tmp'
drop _merge


gen beta2 = alpha1 * beta1
gen indshare2 = alpha1 * (`ind_stub'pop/`weight')
gen indshare_sd2 = alpha1 * `ind_stub'sd
gen G2 = alpha1 * G1
collapse (sum) alpha1 beta2 indshare2 indshare_sd2 G2 (mean) G1 , by(ind)
gen agg_beta = beta2 / alpha1
gen agg_indshare = indshare2 / alpha1
gen agg_indshare_sd = indshare_sd2 / alpha1
gen agg_g = G2 / alpha1

merge 1:1 ind using "./output/crosswalks/ind"

keep if _merge == 3
drop	_merge
rename name ind_name

gsort -alpha1

capture file close fh
file open fh  using "./results/bartik/rotemberg_summary_wFEs.tex", write replace
file write fh "\toprule" _n

/** Panel A: Negative and Positive Weights **/
total alpha1 if alpha1 > 0
mat b = e(b)
local sum_pos_alpha = string(b[1,1], "%9.3f")
total alpha1 if alpha1 < 0
mat b = e(b)
local sum_neg_alpha = string(b[1,1], "%9.3f")

sum alpha1 if alpha1 > 0
local mean_pos_alpha = string(r(mean), "%9.3f")
sum alpha1 if alpha1 < 0
local mean_neg_alpha = string(r(mean), "%9.3f")

local share_pos_alpha = string(abs(`sum_pos_alpha')/(abs(`sum_pos_alpha') + abs(`sum_neg_alpha')), "%9.3f")
local share_neg_alpha = string(abs(`sum_neg_alpha')/(abs(`sum_pos_alpha') + abs(`sum_neg_alpha')), "%9.3f")



/** Panel B: Correlations of Industry Aggregates **/
gen F = .
gen agg_pi = .
gen agg_gamma = .
levelsof ind, local(industries)
foreach ind in `industries' {
	capture replace F = `F_`ind'' if ind == `ind'
	capture replace agg_pi = `pi_`ind'' if ind == `ind'
	capture replace agg_gamma = `gamma_`ind'' if ind == `ind'		
	}
corr alpha1 agg_g agg_beta F agg_indshare_sd
mat corr = r(C)
forvalues i =1/5 {
	forvalues j = `i'/5 {
		local c_`i'_`j' = string(corr[`i',`j'], "%9.3f")
		}
	}

/** Panel  D: Top 5 Rotemberg Weight Inudstries **/
foreach ind in 6 7 11 15 9 {
	qui sum alpha1 if ind == `ind'
   local alpha_`ind' = string(r(mean), "%9.3f")
	qui sum agg_g if ind == `ind'	
	local g_`ind' = string(r(mean), "%9.3f")
	qui sum agg_beta if ind == `ind'	
	local beta_`ind' = string(r(mean), "%9.3f")
	qui sum agg_indshare if ind == `ind'	
	local share_`ind' = string(r(mean)*100, "%9.3f")
	tempvar temp
	qui gen `temp' = ind == `ind'
	gsort -`temp'
	local ind_name_`ind' = ind_name[1]
	drop `temp'
	}


/** Over ID Figures **/
gen omega = alpha1*agg_beta
total omega
mat b = e(b)
local b = b[1,1]

gen label_var = ind 
gen beta_lab = string(agg_beta, "%9.3f")


gen abs_alpha = abs(alpha1) 
gen positive_weight = alpha1 > 0
gen agg_beta_pos = agg_beta if positive_weight == 1
gen agg_beta_neg = agg_beta if positive_weight == 0
twoway (scatter agg_beta_pos agg_beta_neg F [aweight=abs_alpha ], msymbol(Oh Dh) ), legend(pos(6) label(1 "Positive Weights") label( 2 "Negative Weights")) yline(`b', lcolor(black) lpattern(dash)) xtitle("First stage F-statistic")  ytitle("{&beta}{subscript:k} estimate")
graph export "./results/bartik/wFEs_overid.png", replace

gsort -alpha1
twoway (scatter F alpha1, mcolor(dblue) mlabel(ind_name  ) msize(0.5) mlabsize(2) ) (scatter F alpha1, mcolor(dblue) msize(0.5) ), name(a, replace) xtitle("Rotemberg Weight") ytitle("First stage F-statistic") yline(10, lcolor(black) lpattern(dash)) legend(off)
graph export "./results/bartik/wFEs_F_vs_rotemberg_weight.png", replace


/** Panel E: Weighted Betas by alpha weights **/
gen agg_beta_weight = agg_beta * alpha1

collapse (sum) agg_beta_weight alpha1 (mean)  agg_beta, by(positive_weight)
egen total_agg_beta = total(agg_beta_weight)
gen share = agg_beta_weight / total_agg_beta
gsort -positive_weight
local agg_beta_pos = string(agg_beta_weight[1], "%9.3f")
local agg_beta_neg = string(agg_beta_weight[2], "%9.3f")
local agg_beta_pos2 = string(agg_beta[1], "%9.3f")
local agg_beta_neg2 = string(agg_beta[2], "%9.3f")
local agg_beta_pos_share = string(share[1], "%9.3f")
local agg_beta_neg_share = string(share[2], "%9.3f")


/*** Write final table **/
/** Panel A **/
file write fh "\multicolumn{3}{l}{\textbf{Panel A: Negative and positive weights}}\\ [4pt]" _n
file write fh  " & Sum & Mean & Share \\  \cmidrule(lr){2-4}" _n
file write fh  "Negative & `sum_neg_alpha' & `mean_neg_alpha' & `share_neg_alpha' \\" _n
file write fh  "Positive & `sum_pos_alpha' & `mean_pos_alpha' & `share_pos_alpha' \\" _n
file write fh  "\midrule" _n

/** Panel B **/
file write fh "\multicolumn{5}{l}{\textbf{Panel B: Correlations of Industry Aggregates} }\\ [4pt]" _n
file write fh  " &$\alpha_k$ & \$g_{k}$ & $\beta_k$ & \$F_{k}$ & Var(\$z_k$) \\" _n
file write fh  "\cmidrule(lr){2-6} " _n
file write fh " & \\" _n
file write fh " $\alpha_k$             & 1\\" _n
file write fh " \$g_{k}$                &   `c_1_2'  & 1\\" _n
file write fh " $\beta_{k}$             &   `c_1_3'  & `c_2_3'    &1\\" _n
file write fh " \$F_{k}$                &   `c_1_4'  & `c_2_4'    &  `c_3_4'  & 1\\" _n
file write fh " Var(\$z_{k}$)           &   `c_1_5'  & `c_2_5'    &  `c_3_5'  &  `c_4_5'   &1\\" _n
file write fh  "\midrule" _n

/** Panel C **/
file write fh "\multicolumn{5}{l}{\textbf{Panel C: Top 5 Rotemberg weight industries} }\\ [4pt]" _n
file write fh  " & $\hat{\alpha}_{k}$ & \$g_{k}$ & $\hat{\beta}_{k}$ & 95 \% CI & Ind Share \\ \cmidrule(lr){2-6}" _n
foreach ind in 6 7 11 15 9 {
	if `ci_min_`ind'' != -20 & `ci_max_`ind'' != 20 {
		file write fh  "`ind_name_`ind'' & `alpha_`ind'' & `g_`ind'' & `beta_`ind'' & (`ci_min_`ind'',`ci_max_`ind'')  & `share_`ind'' \\ " _n
		}
	else  {
		file write fh  "`ind_name_`ind'' & `alpha_`ind'' & `g_`ind'' & `beta_`ind'' & \multicolumn{1}{c}{N/A}  & `share_`ind'' \\ " _n
		}
	}
file write fh  "\midrule" _n

/** Panel D **/
file write fh "\multicolumn{5}{l}{\textbf{Panel D: Estimates of $\beta_{k}$ for positive and negative weights} }\\ [4pt]" _n
file write fh  " & $\alpha$-weighted 	& Share of 			&  \\ " _n
file write fh  " & sum 					& overall $\beta$ 	& Mean  \\ \cmidrule(lr){2-4}" _n
file write fh  " Negative & `agg_beta_neg' & `agg_beta_neg_share' &`agg_beta_neg2' \\" _n
file write fh  " Positive & `agg_beta_pos' & `agg_beta_pos_share' & `agg_beta_pos2' \\" _n
file write fh  "\midrule" _n

/** Panel E **/
file write fh  "\multicolumn{5}{l}{\textbf{Panel E: Alternative estimates and overidentification} }\\ [4pt]" _n
file write fh  " & Bartik & TSLS & LIML & MBTSLS & HFUL  \\ \cmidrule(lr){2-6}" _n
file write fh  "$\Delta \ln(W_{jt})$ & `est_IV_b'  & `est_mIV_b'  & `est_LIML_b'  & `est_mbtsls_b'  & `est_hful_b' \\" _n
file write fh  " 					 &(`est_IV_se')&(`est_mIV_se')&(`est_LIML_se')&(`est_mbtsls_se')&(`est_hful_se')\\ [4pt]" _n
file write fh  "Over ID Test Stat.   & 			   & `est_mIV_j'  & `est_LIML_j'  &  				& `est_hful_j' \\" _n
file write fh  "\quad $p$-value   	 & 			   &[`est_mIV_jp']&[`est_LIML_jp']&  				&[`est_hful_jp'] \\" _n
file write fh  "\bottomrule" _n
file close fh













