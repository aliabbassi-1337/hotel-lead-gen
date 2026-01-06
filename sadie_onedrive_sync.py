#!/usr/bin/env python3
"""
Sadie OneDrive Sync - Organize and Sync Leads to OneDrive
==========================================================
Creates a geographic folder structure and exports leads with stats to OneDrive.

Usage:
    python3 sadie_onedrive_sync.py --city sydney --country australia --input detector_output/sydney_leads_post.csv
    python3 sadie_onedrive_sync.py --city ocean_city --country usa --region "east_coast" --state maryland --input detector_output/ocean_city_leads_post.csv
    python3 sadie_onedrive_sync.py --list  # List current structure
"""

import os
import sys
import argparse
from datetime import datetime
from pathlib import Path

# OneDrive base path
ONEDRIVE_BASE = os.path.expanduser("~/Library/CloudStorage/OneDrive-ValsoftCorporation")
SADIE_FOLDER = "Sadie Lead Gen"

# Geographic structure mapping
COUNTRY_REGIONS = {
    "usa": {
        "east_coast": ["florida", "maryland", "tennessee", "georgia", "virginia", "north_carolina", 
                       "south_carolina", "new_york", "new_jersey", "pennsylvania", "massachusetts",
                       "maine", "connecticut", "delaware", "rhode_island", "vermont", "new_hampshire"],
        "west_coast": ["california", "oregon", "washington", "hawaii", "alaska"],
        "midwest": ["illinois", "ohio", "michigan", "indiana", "wisconsin", "minnesota", "iowa",
                    "missouri", "kansas", "nebraska", "north_dakota", "south_dakota"],
        "south": ["texas", "louisiana", "arkansas", "oklahoma", "mississippi", "alabama", "kentucky"],
        "mountain": ["colorado", "utah", "arizona", "nevada", "new_mexico", "wyoming", "montana", "idaho"],
    },
    "australia": {
        "new_south_wales": ["sydney", "newcastle", "wollongong", "central_coast"],
        "victoria": ["melbourne", "geelong", "ballarat", "bendigo"],
        "queensland": ["brisbane", "gold_coast", "cairns", "sunshine_coast", "townsville"],
        "western_australia": ["perth", "fremantle", "broome"],
        "south_australia": ["adelaide", "barossa"],
        "tasmania": ["hobart", "launceston"],
        "northern_territory": ["darwin", "alice_springs"],
        "act": ["canberra"],
    },
    "uk": {
        "england": ["london", "manchester", "birmingham", "liverpool", "leeds", "bristol", "brighton"],
        "scotland": ["edinburgh", "glasgow", "aberdeen", "inverness"],
        "wales": ["cardiff", "swansea"],
        "northern_ireland": ["belfast"],
    },
    "canada": {
        "ontario": ["toronto", "ottawa", "niagara_falls"],
        "british_columbia": ["vancouver", "victoria", "whistler"],
        "quebec": ["montreal", "quebec_city"],
        "alberta": ["calgary", "edmonton", "banff"],
    },
}

# City to state/region auto-mapping
CITY_MAPPINGS = {
    # USA
    "ocean_city": ("usa", "east_coast", "maryland"),
    "gatlinburg": ("usa", "east_coast", "tennessee"),
    "miami": ("usa", "east_coast", "florida"),
    "orlando": ("usa", "east_coast", "florida"),
    "new_york": ("usa", "east_coast", "new_york"),
    "boston": ("usa", "east_coast", "massachusetts"),
    "los_angeles": ("usa", "west_coast", "california"),
    "san_francisco": ("usa", "west_coast", "california"),
    "seattle": ("usa", "west_coast", "washington"),
    "denver": ("usa", "mountain", "colorado"),
    "austin": ("usa", "south", "texas"),
    "chicago": ("usa", "midwest", "illinois"),
    "nashville": ("usa", "east_coast", "tennessee"),
    "savannah": ("usa", "east_coast", "georgia"),
    "charleston": ("usa", "east_coast", "south_carolina"),
    
    # Australia
    "sydney": ("australia", "new_south_wales", None),
    "melbourne": ("australia", "victoria", None),
    "brisbane": ("australia", "queensland", None),
    "perth": ("australia", "western_australia", None),
    "adelaide": ("australia", "south_australia", None),
    "gold_coast": ("australia", "queensland", None),
    "cairns": ("australia", "queensland", None),
    
    # UK
    "london": ("uk", "england", None),
    "edinburgh": ("uk", "scotland", None),
    "manchester": ("uk", "england", None),
    
    # Canada
    "toronto": ("canada", "ontario", None),
    "vancouver": ("canada", "british_columbia", None),
    "montreal": ("canada", "quebec", None),
}


def get_onedrive_path() -> Path:
    """Get the Sadie Lead Gen folder in OneDrive."""
    return Path(ONEDRIVE_BASE) / SADIE_FOLDER


