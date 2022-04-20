-- Protection Connectivity - Country with Bound Correction: GIS processing of WDPA AND gaul
-- Part I : prepare gaul

DROP TABLE IF EXISTS gaul_single_part;
CREATE TEMPORARY TABLE gaul_single_part AS
SELECT iso3,(ST_Dump(geom)).geom geom FROM administrative_units.gaul_eez WHERE source='gaul';

ALTER TABLE gaul_single_part
ADD COLUMN geom_was_invalid boolean DEFAULT FALSE;	

UPDATE gaul_single_part
SET geom_was_invalid = TRUE 
WHERE ST_IsValid(geom) IS FALSE;

UPDATE gaul_single_part
SET geom = ST_MakeValid(geom)
WHERE geom_was_invalid IS TRUE;

ALTER TABLE gaul_single_part
DROP COLUMN geom_was_invalid,
ADD COLUMN area_geo double precision;
UPDATE gaul_single_part
SET area_geo = (ST_AREA(geom::geography)/1000000);

DROP TABLE IF EXISTS ind_protconn.gaul_single_part_over1km_simpl;
CREATE TABLE ind_protconn.gaul_single_part_over1km_simpl AS
	(SELECT
	(ROW_NUMBER() OVER (ORDER BY iso3)+100000) AS nodeid,
	iso3,
	iso3 "ISO3final",
	ST_SimplifyPreserveTopology(geom,0.001) geom
	FROM gaul_single_part
	ORDER BY iso3);

ALTER TABLE ind_protconn.gaul_single_part_over1km_simpl
ADD COLUMN geom_was_invalid boolean DEFAULT FALSE;

UPDATE ind_protconn.gaul_single_part_over1km_simpl
SET geom_was_invalid = TRUE 
WHERE ST_IsValid(geom) IS FALSE;

UPDATE ind_protconn.gaul_single_part_over1km_simpl
SET geom = ST_MakeValid(geom)
WHERE geom_was_invalid IS TRUE;

ALTER TABLE ind_protconn.gaul_single_part_over1km_simpl
DROP COLUMN geom_was_invalid,
ADD COLUMN area_geo double precision;
UPDATE ind_protconn.gaul_single_part_over1km_simpl
SET area_geo = (ST_AREA(geom::geography)/1000000);

CREATE INDEX gaul_single_part_over1km_simpl_idx ON ind_protconn.gaul_single_part_over1km_simpl USING gist(geom);

-- Part II : Merge with wdpa_flat_1km_final
-- TO BE TESTED AND IMPLEMENTED, WAITING FOR wdpa_flat_1km2_final

DROP TABLE IF EXISTS ind_protconn.wdpa_plus_land_flat_1km2_final;
CREATE TABLE ind_protconn.wdpa_plus_land_flat_1km2_final AS
SELECT nodeid,"ISO3final",area_geo,geom FROM ind_protconn.gaul_single_part_over1km_simpl
UNION
SELECT nodeid,"ISO3final",area_geo,geom FROM ind_protconn.wdpa_flat_1km2_final;
CREATE INDEX wdpa_plus_land_flat_1km2_final_idx ON ind_protconn.wdpa_plus_land_flat_1km2_final USING gist(geom);


-- Part III : Generate Near Table (Can take several days...)
DROP TABLE IF EXISTS ind_protconn.all_distances_wdpa_plus_land_100km;
CREATE TABLE ind_protconn.all_distances_wdpa_plus_land_100km AS

WITH 
foo1 AS (SELECT nodeid "IN_FID", geom::geography as gg1 FROM ind_protconn.wdpa_plus_land_flat_1km2_final),
foo2 AS (SELECT nodeid "NEAR_FID", geom::geography as gg2 FROM ind_protconn.wdpa_plus_land_flat_1km2_final),

final AS (
SELECT DISTINCT
"IN_FID" "OBJECTID",
"IN_FID",
"NEAR_FID",
ST_Distance(gg1, gg2) AS "NEAR_DIST"
FROM foo1,foo2
WHERE ST_DWithin(gg1,gg2,100000, TRUE) --Here we set the maximum distance (100 km) for calculations
)

SELECT 
*,
row_number() over (PARTITION BY "IN_FID" ORDER BY "NEAR_DIST") as "NEAR_RANK"
FROM final
WHERE "NEAR_DIST">0
ORDER BY "IN_FID", "NEAR_RANK";




