#!/bin/bash
## PROTCONN: SCRIPT TO PERFORM CONNECTIVITY ANALYSIS AT ECOREGION LEVEL ON SERVER WITH PARALLELIZATION

startdate_ep1=`date +%s`

# READ VARIABLES FROM CONFIGURATION FILE
SERVICEDIR="/globes/USERS/GIACOMO/protconn/scripts"
source ${SERVICEDIR}/protconn.conf

NCORES=48
((ALLCNT=$(ls ${eco_with_trans}/nodes*|wc -l)+1))
((TILESIZE=(${ALLCNT}+(${NCORES}-1))/${NCORES}))

# CHANGE WORKING DIRECTORY
cd ${eco_with_trans}

## PARALLEL CONEFOR CYCLE: RUN CONEFOR FOR ECOREGIONS WITH TRANS
for TIL in $(for i in $(eval echo {0..$NCORES}); do ((start=${TILESIZE}*$i)); echo -n $start" "; done)
	do
	for PA in $(ls |grep "nodes"|awk "NR >= (${TIL}+1) && NR <= (${TIL}+${TILESIZE})")
	do 
		eco_idcode=${PA:6:5}
		eco_suffix="${PA:6:5}"
		echo "./conefor2.7.3Linux -nodeFile nodes_${eco_idcode}_2019 -conFile distances_${eco_idcode}_2019 -prefix "${eco_suffix}"_2019 -t dist -confProb 10000 0.5 -PC -F -AWF onlyoverall"
	done
done | parallel -j ${NCORES} --joblog ${LOGPATH}/parallel_conefor_eco_part1.log

## SORT THE RESULTS FILE FOR ECOREGIONS WITH TRANS BY ISO3 SKIPPING THE HEADER
## A NEW FILE IS CREATED AND THE ORIGINAL DELETED TO AVOID MESSING WITH THE FILES OF THE SECOND CYCLE
(head -n 1 "results_all_EC(PC).txt" && tail -n +2 "results_all_EC(PC).txt" | sort) > ${results_folder}/results_ecoregion_with_trans.txt
awk '!a[$0]++' ${results_folder}/results_ecoregion_with_trans.txt > ${results_folder}/tmp && mv ${results_folder}/tmp ${results_folder}/results_ecoregion_with_trans.txt
cp ECAminmax_ecoregions_with_trans.txt ${results_folder}/ECAminmax_ecoregions_with_trans.txt
rm -f conefor2.7.3Linux
cd ..

enddate_ep1=`date +%s`
runtime_ep1=$(((enddate_ep1-startdate_ep1) / 60))

echo "-------------------------------------------------------------------------------------"
echo "Connectivity analysis for ecoregions with trans performed in "${runtime_ep1}" minutes"
echo "-------------------------------------------------------------------------------------"
exit
