# Sadie Lead Gen - Commands

## Setup

```bash
pip3 install -r requirements.txt
python3 -m playwright install chromium
```

## Scraper

```bash
# Miami (default)
python3 sadie_scraper.py

# Custom location
python3 sadie_scraper.py --center-lat 34.0522 --center-lng -118.2437 --overall-radius-km 40

# Limit results
python3 sadie_scraper.py --max-results 50
```

## Detector

```bash
# Basic
python3 sadie_detector.py --input hotels_manual.csv

# Debug mode (show browser + verbose logs)
python3 sadie_detector.py --input hotels_manual.csv --headed --concurrency 1 --debug

# Custom output
python3 sadie_detector.py --input hotels.csv --output my_leads.csv

# Faster
python3 sadie_detector.py --input hotels.csv --concurrency 10
```

## Full Workflow

```bash
# 1. Scrape hotels
python3 sadie_scraper.py --center-lat 38.3365 --center-lng -75.0849 --overall-radius-km 20 --output hotels.csv

# 2. Detect booking engines
python3 sadie_detector.py --input hotels.csv --output leads.csv
```
