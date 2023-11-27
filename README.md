# LAC_NC_TN
Reproducible data analysis for La Crosse virus risk clustering and predictor analysis. 

# IMPORTANT -- Directories and using `renv`

This project uses the `renv` package to create a truly reproducible environment, including the automatic installation of packages at the developmental stage used during the original analysis. You should download this project and save it anywhere on your system, but without changing any of the paths within the project. Each analysis file assumes that the file paths within the project are unchanged.

## Using `renv`

The `renv` package is used to create reproducible environments for R projects. It creates a **project library**, which contains all R packages that are used by the project. The packages in the project library are **the versions used during the original analysis**. This means that if any packages are updated by developers in ways that would change the results of the analysis, this project can still produce the original results because of `renv`. When you open this project for the first time, `renv` will automatically download and install itself and ask you to run `renv::restore()`. **You should run `renv::restore()` to automatically download and install all of the packages within this reproducible environment**. 

# `data/` Folder

This folder contains three datasets. Most are stored as a **GeoPackage** (.gpkg), which is a platform-independent format for storing geographic information and related attributes. These files can be opened in a variety of software, including open-source programs like R and QGIS, but also proprietary GIS software like ArcGIS Pro. See `data dictionary.txt` for a description of all attributes contained within each file. 

## Files within the `data/` folder

- `data dictionary.txt` contains descriptions of every attribute within each data file below
- `LAC_03to11_clean.gpkg` and `LAC_12to20_clean.gpkg` are used for purely spatial cluster analysis of pediatric cases from 2003 to 2011 and 2012 to 2020, respectively. 
- `LAC_15to20_clean.gpkg` is used for the predictor investigation (univariable and multivariable model fitting).  
- `LAC_15to20_GWR.csv` is used for the negative binomial geographically weighted regression analysis. 

# `analysis/` Folder

The `analysis/` folder contains scripts for reproducing the purely spatial cluster analysis and predictor investigation from Day et al. (2024). Files with a .R extension are R scripts that should be opend with RStudio. Files with a .SAS extension are SAS files that must be opened with SAS enterprise guide or another SAS environment. SAS is not open-source and typically requires a license to use. You may be able to access SAS Studio for no charge by using [SAS OnDemand for Academics](https://welcome.oda.sas.com/). 

## Files within the `analysis/` folder

The files are numbered in the order that they were run for the original analysis. In this case, none of the analyses are dependent on the others, so they can technically be used in any order.

- `1_PurelySpatialClusters.R` contains code for the purely spatial cluster analysis using FlexScan
- `2_UnivariableRegression.R` includes the correlation analysis and univariable models used to determine which potential predictors would be retained for the multivariable model. 
- `3_MultivariableRegression.R` contains the manual backward elimination used to identify a final parsimonious model. 
- `4_GeographicallyWeightedRegression.SAS` contains SAS code for running the negative binomial geographically weighted regression model, including the golden search selection for identifying the optimal bandwidth and the non-stationarity test. Note that this file contains code to save the results of the models (e.g., coefficients, residuals, and local p-values) in csv files that can be joined to geographic boundaries to create maps of the results. 
-`C_GWNBR` is the SAS Macro for the negative binomial geographically weighted regression from [da Silva and Rodrigues (2016)](https://chat.openai.com/c/a6c4169e-cd13-48f9-9e7f-27df47bd29de) (see this link). 

