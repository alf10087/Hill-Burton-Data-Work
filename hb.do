/////////////// Data task: Investigating the allocation of Hill-Burton funding across states //////////////////////////
/////////////// By: Alfonso Rojas-Alvarez //////////////////////////

/////////////////////////// 1. 
/////////////////////////// I. Cleanup the three datasets for only what I need.

//////////// First Dataset

/////// Saved the hbpr.txt in .xls first to make the import simpler
import excel "/Users/Alfonso/Google Drive/Berkeley/ra_task_files/hbpr.xls", sheet("hbpr.txt") firstrow clear
drop Status Month Total bedsprovided adjfac typeconst category control nameoffacility county city projno Pagenumber
drop if State=="Hawaii"
drop if State=="Dist of Col"
drop if State=="Alaska"
drop if State =="Virgin Islands"
drop if State =="American Samoa"
drop if State =="Puerto Rico"
drop if State =="Guam"
sort State Year
collapse (sum) HillBurtonFunds, by(State Year)
drop if Year > 64
gen year = Year + 1900
gen str14 state = subinstr(State," ","",.)
tostring year, replace
gen state_year = state + "_" + year
drop State Year year state
order state_year, before(HillBurtonFunds)
save "/Users/Alfonso/Google Drive/Berkeley/ra_task_files/hbprclean.dta", replace

//////////// Second Dataset

insheet using "/Users/Alfonso/Google Drive/Berkeley/ra_task_files/pcinc.csv", clear
drop percapitapersonalincome2dollars
drop if v4 == "(NA)" 
drop if areaname == "District of Columbia"
drop if _n > 49
drop if fips =="00"
destring fips, replace
destring v*, replace
sort fips
rename v4 _1943
rename v5 _1944
rename v6 _1945
rename v7 _1946
rename v8 _1947
rename v9 _1948
rename v10 _1949
rename v11 _1950
rename v12 _1951
rename v13 _1952
rename v14 _1953
rename v15 _1954
rename v16 _1955
rename v17 _1956
rename v18 _1957
rename v19 _1958
rename v20 _1959
rename v21 _1960
rename v22 _1961
rename v23 _1962
gen _1963 =. 
gen _1964 =.

save "/Users/Alfonso/Google Drive/Berkeley/ra_task_files/pcinc.dta", replace

/////// Loop to generate the new stateyear variable

local j = 0
gen state_year = "."
gen pcincv = .
expand 22
sort areaname
foreach str in Alabama Arizona Arkansas California Colorado Connecticut Delaware Florida Georgia Idaho Illinois Indiana Iowa Kansas Kentucky Louisiana Maine Maryland Massachusetts Michigan Minnesota Mississippi Missouri Montana Nebraska Nevada NewHampshire NewJersey NewMexico NewYork NorthCarolina NorthDakota Ohio Oklahoma Oregon Pennsylvania RhodeIsland SouthCarolina SouthDakota Tennessee Texas Utah Vermont Virginia Washington WestVirginia Wisconsin Wyoming {
	foreach var of varlist _1943-_1964 {
		disp "`str'" 
		local j = `j'+1
		replace state_year = "`str'`var'" in `j'
		replace pcincv = `var'[`j'] in `j'
	}
}

drop _*

save "/Users/Alfonso/Google Drive/Berkeley/ra_task_files/pcincclean.dta", replace

//////////// Third Dataset

insheet using "/Users/Alfonso/Google Drive/Berkeley/ra_task_files/pop.csv", clear
drop population1numberofpersons
drop if v4 == "(NA)" 
drop if areaname == "District of Columbia"
drop if _n > 49
drop if fips =="00"
destring fips, replace
destring v*, replace
sort fips
gen _1943 =.
gen _1944 =.
gen _1945 =.
gen _1946 =.
rename v4 _1947
rename v5 _1948
rename v6 _1949
rename v7 _1950
rename v8 _1951
rename v9 _1952
rename v10 _1953
rename v11 _1954
rename v12 _1955
rename v13 _1956
rename v14 _1957
rename v15 _1958
rename v16 _1959
rename v17 _1960
rename v18 _1961
rename v19 _1962
rename v20 _1963
rename v21 _1964 
order _1943 _1944 _1945 _1946, before(_1947)

save "/Users/Alfonso/Google Drive/Berkeley/ra_task_files/pop.dta", replace

/////// Loop to generate the new stateyear variable

local j = 0
gen state_year = "."
gen popv = .
expand 22
sort areaname
foreach str in Alabama Arizona Arkansas California Colorado Connecticut Delaware Florida Georgia Idaho Illinois Indiana Iowa Kansas Kentucky Louisiana Maine Maryland Massachusetts Michigan Minnesota Mississippi Missouri Montana Nebraska Nevada NewHampshire NewJersey NewMexico NewYork NorthCarolina NorthDakota Ohio Oklahoma Oregon Pennsylvania RhodeIsland SouthCarolina SouthDakota Tennessee Texas Utah Vermont Virginia Washington WestVirginia Wisconsin Wyoming {
	foreach var of varlist _1943-_1964 {
		disp "`str'" 
		local j = `j'+1
		replace state_year = "`str'`var'" in `j'
		replace popv = `var'[`j'] in `j'
	}
}
drop _* areaname

save "/Users/Alfonso/Google Drive/Berkeley/ra_task_files/popclean.dta", replace

//////////// Combine into a single dataset, and save.

merge 1:1 state_year using "/Users/Alfonso/Google Drive/Berkeley/ra_task_files/pcincclean.dta"
drop _merge
merge 1:1 state_year using "/Users/Alfonso/Google Drive/Berkeley/ra_task_files/hbprclean.dta"
drop _merge fips

////// Assume that missing observations = no funds allocated that state_year.

replace HillBurtonFunds =0 if missing(HillBurtonFunds)
save "/Users/Alfonso/Google Drive/Berkeley/ra_task_files/dataclean.dta", replace

/////////////////////////// II. Compute Formula

///// 1. Smoothed per capita income

gen smoothpcinc = (pcincv[_n-4] + pcincv[_n-3] + pcincv[_n-2]) / 3

///// 2. National Smoothed Per Capita Income Average Per Year

gen str4 year = substr(state_year, -4, .)
destring year, replace
egen suminc = sum(smoothpcinc), by(year)
gen smoothpcinc_nat = suminc / 48

///// 3. Index Number for each State*Year

gen indexnumber = smoothpcinc / smoothpcinc_nat

///// 4. Allotment percentage

gen allotmentpctg = 1 - 0.5*(indexnumber)

///// 5. Replace minimum and maximum

gen allotmentpctg2 = allotmentpctg
replace allotmentpctg = 0.75 if allotmentpctg > 0.75
replace allotmentpctg = 0.33 if allotmentpctg < 0.33

///// 6. Weighted population

gen weighpop = (allotmentpctg)^2 * popv
gen weighpop2 = (allotmentpctg2)^2 * popv

///// 7. Allocation share

egen sumpopnat = sum(weighpop), by(year)
gen allocshare = weighpop / sumpopnat

egen sumpopnat2 = sum(weighpop2), by(year)
gen allocshare2 = weighpop2 / sumpopnat2

save "/Users/Alfonso/Google Drive/Berkeley/ra_task_files/dataclean.dta", replace
clear
///// 8. Predicted Hill-Burton Allocation

/// Generate Total Federal Hill-Burton appropriations per year

