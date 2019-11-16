
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


********************************************************
* I.  Data preparation & Variable preparation 
********************************************************

use "$path/BNG-PUBLISHED_MIGRANT_NONMIGRANT_HH_MEMBER.dta", clear 
sort HHID

****** Merge data household data with 2 other datasets *******
* Merge 1st data--Individual household member data  

merge m:1 HHID using "$path/BNG-PUBLISHED_MIGRANT_NONMIGRANT_HH.dta" 
*  All matched:  6,104  (_merge==3)
drop _merge 

save "$path/mopfull.dta", replace

****************** 1. Migration variable: used Q5, Q6 
* Clean missing values 
foreach v in q5 q6 q19 q20 q21_1 q21_2 q21_a q23_1 q23_2 q23_3{
    replace `v' = . if `v' == 88
  } 

*** a. <outmgt> Current-out Migrants 
* use q5: is  currently living away from household 
* Define: <outmgt> New variable from Q5, 1337 missing value  

gen outmgt = 1 if q5 == 1  
replace outmgt = 0 if  q5 == 0
label variable outmgt "current-out migrants"
label define out 1 "current-out" 0 "Not out residents"
label value outmgt out 
tab outmgt, m 


*** b. <rtnmgt> return migrants
* Define by q6: <retmgt> using q6 

gen retmgt = 1 if q6 == 1
replace retmgt = 0 if q6  == 0

label define rtn 1 "return migrants" 0"residents" 
label variable retmgt "residents vs return migrants"
label value retmgt rtn

tab retmgt, m 


*** c. <mg> Migrants(General migrants: current & returned) vs Non-migrants

gen mg = 1 if outmgt == 1 | retmgt  == 1
replace mg = 0 if outmgt == 0 & retmgt  == 0
label define mgt 1 "general migrants" 0 "non migrants"
label value mg mgt 
label variable mg "general migrants vs non-migrants"

tab mg, m 

* 19.36% general migrants in the dataset (Individual: 4,932 non-migrants, 1,172 migrants)

*********** Household migration status summary 
 preserve
 collapse (sum) cb_2, by(HHID)
 restore 

gen cb3 = 1 if cb_2 == 2 | cb_2 == 1
replace cb3 = 0 if cb3 == . 
preserve
collapse (sum) cb3, by(HHID)
gsort - cb3
restore 

** 1. 112 households have one or more family members as returned migrants out of 1205 migrant households.  
** 2. So, we use the variable q6 instead of cb_2 as it is more related with the section for returned migrants in the questionnaire.  
** 3. In total, 905 households with migrants and 300 households without migrants were interviewed.

*** d.  Household International migrants vs. Household Internal migrants (for current migrant only)

* <domestic> use migration destination as proxies:
* Define by (q21_1:country) and (q21_2 city)
* specified migration destination country (other than Bangladesh) and cities(Within Bangladesh)

tab q21_1, m 
tab q21_1 if outmgt  == 1, m  
gen domestic = 0 if q21_1 != .
replace domestic  = 1 if q21_2 != . 
* keep the identity of domestic residents if they are not migrants 
replace domestic  = 1 if mg == 0
tab domestic outmgt, m  

* Destination foreign country: 576 international migrants out of 1,182 migrant individuals. 
* For Domestic Analysis, we can only use the 606 subjects. 

tab q21_2, sort
 
* dhaka is the most popular destination for internal migrants,  74 % in 606 subjects.

 replace q21_a = . if q21_a == 77 | q21_a == 8
 tab q21_a domestic, col 
 
* 66.38% of international migrants have company visa.   
 
* Verfication:
sort HHID
preserve
collapse (sum) domestic, by(HHID)
tab domestic
dis 1205 -  744
restore 

* 461 households out of 1205 hh are intnl migrants-(at least one international migrant in hh)


* <globalhh> generate from cb_1 - International  migrants household

 gen globalhh = 1 if  cb_1 == 2 | cb_1 == 3
 replace  globalhh =  0  if cb_1 == 1 
 label variable globalhh "International migrants household"
 tab globalhh, m 

* 748 households out of 1205 hh have their identity as "International migrants household"


********** 2. Occupational variables 

