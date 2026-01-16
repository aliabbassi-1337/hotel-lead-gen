-- Migration: Add google_place_id column and location-based deduplication
-- Date: 2026-01-16
-- Description: Adds Google Place ID and location-based unique constraints for reliable deduplication.
--              - Place ID: globally unique, stable identifier from Google Maps
--              - Location: rounded coordinates (~11m precision) to catch same-location duplicates

-- Add the google_place_id column
ALTER TABLE hotels ADD COLUMN IF NOT EXISTS google_place_id TEXT;

-- Unique constraint on Google Place ID (primary dedup key)
-- Using partial index since existing rows may have NULL place_id
CREATE UNIQUE INDEX IF NOT EXISTS idx_hotels_google_place_id_unique 
ON hotels(google_place_id) 
WHERE google_place_id IS NOT NULL;

-- Unique constraint on location (secondary dedup key)
-- Rounds lat/lng to 4 decimal places (~11m precision)
-- Only applies when google_place_id is NULL (to avoid blocking valid nearby hotels with different place_ids)
CREATE UNIQUE INDEX IF NOT EXISTS idx_hotels_location_unique 
ON hotels(
    ROUND(ST_Y(location::geometry)::numeric, 4),
    ROUND(ST_X(location::geometry)::numeric, 4)
) 
WHERE google_place_id IS NULL AND location IS NOT NULL;

-- Regular index for fast place_id lookups
CREATE INDEX IF NOT EXISTS idx_hotels_google_place_id ON hotels(google_place_id);
