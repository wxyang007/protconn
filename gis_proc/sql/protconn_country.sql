-- Protection Connectivity: GIS processing of WDPA
-- Part I : preparing wdpa_all_relevant dataset

CREATE TABLE :vSCHEMA.wdpa_all_relevant AS

WITH
polygons AS 
	(SELECT
	CAST(WDPAID AS integer) as wdpaid,
	COUNT(WDPAID) AS parcels,
	'Polygon' AS type,
	iso3,
	ST_UNION(wkb_geometry) AS geom
	FROM :WDPASCHEMA.:vINNAME_POLY
	WHERE
	WDPAID IN (
	SELECT WDPAID
	FROM :WDPASCHEMA.:vINNAME_POLY
	WHERE STATUS NOT IN ('Not Reported', 'Proposed')
	AND
	DESIG_ENG NOT IN ('UNESCO-MAB Biosphere Reserve')
	GROUP BY WDPAID
	HAVING COUNT(WDPAID) > 1
	)
	AND WDPAID IN (SELECT wdpaid FROM delli.wdpa_all_relevant) -- ADDED ONLY TO TEST THE SCRIPT ON A SMALL SAMPLE
	GROUP BY WDPAID,iso3
	UNION
	SELECT
	CAST(WDPAID AS integer) as wdpaid,
	CAST('1' AS integer) AS parcels,
	'Polygon' AS type,
	iso3,
	wkb_geometry AS geom
	FROM :WDPASCHEMA.:vINNAME_POLY
	WHERE
	WDPAID IN (
	SELECT WDPAID
	FROM :WDPASCHEMA.:vINNAME_POLY
	WHERE STATUS NOT IN ('Not Reported', 'Proposed')
	AND
	DESIG_ENG NOT IN ('UNESCO-MAB Biosphere Reserve')
	GROUP BY WDPAID
	HAVING COUNT(WDPAID) = 1)
	AND WDPAID IN (SELECT wdpaid FROM delli.wdpa_all_relevant) -- ADDED ONLY TO TEST THE SCRIPT ON A SMALL SAMPLE
	),
points AS 
	(SELECT
	CAST(WDPAID AS integer) as wdpaid,
	'Point' AS type,
	iso3,
	REP_AREA AS rep_areas,
	wkb_geometry AS geom
	FROM :WDPASCHEMA.:vINNAME_POINT
	WHERE
	WDPAID IN (
	SELECT WDPAID
	FROM :WDPASCHEMA.:vINNAME_POINT
	WHERE STATUS NOT IN ('Not Reported', 'Proposed')
	AND
	DESIG_ENG NOT IN ('UNESCO-MAB Biosphere Reserve')
	AND
	REP_AREA > 0)
	AND WDPAID IN (SELECT wdpaid FROM delli.wdpa_all_relevant) -- ADDED ONLY TO TEST THE SCRIPT ON A SMALL SAMPLE
	),
non_intersecting_points AS 
	(SELECT
	a.wdpaid,
	a.type,
	a.iso3,
	b.parcels,
	(ST_Buffer(a.geom::geography(MultiPoint),b.radius*1000))::geometry(Polygon) as geom  -- modified on :vDATE25
	FROM points a
	JOIN (
		SELECT
		wdpaid,
		COUNT(wdpaid)::integer AS parcels,
		iso3,
		sqrt(
			(rep_areas/(COUNT(wdpaid)::integer))/pi()
		) as radius
		FROM points
		GROUP BY wdpaid,rep_areas,iso3
		) b on a.wdpaid=b.wdpaid
		WHERE ST_INTERSECTS((ST_Buffer(a.geom::geography(MultiPoint),b.radius*1000)), ST_GeogFromText('LINESTRING(180 -90, 180 0, 180 90)')) IS false  -- modified on :vDATE25
		),
points_output_1 AS 
	(SELECT
	wdpaid,
	type,
	iso3,
	parcels,
	ST_MULTI(ST_Union(geom)) as geom
	FROM non_intersecting_points
	GROUP BY wdpaid,type,iso3,parcels),