****** Before migration 
* a. Main activity before migration in Original place (q31)
tab q31 
gen orgjob = 1 if q31 == 6
replace orgjob = 2 if inlist(q31, 1, 2, 3)
replace orgjob = 3 if q31 ==  4
replace orgjob = 4 if q31 ==  7 | q31 ==  8 
replace orgjob = 5 if q31 ==  25 | q31 ==  88 

label define orgjob 1 "studying" 2 "paid job"  3  "unpaid job" 4 "unemployed" 5 "other"
label value orgjob orgjob
label variable orgjob "original job"
tab orgjob, m

*   33.25% among 1,182 migrants who were in education before migrating. 

* b. Type of occupations before migration in Original place (q32)
tab outmgt, m 
* 1056 respondents


** Recoding for occupation 
*  (job) Recoding the occupation status 
*=================================

* 6 categories(job): 
  * agricultural related(6) ;
  * manufacturing (9,10, 11);
  * service (4, 5, 12, 13);
  * manual labor ( 7, 8 );
  * professional & managerial (1, 2, 3);
  * Others (25)

* agricultural
gen ojob = 1 if inlist(q32, 6)
* home manufacturing/skilled worker
replace ojob = 2 if inlist(q32, 7,10, 11)
* service 
replace ojob = 3 if inlist(q32, 4, 5, 12, 13) 
* manual worker
replace ojob = 4 if  inlist(q32, 8, 9) 
* professional & managerial
replace ojob = 5 if inlist(q32, 1, 2, 3) 
* others 
replace ojob = 6 if inlist(q32, 25)


label variable ojob "original occupation status"

* Define labels 

label define ojob 1"agricultural" 2"home manufacturing" 3"service" 4"manual labor" 5"professional & managerial" 6"other"
label values ojob ojob

tab ojob, sort 
* 32.68 % workers were doing agricultral jobs before migration. 


*** Current: after migration
  
*  c. <job> (q37: migrant’s current occupation?)

replace q37 = . if q37 == 77 | q37 == 88 

* 1053 non-missing respondence

* Recode as 6 categories 
  * agricultural related(12) ;
  * home manufacturing/skilled worker
  * service 
  * manual labor
  * professional & managerial 
  * Others (25)
* agricultural
gen job = 1 if inlist(q37,12)
* home manufacturing/skilled worker
replace job = 2 if inlist(q37, 1, 3, 4, 11)
* service
replace job = 3 if inlist(q37, 5, 6, 10)
* manual labor
replace job = 4 if inlist(q37, 2, 13)
* professional & managerial & business ;
replace  job = 5 if inlist(q37, 7, 8, 9, 14, 15)
* others  
replace  job = 6 if q37 == 25

label value job ojob
label variable job "current occupation status"
tab job, m


* d. Nature of Occupation (q37a:current-out migrants + q80a: for returned migrants)
* validating the migrants' identity (consistent)

* categories: 
* agriculture-related; 
* business; 
* Manual worker; 

tab q37a, m 
tab q80a, m 
gen jobnature = q37a if q5 == 1
replace jobnature =  q80a if  q6 == 1
replace jobnature = . if  inlist(jobnature, 5, 6, 8 , 9 , 10, 12, 13)
label define jobn 1 "private individual" 2 "private company" 3 "government" 4"semi-government" 25"other"
label value jobnature jobn


