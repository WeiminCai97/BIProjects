# =============================================================
#  WHERE TO DOWNLOAD THE FILE:
#  https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet
# =============================================================

import os
import duckdb

# ── CONFIGURE: Set the path to the downloaded Parquet file ──
FILE_PATH = "yellow_tripdata_2024-01.parquet"
DB_PATH = "nyc_taxi.duckdb"

# ── STEP 1: Confirm the file actually exists ──────────────────
if not os.path.exists(FILE_PATH):
    print(f"ERROR: File not found at: {FILE_PATH}")
    print("Please update FILE_PATH in this script to point to your downloaded file.")
    exit(1)

print(f"Found file: {FILE_PATH}")
file_size_mb = os.path.getsize(FILE_PATH) / (1024 * 1024)
print(f"File size : {file_size_mb:.1f} MB")

# ── STEP 2: Connect to DuckDB ─────────────────────────────────
print(f"\nConnecting to DuckDB: {DB_PATH}")
conn = duckdb.connect(DB_PATH)

# ── STEP 3: Create raw schema and load the file ───────────────
print("Creating raw schema...")
conn.execute("CREATE SCHEMA IF NOT EXISTS raw")

print("Loading Parquet file into raw.yellow_taxi_trips...")
conn.execute(f"""
    CREATE OR REPLACE TABLE raw.yellow_taxi_trips AS
    SELECT * FROM read_parquet('{FILE_PATH}')
""")

# ── STEP 4: Validate the load ─────────────────────────────────
row_count = conn.execute(
    "SELECT COUNT(*) FROM raw.yellow_taxi_trips"
).fetchone()[0]

col_count = conn.execute("""
    SELECT COUNT(*)
    FROM information_schema.columns
    WHERE table_name = 'yellow_taxi_trips'
""").fetchone()[0]

print(f"\nLoaded successfully!")
print(f"  Rows    : {row_count:,}")
print(f"  Columns : {col_count}")
print(f"  Database: {DB_PATH}")

# ── STEP 5: Preview first 3 rows ─────────────────────────────
print("\nPreview of first 3 rows:")
preview = conn.execute("""
    SELECT
        tpep_pickup_datetime,
        tpep_dropoff_datetime,
        trip_distance,
        fare_amount,
        total_amount,
        payment_type
    FROM raw.yellow_taxi_trips
    LIMIT 3
""").fetchdf()

print(preview.to_string(index=False))

# ── STEP 6: Show date range in the file ──────────────────────
print("\nDate range in this file:")
date_range = conn.execute("""
    SELECT
        MIN(tpep_pickup_datetime) AS earliest_trip,
        MAX(tpep_pickup_datetime) AS latest_trip
    FROM raw.yellow_taxi_trips
""").fetchdf()

print(date_range.to_string(index=False))

conn.close()
print("\nDone! Now run:  dbt deps  then  dbt run")