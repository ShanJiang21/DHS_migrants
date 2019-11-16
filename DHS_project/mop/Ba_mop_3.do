
*===========================================================================================*=====*
* Migrating Out of Poverty: 2013 survey data 
* In total, interviewed 905 households with migrants 
*                       300 households without migrants 
* BNG-PUBLISHED_MIGRANT_NONMIGRANT_HH:contain data of household level with 1205 observations (households) and 96 variables corresponding to the questions 1, 3 and 46a, questions 51 to 61, questions 65 to 74.
* BNG-PUBLISHED_MIGRANT_NONMIGRANT_HH_MEMBER: contains household member level data with 6104 observations (household members) and 108 variables corresponding to the questions 5 to 50 (excluding question 46a), questions 75 to 94.
* BNG-PUBLISHED_MIGRANT_NONMIGRANT_HH_INCOME: contains household income source data of 1,205 households and 13 income sources (= 15,665 observations) corresponding to the questions 62 to 64.*
*
*=================================================================================================*


clear all
set more off

* Define a global directory 

global path "/Users/shan/Projects/DHS_project/mop/Migrating out of poverty 2013"


********************************
* I.  Data preparation 
********************************

use "BNG-PUBLISHED_MIGRANT_NONMIGRANT_HH_MEMBER.dta"
sort HHID

* Merge Individual household member data with household data 

merge m:1 HHID using "$path/BNG-PUBLISHED_MIGRANT_NONMIGRANT_HH.dta" 
*  All matched:  6,104  (_merge==3)


********************************
* II.  Variable preparation 
********************************

** 1. Migration variable :Q5, Q6| cb_1, cb_2
* Clean missing values 
foreach v in q5 q6 q19 q20 q21_1 q21_2 q21_a q23_1 q23_2 q23_3{
    replace `v' = . if `v' == 88
  } 


*** a. <outmgt> <outmgt2> Internal vs International migrants 
* use cb_1: Describes whether the household has an internal, international, regional or no migrant
* opt1: <outmgt> New variable from Q5 and original as cb_1 for defining current-out migrant 
gen outmgt = 1 if q5 == 1  
replace outmgt = 0 if  outmgt == .  
label variable outmgt "current-out migrants"
tab outmgt, m 

* opt2: <outmgt2> as 2nd version of current migrants, gen from cb_2, value 1 = "current migrants" 
tab cb_2, m 
gen outmgt2 = 1 if cb_2 == 1
replace outmgt2 = 0 if  outmgt2 == . 
tab outmgt2, m 

*** b. <rtnmgt> return migrant
* opt1: <retmgt> using q6 compare with cb_2 (original variable) 
gen retmgt = 1 if q6 == 1
replace retmgt = 0 if  cb_2 == 1
label define rtn 1 "return migrants" 0"current migrants" 
label variable retmgt "current migrants vs return migrants"
label value retmgt rtn

tab retmgt, m 

* opt2: <retmgt2> 2nd version of returned migrants, value 2 = "returned migrants"
gen retmgt2 = 1 if cb_2 == 2
replace retmgt2 = 0 if  retmgt2 == . 
tab retmgt2, m 

*** c. <mg> migrants(current & returned) vs Non-migrants

gen mg = 1 if outmgt == 1 | retmgt  == 1
replace mg = 0 if mg == .
label define mgt 1 "migrants" 0 "non migrants"
label value mg mgt 
label variable mg "migrants vs non-migrants"

tab mg, m 

* 19% migrants in the dataset (Individual: 4,932 non-migrants, 1,172 migrants)
* 68.68% migrants household(cb_2) and only 575(9.42 %) are returned migrant household.


*** d.  Household International migrants vs. Household Internal migrants (for current migrant only)

* opt 1: Within current migrants, household migration status: 
tab cb_1 if outmgt == 1, m 
gen outintnl = 1 if cb_1 == 2 & outmgt == 1
replace outintnl = 0 if cb_1 == 1 | cb_1 == 3
label define ret 1 "international migrants" 0 "internal migrants"
label variable outintnl "International migrants hh vs Internal hh"
tab outintnl, m 

*  Internal: 2,515, 41.20% 
*  international migrants: 419,  6.86 %

* opt 2: use destination as proxies:
* <q21_1> specified for migration destination by country 

tab q21_1, m 
tab q21_1 if outmgt  == 1, m  


* Destination foreign country: 576 international migrants out of 1,056 migrant individuals. 
* among 576 subjects, 481 international migrants are being currently out. 

* <q21_2> city
 tab q21_2, m
 tab q21_2 if outmgt  == 1, m  
 
* dhaka is the most popular destination for internal migrants,  41 % in 575 subjects. 

* <q21_a> visa type 
 replace q21_a = . if q21_a == 77 | q21_a == 8
 tab q21_a 
 tab q21_a if outmgt  == 1, m 
 * 479 claimed visa type within those who are currently out migrants. 
 

*** e. international migration vs. internal migration(for return migrants) 
tab cb_1 if retmgt == 1, m 
gen retintnl = 1 if cb_1 == 2 & retmgt == 1 
replace retintnl = 0 if cb_1 == 1 | cb_1 == 3
label value  retintnl ret 
tab retintnl, m 

* Verfication:
sort HHID
by HHID: egen sumret = total(retintnl)
tab  sumret
dis 3 + 13 + 14 + 19 + 14  + 4 + 8 + 1 + 3 
* 1205 households, 79 households out of 1205 hh are intnl migrants-hh. 


 gen inthh = 1 if  cb_1 == 1
 replace inthh = 0 if inthh == . 
 label variable inthh "Internal migrants household"
 
 gen globalhh = 1 if  cb_1 == 2
 replace  globalhh =  0 if  globalhh == . 
 label variable globalhh "International  migrants household"
 
 gen reghh = 1 if  cb_1 == 3
 replace reghh = 0 if  reghh == .
 label variable reghh "Regional migrants household"
 tab q21_a if retmgt  == 1, m  
 * 96 claimed visa type within those who are returned migrants. 
 
**** 2. Occupation variables for CURRENT MIGRANTS(1,056 respondents)

* a. Main activity (q31)
tab q31 
*  1,182  not match 1,056, most were in education or as casual employee

* b. Type of occupations (q37)
tab outmgt, m 
* 1056 respondents

foreach v in q37{
    replace `v' = . if `v' == 88 | `v' == 77
  } 
*1053 non-missing respondence

* Recode as 3 categories 
gen occup = 1 if inlist(q37,1,2, 3, 4, 5, 6, 12,13 )
replace occup = 2 if inlist(q37, 7, 8, 9, 10, 11, 14, 15)
replace  occup = 3 if q37 == 25

label define occup 1 "Physical labor" 2 "Service or business"  3  "others"
label value occup occup
label variable occup "occupation status"
tab occup, m

* validating the migrants' identity (consistent)
tab occup outmgt, col 
tab occup outmgt2, col 

* c. Nature of Occupation (q37a)
* validating the migrants' identity (consistent)
replace q37 = . if q37 == 77 | q37 == 88 
* Groups: 
* agriculture-related; 
* business; 
* Manual worker; 

tab q37a, m 
tab q80a, m 
gen ocpnature = q37a if q5 == 1
replace ocpnature =  q80a if  q6 == 1
replace ocpnature = . if ocpnature == 5 | ocpnature == 6 | ocpnature == 8 | ocpnature == 9 | ocpnature == 10 | ocpnature == 12 | ocpnature == 13
label define ocup 1 "private individual" 2 "private company" 3 "government" 4"semi-government" 25"other"
label value ocpnature ocup
tab ocpnature retmgt, col chi2



**** 3. Migration Experience variables for RETURNED MIGRANTS(126 respondents)

* < Q79-Q82, Q85a - Q85d, Q86a - Q86d>
tab retmgt, m //(126 respondents)

* < Q79-Q82>
* a. wanted paid-work but could not find it (q79)
tab q79, m 

