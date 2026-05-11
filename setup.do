/* Setup script: install all required Stata packages for Severen replication.
   Run this once from any working directory before running the analysis.     */

ssc install blindschemes, replace   // plotplainblind scheme (used in profile.do)
ssc install winsor2,      replace   // used in prep_definitions.do
ssc install ivreg2,       replace   // dependency of ivreghdfe
ssc install ivreghdfe,    replace   // IV with high-dimensional FEs
ssc install regsave,      replace   // save regression results (bootstrap_run.do)
ssc install ppmlhdfe,     replace   // PPML with high-dimensional FEs (flows_metroeffects.do)
ssc install ranktest,     replace   // dependency of ivreg2 (tracts_elasticities.do)
ssc install estout,       replace   // eststo/esttab (tracts_elasticities.do)
ssc install coefplot,     replace   // coefficient plots (tracts_elasticities.do)
ssc install gtools,       replace   // gquantiles (plot_flowdensity_ptreatment.do)

net install binsreg, from("https://raw.githubusercontent.com/nppackages/binsreg/master/stata") replace
