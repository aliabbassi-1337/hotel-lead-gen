#!/usr/bin/env python3
"""
Sadie Grid Scraper - Geographic Grid-Based Hotel Scraper
=========================================================
Divides a region into a lat/lng grid and searches each cell.
This gets more unique results by forcing location-specific queries.

Usage:
    python3 sadie_scraper_grid.py --center-lat 25.7617 --center-lng -80.1918 --radius-km 50 --grid-size 5
    python3 sadie_scraper_grid.py --state florida --grid-size 10

Requires:
    - SERPER_SAMI in .env file
"""

import csv
import os
import sys
import math
import argparse
import time
import requests
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

# ============================================================================
# CONFIGURATION
# ============================================================================

SERPER_MAPS_URL = "https://google.serper.dev/maps"

# State bounding boxes (lat_min, lat_max, lng_min, lng_max)
STATE_BOUNDS = {
    "florida": (24.396308, 31.000968, -87.634896, -79.974307),
    "california": (32.528832, 42.009503, -124.482003, -114.131211),
    "texas": (25.837377, 36.500704, -106.645646, -93.508039),
    "new_york": (40.477399, 45.015851, -79.762418, -71.777491),
    "tennessee": (34.982924, 36.678118, -90.310298, -81.6469),
    "north_carolina": (33.752878, 36.588117, -84.321869, -75.460621),
    "georgia": (30.355644, 35.000659, -85.605165, -80.839729),
    "arizona": (31.332177, 37.004260, -114.818269, -109.045223),
    "nevada": (35.001857, 42.002207, -120.005746, -114.039648),
    "colorado": (36.992426, 41.003444, -109.060253, -102.041524),
}

# Search types - diverse terms to surface different properties
SEARCH_TYPES = [
    "hotel",
    "motel", 
    "resort",
    "boutique hotel",
    "inn",
    "lodge",
    "guest house",
    "vacation rental",
    "bed and breakfast",  # Sometimes independent
    "extended stay",
    "suites",
    "apart hotel",
]

# Modifiers to get niche results (rotated per cell)
SEARCH_MODIFIERS = [
    "",  # Plain search
    "small",
    "family",
    "cheap",
    "budget", 
    "local",
    "independent",
    "boutique",
    "cozy",
    "beachfront",
    "waterfront",
    "downtown",
]

# Big chains to filter out
SKIP_CHAINS = [
    "marriott", "hilton", "hyatt", "sheraton", "westin", "w hotel",
    "intercontinental", "holiday inn", "crowne plaza", "ihg",
    "best western", "choice hotels", "comfort inn", "quality inn",
    "radisson", "wyndham", "ramada", "days inn", "super 8", "motel 6",
    "la quinta", "travelodge", "ibis", "novotel", "mercure", "accor",
    "four seasons", "ritz-carlton", "st. regis", "fairmont",
]

_stats = {"found": 0, "skipped_chains": 0, "api_calls": 0, "duplicates": 0}
_out_of_credits = False


def log(msg: str):
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{timestamp}] {msg}")


# ============================================================================
# GRID GENERATION
# ============================================================================

def deg_to_km_lat():
    """Approximate km per degree latitude"""
    return 111.0

def deg_to_km_lng(lat):
    """Approximate km per degree longitude at given latitude"""
    return 111.0 * math.cos(math.radians(lat))

def generate_grid(lat_min, lat_max, lng_min, lng_max, grid_size):
    """
    Generate a grid of center points covering the bounding box.
    Returns list of (lat, lng, cell_radius_km) tuples.
    """
    # Calculate dimensions
    lat_range = lat_max - lat_min
    lng_range = lng_max - lng_min
    
    # Center latitude for longitude calculations
    center_lat = (lat_min + lat_max) / 2
    
    # Calculate step sizes
    lat_step = lat_range / grid_size
    lng_step = lng_range / grid_size
    
    # Cell radius (half diagonal, in km)
    cell_height_km = lat_step * deg_to_km_lat()
    cell_width_km = lng_step * deg_to_km_lng(center_lat)
    cell_radius_km = math.sqrt(cell_height_km**2 + cell_width_km**2) / 2
    
    grid_points = []
    for i in range(grid_size):
        for j in range(grid_size):
            lat = lat_min + (i + 0.5) * lat_step
            lng = lng_min + (j + 0.5) * lng_step
            grid_points.append((lat, lng, cell_radius_km))
    
    return grid_points


# ============================================================================
# SERPER API
# ============================================================================

