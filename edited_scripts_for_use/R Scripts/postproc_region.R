library(tidyverse)
library(dplyr)

print("Script postproc_protconn_country.R started at:")
print(Sys.time())

# args <- commandArgs()

root_folder <- 'C:\\Users\\ywx12\\Desktop\\PhD\\RA\\ProtectedLand\\ProtConn_CALC'
results_folder <- 'C:\\Users\\ywx12\\Desktop\\PhD\\RA\\ProtectedLand\\ProtConn_CALC\\results'

setwd(root_folder)

## We read the files from the connectivity analyses (the final correct names of these files need to be provided)
## These files need to be copied in the input folder specified above
table_with_trans <- paste(results_folder,"/results_countries_EC_PC_with_trans.txt", sep = "")
table_without_trans <- paste(results_folder,"/results_countries_EC_PC_without_trans.txt", sep = "")
table_ECA_min_max_with_trans <- paste(results_folder,"/ECAminmax_countries_with_trans.txt", sep = "")
table_ECA_min_max_without_trans <- paste(results_folder,"/ECAminmax_countries_without_trans.txt", sep = "")
# table_for_BOUND <- paste(args[6],"/results_all_EC_PC_boundcorr.txt", sep = "")
table_for_BOUND <- paste(results_folder, "/results_EC_PC_bound_corr.txt", sep = "")
table_for_BOUND_wr <- paste(results_folder, "/results_EC_PC_bound_corr_wr.txt", sep = "")
table_for_PA_nds <- paste(results_folder, '/near_tab_nds_test.csv', sep = "") # if generated from script, will be a txt file
table_for_PA_ds <- paste(results_folder, '/near_tab_ds_test.csv', sep = "")


## The following table should contain the total land area (in km2) of each country or territory (ISO3 code)
## The file now here given is the one resulting from calculating geodesic areas in ArcPro using the GAUL layer ("Country_areas_ArcPro_GAUL.txt")
table_country_area <- 'C:\\Users\\ywx12\\Desktop\\PhD\\RA\\ProtectedLand\\tmp_area.txt'

## Output files
outfile_all_results <- paste(results_folder,"/All_values_test_final_",'test',".txt", sep = "")
outfile_protconn_results <- paste(results_folder,"/ProtConn_results_test_final_",'test',".txt", sep = "")

## we read the tables
data_within_only <- read.table(table_without_trans,header = TRUE)
data_within_and_outside <- read.table(table_with_trans,header = TRUE)
data_ECA_min_max_within_only <- read.table(table_ECA_min_max_without_trans,header=FALSE)
data_ECA_min_max_within_and_outside <- read.table(table_ECA_min_max_with_trans,header=FALSE)

data_PA_nds <- read.csv(table_for_PA_nds, header = TRUE)
data_PA_nds$AREA_nds <- data_PA_nds$SHAPE_Area/1000000
data_PA_region_nds <- data_PA_nds %>%
  group_by(GEOID) %>%
  summarise(AREA_geo_nds = sum(AREA_nds), AREA_sq_geo_nds = sum(AREA_nds*AREA_nds))
data_PA_region_nds$AREA_geo_nds <- as.numeric(data_PA_region_nds$AREA_geo_nds)
data_PA_region_nds$AREA_sq_geo_nds <- as.numeric(data_PA_region_nds$AREA_sq_geo_nds)
data_PA_region_nds$AREA_sqrt_geo_nds <- sqrt(data_PA_region_nds$AREA_sq_geo_nds)
data_PA_region_nds$AREA_sq_geo_nds <- NULL
colnames(data_PA_region_nds)[1] <- c("Prefix")

