#!/bin/bash
## PROTCONN: SCRIPT TO PERFORM CONNECTIVITY ANALYSIS AT COUNTRY LEVEL WITHOUT TRANSBOUNDARY ON SERVER WITH PARALLELIZATION

startdate_cp2=`date +%s`

##READ VARIABLES FROM CONFIGURATION FILE
SERVICEDIR="/globes/USERS/GIACOMO/protconn/scripts"
source ${SERVICEDIR}/protconn.conf

NCORES=48
((ALLCNT=$(ls ${cnt_without_trans}/nodes*|wc -l)+1))
((TILESIZE=(${ALLCNT}+(${NCORES}-1))/${NCORES}))

# CHANGE WORKING DIRECTORY
cd ${cnt_without_trans}

## PARALLEL CONEFOR CYCLE: RUN CONEFOR FOR COUNTRIES WITHOUT TRANS
echo "Now running Conefor at country level without transboundary in parallel..."
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
		echo "./conefor2.7.3Linux -nodeFile nodes_${iso3_suffix}_2019_WITHOUT_TRANS -conFile distances_${iso3_suffix}_2019_WITHOUT_TRANS -prefix ${iso3_suffix}_2019_WITHOUT_TRANS -t dist -confProb 10000 0.5 -PC -F -AWF onlyoverall"
	done
done | parallel -j ${NCORES} --joblog ${LOGPATH}/parallel_conefor_country_part2.log

## SORT THE RESULTS FILE FOR COUNTRY WITHOUT TRANS BY ISO3 SKIPPING THE HEADER
## A NEW FILE IS CREATED AND THE ORIGINAL DELETED
(head -n 1 "results_all_EC(PC).txt" && tail -n +2 "results_all_EC(PC).txt" | sort) >  ${results_folder}/results_countries_EC_PC_without_trans.txt
cp ECAminmax_countries_without_trans.txt ${results_folder}/ECAminmax_countries_without_trans.txt
rm -f conefor2.7.3Linux
cd ..

enddate_cp2=`date +%s`
runtime_cp2=$(((enddate_cp2-startdate_cp2) / 60))

echo "---------------------------------------------------------------------------------------"
echo "Connectivity analysis for country without trans performed in "${runtime_cp2}" minutes"
echo "---------------------------------------------------------------------------------------"
exit
