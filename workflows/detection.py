"""Detection workflow - Fetch hotels and detect their booking engines."""

import asyncio
from loguru import logger

from db.client import init_db, close_db
from services.leadgen.service import Service
from services.leadgen.detector import DetectionConfig


async def detection_workflow(limit: int = 100, debug: bool = False):
    """
    Fetch pending hotels and run booking engine detection.

    Args:
        limit: Max hotels to process in this run
        debug: Enable debug logging
    """
    config = DetectionConfig(
        concurrency=5,
        headless=True,
        debug=debug,
    )
    service = Service(detection_config=config)

    # Get pending hotels
    hotels = await service.get_hotels_pending_detection(limit=limit)
    logger.info(f"Found {len(hotels)} hotels pending detection")

    if not hotels:
        logger.info("No hotels to process")
        return

    # Run detection
    results = await service.detect_booking_engines(limit=limit)

    # Summary
    detected = sum(1 for r in results if r.booking_engine and r.booking_engine not in ("", "unknown"))
    errors = sum(1 for r in results if r.error)
    no_engine = len(results) - detected - errors

    logger.info("=" * 60)
    logger.info("DETECTION COMPLETE")
    logger.info("=" * 60)
    logger.info(f"Hotels processed:    {len(results)}")
    logger.info(f"Engines detected:    {detected}")
    logger.info(f"No engine found:     {no_engine}")
    logger.info(f"Errors:              {errors}")
    logger.info(f"Hit rate:            {detected / len(results) * 100:.1f}%")
    logger.info("=" * 60)


async def run(limit: int = 100, debug: bool = False):
    """Initialize DB and run workflow."""
    await init_db()
    try:
        await detection_workflow(limit=limit, debug=debug)
    finally:
        await close_db()


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Run booking engine detection workflow")
    parser.add_argument("--limit", type=int, default=100, help="Max hotels to process")
    parser.add_argument("--debug", action="store_true", help="Enable debug logging")
    args = parser.parse_args()

    asyncio.run(run(limit=args.limit, debug=args.debug))