* e. Employ-Related Income: Money earned each month (before and after)  
foreach var in q33 {
  sum `var' , detail 
}


************* Migration Experience variables (Varibles restricted to returned migrant)
*  for RETURNED MIGRANTS(126 respondents)
* < Q79-Q82, Q85a - Q85d, Q86a - Q86d>

* < Q79-Q82>
* a. wanted paid-work but could not find it (q79)
tab q79, m 

* b. Occupation status in most-recent migration 

* Recode as 3 categories 
tab q80, m 
gen retjob = 1 if inlist(q80, 6)
* home manufacturing/skilled worker 
replace retjob = 2 if inlist(q80, 8)
* service
replace retjob= 3 if inlist(q80, 4, 5)
* manual worker 
replace retjob= 4 if inlist(q80, 9, 10)
* professional & managerial ;
replace retjob= 5 if inlist(q80, 3, 1)
replace  retjob = 6 if q80 == 25

label value retjob ojob
label variable retjob  "occupation status in most-recent migration period"
tab retjob, m

* c. Nature of occupation in most-recent migration(q80a)
tab q80a , m 
 
* d. monthly income in most-recent migration(q81)
summarize q81, detail 

* e. Restricted to Return Migrants: Receive any of the following benefits at work(q82a - q82c)
*    Generate binary variables based on the multiple choice 

gen holidays = 1 if q82a == 1 | q82b == 1 | q82c == 1

gen sickleave = 1 if q82a == 2 | q82b == 2 | q82c == 2

gen  ssecurity = 1 if q82a == 3 | q82b == 3 | q82c == 3

gen  uniform = 1 if q82a == 4 | q82b == 4 | q82c == 4

gen  meal = 1 if q82a == 5| q82b == 5 | q82c == 5

gen transport = 1 if q82a == 6 | q82b == 6 | q82c == 6

gen  lodging = 1 if q82a == 7 | q82b == 7 | q82c == 7

gen  otherbenefit = 1 if q82a == 25 | q82b == 25| q82c == 25

egen temp_sum3 = rowtotal(holidays sickleave ssecurity uniform meal transport lodging otherbenefit)

gen benefit  = 1 if temp_sum3 == 0 
replace benefit  = 1 if inlist(temp_sum3, 1, 2, 3, 4) 
tab benefit, m 

tab benefit retmgt if domestic ==1 , m 



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

* <temp_sum1> A temporary variable for checking the diversity of in-work abuse for the same individual 
 egen temp_sum1 = rowtotal(abuse1-abuse9)

* --> We can see there are 30 people (n = 126) who experienced multiple types of abuse in their work 

* <workabuse> Generate offabuse variable if experienced any kind of abuse outside of work (at least one abuse)

gen workabuse = 0 if temp_sum1 == 0 
replace workabuse = 1 if inlist(temp_sum1, 1, 2, 3, 4) 
tab workabuse, m 


 
 
* i: (q86a - q86d) Outside of WORK: experience any of the following negative experiences

* missing value 
foreach v in q86a q86b q86c q86d{
    replace `v' = . if `v' == 88 | `v' == 16
  } 

* Generate 10 OUT of work abuse variables 
* Generate Sum score for Abuse variables
foreach var of numlist 1/10  {
  generate offabuse`var' = 1 if q86a  == `var' | q86b == `var'| q86c == `var' | q86d == `var'
  replace offabuse`var'   = 0 if offabuse`var'  == . 
}

* <temp_sum2> A temporary variable for checking the diversity of off work abuse for the same individual 

egen temp_sum2 = rowtotal(offabuse1-offabuse9)

* --> We can see there are only 17 people (n = 126) who experienced multiple types of abuse outside of work 


* <offabuse> Generate offabuse variable if experienced any kind of abuse outside of work 

gen offabuse = 0 if temp_sum2 == 0 
* (at least one abuse)
replace offabuse = 1 if inlist(temp_sum2, 1, 2, 3, 4) 
tab offabuse, m 


* Rename variables 
* (1)Verbal abuse 
label  variable abuse1  "verbal abuse"
label  variable offabuse1  "verbal abuse"

* (2)Sexual Abuse
label  variable abuse2  "sexabuse"
label  variable offabuse2  "sexabuse"

* (3)Physical abuse
label variable abuse3  "physical abuse"
label  variable offabuse3  "physical abuse" 

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

* (10) No negative experiences ( 100 )  
label variable abuse10 "No negative experiences"
label variable offabuse10 "No negative experiences"

* (11) Any negative experience (22)
label variable workabuse "Any negative experiences in work"
label variable offabuse "Any negative experiences outside of work"



* j.<Q93a> Employment status during migration 
tab  q93a, m sort 

* Full-time worker 88.8% among returned migrants 

* k. <Q94> Reasons for returning to the original place of residence 
 tab q94, m sort 
 
* The top reason for the migrants to get back home is that their contract has ended; 

* L.  personal relationship with your family before you were away
tab q75 ,  m sort 
tab q76 , m sort 
tab q77, m sort


******************* III.Demographic & SES information (q8 - q13, q17, Q18, q84 )
 
* 1. Female (q8)  47.23 % 

