#!/bin/bash

echo " "
echo "-------------------------------------------------------------------------------"
echo "- Script $(basename "$0") started at $(date)"
echo " "
first_start=`date +%s`
start=${first_start}
# READ VARIABLES FROM CONFIGURATION FILE
SERVICEDIR="/globes/USERS/GIACOMO/protconn/scripts"
source ${SERVICEDIR}/protconn.conf

# SET DERIVED VARIABLES
polytab=${poly_table}"_"${wdpadate}
pointtab=${point_table}"_"${wdpadate}
dbpar1="host=${host} user=${user} dbname=${db}"
dbpar2="-h ${host} -U ${user} -d ${db} -w"

## PRE-PROCESS WDPA
psql ${dbpar2}	-v vSCHEMA=${schema_protconn} \
				-v WDPASCHEMA=${wdpa_schema} \
				-v vDATE=${wdpadate} \
				-v vidx='_idx' \
				-v vINNAME_POLY=${polytab} \
				-v vINNAME_POINT=${pointtab} \
				-f ${SQLDIR}/protconn_wdpa_preproc.sql
wait
end=`date +%s`
runtime=$(((end-start) / 60))
echo "WDPA preprocessed in "${runtime}" minutes"

start=`date +%s`
psql ${dbpar2} -c "SELECT * FROM ind_protconn.protconn_country_part_1()"
wait
end=`date +%s`
runtime=$(((end-start) / 60))
echo "protconn-country gis processing (part 1) completed in in "${runtime}" minutes"

start=`date +%s`
psql ${dbpar2} -c "SELECT * FROM ind_protconn.protconn_country_part_2()"
wait
end=`date +%s`
runtime=$(((end-start) / 60))
echo "protconn-country gis processing (part 2) completed in in "${runtime}" minutes"

start=`date +%s`
psql ${dbpar2} -c "SELECT * FROM ind_protconn.protconn_country_part_3()"
wait
end=`date +%s`
runtime=$(((end-start) / 60))
echo "protconn-country gis processing (part 3) completed in in "${runtime}" minutes"

start=`date +%s`
psql ${dbpar2} -c "SELECT * FROM ind_protconn.protconn_country_part_4()"
end=`date +%s`
runtime=$(((end-start) / 60))
echo "protconn-country gis processing (part 4) completed in in "${runtime}" minutes"

last_end=`date +%s`
echo " "
totalruntime=$(((last_end-first_start) / 60))
echo "-------------------------------------------------------------------------------"
echo " "
echo "Full protconn-country gis processing chain completed in "${totalruntime}" minutes"
echo " "
echo "-------------------------------------------------------------------------------"

echo "-------------------------------------------------------------------------------"
echo " "
echo "dissolved_iso completed"
date
