# Sadie Lead Gen - Commands

## Setup

```bash
# Install python3 dependencies
pip install -r requirements.txt

# Install Playwright browser
playwright install chromium
```

## Environment

Create a `.env` file with your Google Places API key:

```
GOOGLE_PLACES_API_KEY=your_api_key_here
```

---

## Full Pipeline (Scrape + Detect)

### Miami (default)
```bash
python3 sadie_lead_gen.py
```

### Custom location (e.g., Los Angeles)
```bash
python3 sadie_lead_gen.py \
  --center-lat 34.0522 \
  --center-lng -118.2437 \
  --overall-radius-km 40
```

### Quick test (10 hotels, show browser)
```bash
python3 sadie_lead_gen.py --max-results 10 --headed
```

### Larger grid for dense areas
```bash
python3 sadie_lead_gen.py \
  --grid-rows 7 \
  --grid-cols 7 \
  --overall-radius-km 50
```

---

## Detection Only (Skip Scraping)

Use existing CSV instead of calling Google Places API (no billing required):

```bash
# Use manual hotel list
python3 sadie_lead_gen.py --skip-scrape --input hotels_manual.csv

# With browser visible for debugging
python3 sadie_lead_gen.py --skip-scrape --input hotels_manual.csv --headed

# Custom output file
python3 sadie_lead_gen.py --skip-scrape --input hotels_manual.csv --output my_leads.csv
```

### CSV Format (minimum required)

```csv
name,website
The Setai Miami Beach,https://www.thesetaihotel.com
Fontainebleau Miami Beach,https://www.fontainebleau.com
```

Optional columns (will be used if present): `latitude`, `longitude`, `phone`, `address`, `rating`, `review_count`, `place_id`

---

## Performance Tuning

```bash
# More parallel browsers (faster, but uses more RAM)
python3 sadie_lead_gen.py --concurrency 10

# Slower, more polite (fewer blocks/CAPTCHAs)
python3 sadie_lead_gen.py --concurrency 3 --pause 1.5

# Debug mode - see the browser
python3 sadie_lead_gen.py --headed --concurrency 1
```

---

## Output Files

| File | Description |
|------|-------------|
| `sadie_leads.csv` | Main output with all lead data |
| `screenshots/` | Booking page screenshots (evidence) |

---

## Common Locations

| City | Lat | Lng |
|------|-----|-----|
| Miami | 25.7617 | -80.1918 |
| Los Angeles | 34.0522 | -118.2437 |
| New York | 40.7128 | -74.0060 |
| Las Vegas | 36.1699 | -115.1398 |
| Orlando | 28.5383 | -81.3792 |
| San Francisco | 37.7749 | -122.4194 |
| Chicago | 41.8781 | -87.6298 |
| Austin | 30.2672 | -97.7431 |
| Denver | 39.7392 | -104.9903 |
| Seattle | 47.6062 | -122.3321 |

### Example: Austin with 30km radius
```bash
python3 sadie_lead_gen.py --center-lat 30.2672 --center-lng -97.7431 --overall-radius-km 30
```

---

## Legacy Scripts

The old separate scripts are still available:

```bash
# Hotel scraper only (Google Places)
python3 "hotel_scraper_beefed_up 1.py" --max-results 100

# Booking engine detector only
python3 booking_engine_detector_parallel.py --input hotels_filtered.csv --output results.csv
```