data_PA_ds <- read_csv(table_for_PA_ds) %>% select(GEOID, SHAPE_Area)
data_PA_ds$AREA_ds <- data_PA_ds$SHAPE_Area/1000000
colnames(data_PA_ds)[1] <- c("Prefix")
data_PA_ds$SHAPE_Area <- NULL
data_PA_ds$Prefix <- as.numeric(data_PA_ds$Prefix)
data_PA_region_ds <- data_PA_ds %>%
  group_by(Prefix) %>%
  summarise(AREA_geo_ds = sum(AREA_ds), AREA_sq_geo_ds = sum(AREA_ds*AREA_ds))
data_PA_region_ds$AREA_sqrt_geo_ds <- sqrt(data_PA_region_ds$AREA_sq_geo_ds)
data_PA_region_ds$AREA_sq_geo_ds <- NULL
## We give the same name (Prefix) to the first column containing the ISO3 code in all files
colnames(data_ECA_min_max_within_only)[1] <- c("Prefix")
colnames(data_ECA_min_max_within_and_outside)[1] <- c("Prefix")


## Now we modify the Prefix of the file without trans to remove the ending "_WITHOUT_TRANS" so that it is set as in the rest of the files (ISO3 code + year, e.g. "ITA_2019", which is 8 characters in total)
# data_within_only$Prefix <- substr(data_within_only$Prefix,1,8)
data_within_only$Prefix <- gsub('_test_WITHOUT_TRANS', '', data_within_only$Prefix)
data_within_and_outside$Prefix <- gsub('_test', '', data_within_and_outside$Prefix)
data_ECA_min_max_within_and_outside$Prefix <- gsub('_tes', '', data_ECA_min_max_within_and_outside$Prefix)
data_ECA_min_max_within_and_outside$Prefix <- gsub('_te', '', data_ECA_min_max_within_and_outside$Prefix)
data_ECA_min_max_within_only$Prefix <- gsub('_tes', '', data_ECA_min_max_within_only$Prefix)
data_ECA_min_max_within_only$Prefix <- gsub('_te', '', data_ECA_min_max_within_only$Prefix)

## All should be correct and hence the files with and without trans should have the same number of cases
nrow(data_ECA_min_max_within_only)
nrow(data_ECA_min_max_within_and_outside)
## The following difference should be equal to zero (same number of cases in the files with and without trans)
nrow(data_ECA_min_max_within_only)-nrow(data_ECA_min_max_within_and_outside)
## In addition, the values of ECAminmax should be the same in both files (with and without trans); this is just to check that all is correct
merge_data_ECA_min_max <- merge(data_ECA_min_max_within_only, data_ECA_min_max_within_and_outside, by=c("Prefix"))
merge_data_ECA_min_max$dif_min <- merge_data_ECA_min_max$V2.x - merge_data_ECA_min_max$V2.y
merge_data_ECA_min_max$dif_max <- merge_data_ECA_min_max$V3.x - merge_data_ECA_min_max$V3.y
## all these four sums should be equal to 0 (each of them) if all is correct
sum(merge_data_ECA_min_max$dif_min)
sum(merge_data_ECA_min_max$dif_max)
sum(merge_data_ECA_min_max$dif_min*merge_data_ECA_min_max$dif_min)
sum(merge_data_ECA_min_max$dif_max*merge_data_ECA_min_max$dif_max)

## to avoid problems with small rounding (errors) of numbers, we make "ECA only within" (and also "within and out") not smaller than ECAmin (these values come calculated with
## different number of decimal digits in the tables from previous calculations, and we need to avoid small issues on this different numerical resolution or number rounding)
## firts, some preparatory steps
merge_data_within_only_and_ECA_min <- merge(data_within_only, data_ECA_min_max_within_only, by=c("Prefix"))
merge_data_within_only_and_ECA_min <- merge_data_within_only_and_ECA_min[order(merge_data_within_only_and_ECA_min$Distance,merge_data_within_only_and_ECA_min$Prefix),]
merge_data_within_and_outside_and_ECA_min <- merge(data_within_and_outside, data_ECA_min_max_within_and_outside, by=c("Prefix"))
merge_data_within_and_outside_and_ECA_min<- merge_data_within_and_outside_and_ECA_min[order(merge_data_within_and_outside_and_ECA_min$Distance,merge_data_within_and_outside_and_ECA_min$Prefix),]
## second, to avoid the problem with rounding of numbers, here is where we make "ECA only within" (and also "within and out") not smaller than ECAmin
data_within_only$EC.PC. <- pmax(data_within_only$EC.PC.,merge_data_within_only_and_ECA_min$V2)
data_within_and_outside$EC.PC. <- pmax(data_within_and_outside$EC.PC.,merge_data_within_and_outside_and_ECA_min$V2)


