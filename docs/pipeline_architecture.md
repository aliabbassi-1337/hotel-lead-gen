# Sadie Pipeline Architecture

## Complete Flow Diagram

```mermaid
flowchart TB
    subgraph LOCAL["🖥️ LOCAL MAC"]
        direction TB

        subgraph SCRAPING["Phase 1: Scraping"]
            direction LR
            OSM[("OSM API<br/>Overpass")]
            SERPER[("Serper API<br/>Google Maps")]

            OSM_SCRIPT["sadie_scraper_osm.py"]
            SERPER_SCRIPT["sadie_scraper_serper.py"]
            ZIP_SCRIPT["sadie_scraper_zipcode.py"]

            OSM --> OSM_SCRIPT
            SERPER --> SERPER_SCRIPT
            SERPER --> ZIP_SCRIPT
        end

        subgraph SCRAPER_OUTPUT["scraper_output/florida/"]
            direction LR
            MIAMI_CSV["miami.csv"]
            TAMPA_CSV["tampa.csv"]
            ORLANDO_CSV["orlando.csv"]
            OTHER_CSV["...22 cities"]
        end

        OSM_SCRIPT --> SCRAPER_OUTPUT
        SERPER_SCRIPT --> SCRAPER_OUTPUT
        ZIP_SCRIPT --> SCRAPER_OUTPUT

        SYNC_UP["sync_to_s3.sh<br/>📤 Upload"]
    end

    SCRAPER_OUTPUT --> SYNC_UP

    subgraph S3["☁️ AWS S3 - sadie-pipeline"]
        direction TB
        S3_INPUT["📁 input/florida/<br/>├── miami.csv<br/>├── tampa.csv<br/>└── ..."]
        S3_OUTPUT["📁 output/florida/<br/>├── miami_leads.csv<br/>├── tampa_leads.csv<br/>└── ..."]
    end

    SYNC_UP -->|"aws s3 sync"| S3_INPUT

    subgraph EC2["⚡ AWS EC2 - c6i.2xlarge"]
        direction TB

        subgraph DOWNLOAD["Step 1: Download"]
            EC2_DOWNLOAD["Download from S3<br/>→ /tmp/input/"]
        end

        subgraph DETECTOR["Step 2: Detection (Parallel)"]
            direction TB

            subgraph WORKER_POOL["Worker Pool (--concurrency 20)"]
                W1["Worker 1"]
                W2["Worker 2"]
                W3["Worker 3"]
                WN["Worker N..."]
            end

            subgraph PER_HOTEL["Per Hotel Processing"]
                direction TB
                LOAD["1. Load Homepage<br/>playwright goto()"]
                CONTACTS["2. Extract Contacts<br/>phone, email, rooms"]
                HTML_SCAN["3. Scan HTML<br/>for engine patterns"]
                BUTTON["4. Find Book Button<br/>JS evaluate"]
                CLICK["5. Click & Navigate<br/>capture network"]
                ANALYZE["6. Analyze Booking Page<br/>detect engine"]
                FALLBACK["7. Fallbacks<br/>iframe, network, HTML"]
            end

            LOAD --> CONTACTS --> HTML_SCAN --> BUTTON --> CLICK --> ANALYZE --> FALLBACK
        end

        subgraph LOCAL_SAVE["Step 3: Local Checkpoint"]
            EC2_LOCAL["💾 /tmp/output/<br/>Incremental saves<br/>every 5 hotels"]
        end

        subgraph UPLOAD["Step 4: Upload"]
            EC2_UPLOAD["Upload to S3<br/>final results"]
        end

        EC2_DOWNLOAD --> DETECTOR
        DETECTOR --> LOCAL_SAVE
        LOCAL_SAVE --> EC2_UPLOAD
    end

    S3_INPUT -->|"boto3 download"| EC2_DOWNLOAD
    EC2_UPLOAD -->|"boto3 upload"| S3_OUTPUT

    subgraph LOCAL_POST["🖥️ LOCAL MAC - Post-processing"]
        direction TB

        SYNC_DOWN["sync_from_s3.sh<br/>📥 Download"]

        subgraph POSTPROCESS["Phase 3: Post-processing"]
            direction TB
            DEDUPE["sadie_dedupe.py<br/>Remove duplicates"]
            SPLIT["sadie_split_by_city.py<br/>Split by coordinates"]
            ENRICH["sadie_room_enricher_llm.py<br/>Enrich room counts"]
            EXCEL["sadie_excel_export.py<br/>Generate Excel"]
        end

        subgraph FINAL_OUTPUT["detector_output/florida/"]
            LEADS_CSV["florida_leads.csv"]
            CITY_CSVS["city/*.csv"]
            EXCEL_FILE["florida_leads.xlsx"]
        end

        ONEDRIVE["☁️ OneDrive<br/>sync_to_onedrive.sh"]
    end

    S3_OUTPUT -->|"aws s3 sync"| SYNC_DOWN
    SYNC_DOWN --> DEDUPE
    DEDUPE --> SPLIT --> ENRICH --> EXCEL
    EXCEL --> FINAL_OUTPUT
    FINAL_OUTPUT --> ONEDRIVE
```

