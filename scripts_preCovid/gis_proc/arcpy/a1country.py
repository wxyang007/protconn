# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# a1country_draft.py
# Created on: 2019-10-29 09:14:57.00000
#   (generated by ArcGIS/ModelBuilder)
# Description: GIS processing for Country-ProtCoon (part 1#2)
# ---------------------------------------------------------------------------

# Import arcpy module
import sys
import arcpy
from arcpy import env
import os
import os.path

from datetime import datetime
firststarttime=datetime.now()

print(" ")
print("PROCEDURE STARTED at ", datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
print('-------------------------------------------------------')

# Set environment variables
arcpy.env.overwriteOutput = True

# Local variables:
# Input layers
WDPA_poly_Oct2019 = "Y:/Original_Datasets/WDPA/uncompressed/WDPA_Mar2020_Public.gdb/WDPA_poly_Mar2020"
WDPA_point_Oct2019 = "Y:/Original_Datasets/WDPA/uncompressed/WDPA_Mar2020_Public.gdb/WDPA_point_Mar2020"

# Output Geodatabase

outgdb = "Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/"

# Output layers
WDPA_poly_relevant = outgdb+"WDPA_poly_relevant"
WDPA_point_relevant = outgdb+"WDPA_point_relevant"
WDPA_point_relevant_Layer_LYR = "WDPA_point_relevant_Layer"
WDPA_point_relevant_with_joined_count_multiparts = WDPA_point_relevant_Layer_LYR
WDPA_point_relevant_singleparted = outgdb+"WDPA_point_relevant_singleparted"
sum_cte = outgdb+"sum_cte"
WDPA_point_relevant_with_joined_count_multiparts_buffered = outgdb+"WDPA_point_relevant_with_joined_count_multiparts_buffered"
WDPA_all_relevant = outgdb+"WDPA_all_relevant"
wdpa_for_protconn_gpkg = "Z:/globes/USERS/GIACOMO/protconn/data/wdpa_for_protconn.gpkg"

# Process: Select relevant polygons
arcpy.Select_analysis(WDPA_poly_Oct2019, WDPA_poly_relevant, "STATUS <> 'Proposed' AND STATUS <> 'Not Reported' AND DESIG_ENG <> 'UNESCO-MAB Biosphere Reserve'")

# Process: Select relevant points
arcpy.Select_analysis(WDPA_point_Oct2019, WDPA_point_relevant, "STATUS <> 'Proposed' AND STATUS <> 'Not Reported' AND DESIG_ENG <> 'UNESCO-MAB Biosphere Reserve' AND REP_AREA >0")
print("Relevant points and polygons selected")
      
# Process: Add Field Areapart
arcpy.AddField_management(WDPA_point_relevant, "Areapart", "FLOAT", "", "", "", "", "NULLABLE", "NON_REQUIRED", "")

# Process: Make Feature Layer
arcpy.MakeFeatureLayer_management(WDPA_point_relevant, WDPA_point_relevant_Layer_LYR, "", "", "OBJECTID OBJECTID VISIBLE NONE;Shape Shape VISIBLE NONE;WDPAID WDPAID VISIBLE NONE;WDPA_PID WDPA_PID VISIBLE NONE;PA_DEF PA_DEF VISIBLE NONE;NAME NAME VISIBLE NONE;ORIG_NAME ORIG_NAME VISIBLE NONE;DESIG DESIG VISIBLE NONE;DESIG_ENG DESIG_ENG VISIBLE NONE;DESIG_TYPE DESIG_TYPE VISIBLE NONE;IUCN_CAT IUCN_CAT VISIBLE NONE;INT_CRIT INT_CRIT VISIBLE NONE;MARINE MARINE VISIBLE NONE;REP_M_AREA REP_M_AREA VISIBLE NONE;REP_AREA REP_AREA VISIBLE NONE;NO_TAKE NO_TAKE VISIBLE NONE;NO_TK_AREA NO_TK_AREA VISIBLE NONE;STATUS STATUS VISIBLE NONE;STATUS_YR STATUS_YR VISIBLE NONE;GOV_TYPE GOV_TYPE VISIBLE NONE;OWN_TYPE OWN_TYPE VISIBLE NONE;MANG_AUTH MANG_AUTH VISIBLE NONE;MANG_PLAN MANG_PLAN VISIBLE NONE;VERIF VERIF VISIBLE NONE;METADATAID METADATAID VISIBLE NONE;SUB_LOC SUB_LOC VISIBLE NONE;PARENT_ISO3 PARENT_ISO3 VISIBLE NONE;ISO3 ISO3 VISIBLE NONE;RESTRICT RESTRICT VISIBLE NONE;Areapart Areapart VISIBLE NONE")

# Process: Multipart To Singlepart
arcpy.MultipartToSinglepart_management(WDPA_point_relevant, WDPA_point_relevant_singleparted)

# Process: Summary Statistics
arcpy.Statistics_analysis(WDPA_point_relevant_singleparted, sum_cte, "WDPAID COUNT", "WDPAID")

# Process: Add Join
arcpy.AddJoin_management(WDPA_point_relevant_Layer_LYR, "WDPAID", sum_cte, "WDPAID", "KEEP_ALL")

# Process: Calculate Field Areapart
arcpy.CalculateField_management(WDPA_point_relevant_with_joined_count_multiparts, "Areapart", "!WDPA_point_relevant.REP_AREA! / !sum_cte.FREQUENCY!", "PYTHON_9.3", "")

# Process: Remove Join
arcpy.RemoveJoin_management(WDPA_point_relevant_with_joined_count_multiparts, "sum_cte")

# Process: Add Field radius_m
arcpy.AddField_management(WDPA_point_relevant_with_joined_count_multiparts, "radius_m", "FLOAT", "", "", "", "", "NULLABLE", "NON_REQUIRED", "")

# Process: Calculate Field
arcpy.CalculateField_management(WDPA_point_relevant_with_joined_count_multiparts, "radius_m", "math.sqrt( !Areapart!*1000000/math.pi )", "PYTHON_9.3", "")

# Process: Buffer
arcpy.Buffer_analysis(WDPA_point_relevant, WDPA_point_relevant_with_joined_count_multiparts_buffered, "radius_m", "FULL", "ROUND", "NONE", "", "PLANAR")
print("Points bufferized")

# Process: Merge
arcpy.Merge_management("Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/WDPA_poly_relevant;Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/WDPA_point_relevant_with_joined_count_multiparts_buffered", WDPA_all_relevant, "WDPAID \"WDPAID\" true true false 8 Double 0 0 ,First,#,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/WDPA_poly_relevant,WDPAID,-1,-1,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/WDPA_point_relevant_with_joined_count_multiparts_buffered,WDPAID,-1,-1;ISO3 \"ISO3\" true true false 50 Text 0 0 ,First,#,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/WDPA_poly_relevant,ISO3,-1,-1,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/WDPA_point_relevant_with_joined_count_multiparts_buffered,ISO3,-1,-1")
print("Points and polygons merged")

# Process: Repair Geometry
arcpy.RepairGeometry_management(WDPA_all_relevant, "DELETE_NULL")
print("Geometries repaired")

# Process: Create SQLite Database
if arcpy.Exists(wdpa_for_protconn_gpkg):
	print(wdpa_for_protconn_gpkg, " already exists.")
else:
	arcpy.CreateSQLiteDatabase_management(wdpa_for_protconn_gpkg, "GEOPACKAGE")

# Process: Feature Class to Feature Class
arcpy.FeatureClassToFeatureClass_conversion(WDPA_all_relevant, wdpa_for_protconn_gpkg, "wdpa_all_relevant")
print("Features exported in Geopackage")

print('-------------------------------------------------------')
endtime=datetime.now()
totaltime= endtime-firststarttime
print(' ')
print('PROCEDURE COMPLETED. Elapsed time: ', totaltime)
print('Now execute in docker the script "/globes/USERS/GIACOMO/protconn/scripts/gis_proc/exec_simplify_wdpa_all_relevant.sh" ')
print(' ')

sys.exit()
