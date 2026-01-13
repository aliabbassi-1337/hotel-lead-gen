"""Unit tests for leadgen repository."""

import pytest
from services.leadgen.repo import get_hotel_by_id, insert_hotel, delete_hotel


@pytest.mark.asyncio
async def test_get_hotel_by_id_not_found():
    """Test getting a non-existent hotel returns None."""
    hotel = await get_hotel_by_id(hotel_id=999999)
    assert hotel is None


@pytest.mark.asyncio
async def test_get_hotel_by_id_exists():
    """Test getting an existing hotel returns Hotel model."""
    # Insert test hotel (will update if already exists)
    hotel_id = await insert_hotel(
        name="Test Hotel Miami",
        website="https://testhotel.com",
        phone_google="+1-305-555-0100",
        email="test@hotel.com",
        latitude=25.7617,
        longitude=-80.1918,
        address="123 Test St",
        city="Miami",
        state="Florida",
        rating=4.5,
        review_count=100,
        status=0,
        source="test",
    )

    # Query the inserted hotel
    hotel = await get_hotel_by_id(hotel_id=hotel_id)
    assert hotel is not None
    assert hotel.id == hotel_id
    assert hotel.name == "Test Hotel Miami"
    assert hotel.city == "Miami"
    assert hotel.state == "Florida"
    assert hotel.status == 0

    # Cleanup
    await delete_hotel(hotel_id)
