"""Integration tests against the seeded PostGIS database (run via the compose test profile)."""

import pytest
from fastapi.testclient import TestClient

from main import app


@pytest.fixture(scope="module")
def client():
    with TestClient(app) as c:
        yield c


def check(client, lat, lon):
    res = client.get("/api/check", params={"lat": lat, "lon": lon})
    assert res.status_code == 200
    return res.json()


def best(body):
    return {r["name"]: (r["tier"], r["fee"]) for r in body["available"]}


def test_landmark_tower_is_in_minato_mirai_near_zone(client):
    body = check(client, 35.4547, 139.6314)
    assert best(body)["みなとみらい店"] == (1, 0)
    assert body["on_water"] is False


def test_noge_is_across_the_river_from_kannai(client):
    assert best(check(client, 35.4475, 139.6290))["関内店"] == (2, 300)


def test_chinatown_overlap_picks_each_stores_best_tier(client):
    stores = best(check(client, 35.4425, 139.6455))
    assert stores["中華街店"] == (1, 0)
    assert stores["関内店"] == (2, 300)


def test_available_sorted_by_fee(client):
    fees = [r["fee"] for r in check(client, 35.4658, 139.6223)["available"]]
    assert fees == sorted(fees)


def test_circle_zone_accepts_a_point_on_the_harbor(client):
    body = check(client, 35.4580, 139.6500)
    assert body["on_water"] is True
    assert "みなとみらい店" in best(body)


def test_out_of_range_reports_distances(client):
    body = check(client, 35.4245, 139.5985)
    assert body["available"] == []
    distances = [r["distance_m"] for r in body["unavailable"]]
    assert len(distances) == len(client.get("/api/stores").json()["features"])
    assert distances == sorted(distances)
    assert distances[0] > 0


def test_store_is_not_listed_both_ways(client):
    body = check(client, 35.4547, 139.6314)
    available = {r["store_id"] for r in body["available"]}
    unavailable = {r["store_id"] for r in body["unavailable"]}
    assert available.isdisjoint(unavailable)
    assert len(available | unavailable) == len(client.get("/api/stores").json()["features"])


def test_zone_boundary_counts_as_inside(client):
    # A vertex of the Kannai near zone.
    assert best(check(client, 35.4490, 139.6420))["関内店"] == (1, 0)


def test_honmoku_lowland_is_near_zone(client):
    assert best(check(client, 35.4228, 139.6611))["本牧店"] == (1, 0)


def test_isogo_station_is_near_zone(client):
    assert best(check(client, 35.4010, 139.6190))["磯子駅前店"] == (1, 0)


def test_shin_isogo_peninsula_is_far_zone_and_on_land(client):
    body = check(client, 35.4035, 139.6350)
    assert best(body)["磯子駅前店"] == (2, 300)
    assert body["on_water"] is False


def test_negishi_station_falls_between_zones(client):
    body = check(client, 35.4173, 139.6363)
    assert body["available"] == []
    assert body["unavailable"][0]["name"] == "磯子駅前店"


def test_negishi_bay_is_water_and_out_of_range(client):
    body = check(client, 35.4030, 139.6550)
    assert body["on_water"] is True
    assert body["available"] == []


def test_invalid_latitude_rejected(client):
    assert client.get("/api/check", params={"lat": 120, "lon": 139.6}).status_code == 422


def test_geojson_endpoints(client):
    zones = client.get("/api/zones").json()
    assert zones["type"] == "FeatureCollection"
    assert len(zones["features"]) == 12
    assert zones["features"][0]["geometry"]["type"] == "Polygon"
    assert len(client.get("/api/stores").json()["features"]) == 6
    assert len(client.get("/api/sea").json()["features"]) == 2
