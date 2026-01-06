#!/usr/bin/env python3
"""
Sadie Funnel Stats - Full Pipeline Analytics
=============================================
Generates comprehensive funnel statistics from scraper through to final export.

Usage:
    python3 sadie_funnel_stats.py --city sydney --scraper scraper_output/sydney_hotels.csv --detector detector_output/sydney_leads.csv
    python3 sadie_funnel_stats.py --city ocean_city --detector detector_output/ocean_city_leads.csv --postprocess detector_output/ocean_city_leads_post.csv
"""

import csv
import sys
import os
import argparse
from datetime import datetime
from collections import Counter
from urllib.parse import urlparse


def load_csv(filepath: str) -> list:
    """Load CSV file and return list of rows."""
    if not filepath or not os.path.exists(filepath):
        return []
    with open(filepath, "r", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def count_with_field(rows: list, field: str) -> int:
    """Count rows that have a non-empty value for a field."""
    return sum(1 for r in rows if r.get(field, "").strip())


def extract_domain(url: str) -> str:
    """Extract domain from URL."""
    try:
        return urlparse(url).netloc.lower().replace("www.", "")
    except:
        return ""


def generate_funnel_stats(city: str, scraper_file: str = None, detector_file: str = None, 
                          postprocess_file: str = None, hubspot_file: str = None) -> dict:
    """Generate comprehensive funnel statistics."""
    
    stats = {
        "city": city,
        "generated_at": datetime.now().isoformat(),
    }
    
    # Load all available data
    scraper_rows = load_csv(scraper_file) if scraper_file else []
    detector_rows = load_csv(detector_file) if detector_file else []
    postprocess_rows = load_csv(postprocess_file) if postprocess_file else []
    hubspot_rows = load_csv(hubspot_file) if hubspot_file else []
    
    # =========================================================================
    # STAGE 1: SCRAPER (Google Maps)
    # =========================================================================
    if scraper_rows:
        stats["scraper_total"] = len(scraper_rows)
        stats["scraper_with_website"] = count_with_field(scraper_rows, "website")
        stats["scraper_with_phone"] = count_with_field(scraper_rows, "phone")
        stats["scraper_with_address"] = count_with_field(scraper_rows, "address")
        stats["scraper_website_rate"] = round(stats["scraper_with_website"] / len(scraper_rows) * 100, 1) if scraper_rows else 0
    
    # =========================================================================
    # STAGE 2: DETECTOR (Booking Engine Detection)
    # =========================================================================
    if detector_rows:
        stats["detector_total"] = len(detector_rows)
        stats["detector_with_website"] = count_with_field(detector_rows, "website")
        stats["detector_with_booking_url"] = count_with_field(detector_rows, "booking_url")
        stats["detector_with_engine"] = sum(1 for r in detector_rows 
            if r.get("booking_engine", "").strip() and 
            r.get("booking_engine") not in ["unknown", "unknown_third_party", "proprietary_or_same_domain", "contact_only", ""])
        stats["detector_with_known_engine"] = sum(1 for r in detector_rows 
            if r.get("booking_engine", "").strip() and 
            r.get("booking_engine") not in ["unknown", "unknown_third_party", "proprietary_or_same_domain", "contact_only", "", "unknown_booking_api"])
        stats["detector_with_error"] = sum(1 for r in detector_rows 
            if r.get("error", "").strip() and r.get("error") != "no_website")
        stats["detector_with_phone"] = sum(1 for r in detector_rows 
            if r.get("phone_google", "").strip() or r.get("phone_website", "").strip())
        stats["detector_with_email"] = count_with_field(detector_rows, "email")
        
        # Booking URL rate (of those with websites)
        with_website = stats["detector_with_website"]
        stats["detector_booking_rate"] = round(stats["detector_with_booking_url"] / with_website * 100, 1) if with_website > 0 else 0
        
        # Engine breakdown
        engine_counts = Counter(r.get("booking_engine", "") for r in detector_rows if r.get("booking_engine", "").strip())
        stats["detector_engines"] = dict(engine_counts.most_common(20))
        
        # Error breakdown
        error_counts = Counter(r.get("error", "") for r in detector_rows 
            if r.get("error", "").strip() and r.get("error") != "no_website")
        stats["detector_errors"] = dict(error_counts.most_common(10))
        
        # Detection method breakdown
        method_counts = Counter()
        for r in detector_rows:
            method = r.get("detection_method", "")
            if method:
                for part in method.split("+"):
                    method_counts[part.strip()] += 1
        stats["detector_methods"] = dict(method_counts.most_common(10))
    
    # =========================================================================
    # STAGE 3: POST-PROCESSING (Cleaned Leads)
    # =========================================================================
    if postprocess_rows:
        stats["postprocess_total"] = len(postprocess_rows)
        stats["postprocess_with_booking_url"] = count_with_field(postprocess_rows, "booking_url")
        stats["postprocess_with_known_engine"] = sum(1 for r in postprocess_rows 
            if r.get("booking_engine", "").strip() and 
            r.get("booking_engine") not in ["unknown", "unknown_third_party", "proprietary_or_same_domain", "contact_only", "", "unknown_booking_api"])
        
        # Calculate conversion from detector
        if detector_rows:
            stats["postprocess_retention_rate"] = round(len(postprocess_rows) / len(detector_rows) * 100, 1)
    
    # =========================================================================
    # STAGE 4: HUBSPOT EXPORT (Final Leads)
    # =========================================================================
    if hubspot_rows:
        stats["hubspot_total"] = len(hubspot_rows)
        stats["hubspot_tier1"] = sum(1 for r in hubspot_rows 
            if r.get("PMS", "").strip() and 
            r.get("PMS") not in ["unknown", "unknown_third_party", "unknown_booking_api", "proprietary_or_same_domain"])
        stats["hubspot_tier2"] = stats["hubspot_total"] - stats["hubspot_tier1"]
    
    # =========================================================================
    # OVERALL FUNNEL METRICS
    # =========================================================================
    # Calculate full funnel conversion
    start_count = stats.get("scraper_total") or stats.get("detector_total", 0)
    end_count = stats.get("hubspot_total") or stats.get("postprocess_total") or stats.get("detector_with_booking_url", 0)
    
    if start_count > 0:
        stats["funnel_conversion_rate"] = round(end_count / start_count * 100, 1)
    
    return stats


def print_funnel_report(stats: dict):
    """Print a formatted funnel report."""
    
    print(f"\n{'='*60}")
    print(f"FUNNEL REPORT: {stats.get('city', 'Unknown').upper()}")
    print(f"Generated: {stats.get('generated_at', '')}")
    print(f"{'='*60}")
    
    # Scraper Stage
    if stats.get("scraper_total"):
        print(f"\n📥 SCRAPER (Google Maps)")
        print(f"   Total scraped: {stats['scraper_total']:,}")
        print(f"   With website: {stats['scraper_with_website']:,} ({stats['scraper_website_rate']}%)")
        print(f"   With phone: {stats.get('scraper_with_phone', 0):,}")
    
    # Detector Stage
    if stats.get("detector_total"):
        print(f"\n🔍 DETECTOR")
        print(f"   Processed: {stats['detector_total']:,}")
        print(f"   Booking URL found: {stats['detector_with_booking_url']:,} ({stats['detector_booking_rate']}%) ← DETECTION RATE")
        print(f"   Known engine: {stats['detector_with_known_engine']:,}")
        print(f"   Errors: {stats['detector_with_error']:,}")
        
        if stats.get("detector_engines"):
            print(f"\n   Top Engines:")
            for engine, count in list(stats["detector_engines"].items())[:10]:
                print(f"     {engine}: {count}")
    
    # Post-process Stage
    if stats.get("postprocess_total"):
        print(f"\n✨ POST-PROCESSING")
        print(f"   Clean leads: {stats['postprocess_total']:,}")
        print(f"   With booking URL: {stats['postprocess_with_booking_url']:,}")
        print(f"   With known engine: {stats['postprocess_with_known_engine']:,}")
        if stats.get("postprocess_retention_rate"):
            print(f"   Retention: {stats['postprocess_retention_rate']}%")
    
    # HubSpot Stage
    if stats.get("hubspot_total"):
        print(f"\n📤 HUBSPOT EXPORT")
        print(f"   Total exported: {stats['hubspot_total']:,}")
        print(f"   Tier 1 (known engine): {stats['hubspot_tier1']:,}")
        print(f"   Tier 2 (unknown engine): {stats['hubspot_tier2']:,}")
    
    # Overall Funnel
    print(f"\n{'='*60}")
    if stats.get("funnel_conversion_rate"):
        print(f"📊 OVERALL FUNNEL CONVERSION: {stats['funnel_conversion_rate']}%")
    print(f"{'='*60}\n")


def save_stats_csv(stats: dict, output_path: str):
    """Save stats to a CSV file."""
    
    # Flatten stats for CSV
    flat_stats = []
    
    # Add main metrics
    metrics = [
        ("City", stats.get("city", "")),
        ("Generated At", stats.get("generated_at", "")),
        ("", ""),
        ("=== SCRAPER STAGE ===", ""),
        ("Scraper - Total Scraped", stats.get("scraper_total", "N/A")),
        ("Scraper - With Website", stats.get("scraper_with_website", "N/A")),
        ("Scraper - Website Rate %", stats.get("scraper_website_rate", "N/A")),
        ("", ""),
        ("=== DETECTOR STAGE ===", ""),
        ("Detector - Total Processed", stats.get("detector_total", "N/A")),
        ("Detector - With Website", stats.get("detector_with_website", "N/A")),
        ("Detector - With Booking URL", stats.get("detector_with_booking_url", "N/A")),
        ("Detector - Booking Rate %", stats.get("detector_booking_rate", "N/A")),
        ("Detector - With Known Engine", stats.get("detector_with_known_engine", "N/A")),
        ("Detector - With Any Engine", stats.get("detector_with_engine", "N/A")),
        ("Detector - With Errors", stats.get("detector_with_error", "N/A")),
        ("Detector - With Phone", stats.get("detector_with_phone", "N/A")),
        ("Detector - With Email", stats.get("detector_with_email", "N/A")),
        ("", ""),
        ("=== POST-PROCESS STAGE ===", ""),
        ("PostProcess - Total Leads", stats.get("postprocess_total", "N/A")),
        ("PostProcess - With Booking URL", stats.get("postprocess_with_booking_url", "N/A")),
        ("PostProcess - With Known Engine", stats.get("postprocess_with_known_engine", "N/A")),
        ("PostProcess - Retention Rate %", stats.get("postprocess_retention_rate", "N/A")),
        ("", ""),
        ("=== HUBSPOT EXPORT ===", ""),
        ("HubSpot - Total Exported", stats.get("hubspot_total", "N/A")),
        ("HubSpot - Tier 1 (Known Engine)", stats.get("hubspot_tier1", "N/A")),
        ("HubSpot - Tier 2 (Unknown Engine)", stats.get("hubspot_tier2", "N/A")),
        ("", ""),
        ("=== OVERALL ===", ""),
        ("Funnel Conversion Rate %", stats.get("funnel_conversion_rate", "N/A")),
    ]
    
    # Add engine breakdown
    if stats.get("detector_engines"):
        metrics.append(("", ""))
        metrics.append(("=== ENGINE BREAKDOWN ===", ""))
        for engine, count in stats["detector_engines"].items():
            metrics.append((f"Engine - {engine}", count))
    
    # Add error breakdown
    if stats.get("detector_errors"):
        metrics.append(("", ""))
        metrics.append(("=== ERROR BREAKDOWN ===", ""))
        for error, count in stats["detector_errors"].items():
            error_display = error[:50] if len(error) > 50 else error
            metrics.append((f"Error - {error_display}", count))
    
    # Write to CSV
    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["Metric", "Value"])
        writer.writerows(metrics)
    
    print(f"Stats saved to: {output_path}")


def main():
    parser = argparse.ArgumentParser(description="Generate funnel statistics")
    parser.add_argument("--city", required=True, help="City name for the report")
    parser.add_argument("--scraper", help="Path to scraper output CSV")
    parser.add_argument("--detector", help="Path to detector output CSV")
    parser.add_argument("--postprocess", help="Path to post-processed CSV")
    parser.add_argument("--hubspot", help="Path to HubSpot export CSV")
    parser.add_argument("--output", help="Path to save stats CSV (optional)")
    
    args = parser.parse_args()
    
    # Generate stats
    stats = generate_funnel_stats(
        city=args.city,
        scraper_file=args.scraper,
        detector_file=args.detector,
        postprocess_file=args.postprocess,
        hubspot_file=args.hubspot
    )
    
    # Print report
    print_funnel_report(stats)
    
    # Save to CSV if output specified
    if args.output:
        save_stats_csv(stats, args.output)
    else:
        # Auto-generate output path
        output_path = f"detector_output/{args.city}_funnel_stats.csv"
        save_stats_csv(stats, output_path)


if __name__ == "__main__":
    main()

