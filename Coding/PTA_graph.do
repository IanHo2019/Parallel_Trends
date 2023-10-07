* This do file shows how to assess the Parallel Trends Assumption by a graph, which is a traditional assessment.
* Author: Ian Ho
* Date: Oct 3, 2023
* Stata Version: 18


clear all

********************************************************************************
**# Data Generating Process
********************************************************************************
local units = 10					// number of units
local time = 21						// number of calendar time periods
local treat_t = 11					// treatment time
local obs_num = `units' * `time'	// number of observations

set obs `obs_num'
set seed 1003

* Construct a balanced panel
egen id	= seq(), block(`time')
egen t = seq(), from(1) to(`time')

gen treat_group = (id > 5)
gen treat_dummy = (t >= `treat_t')
gen treated = treat_group * treat_dummy

gen TE = cond(treated==1, 10, 0)	// true treatment effect

gen eps = rnormal(0, 2)				// error term

gen Y = id + t + TE + eps


********************************************************************************
**# Graphical Evidence
********************************************************************************
gen rel_time = t - 11		// relative time to treatment time

bysort rel_time treat_group: egen average_Y = mean(Y)

twoway (connected average_Y rel_time if treat_group==1, mc(cranberry) lc(cranberry) msymbol(O)) ///
	(connected average_Y rel_time if treat_group==0, mc(midblue) lc(midblue) msymbol(Oh)), ///
	xline(-0.5, lp(dash)) ///
	xtitle("Relative Period") ytitle("Average Outcome") xlab(-10/10, nogrid) ///
	legend(order(1 "Treated Group" 2 "Control Group") rows(1) size(*0.8) position(6) region(lc(black)))
graph export "..\Figures\PTA_graph_evidence.svg", replace
