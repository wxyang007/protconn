#!/bin/bash
## PROTCONN: SCRIPT TO Generate Near Table for country in Postgis
## TO BE RUN AFTER RUNNING PROTCONN MODEL (part 2)IN ARCGIS 10.5

echo " "
echo "-------------------------------------------------------------------------------"
echo "- Script $(basename "$0") started at $(date)"
echo " "

date

##READ VARIABLES FROM CONFIGURATION FILE
first_start=`date +%s`
start=${first_start}

# READ VARIABLES FROM CONFIGURATION FILE
SERVICEDIR="/globes/USERS/GIACOMO/protconn/scripts"
source ${SERVICEDIR}/protconn.conf
dbpar="-h ${host} -U ${user} -d ${db}"
dbpar2="-h ${host} -U ${user} -d ${db} -w"

## 1) IMPORT WDPA_FLAT_1KM_FINAL GPKG IN POSTGRES
echo "Now importing wdpa final in PG..."
ogr2ogr \
-progress \
-overwrite \
-skipfailures \
-f "PostgreSQL"  \
PG:"host=${host} user=${user} dbname=${db} active_schema=${protconn_schema} password=${pw}" \
-nln "${protconn_schema}.${wdpa_flat_1km_final}" \
-nlt "MULTIPOLYGON" \
${DATADIR}/${gdb_name} ${wdpa_flat_1km_final}

wait
end=`date +%s`
runtime=$(((end-start) / 60))
echo "wdpa final imported in PG as table "${protconn_schema}".${wdpa_flat_1km_final} in "${runtime}" minutes"


###########################
## 2) REPAIR GEOMETRIES AND GENERATE NEAR TABLE IN POSTGIS
echo "Now generating Near Table..."

start=`date +%s`
psql ${dbpar} -t -v OUTSCHEMA=${protconn_schema} -v INTABLE=${wdpa_flat_1km_final} -f ${SQLDIR}/generate_near_table_country.sql
end=`date +%s`
runtime=$(((end-start) / 60))
wait
echo "Near Table for Country Generated in "${runtime}" minutes"


###########################
## 3) EXPORT NEAR TABLE TO TXT
echo "Now exporting Near Table to txt file"
start=`date +%s`
echo "\copy ${protconn_schema}.all_distances_300km TO '${raw_distance_file_cnt}' delimiter ',' csv HEADER" > ${SQLDIR}/export_near_table_to_txt.sql
psql ${dbpar} -t -f ${SQLDIR}/export_near_table_to_txt.sql

wait
end=`date +%s`
runtime=$(((end-start) / 60))
wait
echo "Near Table exported to txt file in "${runtime}" minutes"
echo " "
finalruntime=$(((end-first_start) / 60))
date
echo " "
echo "Full processing time: "${runtime}" minutes"

exit
