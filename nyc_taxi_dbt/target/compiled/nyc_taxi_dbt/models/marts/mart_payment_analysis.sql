-- =============================================================
--  models/marts/mart_payment_analysis.sql
--
--  WHAT THIS MODEL DOES:
--  Analyzes tipping behavior broken down by payment method
--  and fare size. This is an insight-rich mart that answers
--  real business questions:
--    - "Do credit card users always tip more than cash users?"
--    - "At what fare amount do tips start dropping off?"
--    - "What % of trips receive no tip at all?"
--    - "Which fare bucket is most profitable per mile?"
--
--  One row per combination of: payment method + fare bucket + tip tier
--
--  Materialized as: TABLE
-- =============================================================

with revenue as (

    select * from "nyc_taxi"."main_intermediate"."int_trip_revenue_metrics"

),

-- Aggregate by payment type, fare range, and tip behavior
payment_summary as (

    select

        -- ── Dimensions ────────────────────────────────────────
        payment_label,          -- "Credit Card", "Cash", etc.
        fare_bucket,            -- "$5–$10", "$10–$20", etc.
        tip_tier,               -- "No Tip", "Low", "Medium", "High"

        -- ── Volume ────────────────────────────────────────────
        count(*)                                            as total_trips,

        -- ── Tip metrics ───────────────────────────────────────
        round(avg(tip_percentage),  2)                      as avg_tip_pct,
        round(avg(tip_amount),      2)                      as avg_tip_dollars,
        round(min(tip_amount),      2)                      as min_tip,
        round(max(tip_amount),      2)                      as max_tip,

        -- ── Fare metrics ──────────────────────────────────────
        round(avg(fare_amount),     2)                      as avg_fare,
        round(avg(total_amount),    2)                      as avg_total_charged,

        -- ── Efficiency metrics ────────────────────────────────
        round(avg(revenue_per_mile),    2)                  as avg_revenue_per_mile,
        round(avg(revenue_per_minute),  2)                  as avg_revenue_per_minute,

        -- ── No-tip rate ───────────────────────────────────────
        -- What % of trips in this group received zero tip?
        round(
            sum(case when tip_amount = 0 then 1 else 0 end) * 100.0
            / nullif(count(*), 0),
        2)                                                  as pct_trips_no_tip

    from revenue
    group by
        payment_label,
        fare_bucket,
        tip_tier

)

select * from payment_summary
order by
    payment_label,
    fare_bucket,
    tip_tier