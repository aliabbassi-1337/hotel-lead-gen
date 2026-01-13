"""
Workflow: Scrape Region
=======================
Scrapes hotels in a given region using the adaptive grid scraper.

Usage:
    uv run python workflows/scrape_region.py --center-lat 25.7907 --center-lng -80.1300 --radius-km 3
    uv run python workflows/scrape_region.py --state florida
"""

import asyncio
import argparse
import logging

from db.client import init_db, close_db
from services.leadgen.service import Service

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s - %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger(__name__)


async def scrape_region_workflow(
    center_lat: float,
    center_lng: float,
    radius_km: float,
) -> int:
    """Scrape hotels in a circular region."""
    await init_db()

    try:
        service = Service()
        count = await service.scrape_region(center_lat, center_lng, radius_km)
        logger.info(f"Scrape complete: {count} hotels saved to database")
        return count
    finally:
        await close_db()


async def scrape_state_workflow(state: str) -> int:
    """Scrape hotels in a state."""
    await init_db()

    try:
        service = Service()
        count = await service.scrape_state(state)
        logger.info(f"Scrape complete: {count} hotels saved to database")
        return count
    finally:
        await close_db()


def main():
    parser = argparse.ArgumentParser(description="Scrape hotels in a region")

    # Region by center + radius
    parser.add_argument("--center-lat", type=float, help="Center latitude")
    parser.add_argument("--center-lng", type=float, help="Center longitude")
    parser.add_argument("--radius-km", type=float, default=5, help="Radius in km (default: 5)")

    # Or by state
    parser.add_argument("--state", type=str, help="State name (e.g., florida)")

    args = parser.parse_args()

    if args.state:
        asyncio.run(scrape_state_workflow(args.state))
    elif args.center_lat and args.center_lng:
        asyncio.run(scrape_region_workflow(args.center_lat, args.center_lng, args.radius_km))
    else:
        parser.error("Provide --state OR --center-lat and --center-lng")


if __name__ == "__main__":
    main()
