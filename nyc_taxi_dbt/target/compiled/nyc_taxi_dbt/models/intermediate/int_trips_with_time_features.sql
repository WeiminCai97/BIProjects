-- =============================================================
--  models/intermediate/int_trips_with_time_features.sql
--
--  WHAT THIS MODEL DOES:
--  Takes the clean staging data and adds time-based columns that
--  multiple mart models will need. Instead of repeating this logic
--  in every mart, we write it once here.
--
--  New columns added:
--    pickup_hour     → 0 to 23
--    day_of_week     → 0 (Sunday) to 6 (Saturday)
--    day_name        → "Monday", "Tuesday", etc.
--    pickup_date     → just the date, no time (e.g. 2024-01-15)
--    time_of_day     → "Morning Rush", "Evening Rush", "Midday", etc.
--    is_weekend      → true / false
--
-- =============================================================

with trips as (

    -- ref() references upstream models
    -- dbt automatically figures out the order to build models
    select * from "nyc_taxi"."main_staging"."stg_yellow_taxi_trips"

),

time_features as (

    select

        -- ── All columns from staging ──────────────────────────
        *,

        -- ── Hour of pickup (0 = midnight, 23 = 11pm) ─────────
        extract(hour from pickup_at)            as pickup_hour,

        -- ── Day of week (0 = Sunday, 6 = Saturday) ───────────
        extract(dow from pickup_at)             as day_of_week,

        -- ── Human-readable day name ───────────────────────────
        dayname(pickup_at)                      as day_name,

        -- ── Date only — useful for daily GROUP BY queries ─────
        pickup_at::date                         as pickup_date,

        -- ── Time-of-day bucket ────────────────────────────────
        -- This classifies each trip into a named period
        case
            when extract(hour from pickup_at) between 7  and 9  then 'Morning Rush'
            when extract(hour from pickup_at) between 16 and 19 then 'Evening Rush'
            when extract(hour from pickup_at) between 10 and 15 then 'Midday'
            when extract(hour from pickup_at) between 20 and 23 then 'Night'
            else                                                      'Early Morning'
        end                                     as time_of_day,

        -- ── Weekend flag ──────────────────────────────────────
        -- In DuckDB, dow: 0 = Sunday, 6 = Saturday
        case
            when extract(dow from pickup_at) in (0, 6) then true
            else false
        end                                     as is_weekend

    from trips

)

select * from time_features