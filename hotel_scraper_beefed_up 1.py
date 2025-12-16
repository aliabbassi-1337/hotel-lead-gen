#!/usr/bin/env python3
import os
import time
import math
import csv
import argparse
from urllib.parse import urlparse

import requests
from dotenv import load_dotenv

# ------------------------------------------------------------
# CONFIG / DEFAULTS
# ------------------------------------------------------------

# Default: Miami
DEFAULT_CENTER_LAT = 25.7617
DEFAULT_CENTER_LNG = -80.1918

# Overall area radius (km) to cover around the center
DEFAULT_OVERALL_RADIUS_KM = 35.0  # rough "Miami metro" bubble

# Default grid
DEFAULT_GRID_ROWS = 5
DEFAULT_GRID_COLS = 5

# If search_radius_km <= 0, it will be derived from OVERALL_RADIUS_KM & grid
DEFAULT_SEARCH_RADIUS_KM = 0.0

# Max pages per nearby search (each page up to 20 results; 3 pages = 60)
DEFAULT_MAX_PAGES_PER_CENTER_PER_MODE = 3

# File to save
OUTPUT_CSV = "hotels_filtered.csv"

# Domains that are true OTA / aggregators we don't want as "direct" hotel sites
OTA_DOMAINS_BLACKLIST = [
    "booking.com",
    "expedia.com",
    "hotels.com",
    "airbnb.com",
    "tripadvisor.com",
    "priceline.com",
    "agoda.com",
    "orbitz.com",
    "kayak.com",
    "travelocity.com",
    "hostelworld.com",
    "vrbo.com",
    "ebookers.com",
    "lastminute.com",
    "trivago.com",
]

# Strings that usually indicate apartments / condos / vacation rentals
APARTMENT_KEYWORDS = [
    "apartment",
    "apartments",
    "condo",
    "condominiums",
    "residence",
    "residences",
    "vacation rental",
    "vacation rentals",
    "airbnb",
    "townhouse",
]

# Extra search passes per center to drag out more hotels
# label is just for logging
SEARCH_MODES = [
    {"label": "lodging_type", "type": "lodging", "keyword": None},
    {"label": "hotel_keyword", "type": None, "keyword": "hotel"},
    {"label": "motel_keyword", "type": None, "keyword": "motel"},
    {"label": "resort_keyword", "type": None, "keyword": "resort"},
    {"label": "inn_keyword", "type": None, "keyword": "inn"},
]


# ------------------------------------------------------------
# UTILS
# ------------------------------------------------------------

def deg_per_km_lat():
    return 1.0 / 111.0  # 1 degree ~111 km


def deg_per_km_lng(lat_deg: float) -> float:
    # 1 degree of longitude shrinks with cos(latitude)
    return 1.0 / (111.0 * math.cos(math.radians(lat_deg)))


def build_grid_centers(center_lat, center_lng, overall_radius_km, rows, cols):
    """
    Build a grid of (lat, lng) centers covering a square around the center.

    We span +/- overall_radius_km in both lat & lng, then place rows*cols centers
    evenly over that square.
    """
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


def extract_domain(url: str) -> str:
    try:
        parsed = urlparse(url)
        host = parsed.netloc.lower()
        # strip leading www.
        if host.startswith("www."):
            host = host[4:]
        return host
    except Exception:
        return ""


def is_ota_aggregator(website: str) -> bool:
    """
    Only skip *true* OTA / aggregators. Brand chains are OK.
    """
    if not website:
        return False
    domain = extract_domain(website)
    for bad in OTA_DOMAINS_BLACKLIST:
        if domain.endswith(bad):
            return True
    return False


def looks_like_apartment(name: str, website: str) -> bool:
    name_l = (name or "").lower()
    web_l = (website or "").lower()
    for kw in APARTMENT_KEYWORDS:
        if kw in name_l or kw in web_l:
            return True
    return False


def has_website(place_detail: dict) -> bool:
    website = place_detail.get("website")
    if not website:
        return False
    website = website.strip()
    if not website:
        return False
    return True


# ------------------------------------------------------------
# GOOGLE PLACES HELPERS
# ------------------------------------------------------------

def places_nearby(api_key, lat, lng, radius_m, place_type=None, keyword=None, page_token=None):
    """
    One call to Places Nearby Search.
    """
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

    resp = requests.get(url, params=params)
    resp.raise_for_status()
    return resp.json()


def place_details(api_key, place_id):
    """
    Fetch fields we actually care about: name, geometry, website, business status, url.
    """
    url = "https://maps.googleapis.com/maps/api/place/details/json"
    params = {
        "key": api_key,
        "place_id": place_id,
        "fields": "name,geometry,website,business_status,url",
    }
    resp = requests.get(url, params=params)
    resp.raise_for_status()
    return resp.json()


# ------------------------------------------------------------
# MAIN LOGIC
# ------------------------------------------------------------

