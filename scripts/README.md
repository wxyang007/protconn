# Scripts HOW TO

## 1-3 Preprocessing.ipynb

### 1. Explanation of the script
- Step 1 merge PA files \
Input: pa files \
Output: PA_all (PA_mexcan_us) \
⬆️　This only needs to be done once.

- Step 2 read in and preprocess PA file \
Input: PA_all also PA_input —> PA_input_proj \
Output: PA_input_proj (PA_mexcan_us_proj) \
⬆️　This only needs to be done once.

- Step 3 preprocess region file and land file \
Input: **region_layer** + land_layer \
Output: **region_final** + land file \
⬆️　Region layers need to be processed separately but land file only needs to be processed once.


- Step 4 merge with land layer and set areas of land layer to 0 (the step for boundary correction) \
Input: land file + PA_input_proj \
Output: PA_land (PA_mexcanus_land_0713) \
⬆️　This only needs to be done once.


- Step 5 intersect merged PA with region file \
Input: PA_land + **region_final** \
Output: Dissolved_singleparted_over_1_km2 \
⬆️　Use result of step 4 and region file from step3.


- Step 6 create node and distance file \
Input: Dissolved_singleparted_over_1_km2 \
Output: PA_final —> node + distance file \
⬆️ Use result of step 5 to create inputs for near analysis & conefor analysis.


### 2. An example

E.g., county level analysis

Step 1: skip

Step 2: skip

**Step 3**: Customize how you would like to preprocess the region file. In the case of county level analysis, just buffer.

Step 4: skip

**Step 5**: use result of step 3 and step 4.

**Step 6**: no need to edit code.

Only bolded steps need to be run.

## 1-4 Analysis_Prepare_Region_PA.ipynb
### 1. Explanation of the script
What you need:
1. Result PA from the script 1-3
2. An excel file outlining the abbreviations of the regions.
3. To edit the script.
