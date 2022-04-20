#!/bin/bash
## AFTER COMPLETION OF FULL PROTCONN ANALYSIS, THIS SCRIPT CLEANS UP ALL 
## INTERMEDIATE DATA NO MORE NEEDED


echo " "
echo "----------------------------------------------------------------------------------"
echo "This script removs from /globes/ all intermediate or temporary data no more needed"
echo "once the computation of PROTCONN is succesfully completed.                        "
echo " "
echo "N.B. : Run this script ONLY after careful check of results obtained and ONLY if you "
echo "are sure that everything is fine."
echo " "

read -p "Do you want to run the script now? (y/n) " -n 1 -r
echo " "

if [[ $REPLY =~ ^[Yy]$ ]]
then
	echo "----------------------------------------------------------------------------------"
	echo " "

	source /globes/USERS/GIACOMO/protconn/scripts/protconn.conf
	dbpar="-h ${host} -U ${user} -d ${db} -p ${port}"

	## DELETE TABLES NO MORE NEEDED FROM PG DATABASE
	psql ${dbpar} -t -c "DROP TABLE IF EXISTS ${protconn_schema}.all_distances_300km;
	DROP TABLE IF EXISTS ${protconn_schema}.all_distances_300km_corr;
	DROP TABLE IF EXISTS ${protconn_schema}.all_distances_country;
	DROP TABLE IF EXISTS ${protconn_schema}.all_distances_ecoregions_200km;
	DROP TABLE IF EXISTS ${protconn_schema}.all_distances_wdpa_plus_land_100km;
	DROP TABLE IF EXISTS ${protconn_schema}.gaul_singleparted;
	DROP TABLE IF EXISTS ${protconn_schema}.gaul_singleparted_shape_simpl;
	DROP TABLE IF EXISTS ${protconn_schema}.wdpa_all_relevant;
	DROP TABLE IF EXISTS ${protconn_schema}.wdpa_all_relevant_shape_simpl;
	DROP TABLE IF EXISTS ${protconn_schema}.wdpa_ecoregions_final;
	DROP TABLE IF EXISTS ${protconn_schema}.wdpa_1km2_final;
	DROP TABLE IF EXISTS ${protconn_schema}.wdpa_1km2_final_try_again;
	DROP TABLE IF EXISTS ${protconn_schema}.wdpa_plus_land_flat_1km2_final;"

	## REMOVE temp folder
	rm -rf  ${temp_folder}

	## REMOVE all_distance* and attrib* txt files
	rm -f ${DATADIR}/*.txt

	## REMOVE GPKG AND SHP FILES
	rm -f ${DATADIR}/wdpa*
	rm -f ${DATADIR}/gaul*

	## REMOVE iso3 and eco area files
	rm -f ${DATADIR}/iso3_area_geo.csv
	rm -f ${DATADIR}/eco_area_geo.csv

	echo "Clean up completed"

else 
	echo " "
	echo "Ok, see you soon"
	echo " "
fi

exit
