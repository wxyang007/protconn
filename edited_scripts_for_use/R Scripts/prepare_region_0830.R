## This script specifically prepares the node and distance files for PAs at state level

## This script performs the connectivity analyses required to obtain the country-level ProtConn.
## It takes as an input: the files obtained in the GIS processing (described in a different document), manipulates and prepares the files as needed for Conefor, and calls the executable file of the Conefor command line.
## There is a different R script for the post-processing of the Conefor results to obtain the values of ProtConn and its fractions for each country.

print("Script prepare_conefor_files_country.R started at:")
print(Sys.time())

# args <- commandArgs()

root_folder <- 'C:\\Users\\ywx12\\Desktop\\PhD\\RA\\ProtectedLand\\ProtConn_CALC\\data\\REGIN_PA\\STATES_1'

# Input
## input is .csv, so need to convert tab files to csv ## done
## input1: near table
raw_distance_file <- 'C:\\Users\\ywx12\\Desktop\\PhD\\RA\\ProtectedLand\\ProtConn_CALC\\data\\NearTable\\Near_tab_PA_230km_AK_July2021.csv'
## input2: node table
raw_nodes_file <- 'C:\\Users\\ywx12\\Desktop\\PhD\\RA\\ProtectedLand\\ProtConn_CALC\\data\\REGION_PA\\STATES_1\\PA_230km_AK_July2021.csv'



# Intermediate Output
node_dist_files_230_km_folder <- 'C:\\Users\\ywx12\\Desktop\\PhD\\RA\\ProtectedLand\\ProtConn_CALC\\data\\REGION_PA\\tmp1'
node_dist_files_without_trans_230_km_folder <- 'C:\\Users\\ywx12\\Desktop\\PhD\\RA\\ProtectedLand\\ProtConn_CALC\\data\\REGION_PA\\tmp1_notrans'

## Variables for naming nodes and distance files
prefix_nodes_files <- "nodes_"
prefix_distances_files <- "distances_"

out_ec <- paste(node_dist_files_230_km_folder,"/ECAminmax_countries_with_trans.txt", sep = "")
out_ec_wt <- paste(node_dist_files_without_trans_230_km_folder,"/ECAminmax_countries_without_trans.txt", sep = "")

## The following are the names of the folders and some specifications of the file names where the node and distance files for Conefor (graph-based connectivity analysis) will be written
## These two folders have to be created "manually" in the location of "rootfolder" above (they are not created automatically by the script) and should contain the executable file of the Conefor commnad line within them
## The files (not the folders) are created automatically by the script
#directory_name <- paste(args[6],"/",sep="")
directory_name <- paste(node_dist_files_230_km_folder,"/",sep="")
directory_name_WITHOUT_TRANS <- paste(node_dist_files_without_trans_230_km_folder,"/",sep="")

end_file_name <- paste("_",'test', sep = "")
end_file_name_WITHOUT_TRANS <- paste("_",'test',"_WITHOUT_TRANS",sep = "")
## The folder and file names "WITHOUT_TRANS" refer to the files that do not account for the transboundary connections (and hence do not account for the Trans component of ProtConn)
## The folder and file names without that addition consider the transboundary connections (the comparison of the results from one and the other set of files allows to obtain the Trans component of ProtConn)
###### ALL LOCAL VARIABLES ARE SET

setwd(root_folder)  # got the warning: cannot change working directory

Raw_Distances <- read.csv(raw_distance_file)
Raw_Nodes <- read.csv(raw_nodes_file)

## As we need to distinguish boundary correction and no-boundary correction:
## for no-boundary correction, the dataframes should be further modified:
Raw_Nodes <- subset(Raw_Nodes, ifPA == 1)
list_nodes <- unique(Raw_Nodes$nodeID)
Raw_Distances <- Raw_Distances[Raw_Distances$IN_FID %in% list_nodes | Raw_Distances$NEAR_FID %in% list_nodes, ]
## for boundary correction, no need of modification.



## Remove two columns that are not needed
Distances <- Raw_Distances
Distances$OBJECTID <- NULL
Distances$NEAR_RANK <- NULL

## Now we identify the duplicates (i.e. both directions; the distance from X to Y is (should be) the same than from Y to X).
## We check that this is the case (that the distance from X to Y is the same than from Y to X) and then we remove one of the two duplicated cases (e.g. we keep the distance from X to Y and remove the distance from Y to X; any of the two can be kept)
## Procedure taken from one of the responses (not the first one) here: https://stackoverflow.com/questions/29170099/remove-duplicate-column-pairs-sort-rows-based-on-2-columns?rq=1
uid = unique(unlist(Distances[c("IN_FID", "NEAR_FID")], use.names=FALSE))

