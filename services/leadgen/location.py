"""Location extraction and matching for hotel websites."""


class LocationExtractor:
    """Extracts location information from website content."""

    # Major cities to look for
    KNOWN_CITIES = [
        # Sweden
        "stockholm", "gothenburg", "göteborg", "malmö", "malmo", "uppsala",
        # Nordic
        "oslo", "copenhagen", "helsinki", "reykjavik",
        # Major European cities
        "london", "paris", "berlin", "amsterdam", "madrid", "barcelona",
        "rome", "milan", "vienna", "prague", "munich", "zurich", "geneva",
        "brussels", "lisbon", "dublin", "edinburgh",
        # US major cities
        "new york", "los angeles", "chicago", "houston", "phoenix",
        "san francisco", "seattle", "miami", "boston", "denver",
        "las vegas", "san diego", "austin", "dallas", "atlanta",
        # Other major cities
        "tokyo", "singapore", "hong kong", "sydney", "melbourne",
        "toronto", "vancouver", "dubai", "bangkok", "bali",
    ]

    # Countries
    KNOWN_COUNTRIES = [
        "sweden", "sverige", "norway", "denmark", "finland", "iceland",
        "united states", "usa", "uk", "united kingdom", "england",
        "france", "germany", "spain", "italy", "netherlands", "belgium",
        "switzerland", "austria", "portugal", "ireland", "scotland",
        "australia", "canada", "japan", "singapore", "thailand",
        "indonesia", "united arab emirates", "uae",
    ]

    @classmethod
    def extract_location(cls, text: str, html: str = "") -> str:
        """Extract location from page content.

        Returns the most likely city/location found, or empty string.
        """
        text_lower = text.lower()
        combined = (text_lower + " " + html.lower()) if html else text_lower

        # Count occurrences of known cities
        city_counts = {}
        for city in cls.KNOWN_CITIES:
            count = combined.count(city)
            if count > 0:
                city_counts[city] = count

        # Return the most frequently mentioned city
        if city_counts:
            best_city = max(city_counts, key=city_counts.get)
            return best_city.title()

        # Fallback: look for country mentions
        for country in cls.KNOWN_COUNTRIES:
            if country in combined:
                return country.title()

        return ""

    # Florida metro areas (cities that should match)
    FLORIDA_METROS = {
        "miami": ["miami", "miami beach", "coral gables", "coconut grove", "south beach", 
                  "north miami", "hialeah", "doral", "aventura", "sunny isles", "key biscayne",
                  "brickell", "wynwood", "little havana", "downtown miami"],
        "orlando": ["orlando", "lake buena vista", "kissimmee", "international drive", 
                    "disney", "universal", "celebration", "dr phillips", "sand lake"],
        "tampa": ["tampa", "st petersburg", "clearwater", "tampa bay", "ybor city",
                  "channelside", "hyde park", "westshore"],
        "fort lauderdale": ["fort lauderdale", "lauderdale", "hollywood", "pompano beach",
                            "deerfield beach", "boca raton"],
    }

    @classmethod
    def location_matches(cls, detected: str, target: str) -> bool:
        """Check if detected location matches target location.

        Uses fuzzy matching to handle variations and metro areas.
        """
        if not detected or not target:
            return True  # If either is empty, don't filter

        detected_lower = detected.lower().strip()
        target_lower = target.lower().strip()

        # Direct match
        if detected_lower == target_lower:
            return True

        # Check if target is contained in detected or vice versa
        if target_lower in detected_lower or detected_lower in target_lower:
            return True

        # Check Florida metro areas - if both are in same metro, match
        for metro, cities in cls.FLORIDA_METROS.items():
            detected_in_metro = any(c in detected_lower for c in cities)
            target_in_metro = any(c in target_lower for c in cities)
            if detected_in_metro and target_in_metro:
                return True
            # Also match if target is the metro name
            if metro in target_lower and detected_in_metro:
                return True

        # Handle Swedish city name variations
        variations = {
            "gothenburg": ["göteborg", "goteborg"],
            "malmö": ["malmo"],
        }

        for canonical, alts in variations.items():
            all_forms = [canonical] + alts
            if detected_lower in all_forms and target_lower in all_forms:
                return True

        # Be lenient - if we're unsure, allow it through
        # Better to have false positives than miss good hotels
        return True
