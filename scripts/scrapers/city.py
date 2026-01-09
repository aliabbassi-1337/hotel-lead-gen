#!/usr/bin/env python3
"""
City Scraper - Scrape hotels for a single city
===============================================
Uses Serper API to search by city name and zip codes.

Usage:
    python3 scripts/scrapers/city.py --city miami_beach --state FL
    python3 scripts/scrapers/city.py --city orlando --state FL --output scraper_output/florida/
"""

import csv
import os
import sys
import argparse
import time
import requests
from datetime import datetime
from dotenv import load_dotenv

# Add project root to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(__file__))))
from data.florida_ceo_cities import CEO_CITIES, get_city_zips, get_city_name

load_dotenv()

SERPER_MAPS_URL = "https://google.serper.dev/maps"
SEARCH_TERMS = ["hotels", "motels", "inns", "resorts", "boutique hotel"]

SKIP_CHAINS = [
    "marriott", "hilton", "hyatt", "sheraton", "westin", "w hotel",
    "intercontinental", "holiday inn", "crowne plaza", "ihg",
    "best western", "choice hotels", "comfort inn", "quality inn",
    "radisson", "wyndham", "ramada", "days inn", "super 8", "motel 6",
    "la quinta", "travelodge", "ibis", "novotel", "mercure", "accor",
    "four seasons", "ritz-carlton", "st. regis", "fairmont",
]

_stats = {"api_calls": 0, "hotels_found": 0, "chains_skipped": 0}

def log(msg: str):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")

def search_serper(query: str, api_key: str) -> list:
    """Search Google Maps via Serper."""
    _stats["api_calls"] += 1
    try:
        resp = requests.post(
            SERPER_MAPS_URL,
            headers={"X-API-KEY": api_key, "Content-Type": "application/json"},
            json={"q": query, "num": 40},
            timeout=30
        )
        if resp.status_code == 400 and "credits" in resp.text.lower():
            log("OUT OF CREDITS!")
            return []
        if resp.status_code != 200:
            return []
        return resp.json().get("places", [])
    except:
        return []

def scrape_city(city_slug: str, state: str, api_key: str) -> list:
    """Scrape hotels for a single city."""
    city_name = get_city_name(city_slug)
    zip_codes = get_city_zips(city_slug)

    hotels = []
    seen = set()

    # Search by city name
    for term in SEARCH_TERMS:
        query = f"{term} in {city_name}, {state}"
        log(f"Searching: {query}")

        for place in search_serper(query, api_key):
            name = place.get("title", "").strip()
            if not name:
                continue

            name_lower = name.lower()
            if any(chain in name_lower for chain in SKIP_CHAINS):
                _stats["chains_skipped"] += 1
                continue
            if name_lower in seen:
                continue
            seen.add(name_lower)

            hotels.append({
                "hotel": name,
                "website": place.get("website", ""),
                "phone": place.get("phoneNumber", ""),
                "address": place.get("address", ""),
                "lat": place.get("latitude", ""),
                "long": place.get("longitude", ""),
                "rating": place.get("rating", ""),
                "city": city_name,
            })
            _stats["hotels_found"] += 1

        time.sleep(0.1)

    # Search by zip codes
    for zipcode in zip_codes[:5]:
        query = f"hotels in {zipcode}"
        log(f"Searching: {query}")

        for place in search_serper(query, api_key):
            name = place.get("title", "").strip()
            if not name:
                continue

            name_lower = name.lower()
            if any(chain in name_lower for chain in SKIP_CHAINS):
                continue
            if name_lower in seen:
                continue
            seen.add(name_lower)

            hotels.append({
                "hotel": name,
                "website": place.get("website", ""),
                "phone": place.get("phoneNumber", ""),
                "address": place.get("address", ""),
                "lat": place.get("latitude", ""),
                "long": place.get("longitude", ""),
                "rating": place.get("rating", ""),
                "city": city_name,
            })
            _stats["hotels_found"] += 1

        time.sleep(0.1)

    return hotels

def main():
    parser = argparse.ArgumentParser(description="Scrape hotels for a single city")
    parser.add_argument("--city", required=True, help="City slug (e.g., miami_beach)")
    parser.add_argument("--state", default="FL", help="State abbreviation (default: FL)")
    parser.add_argument("--output", "-o", default="scraper_output/florida", help="Output directory")
    parser.add_argument("--list-cities", action="store_true", help="List available cities")
    args = parser.parse_args()

    if args.list_cities:
        for slug in CEO_CITIES.keys():
            name = get_city_name(slug)
            zips = len(get_city_zips(slug))
            print(f"  {slug}: {name} ({zips} zip codes)")
        return

    api_key = os.environ.get("SERPER_SAMI") or os.environ.get("SERPER_KEY")
    if not api_key:
        log("ERROR: Set SERPER_SAMI or SERPER_KEY")
        sys.exit(1)

    city_name = get_city_name(args.city)
    log(f"Scraping: {city_name}, {args.state}")

    hotels = scrape_city(args.city, args.state, api_key)

    # Save output
    os.makedirs(args.output, exist_ok=True)
    output_file = os.path.join(args.output, f"{args.city}_hotels.csv")

    if hotels:
        with open(output_file, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=hotels[0].keys())
            writer.writeheader()
            writer.writerows(hotels)

    log(f"Done: {_stats['hotels_found']} hotels, {_stats['api_calls']} API calls")
    log(f"Output: {output_file}")

if __name__ == "__main__":
    main()