gen female = 1 if q8 == 2
replace female = 0 if q8 == 1
tab female, m 

* 2. (q9) Age of migrants 

table female, contents(freq mean q9 ) 
* agegroup codes: 6 groups 
  gen agegroup = q9 
  recode agegroup  (0/5 =1) (6/14 = 2) (15/20= 3) (21/34=4) (35/50=5) (51/65 = 6)(66/max= 6)
  label define agegroup 1 "0-5" 2 "6-14"  3 "15-20" 4 "21-29" 5 "35-50" 6"51-65"7"66+" 
  label values agegroup agegroup
  tab agegroup,  m 

* 3. (q10) Marriage Status 
tab q10, m sort

* < minor >: for child marriage 
gen minor = 1 if q10 ==  6
replace minor = 0 if q10 != 6
label define minor 1 "child marriage" 0 "non child marriage" 
label values minor minor
tab minor, m 

* 4. <q15: muslim> Religion 
 tab q15, m sort 
gen muslim = 1 if q15 ==  1
replace muslim = 0 if q15 != 1
 
* muslim 93.76 % 

* 5. (q17) Education
replace q17 = . if q17 == 88 | q17 == 25

* a. sign
gen sign = 1 if q17 == 1
replace sign = 0 if q17 != 1 & q17 != .

* b. edu 
* No edu
gen edu = 1 if q17 == 1
* primary/little edu
replace edu = 2 if inlist(q17, 2, 3) 
* junior high school
replace edu = 3 if inlist(q17, 4) 
* junior high+
replace edu = 4 if inlist(q17, 5, 6, 7, 8, 9, 10)
* undergrad+(contain undergrad)
replace edu = 5 if inlist(q17, 11, 12, 13)
* post-grad
replace edu = 6 if inlist(q17, 14)

* c. education received years 
replace q18 = . if q18 == 88
gen illi = 1 if q18 == 1
replace illi = 0 if q18 != 1 & q18 != .

* d. <eduyr>(define a binary variable -- received any education?  year = 0 | > 0 )

gen eduyr = 1 if q18 > 0
replace eduyr = 0 if q18 == 0 

* e. Income (q81, restricted to returned migrants) 
  codebook q81
  sum q81, detail 
  
  * Use 20% and 40% quintile as poverty line
  xtile income = q81, nq(5)

* 6. <q11: child> Household with children  
tab q11, m 

gen child  = 1 if q11 == 1 
replace child = 0 if q11 == 0 
replace child = . if q11 == 88

sort HHID
preserve
collapse (sum) child, by(HHID)
tab child, m 
restore 

* Out of 1205 households, 98.26% household have children, only 21 household do not have children. 

* Family size 
sort HHID
preserve
collapse (mean) q3, by(HHID)
tab q3, m sort 
sum q3
restore
* The Average family size of sample is 5.06556, most common size falls between 3-6 people.  



* 7. =** Assets and Facilities =**

* a. land ownership (q51_1a -  q51_1d )
* b. house ownership, size, no. of rooms (q52, q53 and q54)

preserve 
collapse (sum) q52, by(HHID)
tab q52, m 
*  77(6%) hh do not own the house 
restore 

* c. electricity 
replace q55 = . if q55 == 2 | q55 == 3 | q55 == 6 
gen electricity = q55 
tab electricity, m 

* 8. =** Access to drinking water and sanitation =**

*  a. <q60: impwater> water access: Main source of drinking water 
   tab q60, m sort
   gen impwater  = 1 if inlist(q60, 1, 2, 3, 5) 
   replace impwater = 0 if inlist(q60, 4)
   label define impwater  0 "Unimproved drinking water" 1 "Improved drinking"
   label values impwater impwater
   tab impwater, m 

*  b. <q61: toilet> Imporved toilet facility vs unimproved toilet facility 
  tab q61, m sort
  gen toilet = 1 if  inlist(q61, 1,2,3,4)
  replace toilet = 0 if inlist(q61, 5, 25)
  label variable  toilet "Imporved toilet facility vs unimproved toilet facility"
  label define toilet 0 "unimproved facility"  1 "Improved facility"   
  label value toilet toilet 
  tab toilet, m 
 
 * d. <q71a: Child’s access to health services>
 replace q71a =. if q71a == 88
 tab q71a, m 
 

