"""Detection workflow - Fetch hotels and detect their booking engines.

Configurable for different RAM sizes:
- 8GB RAM:  --preset small  (3 concurrent, batch 50)
- 12GB RAM: --preset medium (5 concurrent, batch 100)
- 16GB RAM: --preset large  (8 concurrent, batch 200)

Or tune manually:
  --concurrency 5 --batch-size 100 --contexts 3
"""

import asyncio
from typing import List
from loguru import logger

from db.client import init_db, close_db
from services.leadgen.service import Service
from services.leadgen.detector import DetectionConfig, DetectionResult


# RAM-based presets
# Each Chromium context uses ~150-300MB, each page ~50-100MB additional
PRESETS = {
    "small": {      # 8GB RAM
        "concurrency": 3,
        "batch_size": 50,
        "max_contexts": 3,
        "description": "8GB RAM - conservative",
    },
    "medium": {     # 12GB RAM
        "concurrency": 5,
        "batch_size": 100,
        "max_contexts": 5,
        "description": "12GB RAM - balanced",
    },
    "large": {      # 16GB+ RAM
        "concurrency": 8,
        "batch_size": 200,
        "max_contexts": 8,
        "description": "16GB RAM - aggressive",
    },
    "xlarge": {     # 32GB+ RAM
        "concurrency": 12,
        "batch_size": 500,
        "max_contexts": 12,
        "description": "32GB RAM - maximum throughput",
    },
}


async def run_detection_batch(
    service: Service,
    hotels: List,
    concurrency: int,
    debug: bool,
) -> List[DetectionResult]:
    """Run detection on a batch of hotels."""
    if not hotels:
        return []

    # Convert to dicts for detector
    hotel_dicts = [
        {"id": h.id, "name": h.name, "website": h.website}
        for h in hotels
    ]

    # Create detector with config
    from services.leadgen.detector import BatchDetector

    config = DetectionConfig(
        concurrency=concurrency,
        headless=True,
        debug=debug,
    )

    detector = BatchDetector(config)
    results = await detector.detect_batch(hotel_dicts)

    # Save results to database
    for result in results:
        await service._save_detection_result(result)

    return results


async def detection_workflow(
    limit: int = 100,
    concurrency: int = 5,
    batch_size: int = 100,
    debug: bool = False,
):
    """
    Fetch pending hotels and run booking engine detection.

    Args:
        limit: Total max hotels to process
        concurrency: Parallel browser contexts
        batch_size: Hotels per batch (controls memory)
        debug: Enable debug logging
    """
    service = Service()

    # Get all pending hotels up to limit
    all_hotels = await service.get_hotels_pending_detection(limit=limit)
    total_hotels = len(all_hotels)

    if not all_hotels:
        logger.info("No hotels pending detection")
        return

    logger.info(f"Found {total_hotels} hotels pending detection")
    logger.info(f"Config: concurrency={concurrency}, batch_size={batch_size}")

    # Process in batches to control memory
    all_results = []
    batch_num = 0

    for i in range(0, total_hotels, batch_size):
        batch_num += 1
        batch = all_hotels[i:i + batch_size]
        logger.info(f"Processing batch {batch_num}: {len(batch)} hotels (total: {i + len(batch)}/{total_hotels})")

        results = await run_detection_batch(
            service=service,
            hotels=batch,
            concurrency=concurrency,
            debug=debug,
        )
        all_results.extend(results)

        # Log batch summary
        detected = sum(1 for r in results if r.booking_engine and r.booking_engine not in ("", "unknown"))
        errors = sum(1 for r in results if r.error)
        logger.info(f"Batch {batch_num} complete: {detected} detected, {errors} errors")

        # Small pause between batches to let memory settle
        if i + batch_size < total_hotels:
            await asyncio.sleep(1)

    # Final summary
    detected = sum(1 for r in all_results if r.booking_engine and r.booking_engine not in ("", "unknown"))
    errors = sum(1 for r in all_results if r.error)
    no_engine = len(all_results) - detected - errors

    logger.info("=" * 60)
    logger.info("DETECTION COMPLETE")
    logger.info("=" * 60)
    logger.info(f"Hotels processed:    {len(all_results)}")
    logger.info(f"Engines detected:    {detected}")
    logger.info(f"No engine found:     {no_engine}")
    logger.info(f"Errors:              {errors}")
    if all_results:
        logger.info(f"Hit rate:            {detected / len(all_results) * 100:.1f}%")
    logger.info("=" * 60)


async def run(
    limit: int = 100,
    concurrency: int = 5,
    batch_size: int = 100,
    debug: bool = False,
):
    """Initialize DB and run workflow."""
    await init_db()
    try:
        await detection_workflow(
            limit=limit,
            concurrency=concurrency,
            batch_size=batch_size,
            debug=debug,
        )
    finally:
        await close_db()


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description="Run booking engine detection workflow",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
RAM Presets:
  --preset small   8GB RAM  (3 concurrent, batch 50)
  --preset medium  12GB RAM (5 concurrent, batch 100)
  --preset large   16GB RAM (8 concurrent, batch 200)
  --preset xlarge  32GB RAM (12 concurrent, batch 500)

Examples:
  uv run python workflows/detection.py --preset medium --limit 500
  uv run python workflows/detection.py --concurrency 4 --batch-size 75 --limit 200
  uv run python workflows/detection.py --preset large --debug
        """
    )

    parser.add_argument(
        "--limit", "-l",
        type=int,
        default=100,
        help="Total max hotels to process (default: 100)"
    )
    parser.add_argument(
        "--preset", "-p",
        choices=list(PRESETS.keys()),
        help="RAM preset (small=8GB, medium=12GB, large=16GB, xlarge=32GB)"
    )
    parser.add_argument(
        "--concurrency", "-c",
        type=int,
        help="Parallel browser contexts (overrides preset)"
    )
    parser.add_argument(
        "--batch-size", "-b",
        type=int,
        help="Hotels per batch (overrides preset)"
    )
    parser.add_argument(
        "--debug", "-d",
        action="store_true",
        help="Enable debug logging"
    )

    args = parser.parse_args()

    # Apply preset defaults
    if args.preset:
        preset = PRESETS[args.preset]
        concurrency = preset["concurrency"]
        batch_size = preset["batch_size"]
        logger.info(f"Using preset '{args.preset}': {preset['description']}")
    else:
        concurrency = 5
        batch_size = 100

    # Override with explicit args
    if args.concurrency:
        concurrency = args.concurrency
    if args.batch_size:
        batch_size = args.batch_size

    logger.info(f"Starting detection: limit={args.limit}, concurrency={concurrency}, batch_size={batch_size}")

    asyncio.run(run(
        limit=args.limit,
        concurrency=concurrency,
        batch_size=batch_size,
        debug=args.debug,
    ))


if __name__ == "__main__":
    main()
