# Scripts HOW TO

## 1-3 Preprocessing.ipynb notes

Step 1 merge PA files
Input: pa files
Output: PA_all (PA_mexcan_us)

Step 2 read in and preprocess PA file
Input: PA_all also PA_input —> PA_input_proj
Output: PA_input_proj (PA_mexcan_us_proj)

Step 3 preprocess region file and land file
Input: region_layer + land_layer
Output: region_final + land file

Step 4 merge with land layer and set areas of land layer to 0 (the step for boundary correction)
Input: land file + PA_input_proj
Output: PA_land

Step 5 intersect merged PA with region file
Input: PA_land + region_final
