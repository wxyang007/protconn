# Workflow for computation of Protection Connectivity

## Introduction

The whole workflow for the computation of Protection Connectivity (hereinafter referred to as ProtConn) has been developed reproducing step by step the procedure described by Santiago Saura as per his handover of June 2019. It consists of 3 steps:

1. GIS processing: spatial data processing and computation of distances tables
2. ProtConn analysis in Conefor: processing of distances tables and computation of ProtConn
3. Post-processing of ProtConn data: postprocessing of outputs from Conefor.

Presently the GIS processing step uses a mix of arcypython (ESRI Arcgis license required) and bash/psql tools.

**TBD**: removing the the arcpython component. The main constraint in removing this component is the 'dissolve' features step, not successfully implementable (until now) in Postgis.

**ProtConn analysis** and **Post-processing** steps are entirely run in bash/psql environment. A [master script](conefor/exec_full_conefor_master.sh) calls in sequence all the subscripts required to perform both steps 2 and 3.

Conefor with command line interface is required. Here, [version 2.7.3](http://www.conefor.org/files/usuarios/Conefor_command_line.zip) is used.

Input data used are for computation of ProtConn are:

  - WDPA (latest gdb file downloaded from [protectedplanet.net](https://www.protectedplanet.n))
  - Global Administrative Unit Layers (GAUL), revision 2015 (2017-02-02). The layer must exists in the working gdb befor running scripts.
  - Terrestrial Ecoregions of the World (Olson et al., 2001). The layer must exists in the working gdb befor running scripts
  
**TBD**: 1. Prepare a script for  - GDB creation and 
                                  - copy of required layers (gaul and ecoregions) from DB

### 1. GIS processing

Scripts have been developed and extensively tested for each of the three aggregation levels of ProtConn, i.e. country, country with bound correction and ecoregion.
For each level, the scripts described below need to be executed sequentially.

All variables of bash scripts are controlled by the configuration file [protconn.conf](protconn.conf).

The variables for arcpython scripts are declared at the beginning of each script.

**TBD**: prepare an external file with variables and import in python at start.



**a) Country level**

1. [a1country.py](gis_proc/arcpy/a1country.py)
   - Import polygons and points, bufferize points, merge poly and points.
  
2. [exec_simplify_wdpa_all_relevant.sh](gis_proc/exec_simplify_wdpa_all_relevant.sh)
   - Import wdpa from dgb in Postgis, simplify polygons, export to shp.
  
3. [a2country.py](gis_proc/arcpy/a2country.py)
   - Import shp, process multi iso3 polygons, prepare wdpa flat final, ready for calculation of distances in PostGis (ST_distance)
   - Generate near table (much slower than the same operation in postgis, presently is commented and not executed).
  
4. [exec_generate_near_table_country.sh](gis_proc/exec_generate_near_table_country.sh)
   - Import wdpa from gdb, repair geometries and compute Near Table in Postgis for countries.

Overall processing time is approximately 25 hours (4 hours for steps 1-3, 21 hours for step 4)



**b) Country level with bound correction**

1. [b1country_boundcorr.py](gis_proc/arcpy/b1country_boundcorr.py)
   - Convert GAUL to single part, repair geometries, compute area_geo.
   
2. [exec_simplify_gaul_bound_correction.sh](gis_proc/exec_simplify_gaul_bound_correction.sh)
   - Import gaul single part with area_geo>=1km2 from gdb in Postgis, simplify polygons, export to shp.
   

**TBD**: replace processing of [b1country_boundcorr.py](gis_proc/arcpy/b1country_boundcorr.py) with its equivalent in postgis.

3. [b2country_boundcorr.py](gis_proc/arcpy/b2country_boundcorr.py)
   - Import shp, add and compute required fields, merge gaul and wdpa, repair geometries, export attributes
   - Generate near table (much faster than the same operation in postgis, described below at point 4).

4. [exec_generate_near_table_country_boundcorr.sh](gis_proc/exec_generate_near_table_country_boundcorr.sh)
   - Import relevant layer from gdb, repair geometries and compute Near Table in Postgis for countries with bound correction (about four times slower than the same operation in arcpy. Its use is deprecated).
   
**c) Ecoregion level**

1. [c1ecoregion.py](gis_proc/arcpy/c1ecoregion.py)
   - Select terrestrial ecoregions, dissolve WDPA, intersect it with ecoregions, select polygons over 1km2, add and compute required fields, export attributes
   - Generate near table (much slower than the same operation in postgis, presently is commented and not executed).
   
4. [exec_generate_near_table_ecoregion.sh] (gis_proc/exec_generate_near_table_ecoregion.sh)
   - Import relevant layer from gdb, repair geometries and compute Near Table in Postgis for ecoregions.
   
  
  
