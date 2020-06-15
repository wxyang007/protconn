print("Script postproc_protconn_country.R started at:")
print(Sys.time())

args <- commandArgs()

root_folder <- args[9]
results_folder <- args[6]

setwd(root_folder) 

## We read the files from the connectivity analyses (the final correct names of these files need to be provided)
## These files need to be copied in the input folder specified above
table_with_trans <- paste(args[6],"/results_countries_delme.txt", sep = "")
table_without_trans <- paste(args[6],"/results_countries_EC_PC_without_trans.txt", sep = "")
table_ECA_min_max_with_trans <- paste(args[6],"/ECAminmax_countries_without_trans.txt", sep = "")
table_ECA_min_max_without_trans <- paste(args[6],"/ECAminmax_countries_without_trans.txt", sep = "")
table_for_BOUND <- paste(args[6],"/results_all_EC_PC_boundcorr.txt", sep = "")

## The following table should contain the total land area (in km2) of each country or territory (ISO3 code)
## The file now here given is the one resulting from calculating geodesic areas in ArcPro using the GAUL layer ("Country_areas_ArcPro_GAUL.txt")
table_country_area <- args[8]

## Output files
outfile_all_results <- paste(args[6],"/All_values_countries_final_",args[7],".txt", sep = "")
outfile_protconn_results <- paste(args[6],"/ProtConn_results_countries_final_",args[7],".txt", sep = "")

## we read the tables
data_within_only <- read.table(table_without_trans,header = TRUE)
data_within_and_outside <- read.table(table_with_trans,header = TRUE)
data_ECA_min_max_within_only <- read.table(table_ECA_min_max_without_trans,header=FALSE)
data_ECA_min_max_within_and_outside <- read.table(table_ECA_min_max_with_trans,header=FALSE)
## We give the same name (Prefix) to the first column containing the ISO3 code in all files
colnames(data_ECA_min_max_within_only)[1] <- c("Prefix")
colnames(data_ECA_min_max_within_and_outside)[1] <- c("Prefix")

## we remove the case ABNJ, if present, in all files (Areas Beyond National Jurisdiction, which are not terrestrial or located in the Antarctica; we exclude it from all calculations)
## we use "BNJ" instead of "ABNJ" because in some of the files "ABNJ" has been written as "BNJ" because only three characterers (as expected for ISO3) have been taken. On the other hand, this is not a problem because there is no other ISO3 code that can be confused with "BNJ"
if (length(which(grepl("BNJ", data_within_only$Prefix)))>0) 
{data_within_only <- data_within_only[-c(which(grepl("BNJ", data_within_only$Prefix))), ]}

if (length(which(grepl("BNJ", data_within_and_outside$Prefix)))>0) 
{data_within_and_outside <- data_within_and_outside[-c(which(grepl("BNJ", data_within_and_outside$Prefix))), ]}

if (length(which(grepl("BNJ", data_ECA_min_max_within_only$Prefix)))>0) 
{data_ECA_min_max_within_only <- data_ECA_min_max_within_only[-c(which(grepl("BNJ", data_ECA_min_max_within_only$Prefix))), ]}

if (length(which(grepl("BNJ", data_ECA_min_max_within_and_outside$Prefix)))>0) 
{data_ECA_min_max_within_and_outside <- data_ECA_min_max_within_and_outside[-c(which(grepl("BNJ", data_ECA_min_max_within_and_outside$Prefix))), ]}

## Now we modify the Prefix of the file without trans to remove the ending "_WITHOUT_TRANS" so that it is set as in the rest of the files (ISO3 code + year, e.g. "ITA_2019", which is 8 characters in total)
data_within_only$Prefix <- substr(data_within_only$Prefix,1,8)

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

