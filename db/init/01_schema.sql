CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE stores (
  id    serial PRIMARY KEY,
  name  text NOT NULL UNIQUE,
  color text NOT NULL,                    -- map color used by the frontend
  geom  geometry(Point, 4326) NOT NULL
);

-- A store can have several overlapping zones; a lower tier is a better deal.
CREATE TABLE delivery_zones (
  id       serial PRIMARY KEY,
  store_id int NOT NULL REFERENCES stores(id),
  tier     smallint NOT NULL,
  fee      int NOT NULL,                  -- yen
  eta_min  int NOT NULL,
  shape    text NOT NULL CHECK (shape IN ('polygon', 'circle')),
  geom     geometry(Polygon, 4326) NOT NULL,
  UNIQUE (store_id, tier)
);

-- Rough outline of Yokohama harbor, used to flag points that fall on water.
CREATE TABLE sea_areas (
  id   serial PRIMARY KEY,
  name text NOT NULL,
  geom geometry(Polygon, 4326) NOT NULL
);

CREATE INDEX stores_geom_idx         ON stores         USING gist (geom);
CREATE INDEX delivery_zones_geom_idx ON delivery_zones USING gist (geom);
CREATE INDEX sea_areas_geom_idx      ON sea_areas      USING gist (geom);
