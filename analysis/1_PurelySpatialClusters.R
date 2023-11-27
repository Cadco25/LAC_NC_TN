################################################################################
# Title: FlexScan Purely Spatial Cluster Analysis 
# Reproducible Analysis For: Day et al. (2024) PLOS Neg Trop Dis 
# Author: Corey Day 
# Date Created: 27 November 2023 
# Questions? email coreyallenday96@gmail.com 
################################################################################

# Run `renv::restore()` to install all packages needed for this project. 

#### Load Packages ----
library(sf)
library(rflexscan)
library(tidyverse)
library(spdep)

#### Load Data ----

LAC_03to11 <- st_read('data/LAC_03to11_clean.gpkg') 


LAC_12to20 <- st_read('data/LAC_12to20_clean.gpkg') 


#### Prepare centroids ----

# only need to get one set of centroids for both datasets because 
# both datasets are using 2010 census geometries 

centroids_zctas <- st_centroid(LAC_03to11) %>%
  mutate(X_COORD = sf::st_coordinates(.)[,1],
         Y_COORD = sf::st_coordinates(.)[,2]) %>%
  st_drop_geometry()


##### Create neighbors matrix ----

# only need to create one neighbor matrix for both datasets 

nb_zctas <- spdep::poly2nb(LAC_03to11) # can be slow 

#### Spatial Clustering with FlexScan ----

#### * 2003 to 2011 ----

# * 1. Run FlexScan to find clusters ----

flex_03to11 <-  rflexscan(x=centroids_zctas$X_COORD, # x coordinates of centroids
                          y=centroids_zctas$Y_COORD, # y coordinates of centroids
                               observed = LAC_03to11$cases_18under, # total cases
                               expected = LAC_03to11$pop_18under, # total population
                               clustersize = 30, # max cluster size 
                               name=LAC_03to11$GISJOIN, # name of areas (i.e., ZCTAS)
                               nb = nb_zctas, # spatial neighbors matrix
                               stattype = "RESTRICTED", # Restricted scan statistic
                               scanmethod = "FLEXIBLE") # flexible scan statistic 


# * 2. View significant clusters ----
summary(flex_03to11) # three significant clusters 
 
choropleth(polygons=LAC_03to11,fls=flex_03to11, pval=.05)

# * 3. Add significant clusters to file 

flexlist_03to11 <- flex_03to11[[3]] # save list of clusters 

cluster1_03to11 <- flexlist_03to11[[1]][[11]] # save cluster 1
cluster2_03to11 <- flexlist_03to11[[2]][[11]] # save cluster 2
cluster3_03to11 <- flexlist_03to11[[3]][[11]] # save cluster 3 


# add the clusters to LAC_03to11 object 
LAC_03to11 <- LAC_03to11 %>%
  mutate(cluster = case_when(GISJOIN %in% cluster1_03to11 ~ "1",
                             GISJOIN %in% cluster2_03to11 ~ "2",
                             GISJOIN %in% cluster3_03to11 ~ "3"),
         cluster = ifelse (cluster %in% c('1','2','3'),
                           cluster,"0"),
         across(c(cluster),as.numeric))

# * 4. OPTIONAL save files for mapping ---- 

#st_write(LAC_03to11_zctas,
#         dsn='output/files for GIS mapping/flexscan clusters/LAC_03to11_flxclstr_zctas.gpkg',
#         driver='gpkg',
#         append=FALSE)


#### * 2012 to 2020 ----

# * 1. Run FlexScan to find clusters ----

flex_12to20 <-  rflexscan(x=centroids_zctas$X_COORD, # x coordinates of centroids
                          y=centroids_zctas$Y_COORD, # y coordinates of centroids
                          observed = LAC_12to20$cases_18under, # total cases
                          expected = LAC_12to20$pop_18under, # total population
                          clustersize = 30, # max cluster size 
                          name=LAC_12to20$GISJOIN, # name of areas (i.e., ZCTAS)
                          nb = nb_zctas, # spatial neighbors matrix
                          stattype = "RESTRICTED", # Restricted scan statistic
                          scanmethod = "FLEXIBLE") # flexible scan statistic 


# * 2. View significant clusters ----
summary(flex_12to20) # three significant clusters 

choropleth(polygons=LAC_12to20,fls=flex_12to20, pval=.05)

# * 3. Add significant clusters to file 

flexlist_12to20 <- flex_12to20[[3]] # save list of clusters 

cluster1_12to20 <- flexlist_12to20[[1]][[11]] # save cluster 1
cluster2_12to20 <- flexlist_12to20[[2]][[11]] # save cluster 2
cluster3_12to20 <- flexlist_12to20[[3]][[11]] # save cluster 3 
cluster4_12to20 <- flexlist_12to20[[4]][[11]] # save cluster 3 


# add the clusters to LAC_12to20 object 
LAC_12to20 <- LAC_12to20 %>%
  mutate(cluster = case_when(GISJOIN %in% cluster1_12to20 ~ "1",
                             GISJOIN %in% cluster2_12to20 ~ "2",
                             GISJOIN %in% cluster3_12to20 ~ "3",
                             GISJOIN %in% cluster4_12to20 ~ "4"),
         cluster = ifelse (cluster %in% c('1','2','3', '4'),
                           cluster,"0"),
         across(c(cluster),as.numeric))

# * 4. OPTIONAL save files for mapping ---- 

#st_write(LAC_12to20_zctas,
#         dsn='output/files for GIS mapping/flexscan clusters/LAC_12to20_flxclstr_zctas.gpkg',
#         driver='gpkg',
#         append=FALSE)


