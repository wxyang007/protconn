-- SIMPLIFY GEOMETRIES
DROP TABLE IF EXISTS :OUTSCHEMA.:OUTNAME;
CREATE TABLE :OUTSCHEMA.:OUTNAME AS
WITH step1 AS
(SELECT
objectid,id_object,id_country,name_iso31,iso3,orig_fid,
ST_SimplifyPreserveTopology(wkb_geometry,0.001) geom
FROM :OUTSCHEMA.:INNAME
ORDER BY id_country)

SELECT objectid,id_object,id_country,name_iso31,iso3,orig_fid,
(ST_Dump(ST_CollectionExtract(geom,3))).geom geom
FROM step1;

