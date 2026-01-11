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
    # Alabama
    'birmingham_al': (33.52, -86.80),
    'montgomery_al': (32.37, -86.30),
    'mobile_al': (30.69, -88.04),
    'huntsville_al': (34.73, -86.59),
    'tuscaloosa_al': (33.21, -87.57),
    'gulf_shores_al': (30.25, -87.70),
    'orange_beach_al': (30.29, -87.57),

    # Alaska
    'anchorage_ak': (61.22, -149.90),
    'fairbanks_ak': (64.84, -147.72),
    'juneau_ak': (58.30, -134.42),

    # Arizona
    'phoenix_az': (33.45, -112.07),
    'tucson_az': (32.22, -110.93),
    'scottsdale_az': (33.49, -111.93),
    'sedona_az': (34.87, -111.76),
    'flagstaff_az': (35.20, -111.65),
    'mesa_az': (33.42, -111.83),
    'tempe_az': (33.43, -111.94),
    'grand_canyon_az': (36.05, -112.14),

    # Arkansas
    'little_rock_ar': (34.75, -92.29),
    'hot_springs_ar': (34.50, -93.05),
    'fayetteville_ar': (36.08, -94.17),
    'eureka_springs_ar': (36.40, -93.74),

    # California
    'los_angeles_ca': (34.05, -118.24),
    'san_francisco_ca': (37.77, -122.42),
    'san_diego_ca': (32.72, -117.16),
    'sacramento_ca': (38.58, -121.49),
    'san_jose_ca': (37.34, -121.89),
    'oakland_ca': (37.80, -122.27),
    'santa_monica_ca': (34.02, -118.49),
    'beverly_hills_ca': (34.07, -118.40),
    'hollywood_ca': (34.09, -118.33),
    'long_beach_ca': (33.77, -118.19),
    'anaheim_ca': (33.84, -117.91),
    'santa_barbara_ca': (34.42, -119.70),
    'palm_springs_ca': (33.83, -116.55),
    'napa_ca': (38.30, -122.29),
    'monterey_ca': (36.60, -121.89),
    'carmel_ca': (36.56, -121.92),
    'big_sur_ca': (36.27, -121.81),
    'lake_tahoe_ca': (39.10, -120.04),
    'yosemite_ca': (37.87, -119.54),
    'santa_cruz_ca': (36.97, -122.03),
    'pasadena_ca': (34.15, -118.14),
    'laguna_beach_ca': (33.54, -117.78),
    'newport_beach_ca': (33.62, -117.93),
    'huntington_beach_ca': (33.66, -118.00),
    'malibu_ca': (34.03, -118.68),
    'fresno_ca': (36.74, -119.79),
    'bakersfield_ca': (35.37, -119.02),
    'redding_ca': (40.59, -122.39),
    'eureka_ca': (40.80, -124.16),

    # Colorado
    'denver_co': (39.74, -104.99),
    'colorado_springs_co': (38.83, -104.82),
    'boulder_co': (40.01, -105.27),
    'aspen_co': (39.19, -106.82),
    'vail_co': (39.64, -106.37),
    'breckenridge_co': (39.48, -106.04),
    'steamboat_springs_co': (40.48, -106.83),
    'telluride_co': (37.94, -107.81),
    'durango_co': (37.28, -107.88),
    'estes_park_co': (40.38, -105.52),
    'fort_collins_co': (40.59, -105.08),

    # Connecticut
    'hartford_ct': (41.76, -72.69),
    'new_haven_ct': (41.31, -72.92),
    'stamford_ct': (41.05, -73.54),
    'mystic_ct': (41.35, -71.97),
    'greenwich_ct': (41.03, -73.63),

    # Delaware
    'wilmington_de': (39.74, -75.55),
    'dover_de': (39.16, -75.52),
    'rehoboth_beach_de': (38.72, -75.08),
    'lewes_de': (38.77, -75.14),
    'dewey_beach_de': (38.69, -75.07),

    # Georgia
    'atlanta_ga': (33.75, -84.39),
    'savannah_ga': (32.08, -81.09),
    'augusta_ga': (33.47, -81.97),
    'athens_ga': (33.96, -83.38),
    'macon_ga': (32.84, -83.63),
    'columbus_ga': (32.46, -84.99),
    'jekyll_island_ga': (31.07, -81.42),
    'st_simons_island_ga': (31.15, -81.37),
    'tybee_island_ga': (32.00, -80.85),
    'blue_ridge_ga': (34.86, -84.32),
    'ellijay_ga': (34.69, -84.48),
    'clayton_ga': (34.88, -83.40),
    'helen_ga': (34.70, -83.73),

    # Hawaii
    'honolulu_hi': (21.31, -157.86),
    'waikiki_hi': (21.28, -157.83),
    'maui_hi': (20.80, -156.32),
    'kauai_hi': (22.09, -159.53),
    'kona_hi': (19.64, -155.99),
    'hilo_hi': (19.73, -155.09),
    'lahaina_hi': (20.88, -156.68),
    'wailea_hi': (20.69, -156.44),

    # Idaho
    'boise_id': (43.62, -116.21),
    'sun_valley_id': (43.70, -114.35),
    'coeur_dalene_id': (47.68, -116.78),
    'idaho_falls_id': (43.49, -112.04),
    'mccall_id': (44.91, -116.10),

    # Illinois
    'chicago_il': (41.88, -87.63),
    'springfield_il': (39.80, -89.64),
    'naperville_il': (41.79, -88.15),
    'evanston_il': (42.04, -87.69),
    'oak_brook_il': (41.83, -87.93),
    'schaumburg_il': (42.03, -88.08),
    'galena_il': (42.42, -90.43),

    # Indiana
    'indianapolis_in': (39.77, -86.16),
    'fort_wayne_in': (41.08, -85.14),
    'bloomington_in': (39.17, -86.53),
    'south_bend_in': (41.68, -86.25),
    'carmel_in': (39.98, -86.13),

    # Iowa
    'des_moines_ia': (41.59, -93.62),
    'cedar_rapids_ia': (41.98, -91.67),
    'iowa_city_ia': (41.66, -91.53),
    'davenport_ia': (41.52, -90.58),

    # Kansas
    'kansas_city_ks': (39.11, -94.63),
    'wichita_ks': (37.69, -97.34),
    'topeka_ks': (39.05, -95.68),
    'overland_park_ks': (38.98, -94.67),

    # Kentucky
    'louisville_ky': (38.25, -85.76),
    'lexington_ky': (38.04, -84.50),
    'bowling_green_ky': (36.99, -86.44),
    'covington_ky': (39.08, -84.51),

    # Louisiana
    'new_orleans_la': (29.95, -90.07),
    'baton_rouge_la': (30.45, -91.15),
    'shreveport_la': (32.53, -93.75),
    'lafayette_la': (30.22, -92.02),
    'lake_charles_la': (30.23, -93.22),

    # Maine
    'portland_me': (43.66, -70.26),
    'bar_harbor_me': (44.39, -68.20),
    'kennebunkport_me': (43.36, -70.48),
    'ogunquit_me': (43.25, -70.60),
    'camden_me': (44.21, -69.06),
    'bangor_me': (44.80, -68.78),
    'acadia_me': (44.35, -68.21),

    # Maryland
    'baltimore_md': (39.29, -76.61),
    'annapolis_md': (38.98, -76.49),
    'ocean_city_md': (38.34, -75.08),
    'bethesda_md': (38.98, -77.10),
    'rockville_md': (39.08, -77.15),

    # Massachusetts
    'boston_ma': (42.36, -71.06),
    'cambridge_ma': (42.37, -71.11),
    'salem_ma': (42.52, -70.90),
    'cape_cod_ma': (41.67, -70.30),
    'provincetown_ma': (42.05, -70.19),
    'marthas_vineyard_ma': (41.39, -70.64),
    'nantucket_ma': (41.28, -70.10),
    'plymouth_ma': (41.96, -70.67),
    'worcester_ma': (42.26, -71.80),
    'springfield_ma': (42.10, -72.59),

    # Michigan
    'detroit_mi': (42.33, -83.05),
    'ann_arbor_mi': (42.28, -83.74),
    'grand_rapids_mi': (42.96, -85.66),
    'traverse_city_mi': (44.76, -85.62),
    'mackinac_island_mi': (45.85, -84.62),
    'holland_mi': (42.79, -86.11),
    'saugatuck_mi': (42.65, -86.20),

    # Minnesota
    'minneapolis_mn': (44.98, -93.27),
    'st_paul_mn': (44.95, -93.09),
    'duluth_mn': (46.79, -92.10),
    'rochester_mn': (44.02, -92.47),
    'bloomington_mn': (44.84, -93.30),

    # Mississippi
    'jackson_ms': (32.30, -90.18),
    'biloxi_ms': (30.40, -88.89),
    'gulfport_ms': (30.37, -89.09),
    'natchez_ms': (31.56, -91.40),
    'oxford_ms': (34.37, -89.52),

    # Missouri
    'st_louis_mo': (38.63, -90.20),
    'kansas_city_mo': (39.10, -94.58),
    'springfield_mo': (37.22, -93.29),
    'branson_mo': (36.64, -93.22),
    'columbia_mo': (38.95, -92.33),

    # Montana
    'billings_mt': (45.78, -108.50),
    'missoula_mt': (46.87, -114.00),
    'bozeman_mt': (45.68, -111.04),
    'whitefish_mt': (48.41, -114.34),
    'big_sky_mt': (45.26, -111.40),
    'glacier_mt': (48.76, -113.79),

    # Nebraska
    'omaha_ne': (41.26, -95.93),
    'lincoln_ne': (40.81, -96.68),

    # Nevada
    'las_vegas_nv': (36.17, -115.14),
    'reno_nv': (39.53, -119.81),
    'henderson_nv': (36.04, -114.98),
    'lake_tahoe_nv': (39.10, -119.93),

    # New Hampshire
    'manchester_nh': (42.99, -71.46),
    'portsmouth_nh': (43.07, -70.76),
    'concord_nh': (43.21, -71.54),
    'north_conway_nh': (44.05, -71.13),
    'lincoln_nh': (44.05, -71.67),
    'jackson_nh': (44.15, -71.18),
    'bretton_woods_nh': (44.26, -71.44),

    # New Jersey
    'newark_nj': (40.74, -74.17),
    'jersey_city_nj': (40.73, -74.04),
    'atlantic_city_nj': (39.36, -74.42),
    'cape_may_nj': (38.94, -74.91),
    'hoboken_nj': (40.74, -74.03),
    'princeton_nj': (40.35, -74.66),
    'asbury_park_nj': (40.22, -74.01),

    # New Mexico
    'albuquerque_nm': (35.08, -106.65),
    'santa_fe_nm': (35.69, -105.94),
    'taos_nm': (36.41, -105.57),
    'las_cruces_nm': (32.35, -106.76),

    # New York
    'new_york_ny': (40.71, -74.01),
    'manhattan_ny': (40.78, -73.97),
    'brooklyn_ny': (40.65, -73.95),
    'buffalo_ny': (42.89, -78.88),
    'albany_ny': (42.65, -73.75),
    'rochester_ny': (43.16, -77.61),
    'syracuse_ny': (43.05, -76.15),
    'long_island_ny': (40.79, -73.13),
    'hamptons_ny': (40.94, -72.31),
    'lake_placid_ny': (44.28, -73.99),
    'saratoga_springs_ny': (43.08, -73.78),
    'niagara_falls_ny': (43.09, -79.06),
    'ithaca_ny': (42.44, -76.50),
    'catskills_ny': (42.04, -74.36),

    # North Carolina
    'charlotte_nc': (35.23, -80.84),
    'raleigh_nc': (35.78, -78.64),
    'asheville_nc': (35.60, -82.55),
    'wilmington_nc': (34.23, -77.94),
    'durham_nc': (35.99, -78.90),
    'greensboro_nc': (36.07, -79.79),
    'outer_banks_nc': (35.56, -75.47),
    'boone_nc': (36.22, -81.67),
    'blowing_rock_nc': (36.13, -81.68),
    'banner_elk_nc': (36.16, -81.87),
    'bryson_city_nc': (35.43, -83.45),
    'cherokee_nc': (35.47, -83.31),

    # North Dakota
    'fargo_nd': (46.88, -96.79),
    'bismarck_nd': (46.81, -100.78),

    # Ohio
    'columbus_oh': (39.96, -83.00),
    'cleveland_oh': (41.50, -81.69),
    'cincinnati_oh': (39.10, -84.51),
    'toledo_oh': (41.65, -83.54),
    'akron_oh': (41.08, -81.52),
    'dayton_oh': (39.76, -84.19),

    # Oklahoma
    'oklahoma_city_ok': (35.47, -97.52),
    'tulsa_ok': (36.15, -95.99),
    'norman_ok': (35.22, -97.44),

    # Oregon
    'portland_or': (45.52, -122.68),
    'eugene_or': (44.05, -123.09),
    'salem_or': (44.94, -123.04),
    'bend_or': (44.06, -121.31),
    'ashland_or': (42.19, -122.71),
    'astoria_or': (46.19, -123.83),
    'cannon_beach_or': (45.89, -123.96),
    'hood_river_or': (45.71, -121.51),

    # Pennsylvania
    'philadelphia_pa': (39.95, -75.17),
    'pittsburgh_pa': (40.44, -79.99),
    'harrisburg_pa': (40.27, -76.88),
    'lancaster_pa': (40.04, -76.31),
    'gettysburg_pa': (39.83, -77.23),
    'hershey_pa': (40.29, -76.65),
    'poconos_pa': (41.10, -75.35),

    # Rhode Island
    'providence_ri': (41.82, -71.41),
    'newport_ri': (41.49, -71.31),
    'warwick_ri': (41.70, -71.42),

    # South Carolina
    'charleston_sc': (32.78, -79.93),
    'myrtle_beach_sc': (33.69, -78.89),
    'columbia_sc': (34.00, -81.03),
    'hilton_head_sc': (32.22, -80.75),
    'greenville_sc': (34.85, -82.40),
    'kiawah_island_sc': (32.61, -80.08),

    # South Dakota
    'sioux_falls_sd': (43.55, -96.70),
    'rapid_city_sd': (44.08, -103.23),
    'deadwood_sd': (44.38, -103.73),

    # Tennessee
    'nashville_tn': (36.16, -86.78),
    'memphis_tn': (35.15, -90.05),
    'knoxville_tn': (35.96, -83.92),
    'chattanooga_tn': (35.05, -85.31),
    'gatlinburg_tn': (35.71, -83.51),
    'pigeon_forge_tn': (35.79, -83.55),
    'sevierville_tn': (35.87, -83.56),

    # Texas
    'houston_tx': (29.76, -95.37),
    'san_antonio_tx': (29.42, -98.49),
    'dallas_tx': (32.78, -96.80),
    'austin_tx': (30.27, -97.74),
    'fort_worth_tx': (32.76, -97.33),
    'el_paso_tx': (31.76, -106.49),
    'corpus_christi_tx': (27.80, -97.40),
    'galveston_tx': (29.30, -94.80),
    'south_padre_island_tx': (26.11, -97.17),
    'fredericksburg_tx': (30.28, -98.87),
    'san_marcos_tx': (29.88, -97.94),
    'plano_tx': (33.02, -96.70),

    # Utah
    'salt_lake_city_ut': (40.76, -111.89),
    'park_city_ut': (40.65, -111.50),
    'moab_ut': (38.57, -109.55),
    'st_george_ut': (37.10, -113.58),
    'provo_ut': (40.23, -111.66),

    # Vermont
    'burlington_vt': (44.48, -73.21),
    'stowe_vt': (44.47, -72.69),
    'killington_vt': (43.62, -72.80),
    'manchester_vt': (43.16, -73.07),
    'woodstock_vt': (43.62, -72.52),
    'montpelier_vt': (44.26, -72.58),

    # Virginia
    'virginia_beach_va': (36.85, -75.98),
    'richmond_va': (37.54, -77.44),
    'arlington_va': (38.88, -77.10),
    'alexandria_va': (38.80, -77.05),
    'norfolk_va': (36.85, -76.29),
    'williamsburg_va': (37.27, -76.71),
    'charlottesville_va': (38.03, -78.48),
    'roanoke_va': (37.27, -79.94),
    'shenandoah_va': (38.29, -78.68),

    # Washington
    'seattle_wa': (47.61, -122.33),
    'tacoma_wa': (47.25, -122.44),
    'spokane_wa': (47.66, -117.43),
    'bellevue_wa': (47.61, -122.20),
    'olympia_wa': (47.04, -122.90),
    'leavenworth_wa': (47.60, -120.66),
    'san_juan_islands_wa': (48.53, -123.02),

    # West Virginia
    'charleston_wv': (38.35, -81.63),
    'morgantown_wv': (39.63, -79.96),
    'harpers_ferry_wv': (39.33, -77.73),

    # Wisconsin
    'milwaukee_wi': (43.04, -87.91),
    'madison_wi': (43.07, -89.40),
    'green_bay_wi': (44.51, -88.02),
    'door_county_wi': (45.05, -87.15),
    'wisconsin_dells_wi': (43.63, -89.77),
    'lake_geneva_wi': (42.59, -88.43),

    # Wyoming
    'cheyenne_wy': (41.14, -104.82),
    'jackson_wy': (43.48, -110.76),
    'yellowstone_wy': (44.43, -110.59),
    'cody_wy': (44.53, -109.06),
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

