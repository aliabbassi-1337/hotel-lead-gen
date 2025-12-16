#!/usr/bin/env python3
"""
Sadie Detector - Booking Engine Detection
==========================================
Visits hotel websites to detect booking engines, extract contacts, and take screenshots.

Usage:
    python3 sadie_detector.py --input hotels.csv
"""

import csv
import os
import re
import argparse
import asyncio
from datetime import datetime
from urllib.parse import urlparse
from pathlib import Path
from dataclasses import dataclass, asdict
from typing import Optional

from playwright.async_api import async_playwright, TimeoutError as PWTimeoutError


# ============================================================================
# CONFIGURATION
# ============================================================================

@dataclass
class Config:
    """Central configuration for the detector."""
    # Timeouts (milliseconds)
    timeout_page_load: int = 20000      # 20s
    timeout_booking_click: int = 10000  # 10s
    timeout_popup_detect: int = 3000    # 3s
    
    # Output
    output_csv: str = "sadie_leads.csv"
    screenshots_dir: str = "screenshots"
    log_file: str = "sadie_detector.log"
    
    # Processing
    concurrency: int = 5
    pause_between_hotels: float = 0.5


# Booking engine URL patterns
ENGINE_PATTERNS = {
    "Cloudbeds": ["cloudbeds.com"],
    "Mews": ["mews.com", "mews.li"],
    "SynXis / TravelClick": ["synxis.com", "travelclick.com"],
    "BookingSuite / Booking.com": ["bookingsuite.com"],
    "Little Hotelier": ["littlehotelier.com"],
    "WebRezPro": ["webrezpro.com"],
    "InnRoad": ["innroad.com"],
    "ResNexus": ["resnexus.com"],
    "Newbook": ["newbook.cloud", "newbooksoftware.com"],
    "RMS Cloud": ["rmscloud.com"],
    "RoomRaccoon": ["roomraccoon.com"],
    "SiteMinder": ["thebookingbutton.com", "siteminder.com", "direct-book"],
    "Sabre / CRS": ["sabre.com", "crs.sabre.com"],
    "eZee": ["ezeeabsolute.com", "ezeereservation.com", "ezeetechnosys.com"],
}

# Keywords to identify booking buttons
BOOKING_BUTTON_KEYWORDS = [
    "book now", "book", "reserve", "reserve now", 
    "reservation", "reservations", "check availability", 
    "check rates", "availability", "book online", "book a room",
]

# HTML keywords for engine detection (when URL doesn't reveal engine)
ENGINE_HTML_KEYWORDS = [
    ("cloudbeds", "Cloudbeds"),
    ("synxis", "SynXis / TravelClick"),
    ("travelclick", "SynXis / TravelClick"),
    ("mews.com", "Mews"),
    ("littlehotelier", "Little Hotelier"),
    ("siteminder", "SiteMinder"),
    ("thebookingbutton", "SiteMinder"),
    ("direct-book", "SiteMinder"),
    ("webrezpro", "WebRezPro"),
    ("innroad", "InnRoad"),
    ("resnexus", "ResNexus"),
    ("newbook", "Newbook"),
    ("roomraccoon", "RoomRaccoon"),
    ("ezee", "eZee"),
    ("rmscloud", "RMS Cloud"),
]


# ============================================================================
# DATA MODELS
# ============================================================================

@dataclass
class HotelInput:
    """Input data for a hotel."""
    name: str
    website: str
    phone: str = ""
    address: str = ""
    latitude: str = ""
    longitude: str = ""
    rating: str = ""
    review_count: str = ""
    place_id: str = ""


@dataclass
class HotelResult:
    """Output data for a processed hotel."""
    name: str = ""
    website: str = ""
    booking_url: str = ""
    booking_engine: str = ""
    booking_engine_domain: str = ""
    detection_method: str = ""
    error: str = ""
    phone_google: str = ""
    phone_website: str = ""
    email: str = ""
    address: str = ""
    latitude: str = ""
    longitude: str = ""
    rating: str = ""
    review_count: str = ""
    screenshot_path: str = ""
    place_id: str = ""


# ============================================================================
# LOGGING
# ============================================================================

class Logger:
    """Simple logger that writes to both console and file."""
    
    def __init__(self, log_file: str):
        self.file = open(log_file, "w", encoding="utf-8")
    
    def log(self, msg: str) -> None:
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        line = f"[{ts}] {msg}"
        print(line)
        self.file.write(line + "\n")
        self.file.flush()
    
    def close(self):
        self.file.close()


