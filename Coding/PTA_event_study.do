* This do file shows how to assess the Parallel Trends Assumption by an event study regression.
* Author: Ian He
* Date: Oct 3, 2023
* Stata Version: 18

clear all


********************************************************************************
**# Regression Evidence
* This is an unbalanced panel, with firm data before and after the implementation of "Broadband China". 

use "..\Data\broadband.dta", clear

gen rel_time = year - policy_year

* Run an event-study regression
eventdd patent_new gdp road highrail airport rdspend roa size leverage sharehold lnage, timevar(rel_time) ///
	method(hdfe, cluster(id) absorb(id year year#province year#sic)) ///
	leads(4) lags(3) accum ci(rcap) noline ///
	graph_op( ///
		xlabel(-4/3, nogrid) ///
		xline(0, lpattern(dash) lcolor(gs12) lwidth(thin)) ///
		legend(order(1 "Point Estimate" 2 "95% CI") size(*0.8) position(6) rows(1) region(lc(black))) ///
	)