#!/usr/bin/env python3
"""
Split detector output by actual city location.
Groups hotels by nearest city based on coordinates.
"""

import csv
import math
import os
from datetime import datetime

# City centers for classification (lat, lng)
# USA Cities
USA_CITIES = {
    # Tennessee
    'gatlinburg_tn': (35.71, -83.51),
    'pigeon_forge_tn': (35.79, -83.55),
    'sevierville_tn': (35.87, -83.56),
    'knoxville_tn': (35.96, -83.92),
    # North Carolina
    'asheville_nc': (35.60, -82.55),
    'bryson_city_nc': (35.43, -83.45),
    'cherokee_nc': (35.47, -83.31),
    # South Carolina
    'greenville_sc': (34.85, -82.40),
    # Georgia
    'blue_ridge_ga': (34.86, -84.32),
    'ellijay_ga': (34.69, -84.48),
    'clayton_ga': (34.88, -83.40),
    'helen_ga': (34.70, -83.73),
    # Maryland
    'ocean_city_md': (38.34, -75.08),
    # Florida
    'miami_fl': (25.76, -80.19),
    'miami_beach_fl': (25.79, -80.13),
    'fort_lauderdale_fl': (26.12, -80.14),
    'west_palm_beach_fl': (26.71, -80.05),
    'boca_raton_fl': (26.36, -80.08),
    'key_west_fl': (24.56, -81.78),
    'key_largo_fl': (25.09, -80.45),
    'islamorada_fl': (24.92, -80.63),
    'marathon_fl': (24.71, -81.09),
    'naples_fl': (26.14, -81.79),
    'marco_island_fl': (25.94, -81.72),
    'fort_myers_fl': (26.64, -81.87),
    'fort_myers_beach_fl': (26.45, -81.95),
    'sanibel_fl': (26.44, -82.10),
    'captiva_fl': (26.53, -82.19),
    'sarasota_fl': (27.34, -82.53),
    'siesta_key_fl': (27.27, -82.55),
    'clearwater_fl': (27.97, -82.80),
    'clearwater_beach_fl': (27.98, -82.83),
    'st_petersburg_fl': (27.77, -82.64),
    'tampa_fl': (27.95, -82.46),
    'orlando_fl': (28.54, -81.38),
    'kissimmee_fl': (28.29, -81.41),
    'daytona_beach_fl': (29.21, -81.02),
    'st_augustine_fl': (29.90, -81.31),
    'jacksonville_fl': (30.33, -81.66),
    'jacksonville_beach_fl': (30.29, -81.39),
    'amelia_island_fl': (30.67, -81.44),
    'fernandina_beach_fl': (30.67, -81.44),
    'pensacola_fl': (30.42, -87.22),
    'pensacola_beach_fl': (30.33, -87.14),
    'destin_fl': (30.39, -86.50),
    'panama_city_beach_fl': (30.18, -85.80),
    'tallahassee_fl': (30.44, -84.28),
    'gainesville_fl': (29.65, -82.32),
    'cocoa_beach_fl': (28.32, -80.61),
    'melbourne_fl': (28.08, -80.61),
    'vero_beach_fl': (27.64, -80.40),
    'palm_beach_fl': (26.71, -80.04),
    'delray_beach_fl': (26.46, -80.07),
    'hollywood_fl': (26.01, -80.15),
    'aventura_fl': (25.96, -80.14),
    'sunny_isles_fl': (25.95, -80.12),
    'deerfield_beach_fl': (26.32, -80.10),
    'pompano_beach_fl': (26.24, -80.13),
    'lauderdale_by_the_sea_fl': (26.19, -80.10),
    # Additional top Florida cities
    'cape_coral_fl': (26.56, -81.95),
    'fort_walton_beach_fl': (30.42, -86.62),
    'bradenton_fl': (27.50, -82.57),
    'bradenton_beach_fl': (27.47, -82.70),
    'palm_coast_fl': (29.58, -81.21),
    'flagler_beach_fl': (29.47, -81.13),
    'anna_maria_island_fl': (27.53, -82.73),
    'longboat_key_fl': (27.41, -82.66),
    'treasure_island_fl': (27.77, -82.77),
    'madeira_beach_fl': (27.80, -82.80),
    'indian_rocks_beach_fl': (27.88, -82.85),
    'new_smyrna_beach_fl': (29.03, -80.93),
    'ormond_beach_fl': (29.29, -81.06),
    'lake_buena_vista_fl': (28.37, -81.52),
    'celebration_fl': (28.32, -81.54),
    'winter_park_fl': (28.60, -81.34),
    # Panhandle and other FL areas
    'apalachicola_fl': (29.73, -84.98),
    'st_george_island_fl': (29.66, -84.86),
    'sebring_fl': (27.50, -81.44),
    'lake_placid_fl': (27.29, -81.36),
    'port_st_joe_fl': (29.81, -85.30),
    'mexico_beach_fl': (29.95, -85.42),
    'cedar_key_fl': (29.14, -83.04),
    'crystal_river_fl': (28.90, -82.59),
    'homosassa_fl': (28.78, -82.62),
    'tarpon_springs_fl': (28.15, -82.76),
    'dunedin_fl': (28.02, -82.77),
    'port_charlotte_fl': (26.97, -82.09),
    'punta_gorda_fl': (26.93, -82.05),
    'englewood_fl': (26.96, -82.35),
    'venice_fl': (27.10, -82.45),
    'port_st_lucie_fl': (27.29, -80.35),
    'stuart_fl': (27.20, -80.25),
    'jupiter_fl': (26.93, -80.09),
    'hobe_sound_fl': (27.06, -80.14),
    'lake_worth_fl': (26.62, -80.06),
    'lantana_fl': (26.59, -80.05),
    'boynton_beach_fl': (26.53, -80.07),
    'hallandale_fl': (25.98, -80.15),
    'dania_beach_fl': (26.05, -80.14),
    'homestead_fl': (25.47, -80.48),
    'florida_city_fl': (25.45, -80.48),
}

