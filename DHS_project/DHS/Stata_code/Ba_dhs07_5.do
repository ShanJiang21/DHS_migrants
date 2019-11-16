
*===========================================================================================*=====*
*Individual-level data (men and women) include only EVER MARRIED people.
*=================================================================================================*


clear all
set more off

* The default maximum is 5000, enlarge the dataset list; 
set maxvar 10000

* Define a global directory 

global path "/Users/shan/Projects/DHS_project/DHS/BD_2007_DHS_06202019_2057_135629"


********************************
/*I.  Data preparation*/ 
********************************

/* Import Male data: BDMR51FL.DTA and Append Female's Data: BDIR51FL.DTA */ 

*==============Merge Household dataset and individual dataset====================
* Before merge the data, an overview of dataset:
* Female: 4322 variables, 10996 obs;
* Male:  628 variables, 3771 obs; 
* Household: 2502 variables, 10,400 obs;
* Combined fullsample: 7,452 variables, 14,767 obs. 
* ===============================================================================


* 1. Generate household-level in Male's dataset
use "$path/BDMR51DT/BDMR51FL.DTA"
describe mcaseid
format mcaseid

* 1.1 hhid: household-level id for merging Male and household data 
gen hhid = substr(mcaseid, 1, 12)
sort hhid
* format of hhid is %12s. 
label variable hhid "household id"


* 1.2 caseid: Generate the ID variable, for appending female data to male data  
gen caseid = mcaseid
label variable caseid "male caseid"

* 1.3  Generate gender variable 
gen male = 1 
label variable male "male"
* Save as male data 
save "$path/male.dta", replace

* 2 Generate household-level caseid in Female's dataset

* 2.1 hhid: household-level caseid for female
use "$path/BDIR51DT/BDIR51FL.DTA", clear 
gen hhid = substr(caseid, 1, 12)
sort hhid
* format of hhid is %12s. 

* 2.2 caseid: labelling case ID variable, for appending female data to male data  
label variable caseid "female caseid"

* Save as female data
save "$path/female.dta",replace


* 3 Data Transformation

* 3.1 Append Male's data to Female data

* Appending the Male dataset to Female data: 14,767 obs
append using "$path/male.dta" 
describe hhid
format hhid
sort hhid 
save "$path/fullsample.dta", replace

* 3.2 Merge with household-level data.   
use "$path/BDHR51DT/BDHR51FL.DTA", clear
replace hhid = substr(hhid, 1, 12)
format hhid 
sort hhid
* format of hhid is %12s. 

save "$path/hhold.dta", replace

use "$path/fullsample.dta", clear

* Merge household data with household data using key hhid
merge m:1 hhid using "$path/hhold.dta"

* Only keep eligible individuals (ever married) and group them by household id
drop if _merge == 2 

label variable hhid "household id"

* generate numeric variables nhhid as household ID and ncaseid as individual case id, transform the string variable 
encode hhid, gen (nhhid)
summarize nhhid

encode caseid, gen (ncaseid)
summarize ncaseid


* correction of labels for gender 
replace male = 0 if male ==. 
label define genl 0 "female" 1 "male"
label values male genl

label define sexl 1 "male" 2 "female"
label values hv104_01- hv104_40 sexl
label values hv219 sexl
label values mv134 LABG

* There are 9,289 households and 14,767 individuals in the dataset before further cleaning;


*****************************************************
/* II Variables creation */ 
*****************************************************

* Region 
tab mv101

* < Male: migration variables mv102 - mv135>
* v135: usual resident or visitor (2 = visitor)
 tab mv135, m 
 drop if mv135 == 2
 
* mv102: Type of Residence: restrict to individuals currently living in urban area 
codebook mv102
* mv102: label for urban-rural status 
label define mv102 1 "urban"  2 "rural"
label values mv102 mv102
tab mv102, m 

* MV104 - Men: years lived in place of res.
replace mv104 = . if mv104 == 99
drop if mv104 == 96 
* Drop obs: deleted 125 observations in "visitors" category
* 3,646 male 