intersecting_points AS 
	(SELECT
	a.wdpaid,
	a.type,
	a.iso3,
	b.parcels,
	ST_Split(((ST_Buffer(ST_Translate(a.geom, +180, 0)::geography(MultiPoint),b.radius*1000))::geometry(Polygon)), ST_GeomFromText('LINESTRING(0 -90, 0 90)',4326)) as geom  -- modified on :vDATE25
	FROM points a
	JOIN (
		SELECT
		wdpaid,
		COUNT(wdpaid)::integer AS parcels,
		iso3,
		sqrt(
			(rep_areas/(COUNT(wdpaid)::integer))/pi()
		) as radius
		FROM points
		GROUP BY wdpaid,rep_areas,iso3
		) b on a.wdpaid=b.wdpaid
	WHERE a.wdpaid NOT IN (SELECT wdpaid FROM points_output_1)),

reshifted_points AS 
	(SELECT
	wdpaid,
	type,
	iso3,
	parcels,
	id,
	CASE WHEN ST_XMAX(geom) > 0
	THEN
		ST_Translate(geom, -180, 0)
	ELSE
		ST_Translate(geom, 180, 0)
	END AS geom
	FROM
		(SELECT wdpaid, type, iso3, parcels, (ST_Dump(geom)).path[1] id, (ST_Dump(geom)).geom geom FROM intersecting_points) as shifted_points
	),

points_output_2 AS 
	(SELECT
	wdpaid,
	type,
	iso3,
	parcels,
	ST_MULTI(ST_UNION(geom)) as geom
	FROM reshifted_points
	GROUP BY wdpaid, type, iso3, parcels)

SELECT wdpaid,parcels,type,iso3,geom 
FROM polygons -- modified on 20191025
UNION
SELECT wdpaid,parcels,type,iso3,geom
FROM points_output_1
UNION
SELECT wdpaid,parcels,type,iso3,geom
FROM points_output_2;
CREATE INDEX wdpa_all_relevant:vidx ON :vSCHEMA.wdpa_all_relevant USING gist(geom);


-- Part II: Repair invalid geometries

ALTER TABLE :vSCHEMA.wdpa_all_relevant
ADD COLUMN geom_was_invalid boolean DEFAULT FALSE;

UPDATE :vSCHEMA.wdpa_all_relevant
SET geom_was_invalid = TRUE 
WHERE ST_IsValid(geom) IS FALSE;

UPDATE :vSCHEMA.wdpa_all_relevant
SET geom = ST_MakeValid(geom)
WHERE geom_was_invalid IS TRUE;

ALTER TABLE :vSCHEMA.wdpa_all_relevant
DROP COLUMN geom_was_invalid,
ADD COLUMN area_geo double precision;

UPDATE :vSCHEMA.wdpa_all_relevant
SET area_geo = (ST_AREA(geom::geography)/1000000);


-- Part III: Simplify and repair geometries

DROP TABLE IF EXISTS :vSCHEMA.wdpa_all_relevant_simpl;
CREATE TABLE :vSCHEMA.wdpa_all_relevant_simpl AS
SELECT
wdpaid,
iso3,
ST_SimplifyPreserveTopology(geom,0.001) geom
FROM :vSCHEMA.wdpa_all_relevant
ORDER BY wdpaid;

ALTER TABLE :vSCHEMA.wdpa_all_relevant_simpl
ADD COLUMN geom_was_invalid boolean DEFAULT FALSE;

UPDATE :vSCHEMA.wdpa_all_relevant_simpl
SET geom_was_invalid = TRUE 
WHERE ST_IsValid(geom) IS FALSE;

UPDATE :vSCHEMA.wdpa_all_relevant_simpl
SET geom = ST_MakeValid(geom)
WHERE geom_was_invalid IS TRUE;