def get_city_from_coords(lat, lng, cities: dict):
    """Determine which city a coordinate belongs to."""
    best_match = None
    min_dist = float('inf')
    for city, (clat, clng) in cities.items():
        dist = haversine_km(clat, clng, lat, lng)
        if dist < min_dist:
            min_dist = dist
            best_match = city
    return best_match

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

def split_by_city(input_file: str, output_dir: str = None):
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
                
                city = get_city_from_coords(lat, lng, cities)
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
    
    # Write separate files - append to existing *_leads.csv files in same directory
    print(f"\n  Split into {len(city_rows)} cities:")
    for city, city_data in sorted(city_rows.items(), key=lambda x: -len(x[1])):
        # Extract city name (remove state suffix like _fl)
        parts = city.rsplit('_', 1)
        if len(parts) == 2 and len(parts[1]) == 2:  # e.g., miami_beach_fl
            city_name = parts[0]  # miami_beach
        else:
            city_name = city

        # Look for existing {city}_leads.csv in same directory
        output_file = os.path.join(output_dir, f"{city_name}_leads.csv")

        # Check if file exists and read existing names to avoid duplicates
        existing_names = set()
        file_exists = os.path.exists(output_file)
        if file_exists:
            with open(output_file, 'r', newline='', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    name = (row.get('name') or '').lower().strip()
                    if name:
                        existing_names.add(name)

        # Filter out duplicates
        new_rows = []
        for row in city_data:
            name = (row.get('name') or '').lower().strip()
            if name and name not in existing_names:
                new_rows.append(row)
                existing_names.add(name)

        if not new_rows and file_exists:
            print(f"    {city}: 0 new (all {len(city_data)} already exist)")
            continue

        # Append to existing or create new
        mode = 'a' if file_exists else 'w'
        with open(output_file, mode, newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            if not file_exists:
                writer.writeheader()
            for row in new_rows:
                writer.writerow(row)

        if file_exists:
            print(f"    {city}: +{len(new_rows)} appended (skipped {len(city_data) - len(new_rows)} dupes) -> {output_file}")
        else:
            print(f"    {city}: {len(new_rows)} hotels -> {output_file}")

    return city_rows

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Usage: python3 sadie_split_by_city.py detector_output/sydney_leads.csv")
        sys.exit(1)
    
    split_by_city(sys.argv[1])
