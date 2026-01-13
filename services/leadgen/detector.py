"""Booking engine detector for hotel websites.

Visits hotel websites using Playwright to detect their booking engine
by analyzing URLs, network requests, and page content.
"""

import re
import asyncio
from dataclasses import dataclass, field
from typing import Optional, List, Dict, Tuple
from urllib.parse import urlparse, urljoin

from loguru import logger
from playwright.async_api import async_playwright, Page, BrowserContext
from playwright.async_api import TimeoutError as PWTimeoutError
import httpx


# Booking engine URL patterns - maps engine name to list of domain patterns
ENGINE_PATTERNS = {
    "Cloudbeds": ["cloudbeds.com"],
    "Mews": ["mews.com", "mews.li", "distributor.mews.com"],
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
    "JEHS / iPMS": ["ipms247.com", "live.ipms247.com"],
    "Windsurfer CRS": ["windsurfercrs.com", "res.windsurfercrs.com"],
    "ThinkReservations": ["thinkreservations.com", "secure.thinkreservations.com"],
    "ASI Web Reservations": ["asiwebres.com", "reservation.asiwebres.com"],
    "IQWebBook": ["iqwebbook.com", "us01.iqwebbook.com"],
    "BookDirect": ["bookdirect.net"],
    "RezStream": ["rezstream.com", "guest.rezstream.com"],
    "Reseze": ["reseze.net"],
    "WebRez": ["webrez.com", "secure.webrez.com"],
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
    "HomHero": ["homhero.com.au", "api.homhero.com.au"],
    "Streamline": ["streamlinevrs.com", "resortpro"],
    "Triptease": ["triptease.io", "triptease.com"],
    "Pegasus": ["pegasus.io", "pegs.io"],
    "OwnerReservations": ["ownerreservations.com", "secure.ownerreservations.com"],
    "GuestRoomGenie": ["guestroomgenie.com", "secure.guestroomgenie.com"],
    "Beyond Pricing": ["beyondpricing.com"],
    "HotelKey": ["hotelkeyapp.com", "booking.hotelkeyapp.com"],
    "Preno": ["prenohq.com", "bookdirect.prenohq.com"],
    "BookingMood": ["bookingmood.com", "widget.bookingmood.com"],
    "Seekda / KUBE": ["seekda.com", "kube.seekda.com", "booking.seekda.com"],
    "StayDirectly": ["staydirectly.com"],
    "Rentrax": ["rentrax.io"],
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
    "Apaleo": ["apaleo.com", "app.apaleo.com"],
    "Clock PMS": ["clock-software.com", "booking.clock-pms.com"],
    "Protel": ["protel.net", "onity.com"],
    "Frontdesk Anywhere": ["frontdeskanywhere.com"],
    "HotelTime": ["hoteltime.com"],
    "StayNTouch": ["stayntouch.com", "rover.stayntouch.com"],
    "RoomCloud": ["roomcloud.net"],
    "Escapia": ["escapia.com", "homeaway.escapia.com"],
    "LiveRez": ["liverez.com", "secure.liverez.com"],
    "Barefoot": ["barefoot.com", "barefoot.systems"],
    "Track": ["trackhs.com", "reserve.trackhs.com"],
    "iGMS": ["igms.com"],
    "Smoobu": ["smoobu.com", "login.smoobu.com"],
    "Tokeet": ["tokeet.com"],
    "365Villas": ["365villas.com"],
    "Rentals United": ["rentalsunited.com"],
    "BookingSync": ["bookingsync.com"],
    "JANIIS": ["janiis.com", "secure.janiis.com"],
    "HiRUM": ["hirum.com.au", "book.hirum.com.au"],
    "iBooked": ["ibooked.net.au", "secure.ibooked.net.au"],
    "Seekom": ["seekom.com", "book.seekom.com"],
    "ResPax": ["respax.com", "app.respax.com"],
    "BookingCenter": ["bookingcenter.com"],
    "SuperControl": ["supercontrol.co.uk", "members.supercontrol.co.uk"],
    "Anytime Booking": ["anytimebooking.eu", "anytimebooking.co.uk"],
    "Elina PMS": ["elinapms.com"],
    "Guestline": ["guestline.com", "booking.guestline.com"],
    "Visual Matrix": ["visualmatrix.com", "pms.visualmatrix.com"],
    "AutoClerk": ["autoclerk.com"],
    "SkyTouch": ["skytouch.com", "pms.skytouch.com"],
    "RoomKeyPMS": ["roomkeypms.com", "secure.roomkeypms.com"],
}

