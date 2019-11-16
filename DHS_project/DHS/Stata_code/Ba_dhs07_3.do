
*===========================================================================================*=====*
* Date: 07/25/2019                      										   
* Project: DHS migration                                         
* This program focuses:	                                            
*  1.Migration variable: 
*  	1) a dummy variable of migrant vs. non-migrant; 
*  	2) a dummy variable of rural-urban migrants (using info on where you lived before you moved here vs. nonimmigrants; 3) for rural-urban migrants, how long they have lived in the current place of residence.
*  2. Household asset list. add the items and create an average score. cross-tab the score by migration status (rural-urban migrants vs. nonimmigrants dummy).
*			                       						      
* Database used:
*  1. Male data: BDMR51FL.DTA;
*  2. Female's Data: BDIR51FL.DTA.
*  3. Household Data: BDHR51FL.DTA for generating the assets index  (not appended/merged)
* 
* Key Variables for migration studies:
* v102 - v105;  mv102 - mv105;
*====================================================================================================*


/*Phase I.  Data compile*/ 
/* Import Male data: BDMR51FL.DTA and Append Female's Data: BDIR51FL.DTA */ 

clear
set more off

* The default maximum is 5000, enlarge the dataset list; 
set maxvar 10000

* Define a global directory 
global path "/Users/shan/Projects/DHS_project/DHS/BD_2007_DHS_06202019_2057_135629"


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
* Save as male data 

* 1.2 caseid: Generate the ID variable, for appending female data to male data  
gen caseid = mcaseid
label variable caseid "male caseid"

* 1.3  Generate gender variable 
gen male = 1 
label variable male "male"
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

* 3.2 Merge   
use "$path/BDHR51DT/BDHR51FL.DTA", clear
replace hhid = substr(hhid, 1, 12)
format hhid 
sort hhid
* format of hhid is %12s. 

save "$path/hhold.dta", replace

use "$path/fullsample.dta", clear

* Merge household data with household data using key hhid
merge m:1 hhid using "$path/hhold.dta"

* Only keep these eligible individuals and group them by household id
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

* There are 9,289 households and 14,767 individuals in the dataset before cleaning;


/* Phase II. Clean Variables related to migration */ 

* Region 
tab mv101

* < Male: migration variables mv102 - mv135>
* v135: usual resident or visitor ( 2 = visitor)
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

* mv105:  type of place of previous res.
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

*******************************************************************************
*							Migration variables 							  *
*******************************************************************************

* (1) Binary migrants vs. nonmigrants: mmigr and vmigr
* Definition: After excluding visitors, mv104 == "Always" as Non-migrants, vs. all others as migrants.

* mmigr: Male migrants = 1 vs. Male non-migrants = 0:
* 95 = "always"
 gen mmigr = 0 if mv104 == 95 
 replace  mmigr = 1 if (mv104 < 95 & mv104 != . ) & (male == 1)
 tab mmigr, m 
 tab mv104 if male == 1, m 

 
* vmigr: Female migrants = 1 vs. Female non-migrants = 0:
* 95 = "always"
 gen vmigr = 0 if v104 == 95 
 replace  vmigr = 1 if (v104 < 95 & v104 != . ) & (male == 0)
 tab vmigr, m 


* a compiled variable: mg for Non-migrants vs migrants
gen mg = 0 if vmigr  == 0 | mmigr  == 0
replace mg = 1 if vmigr  == 1 | mmigr  == 1
label define mg 1 "Migrants"  0 "Non-migrants" 
label values mg mg 
tab mg, m 

**Variable: mg denoting Non-migrants vs migrants for all individuals


* (2) rural-urban migrants vs Non-migrants (rumg)
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

* Female: new_vru 
  gen new_vru = 0 if v102 == 1 & v104  ==  95 & male == 0
  replace new_vru = 1 if v102 == 1 & v105 == 3 & male==0
  tab new_vru, m
  
* Male: new_mru  
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
  * female: v104
  gen yrstay = v104 if male == 0
  * male: mv104
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



**************************************************************
*											  				 *
*		Household assets and test results				     *
*   														 *
*              (hv206- hv215, hv221 - hv244)				 *
**************************************************************


 * Deal with missing values
 * (1) hv206- hv215
 tab hv206 hv207
 
 replace hv208 = . if hv208 == 9
 replace hv209 = . if hv209 == 9
 
 tab hv210 hv211
 replace hv210 = . if hv210 == 9
 replace hv211 = . if hv211 == 9
 
 tab hv212 hv213
 replace hv212 = . if hv212 == 9
 replace hv213= . if hv213 == 99
 