* 9. Income and econ decisions 
 
 * a. Top 3 choices for household Income use: 
 tab q65a, m sort 
 tab q65b, m sort 
 tab q65c, m sort 
 
 * b. Financial decisions 
  tab q66, m sort 
  *  42.61 % are father dominant structure, even higher than migrants themselves 
  
 * c. subjective evaluation for economic conditions: 
 
 * <q67-q69,q71> Life experience/financial situation/household living
  tab q67, m sort 
  tab q68, m sort 
  replace q71 =. if q71 == 77
  tab q71, m sort 
  
 * <q72, q73, q74a,q74c> : daily life/ hh'd daily life/judgement for migrants
   tab q74a ,  m
   tab q74c,  m 
  
  * The migration led to the improvement of the life quality of the 
  * lef-behind women, which accounts for 62%. 
 
  
 * d. Level of house debt (q69_a1)
 * e. Right to access Land (q70)
  tab q70, m 
  replace q70 =. if q70 == 88


*****************************************************************************
/* III Analysis: General. Domestic Migrants vs. nonmigrants comparison */ 
*****************************************************************************

************ Demographic Basic Information **************
* 1. Out of 1205 households, 98.26% household have children, 
* only 21 household(1.7%) does not have children. 

* 2. The Average family size of sample is 5.07, most common size falls between 3-6 people. 

* 3. Among the 1,182 current-out migrants, 576(48.73%) chooose international destinations, domestic is around 51.27%. 
 
preserve
keep if domestic == 1

****Demographics

* Categorical variables 
foreach var of varlist female agegroup muslim illi edu eduyr minor q10 child electricity{
    tab `var', m
	tab `var' mg, col chi2
}

* Continuous variables: age (in years) and education years 
foreach var of varlist q9 q18{
	sum `var', detail
	ttest `var', by(mg)
}