* mv105:  type of place of previous residence.
* Missing value 
replace v105 = . if v105 == 9
tab mv102 mv105, m 

* < Female: migration variables v102 - v135>

* v135: usual resident or visitor ( 2 = visitor)
 tab v135, m 
 drop if v135 == 2

* V102: Type of Residence.
codebook v102 
label values v102 mv102
tab v102, m 

* v104: drop "visitors" category.
codebook v104
drop if v104 == 96  
* 859 observations deleted
 
* Relabel v105 like mv105
codebook v105
label define v105 1 "city"  2 "town" 3 "countryside"
label values v105 v105
tab v102 v105, m

* There are 9,289 households and 13,690 individuals after dropping visitors.


****** Migration variables ******** 							  

* (1) Binary | migrants vs. nonmigrants: mmigr and vmigr
* Definition: After excluding visitors, mv104 == "Always" as Non-migrants, vs. all others as migrants.

* <Male> mmigr: Male migrants = 1 vs. Male non-migrants = 0:
* 95 = "always"
 gen mmigr = 0 if mv104 == 95 
 replace  mmigr = 1 if (mv104 < 95 & mv104 != . ) & (male == 1)
 tab mmigr, m 
 tab mv104 if male == 1, m 

 
* <Female> vmigr: Female migrants = 1 vs. Female non-migrants = 0:
* 95 = "always"
 gen vmigr = 0 if v104 == 95 
 replace  vmigr = 1 if (v104 < 95 & v104 != . ) & (male == 0)
 tab vmigr, m 


* <Combined variable> a compiled variable: mg for Non-migrants vs migrants
gen mg = 0 if vmigr  == 0 | mmigr  == 0
replace mg = 1 if vmigr  == 1 | mmigr  == 1
label define mg 1 "Migrants"  0 "Non-migrants" 
label values mg mg 
tab mg, m 

** < Migration Variable 1: mg > denoting Non-migrants vs. Migrants for all individuals


* (2) Rural-urban migrants vs all non-migrants (rumg)
* Definition: After excluding visitors, set v105 == "countryside" as rural.

* vru: Female rural-urban migrants 1 vs. Female non-migrants = 0:

  gen vru = 1 if v102 == 1 &  v105 == 3 & (male == 0)
  replace vru = 0 if  mg == 0 & male==0
  tab vru, m 

* mru: Male rural-urban migrants 1 vs. Male non-migrants = 0: 

  gen mru = 1 if mv102 == 1 &  mv105 == 3 & (male == 1)
  replace mru = 0 if mg ==0 & male== 1
  tab mru, m 

 * rumg: rural-urban migrants 1 vs. non-migrants = 0:
 
  gen rumg = 1 if vru == 1 | mru   == 1
  replace rumg = 0 if   vru == 0 | mru  == 0
  label define rumg 1 "rural-urban migrants"  0 "Non-migrants" 
  label values rumg rumg 
  tab rumg, m 
  
  
 * (3) new migration variable (binary)— rural-urban migrants vs. urban non-migrants.
* 0. Currently living in urban (v102 1 = urban) and never lived previously in another place
* 1. previously living in rural (countryside) and currently living in urban (v102)

* <Female>: new_vru 
  gen new_vru = 0 if v102 == 1 & v104  ==  95 & male == 0
  replace new_vru = 1 if v102 == 1 & v105 == 3 & male==0
  tab new_vru, m
  
* <Male>: new_mru  
  gen new_mru = 0 if mv102 == 1 & mv104  ==  95 & male == 1
  replace new_mru = 1 if mv102 == 1 &  mv105 == 3 & male==1
  tab new_mru, m
  
