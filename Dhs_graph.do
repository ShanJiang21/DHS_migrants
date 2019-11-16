
*** DHS Graphing 
** Date: 09/13/2019

clear all
set more off

* The default maximum is 5000, enlarge the dataset list; 
set maxvar 10000

* Define a global directory 

global path "/Users/shan/Projects/DHS_project/DHS/graph/"


** <1>Input Data from Table 1
input str8 wealth urban ruralurban
"Poorest"   6.8    7.5
"Poor"		10.9   11.8  
"Middle"	13.1   16.4 
"Rich"      23.8   21.7 
"Richest"   45.4   42.6
end

list 

* bar-graph 1: Wealth Index by Migration Status in Bangledesh, 2007
graph bar urban ruralurban, over(wealth, sort(1)) ///
	nofill ///
	graphregion(color(white)) ///
	intensity(*.89) ///
	legend( label(1 "Urban Residents") label(2 "Rural-Urban Migrants") )  ///
	ytitle("Percentage(%)") ///
	bargap(-10) ///
	title("Wealth Index in Bangledesh, 2007") ///
	subtitle("by Migration Status") ///
	blabel(bar, position(inside) format(%9.1f) color(white)) ///
	note("Source: 2007 data from DHS, USAID") 


* Exporting file 
graph export "$path/dhs-bar1.png", width(700) replace





**<2> Table 3 
clear
input str24 toiletusage percentage 
"Flush toilet"   	4.4
"Pit toilet/Latrine"	71.2
"No facility/bucket"	24.4
end

list 

graph bar percentage , over(toiletusage, sort(1) gap(*5)) ///
	nofill ///
	graphregion(color(white)) ///
	intensity(*.9) ///
	ytitle("Percentage(%)") ///
	title("Types of Toilet Facilities in Bangladesh, 2007") ///
	blabel(bar, position(inside) format(%9.1f) color(white)) ///
	note("Source: 2007 data from DHS, USAID")

* Exporting file 
graph export "$path/dhs-bar2.png", width(700) replace




**<3> Table 6 
clear
input str24  toilet3  double(large) medium small 	
"Flush toilet"	     5.7	3.1	    5.4
"Pit toilet/Latrine"  75.9	69.4	71.3
"No facility/bucket" 19.0	27.5	23.4 
end

list 

graph bar large  medium small , over(toilet3) ///
	nofill ///
	graphregion(color(white)) ///
	legend( label(1 "Large city") label(2 "Medium size city") label(3 "Small city") rows(1) ring(0) pos(1) region(lcolor(white))) ///
	bar(1, color(orange*0.5)) bar(2, color(ebblue*0.7)) bar(3, color(eltgreen*0.7)) ///
	ytitle("Percentage(%)") ///
	bargap(-5) ///
	title("Toilet Facilities arrangement in Bangladesh, 2007") ///
	blabel(bar, position(inside) format(%9.1f) color(white)) ///
	subtitle("by city level") ///
	note("Source: 2007 data from DHS, USAID")

* Exporting file 
graph export "$path/dhs-bar3.png", width(700) replace