* b. Occupation status in most-recent migration 

* Recode as 3 categories 
tab q80, m 
gen occuprtn = 1 if inlist(q80,  9, 10, 11, 12, 8, 13) 
replace occuprtn = 2 if inlist(q80, 1, 3, 4, 5)
replace occuprtn = 3 if inlist(q80, 6, 12)
replace  occuprtn = 4 if q80 == 25

label value occuprtn occup 
label variable occuprtn "occupation status in most-recent migration period"
tab occuprtn, m //  48.80 % work in labor-related jobs 

* c. Nature of occupation in most-recent migration(q80a)
tab q80a, m 
 
* d. monthly income in most-recent migration(q81)
summarize q81

* e. Receive any of the following benefits at work(q82a - q82c??)
replace q82a = . if q82a == 74

* f. obtain any educational or work qualifications, or training(q83)
tab q83, m 

* g. The highest level of qualification received during this period (q84: applicable 25 respondents)
tab q84, m 

* h. (q85a - q85d)Time away, exposed to negative experiences within the workplace:
* Caution: Very few observations 

label list LABX
replace q85a = . if q85a == 25
 tab q85a, m 
replace q85b = . if q85a == 0 

replace q85c = . if q85c == 88
replace q85d = . if q85d == 88

* Generate 10 abuse variables 
foreach var of numlist 1/10  {
  generate abuse`var' = 1 if q85a  == `var' | q85b == `var'| q85c == `var' | q85d == `var'
  replace abuse`var'   = 0 if abuse`var'  == . 
}

* i: (q86a - q86d) OUT of WORK: experience any of the following negative experiences

foreach v in q86a q86b q86c q86d{
    replace `v' = . if `v' == 88 | `v' == 16
  } 

* Generate 10 OUT of work abuse variables 
foreach var of numlist 1/10  {
  generate offabuse`var' = 1 if q86a  == `var' | q86b == `var'| q86c == `var' | q86d == `var'
  replace offabuse`var'   = 0 if offabuse`var'  == . 
}
  
* Rename variables 
* (1)Verbal abuse 
label  variable abuse1  "Verbal abuse"
label  variable offabuse1  "Verbal abuse"
tab abuse1, m 

* (2)Sexual Abuse
label  variable abuse2  "sexabuse"
label  variable offabuse2  "sexabuse"
* (3)Physical abuse
label variable abuse3  "Physical abuse"
label  variable offabuse3  "sexabuse" 

* (4)physical injury 
label variable abuse4  "physical injury" 
label variable offabuse4 "physical injury"

* (5)Hazardous chemicals (4) 
label variable abuse5 "Hazardous chemicals" 
label variable  offabuse5 "Hazardous chemicals" 

* (6)Racial discrimination (13)
label variable abuse6  "Racial discrimination" 
label variable  offabuse6 "Racial discrimination" 
* (7)Religious discrimination (9) 
label variable abuse7  "Religious discrimination"
label variable offabuse7 "Religious discrimination"
* (8) gender discrimination
label variable abuse8  "gender discrimination"
label variable offabuse8 "gender discrimination"
* (9) Occupational discrimination
label variable abuse9  "Occupational discrimination"
label variable  offabuse9  "Occupational discrimination"
* (10) No negative experiences ( 86 )  
label variable abuse10 "No negative experiences"
label variable offabuse10 "No negative experiences"

foreach var in abuse1-abuse2 {
  tab `var' , m 
}



**** III. Demographics (q8 - q13, q17, Q18, q84 )
 
* 1. Female (q8)  47.23 % 

gen female = 1 if q8 == 2
replace female = 0 if q8 == 1
tab female, m 


* 2. Age of migrants 

table female, contents(freq mean q9 ) 

* 3. Marriage Status 
tab q10, m 

* 2,987 has children 


* 4. Religion 
 tab q15, m 
 
* muslim 93.76 % 

* 5. Urban vs. Rural variable (??)


*** IV. Analysis restricted to migrants 

* mg inthh globalhh reghh

* REMITTANCES

