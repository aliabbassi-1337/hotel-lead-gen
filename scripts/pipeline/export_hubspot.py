#!/usr/bin/env python3
"""
Sadie HubSpot Export - Convert Detector Output to HubSpot Format
=================================================================
Converts detector output CSV files to HubSpot-ready import format.

Usage:
    python3 sadie_hubspot_export.py detector_output/sydney_leads.csv
    python3 sadie_hubspot_export.py detector_output/sydney_leads.csv --output hubspot_import.csv
"""

import csv
import sys
import os
import argparse
from urllib.parse import urlparse


def extract_domain(url: str) -> str:
    """Extract domain from URL for HubSpot's domain field."""
    try:
        parsed = urlparse(url)
        domain = parsed.netloc.lower().replace("www.", "")
        return domain if domain else url
    except:
        return url


def clean_phone(phone: str) -> str:
    """Clean phone number for HubSpot."""
    if not phone:
        return ""
    # Remove common prefixes and clean up
    phone = phone.strip()
    return phone


def convert_to_hubspot(input_file: str, output_file: str):
    """Convert detector output to HubSpot format."""
    
    with open(input_file, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
    
    if not rows:
        print(f"No data in {input_file}")
        return
    
    # HubSpot column mapping
    # Left = HubSpot property name, Right = our detector output column
    hubspot_rows = []
    
    for row in rows:
        # Skip rows with no booking URL (Tier 3)
        if not row.get("booking_url", "").strip():
            continue
        
        # Get best phone (prefer Google, fallback to website)
        phone = row.get("phone_google", "").strip() or row.get("phone_website", "").strip()
        
        # Build description
        description_parts = []
        if row.get("booking_engine"):
            description_parts.append(f"PMS: {row['booking_engine']}")
        if row.get("booking_url"):
            description_parts.append(f"Booking URL: {row['booking_url']}")
        if row.get("room_count"):
            description_parts.append(f"Rooms: {row['room_count']}")
        
        hubspot_row = {
            # Core company properties
            "Name": row.get("name", "").strip(),
            "Company Domain Name": extract_domain(row.get("website", "")),
            "Website URL": row.get("website", "").strip(),
            "Phone Number": clean_phone(phone),
            "Description": " | ".join(description_parts),
            
            # Custom properties (must exist in HubSpot first)
            "PMS": row.get("booking_engine", "").strip(),
            "Booking URL": row.get("booking_url", "").strip(),
            "Number of Rooms": row.get("room_count", "").strip(),
            
            # Contact info
            "Email": row.get("email", "").strip(),
            
            # Location (if available)
            "Latitude": row.get("latitude", "").strip(),
            "Longitude": row.get("longitude", "").strip(),
            
            # Lead quality indicator
            "Lead Status": "New" if row.get("booking_url") else "Unqualified",
            
            # Existing customer association (to be filled manually)
            "Existing Customer in Area": "",
        }
        
        hubspot_rows.append(hubspot_row)
    
    if not hubspot_rows:
        print("No qualifying rows to export (need booking_url)")
        return
    
    # Write HubSpot CSV
    fieldnames = [
        "Name",
        "Company Domain Name", 
        "Website URL",
        "Phone Number",
        "Email",
        "PMS",
        "Booking URL",
        "Number of Rooms",
        "Lead Status",
        "Existing Customer in Area",
        "Description",
        "Latitude",
        "Longitude",
    ]
    
    with open(output_file, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(hubspot_rows)
    
    print(f"✓ Exported {len(hubspot_rows)} companies to {output_file}")
    print(f"  (Filtered out {len(rows) - len(hubspot_rows)} rows without booking URLs)")


def main():
    parser = argparse.ArgumentParser(description="Convert detector output to HubSpot format")
    parser.add_argument("input", help="Input CSV file from detector")
    parser.add_argument("--output", "-o", help="Output CSV file (default: hubspot_<input>)")
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input):
        print(f"File not found: {args.input}")
        sys.exit(1)
    
    # Generate output filename if not provided
    if args.output:
        output_file = args.output
    else:
        input_basename = os.path.basename(args.input)
        output_file = f"hubspot_{input_basename}"
    
    convert_to_hubspot(args.input, output_file)


if __name__ == "__main__":
    main()