* Combined
  gen new_ru = 0 if (new_mru == 0  & male  == 1)  | (new_vru == 0 &  male  == 0)
  replace new_ru = 1 if (new_mru == 1 & male  == 1)  | (new_vru == 1 &  male  == 0)
  label define new_ru 1 "rural-urban migrants"  0 "urban non-migrants" 
  label values new_ru new_ru
  tab new_ru, m 
 
 
  * (4) rural-urban migrants by duration of residence in current place.
  * <Female>: v104
  gen yrstay = v104 if male == 0
  * <Male>: mv104
  replace yrstay = mv104 if yrstay == .
  * Recode as banded
  tab yrstay if yrstay<95
  
  *roughly equal and commonly used intervals: 0-5; 6-10; 11-20; 21-50.
  gen ruyr=0 if new_ru==0
  replace ruyr=1 if new_ru==1 & (yrstay>=0 & yrstay<=5)
  replace ruyr=2 if new_ru==1 & (yrstay>=6 & yrstay<=10)
  replace ruyr=3 if new_ru==1 & (yrstay>=11 & yrstay<=20)
  replace ruyr=4 if new_ru==1 & (yrstay>=21 & yrstay<=50)
  label define ruyr 0 "urban nonmigrants" 1 "ru mig 0-5"  2 "ru mig 6-10" 3 "ru mig 11-20" 4 "ru mig 21-50"
  label values ruyr ruyr
  tab ruyr, m
  
save "$path/fullsample.dta", replace


******** Household assets & Wealth index (P276 No.109)***********	
							
 * Deal with missing values
 * Original questions: does your household have? (variable are ordered in line with questionaire answer)
 
 * a.(hv206 = electricity, hv207 = radio, hv208 = television, hv243a = mobile telephone) 
 label define assetl 1 "yes" 0 "no"
 label values hv206 - hv208 hv209 hv243a hv221 sh109g assetl 
 
 * Drop missing values 
 codebook hv206
 replace hv206 = . if hv206 == 9
 replace hv207 = . if hv207 == 9
 replace hv208 = . if hv208 == 9
 replace hv243a = . if hv243a == 9
 
 * b. (hv221 = has a telephone, hv209 = refrigerator,  sh109g = almirah, sh109h = table)
 codebook hv221
 replace hv221 = . if hv221 == 9
 replace hv209 = . if hv209 == 9
 replace sh109g = . if sh109g == 9
 replace sh109h = . if sh109h == 9
 
 * c. (sh109i = chair, hv243b = watch, hv210 = has a bicycle, hv211 = motorcycle )
 tab sh109i, m 
 tab hv243b, m 
 replace sh109i  = . if sh109i  == 9 
 replace hv243b  = . if hv243b   == 9
 
 tab hv210, m 
 tab hv211, m 
 replace hv210 = . if hv210 == 9
 replace hv211 = . if hv211 == 9
 
 * d. (hv243c =  has an animal-drawn cart, hv212 = car/truck, hv243d = boat with a motor, sh109p = rickshaw/van)

 tab hv243c, m 
 tab hv212, m 
 replace hv243c  = . if hv243c  == 9 
 replace hv212 = . if hv221 == 9
 
 tab hv243d, m
 tab sh109p, m
 replace hv243d  = . if hv243d  == 9 
 replace sh109p = . if sh109p == 9 

 
foreach var of varlist hv206 hv207 hv208 hv209 hv210 hv211 hv212 hv221 hv243a  hv243b  hv243c  hv243d  sh109h  sh109i  sh109p  sh109g {
replace `var'=. if `var'==9
} 

* Question 109.

gen asset = hv206 + hv207 + hv208 + hv209 + hv210 + hv211 +  hv212 + hv221 +  hv243a + hv243b + hv243c + hv243d + sh109h + sh109i +  sh109p + sh109g 


* Create asset quantiles
 xtile assetq=asset, nq(5)

*** Wealth index. 1 =  poorest to 5 = richest: exist in both female/male data

gen wealth= mv190 if male==1
replace wealth= v190 if male==0




*******************Demographic & SES information of household/individuals 