def create_folder_structure():
    """Create ONLY the base folder in OneDrive. City folders are created on sync."""
    base = get_onedrive_path()
    
    # Create base folder only - no empty subfolders
    base.mkdir(parents=True, exist_ok=True)
    
    print(f"✅ Base folder ready at: {base}")
    print(f"   (City folders will be created when you sync data)")
    return base


def get_city_path(city: str, country: str = None, region: str = None, state: str = None) -> Path:
    """Get the full path for a city's folder."""
    base = get_onedrive_path()
    
    # Normalize city name
    city_key = city.lower().replace(" ", "_").replace("-", "_")
    
    # Auto-detect location if not provided
    if city_key in CITY_MAPPINGS and not country:
        country, region, state = CITY_MAPPINGS[city_key]
    
    if not country:
        raise ValueError(f"Unknown city: {city}. Please provide --country")
    
    # Build path
    country_name = country.replace("_", " ").title()
    path = base / country_name
    
    if region:
        region_name = region.replace("_", " ").title()
        path = path / region_name
    
    if state:
        state_name = state.replace("_", " ").title()
        path = path / state_name
    
    # City folder
    city_name = city.replace("_", " ").title()
    path = path / city_name
    
    return path


def sync_city_data(city: str, input_file: str, country: str = None, 
                   region: str = None, state: str = None, scraper_file: str = None,
                   detector_file: str = None):
    """Sync a city's data to OneDrive as Excel file with Stats sheet."""
    
    # Get city path
    city_path = get_city_path(city, country, region, state)
    city_path.mkdir(parents=True, exist_ok=True)
    
    # Generate timestamp for versioning
    timestamp = datetime.now().strftime("%Y%m%d")
    base_name = os.path.splitext(os.path.basename(input_file))[0]
    
    # Create Excel with leads + stats (single file)
    try:
        from sadie_excel_export import create_excel_export
        excel_dest = city_path / f"{base_name}_{timestamp}.xlsx"
        create_excel_export(
            input_file=input_file,
            city=city,
            scraper_file=scraper_file,
            detector_file=detector_file,
            output_file=str(excel_dest)
        )
        print(f"\n✅ Synced to: {city_path}")
        print(f"   📊 {excel_dest.name}")
        print(f"   (OneDrive will auto-sync)")
    except ImportError:
        print("❌ Could not create Excel file (openpyxl not available)")
        print("   Install with: pip3 install openpyxl")
    except Exception as e:
        print(f"❌ Excel export failed: {e}")


def list_structure():
    """List current folder structure."""
    base = get_onedrive_path()
    
    if not base.exists():
        print(f"Folder not found: {base}")
        print("Run with --init to create the folder structure")
        return
    
    print(f"\n📁 {SADIE_FOLDER}")
    print(f"   Location: {base}\n")
    
    def print_tree(path: Path, prefix: str = ""):
        items = sorted(path.iterdir())
        dirs = [i for i in items if i.is_dir()]
        files = [i for i in items if i.is_file() and not i.name.startswith(".")]
        
        for i, d in enumerate(dirs):
            connector = "└── " if i == len(dirs) - 1 and not files else "├── "
            print(f"{prefix}{connector}📁 {d.name}")
            
            # Count files in this dir
            file_count = len([f for f in d.iterdir() if f.is_file() and not f.name.startswith(".")])
            if file_count > 0:
                sub_prefix = prefix + ("    " if i == len(dirs) - 1 else "│   ")
                print(f"{sub_prefix}({file_count} files)")
            
            # Recurse one level
            subdirs = [sd for sd in d.iterdir() if sd.is_dir()]
            if subdirs:
                sub_prefix = prefix + ("    " if i == len(dirs) - 1 else "│   ")
                print_tree(d, sub_prefix)
    
    print_tree(base)


def main():
    parser = argparse.ArgumentParser(description="Sync leads to OneDrive")
    parser.add_argument("--init", action="store_true", help="Create folder structure")
    parser.add_argument("--list", action="store_true", help="List current structure")
    parser.add_argument("--city", help="City name")
    parser.add_argument("--country", help="Country (usa, australia, uk, canada)")
    parser.add_argument("--region", help="Region (e.g., east_coast, new_south_wales)")
    parser.add_argument("--state", help="State (for USA)")
    parser.add_argument("--input", help="Input CSV file (post-processed leads)")
    parser.add_argument("--scraper", help="Scraper output CSV (for full funnel stats)")
    parser.add_argument("--detector", help="Detector output CSV (for detection rate)")
    
    args = parser.parse_args()
    
    # Check OneDrive exists
    if not os.path.exists(ONEDRIVE_BASE):
        print(f"❌ OneDrive not found at: {ONEDRIVE_BASE}")
        print("   Make sure OneDrive is installed and syncing")
        sys.exit(1)
    
    if args.init:
        create_folder_structure()
    elif args.list:
        list_structure()
    elif args.city and args.input:
        sync_city_data(
            city=args.city,
            input_file=args.input,
            country=args.country,
            region=args.region,
            state=args.state,
            scraper_file=args.scraper,
            detector_file=args.detector
        )
    else:
        parser.print_help()


if __name__ == "__main__":
    main()

