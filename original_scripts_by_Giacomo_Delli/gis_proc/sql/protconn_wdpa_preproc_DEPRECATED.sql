-- Protection Connectivity: GIS processing of WDPA
-- Part I : preparing wdpa_all_relevant dataset

DROP TABLE IF EXISTS :vSCHEMA.wdpa_all_relevant;
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
--	AND WDPAID IN (SELECT wdpaid FROM delli.wdpa_all_relevant) -- ADDED ONLY TO TEST THE SCRIPT ON A SMALL SAMPLE
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
--	AND WDPAID IN (SELECT wdpaid FROM delli.wdpa_all_relevant) -- ADDED ONLY TO TEST THE SCRIPT ON A SMALL SAMPLE
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
--	AND WDPAID IN (SELECT wdpaid FROM delli.wdpa_all_relevant) -- ADDED ONLY TO TEST THE SCRIPT ON A SMALL SAMPLE
	),
non_intersecting_points AS 
	(SELECT
	a.wdpaid,
	a.type,
	a.iso3,
	b.parcels,
	(ST_Buffer(a.geom::geography(MultiPoint),b.radius*1000))::geometry(Polygon) as geom
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
		WHERE ST_INTERSECTS((ST_Buffer(a.geom::geography(MultiPoint),b.radius*1000)), ST_GeogFromText('LINESTRING(180 -90, 180 0, 180 90)')) IS false
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
	ST_Split(((ST_Buffer(ST_Translate(a.geom, +180, 0)::geography(MultiPoint),b.radius*1000))::geometry(Polygon)), ST_GeomFromText('LINESTRING(0 -90, 0 90)',4326)) as geom
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