* 1 Sex

 * 1.1 hv219: Sex of head of household 
   tab hv219, m 
 
   * creating a summarized statistics (% of household head gender = male) by collapsing data 
   preserve 
   collapse hv219 , by (nhhid) 
   *  br 
   tab hv219, m
   restore 
   * Out of 9,289 households, 88.41 % households had their head as male. (Power structure)
 

 * 2 Age 
 
 * 2.1 hv220: Age of the head 
  preserve 
  collapse hv220 , by (nhhid) 
  label variable hv220 "hh head age"
  tab hv220, m
  restore 
 
 * 2.2 Generate age and agegroup (8 groups) variable for individuals 

 *     v012 : current age - respondent (Female)
 *     v013 : Age 5-year group (Female)
 *     mv012: current age - respondent (Male)
 * 	   mv013: Age 5-year group (Male)
 
  gen age = v012 if male == 0
  replace age = mv012 if male == 1
  tab age,  m 
  
 * agegroup codes: 1 = 15-19, 2 = 20-24, 3 = 25-29, 4 = 30-34, 5 = 35-39, 6 = 40-44 ,7= 45-49,8 = 50-54
  gen agegroup = v013 if male == 0
  replace agegroup = mv013 if male == 1
  label define agegroup 1 "15-19" 2  "20-24" 3  "25-29" 4 "30-34" 5 "35-39" 6 "40-44" 7 "45-49" 8 "50-54"
  label values agegroup agegroup
  tab agegroup,  m 
   
 
* 3 Marital status ( mv501, v501)
 
 gen marit =  mv501 if male == 1
 replace marit = v501 if male == 0 
 label define marit  1  "married" 3 "widowed" 4 "divorced" 5 "not living together"
 label values marit marit
 tab marit,  m 
 

* 4 Education 
* (v106, mv106)highest educational level (4 levels)
  replace  v106 = . if v106 == 9 
  replace  mv106 = . if mv106 == 9 
  gen edu_level = v106 if male == 0 
  replace edu_level = mv106 if male == 1
  label define edu 0 "no education"  1 "primary" 2 "secondary" 3 "higher"
  label values edu_level edu
  tab edu_level, m 
  
* (v107 mv107) years of education
   replace  v107 = . if v107 == 99
   replace  mv107 = . if mv107 == 99
   gen edu_yr = v107 if male == 0 
   replace edu_yr = mv107 if male == 1
   tab edu_yr, m 
 
* （v149， mv149) education attainment （6 levels)
   replace  v149 = . if v149 == 9
   replace  mv149  = . if mv149  == 9
   gen edu_atm = v149 if male == 0 
   replace edu_atm = mv149 if male == 1
   tab edu_atm, m 
   label define edu_a 0 "no education"  1 "incomplete primary" 2 "complete primary" 3 "incomplete secondary" 4 "complete secondary"   5 "higher"
   label values edu_atm edu_a
   
 
* 5 Religion 

* Religion (original info)
replace  v130 = . if v130 == 96 | v130 == 99
replace  mv130 = . if mv130 == 96
gen religion = v130 if male == 0 
replace religion = mv130 if male == 1
label define religion 1 "islam" 2 "hinduism" 3 "buddhism" 4 "christianity"
label values religion religion
tab religion, m 

* (religion2)(Binary as Muslim and non-Muslim)
gen religion2 = inlist(religion, 1)
tab religion2, m 
label define religion2 1 "muslim" 0 "non-muslim" 
label values religion2 religion2
tab religion2, m

* 6. Region(v134, mv134) using de facto place of living
 tab v134, m 
 tab mv134, m 
 gen region = v134 if male == 0 
 replace region = mv134 if male == 1 
 label define region 0 "capital, large city (sma,statistical metropolitan area)" ///
					 1 "small city (other urban)"	///
					 2 "town (municipality)"		///
					 3 "countryside (rural)"
label values region region
tab region, m 				
 
 * Recode as (Urban): denoting current living place in urban area 
 gen urban = inlist(region, 0, 1, 2)
 label define urban 1 "urban" 0 "rural" 
 label values urban urban
 tab urban, m 
 

