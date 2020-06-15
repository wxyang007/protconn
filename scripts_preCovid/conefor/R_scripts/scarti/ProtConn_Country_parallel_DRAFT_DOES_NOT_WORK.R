## This script performs the connectivity analyses required to obtain the country-level ProtConn.
## It takes as an input the files obtained in the GIS processing (described in a different document), manipulates and prepares the files as needed for Conefor, 
## and calls the executable file of the Conefor command line.
## There is a different R script for the post-processing of the Conefor results to obtain the values of ProtConn and its fractions for each country.

## ##Loading required package: iterators
library(foreach)
library(doParallel)

###### WE SET ALL LOCAL VARIABLES
args <- commandArgs()
root_folder <- "/globes/USERS/GIACOMO/protconn/R_scripts"
node_dist_files_300_km_folder <- "/globes/USERS/GIACOMO/protconn/R_scripts/node_dist_files_300_KM"
node_dist_files_without_trans_300_km_folder <- "/globes/USERS/GIACOMO/protconn/R_scripts/node_dist_files_WITHOUT_TRANS_300_KM"

## This is the distance file calculated from the protected area (PA) layer for the countries
Raw_distance_file <- "all_distances_300km_nov2019.txt"
## Now we need the information on the area and ISO3 code of each PA, which is in another file (the attribute table of the PA layer)
raw_nodes_file  <- "Attrib_table_wdpa_flat_1km2_final_Nov2019.txt"

## The following are the names of the folders and some specifications of the file names where the node and distance files for Conefor (graph-based connectivity analysis) will be written
## These two folders have to be created "manually" in the location of "rootfolder" above (they are not created automatically by the script) and should contain the executable file of the Conefor commnad line within them
## The files (not the folders) are created automatically by the script
directory_name <- "node_dist_files_300_KM/"
directory_name_WITHOUT_TRANS <- "node_dist_files_WITHOUT_TRANS_300_KM/"
end_file_name <- "_2019"
end_file_name_WITHOUT_TRANS <- "_WITHOUT_TRANS"
## The folder and file names "WITHOUT_TRANS" refer to the files that do not account for the transboundary connections (and hence do not account for the Trans component of ProtConn)
## The folder and file names without that addition consider the transboundary connections (the comparison of the results from one and the other set of files allows to obtain the Trans component of ProtConn)
###### ALL LOCAL VARIABLES ARE SET

# setwd(root_folder)

# Raw_Distances <- read.csv(Raw_distance_file) 
# Distances <- Raw_Distances 
# Raw_Nodes <- read.csv(raw_nodes_file)

# ## Remove two columns that are not needed
# Distances$OBJECTID <- NULL
# Distances$NEAR_RANK <- NULL

# ## Now we identify the duplicates (i.e. both directions; the distance from X to Y is (should be) the same than from Y to X). 
# ## We check that this is the case (that the distance from X to Y is the same than from Y to X) and then we remove one of the two duplicated cases (e.g. we keep the distance from X to Y and remove the distance from Y to X; any of the two can be kept)
# ## Procedure taken from one of the responses (not the first one) here: https://stackoverflow.com/questions/29170099/remove-duplicate-column-pairs-sort-rows-based-on-2-columns?rq=1
# uid = unique(unlist(Distances[c("IN_FID", "NEAR_FID")], use.names=FALSE))

# swap = match(Distances[["IN_FID"]], uid) > match(Distances[["NEAR_FID"]], uid)

# tmp = Distances[swap, "IN_FID"]
# Distances[swap, "IN_FID"] = Distances[swap, "NEAR_FID"]
# Distances[swap, "NEAR_FID"] = tmp
# Distances <- Distances[!duplicated(Distances[1:2]),]

# Nodes <- Raw_Nodes

# ## Remove columns that are not needed
# Nodes$numvert <- NULL ## Commented out by GD on 20191128
# Nodes$OID <- NULL ## Added By GD on 20191128
# Nodes$nodeID <- NULL ## Commented out by GD on 20191128
# Nodes$ORIG_FID <- NULL
# ##Nodes$Shape_Length <- NULL ## Commented out by GD on 20191127
# Nodes$Shape_Leng <- NULL ## Added By GD on 20191128 
# Nodes$Shape_Area <- NULL

