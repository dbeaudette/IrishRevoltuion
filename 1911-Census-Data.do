****This is a STATA do-file for compiling the various tabular files in the 
****Irish Database of Historical Statistics into a single, "wide" data-file
****aggregated at the county level. The do-file performs this operation for 
****1911 data only. It could easily be modified to include other years.

***This do-file uses data from the following UKDA depositories:
**Total population: http://doi.org/10.5255/UKDA-SN-3578-1
**Age: http://doi.org/10.5255/UKDA-SN-3574-1
**Religion: http://doi.org/10.5255/UKDA-SN-3579-1
**Irish Language: http://doi.org/10.5255/UKDA-SN-3573-1
**The data are protected by the UKDA end-user license agreement 
**You'll need to access the data via the DOI's above and download thme into your working directory.



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
gen newcountyid=substr(county_id,1,4)
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

import delimited "UKDA-3573-tab/tab/langcou.tab", varnames(1) clear
gen newcountyid=substr(county_id,1,4)
replace lang=trim(lang)
keep if year==1911
keep if lang=="IRISH&ENGLISH"
rename age* lang_irishenglish_age*
rename under* lang_irishenglish_under*
collapse (sum) lang_*, by(newcountyid)
save "1911-IrishLanguage-IrishEnglish.dta", replace

import delimited "UKDA-3573-tab/tab/langcou.tab", varnames(1) clear
gen newcountyid=substr(county_id,1,4)
replace lang=trim(lang)
keep if year==1911
keep if lang=="IRISH ONLY"
rename age* lang_irishonly_age*
rename under* lang_irish_only_under*
collapse (sum) lang_*, by(newcountyid)
save "1911-IrishLanguage-IrishOnly.dta", replace

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

use "1911-Religion-by-county.dta", clear
merge 1:1 newcountyid using "1911-agestatistics-county-MALES.dta"
drop _m
merge 1:1 newcountyid using "1911-agestatistics-county-FEMALES.dta"
drop _m
merge 1:1 newcountyid using "1911-IrishLanguage-IrishOnly.dta"
drop _m
merge 1:1 newcountyid using "1911-IrishLanguage-IrishEnglish.dta"
drop _m
merge 1:1 newcountyid using "1911-county-codes.dta"
drop if _m~=3

replace county=trim(county)
replace county="DERRY" if county=="LONONDERRY"
replace county="LAOIS" if county=="QUEEN'S COUNTY"
replace county="OFFALY" if county=="KING'S COUNTY"

export delimited "1911-Census-Statistics.csv", replace
