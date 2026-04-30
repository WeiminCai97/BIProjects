-- =============================================================
--  models/intermediate/int_trip_revenue_metrics.sql
--
--  WHAT THIS MODEL DOES:
--  Calculates money and fare-related metrics for every trip.
--  Multiple mart models need these calculations — writing them
--  here once prevents copy-pasting the same CASE statements
--  across multiple files.
--
--  New columns added:
--    tip_percentage    → tip as a % of the base fare
--    revenue_per_mile  → total amount ÷ trip distance
--    revenue_per_min   → total amount ÷ trip duration
--    payment_label     → "Credit Card" instead of the number 1
--    tip_tier          → "No Tip", "Low", "Medium", "High"
--    fare_bucket       → fare grouped into $5 ranges
--
-- =============================================================

with trips as (
    -- ref() references upstream models
    -- dbt automatically figures out the order to build models
    select * from "nyc_taxi"."main_staging"."stg_yellow_taxi_trips"

),

revenue_metrics as (

    select

        -- ── All columns from staging ──────────────────────────
        *,

        -- ── Tip percentage ────────────────────────────────────
        -- How much did the passenger tip relative to the base fare?
        case
            when fare_amount > 0
            then round((tip_amount / fare_amount) * 100, 2)
            else 0
        end                                     as tip_percentage,

        -- ── Revenue per mile ──────────────────────────────────
        -- Useful for comparing efficiency of short vs long trips
        case
            when trip_distance > 0
            then round(total_amount / trip_distance, 2)
            else null
        end                                     as revenue_per_mile,

        -- ── Revenue per minute ────────────────────────────────
        case
            when trip_duration_minutes > 0
            then round(total_amount / trip_duration_minutes, 2)
            else null
        end                                     as revenue_per_minute,

        -- ── Payment label ─────────────────────────────────────
        -- Turns the integer code into a readable string
        case payment_type
            when 1 then 'Credit Card'
            when 2 then 'Cash'
            when 3 then 'No Charge'
            when 4 then 'Dispute'
            else        'Unknown'
        end                                     as payment_label,

        -- ── Tip tier ──────────────────────────────────────────
        -- Buckets trips by how much was tipped
        case
            when tip_amount = 0              then 'No Tip'
            when tip_amount < 2              then 'Low  (under $2)'
            when tip_amount between 2 and 5  then 'Medium ($2–$5)'
            else                                  'High (over $5)'
        end                                     as tip_tier,

        -- ── Fare bucket ───────────────────────────────────────
        -- Groups base fares into $5/$10 ranges
        case
            when fare_amount < 5             then '$0–$5'
            when fare_amount < 10            then '$5–$10'
            when fare_amount < 20            then '$10–$20'
            when fare_amount < 30            then '$20–$30'
            else                                  '$30+'
        end                                     as fare_bucket

    from trips

)

select * from revenue_metrics