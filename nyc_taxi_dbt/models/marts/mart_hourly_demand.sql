-- =============================================================
--  models/marts/mart_hourly_demand.sql
--
--  WHAT THIS MODEL DOES:
--  Answers "when and where are taxis most in demand?"
--  One row per day + hour + pickup zone combination.
--  Useful for visualizing heatmaps, rush hour patterns,
--  and which neighborhoods generate the most trips.

--  Materialized as: TABLE
-- =============================================================

with trips as (

    select * from {{ ref('int_trips_with_time_features') }}

),

hourly_aggregated as (

    select

        -- ── Dimensions ────────────────────────────────────────
        pickup_date,
        pickup_hour,
        day_name,
        is_weekend,
        time_of_day,            -- "Morning Rush", "Evening Rush", etc.
        pickup_location_id,

        -- ── Volume metrics ────────────────────────────────────
        count(*)                                        as total_trips,

        -- ── Trip characteristics ──────────────────────────────
        round(avg(trip_distance),          2)           as avg_distance_miles,
        round(avg(trip_duration_minutes),  1)           as avg_duration_minutes,
        round(sum(trip_distance),          2)           as total_miles_traveled

    from trips
    group by
        pickup_date,
        pickup_hour,
        day_name,
        is_weekend,
        time_of_day,
        pickup_location_id

),

with_rankings as (

    select
        *,

        -- ── Rank each hour within a given day ─────────────────
        -- rank 1 = busiest hour of that day
        rank() over (
            partition by pickup_date
            order by total_trips desc
        )                                               as hour_rank_that_day,

        -- ── Rank each pickup zone for each hour ───────────────
        -- rank 1 = busiest zone during that hour
        rank() over (
            partition by pickup_date, pickup_hour
            order by total_trips desc
        )                                               as zone_rank_that_hour

    from hourly_aggregated

)

select * from with_rankings
order by pickup_date, pickup_hour, total_trips desc