*restricted to men.
foreach var of varlist female agegroup muslim illi edu eduyr minor q10 child electricity{
    tab `var' if female== 0, m
}


***Life Experience Varibles: Restrict to one observation per household in migrants
bysort HHID: gen temp=_n
anova q67 if temp==1
tab q67 mg if temp==1, col chi2
tab q68 mg if temp==1, col chi2
drop temp

***Health Facilities
foreach var of varlist impwater toilet q71a{
tab `var', m
tab `var' mg, col chi2
}

***SES:
 hist q69_a1 if q69_a1 < 200000, freq sort discrete by (retmgt ) color(blue) 
 hist q69_a1 if q69_a1 < 200000, freq sort discrete by (outmgt ) color(blue) 
 
 restore
 
 
************************************************************************
/* IV. Analysis: Restricted to Domestic current-out MIGRANTS (n = 575 ) */
************************************************************************

tab outmgt domestic, m 
*  575 domestic current-out MIGRANTS and 481 transborder current-out MIGRANTS

preserve
keep if domestic == 1

* validating the migrants' identity (consistent)
tab ojob outmgt, col 
tab job outmgt, col 

****Demographics

* Categorical variables 
foreach var of varlist female agegroup muslim illi edu eduyr minor q10 child electricity{
    tab `var', m
	tab `var' mg, col chi2
}

* Continuous variables: age (in years) and education years 
foreach var of varlist q9 q18{
    sum `var', detail 
	ttest `var', by(outmgt)
}

*restricted to men.
foreach var of varlist female agegroup muslim illi edu eduyr minor q10 child electricity{
    tab `var' if female== 0, m
	tab `var' outmgt, col chi2
}

*Health Facilities
foreach var of varlist impwater toilet q71a{
tab `var', m
tab `var' outmgt, col chi2
}

****Occupational Variables 

* Life experience: subjective evaluation of quality of living 
foreach var in  q67 q68 {
    replace `var' = . if `var' == 88 
    anova `var' outmgt
 
}

**Visual: Age difference: Restricted within Domestic MIGRANTS (606 respondents)
     graph box q9 , over(outmgt)

** Occupation Type: 
 graph hbar, over(job, label(labsize(small)) relabel(`r(relabel)')) ///
 title("Percent of current-out migrants: job occupation type", size(small)) ///
 blabel(bar, format(%4.1f)) ///
 intensity(25) 
 
* Life quality
 graph hbar, over(q67, label(labsize(small)) relabel(`r(relabel)')) ///
 title("Life quality evaluation compared with five years ago", size(small)) ///
 blabel(bar, format(%4.1f)) ///
 intensity(70) 

 graph hbar, over(q68, label(labsize(small)) relabel(`r(relabel)')) ///
 title("Now vs five years ago, how would you describe your household’s financial situation?", size(small)) ///
 blabel(bar, format(%4.1f)) ///
 intensity(70) 
 
restore 
  


*********************************************************************
/* IV. Analysis: Restricted to Domestic Returned MIGRANTS (n = 31) */
*********************************************************************

*****Preliminary Test between domestic return migrants and domestic non-return migrants 
***Demographics

* Categorical variables 
foreach var of varlist female agegroup muslim illi edu eduyr minor q10 child{
    tab `var', m
	tab `var' retmgt if domestic == 1 , col chi2
}

* Continuous variables: age (in years) and education received years 
foreach var of varlist q9 q18{
    sum `var', detail 
	ttest `var'  if domestic == 1, by(retmgt)
}

*restricted to men.
foreach var of varlist female agegroup muslim illi edu eduyr minor q10 child{
    tab `var' if female== 0 & domestic == 1, m
	tab `var' retmgt if domestic == 1 , col chi2

}

*****Analysis Restricted within domestic Returned MIGRANTS (31 respondents)
   preserve
   keep if retmgt == 1  & domestic == 1 

***Occupational variables
*Job type and reason quitting
foreach var of varlist q93a q94{
    tab `var', m 
}
 
*Work/off work Experience: Abuse /  Benefits 
foreach var of varlist workabuse offabuse benefit {
    replace `var' = . if `var' == 88 
    tab `var', m 
}
 
***Life experience: subjective evaluation of quality of living 
foreach var in  q67 q68 {
    replace `var' = . if `var' == 88 
	tab `var', m 
 
}

***Income 
  * Distribution of income: Compare with wealth index in DHS, 
  * --> several outliers 
  histogram q81, bin(40) normal frequency fcolor(ltbluishgray) lcolor(%89)

  * Gender difference 
  graph box q81, over(female)
  
  * Wilcoxon rank-sum test test:
  ranksum q81, by(female)
  *--> Significant income difference between Male and female domestic returned migrants

restore 
    
**************************************************************************************************
/* V Analysis: Restricted to migrants within poverty in Domestic Returned MIGRANTS (n = 24)*/ 
**************************************************************************************************

*** Income 
sum q81, detail

* Characteristics and standards of living among migrants in poverty (wealth in the two lowest categories--quintiles)

preserve
keep if domestic == 1 & (income == 1 | income == 2) 

***Demographics
*Categorical variables 
foreach var of varlist female agegroup muslim illi edu eduyr minor q10 child{
    tab `var', m
	tab `var' mg, col chi2
}

*Continuous variables: age (in years) and education received years 
foreach var of varlist q9 q18{
    sum `var', detail 
}

*restricted to men.
foreach var of varlist female agegroup muslim illi edu eduyr minor q10 child{
    tab `var' if female== 0, m
}

***Occupational variables 
*Job Type and quit reason 
foreach var of varlist q93a q94{
    tab `var', m 
}

*Work/off work Experience: Abuse 
foreach var of varlist workabuse offabuse{
    replace `var' = . if `var' == 88 
    tab `var', m 
}

***Life experience: subjective evaluation of quality of living 
foreach var of varlist q67 q68 {
    replace `var' = . if `var' == 88 
    tab `var', m 
 
}

restore



****Note: 
* 1. Child Marriage is defined as a marriage of a girl or boy before the age of 18 and refers to both formal marriages/informal unions in which children under the age of 18 live with a partner as if married. 
* Bangladesh has the highest rate of child marriage in Asia (the fourth highest rate in the world).

* Characteristics and standards of living among migrants in poverty (income in the two lowest categories--quintiles)
****  Define the Quintile income, restricted to the Poor people analysis 

*  The facility data cannot be used as of the current status of the residents instead of at migration destination. 

****Reference: 
* 1. Raj, A. (2010). When the mother is a child: the impact of child marriage on the health and human rights of girls.