swap = match(Distances[["IN_FID"]], uid) > match(Distances[["NEAR_FID"]], uid)

tmp = Distances[swap, "IN_FID"]
Distances[swap, "IN_FID"] = Distances[swap, "NEAR_FID"]
Distances[swap, "NEAR_FID"] = tmp
Distances <- Distances[!duplicated(Distances[1:2]),]

Nodes <- Raw_Nodes
area_field <- 'STATEFP'

## These columns need some changes.
## Remove columns that are not needed
# Nodes$OID <- NULL
# Nodes$nodeID <- NULL ## Commented out by GD on 20191128
# Nodes$ORIG_FID <- NULL
##Nodes$Shape_Length <- NULL ## Commented out by GD on 20191127
# Nodes$Shape_Leng <- NULL ## Added By GD on 20191128
# Nodes$Shape_Area <- NULL
# Nodes$GAP_Sts <- NULL
Nodes$GEOID <- Nodes$STATEFP
Nodes$STATEFP <- NULL
Nodes$SHAPE_Length <- NULL
Nodes$Shape_Le_1 <- NULL
# Nodes$AREA_GEO <- NA
# Nodes$AREA_GEO <- Nodes$SHAPE_Area / 1000000
Nodes$SHAPE_Area <- NULL



# list_ISO3 <- unique(Nodes$ISO3final)
# list_id gets all area codes
list_id <- unique(Nodes$GEOID)
## The following is the number of different ISO3 codes that we have in the PA data to be processed
# nlevels(list_ISO3)
nlevels(list_id) # ?

