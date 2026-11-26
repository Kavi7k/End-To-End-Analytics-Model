"""
train_model.py
--------------
Trains a delivery-time prediction model using the Kaggle
'Food Delivery Time Prediction' dataset.

The model predicts total delivery time (minutes) from features like:
  - store zone, hour of day, day of week
  - weather (rain_mm), rider tenure, customer segment
  - picking time

It outputs:
  - A trained Random Forest model  (models/delivery_time_rf.pkl)
  - A model performance report     (models/model_report.txt)
  - Feature importance chart        (models/feature_importance.png)

Usage:
  pip install -r requirements.txt
  python train_model.py
"""

import os, sys
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.linear_model import LinearRegression
from sklearn.metrics import (
    mean_absolute_error,
    mean_squared_error,
    r2_score,
)
from sklearn.preprocessing import LabelEncoder
import pickle

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
DATA_DIR = Path(__file__).resolve().parent.parent / "data"
MODEL_DIR = Path(__file__).resolve().parent.parent / "models"
MODEL_DIR.mkdir(parents=True, exist_ok=True)

# ---------------------------------------------------------------------------
# 1. Load & merge star-schema tables
# ---------------------------------------------------------------------------
def load_data():
    fact = pd.read_csv(DATA_DIR / "fact_orders.csv", parse_dates=["placed_at", "packed_at", "picked_up_at", "delivered_at"])
    dim_store = pd.read_csv(DATA_DIR / "dim_store.csv")
    dim_rider = pd.read_csv(DATA_DIR / "dim_rider.csv")
    dim_customer = pd.read_csv(DATA_DIR / "dim_customer.csv")
    dim_date = pd.read_csv(DATA_DIR / "dim_date.csv")

    df = fact.merge(dim_store, on="store_id", how="left")
    df = df.merge(dim_rider, on="rider_id", how="left")
    df = df.merge(dim_customer, on="customer_id", how="left")
    df = df.merge(dim_date, on="date_id", how="left")

    return df


# ---------------------------------------------------------------------------
# 2. Feature engineering
# ---------------------------------------------------------------------------
def engineer_features(df):
    df = df.copy()

    # Time-based features
    df["hour"] = df["placed_at"].dt.hour
    df["day_of_week"] = df["placed_at"].dt.dayofweek
    df["is_weekend"] = (df["day_of_week"] >= 5).astype(int)
    df["is_rush_hour"] = df["hour"].apply(lambda h: 1 if 19 <= h <= 21 or 12 <= h <= 14 else 0)
    df["month"] = df["placed_at"].dt.month

    # Delivery duration (target)
    df["delivery_minutes"] = (
        (df["delivered_at"] - df["placed_at"]).dt.total_seconds() / 60
    )

    # Pick time
    df["pick_minutes"] = (
        (df["packed_at"] - df["placed_at"]).dt.total_seconds() / 60
    )

    # Ride time
    df["ride_minutes"] = (
        (df["delivered_at"] - df["picked_up_at"]).dt.total_seconds() / 60
    )

    # Rain
    df["rain_mm"] = df["rain_mm"].fillna(0)
    df["is_rainy"] = (df["rain_mm"] > 0).astype(int)
    df["heavy_rain"] = (df["rain_mm"] > 5).astype(int)

    # Encode categoricals
    label_cols = ["zone", "shift", "segment"]
    encoders = {}
    for col in label_cols:
        if col in df.columns:
            le = LabelEncoder()
            df[col + "_enc"] = le.fit_transform(df[col].astype(str))
            encoders[col] = le

    # Drop rows with missing target
    df = df.dropna(subset=["delivery_minutes"])
    df = df[df["delivery_minutes"] > 0]

    return df, encoders


# ---------------------------------------------------------------------------
# 3. Train models
# ---------------------------------------------------------------------------
FEATURE_COLS = [
    "hour", "day_of_week", "is_weekend", "is_rush_hour", "month",
    "rain_mm", "is_rainy", "heavy_rain",
    "pick_minutes",
    "zone_enc", "shift_enc", "segment_enc",
    "capacity", "tenure_months",
]


