#!/usr/bin/env python3
"""
Add Enrichment Status Migration
===============================
Adds status column to hotel_room_count table for tracking enrichment state.

Usage:
    uv run python scripts/migrations/add_enrichment_status.py
    uv run python scripts/migrations/add_enrichment_status.py --dry-run

Status values:
    -1 = processing (claimed by worker)
     0 = failed
     1 = success
"""

import sys
from pathlib import Path

# Add project root to path for direct script execution
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

import asyncio
import argparse
from loguru import logger

from db.client import init_db, close_db, get_conn


async def run(dry_run: bool = False):
    """Add status column to hotel_room_count table."""
    logger.info("Running enrichment status migration")

    await init_db()

    try:
        async with get_conn() as conn:
            # Check if status column already exists
            exists = await conn.fetchval("""
                SELECT EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_name = 'hotel_room_count'
                      AND column_name = 'status'
                )
            """)

            if exists:
                logger.info("status column already exists in hotel_room_count")
            else:
                if dry_run:
                    logger.info("DRY RUN - would add status column to hotel_room_count")
                else:
                    # Add status column with default 0
                    await conn.execute("""
                        ALTER TABLE hotel_room_count
                        ADD COLUMN status INTEGER DEFAULT 0
                    """)
                    logger.info("Added status column to hotel_room_count")

                    # Set existing records to status=1 (they were successful)
                    result = await conn.execute("""
                        UPDATE hotel_room_count
                        SET status = 1
                        WHERE status = 0 OR status IS NULL
                    """)
                    logger.info(f"Updated existing records to status=1: {result}")

            # Check if room_count is nullable
            is_nullable = await conn.fetchval("""
                SELECT is_nullable FROM information_schema.columns
                WHERE table_name = 'hotel_room_count'
                  AND column_name = 'room_count'
            """)

            if is_nullable == 'YES':
                logger.info("room_count column is already nullable")
            else:
                if dry_run:
                    logger.info("DRY RUN - would make room_count column nullable")
                else:
                    await conn.execute("""
                        ALTER TABLE hotel_room_count
                        ALTER COLUMN room_count DROP NOT NULL
                    """)
                    logger.info("Made room_count column nullable")

        logger.info("=" * 60)
        logger.info("MIGRATION COMPLETE" if not dry_run else "DRY RUN COMPLETE")
        logger.info("=" * 60)

    finally:
        await close_db()


def main():
    parser = argparse.ArgumentParser(
        description="Add status column to hotel_room_count table"
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