# Now we select, for each country or territory (ISO3 code), the rows in the distance file that have ISO3 in any of the two ID columns
# We do so because we want to include the PAS that are within a given country (ISO3 code) but also those that are up to a given maximum distance (230 km) around the PAs of that country (ISO3 code)
for (i in list_id)
{
  # i = 1
  # i = list_id[1]
  ## First we select from the node file the rows that correspond to a given country or territory (ISO3 code)
  # Nodes_current_country <- Nodes[Nodes$ISO3final %in% i,]
  Nodes_current_area <- Nodes[Nodes$GEOID %in% i,]
  
  ## 1, Now that we have all rows (nodes) in the target area
  ## We will select rows in the distance file corresponding to them, meaning that
  ## 2, we will select rows with in_fid or near_fid same as node ids in the selected rows
  ## 3, And we will add (update) all appeared nodes in step 2 to our node file, that is
  ## not only the nodes within the area, but also their near neighbors
  # temp_Distances_current_country <- Distances[Distances$IN_FID %in% Nodes_current_country$OBJECTID | Distances$NEAR_FID %in% Nodes_current_country$OBJECTID,]
  temp_Distances_current_area <- Distances[Distances$IN_FID %in% Nodes_current_area$nodeID | Distances$NEAR_FID %in% Nodes_current_area$nodeID,]
  # temp_Nodes_FINAL_current_country <- Nodes[Nodes$OBJECTID %in% temp_Distances_current_country$IN_FID  | Nodes$OBJECTID %in% temp_Distances_current_country$NEAR_FID | Nodes$OBJECTID %in% Nodes_current_country$OBJECTID,]
  temp_Nodes_FINAL_current_area <- Nodes[Nodes$nodeID %in% temp_Distances_current_area$IN_FID  | Nodes$nodeID %in% temp_Distances_current_area$NEAR_FID | Nodes$nodeID %in% Nodes_current_area$nodeID,]
  
  ## Now we use the above node file to update the distance file
  ## Now we add those that have distances calculated from/to any of the previous rows
  # Distances_current_country <- Distances[Distances$IN_FID %in% temp_Nodes_FINAL_current_country$OBJECTID | Distances$NEAR_FID %in% temp_Nodes_FINAL_current_country$OBJECTID,]
  Distances_current_area <- Distances[Distances$IN_FID %in% temp_Nodes_FINAL_current_area$nodeID | Distances$NEAR_FID %in% temp_Nodes_FINAL_current_area$nodeID,]
  ## Below: here only those cases in which both PAs in the distance pair are within the country (we here exclude transboundary connectivity)
  # Distances_current_country_WITHOUT_TRANS <- Distances[Distances$IN_FID %in% Nodes_current_country$OBJECTID & Distances$NEAR_FID %in% Nodes_current_country$OBJECTID,]
  Distances_current_area_WITHOUT_TRANS <- Distances[Distances$IN_FID %in% Nodes_current_area$nodeID & Distances$NEAR_FID %in% Nodes_current_area$nodeID,]
  
  ## Now I select the cases for the node file of a given country (ISO3 code). The last condition is to include the cases "intra" (intra-patch / intra-PA connectivity) from all the PAs within a given country
  # Nodes_FINAL_current_country <- Nodes[Nodes$OBJECTID %in% Distances_current_country$IN_FID  | Nodes$OBJECTID %in% Distances_current_country$NEAR_FID | Nodes$OBJECTID %in% Nodes_current_country$OBJECTID,]
  Nodes_FINAL_current_area <- Nodes[Nodes$nodeID %in% Distances_current_area$IN_FID  | Nodes$nodeID %in% Distances_current_area$NEAR_FID | Nodes$nodeID %in% Nodes_current_area$nodeID,]
  ## The node file for a given country (ISO3) but without the transboundary connectivity component is directly the one we had from before
  # Nodes_FINAL_current_country_WITHOUT_TRANS <-Nodes_current_country
  Nodes_FINAL_current_area_WITHOUT_TRANS <-Nodes_current_area
  
  ## Now we need to set the attribute (area) equal to zero for those PAs that are not found within the country (these PAs are only potential stepping stones, not sources or destinations). This obviously only applies to the case in which the transboundary connectivity is considered
  # Nodes_FINAL_current_country$AREA_GEO [Nodes_FINAL_current_country$ISO3final != i] <- 0
  Nodes_FINAL_current_area$AREA_GEO [Nodes_FINAL_current_area$nodeID != i] <- 0
  
  ## Now we remove the second column with the ISO3, wihch is no longer needed within the file
  # Nodes_FINAL_current_country$ISO3final <- NULL
  Nodes_FINAL_current_area$nodeID <- NULL
  # Nodes_FINAL_current_country_WITHOUT_TRANS$ISO3final <- NULL
  Nodes_FINAL_current_area_WITHOUT_TRANS$nodeID <- NULL
  
  ## This will be the node file for the country (ISO3 code), saved without column headers and without row names (this is the right format for Conefor)
  node_file_name <- paste(directory_name,prefix_nodes_files,i,end_file_name,sep="")
  write.table(Nodes_FINAL_current_area, file=node_file_name, row.names = FALSE, col.names = FALSE,  sep="\t")
  
  node_file_name_WITHOUT_TRANS <- paste(directory_name_WITHOUT_TRANS,prefix_nodes_files,i,end_file_name_WITHOUT_TRANS,sep="")
  write.table(Nodes_FINAL_current_area_WITHOUT_TRANS, file=node_file_name_WITHOUT_TRANS, row.names = FALSE, col.names = FALSE,  sep="\t")
  
  ## And now we similarly produce the distance file for COnefor for the country (ISO3 code)
  distance_file_name <- paste(directory_name,prefix_distances_files,i,end_file_name,sep="")
  write.table(Distances_current_area, file=distance_file_name, row.names = FALSE, col.names = FALSE,  sep="\t")
  
  distance_file_name_WITHOUT_TRANS <- paste(directory_name_WITHOUT_TRANS,prefix_distances_files,i,end_file_name_WITHOUT_TRANS,sep="")
  write.table(Distances_current_area_WITHOUT_TRANS, file=distance_file_name_WITHOUT_TRANS, row.names = FALSE, col.names = FALSE,  sep="\t")
  
  ## this is just to see the progress of the loop
  print(i)
}

## In the next set of lines we will calculate the minimum and maximum possible value of ECA (Equivalent Connected Area) in each country
## First we make the runs considering the transboundary connectivity

setwd(node_dist_files_230_km_folder)

## The following lines ("for" loop) will account and correct for the cases (ISO3 codes) that have nothing written in the distance file, which can be because of two reasons:
## 1) There is only one node (one PA) and hence do not have any distance calculated between any pair of PAs
## 2) There are several PAs but they are separated by a distance larger than the maximum dispersal distance considered (230 km) and hence there are no distance values in the distance file
## Both cases are solved in the same way: we add a "imaginary" or "fake" node in the node file, and we create a distance file with a distance that is almost infinite between this "imaginary" node and the first node that appears listed in the node file of the country
## This does not cause any change in the resultant connectivity values for the country, but allows to have the results of Conefor calculated systematically and in the same format and table for all countries (including the countries in this case that is here "corrected" or treated separately)

