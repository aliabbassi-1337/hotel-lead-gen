#!/usr/bin/env python3
"""
Sadie Room Count Enricher (LLM-powered)
========================================
Uses Groq's fast LLM API to extract room counts from hotel websites.

Usage:
    python3 sadie_room_enricher_llm.py --input detector_output/sydney_leads_post.csv
    python3 sadie_room_enricher_llm.py --input detector_output/sydney_leads_post.csv --concurrency 5

Requires:
    - ROOM_COUNT_ENRICHER_AGENT_GROQ_KEY in .env file
    - pip3 install httpx python-dotenv
"""

import os
import re
import csv
import json
import asyncio
import argparse
import warnings
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, List
from urllib.parse import urljoin, urlparse

import httpx
from dotenv import load_dotenv

# Suppress SSL warnings (we intentionally bypass for old hotel sites)
warnings.filterwarnings("ignore", message="Unverified HTTPS request")

# Load environment variables
load_dotenv()

GROQ_API_KEY = os.getenv("ROOM_COUNT_ENRICHER_AGENT_GROQ_KEY")
GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"

# Fast model - good balance of speed and accuracy
MODEL = "llama-3.1-8b-instant"

# Pages to check for room count info - be thorough!
ABOUT_PAGE_PATTERNS = [
    "/about", "/about-us", "/about-hotel", "/the-hotel",
    "/our-hotel", "/hotel", "/property", "/accommodation",
    "/accommodations", "/rooms", "/our-rooms", "/guest-rooms", 
    "/suites", "/lodging", "/stay", "/overview",
    # Common variations
    "/smoky-mountains-accommodations", "/hotel-accommodations",
    "/hotel-rooms", "/guest-accommodations", "/the-rooms",
    "/room-types", "/our-accommodations",
]

# Regex patterns for room count extraction - ordered by specificity
ROOM_COUNT_REGEX = [
    # Most specific patterns first
    r'(?i)(?:our|the|with|featuring|offers?|has|have|boasts?|includes?)\s+(\d+)\s+(?:comfortable\s+)?(?:guest\s+)?(?:room|suite|unit|accommodation)s?',
    r'(?i)(\d+)\s+(?:comfortable\s+)?(?:guest\s+)?(?:room|suite|unit|accommodation)s?\s+(?:and\s+suites?)?',
    r'(?i)(\d+)[\s-]+room\s+(?:hotel|motel|inn|lodge|resort)',
    r'(?i)(?:total\s+of\s+)?(\d+)\s+(?:guest\s+)?rooms?',
    r'(?i)(\d+)\s+(?:spacious|luxurious|elegant|cozy|comfortable)\s+(?:guest\s+)?(?:room|suite)s?',
    # Fallback patterns
    r'(?i)(\d+)\s+(?:guest\s+)?(?:room|suite|unit)s?\b',
    r'(?i)(\d+)\s+accommodations?\b',
]


def log(msg: str):
    """Print timestamped log message."""
    ts = datetime.now().strftime("%H:%M:%S")
    print(f"[{ts}] {msg}")


async def fetch_page_raw(client: httpx.AsyncClient, url: str) -> str:
    """Fetch raw HTML from a page."""
    try:
        headers = {
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
        }
        resp = await client.get(url, timeout=15.0, follow_redirects=True, headers=headers)
        if resp.status_code != 200:
            return ""
        return resp.text
        
    except httpx.ConnectError as e:
        log(f"    Connection error: {url} - {str(e)[:50]}")
        return ""
    except httpx.TimeoutException:
        log(f"    Timeout: {url}")
        return ""
    except Exception as e:
        log(f"    Fetch error: {url} - {type(e).__name__}: {str(e)[:50]}")
        return ""


def html_to_text(html: str) -> str:
    """Convert HTML to plain text."""
    # Remove script and style tags
    html = re.sub(r'<script[^>]*>.*?</script>', '', html, flags=re.DOTALL | re.IGNORECASE)
    html = re.sub(r'<style[^>]*>.*?</style>', '', html, flags=re.DOTALL | re.IGNORECASE)
    html = re.sub(r'<!--.*?-->', '', html, flags=re.DOTALL)
    # Remove HTML tags but keep text
    text = re.sub(r'<[^>]+>', ' ', html)
    # Clean up whitespace
    text = re.sub(r'\s+', ' ', text)
    return text.strip()


