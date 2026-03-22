from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from recommender import recommend_workers, add_worker, add_booking, get_all_workers
from location_service import geocode_address, find_workers_within_radius, autocomplete_address, get_place_coordinates

app = FastAPI(title="Doer — Worker Recommendation API 🇱🇰")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Models ────────────────────────────────────────────────────────

class Worker(BaseModel):
    worker_id: str
    name: str
    services: List[str]           # ["cleaning", "cooking", ...]
    district: str                 # "Colombo"
    lat: Optional[float] = None
    lng: Optional[float] = None
    address: Optional[str] = None
    rating: float = 0.0
    total_reviews: int = 0
    hourly_rate: float            # LKR
    verified: bool = False

class RecommendRequest(BaseModel):
    household_id: str
    district: str
    lat: Optional[float] = None
    lng: Optional[float] = None
    needed_services: List[str]
    max_budget: Optional[float] = None
    radius_km: Optional[float] = 20.0

class Booking(BaseModel):
    household_id: str
    worker_id: str
    rating_given: float

class GeocodeRequest(BaseModel):
    address: str

class AutocompleteRequest(BaseModel):
    input_text: str

class PlaceRequest(BaseModel):
    place_id: str

class NearbyRequest(BaseModel):
    lat: float
    lng: float
    radius_km: Optional[float] = 20.0
    services: Optional[List[str]] = None

# ── Health ────────────────────────────────────────────────────────

@app.get("/")
def root():
    return {"status": "Doer API is running ✅", "version": "1.0"}

@app.get("/health")
def health():
    return {"status": "ok"}

# ── Workers ───────────────────────────────────────────────────────

@app.post("/workers/add")
def add_new_worker(worker: Worker):
    data = worker.dict()
    if worker.address and not worker.lat:
        geo = geocode_address(worker.address)
        if geo["success"]:
            data["lat"] = geo["lat"]
            data["lng"] = geo["lng"]
    add_worker(data)
    return {"message": f"Worker {worker.name} added ✅"}

@app.get("/workers/all")
def list_all_workers():
    return {"workers": get_all_workers()}

# ── Recommendations ───────────────────────────────────────────────

@app.post("/recommend")
def get_recommendations(req: RecommendRequest):
    all_workers = get_all_workers()

    if req.lat and req.lng:
        nearby = find_workers_within_radius(req.lat, req.lng, all_workers, req.radius_km)
        results = recommend_workers(
            household_id=req.household_id,
            district=req.district,
            needed_services=req.needed_services,
            max_budget=req.max_budget,
            prefiltered_workers=nearby
        )
        dist_map = {w["worker_id"]: w for w in nearby}
        for r in results:
            info = dist_map.get(r["worker_id"], {})
            r["distance_km"]   = info.get("distance_km")
            r["duration_text"] = info.get("duration_text")
    else:
        results = recommend_workers(
            household_id=req.household_id,
            district=req.district,
            needed_services=req.needed_services,
            max_budget=req.max_budget
        )

    if not results:
        raise HTTPException(status_code=404, detail="No workers found in your area")
    return {"recommendations": results, "total": len(results)}

# ── Bookings ──────────────────────────────────────────────────────

@app.post("/bookings/add")
def record_booking(booking: Booking):
    add_booking(booking.dict())
    return {"message": "Booking recorded ✅"}

# ── Location ──────────────────────────────────────────────────────

@app.post("/location/geocode")
def geocode(req: GeocodeRequest):
    result = geocode_address(req.address)
    if not result["success"]:
        raise HTTPException(status_code=400, detail="Address not found")
    return result

@app.post("/location/autocomplete")
def autocomplete(req: AutocompleteRequest):
    return {"suggestions": autocomplete_address(req.input_text)}

@app.post("/location/place-details")
def place_details(req: PlaceRequest):
    result = get_place_coordinates(req.place_id)
    if not result["success"]:
        raise HTTPException(status_code=400, detail="Place not found")
    return result

@app.post("/location/nearby-workers")
def nearby_workers(req: NearbyRequest):
    workers = get_all_workers()
    if req.services:
        workers = [w for w in workers if any(
            s.lower() in [x.lower() for x in w.get("services", [])] for s in req.services
        )]
    nearby = find_workers_within_radius(req.lat, req.lng, workers, req.radius_km)
    return {"workers": nearby, "total": len(nearby)}