# Australia Cities
AUSTRALIA_CITIES = {
    'sydney': (-33.87, 151.21),
    'melbourne': (-37.81, 144.96),
    'brisbane': (-27.47, 153.03),
    'gold_coast': (-28.02, 153.43),
    'perth': (-31.95, 115.86),
    'adelaide': (-34.93, 138.60),
    'canberra': (-35.28, 149.13),
    'newcastle': (-32.93, 151.78),
    'wollongong': (-34.42, 150.89),
    'blue_mountains': (-33.72, 150.31),
    'central_coast': (-33.43, 151.34),
    'hunter_valley': (-32.79, 151.15),
    'byron_bay': (-28.64, 153.62),
    'cairns': (-16.92, 145.77),
    'hobart': (-42.88, 147.33),
    'darwin': (-12.46, 130.84),
    'sunshine_coast': (-26.65, 153.07),
    'coffs_harbour': (-30.30, 153.11),
    'port_macquarie': (-31.43, 152.91),
    'port_stephens': (-32.72, 152.11),
    'jervis_bay': (-35.04, 150.69),
    'south_coast_nsw': (-35.71, 150.18),
    'snowy_mountains': (-36.43, 148.39),
    'townsville': (-19.26, 146.82),
    'whitsundays': (-20.27, 148.72),
    'noosa': (-26.39, 153.09),
    'margaret_river': (-33.95, 115.08),
    'great_ocean_road': (-38.68, 143.39),
    'yarra_valley': (-37.75, 145.45),
    'mornington_peninsula': (-38.33, 145.03),
    'phillip_island': (-38.49, 145.23),
    'ballarat': (-37.56, 143.85),
    'bendigo': (-36.76, 144.28),
    'geelong': (-38.15, 144.36),
    'launceston': (-41.44, 147.14),
    'alice_springs': (-23.70, 133.88),
    'uluru': (-25.34, 131.04),
    'broome': (-17.96, 122.24),
    'port_douglas': (-16.48, 145.46),
    'mission_beach': (-17.87, 146.10),
    'hervey_bay': (-25.29, 152.85),
    'rockhampton': (-23.38, 150.51),
    'mackay': (-21.14, 149.19),
    'bundaberg': (-24.87, 152.35),
    'toowoomba': (-27.56, 151.95),
}

