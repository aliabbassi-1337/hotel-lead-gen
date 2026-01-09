#!/usr/bin/env python3
"""
Backfill missing longitude data from scraper output.

Usage:
    python3 sadie_backfill_coords.py --leads detector_output/gatlinburg_leads_post.csv --scraper scraper_output/gatlinburg_hotels.csv
"""

import csv
import argparse
from urllib.parse import urlparse


def normalize_url(url: str) -> str:
    """Normalize URL for matching."""
    if not url:
        return ""
    url = url.lower().strip()
    # Remove protocol and www
    url = url.replace("https://", "").replace("http://", "").replace("www.", "")
    # Remove trailing slash and query params
    url = url.split("?")[0].rstrip("/")
    return url


def backfill_coords(leads_file: str, scraper_file: str, output_file: str = None):
    """Backfill missing coordinates from scraper data."""
    
    # Load scraper data and create lookup by website
    scraper_lookup = {}
    with open(scraper_file, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            # Try different column names
            website = row.get("website", row.get("url", ""))
            lat = row.get("lat", row.get("latitude", ""))
            lon = row.get("long", row.get("lng", row.get("longitude", "")))
            
            if website and (lat or lon):
                key = normalize_url(website)
                scraper_lookup[key] = {"lat": lat, "lon": lon}
    
    print(f"Loaded {len(scraper_lookup)} hotels from scraper with coordinates")
    
    # Load leads and backfill
    with open(leads_file, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        leads = list(reader)
        fieldnames = reader.fieldnames
    
    print(f"Loaded {len(leads)} leads")
    
    # Count before
    before_lat = sum(1 for r in leads if r.get("latitude", "").strip())
    before_lon = sum(1 for r in leads if r.get("longitude", "").strip())
    print(f"Before: {before_lat} with lat, {before_lon} with lon")
    
    # Backfill
    filled_count = 0
    for lead in leads:
        website = lead.get("website", "")
        key = normalize_url(website)
        
        if key in scraper_lookup:
            scraper_data = scraper_lookup[key]
            
            # Fill missing latitude
            if not lead.get("latitude", "").strip() and scraper_data["lat"]:
                lead["latitude"] = scraper_data["lat"]
            
            # Fill missing longitude
            if not lead.get("longitude", "").strip() and scraper_data["lon"]:
                lead["longitude"] = scraper_data["lon"]
                filled_count += 1
    
    # Count after
    after_lat = sum(1 for r in leads if r.get("latitude", "").strip())
    after_lon = sum(1 for r in leads if r.get("longitude", "").strip())
    print(f"After: {after_lat} with lat, {after_lon} with lon")
    print(f"Filled {filled_count} missing longitude values")
    
    # Save
    output = output_file or leads_file
    with open(output, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(leads)
    
    print(f"Saved to: {output}")


def main():
    parser = argparse.ArgumentParser(description="Backfill missing coordinates")
    parser.add_argument("--leads", required=True, help="Leads CSV file")
    parser.add_argument("--scraper", required=True, help="Scraper output CSV file")
    parser.add_argument("--output", help="Output file (default: overwrites leads file)")
    
    args = parser.parse_args()
    
    backfill_coords(args.leads, args.scraper, args.output)


if __name__ == "__main__":
    main()

