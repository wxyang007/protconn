import arcpy
import os
from datetime import datetime

shp_folder = r"C:\Users\wyang80\Desktop\ProtConn\data\REGION_PA\COUNTIES"
txt_folder = r"C:\Users\wyang80\Desktop\ProtConn\data\REGION_PA\COUNTIES"
out_folder = r"C:\Users\wyang80\Desktop\ProtConn\data\REGION_PA\COUNTIES\Neartab_Out"
outgdb = 'neartab.gdb'

if not os.path.exists(out_folder):
    os.mkdir(out_folder)
if not arcpy.Exists(os.path.join(out_folder, outgdb)):
    arcpy.CreateFileGDB_management(out_folder, outgdb)

name_shp = [f for f in os.listdir(shp_folder) if f.endswith('.shp')]

for n in name_shp:
    prefix_name = n.split(".")[0]
    path_shp = os.path.join(shp_folder, n)
    path_txt = os.path.join(txt_folder, prefix_name + '.txt')
    outfile = os.path.join(out_folder, outgdb, 'Near_tab_' + prefix_name)
    if arcpy.Exists(outfile):
        pass
    else:
        time0 = time.time()
        arcpy.GenerateNearTable_analysis(path_shp, path_shp,
                                     outfile,
                                     "230 Kilometers",
                                     "NO_LOCATION",
                                     "NO_ANGLE",
                                     "ALL",
                                     "",
                                     "GEODESIC")
        time1 = time.time()
        totaltime = (time1-time0)/60
        print(n + ' done, time lapsed: ' +  "{:.2f}".format(totaltime))
    print(outfile)
