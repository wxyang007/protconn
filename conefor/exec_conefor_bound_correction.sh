#!/bin/bash
## PROTCONN: SCRIPT TO PERFORM CONNECTIVITY ANALYSIS FOR BOUND CORRECTION ON SERVER WITH PARALLELIZATION

echo "-----------------------------------------------------------------------------------"
echo "--- Script $(basename "$0") started at $(date)"
echo "-----------------------------------------------------------------------------------"

startdate_bc=`date +%s`

# READ VARIABLES FROM CONFIGURATION FILE
BASEDIR="/globes/USERS/GIACOMO/protconn/scripts"
source ${BASEDIR}/protconn.conf

## PARALLEL CONEFOR CYCLE: RUN CONEFOR FOR COUNTRIES WITH TRANS
echo "Now running Conefor for bound correction  in parallel..."
NCORES=42
((ALLCNT=$(ls ${bound_corr}/nodes*|wc -l)+1))
((TILESIZE=(${ALLCNT}+(${NCORES}-1))/${NCORES}))

cd ${bound_corr}

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
		echo "./conefor2.7.3Linux -nodeFile nodes_${iso3_suffix}_${yearsuffix} -conFile distances_${iso3_suffix}_${yearsuffix} -prefix "${iso3_suffix}"_${yearsuffix} -t dist -confProb 10000 0.5 -PC -F -AWF onlyoverall"
	done
done | parallel -j ${NCORES} --joblog ${LOGPATH}/parallel_conefor_boundcorr.log

## SORT THE RESULTS FILE FOR BOUND CORRECTION BY ISO3 SKIPPING THE HEADER
## A NEW FILE IS CREATED AND THE ORIGINAL DELETED TO AVOID MESSING WITH THE OTHER RESULTS FILES
cp "results_all_EC(PC).txt" ${results_folder}"/results_bc_all_EC(PC).txt"
(head -n 1 ${results_folder}"/results_bc_all_EC(PC).txt" && tail -n +2 ${results_folder}"/results_bc_all_EC(PC).txt"|grep "Prefix" -v | sort) > ${results_folder}/results_all_EC_PC_boundcorr.txt
awk '!a[$0]++' ${results_folder}/results_all_EC_PC_boundcorr.txt > ${results_folder}/tmp && mv ${results_folder}/tmp ${results_folder}/results_all_EC_PC_boundcorr.txt
cp ECAminmax_bound_corr.txt ${results_folder}/ECAminmax_bound_corr.txt
rm -f conefor2.7.3Linux
cd ..

enddate_bc=`date +%s`
runtime_bc=$(((enddate_bc-startdate_bc) / 60))

echo "-----------------------------------------------------------------------------------"
echo "Script $(basename "$0") ended at $(date)"
echo "-----------------------------------------------------------------------------------"
echo "Connectivity analysis for bound correction performed in "${runtime_bc}" minutes"
echo "-----------------------------------------------------------------------------------"

exit