# list_ISO3 <- unique(Nodes$ISO3final)
# ## The following is the number of different ISO3 codes that we have in the PA data to be processed
# nlevels(list_ISO3)

## Now we select, for each country or territory (ISO3 code), the rows in the distance file that have that ISO3 in any of the two ID columns
## We do so because we want to include the PAS that are within a given country (ISO3 code) but also those that are up to a given maximum distance (300 km) around the PAs of that country (ISO3 code)

# for (i in list_ISO3) 
# {
  # ## First we select from the node file the rows that correspond to a given country or territory (ISO3 code)
  # Nodes_current_country <- Nodes[Nodes$ISO3final %in% i,]
  
  # ## Now we find in the distance file the rows that have, in any of the ID fields (In or Near), the objectID of the list of IDs for a given ISO3 (Nodes_current_country)
  # temp_Distances_current_country <- Distances[Distances$IN_FID %in% Nodes_current_country$OBJECTID | Distances$NEAR_FID %in% Nodes_current_country$OBJECTID,]
  # temp_Nodes_FINAL_current_country <- Nodes[Nodes$OBJECTID %in% temp_Distances_current_country$IN_FID  | Nodes$OBJECTID %in% temp_Distances_current_country$NEAR_FID | Nodes$OBJECTID %in% Nodes_current_country$OBJECTID,]
  # ## Now we add those that have distances calculated from/to any of the previous rows
  # Distances_current_country <- Distances[Distances$IN_FID %in% temp_Nodes_FINAL_current_country$OBJECTID | Distances$NEAR_FID %in% temp_Nodes_FINAL_current_country$OBJECTID,]
  # ## And here only those cases in which both PAs in the distance pair are within the country (we here exclude transboundary connectivity)
  # Distances_current_country_WITHOUT_TRANS <- Distances[Distances$IN_FID %in% Nodes_current_country$OBJECTID & Distances$NEAR_FID %in% Nodes_current_country$OBJECTID,]
  
  # ## Now I select the cases for the node file of a given country (ISO3 code). The last condition is to include the cases "intra" (intra-patch / intra-PA connectivity) from all the PAs within a given country
  # Nodes_FINAL_current_country <- Nodes[Nodes$OBJECTID %in% Distances_current_country$IN_FID  | Nodes$OBJECTID %in% Distances_current_country$NEAR_FID | Nodes$OBJECTID %in% Nodes_current_country$OBJECTID,]
  # ## The node file for a given country (ISO3) but without the transboundary connectivity component is directly the one we had from before
  # Nodes_FINAL_current_country_WITHOUT_TRANS <-Nodes_current_country
  
  # ## Now we need to set the attribute (area) equal to zero for those PAs that are not found within the country (these PAs are only potential stepping stones, not sources or destinations). This obviously only applies to the case in which the transboundary connectivity is considered
  # Nodes_FINAL_current_country$AREA_GEO [Nodes_FINAL_current_country$ISO3final != i] <- 0
  
  # ## Now we remove the second column with the ISO3, wihch is no longer needed within the file
  # Nodes_FINAL_current_country$ISO3final <- NULL
  # Nodes_FINAL_current_country_WITHOUT_TRANS$ISO3final <- NULL
  
  # ## This will be the node file for the country (ISO3 code), saved without column headers and without row names (this is the right format for Conefor)
  # node_file_name <- paste(directory_name,"nodes_",i,end_file_name,sep="")
  # write.table(Nodes_FINAL_current_country, file=node_file_name, row.names = FALSE, col.names = FALSE,  sep="\t")
  
  # node_file_name_WITHOUT_TRANS <- paste(directory_name_WITHOUT_TRANS,"nodes_",i,end_file_name_WITHOUT_TRANS,sep="")
  # write.table(Nodes_FINAL_current_country_WITHOUT_TRANS, file=node_file_name_WITHOUT_TRANS, row.names = FALSE, col.names = FALSE,  sep="\t")
  
  # ## And now we similarly produce the distance file for COnefor for the country (ISO3 code)
  # distance_file_name <- paste(directory_name,"distances_",i,end_file_name,sep="")
  # write.table(Distances_current_country, file=distance_file_name, row.names = FALSE, col.names = FALSE,  sep="\t")
  
  # distance_file_name_WITHOUT_TRANS <- paste(directory_name_WITHOUT_TRANS,"distances_",i,end_file_name_WITHOUT_TRANS,sep="")
  # write.table(Distances_current_country_WITHOUT_TRANS, file=distance_file_name_WITHOUT_TRANS, row.names = FALSE, col.names = FALSE,  sep="\t")
  
  # ## this is just to see the progress of the loop
    # print(i)
  
