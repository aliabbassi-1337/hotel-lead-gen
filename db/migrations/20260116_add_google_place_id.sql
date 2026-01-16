-- Migration: Add google_place_id column to hotels table
-- Date: 2026-01-16
-- Description: Adds Google Place ID for reliable deduplication during scraping.
--              The Place ID is a globally unique, stable identifier from Google Maps.

-- Add the column
ALTER TABLE hotels ADD COLUMN IF NOT EXISTS google_place_id TEXT;

-- Create index for fast lookups (used for dedup on future scrapes)
CREATE INDEX IF NOT EXISTS idx_hotels_google_place_id ON hotels(google_place_id);

-- Note: The unique constraint remains on (name, website) for backwards compatibility.
-- Google Place ID is used for in-memory deduplication during scraping,
-- and stored for potential future use (e.g., re-scraping, data enrichment).
