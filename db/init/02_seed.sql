-- Fictional stores around central Yokohama. All outlines are hand-drawn
-- approximations of rivers and coastline, not survey-accurate boundaries.

INSERT INTO stores (name, color, geom) VALUES
  ('横浜駅西口店',   '#d9480f', ST_SetSRID(ST_MakePoint(139.6195, 35.4655), 4326)),
  ('みなとみらい店', '#1971c2', ST_SetSRID(ST_MakePoint(139.6330, 35.4580), 4326)),
  ('関内店',         '#2f9e44', ST_SetSRID(ST_MakePoint(139.6385, 35.4445), 4326)),
  ('中華街店',       '#ae3ec9', ST_SetSRID(ST_MakePoint(139.6465, 35.4430), 4326)),
  ('本牧店',         '#e64980', ST_SetSRID(ST_MakePoint(139.6611, 35.4228), 4326)),
  ('磯子駅前店',     '#0c8599', ST_SetSRID(ST_MakePoint(139.6190, 35.4010), 4326));

-- Yokohama Station West: the near zone stops at the Katabira River (south side).
INSERT INTO delivery_zones (store_id, tier, fee, eta_min, shape, geom)
SELECT id, 1, 0, 20, 'polygon', ST_GeomFromText('POLYGON((
  139.6050 35.4605, 139.6150 35.4628, 139.6230 35.4642, 139.6290 35.4655,
  139.6300 35.4720, 139.6200 35.4760, 139.6080 35.4740, 139.6020 35.4680,
  139.6050 35.4605))', 4326)
FROM stores WHERE name = '横浜駅西口店';

INSERT INTO delivery_zones (store_id, tier, fee, eta_min, shape, geom)
SELECT id, 2, 300, 35, 'polygon', ST_GeomFromText('POLYGON((
  139.5980 35.4540, 139.6150 35.4560, 139.6280 35.4580, 139.6320 35.4650,
  139.6330 35.4740, 139.6220 35.4810, 139.6050 35.4800, 139.5950 35.4700,
  139.5980 35.4540))', 4326)
FROM stores WHERE name = '横浜駅西口店';

-- Minato Mirai: deliberately plain circles, so a large part ends up over the harbor.
INSERT INTO delivery_zones (store_id, tier, fee, eta_min, shape, geom)
SELECT id, 1, 0, 15, 'circle', ST_Buffer(geom::geography, 1000)::geometry
FROM stores WHERE name = 'みなとみらい店';

INSERT INTO delivery_zones (store_id, tier, fee, eta_min, shape, geom)
SELECT id, 2, 250, 30, 'circle', ST_Buffer(geom::geography, 2000)::geometry
FROM stores WHERE name = 'みなとみらい店';

-- Kannai: the near zone is the east bank of the Ooka River; Noge (west bank) is far.
INSERT INTO delivery_zones (store_id, tier, fee, eta_min, shape, geom)
SELECT id, 1, 0, 20, 'polygon', ST_GeomFromText('POLYGON((
  139.6280 35.4395, 139.6292 35.4450, 139.6322 35.4500, 139.6350 35.4515,
  139.6420 35.4490, 139.6460 35.4470, 139.6440 35.4400, 139.6380 35.4375,
  139.6280 35.4395))', 4326)
FROM stores WHERE name = '関内店';

INSERT INTO delivery_zones (store_id, tier, fee, eta_min, shape, geom)
SELECT id, 2, 300, 35, 'polygon', ST_GeomFromText('POLYGON((
  139.6200 35.4370, 139.6220 35.4480, 139.6290 35.4540, 139.6360 35.4535,
  139.6480 35.4480, 139.6500 35.4440, 139.6450 35.4370, 139.6330 35.4345,
  139.6200 35.4370))', 4326)
FROM stores WHERE name = '関内店';

-- Chinatown: the near zone keeps to the flat area; the Yamate hill is far (higher fee).
INSERT INTO delivery_zones (store_id, tier, fee, eta_min, shape, geom)
SELECT id, 1, 0, 20, 'polygon', ST_GeomFromText('POLYGON((
  139.6410 35.4405, 139.6430 35.4455, 139.6480 35.4478, 139.6555 35.4455,
  139.6560 35.4400, 139.6500 35.4392, 139.6410 35.4405))', 4326)
FROM stores WHERE name = '中華街店';