def main():
    load_dotenv()

    parser = argparse.ArgumentParser(
        description="Fetch hotels for a given area using Google Places (aggressive multi-mode)."
    )
    parser.add_argument(
        "--max-results",
        type=int,
        default=0,
        help="Maximum number of *kept* hotels to save (0 = no limit).",
    )
    parser.add_argument(
        "--center-lat",
        type=float,
        default=DEFAULT_CENTER_LAT,
        help="Center latitude (default: Miami).",
    )
    parser.add_argument(
        "--center-lng",
        type=float,
        default=DEFAULT_CENTER_LNG,
        help="Center longitude (default: Miami).",
    )
    parser.add_argument(
        "--overall-radius-km",
        type=float,
        default=DEFAULT_OVERALL_RADIUS_KM,
        help="Overall radius in km to cover around center (default: 35).",
    )
    parser.add_argument(
        "--grid-rows",
        type=int,
        default=DEFAULT_GRID_ROWS,
        help="Grid rows (default: 5). Increase for more/smaller tiles.",
    )
    parser.add_argument(
        "--grid-cols",
        type=int,
        default=DEFAULT_GRID_COLS,
        help="Grid cols (default: 5). Increase for more/smaller tiles.",
    )
    parser.add_argument(
        "--search-radius-km",
        type=float,
        default=DEFAULT_SEARCH_RADIUS_KM,
        help="Per-center search radius in km. If <=0, derived from grid+overall-radius.",
    )
    parser.add_argument(
        "--max-pages-per-center",
        type=int,
        default=DEFAULT_MAX_PAGES_PER_CENTER_PER_MODE,
        help="Max pages per center *per search mode* (default: 3 -> up to 60 results/mode).",
    )
    parser.add_argument(
        "--include-apartments",
        action="store_true",
        help="Do NOT filter out apartments/condos/vacation rentals.",
    )
    parser.add_argument(
        "--include-ota",
        action="store_true",
        help="Do NOT filter out OTA/aggregator domains (booking.com, expedia, etc).",
    )
    parser.add_argument(
        "--include-no-website",
        action="store_true",
        help="Keep places even if they have no website (not ideal for booking-engine work).",
    )
    parser.add_argument(
        "--test",
        action="store_true",
        help="TEST MODE: do everything except the paid API calls.",
    )
    args = parser.parse_args()

    api_key = os.getenv("GOOGLE_PLACES_API_KEY")
    if not api_key:
        raise SystemExit("Missing GOOGLE_PLACES_API_KEY in .env")

    center_lat = args.center_lat
    center_lng = args.center_lng
    max_results = args.max_results
    overall_radius_km = args.overall_radius_km
    grid_rows = args.grid_rows
    grid_cols = args.grid_cols

    # Derive search radius per center if not explicitly set
    if args.search_radius_km > 0:
        search_radius_km = args.search_radius_km
    else:
        # spacing between centers in km
        spacing_km = (overall_radius_km * 2) / max(grid_rows - 1, grid_cols - 1, 1)
        # radius a bit bigger than half spacing to ensure overlap
        search_radius_km = max(3.0, spacing_km * 0.75)

    radius_m = int(search_radius_km * 1000)

    centers = build_grid_centers(center_lat, center_lng, overall_radius_km, grid_rows, grid_cols)

    mode_label = ""
    print(
        f"Fetching nearby lodging from Google Places{' (TEST MODE)' if args.test else ''}..."
    )
    print(
        f"Overall center: {center_lat:.6f},{center_lng:.6f} | Overall radius: {overall_radius_km} km"
    )
    print(
        f"Grid: {grid_rows}x{grid_cols} ({len(centers)} centers) | Per-center search radius: {search_radius_km:.1f} km (~{radius_m} m)"
    )
    print(
        f"Search modes per center: {[m['label'] for m in SEARCH_MODES]}"
    )
    print(
        f"Max pages per center per mode: {args.max_pages_per_center} (each page up to 20 results)"
    )
    print(f"Max results to keep (after filters): {max_results or 'no limit'} {mode_label}")
    print("------------------------------------------------------------\n")

    seen_place_ids = set()
    kept_hotels = []

    stats = {
        "candidates": 0,
        "kept": 0,
        "no_website": 0,
        "ota": 0,
        "apartment": 0,
        "bad_data": 0,
        "duplicates": 0,
    }

    center_index = 0
    total_centers = len(centers)

    for lat, lng in centers:
        center_index += 1
        print(f"=== CENTER {center_index}/{total_centers} : {lat:.6f},{lng:.6f} ===\n")

        if args.test:
            print("TEST MODE: skipping API calls for this center.\n")
            continue

        for mode in SEARCH_MODES:
            print(f"  -- MODE: {mode['label']} (type={mode['type']}, keyword={mode['keyword']}) --")

            page_token = None
            page_count = 0

            while True:
                if page_count >= args.max_pages_per_center:
                    break

                page_count += 1
                try:
                    nearby = places_nearby(
                        api_key,
                        lat,
                        lng,
                        radius_m,
                        place_type=mode["type"],
                        keyword=mode["keyword"],
                        page_token=page_token,
                    )
                except Exception as e:
                    print(f"  Error calling nearby search: {e}")
                    break

                status = nearby.get("status")
                if status not in ("OK", "ZERO_RESULTS"):
                    print(f"  NearbySearch status: {status}")
                    if status == "OVER_QUERY_LIMIT":
                        print("  Hit OVER_QUERY_LIMIT. Stopping further calls.")
                        break
                    if status == "REQUEST_DENIED":
                        print("  REQUEST_DENIED (check billing / key restrictions).")
                        break

                results = nearby.get("results", [])
                if not results:
                    break

                for r in results:
                    place_id = r.get("place_id")
                    name = r.get("name", "").strip()

                    if not place_id or not name:
                        stats["bad_data"] += 1
                        continue

                    if place_id in seen_place_ids:
                        stats["duplicates"] += 1
                        continue

                    # Mark seen so we don't request details twice
                    seen_place_ids.add(place_id)

                    print(f"[CANDIDATE] '{name}' | place_id={place_id}")

                    # Fetch details
                    try:
                        details = place_details(api_key, place_id)
                    except Exception as e:
                        print(f"  Error fetching details: {e}")
                        stats["bad_data"] += 1
                        continue

                    d_status = details.get("status")
                    if d_status != "OK":
                        print(f"  Details status: {d_status}")
                        stats["bad_data"] += 1
                        continue

                    result = details.get("result", {})
                    website = (result.get("website") or "").strip()
                    business_status = result.get("business_status", "")
                    geometry = result.get("geometry", {})
                    location = geometry.get("location", {})
                    plat = location.get("lat")
                    plng = location.get("lng")

                    print(f"  website: {website or 'None'}")
                    print(f"  status:  {business_status or 'UNKNOWN'}")
                    print(
                        f"  coords:  {plat if plat is not None else '??'}, {plng if plng is not None else '??'}"
                    )

                    stats["candidates"] += 1

                    # Require website (for booking-engine work) unless flag says keep
                    if not website:
                        if not args.include_no_website:
                            print("  [SKIP] no website")
                            stats["no_website"] += 1
                            print()
                            continue
                        else:
                            print("  [KEEP - no website but include_no_website flag set]")

                    # Skip obvious OTAs / aggregators (booking.com, expedia, etc) unless flag says keep
                    if is_ota_aggregator(website) and not args.include_ota:
                        print("  [SKIP] OTA / aggregator website")
                        stats["ota"] += 1
                        print()
                        continue

                    # Skip obvious apartments / condos / vacation rentals unless flag says keep
                    if looks_like_apartment(name, website) and not args.include_apartments:
                        print("  [SKIP] looks like apartment/condo/vacation rental")
                        stats["apartment"] += 1
                        print()
                        continue

                    # If we got here, we KEEP it
                    print(f"  [KEEP] {name} | {website}")
                    kept_hotels.append(
                        {
                            "name": name,
                            "lat": plat,
                            "lng": plng,
                            "website": website,
                            "business_status": business_status,
                            "place_id": place_id,
                        }
                    )
                    stats["kept"] += 1
                    print()

                    # Stop if we hit max_results
                    if max_results > 0 and stats["kept"] >= max_results:
                        break

                if max_results > 0 and stats["kept"] >= max_results:
                    break

                page_token = nearby.get("next_page_token")
                if not page_token:
                    break

                # Google requires a short delay before using next_page_token
                time.sleep(2.0)

            print()  # end mode

            if max_results > 0 and stats["kept"] >= max_results:
                break

        print()  # end center

        if max_results > 0 and stats["kept"] >= max_results:
            break

    # --------------------------------------------------------
    # SAVE CSV
    # --------------------------------------------------------
    if kept_hotels:
        with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(
                ["name", "latitude", "longitude", "website", "business_status", "place_id"]
            )
            for h in kept_hotels:
                writer.writerow(
                    [
                        h["name"],
                        h["lat"],
                        h["lng"],
                        h["website"],
                        h["business_status"],
                        h["place_id"],
                    ]
                )

        print("============================================================")
        print(f"Total unique candidates seen (across ALL centers): {stats['candidates'] + stats['duplicates']}")
        print(f"Kept:                                {stats['kept']}")
        print(f"Skipped (no website):                {stats['no_website']}")
        print(f"Skipped (OTA website):               {stats['ota']}")
        print(f"Skipped (apartment-ish):             {stats['apartment']}")
        print(f"Skipped (bad data / errors):         {stats['bad_data']}")
        print(f"Duplicates (seen multiple centers):  {stats['duplicates']}")
        print("============================================================")
        print(f"Saved {stats['kept']} hotels to {OUTPUT_CSV}")
    else:
        print("No hotels kept after filtering.")

    print("Done.")


if __name__ == "__main__":
    main()