# }

## In the next set of lines we will call the executable file of Conefor command line to perform the connectivity analyses

## We use only the reference median dispersal distance of 10 km (10000 m) for the analyses
median_disp_dist <- 10000
median_disp_dist_text <- as.character(median_disp_dist)

## First we make the runs considering the transboundary connectivity

root_folder <- "/globes/USERS/GIACOMO/protconn/R_scripts"
node_dist_files_300_km_folder <- "/globes/USERS/GIACOMO/protconn/R_scripts/node_dist_files_300_KM"
node_dist_files_without_trans_300_km_folder <- "/globes/USERS/GIACOMO/protconn/R_scripts/node_dist_files_WITHOUT_TRANS_300_KM"

## The following is the number of characters in the text identifier for each country (3 for the ISO3 code + the number of characters for the year e.g. _2019)
num_char_id_unit <- 8 
common_initial_characters_node_file<-"nodes_"
common_initial_characters_distance_file<-"distances_"

file_names_nodes <- dir(node_dist_files_300_km_folder, pattern ="nodes*")
file_names_distances <- dir(node_dist_files_300_km_folder, pattern ="distances*")
ECAminmax <- as.table(matrix(nrow=length(file_names_nodes),ncol=3,byrow=TRUE))

setwd(node_dist_files_300_km_folder)

n_cnt <- length(file_names_nodes)
tilesize <- as.numeric(args[6])
ncores <- n_cnt/tilesize + 1

## The following lines ("for" loop) will account and correct for the cases (ISO3 codes) that have nothing written in the distance file, which can be because of two reasons:
## 1) There is only one node (one PA) and hence do not have any distance calculated between any pair of PAs
## 2) There are several PAs but they are separated by a distance larger than the maximum dispersal distance considered (300 km) and hence there are no distance values in the distance file
## Both cases are solved in the same way: we add a "imaginary" or "fake" node in the node file, and we create a distance file with a distance that is almost infinite between this "imaginary" node and the first node that appears listed in the node file of the country
## This does not cause any change in the resultant connectivity values for the country, but allows to have the results of Conefor calculated systematically and in the same format and table for all countries (including the countries in this case that is here "corrected" or treated separately)

## In the following lines ("for" loop) we also calculate the minimum and maximum possible value of ECA (Equivalent Connected Area) in each country

## Here we set the number of cores for parallelization
registerDoParallel(ncores)
start <- 1

