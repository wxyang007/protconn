## ##Loading required package: iterators

###### WE SET ALL LOCAL VARIABLES
args <- commandArgs()

print("THIS IS JUST TO TRY IF A R SCRIPT RUNS FROM BASH")
name <- args[6]
print(name)
root_folder <- "/globes/USERS/GIACOMO/protconn/R_scripts"
node_dist_files_300_km_folder <- "/globes/USERS/GIACOMO/protconn/R_scripts/node_dist_files_300_KM"
node_dist_files_without_trans_300_km_folder <- "/globes/USERS/GIACOMO/protconn/R_scripts/node_dist_files_WITHOUT_TRANS_300_KM"

setwd(node_dist_files_300_km_folder)
nnn <-list.files(pattern="nodes_BL*")

print(nnn)

## END

