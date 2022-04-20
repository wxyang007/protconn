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
echo "Now importing shp file in PG..."
ogr2ogr \
-progress \
-overwrite \
-skipfailures \
-f "PostgreSQL"  \
PG:"host=${host} user=${user} dbname=${db} active_schema=${protconn_schema} password=${pw}" \
-nln "${protconn_schema}.wdpa_ecoregions_final" \
-nlt "MULTIPOLYGON" \
${DATADIR}/wdpa_ecoregions_final.shp

wait
end=`date +%s`
runtime=$(((end-start) / 60))
echo "Shapefile file imported in PG as table "${protconn_schema}".wdpa_ecoregions_final in "${runtime}" minutes"


###########################
## 2) REPAIR GEOMETRIES AND GENERATE NEAR TABLE IN POSTGIS
echo "Now generating Near Table..."

start=`date +%s`
psql ${dbpar} -t -v OUTSCHEMA=${protconn_schema} -f ${SQLDIR}/generate_near_table_ecoregion.sql
end=`date +%s`
runtime=$(((end-start) / 60))
wait
echo "Near Table for Ecoregion Generated in "${runtime}" minutes"


###########################
## 3) EXPORT NEAR TABLE TO TXT
echo "Now exporting Near Table to txt file"
echo "\copy ${protconn_schema}.all_distances_ecoregions_200km TO '${DATADIR}/all_distances_pg_ecoregions_200km.txt' delimiter ',' csv HEADER" > ${SQLDIR}/export_near_table_to_txt.sql
psql ${dbpar} -t -f ${SQLDIR}/export_near_table_to_txt.sql

wait
end=`date +%s`
runtime=$(((end-start) / 60))
wait
echo "Near Table for ecoregions exported to txt file in "${runtime}" minutes"

date
echo " "

