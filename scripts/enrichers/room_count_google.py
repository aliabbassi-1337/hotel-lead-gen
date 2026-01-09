#!/usr/bin/env python3
"""
Sadie Room Count Enricher (Google AI / Gemini)
==============================================
Fallback enricher using Google AI Studio when Groq hits rate limits.
Only processes hotels that still don't have room_count after Groq pass.

Usage:
    python3 sadie_room_enricher_google.py --input detector_output/sydney_leads_post.csv
    python3 sadie_room_enricher_google.py --input detector_output/sydney_leads_post.csv --concurrency 5

Requires:
    - GOOGLE_AI_API_KEY in .env file (or hoop_audio_api_key)
    - pip3 install httpx python-dotenv
"""

import os
import re
import csv
import asyncio
import argparse
import warnings
from datetime import datetime
from urllib.parse import urljoin, urlparse
from typing import Optional, List

import httpx
from dotenv import load_dotenv

# Suppress SSL warnings
warnings.filterwarnings("ignore", message="Unverified HTTPS request")

load_dotenv()

# Google AI Studio API - try multiple env var names
GOOGLE_AI_API_KEY = os.getenv("GOOGLE_AI_API_KEY") or os.getenv("hoop_audio_api_key")
GOOGLE_AI_URL = "https://generativelanguage.googleapis.com/v1beta/models"

# Use Gemini 2.5 Flash for speed and availability
MODEL = "gemini-2.5-flash"

# Pages to check for room count info
ABOUT_PAGE_PATTERNS = [
    "/about", "/about-us", "/about-hotel", "/the-hotel",
    "/our-hotel", "/hotel", "/property", "/accommodation",
    "/accommodations", "/rooms", "/our-rooms", "/guest-rooms",
    "/suites", "/lodging", "/stay", "/overview",
    "/smoky-mountains-accommodations", "/hotel-accommodations",
    "/hotel-rooms", "/guest-accommodations", "/the-rooms",
    "/room-types", "/our-accommodations",
]

# Regex patterns for room count extraction
ROOM_COUNT_REGEX = [
    r'(?i)(?:our|the|with|featuring|offers?|has|have|boasts?|includes?)\s+(\d+)\s+(?:comfortable\s+)?(?:guest\s+)?(?:room|suite|unit|accommodation)s?',
    r'(?i)(\d+)\s+(?:comfortable\s+)?(?:guest\s+)?(?:room|suite|unit|accommodation)s?\s+(?:and\s+suites?)?',
    r'(?i)(\d+)[\s-]+room\s+(?:hotel|motel|inn|lodge|resort)',
    r'(?i)(?:total\s+of\s+)?(\d+)\s+(?:guest\s+)?rooms?',
    r'(?i)(\d+)\s+(?:spacious|luxurious|elegant|cozy|comfortable)\s+(?:guest\s+)?(?:room|suite)s?',
    r'(?i)(\d+)\s+(?:guest\s+)?(?:room|suite|unit)s?\b',
    r'(?i)(\d+)\s+accommodations?\b',
]


def log(msg: str):
    ts = datetime.now().strftime("%H:%M:%S")
    print(f"[{ts}] {msg}")


async def fetch_page_raw(client: httpx.AsyncClient, url: str) -> str:
    """Fetch raw HTML from a page."""
    try:
        headers = {
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        }
        resp = await client.get(url, timeout=15.0, follow_redirects=True, headers=headers)
        if resp.status_code != 200:
            return ""
        return resp.text
    except Exception:
        return ""


def html_to_text(html: str) -> str:
    """Convert HTML to plain text."""
    html = re.sub(r'<script[^>]*>.*?</script>', '', html, flags=re.DOTALL | re.IGNORECASE)
    html = re.sub(r'<style[^>]*>.*?</style>', '', html, flags=re.DOTALL | re.IGNORECASE)
    html = re.sub(r'<!--.*?-->', '', html, flags=re.DOTALL)
    text = re.sub(r'<[^>]+>', ' ', html)
    text = re.sub(r'\s+', ' ', text)
    return text.strip()


def extract_room_count_regex(html: str) -> Optional[int]:
    """Extract room count from HTML using regex."""
    for pattern in ROOM_COUNT_REGEX:
        matches = re.findall(pattern, html)
        for match in matches:
            try:
                count = int(match)
                if 1 <= count <= 2000:
                    return count
            except:
                pass
    return None


