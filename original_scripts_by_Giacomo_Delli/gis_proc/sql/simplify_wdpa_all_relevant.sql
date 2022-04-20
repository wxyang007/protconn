-- STEP 1 repair geometries
ALTER TABLE :OUTSCHEMA.:INNAME
ADD COLUMN geom_was_invalid boolean DEFAULT FALSE;

UPDATE :OUTSCHEMA.:INNAME
SET geom_was_invalid = TRUE 
WHERE ST_IsValid(wkb_geometry) IS FALSE;

UPDATE :OUTSCHEMA.:INNAME
SET wkb_geometry = ST_MakeValid(wkb_geometry)
WHERE geom_was_invalid IS TRUE;

--ALTER TABLE :OUTSCHEMA.:INNAME
--DROP COLUMN geom_was_invalid;

-- STEP 2 SIMPLIFY GEOMETRIES
DROP TABLE IF EXISTS :OUTSCHEMA.:OUTNAME;
CREATE TABLE :OUTSCHEMA.:OUTNAME AS

WITH step1 AS
(SELECT
CAST(wdpaid AS integer) wdpaid,
iso3,
ST_SimplifyPreserveTopology(wkb_geometry,0.001) geom
FROM :OUTSCHEMA.:INNAME
ORDER BY wdpaid)

SELECT 
wdpaid,
iso3,
(ST_Dump(ST_CollectionExtract(geom,3))).geom geom
FROM step1;

CREATE INDEX idx_:OUTNAME ON :OUTSCHEMA.:OUTNAME USING gist(geom);