INSERT INTO delivery_zones (store_id, tier, fee, eta_min, shape, geom)
SELECT id, 2, 400, 40, 'polygon', ST_GeomFromText('POLYGON((
  139.6370 35.4370, 139.6400 35.4470, 139.6480 35.4500, 139.6580 35.4470,
  139.6600 35.4360, 139.6500 35.4340, 139.6370 35.4370))', 4326)
FROM stores WHERE name = '中華街店';

-- Honmoku: the near zone is the flat Honmoku lowland; the hills to the west are far.
INSERT INTO delivery_zones (store_id, tier, fee, eta_min, shape, geom)
SELECT id, 1, 0, 20, 'polygon', ST_GeomFromText('POLYGON((
  139.6540 35.4170, 139.6545 35.4250, 139.6570 35.4310, 139.6620 35.4350,
  139.6700 35.4330, 139.6760 35.4270, 139.6760 35.4180, 139.6680 35.4130,
  139.6600 35.4140, 139.6540 35.4170))', 4326)
FROM stores WHERE name = '本牧店';

INSERT INTO delivery_zones (store_id, tier, fee, eta_min, shape, geom)
SELECT id, 2, 350, 35, 'polygon', ST_GeomFromText('POLYGON((
  139.6440 35.4160, 139.6450 35.4300, 139.6500 35.4370, 139.6620 35.4400,
  139.6760 35.4390, 139.6800 35.4300, 139.6800 35.4170, 139.6700 35.4100,
  139.6600 35.4120, 139.6500 35.4140, 139.6440 35.4160))', 4326)
FROM stores WHERE name = '本牧店';

-- Isogo: the near zone is the residential strip west of the JR line; the hills,
-- Sugita, and the Shin-Isogo industrial peninsula are far. Negishi Station falls
-- in the gap between Isogo and Honmoku on purpose.
INSERT INTO delivery_zones (store_id, tier, fee, eta_min, shape, geom)
SELECT id, 1, 0, 20, 'polygon', ST_GeomFromText('POLYGON((
  139.6125 35.3895, 139.6142 35.3986, 139.6155 35.4077, 139.6185 35.4160,
  139.6275 35.4160, 139.6288 35.4094, 139.6219 35.4021, 139.6202 35.3930,
  139.6185 35.3881, 139.6125 35.3895))', 4326)
FROM stores WHERE name = '磯子駅前店';

INSERT INTO delivery_zones (store_id, tier, fee, eta_min, shape, geom)
SELECT id, 2, 300, 35, 'polygon', ST_GeomFromText('POLYGON((
  139.6000 35.3800, 139.6000 35.4060, 139.6100 35.4200, 139.6230 35.4260,
  139.6310 35.4200, 139.6285 35.4100, 139.6305 35.4060, 139.6445 35.4060,
  139.6445 35.4012, 139.6300 35.4000, 139.6248 35.3962, 139.6248 35.3922,
  139.6317 35.3946, 139.6332 35.3885, 139.6300 35.3800, 139.6000 35.3800))', 4326)
FROM stores WHERE name = '磯子駅前店';

INSERT INTO sea_areas (name, geom) VALUES
  -- Wraps around the Shin-Isogo peninsula (water on its north and south sides).
  ('根岸湾（おおまかな海域）', ST_GeomFromText('POLYGON((
    139.6290 35.4092, 139.6390 35.4112, 139.6470 35.4115, 139.6550 35.4122,
    139.6610 35.4100, 139.6650 35.4060, 139.6650 35.3990, 139.6780 35.3950,
    139.7000 35.3900, 139.7000 35.3850, 139.6550 35.3890, 139.6390 35.3900,
    139.6317 35.3948, 139.6250 35.3922, 139.6248 35.3960, 139.6300 35.3998,
    139.6450 35.4010, 139.6450 35.4060, 139.6305 35.4058, 139.6290 35.4092))', 4326)),
  ('横浜港（おおまかな海域）', ST_GeomFromText('POLYGON((
    139.6390 35.4630, 139.6385 35.4600, 139.6415 35.4570, 139.6460 35.4555,
    139.6470 35.4520, 139.6490 35.4490, 139.6560 35.4475, 139.6680 35.4470,
    139.6680 35.4680, 139.6450 35.4680, 139.6390 35.4630))', 4326));
