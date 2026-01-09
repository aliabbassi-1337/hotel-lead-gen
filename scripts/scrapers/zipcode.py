#!/usr/bin/env python3
"""
Sadie Zip Code Scraper - Search Hotels by Zip Code
===================================================
Instead of grid coordinates, searches by zip code.
Google treats "hotels in 33139" very differently than "hotels near lat,lng".
This forces more localized, less popularity-biased results.

Usage:
    python3 sadie_scraper_zipcode.py --state florida
    python3 sadie_scraper_zipcode.py --zipcodes 33139 33140 33141 33142
    python3 sadie_scraper_zipcode.py --zipcode-file florida_zipcodes.txt

Requires:
    - SERPER_SAMI in .env file
"""

import csv
import os
import sys
import argparse
import time
import requests
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
from threading import Lock
from dotenv import load_dotenv

load_dotenv()

# ============================================================================
# CONFIGURATION
# ============================================================================

SERPER_MAPS_URL = "https://google.serper.dev/maps"

# State zip code files (real zip codes, not generated)
# Download from: https://gist.github.com/erichurst/7882666
STATE_ZIPCODE_FILES = {
    "florida": "data/florida_zipcodes.txt",
    "california": "data/california_zipcodes.txt",
}

# Fallback: State zip code prefixes for states without files
STATE_ZIP_PREFIXES = {
    "florida": list(range(320, 350)),  # 320-349
    "california": list(range(900, 962)),  # 900-961
    "texas": list(range(750, 800)) + list(range(733, 750)) + list(range(885, 886)),
    "new_york": list(range(100, 150)),  # 100-149
    "tennessee": list(range(370, 386)),  # 370-385
    "north_carolina": list(range(270, 290)),  # 270-289
    "georgia": list(range(300, 320)) + list(range(398, 400)),  # 300-319, 398-399
    "maryland": list(range(206, 220)),  # 206-219
    "virginia": list(range(220, 247)),  # 220-246
}

# Search types (fewer than grid scraper, since we're searching more locations)
SEARCH_TYPES = [
    "hotels",
    "motels",
    "resorts",
    "inns",
    "lodge",
    "boutique hotel",
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
_seen_names = set()
_seen_lock = Lock()


def log(msg: str):
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{timestamp}] {msg}")


# ============================================================================
# ZIP CODE GENERATION
# ============================================================================

def get_zipcodes_for_state(state: str) -> list:
    """
    Get real zip codes for a state from downloaded files.
    Falls back to generated zip codes if file doesn't exist.
    """
    # Try to load from file first
    zipcode_file = STATE_ZIPCODE_FILES.get(state)
    if not zipcode_file:
        zipcode_file = f"data/{state}_zipcodes.txt"

    if os.path.exists(zipcode_file):
        with open(zipcode_file, 'r') as f:
            zipcodes = [line.strip() for line in f if line.strip()]
        log(f"Loaded {len(zipcodes)} real zip codes from {zipcode_file}")
        return zipcodes

    # Fallback: generate from prefixes (less accurate)
    log(f"No zip code file found for {state}, generating from prefixes...")
    prefixes = STATE_ZIP_PREFIXES.get(state, [])
    if not prefixes:
        log(f"Unknown state: {state}")
        return []

    zipcodes = []
    for prefix in prefixes:
        # Generate XX000 to XX999 for each prefix (sample every 10)
        for suffix in range(0, 1000, 10):
            zipcode = f"{prefix:03d}{suffix:02d}"
            zipcodes.append(zipcode)

    log(f"Generated {len(zipcodes)} zip codes (sampled)")
    return zipcodes


def get_zipcodes_from_file(filepath: str) -> list:
    """Load zip codes from a file (one per line)."""
    try:
        with open(filepath, "r") as f:
            return [line.strip() for line in f if line.strip().isdigit()]
    except Exception as e:
        log(f"Error reading zip codes: {e}")
        return []


# ============================================================================
# SERPER API
# ============================================================================

def search_serper_maps(query: str, api_key: str) -> list:
    """Search Google Maps via Serper.dev."""
    global _out_of_credits
    
    if _out_of_credits:
        return []
    
    _stats["api_calls"] += 1
    
    try:
        payload = {
            "q": query,
            "num": 40,  # Get more results per query
        }
        
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
            # Invalid zip code - just skip it
            return []
        
        if response.status_code != 200:
            return []
        
        data = response.json()
        return data.get("places", [])
        
    except Exception as e:
        return []


def search_zipcode(zipcode: str, api_key: str) -> list:
    """Search all hotel types in a specific zip code."""
    global _seen_names
    results = []
    
    for search_type in SEARCH_TYPES:
        if _out_of_credits:
            break
        
        # Query format: "hotels in 33139" - forces local results
        query = f"{search_type} in {zipcode}"
        places = search_serper_maps(query, api_key)
        
        for place in places:
            name = place.get("title", "").strip()
            if not name:
                continue
            
            name_lower = name.lower()
            
            # Thread-safe duplicate check
            with _seen_lock:
                if name_lower in _seen_names:
                    _stats["duplicates"] += 1
                    continue
                _seen_names.add(name_lower)
            
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
                "zipcode": zipcode,
            })
            _stats["found"] += 1
        
        time.sleep(0.1)  # Rate limiting
    
    return results


