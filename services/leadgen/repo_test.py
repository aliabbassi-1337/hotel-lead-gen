"""Unit tests for leadgen repository."""

import pytest
from services.leadgen.repo import (
    get_hotel_by_id,
    insert_hotel,
    delete_hotel,
    insert_hotels_bulk,
    count_hotels_by_status,
    get_hotels_by_status,
)


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


@pytest.mark.asyncio
async def test_insert_hotels_bulk():
    """Test bulk inserting multiple hotels."""
    hotels = [
        {
            "name": "Bulk Test Hotel 1",
            "website": "https://bulktest1.com",
            "city": "Miami",
            "state": "FL",
            "latitude": 25.76,
            "longitude": -80.19,
            "source": "test_bulk",
        },
        {
            "name": "Bulk Test Hotel 2",
            "website": "https://bulktest2.com",
            "city": "Miami Beach",
            "state": "FL",
            "latitude": 25.79,
            "longitude": -80.13,
            "source": "test_bulk",
        },
    ]

    count = await insert_hotels_bulk(hotels)
    assert count == 2

    # Verify hotels were inserted by querying them
    status_hotels = await get_hotels_by_status(status=0, limit=100)
    bulk_hotels = [h for h in status_hotels if h.source == "test_bulk"]
    assert len(bulk_hotels) >= 2

    # Cleanup
    for h in bulk_hotels:
        await delete_hotel(h.id)


@pytest.mark.asyncio
async def test_insert_hotels_bulk_empty():
    """Test bulk insert with empty list."""
    count = await insert_hotels_bulk([])
    assert count == 0


@pytest.mark.asyncio
async def test_count_hotels_by_status():
    """Test counting hotels by status."""
    # Insert test hotel with status=0
    hotel_id = await insert_hotel(
        name="Count Test Hotel",
        website="https://counttest.com",
        status=0,
        source="test_count",
    )

    # Count should include our hotel
    count = await count_hotels_by_status(status=0)
    assert count >= 1

    # Cleanup
    await delete_hotel(hotel_id)


@pytest.mark.asyncio
async def test_get_hotels_by_status():
    """Test getting hotels by status."""
    # Insert test hotel with status=0
    hotel_id = await insert_hotel(
        name="Status Test Hotel",
        website="https://statustest.com",
        city="Miami",
        state="FL",
        status=0,
        source="test_status",
    )

    # Query hotels with status=0
    hotels = await get_hotels_by_status(status=0, limit=100)
    assert len(hotels) >= 1

    # Find our test hotel
    test_hotel = next((h for h in hotels if h.name == "Status Test Hotel"), None)
    assert test_hotel is not None
    assert test_hotel.city == "Miami"

    # Cleanup
    await delete_hotel(hotel_id)
