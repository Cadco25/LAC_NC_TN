# LAC_NC_TN
Reproducible data analysis for La Crosse virus risk clustering and predictor analysis. 

# IMPORTANT -- Directories and using `renv`

This project uses the `renv` package to create a truly reproducible environment, including the automatic installation of packages at the developmental stage used during the original analysis. You should download this project and save it anywhere on your system, but without changing any of the paths within the project. Each analysis file assumes that the file paths within the project are unchanged.

## Using `renv`

The `renv` package is used to create reproducible environments for R projects. It creates a *project library*, which contains all R packages that are used by the project. The packages in the project library are *the versions used during the original analysis*. This means that if any packages are updated by developers in ways that would change the results of the analysis, this project can still produce the original results because of `renv`. When you open this project for the first time, `renv` will automatically download and install itself and ask you to run `renv::restore()`. *You should run `renv::restore()` to automatically download and install all of the packages within this reproducible environment*. 

# Data Folder

This folder contains three datasets. Each is stored as a *GeoPackage* (.gpkg), which is a platform-independent format for storing geographic information and related attributes. These files can be opened in a variety of software, including open-source programs like R and QGIS, but also proprietary GIS software like ArcGIS Pro. 


`LAC_03to11_clean.gpkg` and `LAC_12to20_clean.gpkg` are used for purely spatial cluster analysis of pediatric cases from 2003 to 2011 and 2012 to 2020, respectively. `LAC_15to20_clean.gpkg` is used for the predictor investigation (univariable and multivariable model fitting). `LAC_15to20_GWR.csv` is used for the negative binomial geographically weighted regression analysis. 

# Analysis Folder

The analysis folder contains scripts for reproducing the purely spatial cluster analysis and predictor investigation from Day et al. (2024). Files with a .R extension are R scripts that should be run in RStudio. Files with a .SAS extension are SAS files that must be run in SAS enterprise guide or other SAS environment. 

