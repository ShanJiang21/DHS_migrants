use "C:\Users\sj2921\Downloads\DHS\BD_2007_DHS_06202019_2057_135629\BDHR51DT\BDHR51FL.DTA", clear
use "C:\Users\sj2921\Downloads\DHS\BD_2007_DHS_06202019_2057_135629\BDIR51DT\BDIR51FL.DTA", clear

*==============Merge Household dataset and individual dataset===================
* Before merge the data, an overview of dataset:
* Female: 4322 variables, 10996 obs;
* Male:  628 variables, 3771 obs; 
* Household: 2502 variables, 10,400 obs;
* =============================================================================

* The default maximum is 5000, enlarge the dataset list; 
 set maxvar 10000

* 1. Generate household-level caseid in Female's dataset 
describe caseid
format caseid
* hid1: household-level caseid for female
gen hid1 = substr(caseid, 1, 12)
save "./female.dta",replace
use "./female.dta", clear

merge 1:m hid1 using hhid 

* 2. Generate household-level in Male's dataset
describe mcaseid
format mcaseid
* hid2: household-level caseid for Male
gen hid2 = substr(mcaseid, 1, 12)
save , replace 


* 