def search_serper_maps(query: str, api_key: str, lat: float = None, lng: float = None) -> list:
    """Search Google Maps via Serper.dev with optional location."""
    global _out_of_credits
    
    if _out_of_credits:
        return []
    
    _stats["api_calls"] += 1
    
    try:
        payload = {
            "q": query,
            "num": 100,
        }
        
        # Add location with TIGHT zoom (17z = ~500m view, forces local results)
        if lat is not None and lng is not None:
            payload["ll"] = f"@{lat},{lng},17z"
        
        response = requests.post(
            SERPER_MAPS_URL,
            headers={
                "X-API-KEY": api_key,
                "Content-Type": "application/json"
            },
            json=payload,
            timeout=30
        )
        
        if response.status_code == 400:
            if "Not enough credits" in response.text:
                log("OUT OF CREDITS - stopping")
                _out_of_credits = True
                return []
            log(f"API error 400: {response.text[:100]}")
            return []
        
        if response.status_code != 200:
            log(f"API error {response.status_code}: {response.text[:100]}")
            return []
        
        data = response.json()
        return data.get("places", [])
        
    except Exception as e:
        log(f"Error: {e}")
        return []


def search_grid_cell(lat: float, lng: float, api_key: str, seen_names: set, cell_index: int = 0) -> list:
    """Search all hotel types at a specific grid cell with varied modifiers."""
    results = []
    
    # Pick 3 modifiers for this cell (rotate through them)
    num_mods = len(SEARCH_MODIFIERS)
    mod1 = SEARCH_MODIFIERS[cell_index % num_mods]
    mod2 = SEARCH_MODIFIERS[(cell_index + 4) % num_mods]
    mod3 = SEARCH_MODIFIERS[(cell_index + 8) % num_mods]
    cell_modifiers = [mod1, mod2, mod3]
    
    # Only search 4 types per cell (rotate through them) to save credits
    # but use different modifiers to get variety
    num_types = len(SEARCH_TYPES)
    types_for_cell = [
        SEARCH_TYPES[cell_index % num_types],
        SEARCH_TYPES[(cell_index + 3) % num_types],
        SEARCH_TYPES[(cell_index + 6) % num_types],
        SEARCH_TYPES[(cell_index + 9) % num_types],
    ]
    
    for search_type in types_for_cell:
        for modifier in cell_modifiers:
            if _out_of_credits:
                break
            
            # Build query with modifier
            if modifier:
                query = f"{modifier} {search_type}"
            else:
                query = search_type
            
            places = search_serper_maps(query, api_key, lat, lng)
            
            for place in places:
                name = place.get("title", "").strip()
                if not name:
                    continue
                
                name_lower = name.lower()
                
                # Skip duplicates
                if name_lower in seen_names:
                    _stats["duplicates"] += 1
                    continue
                seen_names.add(name_lower)
                
                # Skip chains
                if any(chain in name_lower for chain in SKIP_CHAINS):
                    _stats["skipped_chains"] += 1
                    continue
                
                results.append({
                    "hotel": name,
                    "website": place.get("website", ""),
                    "phone": place.get("phoneNumber", ""),
                    "lat": place.get("latitude", ""),
                    "long": place.get("longitude", ""),
                    "address": place.get("address", ""),
                    "rating": place.get("rating", ""),
                })
                _stats["found"] += 1
            
            time.sleep(0.15)  # Rate limiting
    
    return results


# ============================================================================
# MAIN
# ============================================================================

