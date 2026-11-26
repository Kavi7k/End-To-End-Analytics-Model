"""
download_kaggle_data.py
-----------------------
Downloads the 'Food Delivery Time Prediction' dataset from Kaggle
and reshapes it into the six CSV files needed by the E2E Analytics
star-schema pipeline.

Prerequisites
-------------
1.  pip install kaggle pandas numpy
2.  Place your Kaggle API token (kaggle.json) in ~/.kaggle/
    See: https://www.kaggle.com/docs/api#authentication

Dataset used
------------
  gauravmalik26/food-delivery-dataset
  (Real-world food-delivery records with timestamps, weather,
   traffic, ratings, coordinates, etc.)
"""

import os, sys, zipfile, shutil
from pathlib import Path

import numpy as np
import pandas as pd

# ---------------------------------------------------------------------------
# 1.  Download from Kaggle
# ---------------------------------------------------------------------------
DATA_DIR = Path(__file__).resolve().parent.parent / "data"
DATA_DIR.mkdir(parents=True, exist_ok=True)

RAW_CSV = DATA_DIR / "kaggle_raw.csv"

def download_dataset():
    """Use the Kaggle CLI to fetch the dataset."""
    if RAW_CSV.exists():
        print(f"[INFO] Raw file already exists: {RAW_CSV}")
        return
    try:
        from kaggle.api.kaggle_api_extended import KaggleApi
        api = KaggleApi()
        api.authenticate()
        api.dataset_download_files(
            "gauravmalik26/food-delivery-dataset",
            path=str(DATA_DIR),
            unzip=True,
        )
        # The dataset may extract as various filenames; find the CSV
        for f in DATA_DIR.glob("*.csv"):
            if f.name != "kaggle_raw.csv":
                f.rename(RAW_CSV)
                break
        print(f"[INFO] Downloaded and saved to {RAW_CSV}")
    except Exception as e:
        print(f"[WARN] Kaggle download failed ({e}). Generating synthetic fallback data.")
        generate_synthetic_fallback()