codebook hv214 hv215
replace hv214= . if hv214 == 99
 replace hv215= . if hv215 == 99
 replace hv216 = . if hv216 == 99

 * (2) hv221 - hv244 
 
 codebook hv221 hv225
 replace hv221 = . if hv221 == 9
 replace hv225 = . if hv225 == 9
 
 * hv242 household has separate room used as kitchen
 replace hv243a  = . if hv243a  == 9 
 replace hv243b  = . if hv243b  == 9 
 replace hv243c  = . if hv243c  == 9 
 replace hv243d  = . if hv243d  == 9 
 replace hv244  = . if hv244  == 9 
 
 * Not included
 replace hv245  = . if hv245  == 99 
 
 * Animals 
  tab hv246
  replace hv246  = . if hv246  == 9
 
* Handling with the recoding for binary variables 

* (1) hv213:   main floor material - 11  earth, sand = 1, others = 0
recode  hv213 11 =1 21 = 0 22 = 0 31 = 0 33 = 0 34 = 0 35 = 0 96 = 0 , gen(new_hv213)
tab new_hv213 
 

* (2) hv214:  no walls,   bamboo with mud  &  dirt  =1, others = 0 
recode  hv214 22 =1 12 =1 13 =1  11 = 1 31 = 0 23 =0 24 = 0 25 =0 32 = 0 31 = 0 33 = 0 34 = 0 35 = 0 96 = 0 , gen(new_hv214)
tab new_hv214 


* (3) hv215:  no roof,  thatch, bamboo with mud  &   tin  =1, others = 0
recode  hv215 11 = 1 12 =1 23 =1   31 = 1  32 = 0 31 = 0 33 = 0 34 = 0 35 = 0 96 = 0 , gen(new_hv215)
tab new_hv215  

* (4) chair and table: sh109h sh109i
replace sh109h  = . if sh109h  == 9 
replace sh109i  = . if sh109i  == 9 
replace sh109p  = . if sh109p  == 9
replace sh121  = . if sh121  == 9

 
 gen asset = hv206 + hv207 + hv208 + hv209 + hv210 + hv211 +  hv212 + hv213 + hv214 + hv215 + hv221 + hv225 + hv242 + hv243a + hv243b + hv243c + hv243d + hv244 + hv245 + sh109h + sh109i +  sh109p + sh121 
 

* Distribution of Index of house assets: Compare with wealth index  
  histogram asset, frequency normal
  * graph box asset, over (hv270)
  

*** Wealth index. 1 =  poorest to   5   = richest: exist in both female/male data
gen wealth= mv190 if male==1
replace wealth= v190 if male==0

* (1) Two-sample t test for wealth index among Non-migrants vs migrants
* within male group
ttest mv190 if male==1, by(mg) 
* within female group
ttest v190 if male==0, by(mg)

ttest wealth, by(mg) 

* (2) t test for wealth index among Non-migrants vs Rural-urban migrants
* within male group
ttest mv190 if male==1, by(rumg)
* within female group
ttest v190 if male==0, by(rumg)

ttest wealth, by(rumg)

* (3) t test for wealth index among Urban non-migrants vs Rural-urban migrants
ttest mv190 if male==1, by(new_ru)
ttest v190 if male==0, by(new_ru)
ttest wealth, by(new_ru)

tab mv190 new_ru if male==1, col chi2
tab v190 new_ru if male==0, col chi2
tab wealth new_ru, col chi2

* (4) ANOVA for wealth index among Urban non-migrants/rural-urban migrants year of 0-5/6-10/11-20/21-50.
graph hbox wealth, over (ruyr)
oneway wealth ruyr, bonferroni tabulate wrap

tab mv190 ruyr if male==1, col chi2
tab v190 ruyr if male==0, col chi2
tab wealth ruyr, col chi2

tab asset ruyr, col chi2

/* Phase II. Demographic & SES information of household/individuals */ 

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
 
 * 1.2  Sex of eligible women/men in the household: male 
	tab male mg, col chi2
	tab male rumg, col chi2
    tab male new_ru, col chi2
	tab male ruyr,col chi2
	
