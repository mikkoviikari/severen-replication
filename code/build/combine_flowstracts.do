* Bring together flow data with empPOW data, treatments (stations roads etc),
* 	housing details, county subdivisions, and land use

clear

*******************************
/* Merge data into flowpanel */
*******************************

local 	dlist 	flowpanel_small flowpanel_all

foreach file of local dlist {

	use 	"./output/intermediate/`file'", clear

	/* Employment data to POW */
	rename 	tract_w tract1990
	rename 	year yr
	if ("`file'"=="flowpanel_small") {
		merge 	m:1 tract1990 yr using "./output/intermediate/empPOW_all", gen(_merge1)
	} 
	else if ("`file'"=="flowpanel_all") {
		merge 	m:1 tract1990 yr using "./output/intermediate/empPOW_all", gen(_merge1) keepusing(empPOW wagePOW wagePOW_ave)
	}
	drop if _merge1==2

	rename tract1990 tract_w
	rename yr year

	/* Housing data to RES */
	rename 	tract_h tract90
	replace year=1990 if year==0
	replace year=2000 if year==1
	if ("`file'"=="flowpanel_small") {
		merge 	m:1 tract90 year using "./output/intermediate/housingdetail_panel_tracts", gen(_merge2)
	} 
	else if ("`file'"=="flowpanel_all") {
		merge 	m:1 tract90 year using "./output/intermediate/housingdetail_panel_tracts", gen(_merge2) keepusing(empRES totpop hval_50 rent_50)
	}
	drop if _merge2==2

	/* Treatment data */
	rename	tract90 tract1990
	
	if ("`file'"=="flowpanel_small") {
		local 	tvars distance1999 distance2000 distance2015 cent_distance1999 cent_distance2015 tracks_distance1999 distance_i105 distance_nhs distance_roads distance_lines1925all distance_lines1925immediate distance_linesper blueline1999 redline1999 purpleline1999 greenline1999 yropen_nearest1999
		merge 	m:1	tract1990 using "./output/intermediate/treatment_data", gen(_merge3h)
	} 
	else if ("`file'"=="flowpanel_all") {
		local 	tvars distance1999 cent_distance1999 tracks_distance1999 distance_i105 distance_lines1925all distance_linesper distance_lines1925immediate
		merge 	m:1	tract1990 using "./output/intermediate/treatment_data", gen(_merge3h) keepusing(`tvars')
	}
	drop if _merge3h==2

	foreach v of varlist `tvars' {
		rename `v' `v'_h
	}

	rename 	tract1990 	tract_h
	rename 	tract_w		tract1990
	
	if ("`file'"=="flowpanel_small") {
		merge 	m:1	tract1990 using "./output/intermediate/treatment_data", gen(_merge3w)
	} 
	else if ("`file'"=="flowpanel_all") {
		merge 	m:1	tract1990 using "./output/intermediate/treatment_data", gen(_merge3w) keepusing(`tvars')
	}
	drop if _merge3w==2

	foreach v of varlist `tvars' {
		rename `v' `v'_w
	}
	
	rename 	tract1990 tract_w

	/* Land use data */
	if ("`file'"=="flowpanel_small") {
		rename 	tract_w tract1990
		
		merge 	m:1	tract1990 year using "./output/intermediate/landusepanel", gen(_merge4w)
		drop if _merge4w==2

		rename 	totarea 	totarea_w
		rename 	land_constr	land_constr_w 
		rename 	land_prod 	land_prod_w
		rename	land_consmptn land_consmptn_w
		rename 	land_res	land_res_w

		rename 	tract1990 	tract_w
		rename	tract_h 	tract1990

		merge 	m:1	tract1990 year using "./output/intermediate/landusepanel", gen(_merge4h)
		drop if _merge4h==2

		rename 	totarea 	totarea_h
		rename 	land_constr	land_constr_h 
		rename 	land_res	land_res_h
		rename 	land_prod	land_prod_h
		rename  land_consmptn land_consmptn_h
		
		rename 	tract1990 tract_h
	} 
	else if ("`file'"=="flowpanel_all") {
		rename 	tract_w tract1990
		
		merge 	m:1	tract1990 year using "./output/intermediate/landusepanel", gen(_merge4w) keepus(land_res land_prod)
		drop if _merge4w==2

		rename 	land_prod 	land_prod_w
		rename 	land_res	land_res_w

		rename 	tract1990 	tract_w
		rename	tract_h 	tract1990

		merge 	m:1	tract1990 year using "./output/intermediate/landusepanel", gen(_merge4h) keepus(land_res land_prod)
		drop if _merge4h==2

		rename 	land_res	land_res_h
		rename 	land_prod	land_prod_h

		rename 	tract1990 tract_h
	} 

	rename 	tract_h tract1990
	
	/* County subdivision data */
	merge 	m:1	tract1990 using "./output/crosswalks/subcounty2tracts", gen(_merge5h)
	drop if _merge5h==2

	rename	cousub 		cousub_h
	rename	county 		county_h
	rename 	tract1990 	tract_h
	rename	tract_w		tract1990

	merge 	m:1	tract1990 using "./output/crosswalks/subcounty2tracts", gen(_merge5w)
	drop if _merge5w==2

	rename	cousub 		cousub_w
	rename	county 		county_w

	rename 	tract1990 	tract_w

	/* Investigate Merge Issues */
	gen 	mergeprob = 0
	replace mergeprob = 1 if _merge1!=3
	replace mergeprob = 1 if _merge2!=3
	replace mergeprob = 1 if _merge3h!=3
	replace mergeprob = 1 if _merge3w!=3
	if ("`file'"=="flowpanel") {
		replace mergeprob = 1 if _merge4h!=3
		replace mergeprob = 1 if _merge4w!=3
	}
	replace mergeprob = 1 if _merge5h!=3
	replace mergeprob = 1 if _merge5w!=3

	codebook mergeprob

	bys pairid: egen mergeprobpanel = total(mergeprob)

	codebook mergeprobpanel

	compress

	sum 	wtflow5a if year==1990 [aw=wtflow5a]
	sum 	wtflow5a if year==1990 & mergeprob==1 [aw=wtflow5a]
	sum 	wtflow5a if year==1990 & mergeprobpanel>=1 [aw=wtflow5a]

	sum 	wtflow5b if year==1990 [aw=wtflow5b]
	sum 	wtflow5b if year==1990 & mergeprob==1 [aw=wtflow5b]
	sum 	wtflow5b if year==1990 & mergeprobpanel>=1 [aw=wtflow5b]

	sum 	wtflow5a if year==2000 [aw=wtflow5a]
	sum 	wtflow5a if year==2000 & mergeprob==1 [aw=wtflow5a]
	sum 	wtflow5a if year==2000 & mergeprobpanel>=1 [aw=wtflow5a]

	sum 	wtflow5b if year==2000 [aw=wtflow5b]
	sum 	wtflow5b if year==2000 & mergeprob==1 [aw=wtflow5b]
	sum 	wtflow5b if year==2000 & mergeprobpanel>=1 [aw=wtflow5b]

	drop 	_merge* mergeprob

	/* SAVE */
	if ("`file'"=="flowpanel_small") {
		save	"./output/intermediate/flows_wcovars_small", replace
	} 
	else if ("`file'"=="flowpanel_all") {
		save	"./output/intermediate/flows_wcovars_all", replace
	}
	clear
}


