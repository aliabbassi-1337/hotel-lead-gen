-- name: get_hotels_pending_enrichment
-- Get hotels that need room count enrichment
-- Criteria: status=1 (detected), has website, not already enriched
SELECT
    h.id,
    h.name,
    h.website,
    h.phone_google,
    h.phone_website,
    h.email,
    h.city,
    h.state,
    h.country,
    h.address,
    ST_Y(h.location::geometry) AS latitude,
    ST_X(h.location::geometry) AS longitude,
    h.rating,
    h.review_count,
    h.status,
    h.source,
    h.created_at,
    h.updated_at
FROM hotels h
LEFT JOIN hotel_room_count hrc ON h.id = hrc.hotel_id
WHERE h.status = 1
  AND h.website IS NOT NULL
  AND h.website != ''
  AND hrc.id IS NULL
ORDER BY h.updated_at DESC
LIMIT :limit;

-- name: claim_hotels_for_enrichment
-- Atomically claim hotels for enrichment (multi-worker safe)
-- Uses FOR UPDATE SKIP LOCKED so multiple workers grab different rows
-- Sets status=2 (enriching) to mark as claimed
UPDATE hotels
SET status = 2, updated_at = CURRENT_TIMESTAMP
WHERE id IN (
    SELECT h.id FROM hotels h
    LEFT JOIN hotel_room_count hrc ON h.id = hrc.hotel_id
    WHERE h.status = 1
      AND h.website IS NOT NULL
      AND h.website != ''
      AND hrc.id IS NULL
    FOR UPDATE SKIP LOCKED
    LIMIT :limit
)
RETURNING
    id,
    name,
    website,
    phone_google,
    phone_website,
    email,
    city,
    state,
    country,
    address,
    ST_Y(location::geometry) AS latitude,
    ST_X(location::geometry) AS longitude,
    rating,
    review_count,
    status,
    source,
    created_at,
    updated_at;

-- name: reset_stale_enriching_hotels!
-- Reset hotels stuck in enriching state (status=2) for more than N minutes
-- Run this periodically to recover from crashed workers
UPDATE hotels
SET status = 1, updated_at = CURRENT_TIMESTAMP
WHERE status = 2
  AND updated_at < NOW() - INTERVAL '30 minutes';

-- name: get_pending_enrichment_count^
-- Count hotels waiting for enrichment (status=1, not yet enriched)
SELECT COUNT(*) AS count
FROM hotels h
LEFT JOIN hotel_room_count hrc ON h.id = hrc.hotel_id
WHERE h.status = 1
  AND h.website IS NOT NULL
  AND h.website != ''
  AND hrc.id IS NULL;

-- name: insert_room_count<!
-- Insert room count for a hotel
INSERT INTO hotel_room_count (hotel_id, room_count, source, confidence)
VALUES (:hotel_id, :room_count, :source, :confidence)
ON CONFLICT (hotel_id) DO UPDATE SET
    room_count = EXCLUDED.room_count,
    source = EXCLUDED.source,
    confidence = EXCLUDED.confidence,
    enriched_at = CURRENT_TIMESTAMP
RETURNING id;

-- name: get_room_count_by_hotel_id^
-- Get room count for a specific hotel
SELECT id, hotel_id, room_count, source, confidence, enriched_at
FROM hotel_room_count
WHERE hotel_id = :hotel_id;

-- name: delete_room_count!
-- Delete room count for a hotel (for testing)
DELETE FROM hotel_room_count
WHERE hotel_id = :hotel_id;

-- name: update_hotel_enrichment_status!
-- Update hotel status after enrichment
UPDATE hotels
SET status = :status, updated_at = CURRENT_TIMESTAMP
WHERE id = :hotel_id;
