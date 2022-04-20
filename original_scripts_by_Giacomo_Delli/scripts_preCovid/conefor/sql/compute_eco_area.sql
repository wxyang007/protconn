-- QUERY TO COMPUTE AREAS OF ECOREGIONS EXCLUDING ANTARCTICA FROM eco_id -9999
-- THIS TABLE IS REQUIRED BY PROTCONN IN THE FINAL POSTPROCESSING SCRIPT FOR ECOREGIONS

DROP TABLE IF EXISTS delli.eco_areas_without_antarctica;
CREATE TABLE delli.eco_areas_without_antarctica AS

WITH dumped AS (
SELECT DISTINCT
first_level_code,
first_level,
(ST_Dump(geom)).geom geom
FROM habitats_and_biotopes.ecoregions
WHERE source='teow' AND first_level_code=-9999
ORDER BY first_level_code),

single9999 AS (
SELECT 
*,
(ST_AREA(geom::geography)/1000000) area_geo
FROM dumped),

ordered AS (
SELECT 
*,
ROW_NUMBER() OVER (PARTITION BY first_level_code ORDER BY area_geo DESC) AS id
FROM single9999),

without_antartica AS (
SELECT DISTINCT first_level_code eco_id,SUM(area_geo) area_geo 
FROM ordered 
WHERE id>1
GROUP BY first_level_code
)

SELECT
first_level_code eco_id,
sqkm area_geo
FROM habitats_and_biotopes.ecoregions
WHERE source='teow' AND first_level_code != -9999
UNION
SELECT * FROM without_antartica
ORDER BY eco_id;
