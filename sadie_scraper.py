#!/usr/bin/env python3
"""
Sadie Scraper - Google Places API Hotel Scraper (Cost-Optimized)
================================================================
Scrapes hotels from Google Places API by geographic area.
Filters out apartments and bad leads.
Uses concurrent API calls for speed.

COST OPTIMIZATIONS:
- 4x4 grid (16 centers) instead of larger grids
- Only uses type=lodging search (most hotels appear here)
- Max 1 page per search (no pagination)
- NO Place Details API calls - Enricher finds websites via Serper

This reduces Google Places API costs by ~90% compared to full search.

Usage:
    python3 sadie_scraper.py --center-lat 25.7617 --center-lng -80.1918 --overall-radius-km 35
    python3 sadie_scraper.py --center-lat 38.3886 --center-lng -75.0735 --overall-radius-km 20 --concurrency 20

Requires:
    - GOOGLE_PLACES_API_KEY in .env file
"""

import csv
import os
import math
import time
import argparse
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
from threading import Lock

import requests
from dotenv import load_dotenv


# ------------------------------------------------------------
# CONFIG
# ------------------------------------------------------------

DEFAULT_CENTER_LAT = 25.7617
DEFAULT_CENTER_LNG = -80.1918
DEFAULT_OVERALL_RADIUS_KM = 35.0
DEFAULT_GRID_ROWS = 4  # Reduced from 5 to 4 for cost savings
DEFAULT_GRID_COLS = 4  # Reduced from 5 to 4 for cost savings
DEFAULT_MAX_PAGES_PER_CENTER = 1  # Reduced from 3 to 1 for cost savings
DEFAULT_CONCURRENCY = 15  # Parallel API calls

OUTPUT_DIR = "hotel_scraper_output"
OUTPUT_CSV = os.path.join(OUTPUT_DIR, "hotels_scraped.csv")
LOG_FILE = "sadie_scraper.log"

# Bad lead keywords
BAD_LEAD_KEYWORDS = [
    "apartment", "apartments", "condo", "condos", "condominium", "condominiums",
    "vacation rental", "vacation rentals", "holiday rental", "holiday home",
    "townhouse", "townhome", "villa rental", "private home",
    "hostel", "hostels", "backpacker",
    "timeshare", "time share", "fractional ownership",
    "extended stay", "corporate housing", "furnished apartment",
    "rv park", "rv resort", "campground", "camping", "glamping",
    "day spa", "wellness center",
    "event venue", "wedding venue", "banquet hall", "conference center",
]

# Search modes - Reduced to just lodging type for cost savings
# Most hotels appear in the lodging type, saving ~80% on search calls
SEARCH_MODES = [
    {"label": "lodging_type", "type": "lodging", "keyword": None},
]


# ------------------------------------------------------------
# Logging (thread-safe)
# ------------------------------------------------------------

_log_file = None
_log_lock = Lock()

def init_log_file():
    global _log_file
    _log_file = open(LOG_FILE, "w", encoding="utf-8")

def log(msg: str) -> None:
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    with _log_lock:
        print(line)
        if _log_file:
            _log_file.write(line + "\n")
            _log_file.flush()


# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

def is_bad_lead(name: str, website: str = "") -> bool:
    text = f"{name} {website}".lower()
    for kw in BAD_LEAD_KEYWORDS:
        if kw in text:
            return True
    return False


def deg_per_km_lat():
    return 1.0 / 111.0


def deg_per_km_lng(lat_deg: float) -> float:
    return 1.0 / (111.0 * math.cos(math.radians(lat_deg)))


def build_grid_centers(center_lat, center_lng, overall_radius_km, rows, cols):
    lat_span_deg = overall_radius_km * deg_per_km_lat()
    lng_span_deg = overall_radius_km * deg_per_km_lng(center_lat)

    min_lat = center_lat - lat_span_deg
    max_lat = center_lat + lat_span_deg
    min_lng = center_lng - lng_span_deg
    max_lng = center_lng + lng_span_deg

    centers = []
    for i in range(rows):
        row_frac = 0.0 if rows == 1 else i / (rows - 1)
        lat = min_lat + (max_lat - min_lat) * row_frac
        for j in range(cols):
            col_frac = 0.0 if cols == 1 else j / (cols - 1)
            lng = min_lng + (max_lng - min_lng) * col_frac
            centers.append((lat, lng))
    return centers


# ------------------------------------------------------------
# Google Places API
# ------------------------------------------------------------

