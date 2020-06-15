-- Generate Near Table for countries with bound correction (can take several days...)

-- STEP 1 repair geometries
ALTER TABLE :OUTSCHEMA.:INTABLE
ADD COLUMN geom_was_invalid boolean DEFAULT FALSE;

UPDATE :OUTSCHEMA.:INTABLE
SET geom_was_invalid = TRUE 
WHERE ST_IsValid(wkb_geometry) IS FALSE;

UPDATE :OUTSCHEMA.:INTABLE
SET wkb_geometry = ST_MakeValid(wkb_geometry)
WHERE geom_was_invalid IS TRUE;

ALTER TABLE :OUTSCHEMA.:INTABLE
DROP COLUMN geom_was_invalid;

-- STEP 2 compute near table (may take several days...)
-- create 2 temp tables with spatial index
CREATE TEMPORARY TABLE foo1 AS
(SELECT objectid "IN_FID", wkb_geometry::geography as gg1 FROM :OUTSCHEMA.:INTABLE);
CREATE INDEX foo1_idx ON foo1 USING GIST (geography(gg1));

CREATE TEMPORARY TABLE foo2 AS
(SELECT objectid "NEAR_FID", wkb_geometry::geography as gg2 FROM :OUTSCHEMA.:INTABLE);
CREATE INDEX foo2_idx ON foo2 USING GIST (geography(gg2));

--create distances table
DROP TABLE IF EXISTS :OUTSCHEMA.:OUTTABLE;
CREATE TABLE :OUTSCHEMA.:OUTTABLE AS

WITH 
finaltable AS (
SELECT DISTINCT
"IN_FID" "OBJECTID",
"IN_FID",
"NEAR_FID",
ST_Distance(gg1, gg2) AS "NEAR_DIST"
FROM foo1,foo2
WHERE ST_DWithin(gg1,gg2,100000, TRUE) --Here we set the maximum distance (100 km) for calculations for countries with bound correction
)

SELECT 
*,
row_number() over (PARTITION BY "IN_FID" ORDER BY "NEAR_DIST") as "NEAR_RANK"
FROM finaltable
WHERE "NEAR_DIST">0
ORDER BY "IN_FID", "NEAR_RANK";
