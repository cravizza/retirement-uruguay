clear all
global path_dgi "C:\Users\cravizza\Google Drive\Projects\Aborto-Uruguay\other_data\DGI+BASES+WEB"

program main
	append_merge_data
	create_new_vars	
end

program append_merge_data
	* Import income_levels & inflation
	import excel "${path_dgi}\income_levels.xlsx", clear firstrow
	drop _*
	save ..\temp\income_levels.dta, replace
	import excel "${path_dgi}\inflation.xlsx", clear firstrow
	rename anio year
	keep year cpi_2009
	save ..\temp\inflation.dta, replace
	clear
	* Construct panel dataset
	forvalues year = 2009/2012 {
		import excel "${path_dgi}\muestra`year'.xlsx", clear firstrow 
		gen year = `year'
		save ..\temp\dgi_m_`year', replace
	}
	use ..\temp\dgi_m_2009
	forvalues year = 2010/2012 {
		append using ..\temp\dgi_m_`year'
	}
	isid nii_retenido_muestra year
	assert !(base_catIIop==1 & base_nf==1) //for CatII only single or married
	merge m:1 year using ..\temp\income_levels.dta, assert(3) nogen
	merge m:1 year using ..\temp\inflation.dta, keep(3) nogen
	save ..\temp\dgi_2009_2012.dta, replace
end

program create_new_vars
	use ..\temp\dgi_2009_2012.dta, clear
	* Note ingresos_catIIop>=ingresos_computables_catIIop if !mi(ingresos_computables_catIIop)
	gen     ingresos_catIIop2 = ingresos_catIIop             if year!=2012
	replace ingresos_catIIop2 = ingresos_computables_catIIop if year==2012
	lab var ingresos_catIIop2 "Taxable labor income (single)"
	lab var ingresos_nf_retenido "Taxable labor income (pers1)"
	lab var ingresos_nf_conyuge  "Taxable labor income (pers2)"
	egen income_op = rowtotal(ingresos_catIIop montoimponible651 montoimponible652 ///
							  montoimponible653 montoimponible662 montoimponible663 ///
							  montoimponible664 montoimponible660 montoimponible671 ///
							  montoimponible680 montoimponible666 montoimponible667 ///
							  montoimponible668 Patr) if base_catIIop==1
	lab var income_op "Taxable total income (single)"
	* Inflation adjustment
	foreach var in ingresos_catIIop ingresos_catIIop2 level_1 level_2 level_3 {
		gen r_`var' = (`var') / (cpi_2009/100)
	}
	lab var   ingresos_catIIop  "Nominal taxable labor income (single)"
	lab var r_ingresos_catIIop  "Real taxable labor income (single)"
	* Derived income vars
	forvalues level = 1/3 {
		gen diff_l`level' = r_ingresos_catIIop - (r_level_`level'*12)
		label var diff_l`level' "Real labor income relative to Level `level'"
		gen inc_l`level'_above = (r_ingresos_catIIop >(r_level_`level'*12)) ///
			if !mi(`var') & base_catIIop==1
	}
	foreach var in income_op r_ingresos_catIIop ingresos_catIIop {
		qui sum `var' if !mi(`var') & base_catIIop==1, det
		gen `var'_above = (`var'>`r(p50)') ///
			if !mi(`var') & base_catIIop==1
	}
	* Demo vars
	rename edad age
	label var age Age
	gen yob = year - age
	lab var yob "Year of birth"
	assert inlist(sexo,1,2)
	replace sexo = 0 if sexo==2
	* Cutoff var: age 40 in 04-1996. Only yob, so could exclude anyone 40 in 1996
	gen reform = (yob<1956) if yob!=1956
	gen cohort_t = (inrange(yob,1957,1961)) if inrange(yob,1951,1955)|inrange(yob,1957,1961)
	
	gen peso2 = peso*1000000000000
	save ..\output\dgi_2009_2012_new_vars.dta, replace
end

main