# ============================================================================
# MAIN
# ============================================================================

def run_zipcode_scraper(
    zipcodes: list,
    output_csv: str,
    api_key: str,
    concurrency: int = 5,
):
    """Run the zip code-based scraper."""
    global _stats, _seen_names
    _stats = {"found": 0, "skipped_chains": 0, "api_calls": 0, "duplicates": 0}
    _seen_names = set()
    
    log("Sadie Zip Code Scraper - Search by Zip Code")
    log(f"Zip codes to search: {len(zipcodes)}")
    log(f"Search types per zip: {len(SEARCH_TYPES)}")
    log(f"Estimated API calls: ~{len(zipcodes) * len(SEARCH_TYPES)}")
    log(f"Concurrency: {concurrency}")
    log("")
    
    all_hotels = []
    start_time = time.time()
    
    with ThreadPoolExecutor(max_workers=concurrency) as executor:
        futures = {
            executor.submit(search_zipcode, zipcode, api_key): zipcode
            for zipcode in zipcodes
        }
        
        completed = 0
        for future in as_completed(futures):
            if _out_of_credits:
                break
            
            zipcode = futures[future]
            completed += 1
            
            try:
                hotels = future.result()
                all_hotels.extend(hotels)
                
                if completed % 20 == 0 or completed == len(zipcodes):
                    log(f"[{completed}/{len(zipcodes)}] Total: {len(all_hotels)} hotels, {_stats['api_calls']} API calls")
                    
            except Exception as e:
                log(f"Error processing {zipcode}: {e}")
    
    # Save results
    if all_hotels:
        output_dir = os.path.dirname(output_csv)
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)
        
        fieldnames = ["hotel", "website", "phone", "lat", "long", "address", "rating", "zipcode"]
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


def get_available_states():
    """Get list of states that have zip code files."""
    states = []
    if os.path.exists("data"):
        for f in os.listdir("data"):
            if f.endswith("_zipcodes.txt"):
                state = f.replace("_zipcodes.txt", "")
                states.append(state)
    # Add fallback states from prefixes
    for state in STATE_ZIP_PREFIXES.keys():
        if state not in states:
            states.append(state)
    return sorted(states)


def main():
    parser = argparse.ArgumentParser(description="Zip code-based hotel scraper")

    # Zip code sources - dynamically get available states
    available_states = get_available_states()
    parser.add_argument("--state", type=str, choices=available_states,
                        help="State to search (uses zip code file from data/)")
    parser.add_argument("--zipcodes", type=str, nargs="+",
                        help="Specific zip codes to search")
    parser.add_argument("--zipcode-file", type=str,
                        help="File with zip codes (one per line)")
    
    parser.add_argument("--output", "-o", default=None)
    parser.add_argument("--api-key", type=str, help="Serper API key")
    parser.add_argument("--concurrency", type=int, default=5)
    parser.add_argument("--estimate", action="store_true", help="Only show cost estimate")
    
    args = parser.parse_args()
    
    # Get API key
    api_key = args.api_key or os.environ.get("SERPER_SAMI", "") 
    if not api_key and not args.estimate:
        log("ERROR: No API key. Set SERPER_SAMI in .env or use --api-key")
        sys.exit(1)
    
    # Timestamp for unique filenames
    timestamp = datetime.now().strftime("%Y%m%d_%H%M")

    # Get zip codes
    if args.zipcodes:
        zipcodes = args.zipcodes
        output = args.output or f"scraper_output/custom/custom_zipcode_{timestamp}.csv"
    elif args.zipcode_file:
        zipcodes = get_zipcodes_from_file(args.zipcode_file)
        # Extract name from file for output
        file_name = os.path.basename(args.zipcode_file).replace("_postcodes.txt", "").replace("_zipcodes.txt", "")
        output = args.output or f"scraper_output/{file_name}/{file_name}_zipcode_{timestamp}.csv"
    elif args.state:
        zipcodes = get_zipcodes_for_state(args.state)
        output = args.output or f"scraper_output/{args.state}/{args.state}_zipcode_{timestamp}.csv"
    else:
        log("ERROR: Provide --state, --zipcodes, or --zipcode-file")
        sys.exit(1)
    
    if not zipcodes:
        log("No zip codes to search")
        sys.exit(1)
    
    # Cost estimate
    if args.estimate:
        total_calls = len(zipcodes) * len(SEARCH_TYPES)
        log(f"COST ESTIMATE")
        log(f"Zip codes: {len(zipcodes)}")
        log(f"Search types: {len(SEARCH_TYPES)}")
        log(f"Total API calls: {total_calls}")
        log(f"Estimated credits: {total_calls}")
        return
    
    run_zipcode_scraper(zipcodes, output, api_key, args.concurrency)


if __name__ == "__main__":
    main()