def haversine_km(lat1, lon1, lat2, lon2):
    R = 6371  # km
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
    return R * 2 * math.asin(math.sqrt(a))

def find_nearest_city(lat, lng, cities: dict, max_dist_km=150):
    """Find nearest city within max_dist_km."""
    nearest = None
    min_dist = float('inf')
    for city, (clat, clng) in cities.items():
        dist = haversine_km(clat, clng, lat, lng)
        if dist < min_dist:
            min_dist = dist
            nearest = city
    
    if min_dist > max_dist_km:
        return 'other', min_dist
    return nearest, min_dist

def detect_region(lat, lng) -> str:
    """Detect if coordinates are in USA or Australia."""
    if lat is None or lng is None:
        return 'unknown'
    # Australia: lat roughly -10 to -44, lng roughly 113 to 154
    if -45 < lat < -10 and 110 < lng < 160:
        return 'australia'
    # USA: lat roughly 24 to 50, lng roughly -125 to -66
    if 24 < lat < 50 and -130 < lng < -60:
        return 'usa'
    return 'unknown'

def split_by_city(input_file: str, output_dir: str = None, max_dist_km: int = 80):
    """Split a detector CSV by actual city location."""
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Splitting: {input_file}")

    # Default output dir to same directory as input file
    if output_dir is None:
        output_dir = os.path.dirname(input_file) or "detector_output"

    # Read all rows
    with open(input_file, 'r', newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        rows = list(reader)
    
    print(f"  Total rows: {len(rows)}")
    
    # Group by city
    city_rows = {}
    no_coords = []
    
    for r in rows:
        try:
            lat = float(r.get('latitude') or 0)
            lng = float(r.get('longitude') or r.get('long') or 0)
            if lat and lng:
                region = detect_region(lat, lng)
                if region == 'australia':
                    cities = AUSTRALIA_CITIES
                elif region == 'usa':
                    cities = USA_CITIES
                else:
                    no_coords.append(r)
                    continue
                
                city, dist = find_nearest_city(lat, lng, cities, max_dist_km)
                if city not in city_rows:
                    city_rows[city] = []
                city_rows[city].append(r)
            else:
                no_coords.append(r)
        except (ValueError, TypeError):
            no_coords.append(r)
    
    # Add no-coords to 'unknown' bucket
    if no_coords:
        city_rows['unknown'] = no_coords
    
    # Write separate files - organized by state/city
    print(f"\n  Split into {len(city_rows)} cities:")
    for city, city_data in sorted(city_rows.items(), key=lambda x: -len(x[1])):
        # Extract state suffix and create state-based folder structure
        parts = city.rsplit('_', 1)
        if len(parts) == 2 and len(parts[1]) == 2:  # e.g., miami_beach_fl
            city_name = parts[0]  # miami_beach
            state = parts[1]      # fl
            state_dir = os.path.join(output_dir, state.upper())
            os.makedirs(state_dir, exist_ok=True)
            output_file = os.path.join(state_dir, f"{city_name}.csv")
        else:
            # No state suffix (other, unknown, australia cities)
            output_file = os.path.join(output_dir, f"{city}.csv")

        with open(output_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            for row in city_data:
                writer.writerow(row)
        print(f"    {city}: {len(city_data)} hotels -> {output_file}")

    return city_rows

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Usage: python3 sadie_split_by_city.py detector_output/sydney_leads.csv")
        sys.exit(1)
    
    split_by_city(sys.argv[1])
