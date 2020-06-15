DROP TABLE IF EXISTS delli.iso3_areas;
CREATE TABLE delli.iso3_areas AS

SELECT DISTINCT 
iso3,
SUM(sqkm) area_geo
FROM administrative_units.gaul_eez
WHERE source='gaul' and iso3 NOT LIKE '%|%'
GROUP BY iso3
ORDER BY iso3;