## Here we start the  parallelization of conefor
foreach(j=1:ncores)  %dopar% 
{
	end <- (j*tilesize)
	# print(start)
	# print(end)
	for(i in start:end)
	{
		# print(file_names_nodes[i])
		# print(file_names_distances[i])
		nodefile <- read.table(file_names_nodes[i],header=FALSE, sep="", stringsAsFactors=FALSE)
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
		if ( substr(file_names_nodes[i],1,10) == "nodes_ABNJ")
			{iso3 <- substr(file_names_nodes[i],8,10)}
		else
			{iso3 <- substr(file_names_nodes[i],7,9)}				# Now we call the executable file of Conefor command line (this executable file must be present in the same folder as the node and distance files for Conefor)
		# # command_string<-paste("../conefor2.7.3Linux -nodeFile",common_initial_characters_node_file," -conFile ",common_initial_characters_distance_file," -* -t dist -confProb ",median_disp_dist_text, " 0.5 -PC -F -AWF onlyoverall") 
		# command_string<-paste("../conefor2.7.3Linux -nodeFile",file_names_nodes[i]," -conFile ",file_names_distances[i]," -prefix ",iso3," -t dist -confProb ",median_disp_dist_text, " 0.5 -PC -F -AWF onlyoverall") 
		# system(command_string)
	}
	## Now we write the minimum and maximum values that are possible for ECA in each country
	# ECAfilename <- paste("ECAminmax_",j,".txt")
	if (j <- ncores)
	{
	write.table(ECAminmax,file = "ECAminmax.txt",row.names=FALSE,col.names=FALSE,sep="\t")
	}

	start <-(end+1)
	print("-------------------")
}	


print("Equivalent Connected Area for each country computed.")

# ## And now we do the same as above but without considering the transboundary connectivity component (without trans)
# setwd(node_dist_files_without_trans_300_km_folder) 
# ## Here we calculate parameters for parallelization
# nnn <-list.files(pattern="nodes*")
# ddd <-list.files(pattern="dist*")
# n_cnt <- length(nnn)
# tilesize <- as.numeric(args[6])
# ncores <- n_cnt/tilesize + 1
# ## Here we set the number of cores for parallelization
# registerDoParallel(ncores)  

# foreach(i=1:ncores)  %dopar% 
# {
	# file_names_nodes <- (split(nnn, rep(1:ceiling(ncores), each=tilesize)[1:n_cnt]))[i]
	# file_names_distances  <- (split(ddd, rep(1:ceiling(ncores), each=tilesize)[1:n_cnt]))[i]
	# ECAminmax<-as.table(matrix(nrow=length(file_names_nodes),ncol=3,byrow=TRUE))
	# for(a in 1:length(file_names_nodes))
	# {
		# nodefile <- read.table(file_names_nodes[a],header=FALSE, sep="\t", stringsAsFactors=FALSE)
		# distfile <- tryCatch(read.table(file_names_distances[a],header=FALSE, sep="\t", stringsAsFactors=FALSE), error=function(e) NULL)
		# ECAminmax[a,1]=substr(file_names_nodes[a],nchar(file_names_nodes[a])-num_char_id_unit-9,nchar(file_names_nodes[a])-10)
		# ECAminmax[a,2]=sqrt(sum(nodefile[,2]*nodefile[,2]))
		# ECAminmax[a,3]=sum(nodefile[,2])
		# if (is.null(nrow(distfile)))
		# {
			# nodefile[nrow(nodefile)+1,] =c(-1,0)
			# distfile <-as.table(matrix(c(nodefile[1,1],nodefile[nrow(nodefile),1],99999999999999999999),ncol=3,byrow=TRUE))
			# write.table(nodefile,file = file_names_nodes[a],row.names=FALSE,col.names=FALSE,sep="\t")
			# write.table(distfile,file=paste(common_initial_characters_distance_file,substr(file_names_nodes[a],nchar(common_initial_characters_node_file)+1,nchar(file_names_nodes[a])),sep=""),row.names=FALSE,col.names = FALSE,sep="\t")
		# }
	# }

	# write.table(ECAminmax,file = "ECAminmax_WITHOUT_TRANS.txt",row.names=FALSE,col.names=FALSE,sep="\t")

	# common_initial_characters_node_file<-"nodes_"
	# common_initial_characters_distance_file<-"distances_"

	# ## Now we call the executable file of Conefor command line for the case without trans (this executable file must be present in the same folder as the node and distance files for Conefor)
	# command_string<-paste("../conefor2.7.3Linux -nodeFile",common_initial_characters_node_file," -conFile ",common_initial_characters_distance_file," -* -t dist -confProb ",median_disp_dist_text, " 0.5 -PC -F -AWF onlyoverall") 

	# system(command_string)
# }
# print("Equivalent Connected Area for each country without transboundary computed.")

print("PROCEDURE COMPLETED")

## END
