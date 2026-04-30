# NYC Yellow Taxi Analytics — dbt Pipeline

A **dbt + DuckDB** data transformation pipeline built on the [NYC Taxi Parquet dataset](https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet) This project models ~3 million real taxi trips using production-grade dbt patterns — staging, intermediate, and mart layers — with full test coverage and auto-generated documentation.

---


## Project Overview
 
| | |
|---|---|
| **Dataset** | NYC TLC Yellow Taxi Trip Records (Jan 2024) |
| **Source rows** | ~2.9 million trips |
| **Stack** | Python · dbt Core · DuckDB |
| **Models** | 7 (1 staging · 2 intermediate · 3 marts) |
| **Tests** | unique, not_null, accepted_values |


---

## Pipeline Architecture
 
```
Raw Parquet (NYC TLC)
        │
        ▼
┌─────────────────────────┐
│  stg_yellow_taxi_trips  │  ← Clean + rename + filter bad rows
└─────────────────────────┘
        │
        ├──────────────────────────────┐
        ▼                              ▼
┌─────────────────────┐   ┌──────────────────────────┐
│ int_trips_time      │   │ int_trip_revenue_metrics │
│ (time features)     │   │ (tip %, fare per mile)   │
└─────────────────────┘   └──────────────────────────┘
        │                              │
        └──────────────┬───────────────┘
                       │
        ┌──────────────┼───────────────┐
        ▼              ▼               ▼
┌───────────────┐ ┌──────────────┐ ┌──────────────────────┐
│ mart_daily    │ │ mart_hourly  │ │ mart_payment_analysis│
│ trip_summary  │ │ demand       │ │                      │
└───────────────┘ └──────────────┘ └──────────────────────┘
```

---

## Models
 
### Staging
 
| Model | Description |
|---|---|
| `stg_yellow_taxi_trips` | Cleans raw data: renames columns, filters bad rows, creates `trip_id` surrogate key |
 
### Intermediate
 
| Model | Description |
|---|---|
| `int_trips_with_time_features` | Adds `pickup_hour`, `day_name`, `time_of_day`, `is_weekend` |
| `int_trip_revenue_metrics` | Adds `tip_percentage`, `revenue_per_mile`, `payment_label`, `tip_tier` |
 
### Marts (business-ready tables)
 
| Model | Description | Key Question Answered |
|---|---|---|
| `mart_daily_trip_summary` | One row per day per payment type | Revenue by day, avg fare, tip rate |
| `mart_hourly_demand` | One row per hour per pickup zone | When/where is demand highest? |
| `mart_payment_analysis` | Tip behavior by payment method + fare range | Do credit card users tip more? |
 
---

## Data Tests
 
```
dbt test
```
 
Tests defined in `stg_yellow_taxi_trips.yml`:
 
- `trip_id` — unique, not_null
- `pickup_at` / `dropoff_at` / `fare_amount` / `total_amount` — not_null
- `payment_type` — accepted_values [0, 1, 2, 3, 4, 5, 6]

---
 
## Data Source
https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet




