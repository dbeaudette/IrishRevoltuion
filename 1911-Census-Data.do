****This is a STATA do-file for compiling the various tabular files in the 
****Irish Database of Historical Statistics into a single, "wide" data-file
****aggregated at the county level. The do-file performs this operation for 
****1911 data only. It could easily be modified to include other years.

***This do-file uses data from the following UKDA depositories:
**Total population: http://doi.org/10.5255/UKDA-SN-3578-1
**Age: http://doi.org/10.5255/UKDA-SN-3574-1
**Religion: http://doi.org/10.5255/UKDA-SN-3579-1
**Save these into your working directory


**Set your working directory:

*cd "YOUR DIRECTORY" 


**Import the tabular data sets and save them as STATA data sets:
import delimited "UKDA-3578-tab/tab/codes/countyid.tab", varnames(1) clear
drop v3
gen newcountyid=trim(county_id)
save "1911-county-codes.dta", replace

import delimited "UKDA-3579-tab/tab/religion_cou.tab", varnames(1) clear
drop if year=="year  "
destring year, replace
keep if year==1911
destring roman_catholic ch_of_ireland presbyterian methodists others, replace
gen total= roman_catholic+ ch_of_ireland+ presbyterian+ methodists+ others
gen newcountyid=trim(county_id)
collapse (sum) roman_catholic ch_of_ireland presbyterian methodists others total, by(newcountyid)
save "1911-Religion-by-county.dta", replace

import delimited "UKDA-3574-tab/tab/age11_cou.tab", varnames(1) clear
replace sex=trim(sex)
keep if sex=="MALES"
gen newcountyid=substr(county_id,1,4)
rename age* maleage*
rename under_1 maleunder_1
collapse (sum) male*, by(newcountyid)
save "1911-agestatistics-county-MALES.dta", replace

import delimited "UKDA-3574-tab/tab/age11_cou.tab", varnames(1) clear
replace sex=trim(sex)
keep if sex=="FEMALES"
gen newcountyid=substr(county_id,1,4)
rename age* femaleage*
rename under_1 femaleunder_1
collapse (sum) female*, by(newcountyid)
save "1911-agestatistics-county-FEMALES.dta", replace

***Having trouble with the total population data. Commenting-out this code, b/c it needs some work.
***Specifically, Dublin City (and other cities) do not appear to be tagged separately, but also are not included in the county totals.
*import delimited "UKDA-3578-tab/tab/poppluco.tab", varnames(1) clear
*keep if year==1911
*gen newcountyid=substr(poor_law_union,1,4)
*gen total=males+females
*collapse (sum) males females total, by(county_id)
*save "Population-PLUC.dta", replace

***Then merge all of the individual data sets together to make the 'wide' version:
*use "Population-PLUC.dta", clear

use "1911-Religion-by-county.dta"
merge 1:1 newcountyid using "1911-agestatistics-county-MALES.dta"
drop if _m~=3
drop _m
merge 1:1 newcountyid using "1911-agestatistics-county-FEMALES.dta"
drop if _m~=3
drop _m
merge 1:1 newcountyid using "1911-county-codes.dta"
drop if _m~=3
