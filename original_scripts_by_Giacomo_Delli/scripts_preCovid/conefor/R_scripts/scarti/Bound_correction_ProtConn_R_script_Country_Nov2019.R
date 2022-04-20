## This script performs the connectivity analyses required to obtain the Bound correction for the country-level ProtConn. 
## This script, and the bound correction, only applies to countries. It does not apply to ecoregions.
## It takes as an input the files obtained in the GIS processing for the Bound correction (described in a different document), manipulates and prepares 
## the files as needed for Conefor, and calls the executable file of the Conefor command line.

###### WE SET ALL LOCAL VARIABLES
rootfolder <- "E:\\Dev\\ProtConn_2019\\R_scripts"
node_dist_files_for_bound_folder <- "E:\\Dev\\ProtConn_2019\\R_scripts\\node_dist_files_FOR_BOUND"


## This is the distance file calculated from the layer for the BOUND correction, which includes both the protected areas (PA) and the country land polygons from GAUL
Raw_distance_file <- "All_distances_WDPA_plus_LAND100km_Nov2019.txt"
## Now we need the information on the area and ISO3 code of each polygon (PA or land polygon), which is in another file (the attribute table of the PA layer)
raw_nodes_file  <- "Attrib_table_WDPA_plus_LAND_Nov_2019_flat_1km2_final.txt"

## The following are the nameS of the folders and some specifications of the file names where the node and distance files for Conefor (graph-based connectivity analysis) will be written
## These two folders have to be created "manually" in the location of "rootfolder" above (they are not created automatically by the script) and should contain the executable file of the Conefor commnad line within them
## The files (not the folders) are created automatically by the script
directory_name <- "node_dist_files_FOR_BOUND/"
end_file_name <- "_2019"
###### ALL LOCAL VARIABLES ARE SET

setwd(rootfolder) 
Raw_Distances <- read.csv(Raw_distance_file) ##,header=TRUE)
Distances <- Raw_Distances 
Raw_Nodes <- read.csv(raw_nodes_file)

## Remove two columns that are not needed
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

## remove columns that are not needed
##Nodes$numvert <- NULL ## Commented out by GD on 20191127
Nodes$OID <- NULL ## Added By GD on 20191127
Nodes$nodeID <- NULL
##Nodes$Shape_Length <- NULL ## Commented out by GD on 20191127
Nodes$Shape_Leng <- NULL ## Added By GD on 20191127
Nodes$Shape_Area <- NULL


list_ISO3 <- unique(Nodes$ISO3final)
## The following is the number of different ISO3 codes that we have in the PA data to be processed
nlevels(list_ISO3)



## Now we select, for each country or territory (ISO3 code), the rows in the distance file that have that ISO3 in any of the two ID columns
## We do so because we want to include the PAS or land polygons that are within a given country (ISO3 code) but also those that are up to a given maximum distance (300 km) around the polygons of that country (ISO3 code)

for (i in list_ISO3) 
  {
  
  ## First we select from the node file the rows that correspond to a given country or territory (ISO3 code)
  Nodes_current_country <- Nodes[Nodes$ISO3final %in% i,]
  
  ## Now we find in the distance file the rows that have, in any of the ID fields (In or Near), the objectID of the list of IDs for a given ISO3 (Nodes_current_country)
  temp_Distances_current_country <- Distances[Distances$IN_FID %in% Nodes_current_country$OBJECTID | Distances$NEAR_FID %in% Nodes_current_country$OBJECTID,]
  temp_Nodes_FINAL_current_country <- Nodes[Nodes$OBJECTID %in% temp_Distances_current_country$IN_FID  | Nodes$OBJECTID %in% temp_Distances_current_country$NEAR_FID | Nodes$OBJECTID %in% Nodes_current_country$OBJECTID,]
  ## For the Bound correction, we now remove the land polygons (not the PAs) outside the focal country (these corresponds to cases "r" in the sums in the equations for the Bound correction as decribed in Saura et al (2018, Biological Conservation); we exclude these "r" cases and keep all other cases (cases "n"+"t"+"q" in the sums/equations)). ProtConnBound will be later calculated as ProtConnBound  = ProtConn + Prot(PA coverage) - (n+t+q), as described in Saura et al (2018, Biological Conservation)
  ## In summary, we remove the polygons with area equal to zero (this means that they are land polygons, not PAs) AND that have an ISO3 different from that of the considered country
  temp_Nodes_FINAL_current_country <- temp_Nodes_FINAL_current_country[!(temp_Nodes_FINAL_current_country$AREA_GEO==0 & !(temp_Nodes_FINAL_current_country$ISO3final %in% i)),]
 
  ## Now we add those that have distances calculated from/to any of the previous rows
  temp_2_Distances_current_country <- Distances[Distances$IN_FID %in% temp_Nodes_FINAL_current_country$OBJECTID | Distances$NEAR_FID %in% temp_Nodes_FINAL_current_country$OBJECTID,]
  ## And get the set of nodes to be considered at this point
  temp_2_Nodes_FINAL_current_country <- Nodes[Nodes$OBJECTID %in% temp_2_Distances_current_country$IN_FID  | Nodes$OBJECTID %in% temp_2_Distances_current_country$NEAR_FID | Nodes$OBJECTID %in% Nodes_current_country$OBJECTID,]
  
  ## Now we remove the polygons that have an area of zero (they are land pieces, not PAs) AND that have an ISO3 code different from that of the considered country (similar filter as done earlier above for the distance file)
  Nodes_FINAL_current_country <- temp_2_Nodes_FINAL_current_country[!(temp_2_Nodes_FINAL_current_country$AREA_GEO==0 & !(temp_2_Nodes_FINAL_current_country$ISO3final %in% i)),]
  
  ## Now we make equal to 0 the area of all those polygons that are outside the considered country (that have an ISO3 code different from that of the conisdered country); these polygons can only be stepping stones (not sources or destinations of dispersal fluxes from/to PAs of the considered country)
  Nodes_FINAL_current_country$AREA_GEO [Nodes_FINAL_current_country$ISO3final != i] <- 0
  
  ## Now we remove the second column with the ISO3, wihch is no longer needed within the file
  Nodes_FINAL_current_country$ISO3final <- NULL
  
  ## This will be the node file for the Bound correction for the country (ISO3 code), saved without column headers and without row names (this is the right format for Conefor)
  node_file_name <- paste(directory_name,"nodes_",i,end_file_name,sep="")
  write.table(Nodes_FINAL_current_country, file=node_file_name, row.names = FALSE, col.names = FALSE,  sep="\t")
  

  ## And now we similarly produce the distance file for COnefor for the country (ISO3 code)
  ## which has to include only the distance for the polygon pairs that have the IDs both within the node file above:
  Distances_FINAL_current_country <- Distances[Distances$IN_FID %in% Nodes_FINAL_current_country$OBJECTID & Distances$NEAR_FID %in% Nodes_FINAL_current_country$OBJECTID,]
  distance_file_name <- paste(directory_name,"distances_",i,end_file_name,sep="")
  write.table(Distances_FINAL_current_country, file=distance_file_name, row.names = FALSE, col.names = FALSE,  sep="\t")
  
  ## this is just to see the progress of the loop
  print(i)
  
  }

