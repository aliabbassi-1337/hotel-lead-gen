#!/usr/bin/env python3
import csv
import argparse
import asyncio
import os
from datetime import datetime
from urllib.parse import urlparse

from playwright.async_api import async_playwright, TimeoutError as PWTimeoutError

INPUT_CSV = "hotels_filtered.csv"
OUTPUT_CSV = "hotels_booking_engines.csv"


# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

def log(msg: str) -> None:
    """Simple timestamped logger."""
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{ts}] {msg}")


def extract_domain(url: str) -> str:
    if not url:
        return ""
    try:
        parsed = urlparse(url)
        host = (parsed.netloc or "").lower()
        if host.startswith("www."):
            host = host[4:]
        return host
    except Exception:
        return ""


def normalize_url(url: str) -> str:
    url = (url or "").strip()
    if not url:
        return ""
    if not url.startswith("http://") and not url.startswith("https://"):
        url = "https://" + url
    return url


ENGINE_PATTERNS = {
    "Cloudbeds": ["cloudbeds.com"],
    "Mews": ["mews.com", "mews.li"],
    "SynXis / TravelClick": ["synxis.com", "travelclick.com"],
    "BookingSuite / Booking.com": ["bookingsuite.com", "booking.com"],
    "Little Hotelier": ["littlehotelier.com"],
    "WebRezPro": ["webrezpro.com"],
    "InnRoad": ["innroad.com"],
    "ResNexus": ["resnexus.com"],
    "Newbook": ["newbook.cloud", "newbooksoftware.com"],
    "RMS Cloud": ["rmscloud.com"],
    "RoomRaccoon": ["roomraccoon.com"],
    "SiteMinder / TheBookingButton": ["thebookingbutton.com", "siteminder.com"],
    "Sabre / CRS": ["sabre.com", "crs.sabre.com"],
    "eZee": ["ezeeabsolute.com", "ezeereservation.com", "ezeetechnosys.com"],
    # You can keep adding here as you discover more engines
}

# Flat list of all engine domains for network sniffing, reuse patterns above
ALL_ENGINE_DOMAINS = sorted({d for patterns in ENGINE_PATTERNS.values() for d in patterns})


def detect_engine_from_domain(domain: str):
    """
    Given a naked domain (no scheme/path), return (engine_name or '', matched_pattern or '').
    """
    if not domain:
        return ("", "")

    for engine_name, patterns in ENGINE_PATTERNS.items():
        for pat in patterns:
            if domain.endswith(pat):
                return (engine_name, pat)
    return ("", "")


def detect_engine_from_url(url: str, hotel_domain: str):
    """
    Try to detect engine from a full URL.
    """
    domain = extract_domain(url)
    if not domain:
        return ("unknown", "", "no_domain")

    engine_name, pat = detect_engine_from_domain(domain)
    if engine_name:
        return (engine_name, domain, "url_domain_match")

    if hotel_domain and domain != hotel_domain:
        # Different domain but not a known engine -> some unknown third-party
        return ("unknown_third_party", domain, "url_third_party_domain")

    return ("proprietary_or_same_domain", domain, "url_same_domain")


def detect_engine_from_html(html: str):
    """
    Keyword-based detection from HTML. This is a 'last mile' detector when domain isn't obvious.
    """
    if not html:
        return ("", "")

    low = html.lower()

    if "cloudbeds" in low:
        return ("Cloudbeds", "html_keyword")
    if "mews" in low:
        return ("Mews", "html_keyword")
    if "synxis" in low or "travelclick" in low:
        return ("SynXis / TravelClick", "html_keyword")
    if "littlehotelier" in low or "little hotelier" in low:
        return ("Little Hotelier", "html_keyword")
    if "webrezpro" in low:
        return ("WebRezPro", "html_keyword")
    if "innroad" in low:
        return ("InnRoad", "html_keyword")
    if "resnexus" in low:
        return ("ResNexus", "html_keyword")
    if "newbook" in low:
        return ("Newbook", "html_keyword")
    if "roomraccoon" in low:
        return ("RoomRaccoon", "html_keyword")
    if "siteminder" in low or "thebookingbutton" in low:
        return ("SiteMinder / TheBookingButton", "html_keyword")
    if "ezee" in low or "ezee reservation" in low:
        return ("eZee", "html_keyword")
    if "rmscloud" in low or "rms cloud" in low:
        return ("RMS Cloud", "html_keyword")
    if "booking.com" in low or "booking suite" in low:
        return ("BookingSuite / Booking.com", "html_keyword")

    return ("", "")