# Global logger instance
logger: Optional[Logger] = None

def log(msg: str) -> None:
    if logger:
        logger.log(msg)
    else:
        print(msg)


# ============================================================================
# URL UTILITIES
# ============================================================================

def extract_domain(url: str) -> str:
    """Extract domain from URL, stripping www. prefix."""
    if not url:
        return ""
    try:
        parsed = urlparse(url)
        host = (parsed.netloc or "").lower()
        return host[4:] if host.startswith("www.") else host
    except Exception:
        return ""


def normalize_url(url: str) -> str:
    """Ensure URL has https:// prefix."""
    url = (url or "").strip()
    if not url:
        return ""
    if not url.startswith(("http://", "https://")):
        return "https://" + url
    return url


# ============================================================================
# ENGINE DETECTION
# ============================================================================

class EngineDetector:
    """Detects booking engines from URLs, HTML, and network requests."""
    
    @staticmethod
    def from_domain(domain: str) -> tuple[str, str]:
        """Check if domain matches a known booking engine. Returns (engine_name, pattern)."""
        if not domain:
            return ("", "")
        for engine_name, patterns in ENGINE_PATTERNS.items():
            for pat in patterns:
                if pat in domain:
                    return (engine_name, pat)
        return ("", "")
    
    @staticmethod
    def from_url(url: str, hotel_domain: str) -> tuple[str, str, str]:
        """Detect engine from URL. Returns (engine_name, domain, method)."""
        if not url:
            return ("unknown", "", "no_url")
        
        url_lower = url.lower()
        
        # Check URL for engine patterns
        for engine_name, patterns in ENGINE_PATTERNS.items():
            for pat in patterns:
                if pat in url_lower:
                    return (engine_name, pat, "url_pattern_match")
        
        domain = extract_domain(url)
        if not domain:
            return ("unknown", "", "no_domain")
        
        # Check domain
        engine_name, pat = EngineDetector.from_domain(domain)
        if engine_name:
            return (engine_name, domain, "url_domain_match")
        
        # Third-party domain (not hotel's own)
        if hotel_domain and domain != hotel_domain:
            return ("unknown_third_party", domain, "third_party_domain")
        
        return ("proprietary_or_same_domain", domain, "same_domain")
    
    @staticmethod
    def from_html(html: str) -> tuple[str, str]:
        """Detect engine from HTML keywords. Returns (engine_name, method)."""
        if not html:
            return ("", "")
        
        low = html.lower()
        for keyword, engine_name in ENGINE_HTML_KEYWORDS:
            if keyword in low:
                return (engine_name, "html_keyword")
        
        return ("", "")
    
    @staticmethod
    def from_network(network_urls: dict, hotel_domain: str) -> tuple[str, str, str, str]:
        """Check network requests for engine domains. Returns (engine, domain, method, full_url)."""
        for host, full_url in network_urls.items():
            engine_name, pat = EngineDetector.from_domain(host)
            if engine_name:
                return (engine_name, host, "network_sniff", full_url)
        return ("", "", "", "")


# ============================================================================
# CONTACT EXTRACTION
# ============================================================================

class ContactExtractor:
    """Extracts phone numbers and emails from HTML."""
    
    PHONE_PATTERNS = [
        r'\+?1?[-.\s]?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}',  # US format
        r'\+\d{1,3}[-.\s]?\d{1,4}[-.\s]?\d{1,4}[-.\s]?\d{1,9}',  # International
    ]
    
    EMAIL_PATTERN = r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
    
    SKIP_EMAIL_PATTERNS = [
        'example.com', 'domain.com', 'email.com', 'sentry.io',
        'wixpress.com', 'schema.org', '.png', '.jpg', '.gif'
    ]
    
    @classmethod
    def extract_phones(cls, html: str) -> list[str]:
        """Extract phone numbers from HTML."""
        phones = []
        for pattern in cls.PHONE_PATTERNS:
            phones.extend(re.findall(pattern, html))
        
        # Clean and dedupe
        seen = set()
        cleaned = []
        for p in phones:
            p = re.sub(r'[^\d+]', '', p)
            if len(p) >= 10 and p not in seen:
                seen.add(p)
                cleaned.append(p)
        return cleaned[:3]
    
    @classmethod
    def extract_emails(cls, html: str) -> list[str]:
        """Extract email addresses from HTML."""
        matches = re.findall(cls.EMAIL_PATTERN, html)
        
        filtered = []
        for email in matches:
            email_lower = email.lower()
            if not any(skip in email_lower for skip in cls.SKIP_EMAIL_PATTERNS):
                if email_lower not in [e.lower() for e in filtered]:
                    filtered.append(email)
        return filtered[:3]