## This is a specific correction for New Caledonia (NCL) that is needed in some cases (depending on the WDPA and GAUL version used), and that if not needed does not harm 
##(does not have any negative effect)
## We make in NCL the value "within and out" (trans included) the same as "within" (trans excluded). This is because, the difference in these two values in NCL, if there is some, 
## is not because there is any actual transboundary terrestrial PA. It is because the terrestrial PAs in New Caledonia are assigned to NCL but the marine PAs around, 
## which may interesect and be clipped when using the GAUL land layer, are assigned to France (FRA), given the false impression of some FRA PAs giving a transboundary 
## connection to the NCL PAs. NCL is an island system that has no transboundary terrestrial corridors. 
data_within_and_outside$EC.PC.[which(substr(data_within_and_outside$Prefix,1,3) == "NCL")]<-data_within_only$EC.PC.[which(substr(data_within_only$Prefix,1,3) == "NCL")]

## We put together in a single dataframe the results for both trans included (within and outside) and trans excluded (within only)
merge_all_data <- merge(data_within_only, data_within_and_outside, by=c("Prefix","Distance","Probability"))
## Now we make an additional check: there should be no value of within+out (transboundary included) lower than the value for within only (transboundary excluded)
## therefore, the following number of rows should be zero
nrow(subset(merge_all_data,merge_all_data$EC.PC..x > merge_all_data$EC.PC..y ))

## now we change to more readable column names
colnames(merge_all_data)[4] <- c("ECA_without_trans")
colnames(merge_all_data)[5] <- c("ECA_with_trans")
## Modify the Prefix column so that only the three characters of the ISO3 remain
merge_all_data$Prefix <- substr(merge_all_data$Prefix,1,3)
## We exclude Antarctica (ATA) from all calculations
merge_all_data <- subset(merge_all_data ,merge_all_data$Prefix!="ATA")
## We add in the "merge_all_data" dataframe the values of ECAminmax (these ECAminmax values are the same no matter if the trans has been considered (within and out) or not (within only); so we can take the ECAminmax file and values from any of the two. Here we take those from "within only").
data_ECA_min_max_within_only$Prefix <- substr(data_ECA_min_max_within_only$Prefix,1,3)
merge_all_data <- merge(merge_all_data, data_ECA_min_max_within_only, by=c("Prefix"))
colnames(merge_all_data)[6] <- c("ECA_min")
colnames(merge_all_data)[7] <- c("ECA_max")

## Now we incorporate the results for the Bound correction 
data_for_BOUND <- read.table(table_for_BOUND,header = TRUE)
data_for_BOUND$Distance <- NULL
data_for_BOUND$Probability  <- NULL
colnames(data_for_BOUND)[2] <- c("ECPC_for_BOUND")

## we shorten the Prefix field to include only the three characters of the ISO3 code and remove the "_2019" part, so that Prefix is here as in the rest of the files
data_for_BOUND$Prefix <- substr(data_for_BOUND$Prefix,1,3)

## now add (merge) the bound dataframe with the rest of the numbers in the "merge_all_data" dataframe, merging them by Prefix
## if there are some ISO3 codes in the land polygons (GAUL layer) that have no PAs, they will not be present in the "merge_all_data" dataframe before this step, and they will not be conserved after this merge. We don't need them / we don't want them; we are only interested in the ISO3 codes that have some PAs in the PA layer used
merge_all_data <- merge(merge_all_data,data_for_BOUND,by=c("Prefix"))

## in case there is any NA values in the "merge_all_data" dataframe, this would correspond to 0 values
merge_all_data[is.na(merge_all_data)] <- 0

## now I will first read, and then later add to the "merge_all_data" dataframe, the values of the area in km2 of each country/ISo3
data_country_area<- read.csv(table_country_area,header=TRUE,sep=",")
colnames(data_country_area)[1] <- c("Prefix")
colnames(data_country_area)[2] <- c("areakm2")
merge_all_data <- merge(merge_all_data, data_country_area, by=c("Prefix"), all=TRUE)

## We exclude the Antarctica (ATA)
merge_all_data <- subset(merge_all_data ,merge_all_data$Prefix!="ATA")