* 7. Employment 

* 7.1 v714: Respondent currently working (Last seven days)
     
codebook v714
replace v714  = . if v714 == 9

gen cw = v714 if male == 0 
replace cw = mv714 if male == 1

label define cw 0 "no" 1 "yes"					
label values cw cw
tab cw, m


* 7.2 v731: Worked in last 12 months
 * (p319. 809 Have you done any work in last 12 months)
replace v731  = . if v731  == 9
gen pastwork = v731 if male == 0 
replace pastwork = mv731 if male == 1
label define pastw 0 "no" 1  "in the past year" 2  "currently working" 3 "have a job, but on leave last 7 days"
label values pastwork pastw
tab pastwork, m


* 7.3 (v732 mv732):  employment all year/seasonal
replace v732  = . if v732  == 9
replace mv732 = . if mv732  == 9
gen ayemp=v732 if male==0
replace ayemp=mv732 if male==1


* 7.4 (v716 mv716) Occupation 

* Missing value detection 
replace  v716 = . if v716 ==  999
replace  mv716 = . if mv716 ==  999
gen occup = v716 if male == 0
replace occup = mv716 if male == 1

* Define labels 

label define occup 0 "unemployed" 11"landowner" 12 "farmer" 13 "agricultural worker" 14 "fisherman" ///
				   15 "poultry, cattle raising"  16 "home-based manufacturing (handicraft)" ///
				   21 "rickshaw driver, brick breaking"  22 "domestic servant" 23 "factory worker,blue collar service" ///
				   31 "semi-skilled labor(carpenter, mason)" 41"professional worker (medical,lawyer, accountant)" /// 
				   51 "large business" 52 "small business" 61 "unemployed/student" 96 "other"
				   
label values occup occup
tab occup, m 

** Recoding for occupation 
*  (job) Recoding the occupation status 
*=================================

* 6 categories(job): 
  * landowner(11) ;
  * agricultural related(12-15) ;
  * home manufacturing (16);
  * service (21, 22);
  * manual labor (23, 31);
  * professional & managerial (41, 51, 52);
  * Others (96)
  
gen job = 1 if  inlist(occup, 11) //landowner
replace job = 2 if inlist(occup, 12, 13, 14, 15) //agricultural
replace job = 3 if inlist(occup, 16) //home manufacturing
replace job = 4 if inlist(occup, 21, 22) // service 
replace job = 5 if  inlist(occup, 23, 31) // manual worker
replace job = 5 if inlist(occup,  41, 51, 52) //professional & managerial
replace job = 6 if inlist(occup, 96)
replace job = . if occup == 0 | occup == 61
label variable job "occupation status"

* Define labels 

label define job 1 "landowner" 2 "agricultural related"  3 "home manufacturing" 4 "service" 5"manual labor" 6"professional & managerial" 7 "other"
label values job job

tab job, m 



* 8. Income 

* 8.1 (v741) Types of Earnings

replace  v741 = . if v741 ==  9
gen tearn = v741 if male == 0

* NA for men
replace tearn = mv741 if male == 1
label define tearn 0  "not paid" 1  "cash only" 2  "cash and kind" 3  "in kind only"
label values tearn tearn
tab tearn, m 

* 8.2 (sm121) Earnings for Family needs, subjective evaluation (only for Male: 3673 respondents)

replace sm121 = . if sm121 == 9 
tab sm121, m 


* 9. Health Measurements

* 9.1 pregnant (4.5% pregnant among women individuals at the time of interview) 
 tab v213, m 
 
* 9.2 BMI (Body mass Index) restrcited to women Not pregnant

replace v445 = . if v445 == 9998 | v445 == 9999
gen bmi = v445/100 if v213 != 1
summarize bmi, detail

