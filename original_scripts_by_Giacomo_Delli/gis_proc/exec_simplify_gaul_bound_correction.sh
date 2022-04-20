#!/bin/bash
## PROTCONN: SCRIPT TO SIMPLIFY gaul_singleparted in PG
## TO BE RUN AFTER RUNNING PROTCONN MODEL FOR BOUND CORRECTION(part 1)IN ARCGIS 10.5

date
start1=`date +%s`

##READ VARIABLES FROM CONFIGURATION FILE
SERVICEDIR="/globes/USERS/GIACOMO/protconn/scripts"
source ${SERVICEDIR}/protconn.conf
dbpar="-h ${host} -U ${user} -d ${db}"

## 1) IMPORT GAUL SINGLE PART IN POSTGRES
echo "Now importing gaul single part in PG..."
ogr2ogr \
-progress \
-overwrite \
-skipfailures \
-sql "SELECT * FROM ${gaul_for_bound_corr} WHERE area_geo>=1" \
-f "PostgreSQL"  \
PG:"host=${host} user=${user} dbname=${db} active_schema=${protconn_schema} password=${pw}" \
-nln "${protconn_schema}.${gaul_for_bound_corr}" \
-nlt "MULTIPOLYGON" \
${DATADIR}/${gdb_name}

wait
echo "GDB feature class imported in PG as table ${protconn_schema}.${gaul_for_bound_corr}"


###########################
## 2) SIMPLIFY FEATURES
echo "Now simplifying features..."

psql ${dbpar} -t -v OUTSCHEMA=${protconn_schema} -v INNAME=${gaul_for_bound_corr} -v OUTNAME=${gaul_for_bound_corr_simpl} -f ./sql/simplify_gaul_singleparted.sql 

wait
echo "Features simplified."

###########################
## 3) EXPORT GAUL FROM POSTGRES TO SHAPEFILE (GPKG DOES NOT WORK DURING SUCCESSIVE IMPORT IN GDB)
echo "Now exporting simplified features in shapefile..."

ogr2ogr  \
-f "ESRI Shapefile" \
${DATADIR}/${gaul_for_bound_corr_simpl}.shp  \
PG:"host=${host} user=${user} dbname=${db} active_schema=${protconn_schema} password=${pw}"  \
"${protconn_schema}.${gaul_for_bound_corr_simpl}"  \
-t_srs EPSG:4326 \
-overwrite \
-skipfailures

wait
date
end1=`date +%s`
runtime=$(((end1-start1) / 60))

echo " "
echo "----------------------------------------------------------------"
echo "Simplified features exported in Shapefile."
echo "Script $(basename "$0") executed in ${runtime} minutes"
echo "Now proceed with the second arcpy script b2country_boundcorr.py "
echo " "

exit
