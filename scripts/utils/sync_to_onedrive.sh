#!/bin/bash
# Sync all lead files to OneDrive
# Usage: ./sync_to_onedrive.sh

set -e
cd "$(dirname "$0")"

echo "========================================"
echo "  SYNCING LEADS TO ONEDRIVE"
echo "========================================"
echo ""

# Gatlinburg
if [ -f "detector_output/gatlinburg_leads_post.csv" ]; then
    echo "📁 Syncing Gatlinburg..."
    python3 sadie_onedrive_sync.py \
        --city gatlinburg \
        --input detector_output/gatlinburg_leads_post.csv \
        --scraper scraper_output/gatlinburg_hotels.csv \
        --detector detector_output/gatlinburg_leads.csv
    echo ""
fi

# Ocean City
if [ -f "detector_output/ocean_city_leads_post.csv" ]; then
    echo "📁 Syncing Ocean City..."
    python3 sadie_onedrive_sync.py \
        --city ocean_city \
        --input detector_output/ocean_city_leads_post.csv \
        --scraper scraper_output/ocean_city_hotels.csv \
        --detector detector_output/ocean_city_leads.csv
    echo ""
fi

# Sydney
if [ -f "detector_output/sydney_leads_post.csv" ]; then
    echo "📁 Syncing Sydney..."
    python3 sadie_onedrive_sync.py \
        --city sydney \
        --input detector_output/sydney_leads_post.csv \
        --scraper scraper_output/sydney_final.csv \
        --detector detector_output/sydney_leads.csv
    echo ""
fi

# Miami
if [ -f "detector_output/miami_leads_post.csv" ]; then
    echo "📁 Syncing Miami..."
    python3 sadie_onedrive_sync.py \
        --city miami \
        --input detector_output/miami_leads_post.csv \
        --scraper scraper_output/florida_miami_hotels_1.csv \
        --detector detector_output/miami_leads.csv
    echo ""
fi

echo "========================================"
echo "  ✅ SYNC COMPLETE"
echo "========================================"
echo ""
echo "View folder structure:"
python3 sadie_onedrive_sync.py --list

