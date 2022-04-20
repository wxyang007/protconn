print("Script postproc_protconn_country.R started at:")
print(Sys.time())

args <- commandArgs()

root_folder <- args[9]
results_folder <- args[6]

setwd(root_folder) 

## the following are the three files that need to be provided as an input (with their appropriate names to be updated below if necessary)
## We are only interested in the ProtConn value with the trans fraction included (it is more than enough for the ecoregion level results)
table_ECA <- paste(args[6],"/results_ecoregion_with_trans.txt", sep = "")
table_ECA_min_max <- paste(args[6],"/ECAminmax_ecoregions_with_trans.txt", sep = "")
## this gives the land area of each terrestrial ecoregion (calculated in the GIS). Important: all the "rock and ice" from Antarctica is excluded, 
## but not the "rock and ice" outsidea Antarctica such as (mainly) the one in Greenland
table_Area <- args[8]

## Output files
outfile_all_results <- paste(args[6],"/All_values_ecoregions_final_",args[7],".txt", sep = "")
outfile_protconn_results <- paste(args[6],"/ProtConn_results_ecoregions_final_",args[7],".txt", sep = "")

## We read the tables
ECA <- read.table(table_ECA,header = TRUE)
ECA_min_max <- read.table(table_ECA_min_max,header=FALSE)
Area <- read.csv(table_Area,header=TRUE,sep=",")
## The area in km2
Area$areakm2 <- Area$area_geo
## And we remove all other columns that are not needed
## Area$OBJECTID <- NULL
## Area$FREQUENCY <- NULL
Area$area_geo <- NULL


## We call "Prefix" to all columns that, in the different files, contain the ECOID_int value for the ecoregions. And we make other adjustments in the column names
colnames(Area)[1] <- c("Prefix")
colnames(ECA_min_max)[1] <- c("Prefix")
colnames(ECA_min_max)[2] <- c("ECAmin")
colnames(ECA_min_max)[3] <- c("ECAmax")
colnames(ECA)[4] <- c("ECA")
ECA$Distance <- NULL
ECA$Probability <- NULL

## We retain only the first five characters of the following columns, so that they only contain the ECOID values in the same way for all the files
ECA$Prefix <- substr(ECA$Prefix,1,5)
ECA_min_max$Prefix <- substr(ECA_min_max$Prefix,1,5)

## We merge all dataframes in a single one called "Ecoregion values". We start with the dataframe "Area", which has all the ecoregions listed (including those ecoregions with no PA of at least 1 km2)
Ecoregion_values <- merge(ECA, ECA_min_max, by=c("Prefix"), all = TRUE)
Ecoregion_values <- merge(Ecoregion_values, Area, by=c("Prefix"), all = TRUE)
## We replace the NA by 0, given that these are ecoregions that do not have any PA (larger than or equal to 1 km2)
Ecoregion_values[is.na(Ecoregion_values)] <- 0

## We remove the ecoregion code -9998 if it exists, and we also remove the four Antarctic ecoregions
Ecoregion_values <- Ecoregion_values[!grepl("-9998", Ecoregion_values$Prefix),]
Ecoregion_values <- Ecoregion_values[!grepl("21101", Ecoregion_values$Prefix),]
Ecoregion_values <- Ecoregion_values[!grepl("21102", Ecoregion_values$Prefix),]
Ecoregion_values <- Ecoregion_values[!grepl("21103", Ecoregion_values$Prefix),]
Ecoregion_values <- Ecoregion_values[!grepl("21104", Ecoregion_values$Prefix),]

## To avoid problems with small round numbering issues, we make sure (we force) that ECA will never be smaller than ECAmin (these numbers may come with different number of decimal digits in the different tables, which may give very small but undesirable differences and problems, which are solved/avoided in this way)
Ecoregion_values$ECA <- pmax(Ecoregion_values$ECA,Ecoregion_values$ECAmin)

## We calculate PA coverage (as given by the used PA layer)
Ecoregion_values$PAcoverage <- 100 * Ecoregion_values$ECAmax / Ecoregion_values$areakm2

## And we calculate ProtConn
Ecoregion_values$ProtConn <- 100 * Ecoregion_values$ECA / Ecoregion_values$areakm2

## We calculate the global averages of PA coverage and ProtConn
weighted.mean(Ecoregion_values$PAcoverage,Ecoregion_values$areakm2)
weighted.mean(Ecoregion_values$ProtConn,Ecoregion_values$areakm2)

## we save the table with all the values
colnames(Ecoregion_values)[1] <- c("ECOID")
write.table(Ecoregion_values, file = outfile_all_results, row.names = FALSE, col.names = TRUE, sep = "\t")

## and now we save the table with only the ECOID and the ProtConn value. This will normally the only table that we would need regarding the ecoregion-level ProtConn (e.g. the values to put in DOPA).
ProtConn_results_ecoregion_final <- data.frame(Ecoregion_values$ECOID,Ecoregion_values$ProtConn)
colnames(ProtConn_results_ecoregion_final)[1] <- c("ECOID")
colnames(ProtConn_results_ecoregion_final)[2] <- c("ProtConn")
write.table(ProtConn_results_ecoregion_final , file = outfile_protconn_results, row.names = FALSE, col.names = TRUE, sep = "\t")

##END
 