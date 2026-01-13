"""Repository for leadgen service database operations."""

from typing import Optional
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
