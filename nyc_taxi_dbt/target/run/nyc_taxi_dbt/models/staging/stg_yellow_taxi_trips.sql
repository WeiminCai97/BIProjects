
  
  create view "nyc_taxi"."main_staging"."stg_yellow_taxi_trips__dbt_tmp" as (
    -- =============================================================
--  models/staging/stg_yellow_taxi_trips.sql
--
--  WHAT THIS MODEL DOES:
--  This is the "cleaning station." It reads from the raw source
--  table and does four things:
--    1. Renames ugly column names to readable ones
--    2. Filters out bad/corrupt rows (impossible values)
--    3. Deduplicates rows that are exact copies in the raw data
--    4. Creates a unique ID (trip_id) for each row
--
--  WHY DEDUPLICATION IS NEEDED:
--  The NYC TLC raw data sometimes contains duplicate records
--  where the same trip is submitted twice by the vendor.
--  ROW_NUMBER() keeps exactly one copy of each duplicate group.
--
--  WHY payment_type filter is needed:
--  The raw data contains payment_type = 0 which is not in the
--  official TLC data dictionary. We filter it out here.
--
--  Every model downstream reads from THIS model — never from raw.
--  Materialized as: VIEW (no storage used, always up to date)
-- =============================================================

with source as (

    -- source()  is dbt syntax — it points to the table
    -- registered in sources.yml and tracks lineage automatically
    select * from "nyc_taxi"."raw"."yellow_taxi_trips"

),

filtered as (

    -- Apply all row-level filters BEFORE deduplication
    -- so we are only deduplicating valid rows
    select *
    from source
    where
        -- Remove rows where the trip clearly didn't happen
        trip_distance  > 0
        and fare_amount   > 0
        and total_amount  > 0

        -- Remove rows where dropoff is before pickup (data error)
        and tpep_pickup_datetime < tpep_dropoff_datetime

        -- Remove undocumented payment_type = 0 (not in TLC data dictionary)
        and payment_type in (1, 2, 3, 4, 5, 6)

        -- Keep only data from the month we loaded
        -- (Update these dates if you load a different month)
        and tpep_pickup_datetime >= '2024-01-01'
        and tpep_pickup_datetime <  '2024-02-01'

),

deduplicated as (

    -- ROW_NUMBER() assigns a number to each row within each
    -- group of identical trips. The first row gets 1, the second
    -- gets 2, etc. We then keep only row_num = 1 below.
    --
    -- PARTITION BY = "group rows by these columns"
    -- ORDER BY fare_amount DESC = "within each group, prefer the
    -- row with the higher fare" (picks the more complete record)
    select
        *,
        row_number() over (
            partition by
                VendorID,
                tpep_pickup_datetime,
                tpep_dropoff_datetime,
                PULocationID,
                DOLocationID
            order by fare_amount desc
        ) as row_num

    from filtered

),

cleaned as (

    select

        -- ── Unique trip identifier ────────────────────────────
        -- generate_surrogate_key() hashes these columns together
        -- to create a unique ID. Duplicates are already removed
        -- above so this is now guaranteed to be unique.
        md5(cast(coalesce(cast(VendorID as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(tpep_pickup_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(tpep_dropoff_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(PULocationID as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(DOLocationID as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as trip_id,

        -- ── Vendor ────────────────────────────────────────────
        VendorID                            as vendor_id,

        -- ── Timestamps ────────────────────────────────────────
        tpep_pickup_datetime                as pickup_at,
        tpep_dropoff_datetime               as dropoff_at,

        -- ── Trip details ──────────────────────────────────────
        passenger_count,
        trip_distance,
        RatecodeID                          as rate_code_id,
        PULocationID                        as pickup_location_id,
        DOLocationID                        as dropoff_location_id,

        -- ── Payment ───────────────────────────────────────────
        payment_type,
        fare_amount,
        extra,
        mta_tax,
        tip_amount,
        tolls_amount,
        improvement_surcharge,
        total_amount,
        congestion_surcharge,

        -- ── Derived column: trip duration in minutes ──────────
        -- date_diff is a DuckDB function
        date_diff('minute', tpep_pickup_datetime, tpep_dropoff_datetime)
            as trip_duration_minutes

    from deduplicated

    -- Keep only the first row from each duplicate group
    where row_num = 1

)

select * from cleaned
  );
