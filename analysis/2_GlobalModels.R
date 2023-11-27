################################################################################
# Title: Univariable Analysis of Potenital Predictor Variables 
# Reproducible Analysis For: Day et al. (2024) PLOS Neg Trop Dis 
# Author: Corey Day 
# Date Created: 27 November 2023 
# Questions? email coreyallenday96@gmail.com 
################################################################################

# Run `renv::restore()` to install all packages needed for this project. 

#### Load Packages ----
library(tidyverse) # to manipulate data 
library(MASS) # to run negative binomial models 
library(MuMIn) # to calculate AICc
library(performance) # to test overdispersion
library(sf)

#### Load Data ----
LAC_15to20 <- st_read('data/LAC_15to20_clean.gpkg')
  
#### Correlation Analysis ---- 


cor_vars <- st_drop_geometry(LAC_15to20) %>%
  dplyr::select(percent_male, percent_poverty, elevation:pop_19under) 
  

# calculate correlation coefficients 
cor_matrix <- cor(cor_vars,use='complete.obs')

# set a threshold for correlation 
threshold <- 0.70

# get row and column indices of high correlations
indices <- which(abs(cor_matrix) > threshold, arr.ind = TRUE)

# display variable pairs and their correlations, excluding self-comparisons and duplicates

for (i in 1:nrow(indices)) { # for loop 
  row_index <- indices[i, 1]
  col_index <- indices[i, 2]
  
  # exclude self-comparisons and duplicates
  if (row_index < col_index) {
    cat("Variables:", rownames(cor_matrix)[row_index], "and", colnames(cor_matrix)[col_index], "\n")
    cat("Correlation:", cor_matrix[row_index, col_index], "\n\n")
  }
}

# temp_mean and elevation are too correlated 
# pop_dens_sqkm and percent developed are too correlated
# percent_developed and percent_forest are too correlated
# Drop: percent_developed and elevation 

#### Univariable Regression Models ---- 

# p < 0.10 is considered sufficent for retaining the variable for multivariable model fitting 

# create a list of predictor variables 
predictor_vars <- c('percent_male', 'percent_poverty', 'change_developed',
                    'percent_education', 'percent_vacant', 'percent_built1969',
                    'pop_dens_sqkm', 'percent_forest', 'temp_mean', 'precip_mean'
                    )
# run a for loop that fits a model for every variable 
for (predictor in predictor_vars) {
  formula <- paste("cases_19under ~ offset(log(pop_19under)) +", predictor) # each model includes the offset and one predictor
  model <- MASS::glm.nb(formula, data = LAC_15to20) # fits the model 
  
  cat("Regression model for", predictor, ":\n") # title for each model 
  print(summary(model))  # Use print() to display the summary
  cat("\n\n")
}

# change_developed, percent_poverty, percent_build1969, percent_vacant, pop_dens_sqkm, percent_forest, temp_mean, precip_mean are all retained 

#### Check Poisson distribution ----

full_poiss <- glm(cases_19under ~ temp_mean*precip_mean + change_developed + percent_poverty + percent_built1969 +
                    percent_vacant + pop_dens_sqkm + percent_forest + 
                    offset(log(pop_19under)),
                  data = LAC_15to20, family='poisson')
summary(full_poiss) # AIC = 545

performance::check_overdispersion(full_poiss) # overdispersion is detected


full_nb <- glm.nb(cases_19under ~ temp_mean*precip_mean + change_developed + percent_poverty + percent_built1969 +
                  percent_vacant + pop_dens_sqkm + percent_forest +  
                 offset(log(pop_19under)),
               data = LAC_15to20)
summary(full_nb) # AIC = 516

# change in AIC is 29, with the negative binomial model providing a better fit than the Poisson 


#### Backward regression on multivariable model ----

# significance threshold is p < 0.05
# variable with highest p-value is removed at each step 

full <- glm.nb(cases_19under ~ temp_mean*precip_mean + change_developed + percent_poverty + percent_built1969 +
                 percent_vacant + pop_dens_sqkm + percent_forest +   
                 offset(log(pop_19under)),
               data = LAC_15to20)
summary(full) # drop percent_built1969

drop1 <- glm.nb(cases_19under ~ temp_mean*precip_mean + change_developed + percent_poverty +
                  percent_vacant + pop_dens_sqkm + percent_forest +   
                  offset(log(pop_19under)),
                data = LAC_15to20)
summary(drop1) # drop percent_vacant

drop2 <- glm.nb(cases_19under ~ temp_mean*precip_mean + change_developed + percent_poverty +
                  pop_dens_sqkm + percent_forest +   
                  offset(log(pop_19under)),
                data = LAC_15to20)
summary(drop2) # drop change_developed

drop3 <- glm.nb(cases_19under ~ temp_mean*precip_mean + percent_poverty +
                  pop_dens_sqkm + percent_forest +   
                  offset(log(pop_19under)),
                data = LAC_15to20)
summary(drop3) # drop pop_dens_sqkm

drop4 <- glm.nb(cases_19under ~ temp_mean*precip_mean + percent_poverty +
                   percent_forest +   
                  offset(log(pop_19under)),
                data = LAC_15to20)
summary(drop4) # drop percent_forest

drop5 <- glm.nb(cases_19under ~ temp_mean*precip_mean + percent_poverty +
                  offset(log(pop_19under)),
                data = LAC_15to20)
summary(drop5) # drop percent_poverty

drop6 <- glm.nb(cases_19under ~ temp_mean*precip_mean + 
                  offset(log(pop_19under)),
                data = LAC_15to20)
summary(drop6) # all predictors significant; final model 


#### Extract model coefficients, confidence intervals, and AICc ----

final_model <- glm.nb(cases_19under ~ temp_mean*precip_mean + offset(log(pop_19under)), data = LAC_15to20)
summary(final_model)

coefficients(final_model) # coefficients
confint(final_model) # 95% confidence intervals 

exp(coefficients(final_model)) # risk ratios
exp(confint(final_model)) # 95% confidence intervals for risk ratios 

MuMIn::AICc(final_model) # AICc = 509.97


#### Create dataset for local model fitting in SAS ---

LAC_15to20_coords <- st_centroid(LAC_15to20) %>% # calculate centroids
  dplyr::select(cases_19under, pop_19under, temp_mean, precip_mean) %>%
  mutate(X_COORD = sf::st_coordinates(.)[,1], # extract x centroid coordinate
         Y_COORD = sf::st_coordinates(.)[,2], # extract y centroid coordinate
         tempxprecip = temp_mean*precip_mean,
         log_pop_19under = log(pop_19under)) %>%
         drop_na() %>% # drop NAs because they won't be included in the analysis anyway and they interfere with SAS reading the data
  st_drop_geometry() # drop geometry 
  
# optional: save the file (this file is already present in the project)
# write.csv(LAC_15to20_coords, "data/LAC_15to20_GWR.csv")