def find_all_internal_links(html: str, base_url: str) -> List[str]:
    """Find all internal links from HTML."""
    links = []
    base_domain = urlparse(base_url).netloc

    href_pattern = r'href=["\']([^"\'#]+)["\']'
    for match in re.finditer(href_pattern, html, re.IGNORECASE):
        href = match.group(1)

        skip_extensions = ['.jpg', '.png', '.pdf', '.css', '.js', '.gif', '.svg', '.ico']
        skip_paths = ['/assets/', '/static/', '/wp-content/', '/images/', '/css/', '/js/']

        if any(href.lower().endswith(ext) for ext in skip_extensions):
            continue
        if any(skip in href.lower() for skip in skip_paths):
            continue
        if href.startswith('mailto:') or href.startswith('tel:') or href.startswith('javascript:'):
            continue

        full_url = urljoin(base_url, href)
        parsed = urlparse(full_url)

        if parsed.netloc == base_domain:
            clean_url = f"{parsed.scheme}://{parsed.netloc}{parsed.path.rstrip('/')}"
            if clean_url not in links and clean_url != base_url.rstrip('/'):
                links.append(clean_url)

    return links


def prioritize_room_links(links: List[str]) -> List[str]:
    """Sort links with room-related keywords first."""
    priority_keywords = ['room', 'accommodation', 'suite', 'lodging', 'stay', 'guest', 'hotel', 'about']

    def score(url):
        path = urlparse(url).path.lower()
        for i, kw in enumerate(priority_keywords):
            if kw in path:
                return i
        return 100

    return sorted(links, key=score)


async def fetch_and_extract_room_count(client: httpx.AsyncClient, website: str) -> tuple:
    """Fetch hotel website and try to extract room count."""
    if not website.startswith("http"):
        website = "https://" + website
    base_url = website.rstrip('/')

    all_html = []
    checked_urls = set()
    all_links = []

    # Try homepage first
    homepage_html = await fetch_page_raw(client, website)
    if homepage_html:
        all_html.append(homepage_html)
        checked_urls.add(base_url)

        count = extract_room_count_regex(homepage_html)
        if count:
            return count, html_to_text(homepage_html)

        all_links = find_all_internal_links(homepage_html, website)

    # Prioritize room-related links
    prioritized_links = prioritize_room_links(all_links)

    # Check prioritized links
    max_pages = 10
    pages_checked = 0

    for link_url in prioritized_links:
        if pages_checked >= max_pages:
            break

        normalized = link_url.rstrip('/')
        if normalized in checked_urls:
            continue
        checked_urls.add(normalized)
        pages_checked += 1

        page_html = await fetch_page_raw(client, link_url)
        if page_html and len(page_html) > 500:
            all_html.append(page_html)
            count = extract_room_count_regex(page_html)
            if count:
                return count, html_to_text(page_html)

    combined_text = "\n\n".join(html_to_text(h) for h in all_html if h)
    return None, combined_text


async def extract_room_count_llm(client: httpx.AsyncClient, hotel_name: str, text: str) -> Optional[int]:
    """Use Google AI (Gemini) to estimate room count."""
    if not text or len(text) < 50:
        return None

    truncated_text = text[:6000] if len(text) > 6000 else text

    prompt = f"""Estimate the number of bookable rooms/units at this property based on the website content.

Hotel/Property: {hotel_name}

YOU MUST RETURN A NUMBER. Use these guidelines:
- Single cabin/cottage/house rental = 1
- Small cabin rental company = 5-15
- B&B or small inn = 5-15
- Boutique hotel = 15-50
- Mid-size hotel = 50-150
- Large hotel/resort = 150-500

Look for clues:
- Explicit numbers ("42 rooms", "15 cabins")
- Lists of properties or room types
- Property names that suggest size

WEBSITE CONTENT:
{truncated_text}

Return ONLY a number (e.g., "12"). You MUST estimate even if unsure:"""

    try:
        url = f"{GOOGLE_AI_URL}/{MODEL}:generateContent?key={GOOGLE_AI_API_KEY}"

        resp = await client.post(
            url,
            json={
                "contents": [{"parts": [{"text": prompt}]}],
                "generationConfig": {
                    "maxOutputTokens": 100,  # Gemini 2.5 uses thinking tokens
                    "temperature": 0.3,
                }
            },
            timeout=30.0,
        )

        if resp.status_code == 429:
            # Rate limited - wait and retry
            for retry in range(3):
                wait_time = (retry + 1) * 5
                log(f"    Rate limited, waiting {wait_time}s (attempt {retry + 1}/3)")
                await asyncio.sleep(wait_time)

                retry_resp = await client.post(
                    url,
                    json={
                        "contents": [{"parts": [{"text": prompt}]}],
                        "generationConfig": {
                            "maxOutputTokens": 100,
                            "temperature": 0.3,
                        }
                    },
                    timeout=30.0,
                )
                if retry_resp.status_code == 200:
                    resp = retry_resp
                    break
            else:
                log(f"    Rate limit exceeded after 3 retries")
                return None

        if resp.status_code != 200:
            log(f"    Google AI error: {resp.status_code} - {resp.text[:100]}")
            return None

        data = resp.json()

        # Extract text from Gemini response
        try:
            answer = data["candidates"][0]["content"]["parts"][0]["text"].strip()
        except (KeyError, IndexError):
            return None

        # Extract number from response
        match = re.search(r'\d+', answer)
        if match:
            count = int(match.group())
            if 1 <= count <= 2000:
                return count

        # Fallback estimate based on property name
        name_lower = hotel_name.lower()
        if any(kw in name_lower for kw in ['cabin', 'cottage', 'house', 'chalet', 'villa']):
            return 1
        elif any(kw in name_lower for kw in ['cabins', 'cottages', 'rentals']):
            return 10
        elif any(kw in name_lower for kw in ['b&b', 'bed and breakfast', 'inn', 'guesthouse']):
            return 8
        elif any(kw in name_lower for kw in ['motel']):
            return 30
        elif any(kw in name_lower for kw in ['hotel', 'resort', 'lodge']):
            return 50
        else:
            return 10

    except Exception as e:
        log(f"  LLM error: {e}")
        return None