## We put together in a single dataframe the results for both trans included (within and outside) and trans excluded (within only)
merge_all_data <- merge(data_within_only, data_within_and_outside, by=c("Prefix","Distance","Probability"))
## Now we make an additional check: there should be no value of within+out (transboundary included) lower than the value for within only (transboundary excluded)
## therefore, the following number of rows should be zero
nrow(subset(merge_all_data,merge_all_data$EC.PC..x > merge_all_data$EC.PC..y ))


## now we change to more readable column names
colnames(merge_all_data)[4] <- c("ECA_without_trans")
colnames(merge_all_data)[5] <- c("ECA_with_trans")
## Modify the Prefix column so that only the three characters of the ISO3 remain
# merge_all_data$Prefix <- substr(merge_all_data$Prefix,1,5)
## We add in the "merge_all_data" dataframe the values of ECAminmax (these ECAminmax values are the same no matter if the trans has been considered (within and out) or not (within only); so we can take the ECAminmax file and values from any of the two. Here we take those from "within only").
# data_ECA_min_max_within_only$Prefix <- substr(data_ECA_min_max_within_only$Prefix,1,5)
merge_all_data <- merge(merge_all_data, data_ECA_min_max_within_only, by=c("Prefix"))
colnames(merge_all_data)[6] <- c("ECA_min")
colnames(merge_all_data)[7] <- c("ECA_max")



## Now we incorporate the results for the Bound correction
data_for_BOUND <- read.table(table_for_BOUND,header = TRUE)
data_for_BOUND$Distance <- NULL
data_for_BOUND$Probability  <- NULL
colnames(data_for_BOUND)[2] <- c("ECPC_for_BOUND")

## we shorten the Prefix field to include only the three characters of the ISO3 code and remove the "_2019" part, so that Prefix is here as in the rest of the files
# data_for_BOUND$Prefix <- substr(data_for_BOUND$Prefix,1,3)
data_for_BOUND$Prefix <- gsub("_test", "", data_for_BOUND$Prefix)


data_for_BOUND_wr <- read.table(table_for_BOUND_wr, header = TRUE)
data_for_BOUND_wr$Distance <- NULL
data_for_BOUND_wr$Probability <- NULL
colnames(data_for_BOUND_wr)[2] <- c("ECPC_for_BOUND_wr")
data_for_BOUND_wr$Prefix <- gsub("_test_wr", "", data_for_BOUND_wr$Prefix)

## now add (merge) the bound dataframe with the rest of the numbers in the "merge_all_data" dataframe, merging them by Prefix
## if there are some ISO3 codes in the land polygons (GAUL layer) that have no PAs, they will not be present in the "merge_all_data" dataframe before this step, and they will not be conserved after this merge. We don't need them / we don't want them; we are only interested in the ISO3 codes that have some PAs in the PA layer used
merge_all_data <- merge(merge_all_data, data_for_BOUND, by = c("Prefix"))
merge_all_data <- merge(merge_all_data, data_for_BOUND_wr, by = c("Prefix"))

## in case there is any NA values in the "merge_all_data" dataframe, this would correspond to 0 values
merge_all_data[is.na(merge_all_data)] <- 0

