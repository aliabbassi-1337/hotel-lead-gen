-- name: get_hotel_by_id^
-- Get single hotel by ID with location coordinates
SELECT
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
    updated_at
FROM hotels
WHERE id = :hotel_id;

-- name: insert_hotel<!
-- Insert a new hotel and return the ID
INSERT INTO hotels (
    name,
    website,
    phone_google,
    phone_website,
    email,
    location,
    address,
    city,
    state,
    country,
    rating,
    review_count,
    status,
    source
) VALUES (
    :name,
    :website,
    :phone_google,
    :phone_website,
    :email,
    ST_Point(:longitude, :latitude)::geography,
    :address,
    :city,
    :state,
    :country,
    :rating,
    :review_count,
    :status,
    :source
)
ON CONFLICT (name, COALESCE(website, ''))
DO UPDATE SET
    phone_google = EXCLUDED.phone_google,
    phone_website = EXCLUDED.phone_website,
    email = EXCLUDED.email,
    location = EXCLUDED.location,
    address = EXCLUDED.address,
    city = EXCLUDED.city,
    state = EXCLUDED.state,
    country = EXCLUDED.country,
    rating = EXCLUDED.rating,
    review_count = EXCLUDED.review_count,
    status = EXCLUDED.status,
    source = EXCLUDED.source,
    updated_at = CURRENT_TIMESTAMP
RETURNING id;

-- name: delete_hotel!
-- Delete a hotel by ID
DELETE FROM hotels
WHERE id = :hotel_id;