# Keywords to identify booking buttons
BOOKING_BUTTON_KEYWORDS = [
    "book now", "book", "reserve", "reserve now",
    "reservation", "reservations", "check availability",
    "check rates", "availability", "book online", "book a room",
]

# Big chains to skip
SKIP_CHAIN_DOMAINS = [
    "marriott.com", "hilton.com", "ihg.com", "hyatt.com", "wyndham.com",
    "choicehotels.com", "bestwestern.com", "radissonhotels.com", "accor.com",
]

# Junk domains to skip
SKIP_JUNK_DOMAINS = [
    "facebook.com", "instagram.com", "twitter.com", "youtube.com", "tiktok.com",
    "linkedin.com", "yelp.com", "tripadvisor.com", "google.com",
    "booking.com", "expedia.com", "hotels.com", "airbnb.com", "vrbo.com",
    ".gov", ".edu", ".mil",
]


@dataclass
class DetectionConfig:
    """Configuration for the detector."""
    timeout_page_load: int = 30000
    timeout_booking_click: int = 3000
    timeout_popup_detect: int = 1500
    concurrency: int = 5
    headless: bool = True


@dataclass
class DetectionResult:
    """Result of booking engine detection for a hotel."""
    hotel_id: int
    booking_engine: str = ""
    booking_engine_domain: str = ""
    booking_url: str = ""
    detection_method: str = ""
    phone_website: str = ""
    email: str = ""
    error: str = ""


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


class EngineDetector:
    """Detects booking engines from URLs and network requests."""

    @staticmethod
    def from_domain(domain: str) -> Tuple[str, str]:
        """Check if domain matches a known booking engine."""
        if not domain:
            return ("", "")
        for engine_name, patterns in ENGINE_PATTERNS.items():
            for pat in patterns:
                if pat in domain:
                    return (engine_name, pat)
        return ("", "")

    @staticmethod
    def from_url(url: str, hotel_domain: str) -> Tuple[str, str, str]:
        """Detect engine from URL. Returns (engine_name, domain, method)."""
        if not url:
            return ("", "", "no_url")

        url_lower = url.lower()
        for engine_name, patterns in ENGINE_PATTERNS.items():
            for pat in patterns:
                if pat in url_lower:
                    return (engine_name, pat, "url_pattern_match")

        domain = extract_domain(url)
        if not domain:
            return ("", "", "no_domain")

        engine_name, pat = EngineDetector.from_domain(domain)
        if engine_name:
            return (engine_name, domain, "url_domain_match")

        if hotel_domain and domain != hotel_domain:
            return ("unknown_third_party", domain, "third_party_domain")

        return ("", domain, "same_domain")

    @staticmethod
    def from_network(
        network_urls: Dict[str, str], hotel_domain: str
    ) -> Tuple[str, str, str, str]:
        """Check network requests for engine domains."""
        skip_hosts = [
            'google', 'facebook', 'analytics', 'cdn', 'cloudflare', 'jquery',
            'doubleclick', 'adsrvr', 'criteo', 'hotjar', 'sentry', 'newrelic',
        ]

        for host, full_url in network_urls.items():
            engine_name, pat = EngineDetector.from_domain(host)
            if engine_name:
                return (engine_name, host, "network_sniff", full_url)

        booking_keywords = ['book', 'reserv', 'avail', 'pricing', 'checkout']
        for host, full_url in network_urls.items():
            if host == hotel_domain:
                continue
            if any(skip in host for skip in skip_hosts):
                continue
            url_lower = full_url.lower()
            for keyword in booking_keywords:
                if keyword in url_lower:
                    return ("unknown_booking_api", host, "network_sniff_keyword", full_url)

        return ("", "", "", "")