# ============================================================================
# BROWSER AUTOMATION
# ============================================================================

class BookingButtonFinder:
    """Finds and clicks booking buttons on hotel websites."""
    
    def __init__(self, config: Config):
        self.config = config
    
    async def find_candidates(self, page, max_candidates: int = 5) -> list:
        """Find elements that look like booking buttons."""
        candidates = []
        loc = page.locator("a, button")
        count = await loc.count()
        
        for i in range(count):
            el = loc.nth(i)
            try:
                text = (await el.inner_text() or "").strip().lower()
            except Exception:
                continue
            
            if not text:
                continue
            
            for kw in BOOKING_BUTTON_KEYWORDS:
                if kw in text:
                    candidates.append(el)
                    break
            
            if len(candidates) >= max_candidates:
                break
        
        return candidates
    
    async def click_and_navigate(self, context, page) -> tuple:
        """Click booking button and return (page, url, method)."""
        candidates = await self.find_candidates(page)
        
        if not candidates:
            return (None, None, "no_booking_button_found")
        
        original_url = page.url
        last_booking_url = None
        last_booking_page = None
        
        for el in candidates:
            # Try to detect popup/new tab
            try:
                async with context.expect_page(timeout=self.config.timeout_popup_detect) as p_info:
                    await el.click()
                new_page = await p_info.value
                try:
                    await new_page.wait_for_load_state("domcontentloaded", timeout=self.config.timeout_booking_click)
                except PWTimeoutError:
                    pass
                return (new_page, new_page.url, "popup_page")
            except PWTimeoutError:
                # Try same-page navigation
                try:
                    await el.click()
                except Exception:
                    continue
                try:
                    await page.wait_for_load_state("domcontentloaded", timeout=self.config.timeout_booking_click)
                except PWTimeoutError:
                    pass
                
                if page.url != original_url:
                    last_booking_page = page
                    last_booking_url = page.url
        
        if last_booking_url:
            return (last_booking_page, last_booking_url, "same_page_navigation")
        
        return (None, None, "no_booking_button_effective")


class FrameScanner:
    """Scans iframes for booking engine signatures."""
    
    @staticmethod
    async def scan(page) -> tuple[str, str, str, str]:
        """Scan frames for engine. Returns (engine, domain, method, frame_url)."""
        for frame in page.frames:
            try:
                frame_url = frame.url
            except Exception:
                continue
            
            if not frame_url or frame_url.startswith("about:"):
                continue
            
            # Check frame URL for engine patterns
            for engine_name, patterns in ENGINE_PATTERNS.items():
                for pat in patterns:
                    if pat in frame_url.lower():
                        return (engine_name, pat, "frame_url_match", frame_url)
            
            # Check frame HTML
            try:
                html = await frame.content()
            except Exception:
                html = ""
            
            engine, method = EngineDetector.from_html(html)
            if engine:
                return (engine, "", f"frame_{method}", frame_url)
        
        return ("", "", "", "")


# ============================================================================
# HOTEL PROCESSOR
# ============================================================================