def run_grid_scraper(
    lat_min: float,
    lat_max: float, 
    lng_min: float,
    lng_max: float,
    grid_size: int,
    output_csv: str,
    api_key: str,
):
    """Run the grid-based scraper."""
    global _stats
    _stats = {"found": 0, "skipped_chains": 0, "api_calls": 0, "duplicates": 0}
    
    # Each cell does: 4 search types × 3 modifiers = 12 API calls
    calls_per_cell = 4 * 3
    total_calls = grid_size ** 2 * calls_per_cell
    
    log("Sadie Grid Scraper - Geographic Grid Search")
    log(f"Bounds: ({lat_min:.2f}, {lat_max:.2f}) x ({lng_min:.2f}, {lng_max:.2f})")
    log(f"Grid: {grid_size}x{grid_size} = {grid_size**2} cells")
    log(f"Queries per cell: {calls_per_cell} (4 types × 3 modifiers)")
    log(f"Estimated API calls: ~{total_calls}")
    
    # Generate grid
    grid_points = generate_grid(lat_min, lat_max, lng_min, lng_max, grid_size)
    log(f"Generated {len(grid_points)} grid cells")
    
    # Search each cell
    all_hotels = []
    seen_names = set()
    start_time = time.time()
    
    for i, (lat, lng, radius) in enumerate(grid_points):
        if _out_of_credits:
            break
            
        log(f"[{i+1}/{len(grid_points)}] Cell ({lat:.3f}, {lng:.3f}) radius ~{radius:.1f}km")
        
        hotels = search_grid_cell(lat, lng, api_key, seen_names, i)
        all_hotels.extend(hotels)
        
        if hotels:
            log(f"  -> {len(hotels)} new hotels (total: {len(all_hotels)})")
    
    # Save results
    if all_hotels:
        output_dir = os.path.dirname(output_csv)
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)
        
        fieldnames = ["hotel", "website", "phone", "lat", "long", "address", "rating"]
        with open(output_csv, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(all_hotels)
    
    elapsed = time.time() - start_time
    with_website = sum(1 for h in all_hotels if h.get("website"))
    
    log("")
    log("=" * 60)
    log("COMPLETE!")
    log(f"Hotels found:      {_stats['found']}")
    log(f"Duplicates:        {_stats['duplicates']}")
    log(f"Skipped (chains):  {_stats['skipped_chains']}")
    log(f"With website:      {with_website}")
    log(f"API calls:         {_stats['api_calls']}")
    log(f"Time:              {elapsed:.1f}s")
    log(f"Output:            {output_csv}")
    log("=" * 60)


def main():
    parser = argparse.ArgumentParser(description="Grid-based hotel scraper")
    
    # State-based bounds
    parser.add_argument("--state", type=str, choices=list(STATE_BOUNDS.keys()),
                        help="Use predefined state bounds")
    
    # Custom bounds
    parser.add_argument("--lat-min", type=float, help="Minimum latitude")
    parser.add_argument("--lat-max", type=float, help="Maximum latitude")
    parser.add_argument("--lng-min", type=float, help="Minimum longitude")
    parser.add_argument("--lng-max", type=float, help="Maximum longitude")
    
    # Center + radius (alternative to bounds)
    parser.add_argument("--center-lat", type=float, help="Center latitude")
    parser.add_argument("--center-lng", type=float, help="Center longitude")
    parser.add_argument("--radius-km", type=float, default=50, help="Radius in km")
    
    # Grid settings
    parser.add_argument("--grid-size", type=int, default=5, 
                        help="Grid divisions (5 = 5x5 = 25 cells)")
    
    parser.add_argument("--output", "-o", default="scraper_output/custom/custom_grid.csv")
    parser.add_argument("--api-key", type=str, help="Serper API key")
    parser.add_argument("--estimate", action="store_true", help="Only show cost estimate")
    
    args = parser.parse_args()
    
    # Get API key
    api_key = args.api_key or os.environ.get("SERPER_SAMI", "")
    if not api_key and not args.estimate:
        log("ERROR: No API key. Set SERPER_SAMI in .env or use --api-key")
        sys.exit(1)
    
    # Determine bounds
    if args.state:
        lat_min, lat_max, lng_min, lng_max = STATE_BOUNDS[args.state]
        output = args.output if args.output != "scraper_output/grid_hotels.csv" else f"scraper_output/{args.state}/{args.state}_grid.csv"
    elif args.center_lat and args.center_lng:
        # Convert center + radius to bounds
        lat_deg = args.radius_km / 111.0
        lng_deg = args.radius_km / (111.0 * math.cos(math.radians(args.center_lat)))
        lat_min = args.center_lat - lat_deg
        lat_max = args.center_lat + lat_deg
        lng_min = args.center_lng - lng_deg
        lng_max = args.center_lng + lng_deg
        output = args.output
    elif args.lat_min and args.lat_max and args.lng_min and args.lng_max:
        lat_min, lat_max = args.lat_min, args.lat_max
        lng_min, lng_max = args.lng_min, args.lng_max
        output = args.output
    else:
        log("ERROR: Provide --state, --center-lat/lng, or --lat-min/max/lng-min/max")
        sys.exit(1)
    
    # Cost estimate: 4 types × 3 modifiers = 12 calls per cell
    total_cells = args.grid_size ** 2
    calls_per_cell = 4 * 3
    total_queries = total_cells * calls_per_cell
    
    if args.estimate:
        log(f"COST ESTIMATE")
        log(f"Grid: {args.grid_size}x{args.grid_size} = {total_cells} cells")
        log(f"Queries per cell: {calls_per_cell} (4 types × 3 modifiers)")
        log(f"Total API calls: {total_queries}")
        log(f"Estimated credits: {total_queries}")
        return
    
    run_grid_scraper(
        lat_min, lat_max, lng_min, lng_max,
        args.grid_size, output, api_key
    )


if __name__ == "__main__":
    main()

