import os
from contextlib import asynccontextmanager
from pathlib import Path

import httpx
from fastapi import FastAPI, HTTPException, Query
from fastapi.staticfiles import StaticFiles
from psycopg.rows import dict_row
from psycopg_pool import ConnectionPool

DATABASE_URL = os.environ.get(
    "DATABASE_URL", "postgresql://demo:demo@localhost:5442/delivery"
)
# GSI (Geospatial Information Authority of Japan) address search; no API key needed.
GSI_URL = "https://msearch.gsi.go.jp/address-search/AddressSearch"
WEB_DIR = Path(os.environ.get("WEB_DIR", Path(__file__).parent / "web"))

pool = ConnectionPool(DATABASE_URL, open=False, kwargs={"row_factory": dict_row})


@asynccontextmanager
async def lifespan(_app: FastAPI):
    pool.open(wait=True, timeout=30)
    yield
    pool.close()


app = FastAPI(title="Delivery area demo", lifespan=lifespan)

POINT_CTE = "WITH pt AS (SELECT ST_SetSRID(ST_MakePoint(%(lon)s, %(lat)s), 4326) AS g)"

# ST_Covers (not ST_Contains) so an address exactly on a zone edge counts as inside.
AVAILABLE_SQL = POINT_CTE + """
SELECT DISTINCT ON (s.id)
       s.id AS store_id, s.name, s.color,
       z.id AS zone_id, z.tier, z.fee, z.eta_min, z.shape
FROM delivery_zones z
JOIN stores s ON s.id = z.store_id, pt
WHERE ST_Covers(z.geom, pt.g)
ORDER BY s.id, z.tier
"""

# Distance in meters from the point to each out-of-range store's nearest zone.
UNAVAILABLE_SQL = POINT_CTE + """
SELECT s.id AS store_id, s.name, s.color,
       round(min(ST_Distance(z.geom::geography, pt.g::geography)))::int AS distance_m
FROM stores s
JOIN delivery_zones z ON z.store_id = s.id, pt
GROUP BY s.id, s.name, s.color
HAVING bool_and(NOT ST_Covers(z.geom, pt.g))
ORDER BY distance_m
"""

ON_WATER_SQL = POINT_CTE + """
SELECT EXISTS (SELECT 1 FROM sea_areas, pt WHERE ST_Covers(sea_areas.geom, pt.g)) AS on_water
"""


def fetch_all(sql: str, params: dict | None = None) -> list[dict]:
    with pool.connection() as conn:
        return conn.execute(sql, params).fetchall()


def feature_collection(rows: list[dict]) -> dict:
    return {
        "type": "FeatureCollection",
        "features": [
            {
                "type": "Feature",
                "geometry": row.pop("geometry"),
                "properties": row,
            }
            for row in rows
        ],
    }


@app.get("/api/check")
def check(
    lat: float = Query(ge=-90, le=90),
    lon: float = Query(ge=-180, le=180),
):
    params = {"lat": lat, "lon": lon}
    available = fetch_all(AVAILABLE_SQL, params)
    available.sort(key=lambda r: (r["fee"], r["eta_min"]))
    return {
        "point": params,
        "on_water": fetch_all(ON_WATER_SQL, params)[0]["on_water"],
        "available": available,
        "unavailable": fetch_all(UNAVAILABLE_SQL, params),
    }


@app.get("/api/zones")
def zones():
    rows = fetch_all("""
        SELECT z.id AS zone_id, z.store_id, s.name, s.color,
               z.tier, z.fee, z.eta_min, z.shape,
               ST_AsGeoJSON(z.geom)::json AS geometry
        FROM delivery_zones z JOIN stores s ON s.id = z.store_id
        ORDER BY z.tier DESC, z.store_id
    """)
    return feature_collection(rows)


@app.get("/api/stores")
def stores():
    rows = fetch_all("""
        SELECT id AS store_id, name, color, ST_AsGeoJSON(geom)::json AS geometry
        FROM stores ORDER BY id
    """)
    return feature_collection(rows)


@app.get("/api/sea")
def sea():
    rows = fetch_all("SELECT id, name, ST_AsGeoJSON(geom)::json AS geometry FROM sea_areas")
    return feature_collection(rows)


@app.get("/api/geocode")
async def geocode(q: str = Query(min_length=1, max_length=200)):
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            res = await client.get(GSI_URL, params={"q": q})
            res.raise_for_status()
            features = res.json()
    except (httpx.HTTPError, ValueError) as exc:
        raise HTTPException(502, f"Geocoding service unavailable: {exc}") from exc

    candidates = [
        {
            "title": f["properties"]["title"],
            "lon": f["geometry"]["coordinates"][0],
            "lat": f["geometry"]["coordinates"][1],
        }
        for f in features
    ]
    # Prefer hits inside Yokohama, keeping the service's order otherwise.
    candidates.sort(key=lambda c: "横浜市" not in c["title"])
    return {"query": q, "candidates": candidates[:5]}


if WEB_DIR.is_dir():
    app.mount("/", StaticFiles(directory=WEB_DIR, html=True), name="web")