def extract_room_count_regex(html: str) -> Optional[int]:
    """Extract room count from HTML using regex. Returns None if not found."""
    # Search through all patterns
    for pattern in ROOM_COUNT_REGEX:
        matches = re.findall(pattern, html)
        for match in matches:
            try:
                count = int(match)
                # Sanity check: 1-2000 rooms
                if 1 <= count <= 2000:
                    return count
            except:
                pass
    return None


def find_all_internal_links(html: str, base_url: str) -> List[str]:
    """Find ALL internal links from HTML."""
    links = []
    base_domain = urlparse(base_url).netloc
    
    # Find all href attributes
    href_pattern = r'href=["\']([^"\'#]+)["\']'
    for match in re.finditer(href_pattern, html, re.IGNORECASE):
        href = match.group(1)
        
        # Skip external links, images, files, assets, etc.
        skip_extensions = ['.jpg', '.png', '.pdf', '.css', '.js', '.gif', '.svg', '.ico', '.woff', '.woff2', '.ttf', '.eot']
        skip_paths = ['/assets/', '/static/', '/wp-content/', '/images/', '/img/', '/css/', '/js/']
        
        if any(href.lower().endswith(ext) for ext in skip_extensions):
            continue
        if any(skip in href.lower() for skip in skip_paths):
            continue
        if href.startswith('mailto:') or href.startswith('tel:') or href.startswith('javascript:'):
            continue
        
        # Convert to absolute URL
        full_url = urljoin(base_url, href)
        parsed = urlparse(full_url)
        
        # Only same-domain links
        if parsed.netloc == base_domain:
            # Normalize URL (remove trailing slash, query params)
            clean_url = f"{parsed.scheme}://{parsed.netloc}{parsed.path.rstrip('/')}"
            if clean_url not in links and clean_url != base_url.rstrip('/'):
                links.append(clean_url)
    
    return links


def prioritize_room_links(links: List[str]) -> List[str]:
    """Sort links with room-related keywords first."""
    priority_keywords = ['room', 'accommodation', 'suite', 'lodging', 'stay', 'guest', 'hotel', 'property', 'about']
    
    def score(url):
        path = urlparse(url).path.lower()
        for i, kw in enumerate(priority_keywords):
            if kw in path:
                return i  # Lower = higher priority
        return 100  # No keyword match
    
    return sorted(links, key=score)


async def fetch_sitemap_links(client: httpx.AsyncClient, base_url: str) -> List[str]:
    """Try to fetch sitemap.xml and extract URLs."""
    links = []
    sitemap_urls = [
        urljoin(base_url, '/sitemap.xml'),
        urljoin(base_url, '/sitemap_index.xml'),
    ]
    
    for sitemap_url in sitemap_urls:
        try:
            resp = await client.get(sitemap_url, timeout=5.0)
            if resp.status_code == 200 and 'xml' in resp.headers.get('content-type', ''):
                # Extract URLs from sitemap
                urls = re.findall(r'<loc>([^<]+)</loc>', resp.text)
                links.extend(urls)
                break
        except:
            pass
    
    return links


