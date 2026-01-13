"""Repository for leadgen service database operations."""

from typing import List, Optional
from db.client import queries, get_conn
from db.models.hotel import Hotel


async def get_hotel_by_id(hotel_id: int) -> Optional[Hotel]:
    """Get hotel by ID with location coordinates."""
    async with get_conn() as conn:
        result = await queries.get_hotel_by_id(conn, hotel_id=hotel_id)
        if result:
            return Hotel.model_validate(dict(result))
        return None


async def insert_hotel(
    name: str,
    website: Optional[str] = None,
    phone_google: Optional[str] = None,
    phone_website: Optional[str] = None,
    email: Optional[str] = None,
    latitude: Optional[float] = None,
    longitude: Optional[float] = None,
    address: Optional[str] = None,
    city: Optional[str] = None,
    state: Optional[str] = None,
    country: str = "USA",
    rating: Optional[float] = None,
    review_count: Optional[int] = None,
    status: int = 0,
    source: Optional[str] = None,
) -> int:
    """Insert a new hotel and return the ID."""
    async with get_conn() as conn:
        result = await queries.insert_hotel(
            conn,
            name=name,
            website=website,
            phone_google=phone_google,
            phone_website=phone_website,
            email=email,
            latitude=latitude,
            longitude=longitude,
            address=address,
            city=city,
            state=state,
            country=country,
            rating=rating,
            review_count=review_count,
            status=status,
            source=source,
        )
        return result


async def delete_hotel(hotel_id: int) -> None:
    """Delete a hotel by ID."""
    async with get_conn() as conn:
        await queries.delete_hotel(conn, hotel_id=hotel_id)


async def insert_hotels_bulk(hotels: List[dict]) -> int:
    """
    Insert multiple hotels and return count of inserted/updated rows.

    Each hotel dict should have keys matching insert_hotel parameters:
    name, website, phone_google, latitude, longitude, address, city, state,
    country, rating, review_count, status, source

    Uses individual inserts with ON CONFLICT (upsert) to handle duplicates.
    """
    if not hotels:
        return 0

    count = 0
    async with get_conn() as conn:
        for hotel in hotels:
            try:
                await queries.insert_hotel(
                    conn,
                    name=hotel.get("name"),
                    website=hotel.get("website"),
                    phone_google=hotel.get("phone_google"),
                    phone_website=hotel.get("phone_website"),
                    email=hotel.get("email"),
                    latitude=hotel.get("latitude"),
                    longitude=hotel.get("longitude"),
                    address=hotel.get("address"),
                    city=hotel.get("city"),
                    state=hotel.get("state"),
                    country=hotel.get("country", "USA"),
                    rating=hotel.get("rating"),
                    review_count=hotel.get("review_count"),
                    status=hotel.get("status", 0),
                    source=hotel.get("source"),
                )
                count += 1
            except Exception:
                # Skip individual failures (e.g., constraint violations)
                continue

    return count


async def get_hotels_by_status(status: int, limit: int = 1000) -> List[Hotel]:
    """Get hotels by pipeline status."""
    async with get_conn() as conn:
        results = await queries.get_hotels_by_status(conn, status=status, limit=limit)
        return [Hotel.model_validate(dict(row)) for row in results]


async def count_hotels_by_status(status: int) -> int:
    """Count hotels with a specific status."""
    async with get_conn() as conn:
        result = await queries.count_hotels_by_status(conn, status=status)
        return result or 0
