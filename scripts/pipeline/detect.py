#!/usr/bin/env python3
"""
Sadie Detector - Booking Engine Detection
==========================================
Visits hotel websites to detect booking engines and extract contacts.

Usage:
    python3 sadie_detector.py --input hotels.csv
"""

import csv
import os
import re
import sys
import argparse
import asyncio
from datetime import datetime
from urllib.parse import urlparse
from pathlib import Path
from dataclasses import dataclass, asdict

from loguru import logger
from playwright.async_api import async_playwright, TimeoutError as PWTimeoutError
import httpx


# ============================================================================
# CONFIGURATION
# ============================================================================

@dataclass
class Config:
    """Central configuration for the detector."""
    # Timeouts (milliseconds)
    timeout_page_load: int = 30000      # 30s (we use fallback if slow)
    timeout_booking_click: int = 3000   # 3s (was 10s!)
    timeout_popup_detect: int = 1500    # 1.5s
    
    # Output
    output_csv: str = "sadie_leads.csv"
    log_file: str = "sadie_detector.log"
    
    # Processing
    concurrency: int = 5
    pause_between_hotels: float = 0.2
    headless: bool = True


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
    "RezTrip": ["reztrip.com"],
    "IHG": ["ihg.com"],
    "Marriott": ["marriott.com"],
    "Hilton": ["hilton.com"],
    "Vacatia": ["vacatia.com"],
    "JEHS / iPMS": ["ipms247.com", "live.ipms247.com"],
    "Windsurfer CRS": ["windsurfercrs.com", "res.windsurfercrs.com"],
    "ThinkReservations": ["thinkreservations.com", "secure.thinkreservations.com"],
    "ASI Web Reservations": ["asiwebres.com", "reservation.asiwebres.com"],
    "IQWebBook": ["iqwebbook.com", "us01.iqwebbook.com"],
    "BookDirect": ["bookdirect.net", "ococean.bookdirect.net"],
    "RezStream": ["rezstream.com", "guest.rezstream.com"],
    "Reseze": ["reseze.net"],
    "WebRez": ["webrez.com", "secure.webrez.com"],
    "IB Strategies": ["ibstrategies.com", "secure.ibstrategies.com"],
    "Morey's Piers": ["moreyspiers.com", "irm.moreyspiers.com"],
    "ReservationKey": ["reservationkey.com", "v2.reservationkey.com"],
    "FareHarbor": ["fareharbor.com"],
    "Firefly Reservations": ["fireflyreservations.com", "app.fireflyreservations.com"],
    "Lodgify": ["lodgify.com", "checkout.lodgify.com"],
    "eviivo": ["eviivo.com", "via.eviivo.com"],
    "LuxuryRes": ["luxuryres.com"],
    "FreeToBook": ["freetobook.com", "portal.freetobook.com"],
    "Checkfront": ["checkfront.com"],
    "Beds24": ["beds24.com"],
    "Hotelogix": ["hotelogix.com"],
    "inngenius": ["inngenius.com"],
    "Sirvoy": ["sirvoy.com"],
    "HotelRunner": ["hotelrunner.com"],
    "Amenitiz": ["amenitiz.io", "amenitiz.com"],
    "Hostaway": ["hostaway.com"],
    "Guesty": ["guesty.com"],
    "Hospitable": ["hospitable.com"],
    "Lodgable": ["lodgable.com"],
    "HomHero": ["homhero.com.au", "api.homhero.com.au", "images.prod.homhero"],
    "Streamline": ["streamlinevrs.com", "resortpro"],
    "Triptease": ["triptease.io", "triptease.com", "onboard.triptease"],
    "Yelp Reservations": ["yelp.com/reservations"],
    "Pegasus": ["pegasus.io", "pegs.io"],
    "TravelTripper / Pegasus": ["traveltrip.com", "reztrip.com"],
    # Added from unknown_booking_api analysis
    "OwnerReservations": ["ownerreservations.com", "secure.ownerreservations.com"],
    "GuestRoomGenie": ["guestroomgenie.com", "secure.guestroomgenie.com"],
    "Beyond Pricing": ["beyondpricing.com", "beacon.beyondpricing.com"],
    "HotelKey": ["hotelkeyapp.com", "booking.hotelkeyapp.com"],
    "Preno": ["prenohq.com", "bookdirect.prenohq.com"],
    "Channel Manager AU": ["channelmanager.com.au", "app.channelmanager.com.au"],
    "OfficialBookings": ["officialbookings.com"],
    "Hidden Mountain": ["reservations.hiddenmountain.com"],
    "Blackberry Mountain": ["reservations.blackberrymountain.com"],
    "BookingMood": ["bookingmood.com", "widget.bookingmood.com"],
    "Seekda / KUBE": ["seekda.com", "kube.seekda.com", "booking.seekda.com"],
    "StayDirectly": ["staydirectly.com"],
    "Rentrax": ["rentrax.io"],
    # Major Direct Booking Engines (from research)
    "Profitroom": ["profitroom.com", "booking.profitroom.com"],
    "Avvio": ["avvio.com", "booking.avvio.com"],
    "Net Affinity": ["netaffinity.com", "booking.netaffinity.com"],
    "Simplotel": ["simplotel.com", "booking.simplotel.com"],
    "Cubilis": ["cubilis.com", "booking.cubilis.com"],
    "Cendyn": ["cendyn.com", "booking.cendyn.com"],
    "BookLogic": ["booklogic.net", "booking.booklogic.net"],
    "RateTiger": ["ratetiger.com", "booking.ratetiger.com"],
    "D-Edge": ["d-edge.com", "availpro.com", "booking-ede.com"],
    "BookAssist": ["bookassist.com", "booking.bookassist.org"],
    "GuestCentric": ["guestcentric.com", "booking.guestcentric.com"],
    "Vertical Booking": ["verticalbooking.com", "book.verticalbooking.com"],
    "Busy Rooms": ["busyrooms.com", "booking.busyrooms.com"],
    "myHotel.io": ["myhotel.io"],
    "HotelSpider": ["hotelspider.com", "be.hotelspider.com"],
    "Staah": ["staah.com", "booking.staah.com"],
    "AxisRooms": ["axisrooms.com", "booking.axisrooms.com"],
    "E4jConnect / VikBooking": ["e4jconnect.com", "vikbooking.com"],
    "HBook (WordPress)": ["developer.starter.developer"],  # Often custom
    "Starter Developer": ["starter.developer"],
    "Apaleo": ["apaleo.com", "app.apaleo.com"],
    "Clock PMS": ["clock-software.com", "booking.clock-pms.com"],
    "Mews": ["mews.com", "app.mews.com", "distributor.mews.com"],
    "Protel": ["protel.net", "onity.com"],
    "Frontdesk Anywhere": ["frontdeskanywhere.com", "booking.frontdeskanywhere.com"],
    "HotelTime": ["hoteltime.com"],
    "StayNTouch": ["stayntouch.com", "rover.stayntouch.com"],
    "Oracle Opera": ["oracle.com/opera", "opera-hotel.com"],
    "Infor HMS": ["infor.com"],
    "RoomCloud": ["roomcloud.net"],
    "Oaky": ["oaky.com"],
    "Revinate": ["revinate.com"],
    "TrustYou": ["trustyou.com"],
    # Vacation Rental / Short Stay
    "Escapia": ["escapia.com", "homeaway.escapia.com"],
    "LiveRez": ["liverez.com", "secure.liverez.com"],
    "Barefoot": ["barefoot.com", "barefoot.systems"],
    "Track": ["trackhs.com", "reserve.trackhs.com"],
    "Streamline VRS": ["streamlinevrs.com", "resortpro"],
    "iGMS": ["igms.com"],
    "Smoobu": ["smoobu.com", "login.smoobu.com"],
    "Tokeet": ["tokeet.com"],
    "365Villas": ["365villas.com"],
    "Rentals United": ["rentalsunited.com"],
    "BookingSync": ["bookingsync.com"],
    "JANIIS": ["janiis.com", "secure.janiis.com"],
    "Quibble": ["quibblerm.com"],
    # Australia / NZ specific
    "HiRUM": ["hirum.com.au", "book.hirum.com.au"],
    "iBooked": ["ibooked.net.au", "secure.ibooked.net.au"],
    "Seekom": ["seekom.com", "book.seekom.com"],
    "ResPax": ["respax.com", "app.respax.com"],
    "BookingCenter": ["bookingcenter.com"],
    "RezExpert": ["rezexpert.com"],
    # UK / Europe specific
    "Freetobook UK": ["freetobook.com"],
    "SuperControl": ["supercontrol.co.uk", "members.supercontrol.co.uk"],
    "Anytime Booking": ["anytimebooking.eu", "anytimebooking.co.uk"],
    "Elina PMS": ["elinapms.com"],
    "Guestline": ["guestline.com", "booking.guestline.com"],
    "Nonius": ["nonius.com"],
    # US specific
    "Visual Matrix": ["visualmatrix.com", "pms.visualmatrix.com"],
    "AutoClerk": ["autoclerk.com"],
    "MSI": ["msisolutions.com"],
    "SkyTouch": ["skytouch.com", "pms.skytouch.com"],
    "StayNTouch": ["stayntouch.com"],
    "Hotelogix US": ["hotelogix.com"],
    "RoomKeyPMS": ["roomkeypms.com", "secure.roomkeypms.com"],
}

# Keywords to identify booking buttons
BOOKING_BUTTON_KEYWORDS = [
    "book now", "book", "reserve", "reserve now", 
    "reservation", "reservations", "check availability", 
    "check rates", "availability", "book online", "book a room",
]

# Big chains to skip - they have their own booking systems, not good leads
SKIP_CHAIN_DOMAINS = [
    "marriott.com", "hilton.com", "ihg.com", "hyatt.com", "wyndham.com",
    "choicehotels.com", "bestwestern.com", "radissonhotels.com", "accor.com",
]

