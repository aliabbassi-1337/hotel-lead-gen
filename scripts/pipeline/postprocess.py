#!/usr/bin/env python3
"""
Sadie Post-Processor
====================
Cleans up detector output:
- Deduplicates by (name, website)
- Removes entries with errors
- Optionally filters by distance from city center

Usage:
    python3 sadie_postprocess.py detector_output/gatlinburg_leads.csv
    python3 sadie_postprocess.py detector_output/gatlinburg_leads.csv --city gatlinburg --radius 30
    python3 sadie_postprocess.py detector_output/*.csv
"""

import csv
import sys
import os
import math
from datetime import datetime

# City coordinates for distance filtering
CITY_COORDS = {
    "gatlinburg": (35.71, -83.51),
    "pigeon forge": (35.79, -83.55),
    "sevierville": (35.87, -83.56),
    "ocean city": (38.34, -75.08),
    "sydney": (-33.87, 151.21),
    "miami": (25.76, -80.19),
    "new york": (40.71, -74.01),
    "los angeles": (34.05, -118.24),
    "chicago": (41.88, -87.63),
}

def haversine_miles(lat1, lon1, lat2, lon2):
    """Calculate distance in miles between two coordinates."""
    R = 3959  # Earth radius in miles
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
    return R * 2 * math.asin(math.sqrt(a))


def log(msg: str):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {msg}")