def generate_synthetic_fallback():
    """Create a realistic synthetic dataset if Kaggle isn't available."""
    np.random.seed(2025)
    n = 50_000
    stores = [
        ("Velachery", "South", "2022-01-15", 120),
        ("T Nagar", "Central", "2021-06-01", 100),
        ("OMR", "East", "2022-03-20", 150),
        ("Porur", "West", "2021-09-10", 90),
        ("Anna Nagar", "North", "2020-11-01", 130),
        ("Adyar", "South", "2021-01-20", 110),
        ("Tambaram", "South", "2023-02-01", 80),
        ("Chromepet", "South", "2022-07-15", 95),
        ("Mylapore", "Central", "2020-05-10", 105),
        ("Guindy", "Central", "2021-12-01", 140),
        ("Perambur", "North", "2022-04-01", 85),
        ("Ambattur", "North", "2021-08-15", 100),
        ("Sholinganallur", "East", "2023-01-10", 120),
        ("Thiruvanmiyur", "South", "2022-06-01", 110),
        ("Egmore", "Central", "2020-09-01", 95),
        ("Vadapalani", "West", "2021-03-15", 100),
        ("Mogappair", "North", "2022-10-01", 90),
        ("Pallavaram", "South", "2023-04-01", 75),
        ("Medavakkam", "South", "2022-11-15", 85),
        ("Ashok Nagar", "Central", "2021-07-01", 110),
        ("KK Nagar", "West", "2022-02-01", 95),
        ("Nungambakkam", "Central", "2020-12-01", 130),
        ("Royapettah", "Central", "2021-05-01", 100),
        ("Kodambakkam", "Central", "2022-08-01", 105),
    ]

    # Date range: Jan-Dec 2025
    dates = pd.date_range("2025-01-01", "2025-12-31", freq="h")
    dates_list = dates.tolist()  # convert to Python datetime objects

    rows = []
    for i in range(n):
        dt = dates_list[np.random.randint(0, len(dates_list))]
        hr = dt.hour
        if hr < 7 or hr > 23:
            continue
        s_idx = np.random.randint(0, len(stores))
        s_name, zone, opened, cap = stores[s_idx]

        # Weather
        rain_mm = 0
        r = np.random.random()
        if r > 0.85:
            rain_mm = np.random.uniform(5, 40)
        elif r > 0.65:
            rain_mm = np.random.uniform(0.1, 5)

        # Rush factor
        rush = 1.0
        if 19 <= hr <= 21:
            rush = 1.3
        elif 12 <= hr <= 14:
            rush = 1.15

        # Picking time (minutes)
        base_pick = {"Velachery": 5.6, "T Nagar": 5.0}.get(s_name, np.random.uniform(2, 4))
        pick_min = max(1, base_pick * np.exp(np.random.normal(0, 0.3)) * rush)

        # Ride time
        rain_add = 0 if rain_mm == 0 else (1.8 if rain_mm < 5 else 4.8)
        rush_add = 2 if rush > 1.1 else 0
        ride_min = max(1, (4.6 + rain_add + rush_add) * np.exp(np.random.normal(0, 0.28)))

        total = pick_min + ride_min + 1  # +1 for handoff
        is_late = 1 if total > 15 else 0

        # Order value
        order_value = round(np.random.lognormal(5.5, 0.6), 2)
        refund = round(order_value * 0.15, 2) if is_late and np.random.random() < 0.3 else 0

        # Rating
        if total < 10:
            rating = min(5, max(1, round(np.random.normal(4.8, 0.3))))
        elif total < 15:
            rating = min(5, max(1, round(np.random.normal(4.3, 0.5))))
        elif total < 20:
            rating = min(5, max(1, round(np.random.normal(3.1, 0.7))))
        else:
            rating = min(5, max(1, round(np.random.normal(1.9, 0.8))))

        placed_at = dt
        packed_at = placed_at + pd.Timedelta(minutes=pick_min)
        picked_up_at = packed_at + pd.Timedelta(minutes=0.5)
        delivered_at = placed_at + pd.Timedelta(minutes=total)

        rows.append({
            "order_id": f"ORD-{i+1:06d}",
            "store_id": s_idx + 1,
            "store_name": s_name,
            "zone": zone,
            "rider_id": np.random.randint(1, 201),
            "customer_id": np.random.randint(1, 10001),
            "product_id": np.random.randint(1, 501),
            "placed_at": placed_at,
            "packed_at": packed_at,
            "picked_up_at": picked_up_at,
            "delivered_at": delivered_at,
            "pick_min": round(pick_min, 2),
            "ride_min": round(ride_min, 2),
            "total_min": round(total, 2),
            "order_value": order_value,
            "refund_amount": refund,
            "rating": rating,
            "is_late": is_late,
            "rain_mm": round(rain_mm, 1),
            "is_holiday": 1 if dt.dayofweek >= 5 else 0,
        })

    df = pd.DataFrame(rows)
    df.to_csv(RAW_CSV, index=False)
    print(f"[INFO] Synthetic dataset generated: {RAW_CSV}  ({len(df)} rows)")


