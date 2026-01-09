#!/usr/bin/env python3
"""
Download US Zip Codes by State
==============================
Downloads zip codes from public data and saves by state.

Usage:
    python3 download_zipcodes.py --all
    python3 download_zipcodes.py --states california florida texas
"""

import csv
import os
import argparse
import urllib.request

# Zip code ranges by state (first 3 digits)
# Source: https://en.wikipedia.org/wiki/List_of_ZIP_Code_prefixes
STATE_RANGES = {
    "alabama": (350, 369),
    "alaska": (995, 999),
    "arizona": (850, 865),
    "arkansas": (716, 729),
    "california": (900, 961),
    "colorado": (800, 816),
    "connecticut": (60, 69),
    "delaware": (197, 199),
    "florida": (320, 349),
    "georgia": (300, 319),
    "hawaii": (967, 968),
    "idaho": (832, 838),
    "illinois": (600, 629),
    "indiana": (460, 479),
    "iowa": (500, 528),
    "kansas": (660, 679),
    "kentucky": (400, 427),
    "louisiana": (700, 714),
    "maine": (39, 49),
    "maryland": (206, 219),
    "massachusetts": (10, 27),
    "michigan": (480, 499),
    "minnesota": (550, 567),
    "mississippi": (386, 397),
    "missouri": (630, 658),
    "montana": (590, 599),
    "nebraska": (680, 693),
    "nevada": (889, 898),
    "new_hampshire": (30, 38),
    "new_jersey": (70, 89),
    "new_mexico": (870, 884),
    "new_york": (100, 149),
    "north_carolina": (270, 289),
    "north_dakota": (580, 588),
    "ohio": (430, 459),
    "oklahoma": (730, 749),
    "oregon": (970, 979),
    "pennsylvania": (150, 196),
    "rhode_island": (28, 29),
    "south_carolina": (290, 299),
    "south_dakota": (570, 577),
    "tennessee": (370, 385),
    "texas": (750, 799),
    "utah": (840, 847),
    "vermont": (50, 59),
    "virginia": (220, 246),
    "washington": (980, 994),
    "west_virginia": (247, 268),
    "wisconsin": (530, 549),
    "wyoming": (820, 831),
}

ZIP_DATA_URL = "https://gist.githubusercontent.com/erichurst/7882666/raw/5bdc46db47d9515269ab12ed6fb2850377fd869e/US%2520Zip%2520Codes%2520from%25202013%2520Government%2520Data"


def download_zip_data():
    """Download the master zip code file."""
    print("Downloading US zip code database...")
    cache_file = "/tmp/us_zipcodes_master.csv"

    if not os.path.exists(cache_file):
        urllib.request.urlretrieve(ZIP_DATA_URL, cache_file)
        print(f"  Downloaded to {cache_file}")
    else:
        print(f"  Using cached {cache_file}")

    return cache_file


def load_all_zipcodes(filepath):
    """Load all zip codes from the master file."""
    zipcodes = {}  # prefix -> list of zips

    with open(filepath, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            zipcode = row['ZIP'].strip()
            if len(zipcode) >= 3:
                prefix = int(zipcode[:3])
                if prefix not in zipcodes:
                    zipcodes[prefix] = []
                zipcodes[prefix].append(zipcode)

    return zipcodes


def get_state_zipcodes(all_zips, state):
    """Get zip codes for a specific state."""
    if state not in STATE_RANGES:
        print(f"Unknown state: {state}")
        return []

    start, end = STATE_RANGES[state]
    result = []
    for prefix in range(start, end + 1):
        result.extend(all_zips.get(prefix, []))

    return sorted(set(result))


def save_state_zipcodes(zipcodes, state, output_dir="data"):
    """Save zip codes for a state to a file."""
    os.makedirs(output_dir, exist_ok=True)
    filepath = os.path.join(output_dir, f"{state}_zipcodes.txt")

    with open(filepath, 'w') as f:
        f.write('\n'.join(zipcodes))

    return filepath


def main():
    parser = argparse.ArgumentParser(description="Download US zip codes by state")
    parser.add_argument("--all", action="store_true", help="Download all states")
    parser.add_argument("--states", nargs="+", help="Specific states to download")
    parser.add_argument("--list", action="store_true", help="List available states")
    parser.add_argument("--output", default="data", help="Output directory")

    args = parser.parse_args()

    if args.list:
        print("Available states:")
        for state in sorted(STATE_RANGES.keys()):
            print(f"  {state}")
        return

    # Download master file
    master_file = download_zip_data()
    all_zips = load_all_zipcodes(master_file)

    # Determine which states to process
    if args.all:
        states = list(STATE_RANGES.keys())
    elif args.states:
        states = [s.lower().replace(" ", "_") for s in args.states]
    else:
        # Default: just CA and FL
        states = ["california", "florida"]

    print(f"\nProcessing {len(states)} states...")

    total_zips = 0
    for state in states:
        zips = get_state_zipcodes(all_zips, state)
        if zips:
            filepath = save_state_zipcodes(zips, state, args.output)
            print(f"  {state}: {len(zips)} zip codes -> {filepath}")
            total_zips += len(zips)
        else:
            print(f"  {state}: No zip codes found")

    print(f"\nTotal: {total_zips} zip codes saved to {args.output}/")

    # Credit estimate
    credits_per_zip = 6  # search types
    total_credits = total_zips * credits_per_zip
    print(f"\nSerper credit estimate: {total_zips} zips × {credits_per_zip} searches = {total_credits:,} credits")


if __name__ == "__main__":
    main()