class ContactExtractor:
    """Extracts phone numbers and emails from HTML."""

    PHONE_PATTERNS = [
        r'\+?1?[-.\s]?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}',
        r'\+\d{1,3}[-.\s]?\d{1,4}[-.\s]?\d{1,4}[-.\s]?\d{1,9}',
    ]
    EMAIL_PATTERN = r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
    SKIP_EMAIL_PATTERNS = [
        'example.com', 'domain.com', 'sentry.io', 'wixpress.com', 'schema.org'
    ]

    @classmethod
    def extract_phones(cls, html: str) -> List[str]:
        """Extract phone numbers from HTML."""
        phones = []
        for pattern in cls.PHONE_PATTERNS:
            phones.extend(re.findall(pattern, html))
        seen = set()
        cleaned = []
        for p in phones:
            p = re.sub(r'[^\d+]', '', p)
            if len(p) >= 10 and p not in seen:
                seen.add(p)
                cleaned.append(p)
        return cleaned[:3]

    @classmethod
    def extract_emails(cls, html: str) -> List[str]:
        """Extract email addresses from HTML."""
        matches = re.findall(cls.EMAIL_PATTERN, html)
        filtered = []
        for email in matches:
            email_lower = email.lower()
            if not any(skip in email_lower for skip in cls.SKIP_EMAIL_PATTERNS):
                if email_lower not in [e.lower() for e in filtered]:
                    filtered.append(email)
        return filtered[:3]