def places_nearby(api_key, lat, lng, radius_m, place_type=None, keyword=None, page_token=None):
    url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
    params = {
        "key": api_key,
        "location": f"{lat},{lng}",
        "radius": radius_m,
    }
    if place_type:
        params["type"] = place_type
    if keyword:
        params["keyword"] = keyword
    if page_token:
        params["pagetoken"] = page_token

    resp = requests.get(url, params=params, timeout=30)
    resp.raise_for_status()
    return resp.json()


# Place Details API function removed - not used for cost savings
# Enricher will find websites via Serper instead


# ------------------------------------------------------------
# Concurrent Processing
# ------------------------------------------------------------

def search_center(api_key: str, lat: float, lng: float, radius_m: int, 
                  max_pages: int, seen_place_ids: set, lock: Lock) -> list:
    """Search all modes for a single center. Returns list of place data dicts with name, place_id, lat, lng."""
    results = []
    
    for mode in SEARCH_MODES:
        page_token = None
        page_count = 0
        
        while page_count < max_pages:
            page_count += 1
            try:
                nearby = places_nearby(
                    api_key, lat, lng, radius_m,
                    place_type=mode["type"],
                    keyword=mode["keyword"],
                    page_token=page_token
                )
            except Exception as e:
                break
            
            status = nearby.get("status")
            if status not in ("OK", "ZERO_RESULTS"):
                break
            
            places = nearby.get("results", [])
            
            for r in places:
                place_id = r.get("place_id")
                name = r.get("name", "").strip()
                geometry = r.get("geometry", {}).get("location", {})
                
                if not place_id or not name:
                    continue
                
                with lock:
                    if place_id in seen_place_ids:
                        continue
                    seen_place_ids.add(place_id)
                
                # Extract data directly from Nearby Search (no Place Details needed)
                results.append({
                    "place_id": place_id,
                    "name": name,
                    "lat": geometry.get("lat", ""),
                    "lng": geometry.get("lng", ""),
                })
            
            page_token = nearby.get("next_page_token")
            if not page_token:
                break
            if max_pages > 1:  # Only sleep if we're doing pagination
                time.sleep(2.0)  # Required by Google for pagination
    
    return results


# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