## ALA (small Finnish islands close to Sweden) is an ISO3 code that appears in the WDPA of 2018 and later; in earlier WDPA 
## versions the PAs in these islands were coded as FIN 
## (Finland). We make the area adjustment considering the total land area of 1580 km2 for ALA according to Protected Planet
## Updated on 20200429 (back to Santigao's value=1580)
merge_all_data$areakm2[merge_all_data$Prefix == "ALA"] <- 1580
merge_all_data$areakm2[merge_all_data$Prefix == "FIN"] <- merge_all_data$areakm2[merge_all_data$Prefix == "FIN"] -1580

## Palestine (PSE) is an ISO3 code that appears in the WDPA of 2018 and later; in the ProtConn processing for previous dates Palestine was considered as a disputed territory 
## and not separately considered with an individual ISO3 code. We make the area adjustment considering the land area of Palestine according to Proteted Planet, 
## and we detract this area from the total area of the disputed territories (the disputed territories are here assumed to be coded as "DSP")
## Updated on 20200429 : this correction is no more needed since PSE is included both in gaul and WDPA
## merge_all_data$areakm2[merge_all_data$Prefix == "PSE"] <- 515
## merge_all_data$areakm2[merge_all_data$Prefix == "DSP"] <- merge_all_data$areakm2[merge_all_data$Prefix == "DSP"] -515

## BES is an ISO3 code that appears in the WDPA of 2012 and later; before, it was part of ANT. We assign to BES the total land area of the islands (as mapped in GAUL) 
## that would correspond to BES, which is 312 km2, and we detract this area from the ANT area
## Updated on 20200429 : this correction is no more needed since BES is included both in gaul and WDPA
## merge_all_data$areakm2[merge_all_data$Prefix == "BES"] <- 2839
## merge_all_data$areakm2[merge_all_data$Prefix == "ANT"] <- merge_all_data$areakm2[merge_all_data$Prefix == "ANT"] - 2839

## CUW is an ISO3 code that appears in the WDPA of 2012 and later; before, it was part of ANT. We assign to CUW the total land area of the islands (as mapped in GAUL) 
## that would correspond to CUW, which is 433 km2, and we detract this area from the ANT area
## Updated on 20200429 : this correction is no more needed since CUW is included both in gaul and WDPA
## merge_all_data$areakm2[merge_all_data$Prefix == "CUW"] <- 433
## merge_all_data$areakm2[merge_all_data$Prefix == "ANT"] <- merge_all_data$areakm2[merge_all_data$Prefix == "ANT"] - 433

## MAF aparece solo en 2012 en la flat layer final, pero en 2018 también esta, solo que con PAs menores de 1 km2 que no quedan en la final layer used for ProtConn.
## Land area total de 40 km2 (muy pequeña) segun tamaño de la isla(s) en GAUL, que quitamos de GLP.
## Updated on 20200429 : this correction is no more needed since MAF is included both in gaul and WDPA
## merge_all_data$areakm2[merge_all_data$Prefix == "MAF"] <- 110
## merge_all_data$areakm2[merge_all_data$Prefix == "GLP"] <- merge_all_data$areakm2[merge_all_data$Prefix == "GLP"] - 110

## we remove columns "dist" and "prob"; we don't need them since we already know which are the values, they are the same in all cases (10000 meters for the distance and 0.5 for the probability)
merge_all_data$Distance <- NULL
merge_all_data$Probability <- NULL
## everything that may remain as NA corresponds to 0
merge_all_data[is.na(merge_all_data)] <- 0

## the dataframe "merge_all_data" includes the area in the disputed territories (coded for instance as "DSP") because, even if this does not correspond to a well-defined individual country, it must be considered as a land area for the computation of the global averages/values of ProtConn

## For consistency in all the values, areas and layers used, we make sure than none of the ECA-related variables can be larger than the actual land area of the country (ISO3 code), forcing the values to meet this condition (the land area of the country has to be at least not smaller than any of the ECA-related variables for the country)
## This may be necessary only in very special cases and circumstances like UMI, but we apply it systematically for all countries (ISO3 codes) for consistency
merge_all_data$areakm2 <- pmax(merge_all_data$ECA_without_trans, merge_all_data$ECA_with_trans, merge_all_data$ECA_min, merge_all_data$ECA_max, merge_all_data$ECPC_for_BOUND, merge_all_data$areakm2)

