-- =============================================================
--  models/marts/mart_daily_trip_summary.sql
--
--  WHAT THIS MODEL DOES:
--  Aggregates millions of individual trip rows into one row
--  per day per payment type. This is the table a manager or
--  BI dashboard would query to answer questions like:
--    - "How much revenue did we make on January 15th?"
--    - "Do credit card users spend more than cash users?"
--    - "Which days of the week are busiest?"
--
--  Materialized as: TABLE (a real table in the database)
--  Downstream use: Tableau, Power BI, Metabase, Looker, etc.
-- =============================================================

with time_data as (

    select * from "nyc_taxi"."main_intermediate"."int_trips_with_time_features"

),

revenue_data as (

    select
        trip_id,
        payment_label,
        total_amount,
        tip_amount,
        fare_amount,
        revenue_per_mile
    from "nyc_taxi"."main_intermediate"."int_trip_revenue_metrics"

),

-- Join the two intermediate models together on trip_id
joined as (

    select
        t.trip_id,
        t.pickup_date,
        t.day_name,
        t.is_weekend,
        t.trip_distance,
        t.trip_duration_minutes,
        r.payment_label,
        r.total_amount,
        r.tip_amount,
        r.fare_amount,
        r.revenue_per_mile

    from time_data t
    inner join revenue_data r on t.trip_id = r.trip_id

),

-- Aggregate to one row per day per payment type
daily_summary as (

    select

        -- ── Dimensions (what we're grouping by) ───────────────
        pickup_date,
        day_name,
        is_weekend,
        payment_label,

        -- ── Trip volume ───────────────────────────────────────
        count(*)                                        as total_trips,

        -- ── Revenue metrics ───────────────────────────────────
        round(sum(total_amount),  2)                    as total_revenue,
        round(avg(total_amount),  2)                    as avg_fare_per_trip,
        round(avg(tip_amount),    2)                    as avg_tip_amount,

        -- Overall tip rate for this day/payment group
        round(
            sum(tip_amount) / nullif(sum(fare_amount), 0) * 100,
        2)                                              as tip_rate_pct,

        -- ── Trip characteristics ──────────────────────────────
        round(avg(trip_distance),          2)           as avg_distance_miles,
        round(avg(trip_duration_minutes),  1)           as avg_duration_minutes,
        round(avg(revenue_per_mile),       2)           as avg_revenue_per_mile

    from joined
    group by
        pickup_date,
        day_name,
        is_weekend,
        payment_label

)

select * from daily_summary
order by pickup_date, payment_label