# ---------------------------------------------------------------------------
# 2.  Transform into star-schema CSV files
# ---------------------------------------------------------------------------
def build_star_schema():
    """Read the raw CSV and produce six star-schema CSV files."""
    print("[INFO] Building star-schema CSV files …")
    df = pd.read_csv(RAW_CSV, parse_dates=["placed_at", "packed_at", "picked_up_at", "delivered_at"])

    # --- dim_store ---
    if "store_name" in df.columns:
        dim_store = (
            df[["store_id", "store_name", "zone"]]
            .drop_duplicates()
            .sort_values("store_id")
            .reset_index(drop=True)
        )
        dim_store["opened_on"] = pd.to_datetime("2021-01-01")  # placeholder
        dim_store["capacity"] = np.random.randint(75, 150, len(dim_store))
    else:
        dim_store = pd.DataFrame({
            "store_id": range(1, 25),
            "store_name": [f"Store_{i}" for i in range(1, 25)],
            "zone": np.random.choice(["North", "South", "East", "West", "Central"], 24),
            "opened_on": pd.to_datetime("2021-01-01"),
            "capacity": np.random.randint(75, 150, 24),
        })
    dim_store.to_csv(DATA_DIR / "dim_store.csv", index=False)

    # --- dim_rider ---
    rider_ids = df["rider_id"].unique()
    dim_rider = pd.DataFrame({
        "rider_id": rider_ids,
        "shift": np.random.choice(["Morning", "Afternoon", "Evening", "Night"], len(rider_ids)),
        "tenure_months": np.random.randint(1, 48, len(rider_ids)),
    })
    dim_rider.to_csv(DATA_DIR / "dim_rider.csv", index=False)

    # --- dim_customer ---
    cust_ids = df["customer_id"].unique()
    dim_customer = pd.DataFrame({
        "customer_id": cust_ids,
        "segment": np.random.choice(["New", "Regular", "Premium", "VIP"], len(cust_ids)),
        "joined_on": pd.to_datetime("2023-01-01") + pd.to_timedelta(
            np.random.randint(0, 730, len(cust_ids)), unit="D"
        ),
    })
    dim_customer.to_csv(DATA_DIR / "dim_customer.csv", index=False)

    # --- dim_product ---
    prod_ids = df["product_id"].unique() if "product_id" in df.columns else range(1, 501)
    categories = ["Groceries", "Snacks", "Beverages", "Dairy", "Fruits", "Vegetables",
                   "Frozen", "Personal Care", "Baby Care", "Household"]
    dim_product = pd.DataFrame({
        "product_id": prod_ids,
        "category": np.random.choice(categories, len(prod_ids)),
        "avg_price": np.round(np.random.lognormal(4.5, 0.8, len(prod_ids)), 2),
    })
    dim_product.to_csv(DATA_DIR / "dim_product.csv", index=False)

    # --- dim_date ---
    all_dates = pd.date_range("2025-01-01", "2025-12-31")
    holidays = pd.to_datetime([
        "2025-01-14", "2025-01-15", "2025-01-26", "2025-03-14",
        "2025-04-14", "2025-08-15", "2025-09-05", "2025-10-02",
        "2025-10-20", "2025-11-01", "2025-12-25",
    ])
    dim_date = pd.DataFrame({
        "date_id": range(1, len(all_dates) + 1),
        "date": all_dates,
        "day": all_dates.day,
        "month": all_dates.month,
        "month_name": all_dates.strftime("%B"),
        "weekday": all_dates.strftime("%A"),
        "is_weekend": (all_dates.dayofweek >= 5).astype(int),
        "is_holiday": all_dates.isin(holidays).astype(int),
        "rain_mm": np.round(np.where(np.random.random(len(all_dates)) > 0.65,
                                      np.random.uniform(0.1, 40, len(all_dates)), 0), 1),
    })
    dim_date.to_csv(DATA_DIR / "dim_date.csv", index=False)

    # --- fact_orders ---
    fact = df.copy()
    # Map dates to date_id
    fact["order_date"] = fact["placed_at"].dt.normalize()
    date_map = dict(zip(dim_date["date"], dim_date["date_id"]))
    fact["date_id"] = fact["order_date"].map(date_map).fillna(1).astype(int)

    fact_cols = [
        "order_id", "store_id", "rider_id", "customer_id", "product_id", "date_id",
        "placed_at", "packed_at", "picked_up_at", "delivered_at",
        "order_value", "refund_amount", "rating", "is_late",
    ]
    # Keep only columns that exist
    fact_cols = [c for c in fact_cols if c in fact.columns]
    fact[fact_cols].to_csv(DATA_DIR / "fact_orders.csv", index=False)

    print(f"[INFO] Star-schema files written to {DATA_DIR}/")
    for f in sorted(DATA_DIR.glob("*.csv")):
        rows = sum(1 for _ in open(f)) - 1
        print(f"       {f.name:25s} → {rows:>8,} rows")


# ---------------------------------------------------------------------------
# 3.  Main
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    download_dataset()
    build_star_schema()
    print("\n✅  Done. CSV files are ready in the data/ folder.")
