clear all
set more off

program main
	summary_stats, run_command(count)   sample(base_catIIop==1 & inrange(yob,1951,1961) & base_iass==1)
	summary_stats, run_command(sum age) sample(base_catIIop==1 & inrange(yob,1951,1961) & base_iass==1)
	* Plots by cohort
	foreach var in ingresos_catIIop r_ingresos_catIIop { //income_op 
		income_cohort, outcome(`var') t_var(age) restr(& base_catIIop==1 & sexo==1) graph_name(Men)
		income_cohort, outcome(`var') t_var(age) restr(& base_catIIop==1 & sexo==0) graph_name(Women)
		//income_cohort, outcome(`var') t_var(age) restr(& inc_l3_above==1 & base_catIIop==1) graph_name(Above_level_3)
		//income_cohort, outcome(`var') t_var(age) restr(& inc_l1_above==1 & inc_l2_above==0 & base_catIIop==1) graph_name(Level_1_to_2)
		//income_cohort, outcome(`var') t_var(age) restr(& inc_l2_above==1 & inc_l3_above==0 & base_catIIop==1) graph_name(Level_2_to_3)
		//income_cohort, outcome(`var') t_var(age) restr(& `var'_above==0 & base_catIIop==1) graph_name(Below_median)
		income_cohort, outcome(`var') t_var(age) restr(& base_catIIop==1 & inc_l1_above==1 & inc_l3_above==0) graph_name(Level_1_to_3)
		income_cohort, outcome(`var') t_var(age) restr(& base_catIIop==1 &  `var'_above==1) graph_name(Above_median)

		grc1leg Men Women Level_1_to_3 Above_median, rows(1) legendfrom(Men) position(6) cols(2) ///
			graphregion(color(white))
		graph export ..\output\plot_`var'_all.pdf, replace
		grc1leg Men Women, rows(2) legendfrom(Men) position(6) cols(2) ///
			graphregion(color(white))  scale(1.2)
		graph display, ysiz(6) xsize(12)
		graph export ..\output\plot_`var'_gender.pdf, replace
		grc1leg Level_1_to_3 Above_median, rows(1) legendfrom(Level_1_to_3) position(6) cols(2) ///
			graphregion(color(white))  scale(1.2)
		graph display, ysiz(6) xsize(12)
		graph export ..\output\plot_`var'_income.pdf, replace
		graph drop _all
	}
	* Plot income distribution
	income_distr, outcome(r_ingresos_catIIop) restr(cohort_t==1 | yob==1956) graph_name(After_1956_inclusive)
	income_distr, outcome(r_ingresos_catIIop) restr(cohort_t==0) graph_name(Before_1956)
	graph combine Before_1956 After_1956_inclusive , ysiz(2.5) graphregion(color(white)) scale(1.5) ycom
	graph export ..\output\plot_income_distr.pdf, replace 
	* Plots relative income distribution
	income_distr_rel, outcome(diff_l1) graph_name(Level_1)
	income_distr_rel, outcome(diff_l3) graph_name(Level_3)
	graph combine Level_1 Level_3, ysiz(2.5) graphregion(color(white)) scale(1.5) 
	graph export ..\output\plot_l1_l3.pdf, replace 
	graph combine Level_1_s Level_3_s, ysiz(2.5) graphregion(color(white)) scale(1.5) 
	graph export ..\output\plot_l1_l3_s.pdf, replace 
	graph combine Level_1_nc Level_3_nc, ysiz(2.5) graphregion(color(white)) scale(1.5) 
	graph export ..\output\plot_l1_l3_nc.pdf, replace 
	graph drop _all
end

capture program drop summary_stats
program              summary_stats
syntax, run_command(str) sample(str)
	use ..\..\derived\output\dgi_2009_2012_new_vars.dta, clear
	`run_command' if base_catIIop==1 & base_catI==0 & base_pat==0 & `sample'
	`run_command' if base_catIIop==0 & base_catI==1 & base_pat==0 & `sample'
	`run_command' if base_catIIop==0 & base_catI==0 & base_pat==1 & `sample'
	`run_command' if base_catIIop==1 & base_catI==1 & base_pat==0 & `sample'
	`run_command' if base_catIIop==1 & base_catI==0 & base_pat==1 & `sample'
	`run_command' if base_catIIop==0 & base_catI==1 & base_pat==1 & `sample'
	`run_command' if base_catIIop==1 & base_catI==1 & base_pat==1 & `sample'
end

capture program drop income_cohort
program              income_cohort
syntax, outcome(string) restr(string) graph_name(string) t_var(string)
	use ..\..\derived\output\dgi_2009_2012_new_vars.dta, clear
	preserve
		collapse (mean) `outcome' [aw = peso] if (!mi(cohort_t) | yob==1956) `restr', by(yob `t_var')
		capture lab var r_ingresos_catIIop  "Real taxable labor income (single)"
		capture lab var   ingresos_catIIop  "Nominal taxable labor income (single)"
		capture lab var ingresos_catIIop2 "Taxable labor income (single)"
		capture lab var income_op "Taxable total income (single)"
		xtset yob `t_var'
		sum `t_var'
		local t_min `r(min)'
		local t_max `r(max)'
		sum `outcome'
		local y_min = round(`r(min)'/10000)*10000
		local y_max = round(`r(max)'/10000)*10000
		local interval = round((`y_max'-`y_min')/2)
		xtline `outcome', ov name(`graph_name') ylabel(`y_min' (`interval') `y_max') ///
			tlabel(`t_min' (2) `t_max' ) legend(rows(2) symx(5) si(small)) ///
			graphregion(color(white)) bgcolor(white) title(`graph_name') ///
			plot6(lp("-..")) plot7(lp(dash)) plot8(lp(dash)) plot9(lp(dash)) ///
			plot10(lp(dash)) plot11(lp(dash))
	restore
end

capture program drop income_distr
program              income_distr
syntax, outcome(str) restr(str) graph_name(str)
	use ..\..\derived\output\dgi_2009_2012_new_vars.dta, clear
	/*qui sum cpi_2009 if year==2012
	local cpi_2012 = `r(mean)'
	forvalues level = 1/3 {
		qui sum r_level_`level' if year==2012
		local l_2012_`level' = `r(mean)'*12/(`cpi_2012'/100)
	}*/
	forvalues level = 1/3 {
		qui sum r_level_`level' if year==2009
		local l_2012_`level' = `r(mean)'*12
	}
	sum  `outcome' if (`restr') & base_catIIop==1, det
	hist `outcome' if (!mi(cohort_t) | yob==1956) & base_catIIop==1 & ///
			inrange(`outcome',0,`r(p95)') & (`restr') [fw = peso2] ///
			, w(28000) graphregion(color(white)) legend(off) ///
			  title(`graph_name') name(`graph_name') ylabel(#2) ///
			  addplot(pci 0 `l_2012_1' 0.000005 `l_2012_1' || ///
					  pci 0 `l_2012_2' 0.000005 `l_2012_2' || ///
					  pci 0 `l_2012_3' 0.000005 `l_2012_3')
end

capture program drop income_distr_rel
program              income_distr_rel
syntax, outcome(str) graph_name(str) [restr(str)]
	use ..\..\derived\output\dgi_2009_2012_new_vars.dta, clear
	local restriction = "(!mi(cohort_t) | yob==1956) & base_catIIop ==1"
	* Using scaled weights
	hist `outcome' if `restriction'  ///
		& inrange(`outcome',-40000,40000) [fw=peso2] ///
		, width(1500) xline(0) name(`graph_name') title(`graph_name') graphregion(color(white)) 
	hist `outcome' if `restriction'  ///
		& inrange(`outcome',-33750,33750) [fw=peso2] ///
		, width(1125) xline(0) name(`graph_name'_s) title(`graph_name') graphregion(color(white))  xlab(-33750(33750)33750)
	*Using NC method
	local outcome = "diff_l1"
		* Midpoints of bins of width 1500, starting at 0
		gen `outcome'_2 = 1 + 1500 * floor(`outcome'/1500) if `restriction'
		* Use price as aw 
		egen binheight = sum(peso) if `restriction' , by(`outcome'_2)
		* Need to use each bin just once 
		egen tag = tag(`outcome'_2) if `restriction'
		* Get total of weights and resize binheight 
		su binheight if tag & `restriction', meanonly 
		di r(sum)
		replace binheight = binheight/r(sum) if `restriction'
		* Bar plot
		twoway bar binheight `outcome'_2 if tag & `restriction' ///
			& inrange(`outcome'_2,-50000,50000) ///
			, bstyle(histogram) barw(1500) ylab(0(.001).003) ytitle(Fraction) ///
			xline(0) xtitle(`: var label `outcome'') graphregion(color(white)) ///
			 name(`graph_name'_nc) title(`graph_name')
end

main