ALTER TABLE :vSCHEMA.wdpa_all_relevant_simpl
DROP COLUMN geom_was_invalid,
ADD COLUMN area_geo double precision;
UPDATE :vSCHEMA.wdpa_all_relevant_simpl
SET area_geo = (ST_AREA(geom::geography)/1000000);

CREATE INDEX wdpa_all_relevant_simpl:vidx ON :vSCHEMA.wdpa_all_relevant_simpl USING gist(geom);

-- Part IV : Dissolve features by iso3

DROP TABLE IF EXISTS :vSCHEMA.dissolved_iso;
CREATE TABLE :vSCHEMA.dissolved_iso AS
(SELECT 
iso3,
(ST_Dump( ST_Union(geom))).geom geom
FROM :vSCHEMA.wdpa_all_relevant_simpl
GROUP BY iso3);

ALTER TABLE :vSCHEMA.dissolved_iso
ADD COLUMN geom_was_invalid boolean DEFAULT FALSE;	

UPDATE :vSCHEMA.dissolved_iso
SET geom_was_invalid = TRUE 
WHERE ST_IsValid(geom) IS FALSE;

UPDATE :vSCHEMA.dissolved_iso
SET geom = ST_MakeValid(geom)
WHERE geom_was_invalid IS TRUE;

ALTER TABLE :vSCHEMA.dissolved_iso
DROP COLUMN geom_was_invalid,
ADD COLUMN area_geo double precision;
UPDATE :vSCHEMA.dissolved_iso
SET area_geo = (ST_AREA(geom::geography)/1000000);

CREATE INDEX dissolved_iso:vidx ON :vSCHEMA.dissolved_iso USING gist(geom);


-- Part V : Process multi-iso3 polygons using gaul

CREATE TEMPORARY TABLE tclipped_iso AS 
SELECT * FROM
	(SELECT
    dissolved_iso.iso3,
    (ST_Intersection(dissolved_iso.geom, gaul.geom)) geom
    FROM :vSCHEMA.dissolved_iso 
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

DROP TABLE IF EXISTS :vSCHEMA.wdpa_flat_1km2_final;
CREATE TABLE :vSCHEMA.wdpa_flat_1km2_final AS
	SELECT
	ROW_NUMBER() OVER (ORDER BY "ISO3final") AS nodeid,
	* 
	FROM 
		(SELECT "ISO3final",geom 
		FROM dissolved_iso3 ORDER BY "ISO3final") a 
	WHERE ST_GEOMETRYTYPE(geom) = 'ST_Polygon';

ALTER TABLE :vSCHEMA.wdpa_flat_1km2_final
ADD COLUMN geom_was_invalid boolean DEFAULT FALSE;

UPDATE :vSCHEMA.wdpa_flat_1km2_final
SET geom_was_invalid = TRUE 
WHERE ST_IsValid(geom) IS FALSE;

UPDATE :vSCHEMA.wdpa_flat_1km2_final
SET geom = ST_MakeValid(geom)
WHERE geom_was_invalid IS TRUE;

ALTER TABLE :vSCHEMA.wdpa_flat_1km2_final
DROP COLUMN geom_was_invalid,
ADD COLUMN area_geo double precision;
UPDATE :vSCHEMA.wdpa_flat_1km2_final
SET area_geo = (ST_AREA(geom::geography)/1000000);
CREATE INDEX wdpa_flat_1km2_final:vidx ON :vSCHEMA.wdpa_flat_1km2_final USING gist(geom);


-- Part VI : Generate Near Table (Can take several days...)

DROP TABLE IF EXISTS :vSCHEMA.all_distances_300km;
CREATE TABLE :vSCHEMA.all_distances_300km AS

WITH 
foo1 AS (SELECT nodeid "IN_FID", geom::geography as gg1 FROM :vSCHEMA.wdpa_flat_1km2_final),
foo2 AS (SELECT nodeid "NEAR_FID", geom::geography as gg2 FROM :vSCHEMA.wdpa_flat_1km2_final),

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
ORDER BY "IN_FID", "NEAR_RANK"

