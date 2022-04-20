#!/bin/bash
## PROTCONN: SCRIPT TO PERFORM FULL CONNECTIVITY ANALYSIS AT COUNTRY, BOUND CORRECTION 
## AND ECOREGION LEVEL ON SERVER WITH PARALLELIZATION

echo " "
echo "----------------------------------------------------------------------------------"
echo "This script executes in parallel the connectivity analysis for countries (with and"
echo "without transboundary), for countries with bound correction and for ecoregions    "
echo "Script $(basename "$0") started at $(date)                                        "
echo "----------------------------------------------------------------------------------"
echo " "

startdate_master=`date +%s`

# READ VARIABLES FROM CONFIGURATION FILE
SERVICEDIR="/globes/USERS/GIACOMO/protconn/scripts"
source ${SERVICEDIR}/protconn.conf
dbpar="-h ${host} -U ${user} -d ${db}"

#######################################################################################
## FIRST PART: CONNECTIVITY ANALISYS FOR COUNTRIES (WITH AND WITHOUT TRANSBOUNDARY) ###
#######################################################################################

echo "FIRST PART: CONNECTIVITY ANALISYS FOR COUNTRIES (WITH AND WITHOUT TRANSBOUNDARY)"

# # CREATE REQUIRED FOLDERS AND COPY EXECUTABLE
mkdir -p ${cnt_with_trans}
mkdir -p ${cnt_without_trans}
cp conefor2.7.3Linux ${cnt_with_trans}/.
cp conefor2.7.3Linux ${cnt_without_trans}/.

# # RUN THE R SCRIPT TO PREPARE THE nodes_ AND distances_FILES NEEDED BY CONEFOR
echo "Now running the R script that prepares the nodes_ and distances_ files needed by Conefor..."
Rscript ./R_scripts/prepare_conefor_files_country.R ${cnt_with_trans} ${cnt_without_trans} ${raw_distance_file_cnt} ${raw_nodes_file_cnt}
date
echo "Files for protconn (countries with and without transboundary) prepared"

## PARALLEL CONEFOR CYCLE: RUN CONEFOR FOR COUNTRIES WITH TRANS
echo "Now running Conefor at country level in parallel..."
echo "Script exec_conefor_country_part1.sh started at $(date)"
./exec_conefor_country_part1.sh >${LOGPATH}/conefor_country_part1.log 2>&1 &

# now waiting for the completion of most part of the cores
sleep 9000

## PARALLEL CONEFOR CYCLE: RUN CONEFOR FOR COUNTRIES WITHOUT TRANS
echo "Now running Conefor at country level without transboundary in parallel..."
echo "Script exec_conefor_country_part2.sh started at $(date)"
./exec_conefor_country_part2.sh >${LOGPATH}/conefor_country_part2.log 2>&1 &


############################################################################
### SECOND PART : CONNECTIVITY ANALISYS FOR COUNTRIES (BOUND CORRECTION) ###
############################################################################

echo "SECOND PART: CONNECTIVITY ANALISYS FOR COUNTRIES (BOUND CORRECTION)"

sleep 60

# # CREATE REQUIRED FOLDERS AND COPY EXECUTABLE
mkdir -p ${bound_corr}
cp conefor2.7.3Linux ${bound_corr}/.

# # RUN THE R SCRIPT TO PREPARE THE nodes_ AND distances_FILES NEEDED BY CONEFOR
echo "Now running the R script that prepares the nodes_ and distances_ files needed by Conefor..."
Rscript ./R_scripts/prepare_conefor_files_bound_correction.R ${bound_corr} ${raw_distance_file_bound} ${raw_nodes_file_bound}
date
echo "Files for protconn (bound correction) prepared"

# now waiting for the completion of most part of the cores used by previous conefor cycles
sleep 5400

## PARALLEL CONEFOR CYCLE: RUN CONEFOR FOR BOUND CORRECTION
echo "Now running Conefor for Bound Correction in parallel..."
echo "Script exec_conefor_bound_correction.sh started at $(date)"
./exec_conefor_bound_correction.sh >${LOGPATH}/conefor_bound_corr.log 2>&1 &