import excel "/Users/Alfonso/Google Drive/Berkeley/ra_task_files/Hill Burton Federal Appropriations.xlsx", sheet("Sheet1") firstrow
rename FiscalYear year, clear
rename TotalAmount000s hbtotalnat
save "/Users/Alfonso/Google Drive/Berkeley/ra_task_files/hbtotal.dta", replace
use "/Users/Alfonso/Google Drive/Berkeley/ra_task_files/dataclean.dta", clear
merge m:1 year using "/Users/Alfonso/Google Drive/Berkeley/ra_task_files/hbtotal.dta"
drop _merge
save "/Users/Alfonso/Google Drive/Berkeley/ra_task_files/hbtotal.dta", replace

/// Now generate the predicted values

gen predicted = allocshare * hbtotalnat
gen predicted2 = allocshare2 * hbtotalnat

///// 9. Replace minimum

replace predicted=100 if (predicted<100 & year==1948)
replace predicted=200 if (predicted<200 & year>1948)

replace predicted2=100 if (predicted2<100 & year==1948)
replace predicted2=200 if (predicted2<200 & year>1948)

/////////////////////////// III. Clean the data to leave only what we need

drop if year < 1947
rename HillBurtonFunds hbfunds
replace hbfunds = hbfunds/1000
drop popv pcincv smoothpcinc suminc smoothpcinc_nat indexnumber weighpop sumpopnat allocshare hbtotalnat weighpop2 allocshare2 sumpopnat2
label variable hbfunds "Actual HB funds allocated ($000)"
label variable predicted "Predicted HB funds to be allocated ($000)"
label variable predicted2 "Predicted federal Hill-Burton funds to be allocated - without minimum"
label variable allotmentpctg "Allotment percentage"
label variable allotmentpctg2 "Allotment percentage without minimum"
label variable state_year "State and Year identifier"
label variable year "Year"
label variable areaname "State"

/////////////////////////// 2.
///// Is the 0.33 minimum empirically relevant?
///// Note: I ignore the 0.75 maximum because none of my observations ended up with allotmentpctg > 0.75.

gen equal = 1 if predicted == predicted2
replace equal=0 if equal==.

///// Run several tests to evaluate whether the 0.33 minimum is empirically relevant
ttest predicted == predicted2
sum predicted if allotmentpctg2<=.33
ttest predicted == predicted2 if (equal==0 & allotmentpctg2<0.33)

/////////////////////////// 3. Are predicted state allocations a good predictor of actual federal Hill-Burton funding allocations?

///// Chart
graph set window fontface "Times New Roman"
twoway (lfit hbfunds predicted) (scatter hbfunds predicted, msymbol(o) ytitle(Actual HB funds allocated ($000), height(5) size(small)) msize(vsmall) xtitle(Predicted HB funds to be allocated ($000), height(5) size(small)) legend(off) ylabel(3000 6000 9000 12000 15000 18000) xlabel(3000 6000 9000 12000 15000) graphregion(color(white)) bgcolor(white) xlabel(,labsize(small)) ylabel(,labsize(small)))

egen state = group(areaname)
xtset state year
xtsum predicted
eststo clear

///// MODEL 1: Clustered OLS

eststo: regress hbfunds predicted, cluster(state)
estimates store clusteredOLS

///// MODEL 2: Fixed Effects for Panel Data without Time Effects

eststo: xtreg hbfunds predicted, fe
estimates store fixednt

///// MODEL 3: Random Effects for Panel Data with Time Effects

eststo: xtreg hbfunds predicted i.year, re
estimates store re

///// MODEL 4: Fixed Effects for Panel Data with Time Effects

eststo: xtreg hbfunds predicted i.year, fe
estimates store fixed

///// Table of Results
esttab using "/Users/Alfonso/Google Drive/Berkeley/ra_task_files/example2.tex", se r2 replace

////////////////////////// Clean dataset for deliverable

drop _est_est1 _est_est2 _est_fixed areaname year allotmentpctg allotmentpctg2 predicted2 equal state _est_clusteredOLS _est_est3 _est_est4 _est_re
save "/Users/Alfonso/Google Drive/Berkeley/ra_task_files/hbfinal.dta", replace

