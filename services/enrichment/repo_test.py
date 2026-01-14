"""Unit tests for enrichment repository."""

import pytest
from decimal import Decimal
from services.enrichment.repo import (
    get_pending_enrichment_count,
    insert_room_count,
    get_room_count_by_hotel_id,
    delete_room_count,
)
from services.leadgen.repo import (
    insert_hotel,
    delete_hotel,
    update_hotel_status,
)


@pytest.mark.asyncio
async def test_insert_and_get_room_count():
    """Test inserting and retrieving room count."""
    # Insert test hotel with status=1 (detected)
    hotel_id = await insert_hotel(
        name="Test Enrichment Hotel",
        website="https://test-enrichment.com",
        city="Miami",
        state="Florida",
        status=1,  # detected
        source="test",
    )

    # Insert room count
    room_count_id = await insert_room_count(
        hotel_id=hotel_id,
        room_count=42,
        source="regex",
        confidence=Decimal("1.0"),
    )
    assert room_count_id is not None

    # Get room count
    room_count = await get_room_count_by_hotel_id(hotel_id=hotel_id)
    assert room_count is not None
    assert room_count.hotel_id == hotel_id
    assert room_count.room_count == 42
    assert room_count.source == "regex"
    assert room_count.confidence == Decimal("1.00")

    # Cleanup
    await delete_room_count(hotel_id)
    await delete_hotel(hotel_id)


@pytest.mark.asyncio
async def test_get_room_count_not_found():
    """Test getting room count for non-existent hotel returns None."""
    room_count = await get_room_count_by_hotel_id(hotel_id=999999)
    assert room_count is None


@pytest.mark.asyncio
async def test_insert_room_count_upsert():
    """Test inserting room count updates on conflict."""
    # Insert test hotel
    hotel_id = await insert_hotel(
        name="Test Upsert Hotel",
        website="https://test-upsert.com",
        city="Miami",
        state="Florida",
        status=1,
        source="test",
    )

    # Insert initial room count
    await insert_room_count(
        hotel_id=hotel_id,
        room_count=10,
        source="groq",
        confidence=Decimal("0.7"),
    )

    # Upsert with new room count
    await insert_room_count(
        hotel_id=hotel_id,
        room_count=25,
        source="regex",
        confidence=Decimal("1.0"),
    )

    # Verify update
    room_count = await get_room_count_by_hotel_id(hotel_id=hotel_id)
    assert room_count is not None
    assert room_count.room_count == 25
    assert room_count.source == "regex"

    # Cleanup
    await delete_room_count(hotel_id)
    await delete_hotel(hotel_id)


@pytest.mark.asyncio
async def test_get_pending_enrichment_count():
    """Test counting hotels pending enrichment."""
    # Insert test hotel with status=1 (detected) and no room count
    hotel_id = await insert_hotel(
        name="Test Pending Enrichment",
        website="https://test-pending.com",
        city="Miami",
        state="Florida",
        status=1,
        source="test",
    )

    # Get count - should include our new hotel
    count = await get_pending_enrichment_count()
    assert count >= 1

    # Add room count - should exclude from pending
    await insert_room_count(
        hotel_id=hotel_id,
        room_count=50,
        source="groq",
        confidence=Decimal("0.7"),
    )

    # Get count again - should be one less
    count_after = await get_pending_enrichment_count()
    assert count_after == count - 1

    # Cleanup
    await delete_room_count(hotel_id)
    await delete_hotel(hotel_id)