BOOKING_KEYWORDS = [
    "book now",
    "book",
    "reserve",
    "reserve now",
    "reservation",
    "reservations",
    "check availability",
    "check rates",
    "check rate",
    "availability",
    "online booking",
    "book online",
]


async def find_booking_element_candidates(page, max_candidates: int = 5):
    """
    Return up to `max_candidates` <a> or <button> elements that look like booking CTAs.
    We collect multiple so we can try more than 1 if the first one sucks.
    """
    candidates = []
    loc = page.locator("a, button")
    count = await loc.count()
    for i in range(count):
        el = loc.nth(i)
        try:
            text = (await el.inner_text() or "").strip()
        except Exception:
            continue
        if not text:
            continue
        lower = text.lower()
        for kw in BOOKING_KEYWORDS:
            if kw in lower:
                candidates.append(el)
                break
        if len(candidates) >= max_candidates:
            break
    return candidates


async def click_and_get_booking_page(context, page, hotel_url: str, timeout_ms: int = 15000):
    """
    Try multiple candidate booking elements. Returns:
        (booking_page, booking_url, method)
    method = one of:
      - 'no_booking_button_found'
      - 'popup_page'
      - 'same_page_or_widget'
      - 'attempted_multiple_buttons'
      - 'no_booking_button_effective'
    """
    candidates = await find_booking_element_candidates(page)
    if not candidates:
        return (None, None, "no_booking_button_found")

    # If any click opens a new page or changes URL significantly, we take that.
    original_url = page.url
    last_booking_url = None
    last_booking_page = None
    last_method = "attempted_multiple_buttons"

    for idx, el in enumerate(candidates):
        # Try popup / new tab
        try:
            async with context.expect_page(timeout=5000) as p_info:
                await el.click()
            new_page = await p_info.value
            try:
                await new_page.wait_for_load_state("networkidle", timeout=timeout_ms)
            except PWTimeoutError:
                pass
            return (new_page, new_page.url, "popup_page")
        except PWTimeoutError:
            # Maybe same tab or widget
            try:
                await el.click()
            except Exception:
                continue
            try:
                await page.wait_for_load_state("networkidle", timeout=timeout_ms)
            except PWTimeoutError:
                pass

            if page.url != original_url:
                last_booking_page = page
                last_booking_url = page.url
                last_method = "same_page_or_widget"

    if last_booking_url:
        return (last_booking_page, last_booking_url, last_method)

    return (None, None, "no_booking_button_effective")


async def sniff_network_for_engine(network_hosts, hotel_domain: str):
    """
    Given a set of all domains hit during browsing, try to infer a booking engine.
    Returns (engine_name, engine_domain, method) or ('', '', '').
    """
    # Prioritize known engine domains
    for host in network_hosts:
        engine_name, pat = detect_engine_from_domain(host)
        if engine_name:
            return (engine_name, host, "network_domain_match")

    # If nothing matches a known engine but we see third-party domains different from hotel
    # we can still flag them as unknown_third_party
    unknown_third_party = [
        h for h in network_hosts
        if hotel_domain and h != hotel_domain
    ]
    if unknown_third_party:
        # Just take the first one for reporting
        return ("unknown_third_party", unknown_third_party[0], "network_third_party_domain")

    return ("", "", "")


async def detect_engine_fallback_from_frames(page):
    """
    Some booking engines load inside iframes / frames.
    We scan frame URLs + frame HTML for engine patterns.
    """
    for frame in page.frames:
        try:
            frame_url = frame.url
        except Exception:
            continue
        domain = extract_domain(frame_url)
        engine_name, pat = detect_engine_from_domain(domain)
        if engine_name:
            return engine_name, domain, "frame_url_domain_match"

        # Try HTML if domain didn't give us anything
        try:
            html = await frame.content()
        except Exception:
            html = ""
        html_engine, html_method = detect_engine_from_html(html)
        if html_engine:
            return html_engine, domain or "", f"frame_{html_method}"

    return "", "", ""


# ------------------------------------------------------------
# Per-hotel worker
# ------------------------------------------------------------

