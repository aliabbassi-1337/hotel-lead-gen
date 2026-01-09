#!/usr/bin/env python3
"""
Sadie OSM Scraper - OpenStreetMap Hotel Extractor
==================================================
Extracts ALL hotels from OpenStreetMap using the Overpass API.
100% free, no API key required, no rate limits.

Usage:
    python3 sadie_scraper_osm.py --state florida
    python3 sadie_scraper_osm.py --city "Miami, Florida"
    python3 sadie_scraper_osm.py --bbox 25.7 25.9 -80.3 -80.1

Note: OSM data is volunteer-contributed, so coverage varies.
      May not have phone/website for all properties.
"""

import csv
import os
import sys
import argparse
import time
import requests
from datetime import datetime

# ============================================================================
# CONFIGURATION
# ============================================================================

# Overpass API endpoints (fallback order)
OVERPASS_URLS = [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
    "https://maps.mail.ru/osm/tools/overpass/api/interpreter",
]

# State bounding boxes (min_lat, max_lat, min_lng, max_lng)
STATE_BOUNDS = {
    # US States
    "alabama": (30.137521, 35.008028, -88.473227, -84.888246),
    "alaska": (51.214183, 71.365162, -179.148909, -129.979511),
    "arizona": (31.332177, 37.004260, -114.818269, -109.045223),
    "arkansas": (33.004106, 36.499767, -94.617919, -89.644395),
    "california": (32.528832, 42.009503, -124.482003, -114.131211),
    "colorado": (36.992426, 41.003444, -109.060253, -102.041524),
    "connecticut": (40.950943, 42.050587, -73.727775, -71.786994),
    "delaware": (38.451013, 39.839007, -75.789023, -74.984165),
    "florida": (24.396308, 31.000968, -87.634896, -79.974307),
    "georgia": (30.355644, 35.000659, -85.605165, -80.839729),
    "hawaii": (18.910361, 28.402123, -178.334698, -154.806773),
    "idaho": (41.988057, 49.001146, -117.243027, -111.043564),
    "illinois": (36.970298, 42.508481, -91.513079, -87.494756),
    "indiana": (37.771742, 41.760592, -88.097892, -84.784579),
    "iowa": (40.375501, 43.501196, -96.639704, -90.140061),
    "kansas": (36.993016, 40.003162, -102.051744, -94.588413),
    "kentucky": (36.497129, 39.147458, -89.571509, -81.964971),
    "louisiana": (28.928609, 33.019457, -94.043147, -88.817017),
    "maine": (42.977764, 47.459686, -71.083924, -66.949895),
    "maryland": (37.911717, 39.723043, -79.487651, -75.048939),
    "massachusetts": (41.186328, 42.886589, -73.508142, -69.928393),
    "michigan": (41.696118, 48.306063, -90.418136, -82.122971),
    "minnesota": (43.499356, 49.384358, -97.239209, -89.491739),
    "mississippi": (30.173943, 34.996052, -91.655009, -88.097888),
    "missouri": (35.995683, 40.613640, -95.774704, -89.098843),
    "montana": (44.358221, 49.001390, -116.050003, -104.039138),
    "nebraska": (39.999998, 43.001708, -104.053514, -95.308290),
    "nevada": (35.001857, 42.002207, -120.005746, -114.039648),
    "new_hampshire": (42.696985, 45.305476, -72.557247, -70.610621),
    "new_jersey": (38.788657, 41.357423, -75.563586, -73.893979),
    "new_mexico": (31.332301, 37.000232, -109.050173, -103.001964),
    "new_york": (40.477399, 45.015851, -79.762418, -71.777491),
    "north_carolina": (33.752878, 36.588117, -84.321869, -75.460621),
    "north_dakota": (45.935054, 49.000574, -104.048915, -96.554507),
    "ohio": (38.403202, 41.977523, -84.820159, -80.518693),
    "oklahoma": (33.615833, 37.002206, -103.002565, -94.430662),
    "oregon": (41.991794, 46.292035, -124.566244, -116.463504),
    "pennsylvania": (39.719799, 42.269860, -80.519891, -74.689516),
    "rhode_island": (41.146339, 42.018798, -71.862772, -71.120570),
    "south_carolina": (32.034600, 35.215402, -83.353928, -78.541039),
    "south_dakota": (42.479635, 45.945716, -104.057698, -96.436589),
    "tennessee": (34.982924, 36.678118, -90.310298, -81.6469),
    "texas": (25.837377, 36.500704, -106.645646, -93.508039),
    "utah": (36.997968, 42.001567, -114.052962, -109.041058),
    "vermont": (42.726853, 45.016659, -73.437740, -71.464555),
    "virginia": (36.540738, 39.466012, -83.675395, -75.242266),
    "washington": (45.543541, 49.002494, -124.848974, -116.915989),
    "west_virginia": (37.201483, 40.638801, -82.644739, -77.719519),
    "wisconsin": (42.491983, 47.080621, -92.888114, -86.805415),
    "wyoming": (40.994746, 45.005904, -111.056888, -104.052154),
    # Australia
    "new_south_wales": (-37.505032, -28.157021, 140.999260, 153.638727),
    "victoria": (-39.159543, -33.980423, 140.961682, 149.976679),
    "queensland": (-29.178459, -10.668186, 137.994568, 153.551926),
}

