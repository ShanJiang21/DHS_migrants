
*===========================================================================================*=====*
* Date: 07/19/2019                      										   
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



/* Import Male data: BDMR51FL.DTA and Append Female's Data: BDIR51FL.DTA */ 

clear
set mem 1024m 
set more off

* Define a global directory 
global path "/Users/yl/Desktop/Bangladesh/DHS 2007/data/BD_2007_DHS_06202019_2057_135629/"

use "$path/BDMR51DT/BDMR51FL.DTA"

* Generate the ID variable  
gen caseid = mcaseid
label variable caseid "caseid"
*3,771 men.

* generate the sex variable: male  
gen male = 1 
label variable male "male"

/* Clean Variables related to migration */ 

* Region 
tab mv101

* mv102: Type of Residence: restrict to individuals currently living in urban area 
codebook mv102
tab mv102, m 
replace mv105 = . if mv105 == 9

* MV104 - Men: years lived in place of res.
replace mv104 = . if mv104 == 99
drop if mv104 == 96 
* Drop obs: deleted 125 observations in "visitors" category
*3,646

* mv105:  type of place of previous res.
tab mv102 mv105, m 


* Appending the dataset
append using  "$path/BDIR51DT/BDIR51FL.DTA"


replace male = 0 if male == . 
label define male 0 "female"  1 "male"
label values male male
tab male, m


* Missing value 
replace v105 = . if v105 == 9

* V102 - Type of Residence.
codebook v102 
label define v102 1 "urban"  2 "rural"
label values v102 v102
tab v102, m 

* v104: drop "visitors" category.
codebook v104
drop if v104 == 96  
* 859 observations deleted

 
* Relabel v105 like mv105
codebook mv105
label define v105 1 "city"  2 "town" 3 "countryside"
label values v105 v105
tab v102 v105, m


****************
*Migration variables
****************

* (1) Binary migrants vs. nonmigrants: mmigr and vmigr
* Definition: After excluding visitors, mv104 == "Always" as Non-migrants, vs. all others as migrants.

* mmigr: Male migrants = 1 vs. Male non-migrants = 0:
 gen mmigr = 0 if mv104 == 95 
 replace  mmigr = 1 if (mv104 < 95 & mv104 != . ) & (male == 1)
 tab mmigr, m 
 tab mv104 if male == 1, m 

 
* vmigr: Female migrants = 1 vs. Female non-migrants = 0:
 gen vmigr = 0 if v104 == 95 
 replace  vmigr = 1 if (v104 < 95 & v104 != . ) & (male == 0)
 tab vmigr, m 


* a compiled variable: mg for Non-migrants vs migrants
gen mg = 0 if vmigr  == 0 | mmigr  == 0
replace mg = 1 if vmigr  == 1 | mmigr  == 1
label define mg 1 "Migrants"  0 "Non-migrants" 
label values mg mg 
tab mg, m 


 * (2) rural-urban migrants vs Non-migrants (rumg)
* Definition: After excluding visitors, v105 == "countryside" as rural.

* vru: Female rural-urban migrants 1 vs. Female non-migrants = 0:

  gen vru = 1 if v102 == 1 &  v105 == 3 & (male == 0)
  replace vru = 0 if  mg == 0 & male==0
  tab vru, m 

* mru: Male rural-urban migrants 1 vs. Male non-migrants = 0: 

  gen mru = 1 if mv102 == 1 &  mv105 == 3 & (male == 1)
  replace mru = 0 if mg ==0 & male==1
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
  tab new_ru, m
 
 
  * (4) rural-urban migrants by duration of residence in current place.
  gen yrstay = v104 
  replace yrstay = mv104 if yrstay == .
  tab yrstay if yrstay<95
  *roughly equal and commonly used intervals: 0-5; 6-10; 11-20; 21-50.
  
  gen ruyr=0 if new_ru==0
  replace ruyr=1 if new_ru==1 & (yrstay>=0 & yrstay<=5)
  replace ruyr=2 if new_ru==1 & (yrstay>=6 & yrstay<=10)
  replace ruyr=3 if new_ru==1 & (yrstay>=11 & yrstay<=20)
  replace ruyr=4 if new_ru==1 & (yrstay>=21 & yrstay<=50)
  label define ruyr 0 "urban nonmigrants" 1 "ru mig 0-5"  2 "ru mig 6-10" 3 "ru mig 11-20" 4 "ru mig 21-50"
  label values ruyr ruyr

  
save "$path/fullsample.dta", replace

*****************
* Household assets
*****************
* (hv206- hv215, hv221 - hv244)

use "$path/BDHR51DT/BDHR51FL.DTA", clear
 
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
  tab hv270 asset
  histogram asset, frequency normal
  graph box asset, over (hv270)
  


***********
*Analysis
***********

use "$path/fullsample.dta", clear

***Wealth index. 1 =  poorest to   5   = richest
gen wealth=mv190 if male==1
replace wealth=v190 if male==0

ttest mv190 if male==1, by(new_ru)
ttest v190 if male==0, by(new_ru)
ttest wealth, by(new_ru)

tab mv190 new_ru if male==1, col chi2
tab v190 new_ru if male==0, col chi2
tab wealth new_ru, col chi2

tab mv190 ruyr if male==1, col chi2
tab v190 ruyr if male==0, col chi2
tab wealth ruyr, col chi2

