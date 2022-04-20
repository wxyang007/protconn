-- SIMPLIFY GEOMETRIES
DROP TABLE IF EXISTS :OUTSCHEMA.:OUTNAME;
CREATE TABLE :OUTSCHEMA.:OUTNAME AS

WITH step1 AS
(SELECT
wdpaid,
iso3,
ST_SimplifyPreserveTopology(wkb_geometry,0.001) geom
FROM :OUTSCHEMA.:INNAME
ORDER BY wdpaid)

SELECT 
wdpaid,
iso3,
(ST_Dump(ST_CollectionExtract(geom,3))).geom geom
FROM step1;

CREATE INDEX :OUTNAME_idx ON :OUTSCHEMA.:OUTNAME USING gist(geom);


