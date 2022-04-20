#!/bin/bash
## PROTCONN: SCRIPT TO SIMPLIFY gaul_singleparted in PG
## TO BE RUN AFTER RUNNING PROTCONN MODEL FOR BOUND CORRECTION(part 1)IN ARCGIS 10.5

date

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
-sql "SELECT * FROM main.${gaul_pgtable}" \
-f "PostgreSQL"  \
PG:"host=${host} user=${user} dbname=${db} active_schema=${protconn_schema} password=${pw}" \
-nln "${protconn_schema}.${gaul_pgtable}" \
-nlt "MULTIPOLYGON" \
${DATADIR}/${gpkg_gaul_from_gdb}.gpkg

wait
echo "gpkg file imported in PG as table ${protconn_schema}.${gaul_pgtable}"


###########################
## 2) SIMPLIFY FEATURES
echo "Now simplifying features..."

psql ${dbpar} -t -v OUTSCHEMA=${protconn_schema} -v INNAME=${gaul_pgtable} -v OUTNAME=${shpgaul_from_pg} -f ./sql/simplify_gaul_singleparted.sql 

wait
echo "Features simplified."

###########################
## 3) EXPORT GAUL FROM POSTGRES TO SHAPEFILE (GPKG DOES NOT WORK DURING SUCCESSIVE IMPORT IN GDB)
echo "Now exporting simplified features in shapefile..."

ogr2ogr  \
-f "ESRI Shapefile" \
${DATADIR}/${shpgaul_from_pg}.shp  \
PG:"host=${host} user=${user} dbname=${db} active_schema=${protconn_schema} password=${pw}"  \
"${protconn_schema}.${shpgaul_from_pg}"  \
-t_srs EPSG:4326 \
-overwrite \
-skipfailures

wait
echo "Simplified features exported in shapefile."
echo "-----------------------------------------------------"
echo "Now proceed with the second part of the protconn model in arcgis 10.5"
echo " "

date

echo " "