class HotelProcessor:
    """Processes a single hotel: visits site, detects engine, extracts contacts."""
    
    def __init__(self, config: Config, browser, semaphore, screenshots_dir: str):
        self.config = config
        self.browser = browser
        self.semaphore = semaphore
        self.screenshots_dir = screenshots_dir
        self.button_finder = BookingButtonFinder(config)
    
    async def process(self, idx: int, total: int, hotel: dict) -> HotelResult:
        """Process a single hotel and return results."""
        name = hotel.get("name", "")
        website = normalize_url(hotel.get("website", ""))
        
        log(f"[{idx}/{total}] {name} | {website}")
        
        result = HotelResult(
            name=name,
            website=website,
            phone_google=hotel.get("phone", ""),
            address=hotel.get("address", ""),
            latitude=hotel.get("latitude", hotel.get("lat", "")),
            longitude=hotel.get("longitude", hotel.get("lng", "")),
            rating=hotel.get("rating", ""),
            review_count=hotel.get("review_count", ""),
            place_id=hotel.get("place_id", ""),
        )
        
        if not website:
            result.error = "no_website"
            return result
        
        async with self.semaphore:
            result = await self._process_website(result)
        
        return result
    
    async def _process_website(self, result: HotelResult) -> HotelResult:
        """Visit website and extract all data."""
        context = await self.browser.new_context(
            user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
        )
        page = await context.new_page()
        
        # Capture network requests
        network_urls = {}
        def capture_request(request):
            try:
                url = request.url
                host = extract_domain(url)
                if host and host not in network_urls:
                    network_urls[host] = url
            except Exception:
                pass
        page.on("request", capture_request)
        
        try:
            # Load page
            await page.goto(result.website, timeout=self.config.timeout_page_load, wait_until="domcontentloaded")
            await asyncio.sleep(2)  # Let JS render
            
            hotel_domain = extract_domain(page.url)
            log(f"  Loaded: {hotel_domain}")
            
            # Extract contacts
            result = await self._extract_contacts(page, result)
            
            # Find booking engine
            result = await self._detect_engine(context, page, hotel_domain, network_urls, result)
            
            # Take screenshot
            result = await self._take_screenshot(page, result)
            
            log(f"  Engine: {result.booking_engine} ({result.booking_engine_domain or 'n/a'})")
            
        except PWTimeoutError:
            result.error = "timeout"
            log("  ERROR: timeout")
        except Exception as e:
            result.error = f"exception: {str(e)[:100]}"
            log(f"  ERROR: {e}")
        
        await context.close()
        
        if self.config.pause_between_hotels > 0:
            await asyncio.sleep(self.config.pause_between_hotels)
        
        return result
    
    async def _extract_contacts(self, page, result: HotelResult) -> HotelResult:
        """Extract phone and email from page."""
        try:
            html = await page.content()
            phones = ContactExtractor.extract_phones(html)
            emails = ContactExtractor.extract_emails(html)
            
            if phones:
                result.phone_website = phones[0]
            if emails:
                result.email = emails[0]
        except Exception:
            pass
        return result
    
    async def _detect_engine(self, context, page, hotel_domain: str, network_urls: dict, result: HotelResult) -> HotelResult:
        """Detect booking engine using multiple methods."""
        
        # 1. Click booking button
        booking_page, booking_url, method = await self.button_finder.click_and_navigate(context, page)
        result.booking_url = booking_url or ""
        result.detection_method = method
        
        engine_name = ""
        engine_domain = ""
        detection_method = method
        
        # 2. Check booking URL
        if booking_url:
            log(f"  Booking URL: {booking_url}")
            engine_name, engine_domain, url_method = EngineDetector.from_url(booking_url, hotel_domain)
            detection_method = f"{method}+{url_method}"
        
        # 3. Check booking page HTML
        if self._needs_more_detection(engine_name) and booking_page:
            try:
                html = await booking_page.content()
                html_engine, html_method = EngineDetector.from_html(html)
                if html_engine:
                    engine_name = html_engine
                    detection_method = f"{detection_method}+{html_method}"
            except Exception:
                pass
        
        # 4. Check network requests
        if self._needs_more_detection(engine_name):
            net_engine, net_domain, net_method, net_url = EngineDetector.from_network(network_urls, hotel_domain)
            if net_engine:
                engine_name = net_engine
                engine_domain = engine_domain or net_domain
                detection_method = f"{detection_method}+{net_method}"
                if not result.booking_url and net_url:
                    result.booking_url = net_url
        
        # 5. Check iframes
        if self._needs_more_detection(engine_name):
            frame_engine, frame_domain, frame_method, frame_url = await FrameScanner.scan(booking_page or page)
            if frame_engine:
                engine_name = frame_engine
                engine_domain = engine_domain or frame_domain
                detection_method = f"{detection_method}+{frame_method}"
                if not result.booking_url and frame_url:
                    result.booking_url = frame_url
        
        result.booking_engine = engine_name or "unknown"
        result.booking_engine_domain = engine_domain
        result.detection_method = detection_method
        
        return result
    
    def _needs_more_detection(self, engine_name: str) -> bool:
        """Check if we need to try more detection methods."""
        return engine_name in ("", "unknown", "unknown_third_party", "proprietary_or_same_domain")
    
    async def _take_screenshot(self, page, result: HotelResult) -> HotelResult:
        """Take screenshot of booking page."""
        if not result.booking_url:
            return result
        
        try:
            safe_name = re.sub(r'[^\w\-]', '_', result.name)[:50]
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"{safe_name}_{timestamp}.png"
            path = os.path.join(self.screenshots_dir, filename)
            
            await page.screenshot(path=path, full_page=False)
            result.screenshot_path = filename
            log(f"  Screenshot: {filename}")
        except Exception as e:
            log(f"  Screenshot failed: {e}")
        
        return result