* 9.3 BMI (Body mass Index) restrcited to women Not pregnant
* Categorized by 4 groups: 
* < Cut-off point: 18.5, 18.5 to <25, 25.0 to <30, 30 >= ; 
recode bmi (0/18.5 = 1 "0-18.5(not included)") (18.5/25 = 2 "18.5-25(not included)") (25/30 = 3 "25 - 30(not included)") (30/50 = 4 "30+"), gen(bmigroup)
table bmigroup, contents(min bmi max bmi)  


**= Access to drinking water and sanitation =**

* 1 water access

 * 1.1 (hv201) Main source of drinking water 

 label define hv201   11"piped into dwelling" 12"piped into yard/plot" 13"public tap/standpipe" ///
					  21"tube well or borehole"  31"protected well"  32"unprotected well" ///
					  41"protected spring" 42"unprotected spring" 43"river/dam/lake/ponds/stream/canal/irrig" ///
					  51 "rainwater"  62"cart with small tank" ///
					  71"bottled water"  96"others" 
					  
 label values hv201 hv201
 tab hv201, m 

 * <(imp_water) Recoding drinking water criteria>
 * 2 categories: Improved drinking water  vs. Unimproved drinking water 
 *===============================================================================
 * (a. Improved drinking: 11, 12, 13, 21, 31, 41, 51, 71)  
 * •	Piped water into dwelling, plot or yard (11, 12)
 * •	Protected dug well (31)
 * •	Piped water into neighbor’s plot    
 * •	Rainwater (51)
 * •	Protected spring (41)
 * •	Tubewell/borehole (21)
 * •	Public tap/standpipe (13)
*===============================================================================
 * (b. Unimproved drinking: 32, 42, 43, 62, 96)
 * Use of 
 * •	Unprotected dug well (32)
 * •	Unprotected spring (42)
 * •	Small cart with tank/drum (62)
 * •	Tanker truck
 * •	Surface water (river, dam, lake, pond, stream, channel, irrigation channel)(43)
 * •	Bottled water 
*===============================================================================
  * Recode as <imp_water>
   gen imp_dwater  = 1 if inlist(hv201, 11, 12, 13, 21, 31, 41, 51, 71) 
   replace imp_dwater = 0 if inlist(hv201, 32, 42, 43, 62, 96)
   label define imp_dwater  0 "Unimproved drinking water" 1 "Improved drinking"
   label values imp_dwater imp_dwater
  
 * Test by rural-urban variable 
   tab region imp_dwater, row chi2
 
 * 1.2 (hv202) Main source of Non-drinking water
 
  * <(use_water)Recoding Non-drinking water criteria> Safe/Unsafe is another criterion
 * 2 categories: Improved Non-drinking water      vs. Unimproved Non-drinking water 
 *===============================================================================
 * (a. Improved non-drinking: 11, 12, 13, 21, 31, 41, 51, 71)  
 * •	Piped water into dwelling, plot or yard (11, 12)
 * •	Protected dug well (31)
 * •	Piped water into neighbor’s plot    
 * •	Rainwater (51)
 * •	Protected spring (41)
 * •	Tubewell/borehole (21)
 * •	Public tap/standpipe (13)
*===============================================================================
 * (b. Unimproved non-drinking: 32, 42, 43, 62, 96)
 * Use of 
 * •	Unprotected dug well (32)
 * •	Unprotected spring (42)
 * •	Small cart with tank/drum (62)
 * •	Tanker truck
 * •	Surface water (river, dam, lake, pond, stream, channel, irrigation channel)(43)
 * •	Bottled water 
*===============================================================================
 
  * recode as <imp_ndwater>
   label values hv202 hv201
   tab hv202, m 
   gen imp_ndwater  = 1 if inlist(hv201, 11, 12, 13, 21, 31, 41, 51, 71) 
   replace imp_ndwater = 0 if inlist(hv201, 32, 42, 43, 62, 96)
   label define imp_ndwater  0 "Unimproved drinking water" 1 "Improved drinking"
   label values imp_ndwater imp_ndwater
   
  ** Test by rural-urban variable ( Pr = 0.000)
   tab region imp_ndwater, row chi2
   
  * Shared the same results/distribution on response as hv201/imp_dwater
  
 * 1.3 <hv237> Do anything to water make it safer 
 replace hv237 = . if hv237 == 9 
 label define hv237  0 "no" 1 "yes"
 label values hv237 hv237
	
  ** Test by rural-urban variable ( Pr = 0.000)
   tab region hv237, row chi2
   

