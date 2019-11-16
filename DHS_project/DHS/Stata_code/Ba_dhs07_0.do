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

* Define a global directory 
global path "/Users/shan/Projects/DHS_project/DHS/BD_2007_DHS_06202019_2057_135629/"
cd $path 

use "./BDMR51DT/BDMR51FL.DTA"

* Generate the ID variable  
gen caseid = mcaseid
label variable caseid "caseid"

* generate the sex variable: male  
gen gender = 1 
label variable gender "gender"

/* Clean Variables related to migration */ 

* Men: --------------------------------------------------------------------
* Region 
 tab mv101
 
*  mv102: Type of Residence: only use individuals living in urban area 
codebook mv102
* Male: Missing value:
tab mv102, m 
replace mv105 = . if mv105 == 9
tab mv102 mv105, m row

* MV104 - Men: years lived in place of res.
replace mv104 = . if mv104 == 99
drop if mv104 == 96 
* Drop obs: 125 observations deleted for "visitors" category

* mv105:  type of place of previous res.
tab mv102 mv105, m 

*  7.00 % +  22.04 %  = 29.04% Male living in urban who lived in Town/countryside


* Appending the dataset
append using  "./BDIR51DT/BDIR51FL.DTA"

* Add gender to the whole dataset, add label 
replace gender = 0 if gender == . 
label define genderl 0 "female"  1 "male"
label values gender genderl
tab gender, m

**== Dataset Inspection =========: 
* 1. There are 14,767 observations in the new dataset;
* 	1.1 There are 628 variables and 3,771 observations in the Male's data * "./BDMR51DT/BDMR51FL.DTA" *;
* 	1.2 There are 4,321 variables and 10,996 observations in Women's dataset * "./BDIR51DT/BDIR51FL.DTA"*. 
* 2. The variable used as key is caseid to identify each unique individual; 
* 3. we generated a new variable called sex to indicate the interviewee's sex: 1 = male 0 = female;   
*===================================

* Women:------------------------------------------------------------------------

* Missing value 
replace v105 = . if v105 == 9

* V102 - Type of Residence: only use individuals living in urban area codebook: relabel
codebook v102 
label define v102l 1 "urban"  2 "rural"
label values v102 v102l
tab v102, m 

* v104: drop "visitors" category for years lived in place of residence;
codebook v104
drop if v104 == 96  
* 859 observations deleted

 
* Relabel v105 like mv105
codebook mv105
label define v105l 1 "city"  2 "town" 3 "countryside"
label values v105 v105l
tab v102 v105, m


**============= variables Inspection =========: 
* 1. mv105: There are 12,689 missing values for mv105(since appended) 
*  Missing: 2,559 ;
* 2. mv102: 10,137 missing values; 
* 3. v102:  3,646 missing 
* 4. v105:  5,328 missing 
*-------------------------------------------------


 * I. Migration list
 
* v104: years lived in place of res;
* mv104

* (1) Generate Migrant variable(mg): mmigr and vmigr

* Definition: After excluding visitors, by using mv104 == "Always" as Non-migrants, vs all others are migrants

* 1.1 mmigr: Male migrants = 1 vs. Male non-migrants = 0:
 gen mmigr = 0 if mv104 == 95 
 replace  mmigr = 1 if (mv104 < 95 & mv104 != . ) & (gender == 1)
 tab mmigr, m 
 
 tab mv104 if gender == 1, m 
 
* n = 3645 as mv104 has one missing within male dataset

* 1.2 vmigr: Female migrants = 1 vs. Female non-migrants = 0:
 gen vmigr = 0 if v104 == 95 
 replace  vmigr = 1 if (v104 < 95 & v104 != . ) & (gender == 0)
 tab vmigr, m 
 
* dis 10137 + 859 = 10996, validated

* 1.3 genderate the compiled variable: mg for Non-migrants vs migrants
gen mg = 0 if vmigr  == 0 | mmigr  == 0
replace mg = 1 if vmigr  == 1 | mmigr  == 1
label define mgl 1 "Migrants"  0 "Non-migrants" 
label values mg mgl 
tab mg, m 


 * (2) rural-urban migrants vs Non-migrants  (rumg)

* Definition: After excluding visitors, by using v105 == "countryside" as rural, vs all other Non-migrants

* 2.1 vru: Female rural-urban migrants 1 vs. Female non-migrants = 0:

  gen vru = 1 if v102 == 1 &  v105 == 3 & (gender == 0)
  replace vru = 0 if  mg == 0
  tab vru v105, m 

* 2.2 mru: Male rural-urban migrants 1 vs. Male non-migrants = 0: 

  gen mru = 1 if mv102 == 1 &  mv105 == 3 & (gender == 1)
  replace mru = 0 if  mg ==0
  tab mru mv105, m 

 * 2.3 rumg: Male rural-urban migrants 1 vs. Male non-migrants = 0:
 
  * Combine two variables in different genders 
  gen rumg = 1 if vru == 1 | mru   == 1
  replace rumg = 0 if   vru == 0 | mru  == 0
  label define rumgl 1 "rural-urban migrants"  0 "Non-migrants" 
  label values rumg rumgl 
  tab rumg, m 
 
 *** (Extra) rural-urban migrants, how long they have lived in the current place of residence
  tab rumg 
  * concatenate two year variables 
  summarize v104 
  summarize mv104
  gen yr_lived = v104 
  replace yr_lived = mv104 if yr_lived == .

  * Descriptive statistics 
  tab rumg if yr_lived ! = 95, sum( yr_lived )
  
 * (3) new migration variable (binary)—separating rural-urban migrants vs. urban non-migrants.
 
*  Variable 3:
* 0. Currently living in urban (v102 1 = urban) and never lived previously in another place
* 1. previously living in rural (countryside & town) and currently living in urban (v102)

* 3.1 Female: new_vru 
  gen new_vru = 0 if v102 == 1 & v104  ==  95 & gender == 0
  replace new_vru = 1 if v102 == 1 &  (v105 == 2 | v105 == 3)
  tab new_vru, m
  
* 3.2 Male: new_mru  
  gen new_mru = 0 if mv102 == 1 & mv104  ==  95 & gender == 1
  replace new_mru = 1 if mv102 == 1 &  (mv105 == 2 | mv105 == 3)
  tab new_mru, m
  
  *  1,142  obs with 12,641 missing 
  
* 3.3 Combined: new_ru as Variable 3 combining male and female varibles
  gen new_ru = 0 if (new_mru == 0  & gender  == 1)  | (new_vru == 0 &  gender  == 0)
  replace new_ru = 1 if (new_mru == 1 & gender  == 1)  | (new_vru == 1 &  gender  == 0)
  tab new_ru, m
 
  
  *  3,447 (25.01 %), previously living in rural, now in urban
 
 *--------------------------
 * II. household asset list. * (hv206- hv215, hv221 - hv244 )
 use "./BDHR51DT/BDHR51FL.DTA", clear
 
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
  graph box asset, over (  hv270 )
  
* -------------------
* III. T-test 

*  wealth index: mv190 with  1 =  poorest to   5   = richest

tab mv190 mg if gender == 1, chi

* Male wealth index t test by migration status 
ttest mv190 if gender == 1, by (mg)  
ttest mv190 if gender == 1, by (rumg) 
ttest mv190 if gender == 1, by (new_ru) 

* Female wealth index t test by migration status 
ttest v190 if gender == 0, by (mg)   
ttest v190 if gender == 0, by (rumg) 
ttest v190 if gender == 0, by (new_ru) 