# ============================================================================
# MAIN PIPELINE
# ============================================================================

class DetectorPipeline:
    """Main pipeline that orchestrates the detection process."""
    
    def __init__(self, config: Config):
        self.config = config
    
    async def run(self, input_csv: str):
        """Run the full detection pipeline."""
        log("Sadie Detector - Booking Engine Detection")
        
        # Setup
        Path(self.config.screenshots_dir).mkdir(parents=True, exist_ok=True)
        
        # Load hotels
        hotels = self._load_hotels(input_csv)
        log(f"Loaded {len(hotels)} hotels from {input_csv}")
        
        # Resume support
        hotels, append_mode = self._filter_processed(hotels)
        
        if not hotels:
            log("All hotels already processed. Nothing to do.")
            return
        
        log(f"{len(hotels)} hotels remaining to process")
        
        # Process hotels
        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            semaphore = asyncio.Semaphore(self.config.concurrency)
            
            processor = HotelProcessor(self.config, browser, semaphore, self.config.screenshots_dir)
            
            tasks = [
                processor.process(idx, len(hotels), hotel)
                for idx, hotel in enumerate(hotels, 1)
            ]
            
            # Write results
            self._write_results(tasks, append_mode)
            
            await browser.close()
    
    def _load_hotels(self, input_csv: str) -> list[dict]:
        """Load hotels from CSV."""
        hotels = []
        with open(input_csv, newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                hotels.append(row)
        return hotels
    
    def _filter_processed(self, hotels: list[dict]) -> tuple[list[dict], bool]:
        """Filter out already-processed hotels. Returns (remaining, append_mode)."""
        if not os.path.exists(self.config.output_csv):
            return hotels, False
        
        processed = set()
        with open(self.config.output_csv, newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                key = (row.get("name", ""), normalize_url(row.get("website", "")))
                processed.add(key)
        
        if not processed:
            return hotels, False
        
        log(f"Found {len(processed)} already processed, will skip them")
        
        remaining = [
            h for h in hotels
            if (h.get("name", ""), normalize_url(h.get("website", ""))) not in processed
        ]
        return remaining, True
    
    def _write_results(self, tasks: list, append_mode: bool):
        """Write results to CSV as they complete."""
        fieldnames = list(HotelResult.__dataclass_fields__.keys())
        
        mode = "a" if append_mode else "w"
        with open(self.config.output_csv, mode, newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            if not append_mode:
                writer.writeheader()
            
            stats = {"processed": 0, "known_engine": 0, "errors": 0}
            
            for coro in asyncio.as_completed(tasks):
                result = asyncio.get_event_loop().run_until_complete(coro)
                stats["processed"] += 1
                
                if result.error:
                    stats["errors"] += 1
                
                if result.booking_engine not in ("unknown", "unknown_third_party", "proprietary_or_same_domain"):
                    stats["known_engine"] += 1
                
                writer.writerow(asdict(result))
                f.flush()
        
        self._print_summary(stats)
    
    def _print_summary(self, stats: dict):
        """Print final summary."""
        log(f"\n{'='*60}")
        log("COMPLETE!")
        log(f"Processed: {stats['processed']} hotels")
        log(f"Known booking engines: {stats['known_engine']}")
        log(f"Errors: {stats['errors']}")
        log(f"Output: {self.config.output_csv}")
        log(f"Screenshots: {self.config.screenshots_dir}/")
        log(f"{'='*60}")


# ============================================================================
# CLI
# ============================================================================

async def main_async(args):
    config = Config(
        output_csv=args.output,
        screenshots_dir=args.screenshots_dir,
        concurrency=args.concurrency,
        pause_between_hotels=args.pause,
    )
    
    pipeline = DetectorPipeline(config)
    await pipeline.run(args.input)


def main():
    global logger
    
    parser = argparse.ArgumentParser(description="Sadie Detector - Booking Engine Detection")
    parser.add_argument("--input", required=True, help="Input CSV with hotels")
    parser.add_argument("--output", default="sadie_leads.csv", help="Output CSV file")
    parser.add_argument("--screenshots-dir", default="screenshots")
    parser.add_argument("--concurrency", type=int, default=5)
    parser.add_argument("--headed", action="store_true")
    parser.add_argument("--pause", type=float, default=0.5)
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input):
        raise SystemExit(f"Input file not found: {args.input}")
    
    logger = Logger("sadie_detector.log")
    
    try:
        asyncio.run(main_async(args))
    finally:
        logger.close()


if __name__ == "__main__":
    main()