def postprocess(input_file: str, city: str = None, radius_miles: float = None):
    """Process a single CSV file.
    
    Args:
        input_file: Path to detector output CSV
        city: Optional city name for distance filtering (e.g., "gatlinburg")
        radius_miles: Max distance in miles from city center (default: 30)
    """
    # Update in-place (no more _post suffix)
    output_file = input_file

    # Create backup before modifying
    import shutil
    backup_file = f"{input_file}.bak"
    shutil.copy2(input_file, backup_file)

    log(f"Processing: {input_file}")
    
    # Read input
    rows = []
    fieldnames = None
    with open(input_file, "r", newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        rows = list(reader)
    
    original_count = len(rows)
    log(f"  Input rows: {original_count}")
    
    # Distance filtering (if city specified)
    if city and city.lower() in CITY_COORDS:
        city_lat, city_lng = CITY_COORDS[city.lower()]
        max_radius = radius_miles or 30  # Default 30 miles
        
        filtered_rows = []
        too_far = []
        for r in rows:
            try:
                lat = float(r.get("latitude") or 0)
                lng = float(r.get("longitude") or 0)
                if lat and lng:
                    dist = haversine_miles(city_lat, city_lng, lat, lng)
                    if dist <= max_radius:
                        filtered_rows.append(r)
                    else:
                        too_far.append((r.get("name", ""), dist))
                else:
                    # Keep rows without coordinates (can't filter)
                    filtered_rows.append(r)
            except (ValueError, TypeError):
                filtered_rows.append(r)
        
        if too_far:
            log(f"  Removed outside {max_radius}mi radius: {len(too_far)}")
            too_far.sort(key=lambda x: -x[1])  # Sort by distance desc
            for name, dist in too_far[:5]:
                log(f"    - {name[:35]} ({dist:.0f} mi away)")
            if len(too_far) > 5:
                log(f"    ... and {len(too_far) - 5} more")
        rows = filtered_rows
    
    # Remove dead/broken domains and error rows
    dead_errors = [
        "ERR_NAME_NOT_RESOLVED", "ERR_HTTP2_PROTOCOL_ERROR", "ERR_CONNECTION_RESET",
        "ERR_CONNECTION_REFUSED", "ERR_EMPTY_RESPONSE", "ERR_SSL", "ERR_CERT",
        "no_booking_found", "no_booking_button_found", "Timeout", "exception:"
    ]
    dead_removed = []
    clean_rows = []
    for r in rows:
        error = r.get("error") or ""
        if any(e in error for e in dead_errors):
            dead_removed.append((r.get("website", ""), error))
        else:
            clean_rows.append(r)
    dead_count = len(dead_removed)
    if dead_count:
        log(f"  Removed errors/dead domains: {dead_count}")
        for domain, err in dead_removed[:10]:  # Show first 10
            log(f"    - {domain} ({err[:40]}...)")
        if dead_count > 10:
            log(f"    ... and {dead_count - 10} more")
    
    # Check for contact info
    def has_contact(row):
        return (row.get("phone_google") or "").strip() or \
               (row.get("phone_website") or "").strip() or \
               (row.get("email") or "").strip()
    
    # Fix rows with junk booking URLs (facebook, OTAs, chains, etc)
    junk_booking_domains = [
        # Social media
        "facebook.com", "instagram.com", "twitter.com", "youtube.com",
        "linkedin.com", "tiktok.com", "pinterest.com",
        # Review sites
        "yelp.com", "tripadvisor.com", "google.com", "maps.google.com",
        # OTAs
        "booking.com", "expedia.com", "hotels.com", "airbnb.com", "vrbo.com",
        "kayak.com", "trivago.com", "priceline.com", "agoda.com", "orbitz.com",
        "travelocity.com", "hotwire.com", "cheaptickets.com", "trip.com",
        # Big chains
        "hilton.com", "marriott.com", "ihg.com", "hyatt.com", "wyndham.com",
        "choicehotels.com", "bestwestern.com", "radissonhotels.com", "accor.com",
        # Restaurant reservations (not hotels)
        "sevenrooms.com", "opentable.com", "resy.com", "nowbookit.com", "dimmi.com.au",
        # Short links / maps
        "goo.gl", "bit.ly", "maps.app",
    ]
    
    def has_junk_booking_url(row):
        booking_url = (row.get("booking_url") or "").lower()
        return any(junk in booking_url for junk in junk_booking_domains)
    
    fixed_rows = []
    junk_booking_fixed = 0
    junk_booking_removed = 0
    
    for row in clean_rows:
        if has_junk_booking_url(row):
            if has_contact(row):
                # Clear junk booking URL, mark as contact only
                row["booking_url"] = ""
                row["booking_engine"] = "contact_only"
                row["booking_engine_domain"] = ""
                row["error"] = ""
                fixed_rows.append(row)
                junk_booking_fixed += 1
            else:
                # No contact info and junk booking URL - remove
                junk_booking_removed += 1
        else:
            fixed_rows.append(row)
    
    clean_rows = fixed_rows
    if junk_booking_fixed:
        log(f"  Fixed junk booking URLs: {junk_booking_fixed}")
    if junk_booking_removed:
        log(f"  Removed junk booking (no contact): {junk_booking_removed}")
    
    # Remove rows with non-engine booking_engine values
    # Note: unknown_booking_api is KEPT - it means we found a booking API, just don't know which one
    no_engine_values = {"proprietary_or_same_domain", "unknown", "unknown_third_party", "Angular-based", "contact_only"}
    before_no_engine = len(clean_rows)
    clean_rows = [r for r in clean_rows if (r.get("booking_engine") or "") not in no_engine_values]
    no_engine_removed = before_no_engine - len(clean_rows)
    if no_engine_removed:
        log(f"  Removed no real engine: {no_engine_removed}")
    
    # Remove rows with no contact info AND no booking URL
    # If we have a booking URL, keep the row even without contact info
    before_contact = len(clean_rows)
    clean_rows = [r for r in clean_rows if has_contact(r) or r.get("booking_url", "").strip()]
    no_contact_count = before_contact - len(clean_rows)
    if no_contact_count:
        log(f"  Removed no contact AND no booking URL: {no_contact_count}")
    
    # Remove junk domains
    junk_domains = [
        # Social media
        "facebook.com", "instagram.com", "twitter.com", "youtube.com",
        "linkedin.com", "yelp.com", "tripadvisor.com", "google.com",
        # OTAs
        "booking.com", "expedia.com", "hotels.com", "airbnb.com", "vrbo.com",
        "kayak.com", "trivago.com", "priceline.com", "agoda.com", "orbitz.com",
        "travelocity.com", "hotwire.com",
        # Big chains
        "hilton.com", "marriott.com", "ihg.com", "hyatt.com", "wyndham.com",
        "choicehotels.com", "bestwestern.com", "radissonhotels.com", "accor.com",
        "sonesta.com", "omnihotels.com", "fourseasons.com", "ritzcarlton.com",
        # Government
        ".gov", ".edu", ".mil", "nps.gov", "usda.gov", "fs.usda.gov",
        # Short links
        "maps.app.goo.gl", "goo.gl",
    ]
    
    def is_junk_domain(row):
        website = (row.get("website") or "").lower()
        # Filter junk domains
        if any(junk in website for junk in junk_domains):
            return True
        # Filter file links
        if website.endswith(".pdf") or ".pdf?" in website:
            return True
        return False
    
    before_junk = len(clean_rows)
    junk_removed = []
    kept_rows = []
    for r in clean_rows:
        if is_junk_domain(r):
            junk_removed.append(r.get("website", ""))
        else:
            kept_rows.append(r)
    clean_rows = kept_rows
    junk_count = before_junk - len(clean_rows)
    if junk_count:
        log(f"  Removed junk website domains: {junk_count}")
        for domain in junk_removed:
            log(f"    - {domain}")
    
    
    # Deduplicate by (name, website)
    seen = set()
    deduped_rows = []
    for row in clean_rows:
        name = (row.get("name") or "").strip().lower()
        website = (row.get("website") or "").strip().lower()
        key = (name, website)
        
        if key in seen:
            continue
        seen.add(key)
        deduped_rows.append(row)
    
    dupe_count = len(clean_rows) - len(deduped_rows)
    log(f"  Removed duplicates: {dupe_count}")
    log(f"  Final rows: {len(deduped_rows)}")
    
    # Remove debug columns from output (these are for internal use only)
    debug_columns = ["error", "detection_method", "screenshot_path", "booking_engine_domain"]
    clean_fieldnames = [f for f in fieldnames if f not in debug_columns]
    
    # Clean the rows (remove debug fields)
    for row in deduped_rows:
        for col in debug_columns:
            row.pop(col, None)
    
    # Write output
    with open(output_file, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=clean_fieldnames)
        writer.writeheader()
        writer.writerows(deduped_rows)
    
    log(f"  Output: {output_file} ({len(deduped_rows)} rows)")
    
    return {
        "input": original_count,
        "output": len(deduped_rows),
        "junk_removed": junk_count,
        "dupes_removed": dupe_count,
    }


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 sadie_postprocess.py <input.csv> [input2.csv ...]")
        sys.exit(1)
    
    import argparse
    parser = argparse.ArgumentParser(description="Post-process detector output")
    parser.add_argument("files", nargs="+", help="CSV files to process")
    parser.add_argument("--city", help="City name for distance filtering (e.g., gatlinburg)")
    parser.add_argument("--radius", type=float, default=30, help="Max radius in miles (default: 30)")
    args = parser.parse_args()
    
    total_stats = {"input": 0, "output": 0, "junk_removed": 0, "dupes_removed": 0}
    
    for f in args.files:
        if not os.path.exists(f):
            log(f"File not found: {f}")
            continue
        
        stats = postprocess(f, city=args.city, radius_miles=args.radius)
        for k, v in stats.items():
            total_stats[k] += v
        print()
    
    if len(args.files) > 1:
        log("=" * 50)
        log("TOTAL SUMMARY")
        log(f"  Input rows:         {total_stats['input']}")
        log(f"  Output rows:        {total_stats['output']}")
        log(f"  Junk removed:       {total_stats['junk_removed']}")
        log(f"  Duplicates removed: {total_stats['dupes_removed']}")


if __name__ == "__main__":
    main()

