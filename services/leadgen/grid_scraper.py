"""
Grid Scraper - Adaptive grid-based hotel scraping.

Converted from scripts/scrapers/grid.py into proper service code.
Uses adaptive subdivision: starts with coarse grid, subdivides dense cells.
"""

import os
import math
import asyncio
import logging
from dataclasses import dataclass, field
from typing import List, Optional, Set, Tuple

import httpx
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)

SERPER_MAPS_URL = "https://google.serper.dev/maps"

# Adaptive subdivision settings (from context/grid_scraper_adaptive.md)
INITIAL_CELL_SIZE_KM = 10.0  # Start with 10km cells
MIN_CELL_SIZE_KM = 2.5       # Don't subdivide below 2.5km
API_RESULT_LIMIT = 20        # Serper returns max 20 results - subdivide if hit

# State bounding boxes from scripts/scrapers/grid.py
STATE_BOUNDS = {
    "florida": (24.396308, 31.000968, -87.634896, -79.974307),
    "california": (32.528832, 42.009503, -124.482003, -114.131211),
    "texas": (25.837377, 36.500704, -106.645646, -93.508039),
    "new_york": (40.477399, 45.015851, -79.762418, -71.777491),
    "tennessee": (34.982924, 36.678118, -90.310298, -81.6469),
    "north_carolina": (33.752878, 36.588117, -84.321869, -75.460621),
    "georgia": (30.355644, 35.000659, -85.605165, -80.839729),
    "arizona": (31.332177, 37.004260, -114.818269, -109.045223),
    "nevada": (35.001857, 42.002207, -120.005746, -114.039648),
    "colorado": (36.992426, 41.003444, -109.060253, -102.041524),
}

# Search terms - rotate through these per cell
SEARCH_TERMS = ["hotels", "motels", "resorts", "boutique hotel", "inns", "lodges"]

# Chain filter from scripts/scrapers/grid.py
SKIP_CHAINS = [
    "marriott", "hilton", "hyatt", "sheraton", "westin", "w hotel",
    "intercontinental", "holiday inn", "crowne plaza", "ihg",
    "best western", "choice hotels", "comfort inn", "quality inn",
    "radisson", "wyndham", "ramada", "days inn", "super 8", "motel 6",
    "la quinta", "travelodge", "ibis", "novotel", "mercure", "accor",
    "four seasons", "ritz-carlton", "st. regis", "fairmont",
]


@dataclass
class GridCell:
    """A grid cell for searching."""
    lat_min: float
    lat_max: float
    lng_min: float
    lng_max: float

    @property
    def center_lat(self) -> float:
        return (self.lat_min + self.lat_max) / 2

    @property
    def center_lng(self) -> float:
        return (self.lng_min + self.lng_max) / 2

    @property
    def size_km(self) -> float:
        """Approximate cell size in km (average of width/height)."""
        height = (self.lat_max - self.lat_min) * 111.0
        width = (self.lng_max - self.lng_min) * 111.0 * math.cos(math.radians(self.center_lat))
        return (height + width) / 2

    def subdivide(self) -> List["GridCell"]:
        """Split into 4 smaller cells."""
        mid_lat = self.center_lat
        mid_lng = self.center_lng
        return [
            GridCell(self.lat_min, mid_lat, self.lng_min, mid_lng),
            GridCell(self.lat_min, mid_lat, mid_lng, self.lng_max),
            GridCell(mid_lat, self.lat_max, self.lng_min, mid_lng),
            GridCell(mid_lat, self.lat_max, mid_lng, self.lng_max),
        ]


@dataclass
class ScrapedHotel:
    """Hotel data from scraper."""
    name: str
    website: Optional[str] = None
    phone: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    rating: Optional[float] = None
    review_count: Optional[int] = None


@dataclass
class ScrapeStats:
    """Scrape run statistics."""
    hotels_found: int = 0
    api_calls: int = 0
    cells_searched: int = 0
    cells_subdivided: int = 0
    duplicates_skipped: int = 0
    chains_skipped: int = 0


