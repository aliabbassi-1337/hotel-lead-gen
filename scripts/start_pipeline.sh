#!/bin/bash
# Start Pipeline: Scrape a region and enqueue for detection
#
# Usage:
#   ./scripts/start_pipeline.sh "Miami Beach" "Florida" "USA"
#   ./scripts/start_pipeline.sh "Florida" "USA"        # Entire state
#   ./scripts/start_pipeline.sh "USA"                  # Entire country

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <city> <state> <country>"
    echo "       $0 <state> <country>"
    echo "       $0 <country>"
    echo ""
    echo "Examples:"
    echo "  $0 \"Miami Beach\" \"Florida\" \"USA\""
    echo "  $0 \"Florida\" \"USA\""
    exit 1
fi

cd "$(dirname "$0")/.."

echo "=== SCRAPING ==="
echo "Region: $@"
echo ""

uv run python workflows/scrape_region.py "$@"

echo ""
echo "=== ENQUEUEING ==="
echo ""

uv run python workflows/enqueue_detection.py --limit 1000

echo ""
echo "=== DONE ==="
echo "Hotels scraped and enqueued to SQS."
echo "Start your EC2 instances to begin processing."
echo ""
echo "Check progress with: uv run python workflows/launcher.py status"
