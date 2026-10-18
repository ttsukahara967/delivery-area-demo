-- Ad-hoc queries to try from psql:
--   docker compose exec db psql -U demo -d delivery -f /queries/explore.sql

-- 1. Basic PIP: which zones cover Yokohama Landmark Tower?
SELECT s.name, z.tier, z.fee
FROM delivery_zones z JOIN stores s ON s.id = z.store_id
WHERE ST_Covers(z.geom, ST_SetSRID(ST_MakePoint(139.6314, 35.4547), 4326))
ORDER BY s.name, z.tier;

-- 2. ST_Contains vs ST_Covers on a boundary vertex of the Kannai near zone.
--    Contains excludes the boundary, Covers includes it.
WITH pt AS (SELECT ST_SetSRID(ST_MakePoint(139.6420, 35.4490), 4326) AS g)
SELECT ST_Contains(z.geom, pt.g) AS contains, ST_Covers(z.geom, pt.g) AS covers
FROM delivery_zones z JOIN stores s ON s.id = z.store_id, pt
WHERE s.name = '関内店' AND z.tier = 1;

-- 3. How much of each zone lies over the harbor? (circles fare badly)
SELECT s.name, z.tier, z.shape,
       round((100 * ST_Area(ST_Intersection(z.geom, w.geom)::geography)
                  / ST_Area(z.geom::geography))::numeric, 1) AS pct_on_water
FROM delivery_zones z
JOIN stores s ON s.id = z.store_id
CROSS JOIN (SELECT ST_Union(geom) AS geom FROM sea_areas) w
ORDER BY pct_on_water DESC;

-- 4. Index usage. With this few rows the planner may prefer a seq scan;
--    SET enable_seqscan = off forces the GiST index so you can see the plan shape.
SET enable_seqscan = off;
EXPLAIN ANALYZE
SELECT id FROM delivery_zones
WHERE ST_Covers(geom, ST_SetSRID(ST_MakePoint(139.6314, 35.4547), 4326));
RESET enable_seqscan;