# Tourism types to search for
TOURISM_TYPES = [
    "hotel",
    "motel", 
    "guest_house",
    "hostel",
    "resort",
    "bed_and_breakfast",
    "apartment",
    "chalet",
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


def log(msg: str):
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{timestamp}] {msg}")


# ============================================================================
# OVERPASS API QUERIES
# ============================================================================

def build_overpass_query(min_lat: float, max_lat: float, min_lng: float, max_lng: float) -> str:
    """Build Overpass QL query for all hotel types in bounding box."""
    
    # Build union of all tourism types
    tourism_queries = []
    for tourism_type in TOURISM_TYPES:
        tourism_queries.append(f'node["tourism"="{tourism_type}"]({min_lat},{min_lng},{max_lat},{max_lng});')
        tourism_queries.append(f'way["tourism"="{tourism_type}"]({min_lat},{min_lng},{max_lat},{max_lng});')
        tourism_queries.append(f'relation["tourism"="{tourism_type}"]({min_lat},{min_lng},{max_lat},{max_lng});')
    
    # Also get amenity=hotel (some are tagged this way)
    tourism_queries.append(f'node["amenity"="hotel"]({min_lat},{min_lng},{max_lat},{max_lng});')
    tourism_queries.append(f'way["amenity"="hotel"]({min_lat},{min_lng},{max_lat},{max_lng});')
    
    query = f"""
[out:json][timeout:300];
(
  {chr(10).join(tourism_queries)}
);
out center meta;
"""
    return query


def query_overpass(query: str) -> list:
    """Execute Overpass API query and return elements. Tries multiple endpoints."""
    log("Querying Overpass API (this may take a minute for large areas)...")

    for i, url in enumerate(OVERPASS_URLS):
        try:
            log(f"  Trying endpoint {i+1}/{len(OVERPASS_URLS)}: {url.split('/')[2]}")

            response = requests.post(
                url,
                data={"data": query},
                timeout=120,
                headers={"User-Agent": "SadieHotelScraper/1.0"}
            )

            if response.status_code == 429:
                log("  Rate limited - trying next endpoint...")
                continue

            if response.status_code in (502, 503, 504):
                log(f"  Server error {response.status_code} - trying next endpoint...")
                continue

            if response.status_code != 200:
                log(f"  Error {response.status_code}: {response.text[:100]}")
                continue

            data = response.json()
            elements = data.get("elements", [])
            if elements:
                log(f"  Success! Got {len(elements)} results")
            return elements

        except requests.exceptions.Timeout:
            log(f"  Timeout - trying next endpoint...")
            continue
        except Exception as e:
            log(f"  Error: {e} - trying next endpoint...")
            continue

    log("All endpoints failed")
    return []


def geocode_city(city_name: str) -> tuple:
    """Get bounding box for a city using Nominatim."""
    try:
        log(f"Geocoding: {city_name}")
        
        response = requests.get(
            "https://nominatim.openstreetmap.org/search",
            params={
                "q": city_name,
                "format": "json",
                "limit": 1,
            },
            headers={"User-Agent": "SadieHotelScraper/1.0"},
            timeout=30
        )
        
        if response.status_code != 200:
            return None
        
        results = response.json()
        if not results:
            return None
        
        bbox = results[0].get("boundingbox")
        if bbox:
            # Nominatim returns [min_lat, max_lat, min_lng, max_lng]
            return (float(bbox[0]), float(bbox[1]), float(bbox[2]), float(bbox[3]))
        
        return None
        
    except Exception as e:
        log(f"Geocoding error: {e}")
        return None


# ============================================================================
# DATA EXTRACTION
# ============================================================================