async def process_single_hotel(idx, total, row, browser, semaphore, pause_sec):
    name = (row.get("name") or "").strip()
    website_raw = (row.get("website") or "").strip()
    website = normalize_url(website_raw)

    log(f"[{idx}/{total}] {name} | {website}")

    result = {
        "name": name,
        "website": website,
        "booking_url": "",
        "booking_engine": "",
        "booking_engine_domain": "",
        "detection_method": "",
        "error": "",
    }

    if not website:
        result["error"] = "no_website"
        return result

    async with semaphore:
        context = await browser.new_context()
        page = await context.new_page()

        # Capture all network domains hit for this hotel
        network_hosts = set()

        def handle_request(request):
            try:
                host = extract_domain(request.url)
                if host:
                    network_hosts.add(host)
            except Exception:
                pass

        # Attach network listener
        page.on("request", handle_request)

        try:
            await page.goto(website, timeout=20000, wait_until="networkidle")
            hotel_domain = extract_domain(page.url)
            log(f"  Loaded site. Domain: {hotel_domain}")

            # Try booking button flow
            booking_page, booking_url, method = await click_and_get_booking_page(
                context, page, website
            )
            result["booking_url"] = booking_url or ""
            result["detection_method"] = method

            # Start with URL-based detection if we got a booking URL
            engine_name = ""
            engine_domain = ""
            detection_method = method

            if booking_url:
                log(f"  Booking URL candidate: {booking_url}")
                engine_name, engine_domain, method2 = detect_engine_from_url(
                    booking_url, hotel_domain
                )
                detection_method = f"{detection_method}+{method2}" if detection_method else method2

            # If booking URL didn’t give us a clear engine, try booking_page HTML
            if booking_page is not None and engine_name in (
                "",
                "unknown",
                "unknown_third_party",
                "proprietary_or_same_domain",
            ):
                try:
                    html = await booking_page.content()
                except Exception:
                    html = ""
                html_engine, html_method = detect_engine_from_html(html)
                if html_engine:
                    engine_name = html_engine
                    detection_method = (
                        f"{detection_method}+{html_method}"
                        if detection_method
                        else html_method
                    )

            # If still unclear, sniff network domains
            if engine_name in ("", "unknown", "unknown_third_party", "proprietary_or_same_domain"):
                net_engine, net_domain, net_method = await sniff_network_for_engine(
                    network_hosts, hotel_domain
                )
                if net_engine:
                    engine_name = net_engine
                    # If we already had an engine_domain from URL but this is more explicit, override domain
                    if not engine_domain:
                        engine_domain = net_domain
                    detection_method = (
                        f"{detection_method}+{net_method}"
                        if detection_method
                        else net_method
                    )

            # If STILL unclear, try scanning frames/iframes
            if engine_name in ("", "unknown", "unknown_third_party", "proprietary_or_same_domain"):
                frame_engine, frame_domain, frame_method = await detect_engine_fallback_from_frames(
                    booking_page or page
                )
                if frame_engine:
                    engine_name = frame_engine
                    if not engine_domain:
                        engine_domain = frame_domain
                    detection_method = (
                        f"{detection_method}+{frame_method}"
                        if detection_method
                        else frame_method
                    )

            # Final fallback: scan main page HTML if we have absolutely nothing
            if engine_name in ("", "unknown", "unknown_third_party", "proprietary_or_same_domain"):
                try:
                    base_html = await page.content()
                except Exception:
                    base_html = ""
                html_engine, html_method = detect_engine_from_html(base_html)
                if html_engine:
                    engine_name = html_engine
                    detection_method = (
                        f"{detection_method}+base_html_{html_method}"
                        if detection_method
                        else f"base_html_{html_method}"
                    )

            # Assign to result
            result["booking_engine"] = engine_name or "unknown"
            result["booking_engine_domain"] = engine_domain
            if detection_method:
                result["detection_method"] = detection_method

            log(
                f"  Engine: {result['booking_engine']} "
                f"({result['booking_engine_domain']}) via {result['detection_method'] or 'n/a'}"
            )

        except PWTimeoutError:
            result["error"] = "timeout_loading_site_or_booking"
            log("  ERROR: timeout_loading_site_or_booking")
        except Exception as e:
            result["error"] = f"exception: {e}"
            log(f"  ERROR: {e}")

        await context.close()

        if pause_sec > 0:
            await asyncio.sleep(pause_sec)

    return result


# ------------------------------------------------------------
# Main driver
# ------------------------------------------------------------

