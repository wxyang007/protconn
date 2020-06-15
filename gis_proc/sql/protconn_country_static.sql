-- Protection Connectivity - Country: GIS processing of WDPA
-- Part I : Simplify and repair geometries

DROP TABLE IF EXISTS ind_protconn.wdpa_all_relevant_simpl;
CREATE TABLE ind_protconn.wdpa_all_relevant_simpl AS
SELECT
wdpaid,
iso3,
ST_SimplifyPreserveTopology(geom,0.001) geom
FROM ind_protconn.wdpa_all_relevant
ORDER BY wdpaid;

ALTER TABLE ind_protconn.wdpa_all_relevant_simpl
ADD COLUMN geom_was_invalid boolean DEFAULT FALSE;

UPDATE ind_protconn.wdpa_all_relevant_simpl
SET geom_was_invalid = TRUE 
WHERE ST_IsValid(geom) IS FALSE;

UPDATE ind_protconn.wdpa_all_relevant_simpl
SET geom = ST_MakeValid(geom)
WHERE geom_was_invalid IS TRUE;

ALTER TABLE ind_protconn.wdpa_all_relevant_simpl
DROP COLUMN geom_was_invalid,
ADD COLUMN area_geo double precision;
UPDATE ind_protconn.wdpa_all_relevant_simpl
SET area_geo = (ST_AREA(geom::geography)/1000000);

CREATE INDEX wdpa_all_relevant_simpl_idx ON ind_protconn.wdpa_all_relevant_simpl USING gist(geom);

-- Part II : Dissolve features by iso3

DROP TABLE IF EXISTS ind_protconn.dissolved_iso;
CREATE TABLE ind_protconn.dissolved_iso AS
(SELECT 
iso3,
(ST_Dump( ST_Union(geom))).geom geom
FROM ind_protconn.wdpa_all_relevant_simpl
GROUP BY iso3);

ALTER TABLE ind_protconn.dissolved_iso
ADD COLUMN geom_was_invalid boolean DEFAULT FALSE;	

UPDATE ind_protconn.dissolved_iso
SET geom_was_invalid = TRUE 
WHERE ST_IsValid(geom) IS FALSE;

UPDATE ind_protconn.dissolved_iso
SET geom = ST_MakeValid(geom)
WHERE geom_was_invalid IS TRUE;

ALTER TABLE ind_protconn.dissolved_iso
DROP COLUMN geom_was_invalid,
ADD COLUMN area_geo double precision;
UPDATE ind_protconn.dissolved_iso
SET area_geo = (ST_AREA(geom::geography)/1000000);

CREATE INDEX dissolved_iso_idx ON ind_protconn.dissolved_iso USING gist(geom);


-- Part III : Process multi-iso3 polygons using gaul

CREATE TEMPORARY TABLE tclipped_iso AS 
SELECT * FROM
	(SELECT
    dissolved_iso.iso3,
    (ST_Intersection(dissolved_iso.geom, gaul.geom)) geom
    FROM ind_protconn.dissolved_iso 
	INNER JOIN (SELECT iso3,geom FROM administrative_units.gaul_eez WHERE source='gaul') gaul 
	ON ST_Intersects(dissolved_iso.geom, gaul.geom)) clipgaul
;

CREATE TEMPORARY TABLE intersected_iso_multi_iso3 AS
WITH
clipped_iso_no_multi_iso3 AS 
	(SELECT * FROM 
	 	(SELECT iso3,iso3 my_iso3,(ST_Dump(geom)).* 
		 FROM tclipped_iso 
		 WHERE iso3 NOT LIKE '%;%' AND ST_area(geom::geography)>1000000) a
	),
clipped_iso_multi_iso3 AS 
	(SELECT * FROM 
	 	(SELECT iso3,iso3 my_iso3,(ST_Dump(geom)).*  
		 FROM tclipped_iso WHERE iso3 LIKE '%;%' AND ST_area(geom::geography)>1000000) a)
SELECT a.iso3,b.iso3 giso3,ST_INTERSECTION(a.geom,b.geom) geom
FROM clipped_iso_multi_iso3 a
JOIN administrative_units.gaul_eez b ON ST_INTERSECTS(a.geom,b.geom)
WHERE b.source='gaul' AND b.iso3 IN (SELECT DISTINCT UNNEST(STRING_TO_ARRAY(iso3,';')) FROM clipped_iso_multi_iso3);

CREATE TEMPORARY TABLE dissolved_iso3 AS
WITH
clipped_iso_no_multi_iso3 AS 
	(SELECT * FROM 
	 	(SELECT iso3,iso3 my_iso3,(ST_Dump(geom)).* 
		 FROM tclipped_iso 
		 WHERE iso3 NOT LIKE '%;%' AND ST_area(geom::geography)>1000000) a
	)
	
SELECT "ISO3final",(ST_Dump(ST_UNION(geom))).geom geom FROM 
	(SELECT giso3 "ISO3final",geom FROM intersected_iso_multi_iso3
	UNION
	SELECT iso3 "ISO3final",geom FROM clipped_iso_no_multi_iso3
	) a
GROUP BY "ISO3final";

DROP TABLE IF EXISTS ind_protconn.wdpa_flat_1km2_final;
CREATE TABLE ind_protconn.wdpa_flat_1km2_final AS
	SELECT
	ROW_NUMBER() OVER (ORDER BY "ISO3final") AS nodeid,
	* 
	FROM 
		(SELECT "ISO3final",geom 
		FROM dissolved_iso3 ORDER BY "ISO3final") a 
	WHERE ST_GEOMETRYTYPE(geom) = 'ST_Polygon';

ALTER TABLE ind_protconn.wdpa_flat_1km2_final
ADD COLUMN geom_was_invalid boolean DEFAULT FALSE;

UPDATE ind_protconn.wdpa_flat_1km2_final
SET geom_was_invalid = TRUE 
WHERE ST_IsValid(geom) IS FALSE;

UPDATE ind_protconn.wdpa_flat_1km2_final
SET geom = ST_MakeValid(geom)
WHERE geom_was_invalid IS TRUE;

ALTER TABLE ind_protconn.wdpa_flat_1km2_final
DROP COLUMN geom_was_invalid,
ADD COLUMN area_geo double precision;
UPDATE ind_protconn.wdpa_flat_1km2_final
SET area_geo = (ST_AREA(geom::geography)/1000000);
CREATE INDEX wdpa_flat_1km2_final_idx ON ind_protconn.wdpa_flat_1km2_final USING gist(geom);


-- Part IV : Generate Near Table (Can take several days...)

DROP TABLE IF EXISTS ind_protconn.all_distances_300km;
CREATE TABLE ind_protconn.all_distances_300km AS

WITH 
foo1 AS (SELECT nodeid "IN_FID", geom::geography as gg1 FROM ind_protconn.wdpa_flat_1km2_final),
foo2 AS (SELECT nodeid "NEAR_FID", geom::geography as gg2 FROM ind_protconn.wdpa_flat_1km2_final),

final AS (
SELECT DISTINCT
"IN_FID" "OBJECTID",
"IN_FID",
"NEAR_FID",
ST_Distance(gg1, gg2) AS "NEAR_DIST"
FROM foo1,foo2
WHERE ST_DWithin(gg1,gg2,300000, TRUE) --Here we set the maximum distance (300 km) for calculations
)

SELECT 
*,
row_number() over (PARTITION BY "IN_FID" ORDER BY "NEAR_DIST") as "NEAR_RANK"
FROM final
WHERE "NEAR_DIST">0
ORDER BY "IN_FID", "NEAR_RANK";