## In the next set of lines we will call the executable file of Conefor command line to perform the connectivity analyses

## We use only the reference median dispersal distance of 10 km (10000 m) for the analyses
median_disp_dist <- 10000
median_disp_dist_text <- as.character(median_disp_dist)

setwd(node_dist_files_for_bound_folder) 

## The following is the number of charaters in the text identifier for each country (3 for the ISO3 code + the number of characters for the year e.g. _2019)
num_char_id_unit <- 8 
common_initial_characters_node_file<-"nodes_"
common_initial_characters_distance_file<-"distances_"

## The following lines ("for" loop) will account and correct for the cases (ISO3 codes) that have nothing written in the distance file, which can be because of two reasons:
## 1) There is only one node (one PA or land polygon) and hence do not have any distance calculated between any pair of polygons
## 2) There are several polygons but they are separated by a distance larger than the maximum dispersal distance considered and hence there are no distance values in the distance file
## Both cases are solved in the same way: we add a "imaginary" or "fake" node in the node file, and we create a distance file with a distance that is almost infinite between this "imaginary" node and the first node that appears listed in the node file of the country
## This does not cause any change in the resultant connectivity values for the country, but allows to have the results of Conefor calculated systematically and in the same format and table for all countries (including the countries in this case that is here "corrected" or treated separately)

## In the following lines ("for" loop) we also calculate the minimum and maximum possible value of ECA (Equivalent Connected Area) in each country

file_names_nodes <- dir(node_dist_files_for_bound_folder, pattern ="nodes*")
file_names_distances <- dir(node_dist_files_for_bound_folder, pattern ="distances*")
ECAminmax<-as.table(matrix(nrow=length(file_names_nodes),ncol=3,byrow=TRUE))
for(i in 1:length(file_names_nodes)){
  nodefile <- read.table(file_names_nodes[i],header=FALSE, sep="\t", stringsAsFactors=FALSE)
  ## Using "tryCatch" here allows to detect the cases with an empty distance file and avoid an error when dealing with these cases
  distfile <- tryCatch(read.table(file_names_distances[i],header=FALSE, sep="\t", stringsAsFactors=FALSE), error=function(e) NULL)
  ECAminmax[i,1]=substr(file_names_nodes[i],nchar(file_names_nodes[i])-num_char_id_unit+1,nchar(file_names_nodes[i]))
  ECAminmax[i,2]=sqrt(sum(nodefile[,2]*nodefile[,2]))
  ECAminmax[i,3]=sum(nodefile[,2])
  if (is.null(nrow(distfile)))
  {
    nodefile[nrow(nodefile)+1,] =c(-1,0)
    distfile <-as.table(matrix(c(nodefile[1,1],nodefile[nrow(nodefile),1],99999999999999999999),ncol=3,byrow=TRUE))
    write.table(nodefile,file = file_names_nodes[i],row.names=FALSE,col.names=FALSE,sep="\t")
    write.table(distfile,file=paste(common_initial_characters_distance_file,substr(file_names_nodes[i],nchar(common_initial_characters_node_file)+1,nchar(file_names_nodes[i])),sep=""),row.names=FALSE,col.names = FALSE,sep="\t")
  }
}
## Now we write the minimum and maximum values that are possible for ECA in each country
write.table(ECAminmax,file = "ECAminmax.txt",row.names=FALSE,col.names=FALSE,sep="\t")

## Now we call the executable file of Conefor command line (this executable file must be present in the same folder as the node and distance files for Conefor)
command_string<-paste("../conefor2.7.3Linux -nodeFile",common_initial_characters_node_file," -conFile ",common_initial_characters_distance_file," -* -t dist -confProb ",median_disp_dist_text, " 0.5 -PC -F -AWF onlyoverall") 

system(command_string)

## END
