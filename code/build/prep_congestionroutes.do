* Develop definitions for analysis

clear

import delim "./output/intermediate/routes_bufferedprepped.csv"
drop v1

foreach id of varlist orig dest {
	gen 	`id'len = strlen(`id')
	gen	 	`id'1990 = `id'
	replace	`id'1990 = `id' + "00" if `id'len==12
	*drop 	`id'len

	destring `id'1990, replace i("G")
	format  `id'1990 %14.0f
}

rename orig1990 tract_h
rename dest1990 tract_w 

drop 	orig dest origlen destlen

destring length_*, i("NA") replace

unab vlist: length_*
foreach v of local vlist {
	replace `v' = 0 if mi(`v')
}

compress

order orig dest, first

** Make Share Variables **
foreach v of local vlist {
	gen 	sh_`v' = `v'/length
}

drop length_*

rename sh_length_lineb_250 shline_nearmetro250
rename sh_length_lineb_500 shline_nearmetro500
rename sh_length_lineb_1000 shline_nearmetro1000
rename sh_length_lineb_2000 shline_nearmetro2000
rename sh_length_lineb_4000 shline_nearmetro4000

rename sh_length_hiwyb_250 shline_nearhiwy250
rename sh_length_hiwyb_1000 shline_nearhiwy1000

drop dist
rename time time_sec
replace time_sec = round(time_sec/1000)

compress

save 	"./output/routeproximity.dta", replace
clear