## Detailed Detection Flow (Per Hotel)

```mermaid
flowchart TB
    START([Hotel Input<br/>name, website, phone])

    START --> NORMALIZE["Normalize URL<br/>add https://"]

    NORMALIZE --> SKIP_CHECK{"Skip?<br/>Chain/Junk?"}
    SKIP_CHECK -->|"marriott.com<br/>facebook.com"| SKIP_END([Skip - No Output])

    SKIP_CHECK -->|Valid| GOTO["playwright.goto()<br/>timeout: 30s<br/>wait: domcontentloaded"]

    GOTO --> GOTO_FAIL{Timeout?}
    GOTO_FAIL -->|Yes| FALLBACK_GOTO["Retry with<br/>wait: commit"]
    FALLBACK_GOTO --> EXTRACT
    GOTO_FAIL -->|No| EXTRACT

    EXTRACT["Extract Contacts<br/>• Phone (regex)<br/>• Email (regex)<br/>• Room count"]

    EXTRACT --> STAGE0["STAGE 0: HTML Scan<br/>Search for engine<br/>patterns in HTML"]

    STAGE0 --> STAGE0_FOUND{Engine<br/>Found?}
    STAGE0_FOUND -->|Yes| GET_BOOKING_URL["Get booking URL<br/>from href/iframe"]
    STAGE0_FOUND -->|No| STAGE1

    GET_BOOKING_URL --> DONE

    STAGE1["STAGE 1: Button Click<br/>Find 'Book Now' button"]

    STAGE1 --> FIND_BUTTON["JS Evaluate:<br/>• Known engine hrefs (P0)<br/>• External domains (P1)<br/>• 'Book Now' text (P2-4)"]

    FIND_BUTTON --> BUTTON_FOUND{Button<br/>Found?}
    BUTTON_FOUND -->|No| NETWORK_FALLBACK

    BUTTON_FOUND -->|Yes| HAS_HREF{Has href?}
    HAS_HREF -->|Yes| USE_HREF["Use href directly<br/>as booking URL"]
    HAS_HREF -->|No| CLICK_BUTTON["Click button<br/>capture network"]

    CLICK_BUTTON --> POPUP{Popup<br/>opened?}
    POPUP -->|Yes| POPUP_URL["Get popup URL"]
    POPUP -->|No| NAV_CHECK{Page<br/>navigated?}
    NAV_CHECK -->|Yes| NAV_URL["Get new URL"]
    NAV_CHECK -->|No| WIDGET["Widget mode<br/>check network requests"]

    USE_HREF --> ANALYZE_URL
    POPUP_URL --> ANALYZE_URL
    NAV_URL --> ANALYZE_URL
    WIDGET --> ANALYZE_URL

    ANALYZE_URL["Analyze Booking URL<br/>• Match ENGINE_PATTERNS<br/>• Check domain<br/>• Network sniff"]

    ANALYZE_URL --> ENGINE_FOUND{Engine<br/>Detected?}
    ENGINE_FOUND -->|Yes| DONE
    ENGINE_FOUND -->|No| NETWORK_FALLBACK

    NETWORK_FALLBACK["FALLBACK: Network<br/>Check homepage requests<br/>for engine domains"]

    NETWORK_FALLBACK --> NET_FOUND{Found?}
    NET_FOUND -->|Yes| DONE
    NET_FOUND -->|No| IFRAME_FALLBACK

    IFRAME_FALLBACK["FALLBACK: Iframes<br/>Scan iframe src URLs"]

    IFRAME_FALLBACK --> IFRAME_FOUND{Found?}
    IFRAME_FOUND -->|Yes| DONE
    IFRAME_FOUND -->|No| HTML_FALLBACK

    HTML_FALLBACK["FALLBACK: HTML Keywords<br/>cloudbeds, mews, synxis..."]

    HTML_FALLBACK --> DONE

    DONE([Output Result<br/>• booking_url<br/>• booking_engine<br/>• detection_method<br/>• contacts])
```

