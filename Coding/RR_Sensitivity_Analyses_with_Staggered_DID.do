* This do file shows how to conduct sensitivity analyses in heterogeneity-robust DID models, following Rambachan & Roth (2023).
* Author: Ian Ho
* Date: Oct 16, 2023
* Stata Version: 18 (not required)

/* Required Packages:
ssc install ftools, replace
ssc install reghdfe, replace
ssc install drdid, replace
ssc install csdid, replace
ssc install avar, replace
ssc install eventstudyinteract, replace
ssc install did_multiplegt, repalce
ssc install event_plot, replace
ssc install honestdid, replace
ssc install coefplot, replace
*/


********************************************************************************
**# Callaway & Sant'Anna (2021) DID Model
use "..\Data\Medicaid_Expansion.dta", replace

recode yexp2 (. = 0)	// Groups that are never treated must be coded as 0.

* CS DID regression
csdid dins, ivar(stfips) time(year) gvar(yexp2) ///
	method(dripw) wboot(reps(1000)) rseed(1016)

* Pretrend test: all pre-treatment group-time ATTs within window are statistically equal to zero.
csdid_estat pretrend, window(-5 -1)

* Aggregation
csdid_estat event, window(-5 5) ///
	wboot(reps(1000)) rseed(1016) ///
	estore(cs) post
	// "post" forces Stata to post the results in e().

mat list e(b)

* Event-study plot
event_plot cs, default_look ///
		stub_lag(Tp#) stub_lead(Tm#) together ///
		graph_opt( ///
			xtitle("Relative Period") ytitle("ATT") ///
			title("CS DID Results", size(medlarge) position(11)) ///
			xlab(-5/5, nogrid labsize(small)) ///
			ylab(, angle(90) labsize(small)) ///
		)


* Sensitivity analysis (RM) for tau_0: The breakdown value for a significant value is about 1.5.
honestdid, pre(3/7) post(8/13) mvec(0.5(0.5)3) ///
	coefplot xtitle("M") ytitle("95% Confidence Intervals")

* Sensitivity analysis (RM) for tau_1
matrix l_vec = 0 \ 1 \ 0 \ 0 \ 0 \ 0

honestdid, pre(3/7) post(8/13) mvec(0.5(0.5)3) ///
	l_vec(l_vec) ///
	coefplot xtitle("M") ytitle("95% Confidence Intervals")

* Sensitivity analysis (SD) for tau_0
honestdid, pre(3/7) post(8/13) mvec(0.01(0.01)0.05) ///
	delta(sd) ///
	coefplot xtitle("M") ytitle("95% Confidence Intervals")




********************************************************************************
**# Sun & Abraham (2021) DID Model
use "..\Data\Medicaid_Expansion.dta", replace

* Generate a list of relative time dummies
gen rel_time = year - yexp2

gen Dn5 = (rel_time <= -5)
forvalues i = 4(-1)1 {
	gen Dn`i' = (rel_time == -`i')
}

forvalues i = 0(1)4 {
	gen D`i' = (rel_time == `i')
}
gen D5 = (rel_time >= 5) & (rel_time != .)

* SA DID regression
gen never_treated = (yexp2 == .)

eventstudyinteract dins Dn5-Dn2 D0-D5, ///
		cohort(yexp2) control_cohort(never_treated) ///
		absorb(stfips year) vce(cluster stfips)

* Sensitivity analysis (RM) for tau_0: The breakdown value for a significant effect is about 2.5.
mata index = 1..4, 5..10
mata st_matrix("b", st_matrix("e(b_iw)")[index])
mata st_matrix("V", st_matrix("e(V_iw)")[index, index])
matrix list b
matrix list V

honestdid, pre(1/4) post(5/10) mvec(0.5(0.5)3) ///
	b(b) vcov(V) ///
	coefplot xtitle("M") ytitle("95% Confidence Intervals")




********************************************************************************
**# de Chaisemartin & D'Haultfoeuille (2022) DID Model
use "..\Data\Medicaid_Expansion.dta", replace

gen treated = (year >= yexp2) & (yexp2 != .)

* DID regression
did_multiplegt dins stfips year treated, ///
	robust_dynamic dynamic(5) placebo(5) ///
	seed(1015) breps(50) cluster(stfips)

* Sensitivity analysis (RM) for tau_0: The breakdown value for a significant effect is about 2.5.
honestdid, pre(7/11) post(1/6) mvec(0.5(0.5)3) ///
	b(didmgt_results_no_avg) vcov(didmgt_vcov) ///
	coefplot xtitle("M") ytitle("95% Confidence Intervals")