## we calculate ProtConn (without the bound correction yet) without and with the transnational component
merge_all_data$ProtConn_without_trans <- 100*merge_all_data$ECA_without_trans/merge_all_data$areakm2
merge_all_data$ProtConn_with_trans <- 100*merge_all_data$ECA_with_trans/merge_all_data$areakm2

## we calculate the PA coverage (based on the PA layer used for ProtConn, which has the 1km2 area threshold)
merge_all_data$coverage <- 100*merge_all_data$ECA_max/merge_all_data$areakm2

## We need to make a "manual" correcto the BES values for the Bound correction. This is because BES is not present in the GAUL layer where it is just part of ANT (hence BES is not considered for the general procedure for the Bound correction) but does have natural isolation of PAs that needs to be accounted for (extracted) through the Bound correction (does not have isolation by foreign lands but has natural isolation by the sea)
## We have externally calculated, especifically for BES, the correct value that would correspond for this ISO3, which is the following:
merge_all_data$ECPC_for_BOUND[merge_all_data$Prefix == "BES"] <- 58.0202100

# Now we proceed to calculate ProtConn_Bound, i.e. ProtConn with the Bound correction already incorporated (The Bound correction is all applied to the ProtConn values with the 
# transnational part included)
merge_all_data$Sea_Outland <- merge_all_data$coverage - 100*(merge_all_data$ECPC_for_BOUND/merge_all_data$areakm2)
## We make sure (we force) that the Sea_Outland value is never lower than 0 (this in reality happens for one iSO3 code and for a very tiny rounding value of -0.0000005, but if better to do it consistently for all cases as folows)
merge_all_data$Sea_Outland <- pmax(merge_all_data$Sea_Outland ,0)
## For the case of Curaçao (CUW), the SeaOutland adjustment should be equal to 0, because all PA land is in a single island. We do this "manual" correction because this is not done "automatically"/correclty in the general procedure because CUW does not appear in the GAUL layer but is assigned to a differnet ISO3 code).
merge_all_data$Sea_Outland[merge_all_data$Prefix == "CUW"] <- 0
## For the same/simiar reason, the SeaOutland adjustment for PSE should be equal to 0
merge_all_data$Sea_Outland[merge_all_data$Prefix == "PSE"] <- 0
## For the same/simiar reason, the SeaOutland adjustment for ALA should be equal to 0
merge_all_data$Sea_Outland[merge_all_data$Prefix == "ALA"] <- 0
## And now we finally calculate ProtConn_Bound for all countries
merge_all_data$ProtConn_BOUND <- merge_all_data$ProtConn_with_trans + merge_all_data$Sea_Outland

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
colnames(All_results_final)[1] <- c("ISO3")
write.table(All_results_final , file = outfile_all_results, row.names = FALSE, col.names = TRUE, sep = "\t")

## and now we save the table with only the ISO3 code and the ProtConn_Bound value. This will normally the only table that we would need regarding ProtConn (e.g. the values to put in DOPA), which are the ProtConn values with the Bound correction already incorporated (ProtConn_Bound)
ProtConn_results_final <- data.frame(merge_all_data$Prefix,merge_all_data$ProtConn_BOUND)
colnames(ProtConn_results_final)[1] <- c("ISO3")
colnames(ProtConn_results_final)[2] <- c("ProtConn")
## we select only those cases with a value of ProtConn_Bound (now renamed simply to ProtConn) larger than 0
ProtConn_results_final <- ProtConn_results_final[ProtConn_results_final$ProtConn > 0,]
write.table(ProtConn_results_final , file = outfile_protconn_results, row.names = FALSE, col.names = TRUE, sep = "\t")


## END

