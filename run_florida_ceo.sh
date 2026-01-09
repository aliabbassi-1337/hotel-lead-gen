#!/bin/bash
# Run city scraper for all 27 CEO Florida cities concurrently
# Usage: ./run_florida_ceo.sh

set -e

OUTPUT_DIR="scraper_output/florida_ceo"
mkdir -p "$OUTPUT_DIR"

echo "Starting scrapers for 27 CEO Florida cities..."
echo "Output: $OUTPUT_DIR"
echo ""

# All 27 CEO cities
CITIES=(
    orlando
    miami
    miami_beach
    fort_lauderdale
    tampa
    west_palm_beach
    key_west
    st_petersburg
    clearwater
    naples
    sarasota
    jacksonville
    st_augustine
    destin
    panama_city_beach
    fort_myers
    pensacola
    kissimmee
    cape_coral
    marco_island
    fort_walton_beach
    bradenton
    pompano_beach
    fernandina_beach
    clearwater_beach
    palm_coast
    flagler_beach
)

# Launch all scrapers in parallel
for city in "${CITIES[@]}"; do
    echo "Starting: $city"
    python3 scripts/scrapers/city.py --city "$city" --state FL --output "$OUTPUT_DIR" &
done

echo ""
echo "All ${#CITIES[@]} scrapers launched. Waiting for completion..."
wait

echo ""
echo "Done! Results in $OUTPUT_DIR"
ls -la "$OUTPUT_DIR"
