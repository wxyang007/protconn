#!/bin/bash
## PROTCONN: SCRIPT TO PERFORM CONNECTIVITY ANALYSIS AT ECOREGION LEVEL ON SERVER WITH PARALLELIZATION

echo "-----------------------------------------------------------------------------------"
echo "--- Script $(basename "$0") started at $(date)"
echo "-----------------------------------------------------------------------------------"

startdate_ep2=`date +%s`

# READ VARIABLES FROM CONFIGURATION FILE
BASEDIR="/globes/USERS/GIACOMO/protconn/scripts"
source ${BASEDIR}/protconn.conf

NCORES=48
((ALLCNT=$(ls ${eco_with_trans}/nodes*|wc -l)+1))
((TILESIZE=(${ALLCNT}+(${NCORES}-1))/${NCORES}))

# CHANGE WORKING DIRECTORY
cd ${eco_without_trans}

## PARALLEL CONEFOR CYCLE: RUN CONEFOR FOR ECOREGIONS WITHOUT TRANS
for TIL in $(for i in $(eval echo {0..$NCORES}); do ((start=${TILESIZE}*$i)); echo -n $start" "; done)
	do
	for PA in $(ls |grep "nodes"|awk "NR >= (${TIL}+1) && NR <= (${TIL}+${TILESIZE})")
	do
		eco_idcode=${PA:6:5}
		eco_suffix="${PA:6:5}"
		echo "./conefor2.7.3Linux -nodeFile nodes_${eco_idcode}_${yearsuffix}_WITHOUT_TRANS -conFile distances_${eco_idcode}_${yearsuffix}_WITHOUT_TRANS -prefix "${eco_suffix}"_${yearsuffix}_WITHOUT_TRANS -t dist -confProb 10000 0.5 -PC -F -AWF onlyoverall"
	done
done | parallel -j ${NCORES} --joblog ${LOGPATH}/parallel_conefor_eco_part2.log

## SORT THE RESULTS FILE FOR ECOREGIONS WITHOUT TRANS BY ISO3 SKIPPING THE HEADER
## A NEW FILE IS CREATED AND THE ORIGINAL DELETED TO AVOID MESSING WITH THE FILES OF THE SECOND CYCLE
cp "results_all_EC(PC).txt" ${results_folder}"/results_ec2_all_EC(PC).txt"
(head -n 1 ${results_folder}"/results_ec2_all_EC(PC).txt" && tail -n +2 ${results_folder}"/results_ec2_all_EC(PC).txt"|grep "Prefix" -v | sort) > ${results_folder}/results_ecoregion_without_trans.txt
awk '!a[$0]++' ${results_folder}/results_ecoregion_without_trans.txt > ${results_folder}/tmp && mv ${results_folder}/tmp ${results_folder}/results_ecoregion_without_trans.txt
cp ECAminmax_ecoregions_without_trans.txt ${results_folder}/ECAminmax_ecoregions_without_trans.txt
rm -f conefor2.7.3Linux
cd ..

enddate_ep2=`date +%s`
runtime_ep2=$(((enddate_ep2-startdate_ep2) / 60))

echo "-----------------------------------------------------------------------------------"
echo "Script $(basename "$0") ended at $(date)"
echo "-----------------------------------------------------------------------------------"
echo "Connectivity analysis for ecoregions without trans performed in "${runtime_ep2}" minutes"
echo "-----------------------------------------------------------------------------------"
exit