#########################################################################################
### THIRD PART: CONNECTIVITY ANALISYS FOR ECOREGIONS (WITH AND WITHOUT TRANSBOUNDARY) ###
#########################################################################################

echo "THIRD PART: CONNECTIVITY ANALISYS FOR ECOREGIONS (WITH AND WITHOUT TRANSBOUNDARY)"

sleep 60

# # CREATE REQUIRED FOLDERS AND COPY EXECUTABLE
mkdir -p ${eco_with_trans}
mkdir -p ${eco_without_trans}
cp conefor2.7.3Linux ${eco_with_trans}/.
cp conefor2.7.3Linux ${eco_without_trans}/.

# # RUN THE R SCRIPT TO PREPARE THE nodes_ AND distances_FILES NEEDED BY CONEFOR
echo "Now running the R script that prepares the nodes_ and distances_ files needed by Conefor..."
Rscript ./R_scripts/prepare_conefor_files_ecoregions.R ${eco_with_trans} ${eco_without_trans} ${raw_distance_file_eco} ${raw_nodes_file_eco}
date
echo "Files for protconn (ecoregions with and without transboundary) prepared"

# # now waiting for the completion of most part of the cores used by previous conefor cycles
sleep 5400

## PARALLEL CONEFOR CYCLE: RUN CONEFOR FOR ECOREGIONS WITH TRANS
echo "Now running Conefor for Ecoregions with trans in parallel..."
echo "Script exec_conefor_eco_part1.sh started at $(date)"
./exec_conefor_eco_part1.sh >${LOGPATH}/conefor_eco_part1.log 2>&1 &

# now waiting for the completion of most part of the cores
sleep 5400

## PARALLEL CONEFOR CYCLE: RUN CONEFOR FOR ECOREGIONS WITHOUT TRANS
echo "Now running Conefor for Ecoregions without trans in parallel..."
echo "Script exec_conefor_eco_part2.sh started at $(date)"
./exec_conefor_eco_part2.sh >${LOGPATH}/conefor_eco_part2.log 2>&1

wait

###########################################################
### FOURTH PART: POSTPROCESSING OF CONNECTIVITY RESULTS ###
###########################################################

echo "Now running the scripts that post-processes connectivity data for countries and ecoregions"
echo "Scripts for post-processing started at $(date)"

# # POSTPROCESS RESULTS FROM CONEFOR FOR COUNTRY:
# RUN SQL TO CREATE TABLE WITH AREAS FOR COUNTRIES
psql ${dbpar} -t -f ./sql/compute_iso3_area.sql
psql ${dbpar} -c '\copy (SELECT * FROM delli.iso3_areas) to '${iso3_area_geo}' with csv HEADER'
# RUN SCRIPT TO POSTPROCESS RESULTS FOR COUNTRIES
Rscript ./R_scripts/postproc_protconn_country.R ${results_folder} ${wdpadate} ${iso3_area_geo} >${LOGPATH}/postproc_conefor_country.log 2>&1
wait

# # POSTPROCESS RESULTS FROM CONEFOR FOR ECOREGIONS:
# RUN SQL TO CREATE TABLE WITH AREAS FOR ECOREGIONS
psql ${dbpar} -t -f ./sql/compute_eco_area.sql
psql ${dbpar} -c '\copy (SELECT * FROM delli.eco_areas_without_antarctica) to '${eco_area_geo}' with csv HEADER'
# RUN SCRIPT TO POSTPROCESS RESULTS FOR COUNTRIES
Rscript ./R_scripts/postproc_protconn_eco.R ${results_folder} ${wdpadate} ${eco_area_geo}  >${LOGPATH}/postproc_conefor_eco.log 2>&1
wait

##########################################################################################

enddate_master=`date +%s`
runtime_master=$(((enddate_master-startdate_master) / 60))

echo " "
echo "-----------------------------------------------------------------------------------"
echo "Full Connectivity analysis performed in "${runtime_master}" minutes"
echo "END OF PROCEDURE                                                                ---"
echo "-----------------------------------------------------------------------------------"

exit