## Engine Detection Patterns

```mermaid
flowchart LR
    subgraph INPUT["Input URL/HTML"]
        URL["booking URL"]
        HTML["page HTML"]
        NET["network requests"]
    end

    subgraph PATTERNS["ENGINE_PATTERNS (188 engines)"]
        direction TB
        P1["Cloudbeds: cloudbeds.com"]
        P2["Mews: mews.com, mews.li"]
        P3["SynXis: synxis.com, travelclick.com"]
        P4["Little Hotelier: littlehotelier.com"]
        P5["...180+ more"]
    end

    subgraph METHODS["Detection Methods"]
        M1["url_pattern_match"]
        M2["url_domain_match"]
        M3["network_sniff"]
        M4["iframe_scan"]
        M5["html_keyword"]
        M6["homepage_html_scan"]
    end

    URL --> PATTERNS
    HTML --> PATTERNS
    NET --> PATTERNS

    PATTERNS --> METHODS

    METHODS --> OUTPUT["booking_engine:<br/>Cloudbeds, Mews, etc."]
```

## Parallel Scaling on EC2

```mermaid
flowchart TB
    subgraph S3_IN["S3 Input"]
        INPUT["florida_hotels.csv<br/>10,000 hotels"]
    end

    subgraph EC2_CLUSTER["EC2 Scaling Options"]
        direction TB

        subgraph OPT1["Option 1: Single Large Instance"]
            SINGLE["c6i.4xlarge<br/>16 vCPU, 32GB<br/>--concurrency 40"]
            SINGLE_RATE["~4,000 hotels/hr"]
        end

        subgraph OPT2["Option 2: Multiple Instances"]
            direction LR
            I1["Instance 1<br/>--chunk 1/5"]
            I2["Instance 2<br/>--chunk 2/5"]
            I3["Instance 3<br/>--chunk 3/5"]
            I4["Instance 4<br/>--chunk 4/5"]
            I5["Instance 5<br/>--chunk 5/5"]
            MULTI_RATE["~10,000 hotels/hr"]
        end
    end

    INPUT --> OPT1
    INPUT --> OPT2

    subgraph S3_OUT["S3 Output"]
        OUT1["chunk_1_leads.csv"]
        OUT2["chunk_2_leads.csv"]
        OUT3["chunk_3_leads.csv"]
        MERGED["florida_leads.csv<br/>(merged)"]
    end

    OPT1 --> MERGED
    I1 --> OUT1
    I2 --> OUT2
    I3 --> OUT3
    OUT1 --> MERGED
    OUT2 --> MERGED
    OUT3 --> MERGED
```

## File Structure

```
sadie_gtm/
├── scripts/
│   ├── scrapers/
│   │   ├── osm.py              # OpenStreetMap scraper
│   │   ├── serper.py           # Google Maps via Serper
│   │   └── zipcode.py          # Zipcode-based scraper
│   ├── pipeline/
│   │   ├── detect.py           # Main detector (this doc)
│   │   ├── postprocess.py      # Dedupe, clean
│   │   └── export_excel.py     # Excel export
│   └── utils/
│       ├── dedupe.py
│       ├── split_by_city.py
│       └── room_enricher_llm.py
├── scraper_output/
│   └── florida/
│       ├── miami.csv
│       ├── tampa.csv
│       └── ...
├── detector_output/
│   └── florida/
│       ├── florida_leads.csv
│       └── city/
│           ├── miami.csv
│           └── ...
├── sync_to_s3.sh               # Upload to S3
├── sync_from_s3.sh             # Download from S3
└── run_pipeline.sh             # Full local pipeline
```
