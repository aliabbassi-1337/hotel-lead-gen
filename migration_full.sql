--
-- PostgreSQL database dump
--

\restrict XMiysYtN5Zl2vfFue7344qVhQRiWkvS98UEQVHAGhc1b8iIyCCFiTBxHuhrtQeG

-- Dumped from database version 17.7
-- Dumped by pg_dump version 17.7

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: sadie_gtm; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA sadie_gtm;


--
-- Name: tiger; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA tiger;


--
-- Name: tiger_data; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA tiger_data;


--
-- Name: topology; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA topology;


--
-- Name: SCHEMA topology; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA topology IS 'PostGIS Topology schema';


--
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: postgis_tiger_geocoder; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder WITH SCHEMA tiger;


--
-- Name: EXTENSION postgis_tiger_geocoder; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis_tiger_geocoder IS 'PostGIS tiger geocoder and reverse geocoder';


--
-- Name: postgis_topology; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_topology WITH SCHEMA topology;


--
-- Name: EXTENSION postgis_topology; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis_topology IS 'PostGIS topology spatial types and functions';


--
-- Name: update_updated_at(); Type: FUNCTION; Schema: sadie_gtm; Owner: -
--

CREATE FUNCTION sadie_gtm.update_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: booking_engines; Type: TABLE; Schema: sadie_gtm; Owner: -
--

CREATE TABLE sadie_gtm.booking_engines (
    id integer NOT NULL,
    name text NOT NULL,
    domains text[],
    tier integer DEFAULT 1,
    is_active boolean DEFAULT true
);


--
-- Name: booking_engines_id_seq; Type: SEQUENCE; Schema: sadie_gtm; Owner: -
--

CREATE SEQUENCE sadie_gtm.booking_engines_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: booking_engines_id_seq; Type: SEQUENCE OWNED BY; Schema: sadie_gtm; Owner: -
--

ALTER SEQUENCE sadie_gtm.booking_engines_id_seq OWNED BY sadie_gtm.booking_engines.id;


--
-- Name: detection_errors; Type: TABLE; Schema: sadie_gtm; Owner: -
--

CREATE TABLE sadie_gtm.detection_errors (
    id integer NOT NULL,
    hotel_id integer NOT NULL,
    error_type text NOT NULL,
    error_message text,
    detected_location text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: detection_errors_id_seq; Type: SEQUENCE; Schema: sadie_gtm; Owner: -
--

CREATE SEQUENCE sadie_gtm.detection_errors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: detection_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: sadie_gtm; Owner: -
--

ALTER SEQUENCE sadie_gtm.detection_errors_id_seq OWNED BY sadie_gtm.detection_errors.id;


--
-- Name: existing_customers; Type: TABLE; Schema: sadie_gtm; Owner: -
--

CREATE TABLE sadie_gtm.existing_customers (
    id integer NOT NULL,
    name text NOT NULL,
    sadie_hotel_id text,
    location public.geography(Point,4326),
    address text,
    city text,
    state text,
    country text DEFAULT 'USA'::text,
    status text DEFAULT 'active'::text,
    go_live_date date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: existing_customers_id_seq; Type: SEQUENCE; Schema: sadie_gtm; Owner: -
--

CREATE SEQUENCE sadie_gtm.existing_customers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: existing_customers_id_seq; Type: SEQUENCE OWNED BY; Schema: sadie_gtm; Owner: -
--

ALTER SEQUENCE sadie_gtm.existing_customers_id_seq OWNED BY sadie_gtm.existing_customers.id;


--
-- Name: hotel_booking_engines; Type: TABLE; Schema: sadie_gtm; Owner: -
--

CREATE TABLE sadie_gtm.hotel_booking_engines (
    hotel_id integer NOT NULL,
    booking_engine_id integer,
    booking_url text,
    detection_method text,
    detected_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: hotel_customer_proximity; Type: TABLE; Schema: sadie_gtm; Owner: -
--

CREATE TABLE sadie_gtm.hotel_customer_proximity (
    id integer NOT NULL,
    hotel_id integer NOT NULL,
    existing_customer_id integer NOT NULL,
    distance_km numeric(6,1) NOT NULL,
    computed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: hotel_customer_proximity_id_seq; Type: SEQUENCE; Schema: sadie_gtm; Owner: -
--

CREATE SEQUENCE sadie_gtm.hotel_customer_proximity_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hotel_customer_proximity_id_seq; Type: SEQUENCE OWNED BY; Schema: sadie_gtm; Owner: -
--

ALTER SEQUENCE sadie_gtm.hotel_customer_proximity_id_seq OWNED BY sadie_gtm.hotel_customer_proximity.id;


--
-- Name: hotel_room_count; Type: TABLE; Schema: sadie_gtm; Owner: -
--

CREATE TABLE sadie_gtm.hotel_room_count (
    id integer NOT NULL,
    hotel_id integer NOT NULL,
    room_count integer NOT NULL,
    source text,
    confidence numeric(3,2),
    enriched_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: hotel_room_count_id_seq; Type: SEQUENCE; Schema: sadie_gtm; Owner: -
--

CREATE SEQUENCE sadie_gtm.hotel_room_count_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hotel_room_count_id_seq; Type: SEQUENCE OWNED BY; Schema: sadie_gtm; Owner: -
--

ALTER SEQUENCE sadie_gtm.hotel_room_count_id_seq OWNED BY sadie_gtm.hotel_room_count.id;


--
-- Name: hotels; Type: TABLE; Schema: sadie_gtm; Owner: -
--

CREATE TABLE sadie_gtm.hotels (
    id integer NOT NULL,
    name text NOT NULL,
    website text,
    phone_google text,
    phone_website text,
    email text,
    location public.geography(Point,4326),
    address text,
    city text,
    state text,
    country text DEFAULT 'USA'::text,
    rating double precision,
    review_count integer,
    status smallint DEFAULT 0,
    source text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: hotels_id_seq; Type: SEQUENCE; Schema: sadie_gtm; Owner: -
--

CREATE SEQUENCE sadie_gtm.hotels_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hotels_id_seq; Type: SEQUENCE OWNED BY; Schema: sadie_gtm; Owner: -
--

ALTER SEQUENCE sadie_gtm.hotels_id_seq OWNED BY sadie_gtm.hotels.id;


--
-- Name: jobs; Type: TABLE; Schema: sadie_gtm; Owner: -
--

CREATE TABLE sadie_gtm.jobs (
    id integer NOT NULL,
    job_type text NOT NULL,
    hotel_id integer,
    city text,
    state text,
    export_type text,
    queue_name text,
    message_id text,
    attempt_number integer DEFAULT 1,
    worker_id text,
    started_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    completed_at timestamp without time zone,
    duration_ms integer,
    status smallint DEFAULT 1,
    error_message text,
    error_stack text,
    input_params jsonb,
    output_data jsonb,
    s3_log_path text
);


--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: sadie_gtm; Owner: -
--

CREATE SEQUENCE sadie_gtm.jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: sadie_gtm; Owner: -
--

ALTER SEQUENCE sadie_gtm.jobs_id_seq OWNED BY sadie_gtm.jobs.id;


--
-- Name: booking_engines id; Type: DEFAULT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.booking_engines ALTER COLUMN id SET DEFAULT nextval('sadie_gtm.booking_engines_id_seq'::regclass);


--
-- Name: detection_errors id; Type: DEFAULT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.detection_errors ALTER COLUMN id SET DEFAULT nextval('sadie_gtm.detection_errors_id_seq'::regclass);


--
-- Name: existing_customers id; Type: DEFAULT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.existing_customers ALTER COLUMN id SET DEFAULT nextval('sadie_gtm.existing_customers_id_seq'::regclass);


--
-- Name: hotel_customer_proximity id; Type: DEFAULT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.hotel_customer_proximity ALTER COLUMN id SET DEFAULT nextval('sadie_gtm.hotel_customer_proximity_id_seq'::regclass);


--
-- Name: hotel_room_count id; Type: DEFAULT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.hotel_room_count ALTER COLUMN id SET DEFAULT nextval('sadie_gtm.hotel_room_count_id_seq'::regclass);


--
-- Name: hotels id; Type: DEFAULT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.hotels ALTER COLUMN id SET DEFAULT nextval('sadie_gtm.hotels_id_seq'::regclass);


--
-- Name: jobs id; Type: DEFAULT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.jobs ALTER COLUMN id SET DEFAULT nextval('sadie_gtm.jobs_id_seq'::regclass);


--
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: booking_engines; Type: TABLE DATA; Schema: sadie_gtm; Owner: -
--

INSERT INTO sadie_gtm.booking_engines VALUES (3, 'Cloudbeds', '{cloudbeds.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (4, 'Mews', '{mews.com,mews.li,app.mews.com,distributor.mews.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (2, 'SynXis / TravelClick', '{synxis.com,travelclick.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (6, 'BookingSuite / Booking.com', '{bookingsuite.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (7, 'Little Hotelier', '{littlehotelier.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (8, 'WebRezPro', '{webrezpro.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (9, 'InnRoad', '{innroad.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (10, 'ResNexus', '{resnexus.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (11, 'Newbook', '{newbook.cloud,newbooksoftware.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (12, 'RMS Cloud', '{rmscloud.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (13, 'RoomRaccoon', '{roomraccoon.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (14, 'SiteMinder', '{thebookingbutton.com,siteminder.com,direct-book}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (15, 'Sabre / CRS', '{sabre.com,crs.sabre.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (16, 'eZee', '{ezeeabsolute.com,ezeereservation.com,ezeetechnosys.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (17, 'RezTrip', '{reztrip.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (18, 'IHG', '{ihg.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (19, 'Marriott', '{marriott.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (20, 'Hilton', '{hilton.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (21, 'Vacatia', '{vacatia.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (22, 'JEHS / iPMS', '{ipms247.com,live.ipms247.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (23, 'Windsurfer CRS', '{windsurfercrs.com,res.windsurfercrs.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (24, 'ThinkReservations', '{thinkreservations.com,secure.thinkreservations.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (25, 'ASI Web Reservations', '{asiwebres.com,reservation.asiwebres.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (26, 'IQWebBook', '{iqwebbook.com,us01.iqwebbook.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (27, 'BookDirect', '{bookdirect.net,ococean.bookdirect.net}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (28, 'RezStream', '{rezstream.com,guest.rezstream.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (29, 'Reseze', '{reseze.net}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (30, 'WebRez', '{webrez.com,secure.webrez.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (31, 'IB Strategies', '{ibstrategies.com,secure.ibstrategies.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (32, 'ReservationKey', '{reservationkey.com,v2.reservationkey.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (33, 'FareHarbor', '{fareharbor.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (34, 'Firefly Reservations', '{fireflyreservations.com,app.fireflyreservations.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (35, 'Lodgify', '{lodgify.com,checkout.lodgify.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (36, 'eviivo', '{eviivo.com,via.eviivo.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (37, 'LuxuryRes', '{luxuryres.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (38, 'FreeToBook', '{freetobook.com,portal.freetobook.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (39, 'Checkfront', '{checkfront.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (40, 'Beds24', '{beds24.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (41, 'Hotelogix', '{hotelogix.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (42, 'inngenius', '{inngenius.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (43, 'Sirvoy', '{sirvoy.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (44, 'HotelRunner', '{hotelrunner.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (45, 'Amenitiz', '{amenitiz.io,amenitiz.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (46, 'Hostaway', '{hostaway.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (47, 'Guesty', '{guesty.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (48, 'Hospitable', '{hospitable.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (49, 'Lodgable', '{lodgable.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (50, 'HomHero', '{homhero.com.au,api.homhero.com.au,images.prod.homhero}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (51, 'Streamline', '{streamlinevrs.com,resortpro}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (1, 'Triptease', '{triptease.io,triptease.com,onboard.triptease}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (53, 'Yelp Reservations', '{yelp.com/reservations}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (54, 'Pegasus', '{pegasus.io,pegs.io}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (55, 'TravelTripper / Pegasus', '{traveltrip.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (56, 'OwnerReservations', '{ownerreservations.com,secure.ownerreservations.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (57, 'GuestRoomGenie', '{guestroomgenie.com,secure.guestroomgenie.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (58, 'Beyond Pricing', '{beyondpricing.com,beacon.beyondpricing.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (59, 'HotelKey', '{hotelkeyapp.com,booking.hotelkeyapp.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (60, 'Preno', '{prenohq.com,bookdirect.prenohq.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (61, 'Channel Manager AU', '{channelmanager.com.au,app.channelmanager.com.au}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (62, 'OfficialBookings', '{officialbookings.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (63, 'BookingMood', '{bookingmood.com,widget.bookingmood.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (64, 'Seekda / KUBE', '{seekda.com,kube.seekda.com,booking.seekda.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (65, 'StayDirectly', '{staydirectly.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (66, 'Rentrax', '{rentrax.io}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (67, 'Profitroom', '{profitroom.com,booking.profitroom.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (68, 'Avvio', '{avvio.com,booking.avvio.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (69, 'Net Affinity', '{netaffinity.com,booking.netaffinity.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (70, 'Simplotel', '{simplotel.com,booking.simplotel.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (71, 'Cubilis', '{cubilis.com,booking.cubilis.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (72, 'Cendyn', '{cendyn.com,booking.cendyn.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (73, 'BookLogic', '{booklogic.net,booking.booklogic.net}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (74, 'RateTiger', '{ratetiger.com,booking.ratetiger.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (75, 'D-Edge', '{d-edge.com,availpro.com,booking-ede.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (76, 'BookAssist', '{bookassist.com,booking.bookassist.org}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (77, 'GuestCentric', '{guestcentric.com,booking.guestcentric.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (78, 'Vertical Booking', '{verticalbooking.com,book.verticalbooking.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (79, 'Busy Rooms', '{busyrooms.com,booking.busyrooms.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (80, 'myHotel.io', '{myhotel.io}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (81, 'HotelSpider', '{hotelspider.com,be.hotelspider.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (82, 'Staah', '{staah.com,booking.staah.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (83, 'AxisRooms', '{axisrooms.com,booking.axisrooms.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (84, 'E4jConnect / VikBooking', '{e4jconnect.com,vikbooking.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (85, 'Apaleo', '{apaleo.com,app.apaleo.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (86, 'Clock PMS', '{clock-software.com,booking.clock-pms.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (87, 'Protel', '{protel.net,onity.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (88, 'Frontdesk Anywhere', '{frontdeskanywhere.com,booking.frontdeskanywhere.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (89, 'HotelTime', '{hoteltime.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (90, 'StayNTouch', '{stayntouch.com,rover.stayntouch.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (91, 'Oracle Opera', '{oracle.com/opera,opera-hotel.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (92, 'Infor HMS', '{infor.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (93, 'RoomCloud', '{roomcloud.net}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (94, 'Oaky', '{oaky.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (95, 'Revinate', '{revinate.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (96, 'TrustYou', '{trustyou.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (97, 'Escapia', '{escapia.com,homeaway.escapia.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (98, 'LiveRez', '{liverez.com,secure.liverez.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (99, 'Barefoot', '{barefoot.com,barefoot.systems}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (100, 'Track', '{trackhs.com,reserve.trackhs.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (101, 'Streamline VRS', '{streamlinevrs.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (102, 'iGMS', '{igms.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (103, 'Smoobu', '{smoobu.com,login.smoobu.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (104, 'Tokeet', '{tokeet.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (105, '365Villas', '{365villas.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (106, 'Rentals United', '{rentalsunited.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (107, 'BookingSync', '{bookingsync.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (108, 'JANIIS', '{janiis.com,secure.janiis.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (109, 'Quibble', '{quibblerm.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (110, 'HiRUM', '{hirum.com.au,book.hirum.com.au}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (111, 'iBooked', '{ibooked.net.au,secure.ibooked.net.au}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (112, 'Seekom', '{seekom.com,book.seekom.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (113, 'ResPax', '{respax.com,app.respax.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (114, 'BookingCenter', '{bookingcenter.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (115, 'RezExpert', '{rezexpert.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (116, 'SuperControl', '{supercontrol.co.uk,members.supercontrol.co.uk}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (117, 'Anytime Booking', '{anytimebooking.eu,anytimebooking.co.uk}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (118, 'Elina PMS', '{elinapms.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (119, 'Guestline', '{guestline.com,booking.guestline.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (120, 'Nonius', '{nonius.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (121, 'Visual Matrix', '{visualmatrix.com,pms.visualmatrix.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (122, 'AutoClerk', '{autoclerk.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (123, 'MSI', '{msisolutions.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (124, 'SkyTouch', '{skytouch.com,pms.skytouch.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (125, 'RoomKeyPMS', '{roomkeypms.com,secure.roomkeypms.com}', 1, true);
INSERT INTO sadie_gtm.booking_engines VALUES (126, 'proprietary_or_same_domain', '{islandsofmiami.com}', 2, true);


--
-- Data for Name: detection_errors; Type: TABLE DATA; Schema: sadie_gtm; Owner: -
--

INSERT INTO sadie_gtm.detection_errors VALUES (1, 18, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 20:13:06.415228');
INSERT INTO sadie_gtm.detection_errors VALUES (2, 24, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 20:13:06.47341');
INSERT INTO sadie_gtm.detection_errors VALUES (3, 42, 'precheck_failed', 'precheck_failed: connection_refused', NULL, '2026-01-14 20:13:06.477096');
INSERT INTO sadie_gtm.detection_errors VALUES (4, 45, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 20:13:06.481226');
INSERT INTO sadie_gtm.detection_errors VALUES (5, 46, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 20:13:06.485144');
INSERT INTO sadie_gtm.detection_errors VALUES (6, 63, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 20:13:06.488947');
INSERT INTO sadie_gtm.detection_errors VALUES (7, 83, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 20:13:06.494639');
INSERT INTO sadie_gtm.detection_errors VALUES (8, 23, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 20:13:06.498556');
INSERT INTO sadie_gtm.detection_errors VALUES (9, 43, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 20:13:06.502495');
INSERT INTO sadie_gtm.detection_errors VALUES (10, 80, 'location_mismatch', 'location_mismatch', 'Paris', '2026-01-14 20:13:06.509251');
INSERT INTO sadie_gtm.detection_errors VALUES (11, 81, 'location_mismatch', 'location_mismatch', 'Paris', '2026-01-14 20:13:06.513168');
INSERT INTO sadie_gtm.detection_errors VALUES (12, 82, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 20:13:06.51736');
INSERT INTO sadie_gtm.detection_errors VALUES (13, 84, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 20:13:06.521425');
INSERT INTO sadie_gtm.detection_errors VALUES (14, 85, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 20:13:06.525336');
INSERT INTO sadie_gtm.detection_errors VALUES (15, 88, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 20:13:06.536765');
INSERT INTO sadie_gtm.detection_errors VALUES (16, 89, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 20:13:06.540306');
INSERT INTO sadie_gtm.detection_errors VALUES (17, 90, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 20:13:06.543667');
INSERT INTO sadie_gtm.detection_errors VALUES (18, 423, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:48:46.151332');
INSERT INTO sadie_gtm.detection_errors VALUES (19, 424, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:48:46.222849');
INSERT INTO sadie_gtm.detection_errors VALUES (20, 425, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:48:46.228603');
INSERT INTO sadie_gtm.detection_errors VALUES (21, 427, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:48:46.23292');
INSERT INTO sadie_gtm.detection_errors VALUES (22, 431, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:48:46.23613');
INSERT INTO sadie_gtm.detection_errors VALUES (23, 432, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:48:46.243039');
INSERT INTO sadie_gtm.detection_errors VALUES (24, 433, 'precheck_failed', 'precheck_failed: connection_refused', NULL, '2026-01-14 21:48:46.247063');
INSERT INTO sadie_gtm.detection_errors VALUES (25, 434, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:48:46.251885');
INSERT INTO sadie_gtm.detection_errors VALUES (26, 435, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:48:46.258209');
INSERT INTO sadie_gtm.detection_errors VALUES (27, 436, 'precheck_failed', 'precheck_failed: connection_refused', NULL, '2026-01-14 21:48:46.263495');
INSERT INTO sadie_gtm.detection_errors VALUES (28, 437, 'precheck_failed', 'precheck_failed: connection_refused', NULL, '2026-01-14 21:48:46.266954');
INSERT INTO sadie_gtm.detection_errors VALUES (29, 441, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:48:46.272718');
INSERT INTO sadie_gtm.detection_errors VALUES (30, 426, 'location_mismatch', 'location_mismatch', 'Bangkok', '2026-01-14 21:48:46.277137');
INSERT INTO sadie_gtm.detection_errors VALUES (31, 438, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:48:46.300642');
INSERT INTO sadie_gtm.detection_errors VALUES (32, 439, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:48:46.303892');
INSERT INTO sadie_gtm.detection_errors VALUES (33, 440, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:48:46.30761');
INSERT INTO sadie_gtm.detection_errors VALUES (34, 444, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:48:46.317538');
INSERT INTO sadie_gtm.detection_errors VALUES (35, 225, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:49:07.098524');
INSERT INTO sadie_gtm.detection_errors VALUES (36, 226, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:49:07.118239');
INSERT INTO sadie_gtm.detection_errors VALUES (37, 231, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:49:07.125443');
INSERT INTO sadie_gtm.detection_errors VALUES (38, 235, 'precheck_failed', 'precheck_failed: Server disconnected without sending a response.', NULL, '2026-01-14 21:49:07.1381');
INSERT INTO sadie_gtm.detection_errors VALUES (39, 236, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:49:07.14787');
INSERT INTO sadie_gtm.detection_errors VALUES (40, 239, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:49:07.154652');
INSERT INTO sadie_gtm.detection_errors VALUES (41, 240, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:49:07.162919');
INSERT INTO sadie_gtm.detection_errors VALUES (42, 242, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:49:07.168714');
INSERT INTO sadie_gtm.detection_errors VALUES (43, 244, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:49:07.175306');
INSERT INTO sadie_gtm.detection_errors VALUES (44, 245, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:49:07.181562');
INSERT INTO sadie_gtm.detection_errors VALUES (45, 238, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:49:07.218987');
INSERT INTO sadie_gtm.detection_errors VALUES (46, 413, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:49:09.160439');
INSERT INTO sadie_gtm.detection_errors VALUES (47, 420, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:49:09.171291');
INSERT INTO sadie_gtm.detection_errors VALUES (48, 402, 'location_mismatch', 'location_mismatch', 'Paris', '2026-01-14 21:49:09.178854');
INSERT INTO sadie_gtm.detection_errors VALUES (49, 403, 'location_mismatch', 'location_mismatch', 'Paris', '2026-01-14 21:49:09.187007');
INSERT INTO sadie_gtm.detection_errors VALUES (50, 404, 'location_mismatch', 'location_mismatch', 'Paris', '2026-01-14 21:49:09.194687');
INSERT INTO sadie_gtm.detection_errors VALUES (51, 405, 'location_mismatch', 'location_mismatch', 'Paris', '2026-01-14 21:49:09.201329');
INSERT INTO sadie_gtm.detection_errors VALUES (52, 407, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:49:09.21357');
INSERT INTO sadie_gtm.detection_errors VALUES (53, 408, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:49:09.220192');
INSERT INTO sadie_gtm.detection_errors VALUES (54, 409, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:49:09.226637');
INSERT INTO sadie_gtm.detection_errors VALUES (55, 410, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:49:09.234521');
INSERT INTO sadie_gtm.detection_errors VALUES (56, 411, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:49:09.242029');
INSERT INTO sadie_gtm.detection_errors VALUES (57, 412, 'no_booking_found', 'no_booking_found', NULL, '2026-01-14 21:49:09.249717');
INSERT INTO sadie_gtm.detection_errors VALUES (58, 421, 'location_mismatch', 'location_mismatch', 'Melbourne', '2026-01-14 21:49:09.286056');
INSERT INTO sadie_gtm.detection_errors VALUES (59, 199, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:49:19.362712');
INSERT INTO sadie_gtm.detection_errors VALUES (60, 201, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:49:19.377961');
INSERT INTO sadie_gtm.detection_errors VALUES (61, 210, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:49:19.388333');
INSERT INTO sadie_gtm.detection_errors VALUES (62, 214, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:49:19.39578');
INSERT INTO sadie_gtm.detection_errors VALUES (63, 208, 'location_mismatch', 'location_mismatch', 'London', '2026-01-14 21:49:19.466134');
INSERT INTO sadie_gtm.detection_errors VALUES (64, 215, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:49:19.484239');
INSERT INTO sadie_gtm.detection_errors VALUES (65, 216, 'location_mismatch', 'location_mismatch', 'London', '2026-01-14 21:49:19.489207');
INSERT INTO sadie_gtm.detection_errors VALUES (66, 533, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:49:56.633398');
INSERT INTO sadie_gtm.detection_errors VALUES (67, 534, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:49:56.694657');
INSERT INTO sadie_gtm.detection_errors VALUES (68, 536, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:49:56.700602');
INSERT INTO sadie_gtm.detection_errors VALUES (69, 537, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:49:56.704777');
INSERT INTO sadie_gtm.detection_errors VALUES (70, 539, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:49:56.708792');
INSERT INTO sadie_gtm.detection_errors VALUES (71, 540, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:49:56.713401');
INSERT INTO sadie_gtm.detection_errors VALUES (72, 543, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:49:56.717542');
INSERT INTO sadie_gtm.detection_errors VALUES (73, 546, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:49:56.721597');
INSERT INTO sadie_gtm.detection_errors VALUES (74, 548, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:49:56.725718');
INSERT INTO sadie_gtm.detection_errors VALUES (75, 551, 'precheck_failed', 'precheck_failed: connection_refused', NULL, '2026-01-14 21:49:56.72948');
INSERT INTO sadie_gtm.detection_errors VALUES (76, 547, 'no_booking_found', 'no_booking_found', NULL, '2026-01-14 21:49:56.745794');
INSERT INTO sadie_gtm.detection_errors VALUES (77, 553, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:49:56.753539');
INSERT INTO sadie_gtm.detection_errors VALUES (78, 554, 'location_mismatch', 'location_mismatch', 'London', '2026-01-14 21:49:56.757757');
INSERT INTO sadie_gtm.detection_errors VALUES (79, 555, 'location_mismatch', 'location_mismatch', 'London', '2026-01-14 21:49:56.762231');
INSERT INTO sadie_gtm.detection_errors VALUES (80, 556, 'location_mismatch', 'location_mismatch', 'Paris', '2026-01-14 21:49:56.766026');
INSERT INTO sadie_gtm.detection_errors VALUES (81, 558, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:49:56.76928');
INSERT INTO sadie_gtm.detection_errors VALUES (82, 559, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:49:56.772458');
INSERT INTO sadie_gtm.detection_errors VALUES (83, 513, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:50:09.450526');
INSERT INTO sadie_gtm.detection_errors VALUES (84, 516, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:09.463661');
INSERT INTO sadie_gtm.detection_errors VALUES (85, 520, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:09.470402');
INSERT INTO sadie_gtm.detection_errors VALUES (86, 522, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:09.476954');
INSERT INTO sadie_gtm.detection_errors VALUES (87, 523, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:50:09.484078');
INSERT INTO sadie_gtm.detection_errors VALUES (88, 524, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:09.489064');
INSERT INTO sadie_gtm.detection_errors VALUES (89, 529, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:09.498595');
INSERT INTO sadie_gtm.detection_errors VALUES (90, 530, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:09.504437');
INSERT INTO sadie_gtm.detection_errors VALUES (91, 505, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:50:09.542019');
INSERT INTO sadie_gtm.detection_errors VALUES (92, 506, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:50:09.549865');
INSERT INTO sadie_gtm.detection_errors VALUES (93, 507, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:50:09.556805');
INSERT INTO sadie_gtm.detection_errors VALUES (94, 508, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:50:09.563652');
INSERT INTO sadie_gtm.detection_errors VALUES (95, 511, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:50:09.571673');
INSERT INTO sadie_gtm.detection_errors VALUES (96, 512, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:50:09.580738');
INSERT INTO sadie_gtm.detection_errors VALUES (97, 514, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:50:09.594503');
INSERT INTO sadie_gtm.detection_errors VALUES (98, 517, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:50:09.604298');
INSERT INTO sadie_gtm.detection_errors VALUES (99, 518, 'no_booking_found', 'no_booking_found', NULL, '2026-01-14 21:50:09.609164');
INSERT INTO sadie_gtm.detection_errors VALUES (100, 525, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:50:09.612792');
INSERT INTO sadie_gtm.detection_errors VALUES (101, 247, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:16.353675');
INSERT INTO sadie_gtm.detection_errors VALUES (102, 252, 'precheck_failed', 'precheck_failed: connection_refused', NULL, '2026-01-14 21:50:16.36732');
INSERT INTO sadie_gtm.detection_errors VALUES (103, 253, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:16.375412');
INSERT INTO sadie_gtm.detection_errors VALUES (104, 254, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:16.382719');
INSERT INTO sadie_gtm.detection_errors VALUES (105, 255, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:16.389736');
INSERT INTO sadie_gtm.detection_errors VALUES (106, 263, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:50:16.396806');
INSERT INTO sadie_gtm.detection_errors VALUES (107, 251, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:50:16.417538');
INSERT INTO sadie_gtm.detection_errors VALUES (108, 258, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:50:16.42989');
INSERT INTO sadie_gtm.detection_errors VALUES (109, 261, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:50:16.433776');
INSERT INTO sadie_gtm.detection_errors VALUES (110, 266, 'location_mismatch', 'location_mismatch', 'London', '2026-01-14 21:50:16.440445');
INSERT INTO sadie_gtm.detection_errors VALUES (111, 272, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:50:16.455326');
INSERT INTO sadie_gtm.detection_errors VALUES (112, 274, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:18.640549');
INSERT INTO sadie_gtm.detection_errors VALUES (113, 278, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:18.65117');
INSERT INTO sadie_gtm.detection_errors VALUES (114, 280, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:18.658536');
INSERT INTO sadie_gtm.detection_errors VALUES (115, 281, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:18.665642');
INSERT INTO sadie_gtm.detection_errors VALUES (116, 284, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:50:18.672639');
INSERT INTO sadie_gtm.detection_errors VALUES (117, 294, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:50:18.679318');
INSERT INTO sadie_gtm.detection_errors VALUES (118, 296, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:18.685247');
INSERT INTO sadie_gtm.detection_errors VALUES (119, 275, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:50:18.699579');
INSERT INTO sadie_gtm.detection_errors VALUES (120, 285, 'location_mismatch', 'location_mismatch', 'Paris', '2026-01-14 21:50:18.732678');
INSERT INTO sadie_gtm.detection_errors VALUES (121, 287, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:50:18.739306');
INSERT INTO sadie_gtm.detection_errors VALUES (122, 288, 'location_mismatch', 'location_mismatch', 'Paris', '2026-01-14 21:50:18.74485');
INSERT INTO sadie_gtm.detection_errors VALUES (123, 291, 'location_mismatch', 'location_mismatch', 'Paris', '2026-01-14 21:50:18.750502');
INSERT INTO sadie_gtm.detection_errors VALUES (124, 292, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:50:18.755849');
INSERT INTO sadie_gtm.detection_errors VALUES (125, 295, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:50:18.764532');
INSERT INTO sadie_gtm.detection_errors VALUES (126, 445, 'precheck_failed', 'precheck_failed: connection_refused', NULL, '2026-01-14 21:50:23.786247');
INSERT INTO sadie_gtm.detection_errors VALUES (127, 475, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.786239');
INSERT INTO sadie_gtm.detection_errors VALUES (128, 446, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.800887');
INSERT INTO sadie_gtm.detection_errors VALUES (129, 447, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.808113');
INSERT INTO sadie_gtm.detection_errors VALUES (130, 448, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.813411');
INSERT INTO sadie_gtm.detection_errors VALUES (131, 452, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.819336');
INSERT INTO sadie_gtm.detection_errors VALUES (132, 454, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.82323');
INSERT INTO sadie_gtm.detection_errors VALUES (133, 455, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.826511');
INSERT INTO sadie_gtm.detection_errors VALUES (134, 457, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.829727');
INSERT INTO sadie_gtm.detection_errors VALUES (135, 458, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.833605');
INSERT INTO sadie_gtm.detection_errors VALUES (136, 476, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.834617');
INSERT INTO sadie_gtm.detection_errors VALUES (137, 459, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.837222');
INSERT INTO sadie_gtm.detection_errors VALUES (138, 478, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.83848');
INSERT INTO sadie_gtm.detection_errors VALUES (139, 460, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.841098');
INSERT INTO sadie_gtm.detection_errors VALUES (140, 479, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.842324');
INSERT INTO sadie_gtm.detection_errors VALUES (141, 462, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.845242');
INSERT INTO sadie_gtm.detection_errors VALUES (142, 480, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.846577');
INSERT INTO sadie_gtm.detection_errors VALUES (143, 464, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.849573');
INSERT INTO sadie_gtm.detection_errors VALUES (144, 481, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.850543');
INSERT INTO sadie_gtm.detection_errors VALUES (145, 465, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.853435');
INSERT INTO sadie_gtm.detection_errors VALUES (146, 483, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.854435');
INSERT INTO sadie_gtm.detection_errors VALUES (147, 466, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.857434');
INSERT INTO sadie_gtm.detection_errors VALUES (148, 486, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.858369');
INSERT INTO sadie_gtm.detection_errors VALUES (149, 468, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.861034');
INSERT INTO sadie_gtm.detection_errors VALUES (150, 487, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.861974');
INSERT INTO sadie_gtm.detection_errors VALUES (151, 469, 'precheck_failed', 'precheck_failed: connection_refused', NULL, '2026-01-14 21:50:23.864282');
INSERT INTO sadie_gtm.detection_errors VALUES (152, 492, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.864868');
INSERT INTO sadie_gtm.detection_errors VALUES (153, 470, 'precheck_failed', 'precheck_failed: connection_refused', NULL, '2026-01-14 21:50:23.867003');
INSERT INTO sadie_gtm.detection_errors VALUES (154, 494, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.867591');
INSERT INTO sadie_gtm.detection_errors VALUES (155, 471, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.869077');
INSERT INTO sadie_gtm.detection_errors VALUES (156, 495, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.869588');
INSERT INTO sadie_gtm.detection_errors VALUES (157, 473, 'precheck_failed', 'precheck_failed: connection_refused', NULL, '2026-01-14 21:50:23.870975');
INSERT INTO sadie_gtm.detection_errors VALUES (158, 496, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:23.871563');
INSERT INTO sadie_gtm.detection_errors VALUES (159, 101, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:24.46248');
INSERT INTO sadie_gtm.detection_errors VALUES (160, 497, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:24.462843');
INSERT INTO sadie_gtm.detection_errors VALUES (161, 102, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:24.474952');
INSERT INTO sadie_gtm.detection_errors VALUES (162, 498, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:24.477548');
INSERT INTO sadie_gtm.detection_errors VALUES (163, 103, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:24.48303');
INSERT INTO sadie_gtm.detection_errors VALUES (164, 499, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:24.485936');
INSERT INTO sadie_gtm.detection_errors VALUES (165, 104, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:24.489899');
INSERT INTO sadie_gtm.detection_errors VALUES (166, 105, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:50:24.496419');
INSERT INTO sadie_gtm.detection_errors VALUES (167, 500, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:24.496928');
INSERT INTO sadie_gtm.detection_errors VALUES (168, 106, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:24.501847');
INSERT INTO sadie_gtm.detection_errors VALUES (169, 501, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:24.504212');
INSERT INTO sadie_gtm.detection_errors VALUES (170, 107, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:24.508582');
INSERT INTO sadie_gtm.detection_errors VALUES (171, 503, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:24.51023');
INSERT INTO sadie_gtm.detection_errors VALUES (172, 109, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:24.514669');
INSERT INTO sadie_gtm.detection_errors VALUES (173, 504, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:24.515959');
INSERT INTO sadie_gtm.detection_errors VALUES (174, 111, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:24.519661');
INSERT INTO sadie_gtm.detection_errors VALUES (175, 112, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:25.151159');
INSERT INTO sadie_gtm.detection_errors VALUES (176, 113, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:25.164019');
INSERT INTO sadie_gtm.detection_errors VALUES (177, 114, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:25.17192');
INSERT INTO sadie_gtm.detection_errors VALUES (178, 93, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:25.181533');
INSERT INTO sadie_gtm.detection_errors VALUES (179, 94, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:25.192716');
INSERT INTO sadie_gtm.detection_errors VALUES (180, 95, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:25.207705');
INSERT INTO sadie_gtm.detection_errors VALUES (181, 96, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:25.215868');
INSERT INTO sadie_gtm.detection_errors VALUES (182, 97, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:25.223486');
INSERT INTO sadie_gtm.detection_errors VALUES (183, 98, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:25.235172');
INSERT INTO sadie_gtm.detection_errors VALUES (184, 99, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:25.243638');
INSERT INTO sadie_gtm.detection_errors VALUES (185, 100, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:25.251415');
INSERT INTO sadie_gtm.detection_errors VALUES (186, 115, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:41.501152');
INSERT INTO sadie_gtm.detection_errors VALUES (187, 116, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:41.514427');
INSERT INTO sadie_gtm.detection_errors VALUES (188, 120, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:41.519522');
INSERT INTO sadie_gtm.detection_errors VALUES (189, 121, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:41.525265');
INSERT INTO sadie_gtm.detection_errors VALUES (190, 124, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:41.533589');
INSERT INTO sadie_gtm.detection_errors VALUES (191, 125, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:50:41.538332');
INSERT INTO sadie_gtm.detection_errors VALUES (192, 126, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:41.542925');
INSERT INTO sadie_gtm.detection_errors VALUES (193, 127, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:41.548164');
INSERT INTO sadie_gtm.detection_errors VALUES (194, 128, 'precheck_failed', 'precheck_failed: connection_refused', NULL, '2026-01-14 21:50:41.552662');
INSERT INTO sadie_gtm.detection_errors VALUES (195, 129, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:50:41.556527');
INSERT INTO sadie_gtm.detection_errors VALUES (196, 139, 'precheck_failed', 'precheck_failed: connection_refused', NULL, '2026-01-14 21:50:41.560685');
INSERT INTO sadie_gtm.detection_errors VALUES (197, 118, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:50:41.569069');
INSERT INTO sadie_gtm.detection_errors VALUES (198, 130, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:50:41.584376');
INSERT INTO sadie_gtm.detection_errors VALUES (199, 131, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:50:41.587229');
INSERT INTO sadie_gtm.detection_errors VALUES (200, 134, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:50:41.590599');
INSERT INTO sadie_gtm.detection_errors VALUES (201, 136, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:50:41.593446');
INSERT INTO sadie_gtm.detection_errors VALUES (202, 143, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:51:26.118959');
INSERT INTO sadie_gtm.detection_errors VALUES (203, 145, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:51:26.169547');
INSERT INTO sadie_gtm.detection_errors VALUES (204, 148, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:51:26.173531');
INSERT INTO sadie_gtm.detection_errors VALUES (205, 149, 'precheck_failed', 'precheck_failed: connection_refused', NULL, '2026-01-14 21:51:26.177655');
INSERT INTO sadie_gtm.detection_errors VALUES (206, 151, 'precheck_failed', 'precheck_failed: connection_refused', NULL, '2026-01-14 21:51:26.180789');
INSERT INTO sadie_gtm.detection_errors VALUES (207, 152, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:51:26.184196');
INSERT INTO sadie_gtm.detection_errors VALUES (208, 155, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:51:26.187961');
INSERT INTO sadie_gtm.detection_errors VALUES (209, 158, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:51:26.191796');
INSERT INTO sadie_gtm.detection_errors VALUES (210, 159, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:51:26.195179');
INSERT INTO sadie_gtm.detection_errors VALUES (211, 160, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:51:26.199125');
INSERT INTO sadie_gtm.detection_errors VALUES (212, 162, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:51:26.202208');
INSERT INTO sadie_gtm.detection_errors VALUES (213, 140, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:51:26.205233');
INSERT INTO sadie_gtm.detection_errors VALUES (214, 141, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:51:26.208084');
INSERT INTO sadie_gtm.detection_errors VALUES (215, 142, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:51:26.211123');
INSERT INTO sadie_gtm.detection_errors VALUES (216, 146, 'no_booking_found', 'no_booking_found', NULL, '2026-01-14 21:51:26.213874');
INSERT INTO sadie_gtm.detection_errors VALUES (217, 150, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:51:26.218079');
INSERT INTO sadie_gtm.detection_errors VALUES (218, 154, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:51:26.221028');
INSERT INTO sadie_gtm.detection_errors VALUES (219, 156, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:51:26.223437');
INSERT INTO sadie_gtm.detection_errors VALUES (220, 157, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:51:26.2255');
INSERT INTO sadie_gtm.detection_errors VALUES (221, 379, 'precheck_failed', 'precheck_failed: connection_refused', NULL, '2026-01-14 21:51:42.74752');
INSERT INTO sadie_gtm.detection_errors VALUES (222, 382, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:51:42.777089');
INSERT INTO sadie_gtm.detection_errors VALUES (223, 384, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:51:42.784818');
INSERT INTO sadie_gtm.detection_errors VALUES (224, 390, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:51:42.792666');
INSERT INTO sadie_gtm.detection_errors VALUES (225, 391, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:51:42.800402');
INSERT INTO sadie_gtm.detection_errors VALUES (226, 392, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:51:42.806765');
INSERT INTO sadie_gtm.detection_errors VALUES (227, 397, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:51:42.811274');
INSERT INTO sadie_gtm.detection_errors VALUES (228, 398, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:51:42.816587');
INSERT INTO sadie_gtm.detection_errors VALUES (229, 399, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:51:42.821887');
INSERT INTO sadie_gtm.detection_errors VALUES (230, 400, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:51:42.82688');
INSERT INTO sadie_gtm.detection_errors VALUES (231, 383, 'location_mismatch', 'location_mismatch', 'Paris', '2026-01-14 21:51:42.8568');
INSERT INTO sadie_gtm.detection_errors VALUES (232, 387, 'location_mismatch', 'location_mismatch', 'London', '2026-01-14 21:51:42.860635');
INSERT INTO sadie_gtm.detection_errors VALUES (233, 394, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:51:42.873349');
INSERT INTO sadie_gtm.detection_errors VALUES (234, 401, 'location_mismatch', 'location_mismatch', 'Paris', '2026-01-14 21:51:42.87725');
INSERT INTO sadie_gtm.detection_errors VALUES (235, 164, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:51:47.465535');
INSERT INTO sadie_gtm.detection_errors VALUES (236, 167, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:51:47.473973');
INSERT INTO sadie_gtm.detection_errors VALUES (237, 171, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:51:47.478884');
INSERT INTO sadie_gtm.detection_errors VALUES (238, 181, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:51:47.486118');
INSERT INTO sadie_gtm.detection_errors VALUES (239, 189, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:51:47.492552');
INSERT INTO sadie_gtm.detection_errors VALUES (240, 178, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:51:47.535045');
INSERT INTO sadie_gtm.detection_errors VALUES (241, 183, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:51:47.539004');
INSERT INTO sadie_gtm.detection_errors VALUES (242, 186, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:51:47.543434');
INSERT INTO sadie_gtm.detection_errors VALUES (243, 187, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:51:47.546799');
INSERT INTO sadie_gtm.detection_errors VALUES (244, 191, 'location_mismatch', 'location_mismatch', 'London', '2026-01-14 21:51:47.552175');
INSERT INTO sadie_gtm.detection_errors VALUES (245, 192, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:51:47.556044');
INSERT INTO sadie_gtm.detection_errors VALUES (246, 363, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:51:52.904175');
INSERT INTO sadie_gtm.detection_errors VALUES (247, 370, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:51:52.923156');
INSERT INTO sadie_gtm.detection_errors VALUES (248, 376, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:51:52.930402');
INSERT INTO sadie_gtm.detection_errors VALUES (249, 352, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:51:52.938149');
INSERT INTO sadie_gtm.detection_errors VALUES (250, 354, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:51:52.945521');
INSERT INTO sadie_gtm.detection_errors VALUES (251, 355, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:51:52.952102');
INSERT INTO sadie_gtm.detection_errors VALUES (252, 356, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:51:52.958148');
INSERT INTO sadie_gtm.detection_errors VALUES (253, 359, 'location_mismatch', 'location_mismatch', 'Milan', '2026-01-14 21:51:52.966459');
INSERT INTO sadie_gtm.detection_errors VALUES (254, 360, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:51:52.972276');
INSERT INTO sadie_gtm.detection_errors VALUES (255, 365, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:51:52.983402');
INSERT INTO sadie_gtm.detection_errors VALUES (256, 366, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:51:52.988274');
INSERT INTO sadie_gtm.detection_errors VALUES (257, 368, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:51:52.996646');
INSERT INTO sadie_gtm.detection_errors VALUES (258, 369, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:51:53.000699');
INSERT INTO sadie_gtm.detection_errors VALUES (259, 371, 'location_mismatch', 'location_mismatch', 'Paris', '2026-01-14 21:51:53.004375');
INSERT INTO sadie_gtm.detection_errors VALUES (260, 321, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:52:27.801099');
INSERT INTO sadie_gtm.detection_errors VALUES (261, 323, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:52:27.816942');
INSERT INTO sadie_gtm.detection_errors VALUES (262, 324, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:52:27.823046');
INSERT INTO sadie_gtm.detection_errors VALUES (263, 326, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:52:27.830624');
INSERT INTO sadie_gtm.detection_errors VALUES (264, 334, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:52:27.837313');
INSERT INTO sadie_gtm.detection_errors VALUES (265, 339, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:52:27.842955');
INSERT INTO sadie_gtm.detection_errors VALUES (266, 342, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:52:27.8487');
INSERT INTO sadie_gtm.detection_errors VALUES (267, 343, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:52:27.855237');
INSERT INTO sadie_gtm.detection_errors VALUES (268, 345, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:52:27.859668');
INSERT INTO sadie_gtm.detection_errors VALUES (269, 347, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:52:27.863671');
INSERT INTO sadie_gtm.detection_errors VALUES (270, 348, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:52:27.871949');
INSERT INTO sadie_gtm.detection_errors VALUES (271, 350, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:52:27.87551');
INSERT INTO sadie_gtm.detection_errors VALUES (272, 351, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:52:27.879186');
INSERT INTO sadie_gtm.detection_errors VALUES (273, 327, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:52:27.890082');
INSERT INTO sadie_gtm.detection_errors VALUES (274, 330, 'location_mismatch', 'location_mismatch', 'London', '2026-01-14 21:52:27.895184');
INSERT INTO sadie_gtm.detection_errors VALUES (275, 331, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:52:27.898755');
INSERT INTO sadie_gtm.detection_errors VALUES (276, 336, 'location_mismatch', 'location_mismatch', 'London', '2026-01-14 21:52:27.902134');
INSERT INTO sadie_gtm.detection_errors VALUES (277, 337, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:52:27.906738');
INSERT INTO sadie_gtm.detection_errors VALUES (278, 297, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:52:36.647492');
INSERT INTO sadie_gtm.detection_errors VALUES (279, 298, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:52:36.671822');
INSERT INTO sadie_gtm.detection_errors VALUES (280, 300, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:52:36.678338');
INSERT INTO sadie_gtm.detection_errors VALUES (281, 301, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:52:36.696067');
INSERT INTO sadie_gtm.detection_errors VALUES (282, 307, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:52:36.700382');
INSERT INTO sadie_gtm.detection_errors VALUES (283, 311, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:52:36.705076');
INSERT INTO sadie_gtm.detection_errors VALUES (284, 312, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:52:36.710485');
INSERT INTO sadie_gtm.detection_errors VALUES (285, 313, 'precheck_failed', 'precheck_failed: connection_refused', NULL, '2026-01-14 21:52:36.714902');
INSERT INTO sadie_gtm.detection_errors VALUES (286, 315, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:52:36.7184');
INSERT INTO sadie_gtm.detection_errors VALUES (287, 318, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:52:36.721325');
INSERT INTO sadie_gtm.detection_errors VALUES (288, 319, 'precheck_failed', 'precheck_failed: connection_refused', NULL, '2026-01-14 21:52:36.724191');
INSERT INTO sadie_gtm.detection_errors VALUES (289, 302, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:52:36.728733');
INSERT INTO sadie_gtm.detection_errors VALUES (290, 303, 'location_mismatch', 'location_mismatch', 'Bali', '2026-01-14 21:52:36.73142');
INSERT INTO sadie_gtm.detection_errors VALUES (291, 305, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:52:36.734752');
INSERT INTO sadie_gtm.detection_errors VALUES (292, 69, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:52:48.350976');
INSERT INTO sadie_gtm.detection_errors VALUES (293, 70, 'precheck_failed', 'precheck_failed: connection_refused', NULL, '2026-01-14 21:52:48.370924');
INSERT INTO sadie_gtm.detection_errors VALUES (294, 71, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:52:48.379323');
INSERT INTO sadie_gtm.detection_errors VALUES (295, 77, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:52:48.387786');
INSERT INTO sadie_gtm.detection_errors VALUES (296, 48, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:52:48.396849');
INSERT INTO sadie_gtm.detection_errors VALUES (297, 53, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:52:48.405602');
INSERT INTO sadie_gtm.detection_errors VALUES (298, 38, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:53:01.923185');
INSERT INTO sadie_gtm.detection_errors VALUES (299, 29, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:53:01.937833');
INSERT INTO sadie_gtm.detection_errors VALUES (300, 30, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:53:01.946918');
INSERT INTO sadie_gtm.detection_errors VALUES (301, 31, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:53:01.956376');
INSERT INTO sadie_gtm.detection_errors VALUES (302, 34, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:53:01.968518');
INSERT INTO sadie_gtm.detection_errors VALUES (303, 36, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:53:01.977121');
INSERT INTO sadie_gtm.detection_errors VALUES (304, 41, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:53:01.984199');
INSERT INTO sadie_gtm.detection_errors VALUES (305, 47, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:53:01.991617');
INSERT INTO sadie_gtm.detection_errors VALUES (306, 55, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:53:01.997619');
INSERT INTO sadie_gtm.detection_errors VALUES (307, 58, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:53:02.001699');
INSERT INTO sadie_gtm.detection_errors VALUES (308, 59, 'precheck_failed', 'precheck_failed: HTTP 404', NULL, '2026-01-14 21:53:02.005376');
INSERT INTO sadie_gtm.detection_errors VALUES (309, 60, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:53:02.00967');
INSERT INTO sadie_gtm.detection_errors VALUES (310, 602, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:53:02.013939');
INSERT INTO sadie_gtm.detection_errors VALUES (311, 27, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:53:02.025841');
INSERT INTO sadie_gtm.detection_errors VALUES (312, 32, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:53:02.029891');
INSERT INTO sadie_gtm.detection_errors VALUES (313, 565, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:53:07.096987');
INSERT INTO sadie_gtm.detection_errors VALUES (314, 572, 'precheck_failed', 'precheck_failed: timeout', NULL, '2026-01-14 21:53:07.10911');
INSERT INTO sadie_gtm.detection_errors VALUES (315, 573, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:53:07.116838');
INSERT INTO sadie_gtm.detection_errors VALUES (316, 577, 'precheck_failed', 'precheck_failed: HTTP 403', NULL, '2026-01-14 21:53:07.124763');
INSERT INTO sadie_gtm.detection_errors VALUES (317, 579, 'precheck_failed', 'precheck_failed: HTTP 404', NULL, '2026-01-14 21:53:07.133065');
INSERT INTO sadie_gtm.detection_errors VALUES (318, 560, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:53:07.143364');
INSERT INTO sadie_gtm.detection_errors VALUES (319, 562, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:53:07.151242');
INSERT INTO sadie_gtm.detection_errors VALUES (320, 576, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:53:07.164801');
INSERT INTO sadie_gtm.detection_errors VALUES (321, 585, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:53:07.170394');
INSERT INTO sadie_gtm.detection_errors VALUES (322, 587, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:53:07.178183');
INSERT INTO sadie_gtm.detection_errors VALUES (323, 588, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:53:07.187373');
INSERT INTO sadie_gtm.detection_errors VALUES (324, 592, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:53:07.192802');
INSERT INTO sadie_gtm.detection_errors VALUES (325, 594, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:53:07.203464');
INSERT INTO sadie_gtm.detection_errors VALUES (326, 595, 'location_mismatch', 'location_mismatch', 'Rome', '2026-01-14 21:53:07.208144');
INSERT INTO sadie_gtm.detection_errors VALUES (327, 596, 'no_booking_found', 'no_booking_found', 'Miami', '2026-01-14 21:53:07.211902');


--
-- Data for Name: existing_customers; Type: TABLE DATA; Schema: sadie_gtm; Owner: -
--

INSERT INTO sadie_gtm.existing_customers VALUES (1, 'Flamingo Hotel', 'S005796', '0101000020E61000002B2DC83BACC452C0D66E6017EA2D4340', NULL, NULL, 'Maryland', 'USA', 'active', '2025-05-21', '2026-01-14 23:35:38.370629');
INSERT INTO sadie_gtm.existing_customers VALUES (2, 'The Burgundy Inn', 'S005840', '0101000020E610000083F92B642EC552C07E0A3664F22B4340', NULL, NULL, 'Maryland', 'USA', 'active', '2025-07-04', '2026-01-14 23:35:38.408506');
INSERT INTO sadie_gtm.existing_customers VALUES (3, 'The Spinnaker Motel', 'S005844', '0101000020E61000008FA339B2F2C452C01D588E90812C4340', NULL, NULL, 'Maryland', 'USA', 'active', '2025-07-02', '2026-01-14 23:35:38.410673');
INSERT INTO sadie_gtm.existing_customers VALUES (4, 'Echo Bluff State Park', 'S005859', '0101000020E610000071395E81E8D956C0FC790904F0A74240', NULL, NULL, 'Missouri', 'USA', 'active', '2025-07-17', '2026-01-14 23:35:38.412397');
INSERT INTO sadie_gtm.existing_customers VALUES (5, 'The Lodge at Mammoth Cave', 'S005861', '0101000020E610000056FC95847A8655C0EA9DC02ACD974240', NULL, NULL, 'Kentucky', 'USA', 'active', '2025-08-28', '2026-01-14 23:35:38.414074');
INSERT INTO sadie_gtm.existing_customers VALUES (6, 'Surf Side Hotel', 'S005863', '0101000020E6100000D2A755F487E652C0B054BC36C0F54140', NULL, NULL, 'North Carolina', 'USA', 'active', '2025-07-27', '2026-01-14 23:35:38.415517');
INSERT INTO sadie_gtm.existing_customers VALUES (7, 'Ocean Island Inn | Backpackers |', 'S005909', '0101000020E610000008D04AB52AD75EC012F39B78BD364840', NULL, NULL, 'British Columbia', 'CA', 'active', '2025-09-15', '2026-01-14 23:35:38.416979');
INSERT INTO sadie_gtm.existing_customers VALUES (8, 'CCBC Resort Hotel', 'S005935', '0101000020E61000002BED1EEA081E5DC019C00067CEE34040', NULL, NULL, 'California', 'USA', 'active', '2025-11-20', '2026-01-14 23:35:38.418277');
INSERT INTO sadie_gtm.existing_customers VALUES (9, 'Eden Roc Motel', 'S005997', '0101000020E610000023DBF97EEAC452C04F5AB8ACC22C4340', NULL, NULL, 'Maryland', 'USA', 'active', '2025-11-28', '2026-01-14 23:35:38.419661');
INSERT INTO sadie_gtm.existing_customers VALUES (10, 'Manning Park Resort', 'S005963', '0101000020E61000008E5DFD335E325EC0ED2D403624884840', NULL, NULL, 'British Columbia', 'CA', 'active', '2025-11-28', '2026-01-14 23:35:38.421023');
INSERT INTO sadie_gtm.existing_customers VALUES (11, 'Altoona Grand Hotel', 'S005981', '0101000020E61000005C3F5821409A53C0350708E6E83A4440', NULL, NULL, 'Pennsylvania', 'USA', 'active', '2025-12-02', '2026-01-14 23:35:38.422392');
INSERT INTO sadie_gtm.existing_customers VALUES (12, 'Blue Strawberry by the Sea', 'S005949', '0101000020E61000003336CF6C320654C0C1A2C794B42F3A40', NULL, NULL, 'Florida', 'USA', 'active', '2025-12-22', '2026-01-14 23:35:38.423569');
INSERT INTO sadie_gtm.existing_customers VALUES (13, 'Sea Garden By The Sea Inc', 'S005945', '0101000020E610000079FE59982A0654C05AD6FD6321323A40', NULL, NULL, 'Florida', 'USA', 'active', '2025-12-22', '2026-01-14 23:35:38.42483');
INSERT INTO sadie_gtm.existing_customers VALUES (14, 'Horizon By the Sea', 'S005942', '0101000020E6100000F5C3BE53370654C0240F9FCFDB2F3A40', NULL, NULL, 'Florida', 'USA', 'active', '2025-12-22', '2026-01-14 23:35:38.426246');
INSERT INTO sadie_gtm.existing_customers VALUES (15, 'The Castle By The Sea', 'S005946', '0101000020E61000000F406A13270654C0E9AC60657E313A40', NULL, NULL, 'Florida', 'USA', 'active', '2025-12-22', '2026-01-14 23:35:38.427541');
INSERT INTO sadie_gtm.existing_customers VALUES (16, 'Blackfin Resort & Marina', 'S006434', '0101000020E610000098A59D9A4B4554C0D25048D7F1B63840', NULL, NULL, 'Florida', 'USA', 'active', '2025-12-18', '2026-01-14 23:35:38.428833');
INSERT INTO sadie_gtm.existing_customers VALUES (17, 'Sea Dell Motel', 'S006217', '0101000020E610000011667F45234554C03B78DCA62EB73840', NULL, NULL, 'Florida', 'USA', 'active', '2025-12-18', '2026-01-14 23:35:38.43004');
INSERT INTO sadie_gtm.existing_customers VALUES (18, 'Osprey Hotel', 'S006003', '0101000020E6100000F7FB6AB3D67755C020AA3AF592363E40', NULL, NULL, 'Florida', 'USA', 'active', NULL, '2026-01-14 23:35:38.431117');
INSERT INTO sadie_gtm.existing_customers VALUES (19, 'The Driftwood Lodge', 'S006363', '0101000020E6100000A11EEC5EB81654C0463DE9E9C8A63B40', NULL, NULL, 'Florida', 'USA', 'active', NULL, '2026-01-14 23:35:38.432288');
INSERT INTO sadie_gtm.existing_customers VALUES (20, 'Penguin Hotel', 'S006397', '0101000020E61000000DB386414F0854C030A248522DC93940', NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.433424');
INSERT INTO sadie_gtm.existing_customers VALUES (21, 'Beach Bum Inn', 'S006444', '0101000020E6100000AA25C22B6EC552C083AC0210D22A4340', NULL, NULL, 'Maryland', 'USA', 'active', NULL, '2026-01-14 23:35:38.434521');
INSERT INTO sadie_gtm.existing_customers VALUES (22, 'Beach Bum West-O', 'S006396', '0101000020E61000003AE40BFF0EC852C0B7FEA72C542B4340', NULL, NULL, 'Maryland', 'USA', 'active', NULL, '2026-01-14 23:35:38.435555');
INSERT INTO sadie_gtm.existing_customers VALUES (23, 'Wood River Inn & Suites', 'S006334', '0101000020E6100000AD742D1073945CC0C332912D26C34540', NULL, NULL, 'Idaho', 'USA', 'active', NULL, '2026-01-14 23:35:38.436609');
INSERT INTO sadie_gtm.existing_customers VALUES (24, 'The Americana Hotel', 'S005824', '0101000020E6100000EBEAE97E29C552C0324976B6912B4340', NULL, NULL, 'Maryland', 'USA', 'active', NULL, '2026-01-14 23:35:38.437562');
INSERT INTO sadie_gtm.existing_customers VALUES (25, 'Americana Motor Inn', 'S005825', '0101000020E6100000CE5FD7E54AC552C0376277CB1F2B4340', NULL, NULL, 'Maryland', 'USA', 'active', NULL, '2026-01-14 23:35:38.438379');
INSERT INTO sadie_gtm.existing_customers VALUES (26, 'Kings Arms Motel', 'S005826', '0101000020E6100000DD90EB4BDBC452C0B5C6A013422D4340', NULL, NULL, 'Maryland', 'USA', 'active', NULL, '2026-01-14 23:35:38.439271');
INSERT INTO sadie_gtm.existing_customers VALUES (27, 'The Landing Hub', 'N/A', '0101000020E61000007BE7AB3F9DAF56C0D2167C3FDA3E4340', NULL, NULL, 'Missouri', 'USA', 'active', NULL, '2026-01-14 23:35:38.440142');
INSERT INTO sadie_gtm.existing_customers VALUES (28, 'Lodge at Five Oaks Pigeon Forge Sevier', 'S005846', '0101000020E6100000B65FE39FBEE454C02A60A7FD7BEA4140', NULL, NULL, 'Tennessee', 'USA', 'active', NULL, '2026-01-14 23:35:38.440953');
INSERT INTO sadie_gtm.existing_customers VALUES (29, 'Appalachian Lodge', 'S005860', '0101000020E6100000CD2DBEB29CE054C087C7D9CFBDDC4140', NULL, NULL, 'Tennessee', 'USA', 'active', NULL, '2026-01-14 23:35:38.441736');
INSERT INTO sadie_gtm.existing_customers VALUES (30, 'Old Creek Lodge', 'S005857', '0101000020E61000001385F12E72E154C04FDC3BB4D9DA4140', NULL, NULL, 'Tennessee', 'USA', 'active', NULL, '2026-01-14 23:35:38.442448');
INSERT INTO sadie_gtm.existing_customers VALUES (31, 'Bearskin Lodge', 'S005856', '0101000020E6100000B187F6B182E154C07C7DAD4B8DDA4140', NULL, NULL, 'Tennessee', 'USA', 'active', NULL, '2026-01-14 23:35:38.443201');
INSERT INTO sadie_gtm.existing_customers VALUES (32, 'Trianon Bonita Bay', 'S005961', '0101000020E610000093CB7F48BF7354C0A35BAFE941593A40', NULL, NULL, 'Florida', 'USA', 'active', NULL, '2026-01-14 23:35:38.443989');
INSERT INTO sadie_gtm.existing_customers VALUES (33, 'DominionHill', 'N/A', '0101000020E61000000865D0BF93BD50C0369D537F73974640', NULL, NULL, 'New Brunswick', 'CA', 'active', NULL, '2026-01-14 23:35:38.444806');
INSERT INTO sadie_gtm.existing_customers VALUES (34, 'White Sands Beach Resort', 'S005970', '0101000020E6100000B5673B4B35AE54C0F866E5A8ED823B40', NULL, NULL, 'Florida', 'USA', 'active', NULL, '2026-01-14 23:35:38.445552');
INSERT INTO sadie_gtm.existing_customers VALUES (35, 'Four Seasons on the Gulf', 'N/A', '0101000020E6100000C689AF7694B357C0AC0E6F8C53473D40', NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.446411');
INSERT INTO sadie_gtm.existing_customers VALUES (36, 'The Kendall', 'N/A', '0101000020E61000002A60F18A96C551C0352F3D505D2E4540', NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.447188');
INSERT INTO sadie_gtm.existing_customers VALUES (37, 'Parador MaunaCaribe', 'S006426', '0101000020E6100000D69D38CA0B7850C074982F2FC0003240', NULL, NULL, NULL, 'USA', 'active', '2025-12-19', '2026-01-14 23:35:38.447877');
INSERT INTO sadie_gtm.existing_customers VALUES (38, 'Lyf Bondi Junction', 'N/A', '0101000020E6100000BE2D58AA0BE86240CAF9073653F240C0', NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.448611');
INSERT INTO sadie_gtm.existing_customers VALUES (39, 'Grassy Flats', 'N/A', '0101000020E610000016C90D750E3D54C0C8F19E5E84C23840', NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.449296');
INSERT INTO sadie_gtm.existing_customers VALUES (40, 'Dolphin Oceanfront', 'S006441', '0101000020E610000058A76F3E1AE652C098BED7101CF44140', NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.450115');
INSERT INTO sadie_gtm.existing_customers VALUES (41, 'John Yancey Inn', 'S006350', '0101000020E6100000FDB8A23957E952C07602F5C18DFF4140', NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.451041');
INSERT INTO sadie_gtm.existing_customers VALUES (42, 'Warroad Casino', 'S006399', '0101000020E610000094A531B500D357C040203C7F7F734840', NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.451826');
INSERT INTO sadie_gtm.existing_customers VALUES (43, 'Red Lake Casino', 'S006400', '0101000020E61000001A321EA592C157C00DB6227BCEE64740', NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.452612');
INSERT INTO sadie_gtm.existing_customers VALUES (44, 'Thief River Casino', 'S006401', '0101000020E6100000CE305AEC1B0258C0A370E25064024840', NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.45329');
INSERT INTO sadie_gtm.existing_customers VALUES (45, 'The Lighthouse Inn', 'N/A', '0101000020E61000002EE00ACD9A0B5FC0F88C446804E04440', NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.453962');
INSERT INTO sadie_gtm.existing_customers VALUES (46, 'Hotel Royal Oak', 'N/A', '0101000020E610000063586A62A6C854C0EB8612D2BF3E4540', NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.454626');
INSERT INTO sadie_gtm.existing_customers VALUES (47, 'The Caribbean Court', 'S006477', '0101000020E61000007C5DD08C8F1654C022D5C10B6CA13B40', NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.455406');
INSERT INTO sadie_gtm.existing_customers VALUES (48, 'Aqua Aire Inn & Suites', 'N/A', '0101000020E6100000BFA7284D396D56C01EE4501AC5EF4640', NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.456159');
INSERT INTO sadie_gtm.existing_customers VALUES (49, 'Santa Fe Motel & Inn', 'N/A', '0101000020E610000084D382177D7C5AC01624C7E75FD74140', NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.456827');
INSERT INTO sadie_gtm.existing_customers VALUES (50, 'The Carrignton Inn', NULL, '0101000020E6100000A4F0EA6610AE6240026ECCA1FBA041C0', NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.457566');
INSERT INTO sadie_gtm.existing_customers VALUES (51, 'Serenite 1', 'N/A', NULL, NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.458259');
INSERT INTO sadie_gtm.existing_customers VALUES (52, 'Serenite 2', 'N/A', NULL, NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.459741');
INSERT INTO sadie_gtm.existing_customers VALUES (53, 'Serenite 3', 'N/A', '0101000020E610000002E9071AD8D652C04183A856BA874440', NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.460853');
INSERT INTO sadie_gtm.existing_customers VALUES (54, 'Serenite 4', 'N/A', '0101000020E610000002E9071AD8D652C04183A856BA874440', NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.461634');
INSERT INTO sadie_gtm.existing_customers VALUES (55, 'Hotel Pepper Tree', 'N/A', '0101000020E6100000081F4AB4E47D5DC0B6EE8BF09BEA4040', NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.462445');
INSERT INTO sadie_gtm.existing_customers VALUES (56, 'Orchid Key Inn', 'S005925', '0101000020E6100000739AAA202B7354C05808066BF78C3840', NULL, NULL, 'Florida', 'USA', 'active', NULL, '2026-01-14 23:35:38.463175');
INSERT INTO sadie_gtm.existing_customers VALUES (57, 'The Almond Tree Inn', 'S005926', '0101000020E6100000DC5A1597197354C0EEE87FB9168D3840', NULL, NULL, 'Florida', 'USA', 'active', NULL, '2026-01-14 23:35:38.463961');
INSERT INTO sadie_gtm.existing_customers VALUES (58, 'Log Cabin Resort', NULL, '0101000020E61000004B2366F679F25EC06F6182BF040C4840', NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.464616');
INSERT INTO sadie_gtm.existing_customers VALUES (59, 'Lake Crescent Lodge', NULL, '0101000020E6100000F18288D434F35EC06FCD678A4A074840', NULL, NULL, NULL, 'USA', 'active', NULL, '2026-01-14 23:35:38.465318');
INSERT INTO sadie_gtm.existing_customers VALUES (60, 'Sherry Frontenac Hotel', 'S005971', '0101000020E61000007D957CECAE0754C034D021156BD93940', NULL, NULL, 'Florida', 'USA', 'active', NULL, '2026-01-14 23:35:38.466043');


--
-- Data for Name: hotel_booking_engines; Type: TABLE DATA; Schema: sadie_gtm; Owner: -
--

INSERT INTO sadie_gtm.hotel_booking_engines VALUES (17, 1, 'https://www.extendedstayamerica.com/reservations/index.html?siteId=1760&propertyCode=EA%3B2697&checkIn=2026-01-14&checkOut=2026-01-21&rateType=ESH&roomRateCode=EPERKW&rateName=Exclusive+Member+Rate&adult=1&child=0&roomCode=STD1QN&room=1&bookingCode=EPERKW&code=&hotelRoomTypeId=957a2207-d862-4679-acd2-be442b339d7f&confirmationNumber=&analyticsPlanName=Exclusive+Member+Rate&roomNightlyRate=268.28&analyticsRateCode=ESH&loginRequiredForRate=true&rateGroup=EV1', 'homepage_html_scan', '2026-01-14 18:03:31.405522', '2026-01-14 18:03:31.405522');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (19, 2, 'https://be.synxis.com/?adult=1&arrive=2026-01-05&chain=27508&child=0&currency=USD&depart=2026-01-06&hotel=36146&level=hotel&locale=en-US&productcurrency=USD&promo=PROSUITE&rooms=1', 'homepage_html_scan', '2026-01-14 18:03:31.417028', '2026-01-14 18:03:31.417028');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (20, 2, 'https://be.synxis.com/?chain=10494', 'homepage_html_scan', '2026-01-14 18:03:31.422403', '2026-01-14 18:03:31.422403');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (13, 4, 'https://app.mews.com/distributor/257692e9-bda3-4a00-9623-b0290156cea0', 'homepage_html_scan', '2026-01-14 19:01:42.536451', '2026-01-14 19:01:42.536451');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (44, 126, 'https://www.islandsofmiami.com/', 'widget_interaction+same_domain', '2026-01-14 19:01:42.556615', '2026-01-14 19:01:42.556615');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (56, 126, 'https://nikkibeach.com/miami-beach/', 'widget_interaction+same_domain', '2026-01-14 19:01:42.570383', '2026-01-14 19:01:42.570383');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (57, 30, 'https://mylesrestaurantgroup.com/book-miami-beach-private-event-venue/', 'homepage_html_scan', '2026-01-14 19:01:42.575259', '2026-01-14 19:01:42.575259');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (68, 3, 'https://whistle.cloudbeds.com/201022/company/guestapp/17232/46199', 'homepage_html_scan', '2026-01-14 20:08:34.262529', '2026-01-14 20:08:34.262529');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (74, 47, 'https://static.guesty.com/ssrs/booking-engine-page/837/static/_next/static/css/94f0c1370489586d.css', 'href_extraction+network_sniff', '2026-01-14 20:08:34.27151', '2026-01-14 20:08:34.27151');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (86, 35, 'https://checkout.lodgify.com/en/rsr-rentals/589068/reservation?currency=EUR', 'homepage_html_scan', '2026-01-14 20:13:06.530337', '2026-01-14 20:13:06.530337');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (428, 126, 'https://www.sohohouse.com/houses/soho-beach-house?utm_source=google&utm_medium=organic&utm_campaign=googlemybusiness', 'widget_interaction+same_domain', '2026-01-14 21:48:46.284328', '2026-01-14 21:48:46.284328');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (429, 30, 'https://bellezahotel.com/rooms/', 'homepage_html_scan', '2026-01-14 21:48:46.291551', '2026-01-14 21:48:46.291551');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (442, 47, NULL, 'homepage_html_scan', '2026-01-14 21:48:46.312313', '2026-01-14 21:48:46.312313');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (221, 3, 'https://hotels.cloudbeds.com/reservation/rqEThz', 'homepage_html_scan', '2026-01-14 21:49:07.193132', '2026-01-14 21:49:07.193132');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (222, 3, 'https://hotels.cloudbeds.com/reservation/gNm8B0', 'homepage_html_scan', '2026-01-14 21:49:07.199697', '2026-01-14 21:49:07.199697');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (223, 3, 'https://hotels.cloudbeds.com/reservation/5M9aBd', 'homepage_html_scan', '2026-01-14 21:49:07.204473', '2026-01-14 21:49:07.204473');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (230, 2, 'https://be.synxis.com/?Hotel=47373&Chain=6063&config=Essex%202024&theme=Essex%202024&Room=ES1', 'homepage_html_scan', '2026-01-14 21:49:07.211195', '2026-01-14 21:49:07.211195');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (234, 14, 'https://www.presidentvillamiami.com/rooms/', 'homepage_html_scan', '2026-01-14 21:49:07.21598', '2026-01-14 21:49:07.21598');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (241, 26, 'https://theshepleyhotel.com/rooms/', 'homepage_html_scan', '2026-01-14 21:49:07.223312', '2026-01-14 21:49:07.223312');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (243, 47, 'https://static.guesty.com/ssrs/booking-engine-page/837/static/_next/static/css/94f0c1370489586d.css', 'href_extraction+network_sniff', '2026-01-14 21:49:07.226469', '2026-01-14 21:49:07.226469');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (406, 4, 'https://staygenerator.com/hotels/miami?utm_source=google-my-business&utm_medium=organic&utm_campaign=hostel-Miami#', 'homepage_html_scan', '2026-01-14 21:49:09.208335', '2026-01-14 21:49:09.208335');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (414, 3, 'https://hotels.cloudbeds.com/reservation/zx8WAT', 'homepage_html_scan', '2026-01-14 21:49:09.258057', '2026-01-14 21:49:09.258057');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (416, 1, 'https://guest.kasa.com', 'href_extraction+third_party_domain+homepage_network', '2026-01-14 21:49:09.263834', '2026-01-14 21:49:09.263834');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (418, 2, 'https://be.synxis.com/?adult=2&arrive=2026-01-14&chain=5321&child=0&currency=USD&depart=2026-01-18&hotel=12476&level=hotel&locale=en-U', 'homepage_html_scan+popup_page', '2026-01-14 21:49:09.274697', '2026-01-14 21:49:09.274697');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (419, 126, 'https://www.leparticuliermiami.com/bookingstep1?checkin=01%2F11%2F2025&idtokenprovider=100380141&currency=MXN&clientCode=&hsri=02040&lang=en&nights=2&parties=W3siYWR1bHRzIjoyLCJjaGlsZHJlbiI6W119XQ%3D%3D&type=hotel&step=1&home=https%3A%2F%2Fwww.leparticuliermiami.com%2F', 'href_extraction+same_domain', '2026-01-14 21:49:09.280981', '2026-01-14 21:49:09.280981');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (422, 100, 'https://lrmb.trackhs.com/guest/#!/login/', 'homepage_html_scan+href_extraction', '2026-01-14 21:49:09.291059', '2026-01-14 21:49:09.291059');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (198, 26, 'https://nassausuite.com/rooms/', 'homepage_html_scan', '2026-01-14 21:49:19.412267', '2026-01-14 21:49:19.412267');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (200, 126, 'https://boutiqueapartmentsmiami.hostify.club/', 'widget_interaction+same_domain', '2026-01-14 21:49:19.421031', '2026-01-14 21:49:19.421031');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (202, 2, 'https://bookings.travelclick.com/107603?adults=2&Children=0&domain=thehotelchelsea.com/&Rooms=1#/datesofstay', 'homepage_html_scan', '2026-01-14 21:49:19.428521', '2026-01-14 21:49:19.428521');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (204, 76, 'https://hotels.cloudbeds.com/', 'homepage_html_scan', '2026-01-14 21:49:19.437777', '2026-01-14 21:49:19.437777');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (205, 2, 'https://us2.cloudbeds.com/reservation/jfny3X', 'homepage_html_scan', '2026-01-14 21:49:19.448368', '2026-01-14 21:49:19.448368');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (206, 3, NULL, 'homepage_html_scan', '2026-01-14 21:49:19.454771', '2026-01-14 21:49:19.454771');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (207, 3, 'https://hotels.cloudbeds.com/en/reservation/p3OITk?currency=usd', 'homepage_html_scan', '2026-01-14 21:49:19.461089', '2026-01-14 21:49:19.461089');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (211, 1, 'https://onboard.triptease.io/bootstrap.js?integrationId=01F793T8DCZXKEZJ9E6SRG5R8V', 'href_extraction+network_sniff', '2026-01-14 21:49:19.471859', '2026-01-14 21:49:19.471859');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (213, 126, 'https://stayviax.com/booking-support', 'href_extraction+same_domain', '2026-01-14 21:49:19.478764', '2026-01-14 21:49:19.478764');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (217, 126, 'https://luxuri.com', 'href_extraction+same_domain', '2026-01-14 21:49:19.497174', '2026-01-14 21:49:19.497174');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (218, 46, 'https://bookingenginecdn.hostaway.com/account/attachment/88992-4XtVzzFY6HaCn4NHNnvgglORA00SatNq1qdV-3Hi5oc-690691686c54a?width=300&quality=70&format=webp&v=2', 'href_extraction+network_sniff', '2026-01-14 21:49:19.505624', '2026-01-14 21:49:19.505624');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (532, 33, 'https://fareharbor.com/embeds/book/mdqwatersports/?full-items=yes', 'homepage_html_scan', '2026-01-14 21:49:56.735822', '2026-01-14 21:49:56.735822');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (545, 126, 'https://www.noburestaurants.com/miami/reservations/', 'href_extraction+same_domain', '2026-01-14 21:49:56.741703', '2026-01-14 21:49:56.741703');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (552, 46, NULL, 'homepage_html_scan', '2026-01-14 21:49:56.749773', '2026-01-14 21:49:56.749773');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (527, 46, 'https://bookingenginecdn.hostaway.com/account/attachment/72087-XWh1XD8z9dyPJtyKb9f9QuBuF6msNgz92H1RsozVjO8-665ee73994833?width=300&quality=70&format=webp&v=2', 'href_extraction+network_sniff', '2026-01-14 21:50:09.616756', '2026-01-14 21:50:09.616756');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (528, 126, 'https://www.vacasa.com/', 'href_extraction+same_domain', '2026-01-14 21:50:09.620301', '2026-01-14 21:50:09.620301');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (246, 3, 'https://hotels.cloudbeds.com/reservation/g1lxD7', 'homepage_html_scan', '2026-01-14 21:50:16.40307', '2026-01-14 21:50:16.40307');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (248, 126, 'https://www.greystonehotel.com/?utm_source=google&utm_medium=organic&utm_campaign=business_listing#', 'navigation+same_domain', '2026-01-14 21:50:16.409043', '2026-01-14 21:50:16.409043');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (250, 2, 'https://be.synxis.com/?hotel=6465&rate=DSPROM', 'homepage_html_scan', '2026-01-14 21:50:16.413564', '2026-01-14 21:50:16.413564');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (256, 2, 'https://static.travelclick.com/web-component-sdk/amadeus-hos-res-ibe-wc-sdk/amadeus-hos-res-ibe-wc-sdk-latest/amadeus-hos-res-ibe-wc-sdk.bundle.js?tx=1401202621', 'href_extraction+network_sniff', '2026-01-14 21:50:16.421808', '2026-01-14 21:50:16.421808');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (257, 46, NULL, 'homepage_html_scan', '2026-01-14 21:50:16.426144', '2026-01-14 21:50:16.426144');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (265, 126, 'https://stayviax.com/booking-support', 'href_extraction+same_domain', '2026-01-14 21:50:16.437181', '2026-01-14 21:50:16.437181');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (268, 46, NULL, 'homepage_html_scan', '2026-01-14 21:50:16.444476', '2026-01-14 21:50:16.444476');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (269, 46, NULL, 'homepage_html_scan', '2026-01-14 21:50:16.4481', '2026-01-14 21:50:16.4481');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (270, 46, NULL, 'homepage_html_scan', '2026-01-14 21:50:16.452085', '2026-01-14 21:50:16.452085');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (273, 3, 'https://hotels.cloudbeds.com/en/reservation/ZY7r7U?currency=usd', 'homepage_html_scan', '2026-01-14 21:50:18.691172', '2026-01-14 21:50:18.691172');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (277, 126, 'https://www.casatualife.com/', 'widget_interaction+same_domain', '2026-01-14 21:50:18.710211', '2026-01-14 21:50:18.710211');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (279, 18, 'https://www.ihg.com/kimptonhotels/hotels/us/en/stay-mgmt/ManageYourStay', 'homepage_html_scan', '2026-01-14 21:50:18.718267', '2026-01-14 21:50:18.718267');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (283, 86, 'https://thekaskadeshotel.com/rooms/', 'homepage_html_scan', '2026-01-14 21:50:18.724275', '2026-01-14 21:50:18.724275');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (117, 2, 'https://be.synxis.com/signin?chain=33376&hotel=48554', 'homepage_html_scan', '2026-01-14 21:50:41.565053', '2026-01-14 21:50:41.565053');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (119, 2, 'https://be.synxis.com/?Hotel=42023&Chain=31158', 'homepage_html_scan', '2026-01-14 21:50:41.572816', '2026-01-14 21:50:41.572816');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (122, 3, 'https://hotels.cloudbeds.com/reservation/H2ureq#', 'homepage_html_scan', '2026-01-14 21:50:41.577365', '2026-01-14 21:50:41.577365');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (123, 126, 'https://www.luxurisuites.com/', 'href_extraction+same_domain', '2026-01-14 21:50:41.580988', '2026-01-14 21:50:41.580988');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (377, 2, 'https://www.ihg.com/redirect?path=hd&brandCode=6C&localeCode=en&regionCode=1&hotelCode=MIAVI&rateCode=IGCOR&cn=no', 'homepage_html_scan+navigation', '2026-01-14 21:51:42.834965', '2026-01-14 21:51:42.834965');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (378, 23, 'https://www.redsouthbeachhotel.com/rooms/', 'homepage_html_scan', '2026-01-14 21:51:42.845678', '2026-01-14 21:51:42.845678');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (381, 2, 'https://www.hotelcroydonmiamibeach.com/rooms-suites', 'homepage_html_scan', '2026-01-14 21:51:42.852396', '2026-01-14 21:51:42.852396');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (388, 126, 'https://www.globalluxurysuites.com/home/error/500', 'widget_interaction+same_domain', '2026-01-14 21:51:42.864997', '2026-01-14 21:51:42.864997');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (389, 1, 'https://staybeyondgreen.com/hotels/united-states/palms-hotel-spa', 'homepage_html_scan', '2026-01-14 21:51:42.869546', '2026-01-14 21:51:42.869546');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (163, 14, 'https://www.siteminder.com/canvas', 'homepage_html_scan', '2026-01-14 21:51:47.500341', '2026-01-14 21:51:47.500341');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (165, 46, 'https://bookingenginecdn.hostaway.com/account/attachment/88992-bsAUV2Yc3CE6zKhbW4G029ihTYHTsuFR9vlHwlsL6V8-68ffe2ede4803?width=300&quality=70&format=webp&v=2', 'href_extraction+network_sniff', '2026-01-14 21:51:47.506449', '2026-01-14 21:51:47.506449');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (166, 2, 'https://clevelandersouthbeach.tripleseat.com/booking_request/28971', 'homepage_html_scan', '2026-01-14 21:51:47.512687', '2026-01-14 21:51:47.512687');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (170, 2, 'https://www.phgsecure.com/IBE/bookingRedirect.ashx?propertyCode=MIAEM', 'homepage_html_scan', '2026-01-14 21:51:47.518521', '2026-01-14 21:51:47.518521');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (172, 1, 'https://www.thebetsyhotel.com/stay/book?startDate=2026-01-17&endDate=2026-01-20&adults=2&children=0&dogs=false%3Futm_source%3DDirect%20Rate%20Banner&utm_medium=Banner&utm_campaign=Direct%20Rate%20Banner', 'href_extraction+homepage_network', '2026-01-14 21:51:47.524389', '2026-01-14 21:51:47.524389');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (173, 26, 'https://lesliehotel.com/rooms/', 'homepage_html_scan', '2026-01-14 21:51:47.529037', '2026-01-14 21:51:47.529037');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (194, 2, 'https://be.synxis.com/?Hotel=34810&Chain=33137&promo=JANSALE', 'homepage_html_scan', '2026-01-14 21:51:47.560364', '2026-01-14 21:51:47.560364');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (195, 2, 'https://www.kenmorevillagehotel.com/rooms-suites', 'homepage_html_scan', '2026-01-14 21:51:47.564122', '2026-01-14 21:51:47.564122');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (364, 20, 'https://be.synxis.com/?Hotel=47819&Chain=33107', 'homepage_html_scan', '2026-01-14 21:51:52.97833', '2026-01-14 21:51:52.97833');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (367, 30, 'https://www.oasiscasitacollection.com/resorts/miami-beach/oasis/courtyard-apartments/', 'homepage_html_scan+widget_interaction', '2026-01-14 21:51:52.992915', '2026-01-14 21:51:52.992915');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (372, 30, NULL, 'homepage_html_scan', '2026-01-14 21:51:53.009826', '2026-01-14 21:51:53.009826');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (374, 2, 'https://be.synxis.com/signIn?&chain=24447&hotel=7030&src=30', 'homepage_html_scan', '2026-01-14 21:51:53.015427', '2026-01-14 21:51:53.015427');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (320, 1, 'https://onboard.triptease.io/bootstrap.js?integrationId=01DECT156J2CEM6S7AZRHDK387', 'href_extraction+network_sniff', '2026-01-14 21:52:27.885034', '2026-01-14 21:52:27.885034');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (341, 2, 'https://www.southbeachhotel.com/rooms', 'homepage_html_scan', '2026-01-14 21:52:27.911394', '2026-01-14 21:52:27.911394');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (308, 2, 'https://www.aquamiami.com/rooms', 'homepage_html_scan', '2026-01-14 21:52:36.738116', '2026-01-14 21:52:36.738116');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (309, 3, 'https://casahotelsgroup.com/book-now/casa-sobe/', 'homepage_html_scan', '2026-01-14 21:52:36.741609', '2026-01-14 21:52:36.741609');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (310, 2, 'https://www.theplymouth.com/rooms-and-suites', 'homepage_html_scan', '2026-01-14 21:52:36.744981', '2026-01-14 21:52:36.744981');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (314, 2, 'https://www.boulanmiami.com/rooms', 'homepage_html_scan', '2026-01-14 21:52:36.748213', '2026-01-14 21:52:36.748213');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (316, 44, 'https://be.hotelrunner.com/assets/js/booking-engine.js?instanceId=131da83c-ce46-4c4a-ad11-31bb59f72166', 'href_extraction+network_sniff', '2026-01-14 21:52:36.751631', '2026-01-14 21:52:36.751631');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (603, 46, 'mailto:reservations@alexanderhotel.com', 'homepage_html_scan+href_extraction', '2026-01-14 21:53:02.018518', '2026-01-14 21:53:02.018518');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (33, 18, 'https://www.ihg.com/kimptonhotels/hotels/us/en/stay-mgmt/ManageYourStay', 'homepage_html_scan', '2026-01-14 21:53:02.033618', '2026-01-14 21:53:02.033618');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (39, 47, 'https://static.guesty.com/production/ownersportal/static/static/js/main.c8ee4aa8.js', 'href_extraction+network_sniff', '2026-01-14 21:53:02.037867', '2026-01-14 21:53:02.037867');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (564, 2, 'https://www.oceansidehotelmiamibeach.com/rooms-suites/', 'homepage_html_scan', '2026-01-14 21:53:07.158891', '2026-01-14 21:53:07.158891');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (593, 46, 'mailto:reservations@alexanderhotel.com', 'homepage_html_scan+href_extraction', '2026-01-14 21:53:07.197932', '2026-01-14 21:53:07.197932');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (599, 47, 'https://www.whimstay.com/detail/Ocean-View-and-Direct-Beach-Access-Stunning-Coastal-Oasis/508250?isgoogle=true', 'homepage_html_scan+widget_interaction', '2026-01-14 21:53:07.219682', '2026-01-14 21:53:07.219682');
INSERT INTO sadie_gtm.hotel_booking_engines VALUES (601, 46, 'mailto:reservations@alexanderhotel.com', 'homepage_html_scan+href_extraction', '2026-01-14 21:53:07.225145', '2026-01-14 21:53:07.225145');


--
-- Data for Name: hotel_customer_proximity; Type: TABLE DATA; Schema: sadie_gtm; Owner: -
--

INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (1, 243, 20, 5.7, '2026-01-14 23:36:53.781392');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (2, 277, 20, 0.7, '2026-01-14 23:36:53.799844');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (3, 273, 20, 1.6, '2026-01-14 23:36:53.803276');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (4, 200, 20, 1.2, '2026-01-14 23:39:17.699957');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (5, 269, 20, 0.1, '2026-01-14 23:39:17.72953');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (6, 173, 20, 0.3, '2026-01-14 23:39:17.738216');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (7, 194, 20, 0.2, '2026-01-14 23:39:17.741432');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (8, 123, 20, 0.8, '2026-01-14 23:39:17.743795');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (9, 246, 20, 0.7, '2026-01-14 23:39:17.746148');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (10, 372, 20, 1.0, '2026-01-14 23:39:17.748203');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (11, 207, 20, 0.1, '2026-01-14 23:39:17.751001');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (12, 195, 20, 0.6, '2026-01-14 23:39:17.753993');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (13, 414, 20, 2.3, '2026-01-14 23:39:17.756414');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (14, 416, 20, 1.4, '2026-01-14 23:39:17.758351');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (15, 265, 20, 0.9, '2026-01-14 23:39:17.760545');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (16, 13, 60, 6.6, '2026-01-14 23:39:17.762659');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (17, 268, 20, 0.1, '2026-01-14 23:39:17.764911');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (18, 320, 20, 0.1, '2026-01-14 23:39:17.767199');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (19, 221, 20, 0.5, '2026-01-14 23:39:17.769384');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (20, 241, 20, 0.2, '2026-01-14 23:39:17.7717');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (21, 223, 20, 0.1, '2026-01-14 23:39:17.773587');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (22, 309, 20, 0.2, '2026-01-14 23:39:17.77573');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (23, 163, 20, 0.5, '2026-01-14 23:39:17.777653');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (24, 39, 20, 6.3, '2026-01-14 23:39:17.779618');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (25, 170, 20, 0.2, '2026-01-14 23:39:17.781616');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (26, 389, 20, 2.3, '2026-01-14 23:39:17.783419');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (27, 86, 20, 6.1, '2026-01-14 23:39:17.785375');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (28, 213, 20, 1.1, '2026-01-14 23:39:17.787126');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (29, 364, 20, 1.5, '2026-01-14 23:39:17.789259');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (30, 406, 20, 2.4, '2026-01-14 23:39:17.790926');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (31, 314, 20, 1.2, '2026-01-14 23:39:17.792725');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (32, 341, 20, 1.2, '2026-01-14 23:39:17.794485');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (33, 378, 20, 2.3, '2026-01-14 23:39:17.796161');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (34, 552, 60, 2.2, '2026-01-14 23:39:17.798489');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (35, 205, 20, 0.1, '2026-01-14 23:39:17.801057');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (36, 418, 60, 3.5, '2026-01-14 23:39:17.803223');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (37, 68, 20, 1.7, '2026-01-14 23:39:17.805105');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (38, 74, 20, 0.8, '2026-01-14 23:39:17.806765');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (39, 283, 20, 0.7, '2026-01-14 23:39:17.808787');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (40, 374, 20, 1.1, '2026-01-14 23:39:17.811479');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (41, 19, 20, 6.8, '2026-01-14 23:39:17.813505');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (42, 564, 60, 0.6, '2026-01-14 23:39:17.816943');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (43, 601, 60, 2.1, '2026-01-14 23:39:17.819062');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (44, 429, 20, 1.3, '2026-01-14 23:39:17.821739');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (45, 217, 20, 1.0, '2026-01-14 23:39:17.823591');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (46, 599, 60, 2.3, '2026-01-14 23:39:17.825634');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (47, 367, 20, 0.8, '2026-01-14 23:39:17.828974');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (48, 593, 60, 2.1, '2026-01-14 23:39:17.831302');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (49, 603, 60, 2.1, '2026-01-14 23:39:17.833711');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (50, 119, 20, 0.8, '2026-01-14 23:39:17.835615');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (51, 270, 20, 0.1, '2026-01-14 23:39:17.837679');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (52, 248, 20, 1.1, '2026-01-14 23:39:17.839596');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (53, 310, 20, 1.2, '2026-01-14 23:39:17.841508');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (54, 279, 20, 0.8, '2026-01-14 23:39:17.843563');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (55, 165, 20, 0.1, '2026-01-14 23:39:17.845525');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (56, 20, 20, 3.2, '2026-01-14 23:39:17.847629');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (57, 532, 60, 2.1, '2026-01-14 23:39:17.849926');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (58, 172, 20, 0.1, '2026-01-14 23:39:17.851909');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (59, 377, 20, 3.0, '2026-01-14 23:39:17.854955');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (60, 545, 60, 3.3, '2026-01-14 23:39:17.856806');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (61, 257, 20, 0.1, '2026-01-14 23:39:17.858896');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (62, 222, 20, 0.7, '2026-01-14 23:39:17.861423');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (63, 218, 20, 1.2, '2026-01-14 23:39:17.864227');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (64, 308, 20, 0.3, '2026-01-14 23:39:17.866559');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (65, 528, 60, 1.7, '2026-01-14 23:39:17.869135');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (66, 44, 20, 3.0, '2026-01-14 23:39:17.871113');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (67, 230, 20, 0.6, '2026-01-14 23:39:17.873264');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (68, 527, 60, 2.1, '2026-01-14 23:39:17.875273');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (69, 56, 20, 1.9, '2026-01-14 23:39:17.877858');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (70, 206, 20, 1.2, '2026-01-14 23:39:17.880056');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (71, 117, 20, 1.4, '2026-01-14 23:39:17.882179');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (72, 211, 20, 0.3, '2026-01-14 23:39:17.884346');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (73, 316, 20, 6.3, '2026-01-14 23:39:17.886186');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (74, 122, 20, 0.9, '2026-01-14 23:39:17.888587');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (75, 198, 20, 0.1, '2026-01-14 23:39:17.890381');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (76, 250, 20, 0.6, '2026-01-14 23:39:17.892286');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (77, 166, 20, 0.6, '2026-01-14 23:39:17.894119');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (78, 204, 20, 0.4, '2026-01-14 23:39:17.896207');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (79, 381, 20, 2.8, '2026-01-14 23:39:17.897729');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (80, 33, 20, 6.2, '2026-01-14 23:39:17.899646');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (81, 442, 20, 1.5, '2026-01-14 23:39:17.901502');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (82, 57, 20, 1.8, '2026-01-14 23:39:17.903189');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (83, 388, 20, 1.4, '2026-01-14 23:39:17.904973');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (84, 428, 20, 3.4, '2026-01-14 23:39:17.906863');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (85, 419, 20, 3.2, '2026-01-14 23:39:17.908503');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (86, 422, 20, 3.1, '2026-01-14 23:39:17.910601');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (87, 234, 20, 0.1, '2026-01-14 23:39:17.912631');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (88, 256, 20, 0.7, '2026-01-14 23:39:17.914637');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (89, 17, 20, 7.5, '2026-01-14 23:39:17.916925');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (90, 202, 20, 0.7, '2026-01-14 23:39:17.919146');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (91, 597, 60, 1.4, '2026-01-14 23:39:17.920813');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (92, 596, 60, 2.1, '2026-01-14 23:39:17.922409');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (93, 595, 60, 1.8, '2026-01-14 23:39:17.924057');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (94, 594, 60, 2.1, '2026-01-14 23:39:17.925639');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (95, 592, 60, 1.7, '2026-01-14 23:39:17.927239');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (96, 588, 60, 2.2, '2026-01-14 23:39:17.928929');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (97, 587, 60, 1.2, '2026-01-14 23:39:17.930496');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (98, 585, 60, 1.7, '2026-01-14 23:39:17.932274');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (99, 576, 60, 6.5, '2026-01-14 23:39:17.933946');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (100, 562, 20, 3.5, '2026-01-14 23:39:17.93565');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (101, 560, 60, 1.7, '2026-01-14 23:39:17.937333');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (102, 579, 60, 2.1, '2026-01-14 23:39:17.938831');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (103, 577, 60, 1.7, '2026-01-14 23:39:17.940452');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (104, 573, 60, 7.2, '2026-01-14 23:39:17.942633');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (105, 572, 60, 0.6, '2026-01-14 23:39:17.944319');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (106, 565, 60, 6.5, '2026-01-14 23:39:17.945985');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (107, 40, 20, 6.7, '2026-01-14 23:39:17.947734');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (108, 32, 20, 3.2, '2026-01-14 23:39:17.949508');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (109, 27, 20, 7.0, '2026-01-14 23:39:17.951286');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (110, 604, 60, 0.6, '2026-01-14 23:39:17.953132');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (111, 602, 60, 2.1, '2026-01-14 23:39:17.954738');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (112, 60, 20, 1.9, '2026-01-14 23:39:17.956211');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (113, 59, 20, 6.0, '2026-01-14 23:39:17.957716');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (114, 58, 20, 5.7, '2026-01-14 23:39:17.959235');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (115, 55, 20, 2.6, '2026-01-14 23:39:17.961307');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (116, 47, 20, 6.8, '2026-01-14 23:39:17.963281');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (117, 41, 20, 6.3, '2026-01-14 23:39:17.96491');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (118, 36, 20, 1.7, '2026-01-14 23:39:17.966588');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (119, 34, 20, 1.7, '2026-01-14 23:39:17.968226');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (120, 31, 20, 6.3, '2026-01-14 23:39:17.969875');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (121, 30, 20, 6.6, '2026-01-14 23:39:17.971494');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (122, 29, 20, 6.9, '2026-01-14 23:39:17.972979');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (123, 38, 20, 6.2, '2026-01-14 23:39:17.974568');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (124, 53, 20, 1.8, '2026-01-14 23:39:17.976082');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (125, 48, 20, 6.2, '2026-01-14 23:39:17.978194');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (126, 77, 20, 6.0, '2026-01-14 23:39:17.979859');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (127, 71, 20, 1.5, '2026-01-14 23:39:17.981443');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (128, 70, 20, 1.4, '2026-01-14 23:39:17.982928');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (129, 69, 20, 0.8, '2026-01-14 23:39:17.984642');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (130, 305, 20, 1.6, '2026-01-14 23:39:17.986606');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (131, 303, 20, 1.1, '2026-01-14 23:39:17.990084');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (132, 302, 20, 1.0, '2026-01-14 23:39:17.991676');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (133, 299, 20, 1.1, '2026-01-14 23:39:17.994038');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (134, 319, 20, 0.7, '2026-01-14 23:39:17.995649');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (135, 318, 20, 1.3, '2026-01-14 23:39:17.997203');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (136, 315, 20, 7.0, '2026-01-14 23:39:17.998709');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (137, 313, 20, 0.2, '2026-01-14 23:39:18.000191');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (138, 312, 20, 1.0, '2026-01-14 23:39:18.00486');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (139, 311, 20, 1.1, '2026-01-14 23:39:18.006434');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (140, 307, 20, 0.9, '2026-01-14 23:39:18.008102');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (141, 301, 20, 0.2, '2026-01-14 23:39:18.010539');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (142, 300, 20, 1.1, '2026-01-14 23:39:18.012938');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (143, 298, 20, 0.3, '2026-01-14 23:39:18.014792');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (144, 297, 20, 0.7, '2026-01-14 23:39:18.016452');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (145, 337, 20, 6.3, '2026-01-14 23:39:18.018056');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (146, 336, 20, 0.9, '2026-01-14 23:39:18.019768');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (147, 331, 20, 1.0, '2026-01-14 23:39:18.021621');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (148, 330, 20, 1.4, '2026-01-14 23:39:18.023122');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (149, 327, 20, 5.7, '2026-01-14 23:39:18.024585');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (150, 351, 20, 1.1, '2026-01-14 23:39:18.026147');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (151, 350, 20, 0.7, '2026-01-14 23:39:18.02777');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (152, 348, 20, 1.7, '2026-01-14 23:39:18.029435');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (153, 347, 20, 1.4, '2026-01-14 23:39:18.030922');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (154, 345, 20, 2.7, '2026-01-14 23:39:18.032579');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (155, 343, 20, 1.6, '2026-01-14 23:39:18.034081');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (156, 342, 20, 0.9, '2026-01-14 23:39:18.035554');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (157, 339, 20, 5.7, '2026-01-14 23:39:18.037105');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (158, 334, 20, 5.7, '2026-01-14 23:39:18.038753');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (159, 326, 20, 0.6, '2026-01-14 23:39:18.040582');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (160, 324, 20, 0.8, '2026-01-14 23:39:18.042976');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (161, 323, 20, 6.0, '2026-01-14 23:39:18.044488');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (162, 321, 20, 0.7, '2026-01-14 23:39:18.046491');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (163, 375, 20, 2.5, '2026-01-14 23:39:18.048349');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (164, 371, 20, 0.7, '2026-01-14 23:39:18.050002');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (165, 369, 20, 0.3, '2026-01-14 23:39:18.051595');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (166, 368, 20, 1.5, '2026-01-14 23:39:18.053444');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (167, 366, 20, 0.5, '2026-01-14 23:39:18.055472');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (168, 365, 20, 1.3, '2026-01-14 23:39:18.05794');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (169, 360, 20, 0.6, '2026-01-14 23:39:18.059672');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (170, 359, 20, 1.1, '2026-01-14 23:39:18.061399');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (171, 358, 20, 0.7, '2026-01-14 23:39:18.063147');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (172, 356, 20, 1.2, '2026-01-14 23:39:18.066356');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (173, 355, 20, 1.2, '2026-01-14 23:39:18.068335');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (174, 354, 20, 1.2, '2026-01-14 23:39:18.069972');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (175, 352, 20, 1.1, '2026-01-14 23:39:18.071501');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (176, 376, 20, 2.4, '2026-01-14 23:39:18.073061');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (177, 370, 20, 1.0, '2026-01-14 23:39:18.074774');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (178, 363, 20, 1.1, '2026-01-14 23:39:18.076423');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (179, 192, 20, 6.1, '2026-01-14 23:39:18.07876');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (180, 191, 20, 6.2, '2026-01-14 23:39:18.080455');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (181, 187, 20, 6.2, '2026-01-14 23:39:18.082174');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (182, 186, 20, 6.2, '2026-01-14 23:39:18.084326');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (183, 183, 20, 1.8, '2026-01-14 23:39:18.086248');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (184, 178, 20, 5.7, '2026-01-14 23:39:18.088246');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (185, 177, 20, 5.6, '2026-01-14 23:39:18.089948');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (186, 189, 20, 6.6, '2026-01-14 23:39:18.091567');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (187, 181, 20, 6.1, '2026-01-14 23:39:18.093262');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (188, 171, 20, 0.3, '2026-01-14 23:39:18.095076');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (189, 167, 20, 1.4, '2026-01-14 23:39:18.096905');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (190, 164, 20, 0.7, '2026-01-14 23:39:18.098594');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (191, 401, 20, 0.4, '2026-01-14 23:39:18.100581');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (192, 394, 20, 2.4, '2026-01-14 23:39:18.102367');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (193, 387, 20, 0.9, '2026-01-14 23:39:18.104207');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (194, 383, 20, 0.1, '2026-01-14 23:39:18.106051');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (195, 380, 20, 2.7, '2026-01-14 23:39:18.10778');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (196, 400, 20, 2.9, '2026-01-14 23:39:18.109377');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (197, 399, 20, 0.9, '2026-01-14 23:39:18.110935');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (198, 398, 20, 1.2, '2026-01-14 23:39:18.113046');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (199, 397, 20, 0.9, '2026-01-14 23:39:18.115321');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (200, 392, 20, 1.5, '2026-01-14 23:39:18.117642');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (201, 391, 20, 1.2, '2026-01-14 23:39:18.119324');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (202, 390, 20, 1.1, '2026-01-14 23:39:18.120826');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (203, 384, 20, 1.3, '2026-01-14 23:39:18.122088');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (204, 382, 20, 0.1, '2026-01-14 23:39:18.123376');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (205, 379, 20, 1.4, '2026-01-14 23:39:18.124799');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (206, 157, 20, 1.2, '2026-01-14 23:39:18.126718');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (207, 156, 20, 0.9, '2026-01-14 23:39:18.128339');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (208, 154, 20, 1.3, '2026-01-14 23:39:18.129906');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (209, 150, 20, 1.3, '2026-01-14 23:39:18.131566');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (210, 147, 20, 1.4, '2026-01-14 23:39:18.133707');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (211, 146, 20, 0.9, '2026-01-14 23:39:18.135376');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (212, 142, 20, 1.1, '2026-01-14 23:39:18.136953');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (213, 141, 20, 1.4, '2026-01-14 23:39:18.138612');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (214, 140, 20, 1.1, '2026-01-14 23:39:18.140149');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (215, 162, 20, 0.3, '2026-01-14 23:39:18.141606');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (216, 160, 20, 1.4, '2026-01-14 23:39:18.143179');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (217, 159, 20, 1.0, '2026-01-14 23:39:18.14467');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (218, 158, 20, 1.6, '2026-01-14 23:39:18.146488');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (219, 155, 20, 1.3, '2026-01-14 23:39:18.148263');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (220, 152, 20, 1.1, '2026-01-14 23:39:18.150461');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (221, 151, 20, 0.8, '2026-01-14 23:39:18.151929');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (222, 149, 20, 0.8, '2026-01-14 23:39:18.153409');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (223, 148, 20, 1.2, '2026-01-14 23:39:18.155062');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (224, 145, 20, 1.0, '2026-01-14 23:39:18.156715');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (225, 143, 20, 0.8, '2026-01-14 23:39:18.15819');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (226, 136, 20, 1.3, '2026-01-14 23:39:18.159744');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (227, 134, 20, 0.8, '2026-01-14 23:39:18.161294');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (228, 131, 20, 1.4, '2026-01-14 23:39:18.163028');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (229, 130, 20, 1.0, '2026-01-14 23:39:18.164956');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (230, 118, 20, 1.5, '2026-01-14 23:39:18.167006');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (231, 139, 20, 1.3, '2026-01-14 23:39:18.168621');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (232, 129, 20, 1.6, '2026-01-14 23:39:18.170268');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (233, 128, 20, 1.3, '2026-01-14 23:39:18.172403');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (234, 127, 20, 1.3, '2026-01-14 23:39:18.173922');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (235, 126, 20, 1.2, '2026-01-14 23:39:18.175466');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (236, 125, 20, 1.6, '2026-01-14 23:39:18.176991');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (237, 124, 20, 0.8, '2026-01-14 23:39:18.178655');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (238, 121, 20, 0.8, '2026-01-14 23:39:18.180277');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (239, 120, 20, 1.4, '2026-01-14 23:39:18.181811');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (240, 116, 20, 1.4, '2026-01-14 23:39:18.183336');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (241, 115, 20, 1.3, '2026-01-14 23:39:18.185028');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (242, 100, 20, 0.8, '2026-01-14 23:39:18.18682');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (243, 99, 20, 1.0, '2026-01-14 23:39:18.188372');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (244, 98, 20, 1.4, '2026-01-14 23:39:18.189912');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (245, 97, 20, 0.8, '2026-01-14 23:39:18.191481');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (246, 96, 20, 0.9, '2026-01-14 23:39:18.192997');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (247, 95, 20, 1.1, '2026-01-14 23:39:18.194515');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (248, 94, 20, 1.4, '2026-01-14 23:39:18.196224');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (249, 93, 20, 6.2, '2026-01-14 23:39:18.197724');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (250, 114, 20, 1.4, '2026-01-14 23:39:18.199333');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (251, 113, 20, 1.5, '2026-01-14 23:39:18.200845');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (252, 112, 20, 1.3, '2026-01-14 23:39:18.202421');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (253, 111, 20, 1.1, '2026-01-14 23:39:18.204244');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (254, 504, 20, 2.8, '2026-01-14 23:39:18.20596');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (255, 109, 20, 1.5, '2026-01-14 23:39:18.207967');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (256, 503, 20, 2.3, '2026-01-14 23:39:18.209514');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (257, 107, 20, 1.5, '2026-01-14 23:39:18.210985');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (258, 501, 20, 3.5, '2026-01-14 23:39:18.212706');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (259, 106, 20, 5.7, '2026-01-14 23:39:18.214395');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (260, 500, 20, 2.8, '2026-01-14 23:39:18.216181');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (261, 105, 20, 1.5, '2026-01-14 23:39:18.217989');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (262, 104, 20, 1.5, '2026-01-14 23:39:18.21955');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (263, 499, 20, 2.5, '2026-01-14 23:39:18.221333');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (264, 103, 20, 1.2, '2026-01-14 23:39:18.223002');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (265, 498, 20, 3.6, '2026-01-14 23:39:18.224644');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (266, 102, 20, 1.3, '2026-01-14 23:39:18.226193');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (267, 497, 20, 3.0, '2026-01-14 23:39:18.227764');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (268, 101, 20, 1.2, '2026-01-14 23:39:18.2298');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (269, 496, 20, 3.0, '2026-01-14 23:39:18.231422');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (270, 473, 20, 3.5, '2026-01-14 23:39:18.232979');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (271, 495, 20, 3.4, '2026-01-14 23:39:18.234535');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (272, 471, 20, 1.7, '2026-01-14 23:39:18.236163');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (273, 494, 20, 3.0, '2026-01-14 23:39:18.239687');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (274, 470, 20, 3.5, '2026-01-14 23:39:18.242001');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (275, 492, 60, 2.7, '2026-01-14 23:39:18.243589');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (276, 469, 20, 3.4, '2026-01-14 23:39:18.244804');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (277, 487, 20, 2.4, '2026-01-14 23:39:18.246086');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (278, 468, 60, 3.3, '2026-01-14 23:39:18.24738');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (279, 486, 60, 2.3, '2026-01-14 23:39:18.248594');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (280, 466, 20, 1.5, '2026-01-14 23:39:18.249773');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (281, 483, 20, 6.6, '2026-01-14 23:39:18.251056');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (282, 465, 20, 1.5, '2026-01-14 23:39:18.252321');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (283, 481, 20, 3.1, '2026-01-14 23:39:18.253572');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (284, 464, 20, 1.3, '2026-01-14 23:39:18.254852');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (285, 480, 20, 7.6, '2026-01-14 23:39:18.256161');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (286, 462, 20, 1.5, '2026-01-14 23:39:18.257373');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (287, 479, 60, 3.5, '2026-01-14 23:39:18.258569');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (288, 460, 20, 1.2, '2026-01-14 23:39:18.259725');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (289, 478, 20, 3.0, '2026-01-14 23:39:18.261004');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (290, 459, 20, 1.5, '2026-01-14 23:39:18.262296');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (291, 476, 20, 3.2, '2026-01-14 23:39:18.263464');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (292, 458, 20, 1.5, '2026-01-14 23:39:18.264647');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (293, 457, 20, 2.3, '2026-01-14 23:39:18.266121');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (294, 455, 20, 1.5, '2026-01-14 23:39:18.267453');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (295, 454, 20, 3.5, '2026-01-14 23:39:18.268795');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (296, 452, 20, 3.5, '2026-01-14 23:39:18.270097');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (297, 448, 20, 3.5, '2026-01-14 23:39:18.271333');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (298, 475, 20, 3.5, '2026-01-14 23:39:18.272733');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (299, 447, 20, 1.5, '2026-01-14 23:39:18.274049');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (300, 446, 20, 1.6, '2026-01-14 23:39:18.275323');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (301, 445, 20, 3.4, '2026-01-14 23:39:18.276948');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (302, 295, 20, 1.4, '2026-01-14 23:39:18.278208');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (303, 293, 20, 0.1, '2026-01-14 23:39:18.279939');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (304, 292, 20, 0.8, '2026-01-14 23:39:18.281545');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (305, 291, 20, 0.5, '2026-01-14 23:39:18.283104');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (306, 288, 20, 0.5, '2026-01-14 23:39:18.284859');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (307, 287, 20, 1.3, '2026-01-14 23:39:18.287306');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (308, 285, 20, 0.5, '2026-01-14 23:39:18.289068');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (309, 276, 20, 1.0, '2026-01-14 23:39:18.290753');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (310, 275, 20, 0.9, '2026-01-14 23:39:18.292256');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (311, 296, 20, 0.6, '2026-01-14 23:39:18.293724');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (312, 294, 20, 1.1, '2026-01-14 23:39:18.295269');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (313, 284, 20, 0.2, '2026-01-14 23:39:18.296779');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (314, 281, 20, 1.1, '2026-01-14 23:39:18.298403');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (315, 280, 20, 1.0, '2026-01-14 23:39:18.299936');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (316, 278, 20, 0.7, '2026-01-14 23:39:18.301479');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (317, 274, 20, 0.7, '2026-01-14 23:39:18.302909');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (318, 272, 20, 5.7, '2026-01-14 23:39:18.304365');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (319, 266, 20, 1.5, '2026-01-14 23:39:18.305948');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (320, 261, 20, 0.5, '2026-01-14 23:39:18.307765');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (321, 258, 20, 1.2, '2026-01-14 23:39:18.309363');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (322, 251, 20, 1.0, '2026-01-14 23:39:18.310759');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (323, 263, 20, 0.9, '2026-01-14 23:39:18.312566');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (324, 255, 20, 0.8, '2026-01-14 23:39:18.314172');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (325, 254, 20, 0.3, '2026-01-14 23:39:18.318311');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (326, 253, 20, 0.6, '2026-01-14 23:39:18.320854');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (327, 252, 20, 0.8, '2026-01-14 23:39:18.322812');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (328, 247, 20, 6.1, '2026-01-14 23:39:18.324663');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (329, 525, 60, 6.7, '2026-01-14 23:39:18.326142');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (330, 518, 60, 2.3, '2026-01-14 23:39:18.327855');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (331, 517, 20, 2.4, '2026-01-14 23:39:18.329688');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (332, 514, 20, 3.4, '2026-01-14 23:39:18.331343');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (333, 512, 20, 3.5, '2026-01-14 23:39:18.333011');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (334, 511, 20, 2.3, '2026-01-14 23:39:18.334315');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (335, 508, 20, 2.3, '2026-01-14 23:39:18.33558');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (336, 507, 20, 2.9, '2026-01-14 23:39:18.336758');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (337, 506, 20, 2.4, '2026-01-14 23:39:18.337957');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (338, 505, 20, 2.9, '2026-01-14 23:39:18.339178');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (339, 530, 60, 1.7, '2026-01-14 23:39:18.340396');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (340, 529, 60, 1.6, '2026-01-14 23:39:18.341546');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (341, 524, 60, 6.7, '2026-01-14 23:39:18.342744');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (342, 523, 60, 6.9, '2026-01-14 23:39:18.343913');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (343, 522, 60, 6.6, '2026-01-14 23:39:18.345092');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (344, 520, 60, 6.7, '2026-01-14 23:39:18.346346');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (345, 516, 60, 2.8, '2026-01-14 23:39:18.347625');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (346, 513, 20, 3.4, '2026-01-14 23:39:18.348827');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (347, 559, 60, 2.1, '2026-01-14 23:39:18.349997');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (348, 558, 60, 1.9, '2026-01-14 23:39:18.351272');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (349, 556, 60, 1.7, '2026-01-14 23:39:18.3526');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (350, 555, 60, 1.7, '2026-01-14 23:39:18.353826');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (351, 554, 60, 3.4, '2026-01-14 23:39:18.355126');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (352, 553, 20, 3.5, '2026-01-14 23:39:18.356811');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (353, 547, 60, 1.7, '2026-01-14 23:39:18.358484');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (354, 551, 20, 3.5, '2026-01-14 23:39:18.360446');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (355, 548, 60, 1.7, '2026-01-14 23:39:18.361985');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (356, 546, 60, 1.7, '2026-01-14 23:39:18.363886');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (357, 543, 60, 1.7, '2026-01-14 23:39:18.365851');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (358, 540, 20, 3.1, '2026-01-14 23:39:18.367471');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (359, 539, 20, 3.0, '2026-01-14 23:39:18.368919');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (360, 537, 20, 3.1, '2026-01-14 23:39:18.37027');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (361, 536, 60, 1.7, '2026-01-14 23:39:18.371584');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (362, 534, 60, 2.1, '2026-01-14 23:39:18.372922');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (363, 533, 60, 1.7, '2026-01-14 23:39:18.374109');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (364, 216, 20, 1.3, '2026-01-14 23:39:18.375321');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (365, 215, 20, 0.8, '2026-01-14 23:39:18.37647');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (366, 208, 20, 1.3, '2026-01-14 23:39:18.377639');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (367, 197, 20, 0.6, '2026-01-14 23:39:18.378849');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (368, 196, 20, 0.1, '2026-01-14 23:39:18.3801');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (369, 214, 20, 0.5, '2026-01-14 23:39:18.381207');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (370, 210, 20, 0.4, '2026-01-14 23:39:18.382376');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (371, 201, 20, 1.5, '2026-01-14 23:39:18.383624');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (372, 199, 20, 0.4, '2026-01-14 23:39:18.385024');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (373, 421, 20, 7.3, '2026-01-14 23:39:18.386227');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (374, 417, 20, 3.2, '2026-01-14 23:39:18.387558');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (375, 412, 20, 2.3, '2026-01-14 23:39:18.388885');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (376, 411, 20, 0.2, '2026-01-14 23:39:18.390122');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (377, 410, 20, 1.9, '2026-01-14 23:39:18.39132');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (378, 409, 20, 2.3, '2026-01-14 23:39:18.393127');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (379, 408, 20, 0.2, '2026-01-14 23:39:18.394633');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (380, 407, 20, 0.2, '2026-01-14 23:39:18.396438');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (381, 405, 20, 0.4, '2026-01-14 23:39:18.398249');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (382, 404, 20, 0.4, '2026-01-14 23:39:18.399736');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (383, 403, 20, 0.4, '2026-01-14 23:39:18.401314');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (384, 402, 20, 0.4, '2026-01-14 23:39:18.402855');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (385, 420, 20, 6.7, '2026-01-14 23:39:18.404377');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (386, 413, 20, 1.9, '2026-01-14 23:39:18.405918');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (387, 238, 20, 0.2, '2026-01-14 23:39:18.40746');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (388, 224, 20, 0.3, '2026-01-14 23:39:18.408934');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (389, 219, 20, 0.1, '2026-01-14 23:39:18.410446');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (390, 245, 20, 1.2, '2026-01-14 23:39:18.412219');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (391, 244, 20, 1.5, '2026-01-14 23:39:18.414157');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (392, 242, 20, 0.4, '2026-01-14 23:39:18.416168');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (393, 240, 20, 0.4, '2026-01-14 23:39:18.418374');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (394, 239, 20, 0.4, '2026-01-14 23:39:18.420095');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (395, 236, 20, 0.2, '2026-01-14 23:39:18.421512');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (396, 235, 20, 0.2, '2026-01-14 23:39:18.422782');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (397, 231, 20, 0.6, '2026-01-14 23:39:18.424044');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (398, 226, 20, 1.2, '2026-01-14 23:39:18.425305');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (399, 225, 20, 0.4, '2026-01-14 23:39:18.426474');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (400, 444, 20, 1.3, '2026-01-14 23:39:18.42762');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (401, 440, 20, 1.4, '2026-01-14 23:39:18.428874');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (402, 439, 20, 1.5, '2026-01-14 23:39:18.430054');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (403, 438, 20, 1.5, '2026-01-14 23:39:18.431285');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (404, 426, 20, 6.7, '2026-01-14 23:39:18.432456');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (405, 441, 20, 1.4, '2026-01-14 23:39:18.433713');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (406, 437, 20, 3.4, '2026-01-14 23:39:18.435415');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (407, 436, 20, 3.5, '2026-01-14 23:39:18.436856');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (408, 435, 60, 3.5, '2026-01-14 23:39:18.438707');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (409, 434, 20, 1.2, '2026-01-14 23:39:18.441935');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (410, 433, 20, 3.4, '2026-01-14 23:39:18.443474');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (411, 432, 20, 3.1, '2026-01-14 23:39:18.445068');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (412, 431, 20, 3.4, '2026-01-14 23:39:18.446757');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (413, 427, 20, 3.2, '2026-01-14 23:39:18.448512');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (414, 425, 20, 6.0, '2026-01-14 23:39:18.450074');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (415, 424, 20, 6.1, '2026-01-14 23:39:18.452095');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (416, 423, 20, 6.6, '2026-01-14 23:39:18.453786');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (417, 90, 20, 6.1, '2026-01-14 23:39:18.455257');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (418, 89, 20, 6.1, '2026-01-14 23:39:18.456764');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (419, 88, 20, 6.1, '2026-01-14 23:39:18.458381');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (420, 85, 20, 6.0, '2026-01-14 23:39:18.459904');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (421, 84, 20, 6.0, '2026-01-14 23:39:18.461399');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (422, 82, 20, 6.8, '2026-01-14 23:39:18.463391');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (423, 81, 20, 6.0, '2026-01-14 23:39:18.464883');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (424, 80, 20, 6.0, '2026-01-14 23:39:18.466457');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (425, 64, 20, 6.0, '2026-01-14 23:39:18.468198');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (426, 62, 20, 6.3, '2026-01-14 23:39:18.469786');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (427, 43, 20, 6.2, '2026-01-14 23:39:18.471545');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (428, 23, 20, 7.6, '2026-01-14 23:39:18.472995');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (429, 83, 20, 6.1, '2026-01-14 23:39:18.474522');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (430, 63, 20, 6.3, '2026-01-14 23:39:18.475793');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (431, 46, 20, 6.3, '2026-01-14 23:39:18.477215');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (432, 45, 20, 6.9, '2026-01-14 23:39:18.479475');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (433, 42, 20, 9.6, '2026-01-14 23:39:18.481076');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (434, 24, 20, 6.8, '2026-01-14 23:39:18.482712');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (435, 18, 20, 7.5, '2026-01-14 23:39:18.484201');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (436, 79, 20, 6.0, '2026-01-14 23:39:18.485664');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (437, 78, 20, 6.0, '2026-01-14 23:39:18.487105');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (438, 76, 20, 6.0, '2026-01-14 23:39:18.489062');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (439, 65, 20, 6.1, '2026-01-14 23:39:18.491263');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (440, 54, 20, 6.0, '2026-01-14 23:39:18.492798');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (441, 49, 20, 1.8, '2026-01-14 23:39:18.494306');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (442, 600, 60, 2.2, '2026-01-14 23:39:18.496188');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (443, 598, 60, 2.3, '2026-01-14 23:39:18.497887');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (444, 591, 60, 2.8, '2026-01-14 23:39:18.499445');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (445, 590, 60, 1.6, '2026-01-14 23:39:18.500864');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (446, 589, 60, 1.4, '2026-01-14 23:39:18.5025');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (447, 586, 60, 1.7, '2026-01-14 23:39:18.504015');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (448, 584, 60, 2.1, '2026-01-14 23:39:18.505443');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (449, 583, 60, 2.1, '2026-01-14 23:39:18.506838');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (450, 582, 60, 1.5, '2026-01-14 23:39:18.508849');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (451, 581, 60, 0.7, '2026-01-14 23:39:18.510326');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (452, 580, 60, 0.6, '2026-01-14 23:39:18.512061');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (453, 578, 60, 1.7, '2026-01-14 23:39:18.513694');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (454, 575, 20, 7.1, '2026-01-14 23:39:18.515164');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (455, 574, 60, 6.5, '2026-01-14 23:39:18.516749');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (456, 571, 60, 0.6, '2026-01-14 23:39:18.518407');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (457, 570, 60, 6.6, '2026-01-14 23:39:18.520013');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (458, 569, 60, 6.5, '2026-01-14 23:39:18.521525');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (459, 568, 60, 6.8, '2026-01-14 23:39:18.523066');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (460, 567, 60, 0.6, '2026-01-14 23:39:18.52455');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (461, 563, 60, 1.7, '2026-01-14 23:39:18.525964');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (462, 561, 60, 3.3, '2026-01-14 23:39:18.527341');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (463, 557, 60, 2.3, '2026-01-14 23:39:18.529355');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (464, 550, 60, 1.7, '2026-01-14 23:39:18.530871');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (465, 549, 60, 1.7, '2026-01-14 23:39:18.533401');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (466, 544, 60, 1.7, '2026-01-14 23:39:18.53496');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (467, 542, 60, 1.7, '2026-01-14 23:39:18.536448');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (468, 541, 60, 2.2, '2026-01-14 23:39:18.537863');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (469, 538, 20, 2.9, '2026-01-14 23:39:18.539767');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (470, 535, 60, 2.3, '2026-01-14 23:39:18.541339');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (471, 531, 60, 1.7, '2026-01-14 23:39:18.542759');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (472, 526, 60, 8.1, '2026-01-14 23:39:18.54415');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (473, 521, 60, 6.9, '2026-01-14 23:39:18.546209');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (474, 519, 60, 7.8, '2026-01-14 23:39:18.548248');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (475, 515, 20, 2.1, '2026-01-14 23:39:18.549874');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (476, 510, 20, 2.3, '2026-01-14 23:39:18.551611');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (477, 509, 20, 2.1, '2026-01-14 23:39:18.553064');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (478, 502, 20, 2.1, '2026-01-14 23:39:18.554648');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (479, 493, 20, 3.2, '2026-01-14 23:39:18.557133');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (480, 491, 20, 6.7, '2026-01-14 23:39:18.558703');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (481, 490, 20, 7.5, '2026-01-14 23:39:18.560285');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (482, 489, 20, 8.2, '2026-01-14 23:39:18.563104');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (483, 488, 20, 8.1, '2026-01-14 23:39:18.56622');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (484, 485, 20, 6.8, '2026-01-14 23:39:18.570352');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (485, 484, 20, 7.8, '2026-01-14 23:39:18.57216');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (486, 482, 20, 7.2, '2026-01-14 23:39:18.573704');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (487, 477, 20, 3.3, '2026-01-14 23:39:18.575162');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (488, 474, 60, 3.4, '2026-01-14 23:39:18.576805');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (489, 472, 20, 1.4, '2026-01-14 23:39:18.578259');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (490, 467, 20, 3.1, '2026-01-14 23:39:18.579994');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (491, 463, 20, 1.2, '2026-01-14 23:39:18.581779');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (492, 461, 20, 1.2, '2026-01-14 23:39:18.583553');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (493, 456, 20, 1.5, '2026-01-14 23:39:18.585066');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (494, 453, 20, 1.3, '2026-01-14 23:39:18.586475');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (495, 451, 20, 2.3, '2026-01-14 23:39:18.588115');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (496, 450, 20, 2.8, '2026-01-14 23:39:18.589661');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (497, 449, 20, 1.6, '2026-01-14 23:39:18.591524');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (498, 443, 20, 1.9, '2026-01-14 23:39:18.592931');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (499, 430, 20, 2.3, '2026-01-14 23:39:18.594341');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (500, 415, 20, 0.3, '2026-01-14 23:39:18.596117');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (501, 396, 20, 1.0, '2026-01-14 23:39:18.597727');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (502, 395, 20, 1.2, '2026-01-14 23:39:18.599433');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (503, 393, 20, 0.4, '2026-01-14 23:39:18.600955');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (504, 386, 20, 1.4, '2026-01-14 23:39:18.602645');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (505, 385, 20, 1.2, '2026-01-14 23:39:18.604483');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (506, 373, 20, 0.5, '2026-01-14 23:39:18.605926');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (507, 362, 20, 0.2, '2026-01-14 23:39:18.607741');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (508, 361, 20, 1.3, '2026-01-14 23:39:18.609211');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (509, 357, 20, 0.9, '2026-01-14 23:39:18.610661');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (510, 353, 20, 1.2, '2026-01-14 23:39:18.612598');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (511, 349, 20, 1.4, '2026-01-14 23:39:18.614251');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (512, 344, 20, 0.2, '2026-01-14 23:39:18.616324');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (513, 340, 20, 0.5, '2026-01-14 23:39:18.617717');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (514, 338, 20, 0.9, '2026-01-14 23:39:18.619169');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (515, 335, 20, 6.3, '2026-01-14 23:39:18.620994');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (516, 333, 20, 5.8, '2026-01-14 23:39:18.622901');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (517, 332, 20, 0.9, '2026-01-14 23:39:18.624434');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (518, 329, 20, 1.0, '2026-01-14 23:39:18.626223');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (519, 328, 20, 0.9, '2026-01-14 23:39:18.627544');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (520, 325, 20, 6.2, '2026-01-14 23:39:18.628782');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (521, 322, 20, 0.3, '2026-01-14 23:39:18.629992');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (522, 317, 20, 0.1, '2026-01-14 23:39:18.631213');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (523, 306, 20, 1.1, '2026-01-14 23:39:18.632449');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (524, 304, 20, 1.0, '2026-01-14 23:39:18.633891');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (525, 290, 20, 0.5, '2026-01-14 23:39:18.635284');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (526, 289, 20, 1.3, '2026-01-14 23:39:18.636556');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (527, 286, 20, 1.1, '2026-01-14 23:39:18.637802');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (528, 282, 20, 0.3, '2026-01-14 23:39:18.639007');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (529, 271, 20, 1.5, '2026-01-14 23:39:18.64019');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (530, 267, 20, 0.6, '2026-01-14 23:39:18.641304');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (531, 264, 20, 1.5, '2026-01-14 23:39:18.642467');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (532, 262, 20, 1.5, '2026-01-14 23:39:18.643623');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (533, 260, 20, 1.5, '2026-01-14 23:39:18.644801');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (534, 259, 20, 1.5, '2026-01-14 23:39:18.646016');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (535, 249, 20, 0.2, '2026-01-14 23:39:18.647214');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (536, 237, 20, 0.7, '2026-01-14 23:39:18.648403');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (537, 233, 20, 0.7, '2026-01-14 23:39:18.64952');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (538, 232, 20, 0.8, '2026-01-14 23:39:18.650706');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (539, 229, 20, 1.0, '2026-01-14 23:39:18.652902');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (540, 228, 20, 0.7, '2026-01-14 23:39:18.655236');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (541, 227, 20, 0.7, '2026-01-14 23:39:18.656577');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (542, 220, 20, 0.2, '2026-01-14 23:39:18.657789');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (543, 212, 20, 0.8, '2026-01-14 23:39:18.658956');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (544, 209, 20, 1.3, '2026-01-14 23:39:18.660126');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (545, 203, 20, 0.4, '2026-01-14 23:39:18.661306');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (546, 193, 20, 6.2, '2026-01-14 23:39:18.662549');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (547, 190, 20, 5.9, '2026-01-14 23:39:18.66378');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (548, 188, 20, 1.6, '2026-01-14 23:39:18.665065');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (549, 185, 20, 6.2, '2026-01-14 23:39:18.666391');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (550, 184, 20, 1.5, '2026-01-14 23:39:18.667665');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (551, 182, 20, 6.2, '2026-01-14 23:39:18.668852');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (552, 180, 20, 6.6, '2026-01-14 23:39:18.669972');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (553, 179, 20, 6.1, '2026-01-14 23:39:18.671148');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (554, 176, 20, 6.0, '2026-01-14 23:39:18.67245');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (555, 175, 20, 0.9, '2026-01-14 23:39:18.673865');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (556, 174, 20, 1.2, '2026-01-14 23:39:18.675334');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (557, 169, 20, 0.0, '2026-01-14 23:39:18.676574');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (558, 168, 20, 0.5, '2026-01-14 23:39:18.677772');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (559, 161, 20, 3.5, '2026-01-14 23:39:18.67896');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (560, 153, 20, 1.2, '2026-01-14 23:39:18.680129');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (561, 144, 20, 0.9, '2026-01-14 23:39:18.681327');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (562, 138, 20, 1.4, '2026-01-14 23:39:18.682488');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (563, 137, 20, 1.4, '2026-01-14 23:39:18.683751');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (564, 135, 20, 1.4, '2026-01-14 23:39:18.685008');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (565, 133, 20, 1.4, '2026-01-14 23:39:18.686235');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (566, 132, 20, 1.4, '2026-01-14 23:39:18.687433');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (567, 110, 20, 1.5, '2026-01-14 23:39:18.68904');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (568, 108, 20, 0.9, '2026-01-14 23:39:18.690247');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (569, 92, 20, 6.7, '2026-01-14 23:39:18.691532');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (570, 91, 20, 6.0, '2026-01-14 23:39:18.692756');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (571, 87, 20, 6.2, '2026-01-14 23:39:18.693904');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (572, 75, 20, 6.2, '2026-01-14 23:39:18.695042');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (573, 73, 20, 6.0, '2026-01-14 23:39:18.696314');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (574, 72, 20, 1.6, '2026-01-14 23:39:18.697464');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (575, 67, 20, 6.4, '2026-01-14 23:39:18.698682');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (576, 66, 20, 6.0, '2026-01-14 23:39:18.699873');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (577, 61, 20, 6.2, '2026-01-14 23:39:18.701094');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (578, 52, 20, 6.3, '2026-01-14 23:39:18.702432');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (579, 51, 20, 7.1, '2026-01-14 23:39:18.7037');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (580, 50, 20, 6.9, '2026-01-14 23:39:18.705026');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (581, 37, 20, 1.8, '2026-01-14 23:39:18.706449');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (582, 35, 20, 6.8, '2026-01-14 23:39:18.707644');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (583, 28, 20, 6.6, '2026-01-14 23:39:18.708797');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (584, 26, 20, 6.7, '2026-01-14 23:39:18.70996');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (585, 25, 20, 6.6, '2026-01-14 23:39:18.71116');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (586, 22, 20, 7.0, '2026-01-14 23:39:18.712473');
INSERT INTO sadie_gtm.hotel_customer_proximity VALUES (587, 21, 20, 7.9, '2026-01-14 23:39:18.713645');


--
-- Data for Name: hotel_room_count; Type: TABLE DATA; Schema: sadie_gtm; Owner: -
--

INSERT INTO sadie_gtm.hotel_room_count VALUES (1, 283, 25, 'regex', 1.00, '2026-01-14 23:25:52.942725');
INSERT INTO sadie_gtm.hotel_room_count VALUES (2, 74, 10, 'groq', 0.70, '2026-01-14 23:25:57.419988');
INSERT INTO sadie_gtm.hotel_room_count VALUES (3, 68, 25, 'groq', 0.70, '2026-01-14 23:26:22.922943');
INSERT INTO sadie_gtm.hotel_room_count VALUES (4, 418, 10, 'groq', 0.70, '2026-01-14 23:26:31.562588');
INSERT INTO sadie_gtm.hotel_room_count VALUES (5, 205, 1, 'regex', 1.00, '2026-01-14 23:26:35.019977');
INSERT INTO sadie_gtm.hotel_room_count VALUES (6, 552, 20, 'groq', 0.70, '2026-01-14 23:27:29.392699');
INSERT INTO sadie_gtm.hotel_room_count VALUES (7, 378, 50, 'groq', 0.70, '2026-01-14 23:28:00.944261');
INSERT INTO sadie_gtm.hotel_room_count VALUES (8, 341, 50, 'groq', 0.70, '2026-01-14 23:28:16.634053');
INSERT INTO sadie_gtm.hotel_room_count VALUES (9, 314, 10, 'groq', 0.70, '2026-01-14 23:28:28.94743');
INSERT INTO sadie_gtm.hotel_room_count VALUES (10, 406, 4, 'regex', 1.00, '2026-01-14 23:28:36.279623');
INSERT INTO sadie_gtm.hotel_room_count VALUES (11, 364, 42, 'groq', 0.70, '2026-01-14 23:28:54.723821');
INSERT INTO sadie_gtm.hotel_room_count VALUES (12, 213, 10, 'groq', 0.70, '2026-01-14 23:29:23.032145');
INSERT INTO sadie_gtm.hotel_room_count VALUES (13, 86, 1, 'groq', 0.70, '2026-01-14 23:29:36.413287');
INSERT INTO sadie_gtm.hotel_room_count VALUES (14, 389, 1, 'regex', 1.00, '2026-01-14 23:29:40.915221');
INSERT INTO sadie_gtm.hotel_room_count VALUES (15, 170, 10, 'groq', 0.70, '2026-01-14 23:29:58.184625');
INSERT INTO sadie_gtm.hotel_room_count VALUES (16, 39, 10, 'groq', 0.70, '2026-01-14 23:30:02.658545');
INSERT INTO sadie_gtm.hotel_room_count VALUES (17, 163, 10, 'groq', 0.70, '2026-01-14 23:30:16.843006');
INSERT INTO sadie_gtm.hotel_room_count VALUES (18, 309, 10, 'groq', 0.70, '2026-01-14 23:30:50.179654');
INSERT INTO sadie_gtm.hotel_room_count VALUES (19, 223, 27, 'regex', 1.00, '2026-01-14 23:30:57.227133');
INSERT INTO sadie_gtm.hotel_room_count VALUES (20, 241, 29, 'regex', 1.00, '2026-01-14 23:31:01.20078');
INSERT INTO sadie_gtm.hotel_room_count VALUES (21, 221, 1, 'regex', 1.00, '2026-01-14 23:31:08.84911');
INSERT INTO sadie_gtm.hotel_room_count VALUES (22, 320, 1564, 'regex', 1.00, '2026-01-14 23:31:18.910618');
INSERT INTO sadie_gtm.hotel_room_count VALUES (23, 268, 10, 'groq', 0.70, '2026-01-14 23:32:48.760218');
INSERT INTO sadie_gtm.hotel_room_count VALUES (24, 13, 53, 'regex', 1.00, '2026-01-14 23:32:52.062757');
INSERT INTO sadie_gtm.hotel_room_count VALUES (25, 265, 10, 'groq', 0.70, '2026-01-14 23:33:02.728601');
INSERT INTO sadie_gtm.hotel_room_count VALUES (26, 416, 20, 'groq', 0.70, '2026-01-14 23:33:20.159016');
INSERT INTO sadie_gtm.hotel_room_count VALUES (27, 414, 1, 'regex', 1.00, '2026-01-14 23:33:26.255152');
INSERT INTO sadie_gtm.hotel_room_count VALUES (28, 195, 50, 'groq', 0.70, '2026-01-14 23:33:37.394216');
INSERT INTO sadie_gtm.hotel_room_count VALUES (29, 207, 50, 'groq', 0.70, '2026-01-14 23:33:45.237673');
INSERT INTO sadie_gtm.hotel_room_count VALUES (30, 372, 1, 'regex', 1.00, '2026-01-14 23:33:49.105642');
INSERT INTO sadie_gtm.hotel_room_count VALUES (31, 246, 1, 'regex', 1.00, '2026-01-14 23:33:55.204702');
INSERT INTO sadie_gtm.hotel_room_count VALUES (32, 123, 10, 'groq', 0.70, '2026-01-14 23:33:59.809625');
INSERT INTO sadie_gtm.hotel_room_count VALUES (33, 194, 10, 'groq', 0.70, '2026-01-14 23:34:09.938579');
INSERT INTO sadie_gtm.hotel_room_count VALUES (34, 173, 35, 'regex', 1.00, '2026-01-14 23:34:13.703822');
INSERT INTO sadie_gtm.hotel_room_count VALUES (35, 269, 5, 'groq', 0.70, '2026-01-14 23:35:12.264678');
INSERT INTO sadie_gtm.hotel_room_count VALUES (36, 200, 600, 'regex', 1.00, '2026-01-14 23:35:37.10694');
INSERT INTO sadie_gtm.hotel_room_count VALUES (37, 166, 10, 'groq', 0.70, '2026-01-14 23:42:55.820784');
INSERT INTO sadie_gtm.hotel_room_count VALUES (38, 44, 10, 'groq', 0.70, '2026-01-14 23:43:10.254232');
INSERT INTO sadie_gtm.hotel_room_count VALUES (39, 527, 50, 'groq', 0.70, '2026-01-14 23:43:26.508721');
INSERT INTO sadie_gtm.hotel_room_count VALUES (40, 367, 1, 'regex', 1.00, '2026-01-14 23:43:30.590074');
INSERT INTO sadie_gtm.hotel_room_count VALUES (41, 117, 24, 'regex', 1.00, '2026-01-14 23:43:35.011233');
INSERT INTO sadie_gtm.hotel_room_count VALUES (42, 601, 50, 'groq', 0.70, '2026-01-14 23:44:29.506399');
INSERT INTO sadie_gtm.hotel_room_count VALUES (43, 374, 10, 'groq', 0.70, '2026-01-14 23:44:38.353765');
INSERT INTO sadie_gtm.hotel_room_count VALUES (44, 257, 305, 'groq', 0.70, '2026-01-14 23:45:22.934457');
INSERT INTO sadie_gtm.hotel_room_count VALUES (45, 206, 5, 'groq', 0.70, '2026-01-14 23:45:31.67248');
INSERT INTO sadie_gtm.hotel_room_count VALUES (46, 119, 43, 'regex', 1.00, '2026-01-14 23:45:36.26704');
INSERT INTO sadie_gtm.hotel_room_count VALUES (47, 428, 49, 'groq', 0.70, '2026-01-14 23:45:58.567732');
INSERT INTO sadie_gtm.hotel_room_count VALUES (48, 603, 50, 'groq', 0.70, '2026-01-14 23:46:30.922791');
INSERT INTO sadie_gtm.hotel_room_count VALUES (49, 279, 186, 'regex', 1.00, '2026-01-14 23:46:36.222424');
INSERT INTO sadie_gtm.hotel_room_count VALUES (50, 230, 1, 'groq', 0.70, '2026-01-14 23:51:17.930516');
INSERT INTO sadie_gtm.hotel_room_count VALUES (51, 202, 50, 'groq', 0.70, '2026-01-14 23:51:25.283737');
INSERT INTO sadie_gtm.hotel_room_count VALUES (52, 419, 25, 'groq', 0.70, '2026-01-14 23:51:52.538687');
INSERT INTO sadie_gtm.hotel_room_count VALUES (53, 222, 45, 'regex', 1.00, '2026-01-14 23:51:59.204039');
INSERT INTO sadie_gtm.hotel_room_count VALUES (54, 308, 50, 'groq', 0.70, '2026-01-14 23:52:06.285554');
INSERT INTO sadie_gtm.hotel_room_count VALUES (55, 381, 25, 'groq', 0.70, '2026-01-14 23:52:14.497778');
INSERT INTO sadie_gtm.hotel_room_count VALUES (56, 442, 50, 'groq', 0.70, '2026-01-14 23:52:20.106142');
INSERT INTO sadie_gtm.hotel_room_count VALUES (57, 593, 10, 'groq', 0.70, '2026-01-14 23:52:44.369197');
INSERT INTO sadie_gtm.hotel_room_count VALUES (58, 532, 10, 'groq', 0.70, '2026-01-14 23:53:15.708477');
INSERT INTO sadie_gtm.hotel_room_count VALUES (59, 564, 50, 'groq', 0.70, '2026-01-14 23:53:25.59864');
INSERT INTO sadie_gtm.hotel_room_count VALUES (60, 377, 97, 'regex', 1.00, '2026-01-14 23:53:29.056239');
INSERT INTO sadie_gtm.hotel_room_count VALUES (61, 248, 50, 'groq', 0.70, '2026-01-14 23:53:39.082953');
INSERT INTO sadie_gtm.hotel_room_count VALUES (62, 57, 14, 'groq', 0.70, '2026-01-14 23:53:52.497558');
INSERT INTO sadie_gtm.hotel_room_count VALUES (63, 19, 50, 'groq', 0.70, '2026-01-14 23:54:08.642137');
INSERT INTO sadie_gtm.hotel_room_count VALUES (64, 429, 30, 'groq', 0.70, '2026-01-14 23:54:28.747721');
INSERT INTO sadie_gtm.hotel_room_count VALUES (65, 217, 15, 'groq', 0.70, '2026-01-14 23:54:44.217365');
INSERT INTO sadie_gtm.hotel_room_count VALUES (66, 172, 1564, 'regex', 1.00, '2026-01-14 23:54:51.138211');
INSERT INTO sadie_gtm.hotel_room_count VALUES (67, 122, 50, 'groq', 0.70, '2026-01-14 23:54:59.20898');
INSERT INTO sadie_gtm.hotel_room_count VALUES (68, 250, 101, 'regex', 1.00, '2026-01-14 23:55:02.820029');
INSERT INTO sadie_gtm.hotel_room_count VALUES (69, 218, 30, 'groq', 0.70, '2026-01-14 23:55:18.54512');
INSERT INTO sadie_gtm.hotel_room_count VALUES (70, 234, 1, 'groq', 0.70, '2026-01-14 23:55:29.647481');
INSERT INTO sadie_gtm.hotel_room_count VALUES (71, 316, 10, 'groq', 0.70, '2026-01-14 23:55:43.493432');
INSERT INTO sadie_gtm.hotel_room_count VALUES (72, 211, 10, 'groq', 0.70, '2026-01-14 23:55:53.516593');
INSERT INTO sadie_gtm.hotel_room_count VALUES (73, 198, 44, 'groq', 0.70, '2026-01-14 23:56:38.69392');
INSERT INTO sadie_gtm.hotel_room_count VALUES (74, 17, 1, 'regex', 1.00, '2026-01-14 23:56:43.120804');
INSERT INTO sadie_gtm.hotel_room_count VALUES (75, 310, 10, 'groq', 0.70, '2026-01-14 23:56:55.388224');
INSERT INTO sadie_gtm.hotel_room_count VALUES (76, 256, 1, 'regex', 1.00, '2026-01-14 23:57:00.597776');
INSERT INTO sadie_gtm.hotel_room_count VALUES (77, 20, 170, 'regex', 1.00, '2026-01-14 23:57:17.567328');
INSERT INTO sadie_gtm.hotel_room_count VALUES (78, 545, 10, 'groq', 0.70, '2026-01-14 23:57:36.816911');
INSERT INTO sadie_gtm.hotel_room_count VALUES (79, 33, 50, 'groq', 0.70, '2026-01-14 23:57:53.957');
INSERT INTO sadie_gtm.hotel_room_count VALUES (80, 204, 50, 'groq', 0.70, '2026-01-14 23:58:29.910946');
INSERT INTO sadie_gtm.hotel_room_count VALUES (81, 599, 50, 'groq', 0.70, '2026-01-14 23:58:44.954051');
INSERT INTO sadie_gtm.hotel_room_count VALUES (82, 422, 10, 'groq', 0.70, '2026-01-14 23:59:24.976572');
INSERT INTO sadie_gtm.hotel_room_count VALUES (83, 528, 5, 'regex', 1.00, '2026-01-14 23:59:45.331458');
INSERT INTO sadie_gtm.hotel_room_count VALUES (84, 388, 1, 'regex', 1.00, '2026-01-14 23:59:49.279944');
INSERT INTO sadie_gtm.hotel_room_count VALUES (85, 270, 10, 'groq', 0.70, '2026-01-15 00:01:38.328329');
INSERT INTO sadie_gtm.hotel_room_count VALUES (86, 165, 25, 'groq', 0.70, '2026-01-15 00:01:57.271978');
INSERT INTO sadie_gtm.hotel_room_count VALUES (87, 56, 10, 'groq', 0.70, '2026-01-15 00:02:21.6252');


--
-- Data for Name: hotels; Type: TABLE DATA; Schema: sadie_gtm; Owner: -
--

INSERT INTO sadie_gtm.hotels VALUES (379, 'The Daydrift', 'https://www.thedaydrift.com/?utm_source=google&utm_medium=organic&utm_campaign=business_listing', '(305) 615-4649', NULL, NULL, '0101000020E6100000515E752E560854C0393476D377CC3940', '2216 Park Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.5, NULL, 99, 'grid_region', '2026-01-14 00:03:28.948725', '2026-01-14 21:51:42.765155');
INSERT INTO sadie_gtm.hotels VALUES (13, 'The Biscayne Hotel', 'http://thebiscaynehotel.com/', '(305) 456-0432', '3054560432', 'reservation@thebiscaynehotel.com', '0101000020E61000004314387ECD0B54C033BCFEC984D63940', '6730 Biscayne Blvd, Miami, FL 33138', 'Miami', 'FL', 'USA', 4.2, NULL, 3, 'grid_region', '2026-01-13 23:32:59.147981', '2026-01-14 23:32:52.073469');
INSERT INTO sadie_gtm.hotels VALUES (195, 'Kenmore Village Hotel', 'https://www.kenmorevillagehotel.com/', '(786) 605-0910', NULL, NULL, '0101000020E610000097361C96860854C0300F99F221C83940', '1050 Washington Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.8, NULL, 3, 'grid_region', '2026-01-14 00:02:27.008003', '2026-01-14 23:33:37.410828');
INSERT INTO sadie_gtm.hotels VALUES (207, 'SBV Luxury Ocean Hotel Suites', 'https://www.southbeachluxuryoceanviewhotel.com/', '(305) 809-6167', '+13058096167', 'southbeachvr@gmail.com', '0101000020E6100000904F23884E0854C0E744CC3681C93940', '1458 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.1, NULL, 3, 'grid_region', '2026-01-14 00:02:30.468511', '2026-01-14 23:33:45.249095');
INSERT INTO sadie_gtm.hotels VALUES (102, 'The Firefly', 'https://www.theinstantstay.com/', '(646) 626-3383', NULL, NULL, '0101000020E6100000DF1225C6D70854C0E535C01605C73940', '721 Michigan Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 5, NULL, 99, 'grid_region', '2026-01-14 00:02:10.23513', '2026-01-14 21:50:24.478774');
INSERT INTO sadie_gtm.hotels VALUES (21, '2110 Brickell Hotel', NULL, '(786) 252-8984', NULL, NULL, '0101000020E6100000F0E7CA56CD0C54C078E860A2E6C03940', '2110 Brickell Ave, Miami, FL 33129', 'Miami', 'FL', 'USA', 4.6, NULL, 0, 'grid_region', '2026-01-14 00:01:41.483141', '2026-01-14 00:01:41.483141');
INSERT INTO sadie_gtm.hotels VALUES (22, 'La Mare Hotel and Residence', NULL, NULL, NULL, NULL, '0101000020E6100000692222EB5F0C54C0240DC9247EC23940', '1451 S Miami Ave, Miami, FL 33130', 'Miami', 'FL', 'USA', 5, NULL, 0, 'grid_region', '2026-01-14 00:01:41.485076', '2026-01-14 00:01:41.485076');
INSERT INTO sadie_gtm.hotels VALUES (103, 'Bentley Hotel South Beach', 'https://thebentleyhotel.com/', '(305) 538-1700', NULL, NULL, '0101000020E61000008FE854E8720854C0CA0281295EC63940', '510 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:02:10.238416', '2026-01-14 21:50:24.486706');
INSERT INTO sadie_gtm.hotels VALUES (104, 'Casa Ocean', 'https://www.casahotelsgroup.com/casa-ocean', '(305) 801-5348', NULL, NULL, '0101000020E6100000F08975AA7C0854C0F27519FED3C53940', '334 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:02:10.240743', '2026-01-14 21:50:24.492642');
INSERT INTO sadie_gtm.hotels VALUES (25, 'SELECTIVE VACATION RENTALS', NULL, NULL, NULL, NULL, '0101000020E6100000C4758C2B2E0C54C012CD4DE5FEC23940', '1200 Brickell Bay Dr, Miami, FL 33131', 'Miami', 'FL', 'USA', 5, NULL, 0, 'grid_region', '2026-01-14 00:01:41.490351', '2026-01-14 00:01:41.490351');
INSERT INTO sadie_gtm.hotels VALUES (26, 'StayMe', NULL, '(786) 654-8533', NULL, NULL, '0101000020E61000000186E5CF370C54C0F4249F0DAFC23940', '1395 Brickell Ave, Miami, FL 33131', 'Miami', 'FL', 'USA', 4.4, NULL, 0, 'grid_region', '2026-01-14 00:01:41.492298', '2026-01-14 00:01:41.492298');
INSERT INTO sadie_gtm.hotels VALUES (105, 'The Julia Hotel By At Mine Hospitality', 'https://www.atminehospitality.com/', '(305) 497-7553', NULL, NULL, '0101000020E610000069B05F668E0854C0697BAAF9E0C53940', '336 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.5, NULL, 99, 'grid_region', '2026-01-14 00:02:10.244235', '2026-01-14 21:50:24.498973');
INSERT INTO sadie_gtm.hotels VALUES (28, 'Miami Mansion and Villa Rental', NULL, '(786) 724-1320', NULL, NULL, '0101000020E6100000DABF5719320C54C04015376E31C33940', '1111 Brickell Ave, Miami, FL 33131', 'Miami', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:01:41.495732', '2026-01-14 00:01:41.495732');
INSERT INTO sadie_gtm.hotels VALUES (106, 'Fish Jumanji', 'https://www.fishjumanji.com/', '(786) 486-7200', NULL, NULL, '0101000020E610000058EEBBD8EA0B54C04216B36F38C73940', '401 Biscayne Blvd, Miami, FL 33132', 'Miami', 'FL', 'USA', 4.2, NULL, 99, 'grid_region', '2026-01-14 00:02:10.247163', '2026-01-14 21:50:24.505399');
INSERT INTO sadie_gtm.hotels VALUES (107, 'Target', 'https://www.target.com/sl/south-beach/3269', '(786) 582-6708', NULL, NULL, '0101000020E610000088618731E90854C0946588635DC63940', '1045 5th St Unit 201, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.4, NULL, 99, 'grid_region', '2026-01-14 00:02:10.250051', '2026-01-14 21:50:24.511885');
INSERT INTO sadie_gtm.hotels VALUES (109, 'Instant Stay Ocean Drive', 'http://www.instantstayoceandrive.com/', '(646) 626-3383', NULL, NULL, '0101000020E61000000DB4F1167E0854C090BF0F62C2C53940', '320 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 5, NULL, 99, 'grid_region', '2026-01-14 00:02:10.25462', '2026-01-14 21:50:24.517056');
INSERT INTO sadie_gtm.hotels VALUES (111, 'Metropole Suites South Beach', 'https://metropolesouthbeach.com/', '(305) 672-0009', NULL, NULL, '0101000020E6100000B0C0FCBA780854C0108EFE3CB2C63940', '635 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.2, NULL, 99, 'grid_region', '2026-01-14 00:02:10.258697', '2026-01-14 21:50:25.14005');
INSERT INTO sadie_gtm.hotels VALUES (112, 'The Cove by Renzzi', 'https://thecovebyrenzzi.com/book-now/', '(305) 924-3187', NULL, NULL, '0101000020E6100000EB15BB229D0854C0220C4D2377C63940', '534 Washington Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.7, NULL, 99, 'grid_region', '2026-01-14 00:02:10.260663', '2026-01-14 21:50:25.159068');
INSERT INTO sadie_gtm.hotels VALUES (113, 'Life House, South of Fifth', 'https://www.atminehospitality.com/', '(305) 497-7553', NULL, NULL, '0101000020E6100000C2A4F8F8840854C0ED9BFBABC7C53940', '321 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:02:10.262644', '2026-01-14 21:50:25.168515');
INSERT INTO sadie_gtm.hotels VALUES (35, 'Royal palms hotel', NULL, NULL, NULL, NULL, '0101000020E61000005F2C674A460C54C019068772FDC23940', 'Miami, FL 33131', 'Miami', 'FL', 'USA', 4, NULL, 0, 'grid_region', '2026-01-14 00:01:55.362607', '2026-01-14 00:01:55.362607');
INSERT INTO sadie_gtm.hotels VALUES (114, 'Upsun Hotel', 'https://upsunhotel.com/?utm_source=google&utm_medium=Local+SEO&utm_campaign=Google+Business+Profile', '(786) 216-7469', NULL, NULL, '0101000020E6100000CBF6216FB90854C02B932B0659C63940', '803 5th St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.2, NULL, 99, 'grid_region', '2026-01-14 00:02:10.264748', '2026-01-14 21:50:25.176292');
INSERT INTO sadie_gtm.hotels VALUES (115, 'Bars B&B South Beach Hotel', 'http://www.barshotel.com/', '(305) 534-3010', NULL, NULL, '0101000020E61000006482D030EB0854C04491A45AFAC63940', '711 Lenox Ave., Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.1, NULL, 99, 'grid_region', '2026-01-14 00:02:10.267276', '2026-01-14 21:50:41.509042');
INSERT INTO sadie_gtm.hotels VALUES (116, 'Local House Hotel', 'http://www.localhouse.com/', '(305) 538-5529', NULL, NULL, '0101000020E6100000BBF2B4577A0854C0EFB4EB94FDC53940', '400 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.6, NULL, 99, 'grid_region', '2026-01-14 00:02:10.269507', '2026-01-14 21:50:41.516942');
INSERT INTO sadie_gtm.hotels VALUES (120, 'Local House', 'http://www.localhouse.com/', '(305) 538-5529', NULL, NULL, '0101000020E610000097A608707A0854C0535A7F4B00C63940', '400 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.5, NULL, 99, 'grid_region', '2026-01-14 00:02:10.280736', '2026-01-14 21:50:41.522653');
INSERT INTO sadie_gtm.hotels VALUES (121, 'Hotel Shelley', 'https://hotelshelley.com/', '(305) 531-3341', NULL, NULL, '0101000020E610000088D7F50B760854C04C88B9A46AC73940', '844 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:02:10.283696', '2026-01-14 21:50:41.527695');
INSERT INTO sadie_gtm.hotels VALUES (118, 'The Fountain Miami', 'http://thefountainmiami.com/', '(305) 202-0824', NULL, NULL, '0101000020E61000006F0388CCA60854C0F2C3526EECC53940', '334 Euclid Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.6, NULL, 99, 'grid_region', '2026-01-14 00:02:10.274936', '2026-01-14 21:50:41.57075');
INSERT INTO sadie_gtm.hotels VALUES (18, 'Roami at Habitat Brickell', 'https://www.roami.com/destinations/miami/689d181642792a003e1a94ff', '(833) 305-3535', NULL, NULL, '0101000020E6100000FB3BDBA3B70C54C05C46A0B07AC23940', '1700 SW 2nd Ave, Miami, FL 33129', 'Miami', 'FL', 'USA', 4.4, NULL, 99, 'grid_region', '2026-01-14 00:01:41.475277', '2026-01-14 20:13:06.45592');
INSERT INTO sadie_gtm.hotels VALUES (24, 'Fortune House Hotel', 'http://www.fortunehousehotel.com/', '(305) 349-5200', NULL, NULL, '0101000020E61000005467FF4D390C54C0F42E83D668C23940', '185 SE 14th Terrace, Miami, FL 33131', 'Miami', 'FL', 'USA', 4.4, NULL, 99, 'grid_region', '2026-01-14 00:01:41.488539', '2026-01-14 20:13:06.475005');
INSERT INTO sadie_gtm.hotels VALUES (23, 'Pet Friendly Home Brickell 5 min to Miami Beach', 'https://br.bluepillow.com/search/6233abed4c4d8d9b9b7f5415?dest=bpex&cat=Cottage&lat=25.75688&lng=-80.19854&language=pt', NULL, NULL, NULL, '0101000020E61000004A9DDBDFB40C54C0C600E4DFC2C13940', 'Miami, FL 33129', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:01:41.486672', '2026-01-14 20:13:06.500465');
INSERT INTO sadie_gtm.hotels VALUES (37, 'Brown''s Hotel', NULL, NULL, NULL, NULL, '0101000020E610000008799851870854C08246FAFE17C53940', '112 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.4, NULL, 0, 'grid_region', '2026-01-14 00:01:55.370634', '2026-01-14 00:01:55.370634');
INSERT INTO sadie_gtm.hotels VALUES (140, 'South Beach Family Pet Friendly with Free Parking', 'https://br.bluepillow.com/search/681a0b09fa4e397cabb7fd85?dest=bkng&cat=Apartment&lat=25.77802&lng=-80.13584&language=pt', NULL, NULL, NULL, '0101000020E61000008D3CB59FB10854C0BF1AB1602CC73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:15.014664', '2026-01-14 21:51:26.20672');
INSERT INTO sadie_gtm.hotels VALUES (141, 'South Beach Free Parking Family Pet Friendly Walk to Beach Bay', 'https://br.bluepillow.com/search/6811a8be6178c7268f2c01f6?dest=bkng&cat=House&lat=25.77833&lng=-80.14046&language=pt', NULL, NULL, NULL, '0101000020E6100000371F3240FD0854C091802C9F40C73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:15.01709', '2026-01-14 21:51:26.209824');
INSERT INTO sadie_gtm.hotels VALUES (123, 'Luxuri Suites', 'http://www.luxurisuites.com/', '(305) 930-1362', NULL, 'booking@luxuri.com', '0101000020E61000005DDC4603780854C0DC65BFEE74C73940', '852 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.5, NULL, 3, 'grid_region', '2026-01-14 00:02:10.288175', '2026-01-14 23:33:59.82125');
INSERT INTO sadie_gtm.hotels VALUES (50, 'Miami Bliss Properties & Co.', NULL, '(305) 423-7075', NULL, NULL, '0101000020E6100000AC40E378740C54C0E17C451218C43940', '80 SW 8th St, Miami, FL 33130', 'Miami', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:01:55.419203', '2026-01-14 00:01:55.419203');
INSERT INTO sadie_gtm.hotels VALUES (51, 'Vacation Rentals in Miami ( AKA BRICKELL)', NULL, '(305) 762-9930', NULL, NULL, '0101000020E61000006F13494F6C0C54C0DA4D959460C23940', NULL, NULL, NULL, 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:01:55.421587', '2026-01-14 00:01:55.421587');
INSERT INTO sadie_gtm.hotels VALUES (52, 'Icon by Design Suites Miami', NULL, '(305) 851-2444', NULL, NULL, '0101000020E6100000AD72FCAB220C54C097F0958AD7C43940', '485 Brickell Ave, Miami, FL 33131', 'Miami', 'FL', 'USA', 2.3, NULL, 0, 'grid_region', '2026-01-14 00:01:55.424597', '2026-01-14 00:01:55.424597');
INSERT INTO sadie_gtm.hotels VALUES (125, 'Roami at 250 Collins', 'https://www.roami.com/destinations/miami-beach/68a2fd96f2adac0013eedc86', '(833) 305-3535', NULL, NULL, '0101000020E61000003EDD8A0E920854C0AE9EEE97AAC53940', '250 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 2.3, NULL, 99, 'grid_region', '2026-01-14 00:02:10.292573', '2026-01-14 21:50:41.540252');
INSERT INTO sadie_gtm.hotels VALUES (126, 'The Fritz Hotel', 'http://www.thefritzhotel.com/', '(305) 531-0101', NULL, NULL, '0101000020E6100000F56B4661720854C0DD9F41F971C63940', '524 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4, NULL, 99, 'grid_region', '2026-01-14 00:02:14.960961', '2026-01-14 21:50:41.544854');
INSERT INTO sadie_gtm.hotels VALUES (127, 'Ocean Drive Suites', 'https://www.oceandrivesuit.com/', NULL, NULL, NULL, '0101000020E610000044882B676F0854C02A3982AF43C63940', '465 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.8, NULL, 99, 'grid_region', '2026-01-14 00:02:14.975537', '2026-01-14 21:50:41.55008');
INSERT INTO sadie_gtm.hotels VALUES (128, 'Ocean Five Hotel Miami Beach', 'http://www.oceanfive.com/', '(877) 666-0505', NULL, NULL, '0101000020E6100000B0C0FCBA780854C0ABDC555925C63940', '436 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.6, NULL, 99, 'grid_region', '2026-01-14 00:02:14.980608', '2026-01-14 21:50:41.554606');
INSERT INTO sadie_gtm.hotels VALUES (129, 'Dream Destinations LLC', 'http://www.dreamdestinationsllc.com/', '(888) 440-4478', NULL, NULL, '0101000020E610000079003043880854C068CFC02385C53940', '225 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.9, NULL, 99, 'grid_region', '2026-01-14 00:02:14.983463', '2026-01-14 21:50:41.558234');
INSERT INTO sadie_gtm.hotels VALUES (61, 'Luxury Waterfront Brickell ICON W-Hotel Balcony Ocean Views', NULL, NULL, NULL, NULL, '0101000020E6100000E4744820140C54C0D5A1E41FC7C43940', 'Miami, FL 33131', 'Miami', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:07.079012', '2026-01-14 00:02:07.079012');
INSERT INTO sadie_gtm.hotels VALUES (139, 'Ocean Five Condo', 'https://www.oceanfivecondohtel.com/', '(305) 434-6658', NULL, NULL, '0101000020E6100000F2C92F28780854C0E36FD63B37C63940', '458 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.6, NULL, 99, 'grid_region', '2026-01-14 00:02:15.012416', '2026-01-14 21:50:41.56263');
INSERT INTO sadie_gtm.hotels VALUES (130, 'Oceanfront Family Friendly Retreat + Parking Spot', 'https://br.bluepillow.com/search/65cb8b173e6d928972fadbfc?dest=bpex&cat=Apartment&lat=25.77712&lng=-80.13209&language=pt', NULL, NULL, NULL, '0101000020E61000000CEDF71F740854C0430C2A60F1C63940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:14.986806', '2026-01-14 21:50:41.585724');
INSERT INTO sadie_gtm.hotels VALUES (66, 'Leamington Hotel', NULL, '(786) 755-2596', NULL, NULL, '0101000020E61000004544D6BF100C54C0CB12F81E89C63940', '307 NE 1st St, Miami, FL 33132', 'Miami', 'FL', 'USA', 2.3, NULL, 0, 'grid_region', '2026-01-14 00:02:07.092918', '2026-01-14 00:02:07.092918');
INSERT INTO sadie_gtm.hotels VALUES (67, 'The Ralston', NULL, '(833) 305-3535', NULL, NULL, '0101000020E6100000B0462C184B0C54C091BD39B764C63940', '40 NE 1st Ave #704, Miami, FL 33132', 'Miami', 'FL', 'USA', 3.2, NULL, 0, 'grid_region', '2026-01-14 00:02:07.095645', '2026-01-14 00:02:07.095645');
INSERT INTO sadie_gtm.hotels VALUES (131, 'Sofi Beach Apartments - Family Double Room', 'https://br.bluepillow.com/search/5eb447db67a9d10d04235336/564352405?dest=bkng&cat=Apartment&lat=25.77378&lng=-80.13278&language=pt', NULL, NULL, NULL, '0101000020E6100000D6DF12807F0854C0D0459E7F16C63940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:14.990416', '2026-01-14 21:50:41.588655');
INSERT INTO sadie_gtm.hotels VALUES (134, 'Two Family Ready Beachside at Ocean Drive | Close to Lummus Park', 'https://br.bluepillow.com/search/67a11656827ba4077c844ddc?dest=bpvr&cat=House&lat=25.779&lng=-80.12709&language=pt', NULL, NULL, NULL, '0101000020E610000077483140220854C05D1B857F6CC73940', 'Florida 33139', NULL, NULL, 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:14.998722', '2026-01-14 21:50:41.592');
INSERT INTO sadie_gtm.hotels VALUES (136, 'South Beach 2 Bedroom Family Pet Friendly Apartment with Free Parking on Premise', 'https://br.bluepillow.com/search/67a22f905a2dfa15b1826ed8?dest=bkng&cat=Apartment&lat=25.77859&lng=-80.14057&language=pt', NULL, NULL, NULL, '0101000020E6100000C52F0620FF0854C0FA83DCA051C73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:15.005037', '2026-01-14 21:50:41.594905');
INSERT INTO sadie_gtm.hotels VALUES (65, 'YOTEL Miami', 'https://www.yotel.com/en/hotels/yotel-miami?utm_source=Google&utm_medium=Yext_YOMIAH', '(786) 785-5700', '+17867855700', 'miami.reservations@yotel.com', '0101000020E61000000B896A00250C54C0602CC203B9C63940', '227 NE 2nd St, Miami, FL 33132', 'Miami', 'FL', 'USA', 3.6, NULL, 98, 'grid_region', '2026-01-14 00:02:07.090357', '2026-01-14 20:08:34.26019');
INSERT INTO sadie_gtm.hotels VALUES (42, 'OnTour Rentals', 'http://www.ontourrentals.com/', '(443) 800-7141', NULL, NULL, '0101000020E6100000FE6E70D86C0E54C0BBEEAD484CC83940', NULL, NULL, NULL, 'USA', 4.5, NULL, 99, 'grid_region', '2026-01-14 00:01:55.39734', '2026-01-14 20:13:06.478917');
INSERT INTO sadie_gtm.hotels VALUES (45, 'Key Biscayne Cottages', 'http://keybiscaynecottages.com/contactus.html', '(305) 361-8833', NULL, NULL, '0101000020E6100000C6962F794D0C54C0F8E4BC5A49C23940', '1441 Brickell Ave Unit 1400, Miami, FL 33131', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:01:55.404745', '2026-01-14 20:13:06.483207');
INSERT INTO sadie_gtm.hotels VALUES (46, 'Vaca Rentalz', 'http://www.vacarentalz.com/', '(305) 833-1008', NULL, NULL, '0101000020E6100000D237691A140C54C0B3812A244FC43940', '701 Brickell Ave, Miami, FL 33131', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:01:55.40687', '2026-01-14 20:13:06.486984');
INSERT INTO sadie_gtm.hotels VALUES (63, 'Miami Sun Hotel- Downtown/Port of Miami', 'http://www.themiamisunhotel.com/', '(305) 375-0786', NULL, NULL, '0101000020E61000007FA54E9B4C0C54C0D5BECAEBD2C63940', 'Sun Hotel, 226 NE 1st Ave, Miami, FL 33132', 'Miami', 'FL', 'USA', 2.9, NULL, 99, 'grid_region', '2026-01-14 00:02:07.085459', '2026-01-14 20:13:06.491041');
INSERT INTO sadie_gtm.hotels VALUES (43, 'IMD Miami', 'https://imd-miami.com/', '(305) 850-2456', NULL, 'info@imdmiami.com', '0101000020E61000005BC5877E120C54C04B34ED07E1C43940', '465 Brickell Ave, Miami, FL 33131', 'Miami', 'FL', 'USA', 4.8, NULL, 99, 'grid_region', '2026-01-14 00:01:55.399864', '2026-01-14 20:13:06.504308');
INSERT INTO sadie_gtm.hotels VALUES (62, 'Eurostars Langford', 'https://www.eurostarshotels.us/eurostars-langford.html?referer_code=lb0gg00yx&utm_source=google&utm_medium=business&utm_campaign=lb0gg00yx', '(305) 420-2200', '+13054202200', NULL, '0101000020E6100000C14C8006400C54C0B8E0B1440CC63940', '121 SE 1st St, Miami, FL 33131', 'Miami', 'FL', 'USA', 4.1, NULL, 99, 'grid_region', '2026-01-14 00:02:07.082112', '2026-01-14 20:13:06.505944');
INSERT INTO sadie_gtm.hotels VALUES (64, 'YVE Hotel Miami', 'https://www.yvehotelmiami.com/?utm_source=google&utm_medium=organic&utm_campaign=local-listing', '(305) 358-4555', '+13053584555', NULL, '0101000020E61000007162FEC00B0C54C0D773886EACC63940', '146 Biscayne Blvd, Miami, FL 33132', 'Miami', 'FL', 'USA', 3.8, NULL, 99, 'grid_region', '2026-01-14 00:02:07.088222', '2026-01-14 20:13:06.507617');
INSERT INTO sadie_gtm.hotels VALUES (143, 'Roami at Collins Ave Penthouse', 'https://www.roami.com/destinations/miami-beach/6865e201801a14003a099d34', '(833) 305-3535', NULL, NULL, '0101000020E610000068AF3E1E7A0854C0CB98277C5BC73940', '826 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.7, NULL, 99, 'grid_region', '2026-01-14 00:02:15.022552', '2026-01-14 21:51:26.15525');
INSERT INTO sadie_gtm.hotels VALUES (145, 'Beacon South Beach Hotel', 'http://www.beaconsouthbeach.com/', '(305) 763-8700', NULL, NULL, '0101000020E610000022BEB8F96B0854C0E253A5D2F4C63940', '720 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.9, NULL, 99, 'grid_region', '2026-01-14 00:02:15.026182', '2026-01-14 21:51:26.171538');
INSERT INTO sadie_gtm.hotels VALUES (72, 'SoBe Hostel & Bar', NULL, '(305) 534-6669', NULL, NULL, '0101000020E61000000A0A28799A0854C04703D3C496C53940', '235 Washington Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.9, NULL, 0, 'grid_region', '2026-01-14 00:02:07.113126', '2026-01-14 00:02:07.113126');
INSERT INTO sadie_gtm.hotels VALUES (73, 'Hotel Miami', NULL, NULL, NULL, NULL, '0101000020E610000075FF58880E0C54C067391AD187C63940', '307 NE 1st St, Miami, FL 33132', 'Miami', 'FL', 'USA', 5, NULL, 0, 'grid_region', '2026-01-14 00:02:07.11556', '2026-01-14 00:02:07.11556');
INSERT INTO sadie_gtm.hotels VALUES (142, 'South Beach Walk to Sea Free Parking Balcony Family Pet Friendly', 'https://br.bluepillow.com/search/67a22f815a2dfa15b1826b99?dest=bkng&cat=House&lat=25.77802&lng=-80.13584&language=pt', NULL, NULL, NULL, '0101000020E61000008D3CB59FB10854C0BF1AB1602CC73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:15.019108', '2026-01-14 21:51:26.212492');
INSERT INTO sadie_gtm.hotels VALUES (75, 'Downtown Miami', NULL, NULL, NULL, NULL, '0101000020E610000078B06AB52C0C54C0FA42C879FFC53940', 'Miami, FL', 'Miami', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:07.119681', '2026-01-14 00:02:07.119681');
INSERT INTO sadie_gtm.hotels VALUES (223, 'Rock Apartments by Lowkl', 'https://lowkl.com/property/rock-apartments-by-lowkl/', '(786) 232-3625', '+17862323625', 'reservations@lowkl.com', '0101000020E610000088B7CEBF5D0854C0D55D34BFF5C83940', '1351 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.2, NULL, 3, 'grid_region', '2026-01-14 00:02:30.510808', '2026-01-14 23:30:57.233714');
INSERT INTO sadie_gtm.hotels VALUES (428, 'Soho Beach House', 'https://www.sohohouse.com/houses/soho-beach-house?utm_source=google&utm_medium=organic&utm_campaign=googlemybusiness', '(786) 507-7900', '+17865077900', NULL, '0101000020E6100000E37B90AFCE0754C0D27B197BE5D03940', '4385 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.5, NULL, 3, 'grid_region', '2026-01-14 00:03:49.844933', '2026-01-14 23:45:58.583388');
INSERT INTO sadie_gtm.hotels VALUES (423, 'Wishes Biscayne Motel', 'http://www.wishesbiscaynemotel.us/', '(305) 571-5115', NULL, NULL, '0101000020E6100000816E79F6260C54C0E67C0CB155CF3940', '3530 Biscayne Blvd, Miami, FL 33137', 'Miami', 'FL', 'USA', 2.7, NULL, 99, 'grid_region', '2026-01-14 00:03:49.824038', '2026-01-14 21:48:46.199169');
INSERT INTO sadie_gtm.hotels VALUES (432, 'Westover Arms Hotel', 'http://www.westoverarmshotel.com/', '(305) 390-8088', NULL, NULL, '0101000020E610000003AD65D7E20754C0159051F932D03940', '4100 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4, NULL, 99, 'grid_region', '2026-01-14 00:03:53.47521', '2026-01-14 21:48:46.245103');
INSERT INTO sadie_gtm.hotels VALUES (436, 'Fontainebleau | 2BR Beachfront Scenic View', 'https://properties.makrealty.com/properties/678694a57ab2850013ab8c91', NULL, NULL, NULL, '0101000020E6100000EF2312E0CF0754C0D8EE1EA0FBD03940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:53.485131', '2026-01-14 21:48:46.265377');
INSERT INTO sadie_gtm.hotels VALUES (87, 'Fonte Vacation Rentals - Brickell', NULL, '(786) 907-2502', NULL, NULL, '0101000020E6100000D237691A140C54C05E29CB10C7C43940', '485 Brickell Ave, Miami, FL 33131', 'Miami', 'FL', 'USA', 4, NULL, 0, 'grid_region', '2026-01-14 00:02:07.147582', '2026-01-14 00:02:07.147582');
INSERT INTO sadie_gtm.hotels VALUES (225, 'Iberostar Waves Berkeley Shore', 'https://www.iberostar.com/eu/hotels/miami/iberostar-waves-berkeley-shore/?utm_source=gmb&utm_medium=organic&utm_campaign=IBSVOL_AME_SEOLOC_GMB_NA_EN_USA_MIA_MIA_NA_PULL_NA_NA_NA_NA_NA', '+1 786-605-0810', NULL, NULL, '0101000020E61000004181D2AB5C0854C0A46FD23428CA3940', '1610 Collins Ave, Miami Beach, FL 33139, United States', 'FL 33139', NULL, 'USA', 4, NULL, 99, 'grid_region', '2026-01-14 00:02:37.66984', '2026-01-14 21:49:07.112202');
INSERT INTO sadie_gtm.hotels VALUES (91, 'Resort and luxurious living in downtown Miami', NULL, NULL, NULL, NULL, '0101000020E61000004E250340150C54C023CA28E0E8C63940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:07.157825', '2026-01-14 00:02:07.157825');
INSERT INTO sadie_gtm.hotels VALUES (92, 'Lux Condo with City View, Downtown Brickell, Free Parking, Pool, Gym', NULL, NULL, NULL, NULL, '0101000020E610000044DD0720350C54C0FD892540A8C23940', 'Miami, FL 33131', 'Miami', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:07.159848', '2026-01-14 00:02:07.159848');
INSERT INTO sadie_gtm.hotels VALUES (196, 'Eurostars Winter Haven', 'https://www.eurostarshotels.us/eurostars-winter-haven.html?referer_code=lb0ww00yx&utm_source=warios&utm_medium=business&utm_campaign=lb0ww00yx', '(305) 531-5571', '+13055315571', NULL, '0101000020E6100000E361EB634F0854C0668C6A6C0AC93940', '1400 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.9, NULL, 99, 'grid_region', '2026-01-14 00:02:27.010099', '2026-01-14 21:49:19.404657');
INSERT INTO sadie_gtm.hotels VALUES (94, 'The Savoy Hotel & Beach Club ~ Miami Beach', 'https://www.savoy-miami.com/', '(305) 532-0200', NULL, NULL, '0101000020E6100000CDC7B5A1620854C0132FAAA0FDC53940', '425 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.4, NULL, 99, 'grid_region', '2026-01-14 00:02:10.195433', '2026-01-14 21:50:25.203638');
INSERT INTO sadie_gtm.hotels VALUES (95, 'Park Central South Beach', 'https://thegabrielsouthbeach.com/', '(305) 685-2000', NULL, NULL, '0101000020E6100000B691FCD26C0854C04A61399DBFC63940', '640 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4, NULL, 99, 'grid_region', '2026-01-14 00:02:10.21187', '2026-01-14 21:50:25.2118');
INSERT INTO sadie_gtm.hotels VALUES (96, 'The Tony Hotel South Beach', 'http://www.thetonyhotel.com/', '(305) 531-2222', NULL, NULL, '0101000020E610000007EE409D720854C0E11577723CC73940', '801 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.4, NULL, 99, 'grid_region', '2026-01-14 00:02:10.215865', '2026-01-14 21:50:25.220028');
INSERT INTO sadie_gtm.hotels VALUES (97, 'Pelican Hotel Miami Beach', 'http://www.pelicanhotel.com/', '(305) 673-3373', NULL, NULL, '0101000020E6100000555DD1F7640854C0919D126B4CC73940', '826 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:02:10.219245', '2026-01-14 21:50:25.227226');
INSERT INTO sadie_gtm.hotels VALUES (98, 'Balfour Miami Beach, a Registry Collection Hotel', 'https://balfourhotelmiami.com/', '(305) 538-1055', NULL, NULL, '0101000020E6100000C1221A387B0854C08DA2BDB0EBC53940', '350 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.5, NULL, 99, 'grid_region', '2026-01-14 00:02:10.221849', '2026-01-14 21:50:25.239655');
INSERT INTO sadie_gtm.hotels VALUES (99, 'Majestic Hotel South Beach', 'https://www.majesticsouthbeach.com/', '(305) 455-3270', NULL, NULL, '0101000020E61000009EAB521F6D0854C0B891B245D2C63940', '660 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.4, NULL, 99, 'grid_region', '2026-01-14 00:02:10.225427', '2026-01-14 21:50:25.247562');
INSERT INTO sadie_gtm.hotels VALUES (83, 'Sunshine Rentals Miami', 'https://www.sunshine-rentals.miami/', '(813) 694-2053', NULL, NULL, '0101000020E610000059FB3BDB230C54C087742E7BC8C63940', '227 NE 2nd St, Miami, FL 33132', 'Miami', 'FL', 'USA', 5, NULL, 99, 'grid_region', '2026-01-14 00:02:07.138321', '2026-01-14 20:13:06.496633');
INSERT INTO sadie_gtm.hotels VALUES (80, 'Miami Vacation Rentals - Downtown - Deluxe Studio, 1 King Bed with Sofa bed, Bay View 2408', 'https://br.bluepillow.com/search/67cab1c2fa1a57d5a4b05976/327276827?dest=eps&cat=Apartment&lat=25.77888&lng=-80.18908&language=pt', NULL, '0992961096', 'info@bluepillow.com', '0101000020E6100000707610E0190C54C0DE8893A064C73940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:02:07.131933', '2026-01-14 20:13:06.511191');
INSERT INTO sadie_gtm.hotels VALUES (81, 'Miami Vacation Rentals - Downtown - Deluxe Studio, 1 King Bed with Sofa bed, Bay View2013', 'https://br.bluepillow.com/search/67cab1c2fa1a57d5a4b05976/327084555?dest=eps&cat=Apartment&lat=25.77888&lng=-80.18908&language=pt', NULL, NULL, NULL, '0101000020E6100000707610E0190C54C0DE8893A064C73940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:02:07.134241', '2026-01-14 20:13:06.515347');
INSERT INTO sadie_gtm.hotels VALUES (82, 'Luxury Condo in Downtown Brickell 1B\/1B', 'https://br.bluepillow.com/search/62177ff6a7239796807f4588?dest=bpvr&cat=Apartment&lat=25.7603&lng=-80.19178&language=pt', NULL, NULL, NULL, '0101000020E610000083610A20460C54C09AA84A00A3C23940', 'Miami, FL 33131', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:07.136508', '2026-01-14 20:13:06.519413');
INSERT INTO sadie_gtm.hotels VALUES (84, 'Luxurious 1 BD Condo in Downtown #3015', 'https://br.bluepillow.com/search/67a10a44827ba4077c7bef3c?dest=bpvr&cat=Apartment&lat=25.77888&lng=-80.18905&language=pt', NULL, NULL, NULL, '0101000020E61000007CF6B75F190C54C0DE8893A064C73940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:07.140281', '2026-01-14 20:13:06.523207');
INSERT INTO sadie_gtm.hotels VALUES (85, 'Ocean Front View Stylish Condo in Downtown Miami', 'https://br.bluepillow.com/search/67a23ee4905c444f2d08720f?dest=ago&cat=Vacation+rental+(other)&lat=25.77918&lng=-80.18875&language=pt', NULL, NULL, NULL, '0101000020E6100000F5245580140C54C0512E8D5F78C73940', 'Miami, FL 33130', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:07.142582', '2026-01-14 20:13:06.527131');
INSERT INTO sadie_gtm.hotels VALUES (216, 'Dolce Suites South Beach', 'https://deals.vio.com/?sig=73aca13c7f952d2641c156f3e69125e1eb497c325f122828ee5aa8797168b9a12d32303331333438363233&turl=https%3A%2F%2Fwww.vio.com%2FHotel%2FSearch%3FhotelId%3D4602359%26utm_source%3Dgha-vr%26utm_campaign%3Dstatic%26openHotelDetails%3D1', NULL, NULL, 'partners@vio.com', '0101000020E610000085DA25602A0954C06DDFA3FE7AC93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:02:30.495562', '2026-01-14 21:49:19.491595');
INSERT INTO sadie_gtm.hotels VALUES (446, 'Beachfront Luxury Apartment Rental 3 br Unit 1440', 'https://www.beachhouse.com/miami-beach-beach-vacation-rental-p567786.html', NULL, NULL, NULL, '0101000020E6100000EF6A5E7A200854C084E3439AC2CC3940', '102 24th St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 5, NULL, 99, 'grid_region', '2026-01-14 00:03:53.509417', '2026-01-14 21:50:23.804832');
INSERT INTO sadie_gtm.hotels VALUES (447, 'Deluxe beachfront condo with ocean views, pools, spas, gym, valet parking', 'https://br.bluepillow.com/search/65cb81033e6d928972f6ebf3?dest=bpex&cat=Apartment&lat=25.79871&lng=-80.12689&language=pt', NULL, NULL, NULL, '0101000020E6100000BAE70A001F0854C0A4FED53E78CC3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:53.512323', '2026-01-14 21:50:23.810886');
INSERT INTO sadie_gtm.hotels VALUES (457, 'YOUR VACATION HOME! NEAR THE BEACH', 'https://book.bookedaway.com/listings/225820?googleVR=1&utm_source=google&utm_medium=vacation_rentals', NULL, NULL, NULL, '0101000020E610000045AEE5DFF80754C059FD6C3F74CE3940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:04:00.186446', '2026-01-14 21:50:23.831535');
INSERT INTO sadie_gtm.hotels VALUES (101, 'Kimpton Angler''s Hotel', 'https://www.anglershotelmiami.com/?&cm_mmc=WEB-_-KI-_-AMER-_-EN-_-EV-_-Google%20Business%20Profile-_-DD-_-anglers', '(305) 534-9600', NULL, NULL, '0101000020E61000008466D7BD950854C0147E0459AAC63940', '660 Washington Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.1, NULL, 99, 'grid_region', '2026-01-14 00:02:10.232144', '2026-01-14 21:50:24.470003');
INSERT INTO sadie_gtm.hotels VALUES (383, 'Boutique Suites 3 min walk to beach - King Suite with Pool View', 'https://br.bluepillow.com/search/6398dbf4c551970d3c737583/772772006?dest=bkng&cat=Apartment&lat=25.7871&lng=-80.13003&language=pt', NULL, '0992961096', 'info@bluepillow.com', '0101000020E610000088241F60520854C02AB05B5F7FC93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:03:28.957973', '2026-01-14 21:51:42.85855');
INSERT INTO sadie_gtm.hotels VALUES (191, 'Waterfront Spacious Luxury Studio at IconBrickell', 'https://deals.vio.com/?sig=73aca13c7f952d2641c156f3e69125e1eb497c325f122828ee5aa8797168b9a12d32303331333438363233&turl=https%3A%2F%2Fwww.vio.com%2FHotel%2FSearch%3FhotelId%3D15694472%26utm_source%3Dgha-vr%26utm_campaign%3Dstatic%26openHotelDetails%3D1', NULL, NULL, 'partners@vio.com', '0101000020E610000056F4E21F110C54C07CB207FFC7C43940', 'Miami, FL 33131', 'Miami', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:02:26.990566', '2026-01-14 21:51:47.554112');
INSERT INTO sadie_gtm.hotels VALUES (108, 'Bikini', NULL, '(954) 397-5105', NULL, NULL, '0101000020E61000001D63DD2E6A0854C0F46679C322C73940', '760 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 1, NULL, 0, 'grid_region', '2026-01-14 00:02:10.252598', '2026-01-14 00:02:10.252598');
INSERT INTO sadie_gtm.hotels VALUES (363, 'Momentum Business Center', 'http://momentumbusinesscenter.com/', '(305) 777-2200', NULL, NULL, '0101000020E610000079A97DDFE40854C0CC800E4E9FCA3940', '1680 Michigan Ave Suite 700, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.8, NULL, 99, 'grid_region', '2026-01-14 00:03:20.668604', '2026-01-14 21:51:52.915874');
INSERT INTO sadie_gtm.hotels VALUES (110, 'ORANGE', NULL, '(305) 815-8786', NULL, NULL, '0101000020E6100000CF59B09EA40854C085668D30FBC53940', '350 Euclid Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.4, NULL, 0, 'grid_region', '2026-01-14 00:02:10.256636', '2026-01-14 00:02:10.256636');
INSERT INTO sadie_gtm.hotels VALUES (365, 'NEW LISTING! Belleza Miami Beach Family Deluxe 1BR sleeps 6', 'https://br.bluepillow.com/search/65cb7e773e6d928972f63d79?dest=bpex&cat=House&lat=25.79767&lng=-80.13179&language=pt', NULL, NULL, NULL, '0101000020E6100000BBBB29406F0854C0BBFC982034CC3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:03:24.086096', '2026-01-14 21:51:52.985773');
INSERT INTO sadie_gtm.hotels VALUES (132, 'Family 1 bedroom full kitchen double bed', NULL, NULL, NULL, NULL, '0101000020E61000002920ED7F800854C047E6913F18C63940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:14.992886', '2026-01-14 00:02:14.992886');
INSERT INTO sadie_gtm.hotels VALUES (133, '🏖️WALK TO BEACH🏖️Family Friendly Perfect Location-Parking', NULL, NULL, NULL, NULL, '0101000020E610000093D629A09A0854C022F94A2025C63940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:14.995894', '2026-01-14 00:02:14.995894');
INSERT INTO sadie_gtm.hotels VALUES (533, 'Blu Vacation Rentals', 'http://blurentals.com/', '(786) 625-7603', NULL, NULL, '0101000020E61000005E06088BAF0754C02FA75F7D97D53940', 'Blu Vacation Rentals @ The Castle Beach Club, 5445 Collins Ave STE CU20, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:04:28.691775', '2026-01-14 21:49:56.673295');
INSERT INTO sadie_gtm.hotels VALUES (135, '1 bedroom full Kitchen family group', NULL, NULL, NULL, NULL, '0101000020E61000002920ED7F800854C047E6913F18C63940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:15.001746', '2026-01-14 00:02:15.001746');
INSERT INTO sadie_gtm.hotels VALUES (552, 'Villa Santorini | 8BR 7BA for 26 | Waterfront, Private Pool & More | Miami Beach', 'https://dreamvillas.holidayfuture.com/listings/178346?googleVR=1&utm_source=google&utm_medium=vacation_rentals', NULL, NULL, 'dreamvillas@ourhausmanagement.com', '0101000020E610000074FBF6BFED0754C0FD37E5C061D43940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 3, 'grid_region', '2026-01-14 00:04:37.624019', '2026-01-14 23:27:29.411969');
INSERT INTO sadie_gtm.hotels VALUES (137, 'Family 2 bedroom full kitchen South of Fifth', NULL, NULL, NULL, NULL, '0101000020E61000002920ED7F800854C047E6913F18C63940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:15.007692', '2026-01-14 00:02:15.007692');
INSERT INTO sadie_gtm.hotels VALUES (138, 'BEST LOCATION 🏖️FAMILY FRIENDLY w BALCONY - 1 BLOCK to BEACH Parking Laundry', NULL, NULL, NULL, NULL, '0101000020E61000008223DCBF8D0854C0BA5FAA3EFCC53940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:15.010077', '2026-01-14 00:02:15.010077');
INSERT INTO sadie_gtm.hotels VALUES (553, 'FB Miami Beach Tresor Private Luxury Suites', 'https://m.wowotrip.com/homestay/detail?hotelId=9JA1', NULL, NULL, NULL, '0101000020E610000070B43E40D20754C0BBD97AE129D13940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:39.612814', '2026-01-14 21:49:56.756036');
INSERT INTO sadie_gtm.hotels VALUES (554, 'Luxury Suites International at Fontainebleau', 'https://deals.vio.com/?sig=73aca13c7f952d2641c156f3e69125e1eb497c325f122828ee5aa8797168b9a12d32303331333438363233&turl=https%3A%2F%2Fwww.vio.com%2FHotel%2FSearch%3FhotelId%3D117229390%26utm_source%3Dgha-vr%26utm_campaign%3Dstatic%26openHotelDetails%3D1', NULL, NULL, 'partners@vio.com', '0101000020E6100000E9F3ACFFCE0754C060D2CE1F89D13940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:39.622326', '2026-01-14 21:49:56.760311');
INSERT INTO sadie_gtm.hotels VALUES (505, 'Miami Beach Cozy Studio', 'https://br.bluepillow.com/search/62df29d22d760a9969f0f216?dest=bpex&cat=Apartment&lat=25.81149&lng=-80.12239&language=pt', NULL, NULL, NULL, '0101000020E610000033D53840D50754C07B8FE9BFBDCF3940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:13.338599', '2026-01-14 21:50:09.546985');
INSERT INTO sadie_gtm.hotels VALUES (252, 'The Catalina Hotel & Beach Club', 'https://catalinahotel.com/', '(305) 674-1160', NULL, NULL, '0101000020E61000001FF065474F0854C0B329B2310ACB3940', '1732 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.9, NULL, 99, 'grid_region', '2026-01-14 00:02:46.892507', '2026-01-14 21:50:16.371108');
INSERT INTO sadie_gtm.hotels VALUES (255, 'Marseilles Beachfront Hotel', 'http://www.marseilleshotel.com/', '(305) 538-5711', NULL, NULL, '0101000020E610000073DAAE2B410854C0A6A3D23E0CCB3940', '1741 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.4, NULL, 99, 'grid_region', '2026-01-14 00:02:46.898173', '2026-01-14 21:50:16.392493');
INSERT INTO sadie_gtm.hotels VALUES (144, 'Sofi Apartments', NULL, '(786) 780-7948', NULL, NULL, '0101000020E61000006CB64D4C720854C09C137B681FC73940', '751 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 2.8, NULL, 0, 'grid_region', '2026-01-14 00:02:15.024209', '2026-01-14 00:02:15.024209');
INSERT INTO sadie_gtm.hotels VALUES (266, 'Beachfront Studio South Beach Miami', 'https://deals.vio.com/?sig=73aca13c7f952d2641c156f3e69125e1eb497c325f122828ee5aa8797168b9a12d32303331333438363233&turl=https%3A%2F%2Fwww.vio.com%2FHotel%2FSearch%3FhotelId%3D77444015%26utm_source%3Dgha-vr%26utm_campaign%3Dstatic%26openHotelDetails%3D1', NULL, NULL, 'partners@vio.com', '0101000020E6100000371CF1BF700854C04373F8FFCCC53940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:02:46.915001', '2026-01-14 21:50:16.442011');
INSERT INTO sadie_gtm.hotels VALUES (294, 'LINCOLN RD-MIAMI BEACH-CHARMING VACATION RENTALS', 'https://www.decolar.com/hoteis/h-1754875', NULL, NULL, NULL, '0101000020E6100000C17BFDFFEE0854C089F5FC1F16CA3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:54.627799', '2026-01-14 21:50:18.68234');
INSERT INTO sadie_gtm.hotels VALUES (291, 'C Ocean Rentals at Strand Ocean Drive', 'https://br.bluepillow.com/search/646341c4a51ab0c4fc3c6450?dest=eps&cat=Apartment&lat=25.78119&lng=-80.13068&language=pt', NULL, '0992961096', 'info@bluepillow.com', '0101000020E61000002FB720005D0854C0CC6E7720FCC73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:02:54.617086', '2026-01-14 21:50:18.752901');
INSERT INTO sadie_gtm.hotels VALUES (153, 'South Beach Vacation Rentals on Ocean Drive', NULL, NULL, NULL, NULL, '0101000020E61000001FAC10A0700854C0D5BF35C181C63940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:18.678611', '2026-01-14 00:02:18.678611');
INSERT INTO sadie_gtm.hotels VALUES (161, 'Fisher Island Beach Club Restaurant', NULL, NULL, NULL, NULL, '0101000020E6100000C390E6D9F60854C00BDC700E8DC13940', '15211 Fisher Island Dr, Miami Beach, FL 33109', 'Miami Beach', 'FL', 'USA', 4.6, NULL, 0, 'grid_region', '2026-01-14 00:02:18.694092', '2026-01-14 00:02:18.694092');
INSERT INTO sadie_gtm.hotels VALUES (314, 'Boulan South Beach Miami', 'https://www.boulanmiami.com/', '(216) 392-7141', '3059250740', NULL, '0101000020E61000004DA7D0D4460854C0ADAAF298DCCB3940', '220 21st St APT 507, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3, NULL, 3, 'grid_region', '2026-01-14 00:03:05.67044', '2026-01-14 23:28:28.975077');
INSERT INTO sadie_gtm.hotels VALUES (406, 'Generator Miami', 'https://staygenerator.com/hotels/miami?utm_source=google-my-business&utm_medium=organic&utm_campaign=hostel-Miami', '(786) 496-5730', '+17864965730', 'ask.miami@staygenerator.com', '0101000020E610000005B4BE92F50754C093324EE89ACE3940', '3120 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.5, NULL, 3, 'grid_region', '2026-01-14 00:03:39.44138', '2026-01-14 23:28:36.297603');
INSERT INTO sadie_gtm.hotels VALUES (86, 'NEW Luxury Downtown Apt - Gym,Pool by Sunshine Rentals Miami', 'https://sunshine-rentals.miami/listing/en/655842', NULL, '+16462805554', 'contact@rsr-rentals.com', '0101000020E61000000B19D9DF230C54C063B2B8FFC8C63940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 3, 'grid_region', '2026-01-14 00:02:07.1447', '2026-01-14 23:29:36.429212');
INSERT INTO sadie_gtm.hotels VALUES (389, 'The Palms Hotel & Spa', 'https://www.thepalmshotel.com/?utm_source=google&utm_medium=organic&utm_campaign=business-listing', '(305) 534-0505', '18005500505', NULL, '0101000020E61000006D776A89F00754C0E8BF07AF5DCE3940', '3025 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.4, NULL, 3, 'grid_region', '2026-01-14 00:03:31.870065', '2026-01-14 23:29:40.922929');
INSERT INTO sadie_gtm.hotels VALUES (309, 'Casa SOBE', 'https://casahotelsgroup.com/casa-sobe/', '(305) 801-5348', '3058015348', 'info@hotels.casa', '0101000020E610000075B63643600854C043D48E2CAAC93940', '1506 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 3, 'grid_region', '2026-01-14 00:03:02.361026', '2026-01-14 23:30:50.195179');
INSERT INTO sadie_gtm.hotels VALUES (320, 'Art Deco Wing of The Betsy Hotel', 'http://thebetsyhotel.com/', '(305) 531-6100', '8445392840', 'info@thebetsyhotel.com', '0101000020E61000008069AC58570854C09A98897D5DC93940', '1433 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.2, NULL, 3, 'grid_region', '2026-01-14 00:03:10.657694', '2026-01-14 23:31:18.914702');
INSERT INTO sadie_gtm.hotels VALUES (277, 'Casa Tua Hotel', 'https://www.casatualife.com/', '(305) 673-1010', NULL, NULL, '0101000020E6100000E6F516C5610854C0702AAD1ADFCA3940', '1700 James Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.1, NULL, 1, 'grid_region', '2026-01-14 00:02:50.313533', '2026-01-14 23:31:24.470461');
INSERT INTO sadie_gtm.hotels VALUES (268, 'Ocean Drive Beachfront by Deco 305-Beach Apt Deal', 'https://all.deco305.com/listings/233176?googleVR=1&utm_source=google&utm_medium=vacation_rentals', NULL, '+17863092173', 'louiezrentals@gmail.com', '0101000020E6100000CBC3F81F4F0854C0BF6CF1DF72C93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 3, 'grid_region', '2026-01-14 00:02:46.91737', '2026-01-14 23:32:48.813784');
INSERT INTO sadie_gtm.hotels VALUES (265, 'Beachfront Ocean View Apartment on Ocean Drive', 'https://stayviax.com/hotel/72296725', NULL, NULL, 'support@stayviax.com', '0101000020E6100000E6EA22E06B0854C04A743BA011C73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 3, 'grid_region', '2026-01-14 00:02:46.913511', '2026-01-14 23:33:02.74013');
INSERT INTO sadie_gtm.hotels VALUES (416, 'Kasa Collins Park Miami Beach Convention Center', 'https://kasa.com/properties/kasa-collins-park-miami-beach-convention-center?utm_source=Google&utm_medium=nonpaid&utm_campaign=GMB&utm_term=VisitHotelWebsiteButton&utm_content=CPK', '(786) 901-5642', NULL, NULL, '0101000020E61000007C09151C5E0854C0076C184F4ECC3940', '2150 Park Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.4, NULL, 3, 'grid_region', '2026-01-14 00:03:39.460272', '2026-01-14 23:33:20.167802');
INSERT INTO sadie_gtm.hotels VALUES (414, 'Samantha Apartments by Lowkl', 'https://lowkl.com/property/samantha-apartments-by-lowkl/', '(786) 385-4880', '+17863854880', 'reservations@lowkl.com', '0101000020E6100000E621533E040854C0162D40DB6ACE3940', '235 30th St, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.8, NULL, 3, 'grid_region', '2026-01-14 00:03:39.456682', '2026-01-14 23:33:26.262636');
INSERT INTO sadie_gtm.hotels VALUES (487, 'Florida Buffet Restaurant', 'https://www.riu.com/en/hotel/usa/miami-beach/hotel-riu-plaza-miami-beach/', '(305) 673-5333', NULL, NULL, '0101000020E6100000F20B0ADEEB0754C029F2DA5B80CE3940', '3101 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:04:05.185879', '2026-01-14 21:50:23.863103');
INSERT INTO sadie_gtm.hotels VALUES (168, 'Ocean Drive Studios Beach Front', NULL, '(305) 793-2079', NULL, NULL, '0101000020E61000006A847EA65E0854C0B6494563EDC73940', '1024 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 2.7, NULL, 0, 'grid_region', '2026-01-14 00:02:22.807168', '2026-01-14 00:02:22.807168');
INSERT INTO sadie_gtm.hotels VALUES (169, 'Edgewater South Beach', NULL, '(786) 517-6200', NULL, NULL, '0101000020E61000008F60F426500854C01CD13DEB1AC93940', '1410 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.5, NULL, 0, 'grid_region', '2026-01-14 00:02:22.810366', '2026-01-14 00:02:22.810366');
INSERT INTO sadie_gtm.hotels VALUES (174, 'The South Beach House: Walk to Everything!', NULL, '(786) 286-2490', NULL, NULL, '0101000020E6100000C68FE7E9120954C0AA63F08BA6C83940', '1234 13th St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:22.825864', '2026-01-14 00:02:22.825864');
INSERT INTO sadie_gtm.hotels VALUES (175, 'The Miami Beach', NULL, NULL, NULL, NULL, '0101000020E61000000A021A5BBE0854C01F1CA2C0F1C73940', '1018 Meridian Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.2, NULL, 0, 'grid_region', '2026-01-14 00:02:26.920473', '2026-01-14 00:02:26.920473');
INSERT INTO sadie_gtm.hotels VALUES (176, 'Marina''s Bar & Grill', NULL, '(305) 371-4400', NULL, NULL, '0101000020E61000007F87FDF9110C54C068AACC391DC73940', 'Biscayne Blvd, Miami, FL 33130', 'Miami', 'FL', 'USA', 3.8, NULL, 0, 'grid_region', '2026-01-14 00:02:26.927426', '2026-01-14 00:02:26.927426');
INSERT INTO sadie_gtm.hotels VALUES (179, 'Luxury Waterfront Residences, Studio Apartment with Sea View', NULL, NULL, NULL, NULL, '0101000020E6100000FF983160240C54C089F83DA022C73940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:26.939256', '2026-01-14 00:02:26.939256');
INSERT INTO sadie_gtm.hotels VALUES (180, 'Waterfront Luxury 1BR Oasis with Private Balcony', NULL, NULL, NULL, NULL, '0101000020E6100000BCF957A0270C54C028A14F3F03C33940', 'Miami, FL 33131', 'Miami', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:26.942522', '2026-01-14 00:02:26.942522');
INSERT INTO sadie_gtm.hotels VALUES (182, 'Luxury Waterfront Condo In The Urban Oasis At Icon-Brickell Free Spa', NULL, NULL, NULL, NULL, '0101000020E6100000DC35D71F170C54C037F35080CDC43940', 'Miami, FL 33131', 'Miami', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:26.948402', '2026-01-14 00:02:26.948402');
INSERT INTO sadie_gtm.hotels VALUES (184, 'Waterfront Luxury private balcony', NULL, NULL, NULL, NULL, '0101000020E6100000FFC1D19F470954C022669BC019C93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:26.956106', '2026-01-14 00:02:26.956106');
INSERT INTO sadie_gtm.hotels VALUES (185, 'Waterfront Luxury Apartment 2Bedrooms IconBrickell', NULL, NULL, NULL, NULL, '0101000020E6100000AB460AC01A0C54C08E5143C0C6C43940', 'Miami, FL 33131', 'Miami', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:26.96688', '2026-01-14 00:02:26.96688');
INSERT INTO sadie_gtm.hotels VALUES (188, 'Waterfront Luxury: South Beach 2Bed/2Bath Boutique Condo, Panoramic Views', NULL, NULL, NULL, NULL, '0101000020E61000009BA50980160954C0B63984E0A7C63940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:26.9759', '2026-01-14 00:02:26.9759');
INSERT INTO sadie_gtm.hotels VALUES (190, 'Luxury Waterfront Residences - near Kaseya Center\n', NULL, NULL, NULL, NULL, '0101000020E61000002D414640050C54C0ECFF779F3EC73940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:26.984887', '2026-01-14 00:02:26.984887');
INSERT INTO sadie_gtm.hotels VALUES (193, 'Waterfront Luxury Apartment 2 Bedrooms IconBrickell', NULL, NULL, NULL, NULL, '0101000020E6100000C2B6EADF1A0C54C0A6C123E0C6C43940', 'Miami, FL 33131', 'Miami', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:27.003859', '2026-01-14 00:02:27.003859');
INSERT INTO sadie_gtm.hotels VALUES (372, 'Casa Gaby Apartments Part of the Oasis Casita Collection', 'https://www.oasiscasitacollection.com/resorts/miami-beach/oasis/casa-gaby-apartments/', '(786) 992-7751', '+17869927751', NULL, '0101000020E610000086D6D4C3E10854C094490D6D00C83940', '1032 Michigan Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.1, NULL, 3, 'grid_region', '2026-01-14 00:03:24.112321', '2026-01-14 23:33:49.115333');
INSERT INTO sadie_gtm.hotels VALUES (246, 'Greenview by Lowkl', 'https://lowkl.com/property/greenview-by-lowkl/', '(786) 550-8053', '+17865508053', 'reservations@lowkl.com', '0101000020E6100000A5B915C26A0854C06A4C88B9A4CA3940', '1671 Washington Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.8, NULL, 3, 'grid_region', '2026-01-14 00:02:46.882404', '2026-01-14 23:33:55.212704');
INSERT INTO sadie_gtm.hotels VALUES (194, 'Cardozo South Beach', 'https://cardozohotel.com/?utm_source=google&utm_medium=organic&utm_campaign=mybusiness', '(786) 577-7600', '7865777600', 'sales@cardozosouthbeach.com', '0101000020E61000007A0B3554560854C07891AE3EC3C83940', '1300 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.1, NULL, 3, 'grid_region', '2026-01-14 00:02:27.006165', '2026-01-14 23:34:09.953');
INSERT INTO sadie_gtm.hotels VALUES (269, 'Ocean Drive Beachfront by Deco 305-Ocean Dream', 'https://all.deco305.com/listings/233189?googleVR=1&utm_source=google&utm_medium=vacation_rentals', NULL, '+17863092173', 'louiezrentals@gmail.com', '0101000020E6100000CBC3F81F4F0854C0BF6CF1DF72C93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 3, 'grid_region', '2026-01-14 00:02:46.918662', '2026-01-14 23:35:12.285715');
INSERT INTO sadie_gtm.hotels VALUES (243, 'Grand Stay Cozy Miami', 'https://staycozy.com/', '(716) 902-6259', '+17169026259', 'reservations@staycozy.com', '0101000020E6100000BEFE7FF7E90B54C031CD74AF93CA3940', '1717 N Bayshore Dr, Miami, FL 33132', 'Miami', 'FL', 'USA', 3.3, NULL, 1, 'grid_region', '2026-01-14 00:02:46.867477', '2026-01-14 23:35:24.265179');
INSERT INTO sadie_gtm.hotels VALUES (200, 'Boutique Suite South Beach - West Deco', 'https://boutiqueapartmentsmiami.hostify.club/', '(786) 961-1466', NULL, NULL, '0101000020E6100000D1178C5B160954C047A3A76D68C93940', '1443 West Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 2.9, NULL, 3, 'grid_region', '2026-01-14 00:02:30.437086', '2026-01-14 23:35:37.113977');
INSERT INTO sadie_gtm.hotels VALUES (44, 'Island Leasing | Fisher Island', 'https://www.islandsofmiami.com/', '(305) 673-6030', '3056045992', 'rbv@theislandre.com', '0101000020E61000000D3D1867420954C0F736A2201DC33940', '42208 Fisher Island Dr, Miami Beach, FL 33109', 'Miami Beach', 'FL', 'USA', 5, NULL, 3, 'grid_region', '2026-01-14 00:01:55.402646', '2026-01-14 23:43:10.278172');
INSERT INTO sadie_gtm.hotels VALUES (367, 'Courtyard Apartments Part of the Oasis Casita Collection', 'https://www.oasiscasitacollection.com/resorts/miami-beach/oasis/courtyard-apartments/', '(786) 992-7751', '+17869927751', NULL, '0101000020E6100000821C9430D30854C05C0EAAC3C0C93940', '1536 Jefferson Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.6, NULL, 3, 'grid_region', '2026-01-14 00:03:24.099018', '2026-01-14 23:43:30.598875');
INSERT INTO sadie_gtm.hotels VALUES (117, 'The March Hotel', 'https://themarchhotel.com/?utm_source=google&utm_medium=Local+SEO&utm_campaign=Google+Business+Profile', '(305) 397-8144', '+13053978144', 'hello@themarchhotel.com', '0101000020E610000016E934C1A60854C0ECFC361F32C63940', '426 Euclid Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.2, NULL, 3, 'grid_region', '2026-01-14 00:02:10.272279', '2026-01-14 23:43:35.017692');
INSERT INTO sadie_gtm.hotels VALUES (374, 'The Setai, Miami Beach', 'https://www.thesetaihotel.com/?utm_source=local&utm_campaign=GMB&utm_medium=organic', '(305) 720-2125', '+18446628387', 'info@thesetaihotel.com', '0101000020E610000015C440D73E0854C0BCEE0802BFCB3940', '2001 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.6, NULL, 3, 'grid_region', '2026-01-14 00:03:24.118837', '2026-01-14 23:44:38.363966');
INSERT INTO sadie_gtm.hotels VALUES (257, 'Ocean Drive Beachfront by Deco 305-w/2 Queen Beds', 'https://all.deco305.com/listings/233191?googleVR=1&utm_source=google&utm_medium=vacation_rentals', NULL, '+17863092173', 'louiezrentals@gmail.com', '0101000020E6100000CBC3F81F4F0854C0BF6CF1DF72C93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 3, 'grid_region', '2026-01-14 00:02:46.901854', '2026-01-14 23:45:22.952401');
INSERT INTO sadie_gtm.hotels VALUES (206, 'The West Gem', 'https://www.thewestgem.com/', '(305) 747-6816', '+13057476816', '1327westave@gmail.com', '0101000020E6100000A8B8BB18140954C025016A6AD9C83940', '1327 West Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 3, 'grid_region', '2026-01-14 00:02:30.465351', '2026-01-14 23:45:31.70197');
INSERT INTO sadie_gtm.hotels VALUES (279, 'Kimpton Surfcomber Hotel', 'https://www.surfcomber.com/?&cm_mmc=WEB-_-KI-_-AMER-_-EN-_-EV-_-Google%20Business%20Profile-_-DD-_-surfcomber', '(305) 532-7715', '8009946103', NULL, '0101000020E610000076960FF7470854C087A00F3BF8CA3940', '1717 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4, NULL, 3, 'grid_region', '2026-01-14 00:02:50.322206', '2026-01-14 23:46:36.239669');
INSERT INTO sadie_gtm.hotels VALUES (230, 'Essex House by Clevelander', 'https://www.essexhotel.com/', '(305) 532-4006', '8775324006', NULL, '0101000020E6100000C94D79196A0854C0AB56CB42E0C73940', '1001 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.8, NULL, 3, 'grid_region', '2026-01-14 00:02:37.692644', '2026-01-14 23:51:17.947919');
INSERT INTO sadie_gtm.hotels VALUES (202, 'Hotel Chelsea', 'https://thehotelchelsea.com/', '(305) 534-4069', '3057034641', 'bookings@southbeachgroup.com', '0101000020E6100000DFE819B1850854C085FDE8E5C1C73940', '944 Washington Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 3, 'grid_region', '2026-01-14 00:02:30.451081', '2026-01-14 23:51:25.289622');
INSERT INTO sadie_gtm.hotels VALUES (419, 'Le Particulier Miami', 'https://www.leparticuliermiami.com/', '(386) 296-0036', NULL, NULL, '0101000020E610000004E44BA8E00754C061A3ACDF4CD03940', '4130 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.7, NULL, 3, 'grid_region', '2026-01-14 00:03:47.644426', '2026-01-14 23:51:52.552029');
INSERT INTO sadie_gtm.hotels VALUES (93, 'Bayfront High-Rise Luxury City View Downtown Miami', 'https://br.bluepillow.com/search/67a516ee064d51dcdc971757?dest=bpex&cat=Apartment&lat=25.77309&lng=-80.19013&language=pt', NULL, NULL, NULL, '0101000020E6100000A83A3F202B0C54C0D65AF33EE9C53940', 'Miami, FL 33131', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:07.161678', '2026-01-14 21:50:25.187084');
INSERT INTO sadie_gtm.hotels VALUES (100, 'Clinton Hotel South Beach', 'http://www.clintonsouthbeach.com/?utm_source=local-directories&utm_medium=organic&utm_campaign=travelclick-localconnect', '(305) 938-4040', NULL, NULL, '0101000020E610000099A14CFE820854C0358B61985DC73940', '825 Washington Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.8, NULL, 99, 'grid_region', '2026-01-14 00:02:10.228981', '2026-01-14 21:50:25.255007');
INSERT INTO sadie_gtm.hotels VALUES (124, 'Chesterfield Hotel & Suites', 'https://thechesterfieldhotel.com/', '(305) 531-5831', NULL, NULL, '0101000020E61000000FC358F06C0854C0572A03626DC73940', '855 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:02:10.290085', '2026-01-14 21:50:41.535936');
INSERT INTO sadie_gtm.hotels VALUES (119, 'Waldorf Towers South Beach', 'https://www.waldorftowersmiami.com/?utm_medium=organic&utm_source=google&utm_campaign=business-listing', '(786) 446-8100', '7864468100', 'info@waldorftowersmiami.com', '0101000020E6100000C629841F660854C0D11F9A7972C73940', '860 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 3, 'grid_region', '2026-01-14 00:02:10.277849', '2026-01-14 23:45:36.277675');
INSERT INTO sadie_gtm.hotels VALUES (203, 'Barcelona Studios', NULL, '(305) 674-7368', NULL, NULL, '0101000020E6100000C744EFF9860854C05CF635DC91C93940', '500 15th St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.4, NULL, 0, 'grid_region', '2026-01-14 00:02:30.455023', '2026-01-14 00:02:30.455023');
INSERT INTO sadie_gtm.hotels VALUES (209, 'Mare Suites South Beach by Red Group Rentals', NULL, NULL, NULL, NULL, '0101000020E6100000B93FCD7FFE0854C0F782609F4AC73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:30.474414', '2026-01-14 00:02:30.474414');
INSERT INTO sadie_gtm.hotels VALUES (212, 'South Beach Suites in Ocean Drive', NULL, NULL, NULL, NULL, '0101000020E6100000C5991540670854C095C7E41E5CC73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:30.487047', '2026-01-14 00:02:30.487047');
INSERT INTO sadie_gtm.hotels VALUES (220, 'Beach rentals', NULL, '(305) 528-8000', NULL, NULL, '0101000020E61000009632BACD650854C0CFD6C1C1DEC83940', '1330 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 2.9, NULL, 0, 'grid_region', '2026-01-14 00:02:30.504428', '2026-01-14 00:02:30.504428');
INSERT INTO sadie_gtm.hotels VALUES (222, 'Nine20 Collins Apartments By Lowkl', 'https://lowkl.com/property/nine20-apartments-by-lowkl/', '(786) 345-7068', '+17863457068', 'reservations@lowkl.com', '0101000020E6100000908C30A0720854C078D89F1FA1C73940', '920 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 3, 'grid_region', '2026-01-14 00:02:30.508823', '2026-01-14 23:51:59.2217');
INSERT INTO sadie_gtm.hotels VALUES (308, 'Aqua Hotel', 'http://www.aquamiami.com/?utm_source=gmb&utm_medium=organic', '(305) 538-4361', '3055384361', NULL, '0101000020E6100000F3ACA4155F0854C097CD774BCDC93940', '1530 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.7, NULL, 3, 'grid_region', '2026-01-14 00:03:02.350159', '2026-01-14 23:52:06.324261');
INSERT INTO sadie_gtm.hotels VALUES (227, 'Miami Party Hostel', NULL, '(305) 397-8423', NULL, NULL, '0101000020E6100000BB6D9516640854C00799BF9D9FC73940', '928 Ocean Dr floor 2, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.2, NULL, 0, 'grid_region', '2026-01-14 00:02:37.683387', '2026-01-14 00:02:37.683387');
INSERT INTO sadie_gtm.hotels VALUES (381, 'Hotel Croydon Miami Beach', 'https://hotelcroydonmiamibeach.com/', '(305) 938-1145', '+13057034641', NULL, '0101000020E6100000366964A1E70754C05F2BFC7497CF3940', '3720 Collins Ave Lobby, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.5, NULL, 3, 'grid_region', '2026-01-14 00:03:28.95348', '2026-01-14 23:52:14.511044');
INSERT INTO sadie_gtm.hotels VALUES (593, 'Cozy Beachfront Condo w Beach Service / 1410', 'https://alexanderhotel.holidayfuture.com/listings/377669?googleVR=1&utm_source=google&utm_medium=vacation_rentals', NULL, NULL, 'reservations@alexanderhotel.com', '0101000020E6100000F5503640C40754C08B6E18607AD43940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 3, 'grid_region', '2026-01-14 00:04:51.089078', '2026-01-14 23:52:44.38067');
INSERT INTO sadie_gtm.hotels VALUES (532, 'Mdq Watersports and Jet Ski Rental', 'https://mdqwatersports.com/', '(305) 301-8607', '(305)20301-8607', 'info@mdqwatersports.com', '0101000020E6100000E4130DADA90754C0D03648D27FD43940', '5225 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.9, NULL, 3, 'grid_region', '2026-01-14 00:04:28.690749', '2026-01-14 23:53:15.721733');
INSERT INTO sadie_gtm.hotels VALUES (564, 'Oceanside Hotel + Suites', 'https://oceansidehotelmiamibeach.com/', '(305) 763-8125', '3057034541', 'sales@oceansidehotelmiamibeach.com', '0101000020E610000085E6DFD3C10754C03BC8467B17D83940', '6084 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.6, NULL, 3, 'grid_region', '2026-01-14 00:04:43.09784', '2026-01-14 23:53:25.607773');
INSERT INTO sadie_gtm.hotels VALUES (377, 'Circa 39 Miami Beach', 'https://www.circa39.com/?utm_medium=organic&utm_source=google&utm_campaign=business-listing', '(305) 538-4900', '8778247223', 'frontdesk@circa39.com', '0101000020E6100000D0FC7B3AE80754C01BAA189DE2CF3940', '3900 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 3, 'grid_region', '2026-01-14 00:03:28.942848', '2026-01-14 23:53:29.065316');
INSERT INTO sadie_gtm.hotels VALUES (248, 'Hotel Greystone', 'https://www.greystonehotel.com/?utm_source=google&utm_medium=organic&utm_campaign=business_listing', '(305) 847-4000', '3058474000', NULL, '0101000020E6100000A67C08AA460854C057EFCBF4A6CB3940', '1920 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.5, NULL, 3, 'grid_region', '2026-01-14 00:02:46.885792', '2026-01-14 23:53:39.104532');
INSERT INTO sadie_gtm.hotels VALUES (19, 'Hotel AKA Brickell', 'https://www.stayaka.com/hotel-aka-brickell', '(305) 503-6500', '3055036500', NULL, '0101000020E6100000B907D792440C54C02BBA9AE1ABC23940', '1395 Brickell Ave, Miami, FL 33131', 'Miami', 'FL', 'USA', 4.3, NULL, 3, 'grid_region', '2026-01-14 00:01:41.478741', '2026-01-14 23:54:08.649754');
INSERT INTO sadie_gtm.hotels VALUES (429, 'Hotel Belleza', 'https://www.bellezahotel.com/', '(305) 740-1430', '+13057401430', 'reservations@bellezahotel.com', '0101000020E61000002D639EF06D0854C02DB87AA933CC3940', '2115 Washington Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.5, NULL, 3, 'grid_region', '2026-01-14 00:03:49.847859', '2026-01-14 23:54:28.758572');
INSERT INTO sadie_gtm.hotels VALUES (217, 'Luxuri', 'https://luxuri.com/?utm_campaign=gmb', '(786) 981-0924', '+17869810924', 'booking@luxuri.com', '0101000020E61000006A42A4F06A0854C04F16084CF1C63940', '720 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.9, NULL, 3, 'grid_region', '2026-01-14 00:02:30.497755', '2026-01-14 23:54:44.229505');
INSERT INTO sadie_gtm.hotels VALUES (122, 'Starlite Hotel', 'http://www.starlitehotel.com/', '(888) 539-4065', '3055342161', 'reservations@starlitehotel.com', '0101000020E6100000D0419770680854C04890A56A16C73940', '750 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.7, NULL, 3, 'grid_region', '2026-01-14 00:02:10.28601', '2026-01-14 23:54:59.218884');
INSERT INTO sadie_gtm.hotels VALUES (250, 'Sagamore Hotel South Beach - An All Suite Hotel', 'https://www.sagamoresouthbeach.com/', '(305) 535-8088', '3055358088', 'reservations@sagamorehotel.com', '0101000020E6100000BE1AFBED460854C0CEF11B70A7CA3940', 'The Sagamore, 1671 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.2, NULL, 3, 'grid_region', '2026-01-14 00:02:46.889072', '2026-01-14 23:55:02.827775');
INSERT INTO sadie_gtm.hotels VALUES (218, 'Louiez Rentals', 'https://www.deco305.com/', '(786) 309-2173', '7863092173', 'louiezrentals@gmail.com', '0101000020E6100000211510A49C0854C0C53E5CCD95C63940', '634 6th St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3, NULL, 3, 'grid_region', '2026-01-14 00:02:30.500263', '2026-01-14 23:55:18.557492');
INSERT INTO sadie_gtm.hotels VALUES (234, 'President Hotel Villa Miami Beach', 'https://www.presidentvillamiami.com/', '(305) 534-9334', '8447689738', 'Reservations@presidenthotelmiami.com', '0101000020E61000009C5FDE2D5A0854C0C4398F2F46C93940', '1425 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.4, NULL, 3, 'grid_region', '2026-01-14 00:02:41.827782', '2026-01-14 23:55:29.659033');
INSERT INTO sadie_gtm.hotels VALUES (316, 'OQP Vacations Miami', 'https://www.oqpvacations.com/', '(305) 218-9049', '13052189049', NULL, '0101000020E6100000D46AFE4E490C54C00688DDD2C5CB3940', '144 NE 20th Terrace, Miami, FL 33137', 'Miami', 'FL', 'USA', 4.5, NULL, 3, 'grid_region', '2026-01-14 00:03:10.639647', '2026-01-14 23:55:43.503529');
INSERT INTO sadie_gtm.hotels VALUES (211, 'Kasa El Paseo Miami Beach', 'https://kasa.com/properties/kasa-el-paseo-miami-beach?utm_source=Google&utm_medium=nonpaid&utm_campaign=GMB&utm_term=VisitHotelWebsiteButton&utm_content=PAS', '(786) 755-5032', NULL, NULL, '0101000020E6100000787874C8720854C0532F09617FC93940', '405 Española Wy, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.5, NULL, 3, 'grid_region', '2026-01-14 00:02:30.484456', '2026-01-14 23:55:53.524835');
INSERT INTO sadie_gtm.hotels VALUES (198, 'Nassau Suite South Beach, an All Suite Hotel', 'https://nassausuite.com/', '(786) 646-2475', '+17866462475', NULL, '0101000020E6100000A933524A630854C0ADD799E72DC93940', '1414 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.7, NULL, 3, 'grid_region', '2026-01-14 00:02:27.014274', '2026-01-14 23:56:38.710186');
INSERT INTO sadie_gtm.hotels VALUES (228, 'Deco Walk', NULL, '(305) 397-8423', NULL, NULL, '0101000020E610000093CC45D7600854C0A9B0636D9DC73940', '928 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.2, NULL, 0, 'grid_region', '2026-01-14 00:02:37.686521', '2026-01-14 00:02:37.686521');
INSERT INTO sadie_gtm.hotels VALUES (229, 'South Beach Beds', NULL, '(786) 659-2814', NULL, NULL, '0101000020E6100000B030E9946C0854C053D048DFFFC63940', '728 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:37.689668', '2026-01-14 00:02:37.689668');
INSERT INTO sadie_gtm.hotels VALUES (232, 'Ocean Hotel and Hostel', NULL, '(305) 763-8764', NULL, NULL, '0101000020E6100000147AFD497C0854C07491E79F85C73940', '236 9th St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.8, NULL, 0, 'grid_region', '2026-01-14 00:02:37.698668', '2026-01-14 00:02:37.698668');
INSERT INTO sadie_gtm.hotels VALUES (233, 'SOBE STUDIO-FULL KITCHEN-OCEAN DRIVE', NULL, NULL, NULL, NULL, '0101000020E610000002791B40640854C0F524558094C73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:41.821539', '2026-01-14 00:02:41.821539');
INSERT INTO sadie_gtm.hotels VALUES (237, 'Stardust South Beach Hotel', NULL, '(786) 899-3669', NULL, NULL, '0101000020E6100000769DB23F750854C0FFA6C17E99C73940', '910 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.9, NULL, 0, 'grid_region', '2026-01-14 00:02:41.832255', '2026-01-14 00:02:41.832255');
INSERT INTO sadie_gtm.hotels VALUES (17, 'Extended Stay America Premier Suites- Miami - Downtown Brickell - Cruise Port', 'https://www.extendedstayamerica.com/hotels/fl/miami/downtown-brickell-cruise-port?channel=gmb-listing&utm_source=google&utm_medium=organic&utm_campaign=gmb_listing', '(305) 856-3700', '8008043724', NULL, '0101000020E610000088BC40A4BA0C54C0BC9E9E2DD6C23940', '298 SW 15th Rd, Miami, FL 33129', 'Miami', 'FL', 'USA', 3.9, NULL, 3, 'grid_region', '2026-01-14 00:01:41.330307', '2026-01-14 23:56:43.128805');
INSERT INTO sadie_gtm.hotels VALUES (310, 'The Plymouth South Beach', 'http://www.theplymouth.com/', '(305) 602-5000', '3056025000', NULL, '0101000020E61000009BE040ED5C0854C09D7A4908FBCB3940', '336 21st St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.2, NULL, 3, 'grid_region', '2026-01-14 00:03:05.648617', '2026-01-14 23:56:55.39843');
INSERT INTO sadie_gtm.hotels VALUES (256, 'National Hotel', 'https://nationalhotel.com/', '(305) 532-2311', '1811789996', NULL, '0101000020E610000057A2A2A04A0854C01EADC502BACA3940', '1677 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 3, 'grid_region', '2026-01-14 00:02:46.900054', '2026-01-14 23:57:00.607935');
INSERT INTO sadie_gtm.hotels VALUES (20, 'Provident Luxury Suites Fisher Island', 'https://www.providentresorts.com/fisher-island-miami', '(888) 222-2206', '7277264770', NULL, '0101000020E6100000A11CBBFA670954C0A3906456EFC23940', '13 Fisher Island Dr, Miami Beach, FL 33109', 'Miami Beach', 'FL', 'USA', 4.7, NULL, 3, 'grid_region', '2026-01-14 00:01:41.480827', '2026-01-14 23:57:17.574959');
INSERT INTO sadie_gtm.hotels VALUES (545, 'Nobu Miami', 'https://www.noburestaurants.com/miami/home/?utm_source=google&utm_medium=Yext', '(305) 695-3232', NULL, NULL, '0101000020E61000001ADD41ECCC0754C0CF9F36AAD3D13940', '4525 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4, NULL, 3, 'grid_region', '2026-01-14 00:04:34.689242', '2026-01-14 23:57:36.829542');
INSERT INTO sadie_gtm.hotels VALUES (249, 'Ocean Beach Suites', NULL, NULL, NULL, NULL, '0101000020E6100000281C8BB75F0854C00983D7D3B3C93940', '1510 Collins Ave CU-1, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 2.2, NULL, 0, 'grid_region', '2026-01-14 00:02:46.887344', '2026-01-14 00:02:46.887344');
INSERT INTO sadie_gtm.hotels VALUES (204, 'Viajero Hostels Miami', 'https://www.viajerohostels.com/en/destinations-eeuu/miami-south-beach/', '(305) 674-7800', '+17866534440', 'miami@viajerohostels.com', '0101000020E6100000C9192F826B0854C0B6A4FED53EC83940', '1120 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.7, NULL, 3, 'grid_region', '2026-01-14 00:02:30.458567', '2026-01-14 23:58:29.917968');
INSERT INTO sadie_gtm.hotels VALUES (599, 'Ocean View |Balcony-Beachfront Resort', 'https://whimstay.com/detail/Ocean-View-and-Direct-Beach-Access-Stunning-Coastal-Oasis/508250?isgoogle=true', NULL, NULL, NULL, '0101000020E61000003AFF1B20BD0754C0FC0A88FF2AD43940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 3, 'grid_region', '2026-01-14 00:04:51.109149', '2026-01-14 23:58:44.972178');
INSERT INTO sadie_gtm.hotels VALUES (422, 'Luxury Rentals Miami Beach', 'https://www.luxuryrentalsmiamibeach.com/?utm_source=google&utm_medium=organic&utm_campaign=gbp', '(305) 902-6190', '3053912222', 'bookings@lrmb.com', '0101000020E6100000C11DA8531E0854C02713B70A62D03940', '301 W 41st St #502, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.8, NULL, 3, 'grid_region', '2026-01-14 00:03:47.655686', '2026-01-14 23:59:24.990685');
INSERT INTO sadie_gtm.hotels VALUES (528, 'Miami Beach Vacation Rentals by Vacasa', 'https://www.vacasa.com/usa/Florida/Miami-Beach/?utm_source=gmb&utm_medium=organic&utm_campaign=GMB-Miami-Vacation-Rentals', '(855) 861-5757', '+18005440300', NULL, '0101000020E610000076FD82DDB00754C0C76471FF91D53940', '5445 Collins Ave, Suite CU20, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.7, NULL, 3, 'grid_region', '2026-01-14 00:04:28.685883', '2026-01-14 23:59:45.339609');
INSERT INTO sadie_gtm.hotels VALUES (388, 'Global Luxury Suites at The Apex Miami', 'https://www.globalluxurysuites.com/property/78111/fl/miami-beach/global-luxury-suites-at-the-apex-miami', '(844) 372-7411', '8443727411', NULL, '0101000020E6100000458F29690F0954C0E5284014CCCA3940', '1201 17th St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4, NULL, 3, 'grid_region', '2026-01-14 00:03:31.863473', '2026-01-14 23:59:49.287295');
INSERT INTO sadie_gtm.hotels VALUES (270, 'Ocean Drive Beachfront by Deco 305-Comfy Apt Deal', 'https://all.deco305.com/listings/233209?googleVR=1&utm_source=google&utm_medium=vacation_rentals', NULL, '+17863092173', 'louiezrentals@gmail.com', '0101000020E6100000CBC3F81F4F0854C0BF6CF1DF72C93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 3, 'grid_region', '2026-01-14 00:02:46.919916', '2026-01-15 00:01:38.347104');
INSERT INTO sadie_gtm.hotels VALUES (259, 'BeachFront On The Sand #227 South of 5th, 335 Ocean Dr, Miami Beach', NULL, NULL, NULL, NULL, '0101000020E61000004BDB09406D0854C08712D2BFC9C53940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:46.905303', '2026-01-14 00:02:46.905303');
INSERT INTO sadie_gtm.hotels VALUES (260, 'BeachFront On The Sand #229, South of 5t, 335 Ocean Dr, Miami Beach', NULL, NULL, NULL, NULL, '0101000020E61000004BDB09406D0854C08712D2BFC9C53940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:46.906515', '2026-01-14 00:02:46.906515');
INSERT INTO sadie_gtm.hotels VALUES (262, 'BeachFront On The Sand #117 South of 5th, 335 Ocean Dr, Miami Beach', NULL, NULL, NULL, NULL, '0101000020E61000004BDB09406D0854C08712D2BFC9C53940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:46.909075', '2026-01-14 00:02:46.909075');
INSERT INTO sadie_gtm.hotels VALUES (264, 'BEACHFRONT STUDIO ON OCEAN DRIVE-slps up to 4', NULL, NULL, NULL, NULL, '0101000020E61000005C8B16A06D0854C0CE62731FCAC53940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:46.911853', '2026-01-14 00:02:46.911853');
INSERT INTO sadie_gtm.hotels VALUES (267, 'Beachfront studio with living balcony in the heart of Miami Beach', NULL, NULL, NULL, NULL, '0101000020E610000096B613805A0854C038C76FC09DCA3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:46.916376', '2026-01-14 00:02:46.916376');
INSERT INTO sadie_gtm.hotels VALUES (271, 'Beachfront Oasis Ocean Drive JACUZZI ; Recently Renovated!', NULL, NULL, NULL, NULL, '0101000020E6100000F3154960980854C04F667220DAC53940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:46.922298', '2026-01-14 00:02:46.922298');
INSERT INTO sadie_gtm.hotels VALUES (282, 'Azure Luxury Suites', NULL, '(786) 571-7273', NULL, NULL, '0101000020E61000003A4BDA9E6A0854C02028B7ED7BC83940', '1208 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.5, NULL, 0, 'grid_region', '2026-01-14 00:02:50.335489', '2026-01-14 00:02:50.335489');
INSERT INTO sadie_gtm.hotels VALUES (286, 'Luxury Vacation Rentals at The Setai by LRMB', NULL, NULL, NULL, NULL, '0101000020E6100000D50E35C03B0854C09E5C5320B3CB3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:54.595012', '2026-01-14 00:02:54.595012');
INSERT INTO sadie_gtm.hotels VALUES (289, 'COLORS THE BEST VACATION RENTAL ON THE BEACH!', NULL, NULL, NULL, NULL, '0101000020E61000006C58F89F210954C0CF9211610DC93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:54.608299', '2026-01-14 00:02:54.608299');
INSERT INTO sadie_gtm.hotels VALUES (290, 'Elegant Ocean Front Studio For Rent - The Decoplage Building (South Beach)', NULL, NULL, NULL, NULL, '0101000020E610000049A01C60410854C0C364AA6054CA3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:02:54.611468', '2026-01-14 00:02:54.611468');
INSERT INTO sadie_gtm.hotels VALUES (304, 'South Beach Apartment Rentals', NULL, '(305) 535-9049', NULL, NULL, '0101000020E61000002EDDC94C8E0854C01FD5B0DF13C73940', '710 Washington Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 1, NULL, 0, 'grid_region', '2026-01-14 00:02:58.606549', '2026-01-14 00:02:58.606549');
INSERT INTO sadie_gtm.hotels VALUES (306, 'South Beach Vacation Rentals', NULL, '(305) 538-5595', NULL, NULL, '0101000020E61000003BFE0B04010954C0C8409E5DBEC93940', '1521 Alton Rd #412, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.7, NULL, 0, 'grid_region', '2026-01-14 00:02:58.613479', '2026-01-14 00:02:58.613479');
INSERT INTO sadie_gtm.hotels VALUES (317, 'SoBe Ocean Drive Suites', NULL, '(714) 717-0053', NULL, NULL, '0101000020E6100000904F23884E0854C0E744CC3681C93940', '1458 Ocean Dr Z, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 2.3, NULL, 0, 'grid_region', '2026-01-14 00:03:10.648275', '2026-01-14 00:03:10.648275');
INSERT INTO sadie_gtm.hotels VALUES (322, 'Parisian Hotel', NULL, '(305) 538-7464', NULL, NULL, '0101000020E6100000FE3A81FA600854C01A72C7F6B5C93940', '1510 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 2.6, NULL, 0, 'grid_region', '2026-01-14 00:03:10.663033', '2026-01-14 00:03:10.663033');
INSERT INTO sadie_gtm.hotels VALUES (346, 'Water Front Guest House', NULL, '+27 82 499 4103', NULL, NULL, '0101000020E6100000C7A4750AA8FE3B4041AE79FAAD1C3AC0', '32 Tuin Ave, Robindale, Johannesburg, 2194, South Africa', '2194', NULL, 'USA', 4.7, NULL, 69, 'grid_region', '2026-01-14 00:03:16.657409', '2026-01-14 23:47:41.810514');
INSERT INTO sadie_gtm.hotels VALUES (325, 'Cozy condo with amazing view !', NULL, NULL, NULL, NULL, '0101000020E6100000E7BE41203C0C54C06437D8405FC73940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:03:10.674478', '2026-01-14 00:03:10.674478');
INSERT INTO sadie_gtm.hotels VALUES (328, 'Cozy Studio. Walk to the Beach and Restaurants', NULL, NULL, NULL, NULL, '0101000020E6100000392E3E60790854C05EEFA3BF3CC73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:03:10.683963', '2026-01-14 00:03:10.683963');
INSERT INTO sadie_gtm.hotels VALUES (329, 'Pet Friendly Cozy Condo in the Heart of South Beach', NULL, NULL, NULL, NULL, '0101000020E6100000FD1F1620C00854C0C29E1B3FF9CA3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:03:10.686193', '2026-01-14 00:03:10.686193');
INSERT INTO sadie_gtm.hotels VALUES (332, 'Beachside Bliss: Cozy 2BR Condo in Heart of South Beach!', NULL, NULL, NULL, NULL, '0101000020E61000002D3E05C0780854C03595456117C73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:03:10.693223', '2026-01-14 00:03:10.693223');
INSERT INTO sadie_gtm.hotels VALUES (333, 'Cozy studio in Edgewater/Downtown Miami', NULL, NULL, NULL, NULL, '0101000020E6100000769DB23FF50B54C06AF46A80D2CA3940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:03:10.695736', '2026-01-14 00:03:10.695736');
INSERT INTO sadie_gtm.hotels VALUES (335, 'Cozy 1-bedroom condo in charming Wynwood and 10 mins to south beach.', NULL, NULL, NULL, NULL, '0101000020E61000006EA53220560C54C08B04094092CA3940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:03:10.703236', '2026-01-14 00:03:10.703236');
INSERT INTO sadie_gtm.hotels VALUES (338, 'COZY & CHIC Suite 1 BDR/1BTH', NULL, NULL, NULL, NULL, '0101000020E6100000197FEC3F7C0854C08D39741F25C73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:03:10.710664', '2026-01-14 00:03:10.710664');
INSERT INTO sadie_gtm.hotels VALUES (340, 'Cozy Ocean Drive Studio - Roof top Pool and Bar', NULL, NULL, NULL, NULL, '0101000020E6100000AC17E87F5E0854C01BFB4800EDC73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:03:10.71516', '2026-01-14 00:03:10.71516');
INSERT INTO sadie_gtm.hotels VALUES (344, 'Il Villaggio Condominium', NULL, '(305) 673-9371', NULL, NULL, '0101000020E610000064A1E760470854C08E16B1998DC93940', '1455 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.2, NULL, 0, 'grid_region', '2026-01-14 00:03:10.724024', '2026-01-14 00:03:10.724024');
INSERT INTO sadie_gtm.hotels VALUES (349, 'The Vintro Hotel', NULL, '(888) 542-5565', NULL, NULL, '0101000020E6100000261B0FB6580854C03C74305173CC3940', '2216 Park Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.1, NULL, 0, 'grid_region', '2026-01-14 00:03:16.669521', '2026-01-14 00:03:16.669521');
INSERT INTO sadie_gtm.hotels VALUES (353, 'The Abbey Hotel Miami Beach Sonder', NULL, '(617) 300-0956', NULL, NULL, '0101000020E61000009FED878E530854C08875F409EACB3940', '300 21st St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4, NULL, 0, 'grid_region', '2026-01-14 00:03:16.681748', '2026-01-14 00:03:16.681748');
INSERT INTO sadie_gtm.hotels VALUES (357, 'Fraternal Order of Police', NULL, '(305) 534-2775', NULL, NULL, '0101000020E6100000491C68F4D90854C07ABA5FAA3EC83940', '999 11th St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:03:20.646623', '2026-01-14 00:03:20.646623');
INSERT INTO sadie_gtm.hotels VALUES (361, 'Delfino Suites South Beach', NULL, '(786) 363-4339', NULL, NULL, '0101000020E61000006A7A9ADD240954C00D6A64FCA0C93940', '1321 15th St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.3, NULL, 0, 'grid_region', '2026-01-14 00:03:20.661358', '2026-01-14 00:03:20.661358');
INSERT INTO sadie_gtm.hotels VALUES (362, 'The Hall South Beach', NULL, '(305) 531-1251', NULL, NULL, '0101000020E6100000B09A9DFB610854C05F2BFC7497C93940', '1500 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.9, NULL, 0, 'grid_region', '2026-01-14 00:03:20.6652', '2026-01-14 00:03:20.6652');
INSERT INTO sadie_gtm.hotels VALUES (373, 'Dreamers Resorts, LLP', NULL, '(786) 507-8500', NULL, NULL, '0101000020E61000009376FE486C0854C04543C6A354CA3940', 'Lincoln Building, 350 Lincoln Rd #2nd, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:03:24.115674', '2026-01-14 00:03:24.115674');
INSERT INTO sadie_gtm.hotels VALUES (385, 'West Deco Boutique Apartments', NULL, NULL, NULL, NULL, '0101000020E61000006BC54840160954C0E2395B4068C93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:03:28.966278', '2026-01-14 00:03:28.966278');
INSERT INTO sadie_gtm.hotels VALUES (386, 'Boutique Apartments Convention Center', NULL, NULL, NULL, NULL, '0101000020E6100000020CCB9F6F0854C059411DA045CC3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:03:28.97009', '2026-01-14 00:03:28.97009');
INSERT INTO sadie_gtm.hotels VALUES (393, 'Royal Palm South Beach Miami - Umbrella and beach bed renting', NULL, NULL, NULL, NULL, '0101000020E6100000F502FDCF2B0854C0AF46D15ED8C93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.4, NULL, 0, 'grid_region', '2026-01-14 00:03:31.88327', '2026-01-14 00:03:31.88327');
INSERT INTO sadie_gtm.hotels VALUES (395, 'Miami Waterfront Homes', NULL, '(305) 726-4312', NULL, NULL, '0101000020E610000068739CDB040954C03D63BA6B64CA3940', '1111 Lincoln Rd #805, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 5, NULL, 0, 'grid_region', '2026-01-14 00:03:35.035533', '2026-01-14 00:03:35.035533');
INSERT INTO sadie_gtm.hotels VALUES (396, 'Miami Beach Rentals', NULL, '(954) 361-0803', NULL, NULL, '0101000020E6100000CBEB2D8AC30854C05104824AA6CA3940', '1674 Meridian Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4, NULL, 0, 'grid_region', '2026-01-14 00:03:35.040516', '2026-01-14 00:03:35.040516');
INSERT INTO sadie_gtm.hotels VALUES (535, 'Tiki Bar at Seacoast 5151', NULL, '(305) 861-3655', NULL, NULL, '0101000020E6100000F430B43AB90754C0872359D130D43940', '5151 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 0, 'grid_region', '2026-01-14 00:04:28.700142', '2026-01-14 00:04:28.700142');
INSERT INTO sadie_gtm.hotels VALUES (415, 'The Hudson South Beach', NULL, NULL, NULL, NULL, '0101000020E6100000BD715298770854C014A6947C91C93940', '420 15th St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4, NULL, 0, 'grid_region', '2026-01-14 00:03:39.458603', '2026-01-14 00:03:39.458603');
INSERT INTO sadie_gtm.hotels VALUES (430, 'The Getty Suites', NULL, '(786) 838-3047', NULL, NULL, '0101000020E6100000CEDF8442040854C0162D40DB6ACE3940', '235 30th St, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.5, NULL, 0, 'grid_region', '2026-01-14 00:03:53.461995', '2026-01-14 00:03:53.461995');
INSERT INTO sadie_gtm.hotels VALUES (568, 'Carl''s Motel El Padre', NULL, '(305) 754-2092', NULL, NULL, '0101000020E6100000CD5F7C2CD80B54C0E98BCE43B7D43940', '5950 Biscayne Blvd, Miami, FL 33137', 'Miami', 'FL', 'USA', 4.2, NULL, 0, 'grid_region', '2026-01-14 00:04:43.198417', '2026-01-14 00:04:43.198417');
INSERT INTO sadie_gtm.hotels VALUES (443, 'Beachfront Condo! Heated pools, board walk, and much more!', NULL, NULL, NULL, NULL, '0101000020E6100000C03DCF9F360854C0BF02E2BF8ACD3940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:03:53.502819', '2026-01-14 00:03:53.502819');
INSERT INTO sadie_gtm.hotels VALUES (449, 'Ocean View Private Residence - 906', NULL, '(786) 358-5580', NULL, NULL, '0101000020E6100000BACAC97A200854C09C3FB7E1C1CC3940', '102 24th St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 5, NULL, 0, 'grid_region', '2026-01-14 00:03:53.516451', '2026-01-14 00:03:53.516451');
INSERT INTO sadie_gtm.hotels VALUES (450, 'Caribbean South Beach', NULL, '(786) 275-6752', NULL, NULL, '0101000020E610000099339188DF0754C02B7D8DC987CF3940', '3737 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.6, NULL, 0, 'grid_region', '2026-01-14 00:03:53.518341', '2026-01-14 00:03:53.518341');
INSERT INTO sadie_gtm.hotels VALUES (451, 'A Block from the Beach- Miami Beach', NULL, '(305) 342-4987', NULL, NULL, '0101000020E610000011267B3A0D0854C0385849754BCE3940', '2925 Indian Creek Dr, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.5, NULL, 0, 'grid_region', '2026-01-14 00:03:53.520142', '2026-01-14 00:03:53.520142');
INSERT INTO sadie_gtm.hotels VALUES (453, 'Luxury Vacation Rentals in South Beach by LRMB', NULL, NULL, NULL, NULL, '0101000020E61000006A49EC7F250854C036DEC25F38CC3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:00.156119', '2026-01-14 00:04:00.156119');
INSERT INTO sadie_gtm.hotels VALUES (456, '1 Homes Vacation Rentals by LMC', NULL, NULL, NULL, NULL, '0101000020E6100000BAE70A001F0854C001A5FCFF93CC3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:00.183476', '2026-01-14 00:04:00.183476');
INSERT INTO sadie_gtm.hotels VALUES (461, 'BOULAN HOTEL MIAMI BEACH 1BR/1BA UNIT', NULL, NULL, NULL, NULL, '0101000020E61000008E5143C0460854C05287CBE0DECB3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:00.197998', '2026-01-14 00:04:00.197998');
INSERT INTO sadie_gtm.hotels VALUES (463, 'Sun-kissed South Beach Summer Rental', NULL, NULL, NULL, NULL, '0101000020E610000049360D40590854C0174A8160E9CB3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:00.202736', '2026-01-14 00:04:00.202736');
INSERT INTO sadie_gtm.hotels VALUES (467, 'Apart Hotel Miami', NULL, NULL, NULL, NULL, '0101000020E61000009E5A22BCE20754C01941199936D03940', '4100 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4, NULL, 0, 'grid_region', '2026-01-14 00:04:00.212036', '2026-01-14 00:04:00.212036');
INSERT INTO sadie_gtm.hotels VALUES (472, 'Luxury Oceanfront resort/condo/1 Hotel / Roney Palace', NULL, NULL, NULL, NULL, '0101000020E61000003185BD3F140854C01AE9FB5F64CC3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:00.225172', '2026-01-14 00:04:00.225172');
INSERT INTO sadie_gtm.hotels VALUES (474, 'Versailles Tower', NULL, NULL, NULL, NULL, '0101000020E610000021054F21D70754C0238F96B9AFD13940', 'Miami Beach Boardwalk, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.6, NULL, 0, 'grid_region', '2026-01-14 00:04:02.580475', '2026-01-14 00:04:02.580475');
INSERT INTO sadie_gtm.hotels VALUES (477, 'Paradise Cafe', NULL, '(305) 532-3311', NULL, NULL, '0101000020E61000001710B5C8D10754C041D653ABAFD03940', '4333 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.4, NULL, 0, 'grid_region', '2026-01-14 00:04:02.626663', '2026-01-14 00:04:02.626663');
INSERT INTO sadie_gtm.hotels VALUES (482, 'Bianco Hotel', NULL, '(786) 548-0803', NULL, NULL, '0101000020E61000003D38E9C7F00B54C088E1D9D42FD33940', '5255 Biscayne Blvd, Miami, FL 33137', 'Miami', 'FL', 'USA', 5, NULL, 0, 'grid_region', '2026-01-14 00:04:05.173987', '2026-01-14 00:04:05.173987');
INSERT INTO sadie_gtm.hotels VALUES (484, 'Atrium Design District', NULL, '(561) 302-1464', NULL, NULL, '0101000020E61000004A873DA3630C54C0B88FDC9A74D33940', '130 NE 55th St, Miami, FL 33137', 'Miami', 'FL', 'USA', 4.6, NULL, 0, 'grid_region', '2026-01-14 00:04:05.179433', '2026-01-14 00:04:05.179433');
INSERT INTO sadie_gtm.hotels VALUES (485, 'Real Living Hotel Residences', NULL, '(786) 459-4571', NULL, NULL, '0101000020E6100000B7BD9305820C54C0E9E0AAFC7CCD3940', '2700 N Miami Ave, Miami, FL 33127', 'Miami', 'FL', 'USA', 3.5, NULL, 0, 'grid_region', '2026-01-14 00:04:05.181708', '2026-01-14 00:04:05.181708');
INSERT INTO sadie_gtm.hotels VALUES (488, 'Miami Rental Hostel', NULL, NULL, NULL, NULL, '0101000020E6100000A0B250210D0D54C08964236B68D03940', '509 NW 41st St, Miami, FL 33127', 'Miami', 'FL', 'USA', 4.4, NULL, 0, 'grid_region', '2026-01-14 00:04:05.18953', '2026-01-14 00:04:05.18953');
INSERT INTO sadie_gtm.hotels VALUES (489, 'Eco-Shared Paradise', NULL, '(786) 282-7025', NULL, NULL, '0101000020E61000003BDEE4B7E80C54C0B72407EC6AD23940', '5029 NW 3rd Ave, Miami, FL 33127', 'Miami', 'FL', 'USA', 3.3, NULL, 0, 'grid_region', '2026-01-14 00:04:05.195206', '2026-01-14 00:04:05.195206');
INSERT INTO sadie_gtm.hotels VALUES (490, 'Eco hostel', NULL, NULL, NULL, NULL, '0101000020E61000001F01ED58B60C54C010429B77F7CF3940', '160 NW 39th St, Miami, FL 33127', 'Miami', 'FL', 'USA', 4, NULL, 0, 'grid_region', '2026-01-14 00:04:05.198613', '2026-01-14 00:04:05.198613');
INSERT INTO sadie_gtm.hotels VALUES (491, 'Nomada Destination Residences', NULL, '(786) 420-0621', NULL, NULL, '0101000020E61000005A3222AC210C54C0C33357BC47D03940', '3900 Biscayne Blvd, Miami, FL 33137', 'Miami', 'FL', 'USA', 4.4, NULL, 0, 'grid_region', '2026-01-14 00:04:05.202045', '2026-01-14 00:04:05.202045');
INSERT INTO sadie_gtm.hotels VALUES (493, 'Beaches Bar And Grill', NULL, '(305) 672-1910', NULL, NULL, '0101000020E61000000E637726D90754C03FA9F6E978D03940', '4299 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.4, NULL, 0, 'grid_region', '2026-01-14 00:04:13.288884', '2026-01-14 00:04:13.288884');
INSERT INTO sadie_gtm.hotels VALUES (502, 'COZY APARTMENT STEPS FROM THE BEACH', NULL, NULL, NULL, NULL, '0101000020E6100000875341A00E0854C062258BA0D6CD3940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:13.327075', '2026-01-14 00:04:13.327075');
INSERT INTO sadie_gtm.hotels VALUES (509, 'MODERN AND COZY apartment steps from the beach', NULL, NULL, NULL, NULL, '0101000020E6100000875341A00E0854C062258BA0D6CD3940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:13.348681', '2026-01-14 00:04:13.348681');
INSERT INTO sadie_gtm.hotels VALUES (510, 'Cozy 1-bedroom apartment in beautiful Miami Beach.', NULL, NULL, NULL, NULL, '0101000020E6100000DC9FE63FFF0754C01E9AC3FF67CE3940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:13.350996', '2026-01-14 00:04:13.350996');
INSERT INTO sadie_gtm.hotels VALUES (515, 'Chic Apartments at Miami Beach', NULL, '(917) 675-0259', NULL, NULL, '0101000020E61000002CFF6B8A110854C0CCBBA074D8CD3940', '225 27th St, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 0, 'grid_region', '2026-01-14 00:04:13.368608', '2026-01-14 00:04:13.368608');
INSERT INTO sadie_gtm.hotels VALUES (519, 'Touchdown Hostel', NULL, '(305) 922-5494', NULL, NULL, '0101000020E610000009850838840C54C084F23E8EE6D43940', '47 NE 60th Terrace, Miami, FL 33137', 'Miami', 'FL', 'USA', 4.9, NULL, 0, 'grid_region', '2026-01-14 00:04:25.143094', '2026-01-14 00:04:25.143094');
INSERT INTO sadie_gtm.hotels VALUES (521, 'Seven Seas Hotel | Miami Hotel', NULL, '(305) 757-1678', NULL, NULL, '0101000020E61000003710374CD90B54C0D1EC157195D43940', '5940 Biscayne Blvd, Miami, FL 33137', 'Miami', 'FL', 'USA', 3.3, NULL, 0, 'grid_region', '2026-01-14 00:04:25.155802', '2026-01-14 00:04:25.155802');
INSERT INTO sadie_gtm.hotels VALUES (526, 'Beautiful Studio in Heart of Miami', NULL, '(786) 307-5015', NULL, NULL, '0101000020E61000007D14BF73B90C54C0E36E10AD15D53940', '156 NW 62nd St Unit 3, Miami, FL 33150', 'Miami', 'FL', 'USA', 3, NULL, 0, 'grid_region', '2026-01-14 00:04:25.173235', '2026-01-14 00:04:25.173235');
INSERT INTO sadie_gtm.hotels VALUES (531, 'Miami Sightseeing Tours & Concierge Services', NULL, '(786) 250-2683', NULL, NULL, '0101000020E6100000EC134031B20754C03D61890794D53940', '5445 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.3, NULL, 0, 'grid_region', '2026-01-14 00:04:28.689767', '2026-01-14 00:04:28.689767');
INSERT INTO sadie_gtm.hotels VALUES (569, 'Saturn Motel', NULL, '(305) 757-8891', NULL, NULL, '0101000020E610000023E3079DC60B54C06228CC20E3D63940', '6995 Biscayne Blvd, Miami, FL 33138', 'Miami', 'FL', 'USA', 3.5, NULL, 0, 'grid_region', '2026-01-14 00:04:43.200041', '2026-01-14 00:04:43.200041');
INSERT INTO sadie_gtm.hotels VALUES (538, 'Four Freedoms House', NULL, '(305) 673-8425', NULL, NULL, '0101000020E610000054B3BDCCE60754C0178E31C1BACF3940', '3800 Collins Ave, Miami, FL 33140', 'Miami', 'FL', 'USA', 3.8, NULL, 0, 'grid_region', '2026-01-14 00:04:31.163971', '2026-01-14 00:04:31.163971');
INSERT INTO sadie_gtm.hotels VALUES (541, '\"Miami Beach Getaway: Oceanfront Luxury Resort\"', NULL, NULL, NULL, NULL, '0101000020E61000003EB0E3BFC00754C0DB3E9AA03CD43940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:31.176217', '2026-01-14 00:04:31.176217');
INSERT INTO sadie_gtm.hotels VALUES (542, 'Girasole Apartments', NULL, '(786) 961-1466', NULL, NULL, '0101000020E61000005E06088BAF0754C02FA75F7D97D53940', '5445 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 2.9, NULL, 0, 'grid_region', '2026-01-14 00:04:31.179202', '2026-01-14 00:04:31.179202');
INSERT INTO sadie_gtm.hotels VALUES (544, 'SUITE MIAMI BEACH', NULL, '(786) 878-1153', NULL, NULL, '0101000020E6100000AB9D17DDB00754C092C7783991D53940', '5445 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:31.185904', '2026-01-14 00:04:31.185904');
INSERT INTO sadie_gtm.hotels VALUES (549, 'Beachfront Condos', NULL, '(786) 271-4965', NULL, NULL, '0101000020E61000006E4BE482B30754C0212C746F8FD53940', '5445 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3, NULL, 0, 'grid_region', '2026-01-14 00:04:34.711577', '2026-01-14 00:04:34.711577');
INSERT INTO sadie_gtm.hotels VALUES (550, 'Tropical Suites Inc.', NULL, '(954) 868-1914', NULL, NULL, '0101000020E61000007BBABA63B10754C01536035C90D53940', '5445 Collins Ave, Miami Beach, FL 33486', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:34.714715', '2026-01-14 00:04:34.714715');
INSERT INTO sadie_gtm.hotels VALUES (557, 'Seacoast Suites on Miami Beach', NULL, NULL, NULL, NULL, '0101000020E6100000A091BEFFC50754C0D560753F02D43940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:39.631824', '2026-01-14 00:04:39.631824');
INSERT INTO sadie_gtm.hotels VALUES (561, 'Fontainebleau Hotel 30th Fl Oceanfront Jr Suite', NULL, NULL, NULL, NULL, '0101000020E61000009EEF0280BE0754C082610A20C6D13940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:39.642152', '2026-01-14 00:04:39.642152');
INSERT INTO sadie_gtm.hotels VALUES (563, 'Collins Apartments', NULL, NULL, NULL, NULL, '0101000020E610000063A6FE8BB10754C02221808A99D53940', '5445 Collins Ave, Miami, FL 33140', 'Miami', 'FL', 'USA', 3.5, NULL, 0, 'grid_region', '2026-01-14 00:04:39.647384', '2026-01-14 00:04:39.647384');
INSERT INTO sadie_gtm.hotels VALUES (567, 'Casablanca on the Ocean West Tower', NULL, '(305) 868-0010', NULL, NULL, '0101000020E610000099976835C90754C0B27F9E060CD83940', '6060 Indian Creek Dr, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.6, NULL, 0, 'grid_region', '2026-01-14 00:04:43.196283', '2026-01-14 00:04:43.196283');
INSERT INTO sadie_gtm.hotels VALUES (570, 'King Motel', NULL, '(305) 757-2674', NULL, NULL, '0101000020E61000008D093197D40B54C0618907944DD73940', '7150 Biscayne Blvd, Miami, FL 33138', 'Miami', 'FL', 'USA', 3.9, NULL, 0, 'grid_region', '2026-01-14 00:04:43.20147', '2026-01-14 00:04:43.20147');
INSERT INTO sadie_gtm.hotels VALUES (571, 'Sixty Sixty Resort', NULL, '(786) 864-2300', NULL, NULL, '0101000020E61000000A25389AC80754C0D46B6924F8D73940', '6060 Indian Creek Dr, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.6, NULL, 0, 'grid_region', '2026-01-14 00:04:43.203097', '2026-01-14 00:04:43.203097');
INSERT INTO sadie_gtm.hotels VALUES (574, 'Royal Inn', NULL, NULL, NULL, NULL, '0101000020E610000017F60F7DD20B54C0E70AA5E5F6D73940', '7422 Biscayne Blvd, Miami, FL 33138', 'Miami', 'FL', 'USA', 4.1, NULL, 0, 'grid_region', '2026-01-14 00:04:43.208317', '2026-01-14 00:04:43.208317');
INSERT INTO sadie_gtm.hotels VALUES (575, 'Alojamiento Miami', NULL, NULL, NULL, NULL, '0101000020E6100000259AF683F00B54C0C95E4AB8EBD23940', '23 NE 52nd St, Miami, FL 33137', 'Miami', 'FL', 'USA', 4.3, NULL, 0, 'grid_region', '2026-01-14 00:04:43.209788', '2026-01-14 00:04:43.209788');
INSERT INTO sadie_gtm.hotels VALUES (578, 'L&D Vacation Rentals', NULL, '(786) 657-8743', NULL, NULL, '0101000020E6100000AB9D17DDB00754C092C7783991D53940', '5445 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 1, NULL, 0, 'grid_region', '2026-01-14 00:04:43.214743', '2026-01-14 00:04:43.214743');
INSERT INTO sadie_gtm.hotels VALUES (580, 'Sultan Suites- Balcony with Magnificent Views with Simply the best Value', NULL, '(954) 404-3945', NULL, NULL, '0101000020E6100000C8602063C90754C06BCA5F6B00D83940', '6060 Indian Creek Dr, Miami Beach, FL 33141', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:51.030996', '2026-01-14 00:04:51.030996');
INSERT INTO sadie_gtm.hotels VALUES (581, 'Alden on Indian Creek Vacation Rentals', NULL, '(786) 456-8710', NULL, NULL, '0101000020E6100000E01DCF1DB30754C0300510E3DAD73940', '6039 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 5, NULL, 0, 'grid_region', '2026-01-14 00:04:51.039171', '2026-01-14 00:04:51.039171');
INSERT INTO sadie_gtm.hotels VALUES (582, 'Pavilion', NULL, NULL, NULL, NULL, '0101000020E6100000A3416557B50754C08828CBB50DD63940', 'South, Miami, FL 33140', 'Miami', 'FL', 'USA', 4.4, NULL, 0, 'grid_region', '2026-01-14 00:04:51.042935', '2026-01-14 00:04:51.042935');
INSERT INTO sadie_gtm.hotels VALUES (583, 'Cozy Beachfront 2 BDR Miami Beach Condo 1516', NULL, NULL, NULL, NULL, '0101000020E6100000F5503640C40754C074FE37407AD43940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:51.048036', '2026-01-14 00:04:51.048036');
INSERT INTO sadie_gtm.hotels VALUES (584, 'Spacious Ocean View Condo in Beachfront Hotel Resort Amenities 1608', NULL, NULL, NULL, NULL, '0101000020E6100000F5503640C40754C074FE37407AD43940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:51.051827', '2026-01-14 00:04:51.051827');
INSERT INTO sadie_gtm.hotels VALUES (586, 'Castle M4 Beachfront Balcony Loft, FREE Parking, Pool, Tennis, Beach Access', NULL, NULL, NULL, NULL, '0101000020E61000009FECC1FFB10754C08B7159E086D53940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:51.061535', '2026-01-14 00:04:51.061535');
INSERT INTO sadie_gtm.hotels VALUES (589, 'Direct BeachFront Views in Central Location Between South Beach and North Beach', NULL, NULL, NULL, NULL, '0101000020E610000081BC0D20B20754C0C57E051F39D63940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:51.075487', '2026-01-14 00:04:51.075487');
INSERT INTO sadie_gtm.hotels VALUES (590, 'Beautiful Townhouse with Beachfront Access to Boardwalk to Miami South Beach.', NULL, NULL, NULL, NULL, '0101000020E61000001DC9E53FA40754C0343F4860BDD53940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:51.07908', '2026-01-14 00:04:51.07908');
INSERT INTO sadie_gtm.hotels VALUES (591, '2bd Beachfront Master Ste, Bay View w/balcony, Pool, nearby dining, beach access', NULL, NULL, NULL, NULL, '0101000020E61000001844FF5FD00754C01803907F0BD33940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:51.082466', '2026-01-14 00:04:51.082466');
INSERT INTO sadie_gtm.hotels VALUES (598, 'Ocean View Balcony-Beachfront Resort', NULL, NULL, NULL, NULL, '0101000020E61000003AFF1B20BD0754C09D4A06802AD43940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:51.10646', '2026-01-14 00:04:51.10646');
INSERT INTO sadie_gtm.hotels VALUES (600, 'Gorgeous Ocean View 3BD Condo in Beachfront Resort 907', NULL, NULL, NULL, NULL, '0101000020E61000008B30EAFFC10754C0418D8C1F74D43940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 0, 'grid_region', '2026-01-14 00:04:51.112335', '2026-01-14 00:04:51.112335');
INSERT INTO sadie_gtm.hotels VALUES (148, 'Ithaca Hotel By At Mine Hospitality', 'https://www.atminehospitality.com/', '(305) 497-7553', NULL, NULL, '0101000020E6100000A32314B67A0854C0384E65AC91C63940', '601 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.8, NULL, 99, 'grid_region', '2026-01-14 00:02:15.032225', '2026-01-14 21:51:26.175692');
INSERT INTO sadie_gtm.hotels VALUES (149, 'Posh Hostel South Beach', 'https://www.poshsouthbeach.com/', '(305) 674-8821', NULL, NULL, '0101000020E610000010B8640B770854C02A3CC32F50C73940', '820 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.9, NULL, 99, 'grid_region', '2026-01-14 00:02:18.648536', '2026-01-14 21:51:26.179459');
INSERT INTO sadie_gtm.hotels VALUES (151, 'Jurny suites Miami Beach', 'https://www.jurnysouthbeach.xyz/', '(888) 875-8769', NULL, NULL, '0101000020E6100000751E15FF770854C03B6EF8DD74C73940', '852 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.5, NULL, 99, 'grid_region', '2026-01-14 00:02:18.672958', '2026-01-14 21:51:26.182499');
INSERT INTO sadie_gtm.hotels VALUES (170, 'Esmé Miami Beach', 'https://www.esmehotel.com/?utm_source=local-listings&utm_medium=organic&utm_campaign=local-listings', '(305) 809-8050', '+13058098050', NULL, '0101000020E6100000E947C329730854C01CD0D2156CC93940', '1438 Washington Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 3, 'grid_region', '2026-01-14 00:02:22.813526', '2026-01-14 23:29:58.196819');
INSERT INTO sadie_gtm.hotels VALUES (163, 'Strand Ocean Drive Suites', 'https://www.strandoceandrivesuites.com/', NULL, '+17147170053', NULL, '0101000020E6100000889D29745E0854C00E677E3507C83940', '1052 Ocean Dr suite a, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.7, NULL, 3, 'grid_region', '2026-01-14 00:02:22.788524', '2026-01-14 23:30:16.856015');
INSERT INTO sadie_gtm.hotels VALUES (166, 'Clevelander South Beach', 'https://www.clevelander.com/', '(305) 532-4006', '8775324006', NULL, '0101000020E6100000FEB3E6C75F0854C0EF8E8CD5E6C73940', '1020 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.1, NULL, 3, 'grid_region', '2026-01-14 00:02:22.796915', '2026-01-14 23:42:55.87829');
INSERT INTO sadie_gtm.hotels VALUES (172, 'The Betsy Hotel', 'https://www.thebetsyhotel.com/?utm_source=google-gbp&utm_medium=organic&utm_campaign=gbp', '(866) 792-3879', '8445392840', 'info@thebetsyhotel.com', '0101000020E6100000AF0F46474D0854C09C48D51B5AC93940', '1440 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.6, NULL, 3, 'grid_region', '2026-01-14 00:02:22.820638', '2026-01-14 23:54:51.14951');
INSERT INTO sadie_gtm.hotels VALUES (165, 'Ocean Drive Beachfront by Deco 305', 'https://www.deco305.com/ocean-drive-beachfront/', '(786) 309-2173', '7863092173', 'louiezrentals@gmail.com', '0101000020E6100000BA6F10084F0854C0377579CE71C93940', '1446 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.5, NULL, 3, 'grid_region', '2026-01-14 00:02:22.794376', '2026-01-15 00:01:57.286955');
INSERT INTO sadie_gtm.hotels VALUES (152, 'Beach Park Hotel', 'http://www.beachparkmiami.com/', '(305) 531-0021', NULL, NULL, '0101000020E6100000CCB051D66F0854C073BC02D193C63940', '600 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.2, NULL, 99, 'grid_region', '2026-01-14 00:02:18.675818', '2026-01-14 21:51:26.186174');
INSERT INTO sadie_gtm.hotels VALUES (155, 'Miami Beach Vacation Rental w/ Rooftop Pool Access', 'http://g.rentalsunited.com/gate.aspx?uid=554691&url=1&pid=3554852&lc=google', NULL, NULL, NULL, '0101000020E6100000D43D5700780854C0264003A040C63940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:18.68265', '2026-01-14 21:51:26.189895');
INSERT INTO sadie_gtm.hotels VALUES (158, 'Miami World Rental - Ocean 201 130', 'https://www.decolar.com/hoteis/h-1716601', NULL, NULL, NULL, '0101000020E6100000C66AF3FFAA0854C005EFF5FFBBC53940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:18.688684', '2026-01-14 21:51:26.193359');
INSERT INTO sadie_gtm.hotels VALUES (159, 'Avalon Hotel Miami', 'http://www.avalonhotel.com/', '(305) 538-0133', NULL, NULL, '0101000020E6100000F9FC8BFB6A0854C0CC069964E4C63940', '700 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:02:18.690162', '2026-01-14 21:51:26.197111');
INSERT INTO sadie_gtm.hotels VALUES (160, 'The Meridian Hotel by At Mine Hospitality', 'https://www.atminehospitality.com/', '(305) 497-7553', NULL, NULL, '0101000020E610000096EC33C2B60854C0DCF9D9232FC63940', '418 Meridian Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.8, NULL, 99, 'grid_region', '2026-01-14 00:02:18.691946', '2026-01-14 21:51:26.200613');
INSERT INTO sadie_gtm.hotels VALUES (162, 'Hotel Ocean South Beach', 'http://hotelocean.com/', '(305) 672-2579', NULL, NULL, '0101000020E6100000F1660DDE570854C0C2A4F8F884C83940', '1230 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4, NULL, 99, 'grid_region', '2026-01-14 00:02:22.782756', '2026-01-14 21:51:26.203688');
INSERT INTO sadie_gtm.hotels VALUES (146, 'The Colony Hotel', 'https://colonymiami.com/', '(305) 673-0088', NULL, NULL, '0101000020E61000005FE2D92F690854C038903F6205C73940', '736 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.6, NULL, 99, 'grid_region', '2026-01-14 00:02:15.028101', '2026-01-14 21:51:26.215205');
INSERT INTO sadie_gtm.hotels VALUES (147, 'Jasper Miami', 'https://jasper.miami/', NULL, NULL, 'reservations@jasper.miami', '0101000020E610000009C5B189A70854C001B6CD9E15C63940', '701 4th St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 5, NULL, 99, 'grid_region', '2026-01-14 00:02:15.030336', '2026-01-14 21:51:26.216638');
INSERT INTO sadie_gtm.hotels VALUES (150, 'Miami Beach Villa Venezia B&B', 'https://www.miamibeachvillavenezia.com/', '(786) 757-6287', NULL, NULL, '0101000020E6100000C3876DE6EB0854C07FD2F5E91DC73940', '745 Lenox Ave., Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:02:18.65533', '2026-01-14 21:51:26.219617');
INSERT INTO sadie_gtm.hotels VALUES (154, 'Miami Beach Vacation Rental with Rooftop Pool Access', 'https://br.bluepillow.com/search/65c9d5ba671b07d23c676890?dest=bkng&cat=House&lat=25.77442&lng=-80.13233&language=pt', NULL, NULL, NULL, '0101000020E6100000224ECC1F780854C0F75F426040C63940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:18.680513', '2026-01-14 21:51:26.222318');
INSERT INTO sadie_gtm.hotels VALUES (156, 'Relaxing City Getaway 1BR, Sleeps 4, Sun Deck', 'https://br.bluepillow.com/search/67a24191905c444f2d0b1a82?dest=ago&cat=Vacation+rental+(other)&lat=25.77851&lng=-80.13397&language=pt', NULL, NULL, NULL, '0101000020E6100000AF642200930854C06D23545F4CC73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:18.685301', '2026-01-14 21:51:26.224413');
INSERT INTO sadie_gtm.hotels VALUES (157, 'vacation home-ocean view SoBe 318', 'https://br.bluepillow.com/search/5cdf33d7e24da42780d86e91?dest=bkng&cat=House&lat=25.77539&lng=-80.13206&language=pt', NULL, NULL, NULL, '0101000020E6100000E2CC0AA0730854C035A094FF7FC63940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:18.687104', '2026-01-14 21:51:26.22651');
INSERT INTO sadie_gtm.hotels VALUES (164, 'Hotel Breakwater South Beach', 'http://breakwatersouthbeach.com/', '(305) 532-2362', NULL, NULL, '0101000020E61000007F3EDBB4630854C0B99C5C9DADC73940', '940 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.8, NULL, 99, 'grid_region', '2026-01-14 00:02:22.791917', '2026-01-14 21:51:47.47072');
INSERT INTO sadie_gtm.hotels VALUES (167, 'Mondrian South Beach Miami', 'http://mondriansouthbeach.com/?utm_source=google-gmb&utm_medium=organic&utm_campaign=gmb&y_source=1_MTUzNjE4ODctNzE1LWxvY2F0aW9uLmdvb2dsZV93ZWJzaXRlX292ZXJyaWRl', '(305) 514-1500', NULL, NULL, '0101000020E6100000D67844E0230954C000FB8D1B23C83940', '1100 West Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.9, NULL, 99, 'grid_region', '2026-01-14 00:02:22.804728', '2026-01-14 21:51:47.476281');
INSERT INTO sadie_gtm.hotels VALUES (171, 'Casa Boutique Hotel', 'http://www.casamiamihotel.com/?utm_source=gmb&utm_medium=organic', '(786) 216-7780', NULL, NULL, '0101000020E6100000CFCB7223760854C03F47F5E7ECC83940', '1334 Washington Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:02:22.817556', '2026-01-14 21:51:47.482467');
INSERT INTO sadie_gtm.hotels VALUES (181, 'Luxury Waterfront Condo In The Urban Oasis At Icon-Brickell, W Resort Free SPA', 'https://www.decolar.com/hoteis/h-5738054', NULL, NULL, NULL, '0101000020E610000029232E000D0C54C022AA4B21EBC43940', 'Miami, FL 33131', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:26.945336', '2026-01-14 21:51:47.489065');
INSERT INTO sadie_gtm.hotels VALUES (189, 'Waterfront Condo w/ View ~ 6 Miles to South Beach!', 'http://g.rentalsunited.com/gate.aspx?uid=554691&url=1&pid=3099527&lc=google', NULL, NULL, NULL, '0101000020E6100000D60BF43F2F0C54C082209B3F01C33940', 'Miami, FL 33131', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:26.978177', '2026-01-14 21:51:47.495625');
INSERT INTO sadie_gtm.hotels VALUES (68, 'Casa Sofi', 'https://www.casahotelsgroup.com/casa-sofi', '(305) 801-5348', '3058015348', 'info@hotels.casa', '0101000020E61000006598C926AF0854C042EFE8DA72C53940', '735 2nd St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.1, NULL, 3, 'grid_region', '2026-01-14 00:02:07.098521', '2026-01-14 23:26:22.956138');
INSERT INTO sadie_gtm.hotels VALUES (177, 'Hard Rock Cafe', 'https://cafe.hardrock.com/miami/#utm_source=Google&utm_medium=Yext&utm_campaign=Listings', '(305) 377-3110', NULL, 'miami_social@hardrock.com', '0101000020E6100000CC988235CE0B54C0184B47EF0AC73940', '401 Biscayne Blvd, Miami, FL 33132', 'Miami', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:02:26.931673', '2026-01-14 21:51:47.532947');
INSERT INTO sadie_gtm.hotels VALUES (178, 'Chili''s Grill & Bar', 'https://www.chilis.com/locations/us/florida/miami/bayside-miami?utm_source=google&utm_medium=local&utm_campaign=Chilis', '(305) 373-0601', '3053730601', NULL, '0101000020E6100000A3906456EF0B54C0D5230D6E6BC73940', 'Bayside Marketplace, 401 Biscayne Blvd N-212, Miami, FL 33132', 'Miami', 'FL', 'USA', 3.9, NULL, 99, 'grid_region', '2026-01-14 00:02:26.935618', '2026-01-14 21:51:47.537016');
INSERT INTO sadie_gtm.hotels VALUES (183, 'Waterfront Luxury: South Beach 2Bed\/2Bath Boutique Condo, Panoramic Views', 'https://br.bluepillow.com/search/67a4dfc0064d51dcdc954416?dest=bpex&cat=Apartment&lat=25.77316&lng=-80.14084&language=pt', NULL, NULL, NULL, '0101000020E6100000EC40E77F030954C0C20B6CDFEDC53940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:26.951547', '2026-01-14 21:51:47.54125');
INSERT INTO sadie_gtm.hotels VALUES (173, 'Leslie Hotel Ocean Drive', 'https://lesliehotel.com/', '(786) 476-2645', '17864762645', NULL, '0101000020E61000009F18FE78540854C077595D9896C83940', '1244 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.2, NULL, 3, 'grid_region', '2026-01-14 00:02:22.823348', '2026-01-14 23:34:13.714615');
INSERT INTO sadie_gtm.hotels VALUES (57, 'Prime Hotel', 'https://mylesrestaurantgroup.com/prime-hotel/', '(305) 532-0553', NULL, NULL, '0101000020E6100000B538BE51860854C0BC1BB05010C53940', '100 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 3, 'grid_region', '2026-01-14 00:01:55.437607', '2026-01-14 23:53:52.517165');
INSERT INTO sadie_gtm.hotels VALUES (56, 'Nikki Beach Miami Beach', 'https://nikkibeach.com/miami-beach/', '(305) 538-1111', '13053215238', 'reservations.miamibeach@nikkibeach.com', '0101000020E6100000D55A9885760854C022FDF675E0C43940', '1 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.2, NULL, 3, 'grid_region', '2026-01-14 00:01:55.435555', '2026-01-15 00:02:21.636521');
INSERT INTO sadie_gtm.hotels VALUES (186, 'Waterfront Luxury 1 Bedroom IconBrickell with View', 'https://br.bluepillow.com/search/6398c958c551970d3c725a7d?dest=bkng&cat=Apartment&lat=25.76866&lng=-80.18873&language=pt', NULL, NULL, NULL, '0101000020E6100000E4744820140C54C0A6C123E0C6C43940', 'Miami, FL 33131', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:26.970068', '2026-01-14 21:51:47.545087');
INSERT INTO sadie_gtm.hotels VALUES (187, 'Waterfront Spacious Luxury 1 Bedroom IconBrickell', 'https://br.bluepillow.com/search/6398c94dc551970d3c725a63?dest=bkng&cat=House&lat=25.76835&lng=-80.18898&language=pt', NULL, NULL, NULL, '0101000020E61000001146FD3F180C54C0AADCFA9FB2C43940', 'Miami, FL 33131', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:26.973534', '2026-01-14 21:51:47.548847');
INSERT INTO sadie_gtm.hotels VALUES (49, 'SoFi Vacation Rentals', 'https://deals.vio.com/?sig=73aca13c7f952d2641c156f3e69125e1eb497c325f122828ee5aa8797168b9a12d32303331333438363233&turl=https%3A%2F%2Fwww.vio.com%2FHotel%2FSearch%3FhotelId%3D115600612%26utm_source%3Dgha-vr%26utm_campaign%3Dstatic%26openHotelDetails%3D1', NULL, NULL, 'partners@vio.com', '0101000020E61000002F76B11F980854C07539252026C53940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:01:55.415776', '2026-01-14 19:01:42.563973');
INSERT INTO sadie_gtm.hotels VALUES (54, 'SeaDream Yacht Club', 'https://seadream.com/', '(800) 707-4911', '+18007074911', NULL, '0101000020E61000002ABE4637E70B54C0241D2FEE50C43940', '601 Brickell Key Dr #700, Miami, FL 33131', 'Miami', 'FL', 'USA', 4.8, NULL, 98, 'grid_region', '2026-01-14 00:01:55.430379', '2026-01-14 19:01:42.567845');
INSERT INTO sadie_gtm.hotels VALUES (205, 'Island House South Beach Hotel', 'https://islandhousesouthbeach.com/', '(305) 864-2422', '+13058642422', NULL, '0101000020E61000005D88D51F610854C089B48D3F51C93940', '1428 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.5, NULL, 3, 'grid_region', '2026-01-14 00:02:30.46225', '2026-01-14 23:26:35.033439');
INSERT INTO sadie_gtm.hotels VALUES (213, 'Two Bedroom Suites South Beach', 'https://stayviax.com/hotel/72229962', NULL, NULL, 'support@stayviax.com', '0101000020E61000002D3E05C0780854C0638C5940B2C63940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 3, 'grid_region', '2026-01-14 00:02:30.489363', '2026-01-14 23:29:23.049678');
INSERT INTO sadie_gtm.hotels VALUES (192, 'Luxury Waterfront Residences - near Kaseya Center', 'https://m.wowotrip.com/homestay/detail?hotelId=LiaS', NULL, NULL, NULL, '0101000020E6100000F968CC7F230C54C0E527D53E1DC73940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:02:27.000736', '2026-01-14 21:51:47.557998');
INSERT INTO sadie_gtm.hotels VALUES (76, 'Downtown by Miami Vacation Rentals', 'https://m.wowotrip.com/homestay/detail?hotelId=KSpc', NULL, NULL, NULL, '0101000020E61000005EC60380190C54C0DE8893A064C73940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:02:07.121759', '2026-01-14 20:08:34.275574');
INSERT INTO sadie_gtm.hotels VALUES (78, 'Miami Vacation Rentals - Downtown - Deluxe Studio, 1 King Bed with Sofa bed, Bay View4202', 'https://br.bluepillow.com/search/67cab1c2fa1a57d5a4b05976/327324352?dest=eps&cat=Apartment&lat=25.77888&lng=-80.18908&language=pt', NULL, '0992961096', 'info@bluepillow.com', '0101000020E6100000707610E0190C54C0DE8893A064C73940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:02:07.126387', '2026-01-14 20:08:34.277693');
INSERT INTO sadie_gtm.hotels VALUES (79, 'Miami Vacation Rentals - Downtown - Deluxe Studio, 1 King Bed with Sofa bed, Bay View1804', 'https://br.bluepillow.com/search/67cab1c2fa1a57d5a4b05976/327084477?dest=eps&cat=Apartment&lat=25.77888&lng=-80.18908&language=pt', NULL, '0992961096', 'info@bluepillow.com', '0101000020E6100000707610E0190C54C0DE8893A064C73940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:02:07.128977', '2026-01-14 20:08:34.279917');
INSERT INTO sadie_gtm.hotels VALUES (199, 'K''Alma Spa', 'http://kalmaspas.com/', '(305) 534-5555', NULL, NULL, '0101000020E6100000CC28965B5A0854C04102902452C83940', '1144 Ocean Dr Lower Level, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.6, NULL, 99, 'grid_region', '2026-01-14 00:02:27.01624', '2026-01-14 21:49:19.372407');
INSERT INTO sadie_gtm.hotels VALUES (88, 'Downtown Miami Condos by Lua Host - Apartment with Balcony', 'https://br.bluepillow.com/search/65cad1af671b07d23c707f7d/979905109?dest=bkng&cat=House&lat=25.77651&lng=-80.18969&language=pt', NULL, NULL, NULL, '0101000020E61000000B19D9DF230C54C0AB025A5FC9C63940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:07.149684', '2026-01-14 20:13:06.538494');
INSERT INTO sadie_gtm.hotels VALUES (89, '1Br Loft in downtown with bay view and workspace', 'https://br.bluepillow.com/search/681307115250632c595599a6?dest=bkng&cat=Apartment&lat=25.77708&lng=-80.18967&language=pt', NULL, NULL, NULL, '0101000020E6100000F968CC7F230C54C0FDDB65BFEEC63940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:07.151696', '2026-01-14 20:13:06.541964');
INSERT INTO sadie_gtm.hotels VALUES (90, '**Luxurious,Boho Studio in Downtown Miami/Bay View', 'https://br.bluepillow.com/search/62df12d0ba454484938a7879?dest=bkng&cat=House&lat=25.77779&lng=-80.18969&language=pt', NULL, NULL, NULL, '0101000020E61000000B19D9DF230C54C00EA782401DC73940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:07.153659', '2026-01-14 20:13:06.545315');
INSERT INTO sadie_gtm.hotels VALUES (74, 'Franklin Suites South Beach', 'https://franklinsuitessouthbeach.com/', '(813) 578-4561', '8135784561', 'info@franklinsuitessouthbeach.com', '0101000020E61000006477DC4B750854C05AB0F95D7DC73940', '860 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 3, 'grid_region', '2026-01-14 00:02:07.117628', '2026-01-14 23:25:57.429475');
INSERT INTO sadie_gtm.hotels VALUES (201, 'St. Augustine Hotel By At Mine Hospitality', 'https://atminehospitality.com/', '(305) 497-7553', NULL, NULL, '0101000020E6100000F50AB034950854C097FC4FFEEEC53940', '347 Washington Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 5, NULL, 99, 'grid_region', '2026-01-14 00:02:30.446736', '2026-01-14 21:49:19.383634');
INSERT INTO sadie_gtm.hotels VALUES (210, 'Ocean Reef Suites', 'http://www.oceanreefsuites.com/', '(305) 538-1970', NULL, NULL, '0101000020E61000002203D42F6C0854C02CAA8FD14BC83940', '1130 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.1, NULL, 99, 'grid_region', '2026-01-14 00:02:30.479709', '2026-01-14 21:49:19.391929');
INSERT INTO sadie_gtm.hotels VALUES (197, 'Aloha Fridays', 'https://alohafridaysmiami.com/', '(305) 928-7564', '3059287564', 'reservations@blue-suede.com', '0101000020E6100000E8FF0BBA730854C0601B96ABC4C73940', '944 Collins Ave #952, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.1, NULL, 99, 'grid_region', '2026-01-14 00:02:27.012373', '2026-01-14 21:49:19.407635');
INSERT INTO sadie_gtm.hotels VALUES (208, 'Miami Suites South Beach', 'https://deals.vio.com/?sig=73aca13c7f952d2641c156f3e69125e1eb497c325f122828ee5aa8797168b9a12d32303331333438363233&turl=https%3A%2F%2Fwww.vio.com%2FHotel%2FSearch%3FhotelId%3D3028412%26utm_source%3Dgha-vr%26utm_campaign%3Dstatic%26openHotelDetails%3D1', NULL, NULL, 'partners@vio.com', '0101000020E610000028B91EE0240954C02DF713DF9AC93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:02:30.471518', '2026-01-14 21:49:19.468563');
INSERT INTO sadie_gtm.hotels VALUES (241, 'The Shepley South Beach Hotel', 'https://theshepleyhotel.com/', '(786) 260-6124', '17862606124', NULL, '0101000020E61000002D5DC136620854C00F8F0E59EEC83940', '1340 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.4, NULL, 3, 'grid_region', '2026-01-14 00:02:41.8374', '2026-01-14 23:31:01.209875');
INSERT INTO sadie_gtm.hotels VALUES (221, 'Miami International Apartments by Lowkl', 'https://lowkl.com/property/miami-beach-international/', '(786) 373-6701', '+17863736701', 'reservations@lowkl.com', '0101000020E6100000E89A6E7E680854C06F980DD70FC83940', '1051 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.9, NULL, 3, 'grid_region', '2026-01-14 00:02:30.506409', '2026-01-14 23:31:08.859899');
INSERT INTO sadie_gtm.hotels VALUES (226, 'Bikini Hostel, Cafe & Beer Garden', 'http://www.bikinihostel.com/', '(305) 253-9000', NULL, NULL, '0101000020E6100000BA96DA9C140954C0E1A7BBFC98C83940', '1247 West Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.2, NULL, 99, 'grid_region', '2026-01-14 00:02:37.679196', '2026-01-14 21:49:07.121319');
INSERT INTO sadie_gtm.hotels VALUES (231, 'Edison Hotel', 'http://edisonhotelsouthbeach.com/', '(305) 908-1462', NULL, NULL, '0101000020E61000005DE795A1600854C021FC30E7BEC73940', '960 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.9, NULL, 99, 'grid_region', '2026-01-14 00:02:37.696123', '2026-01-14 21:49:07.132381');
INSERT INTO sadie_gtm.hotels VALUES (235, 'The Clay Hotel', 'https://hotelsbeaches.com/the-clay-hotel', '(305) 534-2988', NULL, NULL, '0101000020E6100000E947C329730854C01CD0D2156CC93940', '1438 Washington Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.6, NULL, 99, 'grid_region', '2026-01-14 00:02:41.829393', '2026-01-14 21:49:07.14206');
INSERT INTO sadie_gtm.hotels VALUES (236, 'Suites On South Beach', 'http://www.suitesonsouthbeach.com/', '(305) 604-9926', NULL, NULL, '0101000020E61000005C7F0173630854C09B59A6BADBC83940', '1330 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4, NULL, 99, 'grid_region', '2026-01-14 00:02:41.831018', '2026-01-14 21:49:07.150964');
INSERT INTO sadie_gtm.hotels VALUES (239, 'The Stiles Hotel', 'http://www.thestileshotel.com/', '(305) 674-7800', NULL, NULL, '0101000020E61000001159FF426A0854C059C8128C39C83940', '1120 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.8, NULL, 99, 'grid_region', '2026-01-14 00:02:41.835177', '2026-01-14 21:49:07.158911');
INSERT INTO sadie_gtm.hotels VALUES (240, 'Hotel Victor South Beach', 'http://www.hotelvictorsouthbeach.com/', '(305) 779-8700', NULL, NULL, '0101000020E610000031D7FDBE5A0854C032535A7F4BC83940', '1144 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.2, NULL, 99, 'grid_region', '2026-01-14 00:02:41.836259', '2026-01-14 21:49:07.165805');
INSERT INTO sadie_gtm.hotels VALUES (242, 'The Villa Casa Casuarina At The Former Versace Mansion', 'http://www.vmmiamibeach.com/', '(786) 485-2200', NULL, NULL, '0101000020E610000066A8401C5A0854C0833E479A2EC83940', '1116 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.4, NULL, 99, 'grid_region', '2026-01-14 00:02:41.838436', '2026-01-14 21:49:07.172243');
INSERT INTO sadie_gtm.hotels VALUES (244, 'Hôtel Gaythering', 'http://www.gaythering.com/', '(786) 284-1176', NULL, NULL, '0101000020E6100000B0F5566E330954C0DAA9B9DC60CA3940', '1409 Lincoln Rd, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.6, NULL, 99, 'grid_region', '2026-01-14 00:02:46.876376', '2026-01-14 21:49:07.178174');
INSERT INTO sadie_gtm.hotels VALUES (245, '1818 Meridian House by Eskape Collection', 'http://www.1818meridianhouse.com/', '(305) 974-1004', NULL, NULL, '0101000020E61000006729594EC20854C08A308F464FCB3940', '1816 Meridian Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.9, NULL, 99, 'grid_region', '2026-01-14 00:02:46.880271', '2026-01-14 21:49:07.184575');
INSERT INTO sadie_gtm.hotels VALUES (219, 'MiamiBeachOceanRental', 'https://www.miamibeachoceanrental.com/', '(786) 548-7731', '+17865487731', NULL, '0101000020E610000059A31EA2510854C083AA871EE7C83940', '1330 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4, NULL, 99, 'grid_region', '2026-01-14 00:02:30.502316', '2026-01-14 21:49:07.187681');
INSERT INTO sadie_gtm.hotels VALUES (224, 'Kasa Impala Miami Beach', 'https://kasa.com/properties/kasa-impala-miami-beach?utm_source=Google&utm_medium=nonpaid&utm_campaign=GMB&utm_term=VisitHotelWebsiteButton&utm_content=IMP', '(786) 933-4889', NULL, NULL, '0101000020E6100000ED3D01B9690854C0B1BE81C98DC83940', '1228 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.6, NULL, 99, 'grid_region', '2026-01-14 00:02:30.512857', '2026-01-14 21:49:07.208407');
INSERT INTO sadie_gtm.hotels VALUES (238, 'Z Ocean Hotel', 'https://www.sonesta.com/classico-sonesta-collection/fl/miami-beach/z-ocean-hotel-classico-sonesta-collection', '(305) 672-4554', NULL, NULL, '0101000020E610000038FCC973580854C05E752ED681C93940', '1437 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.7, NULL, 99, 'grid_region', '2026-01-14 00:02:41.833657', '2026-01-14 21:49:07.220884');
INSERT INTO sadie_gtm.hotels VALUES (214, 'Congress Hotel South Beach', 'http://www.congresshotelsouthbeach.com/', '(786) 209-3474', NULL, NULL, '0101000020E61000006AF7AB005F0854C0C20078FAF7C73940', '1036 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.2, NULL, 99, 'grid_region', '2026-01-14 00:02:30.49152', '2026-01-14 21:49:19.401225');
INSERT INTO sadie_gtm.hotels VALUES (215, 'South Beach Suites in Ocean Drive - Apartment with Sea View', 'https://br.bluepillow.com/search/5f087c65e24da40d2075431f/641709501?dest=bkng&cat=House&lat=25.77875&lng=-80.1313&language=pt', NULL, NULL, NULL, '0101000020E6100000C5991540670854C095C7E41E5CC73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:30.493689', '2026-01-14 21:49:19.486667');
INSERT INTO sadie_gtm.hotels VALUES (247, 'SobeVillas', 'http://www.sobevillas.com/', '(888) 762-3845', NULL, NULL, '0101000020E6100000B5029E0F2A0C54C04797EDF950C83940', '888 Biscayne Blvd APT 703, Miami, FL 33132', 'Miami', 'FL', 'USA', 4.9, NULL, 99, 'grid_region', '2026-01-14 00:02:46.884207', '2026-01-14 21:50:16.362982');
INSERT INTO sadie_gtm.hotels VALUES (251, 'Nautilus Sonesta Miami Beach', 'https://www.nautilushotelmiami.com/?utm_source=google&utm_medium=organic&utm_campaign=gmb', '(305) 503-5700', NULL, NULL, '0101000020E610000041898510460854C04666E4E25ECB3940', '1825 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.1, NULL, 99, 'grid_region', '2026-01-14 00:02:46.890672', '2026-01-14 21:50:16.41928');
INSERT INTO sadie_gtm.hotels VALUES (273, 'ART DECO MARELA BOUTIQUE', 'https://decomarela.com/', '(786) 577-9801', NULL, NULL, '0101000020E6100000CBF6216FB90854C01A84B9DDCBC53940', '310 Meridian Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 5, NULL, 1, 'grid_region', '2026-01-14 00:02:50.300211', '2026-01-14 23:26:05.948565');
INSERT INTO sadie_gtm.hotels VALUES (283, 'Kaskades Hotel South Beach', 'https://thekaskadeshotel.com/', '(305) 763-8689', '3057638689', NULL, '0101000020E6100000617EB8F5640854C0FD288F13CBCA3940', '300 17th St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.9, NULL, 3, 'grid_region', '2026-01-14 00:02:50.338689', '2026-01-14 23:25:52.973261');
INSERT INTO sadie_gtm.hotels VALUES (253, 'Fairwind Hotel Miami', 'http://fairwindhotelmiami.com/', '(786) 753-9020', NULL, NULL, '0101000020E61000006ED9C6446F0854C070E82D1EDEC73940', '1000 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.8, NULL, 99, 'grid_region', '2026-01-14 00:02:46.894339', '2026-01-14 21:50:16.378908');
INSERT INTO sadie_gtm.hotels VALUES (254, 'Geneva Hotel', 'http://www.genevahotelmiamibeach.com/', '(305) 398-5364', NULL, NULL, '0101000020E61000007797303F5C0854C02D62331BBFC93940', '1520 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 2.7, NULL, 99, 'grid_region', '2026-01-14 00:02:46.896279', '2026-01-14 21:50:16.386356');
INSERT INTO sadie_gtm.hotels VALUES (263, 'Beachfront, Quiet, Elegant Large Studio On Ocean Drive JACUZZI Art Deco District', 'https://www.decolar.com/hoteis/h-4849641', NULL, NULL, NULL, '0101000020E6100000D9582EC0630854C07419486128C73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:46.910575', '2026-01-14 21:50:16.399503');
INSERT INTO sadie_gtm.hotels VALUES (258, 'Beachfront Ocean Dr white sand paradise SoBe 311', 'https://br.bluepillow.com/search/5ff76f002e43a44b27e1ea91?dest=bkng&cat=Apartment&lat=25.77539&lng=-80.13206&language=pt', NULL, NULL, NULL, '0101000020E6100000E2CC0AA0730854C035A094FF7FC63940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:46.903597', '2026-01-14 21:50:16.43164');
INSERT INTO sadie_gtm.hotels VALUES (261, 'Beachfront apartment with Ocean View', 'https://br.bluepillow.com/search/62df23362d760a9969f0b9d3?dest=bpex&cat=Apartment&lat=25.79027&lng=-80.12846&language=pt', NULL, NULL, NULL, '0101000020E610000012EE3AC0380854C06083CF204FCA3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:46.907884', '2026-01-14 21:50:16.435424');
INSERT INTO sadie_gtm.hotels VALUES (272, 'Beautiful BAY VIEW 2\/2 1100sqf, Resort Style waterfront', 'https://br.bluepillow.com/search/67a4d376064d51dcdc94d9ac?dest=bpex&cat=Apartment&lat=25.79125&lng=-80.18677&language=pt', NULL, NULL, NULL, '0101000020E6100000F47C1700F40B54C016F4835F8FCA3940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:50.293', '2026-01-14 21:50:16.457367');
INSERT INTO sadie_gtm.hotels VALUES (274, 'Beds N'' Drinks', 'http://www.bedsndrinks.com/', '(305) 535-7415', NULL, NULL, '0101000020E6100000FD20DCAE610854C004B86AE8B0CA3940', '1676 James Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.6, NULL, 99, 'grid_region', '2026-01-14 00:02:50.303569', '2026-01-14 21:50:18.648019');
INSERT INTO sadie_gtm.hotels VALUES (278, 'Cadet Hotel', 'http://www.cadethotel.com/?utm_source=google&utm_medium=organic&utm_campaign=GMB', '(305) 672-6688', NULL, NULL, '0101000020E610000078B1D58A5B0854C00B653CA5DECA3940', '1701 James Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:02:50.317242', '2026-01-14 21:50:18.655213');
INSERT INTO sadie_gtm.hotels VALUES (280, 'Dorchester Miami Beach Hotel & Suites', 'http://www.hoteldorchester.com/', '(305) 531-5745', NULL, NULL, '0101000020E6100000EF3DB72B4F0854C025276E707DCB3940', '1850 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4, NULL, 99, 'grid_region', '2026-01-14 00:02:50.32646', '2026-01-14 21:50:18.661604');
INSERT INTO sadie_gtm.hotels VALUES (281, 'Boulan South Beach', 'http://www.boulanmiami.com/', '(305) 674-3315', NULL, NULL, '0101000020E61000004EF85BF1430854C04FFB52E4B5CB3940', '2000 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.9, NULL, 99, 'grid_region', '2026-01-14 00:02:50.330327', '2026-01-14 21:50:18.668987');
INSERT INTO sadie_gtm.hotels VALUES (284, '️️️️️Best Location! Vacation in Paradise on Ocean Dr with Direct Beach View', 'https://www.decolar.com/hoteis/h-4821596', NULL, NULL, NULL, '0101000020E610000086151340560854C0CFC941BFA5C83940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:54.581897', '2026-01-14 21:50:18.676163');
INSERT INTO sadie_gtm.hotels VALUES (275, 'Uma House by Yurbban South Beach', 'https://www.umahousesouthbeach.com/?utm_source=gmb&utm_medium=organic', '(305) 390-1184', '+13053901184', 'southbeach@umahouse.com', '0101000020E610000079E8BB5B590854C077F2E9B12DCB3940', '1775 James Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:02:50.306411', '2026-01-14 21:50:18.702519');
INSERT INTO sadie_gtm.hotels VALUES (276, 'Pestana Miami South Beach', 'https://www.pestana.com/en/hotel/pestana-south-beach?utm_campaign=pestana-south-beach-partoo&utm_medium=organicsearch', '(305) 341-2401', '3053412401', 'fo.southbeach@pestana.com', '0101000020E610000036AB3E575B0854C0A6B6D4415ECB3940', '1817 James Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.4, NULL, 99, 'grid_region', '2026-01-14 00:02:50.309138', '2026-01-14 21:50:18.70588');
INSERT INTO sadie_gtm.hotels VALUES (285, 'C Ocean Rentals at Strand Ocean Drive - Suite, 1 Bedroom, Balcony, Ocean View', 'https://br.bluepillow.com/search/646341c4a51ab0c4fc3c6450/202347207?dest=eps&cat=Apartment&lat=25.78119&lng=-80.13068&language=pt', NULL, NULL, NULL, '0101000020E61000002FB720005D0854C0CC6E7720FCC73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:02:54.590581', '2026-01-14 21:50:18.735575');
INSERT INTO sadie_gtm.hotels VALUES (287, 'Resort style apartment with beautiful Bay views \nMinimum 30 days rental', 'https://br.bluepillow.com/search/67a4ba8c064d51dcdc8f54ec?dest=bpex&cat=Apartment&lat=25.78461&lng=-80.14287&language=pt', NULL, NULL, NULL, '0101000020E610000046E9D2BF240954C07797303FDCC83940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:54.598765', '2026-01-14 21:50:18.742135');
INSERT INTO sadie_gtm.hotels VALUES (288, 'C Ocean Rentals at Strand Ocean Drive - Junior Suite, 1 King Bed, Balcony', 'https://br.bluepillow.com/search/646341c4a51ab0c4fc3c6450/202347215?dest=eps&cat=Apartment&lat=25.78119&lng=-80.13068&language=pt', NULL, '0992961096', 'info@bluepillow.com', '0101000020E61000002FB720005D0854C0CC6E7720FCC73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:02:54.604619', '2026-01-14 21:50:18.747721');
INSERT INTO sadie_gtm.hotels VALUES (321, 'James Hotel', 'https://www.jameshotelmiami.com/', '(305) 531-1125', NULL, NULL, '0101000020E610000026DCD039640854C010ABE408BECA3940', '1680 James Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.6, NULL, 99, 'grid_region', '2026-01-14 00:03:10.659979', '2026-01-14 21:52:27.811835');
INSERT INTO sadie_gtm.hotels VALUES (323, 'Pierogi One', 'https://pierogione.com/', '(305) 333-9201', NULL, NULL, '0101000020E6100000745BC75D290C54C0025BCA9EA9C83940', '990 Biscayne Blvd, Miami, FL 33132', 'Miami', 'FL', 'USA', 4.8, NULL, 99, 'grid_region', '2026-01-14 00:03:10.666352', '2026-01-14 21:52:27.820268');
INSERT INTO sadie_gtm.hotels VALUES (324, 'Cozy Apartment on South Beach', 'https://miami4aday.holidayfuture.com/listings/152344?googleVR=1&utm_source=google&utm_medium=vacation_rentals', NULL, NULL, NULL, '0101000020E610000080EB2F606E0854C0807EDFBF79C73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:10.669421', '2026-01-14 21:52:27.827');
INSERT INTO sadie_gtm.hotels VALUES (326, 'Cozy Room with WiFi and AC in amazing South Miami 2minutes walking to Beach st', 'https://www.decolar.com/hoteis/h-6767476', NULL, NULL, NULL, '0101000020E610000074684760620854C000D41E40D0C73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:10.677562', '2026-01-14 21:52:27.834317');
INSERT INTO sadie_gtm.hotels VALUES (327, 'Cozy Oceanview Retreat on the Bay', 'https://br.bluepillow.com/search/6398aad1c551970d3c721a50?dest=bkng&cat=Apartment&lat=25.79147&lng=-80.18621&language=pt', NULL, NULL, NULL, '0101000020E6100000C94ADDDFEA0B54C038C76FC09DCA3940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:10.680701', '2026-01-14 21:52:27.892159');
INSERT INTO sadie_gtm.hotels VALUES (296, 'Crest Hotel Suites', 'http://cresthotel.com/?utm_source=gmb&utm_medium=organic', '(305) 531-0321', NULL, NULL, '0101000020E61000005D5AC3FB600854C0D70EEB32A1CA3940', '1670 James Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.8, NULL, 99, 'grid_region', '2026-01-14 00:02:58.577147', '2026-01-14 21:50:18.687523');
INSERT INTO sadie_gtm.hotels VALUES (292, '6 Months + Beach Building Rental Apartment, directly at the beach and pool', 'https://br.bluepillow.com/search/67a4ad65064d51dcdc8aac6f?dest=bpex&cat=Apartment&lat=25.7917&lng=-80.12578&language=pt', NULL, NULL, NULL, '0101000020E61000002FE301C00C0854C0E93A9EE0ACCA3940', 'Florida 33139', NULL, NULL, 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:54.622462', '2026-01-14 21:50:18.758543');
INSERT INTO sadie_gtm.hotels VALUES (293, 'Penthouse De Soleil South Beach - on Ocean Drive Miami Beach', 'https://www.redawning.com/rental-property/penthouse-de-soleil-south-beach-ocean-drive-miami-beach-miami-beach', NULL, '5109534900', 'guest@redawning.com', '0101000020E6100000B804E09F520854C0E7A0F07E81C93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:54.625404', '2026-01-14 21:50:18.761901');
INSERT INTO sadie_gtm.hotels VALUES (295, '17WEST Apartments by Stay Hospitality', 'https://stay-hospitality.com/17-west/', '(954) 526-8998', '9545268998', 'help@stay-hospitality.com', '0101000020E6100000D7C3F242150954C046A7F809B1CA3940', '1220 17th St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.6, NULL, 99, 'grid_region', '2026-01-14 00:02:54.630264', '2026-01-14 21:50:18.766991');
INSERT INTO sadie_gtm.hotels VALUES (297, 'Sherbrooke All Suites Hotel', 'http://www.sherbrookehotel.com/', '(305) 532-0958', NULL, NULL, '0101000020E6100000A334400E6F0854C05B15979988C73940', '901 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.7, NULL, 99, 'grid_region', '2026-01-14 00:02:58.585239', '2026-01-14 21:52:36.657911');
INSERT INTO sadie_gtm.hotels VALUES (298, 'Tropics Hotel', 'https://www.atminehospitality.com/', '(305) 497-7553', NULL, NULL, '0101000020E6100000255AF2785A0854C0069ACFB9DBC93940', '1550 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.8, NULL, 99, 'grid_region', '2026-01-14 00:02:58.588056', '2026-01-14 21:52:36.675194');
INSERT INTO sadie_gtm.hotels VALUES (300, 'Escape', 'https://www.escapelux.com/', '(786) 264-2911', NULL, NULL, '0101000020E6100000431D56B8E50854C01EC429CEACCA3940', '1680 Michigan Ave Suite 700, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.9, NULL, 99, 'grid_region', '2026-01-14 00:02:58.593856', '2026-01-14 21:52:36.693465');
INSERT INTO sadie_gtm.hotels VALUES (301, 'Premier Villa Rental Miami', 'https://premiervillarental.com/villa-rentals-in-miami/', '(866) 551-6108', NULL, NULL, '0101000020E6100000281C8BB75F0854C00983D7D3B3C93940', '1510 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4, NULL, 99, 'grid_region', '2026-01-14 00:02:58.597023', '2026-01-14 21:52:36.698203');
INSERT INTO sadie_gtm.hotels VALUES (307, 'Lincoln Arms Suites', 'https://lincolnarmssuites.com/', '(786) 541-2125', NULL, NULL, '0101000020E6100000796462A9640854C0583BE52C47CB3940', '1800 James Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.4, NULL, 99, 'grid_region', '2026-01-14 00:02:58.616926', '2026-01-14 21:52:36.702648');
INSERT INTO sadie_gtm.hotels VALUES (311, 'Riviera Hotel South Beach', 'https://rivierahotelsouthbeach.com/', '(305) 538-7444', NULL, NULL, '0101000020E61000004E017A2B5C0854C004CF1841BECB3940', '318 20th St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.2, NULL, 99, 'grid_region', '2026-01-14 00:03:05.659878', '2026-01-14 21:52:36.707182');
INSERT INTO sadie_gtm.hotels VALUES (312, 'Lennox Miami Beach', 'https://www.lennoxmiamibeach.com/?utm_source=google&utm_medium=organic&utm_campaign=gbp_listing', '(305) 531-6800', NULL, NULL, '0101000020E61000002ECD08CA480854C081D888168FCB3940', '1900 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4, NULL, 99, 'grid_region', '2026-01-14 00:03:05.663654', '2026-01-14 21:52:36.712964');
INSERT INTO sadie_gtm.hotels VALUES (313, 'Donatella Boutique Hotel', 'https://donatellahotel.com/', '(305) 400-4393', NULL, NULL, '0101000020E6100000F0243328640854C05C5DA9C2FAC83940', '1350 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:03:05.666237', '2026-01-14 21:52:36.716898');
INSERT INTO sadie_gtm.hotels VALUES (315, 'Dunns Josephine Hotel', 'http://dunns-josephinehotel.com/', '(877) 571-9311', NULL, NULL, '0101000020E6100000BBC09B24CC0C54C0CD3F55E0BFC83940', '1028 NW 3rd Ave, Miami, FL 33136', 'Miami', 'FL', 'USA', 3.9, NULL, 99, 'grid_region', '2026-01-14 00:03:05.67612', '2026-01-14 21:52:36.719854');
INSERT INTO sadie_gtm.hotels VALUES (318, 'Baybreeze Apartments by Lowkl', 'https://lowkl.com/property/baybreeze-apartments-by-lowkl/', '(786) 373-6691', NULL, NULL, '0101000020E6100000232A5437170954C05D71CC0DE1C93940', '1565 West Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.5, NULL, 99, 'grid_region', '2026-01-14 00:03:10.651694', '2026-01-14 21:52:36.7227');
INSERT INTO sadie_gtm.hotels VALUES (319, 'The Dorset Hotel', 'https://catalinahotel.com/', '(305) 938-6000', NULL, NULL, '0101000020E6100000965AEF375A0854C0DCCC32D5DDCA3940', '1720 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.3, NULL, 99, 'grid_region', '2026-01-14 00:03:10.655208', '2026-01-14 21:52:36.725738');
INSERT INTO sadie_gtm.hotels VALUES (299, 'American Vacation Living', 'https://www.americanvacationliving.com/', '(305) 767-5512', '+13056996125', 'info@AmericanVacationLiving.com', '0101000020E6100000BE24DFB6000954C0921337B8BEC93940', '1521 Alton Rd #216, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 5, NULL, 99, 'grid_region', '2026-01-14 00:02:58.591018', '2026-01-14 21:52:36.727103');
INSERT INTO sadie_gtm.hotels VALUES (302, 'Miami Residences Management and Vacation Rentals', 'https://mrmvr.com/', '(305) 747-3886', NULL, NULL, '0101000020E6100000B48AA317DA0854C0D5FE733D76CA3940', '927 Lincoln Rd #200, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.8, NULL, 99, 'grid_region', '2026-01-14 00:02:58.600219', '2026-01-14 21:52:36.730126');
INSERT INTO sadie_gtm.hotels VALUES (303, 'VILLAWAY ® - Luxury Vacation Rentals & Villas for Rent', 'https://www.villaway.com/', '(800) 897-1100', NULL, NULL, '0101000020E61000001EABEF57DC0854C00046E1C4A1CA3940', '1680 Michigan Ave Suite 700, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:02:58.603064', '2026-01-14 21:52:36.732832');
INSERT INTO sadie_gtm.hotels VALUES (305, 'Thine Agency', 'https://www.thineagency.com/', '(305) 609-5500', '3054344572', 'sophia@thineagency.com', '0101000020E6100000EA8DFFA7870854C07A26457584C53940', '225 Collins Ave #101, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.8, NULL, 99, 'grid_region', '2026-01-14 00:02:58.609818', '2026-01-14 21:52:36.736098');
INSERT INTO sadie_gtm.hotels VALUES (341, 'South Beach Hotel', 'http://www.southbeachhotel.com/', '(305) 531-3464', NULL, NULL, '0101000020E61000006D9681B94C0854C0435C9434DACB3940', '236 21st St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.7, NULL, 3, 'grid_region', '2026-01-14 00:03:10.717332', '2026-01-14 23:28:16.645935');
INSERT INTO sadie_gtm.hotels VALUES (364, 'The Gates Hotel South Beach', 'https://www.gatessouthbeach.com/', '(305) 860-9444', '3058609444', 'Rooms@gatessouthbeach.com', '0101000020E61000007DAF21382E0854C0DC3BB4D9A2CC3940', '2360 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.8, NULL, 3, 'grid_region', '2026-01-14 00:03:20.671927', '2026-01-14 23:28:54.737701');
INSERT INTO sadie_gtm.hotels VALUES (352, 'Luxury 2 bedroom apartment in downtown', 'https://br.bluepillow.com/search/6812385f1a0d3c624bfe003b?dest=bpex&cat=Apartment&lat=25.79186&lng=-80.13811&language=pt', NULL, NULL, NULL, '0101000020E6100000B03500C0D60854C0AEFD5360B7CA3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:16.678242', '2026-01-14 21:51:52.942051');
INSERT INTO sadie_gtm.hotels VALUES (354, 'Bikini Lodge', 'https://br.bluepillow.com/search/594394827c00cb0e643ab764?dest=bkng&cat=House&lat=25.78383&lng=-80.14183&language=pt', NULL, NULL, NULL, '0101000020E61000000865D0BF130954C0CD19F620A9C83940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:20.629638', '2026-01-14 21:51:52.948358');
INSERT INTO sadie_gtm.hotels VALUES (355, 'Bikini Lodge - One-Bedroom Apartment', 'https://br.bluepillow.com/search/594394827c00cb0e643ab764/40270002?dest=bkng&cat=House&lat=25.78383&lng=-80.14183&language=pt', NULL, NULL, NULL, '0101000020E61000000865D0BF130954C0CD19F620A9C83940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:20.637267', '2026-01-14 21:51:52.954732');
INSERT INTO sadie_gtm.hotels VALUES (356, 'Bikini Lodge - Studio with Two Queen Beds', 'https://br.bluepillow.com/search/594394827c00cb0e643ab764/40270004?dest=bkng&cat=House&lat=25.78383&lng=-80.14183&language=pt', NULL, NULL, NULL, '0101000020E61000000865D0BF130954C0CD19F620A9C83940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:20.642756', '2026-01-14 21:51:52.960931');
INSERT INTO sadie_gtm.hotels VALUES (358, 'PanIQ Escape Room Miami Beach', 'https://paniqescaperoom.com/miami-beach/en/', '(305) 247-4995', '3052474995', 'miamibeach@paniqroom.com', '0101000020E6100000C571E0D5720854C06CB1DB6795C73940', '910 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 5, NULL, 99, 'grid_region', '2026-01-14 00:03:20.649966', '2026-01-14 21:51:52.963682');
INSERT INTO sadie_gtm.hotels VALUES (359, 'Rainforest Cruises', 'https://www.rainforestcruises.com/', '(888) 215-3555', '+18882153555', NULL, '0101000020E610000079A97DDFE40854C0CC800E4E9FCA3940', '1680 Michigan Ave Suite 700, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.9, NULL, 98, 'grid_region', '2026-01-14 00:03:20.653932', '2026-01-14 21:51:52.969017');
INSERT INTO sadie_gtm.hotels VALUES (360, 'Small Stays', 'https://www.small-stays.com/', '(786) 905-4347', NULL, NULL, '0101000020E61000005FAC14A77F0854C0320FAA1E7ACA3940', '407 Lincoln Rd Suite 6H PMB 1536, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 5, NULL, 98, 'grid_region', '2026-01-14 00:03:20.657999', '2026-01-14 21:51:52.974856');
INSERT INTO sadie_gtm.hotels VALUES (366, 'SOUTH BEACH.FAMILY\/FRIENDS.WE''RE GOOD! SUN,FUN!!', 'https://br.bluepillow.com/search/681244711a0d3c624bfea69c?dest=bpex&cat=House&lat=25.78695&lng=-80.1343&language=pt', NULL, NULL, NULL, '0101000020E6100000F3154960980854C0059DB58075C93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:24.095453', '2026-01-14 21:51:52.990274');
INSERT INTO sadie_gtm.hotels VALUES (368, 'Luxury family apartment 2 bedrooms+2.5 baths', 'https://br.bluepillow.com/search/655208c11811a9820ec5796a?dest=ago&cat=Apartment&lat=25.79899&lng=-80.12693&language=pt', NULL, NULL, NULL, '0101000020E6100000FB77D89F1F0854C03C52D8A08ACC3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:03:24.101781', '2026-01-14 21:51:52.998587');
INSERT INTO sadie_gtm.hotels VALUES (334, 'Cozy 2BR Bayview Stay', 'https://booking.staycozy.com/properties/64a89ed08bbc77003547666b', NULL, NULL, NULL, '0101000020E61000008E7AE3FFE90B54C001A5FCFF93CA3940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:10.699665', '2026-01-14 21:52:27.840366');
INSERT INTO sadie_gtm.hotels VALUES (339, 'Cozy Boho 1 Bedroom Apartment', 'https://booking.staycozy.com/properties/64441df3d8006100422632fb', NULL, NULL, NULL, '0101000020E61000008E7AE3FFE90B54C001A5FCFF93CA3940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:10.712933', '2026-01-14 21:52:27.846096');
INSERT INTO sadie_gtm.hotels VALUES (342, 'The Shelborne By Proper', 'https://shelborne.com/?utm_source=local-listings&utm_medium=organic&utm_campaign=local-listings', '(305) 341-1400', NULL, NULL, '0101000020E61000007994A531350854C0A82160634DCB3940', '1801 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.8, NULL, 99, 'grid_region', '2026-01-14 00:03:10.719414', '2026-01-14 21:52:27.850945');
INSERT INTO sadie_gtm.hotels VALUES (343, 'Tradewinds Apartment Hotel', 'https://www.tradewindsapartmenthotel.com/', '(305) 531-6795', NULL, NULL, '0101000020E6100000EC0555594A0854C0D27B197BE5CC3940', '2365 Pine Tree Dr, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.8, NULL, 99, 'grid_region', '2026-01-14 00:03:10.72153', '2026-01-14 21:52:27.85766');
INSERT INTO sadie_gtm.hotels VALUES (345, 'Westgate South Beach Oceanfront Resort', 'https://resort.to/wsbor?y_source=1_OTc1MjI0Mi03MTUtbG9jYXRpb24ud2Vic2l0ZQ%3D%3D', '(305) 532-8831', NULL, NULL, '0101000020E6100000C9A0246EDF0754C0FB4795174FCF3940', '3611 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.1, NULL, 99, 'grid_region', '2026-01-14 00:03:16.645579', '2026-01-14 21:52:27.861589');
INSERT INTO sadie_gtm.hotels VALUES (347, 'Kimpton Hotel Palomar South Beach', 'https://www.hotelpalomar-southbeach.com/?&cm_mmc=WEB-_-KI-_-AMER-_-EN-_-EV-_-Google%20Business%20Profile-_-DD-_-palomar', '(786) 628-2000', NULL, NULL, '0101000020E610000015617946110954C099C640E8EACA3940', '1750 Alton Rd, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4, NULL, 99, 'grid_region', '2026-01-14 00:03:16.662156', '2026-01-14 21:52:27.869569');
INSERT INTO sadie_gtm.hotels VALUES (348, 'Mantell Plaza', 'https://themantellplaza.com/', '(305) 772-5665', NULL, NULL, '0101000020E6100000E6841ACF310854C07DB4931C0BCD3940', '255 W 24th St, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4, NULL, 99, 'grid_region', '2026-01-14 00:03:16.66603', '2026-01-14 21:52:27.873506');
INSERT INTO sadie_gtm.hotels VALUES (350, 'The Claremont Hotel, South Beach', 'https://claremont.miamibeachfl-hotel.com/en/', '(786) 620-2900', NULL, NULL, '0101000020E61000001139D8F6510854C03C5AE6BEE6CA3940', '1700 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.7, NULL, 99, 'grid_region', '2026-01-14 00:03:16.672691', '2026-01-14 21:52:27.877266');
INSERT INTO sadie_gtm.hotels VALUES (351, 'Iberostar Waves Miami Beach', 'https://www.iberostar.com/eu/hotels/miami/iberostar-waves-miami-beach/?utm_source=gmb&utm_medium=organic&utm_campaign=IBSVOL_AME_SEOLOC_GMB_NA_EN_USA_MIA_MIA_NA_PULL_NA_NA_NA_NA_NA', '(786) 697-1333', NULL, NULL, '0101000020E61000006AF40FC75F0854C081559A39C9CB3940', '334 20th St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.1, NULL, 99, 'grid_region', '2026-01-14 00:03:16.675365', '2026-01-14 21:52:27.880865');
INSERT INTO sadie_gtm.hotels VALUES (330, 'Cozy Studio Walk to Beach & Convention Center', 'https://deals.vio.com/?sig=73aca13c7f952d2641c156f3e69125e1eb497c325f122828ee5aa8797168b9a12d32303331333438363233&turl=https%3A%2F%2Fwww.vio.com%2FHotel%2FSearch%3FhotelId%3D77445279%26utm_source%3Dgha-vr%26utm_campaign%3Dstatic%26openHotelDetails%3D1', NULL, NULL, 'partners@vio.com', '0101000020E6100000020CCB9F6F0854C059411DA045CC3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:03:10.688926', '2026-01-14 21:52:27.897056');
INSERT INTO sadie_gtm.hotels VALUES (331, 'Cozy studio, walk to the beach, restaurants, bars', 'https://br.bluepillow.com/search/6626cd8c4338d48a8fcb4594?dest=bkng&cat=Apartment&lat=25.77771&lng=-80.13372&language=pt', NULL, NULL, NULL, '0101000020E6100000B73302E08E0854C0ACC5A70018C73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:10.6912', '2026-01-14 21:52:27.900344');
INSERT INTO sadie_gtm.hotels VALUES (336, 'COZY and CHIC Suite 1 BDR and 1BTH', 'https://deals.vio.com/?sig=73aca13c7f952d2641c156f3e69125e1eb497c325f122828ee5aa8797168b9a12d32303331333438363233&turl=https%3A%2F%2Fwww.vio.com%2FHotel%2FSearch%3FhotelId%3D92147877%26utm_source%3Dgha-vr%26utm_campaign%3Dstatic%26openHotelDetails%3D1', NULL, NULL, 'partners@vio.com', '0101000020E610000031EFCC5F7C0854C08D39741F25C73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:03:10.705959', '2026-01-14 21:52:27.904014');
INSERT INTO sadie_gtm.hotels VALUES (337, 'Cozy studio in Edgewater\/Downtown Miami', 'https://br.bluepillow.com/search/67a4bd90064d51dcdc910736?dest=bpex&cat=Apartment&lat=25.7964&lng=-80.19124&language=pt', NULL, NULL, NULL, '0101000020E6100000526FFC3F3D0C54C0F80780E0E0CB3940', 'Miami, FL 33137', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:10.70853', '2026-01-14 21:52:27.908976');
INSERT INTO sadie_gtm.hotels VALUES (378, 'Red South Beach Hotel', 'https://www.redsouthbeachhotel.com/', '(305) 531-7742', '6287665789', 'info@redsouthbeach.com', '0101000020E6100000AA0029FBF80754C032D5DD8662CE3940', '3010 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.3, NULL, 3, 'grid_region', '2026-01-14 00:03:28.946347', '2026-01-14 23:28:00.958077');
INSERT INTO sadie_gtm.hotels VALUES (382, 'President Hotel South Beach', 'http://www.presidentsouthbeach.com/', '(844) 768-9738', NULL, NULL, '0101000020E610000079FFC46D590854C04336902E36C93940', '1423 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4, NULL, 99, 'grid_region', '2026-01-14 00:03:28.955686', '2026-01-14 21:51:42.780775');
INSERT INTO sadie_gtm.hotels VALUES (384, 'Boutique Apartments SoBe', 'https://www.decolar.com/hoteis/h-6764808', NULL, NULL, NULL, '0101000020E61000007009C03F250954C0BA579C20A0C93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:28.960196', '2026-01-14 21:51:42.78934');
INSERT INTO sadie_gtm.hotels VALUES (390, 'The Setai Ocean Suites', 'http://www.thesetaihotel.com/', '(305) 433-0305', NULL, NULL, '0101000020E61000006EBB75A3340854C00A9A3B9FA6CB3940', '2001 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.6, NULL, 99, 'grid_region', '2026-01-14 00:03:31.873232', '2026-01-14 21:51:42.795637');
INSERT INTO sadie_gtm.hotels VALUES (391, 'PGA VILLAGE RESORT', 'http://pgavillageresort.com/', '(305) 767-2122', NULL, NULL, '0101000020E61000008636001B100954C0BCE4243905CA3940', '1602 Alton Rd #72, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:31.877094', '2026-01-14 21:51:42.803709');
INSERT INTO sadie_gtm.hotels VALUES (392, '1 Hotel Penthouse 2 Story Beachfront Ultra Luxe', 'https://www.caribbeanluxuryrentals.com/1-hotel-penthouse-miami-beach/', '(833) 778-4552', NULL, NULL, '0101000020E6100000F8A41309260854C0B480BF4EA0CC3940', '2341 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 5, NULL, 99, 'grid_region', '2026-01-14 00:03:31.880036', '2026-01-14 21:51:42.808783');
INSERT INTO sadie_gtm.hotels VALUES (397, 'Nightfall Group Miami Villa Rentals & Property Management', 'http://www.nightfallgroup.com/', '(310) 666-7012', NULL, NULL, '0101000020E610000038A85890C10854C012691B7FA2CA3940', '1688 Meridian Ave STE 700, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.9, NULL, 99, 'grid_region', '2026-01-14 00:03:35.043939', '2026-01-14 21:51:42.813963');
INSERT INTO sadie_gtm.hotels VALUES (398, 'Miami Beach Real Estate', 'http://www.miamibeachhomefinder.com/', '(786) 200-3966', NULL, NULL, '0101000020E6100000156F641EF90854C04B0FF91D79CA3940', '1111 Lincoln Rd, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 5, NULL, 99, 'grid_region', '2026-01-14 00:03:35.046797', '2026-01-14 21:51:42.819151');
INSERT INTO sadie_gtm.hotels VALUES (399, 'Agave on the Beach', 'https://www.agaveonthebeach.com/', '(305) 429-6672', NULL, NULL, '0101000020E6100000ECB2A904550854C00CAA0D4E44CB3940', '235 18th St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.9, NULL, 99, 'grid_region', '2026-01-14 00:03:35.049371', '2026-01-14 21:51:42.824284');
INSERT INTO sadie_gtm.hotels VALUES (400, 'Venezia Hotel By At Mine Hospitality', 'https://www.atminehospitality.com/', '(305) 497-7553', NULL, NULL, '0101000020E610000054E41071F30754C0A637ED73C6CF3940', '3865 Indian Creek Dr Suite 100, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.2, NULL, 99, 'grid_region', '2026-01-14 00:03:35.051992', '2026-01-14 21:51:42.82926');
INSERT INTO sadie_gtm.hotels VALUES (380, 'Casa Faena Miami Beach', 'https://www.faena.com/casa-faena?utm_source=google-gbp&utm_medium=organic&utm_campaign=gbp', '(305) 604-8485', '+17866461250', 'reservations-miamibeach@faena.com', '0101000020E610000092CF8657ED0754C05BD141F229CF3940', '3500 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4, NULL, 99, 'grid_region', '2026-01-14 00:03:28.951041', '2026-01-14 21:51:42.849965');
INSERT INTO sadie_gtm.hotels VALUES (387, 'Hotel Boutique 18', 'https://deals.vio.com/?sig=73aca13c7f952d2641c156f3e69125e1eb497c325f122828ee5aa8797168b9a12d32303331333438363233&turl=https%3A%2F%2Fwww.vio.com%2FHotel%2FSearch%3FhotelId%3D2746417%26utm_source%3Dgha-vr%26utm_campaign%3Dstatic%26openHotelDetails%3D1', NULL, NULL, 'partners@vio.com', '0101000020E61000008CD5E6FF550854C0C0D07EFF41CB3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:03:28.973591', '2026-01-14 21:51:42.862337');
INSERT INTO sadie_gtm.hotels VALUES (394, 'Hotel Riu Plaza Miami Beach', 'https://www.riu.com/en/hotel/united-states/miami-beach/hotel-riu-plaza-miami-beach?utm_source=google&utm_medium=organic&utm_campaign=my_business&utm_content=ZMB', '(305) 673-5333', '3056735333', 'hotel.plazamiamibeach@riu.com', '0101000020E61000002E24BB2DEC0754C0E58E482586CE3940', '3101 Collins Ave, Miami, FL 33140', 'Miami', 'FL', 'USA', 4, NULL, 99, 'grid_region', '2026-01-14 00:03:35.027177', '2026-01-14 21:51:42.875321');
INSERT INTO sadie_gtm.hotels VALUES (401, 'Barcelona Studios Guesthouse - Deluxe Double Room #1', 'https://br.bluepillow.com/search/67cab377fa1a57d5a4b131fb/324871919?dest=eps&cat=House&lat=25.78712&lng=-80.13321&language=pt', NULL, '0992961096', 'info@bluepillow.com', '0101000020E6100000AF61E17F860854C05900AEBF80C93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:03:39.427199', '2026-01-14 21:51:42.879071');
INSERT INTO sadie_gtm.hotels VALUES (370, 'Big family apartment in South beach with free parking', 'https://www.decolar.com/hoteis/h-6597012', NULL, NULL, NULL, '0101000020E6100000C9E0CDBF820854C060167F805ACB3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:24.10712', '2026-01-14 21:51:52.926451');
INSERT INTO sadie_gtm.hotels VALUES (376, 'Hotel Trouvail Miami Beach', 'https://www.hoteltrouvailmiamibeach.com/?utm_source=google&utm_medium=organic&utm_campaign=gbp_listing', '(305) 763-8006', NULL, NULL, '0101000020E610000063E47679040854C00171B26895CE3940', '3101 Indian Creek Dr, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:03:28.938332', '2026-01-14 21:51:52.934482');
INSERT INTO sadie_gtm.hotels VALUES (369, '3 Minute Walk to Beach 2 Bedroom Apartment Family Friendly with No Pet Fee', 'https://br.bluepillow.com/search/67a2415b905c444f2d0ad8e1?dest=ago&cat=Vacation+rental+(other)&lat=25.78474&lng=-80.13277&language=pt', NULL, NULL, NULL, '0101000020E6100000DC9FE63F7F0854C0C058DFC0E4C83940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:24.104624', '2026-01-14 21:51:53.002466');
INSERT INTO sadie_gtm.hotels VALUES (371, 'Roami at Hotel Astor - Family Studio, 2 Queen Beds, Non Smoking', 'https://br.bluepillow.com/search/67cab26ffa1a57d5a4b0b4d0/324489822?dest=eps&cat=Apartment&lat=25.78051&lng=-80.13332&language=pt', NULL, NULL, NULL, '0101000020E61000003D72B55F880854C048B42E7FCFC73940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:03:24.109447', '2026-01-14 21:51:53.006801');
INSERT INTO sadie_gtm.hotels VALUES (375, 'Faena Hotel Miami Beach', 'https://www.faena.com/miami-beach?utm_source=google-gbp&utm_medium=organic&utm_campaign=gbp', '(305) 534-8800', '+13055354697', 'reservations-miamibeach@faena.com', '0101000020E6100000BF4F0B14E70754C07C64CE8EAFCE3940', '3201 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.6, NULL, 99, 'grid_region', '2026-01-14 00:03:28.929641', '2026-01-14 21:51:53.020054');
INSERT INTO sadie_gtm.hotels VALUES (418, 'Fontainebleau Miami Beach', 'https://fontainebleau.com/?utm_source=google-local&utm_medium=organic&utm_campaign=gmb', '(800) 548-8886', NULL, NULL, '0101000020E61000001F550383DA0754C0C4735BC75DD13940', '4441 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.1, NULL, 3, 'grid_region', '2026-01-14 00:03:47.636702', '2026-01-14 23:26:31.578525');
INSERT INTO sadie_gtm.hotels VALUES (424, 'Five Star Luxury Travel', 'https://www.fivestarluxurytravel.com/', '(305) 330-6182', NULL, NULL, '0101000020E61000000CA6063F160C54C0118C834BC7CC3940', '350 NE 24th St Suite 101, Miami, FL 33137', 'Miami', 'FL', 'USA', 4.7, NULL, 99, 'grid_region', '2026-01-14 00:03:49.832142', '2026-01-14 21:48:46.226109');
INSERT INTO sadie_gtm.hotels VALUES (425, 'Lunabase Travelstays & Property Management', 'http://lunabase.io/', '(786) 305-4770', NULL, NULL, '0101000020E610000056A824A1E30B54C0B3BC619115CE3940', '2900 NE 7th Ave, Miami, FL 33137', 'Miami', 'FL', 'USA', 5, NULL, 99, 'grid_region', '2026-01-14 00:03:49.835546', '2026-01-14 21:48:46.230494');
INSERT INTO sadie_gtm.hotels VALUES (427, 'Secret Garden Miami Beach', 'http://www.secretgardenmiamibeach.com/', '(786) 275-6434', NULL, NULL, '0101000020E610000045460724E10754C05B34AEC964D03940', '4210 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.2, NULL, 99, 'grid_region', '2026-01-14 00:03:49.841586', '2026-01-14 21:48:46.23443');
INSERT INTO sadie_gtm.hotels VALUES (431, 'Fontainebleau Miami Beach Private Suites', 'http://www.erorentals.com/', '(305) 434-4076', NULL, NULL, '0101000020E6100000EE4E88CAD00754C07A319413EDD03940', '4391 Collins Ave #715, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.6, NULL, 99, 'grid_region', '2026-01-14 00:03:53.470859', '2026-01-14 21:48:46.239955');
INSERT INTO sadie_gtm.hotels VALUES (426, 'Luxury Travel Curators LLC', 'https://www.luxurytravelcurators.com/', '(917) 754-5515', '+19177545515', 'info@luxurytravelcurators.com', '0101000020E61000009C9E1CAA4E0C54C0BB95253ACBCE3940', '3301 NE 1st Ave H805, Miami, FL 33137', 'Miami', 'FL', 'USA', 5, NULL, 98, 'grid_region', '2026-01-14 00:03:49.838793', '2026-01-14 21:48:46.279393');
INSERT INTO sadie_gtm.hotels VALUES (413, 'Lorraine Hotel', 'http://www.lorrainehotel.com/', '(305) 538-7721', NULL, NULL, '0101000020E6100000DB0F1DA70D0854C03D0AD7A370CD3940', '2601 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.7, NULL, 99, 'grid_region', '2026-01-14 00:03:39.45476', '2026-01-14 21:49:09.167047');
INSERT INTO sadie_gtm.hotels VALUES (420, 'Lagniappe', 'http://www.lagniappehouse.com/', '(305) 576-0108', NULL, NULL, '0101000020E6100000FA1E9A1E390C54C085A39A481FCF3940', '3425 NE 2nd Ave, Miami, FL 33137', 'Miami', 'FL', 'USA', 4.7, NULL, 99, 'grid_region', '2026-01-14 00:03:47.648695', '2026-01-14 21:49:09.175244');
INSERT INTO sadie_gtm.hotels VALUES (402, 'Barcelona Studios Guesthouse - Deluxe Double Room #19', 'https://br.bluepillow.com/search/67cab377fa1a57d5a4b131fb/324871944?dest=eps&cat=House&lat=25.78712&lng=-80.13321&language=pt', NULL, NULL, NULL, '0101000020E6100000AF61E17F860854C05900AEBF80C93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:03:39.432188', '2026-01-14 21:49:09.182846');
INSERT INTO sadie_gtm.hotels VALUES (403, 'Barcelona Studios Guesthouse - Deluxe Double Room #5', 'https://br.bluepillow.com/search/67cab377fa1a57d5a4b131fb/324871957?dest=eps&cat=House&lat=25.78712&lng=-80.13321&language=pt', NULL, NULL, NULL, '0101000020E6100000AF61E17F860854C05900AEBF80C93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:03:39.434347', '2026-01-14 21:49:09.190862');
INSERT INTO sadie_gtm.hotels VALUES (404, 'Barcelona Studios Guesthouse', 'https://br.bluepillow.com/search/67cab377fa1a57d5a4b131fb?dest=eps&cat=House&lat=25.78712&lng=-80.13321&language=pt', NULL, '0992961096', 'info@bluepillow.com', '0101000020E6100000AF61E17F860854C05900AEBF80C93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:03:39.437089', '2026-01-14 21:49:09.198174');
INSERT INTO sadie_gtm.hotels VALUES (405, 'Barcelona Studios Guesthouse - Comfort Studio #11', 'https://br.bluepillow.com/search/67cab377fa1a57d5a4b131fb/324871988?dest=eps&cat=House&lat=25.78712&lng=-80.13321&language=pt', NULL, NULL, NULL, '0101000020E6100000AF61E17F860854C05900AEBF80C93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:03:39.439147', '2026-01-14 21:49:09.204608');
INSERT INTO sadie_gtm.hotels VALUES (407, 'Suites Ocean Drive Hotel - Deluxe Double Room with Bath', 'https://br.bluepillow.com/search/65c9fb59671b07d23c6982cc/1096669301?dest=bkng&cat=House&lat=25.78724&lng=-80.12997&language=pt', NULL, NULL, NULL, '0101000020E61000006B84D95F510854C0C022BF7E88C93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:39.443247', '2026-01-14 21:49:09.216458');
INSERT INTO sadie_gtm.hotels VALUES (408, 'Suites Ocean Drive Hotel - Double Room with Balcony', 'https://br.bluepillow.com/search/65c9fb59671b07d23c6982cc/1096669302?dest=bkng&cat=House&lat=25.78724&lng=-80.12997&language=pt', NULL, NULL, NULL, '0101000020E61000006B84D95F510854C0C022BF7E88C93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:39.444924', '2026-01-14 21:49:09.223532');
INSERT INTO sadie_gtm.hotels VALUES (409, 'The Madison South beach Suites - One-Bedroom Apartment', 'https://br.bluepillow.com/search/5eb4555567a9d10d0426565d/628172301?dest=bkng&cat=House&lat=25.80646&lng=-80.12457&language=pt', NULL, NULL, NULL, '0101000020E6100000277E3100F90754C0418D8C1F74CE3940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:03:39.446741', '2026-01-14 21:49:09.230091');
INSERT INTO sadie_gtm.hotels VALUES (410, 'Madison Suite 2 BD\/2BA Miami Beach Lincoln Casa', 'https://br.bluepillow.com/search/68123fa21a0d3c624bfe69a6?dest=bpex&cat=Apartment&lat=25.78835&lng=-80.14857&language=pt', NULL, NULL, NULL, '0101000020E610000088500020820954C0E8D3CF40D1C93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:39.448498', '2026-01-14 21:49:09.23827');
INSERT INTO sadie_gtm.hotels VALUES (411, 'Suites Ocean Drive Hotel', 'https://br.bluepillow.com/search/65c9fb59671b07d23c6982cc?dest=bkng&cat=House&lat=25.78724&lng=-80.12997&language=pt', NULL, NULL, NULL, '0101000020E61000006B84D95F510854C0C022BF7E88C93940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:39.450518', '2026-01-14 21:49:09.245905');
INSERT INTO sadie_gtm.hotels VALUES (412, 'Alden Hotel Miami Beach', 'https://hotelscompany.net/business/alden-hotel-miami-beach-3xalmt', '(786) 456-8710', NULL, NULL, '0101000020E610000011267B3A0D0854C0385849754BCE3940', '2925 Indian Creek Dr, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.5, NULL, 99, 'grid_region', '2026-01-14 00:03:39.452736', '2026-01-14 21:49:09.253368');
INSERT INTO sadie_gtm.hotels VALUES (417, 'Lexington by Hotel RL Miami Beach', 'https://www.sonesta.com/hotel-rl/fl/miami-beach/lexington-hotel-rl-miami-beach?utm_source=google&utm_medium=organic&utm_campaign=gmb', '(305) 673-1513', '3056731513', 'sales@redlion.com', '0101000020E61000001A59E839D80754C072E94E6672D03940', '4299 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.4, NULL, 99, 'grid_region', '2026-01-14 00:03:47.629671', '2026-01-14 21:49:09.270392');
INSERT INTO sadie_gtm.hotels VALUES (421, 'Villatel', 'https://villatel.com/', '(407) 307-2794', '4073072794', 'stay@villatel.com', '0101000020E6100000B7184D78D30C54C035BB4967BBCD3940', 'c/o Villatel, 286 NW 29th St 9th Floor, Miami, FL 33127', 'Miami', 'FL', 'USA', 4.7, NULL, 98, 'grid_region', '2026-01-14 00:03:47.652256', '2026-01-14 21:49:09.288188');
INSERT INTO sadie_gtm.hotels VALUES (442, 'Oasis on the Beach - Beachfront condo with resort amenities', 'https://grandwelcomehollywood.guestybookings.com/properties/680ba7a29575860013cf2c54', NULL, NULL, NULL, '0101000020E61000002389B9FF230854C090AF4EDF7CCC3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 3, 'grid_region', '2026-01-14 00:03:53.49998', '2026-01-14 23:52:20.117988');
INSERT INTO sadie_gtm.hotels VALUES (433, 'FontaineBleau|Beachfront Suite w/ "La Plage" Views', 'https://properties.makrealty.com/properties/659060a952cfea0011328f50', NULL, NULL, NULL, '0101000020E6100000EF2312E0CF0754C0CDFBA47FEED03940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:53.477566', '2026-01-14 21:48:46.249349');
INSERT INTO sadie_gtm.hotels VALUES (434, 'Luxury 1-bedroom Beachfront condo with WiFi, AC in Sounth Miami Beach', 'https://www.decolar.com/hoteis/h-6516927', NULL, NULL, NULL, '0101000020E6100000F7C610001C0854C00F0E51E0F8CB3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:53.480756', '2026-01-14 21:48:46.253845');
INSERT INTO sadie_gtm.hotels VALUES (435, 'Mid-beachfront with direct access to beach', 'https://www.decolar.com/hoteis/h-5809415', NULL, NULL, NULL, '0101000020E610000051723DC0C90754C00AB20A4048D13940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:53.483078', '2026-01-14 21:48:46.260865');
INSERT INTO sadie_gtm.hotels VALUES (437, 'FontaineBleau | Beachfront Bliss', 'https://properties.makrealty.com/properties/64619fb5f6f7fe00431ed0e3', NULL, NULL, NULL, '0101000020E6100000EF2312E0CF0754C0CDFBA47FEED03940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:53.487091', '2026-01-14 21:48:46.268786');
INSERT INTO sadie_gtm.hotels VALUES (441, 'W SOUTH BEACH • 2 BDR/1.5 BATH • BEACHFRONT OCEAN VIEW', 'https://www.decolar.com/hoteis/h-4821757', NULL, NULL, NULL, '0101000020E6100000FF2E22403C0854C0C320FAFF82CC3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:53.497473', '2026-01-14 21:48:46.275196');
INSERT INTO sadie_gtm.hotels VALUES (438, 'Magical 1BR Beachfront Apt In South Beach Miami', 'https://br.bluepillow.com/search/65520b0e1811a9820ec76847?dest=ago&cat=Apartment&lat=25.79878&lng=-80.12718&language=pt', NULL, NULL, NULL, '0101000020E6100000F3A8F8BF230854C090AF4EDF7CCC3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:03:53.489308', '2026-01-14 21:48:46.302304');
INSERT INTO sadie_gtm.hotels VALUES (439, 'Magical 1BR Beachfront Apt In South Beach Miami - King Studio with Sofa Bed', 'https://br.bluepillow.com/search/65c9fb17671b07d23c697e1c/1096182403?dest=bkng&cat=House&lat=25.79878&lng=-80.12719&language=pt', NULL, NULL, NULL, '0101000020E61000000B19D9DF230854C090AF4EDF7CCC3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:03:53.492358', '2026-01-14 21:48:46.305852');
INSERT INTO sadie_gtm.hotels VALUES (440, 'W SOUTH BEACH • 2 BDR\/1.5 BATH • BEACHFRONT OCEAN VIEW', 'https://br.bluepillow.com/search/62df2ee22d760a9969f23845?dest=bpex&cat=Apartment&lat=25.79887&lng=-80.12868&language=pt', NULL, NULL, NULL, '0101000020E6100000FF2E22403C0854C0934039C082CC3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:03:53.495193', '2026-01-14 21:48:46.30944');
INSERT INTO sadie_gtm.hotels VALUES (444, 'Perfect Beachfront Getaway! 3BR\/2Bath, Located at 1Hotel South Beach, 3 Pools!', 'https://br.bluepillow.com/search/67a52244064d51dcdc97d82b?dest=bpex&cat=Apartment&lat=25.79772&lng=-80.12777&language=pt', NULL, NULL, NULL, '0101000020E610000048FB1F602D0854C04FDE115F37CC3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:03:53.504868', '2026-01-14 21:48:46.319165');
INSERT INTO sadie_gtm.hotels VALUES (445, 'FontaineBleau|1BR Panorama: Entire Beachfront View', 'https://properties.makrealty.com/properties/6418b71549fc83002c53a4b2', NULL, NULL, NULL, '0101000020E6100000EF2312E0CF0754C0CDFBA47FEED03940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:03:53.507194', '2026-01-14 21:50:23.795638');
INSERT INTO sadie_gtm.hotels VALUES (448, 'MAK Vacation Rentals', 'https://makvacation.com/', '(305) 204-6049', NULL, NULL, '0101000020E6100000A3ACDF4CCC0754C03CBF83FAF1D03940', '4391 Collins Ave #703, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.9, NULL, 99, 'grid_region', '2026-01-14 00:03:53.514492', '2026-01-14 21:50:23.817599');
INSERT INTO sadie_gtm.hotels VALUES (452, 'Trésor Tower', 'http://www.fontainebleau.com/', '(305) 538-2000', NULL, NULL, '0101000020E6100000E1FC97B5DE0754C07FAC962A07D13940', '4401 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:03:53.522077', '2026-01-14 21:50:23.821454');
INSERT INTO sadie_gtm.hotels VALUES (454, 'Luxury Vacation Rentals at Fontainebleau Miami Beach by LRMB', 'https://www.decolar.com/hoteis/h-6810093', NULL, NULL, NULL, '0101000020E610000090F63FC0DA0754C08CF337A110D13940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:04:00.172968', '2026-01-14 21:50:23.824808');
INSERT INTO sadie_gtm.hotels VALUES (455, '1 Homes Vacation Rentals by LMC - Luxury Condo, 1 Bedroom, Balcony, Partial Ocean View (10L07)', 'https://br.bluepillow.com/search/639a123ad63fe20c76621d46/315644691?dest=eps&cat=Apartment&lat=25.79913&lng=-80.12689&language=pt', NULL, NULL, NULL, '0101000020E6100000BAE70A001F0854C0D2C43BC093CC3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:04:00.180194', '2026-01-14 21:50:23.828174');
INSERT INTO sadie_gtm.hotels VALUES (458, '1 Homes Vacation Rentals by LMC - Deluxe Condo, 1 King Bed with Sofa bed, Non Smoking, Resort View', 'https://br.bluepillow.com/search/639a123ad63fe20c76621d46/316027127?dest=eps&cat=Apartment&lat=25.79913&lng=-80.12689&language=pt', NULL, NULL, NULL, '0101000020E6100000BAE70A001F0854C0D2C43BC093CC3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:04:00.191109', '2026-01-14 21:50:23.835243');
INSERT INTO sadie_gtm.hotels VALUES (459, '1 Homes Vacation Rentals by LMC - Classic Condo, 1 Bedroom, Balcony, Partial Ocean View (10L13)', 'https://br.bluepillow.com/search/639a123ad63fe20c76621d46/219957803?dest=eps&cat=Apartment&lat=25.79913&lng=-80.12689&language=pt', NULL, NULL, NULL, '0101000020E6100000BAE70A001F0854C0D2C43BC093CC3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:04:00.193654', '2026-01-14 21:50:23.839173');
INSERT INTO sadie_gtm.hotels VALUES (460, 'BOULAN HOTEL MIAMI BEACH BY IMD MIAMI VACATION RENTALS 1BR\/1BA UNIT', 'https://br.bluepillow.com/search/65cb82743e6d928972f7902c?dest=bpex&cat=Apartment&lat=25.79637&lng=-80.12932&language=pt', NULL, NULL, NULL, '0101000020E61000008E5143C0460854C05287CBE0DECB3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:04:00.195824', '2026-01-14 21:50:23.843272');
INSERT INTO sadie_gtm.hotels VALUES (462, 'The Retreat Collection at 1 Hotel Homes South Beach - Three Bedroom Homes Ocean View with Balcony', 'https://br.bluepillow.com/search/64633a15a51ab0c4fc3c1140/201320992?dest=eps&cat=Apartment&lat=25.79965&lng=-80.12748&language=pt', NULL, NULL, NULL, '0101000020E61000000F3A32A0280854C0673D21E0B5CC3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:04:00.200608', '2026-01-14 21:50:23.847231');
INSERT INTO sadie_gtm.hotels VALUES (464, 'Oceanfront Private Penthouse at W South Beach -PH2006', 'https://br.bluepillow.com/search/67a233ec905c444f2d043dc9?dest=ago&cat=Vacation+rental+(other)&lat=25.79758&lng=-80.12725&language=pt', NULL, NULL, NULL, '0101000020E610000028B91EE0240854C0B86BAE3F2ECC3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:04:00.205166', '2026-01-14 21:50:23.851546');
INSERT INTO sadie_gtm.hotels VALUES (465, 'The Retreat Collection at 1 Hotel Homes South Beach - Two Bedroom Homes Ocean View with Balcony', 'https://br.bluepillow.com/search/64633a15a51ab0c4fc3c1140/201320989?dest=eps&cat=Apartment&lat=25.79965&lng=-80.12748&language=pt', NULL, NULL, NULL, '0101000020E61000000F3A32A0280854C0673D21E0B5CC3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:04:00.207303', '2026-01-14 21:50:23.855344');
INSERT INTO sadie_gtm.hotels VALUES (466, 'The Retreat Collection at 1 Hotel Homes South Beach - Two Bedroom Homes Skyline View with Balcony', 'https://br.bluepillow.com/search/64633a15a51ab0c4fc3c1140/201320990?dest=eps&cat=Apartment&lat=25.79965&lng=-80.12748&language=pt', NULL, NULL, NULL, '0101000020E61000000F3A32A0280854C0673D21E0B5CC3940', 'Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:04:00.209624', '2026-01-14 21:50:23.859369');
INSERT INTO sadie_gtm.hotels VALUES (506, 'Cozy Studio with pool, steps away from the beach', 'https://beds24.com/booking.php?propid=179236&sr1-best=1&apisource=58&referer=googlehpa', NULL, NULL, NULL, '0101000020E6100000BB511A20070854C063D009A183CE3940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:13.341275', '2026-01-14 21:50:09.552935');
INSERT INTO sadie_gtm.hotels VALUES (507, 'Cozy Apartment MIAMI BEACH, 2min walk to the Beach', 'https://br.bluepillow.com/search/5eb446f567a9d10d042351e5?dest=bkng&cat=House&lat=25.81135&lng=-80.12432&language=pt', NULL, NULL, NULL, '0101000020E61000002F4D11E0F40754C0E51C86A0B4CF3940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:13.343418', '2026-01-14 21:50:09.560436');
INSERT INTO sadie_gtm.hotels VALUES (508, 'Cozy studio in Miami beach', 'https://br.bluepillow.com/search/5df4f6a0e24da45b685d6a8b?dest=bkng&cat=House&lat=25.80664&lng=-80.12548&language=pt', NULL, NULL, NULL, '0101000020E6100000DEB133E0070854C035A094FF7FCE3940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:13.346355', '2026-01-14 21:50:09.568285');
INSERT INTO sadie_gtm.hotels VALUES (475, 'Sorrento Tower', 'https://fontainebleau.com/', '(305) 538-2000', NULL, NULL, '0101000020E61000001AE0DD25CC0754C063DE99BFF8D03940', 'Miami Beach Boardwalk, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:04:02.618846', '2026-01-14 21:50:23.816874');
INSERT INTO sadie_gtm.hotels VALUES (476, 'Notebook Hotel', 'http://www.notebookmiamibeach.com/', '(786) 768-2586', NULL, NULL, '0101000020E61000002B0C361AE50754C007701F5E7CD03940', '216 W 43rd St, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 2.3, NULL, 99, 'grid_region', '2026-01-14 00:04:02.623272', '2026-01-14 21:50:23.836393');
INSERT INTO sadie_gtm.hotels VALUES (478, 'Donna Mare Italian Chophouse', 'https://www.donnamare.com/', '(305) 673-6273', NULL, NULL, '0101000020E61000002EF36789DF0754C0394AB956D6CF3940', '3921 Collins Ave, Miami, FL 33140', 'Miami', 'FL', 'USA', 4.4, NULL, 99, 'grid_region', '2026-01-14 00:04:02.629429', '2026-01-14 21:50:23.840208');
INSERT INTO sadie_gtm.hotels VALUES (479, 'Vida', 'https://www.fontainebleau.com/miamibeach/dining/restaurants/vida/', '(305) 674-4730', NULL, NULL, '0101000020E6100000F70C970BCB0754C0FAB2B45373D13940', '4441 Collins Ave Off Lobby, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.1, NULL, 99, 'grid_region', '2026-01-14 00:04:02.63203', '2026-01-14 21:50:23.844211');
INSERT INTO sadie_gtm.hotels VALUES (480, 'Casa Rosa All Women''s Hostel Miami', 'https://casarosamiami.com/', '(786) 449-6923', NULL, NULL, '0101000020E6100000B0952B17850C54C0D52137C30DD23940', '48th Street &, N Miami Ave, Miami, FL 33127', 'Miami', 'FL', 'USA', 4.2, NULL, 99, 'grid_region', '2026-01-14 00:04:05.153318', '2026-01-14 21:50:23.848303');
INSERT INTO sadie_gtm.hotels VALUES (481, 'Hotel Alamo', 'https://www.atminehospitality.com/', '(305) 497-7553', NULL, NULL, '0101000020E6100000CBCFB293E60754C0EA2A93D04CD03940', '4121 Indian Creek Dr, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.8, NULL, 99, 'grid_region', '2026-01-14 00:04:05.170109', '2026-01-14 21:50:23.852493');
INSERT INTO sadie_gtm.hotels VALUES (483, 'Up Midtown Hotel', 'http://upmidtown.com/', '(305) 571-5115', NULL, NULL, '0101000020E6100000055CA159230C54C0D3F13DC857CF3940', '3530 Biscayne Blvd, Miami, FL 33137', 'Miami', 'FL', 'USA', 3.5, NULL, 99, 'grid_region', '2026-01-14 00:04:05.176791', '2026-01-14 21:50:23.856472');
INSERT INTO sadie_gtm.hotels VALUES (486, 'Seacoast Suites', 'http://www.seacoastsuites.com/', '(305) 865-5152', NULL, NULL, '0101000020E610000057B9066CBD0754C00F875BF404D43940', '5101 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.4, NULL, 99, 'grid_region', '2026-01-14 00:04:05.183718', '2026-01-14 21:50:23.860255');
INSERT INTO sadie_gtm.hotels VALUES (468, 'Eden Roc Miami Beach', 'https://www.edenrochotelmiami.com/?utm_source=google-gbp&utm_medium=organic&utm_campaign=gbp', '(305) 704-7605', NULL, NULL, '0101000020E610000085909845CD0754C079443B5DCCD13940', '4525 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.2, NULL, 99, 'grid_region', '2026-01-14 00:04:00.214532', '2026-01-14 21:50:23.862533');
INSERT INTO sadie_gtm.hotels VALUES (469, 'FountaineBleau Resort, Balcony w/Ocean-Pool Scenic', 'https://properties.makrealty.com/properties/60abc7b12a0bc7002dc3d197', NULL, NULL, NULL, '0101000020E6100000EF2312E0CF0754C0CDFBA47FEED03940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:04:00.217237', '2026-01-14 21:50:23.865816');
INSERT INTO sadie_gtm.hotels VALUES (492, 'Grand Beach Hotel', 'https://www.grandbeachhotel.com/hotels/miami?utm_source=google-local&utm_medium=organic&utm_campaign=gmb_miami_beach', '(305) 538-8666', NULL, NULL, '0101000020E610000030664B56C50754C050267F411CD33940', '4835 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.8, NULL, 99, 'grid_region', '2026-01-14 00:04:10.415901', '2026-01-14 21:50:23.866479');
INSERT INTO sadie_gtm.hotels VALUES (470, 'FontaineBleau | 1BR Resort Oasis w/ Luxe Amenities', 'https://properties.makrealty.com/properties/62831870409f8f00348ed573', NULL, NULL, NULL, '0101000020E6100000D5A425A0D30754C0BCF957A027D13940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:04:00.21977', '2026-01-14 21:50:23.86812');
INSERT INTO sadie_gtm.hotels VALUES (494, 'Bungalow By The Sea', 'https://www.cadillachotelmiamibeach.com/bungalow-by-the-sea', '(305) 538-3373', NULL, NULL, '0101000020E61000000C29F51BDC0754C0E6E44526E0CF3940', '3925 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:04:13.298534', '2026-01-14 21:50:23.86862');
INSERT INTO sadie_gtm.hotels VALUES (471, 'Luxury Oceanfront resort\/condo\/1 Hotel \/ Roney Palace', 'https://br.bluepillow.com/search/62df2f352d760a9969f25895?dest=bpex&cat=Apartment&lat=25.80075&lng=-80.12659&language=pt', NULL, NULL, NULL, '0101000020E610000087E6F0FF190854C0C5BF74FFFDCC3940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:04:00.22228', '2026-01-14 21:50:23.870032');
INSERT INTO sadie_gtm.hotels VALUES (495, 'Cecconi''s Miami', 'https://www.cecconismiamibeach.com/?utm_source=google&utm_medium=organic&utm_campaign=googlemybusiness', '(786) 507-7902', NULL, NULL, '0101000020E610000025DE4B2BCF0754C0DF5D1DB6E3D03940', '4385 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:04:13.301869', '2026-01-14 21:50:23.87049');
INSERT INTO sadie_gtm.hotels VALUES (473, 'FontaineBleau Resort, Full Ocean/Pool/Resort Views', 'https://properties.makrealty.com/properties/62cf2967879a21003567cda6', NULL, NULL, NULL, '0101000020E6100000D5A425A0D30754C0BCF957A027D13940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:04:00.228847', '2026-01-14 21:50:23.872049');
INSERT INTO sadie_gtm.hotels VALUES (496, 'Piola Italian Restaurant Miami Beach', 'https://piolausa.com/locations-miami-mid-beach-fl/', '(786) 803-8825', NULL, NULL, '0101000020E610000038C02731E30754C04510E7E104D03940', '4000 Collins Ave Suite B, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.8, NULL, 99, 'grid_region', '2026-01-14 00:04:13.305109', '2026-01-14 21:50:23.872694');
INSERT INTO sadie_gtm.hotels VALUES (497, 'WunderBar', 'http://www.circa39.com/wunderbar/', '(305) 538-4900', NULL, NULL, '0101000020E610000012375D05E70754C0FF740305DECF3940', '3900 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.6, NULL, 99, 'grid_region', '2026-01-14 00:04:13.308213', '2026-01-14 21:50:24.471823');
INSERT INTO sadie_gtm.hotels VALUES (498, 'Arkadia Grill', 'https://www.fontainebleaumiamibeach.com/dining/restaurants/arkadia-grill/', '(305) 674-4636', NULL, NULL, '0101000020E61000006BE0FDA7D10754C04542001533D13940', '4441 Collins Ave Lower Lobby, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.1, NULL, 99, 'grid_region', '2026-01-14 00:04:13.311475', '2026-01-14 21:50:24.481295');
INSERT INTO sadie_gtm.hotels VALUES (499, 'Pao by Paul Qui', 'https://www.faena.com/miami-beach/dining/pao-by-paul-qui?utm_source=google-gbp&utm_medium=organic&utm_campaign=gbp', '(786) 655-5600', NULL, NULL, '0101000020E6100000CF21BAB1EA0754C0D97FF854A9CE3940', '3201 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.5, NULL, 99, 'grid_region', '2026-01-14 00:04:13.315789', '2026-01-14 21:50:24.491371');
INSERT INTO sadie_gtm.hotels VALUES (500, 'The Tavern - American Restaurant in Miami Beach', 'https://hotelcroydonmiamibeach.com/thetavern/', NULL, NULL, NULL, '0101000020E610000006B7B585E70754C0A7AFE76B96CF3940', '3720 Collins Ave Lobby, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.6, NULL, 99, 'grid_region', '2026-01-14 00:04:13.320098', '2026-01-14 21:50:24.499903');
INSERT INTO sadie_gtm.hotels VALUES (501, 'La Côte', 'https://www.fontainebleau.com/miamibeach/dining/restaurants/la-cote/', '(305) 674-4636', NULL, NULL, '0101000020E6100000AD9E3825C50754C0F65503DE13D13940', '4441 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:04:13.323596', '2026-01-14 21:50:24.507046');
INSERT INTO sadie_gtm.hotels VALUES (503, 'Cozy Apartment near the beach with wifi, full kitchen, shared washer and dryer', 'https://br.bluepillow.com/search/67a4c1c5064d51dcdc932be9?dest=bpex&cat=Apartment&lat=25.80643&lng=-80.12459&language=pt', NULL, NULL, NULL, '0101000020E6100000575EF23FF90754C0B37CB83F72CE3940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:04:13.330688', '2026-01-14 21:50:24.513602');
INSERT INTO sadie_gtm.hotels VALUES (504, 'Cozy 1 bedroom beachside apartment in Miami Beach', 'https://br.bluepillow.com/search/681254861a0d3c624bff7e35?dest=bpex&cat=Apartment&lat=25.81055&lng=-80.12368&language=pt', NULL, NULL, NULL, '0101000020E6100000A02AF05FEA0754C0FA3F2C4080CF3940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:04:13.335535', '2026-01-14 21:50:24.518519');
INSERT INTO sadie_gtm.hotels VALUES (527, 'The Alexander Hotel Miami', 'https://www.alexanderhotel.com/', '(833) 843-2539', '8338432539', 'info@alexanderhotel.com', '0101000020E6100000D1D9136EC30754C01564158090D43940', '5225 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.3, NULL, 3, 'grid_region', '2026-01-14 00:04:28.681228', '2026-01-14 23:43:26.518074');
INSERT INTO sadie_gtm.hotels VALUES (534, 'Hora Vacation Rentals', 'http://www.horarentals.com/', '(305) 209-4672', NULL, NULL, '0101000020E61000001D4EAAC7C70754C01AC7A3AF7BD43940', '5225 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.6, NULL, 99, 'grid_region', '2026-01-14 00:04:28.698858', '2026-01-14 21:49:56.698168');
INSERT INTO sadie_gtm.hotels VALUES (536, 'Castle Beach Suites', 'https://www.castlebeachhotel.com/', '(786) 396-3505', NULL, NULL, '0101000020E610000076FD82DDB00754C02068BBF891D53940', '5445 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.7, NULL, 99, 'grid_region', '2026-01-14 00:04:28.702068', '2026-01-14 21:49:56.702671');
INSERT INTO sadie_gtm.hotels VALUES (537, 'We Own South Beach Concierge', 'http://weownsouthbeach.com/', '(954) 394-9299', NULL, NULL, '0101000020E610000077D66EBB500854C01AD58E8763D03940', '529 W 41st St #444, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 5, NULL, 99, 'grid_region', '2026-01-14 00:04:28.703451', '2026-01-14 21:49:56.706833');
INSERT INTO sadie_gtm.hotels VALUES (539, 'Jules Kitchen, at Circa 39 Hotel', 'http://www.circa39.com/jules-kitchen/', '(305) 538-4900', NULL, NULL, '0101000020E6100000D0FC7B3AE80754C01BAA189DE2CF3940', '3900 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4, NULL, 99, 'grid_region', '2026-01-14 00:04:31.169964', '2026-01-14 21:49:56.710745');
INSERT INTO sadie_gtm.hotels VALUES (540, 'CVS', 'https://www.cvs.com/store-locator/miami-beach-fl-pharmacies/4000-collins-ave-suite-c-miami-beach-fl-33140/storeid=10878?WT.mc_id=LS_GOOGLE_FS_10878', '(305) 341-3639', NULL, NULL, '0101000020E61000007AFA08FCE10754C02F3773A323D03940', '4000 Collins Ave Suite C, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.7, NULL, 99, 'grid_region', '2026-01-14 00:04:31.17334', '2026-01-14 21:49:56.715317');
INSERT INTO sadie_gtm.hotels VALUES (543, 'The Castle Hotel', 'http://miamihotelresort.com/the-castle-hotel/', '(305) 865-6969', NULL, NULL, '0101000020E61000007994A531B50754C0E0980A968FD53940', '5445 Collins Ave Suits CU15, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.2, NULL, 99, 'grid_region', '2026-01-14 00:04:31.182276', '2026-01-14 21:49:56.719584');
INSERT INTO sadie_gtm.hotels VALUES (546, 'SeaStays Miami Beach: Top-Rated Vacation Rentals', 'https://www.seastays.com/', '(786) 396-3505', NULL, NULL, '0101000020E610000021F9EF66B20754C01DBAEA4B80D53940', '5445 Collins Ave CU-9, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.7, NULL, 99, 'grid_region', '2026-01-14 00:04:34.698808', '2026-01-14 21:49:56.723584');
INSERT INTO sadie_gtm.hotels VALUES (548, 'New Point Miami', 'http://newpointmiami.com/', '(305) 397-8952', NULL, NULL, '0101000020E610000021F9EF66B20754C01DBAEA4B80D53940', '5445 Collins Ave Suits CU15, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.5, NULL, 99, 'grid_region', '2026-01-14 00:04:34.707688', '2026-01-14 21:49:56.727475');
INSERT INTO sadie_gtm.hotels VALUES (551, 'Fontainebleau | 1BR Scenic Waterfront', 'https://properties.makrealty.com/properties/6786955d5aa1e4001954c3f1', NULL, NULL, NULL, '0101000020E6100000EF2312E0CF0754C0D8EE1EA0FBD03940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:04:37.615549', '2026-01-14 21:49:56.73145');
INSERT INTO sadie_gtm.hotels VALUES (547, 'Castle Beach club apartments', 'https://castle-beach-club-apartments.hotel10.com.es/', '(786) 575-5222', NULL, NULL, '0101000020E610000063A6FE8BB10754C02221808A99D53940', '5445 Collins Ave, Miami, FL 33140', 'Miami', 'FL', 'USA', 2.3, NULL, 99, 'grid_region', '2026-01-14 00:04:34.703987', '2026-01-14 21:49:56.747495');
INSERT INTO sadie_gtm.hotels VALUES (513, 'Ocean Spray: Junior Bed, Cozy Stay, Sofa Bed & Minutes from the Beach', 'https://www.decolar.com/hoteis/h-6552195', NULL, NULL, NULL, '0101000020E61000008B040940120854C06E6182BF04D13940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:04:13.361698', '2026-01-14 21:50:09.459152');
INSERT INTO sadie_gtm.hotels VALUES (516, 'Miami Beach Resort & Spa', 'http://www.miamibeachresortandspa.com/', '(305) 532-3600', NULL, NULL, '0101000020E61000000EED084CCC0754C019E9A0A6F1D23940', '4833 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 3.7, NULL, 99, 'grid_region', '2026-01-14 00:04:13.371951', '2026-01-14 21:50:09.467722');
INSERT INTO sadie_gtm.hotels VALUES (520, 'Shalimar Motel', 'http://shalimarmotelmiami.com/', '(305) 751-0345', NULL, NULL, '0101000020E61000005C4535DBCB0B54C0A57D18C682D53940', '6200 Biscayne Blvd, Miami, FL 33138', 'Miami', 'FL', 'USA', 3.3, NULL, 99, 'grid_region', '2026-01-14 00:04:25.151202', '2026-01-14 21:50:09.473456');
INSERT INTO sadie_gtm.hotels VALUES (522, 'The New Yorker Miami Hotel', 'http://thenewyorkermiami.com/', '(305) 759-5823', NULL, NULL, '0101000020E610000079895693CC0B54C0F3D5445502D63940', '6500 Biscayne Blvd, Miami, FL 33138', 'Miami', 'FL', 'USA', 3.7, NULL, 99, 'grid_region', '2026-01-14 00:04:25.158472', '2026-01-14 21:50:09.479814');
INSERT INTO sadie_gtm.hotels VALUES (523, 'Boutique Hotel Room 5 Mins from All - 8Z', 'https://www.decolar.com/hoteis/h-5071022', NULL, NULL, NULL, '0101000020E61000008EE733A0DE0B54C0404F5EBFBBD43940', 'Miami, FL 33137', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:04:25.162788', '2026-01-14 21:50:09.486845');
INSERT INTO sadie_gtm.hotels VALUES (524, 'Vive Zen', 'http://zen.vive.miami/', '(786) 282-5914', NULL, NULL, '0101000020E61000007DAAAF53D10B54C0CC199B6736D53940', '575 NE 61st St, Miami, FL 33137', 'Miami', 'FL', 'USA', 4.5, NULL, 99, 'grid_region', '2026-01-14 00:04:25.166438', '2026-01-14 21:50:09.491845');
INSERT INTO sadie_gtm.hotels VALUES (529, 'Luxury Vacation Rental | Miami Beach by MBDV', 'http://www.castlemilk.rentals/', '(347) 244-9996', NULL, NULL, '0101000020E6100000200725CCB40754C0A4839AC69BD53940', '5445 Collins Ave Pavilion 2, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 4.5, NULL, 99, 'grid_region', '2026-01-14 00:04:28.687409', '2026-01-14 21:50:09.501001');
INSERT INTO sadie_gtm.hotels VALUES (530, 'Castle Beach Suites by MiaRentals', 'http://www.miarentals.com/', '(305) 333-6014', NULL, NULL, '0101000020E610000063A6FE8BB10754C02221808A99D53940', '5445 Collins Ave, Miami, FL 33140', 'Miami', 'FL', 'USA', 3, NULL, 99, 'grid_region', '2026-01-14 00:04:28.688699', '2026-01-14 21:50:09.537155');
INSERT INTO sadie_gtm.hotels VALUES (511, 'Cozy studio in Miami beach - Studio Apartment', 'https://br.bluepillow.com/search/5df4f6a0e24da45b685d6a8b/594537501?dest=bkng&cat=House&lat=25.80664&lng=-80.12548&language=pt', NULL, NULL, NULL, '0101000020E6100000DEB133E0070854C035A094FF7FCE3940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:13.353699', '2026-01-14 21:50:09.574674');
INSERT INTO sadie_gtm.hotels VALUES (512, '3-bedroom Cozy Boho Home in Heart of Miami Beach. Big Pool, Jacuzzi, Cold Plunge', 'https://br.bluepillow.com/search/68115d03a74f8eb5bd29bff8?dest=bpex&cat=House&lat=25.81747&lng=-80.13137&language=pt', NULL, NULL, NULL, '0101000020E6100000304AD05F680854C0DCF126BF45D13940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:13.357509', '2026-01-14 21:50:09.584112');
INSERT INTO sadie_gtm.hotels VALUES (514, 'Ocean Spray: Junior Bed, Cozy Stay, Sofa Bed Minutes from the Beach', 'https://br.bluepillow.com/search/6811623ca74f8eb5bd2aefda?dest=bpex&cat=House&lat=25.81647&lng=-80.12611&language=pt', NULL, NULL, NULL, '0101000020E610000073942820120854C0F830202004D13940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:13.365187', '2026-01-14 21:50:09.599865');
INSERT INTO sadie_gtm.hotels VALUES (517, '1505- Downtown Miami Bay View Retreat with 1BR 1BA', 'https://br.bluepillow.com/search/68119c126178c7268f2b0bc6?dest=bkng&cat=Apartment&lat=25.80683&lng=-80.12463&language=pt', NULL, NULL, NULL, '0101000020E61000007ABE0B00FA0754C0B2F2CB608CCE3940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:16.595263', '2026-01-14 21:50:09.60702');
INSERT INTO sadie_gtm.hotels VALUES (518, 'Oceanfront Contemporary Suites', 'https://gabrielalovestotravel.com/seacoast-contemporary-apartments-usa', '(305) 909-7703', NULL, NULL, '0101000020E6100000EA3823EFC10754C0DBAD1BA501D43940', '5101 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 2.4, NULL, 99, 'grid_region', '2026-01-14 00:04:16.602532', '2026-01-14 21:50:09.610756');
INSERT INTO sadie_gtm.hotels VALUES (525, '2 Queen Beds Boutique Hotel', 'https://vive.miami/property/z2z#availability', NULL, NULL, 'sergiober@gmail.com', '0101000020E61000006B84D95FD10B54C0251DE56036D53940', 'Miami, FL 33137', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:04:25.170464', '2026-01-14 21:50:09.61427');
INSERT INTO sadie_gtm.hotels VALUES (38, 'SuCasa Vacay', 'http://www.sucasavacay.com/', '(305) 815-9022', NULL, NULL, '0101000020E6100000D237691A140C54C05E29CB10C7C43940', '485 Brickell Ave, Miami, FL 33131', 'Miami', 'FL', 'USA', 5, NULL, 99, 'grid_region', '2026-01-14 00:01:55.380146', '2026-01-14 21:53:01.93248');
INSERT INTO sadie_gtm.hotels VALUES (565, 'The Vagabond Hotel Miami', 'http://www.thevagabondhotelmiami.com/', '(305) 400-8420', NULL, NULL, '0101000020E61000001072DEFFC70B54C009A0BD9FBFD73940', '7301 Biscayne Blvd, Miami, FL 33138', 'Miami', 'FL', 'USA', 4.5, NULL, 99, 'grid_region', '2026-01-14 00:04:43.124019', '2026-01-14 21:53:07.10427');
INSERT INTO sadie_gtm.hotels VALUES (572, '6080 Design Hotel by Eskape Collection', 'http://6080hotel.com/', '(786) 475-9125', NULL, NULL, '0101000020E61000001B9B1DA9BE0754C0387F130A11D83940', '6080 Collins Ave, Miami Beach, FL 33141', 'Miami Beach', 'FL', 'USA', 3.9, NULL, 99, 'grid_region', '2026-01-14 00:04:43.204585', '2026-01-14 21:53:07.113514');
INSERT INTO sadie_gtm.hotels VALUES (573, 'Roami', 'https://www.roami.com/?&utm_source=Google_Map_Pins&utm_medium=Main_Office&utm_campaign=Miami', '(833) 305-3535', NULL, NULL, '0101000020E61000005E8DA2BD300C54C0E293A9DD0AD63940', '296 NE 67th St, Miami, FL 33138', 'Miami', 'FL', 'USA', 4.6, NULL, 99, 'grid_region', '2026-01-14 00:04:43.206362', '2026-01-14 21:53:07.120167');
INSERT INTO sadie_gtm.hotels VALUES (577, 'Castle Beach Aparth.', 'https://www.castlebeachhotel.com/contact-us', '(786) 396-3505', NULL, NULL, '0101000020E6100000AB9D17DDB00754C092C7783991D53940', '5445 Collins Ave CU-4, Miami, FL 33140', 'Miami', 'FL', 'USA', 4, NULL, 99, 'grid_region', '2026-01-14 00:04:43.212953', '2026-01-14 21:53:07.128789');
INSERT INTO sadie_gtm.hotels VALUES (579, 'Ava Stays', 'https://avastays.com/', '(479) 366-9124', NULL, NULL, '0101000020E6100000C2AEDCC1BE0754C03252EFA99CD43940', '5255 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 1, NULL, 99, 'grid_region', '2026-01-14 00:04:45.5451', '2026-01-14 21:53:07.138922');
INSERT INTO sadie_gtm.hotels VALUES (601, 'Spacious Ocean View Condo in Beachfront Resort 605', 'https://alexanderhotel.holidayfuture.com/listings/190221?googleVR=1&utm_source=google&utm_medium=vacation_rentals', NULL, NULL, 'reservations@alexanderhotel.com', '0101000020E6100000F5503640C40754C08B6E18607AD43940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 3, 'grid_region', '2026-01-14 00:04:51.115417', '2026-01-14 23:44:29.535204');
INSERT INTO sadie_gtm.hotels VALUES (555, 'Pelican Executive Suites', 'https://deals.vio.com/?sig=73aca13c7f952d2641c156f3e69125e1eb497c325f122828ee5aa8797168b9a12d32303331333438363233&turl=https%3A%2F%2Fwww.vio.com%2FHotel%2FSearch%3FhotelId%3D2631290%26utm_source%3Dgha-vr%26utm_campaign%3Dstatic%26openHotelDetails%3D1', NULL, NULL, 'partners@vio.com', '0101000020E61000007D9EF5DFB90754C01CA386808DD53940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:39.625984', '2026-01-14 21:49:56.764109');
INSERT INTO sadie_gtm.hotels VALUES (556, 'Castle Beach Suites by MiaRentals - Deluxe Room, Ocean View', 'https://br.bluepillow.com/search/6463396ba51ab0c4fc3c0b81/201340014?dest=eps&cat=Apartment&lat=25.83411&lng=-80.1208&language=pt', NULL, NULL, NULL, '0101000020E6100000CA1EFC1FBB0754C0BAC1AB4088D53940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:39.629086', '2026-01-14 21:49:56.767679');
INSERT INTO sadie_gtm.hotels VALUES (558, 'Design Suites Miami Beach', 'https://br.bluepillow.com/search/61828ad89e3163a56a27e373?dest=ago&cat=Vacation+rental+(other)&lat=25.83208&lng=-80.12123&language=pt', NULL, NULL, NULL, '0101000020E610000085701640C20754C028A14F3F03D53940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:39.634376', '2026-01-14 21:49:56.770834');
INSERT INTO sadie_gtm.hotels VALUES (559, 'Alexander suites ocean view', 'https://br.bluepillow.com/search/5f0872f4e24da40d207524d7?dest=bkng&cat=Apartment&lat=25.82999&lng=-80.12135&language=pt', NULL, NULL, NULL, '0101000020E6100000F5503640C40754C074FE37407AD43940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:39.637185', '2026-01-14 21:49:56.773919');
INSERT INTO sadie_gtm.hotels VALUES (560, 'Castle Beach Suites by Vacation Media', 'https://br.bluepillow.com/search/61eefdcf113b0ba9fb942499?dest=bkng&cat=Apartment&lat=25.83434&lng=-80.12009&language=pt', NULL, NULL, NULL, '0101000020E6100000D04B2080AF0754C053C5F94097D53940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:39.639681', '2026-01-14 21:53:07.146803');
INSERT INTO sadie_gtm.hotels VALUES (562, 'Fontainebleau Hotel One Bedroom Suite', 'https://br.bluepillow.com/search/6811b7676178c7268f2d02ae?dest=bkng&cat=House&lat=25.81689&lng=-80.12224&language=pt', NULL, NULL, NULL, '0101000020E61000009AD42BC0D20754C03D6766C11FD13940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:39.644692', '2026-01-14 21:53:07.154677');
INSERT INTO sadie_gtm.hotels VALUES (576, 'Townhouse by Zenmotel', 'https://www.oyorooms.com/us/85684?utm_source=Google_gmb_US&utm_medium=Organic&utm_campaign=US_MAI003&latitude=25.84088&longitude=-80.1847&locale=en', NULL, '+13477524172', NULL, '0101000020E610000000BA79F4D00B54C0C14C800640D73940', '7126 Biscayne Blvd, Miami, FL 33138', 'Miami', 'FL', 'USA', 2.8, NULL, 99, 'grid_region', '2026-01-14 00:04:43.211233', '2026-01-14 21:53:07.16719');
INSERT INTO sadie_gtm.hotels VALUES (585, 'Villa Katy, Beachfront property - One-Bedroom Townhouse with Ocean View', 'https://br.bluepillow.com/search/594398417c00cb0e643ca351/72072403?dest=bkng&cat=Villa&lat=25.83409&lng=-80.12054&language=pt', NULL, NULL, NULL, '0101000020E6100000BA7DFBDFB60754C08B7159E086D53940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:51.055796', '2026-01-14 21:53:07.174321');
INSERT INTO sadie_gtm.hotels VALUES (587, 'Serena Miami Beachfront 2 BRS Direct OceanView w Parking', 'https://br.bluepillow.com/search/67a4bd07064d51dcdc90ba54?dest=bpex&cat=Apartment&lat=25.83889&lng=-80.12106&language=pt', NULL, NULL, NULL, '0101000020E6100000F12FDD7FBF0754C02C706880C1D63940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:51.069023', '2026-01-14 21:53:07.184129');
INSERT INTO sadie_gtm.hotels VALUES (588, 'Beachfront Ocean View Condo Beach Service 520', 'https://br.bluepillow.com/search/65520a9c1811a9820ec6f0e8?dest=ago&cat=Apartment&lat=25.82954&lng=-80.12129&language=pt', NULL, NULL, NULL, '0101000020E6100000D7B0F03FC30754C0CA36CBC05CD43940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:51.072111', '2026-01-14 21:53:07.189819');
INSERT INTO sadie_gtm.hotels VALUES (592, 'Villa Katy, Beachfront property - Apartment with Sea View', 'https://br.bluepillow.com/search/594398417c00cb0e643ca351/72072402?dest=bkng&cat=Villa&lat=25.83409&lng=-80.12054&language=pt', NULL, NULL, NULL, '0101000020E6100000BA7DFBDFB60754C08B7159E086D53940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:51.085634', '2026-01-14 21:53:07.195048');
INSERT INTO sadie_gtm.hotels VALUES (594, 'Beachfront Condo w Beach Service 1207', 'https://br.bluepillow.com/search/68e3d9d2f93025efada61f89?dest=nuit&cat=Apartment&lat=25.82999&lng=-80.12135&language=pt', NULL, NULL, NULL, '0101000020E6100000F5503640C40754C074FE37407AD43940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:51.091879', '2026-01-14 21:53:07.205964');
INSERT INTO sadie_gtm.hotels VALUES (595, 'BEACHFRONT 1 bed \/ 2bath CONDO on the beach with TERRACE and oceanview', 'https://br.bluepillow.com/search/65cb569e3e6d928972f565e6?dest=bpex&cat=House&lat=25.83383&lng=-80.12366&language=pt', NULL, NULL, NULL, '0101000020E61000008E7AE3FFE90754C04CED56E075D53940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:51.095923', '2026-01-14 21:53:07.210066');
INSERT INTO sadie_gtm.hotels VALUES (596, 'Beachfront Condo w Beach Service \/1207', 'https://br.bluepillow.com/search/67a10c67827ba4077c7d6789?dest=bpvr&cat=Apartment&lat=25.82999&lng=-80.12135&language=pt', NULL, NULL, NULL, '0101000020E6100000F5503640C40754C074FE37407AD43940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:04:51.099267', '2026-01-14 21:53:07.213797');
INSERT INTO sadie_gtm.hotels VALUES (597, 'Miami Host Vacations', 'https://miami.host.vacations/', NULL, '+13057251368', 'book@miami.host.vacations', '0101000020E6100000033C69E1B20754C0516FFC3F3DD63940', '5601 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 5, NULL, 99, 'grid_region', '2026-01-14 00:04:51.103096', '2026-01-14 21:53:07.216509');
INSERT INTO sadie_gtm.hotels VALUES (39, 'Miami Vacation Rentals-Brickell', 'https://www.miamivacationrentals.com/', '(305) 747-5242', '+16812305340', 'sales@miamivacationrentals.com', '0101000020E61000000B896A00250C54C0798F334DD8C43940', '485 Brickell Ave, Miami, FL 33131', 'Miami', 'FL', 'USA', 4.2, NULL, 3, 'grid_region', '2026-01-14 00:01:55.385554', '2026-01-14 23:30:02.674517');
INSERT INTO sadie_gtm.hotels VALUES (603, 'Luxury Beachfront Condo / Resort / 1415', 'https://alexanderhotel.holidayfuture.com/listings/274633?googleVR=1&utm_source=google&utm_medium=vacation_rentals', NULL, NULL, 'reservations@alexanderhotel.com', '0101000020E6100000F5503640C40754C08B6E18607AD43940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 3, 'grid_region', '2026-01-14 00:04:51.1234', '2026-01-14 23:46:30.940766');
INSERT INTO sadie_gtm.hotels VALUES (33, 'Kimpton EPIC Hotel', 'https://www.epichotel.com/?&cm_mmc=WEB-_-KI-_-AMER-_-EN-_-EV-_-Google%20Business%20Profile-_-DD-_-EPIC', '(305) 424-5226', '8667603742', NULL, '0101000020E610000073F629221E0C54C0675DA3E540C53940', '270 Biscayne Blvd Way, Miami, FL 33131', 'Miami', 'FL', 'USA', 4.3, NULL, 3, 'grid_region', '2026-01-14 00:01:52.628108', '2026-01-14 23:57:53.967683');
INSERT INTO sadie_gtm.hotels VALUES (69, 'South Beach Rooms and Hostel', 'http://236southbeach.com/', '(305) 763-8764', NULL, NULL, '0101000020E610000036EBE7A87E0854C0ABDE2B0483C73940', '236 9th St, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.5, NULL, 99, 'grid_region', '2026-01-14 00:02:07.101543', '2026-01-14 21:52:48.364708');
INSERT INTO sadie_gtm.hotels VALUES (70, 'Hotel at The Harrison Miami Beach', 'http://theharrisonmiamibeach.com/', '(305) 722-3538', NULL, NULL, '0101000020E610000007623486940854C00B1060EC18C63940', '411 Washington Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 2.8, NULL, 99, 'grid_region', '2026-01-14 00:02:07.104375', '2026-01-14 21:52:48.374725');
INSERT INTO sadie_gtm.hotels VALUES (71, 'Villa Italia By At Mine Hospitality', 'https://www.atminehospitality.com/', '(305) 497-7553', NULL, NULL, '0101000020E6100000F7A9CF7A9D0854C063A593B602C63940', '354 Washington Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.4, NULL, 99, 'grid_region', '2026-01-14 00:02:07.107268', '2026-01-14 21:52:48.383496');
INSERT INTO sadie_gtm.hotels VALUES (77, 'Miami Vacation Rentals - Downtown', 'https://www.decolar.com/hoteis/h-5756063', NULL, NULL, NULL, '0101000020E6100000707610E0190C54C03D49152065C73940', 'Miami, FL 33132', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:02:07.124041', '2026-01-14 21:52:48.392453');
INSERT INTO sadie_gtm.hotels VALUES (48, 'Icon Residences by SS Vacation Rentals - 1/1 Premier One Bedroom Ocean View', 'https://br.bluepillow.com/search/594388477c00cb0e64346559/172698802?dest=bkng&cat=Apartment&lat=25.76826&lng=-80.18891&language=pt', NULL, NULL, NULL, '0101000020E6100000DC35D71F170C54C090DB2F9FACC43940', 'Miami, FL 33131', 'Miami', 'FL', 'USA', NULL, NULL, 99, 'grid_region', '2026-01-14 00:01:55.412382', '2026-01-14 21:52:48.401341');
INSERT INTO sadie_gtm.hotels VALUES (53, 'Bentley Beach Club', 'https://www.bentleybeachclub.com/', '(305) 938-4600', '7865104761', 'info@bentleybeachclub.com', '0101000020E610000026A60BB17A0854C0452A8C2D04C53940', '101 Ocean Dr # 101, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.4, NULL, 99, 'grid_region', '2026-01-14 00:01:55.427652', '2026-01-14 21:52:48.409805');
INSERT INTO sadie_gtm.hotels VALUES (29, 'StayHub Airbnb Property Management', 'https://airbnbmanagementmiami.com/', '(786) 796-7217', NULL, NULL, '0101000020E61000003403A61D480C54C02A6EDC627EC23940', '1403 Brickell Ave, Miami, FL 33131', 'Miami', 'FL', 'USA', 5, NULL, 99, 'grid_region', '2026-01-14 00:01:41.497651', '2026-01-14 21:53:01.942409');
INSERT INTO sadie_gtm.hotels VALUES (30, 'Executive Corporate Rental', 'http://www.executivecorporaterental.com/', '(786) 368-4423', NULL, NULL, '0101000020E6100000E07316AC270C54C0F217C45103C33940', '1200 Brickell Bay Dr #104b, Miami, FL 33131', 'Miami', 'FL', 'USA', 3.9, NULL, 99, 'grid_region', '2026-01-14 00:01:41.499533', '2026-01-14 21:53:01.950886');
INSERT INTO sadie_gtm.hotels VALUES (31, 'Gator Bait Wakeboard & Wakesurf School', 'http://www.gatorbaitwakeboard.com/', '(305) 282-5706', NULL, NULL, '0101000020E6100000F803D48A250B54C054CF38C3C3BE3940', '3301 Rickenbacker Cswy, Miami, FL 33149', 'Miami', 'FL', 'USA', 5, NULL, 99, 'grid_region', '2026-01-14 00:01:43.905357', '2026-01-14 21:53:01.960992');
INSERT INTO sadie_gtm.hotels VALUES (34, 'Century Hotel', 'http://www.centurymiamibeach.com/', '(305) 674-8855', NULL, NULL, '0101000020E61000006859F78F850854C05E7F129F3BC53940', '140 Ocean Dr, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 3.6, NULL, 99, 'grid_region', '2026-01-14 00:01:55.355407', '2026-01-14 21:53:01.972076');
INSERT INTO sadie_gtm.hotels VALUES (36, 'Blanc Kara', 'http://www.blanckara.com/', '(786) 216-7205', NULL, NULL, '0101000020E610000017FD570C8D0854C05F5B3FFD67C53940', '205 Collins Ave, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:01:55.367488', '2026-01-14 21:53:01.980641');
INSERT INTO sadie_gtm.hotels VALUES (41, 'Icon Residences by SS Vacation Rentals', 'https://icon-residences.com/', NULL, NULL, NULL, '0101000020E6100000007157AF220C54C0865DCAAFD5C43940', '485 Brickell Ave, Miami, FL 33131', 'Miami', 'FL', 'USA', 3.9, NULL, 99, 'grid_region', '2026-01-14 00:01:55.394232', '2026-01-14 21:53:01.987286');
INSERT INTO sadie_gtm.hotels VALUES (47, 'Stay Vacation Rental Property Management', 'https://vacationrentalmanagementmiami.com/', '(305) 404-3073', NULL, NULL, '0101000020E61000004B659B65600C54C08E379E74C7C33940', '902 S Miami Ave, Miami, FL 33130', 'Miami', 'FL', 'USA', 5, NULL, 99, 'grid_region', '2026-01-14 00:01:55.409834', '2026-01-14 21:53:01.994898');
INSERT INTO sadie_gtm.hotels VALUES (55, 'Fisher Island Club', 'http://www.fisherislandclub.com/', '(800) 537-3708', NULL, NULL, '0101000020E610000039679F22E20854C05FD4491174C33940', '1 Fisher Island Dr, Miami Beach, FL 33109', 'Miami Beach', 'FL', 'USA', 4.7, NULL, 99, 'grid_region', '2026-01-14 00:01:55.433255', '2026-01-14 21:53:01.999798');
INSERT INTO sadie_gtm.hotels VALUES (58, 'Three Tequesta Point Condo', 'http://www.brickellkeymiami.com/three-tequesta-point-condo.htm', '(305) 373-2922', NULL, NULL, '0101000020E6100000CC4AEE0BC30B54C0546EA296E6C43940', '848 Brickell Key Dr # 503, Miami, FL 33131', 'Miami', 'FL', 'USA', 4.7, NULL, 99, 'grid_region', '2026-01-14 00:01:55.439802', '2026-01-14 21:53:02.003412');
INSERT INTO sadie_gtm.hotels VALUES (59, 'The Spa at Mandarin Oriental, Miami', 'https://www.mandarinoriental.com/miami/brickell-key/luxury-spa?htl=MOMIA&kw=MOMIA_spa&eng=google&src=local', '(305) 913-8332', NULL, NULL, '0101000020E6100000FAD170CADC0B54C0C5AA4198DBC33940', '500 Brickell Key Dr, Miami, FL 33131', 'Miami', 'FL', 'USA', 4.3, NULL, 99, 'grid_region', '2026-01-14 00:01:55.442072', '2026-01-14 21:53:02.007376');
INSERT INTO sadie_gtm.hotels VALUES (60, 'The Yacht Club at Portofino', 'http://www.portofinoyachtclub.com/', '(305) 673-4448', NULL, NULL, '0101000020E610000081E5AD5FD50854C0C4526EEC23C53940', '90 Alton Rd, Miami Beach, FL 33139', 'Miami Beach', 'FL', 'USA', 4.6, NULL, 99, 'grid_region', '2026-01-14 00:01:57.818905', '2026-01-14 21:53:02.011772');
INSERT INTO sadie_gtm.hotels VALUES (602, 'Luxury Beachfront Condo \/ Resort \/ 1415', 'https://br.bluepillow.com/search/67a10e80827ba4077c7ed3d0?dest=bpvr&cat=Apartment&lat=25.82999&lng=-80.12135&language=pt', NULL, NULL, NULL, '0101000020E6100000F5503640C40754C074FE37407AD43940', 'Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', NULL, NULL, 98, 'grid_region', '2026-01-14 00:04:51.118071', '2026-01-14 21:53:02.015823');
INSERT INTO sadie_gtm.hotels VALUES (604, 'Eskape Collection', 'https://eskapecollection.com/', '(786) 888-1702', '+17868881702', 'INFO@ESKAPECOLLECTION.COM', '0101000020E61000007A449616BF0754C0BD55325B0DD83940', '6080 Collins Ave, Miami Beach, FL 33140', 'Miami Beach', 'FL', 'USA', 2.5, NULL, 99, 'grid_region', '2026-01-14 00:04:53.444747', '2026-01-14 21:53:02.023506');
INSERT INTO sadie_gtm.hotels VALUES (27, 'Park Place Properties', 'https://parkpl.co/miami', '(786) 833-9714', '7863212226', NULL, '0101000020E61000005C57CC086F0C54C0796462A9E4C23940', '40 SW 13th St UNIT 203, Miami, FL 33130', 'Miami', 'FL', 'USA', 4.9, NULL, 99, 'grid_region', '2026-01-14 00:01:41.493888', '2026-01-14 21:53:02.027858');
INSERT INTO sadie_gtm.hotels VALUES (32, 'Fisher Island Resorts by SS Vacation Rentals', 'https://sshvr.com/', '(305) 351-9860', NULL, NULL, '0101000020E61000003A5C06F7DE0854C0B57A9807FAC13940', '19142 Fisher Island Dr, Miami Beach, FL 33109', 'Miami Beach', 'FL', 'USA', 4.8, NULL, 99, 'grid_region', '2026-01-14 00:01:48.075839', '2026-01-14 21:53:02.031276');
INSERT INTO sadie_gtm.hotels VALUES (40, 'Guestable', 'https://www.guestable.com/miami-vacation-rental-property-management/', '(305) 851-2056', '9548378149', NULL, '0101000020E610000096181582660C54C034C467A153C43940', '78 SW 7th St, Miami, FL 33130', 'Miami', 'FL', 'USA', 4.8, NULL, 99, 'grid_region', '2026-01-14 00:01:55.389928', '2026-01-14 21:53:02.041818');


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: sadie_gtm; Owner: -
--



--
-- Data for Name: geocode_settings; Type: TABLE DATA; Schema: tiger; Owner: -
--



--
-- Data for Name: pagc_gaz; Type: TABLE DATA; Schema: tiger; Owner: -
--



--
-- Data for Name: pagc_lex; Type: TABLE DATA; Schema: tiger; Owner: -
--



--
-- Data for Name: pagc_rules; Type: TABLE DATA; Schema: tiger; Owner: -
--



--
-- Data for Name: topology; Type: TABLE DATA; Schema: topology; Owner: -
--



--
-- Data for Name: layer; Type: TABLE DATA; Schema: topology; Owner: -
--



--
-- Name: booking_engines_id_seq; Type: SEQUENCE SET; Schema: sadie_gtm; Owner: -
--

SELECT pg_catalog.setval('sadie_gtm.booking_engines_id_seq', 126, true);


--
-- Name: detection_errors_id_seq; Type: SEQUENCE SET; Schema: sadie_gtm; Owner: -
--

SELECT pg_catalog.setval('sadie_gtm.detection_errors_id_seq', 327, true);


--
-- Name: existing_customers_id_seq; Type: SEQUENCE SET; Schema: sadie_gtm; Owner: -
--

SELECT pg_catalog.setval('sadie_gtm.existing_customers_id_seq', 60, true);


--
-- Name: hotel_customer_proximity_id_seq; Type: SEQUENCE SET; Schema: sadie_gtm; Owner: -
--

SELECT pg_catalog.setval('sadie_gtm.hotel_customer_proximity_id_seq', 587, true);


--
-- Name: hotel_room_count_id_seq; Type: SEQUENCE SET; Schema: sadie_gtm; Owner: -
--

SELECT pg_catalog.setval('sadie_gtm.hotel_room_count_id_seq', 87, true);


--
-- Name: hotels_id_seq; Type: SEQUENCE SET; Schema: sadie_gtm; Owner: -
--

SELECT pg_catalog.setval('sadie_gtm.hotels_id_seq', 604, true);


--
-- Name: jobs_id_seq; Type: SEQUENCE SET; Schema: sadie_gtm; Owner: -
--

SELECT pg_catalog.setval('sadie_gtm.jobs_id_seq', 1, false);


--
-- Name: topology_id_seq; Type: SEQUENCE SET; Schema: topology; Owner: -
--

SELECT pg_catalog.setval('topology.topology_id_seq', 1, false);


--
-- Name: booking_engines booking_engines_name_key; Type: CONSTRAINT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.booking_engines
    ADD CONSTRAINT booking_engines_name_key UNIQUE (name);


--
-- Name: booking_engines booking_engines_pkey; Type: CONSTRAINT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.booking_engines
    ADD CONSTRAINT booking_engines_pkey PRIMARY KEY (id);


--
-- Name: detection_errors detection_errors_pkey; Type: CONSTRAINT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.detection_errors
    ADD CONSTRAINT detection_errors_pkey PRIMARY KEY (id);


--
-- Name: existing_customers existing_customers_pkey; Type: CONSTRAINT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.existing_customers
    ADD CONSTRAINT existing_customers_pkey PRIMARY KEY (id);


--
-- Name: hotel_booking_engines hotel_booking_engines_pkey; Type: CONSTRAINT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.hotel_booking_engines
    ADD CONSTRAINT hotel_booking_engines_pkey PRIMARY KEY (hotel_id);


--
-- Name: hotel_customer_proximity hotel_customer_proximity_hotel_id_key; Type: CONSTRAINT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.hotel_customer_proximity
    ADD CONSTRAINT hotel_customer_proximity_hotel_id_key UNIQUE (hotel_id);


--
-- Name: hotel_customer_proximity hotel_customer_proximity_pkey; Type: CONSTRAINT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.hotel_customer_proximity
    ADD CONSTRAINT hotel_customer_proximity_pkey PRIMARY KEY (id);


--
-- Name: hotel_room_count hotel_room_count_hotel_id_key; Type: CONSTRAINT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.hotel_room_count
    ADD CONSTRAINT hotel_room_count_hotel_id_key UNIQUE (hotel_id);


--
-- Name: hotel_room_count hotel_room_count_pkey; Type: CONSTRAINT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.hotel_room_count
    ADD CONSTRAINT hotel_room_count_pkey PRIMARY KEY (id);


--
-- Name: hotels hotels_pkey; Type: CONSTRAINT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.hotels
    ADD CONSTRAINT hotels_pkey PRIMARY KEY (id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: idx_detection_errors_created_at; Type: INDEX; Schema: sadie_gtm; Owner: -
--

CREATE INDEX idx_detection_errors_created_at ON sadie_gtm.detection_errors USING btree (created_at);


--
-- Name: idx_detection_errors_error_type; Type: INDEX; Schema: sadie_gtm; Owner: -
--

CREATE INDEX idx_detection_errors_error_type ON sadie_gtm.detection_errors USING btree (error_type);


--
-- Name: idx_detection_errors_hotel_id; Type: INDEX; Schema: sadie_gtm; Owner: -
--

CREATE INDEX idx_detection_errors_hotel_id ON sadie_gtm.detection_errors USING btree (hotel_id);


--
-- Name: idx_existing_customers_city_state; Type: INDEX; Schema: sadie_gtm; Owner: -
--

CREATE INDEX idx_existing_customers_city_state ON sadie_gtm.existing_customers USING btree (city, state);


--
-- Name: idx_existing_customers_location; Type: INDEX; Schema: sadie_gtm; Owner: -
--

CREATE INDEX idx_existing_customers_location ON sadie_gtm.existing_customers USING gist (location);


--
-- Name: idx_hotel_booking_engines_engine_id; Type: INDEX; Schema: sadie_gtm; Owner: -
--

CREATE INDEX idx_hotel_booking_engines_engine_id ON sadie_gtm.hotel_booking_engines USING btree (booking_engine_id);


--
-- Name: idx_hotel_customer_proximity_customer; Type: INDEX; Schema: sadie_gtm; Owner: -
--

CREATE INDEX idx_hotel_customer_proximity_customer ON sadie_gtm.hotel_customer_proximity USING btree (existing_customer_id);


--
-- Name: idx_hotel_customer_proximity_distance; Type: INDEX; Schema: sadie_gtm; Owner: -
--

CREATE INDEX idx_hotel_customer_proximity_distance ON sadie_gtm.hotel_customer_proximity USING btree (distance_km);


--
-- Name: idx_hotel_customer_proximity_hotel; Type: INDEX; Schema: sadie_gtm; Owner: -
--

CREATE INDEX idx_hotel_customer_proximity_hotel ON sadie_gtm.hotel_customer_proximity USING btree (hotel_id);


--
-- Name: idx_hotel_room_count_hotel; Type: INDEX; Schema: sadie_gtm; Owner: -
--

CREATE INDEX idx_hotel_room_count_hotel ON sadie_gtm.hotel_room_count USING btree (hotel_id);


--
-- Name: idx_hotels_city_state; Type: INDEX; Schema: sadie_gtm; Owner: -
--

CREATE INDEX idx_hotels_city_state ON sadie_gtm.hotels USING btree (city, state);


--
-- Name: idx_hotels_location; Type: INDEX; Schema: sadie_gtm; Owner: -
--

CREATE INDEX idx_hotels_location ON sadie_gtm.hotels USING gist (location);


--
-- Name: idx_hotels_name_website_unique; Type: INDEX; Schema: sadie_gtm; Owner: -
--

CREATE UNIQUE INDEX idx_hotels_name_website_unique ON sadie_gtm.hotels USING btree (name, COALESCE(website, ''::text));


--
-- Name: idx_hotels_status; Type: INDEX; Schema: sadie_gtm; Owner: -
--

CREATE INDEX idx_hotels_status ON sadie_gtm.hotels USING btree (status);


--
-- Name: idx_hotels_website; Type: INDEX; Schema: sadie_gtm; Owner: -
--

CREATE INDEX idx_hotels_website ON sadie_gtm.hotels USING btree (website);


--
-- Name: idx_jobs_city_state; Type: INDEX; Schema: sadie_gtm; Owner: -
--

CREATE INDEX idx_jobs_city_state ON sadie_gtm.jobs USING btree (city, state);


--
-- Name: idx_jobs_hotel_id; Type: INDEX; Schema: sadie_gtm; Owner: -
--

CREATE INDEX idx_jobs_hotel_id ON sadie_gtm.jobs USING btree (hotel_id);


--
-- Name: idx_jobs_started_at; Type: INDEX; Schema: sadie_gtm; Owner: -
--

CREATE INDEX idx_jobs_started_at ON sadie_gtm.jobs USING btree (started_at);


--
-- Name: idx_jobs_status; Type: INDEX; Schema: sadie_gtm; Owner: -
--

CREATE INDEX idx_jobs_status ON sadie_gtm.jobs USING btree (status);


--
-- Name: idx_jobs_type; Type: INDEX; Schema: sadie_gtm; Owner: -
--

CREATE INDEX idx_jobs_type ON sadie_gtm.jobs USING btree (job_type);


--
-- Name: hotel_booking_engines hotel_booking_engines_updated_at; Type: TRIGGER; Schema: sadie_gtm; Owner: -
--

CREATE TRIGGER hotel_booking_engines_updated_at BEFORE UPDATE ON sadie_gtm.hotel_booking_engines FOR EACH ROW EXECUTE FUNCTION sadie_gtm.update_updated_at();


--
-- Name: hotels hotels_updated_at; Type: TRIGGER; Schema: sadie_gtm; Owner: -
--

CREATE TRIGGER hotels_updated_at BEFORE UPDATE ON sadie_gtm.hotels FOR EACH ROW EXECUTE FUNCTION sadie_gtm.update_updated_at();


--
-- Name: detection_errors detection_errors_hotel_id_fkey; Type: FK CONSTRAINT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.detection_errors
    ADD CONSTRAINT detection_errors_hotel_id_fkey FOREIGN KEY (hotel_id) REFERENCES sadie_gtm.hotels(id) ON DELETE CASCADE;


--
-- Name: hotel_booking_engines hotel_booking_engines_booking_engine_id_fkey; Type: FK CONSTRAINT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.hotel_booking_engines
    ADD CONSTRAINT hotel_booking_engines_booking_engine_id_fkey FOREIGN KEY (booking_engine_id) REFERENCES sadie_gtm.booking_engines(id);


--
-- Name: hotel_booking_engines hotel_booking_engines_hotel_id_fkey; Type: FK CONSTRAINT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.hotel_booking_engines
    ADD CONSTRAINT hotel_booking_engines_hotel_id_fkey FOREIGN KEY (hotel_id) REFERENCES sadie_gtm.hotels(id) ON DELETE CASCADE;


--
-- Name: hotel_customer_proximity hotel_customer_proximity_existing_customer_id_fkey; Type: FK CONSTRAINT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.hotel_customer_proximity
    ADD CONSTRAINT hotel_customer_proximity_existing_customer_id_fkey FOREIGN KEY (existing_customer_id) REFERENCES sadie_gtm.existing_customers(id);


--
-- Name: hotel_customer_proximity hotel_customer_proximity_hotel_id_fkey; Type: FK CONSTRAINT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.hotel_customer_proximity
    ADD CONSTRAINT hotel_customer_proximity_hotel_id_fkey FOREIGN KEY (hotel_id) REFERENCES sadie_gtm.hotels(id) ON DELETE CASCADE;


--
-- Name: hotel_room_count hotel_room_count_hotel_id_fkey; Type: FK CONSTRAINT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.hotel_room_count
    ADD CONSTRAINT hotel_room_count_hotel_id_fkey FOREIGN KEY (hotel_id) REFERENCES sadie_gtm.hotels(id) ON DELETE CASCADE;


--
-- Name: jobs jobs_hotel_id_fkey; Type: FK CONSTRAINT; Schema: sadie_gtm; Owner: -
--

ALTER TABLE ONLY sadie_gtm.jobs
    ADD CONSTRAINT jobs_hotel_id_fkey FOREIGN KEY (hotel_id) REFERENCES sadie_gtm.hotels(id);


--
-- PostgreSQL database dump complete
--

\unrestrict XMiysYtN5Zl2vfFue7344qVhQRiWkvS98UEQVHAGhc1b8iIyCCFiTBxHuhrtQeG

