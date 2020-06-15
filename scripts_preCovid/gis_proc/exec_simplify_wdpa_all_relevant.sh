#!/bin/bash
## PROTCONN: SCRIPT TO SIMPLIFY wdpa_all_relevant in PG
## TO BE RUN AFTER RUNNING PROTCONN MODEL (part 1)IN ARCGIS 10.5

date
start1=`date +%s`

##READ VARIABLES FROM CONFIGURATION FILE
SERVICEDIR="/globes/USERS/GIACOMO/protconn/scripts"
source ${SERVICEDIR}/protconn.conf
dbpar="-h ${host} -U ${user} -d ${db}"


## 1) IMPORT WDPA GPKG IN POSTGRES
echo "Now importing gpkg file in PG..."
ogr2ogr \
-progress \
-overwrite \
-skipfailures \
-sql "SELECT * FROM main.wdpa_all_relevant" \
-f "PostgreSQL"  \
PG:"host=${host} user=${user} dbname=${db} active_schema=${protconn_schema} password=${pw}" \
-nln "${protconn_schema}.wdpa_all_relevant" \
-nlt "MULTIPOLYGON" \
${DATADIR}/${gpkg_from_gdb}.gpkg

wait
echo "gpkg file imported in PG as table delli.wdpa_all_relevant"


###########################
## 2) SIMPLIFY FEATURES
echo "Now simplifying features..."

psql ${dbpar} -t -v OUTSCHEMA=${protconn_schema} -v INNAME=${wdpa_pgtable} -v OUTNAME=${shp_from_pg} -f ./sql/simplify_wdpa_all_relevant.sql 

wait
echo "Features simplified."

###########################
## 3) EXPORT WDPA FROM POSTGRES TO SHAPEFILE (GPKG DOES NOT WORK DURING SUCCESSIVE IMPORT IN GDB)
echo "Now exporting simplified features in shapefile..."

ogr2ogr  \
-progress \
-select wdpaid,iso3,geom \
-f "ESRI Shapefile" \
${DATADIR}/${shp_from_pg}.shp  \
PG:"host=${host} user=${user} dbname=${db} active_schema=${protconn_schema} password=${pw}"  \
"${protconn_schema}.wdpa_all_relevant_shape_simpl"  \
-t_srs EPSG:4326 \
-overwrite \
-skipfailures

wait
date
end1=`date +%s`
runtime=$(((end1-start1) / 60))
echo "Simplified features exported in Shapefile."
echo "Script $(basename "$0") executed in ${runtime} minutes"
echo "-----------------------------------------------------"
echo "Now proceed with the second part of the protconn model in arcgis 10.5"

exit

