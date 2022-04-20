#!/bin/bash
## PROTCONN: SCRIPT TO PERFORM CONNECTIVITY ANALYSIS AT COUNTRY LEVEL ON SERVER WITH PARALLELIZATION

startdate_cp1=`date +%s`

# READ VARIABLES FROM CONFIGURATION FILE
SERVICEDIR="/globes/USERS/GIACOMO/protconn/scripts"
source ${SERVICEDIR}/protconn.conf

NCORES=48
((ALLCNT=$(ls ${cnt_with_trans}/nodes*|wc -l)+1))
((TILESIZE=(${ALLCNT}+(${NCORES}-1))/${NCORES}))

# CHANGE WORKING DIRECTORY
cd ${cnt_with_trans}

## PARALLEL CONEFOR CYCLE: RUN CONEFOR FOR COUNTRIES WITH TRANS
echo "Now running Conefor at country level with transboundary in parallel..."
for TIL in $(for i in $(eval echo {0..$NCORES}); do ((start=${TILESIZE}*$i)); echo -n $start" "; done)
	do
	for PA in $(ls |grep "nodes"|awk "NR >= (${TIL}+1) && NR <= (${TIL}+${TILESIZE})")
	do 
		if [ ${PA:0:10} == "nodes_ABNJ" ]
		then 
		iso3_suffix=${PA:6:4}
		else
		iso3_suffix=${PA:6:3}
		fi
		echo "./conefor2.7.3Linux -nodeFile nodes_${iso3_suffix}_2019 -conFile distances_${iso3_suffix}_2019 -prefix ${iso3_suffix}_2019 -t dist -confProb 10000 0.5 -PC -F -AWF onlyoverall"
	done
done | parallel -j ${NCORES} --joblog ${LOGPATH}/parallel_conefor_country_part1.log

## SORT THE RESULTS FILE FOR COUNTRY WITH TRANS BY ISO3 SKIPPING THE HEADER
## A NEW FILE IS CREATED AND THE ORIGINAL DELETED TO AVOID MESSING WITH THE FILES OF THE SECOND CYCLE
(head -n 1 "results_all_EC(PC).txt" && tail -n +2 "results_all_EC(PC).txt" | sort) > ${results_folder}/results_countries_EC_PC_with_trans.txt
cp ECAminmax_countries_with_trans.txt ${results_folder}/ECAminmax_countries_with_trans.txt
rm -f conefor2.7.3Linux
cd ..

enddate_cp1=`date +%s`
runtime_cp1=$(((enddate_cp1-startdate_cp1) / 60))

echo "------------------------------------------------------------------------------------"
echo "Connectivity analysis for country with trans performed in "${runtime_cp1}" minutes"
echo "------------------------------------------------------------------------------------"
exit