async def fetch_and_extract_room_count(client: httpx.AsyncClient, website: str) -> tuple:
    """
    Fetch hotel website pages and try to extract room count.
    Returns (room_count, all_text) - room_count is None if not found via regex.
    """
    # Normalize URL
    if not website.startswith("http"):
        website = "https://" + website
    base_url = website.rstrip('/')
    
    all_html = []
    checked_urls = set()
    all_links = []
    
    # 1. Try homepage first
    homepage_html = await fetch_page_raw(client, website)
    if homepage_html:
        all_html.append(homepage_html)
        checked_urls.add(base_url)
        checked_urls.add(base_url + '/')
        
        # Try regex on homepage
        count = extract_room_count_regex(homepage_html)
        if count:
            return count, html_to_text(homepage_html)
        
        # Discover ALL internal links from homepage
        all_links = find_all_internal_links(homepage_html, website)
    
    # 2. Try sitemap.xml for more pages
    sitemap_links = await fetch_sitemap_links(client, website)
    for link in sitemap_links:
        if link not in all_links:
            all_links.append(link)
    
    # 3. Prioritize room-related links first
    prioritized_links = prioritize_room_links(all_links)
    
    # 4. Check prioritized links (limit to avoid hammering server)
    max_pages = 15
    pages_checked = 0
    
    for link_url in prioritized_links:
        if pages_checked >= max_pages:
            break
        
        # Normalize URL for comparison
        normalized = link_url.rstrip('/')
        if normalized in checked_urls or normalized + '/' in checked_urls:
            continue
        checked_urls.add(normalized)
        pages_checked += 1
        
        page_html = await fetch_page_raw(client, link_url)
        if page_html and len(page_html) > 500:
            all_html.append(page_html)
            count = extract_room_count_regex(page_html)
            if count:
                short_path = urlparse(link_url).path or '/'
                log(f"    Found via regex on {short_path}: {count} rooms")
                return count, html_to_text(page_html)
    
    # No regex match found - return all text for LLM fallback
    combined_text = "\n\n".join(html_to_text(h) for h in all_html if h)
    return None, combined_text


def extract_room_relevant_content(text: str) -> str:
    """Extract sentences/paragraphs that likely contain room count information."""
    # Keywords that often appear near room counts
    keywords = [
        'room', 'suite', 'unit', 'apartment', 'accommodation', 'cabin', 'cottage',
        'guest', 'bedroom', 'lodging', 'property', 'hotel', 'motel', 'inn',
        'featuring', 'offers', 'boasts', 'includes', 'comfortable'
    ]
    
    # Split into sentences (rough split)
    sentences = re.split(r'[.!?]\s+', text)
    
    relevant = []
    for sentence in sentences:
        sentence_lower = sentence.lower()
        # Check if sentence contains numbers AND room-related keywords
        has_number = bool(re.search(r'\d+', sentence))
        has_keyword = any(kw in sentence_lower for kw in keywords)
        
        if has_number and has_keyword:
            # Clean up and add
            clean = sentence.strip()
            if len(clean) > 20 and len(clean) < 500:
                relevant.append(clean)
    
    # Also search for specific patterns anywhere in text
    patterns = [
        r'.{0,100}\d+\s*(?:guest\s*)?rooms?.{0,100}',
        r'.{0,100}\d+\s*(?:guest\s*)?suites?.{0,100}',
        r'.{0,100}\d+\s*(?:guest\s*)?units?.{0,100}',
        r'.{0,100}\d+\s*accommodations?.{0,100}',
        r'.{0,100}(?:featuring|with|offers?|has|have)\s+\d+.{0,100}',
    ]
    
    for pattern in patterns:
        matches = re.findall(pattern, text, re.IGNORECASE)
        for match in matches[:3]:  # Limit matches per pattern
            clean = match.strip()
            if clean and clean not in relevant and len(clean) > 20:
                relevant.append(clean)
    
    # Deduplicate while preserving order
    seen = set()
    unique = []
    for r in relevant:
        r_lower = r.lower()[:50]  # Use first 50 chars for dedup
        if r_lower not in seen:
            seen.add(r_lower)
            unique.append(r)
    
    return "\n".join(unique[:20])  # Max 20 relevant excerpts