class HotelDetector:
    """Detects booking engine for a single hotel."""

    def __init__(self, config: DetectionConfig):
        self.config = config

    async def detect(
        self,
        hotel_id: int,
        name: str,
        website: str,
    ) -> DetectionResult:
        """Detect booking engine for a hotel."""
        result = DetectionResult(hotel_id=hotel_id)
        website = normalize_url(website)

        if not website:
            return result

        # Skip junk domains
        website_lower = website.lower()
        if any(junk in website_lower for junk in SKIP_JUNK_DOMAINS):
            result.error = "junk_domain"
            return result

        # HTTP pre-check
        is_reachable, precheck_error = await self._http_precheck(website)
        if not is_reachable:
            result.error = f"precheck_failed: {precheck_error}"
            return result

        # Visit website with Playwright
        try:
            async with async_playwright() as p:
                browser = await p.chromium.launch(headless=self.config.headless)
                context = await browser.new_context(
                    user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
                    ignore_https_errors=True,
                )
                try:
                    result = await self._process_website(context, website, result)
                finally:
                    await context.close()
                    await browser.close()
        except Exception as e:
            result.error = f"browser_error: {str(e)[:100]}"

        return result

    async def _http_precheck(self, url: str, timeout: float = 5.0) -> Tuple[bool, str]:
        """Quick HTTP check before launching Playwright."""
        try:
            async with httpx.AsyncClient(
                timeout=timeout, follow_redirects=True, verify=False
            ) as client:
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

    async def _process_website(
        self, context: BrowserContext, website: str, result: DetectionResult
    ) -> DetectionResult:
        """Visit website and detect booking engine."""
        page = await context.new_page()
        network_urls: Dict[str, str] = {}

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
            try:
                await page.goto(
                    website, timeout=self.config.timeout_page_load, wait_until="domcontentloaded"
                )
            except PWTimeoutError:
                try:
                    await page.goto(website, timeout=15000, wait_until="commit")
                except Exception:
                    pass

            await asyncio.sleep(1.5)
            hotel_domain = extract_domain(page.url)

            # Extract contacts
            result = await self._extract_contacts(page, result)

            # Scan HTML for engines
            engine_name, engine_domain = await self._scan_html_for_engines(page)
            if engine_name:
                result.booking_engine = engine_name
                result.booking_engine_domain = engine_domain
                result.detection_method = "html_scan"

            # Find booking button and URL
            if not result.booking_engine or result.booking_engine in ("unknown", "unknown_third_party"):
                booking_url, method = await self._find_booking_url(context, page, hotel_domain)
                if booking_url:
                    result.booking_url = booking_url
                    # Detect engine from booking URL
                    url_engine, url_domain, url_method = EngineDetector.from_url(booking_url, hotel_domain)
                    if url_engine and url_engine not in ("unknown_third_party", ""):
                        result.booking_engine = url_engine
                        result.booking_engine_domain = url_domain
                        result.detection_method = f"{method}+{url_method}"
                    else:
                        result.detection_method = method

            # Check network requests
            if not result.booking_engine or result.booking_engine in ("unknown", "unknown_third_party"):
                net_engine, net_domain, _, net_url = EngineDetector.from_network(network_urls, hotel_domain)
                if net_engine and net_engine not in ("unknown_third_party",):
                    result.booking_engine = net_engine
                    result.booking_engine_domain = net_domain
                    result.detection_method = (result.detection_method or "") + "+network_sniff"
                    if net_url and not result.booking_url:
                        result.booking_url = net_url

            # Scan iframes
            if not result.booking_engine or result.booking_engine in ("unknown", "unknown_third_party"):
                frame_engine, frame_domain, frame_url = await self._scan_frames(page)
                if frame_engine:
                    result.booking_engine = frame_engine
                    result.booking_engine_domain = frame_domain
                    result.detection_method = (result.detection_method or "") + "+iframe_scan"
                    if frame_url and not result.booking_url:
                        result.booking_url = frame_url

            if not result.booking_url and not result.booking_engine:
                result.error = "no_booking_found"

        except PWTimeoutError:
            result.error = "timeout"
        except Exception as e:
            result.error = f"exception: {str(e)[:100]}"
        finally:
            await page.close()

        return result

    async def _extract_contacts(self, page: Page, result: DetectionResult) -> DetectionResult:
        """Extract phone and email from page."""
        try:
            text = await page.evaluate("document.body ? document.body.innerText : ''")
            phones = ContactExtractor.extract_phones(text)
            emails = ContactExtractor.extract_emails(text)

            if phones:
                result.phone_website = phones[0]
            if emails:
                result.email = emails[0]

            # Check tel: and mailto: links
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

    async def _scan_html_for_engines(self, page: Page) -> Tuple[str, str]:
        """Scan page HTML for booking engine patterns."""
        try:
            html = await page.evaluate("document.documentElement.outerHTML")
            html_lower = html.lower()

            # Extract URLs from HTML
            url_pattern = r'(?:src|href|data-src|action)=["\']?(https?://[^"\'\s>]+)'
            found_urls = re.findall(url_pattern, html, re.IGNORECASE)

            domains_found = set()
            for url in found_urls:
                domain = extract_domain(url)
                if domain:
                    domains_found.add(domain.lower())

            for domain in domains_found:
                for engine_name, patterns in ENGINE_PATTERNS.items():
                    for pat in patterns:
                        if pat.lower() in domain:
                            return (engine_name, pat)

            # Check for keywords in HTML
            keyword_patterns = [
                ("cloudbeds", "Cloudbeds", "cloudbeds.com"),
                ("synxis", "SynXis / TravelClick", "synxis.com"),
                ("mews.com", "Mews", "mews.com"),
                ("littlehotelier", "Little Hotelier", "littlehotelier.com"),
                ("siteminder", "SiteMinder", "siteminder.com"),
                ("thebookingbutton", "SiteMinder", "thebookingbutton.com"),
                ("webrezpro", "WebRezPro", "webrezpro.com"),
                ("resnexus", "ResNexus", "resnexus.com"),
                ("freetobook", "FreeToBook", "freetobook.com"),
                ("beds24", "Beds24", "beds24.com"),
                ("checkfront", "Checkfront", "checkfront.com"),
                ("lodgify", "Lodgify", "lodgify.com"),
                ("eviivo", "eviivo", "eviivo.com"),
                ("ipms247", "JEHS / iPMS", "ipms247.com"),
                ("bookingmood", "BookingMood", "bookingmood.com"),
                ("seekda", "Seekda / KUBE", "seekda.com"),
            ]

            for keyword, engine_name, domain in keyword_patterns:
                pattern = rf'{re.escape(keyword)}[\./\-]'
                if re.search(pattern, html_lower):
                    return (engine_name, domain)

            return ("", "")

        except Exception:
            return ("", "")

    async def _find_booking_url(
        self, context: BrowserContext, page: Page, hotel_domain: str
    ) -> Tuple[str, str]:
        """Find booking button and get the booking URL."""
        try:
            # Dismiss popups first
            await self._dismiss_popups(page)

            # Find booking button candidates using JavaScript
            candidates = await page.evaluate("""() => {
                const bookingTerms = ['book', 'reserve', 'availability', 'check rates'];
                const excludeTerms = ['facebook', 'twitter', 'instagram', 'terms', 'policy', 'privacy'];
                const results = [];

                const elements = document.querySelectorAll('a, button, [role="button"]');
                for (const el of elements) {
                    const text = (el.innerText || el.textContent || '').toLowerCase().trim();
                    const href = el.href || el.getAttribute('href') || '';

                    if (excludeTerms.some(t => text.includes(t) || href.toLowerCase().includes(t))) continue;
                    if (!bookingTerms.some(t => text.includes(t))) continue;

                    const rect = el.getBoundingClientRect();
                    if (rect.width === 0 || rect.height === 0) continue;
                    if (rect.width > 600 || rect.height > 150) continue;

                    results.push({
                        text: text.substring(0, 40),
                        href: href,
                        tag: el.tagName.toLowerCase()
                    });

                    if (results.length >= 5) break;
                }
                return results;
            }""")

            for candidate in candidates:
                href = candidate.get('href', '')
                if href and href.startswith('http') and not href.startswith('#'):
                    return (href, "href_extraction")

            # Try clicking the first booking button
            if candidates:
                text = candidates[0].get('text', '')
                if text:
                    try:
                        btn = page.locator(f"text={text}").first
                        if await btn.count() > 0:
                            original_url = page.url

                            # Try for popup
                            try:
                                async with context.expect_page(timeout=2000) as p_info:
                                    await btn.click(force=True, no_wait_after=True)
                                new_page = await p_info.value
                                url = new_page.url
                                await new_page.close()
                                return (url, "popup_page")
                            except PWTimeoutError:
                                pass

                            await asyncio.sleep(1.0)
                            if page.url != original_url:
                                return (page.url, "navigation")
                    except Exception:
                        pass

            return ("", "no_booking_button")

        except Exception:
            return ("", "error")

    async def _dismiss_popups(self, page: Page) -> None:
        """Try to dismiss cookie consent and other popups."""
        dismiss_selectors = [
            "button:has-text('Accept')",
            "button:has-text('Accept All')",
            "button:has-text('I agree')",
            "button:has-text('OK')",
            "[class*='cookie'] button",
            "[class*='consent'] button",
        ]

        for selector in dismiss_selectors:
            try:
                btn = page.locator(selector).first
                if await btn.count() > 0 and await btn.is_visible():
                    await btn.click(timeout=1000)
                    await asyncio.sleep(0.3)
                    return
            except Exception:
                continue

    async def _scan_frames(self, page: Page) -> Tuple[str, str, str]:
        """Scan iframes for booking engine patterns."""
        for frame in page.frames:
            try:
                frame_url = frame.url
            except Exception:
                continue

            if not frame_url or frame_url.startswith("about:"):
                continue

            for engine_name, patterns in ENGINE_PATTERNS.items():
                for pat in patterns:
                    if pat in frame_url.lower():
                        return (engine_name, pat, frame_url)

        return ("", "", "")


class BatchDetector:
    """Runs detection on multiple hotels concurrently."""

    def __init__(self, config: Optional[DetectionConfig] = None):
        self.config = config or DetectionConfig()

    async def detect_batch(
        self,
        hotels: List[Dict],
    ) -> List[DetectionResult]:
        """Detect booking engines for a batch of hotels.

        Args:
            hotels: List of dicts with 'id', 'name', 'website' keys

        Returns:
            List of DetectionResult objects
        """
        semaphore = asyncio.Semaphore(self.config.concurrency)

        async def detect_with_semaphore(hotel: Dict) -> DetectionResult:
            async with semaphore:
                detector = HotelDetector(self.config)
                return await detector.detect(
                    hotel_id=hotel['id'],
                    name=hotel['name'],
                    website=hotel.get('website', ''),
                )

        tasks = [detect_with_semaphore(h) for h in hotels]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        # Convert exceptions to error results
        final_results = []
        for i, result in enumerate(results):
            if isinstance(result, Exception):
                final_results.append(DetectionResult(
                    hotel_id=hotels[i]['id'],
                    error=f"exception: {str(result)[:100]}"
                ))
            else:
                final_results.append(result)

        return final_results
