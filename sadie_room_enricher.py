#!/usr/bin/env python3
"""
Sadie Room Enricher - Add room count to existing lead CSVs
==========================================================
Visits hotel websites to extract room count and adds it to existing detector output.

Usage:
    python3 sadie_room_enricher.py --input detector_output/ocean_city_leads.csv
    python3 sadie_room_enricher.py --input detector_output/ocean_city_leads.csv --concurrency 10
"""

import csv
import os
import re
import sys
import argparse
import asyncio
from datetime import datetime

from playwright.async_api import async_playwright, TimeoutError as PWTimeoutError


# ============================================================================
# ROOM COUNT EXTRACTION
# ============================================================================

ROOM_COUNT_PATTERNS = [
    r'(\d+)\s*(?:guest\s*)?rooms?(?:\s+available)?',  # "30 rooms", "30 guest rooms"
    r'(\d+)\s*(?:boutique\s*)?(?:guest\s*)?rooms?',   # "30 boutique guest rooms"
    r'(\d+)[\s-]*room\s+(?:hotel|motel|inn|property)',  # "50-room hotel"
    r'(?:hotel|property|we)\s+(?:has|have|offers?|features?)\s+(\d+)\s*rooms?',  # "hotel has 120 rooms"
    r'(?:featuring|with)\s+(\d+)\s*(?:guest\s*)?rooms?',  # "featuring 45 rooms"
    r'(\d+)\s*(?:suites?|units?|apartments?|accommodations?)',  # "20 suites", "15 units"
]


def extract_room_count(text: str) -> str:
    """Extract number of rooms from text."""
    text_lower = text.lower()
    
    for pattern in ROOM_COUNT_PATTERNS:
        matches = re.findall(pattern, text_lower, re.IGNORECASE)
        for match in matches:
            try:
                count = int(match)
                # Sanity check: room count should be reasonable (1-2000)
                if 1 <= count <= 2000:
                    return str(count)
            except ValueError:
                continue
    return ""


def log(msg: str):
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{timestamp}] {msg}")


# ============================================================================
# ENRICHER
# ============================================================================

async def enrich_hotel(context, website: str) -> str:
    """Visit website and extract room count."""
    if not website:
        return ""
    
    page = await context.new_page()
    room_count = ""
    
    try:
        await page.goto(website, timeout=20000, wait_until="domcontentloaded")
        await asyncio.sleep(1)
        
        # Get page text
        text = await page.evaluate("document.body ? document.body.innerText : ''")
        room_count = extract_room_count(text)
        
    except Exception as e:
        pass  # Silently skip errors
    finally:
        await page.close()
    
    return room_count


async def process_batch(browser, hotels: list, semaphore) -> dict:
    """Process a batch of hotels concurrently."""
    results = {}
    
    async def process_one(hotel):
        async with semaphore:
            name = hotel.get("name", "")
            website = hotel.get("website", "")
            
            if not website:
                return
            
            context = await browser.new_context(
                user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
                ignore_https_errors=True,
            )
            
            try:
                room_count = await enrich_hotel(context, website)
                if room_count:
                    results[website] = room_count
                    log(f"  ✓ {name}: {room_count} rooms")
                else:
                    log(f"  - {name}: no room count found")
            finally:
                await context.close()
    
    tasks = [process_one(h) for h in hotels]
    await asyncio.gather(*tasks, return_exceptions=True)
    
    return results


async def run_enricher(input_csv: str, output_csv: str, concurrency: int):
    """Main enricher function."""
    log(f"Loading {input_csv}...")
    
    # Read existing data
    hotels = []
    fieldnames = None
    
    with open(input_csv, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        hotels = list(reader)
    
    log(f"Loaded {len(hotels)} hotels")
    
    # Add room_count column if not present
    if "room_count" not in fieldnames:
        fieldnames = list(fieldnames) + ["room_count"]
    
    # Find hotels that need room count
    to_enrich = [h for h in hotels if not h.get("room_count") and h.get("website")]
    log(f"Hotels needing room count: {len(to_enrich)}")
    
    if not to_enrich:
        log("Nothing to enrich!")
        return
    
    # Process in batches
    semaphore = asyncio.Semaphore(concurrency)
    room_counts = {}
    
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        
        batch_size = 50
        for i in range(0, len(to_enrich), batch_size):
            batch = to_enrich[i:i + batch_size]
            log(f"Processing batch {i // batch_size + 1} ({len(batch)} hotels)...")
            
            batch_results = await process_batch(browser, batch, semaphore)
            room_counts.update(batch_results)
            
            # Save checkpoint
            _save_results(hotels, fieldnames, room_counts, output_csv)
            log(f"  [CHECKPOINT] Saved {len(room_counts)} room counts")
        
        await browser.close()
    
    # Final save
    _save_results(hotels, fieldnames, room_counts, output_csv)
    
    log("")
    log("=" * 50)
    log("ENRICHMENT COMPLETE!")
    log(f"Room counts found: {len(room_counts)}")
    log(f"Output: {output_csv}")
    log("=" * 50)


def _save_results(hotels: list, fieldnames: list, room_counts: dict, output_csv: str):
    """Save enriched data to CSV."""
    # Update hotels with room counts
    for hotel in hotels:
        website = hotel.get("website", "")
        if website in room_counts:
            hotel["room_count"] = room_counts[website]
    
    # Write output
    with open(output_csv, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(hotels)


def main():
    parser = argparse.ArgumentParser(description="Sadie Room Enricher")
    parser.add_argument("--input", required=True, help="Input CSV (detector output)")
    parser.add_argument("--output", help="Output CSV (default: overwrites input)")
    parser.add_argument("--concurrency", type=int, default=5, help="Concurrent browsers")
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input):
        raise SystemExit(f"File not found: {args.input}")
    
    output = args.output or args.input
    
    asyncio.run(run_enricher(args.input, output, args.concurrency))


if __name__ == "__main__":
    main()

