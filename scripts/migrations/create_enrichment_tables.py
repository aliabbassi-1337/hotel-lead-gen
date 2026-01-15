#!/usr/bin/env python3
"""
Create Enrichment Tables Migration
==================================
Creates hotel_room_count and hotel_customer_proximity tables.

Usage:
    uv run python scripts/migrations/create_enrichment_tables.py
    uv run python scripts/migrations/create_enrichment_tables.py --dry-run
"""

import sys
from pathlib import Path

# Add project root to path for direct script execution
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

import asyncio
import argparse
from loguru import logger

from db.client import init_db, close_db, get_conn


CREATE_HOTEL_ROOM_COUNT = """
CREATE TABLE IF NOT EXISTS hotel_room_count (
    id SERIAL PRIMARY KEY,
    hotel_id INTEGER NOT NULL UNIQUE REFERENCES hotels(id) ON DELETE CASCADE,
    room_count INTEGER,
    source TEXT,
    confidence NUMERIC(3,2),
    status INTEGER DEFAULT 0,
    enriched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_hotel_room_count_hotel_id ON hotel_room_count(hotel_id);
CREATE INDEX IF NOT EXISTS idx_hotel_room_count_status ON hotel_room_count(status);
"""

CREATE_HOTEL_CUSTOMER_PROXIMITY = """
CREATE TABLE IF NOT EXISTS hotel_customer_proximity (
    id SERIAL PRIMARY KEY,
    hotel_id INTEGER NOT NULL UNIQUE REFERENCES hotels(id) ON DELETE CASCADE,
    existing_customer_id INTEGER NOT NULL REFERENCES existing_customers(id) ON DELETE CASCADE,
    distance_km NUMERIC(10,2) NOT NULL,
    computed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_hotel_customer_proximity_hotel_id ON hotel_customer_proximity(hotel_id);
CREATE INDEX IF NOT EXISTS idx_hotel_customer_proximity_customer_id ON hotel_customer_proximity(existing_customer_id);
CREATE INDEX IF NOT EXISTS idx_hotel_customer_proximity_distance ON hotel_customer_proximity(distance_km);
"""


async def run(dry_run: bool = False):
    """Create enrichment tables."""
    logger.info("Running create enrichment tables migration")

    await init_db()

    try:
        async with get_conn() as conn:
            # Set search path to include sadie_gtm schema
            await conn.execute('SET search_path TO sadie_gtm, public')

            # Check if hotel_room_count exists
            hrc_exists = await conn.fetchval("""
                SELECT EXISTS (
                    SELECT 1 FROM information_schema.tables
                    WHERE table_schema = 'sadie_gtm'
                      AND table_name = 'hotel_room_count'
                )
            """)

            if hrc_exists:
                logger.info("hotel_room_count table already exists")
            else:
                if dry_run:
                    logger.info("DRY RUN - would create hotel_room_count table")
                else:
                    await conn.execute(CREATE_HOTEL_ROOM_COUNT)
                    logger.info("Created hotel_room_count table")

            # Check if hotel_customer_proximity exists
            hcp_exists = await conn.fetchval("""
                SELECT EXISTS (
                    SELECT 1 FROM information_schema.tables
                    WHERE table_schema = 'sadie_gtm'
                      AND table_name = 'hotel_customer_proximity'
                )
            """)

            if hcp_exists:
                logger.info("hotel_customer_proximity table already exists")
            else:
                if dry_run:
                    logger.info("DRY RUN - would create hotel_customer_proximity table")
                else:
                    await conn.execute(CREATE_HOTEL_CUSTOMER_PROXIMITY)
                    logger.info("Created hotel_customer_proximity table")

        logger.info("=" * 60)
        logger.info("MIGRATION COMPLETE" if not dry_run else "DRY RUN COMPLETE")
        logger.info("=" * 60)

    finally:
        await close_db()


def main():
    parser = argparse.ArgumentParser(
        description="Create enrichment tables (hotel_room_count, hotel_customer_proximity)"
    )
    parser.add_argument(
        "--dry-run", "-n",
        action="store_true",
        help="Show what would be done without making changes"
    )

    args = parser.parse_args()
    asyncio.run(run(dry_run=args.dry_run))


if __name__ == "__main__":
    main()
