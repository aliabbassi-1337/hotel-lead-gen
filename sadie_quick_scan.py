#!/usr/bin/env python3
"""
Sadie Quick Scan - Fast booking engine detection WITHOUT browser
================================================================
Uses requests to fetch HTML and scan for booking engine patterns.
Much faster than Playwright - use this for initial filtering.

Usage:
    python3 sadie_quick_scan.py https://example-hotel.com
    python3 sadie_quick_scan.py --input hotels.csv --output quick_scan.csv
"""

import csv
import re
import sys
import argparse
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime

# Known booking engine patterns (domain substrings)
ENGINE_PATTERNS = {
    "HomHero": ["homhero.com", "api.homhero", "images.prod.homhero"],
    "Cloudbeds": ["cloudbeds.com"],
    "FreeToBook": ["freetobook.com"],
    "SiteMinder": ["siteminder.com", "thebookingbutton.com", "direct-book.com"],
    "Little Hotelier": ["littlehotelier.com"],
    "Mews": ["mews.com", "mews.li"],
    "SynXis / TravelClick": ["synxis.com", "travelclick.com"],
    "WebRezPro": ["webrezpro.com"],
    "ResNexus": ["resnexus.com"],
    "Beds24": ["beds24.com"],
    "Checkfront": ["checkfront.com"],
    "eviivo": ["eviivo.com"],
    "Lodgify": ["lodgify.com"],
    "Hostaway": ["hostaway.com"],
    "Guesty": ["guesty.com"],
    "Sirvoy": ["sirvoy.com"],
    "Amenitiz": ["amenitiz.io", "amenitiz.com"],
    "Newbook": ["newbook.cloud"],
    "RMS Cloud": ["rmscloud.com"],
    "JEHS / iPMS": ["ipms247.com"],
    "InnRoad": ["innroad.com"],
    "RoomRaccoon": ["roomraccoon.com"],
    "eZee": ["ezee", "ezeereservation"],
    "HotelRunner": ["hotelrunner.com"],
    "Hospitable": ["hospitable.com"],
    "Streamline": ["streamlinevrs.com", "resortpro"],
    "Triptease": ["triptease.io", "triptease.com", "onboard.triptease"],
}

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
}


def log(msg: str):
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{timestamp}] {msg}")


def fetch_html(url: str, timeout: int = 15) -> str:
    """Fetch HTML from URL using requests."""
    try:
        if not url.startswith("http"):
            url = "https://" + url
        response = requests.get(url, headers=HEADERS, timeout=timeout, allow_redirects=True)
        return response.text
    except Exception as e:
        return ""


def extract_urls_from_html(html: str) -> set:
    """Extract all URLs from HTML source."""
    # Match URLs in href, src, and JS strings
    patterns = [
        r'https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}[^\s"\'<>]*',
        r'//[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}[^\s"\'<>]*',
    ]
    
    urls = set()
    for pattern in patterns:
        urls.update(re.findall(pattern, html))
    return urls


def detect_engine(html: str) -> tuple[str, str]:
    """Detect booking engine from HTML content."""
    html_lower = html.lower()
    
    for engine_name, patterns in ENGINE_PATTERNS.items():
        for pattern in patterns:
            if pattern.lower() in html_lower:
                return (engine_name, pattern)
    
    return ("", "")


def find_booking_urls(html: str) -> list[str]:
    """Find URLs that look like booking-related endpoints."""
    urls = extract_urls_from_html(html)
    
    booking_keywords = ['book', 'reserv', 'checkout', 'payment', 'calendar', 'availability']
    
    booking_urls = []
    for url in urls:
        url_lower = url.lower()
        if any(kw in url_lower for kw in booking_keywords):
            # Skip common non-booking URLs
            if not any(skip in url_lower for skip in ['facebook', 'google', 'analytics', '.css', '.js', '.png', '.jpg']):
                booking_urls.append(url)
    
    return booking_urls[:10]


def scan_website(url: str) -> dict:
    """Scan a website for booking engine patterns."""
    result = {
        "url": url,
        "engine": "",
        "engine_pattern": "",
        "booking_urls": [],
        "error": "",
    }
    
    # Fetch main page
    html = fetch_html(url)
    if not html:
        result["error"] = "failed_to_fetch"
        return result
    
    # Detect engine
    engine, pattern = detect_engine(html)
    result["engine"] = engine
    result["engine_pattern"] = pattern
    
    # Find booking-related URLs
    result["booking_urls"] = find_booking_urls(html)
    
    # If no engine found, try common booking page paths
    if not engine:
        booking_paths = ["/book", "/booking", "/reservations", "/book-now", "/book-direct"]
        for path in booking_paths:
            try:
                base = url.rstrip("/")
                booking_html = fetch_html(base + path, timeout=10)
                if booking_html:
                    engine, pattern = detect_engine(booking_html)
                    if engine:
                        result["engine"] = engine
                        result["engine_pattern"] = pattern
                        break
            except Exception:
                continue
    
    return result


def scan_single(url: str):
    """Scan a single URL and print results."""
    log(f"Scanning: {url}")
    
    result = scan_website(url)
    
    if result["engine"]:
        log(f"✓ Engine: {result['engine']} (found: {result['engine_pattern']})")
    else:
        log("✗ No known engine detected")
    
    if result["booking_urls"]:
        log(f"  Booking URLs found:")
        for bu in result["booking_urls"][:5]:
            log(f"    - {bu[:80]}")
    
    return result


def scan_csv(input_csv: str, output_csv: str, concurrency: int = 10):
    """Scan multiple hotels from CSV."""
    # Load hotels
    hotels = []
    with open(input_csv, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            website = row.get("website", "")
            if website:
                hotels.append({
                    "name": row.get("name") or row.get("hotel", ""),
                    "website": website,
                })
    
    log(f"Loaded {len(hotels)} hotels with websites")
    
    # Scan in parallel
    results = []
    with ThreadPoolExecutor(max_workers=concurrency) as executor:
        futures = {executor.submit(scan_website, h["website"]): h for h in hotels}
        
        for i, future in enumerate(as_completed(futures), 1):
            hotel = futures[future]
            try:
                result = future.result()
                result["name"] = hotel["name"]
                results.append(result)
                
                status = f"✓ {result['engine']}" if result['engine'] else "✗ none"
                log(f"[{i}/{len(hotels)}] {hotel['name'][:30]}: {status}")
                
            except Exception as e:
                log(f"[{i}/{len(hotels)}] {hotel['name'][:30]}: error - {e}")
    
    # Write output
    fieldnames = ["name", "url", "engine", "engine_pattern", "booking_urls", "error"]
    with open(output_csv, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for r in results:
            r["booking_urls"] = "; ".join(r.get("booking_urls", []))
            writer.writerow(r)
    
    # Summary
    found = sum(1 for r in results if r["engine"])
    log("")
    log("=" * 50)
    log(f"Scanned: {len(results)}")
    log(f"Engines found: {found}")
    log(f"Output: {output_csv}")


def main():
    parser = argparse.ArgumentParser(description="Quick booking engine scan (no browser)")
    parser.add_argument("url", nargs="?", help="Single URL to scan")
    parser.add_argument("--input", "-i", help="Input CSV with hotels")
    parser.add_argument("--output", "-o", default="quick_scan.csv", help="Output CSV")
    parser.add_argument("--concurrency", "-c", type=int, default=10)
    
    args = parser.parse_args()
    
    if args.url:
        scan_single(args.url)
    elif args.input:
        scan_csv(args.input, args.output, args.concurrency)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()