## now I will first read, and then later add to the "merge_all_data" dataframe, the values of the area in km2 of each country/ISo3
data_country_area<- read.csv(table_country_area, header = TRUE, sep = ",")
data_country_area <- data_country_area %>% select(GEOID, Shape_Area)
data_country_area$Shape_Area <- data_country_area$Shape_Area/1000000
colnames(data_country_area)[1] <- c("Prefix")
colnames(data_country_area)[2] <- c("areakm2")
merge_all_data <- merge(merge_all_data, data_country_area, by = c("Prefix"), all = TRUE)


merge_all_data <- merge(merge_all_data, data_PA_region_nds, by = c("Prefix"), all = TRUE)

merge_all_data<- merge(merge_all_data, data_PA_region_ds, by = c("Prefix"), all = TRUE)

## we remove columns "dist" and "prob"; we don't need them since we already know which are the values, they are the same in all cases (10000 meters for the distance and 0.5 for the probability)
merge_all_data$Distance <- NULL
merge_all_data$Probability <- NULL
## everything that may remain as NA corresponds to 0
merge_all_data[is.na(merge_all_data)] <- 0

## the dataframe "merge_all_data" includes the area in the disputed territories (coded for instance as "DSP") because, even if this does not correspond to a well-defined individual country, it must be considered as a land area for the computation of the global averages/values of ProtConn

## For consistency in all the values, areas and layers used, we make sure that none of the ECA-related variables can be larger than the actual land area of the country (ISO3 code), forcing the values to meet this condition (the land area of the country has to be at least not smaller than any of the ECA-related variables for the country)
## This may be necessary only in very special cases and circumstances like UMI, but we apply it systematically for all countries (ISO3 codes) for consistency
merge_all_data$areakm2 <- pmax(merge_all_data$ECA_without_trans, merge_all_data$ECA_with_trans, merge_all_data$ECA_min, merge_all_data$ECA_max, merge_all_data$ECPC_for_BOUND, merge_all_data$areakm2)

## we calculate ProtConn (without the bound correction yet) without and with the transnational component
# ProtConn - ProtConn[Trans]
merge_all_data$ProtConn_without_trans <- 100*(merge_all_data$ECA_without_trans/merge_all_data$areakm2)
# ProtConn
merge_all_data$ProtConn_with_trans <- 100*(merge_all_data$ECA_with_trans/merge_all_data$areakm2)

# Prot
## we calculate the PA coverage (based on the PA layer used for ProtConn, which has the 1km2 area threshold)
merge_all_data$coverage <- 100*(merge_all_data$ECA_max/merge_all_data$areakm2)


# ProtConn[Prot]
merge_all_data$ProtConn_Prot <- 100*100*(merge_all_data$AREA_sqrt_geo_ds/(merge_all_data$areakm2*merge_all_data$ProtConn_with_trans))


# ProtConn[Within]
merge_all_data$ProtConn_Within <- 100*100*(merge_all_data$AREA_sqrt_geo_nds*sqrt(merge_all_data$AREA_geo_ds)/(merge_all_data$areakm2*merge_all_data$ProtConn_with_trans*sqrt(merge_all_data$AREA_geo_nds)))


# ProtConn[Contig] = ProtConn[Prot] - ProtConn[Within]
merge_all_data$ProtConn_Contig <- merge_all_data$ProtConn_Prot - merge_all_data$ProtConn_Within


# ProtConn[Trans] = ProtConn_with_trans - ProtConn_without_trans
merge_all_data$ProtConn_Trans <- merge_all_data$ProtConn_with_trans - merge_all_data$ProtConn_without_trans

#ProtConn[Unprot] = ProtConn - ProtConn[Prot] - ProtConn[Trans]
merge_all_data$ProtConn_Unprot <- merge_all_data$ProtConn_with_trans - merge_all_data$ProtConn_Prot - merge_all_data$ProtConn_Trans