async def process_hotel(
    client: httpx.AsyncClient,
    row: dict,
    semaphore: asyncio.Semaphore,
) -> dict:
    """Process a single hotel to extract room count."""
    async with semaphore:
        name = row.get("name", "Unknown")
        website = row.get("website", "")
        existing_count = row.get("room_count", "")

        # Skip if already has room count
        if existing_count and str(existing_count).strip() and str(existing_count).strip() != "0":
            return row

        # Skip if no website
        if not website:
            return row

        log(f"Processing: {name}")

        # Fetch website and try regex extraction first
        regex_count, text = await fetch_and_extract_room_count(client, website)

        if regex_count:
            log(f"  Found via regex: {regex_count} rooms")
            row["room_count"] = regex_count
            return row

        if not text:
            log(f"  Could not fetch website")
            return row

        # Fall back to LLM estimation
        count = await extract_room_count_llm(client, name, text)

        if count:
            log(f"  Gemini estimate: ~{count} rooms")
            row["room_count"] = count
        else:
            log(f"  Could not estimate room count")

        # Small delay to be nice to Google's API
        await asyncio.sleep(0.5)

        return row


async def enrich_csv(input_file: str, concurrency: int = 5):
    """Enrich CSV with room counts using Google AI."""

    if not GOOGLE_AI_API_KEY:
        print("Error: GOOGLE_AI_API_KEY or hoop_audio_api_key not found in .env")
        return

    # Read input CSV
    with open(input_file, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        fieldnames = reader.fieldnames

    if "room_count" not in fieldnames:
        fieldnames = list(fieldnames) + ["room_count"]

    log(f"Loaded {len(rows)} hotels from {input_file}")

    # Count how many need enrichment
    needs_enrichment = [r for r in rows if not r.get("room_count", "").strip() or r.get("room_count", "").strip() == "0"]
    log(f"Hotels needing room count: {len(needs_enrichment)}")

    if not needs_enrichment:
        log("All hotels already have room counts!")
        return

    semaphore = asyncio.Semaphore(concurrency)
    enriched_count = 0

    async with httpx.AsyncClient(verify=False) as client:
        for i, row in enumerate(rows):
            existing = row.get("room_count", "").strip()
            if existing and existing != "0":
                continue

            updated_row = await process_hotel(client, row, semaphore)
            rows[i] = updated_row

            if updated_row.get("room_count") and str(updated_row.get("room_count")).strip() != "0":
                enriched_count += 1

            if (i + 1) % 20 == 0:
                log(f"Progress: {i + 1}/{len(rows)} ({enriched_count} enriched)")

    # Write back to same file (update in place)
    with open(input_file, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    final_with_count = len([r for r in rows if r.get("room_count") and str(r.get("room_count")).strip() != "0"])

    print(f"\n{'='*50}")
    print(f"GOOGLE AI ENRICHMENT COMPLETE")
    print(f"{'='*50}")
    print(f"Total hotels: {len(rows)}")
    print(f"With room count: {final_with_count} ({final_with_count/len(rows)*100:.1f}%)")
    print(f"Newly enriched this run: {enriched_count}")
    print(f"Output: {input_file}")


def main():
    parser = argparse.ArgumentParser(description="Enrich leads with room counts using Google AI (Gemini)")
    parser.add_argument("--input", required=True, help="Input CSV file")
    parser.add_argument("--concurrency", type=int, default=5, help="Concurrent requests (default: 5)")

    args = parser.parse_args()
    asyncio.run(enrich_csv(args.input, args.concurrency))


if __name__ == "__main__":
    main()