async def extract_room_count_llm(client: httpx.AsyncClient, hotel_name: str, text: str) -> Optional[int]:
    """Use Groq LLM to extract room count from text."""
    if not text or len(text) < 50:
        return None
    
    # Extract only room-relevant content from the full text
    relevant_content = extract_room_relevant_content(text)
    
    if not relevant_content:
        # Fall back to first chunk if no relevant content found
        relevant_content = text[:3000]
    
    prompt = f"""Extract the number of rooms/suites/units at this hotel from the text below.

Hotel: {hotel_name}

RULES:
- Return ONLY a single number (e.g., "42")
- If you find multiple numbers, return the total room count
- If the text mentions "X rooms" or "X suites" or "X units" or "X accommodations", extract X
- If no room count is mentioned, return "unknown"
- Do NOT guess or estimate - only extract if explicitly stated

TEXT:
{relevant_content}

ROOM COUNT:"""

    try:
        resp = await client.post(
            GROQ_API_URL,
            headers={
                "Authorization": f"Bearer {GROQ_API_KEY}",
                "Content-Type": "application/json",
            },
            json={
                "model": MODEL,
                "messages": [{"role": "user", "content": prompt}],
                "max_tokens": 20,
                "temperature": 0,
            },
            timeout=30.0,
        )
        
        if resp.status_code == 429:
            # Rate limited - wait and retry up to 3 times
            for retry in range(3):
                wait_time = (retry + 1) * 5  # 5s, 10s, 15s
                log(f"    ⏳ Rate limited, waiting {wait_time}s (attempt {retry + 1}/3)")
                await asyncio.sleep(wait_time)
                
                retry_resp = await client.post(
                    GROQ_API_URL,
                    headers={
                        "Authorization": f"Bearer {GROQ_API_KEY}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": MODEL,
                        "messages": [{"role": "user", "content": prompt}],
                        "max_tokens": 20,
                        "temperature": 0,
                    },
                    timeout=30.0,
                )
                if retry_resp.status_code == 200:
                    resp = retry_resp
                    break
                elif retry_resp.status_code != 429:
                    return None
            else:
                log(f"    ❌ Rate limit exceeded after 3 retries")
                return None
        
        if resp.status_code != 200:
            log(f"    ❌ Groq API error: {resp.status_code}")
            return None
        
        data = resp.json()
        answer = data["choices"][0]["message"]["content"].strip()
        
        # Parse the response
        if answer.lower() in ["unknown", "n/a", "not found", "none", "not mentioned"]:
            return None
        
        # Extract number from response
        match = re.search(r'\d+', answer)
        if match:
            count = int(match.group())
            # Sanity check - most hotels have 1-2000 rooms
            if not (1 <= count <= 2000):
                return None
            
            # ANTI-HALLUCINATION: Verify the number actually appears in the source text
            # The number must appear near room-related words
            count_str = str(count)
            room_keywords = r'(?:room|suite|unit|apartment|accommodation|cabin|cottage|guest|bed)'
            
            # Check if this number appears near room-related keywords in the text
            # Pattern: number followed by room keyword, or room keyword followed by number
            verify_patterns = [
                rf'\b{count_str}\s*(?:[-\s])?{room_keywords}',  # "42 rooms", "42-room"
                rf'{room_keywords}s?\s*[:=]?\s*{count_str}\b',  # "rooms: 42"
                rf'(?:has|have|with|featuring|offers?)\s+{count_str}\s',  # "has 42"
            ]
            
            text_lower = text.lower()
            verified = False
            for pattern in verify_patterns:
                if re.search(pattern, text_lower):
                    verified = True
                    break
            
            if not verified:
                # Number not found in expected context - likely hallucination
                log(f"    ⚠ LLM said {count} but not verified in text (possible hallucination)")
                return None
            
            return count
        
        return None
        
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
            log(f"  ✓ Found via regex: {regex_count} rooms")
            row["room_count"] = regex_count
            return row
        
        if not text:
            log(f"  ✗ Could not fetch website")
            return row
        
        # Fall back to LLM extraction
        count = await extract_room_count_llm(client, name, text)
        
        if count:
            log(f"  ✓ Found via LLM (verified): {count} rooms")
            row["room_count"] = count
        else:
            log(f"  ✗ No room count found")
        
        # Delay to avoid Groq rate limits (30 RPM = 1 request every 2 seconds)
        await asyncio.sleep(2.5)
        
        return row