# Skip social media and junk websites (not real hotel sites)
SKIP_JUNK_DOMAINS = [
    "facebook.com", "instagram.com", "twitter.com", "youtube.com", "tiktok.com",
    "linkedin.com", "yelp.com", "tripadvisor.com", "google.com",
    "booking.com", "expedia.com", "hotels.com", "airbnb.com", "vrbo.com",
    "dnr.", "parks.", "recreation.", ".gov", ".edu", ".mil",
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
    room_count: str = ""


# ============================================================================
# LOGGING
# ============================================================================

def setup_logging(debug: bool = False):
    """Configure loguru logging."""
    logger.remove()
    
    # Console: INFO by default, DEBUG if flag set
    log_level = "DEBUG" if debug else "INFO"
    logger.add(
        sys.stderr,
        format="<green>{time:HH:mm:ss}</green> | <level>{level: <8}</level> | <level>{message}</level>",
        level=log_level,
        colorize=True,
    )
    
    # File: Always DEBUG
    logger.add(
        "sadie_detector.log",
        format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {message}",
        level="DEBUG",
        rotation="10 MB",
    )


def log(msg: str) -> None:
    """Log wrapper for backwards compatibility."""
    logger.info(msg)


def log_debug(msg: str) -> None:
    """Debug log."""
    logger.debug(msg)


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
    def from_network(network_urls: dict, hotel_domain: str) -> tuple[str, str, str, str]:
        """Check network requests for engine domains. Returns (engine, domain, method, full_url)."""
        # First: check for known booking engines
        for host, full_url in network_urls.items():
            engine_name, pat = EngineDetector.from_domain(host)
            if engine_name:
                return (engine_name, host, "network_sniff", full_url)
        
        # Second: look for ANY booking-related API calls (discover unknown engines)
        booking_keywords = ['book', 'reserv', 'avail', 'pricing', 'checkout', 'payment']
        for host, full_url in network_urls.items():
            # Skip the hotel's own domain and common CDNs/analytics
            if host == hotel_domain:
                continue
            if any(skip in host for skip in [
                'google', 'facebook', 'analytics', 'cdn', 'cloudflare', 'jquery', 'wp-',
                '2o7.net', 'omtrdc.net', 'demdex.net', 'adobedtm', 'omniture',  # Adobe Analytics
                'doubleclick', 'adsrvr', 'adnxs', 'criteo', 'taboola', 'outbrain',  # Ads
                'hotjar', 'mouseflow', 'fullstory', 'heap', 'mixpanel', 'segment',  # Analytics
                'newrelic', 'datadome', 'sentry', 'bugsnag',  # Monitoring
                'shopify', 'shop.app', 'myshopify',  # E-commerce (not booking)
                'nowbookit', 'dimmi.com.au', 'sevenrooms', 'opentable', 'resy.com',  # Restaurant reservations (not hotels)
            ]):
                continue
            
            url_lower = full_url.lower()
            for keyword in booking_keywords:
                if keyword in url_lower:
                    return ("unknown_booking_api", host, "network_sniff_keyword", full_url)
        
        return ("", "", "", "")


# ============================================================================
# CONTACT EXTRACTION
# ============================================================================

class ContactExtractor:
    """Extracts phone numbers, emails, and room count from HTML."""
    
    PHONE_PATTERNS = [
        r'\+?1?[-.\s]?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}',  # US format
        r'\+\d{1,3}[-.\s]?\d{1,4}[-.\s]?\d{1,4}[-.\s]?\d{1,9}',  # International
    ]
    
    EMAIL_PATTERN = r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
    
    # Patterns for room count extraction
    ROOM_COUNT_PATTERNS = [
        r'(\d+)\s*(?:guest\s*)?rooms?(?:\s+available)?',  # "30 rooms", "30 guest rooms"
        r'(\d+)\s*(?:boutique\s*)?(?:guest\s*)?rooms?',   # "30 boutique guest rooms"
        r'(\d+)[\s-]*room\s+(?:hotel|motel|inn|property)',  # "50-room hotel"
        r'(?:hotel|property|we)\s+(?:has|have|offers?|features?)\s+(\d+)\s*rooms?',  # "hotel has 120 rooms"
        r'(?:featuring|with)\s+(\d+)\s*(?:guest\s*)?rooms?',  # "featuring 45 rooms"
        r'(\d+)\s*(?:suites?|units?|apartments?|accommodations?)',  # "20 suites", "15 units"
    ]
    
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
    
    @classmethod
    def extract_room_count(cls, text: str) -> str:
        """Extract number of rooms from text."""
        text_lower = text.lower()
        
        for pattern in cls.ROOM_COUNT_PATTERNS:
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


# ============================================================================
# BROWSER AUTOMATION
# ============================================================================

class BookingButtonFinder:
    """Finds and clicks booking buttons on hotel websites."""
    
    # Domains to skip (social media, etc.)
    SKIP_DOMAINS = [
        "facebook.com", "twitter.com", "instagram.com", "linkedin.com",
        "youtube.com", "tiktok.com", "pinterest.com", "yelp.com",
        "tripadvisor.com", "google.com", "maps.google.com",
        "mailto:", "tel:", "javascript:"
    ]
    
    def __init__(self, config: Config):
        self.config = config
    
    async def _dismiss_popups(self, page):
        """Try to dismiss cookie consent and other popups."""
        log("    [COOKIES] Trying to dismiss popups...")
        
        dismiss_selectors = [
            # Common cookie consent buttons
            "button:has-text('Accept All')",
            "button:has-text('Accept all')",
            "button:has-text('accept all')",
            "button:has-text('Accept')",
            "button:has-text('accept')",
            "button:has-text('I agree')",
            "button:has-text('Agree')",
            "button:has-text('Got it')",
            "button:has-text('OK')",
            "button:has-text('Allow')",
            "button:has-text('Continue')",
            "a:has-text('Accept')",
            "a:has-text('accept')",
            # By class/id
            "[class*='cookie'] button",
            "[class*='Cookie'] button",
            "[id*='cookie'] button",
            "[class*='consent'] button",
            "[class*='gdpr'] button",
            "[class*='privacy'] button:has-text('accept')",
            # Close buttons
            "[class*='cookie'] [class*='close']",
            "[class*='popup'] [class*='close']",
            "[class*='modal'] [class*='close']",
            "button[aria-label='Close']",
            "button[aria-label='close']",
        ]
        
        for selector in dismiss_selectors:
            try:
                btn = page.locator(selector).first
                if await btn.count() > 0:
                    visible = await btn.is_visible()
                    if visible:
                        log(f"    [COOKIES] Clicking: {selector}")
                        await btn.click(timeout=1000)
                        await asyncio.sleep(0.5)
                        return
            except Exception:
                continue
        
        log("    [COOKIES] No popup found to dismiss")
    
    async def find_candidates(self, page, max_candidates: int = 5) -> list:
        """Find elements that look like booking buttons using JavaScript."""
        import time
        
        log("    [FIND] Searching for booking buttons...")
        t0 = time.time()
        
        # Use JavaScript to find ANY clickable element with booking-related text
        # This is more reliable than CSS selectors for dynamic/custom elements
        # PRIORITIZES: Known engines > External domains > Same domain
        js_result = await page.evaluate("""() => {
            const bookingTerms = ['book', 'reserve', 'availability', 'check rates', 'rooms', 'stay', 'inquire', 'enquire', 'rates', 'pricing', 'get started', 'plan your'];
            const excludeTerms = ['facebook', 'twitter', 'instagram', 'spa ', 'conference', 'wedding', 'restaurant', 'careers', 'terms', 'conditions', 'privacy', 'policy', 'contact', 'about', 'faq', 'gallery', 'reviews', 'gift', 'shop', 'store', 'blog', 'news', 'press'];
            const bookingEngineUrls = ['synxis', 'cloudbeds', 'ipms247', 'windsurfercrs', 'travelclick', 
                'webrezpro', 'resnexus', 'thinkreservations', 'asiwebres', 'book-direct', 'bookdirect',
                'reservations', 'booking', 'mews.', 'little-hotelier', 'siteminder', 'thebookingbutton',
                'triptease', 'homhero', 'streamlinevrs', 'freetobook', 'eviivo', 'beds24', 'checkfront',
                'lodgify', 'hostaway', 'guesty', 'staydirectly', 'rentrax', 'bookingmood', 'seekda',
                'profitroom', 'avvio', 'simplotel', 'hotelrunner', 'amenitiz', 'newbook', 'roomraccoon',
                'rezstream', 'fareharbor', 'hirum', 'seekom', 'escapia', 'liverez', 'trackhs'];
            const results = [];
            
            // Get current page domain for external domain detection
            const currentDomain = window.location.hostname.replace('www.', '');
            
            // Get ALL potentially clickable elements (excluding script, style, svg, head elements)
            const elements = document.querySelectorAll('a, button, input[type="submit"], input[type="button"], [role="button"], [onclick], li[onclick], div[onclick], span[onclick], [class*="book"], [class*="reserve"], [class*="btn"], [class*="button"], [class*="cta"]');
            
            for (const el of elements) {
                // SKIP non-visible/non-clickable element types
                const tag = el.tagName.toLowerCase();
                if (['script', 'style', 'svg', 'path', 'meta', 'link', 'head', 'noscript', 'template'].includes(tag)) continue;
                
                const text = (el.innerText || el.textContent || el.value || '').toLowerCase().trim();
                const href = (typeof el.href === 'string' ? el.href : el.getAttribute('href') || '').toLowerCase();
                const rect = el.getBoundingClientRect();
                
                // Skip invisible elements
                if (rect.width === 0 || rect.height === 0) continue;
                // Skip very large elements (containers)
                if (rect.width > 600 || rect.height > 150) continue;
                // Skip very small elements
                if (rect.width < 20 || rect.height < 15) continue;
                
                // Check for excluded terms
                let isExcluded = false;
                for (const term of excludeTerms) {
                    if (href.includes(term) || text.includes(term)) {
                        isExcluded = true;
                        break;
                    }
                }
                if (isExcluded) continue;
                
                // Detect if link goes to external domain
                let isExternal = false;
                let linkDomain = '';
                if (href.startsWith('http')) {
                    try {
                        linkDomain = new URL(href).hostname.replace('www.', '');
                        isExternal = linkDomain !== currentDomain;
                    } catch(e) {}
                }
                
                // Priority 0: href contains known booking engine URL (HIGHEST)
                let priority = 99;
                for (const url of bookingEngineUrls) {
                    if (href.includes(url)) {
                        priority = 0;
                        break;
                    }
                }
                
                // Priority 1: External domain with booking text
                if (priority > 1 && isExternal) {
                    if (text.includes('book') || text.includes('reserve') || text.includes('availability')) {
                        priority = 1;
                    }
                }
                
                // Priority 2-4: Same-domain booking buttons
                if (priority > 2) {
                    // "book now", "book a stay", "reserve now" = highest text priority
                    if (text.includes('book now') || text.includes('book a stay') || text.includes('reserve now') || text.includes('book direct')) {
                        priority = isExternal ? 1 : 2;
                    }
                    // Just "book" or "reserve" = lower priority
                    else if ((text.includes('book') || text.includes('reserve')) && text.length < 30) {
                        priority = isExternal ? 2 : 3;
                    }
                    // "availability", "check rates" = even lower
                    else if (text.includes('availability') || text.includes('check rates') || text.includes('rooms')) {
                        priority = isExternal ? 2 : 4;
                    }
                }
                
                // Only add if it matched something
                if (priority < 99) {
                    // Boost priority for shorter text (more likely to be actual button)
                    // "Book Now" (8 chars) should beat "Booking Terms and Conditions" (30 chars)
                    const lengthPenalty = Math.floor(text.length / 15);  // +1 priority per 15 chars
                    
                    results.push({
                        tag: el.tagName.toLowerCase(),
                        text: text.substring(0, 40),
                        href: href.substring(0, 200),
                        fullHref: el.href || el.getAttribute('href') || '',
                        classes: (el.className || '').substring(0, 100),
                        id: el.id || '',
                        priority: priority + lengthPenalty,
                        isExternal: isExternal,
                        linkDomain: linkDomain,
                        x: rect.x,
                        y: rect.y
                    });
                }
                
                if (results.length >= 20) break;
            }
            
            // Sort by priority
            results.sort((a, b) => a.priority - b.priority);
            return results.slice(0, 10);
        }""")
        
        log(f"    [FIND] Found {len(js_result)} candidates in {time.time()-t0:.1f}s")
        
        candidates = []
        for item in js_result:
            try:
                loc = None
                
                # Strategy 1: Find by ID (most reliable)
                if item.get('id'):
                    loc = page.locator(f"#{item['id']}").first
                    if await loc.count() > 0:
                        candidates.append(loc)
                        log(f"    [FIND] ✓ #{item['id']}: '{item['text'][:25]}'")
                        continue
                
                # Strategy 2: Find by href
                if item.get('href') and item['href'].startswith('http'):
                    loc = page.locator(f"a[href='{item['href']}']").first
                    if await loc.count() > 0:
                        candidates.append(loc)
                        log(f"    [FIND] ✓ href: '{item['text'][:25]}'")
                        continue
                
                # Strategy 3: Find by text content (works for any element type)
                text_clean = item['text'][:25].replace("'", "\\'").replace('"', '\\"')
                if text_clean:
                    # Use xpath for text matching, EXCLUDING non-clickable elements (script, style, svg, etc)
                    # Only match: a, button, div, span, li, input, label - actual clickable elements
                    loc = page.locator(f"//*[self::a or self::button or self::div or self::span or self::li or self::input or self::label][contains(translate(text(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), '{text_clean}')]").first
                    if await loc.count() > 0:
                        candidates.append(loc)
                        log(f"    [FIND] ✓ text: '{item['text'][:25]}'")
                        continue
                
                # Strategy 4: Find by position (last resort)
                if item.get('x') and item.get('y'):
                    loc = page.locator(f"{item['tag']}").first
                    # Just use the tag-based locator as fallback
                    if await loc.count() > 0:
                        candidates.append(loc)
                        log(f"    [FIND] ✓ tag: {item['tag']} '{item['text'][:25]}'")
                        
            except Exception as e:
                log(f"    [FIND] Error: {e}")
                continue
            
            if len(candidates) >= max_candidates:
                break
        
        if not candidates:
            log("    [FIND] No booking buttons found")
            await self._debug_page_elements(page)
        
        return candidates
    
    async def click_and_navigate(self, context, page) -> tuple:
        """Click booking button and return (page, url, method).
        
        ALWAYS returns the booking button URL if found, even without engine detection.
        """
        # Try to dismiss cookie consent banners first
        await self._dismiss_popups(page)
        
        candidates = await self.find_candidates(page)
        
        log(f"    [CLICK] Found {len(candidates)} candidates")
        
        if not candidates:
            await self._debug_page_elements(page)
            return (None, None, "no_booking_button_found", {})
        
        # SIMPLE APPROACH: Get the href from the FIRST candidate (already sorted by priority)
        # Priority order: known engines > external domains > same domain
        el = candidates[0]
        
        try:
            el_text = (await asyncio.wait_for(el.text_content(), timeout=2.0) or "").strip()
            el_href = await asyncio.wait_for(el.get_attribute("href"), timeout=2.0) or ""
        except asyncio.TimeoutError:
            el_text = ""
            el_href = ""
        
        # Check if external
        is_external = ""
        if el_href and el_href.startswith("http"):
            try:
                from urllib.parse import urlparse
                link_domain = urlparse(el_href).netloc.replace("www.", "")
                page_domain = urlparse(page.url).netloc.replace("www.", "")
                is_external = " [EXTERNAL]" if link_domain != page_domain else ""
            except Exception:
                pass
        
        log(f"    [CLICK] Best candidate: '{el_text[:30]}' -> {el_href[:80] if el_href else 'no-href'}{is_external}")
        
        # If it has an href, use it directly (this is the booking URL!)
        if el_href and not el_href.startswith("#") and not el_href.startswith("javascript:"):
            # Make absolute URL if relative
            if not el_href.startswith("http"):
                from urllib.parse import urljoin
                el_href = urljoin(page.url, el_href)
            
            log(f"    [CLICK] ✓ Booking URL: {el_href[:80]}")
            return (None, el_href, "href_extraction", {})  # No click needed, empty network dict
        
        # No href - try clicking to see where it goes and capture network requests
        original_url = page.url
        
        # Set up network listener to catch AJAX requests (for embedded widgets)
        click_network_urls = {}
        def capture_click_request(request):
            try:
                url = request.url
                host = extract_domain(url)
                if host and host not in click_network_urls:
                    click_network_urls[host] = url
            except Exception:
                pass
        
        page.on("request", capture_click_request)
        
        try:
            # Try for popup first
            try:
                async with context.expect_page(timeout=2000) as p_info:
                    await el.click(force=True, no_wait_after=True)
                new_page = await p_info.value
                page.remove_listener("request", capture_click_request)
                log(f"    [CLICK] ✓ Popup: {new_page.url[:60]}")
                return (new_page, new_page.url, "popup_page", click_network_urls)
            except PWTimeoutError:
                pass
            
            # Check if page URL changed
            await asyncio.sleep(1.5)  # Wait longer for AJAX/widget to load
            if page.url != original_url:
                page.remove_listener("request", capture_click_request)
                log(f"    [CLICK] ✓ Navigated: {page.url[:60]}")
                return (page, page.url, "navigation", click_network_urls)
            
            # Check network requests made by the click (for widgets)
            page.remove_listener("request", capture_click_request)
            if click_network_urls:
                log(f"    [CLICK] Widget detected - captured {len(click_network_urls)} network requests")
                return (page, original_url, "widget_interaction", click_network_urls)
                
        except Exception as e:
            page.remove_listener("request", capture_click_request)
            log(f"    [CLICK] Click failed: {e}")
        
        return (None, None, "click_failed", click_network_urls)
    
    async def _debug_page_elements(self, page):
        """Log all buttons and prominent links on the page for debugging."""
        try:
            # Get all buttons
            buttons = await page.locator("button").all()
            button_texts = []
            for b in buttons[:10]:  # Limit to first 10
                try:
                    txt = await b.text_content()
                    if txt and txt.strip():
                        button_texts.append(txt.strip()[:30])
                except Exception:
                    pass
            if button_texts:
                log(f"    [DEBUG] Buttons on page: {button_texts}")
            
            # Get all links with text
            links = await page.locator("a").all()
            link_info = []
            for a in links[:15]:  # Limit to first 15
                try:
                    txt = await a.text_content()
                    href = await a.get_attribute("href") or ""
                    if txt and txt.strip() and len(txt.strip()) < 40:
                        link_info.append(f"'{txt.strip()[:20]}' -> {href[:30] if href else 'no-href'}")
                except Exception:
                    pass
            if link_info:
                log(f"    [DEBUG] Links on page: {link_info[:8]}")
        except Exception as e:
            log(f"    [DEBUG] Error getting page elements: {e}")
    
    async def _try_second_stage_click(self, context, page) -> tuple:
        """Try to find and click a second booking button (in sidebar/modal)."""
        log("    [2ND STAGE] Looking for second button...")
        
        original_url = page.url
        
        # Look for booking buttons that might have appeared
        second_selectors = [
            # Availability first
            "button:has-text('check availability')",
            "a:has-text('check availability')",
            "button:has-text('availability')",
            "a:has-text('availability')",
            # Then book/rates
            "button:has-text('book now')",
            "button:has-text('check rates')",
            "button:has-text('search')",
            "button:has-text('view rates')",
            "a:has-text('book now')",
            "a:has-text('check rates')",
            # Direct booking engine links
            "a[href*='ipms247']",
            "a[href*='synxis']",
            "a[href*='cloudbeds']",
            # Submit buttons
            "input[type='submit']",
            "button[type='submit']",
        ]
        
        for selector in second_selectors:
            try:
                btn = page.locator(selector).first
                count = await btn.count()
                visible = await btn.is_visible() if count > 0 else False
                log(f"    [2ND STAGE] {selector}: count={count}, visible={visible}")
                
                if count > 0 and visible:
                    # Try to get href first (if it's a link)
                    href = await btn.get_attribute("href") or ""
                    if href and href.startswith("http"):
                        log(f"    [2ND STAGE] Found href: {href[:60]}")
                        return (None, href, "two_stage_href")
                    
                    try:
                        async with context.expect_page(timeout=1500) as p_info:
                            await btn.click(force=True, no_wait_after=True)
                        new_page = await p_info.value
                        log(f"    [2ND STAGE] Got popup: {new_page.url[:60]}")
                        return (new_page, new_page.url, "two_stage_popup")
                    except PWTimeoutError:
                        log("    [2ND STAGE] No popup from click")
                        
                        # Check if URL changed (form submission)
                        await asyncio.sleep(0.5)
                        if page.url != original_url:
                            log(f"    [2ND STAGE] URL changed: {page.url[:60]}")
                            return (page, page.url, "two_stage_navigation")
            except Exception as e:
                log(f"    [2ND STAGE] Error: {e}")
                continue
        
        return None


# ============================================================================
# HTTP PRE-CHECK (fast filter for dead URLs)
# ============================================================================

async def http_precheck(url: str, timeout: float = 5.0) -> tuple[bool, str]:
    """
    Quick HTTP HEAD/GET to check if URL is reachable before launching Playwright.
    Returns (is_reachable, error_message).
    """
    try:
        async with httpx.AsyncClient(
            timeout=timeout,
            follow_redirects=True,
            verify=False,  # Skip SSL verification like Playwright does
        ) as client:
            # Try HEAD first (faster), fall back to GET
            try:
                resp = await client.head(url)
            except httpx.HTTPStatusError:
                resp = await client.get(url)

            if resp.status_code >= 400:
                return (False, f"HTTP {resp.status_code}")
            return (True, "")
    except httpx.TimeoutException:
        return (False, "timeout")
    except httpx.ConnectError:
        return (False, "connection_refused")
    except Exception as e:
        return (False, str(e)[:50])


# ============================================================================
# HOTEL PROCESSOR
# ============================================================================

class HotelProcessor:
    """Processes a single hotel: visits site, detects engine, extracts contacts."""

    def __init__(self, config: Config, browser, semaphore, context_queue: asyncio.Queue = None):
        self.config = config
        self.browser = browser
        self.semaphore = semaphore
        self.button_finder = BookingButtonFinder(config)
        self.context_queue = context_queue  # Async queue of reusable browser contexts
    
    async def process(self, idx: int, total: int, hotel: dict) -> HotelResult:
        """Process a single hotel and return results."""
        # Support both 'name' and 'hotel' column names
        name = hotel.get("name") or hotel.get("hotel", "")
        website = normalize_url(hotel.get("website", ""))
        
        # Fallback: use domain as name if no name provided
        if not name and website:
            name = extract_domain(website).replace("www.", "").split(".")[0].title()
        
        log(f"[{idx}/{total}] {name} | {website}")
        
        result = HotelResult(
            name=name,
            website=website,
            phone_google=hotel.get("phone", ""),
            address=hotel.get("address", ""),
            latitude=hotel.get("latitude", hotel.get("lat", "")),
            longitude=hotel.get("longitude", hotel.get("lng", hotel.get("long", ""))),
            rating=hotel.get("rating", ""),
            review_count=hotel.get("review_count", ""),
        )
        
        if not website:
            # Not an error - just skip silently (no website to check)
            return result

        # Quick HTTP pre-check before launching Playwright (saves ~30s per dead URL)
        is_reachable, precheck_error = await http_precheck(website)
        if not is_reachable:
            log(f"  [PRECHECK] ✗ Skipping (not reachable): {precheck_error}")
            result.error = f"precheck_failed: {precheck_error}"
            return result

        async with self.semaphore:
            result = await self._process_website(result)
        
        return result
    
    async def _process_website(self, result: HotelResult) -> HotelResult:
        """Visit website and extract all data."""
        # Reuse context from queue if available, otherwise create new one
        if self.context_queue:
            context = await self.context_queue.get()
            reuse_context = True
        else:
            context = await self.browser.new_context(
                user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
                ignore_https_errors=True,
            )
            reuse_context = False
        page = await context.new_page()
        
        # Capture homepage network requests (for fallback detection)
        homepage_network = {}
        def capture_homepage_request(request):
            try:
                url = request.url
                host = extract_domain(url)
                if host and host not in homepage_network:
                    homepage_network[host] = url
            except Exception:
                pass
        page.on("request", capture_homepage_request)
        
        try:
            import time
            
            # 1. Load homepage (don't wait for full load - find buttons ASAP)
            t0 = time.time()
            try:
                # Use shorter timeout and don't wait for network idle
                await page.goto(result.website, timeout=30000, wait_until="domcontentloaded")
            except PWTimeoutError:
                # If domcontentloaded times out, try with just commit
                try:
                    await page.goto(result.website, timeout=15000, wait_until="commit")
                except Exception:
                    pass
            log(f"  [TIME] goto: {time.time()-t0:.1f}s")
            
            # Wait for iframes and JS to render before scanning HTML
            await asyncio.sleep(1.5)  # Reduced from 3.0s - most JS loads faster
            
            hotel_domain = extract_domain(page.url)
            log(f"  Loaded: {hotel_domain}")
            
            # 2. Extract contacts
            t0 = time.time()
            result = await self._extract_contacts_fast(page, result)
            log(f"  [TIME] contacts: {time.time()-t0:.1f}s")
            
            engine_name = ""
            engine_domain = ""
            booking_url = ""
            click_method = ""
            
            # 3. STAGE 0: Quick scan homepage HTML for engine patterns (fastest check)
            t0 = time.time()
            html_engine, html_domain = await self._scan_html_for_engines(page)
            log(f"  [TIME] homepage_html_scan: {time.time()-t0:.1f}s")
            
            if html_engine:
                log(f"  [STAGE0] ✓ Found engine in homepage HTML: {html_engine}")
                engine_name = html_engine
                engine_domain = html_domain
                click_method = "homepage_html_scan"
                
                # Try to grab a sample booking URL from page for verification
                # PRIORITIZE: External domains > Same domain
                try:
                    all_booking_urls = await page.evaluate("""
                        (hotelDomain) => {
                            const links = document.querySelectorAll('a[href]');
                            const bookingPatterns = ['/book', '/checkout', '/reserve', '/availability', 'booking=', 'checkin=', '/enquiry', '/inquiry', '/rooms', '/stay', '/accommodation'];
                            // Known booking engine domains - if link goes to these, it's a booking URL
                            const knownEngines = ['synxis', 'cloudbeds', 'lodgify', 'freetobook', 'mews.', 'siteminder', 'thebookingbutton', 
                                'webrezpro', 'resnexus', 'beds24', 'checkfront', 'eviivo', 'ipms247', 'asiwebres', 'thinkreservations',
                                'bookdirect', 'rezstream', 'fareharbor', 'newbook', 'roomraccoon', 'hostaway', 'guesty', 'staydirectly',
                                'rentrax', 'bookingmood', 'seekda', 'profitroom', 'avvio', 'simplotel', 'hotelrunner', 'amenitiz'];
                            const junk = ['terms', 'conditions', 'policy', 'privacy', 'faq', 'about', 'appraisal', 'cancellation', 'facebook', 'twitter', 'instagram'];
                            const results = [];
                            
                            for (const a of links) {
                                const href = a.href;
                                const hrefLower = href.toLowerCase();
                                if (!href.startsWith('http')) continue;
                                if (junk.some(j => hrefLower.includes(j))) continue;
                                
                                // Check if it matches booking patterns OR goes to known engine domain
                                const matchesPattern = bookingPatterns.some(p => hrefLower.includes(p));
                                const isKnownEngine = knownEngines.some(e => hrefLower.includes(e));
                                if (!matchesPattern && !isKnownEngine) continue;
                                
                                // Check if external domain
                                try {
                                    const linkDomain = new URL(href).hostname.replace('www.', '');
                                    const isExternal = linkDomain !== hotelDomain;
                                    results.push({ href, isExternal, domain: linkDomain });
                                } catch(e) {}
                            }
                            
                            // Fallback: property/listing links
                            if (results.length === 0) {
                                for (const a of links) {
                                    const href = a.href;
                                    const hrefLower = href.toLowerCase();
                                    if (hrefLower.includes('/property/') || hrefLower.includes('/listing/') || 
                                        hrefLower.includes('/unit/') || hrefLower.includes('/rental/')) {
                                        try {
                                            const linkDomain = new URL(href).hostname.replace('www.', '');
                                            const isExternal = linkDomain !== hotelDomain;
                                            results.push({ href, isExternal, domain: linkDomain });
                                        } catch(e) {}
                                    }
                                }
                            }
                            return results;
                        }
                    """, hotel_domain)
                    
                    if all_booking_urls:
                        # Prioritize: known engines > external domains > same domain
                        best_url = None
                        best_priority = -1
                        
                        for item in all_booking_urls:
                            href = item['href']
                            is_external = item['isExternal']
                            link_domain = item['domain']
                            
                            # Check if it's a known engine (highest priority)
                            is_known_engine = False
                            for eng_name, patterns in ENGINE_PATTERNS.items():
                                if any(pat in link_domain for pat in patterns):
                                    is_known_engine = True
                                    break
                            
                            if is_known_engine:
                                priority = 3
                            elif is_external:
                                priority = 2
                            else:
                                priority = 1
                            
                            if priority > best_priority:
                                best_priority = priority
                                best_url = href
                        
                        if best_url:
                            booking_url = best_url
                            priority_desc = {3: "known engine", 2: "external domain", 1: "same domain"}
                            log(f"  [STAGE0] Sample booking URL ({priority_desc.get(best_priority, 'unknown')}): {booking_url[:60]}...")
                    else:
                        log(f"  [STAGE0] No booking URLs in links, checking iframes...")
                        # Try to get booking URL from iframes
                        try:
                            iframe_urls = await page.evaluate("""
                                () => {
                                    const iframes = document.querySelectorAll('iframe[src]');
                                    const results = [];
                                    for (const iframe of iframes) {
                                        const src = iframe.src || '';
                                        if (src && src.startsWith('http')) {
                                            results.push(src);
                                        }
                                    }
                                    return results;
                                }
                            """)
                            for iframe_url in iframe_urls:
                                # Check if iframe is a known booking engine
                                iframe_lower = iframe_url.lower()
                                for eng_name, patterns in ENGINE_PATTERNS.items():
                                    if any(pat in iframe_lower for pat in patterns):
                                        booking_url = iframe_url
                                        log(f"  [STAGE0] Found booking iframe: {iframe_url[:60]}...")
                                        break
                                if booking_url:
                                    break
                        except Exception as e2:
                            log(f"  [STAGE0] Iframe scan error: {e2}")
                except Exception as e:
                    log(f"  [STAGE0] Error getting sample URL: {e}")
            
            # 5. STAGE 1: If engine found but no booking URL yet, find one via button click
            # If no engine found, also try button click to find both
            if not engine_name or engine_name in ("unknown", "unknown_third_party", "proprietary_or_same_domain") or not booking_url:
                log(f"  [STAGE1] Looking for booking URL via button click...")
                t0 = time.time()
                button_url, button_method, click_network_urls = await self._find_booking_url(context, page, hotel_domain)
                log(f"  [TIME] button_find: {time.time()-t0:.1f}s")
                
                if button_url:
                    booking_url = button_url
                    if not click_method:
                        click_method = button_method
                    else:
                        click_method = f"{click_method}+{button_method}"
                
                # Check if widget click revealed an engine (even if we already had one from HTML)
                if click_network_urls and self._needs_fallback(engine_name):
                    net_engine, net_domain, net_method, net_url = EngineDetector.from_network(click_network_urls, hotel_domain)
                    if net_engine:
                        log(f"  [WIDGET NET] ✓ Found engine from click network: {net_engine}")
                        engine_name = net_engine
                        engine_domain = net_domain
                        click_method = f"{click_method}+widget_network" if click_method else "widget_network"
                        if net_url and not booking_url:
                            booking_url = net_url
            
            result.booking_url = booking_url or ""
            result.detection_method = click_method
            
            # 5. If we have a booking URL but no engine yet, analyze it
            if booking_url and (not engine_name or engine_name in ("unknown", "unknown_third_party", "proprietary_or_same_domain")):
                t0 = time.time()
                engine_name, engine_domain, result = await self._analyze_booking_page(
                    context, booking_url, hotel_domain, click_method, result
                )
                log(f"  [TIME] analyze_booking: {time.time()-t0:.1f}s")
            
            # 5. FALLBACK: Check homepage network
            if self._needs_fallback(engine_name):
                t0 = time.time()
                net_engine, net_domain, _, net_url = EngineDetector.from_network(homepage_network, hotel_domain)
                log(f"  [TIME] network_fallback: {time.time()-t0:.1f}s")
                if net_engine and net_engine not in ("unknown_third_party",):
                    engine_name = net_engine
                    engine_domain = net_domain
                    result.detection_method += "+homepage_network"
                    if net_url and not result.booking_url:
                        result.booking_url = net_url
            
            # 6. FALLBACK: Scan iframes
            if self._needs_fallback(engine_name):
                t0 = time.time()
                frame_engine, frame_domain, frame_url = await self._scan_frames(page)
                log(f"  [TIME] frame_scan: {time.time()-t0:.1f}s")
                if frame_engine:
                    engine_name = frame_engine
                    engine_domain = frame_domain
                    result.detection_method += "+frame_scan"
                    if frame_url and not result.booking_url:
                        result.booking_url = frame_url
            
            # 7. FALLBACK: HTML keyword
            if self._needs_fallback(engine_name):
                t0 = time.time()
                html_engine = await self._detect_from_html(page)
                log(f"  [TIME] html_detect: {time.time()-t0:.1f}s")
                if html_engine:
                    engine_name = html_engine
                    result.detection_method += "+html_keyword"
            
            result.booking_engine = engine_name or "unknown"
            result.booking_engine_domain = engine_domain
            
            # Check if booking URL is actually a junk domain (facebook, etc) - mark for retry
            junk_booking_domains = [
                "facebook.com", "instagram.com", "twitter.com", "youtube.com",
                "linkedin.com", "yelp.com", "tripadvisor.com", "google.com",
                "booking.com", "expedia.com", "hotels.com", "airbnb.com", "vrbo.com",
            ]
            if result.booking_url:
                booking_domain = extract_domain(result.booking_url)
                if any(junk in booking_domain for junk in junk_booking_domains):
                    log(f"  Junk booking URL detected: {booking_domain} - marking for retry")
                    result.booking_url = ""
                    result.booking_engine = ""
                    result.booking_engine_domain = ""
                    result.error = "junk_booking_url_retry"
            
            # Only mark as error if we found absolutely nothing useful
            if not result.booking_url and result.booking_engine in ("", "unknown"):
                result.error = "no_booking_found"
            
            log(f"  Engine: {result.booking_engine} ({result.booking_engine_domain or 'n/a'})")
            
        except PWTimeoutError:
            result.error = "timeout"
            log("  ERROR: timeout")
        except Exception as e:
            # Remove newlines to prevent CSV breakage
            error_msg = str(e).replace('\n', ' ').replace('\r', '')[:100]
            result.error = f"exception: {error_msg}"
            log(f"  ERROR: {e}")
        
        # Return context to queue or close it
        if reuse_context and self.context_queue is not None:
            await page.close()  # Close the page, keep context
            await self.context_queue.put(context)
        else:
            await context.close()

        if self.config.pause_between_hotels > 0:
            await asyncio.sleep(self.config.pause_between_hotels)

        return result
    
    def _needs_fallback(self, engine_name: str) -> bool:
        """Check if we need to try fallback detection."""
        return engine_name in ("", "unknown", "unknown_third_party", "proprietary_or_same_domain")
    
    async def _extract_contacts_fast(self, page, result: HotelResult) -> HotelResult:
        """Extract phone, email, and room count using JS evaluate (non-blocking)."""
        try:
            # Get body text via JS - doesn't wait for page stability
            text = await page.evaluate("document.body ? document.body.innerText : ''")
            phones = ContactExtractor.extract_phones(text)
            emails = ContactExtractor.extract_emails(text)
            room_count = ContactExtractor.extract_room_count(text)
            
            if phones:
                result.phone_website = phones[0]
            if emails:
                result.email = emails[0]
            if room_count:
                result.room_count = room_count
            
            # Also extract from tel: and mailto: links
            if not result.phone_website:
                try:
                    tel_links = await page.evaluate("""
                        () => Array.from(document.querySelectorAll('a[href^="tel:"]'))
                            .map(a => a.href.replace('tel:', '').replace(/[^0-9+()-]/g, ''))
                            .filter(p => p.length >= 10)
                    """)
                    if tel_links:
                        result.phone_website = tel_links[0]
                except Exception:
                    pass
            
            if not result.email:
                try:
                    mailto_links = await page.evaluate("""
                        () => Array.from(document.querySelectorAll('a[href^="mailto:"]'))
                            .map(a => a.href.replace('mailto:', '').split('?')[0])
                            .filter(e => e.includes('@'))
                    """)
                    if mailto_links:
                        result.email = mailto_links[0]
                except Exception:
                    pass
                    
        except Exception:
            pass
        return result
    
    async def _scan_html_for_booking_urls(self, page) -> list[tuple[str, str, str]]:
        """Scan page HTML for booking URLs in href attributes.
        
        Returns list of (url, engine_name, engine_domain) tuples.
        engine_name/domain will be empty if no known engine detected in URL.
        """
        booking_urls = []
        
        try:
            # Get all hrefs from the page
            hrefs = await page.evaluate("""
                () => {
                    const links = document.querySelectorAll('a[href]');
                    return Array.from(links).map(a => a.href).filter(h => h && h.startsWith('http'));
                }
            """)
            
            # Booking URL patterns to look for
            booking_patterns = [
                '/booking', '/book-', '/booknow', '/book_now', '/book?',
                '/reserve', '/reservation', '/check-availability',
                '/availability', '/rates', 'booking=', 'checkin=',
                'listing=', '/enquiry', '/inquiry', '/make-booking',
            ]
            
            # Patterns that indicate NOT a real booking URL
            exclude_patterns = [
                'terms', 'conditions', 'policy', 'privacy', 'legal',
                'faq', 'help', 'about', 'contact', 'cancellation',
                'refund', 'disclaimer', 'appraisal',
            ]
            
            seen = set()
            for href in hrefs:
                href_lower = href.lower()
                
                # Skip if not a booking-related URL
                if not any(pat in href_lower for pat in booking_patterns):
                    continue
                
                # Skip terms/conditions/policy pages
                if any(excl in href_lower for excl in exclude_patterns):
                    continue
                
                # Skip OTAs and junk
                junk_domains = [
                    "booking.com", "expedia.com", "hotels.com", "airbnb.com",
                    "tripadvisor.com", "facebook.com", "instagram.com", "google.com",
                    "yelp.com", "vrbo.com", "agoda.com",
                ]
                if any(junk in href_lower for junk in junk_domains):
                    continue
                
                # Dedupe
                if href in seen:
                    continue
                seen.add(href)
                
                # Check if URL contains a known engine
                engine_name = ""
                engine_domain = ""
                for eng_name, patterns in ENGINE_PATTERNS.items():
                    for pat in patterns:
                        if pat in href_lower:
                            engine_name = eng_name
                            engine_domain = pat
                            break
                    if engine_name:
                        break
                
                booking_urls.append((href, engine_name, engine_domain))
                
                # Log what we found
                if engine_name:
                    log(f"  [HTML URL] ✓ Found {engine_name} in: {href[:60]}...")
                else:
                    log(f"  [HTML URL] Booking URL: {href[:60]}...")
        
        except Exception as e:
            log(f"  [HTML URL] Error scanning: {e}")
        
        return booking_urls
    
    async def _find_booking_url(self, context, page, hotel_domain: str) -> tuple[str, str, dict]:
        """Find booking button and get the booking URL.
        
        Returns (booking_url, method, click_network_urls).
        click_network_urls contains network requests captured during button click (for widgets).
        """
        booking_page, booking_url, method, click_network_urls = await self.button_finder.click_and_navigate(context, page)
        
        # Check if click triggered a widget with booking engine requests
        if click_network_urls:
            log(f"  [WIDGET] Captured {len(click_network_urls)} network requests from click")
            engine_name, engine_domain, net_method, engine_url = EngineDetector.from_network(click_network_urls, hotel_domain)
            if engine_name:
                log(f"  [WIDGET] Found engine from click: {engine_name} ({engine_domain})")
                # Use the engine URL if no booking URL yet
                if not booking_url and engine_url:
                    booking_url = engine_url
                    method = "widget_network_sniff"
        
        # Close the booking page if it opened (we'll open a fresh one for sniffing)
        if booking_page and booking_page != page:
            try:
                await booking_page.close()
            except Exception:
                pass
        
        return booking_url, method, click_network_urls
    
    async def _analyze_booking_page(self, context, booking_url: str, hotel_domain: str, 
                                     click_method: str, result: HotelResult) -> tuple[str, str, HotelResult]:
        """Navigate to booking URL, sniff network, detect engine.
        Returns (engine_name, engine_domain, result)."""
        log(f"  Booking URL: {booking_url[:80]}...")
        
        page = await context.new_page()
        network_urls = {}
        engine_name = ""
        engine_domain = ""
        
        # Capture all network requests
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
            # Navigate to booking URL
            await page.goto(booking_url, timeout=self.config.timeout_page_load, wait_until="domcontentloaded")
            await asyncio.sleep(3.0)  # Let booking engine load (increased for slow widgets)
            
            # FIRST: Scan booking page for external booking links
            # This catches cases like wildluxury.co/book-now with "Check Availability" to contemporaryhotels.com.au
            external_booking_url = await self._find_external_booking_url(page, hotel_domain)
            if external_booking_url:
                log(f"  [BOOKING PAGE] Found external URL: {external_booking_url[:60]}...")
                result.booking_url = external_booking_url
                engine_name, engine_domain, url_method = EngineDetector.from_url(external_booking_url, hotel_domain)
                if engine_name and engine_name not in ("proprietary_or_same_domain",):
                    result.detection_method = f"{click_method}+external_booking_url"
                    await page.close()
                    return engine_name, engine_domain, result
            
            # Detect engine from network requests (most reliable)
            engine_name, engine_domain, net_method, engine_url = EngineDetector.from_network(network_urls, hotel_domain)
            
            # Fallback: check the URL itself
            if not engine_name:
                engine_name, engine_domain, url_method = EngineDetector.from_url(booking_url, hotel_domain)
                net_method = url_method
            
            # Fallback: scan iframes on booking page (catches embedded engines like FreeToBook)
            if not engine_name or engine_name in ("unknown", "unknown_third_party", "proprietary_or_same_domain"):
                frame_engine, frame_domain, frame_url = await self._scan_frames(page)
                if frame_engine:
                    engine_name = frame_engine
                    engine_domain = frame_domain
                    net_method = "iframe_on_booking_page"
                    if frame_url:
                        engine_url = frame_url
            
            # Fallback: scan HTML/JS source for booking engine patterns
            if not engine_name or engine_name in ("unknown", "unknown_third_party", "proprietary_or_same_domain"):
                html_engine, html_domain = await self._scan_html_for_engines(page)
                if html_engine:
                    engine_name = html_engine
                    engine_domain = html_domain
                    net_method = "html_source_scan"
            
            # MULTI-STEP FALLBACK: Try clicking another booking button on this page
            # This handles cases like /accommodations/ -> /cabins/riverside-cabin/ -> BookingMood widget
            if not engine_name or engine_name in ("unknown", "unknown_third_party", "proprietary_or_same_domain"):
                try:
                    # Check if page is still valid before trying multi-step
                    if page.is_closed():
                        log("  [MULTI-STEP] Page already closed, skipping")
                    else:
                        log("  [MULTI-STEP] Trying second button click...")
                        second_page, second_url, second_method, second_network = await self.button_finder.click_and_navigate(context, page)
                        
                        if second_url and second_url != booking_url:
                            log(f"  [MULTI-STEP] Found deeper URL: {second_url[:60]}...")
                            result.booking_url = second_url
                            
                            # Check if second click network caught anything
                            if second_network:
                                net_engine, net_domain, _, net_url = EngineDetector.from_network(second_network, hotel_domain)
                                if net_engine:
                                    engine_name = net_engine
                                    engine_domain = net_domain
                                    net_method = f"{net_method}+second_click_network"
                                    if net_url:
                                        result.booking_url = net_url
                            
                            # If still no engine, navigate to second URL and scan
                            if not engine_name or engine_name in ("unknown", "unknown_third_party", "proprietary_or_same_domain"):
                                try:
                                    if not page.is_closed():
                                        await page.goto(second_url, timeout=self.config.timeout_page_load, wait_until="domcontentloaded")
                                        await asyncio.sleep(2.0)  # Let widget load
                                        
                                        # Scan for engine
                                        html_engine, html_domain = await self._scan_html_for_engines(page)
                                        if html_engine:
                                            engine_name = html_engine
                                            engine_domain = html_domain
                                            net_method = f"{net_method}+second_page_scan"
                                        
                                        # Check network again
                                        if (not engine_name or engine_name in ("unknown", "unknown_third_party", "proprietary_or_same_domain")) and network_urls:
                                            net_engine2, net_domain2, _, net_url2 = EngineDetector.from_network(network_urls, hotel_domain)
                                            if net_engine2:
                                                engine_name = net_engine2
                                                engine_domain = net_domain2
                                                net_method = f"{net_method}+second_page_network"
                                except Exception as e:
                                    log(f"  [MULTI-STEP] Error on second page: {e}")
                        
                        if second_page and second_page != page:
                            try:
                                await second_page.close()
                            except Exception:
                                pass
                except Exception as e:
                    log(f"  [MULTI-STEP] Error: {e}")
            
            # Update booking URL if we found a better one from network/iframe
            if engine_url and engine_url != booking_url:
                result.booking_url = engine_url
            # Also update if we found external booking URL earlier
            elif external_booking_url:
                result.booking_url = external_booking_url
            
            result.detection_method = f"{click_method}+{net_method}"
            
        except Exception as e:
            log(f"  Booking page error: {e}")
        finally:
            await page.close()
        
        return engine_name, engine_domain, result
    
    async def _find_external_booking_url(self, page, hotel_domain: str) -> str:
        """Find external booking URLs on the current page.
        
        This catches cases like wildluxury.co/book-now with "Check Availability" 
        buttons linking to contemporaryhotels.com.au
        """
        try:
            external_urls = await page.evaluate("""
                (hotelDomain) => {
                    const links = document.querySelectorAll('a[href]');
                    const bookingText = ['book', 'reserve', 'availability', 'check avail', 'enquire', 'inquire'];
                    const junk = ['terms', 'conditions', 'policy', 'privacy', 'faq', 'facebook', 'instagram', 'twitter', 'sevenrooms', 'opentable', 'resy.com'];
                    
                    for (const a of links) {
                        const href = a.href;
                        if (!href || !href.startsWith('http')) continue;
                        
                        // Get link text
                        const text = (a.innerText || a.textContent || '').toLowerCase().trim();
                        const ariaLabel = (a.getAttribute('aria-label') || '').toLowerCase();
                        const title = (a.getAttribute('title') || '').toLowerCase();
                        const combinedText = text + ' ' + ariaLabel + ' ' + title;
                        
                        // Must have booking-related text
                        if (!bookingText.some(t => combinedText.includes(t))) continue;
                        
                        // Skip junk
                        if (junk.some(j => href.toLowerCase().includes(j) || combinedText.includes(j))) continue;
                        
                        // Check if external domain
                        try {
                            const linkDomain = new URL(href).hostname.replace('www.', '');
                            if (linkDomain !== hotelDomain) {
                                return href;  // Return first external booking link
                            }
                        } catch(e) {}
                    }
                    return '';
                }
            """, hotel_domain)
            
            return external_urls
        except Exception as e:
            log(f"  [BOOKING PAGE] Error scanning: {e}")
            return ""
    
    async def _scan_frames(self, page) -> tuple[str, str, str]:
        """Scan iframes for booking engine patterns. Returns (engine, domain, url)."""
        for frame in page.frames:
            try:
                frame_url = frame.url
            except Exception:
                continue
            
            if not frame_url or frame_url.startswith("about:"):
                continue
            
            # Check frame URL for engine patterns (fast, no waiting)
            for engine_name, patterns in ENGINE_PATTERNS.items():
                for pat in patterns:
                    if pat in frame_url.lower():
                        return (engine_name, pat, frame_url)
        
        # Skip frame HTML scanning - too slow and unreliable
        return ("", "", "")
    
    async def _detect_from_html(self, page) -> str:
        """Detect engine from page HTML keywords (non-blocking)."""
        try:
            # Use evaluate instead of content() - doesn't wait
            html = await page.evaluate("document.documentElement.outerHTML")
            return self._detect_engine_from_html_content(html)
        except Exception:
            return ""
    
    async def _scan_html_for_engines(self, page) -> tuple[str, str]:
        """Scan page HTML for booking engine patterns.
        
        Two-pronged approach:
        1. Extract ALL URLs/domains from HTML (scripts, links, images, iframes)
        2. Check each domain against ENGINE_PATTERNS
        3. Also search for known keywords in the raw HTML
        """
        try:
            # Get full HTML
            html = await page.evaluate("document.documentElement.outerHTML")
            html_lower = html.lower()
            
            # 1. Extract all URLs from HTML using regex
            import re
            url_pattern = r'(?:src|href|data-src|action)=["\']?(https?://[^"\'\s>]+)'
            found_urls = re.findall(url_pattern, html, re.IGNORECASE)
            
            # Also get inline URLs that might be in JS
            js_url_pattern = r'["\']?(https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}[^"\'\s]*)["\']?'
            found_urls.extend(re.findall(js_url_pattern, html))
            
            # Extract unique domains
            domains_found = set()
            for url in found_urls:
                try:
                    domain = extract_domain(url)
                    if domain:
                        domains_found.add(domain.lower())
                except Exception:
                    pass
            
            # 2. Check each domain against ENGINE_PATTERNS
            for domain in domains_found:
                for engine_name, patterns in ENGINE_PATTERNS.items():
                    for pat in patterns:
                        if pat.lower() in domain:
                            log(f"    [HTML SCAN] Found domain '{domain}' -> {engine_name}")
                            return (engine_name, pat)
            
            # 3. Also search for keywords in raw HTML
            keyword_patterns = [
                ("resortpro", "Streamline", "streamlinevrs.com"),
                ("homhero", "HomHero", "homhero.com.au"),
                ("cloudbeds", "Cloudbeds", "cloudbeds.com"),
                ("freetobook", "FreeToBook", "freetobook.com"),
                ("siteminder", "SiteMinder", "siteminder.com"),
                ("thebookingbutton", "SiteMinder", "thebookingbutton.com"),
                ("littlehotelier", "Little Hotelier", "littlehotelier.com"),
                ("webrezpro", "WebRezPro", "webrezpro.com"),
                ("resnexus", "ResNexus", "resnexus.com"),
                ("beds24", "Beds24", "beds24.com"),
                ("checkfront", "Checkfront", "checkfront.com"),
                ("eviivo", "eviivo", "eviivo.com"),
                ("lodgify", "Lodgify", "lodgify.com"),
                ("newbook", "Newbook", "newbook.cloud"),
                ("rmscloud", "RMS Cloud", "rmscloud.com"),
                ("ipms247", "JEHS / iPMS", "ipms247.com"),
                ("synxis", "SynXis / TravelClick", "synxis.com"),
                ("mews.com", "Mews", "mews.com"),
                ("triptease", "Triptease", "triptease.io"),
                ("bookingmood", "BookingMood", "bookingmood.com"),
                ("seekda", "Seekda / KUBE", "seekda.com"),
                ("kube", "Seekda / KUBE", "seekda.com"),
                ("ownerreservations", "OwnerReservations", "ownerreservations.com"),
                ("guestroomgenie", "GuestRoomGenie", "guestroomgenie.com"),
                ("beyondpricing", "Beyond Pricing", "beyondpricing.com"),
                ("hotelkeyapp", "HotelKey", "hotelkeyapp.com"),
                ("prenohq", "Preno", "prenohq.com"),
                # New engines from research
                ("profitroom", "Profitroom", "profitroom.com"),
                ("avvio", "Avvio", "avvio.com"),
                ("netaffinity", "Net Affinity", "netaffinity.com"),
                ("simplotel", "Simplotel", "simplotel.com"),
                ("cubilis", "Cubilis", "cubilis.com"),
                ("cendyn", "Cendyn", "cendyn.com"),
                ("booklogic", "BookLogic", "booklogic.net"),
                ("ratetiger", "RateTiger", "ratetiger.com"),
                ("d-edge", "D-Edge", "d-edge.com"),
                ("availpro", "D-Edge", "availpro.com"),
                ("bookassist", "BookAssist", "bookassist.com"),
                ("guestcentric", "GuestCentric", "guestcentric.com"),
                ("verticalbooking", "Vertical Booking", "verticalbooking.com"),
                ("busyrooms", "Busy Rooms", "busyrooms.com"),
                ("myhotel.io", "myHotel.io", "myhotel.io"),
                ("hotelspider", "HotelSpider", "hotelspider.com"),
                ("staah", "Staah", "staah.com"),
                ("axisrooms", "AxisRooms", "axisrooms.com"),
                ("e4jconnect", "E4jConnect", "e4jconnect.com"),
                ("vikbooking", "VikBooking", "vikbooking.com"),
                ("apaleo", "Apaleo", "apaleo.com"),
                ("clock-software", "Clock PMS", "clock-software.com"),
                ("clock-pms", "Clock PMS", "clock-pms.com"),
                ("protel", "Protel", "protel.net"),
                ("frontdeskanywhere", "Frontdesk Anywhere", "frontdeskanywhere.com"),
                ("hoteltime", "HotelTime", "hoteltime.com"),
                ("stayntouch", "StayNTouch", "stayntouch.com"),
                ("roomcloud", "RoomCloud", "roomcloud.net"),
                ("oaky", "Oaky", "oaky.com"),
                ("revinate", "Revinate", "revinate.com"),
                ("escapia", "Escapia", "escapia.com"),
                ("liverez", "LiveRez", "liverez.com"),
                ("barefoot", "Barefoot", "barefoot.com"),
                ("trackhs", "Track", "trackhs.com"),
                ("igms", "iGMS", "igms.com"),
                ("smoobu", "Smoobu", "smoobu.com"),
                ("tokeet", "Tokeet", "tokeet.com"),
                ("365villas", "365Villas", "365villas.com"),
                ("rentalsunited", "Rentals United", "rentalsunited.com"),
                ("bookingsync", "BookingSync", "bookingsync.com"),
                ("janiis", "JANIIS", "janiis.com"),
                ("quibblerm", "Quibble", "quibblerm.com"),
                ("hirum", "HiRUM", "hirum.com.au"),
                ("ibooked", "iBooked", "ibooked.net.au"),
                ("seekom", "Seekom", "seekom.com"),
                ("respax", "ResPax", "respax.com"),
                ("bookingcenter", "BookingCenter", "bookingcenter.com"),
                ("rezexpert", "RezExpert", "rezexpert.com"),
                ("supercontrol", "SuperControl", "supercontrol.co.uk"),
                ("anytimebooking", "Anytime Booking", "anytimebooking.eu"),
                ("elinapms", "Elina PMS", "elinapms.com"),
                ("guestline", "Guestline", "guestline.com"),
                ("nonius", "Nonius", "nonius.com"),
                ("visualmatrix", "Visual Matrix", "visualmatrix.com"),
                ("autoclerk", "AutoClerk", "autoclerk.com"),
                ("msisolutions", "MSI", "msisolutions.com"),
                ("skytouch", "SkyTouch", "skytouch.com"),
                ("roomkeypms", "RoomKeyPMS", "roomkeypms.com"),
            ]
            
            for keyword, engine_name, domain in keyword_patterns:
                # Look for keyword as part of a domain/URL pattern to avoid false positives
                # e.g., "ezee" alone might match "freeze", but "ezee.com" or "ezee/" is more reliable
                import re
                # Pattern: keyword followed by domain suffix (.com, .io, .net, etc.) or URL path (/)
                pattern = rf'{re.escape(keyword)}[\./\-]'
                if re.search(pattern, html_lower):
                    log(f"    [HTML SCAN] Found keyword '{keyword}' -> {engine_name}")
                    return (engine_name, domain)
            
            return ("", "")
            
        except Exception as e:
            log(f"    [HTML SCAN] Error: {e}")
            return ("", "")
    
    def _detect_engine_from_html_content(self, html: str) -> str:
        """Check HTML for booking engine keywords."""
        if not html:
            return ""
        
        low = html.lower()
        
        keywords = [
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
            ("ezeeabsolute", "eZee"),
            ("ezeereservation", "eZee"),
            ("ezeetechnosys", "eZee"),
            ("rmscloud", "RMS Cloud"),
            ("reztrip", "RezTrip"),
            ("freetobook", "FreeToBook"),
            ("checkfront", "Checkfront"),
            ("beds24", "Beds24"),
            ("sirvoy", "Sirvoy"),
            ("amenitiz", "Amenitiz"),
            ("hostaway", "Hostaway"),
            ("guesty", "Guesty"),
            ("lodgify", "Lodgify"),
            ("eviivo", "eviivo"),
            ("bookingmood", "BookingMood"),
            ("seekda", "Seekda / KUBE"),
            ("kube", "Seekda / KUBE"),
            ("ownerreservations", "OwnerReservations"),
            ("guestroomgenie", "GuestRoomGenie"),
            ("beyondpricing", "Beyond Pricing"),
            ("hotelkeyapp", "HotelKey"),
            ("prenohq", "Preno"),
            # New engines
            ("profitroom", "Profitroom"),
            ("avvio", "Avvio"),
            ("netaffinity", "Net Affinity"),
            ("simplotel", "Simplotel"),
            ("cubilis", "Cubilis"),
            ("cendyn", "Cendyn"),
            ("booklogic", "BookLogic"),
            ("ratetiger", "RateTiger"),
            ("d-edge", "D-Edge"),
            ("availpro", "D-Edge"),
            ("bookassist", "BookAssist"),
            ("guestcentric", "GuestCentric"),
            ("verticalbooking", "Vertical Booking"),
            ("busyrooms", "Busy Rooms"),
            ("hotelspider", "HotelSpider"),
            ("staah", "Staah"),
            ("axisrooms", "AxisRooms"),
            ("apaleo", "Apaleo"),
            ("clock-software", "Clock PMS"),
            ("protel", "Protel"),
            ("frontdeskanywhere", "Frontdesk Anywhere"),
            ("stayntouch", "StayNTouch"),
            ("escapia", "Escapia"),
            ("liverez", "LiveRez"),
            ("barefoot", "Barefoot"),
            ("trackhs", "Track"),
            ("igms", "iGMS"),
            ("smoobu", "Smoobu"),
            ("tokeet", "Tokeet"),
            ("hirum", "HiRUM"),
            ("seekom", "Seekom"),
            ("respax", "ResPax"),
            ("supercontrol", "SuperControl"),
            ("guestline", "Guestline"),
            ("visualmatrix", "Visual Matrix"),
            ("skytouch", "SkyTouch"),
            ("roomkeypms", "RoomKeyPMS"),
        ]
        
        for keyword, engine in keywords:
            if keyword in low:
                return engine
        
        return ""
    
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
        
        # Load hotels
        hotels = self._load_hotels(input_csv)
        log(f"Loaded {len(hotels)} hotels from {input_csv}")
        
        # Resume support - get existing successful results to preserve
        hotels, existing_results = self._filter_processed(hotels)
        
        if not hotels:
            log("All hotels already processed. Nothing to do.")
            return
        
        log(f"{len(hotels)} hotels remaining to process")
        
        # Process hotels
        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=self.config.headless)
            semaphore = asyncio.Semaphore(self.config.concurrency)

            # Create reusable context queue (one per concurrent worker)
            log(f"Creating {self.config.concurrency} reusable browser contexts...")
            context_queue = asyncio.Queue()
            contexts = []
            for _ in range(self.config.concurrency):
                ctx = await browser.new_context(
                    user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
                    ignore_https_errors=True,
                )
                contexts.append(ctx)
                await context_queue.put(ctx)

            processor = HotelProcessor(self.config, browser, semaphore, context_queue)

            tasks = [
                processor.process(idx, len(hotels), hotel)
                for idx, hotel in enumerate(hotels, 1)
            ]

            # Write results (merging with existing successful results)
            await self._write_results(tasks, existing_results)

            # Clean up contexts
            for ctx in contexts:
                await ctx.close()
            await browser.close()
    
    def _load_hotels(self, input_csv: str) -> list[dict]:
        """Load hotels from CSV, filtering out big chains and junk sites."""
        hotels = []
        skipped_chains = 0
        skipped_junk = 0
        with open(input_csv, newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                website = row.get("website", "").lower()
                # Skip big hotel chains - they have their own booking systems
                if any(chain in website for chain in SKIP_CHAIN_DOMAINS):
                    skipped_chains += 1
                    continue
                # Skip social media and junk domains
                if any(junk in website for junk in SKIP_JUNK_DOMAINS):
                    skipped_junk += 1
                    continue
                hotels.append(row)
        if skipped_chains:
            log(f"Skipped {skipped_chains} big chain hotels (Marriott, Hilton, etc.)")
        if skipped_junk:
            log(f"Skipped {skipped_junk} junk URLs (Facebook, gov sites, etc.)")
        return hotels
    
    def _filter_processed(self, hotels: list[dict]) -> tuple[list[dict], dict]:
        """Filter out already-processed hotels. Returns (remaining, existing_results).
        
        Hotels with errors OR no engine detected are NOT filtered out - they can be retried.
        existing_results is a dict of {(name, website): row_dict} for successful results only.
        """
        if not os.path.exists(self.config.output_csv):
            return hotels, {}
        
        # Engines that count as "no engine detected" - these should be retried
        no_engine_values = {"", "unknown", "unknown_third_party", "proprietary_or_same_domain", "unknown_booking_api"}
        
        # Read existing results, separating successful from failed
        existing_results = {}  # Will contain successful results to preserve
        error_count = 0
        no_engine_count = 0
        
        with open(self.config.output_csv, newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                row_name = row.get("name") or row.get("hotel", "")
                key = (row_name, normalize_url(row.get("website", "")))
                
                # Check if this row had an error
                error = (row.get("error") or "").strip()
                engine = (row.get("booking_engine") or "").strip()
                
                if error:
                    error_count += 1
                    # Don't keep error rows - they'll be retried
                elif engine in no_engine_values:
                    no_engine_count += 1
                    # Don't keep no-engine rows - they'll be retried
                else:
                    existing_results[key] = row
        
        if not existing_results and error_count == 0 and no_engine_count == 0:
            return hotels, {}
        
        log(f"Found {len(existing_results)} successful, {error_count} with errors, {no_engine_count} with no engine (will retry)")
        
        # Only skip successfully processed hotels - errors can be retried
        remaining = [
            h for h in hotels
            if ((h.get("name") or h.get("hotel", "")), normalize_url(h.get("website", ""))) not in existing_results
        ]
        return remaining, existing_results
    
    async def _write_results(self, tasks: list, existing_results: dict):
        """Write results to CSV incrementally as they complete."""
        fieldnames = list(HotelResult.__dataclass_fields__.keys())
        
        # Create output directory if needed
        output_dir = os.path.dirname(self.config.output_csv)
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)
        
        stats = {"processed": 0, "known_engine": 0, "booking_url_found": 0, "errors": 0, "skipped_no_result": 0, "saved": 0}
        all_results = dict(existing_results)  # Start with existing successful results
        
        # Track when to save (every N hotels or on important results)
        save_interval = 5
        last_save_count = 0
        
        for coro in asyncio.as_completed(tasks):
            result = await coro
            stats["processed"] += 1
            
            if result.error:
                stats["errors"] += 1
            
            if result.booking_engine and result.booking_engine not in ("", "unknown", "unknown_third_party", "proprietary_or_same_domain"):
                stats["known_engine"] += 1
            
            # Count as hit if we found a booking URL (regardless of engine recognition)
            has_booking_url = result.booking_url and result.booking_url.strip()
            if has_booking_url:
                stats["booking_url_found"] += 1
            
            # Only save if we found a booking URL or a known engine
            has_known_engine = result.booking_engine and result.booking_engine not in ("", "unknown", "unknown_third_party", "proprietary_or_same_domain")
            
            # Also save errors so we can track/retry them
            has_error = bool(result.error)
            
            if has_booking_url or has_known_engine or has_error:
                key = (result.name, normalize_url(result.website))
                all_results[key] = asdict(result)
                stats["saved"] += 1
            else:
                stats["skipped_no_result"] += 1
                log(f"  Skipped {result.name}: no booking URL or known engine found")
            
            # INCREMENTAL SAVE: Write to disk every N hotels to avoid losing progress
            if stats["processed"] - last_save_count >= save_interval:
                self._save_to_csv(all_results, fieldnames)
                last_save_count = stats["processed"]
                log(f"  [CHECKPOINT] Saved {len(all_results)} results to {self.config.output_csv}")
        
        # Final save
        self._save_to_csv(all_results, fieldnames)
        
        self._print_summary(stats)
    
    def _save_to_csv(self, results: dict, fieldnames: list):
        """Write all results to CSV file."""
        with open(self.config.output_csv, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            for row in results.values():
                # Filter out any extra fields not in fieldnames (e.g., old screenshot_path)
                filtered_row = {k: v for k, v in row.items() if k in fieldnames}
                writer.writerow(filtered_row)
    
    def _print_summary(self, stats: dict):
        """Print final summary with hit rate."""
        total = stats['processed']
        known = stats['known_engine']
        booking_urls_found = stats['booking_url_found']
        
        # Hit rate = percentage of hotels where we found a booking URL
        hit_rate = (booking_urls_found / total * 100) if total > 0 else 0
        
        logger.info("")
        logger.info("=" * 60)
        logger.info("DETECTION COMPLETE!")
        logger.info("=" * 60)
        logger.info(f"Hotels processed:    {total}")
        logger.info(f"Saved to output:      {stats.get('saved', 0)}")
        logger.info(f"Booking URLs found:   {booking_urls_found}")
        logger.info(f"Known engines:        {known}")
        logger.info(f"Skipped (no result):  {stats.get('skipped_no_result', 0)}")
        logger.info(f"Errors:               {stats['errors']}")
        logger.info("-" * 60)
        logger.info(f"HIT RATE:             {hit_rate:.1f}%")
        logger.info("=" * 60)
        logger.info(f"Output: {self.config.output_csv}")


# ============================================================================
# CLI
# ============================================================================

async def main_async(args):
    config = Config(
        output_csv=args.output,
        concurrency=args.concurrency,
        pause_between_hotels=args.pause,
        headless=not args.headed,
    )
    
    pipeline = DetectorPipeline(config)
    await pipeline.run(args.input)


def main():
    parser = argparse.ArgumentParser(description="Sadie Detector - Booking Engine Detection")
    parser.add_argument("--input", required=True, help="Input CSV with hotels")
    parser.add_argument("--output", default="sadie_leads.csv", help="Output CSV file")
    parser.add_argument("--concurrency", type=int, default=5)
    parser.add_argument("--headed", action="store_true")
    parser.add_argument("--pause", type=float, default=0.5)
    parser.add_argument("--debug", action="store_true", help="Run browser in headed mode + verbose logging")
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input):
        raise SystemExit(f"Input file not found: {args.input}")
    
    # --debug implies headed mode
    if args.debug:
        args.headed = True
    
    setup_logging(args.debug)
    
    asyncio.run(main_async(args))


if __name__ == "__main__":
    main()
