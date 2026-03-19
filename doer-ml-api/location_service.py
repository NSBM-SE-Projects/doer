import requests
import math
import os

GOOGLE_MAPS_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY", "")


def geocode_address(address: str) -> dict:
    """Convert text address → lat/lng (Sri Lanka restricted)."""
    r = requests.get(
        "https://maps.googleapis.com/maps/api/geocode/json",
        params={"address": f"{address}, Sri Lanka", "key": GOOGLE_MAPS_API_KEY},
    )
    data = r.json()
    if data["status"] == "OK":
        loc = data["results"][0]["geometry"]["location"]
        return {
            "success": True,
            "lat": loc["lat"],
            "lng": loc["lng"],
            "formatted_address": data["results"][0]["formatted_address"],
        }
    return {"success": False, "error": data["status"]}


def get_distances(origin_lat: float, origin_lng: float, destinations: list) -> list:
    """Driving distances from one origin to many destinations (Google Distance Matrix)."""
    if not destinations:
        return []
    dest_str = "|".join(f"{d['lat']},{d['lng']}" for d in destinations[:25])
    r = requests.get(
        "https://maps.googleapis.com/maps/api/distancematrix/json",
        params={
            "origins": f"{origin_lat},{origin_lng}",
            "destinations": dest_str,
            "mode": "driving",
            "units": "metric",
            "key": GOOGLE_MAPS_API_KEY,
        },
    )
    data = r.json()
    out = []
    if data["status"] == "OK":
        for dest, el in zip(destinations, data["rows"][0]["elements"]):
            if el["status"] == "OK":
                out.append({
                    **dest,
                    "distance_km":      round(el["distance"]["value"] / 1000, 1),
                    "duration_minutes": round(el["duration"]["value"] / 60),
                    "distance_text":    el["distance"]["text"],
                    "duration_text":    el["duration"]["text"],
                })
            else:
                sl = _haversine(origin_lat, origin_lng, dest["lat"], dest["lng"])
                out.append({
                    **dest,
                    "distance_km":      sl,
                    "duration_minutes": round(sl * 3),
                    "distance_text":    f"{sl} km",
                    "duration_text":    f"{round(sl*3)} mins",
                })
    return out


def find_workers_within_radius(
    household_lat: float,
    household_lng: float,
    workers: list,
    radius_km: float = 20.0,
) -> list:
    """Filter workers by radius then sort nearest-first."""
    if not workers:
        return []
    # Quick straight-line pre-filter
    nearby = [
        w for w in workers
        if "lat" in w and "lng" in w and w["lat"] and w["lng"]
        and _haversine(household_lat, household_lng, w["lat"], w["lng"]) <= radius_km * 1.3
    ]
    if not nearby:
        return []

    dests = [{"lat": w["lat"], "lng": w["lng"], "worker_id": w["worker_id"]} for w in nearby]
    distances = get_distances(household_lat, household_lng, dests)
    dist_map = {d["worker_id"]: d for d in distances}

    result = []
    for w in nearby:
        info = dist_map.get(w["worker_id"])
        if info and info["distance_km"] <= radius_km:
            result.append({**w, **{
                "distance_km":      info["distance_km"],
                "duration_minutes": info["duration_minutes"],
                "distance_text":    info["distance_text"],
                "duration_text":    info["duration_text"],
            }})
    result.sort(key=lambda x: x.get("distance_km", 999))
    return result


def autocomplete_address(input_text: str) -> list:
    """Return up to 5 address suggestions (Sri Lanka only)."""
    r = requests.get(
        "https://maps.googleapis.com/maps/api/place/autocomplete/json",
        params={
            "input":      input_text,
            "components": "country:lk",
            "types":      "geocode",
            "key":        GOOGLE_MAPS_API_KEY,
        },
    )
    data = r.json()
    if data["status"] != "OK":
        return []
    return [
        {
            "place_id":    p["place_id"],
            "description": p["description"],
            "main_text":   p["structured_formatting"]["main_text"],
        }
        for p in data["predictions"][:5]
    ]


def get_place_coordinates(place_id: str) -> dict:
    """Get lat/lng from a place_id (returned by autocomplete)."""
    r = requests.get(
        "https://maps.googleapis.com/maps/api/place/details/json",
        params={
            "place_id": place_id,
            "fields":   "geometry,formatted_address",
            "key":      GOOGLE_MAPS_API_KEY,
        },
    )
    data = r.json()
    if data["status"] == "OK":
        loc = data["result"]["geometry"]["location"]
        return {
            "success": True,
            "lat": loc["lat"],
            "lng": loc["lng"],
            "formatted_address": data["result"]["formatted_address"],
        }
    return {"success": False}


def _haversine(lat1, lng1, lat2, lng2) -> float:
    """Straight-line distance in km between two coordinates."""
    R = 6371
    d1 = math.radians(lat2 - lat1)
    d2 = math.radians(lng2 - lng1)
    a = math.sin(d1/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(d2/2)**2
    return round(R * 2 * math.asin(math.sqrt(a)), 1)
