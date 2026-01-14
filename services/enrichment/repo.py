"""Repository for enrichment service database operations."""

from typing import Optional, List
from decimal import Decimal
from db.client import queries, get_conn
from db.models.hotel import Hotel
from db.models.hotel_room_count import HotelRoomCount


async def get_hotels_pending_enrichment(limit: int = 100) -> List[Hotel]:
    """Get hotels that need room count enrichment.

    Criteria:
    - status = 1 (detected)
    - has website
    - not already in hotel_room_count table
    """
    async with get_conn() as conn:
        results = await queries.get_hotels_pending_enrichment(conn, limit=limit)
        return [Hotel.model_validate(dict(row)) for row in results]


async def claim_hotels_for_enrichment(limit: int = 100) -> List[Hotel]:
    """Atomically claim hotels for enrichment (multi-worker safe).

    Uses FOR UPDATE SKIP LOCKED so multiple workers can run concurrently
    without grabbing the same hotels. Sets status=2 (enriching).

    Returns list of claimed hotels.
    """
    async with get_conn() as conn:
        results = await queries.claim_hotels_for_enrichment(conn, limit=limit)
        return [Hotel.model_validate(dict(row)) for row in results]


async def reset_stale_enriching_hotels() -> None:
    """Reset hotels stuck in enriching state (status=2) for > 30 min.

    Run this periodically to recover from crashed workers.
    """
    async with get_conn() as conn:
        await queries.reset_stale_enriching_hotels(conn)


async def get_pending_enrichment_count() -> int:
    """Count hotels waiting for enrichment (status=1, not yet enriched)."""
    async with get_conn() as conn:
        result = await queries.get_pending_enrichment_count(conn)
        return result["count"] if result else 0


async def insert_room_count(
    hotel_id: int,
    room_count: int,
    source: Optional[str] = None,
    confidence: Optional[Decimal] = None,
) -> int:
    """Insert room count for a hotel.

    Returns the hotel_room_count ID.
    """
    async with get_conn() as conn:
        result = await queries.insert_room_count(
            conn,
            hotel_id=hotel_id,
            room_count=room_count,
            source=source,
            confidence=confidence,
        )
        return result


async def get_room_count_by_hotel_id(hotel_id: int) -> Optional[HotelRoomCount]:
    """Get room count for a specific hotel."""
    async with get_conn() as conn:
        result = await queries.get_room_count_by_hotel_id(conn, hotel_id=hotel_id)
        if result:
            return HotelRoomCount.model_validate(dict(result))
        return None


async def delete_room_count(hotel_id: int) -> None:
    """Delete room count for a hotel (for testing)."""
    async with get_conn() as conn:
        await queries.delete_room_count(conn, hotel_id=hotel_id)


async def update_hotel_enrichment_status(hotel_id: int, status: int) -> None:
    """Update hotel status after enrichment.

    Status values:
    - 3 = enriched (room count found)
    - 1 = detected (reset back if enrichment failed)
    """
    async with get_conn() as conn:
        await queries.update_hotel_enrichment_status(
            conn, hotel_id=hotel_id, status=status
        )
