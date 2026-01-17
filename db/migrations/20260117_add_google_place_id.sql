-- Migration: Add google_place_id column for deduplication
-- Date: 2026-01-17
-- Description: Adds Google Place ID as primary deduplication key
--              Place ID is globally unique and stable from Google Maps

SET search_path TO sadie_gtm, public;

-- Add the google_place_id column
ALTER TABLE hotels ADD COLUMN IF NOT EXISTS google_place_id TEXT;

-- Regular index for fast lookups
CREATE INDEX IF NOT EXISTS idx_hotels_google_place_id ON hotels(google_place_id);

-- Unique constraint on Google Place ID (primary dedup key)
-- Using partial index since existing rows may have NULL place_id
CREATE UNIQUE INDEX IF NOT EXISTS idx_hotels_google_place_id_unique 
ON hotels(google_place_id) 
WHERE google_place_id IS NOT NULL;