# ProtConn[Bound]
# Now we proceed to calculate ProtConn_Bound, i.e. ProtConn with the Bound correction already incorporated (The Bound correction is all applied to the ProtConn values with the
# transnational part included)
# ProtUnconn[Sea & Outland]
merge_all_data$Sea_Outland <- merge_all_data$coverage - 100*(merge_all_data$ECPC_for_BOUND/merge_all_data$areakm2)
## We make sure (we force) that the Sea_Outland value is never lower than 0 (this in reality happens for one iSO3 code and for a very tiny rounding value of -0.0000005, but if better to do it consistently for all cases as folows)
merge_all_data$Sea_Outland <- pmax(merge_all_data$Sea_Outland, 0)
## And now we finally calculate ProtConn_Bound for all countries
merge_all_data$ProtConn_BOUND <- merge_all_data$ProtConn_with_trans + merge_all_data$Sea_Outland

## ProtUnconn_design = Prot - ProtConn_bound
merge_all_data$ProtUnconn_Design <- merge_all_data$coverage - merge_all_data$ProtConn_BOUND

## ProtUnconn[Sea] = Prot - 100*ECPEC_boundcorrwr/area
merge_all_data$ProtUnconn_Sea <- merge_all_data$coverage - 100*(merge_all_data$ECPC_for_BOUND_wr/merge_all_data$areakm2)

## ProtUnconn[Outland]
merge_all_data$ProtUnconn_Outland <- merge_all_data$Sea_Outland - merge_all_data$ProtUnconn_Sea

merge_all_data$test <- merge_all_data$ECPC_for_BOUND_wr - merge_all_data$ECPC_for_BOUND

## All the NAs (if any) are 0
merge_all_data[is.na(merge_all_data)] <- 0

## We calculate the global PA coverage
weighted.mean(merge_all_data$coverage,merge_all_data$areakm2)

## We calculate the global value of ProtConn without the Bound correction, with and without the transnational component
weighted.mean(merge_all_data$ProtConn_with_trans,merge_all_data$areakm2)
weighted.mean(merge_all_data$ProtConn_without_trans,merge_all_data$areakm2)
## The percentage of the transnational component globally is (calculated with respect to the total ProtConn value)
100*(weighted.mean(merge_all_data$ProtConn_with_trans,merge_all_data$areakm2) - weighted.mean(merge_all_data$ProtConn_without_trans,merge_all_data$areakm2) )/weighted.mean(merge_all_data$ProtConn_with_trans,merge_all_data$areakm2)

## We calculate the global value of ProtConn_BOUND: this will be in general the most interesting value and the one to use "by default" in reporting the indicator value at the country level
weighted.mean(merge_all_data$ProtConn_BOUND,merge_all_data$areakm2)

## we save the table with all the values
All_results_final <- merge_all_data
## we select only those cases with a value of ProtConn_Bound larger than 0
All_results_final <- All_results_final[All_results_final$ProtConn_BOUND > 0,]
colnames(All_results_final)[1] <- c("GEOID")
write.table(All_results_final , file = outfile_all_results, row.names = FALSE, col.names = TRUE, sep = "\t")

## and now we save the table with only the ISO3 code and the ProtConn_Bound value. This will normally the only table that we would need regarding ProtConn (e.g. the values to put in DOPA), which are the ProtConn values with the Bound correction already incorporated (ProtConn_Bound)
ProtConn_results_final <- data.frame(merge_all_data$Prefix, merge_all_data$ProtConn_BOUND)
colnames(ProtConn_results_final)[1] <- c("GEOID")
colnames(ProtConn_results_final)[2] <- c("ProtConn")
## we select only those cases with a value of ProtConn_Bound (now renamed simply to ProtConn) larger than 0
ProtConn_results_final <- ProtConn_results_final[ProtConn_results_final$ProtConn > 0,]
write.table(ProtConn_results_final , file = outfile_protconn_results, row.names = FALSE, col.names = TRUE, sep = "\t")


## END

merge_all_data$test <- merge_all_data$coverage - merge_all_data$ProtConn_with_trans - merge_all_data$ProtUnconn_Design - merge_all_data$Sea_Outland
