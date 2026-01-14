from abc import ABC, abstractmethod
from decimal import Decimal
import asyncio

import httpx

from services.enrichment import repo
from services.enrichment.room_count_enricher import (
    enrich_hotel_room_count,
    get_groq_api_key,
    log,
)


class IService(ABC):
    """Enrichment Service - Enrich hotel data with room counts and proximity."""

    @abstractmethod
    async def enrich_room_counts(self, limit: int = 100) -> int:
        """
        Get room counts for hotels with status=1 (detected).
        Uses Groq/Google to extract room count from website.
        Returns number of hotels enriched.
        """
        pass

    @abstractmethod
    async def calculate_customer_proximity(self, limit: int = 100) -> int:
        """
        Calculate distance to nearest Sadie customer for hotels.
        Updates hotel_customer_proximity table.
        Returns number of hotels processed.
        """
        pass

    @abstractmethod
    async def get_pending_enrichment_count(self) -> int:
        """
        Count hotels waiting for enrichment (status=1).
        """
        pass


class Service(IService):
    def __init__(self) -> None:
        pass

    async def enrich_room_counts(self, limit: int = 100) -> int:
        """
        Get room counts for hotels with status=1 (detected).
        Uses regex extraction first, then falls back to Groq LLM estimation.
        Returns number of hotels enriched.
        """
        # Check for API key
        if not get_groq_api_key():
            log("Error: ROOM_COUNT_ENRICHER_AGENT_GROQ_KEY not found in .env")
            return 0

        # Claim hotels for enrichment (multi-worker safe)
        hotels = await repo.claim_hotels_for_enrichment(limit=limit)

        if not hotels:
            log("No hotels pending enrichment")
            return 0

        log(f"Claimed {len(hotels)} hotels for enrichment")

        enriched_count = 0

        # Use SSL context that's more permissive for older sites
        async with httpx.AsyncClient(verify=False) as client:
            for hotel in hotels:
                # Skip if no website
                if not hotel.website:
                    await repo.update_hotel_enrichment_status(hotel.id, status=1)
                    continue

                # Enrich this hotel
                room_count, source = await enrich_hotel_room_count(
                    client=client,
                    hotel_id=hotel.id,
                    hotel_name=hotel.name,
                    website=hotel.website,
                )

                if room_count:
                    # Set confidence based on source
                    confidence = Decimal("1.0") if source == "regex" else Decimal("0.7")

                    # Insert room count
                    await repo.insert_room_count(
                        hotel_id=hotel.id,
                        room_count=room_count,
                        source=source,
                        confidence=confidence,
                    )

                    # Update hotel status to enriched (3)
                    await repo.update_hotel_enrichment_status(hotel.id, status=3)
                    enriched_count += 1
                else:
                    # Reset back to detected (1) if enrichment failed
                    await repo.update_hotel_enrichment_status(hotel.id, status=1)

                # Delay to avoid Groq rate limits (30 RPM = 1 request every 2 seconds)
                await asyncio.sleep(2.5)

        log(f"Enrichment complete: {enriched_count}/{len(hotels)} hotels enriched")
        return enriched_count

    async def calculate_customer_proximity(self, limit: int = 100) -> int:
        # TODO: Integrate customer_match.py
        return 0

    async def get_pending_enrichment_count(self) -> int:
        """Count hotels waiting for enrichment (status=1, not yet enriched)."""
        return await repo.get_pending_enrichment_count()