* 2 Sanitation Facility

* Usually classified as Improved sanitation facility vs. Unimproved sanitation
*===============================================================================
* a.Improved sanitation facility (11, 12, 13, 14, 15, 22) 
*	Flush or pour-flush to: 
	*   piped sewer system (11)
	*	septic tank (12)
	*	pit latrine (13)
*	Ventilated improved pit latrine (VIP)
*	Pit latrine with slab (22)
*	Composting toilet
*===============================================================================
* b.Unimproved sanitation facility (23, 31, 42, 43)
*	Flush or pour-flush to: 
	*   Flush or pour-flush to elsewhere  
	*   Pit latrine without slab or open pit
	*   Bucket (42)
	*   Hanging toilet or hanging latrine (43)
*   Public or shared sanitation facilities 
*   No facilities or bush or field (open defecation)
*===============================================================================

* 2.1 hv205: Type of toilet 
  replace hv205 = . if hv205 == 99 
  tab hv205, nolabel m 
  tab hv205, m 
  gen imp_tlt = 0 if inlist(hv205, 23, 31, 42, 43) 
  replace imp_tlt = 1 if inlist(hv205, 11, 12, 13, 14, 15, 22) 
  label define imp_tlt 0 "unimproved sanitation" 1 "improved sanitation"
  label values imp_tlt imp_tlt
  
 * Test by urban-rural region segregation
 tab imp_tlt urban, col chi2
  
  
* 2.2 hv225: share toilet with other households 

  label define share_t  0 "no" 1 "yes"
  label values hv225 share_t
  tab hv225, m
  
* relationship with migrations status. 
tab hv225 mg, col chi2
tab hv225 rumg, col chi2
tab hv225 new_ru, col chi2
tab hv225 ruyr, col chi2

 * Test by urban-rural region segregation
 tab hv225 urban, col chi2

* 2.3 hv238: number of households sharing toilet
  replace hv238 = . if hv238 == 99 | hv238 ==  98 
  
  * ANOVA:
   oneway hv238 mg, bonferroni tabulate
 
  
* 3 Health access 

* 3.1 (v770 and mv770) seek advice for last disease
replace mv770 = . if mv770 == 9
replace v770 = . if v770 == 9

gen adv = v770 if male == 0 
replace adv = mv770 if male ==1 

label define adv 0 "no" 1 "yes"
label value adv adv


*******************Family arrangement (number of children)

*   1. Children of age 5 and under in all households;  
	tab v137, m 
	preserve 
    collapse v137 , by (nhhid) 
    *  br 
    tab v137, m
    restore 
	* Number of children 0-5 
	
*   2. Children of age 0-15 in all households; 	
*   b8_01 - b8_20 are age of children: visitors have been excluded; 
*   first find out the children aged 0-15 for each variable of b8_*, then loop through them for summarize
	
	sort hhid
	
*  2.1 Create binary variable(child_b8_01 to child_b8_20): 
*  indicating if the age of each child is 0-15; 
   
   foreach var of varlist b8_01-b8_20 {
   gen child_`var' = 1 if (`var' >= 0 & `var' <= 15) 
   replace child_`var' = 0 if child_`var' == .  
  }

 *  2.2 (enumkid) Denoting No. of 0-15 aged children in each household

 /* Use egen to count the number of under15 age children per household */
 * loop across variables: child_b8_01 to child_b8_20 for generating total number of  0-15 aged children in hh**
  
  egen enumkid = rowtotal(child_b8_*)
  tab enumkid, m   

*  2.3 /* Run a t-test to check difference in mean No. of kid in household */
  tab enumkid mg, col chi2
  ttest enumkid, by(mg ) 
  tab enumkid rumg, col chi2
  tab enumkid ruyr, col chi2