async def enrich_csv(input_file: str, output_file: str, concurrency: int = 5):
    """Enrich CSV with room counts."""
    
    if not GROQ_API_KEY:
        print("❌ Error: ROOM_COUNT_ENRICHER_AGENT_GROQ_KEY not found in .env")
        print("   Add your Groq API key to the .env file")
        return
    
    # Check for existing checkpoint to resume from
    checkpoint_file = output_file.replace(".csv", "_checkpoint.csv")
    
    if os.path.exists(checkpoint_file):
        log(f"📂 Found checkpoint file, resuming...")
        with open(checkpoint_file, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            rows = list(reader)
            fieldnames = reader.fieldnames
        log(f"   Loaded {len(rows)} hotels from checkpoint")
    else:
        # Read input CSV
        with open(input_file, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            rows = list(reader)
            fieldnames = reader.fieldnames
    
    # Ensure room_count column exists
    if "room_count" not in fieldnames:
        fieldnames = list(fieldnames) + ["room_count"]
    
    log(f"Loaded {len(rows)} hotels from {input_file}")
    
    # Count how many need enrichment
    needs_enrichment = [r for r in rows if not r.get("room_count", "").strip() or r.get("room_count", "").strip() == "0"]
    log(f"Hotels needing room count: {len(needs_enrichment)}")
    
    if not needs_enrichment:
        log("All hotels already have room counts!")
        return
    
    # Process in batches
    semaphore = asyncio.Semaphore(concurrency)
    enriched_count = 0
    checkpoint_interval = 25  # Save more frequently due to rate limits
    
    # Track which hotels we've already processed (by name+website combo)
    processed_keys = set()
    for row in rows:
        key = f"{row.get('name', '')}|{row.get('website', '')}"
        if row.get("room_count") and str(row.get("room_count")).strip() and str(row.get("room_count")).strip() != "0":
            processed_keys.add(key)
    
    # Use SSL context that's more permissive for older sites
    async with httpx.AsyncClient(verify=False) as client:
        # Process hotels one by one to maintain order and save checkpoints properly
        for i, row in enumerate(rows):
            key = f"{row.get('name', '')}|{row.get('website', '')}"
            
            # Skip if already has room count
            if key in processed_keys:
                continue
            
            # Process this hotel
            updated_row = await process_hotel(client, row, semaphore)
            rows[i] = updated_row  # Update in place
            
            # Check if we enriched this one
            if updated_row.get("room_count") and str(updated_row.get("room_count")).strip() and str(updated_row.get("room_count")).strip() != "0":
                enriched_count += 1
                processed_keys.add(key)
            
            # Progress update
            if (i + 1) % 20 == 0:
                remaining = len(rows) - len(processed_keys)
                log(f"Progress: {i + 1}/{len(rows)} ({enriched_count} enriched, {remaining} remaining)")
            
            # Save checkpoint frequently
            if (i + 1) % checkpoint_interval == 0:
                with open(checkpoint_file, "w", newline="", encoding="utf-8") as f:
                    writer = csv.DictWriter(f, fieldnames=fieldnames)
                    writer.writeheader()
                    writer.writerows(rows)
                log(f"💾 Checkpoint saved ({i + 1}/{len(rows)})")
    
    # Write final output
    with open(output_file, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    
    # Clean up checkpoint file on successful completion
    if os.path.exists(checkpoint_file):
        os.remove(checkpoint_file)
        log("🧹 Cleaned up checkpoint file")
    
    # Summary
    final_with_count = len([r for r in rows if r.get("room_count") and str(r.get("room_count")).strip() and str(r.get("room_count")).strip() != "0"])
    
    print(f"\n{'='*50}")
    print(f"✅ ENRICHMENT COMPLETE")
    print(f"{'='*50}")
    print(f"Total hotels: {len(rows)}")
    print(f"With room count: {final_with_count} ({final_with_count/len(rows)*100:.1f}%)")
    print(f"Newly enriched this run: {enriched_count}")
    print(f"Output: {output_file}")


def main():
    parser = argparse.ArgumentParser(description="Enrich leads with room counts using LLM")
    parser.add_argument("--input", required=True, help="Input CSV file")
    parser.add_argument("--output", help="Output CSV file (default: input_enriched.csv)")
    parser.add_argument("--concurrency", type=int, default=5, help="Concurrent requests (default: 5)")
    
    args = parser.parse_args()
    
    # Default output file
    if not args.output:
        base = os.path.splitext(args.input)[0]
        args.output = f"{base}_enriched.csv"
    
    asyncio.run(enrich_csv(args.input, args.output, args.concurrency))


if __name__ == "__main__":
    main()