class GridScraper:
    """Adaptive grid-based hotel scraper using Serper Maps API."""

    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.environ.get("SERPER_SAMI", "")
        if not self.api_key:
            raise ValueError("No Serper API key. Set SERPER_SAMI env var or pass api_key.")

        self._seen: Set[str] = set()
        self._stats = ScrapeStats()
        self._out_of_credits = False

    async def scrape_region(
        self,
        center_lat: float,
        center_lng: float,
        radius_km: float,
    ) -> Tuple[List[ScrapedHotel], ScrapeStats]:
        """Scrape hotels in a circular region using adaptive grid."""
        # Convert center+radius to bounding box
        lat_deg = radius_km / 111.0
        lng_deg = radius_km / (111.0 * math.cos(math.radians(center_lat)))

        return await self._scrape_bounds(
            lat_min=center_lat - lat_deg,
            lat_max=center_lat + lat_deg,
            lng_min=center_lng - lng_deg,
            lng_max=center_lng + lng_deg,
        )

    async def scrape_state(self, state: str) -> Tuple[List[ScrapedHotel], ScrapeStats]:
        """Scrape hotels in a state using adaptive grid."""
        state_key = state.lower().replace(" ", "_")
        if state_key not in STATE_BOUNDS:
            raise ValueError(f"Unknown state: {state}. Available: {list(STATE_BOUNDS.keys())}")

        lat_min, lat_max, lng_min, lng_max = STATE_BOUNDS[state_key]
        return await self._scrape_bounds(lat_min, lat_max, lng_min, lng_max)

    async def _scrape_bounds(
        self,
        lat_min: float,
        lat_max: float,
        lng_min: float,
        lng_max: float,
    ) -> Tuple[List[ScrapedHotel], ScrapeStats]:
        """Scrape with adaptive subdivision."""
        self._seen = set()
        self._stats = ScrapeStats()
        self._out_of_credits = False

        hotels: List[ScrapedHotel] = []

        # Generate initial coarse grid
        cells = self._generate_grid(lat_min, lat_max, lng_min, lng_max, INITIAL_CELL_SIZE_KM)
        logger.info(f"Starting scrape: {len(cells)} initial cells")

        async with httpx.AsyncClient(timeout=30.0) as client:
            while cells and not self._out_of_credits:
                cell = cells.pop(0)
                self._stats.cells_searched += 1

                cell_hotels, hit_limit = await self._search_cell(client, cell)
                hotels.extend(cell_hotels)

                # Adaptive subdivision: if we hit API limit and cell is large enough
                if hit_limit and cell.size_km > MIN_CELL_SIZE_KM * 2:
                    subcells = cell.subdivide()
                    cells.extend(subcells)
                    self._stats.cells_subdivided += 1
                    logger.debug(f"Subdivided cell at ({cell.center_lat:.3f}, {cell.center_lng:.3f})")

                await asyncio.sleep(0.1)  # Rate limit

        self._stats.hotels_found = len(hotels)
        logger.info(f"Scrape done: {len(hotels)} hotels, {self._stats.api_calls} API calls")

        return hotels, self._stats

    def _generate_grid(
        self,
        lat_min: float,
        lat_max: float,
        lng_min: float,
        lng_max: float,
        cell_size_km: float,
    ) -> List[GridCell]:
        """Generate grid cells covering bounding box."""
        center_lat = (lat_min + lat_max) / 2

        height_km = (lat_max - lat_min) * 111.0
        width_km = (lng_max - lng_min) * 111.0 * math.cos(math.radians(center_lat))

        n_lat = max(1, int(math.ceil(height_km / cell_size_km)))
        n_lng = max(1, int(math.ceil(width_km / cell_size_km)))

        lat_step = (lat_max - lat_min) / n_lat
        lng_step = (lng_max - lng_min) / n_lng

        cells = []
        for i in range(n_lat):
            for j in range(n_lng):
                cells.append(GridCell(
                    lat_min=lat_min + i * lat_step,
                    lat_max=lat_min + (i + 1) * lat_step,
                    lng_min=lng_min + j * lng_step,
                    lng_max=lng_min + (j + 1) * lng_step,
                ))
        return cells

    async def _search_cell(
        self,
        client: httpx.AsyncClient,
        cell: GridCell,
    ) -> Tuple[List[ScrapedHotel], bool]:
        """Search a cell. Returns (hotels, hit_api_limit)."""
        hotels: List[ScrapedHotel] = []
        hit_limit = False

        for term in SEARCH_TERMS:
            if self._out_of_credits:
                break

            places = await self._search_serper(client, term, cell.center_lat, cell.center_lng)

            if len(places) >= API_RESULT_LIMIT:
                hit_limit = True

            for place in places:
                hotel = self._process_place(place)
                if hotel:
                    hotels.append(hotel)

            await asyncio.sleep(0.05)

        return hotels, hit_limit

    async def _search_serper(
        self,
        client: httpx.AsyncClient,
        query: str,
        lat: float,
        lng: float,
    ) -> List[dict]:
        """Call Serper Maps API."""
        if self._out_of_credits:
            return []

        self._stats.api_calls += 1

        try:
            resp = await client.post(
                SERPER_MAPS_URL,
                headers={"X-API-KEY": self.api_key, "Content-Type": "application/json"},
                json={"q": query, "num": 100, "ll": f"@{lat},{lng},14z"},
            )

            if resp.status_code == 400 and "credits" in resp.text.lower():
                logger.warning("Out of Serper credits")
                self._out_of_credits = True
                return []

            if resp.status_code != 200:
                logger.error(f"Serper error {resp.status_code}: {resp.text[:100]}")
                return []

            return resp.json().get("places", [])
        except Exception as e:
            logger.error(f"Serper request failed: {e}")
            return []

    def _process_place(self, place: dict) -> Optional[ScrapedHotel]:
        """Process place into ScrapedHotel, filtering chains/duplicates."""
        name = place.get("title", "").strip()
        if not name:
            return None

        name_lower = name.lower()

        # Skip duplicates
        if name_lower in self._seen:
            self._stats.duplicates_skipped += 1
            return None
        self._seen.add(name_lower)

        # Skip chains
        if any(chain in name_lower for chain in SKIP_CHAINS):
            self._stats.chains_skipped += 1
            return None

        # Parse city/state from address
        address = place.get("address", "")
        city, state = self._parse_address(address)

        return ScrapedHotel(
            name=name,
            website=place.get("website"),
            phone=place.get("phoneNumber"),
            latitude=place.get("latitude"),
            longitude=place.get("longitude"),
            address=address or None,
            city=city,
            state=state,
            rating=place.get("rating"),
            review_count=place.get("reviews"),
        )

    def _parse_address(self, address: str) -> Tuple[Optional[str], Optional[str]]:
        """Extract city and state from address string."""
        if not address:
            return None, None

        parts = [p.strip() for p in address.split(",")]
        if len(parts) >= 2:
            # Last part: "FL 33139" -> state = "FL"
            last = parts[-1].split()
            state = last[0] if last and len(last[0]) == 2 else None
            city = parts[-2] if len(parts) >= 2 else None
            return city, state

        return None, None