async def process_hotels_parallel(
    input_csv: str,
    output_csv: str,
    limit: int = 0,
    concurrency: int = 10,
    headless: bool = True,
    pause_sec: float = 0.5,
    flush_every: int = 10,
):
    # Load all hotels from input
    with open(input_csv, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        all_hotels = list(reader)

    total_in_input = len(all_hotels)
    log(f"Loaded {total_in_input} hotels from {input_csv}")

    # Check existing output to enable resume
    processed_keys = set()
    append_mode = False
    if os.path.exists(output_csv):
        with open(output_csv, newline="", encoding="utf-8") as f_out:
            out_reader = csv.DictReader(f_out)
            for row in out_reader:
                name = (row.get("name") or "").strip()
                website = normalize_url(row.get("website") or "")
                processed_keys.add((name, website))
        if processed_keys:
            append_mode = True
            log(f"Found {len(processed_keys)} existing rows in {output_csv}, will skip those hotels.")

    # Filter hotels to process (skip ones already in output)
    hotels = []
    for row in all_hotels:
        name = (row.get("name") or "").strip()
        website_raw = (row.get("website") or "").strip()
        website_norm = normalize_url(website_raw)
        key = (name, website_norm)
        if key in processed_keys:
            continue
        hotels.append(row)

    if limit > 0:
        hotels = hotels[:limit]

    total_to_process = len(hotels)
    if total_to_process == 0:
        log("Nothing to do. All hotels already present in output CSV.")
        return

    log(f"{total_to_process} hotels to process (after skipping already processed ones).")

    # Stats
    processed_count = 0
    written_count = 0
    timeout_count = 0
    exception_count = 0
    known_engine_count = 0

    fieldnames = [
        "name",
        "website",
        "booking_url",
        "booking_engine",
        "booking_engine_domain",
        "detection_method",
        "error",
    ]

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=headless)
        semaphore = asyncio.Semaphore(concurrency)

        tasks = [
            process_single_hotel(
                idx, total_to_process, row, browser, semaphore, pause_sec
            )
            for idx, row in enumerate(hotels, start=1)
        ]

        # Open output file once and write incrementally
        mode = "a" if append_mode else "w"
        with open(output_csv, mode, newline="", encoding="utf-8") as f_out:
            writer = csv.DictWriter(f_out, fieldnames=fieldnames)
            if not append_mode:
                writer.writeheader()

            since_last_flush = 0

            for coro in asyncio.as_completed(tasks):
                res = await coro
                processed_count += 1

                # Update stats
                err = res.get("error") or ""
                if err:
                    if "timeout" in err:
                        timeout_count += 1
                    else:
                        exception_count += 1

                engine = res.get("booking_engine") or ""
                if engine not in ("", "unknown", "proprietary_or_same_domain", "unknown_third_party"):
                    known_engine_count += 1

                # Write row immediately
                writer.writerow(res)
                written_count += 1
                since_last_flush += 1

                # Flush every N rows to ensure progress is on disk
                if since_last_flush >= flush_every:
                    f_out.flush()
                    since_last_flush = 0
                    log(
                        f"[progress] written={written_count}, "
                        f"processed={processed_count}/{total_to_process}, "
                        f"timeouts={timeout_count}, "
                        f"exceptions={exception_count}, "
                        f"known_engines={known_engine_count}"
                    )

            if since_last_flush > 0:
                f_out.flush()

        await browser.close()

    log(
        f"\nDone. Processed {processed_count} hotels, wrote {written_count} rows to {output_csv}. "
        f"Timeouts={timeout_count}, exceptions={exception_count}, known_engines={known_engine_count}"
    )


def main():
    parser = argparse.ArgumentParser(
        description="Detect hotel booking engines in parallel from hotels_filtered.csv"
    )
    parser.add_argument("--input", default=INPUT_CSV, help="Input CSV file")
    parser.add_argument("--output", default=OUTPUT_CSV, help="Output CSV file")
    parser.add_argument("--limit", type=int, default=0, help="Limit number of hotels")
    parser.add_argument(
        "--concurrency",
        type=int,
        default=10,
        help="Number of hotels to process in parallel (default: 10)",
    )
    parser.add_argument(
        "--headed",
        action="store_true",
        help="Run browser in headed mode (show UI)",
    )
    parser.add_argument(
        "--pause",
        type=float,
        default=0.5,
        help="Pause per hotel (inside semaphore) to be nicer (default: 0.5s)",
    )
    parser.add_argument(
        "--flush-every",
        type=int,
        default=10,
        help="Flush output CSV to disk after this many rows (default: 10)",
    )
    args = parser.parse_args()

    asyncio.run(
        process_hotels_parallel(
            input_csv=args.input,
            output_csv=args.output,
            limit=args.limit,
            concurrency=args.concurrency,
            headless=not args.headed,
            pause_sec=args.pause,
            flush_every=args.flush_every,
        )
    )


if __name__ == "__main__":
    main()
