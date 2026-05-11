/* Master .do file for "Commuting, Labor, and Housing Market Effects of Mass
*  Transportation: Welfare and Identification," (Severen). See README.txt for
*  instructions */

clear
cls

** Set working directory to top level file (one level above this file) **

*====================================*
*========== Building Data ===========*

*before running state, move contents of "./code/bartik-weights/" to PERSONAL ADO location
*to ensure table reproduction...

*in R: set cdir, execute:		"./code/build/index_rbuildscripts.R"

** Build Crosswalks **
do 		"./code/build/make_crosswalks.do"
do 		"./code/build/make_subcounties.do"

** Build Flow (Tract-Pair) Data **
do 		"./code/build/make_flows_1990tracts.do"
do 		"./code/build/make_flows_2000tracts.do"
do 		"./code/build/make_flowpanel.do"
do 		"./code/build/make_flowpanel_LEHD.do"

** Build Tract Data **
do 		"./code/build/make_wageemp.do"
do 		"./code/build/make_housingdata_tracts.do"
do 		"./code/build/make_treatmentdata.do"
do 		"./code/build/make_landuse.do" 
do 		"./code/build/make_tractshocks.do" 
do 		"./code/build/make_NCDB.do" 		// Note that this is 2010 tract geography
do 		"./code/build/make_transitdata_tracts.do"

** Combine Data **
do 		"./code/build/combine_flowstracts.do"
do 		"./code/build/combine_shiftshare.do"

** Prep Data for Analysis **
do 		"./code/build/prep_definitions.do"
do 		"./code/build/prep_dataRwelfare.do"
do 		"./code/build/prep_congestionroutes.do"
do 		"./code/build/prep_wagetransit.do"

** Bootstrap Prep **
do 		"./code/build/make_bstractlist.do"

*===============================*
*========== Analysis ===========*

** Final Cleaning (called by scripts below) **
/* "./code/analysis/finalflowcleaning.do" */

** Flow Analysis **
// do 		"./code/analysis/test_ncdbpretrends.do" 		// Table H2
do 		"./code/analysis/flows_metroeffects.do" 		// Tables 1, H1, H3, H4, H5, H6
do 		"./code/analysis/plot_treatmentgradient.do"		// Figure H6
do 		"./code/analysis/flows_congestion.do"			// Table 2
do 		"./code/analysis/flows_lehdthrough2015.do"		// Table 1
do 		"./code/analysis/gravity.do"					// Table F1

** Elasticities **
do 		"./code/analysis/recover_powFEs.do" 
do 		"./code/analysis/tracts_elasticities.do" 		// Tables 3, 4, D1, D2
do		"./code/analysis/epsilon_shiftshareanalysis.do" // Table H7
do		"./code/analysis/epsilon_shiftshareanalysis_wsubcoFEs.do" // Table H8
do 		"./code/analysis/comparison_FEs_vs_wage.do" 	// Figure D1

** Non-flow Effects of Transit **
do 		"./code/analysis/estimate_lambdas.do" 			// Tables 5, H9, H10, H11, H12
do 		"./code/analysis/plot_wagetransit.do" 			// Figure 2
do 		"./code/analysis/plot_ridership.do" 			// Figures H2, H3

** Bootstrapping **
do 		"./code/analysis/bootstrap_run.do"				// Table E1
do 		"./code/analysis/bootstrap_output.do"			// Table 6

** Other Pictures
do 		"./code/analysis/plot_flowdensity_ptreatment.do" // Figure 3

/* in R: set cdir, execute "./code/welfare/index_rwelfarescripts.R" to deliver
model results, etc., as in Tables 6 and H13. */