* There is significant gender difference among female and male subjects when choosing to migrate at 0.05 sig. level. 
     

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
  
 * agegroup codebook: 1 = 15-19, 2 = 20-24, 3 = 25-29, 4 = 30-34, 5 = 35-39, 6 = 40-44 ,7= 45-49,8 = 50-54
  gen agegroup = v013 if male == 0
  replace agegroup = mv013 if male == 1
  label define agegroup 1 "15-19" 2  "20-24" 3  "25-29" 4 "30-34" 5 "35-39" 6 "40-44" 7 "45-49" 8 "50-54"
  label values agegroup agegroup
  tab agegroup,  m 
   
 * Pearson chi2 and fisher's exact test on age and migration status variables
 tab age mg, col chi2
 tab age rumg, col chi2
 tab age new_ru,col chi2
 tab age ruyr, col chi2
 
 tab agegroup mg, col chi2

 * Conclusion:
 * There is significant age difference among subjects when choosing to migrate or not.
 * There is significant difference on age Non-migrants vs rural-urban migrants; 
 * There is significant difference on age among Urban non migrants vs rural-urban migrants; 
 * The rural-urban migration year is significantly associated with age at 5% sig. level; 
 
 
* 3 Marital status ( mv501, v501)
 
 gen marit =  mv501 if male == 1
 replace marit = v501 if male == 0 
 label define marit  1  "married" 3 "widowed" 4 "divorced" 5 "not living together"
 label values marit marit
 tab marit,  m 
 
 * Pearson chi2 and fisher's exact test on age and migration status variables
 tab marit  mg, col chi2
 tab marit  rumg, col chi2
 tab marit  new_ru, col chi2
 tab marit  ruyr, col chi2
 
 tab agegroup mg, col chi2

 * Conclusion:
 * There is significant gender difference among  subjects with different maritus status when choosing to migrate or not.
 * There is significant difference on age Non-migrants vs rural-urban migrants; 
 * There is significant difference on age among Urban non migrants vs rural-urban migrants; 
 * The rural-urban migration year is significantly associated with age at 5% sig. level; 
 

* 4 Education 
* (v106, mv106)highest educational level (4 levels)
  replace  v106 = . if v106 == 9 
  replace  mv106 = . if mv106 == 9 
  gen edu_level = v106 if male == 0 
  replace edu_level = mv106 if male == 1
  label define edu 0 "no education"  1 "primary" 2 "secondary" 3 "higher"
  label values edu_level edu
  tab edu_level, m 
  
* (v107 mv107) highest year of education
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

replace  v130 = . if v130 == 96 | v130 == 99
replace  mv130 = . if mv130 == 96
gen religion = v130 if male == 0 
replace religion = mv130 if male == 1
label define religion 1 "islam" 2 "hinduism" 3 "buddhism" 4 "christianity"
label values religion religion
tab religion, m 

* Anova 
tab mg religion, col chi2

* 6. Region(v134, mv134) using de facto place of living
 tab v134, m 
 tab mv134, m 
 gen region = v134 if male == 0 
 replace region = mv134 if male == 1 
 label define region 0 "capital, large city (sma,statistical metropolitan area)" 1 "small city (other urban)" 2 "town (municipality)" 3 "countryside (rural)"
 label values region region
 tab region, m 				

/*III SES information */

* (a) SES

* (1.1) Education ( v106-v107, mv106-mv107)

* 1 Education level (sig.)
tab edu_level, m 
tab edu_level mg, col chi2
tab edu_level rumg, col chi2
tab edu_level new_ru, col chi2
tab edu_level ruyr, col chi2

* 2 Education years 
tab edu_yr, m
tab edu_yr mg, col chi2
tab edu_yr rumg, col chi2
tab edu_yr new_ru, col chi2
tab edu_yr ruyr, col chi2


* 3 Education attainment
tab edu_atm, m 
tab edu_atm mg, col chi2
tab edu_atm rumg, col chi2
tab edu_atm new_ru, col chi2
tab edu_atm ruyr, col chi2


* (1.2) Employment 

* 1. v714: Respondent currently working

codebook v714
replace v714  = . if v714 == 9

gen cw = v714 if male == 0 
replace cw = mv714 if male == 1

label define cw 0 "no" 1 "yes"					
label values cw cw
tab cw, m

tab cw mg, col chi2

* Migrants not working significantly more than non-miragnts;

* 2. v731: Worked in last 12 months

replace v731  = . if v731  == 9
gen pastwork = v731 if male == 0 
replace pastwork = mv731 if male == 1
label define pastw 0 "no" 1  "in the past year" 2  "currently working" 3 "have a job, but on leave last 7 days"
label values pastwork pastw
tab pastwork, m

tab pastwork mg, col chi2

* 3. v732:  employment all year/seasonal
replace v732  = . if v732  == 9
replace mv732 = . if mv732  == 9
tab 