def extract_hotel_data(elements: list) -> list:
    """Extract hotel data from Overpass elements."""
    hotels = []
    seen_names = set()
    skipped_chains = 0
    
    for element in elements:
        tags = element.get("tags", {})
        
        # Get name
        name = tags.get("name", "").strip()
        if not name:
            continue
        
        name_lower = name.lower()
        
        # Skip duplicates
        if name_lower in seen_names:
            continue
        seen_names.add(name_lower)
        
        # Skip chains
        if any(chain in name_lower for chain in SKIP_CHAINS):
            skipped_chains += 1
            continue
        
        # Get coordinates
        if element.get("type") == "node":
            lat = element.get("lat")
            lng = element.get("lon")
        else:
            # For ways/relations, use center point
            center = element.get("center", {})
            lat = center.get("lat")
            lng = center.get("lon")
        
        if not lat or not lng:
            continue
        
        # Build address from tags
        address_parts = []
        if tags.get("addr:housenumber"):
            address_parts.append(tags["addr:housenumber"])
        if tags.get("addr:street"):
            address_parts.append(tags["addr:street"])
        if tags.get("addr:city"):
            address_parts.append(tags["addr:city"])
        if tags.get("addr:state"):
            address_parts.append(tags["addr:state"])
        if tags.get("addr:postcode"):
            address_parts.append(tags["addr:postcode"])
        
        address = ", ".join(address_parts) if address_parts else ""
        
        hotels.append({
            "hotel": name,
            "website": tags.get("website", "") or tags.get("contact:website", ""),
            "phone": tags.get("phone", "") or tags.get("contact:phone", ""),
            "lat": lat,
            "long": lng,
            "address": address,
            "rating": "",  # OSM doesn't have ratings
            "osm_id": f"{element.get('type')}/{element.get('id')}",
            "tourism_type": tags.get("tourism", tags.get("amenity", "")),
        })
    
    log(f"Skipped {skipped_chains} chain hotels")
    return hotels


# ============================================================================
# MAIN
# ============================================================================

def run_osm_scraper(
    min_lat: float,
    max_lat: float,
    min_lng: float,
    max_lng: float,
    output_csv: str,
):
    """Run the OSM-based scraper."""
    log("Sadie OSM Scraper - OpenStreetMap Hotel Extractor")
    log(f"Bounds: ({min_lat:.2f}, {max_lat:.2f}) x ({min_lng:.2f}, {max_lng:.2f})")
    log(f"Tourism types: {len(TOURISM_TYPES)}")
    log("")
    
    # Build and execute query
    query = build_overpass_query(min_lat, max_lat, min_lng, max_lng)
    elements = query_overpass(query)
    
    if not elements:
        log("No results found")
        return
    
    log(f"Found {len(elements)} raw OSM elements")
    
    # Extract hotel data
    hotels = extract_hotel_data(elements)
    log(f"Extracted {len(hotels)} unique hotels (after filtering)")
    
    # Count stats
    with_website = sum(1 for h in hotels if h.get("website"))
    with_phone = sum(1 for h in hotels if h.get("phone"))
    with_address = sum(1 for h in hotels if h.get("address"))
    
    log(f"  With website: {with_website} ({100*with_website/len(hotels):.1f}%)")
    log(f"  With phone:   {with_phone} ({100*with_phone/len(hotels):.1f}%)")
    log(f"  With address: {with_address} ({100*with_address/len(hotels):.1f}%)")
    
    # Save results
    if hotels:
        output_dir = os.path.dirname(output_csv)
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)
        
        fieldnames = ["hotel", "website", "phone", "lat", "long", "address", "rating", "osm_id", "tourism_type"]
        with open(output_csv, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(hotels)
        
        log(f"\n✅ Saved {len(hotels)} hotels to: {output_csv}")


def main():
    parser = argparse.ArgumentParser(description="OpenStreetMap hotel scraper")
    
    # Location options
    parser.add_argument("--state", type=str, choices=list(STATE_BOUNDS.keys()),
                        help="Use predefined state bounds")
    parser.add_argument("--city", type=str, 
                        help="City name to geocode (e.g., 'Miami, Florida')")
    parser.add_argument("--bbox", type=float, nargs=4,
                        metavar=("MIN_LAT", "MAX_LAT", "MIN_LNG", "MAX_LNG"),
                        help="Custom bounding box")
    
    parser.add_argument("--output", "-o", default=None,
                        help="Output CSV file")
    
    args = parser.parse_args()
    
    # Determine bounds
    # Timestamp for unique filenames
    timestamp = datetime.now().strftime("%Y%m%d_%H%M")

    if args.state:
        min_lat, max_lat, min_lng, max_lng = STATE_BOUNDS[args.state]
        output = args.output or f"scraper_output/{args.state}/{args.state}_osm_{timestamp}.csv"
    elif args.city:
        bounds = geocode_city(args.city)
        if not bounds:
            log(f"Could not geocode: {args.city}")
            sys.exit(1)
        min_lat, max_lat, min_lng, max_lng = bounds
        # Extract state from city string (e.g., "Miami, Florida" -> florida)
        parts = args.city.split(",")
        city_name = parts[0].strip().lower().replace(" ", "_")
        state_name = parts[1].strip().lower().replace(" ", "_") if len(parts) > 1 else "unknown"
        output = args.output or f"scraper_output/{state_name}/{city_name}_osm_{timestamp}.csv"
    elif args.bbox:
        min_lat, max_lat, min_lng, max_lng = args.bbox
        output = args.output or f"scraper_output/custom/custom_osm_{timestamp}.csv"
    else:
        log("ERROR: Provide --state, --city, or --bbox")
        sys.exit(1)
    
    run_osm_scraper(min_lat, max_lat, min_lng, max_lng, output)


if __name__ == "__main__":
    main()
