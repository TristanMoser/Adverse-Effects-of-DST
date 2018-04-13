*Daylight Savings Project Do File

*Read in the data
cd "J:\"
import delimited J:\Totals2wks.csv

*Summarize continuous variables for each year
foreach X of numlist 0/5{
local Y 201`X'
summ crashes tax_on_fuel tax_on_lic~e tot_hwy_exp population if year == `Y'
}

*Summarize categorical variables for each year
foreach X of numlist 0/5{
local Y 201`X'
tabulate weather if year == `Y'
}

*View crash statistics by weather
tabulate weather, summarize(crashes)

*View crash statistics by week before and week of DST
tabulate prox if prox == -1 | prox == 0, summarize(crashes)


*Regression showing RD effect of DST around transition
reg crashes dst prox if prox > -11 & prox < 10
outreg2 using regs.doc, replace label ctitle(RD)

*Regression with standard errors clustered by county unit
reg crashes dst prox if prox > -11 & prox < 10, vce(cluster unit)
outreg2 using regs.doc, append label ctitle(Clustering)

*Regression with week and state fixed effects with clustering
encode state, gen(numstate)
reg crashes dst prox i.week i.numstate if prox > -11 & prox < 10, vce(cluster unit)
outreg2 using regs.doc, append label ctitle(Fixed Effects)

*Take log of control variables
gen lnpop = ln(population)
gen lnfuel = ln(tax_on_fuel)
gen lnlic = ln(tax_on_license)
gen lnhwy = ln(tot_hwy_exp)

*Regression using control variables
encode weather, gen(numweather)
reg crashes dst prox numweather lnfuel lnlic lnhwy lnpop if prox > -11 & prox < 10,robust
outreg2 using regs.doc, append label ctitle(Controls)


*Generate average crashes by weeks to DST
bysort prox : egen avgcrash = mean(crash)

*Generate Confidence Intervals for graph
gen lb = avgcrash - 0.002
gen ub = avgcrash + 0.002

*Graph of discontinuity
twoway (scatter avgcrash prox if prox < 0 & prox >-11,mcolor(black) msize(small)) ///
(lfit lb prox if prox <0 & prox >-11, lcolor(black) lpattern(--)) ///
(lfit lb prox if prox >=0 & prox <=10, lcolor(black) lpattern(--)) ///
 (scatter avgcrash prox if prox >=0 & prox <=10, mcolor(black) msize(small)) ///
 (lfit ub prox if prox <0 & prox >-11, lcolor(black) lpattern(--)) ///
(lfit ub prox if prox >=0 & prox <=10, lcolor(black) lpattern(--)) ///
 (lfit avgcrash prox if prox < 0 & prox >-11, lcolor(black)) ///
 (lfit avgcrash prox if prox >=0 & prox <=10, lcolor(black)), ///
 xtitle(Weeks from DST) ytitle(Average Number of Fatal Crashes) ylabel(.12(.02).2)legend(off) ///
 xline(-.5,lcolor(blue) lpattern(--)) graphregion(color(white)) title(Spring DST Crashes)
 
graph export graph.png, replace 


*Fall DST
replace dst = 1 if week == 45 & year == 2015
replace dst = 1 if week == 45 & year == 2014
replace dst = 1 if week == 45 & year == 2013
replace dst = 1 if week == 45 & year == 2012
replace dst = 1 if week == 46 & year == 2011
replace dst = 1 if week == 46 & year == 2010

gen fprox = week - 45 if year == 2015 | year == 2014 | year == 2013 | year == 2012
replace fprox = week -45 if year == 2011 | year == 2010


*Regression showing RD effect of DST around transition
reg crashes dst fprox if fprox > -11 & fprox < 8
outreg2 using fallregs.doc, replace label ctitle(RD)

*Regression with standard errors clustered by county unit
reg crashes dst fprox if fprox > -11 & fprox < 8, vce(cluster unit)
outreg2 using fallregs.doc, append label ctitle(Clustering)

*Regression with week and state fixed effects with clustering
reg crashes dst fprox i.week i.numstate if fprox > -11 & fprox < 8, vce(cluster unit)
outreg2 using fallregs.doc, append label ctitle(Fixed Effects)

*Regression using control variables
reg crashes dst fprox numweather lnfuel lnlic lnhwy lnpop if fprox > -11 & fprox < 8,robust
outreg2 using fallregs.doc, append label ctitle(Controls)


*Generate average crashes by weeks to DST
bysort fprox : egen favgcrash = mean(crash)

*Generate Confidence Interval for graph
gen fub = favgcrash + 0.002
gen flb = favgcrash - 0.002

*Graph of discontinuity
twoway (scatter favgcrash fprox if fprox < 0 & fprox >-11,mcolor(black) msize(small)) ///
(lfit flb fprox if fprox < 0 & fprox >-11, lcolor(black) lpattern(--)) ///
(lfit flb fprox if fprox >=0 & fprox <=7, lcolor(black) lpattern(--)) ///
 (scatter favgcrash fprox if fprox >=0 & fprox <=7, mcolor(black) msize(small)) ///
 (lfit fub fprox if fprox < 0 & fprox >-11, lcolor(black) lpattern(--)) ///
(lfit fub fprox if fprox >=0 & fprox <=7, lcolor(black) lpattern(--)) ///
 (lfit favgcrash fprox if fprox < 0 & fprox >-11, lcolor(black)) ///
 (lfit favgcrash fprox if fprox >=0 & fprox <=7, lcolor(black)), ///
 xtitle(Weeks from DST) ytitle(Average Number of Fatal Crashes) ylabel(.16(.02).22)legend(off) ///
 xline(-.5,lcolor(blue) lpattern(--)) graphregion(color(white)) title(Fall DST Crashes)

graph export graph.png, replace 

*Gas Price Continuity Check
clear
import excel "J:\Gas_Prices.xlsx", sheet("Sheet2") firstrow
destring Price, replace
destring Fall_P, replace

*Create average price variables
bysort prox : egen savg = mean(Price)
bysort Fall_prox : egen favg = mean(Fall_P)

*Plot for Spring Gas Prices
twoway (lpoly savg prox, lcolor(black)) (scatter savg prox, mcolor(black)), legend(off) ///
xtitle(Average Gas Price) ytitle(Weeks from DST)  xline(-.5,lcolor(blue) lpattern(--)) ///
graphregion(color(white)) title(Gas Prices through Spring DST)

graph export graph.png, replace 

*Plot for Fall Gas Prices
twoway (lpoly favg Fall_prox, lcolor(black)) (scatter favg Fall_prox, mcolor(black)), legend(off) ///
xtitle(Average Gas Price) ytitle(Weeks from DST)  xline(-.5,lcolor(blue) lpattern(--)) ///
graphregion(color(white)) title(Gas Prices through Fall DST)

graph export graph.png, replace 