* 4. (v716 mv716)  occupation 

replace  v716 = . if v716 ==  999
replace  mv716 = . if mv716 ==  999
gen occup = v716 if male == 0
replace occup = mv716 if male == 1

* Define labels (unfinished)
*label define occup 0 "unemployed" 12 "farmer" 13 "agricultural worker" 14 "fisherman" 15 "poultry, cattle raising" 16 "home-based manufacturing (handicraft)"  21 "rickshaw driver, brick breaking" 22 "home-based manufacturing (handicraft, food products)" 1 51 "large business" "small business"
tab occup, m 


* (1.3) Income 

* 1. (v741) Types of Earnings

replace  v741 = . if v741 ==  9
gen tearn = v741 if male == 0
* NA for men
replace tearn = mv741 if male == 1
label define tearn 0  "not paid" 1  "cash only" 2  "cash and kind" 3  "in kind only"
label values tearn tearn
tab tearn, m 

* 2. wealth index ?


 
/* IV. Health Services */
 
* 1 water access

 * 1.1 (hv201) Main source of drinking water 

 label define hv201   11"piped into dwelling" 12 "piped into yard/plot" 13"public tap/standpipe"  21 "tube well or borehole"  31"protected well"  32 "unprotected well"41 "protected spring"  42 "unprotected spring" 43 "river/dam/lake/ponds/stream/canal/irrig" 51 "rainwater" 62 "cart with small tank" 71 "bottled water"  91 "bottled water"  96 "others"
 label values hv201 hv201
 tab hv201, m 

 
 * 1.2 (hv202) Main source of cooking/handwashing water
  label values hv202 hv201
  tab hv202, m 
  
 
 * 1.3 (hv237) Do anything to water make it safer 
 replace hv237 = . if hv237 == 9 
 label define hv237  0 "no" 1 "yes"
 label values hv237 hv237

 * Their relationship with migrations status. 
 
tab hv237 mg, col chi2 
tab hv237 rumg, col chi2
tab hv237 new_ru, col chi2
tab hv237 ruyr, col chi2
 * Not independent
 
 

* 2 sanitation 

* 2.1 hv205: Type of toilet 
replace hv205 = . if hv205 == 99 
tab hv205, m 

* 2.2 hv225: share toilet with other households 

  label define share_t  0 "no" 1 "yes"
  label values hv225 share_t
  tab hv225, m
* relationship with migrations status. 
tab hv225 mg, col chi2
tab hv225 rumg, col chi2
tab hv225 new_ru, col chi2
tab hv225 ruyr, col chi2

* hv238: number of households sharing toilet
  replace hv238 = . if hv238 == 99 | hv238 ==  98 
  
  * ANOVA:
   oneway hv238 mg, bonferroni tabulate
 
  
* 3 Health access variables. 

* (v770 and  mv770) seek advice for last disease
replace mv770 = . if mv770 == 9
replace v770 = . if v770 == 9

gen adv = v770 if male == 0 
replace adv = mv770 if male ==1 

label define adv 0 "no" 1 "yes"
label value adv adv

* relationship with migrations status. 
tab adv mg, col chi2
tab adv rumg, col chi2

* fail to reject the null.




/* VI. Children of age under 5 and 0-15 */ 

*   1 Children of age 5 and under in all households;  
	tab v137, m 
	preserve 
    collapse v137 , by (nhhid) 
    *  br 
    tab v137, m
    restore 
	* Number of children 0-5 
	
*   2 Children of age 0-15 in all households; 	
*   b8_01 - b8_20 are age of children: visitors have been excluded; 
*   first find out the children aged 0-15 for each variable of b8_*, then loop through them for summarize


*  ! 1st binary variable(child_b8_01 to child_b8_20): 
*  indicating if there is 0-15 aged children in this household
   
   foreach var of varlist b8_01-b8_20 {
   gen child_`var' = 1 if (`var' >= 0 & `var' <= 15) 
   replace child_`var' = 0 if child_`var' == .  
  }
  
 
*  ! 2nd variable: (numkid) Denoting No. of 0-15 aged children in each household

 * loop across variables: child_b8_01 to child_b8_20 for generating total number of  0-15 aged children in hh**
  
  egen numkid = rowtotal(child_b8_*)
  tab numkid, m 
  
  preserve 
  collapse numkid, by (mg rumg ruyr nhhid) 
  tab numkid mg, col
  restore 
  
 * Conclusion:  (1- 21.34%) 78.66% of migrant households with young children.