## In the following lines ("for" loop) we  calculate the minimum and maximum possible value of ECA (Equivalent Connected Area) in each country

file_names_nodes <- dir(node_dist_files_230_km_folder, pattern = prefix_nodes_files)
file_names_distances <- dir(node_dist_files_230_km_folder, pattern = prefix_distances_files)
ECAminmax<-as.table(matrix(nrow=length(file_names_nodes),ncol=3,byrow=TRUE))

for(i in 1:length(file_names_nodes))
{
  # i = 1
  nodefile <- read.table(file_names_nodes[i],header=FALSE, sep="\t", stringsAsFactors=FALSE)
  ## Using "tryCatch" here allows to detect the cases with an empty distance file and avoid an error when dealing with these cases
  distfile <- tryCatch(read.table(file_names_distances[i],header=FALSE, sep="\t", stringsAsFactors=FALSE), error=function(e) NULL)
  ECAminmax[i,1]=substr(file_names_nodes[i],nchar(prefix_nodes_files)+1,nchar(prefix_nodes_files)+3+nchar(end_file_name))
  ECAminmax[i,2]=sqrt(sum(nodefile[,2]*nodefile[,2]))
  ECAminmax[i,3]=sum(nodefile[,2])
  if (is.null(nrow(distfile)))
  {
    nodefile[nrow(nodefile)+1,] =c(-1,0)
    distfile <-as.table(matrix(c(nodefile[1,1],nodefile[nrow(nodefile),1],99999999999999999999),ncol=3,byrow=TRUE))
    write.table(nodefile,file = file_names_nodes[i],row.names=FALSE,col.names=FALSE,sep="\t")
    write.table(distfile,file=paste(prefix_distances_files,substr(file_names_nodes[i],nchar(prefix_nodes_files)+1,nchar(file_names_nodes[i])),sep=""),row.names=FALSE,col.names = FALSE,sep="\t")
  }
}
## Now we write the minimum and maximum values that are possible for ECA in each country
write.table(ECAminmax,file = out_ec,row.names=FALSE,col.names=FALSE,sep="\t")


## And now we do the same as above but without considering the transboundary connectivity component (without trans)

setwd(node_dist_files_without_trans_230_km_folder)

## The following is the number of characters in the text identifier for each country (3 for the ISO3 code + the number of characters for the year e.g. _2019)

file_names_nodes_wt <- dir(node_dist_files_without_trans_230_km_folder, pattern = prefix_nodes_files)
file_names_distances_wt <- dir(node_dist_files_without_trans_230_km_folder, pattern = prefix_distances_files)
ECAminmax<-as.table(matrix(nrow=length(file_names_nodes_wt),ncol=3,byrow=TRUE))

for(i in 1:length(file_names_nodes_wt))
{
  nodefile <- read.table(file_names_nodes_wt[i],header=FALSE, sep="\t", stringsAsFactors=FALSE)
  distfile <- tryCatch(read.table(file_names_distances_wt[i],header=FALSE, sep="\t", stringsAsFactors=FALSE), error=function(e) NULL)
  ECAminmax[i,1]=substr(file_names_nodes_wt[i],nchar(prefix_nodes_files)+1,nchar(prefix_nodes_files)+3+nchar(end_file_name_WITHOUT_TRANS))
  ECAminmax[i,2]=sqrt(sum(nodefile[,2]*nodefile[,2]))
  ECAminmax[i,3]=sum(nodefile[,2])
  if (is.null(nrow(distfile)))
  {
    nodefile[nrow(nodefile)+1,] =c(-1,0)
    distfile <-as.table(matrix(c(nodefile[1,1],nodefile[nrow(nodefile),1],99999999999999999999),ncol=3,byrow=TRUE))
    write.table(nodefile,file = file_names_nodes_wt[i],row.names=FALSE,col.names=FALSE,sep="\t")
    write.table(distfile,file=paste(prefix_distances_files,substr(file_names_nodes_wt[i],nchar(prefix_nodes_files)+1,nchar(file_names_nodes_wt[i])),sep=""),row.names=FALSE,col.names = FALSE,sep="\t")
  }
}
write.table(ECAminmax, file = out_ec_wt,row.names=FALSE,col.names=FALSE,sep="\t")

print("Script prepare_conefor_files_country.R ended at:")
print(Sys.time())

## END
