# Data and Reproducible Analysis For: "Persistent Spatial Clustering and Predictors of Pediatric La Crosse Virus Neuroinvasive Disease Risk in Eastern Tennessee and Western North Carolina, 2003-2020"

This repository contains pre-processed data sets and code scripts to reproduce the purely spatial cluster analyses and predictor investigations that are described in the manuscript. Because of concerns regarding the privacy of study subjects, the annual data for the space-time cluster investigation is not provided. Please read this entire README file for details on the data and code, and how to use it. 

# Ethics Approval 

This study was approved by the University of Tennessee, Knoxville Institutional Review Board (UTK IRB-22-07079-XP) and the Tennessee Department of Health Institutional Review Board (TDH IRB 2021-0314). Data provided here is de-identified and aggregated (both temporally and spatially) to protect the privacy of individuals included in the study, in concordance with IRB and Data Use Agreements. 

# How to use this repository 

This repository is designed to support the reproduction of analyses in the associated manuscript. The entire project can be downloaded and stored anywhere on your computer, as long as the file structure is not altered. The project contains folders with all data sets and code scripts necessary for analysis. 


What you will need: 
 - Installed R and RStudio for purely spatial cluster and global model analyses
 - SAS Enterprise Guide, SAS studio, or other SAS interface for the geographically weighted regression 
 - Basic understanding of how to open R/SAS and run code 
 - For SAS only -- an understanding of where you installed this project so that you can define the directory 
 
 You do NOT need:
 - To download or install R packages on your own; that is taken care of within this environment
 - To download or install SAS macros; the necessary macro is included in the `analysis` folder 
 - To write any code 
 - To set up any working directories in R 

## ***Important***: Using `renv`

Short Version: When you open the R project, run `renv::init()` and follow the prompts to install the necessary R packages. 

The R package `renv` was used to create a **project library**, which contains all R packages that are used by the project. The packages in the project library are **the versions used during the original analysis**. This means that if any packages are updated by developers in ways that would change the results of the analysis, this project can still produce the original results because of `renv`. When you open this project for the first time, `renv` will automatically download and install itself and ask you to run `renv::restore()`. **You should run `renv::restore()` to automatically download and install all of the packages within this reproducible environment**. 

## Basic step-by-step guide:

- 1. Download the entire repository by clicking "Code -> Download ZIP" on GitHub or by downloading the ZIP file in Zenodo
- 2. Extract the ZIP file anywhere on your computer (do not change the structure of the files once extracted)
- 3. In RStudio, click *File -> Open Project* and browse to the location where you extracted the repository; in the repository file, open the LAC-NC_TN R Project file 
- 4. Open either of the R scripts in the `analysis/` folder
- 5. Run the code 'renv::init()' in the script or in the console and follow the prompt to install the packages 
  - Now you can run the R Scripts; start from the top with loading the packages and data, then work your way down line-by-line
- 6. To run the .SAS code, open `analysis/3_LocalModel` in SAS Enterprise Guide or SAS Studio, replace directories with your directories as prompted within the file, and then run each chunk of code from top to bottom


# Data sources

Details regarding sources and processing techniques are described in "Persistent Spatial Clustering and Predictors of Pediatric La Crosse Virus Neuroinvasive Disease Risk in Eastern Tennessee and Western North Carolina, 2003-2020". Please refer to the methods in that manuscript and supplemental file "Table S1". 

In brief: 
- Case data was provided by the North Carolina Department of Health & Human Services and the Tennessee Department of Health
- Census data was extracted from the 2000, 2010, and 2020 United States Census Bureau decennial surveys, as well as the 2020 American Community Survey; 
- land cover data was exctracted from the 2019 National Land Cover Database; 
- climate data was obtained from the PRISM Climate Group; 
- elevation was obtained using the United States Geographic Service LiDAR Explorer. 

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
- `2_GlobalModels.R` contains code for predictor selection and identification of the final global negative binomial regression model.  
- `3_LocalModel.SAS` contains SAS code for running the negative binomial geographically weighted regression model (i.e., local model), including the golden search selection for identifying the optimal bandwidth and the non-stationarity test. Note that this file contains code to save the results of the models (e.g., coefficients, residuals, and local p-values) in csv files that can be joined to geographic boundaries to create maps of the results. 
    - `C_GWNBR` is the SAS Macro for the negative binomial geographically weighted regression from [da Silva and Rodrigues (2016)](https://chat.openai.com/c/a6c4169e-cd13-48f9-9e7f-27df47bd29de) (see this link). 