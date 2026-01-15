<p align="center">
  <img src="graphics/sadie-gtm-logo.svg" width="300" alt="Sadie GTM Logo">
</p>

# Sadie GTM Pipeline

Automated lead generation pipeline for hotel booking engine detection at scale.

## Pipeline Overview

```
Scrape → Enqueue → Detect (EC2) → Enrich (EC2) → Launch (EC2) → Export
```

**Status values:**
- `-2` = location_mismatch (rejected)
- `-1` = no_booking_engine (rejected)
- `0` = pending (in pipeline)
- `1` = launched (live lead)

**Services:**
- **leadgen** - Scrape hotels + detect booking engines
- **enrichment** - Add room counts + customer proximity
- **reporting** - Excel exports to S3
- **launcher** - Mark fully enriched hotels as live

## Quick Start

### Start Pipeline (local)
```bash
# Scrape a region and enqueue for detection
./scripts/start_pipeline.sh "Miami Beach" "Florida" "USA"

# Or scrape an entire state
./scripts/start_pipeline.sh "Florida" "USA"
```

### Process on EC2
Start your EC2 instances - they auto-run detection, enrichment, and launcher via systemd/cron.

### Finish Pipeline (local)
```bash
# Check status
uv run python workflows/launcher.py status

# Launch + export
./scripts/finish_pipeline.sh "Florida" "USA"
```

## Local Development

### Prerequisites

- Python 3.12+
- Docker (for PostgreSQL + PostGIS)
- [uv](https://github.com/astral-sh/uv) package manager

### Setup

```bash
# Start local database
docker compose up -d

# Apply schema
docker exec -i sadie-gtm-local-db psql -U sadie -d sadie_gtm < db/schema.sql

# Install dependencies
uv sync

# Install Playwright browsers
uv run playwright install chromium
```

### Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Database
SADIE_DB_HOST=localhost
SADIE_DB_PORT=5432
SADIE_DB_NAME=sadie_gtm
SADIE_DB_USER=sadie
SADIE_DB_PASSWORD=sadie_dev_password

# APIs
SERPER_API_KEY=your_serper_api_key
GOOGLE_PLACES_API_KEY=your_google_api_key

# AWS (for SQS)
SQS_DETECTION_QUEUE_URL=https://sqs.eu-north-1.amazonaws.com/xxx/detection-queue
AWS_REGION=eu-north-1
```

### Run Tests

```bash
uv run pytest -v

# Skip integration tests (no network)
uv run pytest -v -m "not integration"
```

## Workflows

See [workflows.yaml](workflows.yaml) for full configuration.

### Local Workflows
| Workflow | Command |
|----------|---------|
| Scrape region | `uv run python workflows/scrape_region.py "Florida" "USA"` |
| Enqueue detection | `uv run python workflows/enqueue_detection.py --limit 500` |
| Check status | `uv run python workflows/launcher.py status` |
| Export leads | `uv run python workflows/export.py --state Florida --country USA` |

### EC2 Workflows (auto-start on boot)
| Workflow | Schedule | Type |
|----------|----------|------|
| detection_consumer | continuous | systemd |
| enrichment_room_counts | every 10 min | cron |
| enrichment_proximity | every 5 min | cron |
| launcher | every 5 min | cron |

## Architecture

```
services/
├── leadgen/           # Scraping + detection
│   ├── service.py     # Business logic
│   ├── repo.py        # Database access
│   ├── grid_scraper.py
│   └── detector.py
├── enrichment/        # Room counts + proximity
├── reporting/         # Excel exports to S3
└── launcher/          # Mark hotels as live

workflows/             # CLI entry points
├── scrape_region.py
├── enqueue_detection.py
├── detection_consumer.py
├── enrichment.py
├── launcher.py
└── export.py

db/
├── schema.sql         # Database schema
├── migrations/        # Schema migrations
├── queries/           # SQL queries (aiosql)
└── models/            # Pydantic models

scripts/
├── start_pipeline.sh  # Scrape + enqueue
└── finish_pipeline.sh # Launch + export
```

See [context/CODING_GUIDE.md](context/CODING_GUIDE.md) for development patterns.