*****************************************************************
/* III Analysis: General. Migrants vs. nonmigrants comparison */ 
*****************************************************************
 
***Wealth and asset
ttest wealth, by(new_ru)
tab wealth new_ru, col chi2
tab wealth ruyr, col chi2

* Distribution of Index of house assets: Compare with wealth index  
  histogram asset, frequency normal

*By region
forvalues i = 0(1)3 {
tab wealth new_ru if region==`i', col chi2
}

ttest asset, by(new_ru)
reg asset i.ruyr
tab assetq new_ru, col chi2
tab assetq ruyr, col chi2

*Bi-modal distribution. Rural-urban migrants disproportionately in both ends of the distribution.
*More recent migrants fare better.

*For men.
ttest wealth if male==1, by(new_ru)
tab wealth new_ru if male==1, col chi2
tab wealth ruyr if male==1, col chi2

*Restrict to one observation per household
bysort hhid: gen temp=_n
ttest wealth if temp==1, by(new_ru)
tab wealth new_ru if temp==1, col chi2
tab wealth ruyr if temp==1, col chi2
drop temp


***Demographics


foreach var of varlist male agegroup marit religion region edu_level edu_atm cw pastwork ayemp tearn job {
    tab `var' new_ru, col chi2
	tab `var' ruyr,col chi2

}

foreach var of varlist age edu_yr enumkid {
    ttest `var', by(new_ru)
	reg `var' i.ruyr

}

*SES restricted to men.
foreach var of varlist edu_level edu_atm cw pastwork ayemp tearn {
    tab `var' new_ru if male==1, col chi2
	tab `var' ruyr if male==1,col chi2

}


***Standards of living

foreach var of varlist hv201 hv225 hv206 hv205 adv {
    tab `var' new_ru, col chi2
	tab `var' ruyr,col chi2

}


*****************************************************************
/* IV Analysis: Restricted to people in poverty */ 
*****************************************************************

preserve
keep if wealth==1 | wealth==2

***Demographics

foreach var in male agegroup marit religion region edu_level edu_atm cw pastwork ayemp job tearn {
    tab `var' new_ru, col chi2
	tab `var' ruyr, col chi2

}


foreach var in age edu_yr{
    ttest `var', by(new_ru)
	reg `var' i.ruyr

}

*SES restricted to men.
foreach var in edu_level edu_atm cw pastwork ayemp tearn sm121{
    tab `var' new_ru if male==1, col chi2
	tab `var' ruyr if male==1,col chi2

}


***Standards of living

foreach var of varlist hv201 hv225 hv206 hv205 adv {
    tab `var' new_ru, col chi2
	tab `var' ruyr,col chi2

}

restore


*****************************************************************
/* V Analysis: Restricted to migrants in poverty */ 
*****************************************************************

* Characteristics and standards of living among migrants in poverty (wealth in the two lowest categories--quintiles)

preserve
keep if new_ru==1 & (wealth==1 | wealth==2)

***Demographics

foreach var of varlist male agegroup marit religion region edu_level edu_atm cw pastwork ayemp job tearn{
    tab `var', m
}

foreach var of varlist age edu_yr {
    sum `var'
}

*SES restricted to men.
foreach var of varlist edu_level edu_atm cw pastwork ayemp tearn sm121{
    tab `var' if male==1, m
}


***Standards of living

foreach var of varlist hv201 hv225 hv206 hv205 adv {
    tab `var'
}

restore


******Reference 
* 1. DHS Program. Using Datasets for Analysis. http://dhsprogram.com/data/Using-DataSets-for-Analysis.cfm#CP_JUMP_14042. Accessed 23 Mar 2016.
* 2. Das, S., & Gulshan, J. (2017). Different forms of malnutrition among under five children in Bangladesh: a cross sectional study on prevalence and determinants. BMC Nutrition, 3(1), 1.


 

 
  
  
