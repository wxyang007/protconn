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
echo "Now importing gpkg file in PG..."
ogr2ogr \
-progress \
-overwrite \
-skipfailures \
-sql "SELECT * FROM main.wdpa_flat_1km2_final" \
-f "PostgreSQL"  \
PG:"host=${host} user=${user} dbname=${db} active_schema=${protconn_schema} password=${pw}" \
-nln "${protconn_schema}.wdpa_flat_1km2_final" \
-nlt "MULTIPOLYGON" \
${DATADIR}/${gpkg_from_gdb}.gpkg

wait
end=`date +%s`
runtime=$(((end-start) / 60))
echo "gpkg file imported in PG as table "${protconn_schema}".wdpa_flat_1km2_final in "${runtime}" minutes"


###########################
## 2) REPAIR GEOMETRIES AND GENERATE NEAR TABLE IN POSTGIS
echo "Now generating Near Table..."

start=`date +%s`
psql ${dbpar} -t -v OUTSCHEMA=${protconn_schema} -f ${SQLDIR}/generate_near_table_country.sql
end=`date +%s`
runtime=$(((end-start) / 60))
wait
echo "Near Table for Country Generated in "${runtime}" minutes"


###########################
## 3) EXPORT NEAR TABLE TO TXT
echo "Now exporting Near Table to txt file"
echo "\copy ${protconn_schema}.all_distances_300km TO '${DATADIR}/all_distances_pg_300km_mar2020.txt' delimiter ',' csv HEADER" > ${SQLDIR}/export_near_table_to_txt.sql
psql ${dbpar} -t -f ${SQLDIR}/export_near_table_to_txt.sql

wait
end=`date +%s`
runtime=$(((end-start) / 60))
wait
echo "Near Table exported to txt file in "${runtime}" minutes"

date
echo " "