def train(df):
    # Keep only features that exist
    available = [c for c in FEATURE_COLS if c in df.columns]
    X = df[available].fillna(0)
    y = df["delivery_minutes"]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    models = {
        "Linear Regression": LinearRegression(),
        "Random Forest": RandomForestRegressor(
            n_estimators=200, max_depth=12, random_state=42, n_jobs=-1
        ),
        "Gradient Boosting": GradientBoostingRegressor(
            n_estimators=200, max_depth=6, learning_rate=0.1, random_state=42
        ),
    }

    results = {}
    best_model = None
    best_r2 = -np.inf

    for name, model in models.items():
        print(f"\n{'='*50}")
        print(f"Training: {name}")
        print(f"{'='*50}")

        model.fit(X_train, y_train)
        y_pred = model.predict(X_test)

        mae = mean_absolute_error(y_test, y_pred)
        rmse = np.sqrt(mean_squared_error(y_test, y_pred))
        r2 = r2_score(y_test, y_pred)

        # Cross-validation
        cv_scores = cross_val_score(model, X, y, cv=5, scoring="r2", n_jobs=-1)

        results[name] = {
            "MAE": mae,
            "RMSE": rmse,
            "R2": r2,
            "CV_R2_mean": cv_scores.mean(),
            "CV_R2_std": cv_scores.std(),
        }

        print(f"  MAE  : {mae:.2f} min")
        print(f"  RMSE : {rmse:.2f} min")
        print(f"  R²   : {r2:.4f}")
        print(f"  CV R²: {cv_scores.mean():.4f} ± {cv_scores.std():.4f}")

        if r2 > best_r2:
            best_r2 = r2
            best_model = (name, model)

    return results, best_model, X_test, y_test, available


# ---------------------------------------------------------------------------
# 4. Save outputs
# ---------------------------------------------------------------------------
def save_outputs(results, best_model, feature_cols, encoders):
    name, model = best_model

    # Save model
    model_path = MODEL_DIR / "delivery_time_model.pkl"
    with open(model_path, "wb") as f:
        pickle.dump({"model": model, "features": feature_cols, "encoders": encoders}, f)
    print(f"\n✅ Best model ({name}) saved to {model_path}")

    # Save report
    report_path = MODEL_DIR / "model_report.txt"
    with open(report_path, "w") as f:
        f.write("=" * 60 + "\n")
        f.write("E2E ANALYTICS – DELIVERY TIME PREDICTION MODEL REPORT\n")
        f.write("=" * 60 + "\n\n")
        f.write(f"Dataset: Kaggle Food Delivery / Synthetic fallback\n")
        f.write(f"Best Model: {name}\n\n")

        for model_name, metrics in results.items():
            f.write(f"\n--- {model_name} ---\n")
            for k, v in metrics.items():
                f.write(f"  {k:15s}: {v:.4f}\n")

        f.write(f"\n\nFeatures used: {', '.join(feature_cols)}\n")

        # Feature importance (if available)
        if hasattr(model, "feature_importances_"):
            f.write("\n\nFeature Importance (top 10):\n")
            imp = sorted(
                zip(feature_cols, model.feature_importances_),
                key=lambda x: x[1],
                reverse=True,
            )
            for feat, score in imp[:10]:
                bar = "█" * int(score * 50)
                f.write(f"  {feat:20s}  {score:.4f}  {bar}\n")

    print(f"✅ Report saved to {report_path}")

    # Save feature importance as CSV
    if hasattr(model, "feature_importances_"):
        imp_df = pd.DataFrame({
            "feature": feature_cols,
            "importance": model.feature_importances_,
        }).sort_values("importance", ascending=False)
        imp_df.to_csv(MODEL_DIR / "feature_importance.csv", index=False)
        print(f"✅ Feature importance saved to {MODEL_DIR / 'feature_importance.csv'}")


# ---------------------------------------------------------------------------
# 5. Main
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    print("Loading data …")
    df = load_data()
    print(f"  Loaded {len(df):,} orders")

    print("\nEngineering features …")
    df, encoders = engineer_features(df)
    print(f"  {len(df):,} orders after cleaning")

    results, best_model, X_test, y_test, feature_cols = train(df)
    save_outputs(results, best_model, feature_cols, encoders)

    print("\n✅ All done! Model training complete.")