def run_scraper(
    api_key: str,
    center_lat: float,
    center_lng: float,
    overall_radius_km: float,
    grid_rows: int,
    grid_cols: int,
    max_pages_per_center: int,
    max_results: int,
    output_csv: str,
    concurrency: int,
):
    log("Sadie Scraper - Google Places Hotel Scraper")
    
    spacing_km = (overall_radius_km * 2) / max(grid_rows - 1, grid_cols - 1, 1)
    search_radius_km = max(3.0, spacing_km * 0.75)
    radius_m = int(search_radius_km * 1000)
    
    centers = build_grid_centers(center_lat, center_lng, overall_radius_km, grid_rows, grid_cols)
    
    log(f"Center: {center_lat:.4f}, {center_lng:.4f} | Radius: {overall_radius_km}km")
    log(f"Grid: {grid_rows}x{grid_cols} ({len(centers)} centers) | Search radius: {search_radius_km:.1f}km")
    log(f"Concurrency: {concurrency} parallel requests")
    
    seen_place_ids = set()
    seen_lock = Lock()
    all_places = []
    hotels = []
    stats = {"candidates": 0, "kept": 0, "bad_lead": 0, "duplicates": 0, "existing": 0}
    
    # Load existing hotels from output file to avoid duplicates across runs
    existing_hotels = {}
    if os.path.exists(output_csv):
        try:
            with open(output_csv, "r", newline="", encoding="utf-8") as f:
                reader = csv.DictReader(f)
                for row in reader:
                    # Use hotel name + lat/lng as key (since we don't have website yet)
                    name = row.get("hotel", "").strip().lower()
                    lat = row.get("lat", "").strip()
                    lng = row.get("long", "").strip()
                    key = (name, lat, lng)
                    if name:
                        existing_hotels[key] = row
            if existing_hotels:
                log(f"Loaded {len(existing_hotels)} existing hotels from {output_csv}")
        except Exception as e:
            log(f"Warning: Could not read existing file: {e}")
    
    # Phase 1: Search all centers concurrently (no Place Details needed - cost savings!)
    log(f"\nPhase 1: Searching {len(centers)} grid centers...")
    log("  NOTE: Skipping Place Details API calls - Enricher will find websites via Serper")
    start_time = time.time()
    
    with ThreadPoolExecutor(max_workers=min(concurrency, len(centers))) as executor:
        futures = {
            executor.submit(
                search_center, api_key, lat, lng, radius_m, 
                max_pages_per_center, seen_place_ids, seen_lock
            ): (i, lat, lng)
            for i, (lat, lng) in enumerate(centers, 1)
        }
        
        for future in as_completed(futures):
            center_idx, lat, lng = futures[future]
            try:
                results = future.result()
                all_places.extend(results)
                log(f"  Center {center_idx}/{len(centers)}: {len(results)} places found")
            except Exception as e:
                log(f"  Center {center_idx} error: {e}")
    
    search_time = time.time() - start_time
    log(f"  Search complete: {len(all_places)} unique places in {search_time:.1f}s")
    
    # Phase 2: Process results directly from Nearby Search (no Place Details API calls)
    if all_places:
        log(f"\nPhase 2: Processing {len(all_places)} places...")
        for place in all_places:
            name = place.get("name", "").strip()
            lat = place.get("lat", "")
            lng = place.get("lng", "")
            
            if not name:
                continue
            
            stats["candidates"] += 1
            
            # Filter bad leads based on name only (no website available yet)
            if is_bad_lead(name, ""):
                stats["bad_lead"] += 1
                continue
            
            # Check if this hotel already exists in output file
            key = (name.lower(), str(lat), str(lng))
            if key in existing_hotels:
                stats["existing"] += 1
                continue
            
            # Add hotel with empty website/phone - Enricher will fill these
            hotels.append({
                "hotel": name,
                "website": "",  # Enricher will find via Serper
                "phone": "",     # Enricher will find via Serper
                "lat": lat,
                "long": lng,
            })
            stats["kept"] += 1
            
            if max_results > 0 and stats["kept"] >= max_results:
                break
    
    # Merge new hotels with existing ones
    all_hotels = list(existing_hotels.values()) + hotels
    
    # Save to CSV
    if all_hotels or existing_hotels:
        output_dir = os.path.dirname(output_csv)
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)
        
        fieldnames = ["hotel", "website", "phone", "lat", "long"]
        with open(output_csv, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(all_hotels)
    
    log(f"\n{'='*60}")
    log("COMPLETE!")
    log(f"Candidates found: {stats['candidates']}")
    log(f"New hotels added: {stats['kept']}")
    log(f"Already existed:  {stats['existing']}")
    log(f"Skipped: {stats['bad_lead']} bad leads (filtered by name)")
    log(f"NOTE: Website/phone fields empty - Enricher will find via Serper")
    if all_hotels:
        log(f"Total in file:    {len(all_hotels)}")
    log(f"Output: {output_csv}")
    log(f"{'='*60}")


def main():
    load_dotenv()
    init_log_file()
    
    parser = argparse.ArgumentParser(description="Sadie Scraper - Google Places Hotel Scraper")
    
    parser.add_argument("--center-lat", type=float, default=DEFAULT_CENTER_LAT)
    parser.add_argument("--center-lng", type=float, default=DEFAULT_CENTER_LNG)
    parser.add_argument("--overall-radius-km", type=float, default=DEFAULT_OVERALL_RADIUS_KM)
    parser.add_argument("--grid-rows", type=int, default=DEFAULT_GRID_ROWS)
    parser.add_argument("--grid-cols", type=int, default=DEFAULT_GRID_COLS)
    parser.add_argument("--max-pages-per-center", type=int, default=DEFAULT_MAX_PAGES_PER_CENTER)
    parser.add_argument("--max-results", type=int, default=0)
    parser.add_argument("--output", default=OUTPUT_CSV)
    parser.add_argument("--concurrency", "-c", type=int, default=DEFAULT_CONCURRENCY,
                        help=f"Number of concurrent API requests (default: {DEFAULT_CONCURRENCY})")
    
    args = parser.parse_args()
    
    api_key = os.getenv("GOOGLE_PLACES_API_KEY")
    if not api_key:
        raise SystemExit("Missing GOOGLE_PLACES_API_KEY in .env")
    
    run_scraper(
        api_key=api_key,
        center_lat=args.center_lat,
        center_lng=args.center_lng,
        overall_radius_km=args.overall_radius_km,
        grid_rows=args.grid_rows,
        grid_cols=args.grid_cols,
        max_pages_per_center=args.max_pages_per_center,
        max_results=args.max_results,
        output_csv=args.output,
        concurrency=args.concurrency,
    )


if __name__ == "__main__":
    main()
