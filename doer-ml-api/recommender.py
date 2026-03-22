import pandas as pd

# In-memory store (replace with Supabase queries when ready)
_workers: list = []
_bookings: list = []


def add_worker(w: dict):
    global _workers
    _workers = [x for x in _workers if x["worker_id"] != w["worker_id"]]
    _workers.append(w)


def add_booking(b: dict):
    _bookings.append(b)


def get_all_workers():
    return _workers


def recommend_workers(
    household_id: str,
    district: str,
    needed_services: list,
    max_budget: float = None,
    top_n: int = 10,
    prefiltered_workers: list = None,
):
    """
    Score every worker out of 100 pts:
      Location match  → 40 pts
      Service match   → 30 pts
      Rating          → 20 pts
      Verified badge  → 10 pts
      Collab boost    → up to +10 pts
    """
    pool = prefiltered_workers if prefiltered_workers is not None else _workers
    if not pool:
        return []

    collab = _collaborative_scores(household_id)
    results = []

    for w in pool:
        if max_budget and w.get("hourly_rate", 0) > max_budget:
            continue

        score = 0
        reasons = []

        # ── Location (40 pts) ─────────────────────────────────────
        if prefiltered_workers is not None:
            d = w.get("distance_km")
            if d is not None:
                if d <= 5:
                    score += 40; reasons.append(f"📍 Very close — {d} km")
                elif d <= 10:
                    score += 30; reasons.append(f"📍 Nearby — {d} km")
                else:
                    score += 20; reasons.append(f"📍 {d} km away")
            else:
                score += 15
        else:
            wd = w.get("district", "").lower()
            hd = district.lower()
            if wd == hd:
                score += 40; reasons.append("📍 Same district")
            elif _is_nearby(wd, hd):
                score += 20; reasons.append("📍 Nearby district")

        # ── Services (30 pts) ─────────────────────────────────────
        ws = [s.lower() for s in w.get("services", [])]
        ns = [s.lower() for s in needed_services]
        matched = [s for s in ns if s in ws]
        if ns:
            score += round(len(matched) / len(ns) * 30)
            if matched:
                reasons.append(f"✅ Offers: {', '.join(matched)}")

        # ── Rating (20 pts) ───────────────────────────────────────
        reviews = w.get("total_reviews", 0)
        if reviews > 0:
            weight = min(reviews / 10, 1.0)
            score += round((w.get("rating", 0) / 5.0) * 20 * weight)
            reasons.append(f"⭐ {w['rating']}/5 ({reviews} reviews)")

        # ── Verified (10 pts) ─────────────────────────────────────
        if w.get("verified"):
            score += 10; reasons.append("✔️ ID Verified")

        # ── Collaborative boost ───────────────────────────────────
        boost = collab.get(w["worker_id"], 0)
        score += boost
        if boost > 0:
            reasons.append("👥 Popular with similar households")

        results.append({
            "worker_id":       w["worker_id"],
            "name":            w["name"],
            "services":        w["services"],
            "district":        w["district"],
            "lat":             w.get("lat"),
            "lng":             w.get("lng"),
            "rating":          w.get("rating", 0),
            "total_reviews":   w.get("total_reviews", 0),
            "hourly_rate":     w.get("hourly_rate"),
            "verified":        w.get("verified", False),
            "match_score":     min(score, 100),
            "why_recommended": reasons,
        })

    results.sort(key=lambda x: x["match_score"], reverse=True)
    return results[:top_n]


def _collaborative_scores(household_id: str) -> dict:
    """Boost workers loved by households similar to this one."""
    if len(_bookings) < 5:
        return {}
    df = pd.DataFrame(_bookings)
    seen = df[df["household_id"] == household_id]["worker_id"].tolist()
    if not seen:
        return {}
    similar_ids = df[
        (df["worker_id"].isin(seen)) & (df["household_id"] != household_id)
    ]["household_id"].unique()
    if len(similar_ids) == 0:
        return {}
    good = df[
        (df["household_id"].isin(similar_ids)) &
        (df["rating_given"] >= 4.0) &
        (~df["worker_id"].isin(seen))
    ]
    counts = good["worker_id"].value_counts()
    if counts.empty:
        return {}
    mx = counts.max()
    return {wid: round(c / mx * 10) for wid, c in counts.items()}


_NEARBY = {
    "colombo":     ["gampaha", "kalutara"],
    "gampaha":     ["colombo", "kurunegala", "kegalle"],
    "kalutara":    ["colombo", "ratnapura", "galle"],
    "kandy":       ["matale", "nuwara eliya", "kegalle"],
    "galle":       ["matara", "kalutara"],
    "matara":      ["galle", "hambantota"],
    "jaffna":      ["kilinochchi", "mannar"],
    "trincomalee": ["batticaloa", "polonnaruwa"],
    "batticaloa":  ["trincomalee", "ampara"],
    "kurunegala":  ["gampaha", "puttalam", "matale"],
    "ratnapura":   ["kalutara", "kegalle", "monaragala"],
    "negombo":     ["colombo", "gampaha"],
}

def _is_nearby(w: str, h: str) -> bool:
    return h in _NEARBY.get(w, [])
