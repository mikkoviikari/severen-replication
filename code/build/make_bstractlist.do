* Analysis 

clear

use 	"./output/intermediate/flows_prepped_small.dta"

**********

codebook tract_h tract_w

keep 	if OWN==1 & yr==0
keep  	tract_h

rename 	tract_h tract

save	"./output/intermediate/bstractlist.dta"




