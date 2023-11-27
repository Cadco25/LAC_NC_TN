/***************************************************
 Title: Univariable Analysis of Potenital Predictor Variables 
 Reproducible Analysis For: Day et al. (2024) PLOS Neg Trop Dis 
 Author: Corey Day 
 Date Created: 27 November 2023 
 Questions? email coreyallenday96@gmail.com 
***************************************************/

/* Set your project directory */ 
%let rc = %sysfunc(
dlgcdir(
/* Replace with your directory to project root */ 
'C:\Users\corey\OneDrive - University of Tennessee\Spatial_LACV_TN_NC\reproducible project\LAC_NC_TN'));

LIBNAME gwr 'data/';
/* Load the data */
proc import 
out=LAC_15to20
datafile='data/LAC_15to20_GWR.csv'
dbms=csv
replace;
guessingrows=MAX;
getnames=YES;
run;
/* create numeric ID column named var2 */
data LAC_15to20_formatted;
set LAC_15to20;
 	var2 = input(var1, ?? best32.);;
	run;

/* export a file with var2 for joining */ 	
proc export data= LAC_15to20_formatted
    outfile="c:/users/corey/OneDrive - University of Tennessee/Spatial_LACV_TN_NC/reproducible project/LAC_NC_TN/files for GIS mapping/LAC_NBGWR_ForJoining.csv"
    dbms=csv
    replace;
run;


/*GWR Model without interaction using method = adaptive1 type=aic offset=log_total_population_19under*/;
/* Estimate the bandwidth (xmin) */
Title "FINAL GWR NB Model 1 using Method=adaptive, type=aic and offset=log_total_population_19under";
Title2 "Estimation of Bandwidth (xmin)";
/* Replace with your directory to C_GWNBR.SAS */ 
%Include 'C:\Users\corey\OneDrive - University of Tennessee\Spatial_LACV_TN_NC\reproducible project\LAC_NC_TN\analysis\C_GWNBR.sas';
%Golden(data = LAC_15to20_formatted,
		y = cases_19under,
		x = precip_mean temp_mean tempxprecip,
		offset = log_pop_19under,
	    lat = Y_COORD,
		long = X_COORD,
		method = adaptive1, 
		type = aic,
		gwr = global,
		out=band);

/* Use the estimated bandwidth to fit the NB GWR */
Title "FINAL GWR NB Model 1 using Method=adaptive, type=aicc and offset=logpop";
Title2 "FINAL GWR NB Model 1";
/* Replace with your directory to C_GWNBR.SAS */ 
%Include 'C:\Users\corey\OneDrive - University of Tennessee\Spatial_LACV_TN_NC\reproducible project\LAC_NC_TN\analysis\C_GWNBR.sas';
%gwnbr(data = LAC_15to20_formatted,
		y=cases_19under,
		x=precip_mean temp_mean tempxprecip,
		offset=log_pop_19under,
	    lat=Y_COORD, 
        long=X_COORD,
		h=124, /* This comes from xmin in the results from the previous code */
		gwr=global,
		method=adaptive1,
		alphag=,
		geocod = var2, /* use the numeric ID code */
		out = negglob_adap); 

/* AICc = 480; much better than the global model */ 

/* Save GWNBR model parameters in permanent dataset - can be exported to map coefficients, t-values etc. */ 

data LAC_15to20_formatted;
	set _parameters_; 
run;


/* Print GWNBR model parameter estimates */
	
Title 'Parameter estimates of GWNBR';

proc contents; 
run;

proc print;
run;


/* Save GWNBR model residuals */

data LAC_15to20_formatted;
	set _res_; 
run;

/* Print GWNBR residuals */ 

Title "Residuals of GW NB";

proc contents; 
run;

proc print; 
run;

/*Testing stationarity of local coefficients in the NB GWR model without interaction*/;
Title2 "Testing stationarity of local coefficients";
/* Replace with your directory to C_GWNBR.SAS */ 
%Include 'C:\Users\corey\OneDrive - University of Tennessee\Spatial_LACV_TN_NC\reproducible project\LAC_NC_TN\analysis\C_GWNBR.sas';
%estac(data = LAC_15to20_formatted,
		y=cases_19under,
		x= precip_mean temp_mean tempxprecip,
		lat=Y_COORD,
		long=X_COORD,
		h=124, /* used the same bandwidth as above */
		grid=,
		gwr=global,
		method=adaptive1,
		alphag=,
		offset = log_pop_19under,
		geocod=var2,
		rep=999); /* takes a long time to run */


