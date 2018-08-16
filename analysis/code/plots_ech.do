clear all
set more off
global path_ech "C:\Users\cravizza\GitHub\Aborto-Uruguay\assign_treatment\output"

program main
	plot_cohort, outcome(trabajo) t_var(age) graph_name(Employment)
	plot_cohort, outcome(horas_trabajo) t_var(age) graph_name(Hours_worked)
	grc1leg Employment Hours_worked, rows(1) legendfrom(Employment) position(6) cols(2) ///
				graphregion(color(white))  scale(1.2)
	graph display, ysiz(6) xsize(12)
	graph export ..\output\plot_ech.pdf, replace
	grc1leg Employment_s Hours_worked_s, rows(1) legendfrom(Employment_s) position(6) cols(2) ///
				graphregion(color(white))  scale(1.2)
	graph display, ysiz(6) xsize(12)
	graph export ..\output\plot_ech_s.pdf, replace
	graph drop _all
end

program plot_cohort
syntax, outcome(str) t_var(str) graph_name(str)
	use  "${path_ech}\ech_final_98_2016.dta", clear
	rename edad age
	tab yob
	gen cohort_t = (inrange(yob,1957,1961)) if inrange(yob,1951,1955)|inrange(yob,1957,1961)
	collapse (mean) `outcome' [aw = pesoan] if (!mi(cohort_t) | yob==1956), by(yob `t_var')
	capture lab var trabajo "Employment"
	capture lab var horas_trabajo "Hours worked"
	capture lab var age "Age"
	keep if inrange(`t_var',40,59)
	xtset yob `t_var'
	sum `t_var'
	local t_min `r(min)'
	local t_max `r(max)'
	/*xtline `outcome' ///
		, ov tlabel(`t_min' (2) `t_max' ) legend(rows(2) symx(5) si(small)) ylab(#3) ///
		graphregion(color(white)) bgcolor(white) name(`graph_name') title(`graph_name') ///
		plot6(lp("-..")) plot7(lp(dash)) plot8(lp(dash)) plot9(lp(dash)) ///
		plot10(lp(dash)) plot11(lp(dash)) */
	xtline `outcome' if inrange(yob,1954,1958) ///
		, ov tlabel(`t_min' (2) `t_max' ) legend(rows(1) symx(5) si(small)) ylab(#3) ///
		graphregion(color(white)) bgcolor(white) name(`graph_name') title(`graph_name') ///
		plot1(lc(orange)) plot2(lc(olive))	plot3(lp("-..") lc(red)) ///
		plot4(lp(dash) lc(lavender)) plot5(lp(dash) lc(khaki))
	xtline `outcome' if inrange(yob,1955,1957) ///
		, ov tlabel(`t_min' (2) `t_max' ) legend(rows(1) symx(5) si(small)) ylab(#3) ///
		graphregion(color(white)) bgcolor(white) name(`graph_name'_s) title(`graph_name') ///
		plot1(lc(olive)) plot2(lp("-..") lc(red))	plot3(lp(dash) lc(lavender))
end

main
	
/*
gen cohort = .
forvalues y = 0/7 {
	local age_treat = 18 + `y'*5
	
	local yr_start = 1990 - `y'*5
	local yr_end   = `yr_start'+4
	di "Age: " `age_treat' ". Start: " `yr_start' ". End: " `yr_end'
	
	replace cohort = `age_treat' if inrange(yob,`yr_start',`yr_end')
	gen     cohort_`age_treat'    = inrange(yob,`yr_start',`yr_end')
}
*****
gen     cohort = 0  if inrange(yob,1933,1944)
replace cohort = 11 if inrange(yob,1995,2000) 
forvalues y = 1/10 {
	local yr_start = 1940 + `y'*5
	local yr_end   = `yr_start'+4
	di "Start: " `yr_start' ". End: " `yr_end'
	replace cohort = `y' if inrange(yob,`yr_start',`yr_end')
}
