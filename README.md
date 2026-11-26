# E2E Analytics – SQL & Power BI Project

> An end-to-end analytics pipeline that answers one question: **why does a quick-commerce network in Chennai miss its ten-minute delivery promise?**

![SQL](https://img.shields.io/badge/SQL_Server-T--SQL-blue)
![Python](https://img.shields.io/badge/Python-3.10+-green)
![Power BI](https://img.shields.io/badge/Power_BI-Desktop-yellow)
![Kaggle](https://img.shields.io/badge/Data-Kaggle-20BEFF)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

---

## 📋 Overview

**Ten Minute Promise** is a fictional grocery delivery company operating 24 dark stores across 9 zones in Chennai. This project builds a full analytics pipeline — from raw data to executive dashboards — to find out which stores, hours, and weather conditions cause late deliveries, and what that costs in refunds and lost repeat customers.

### Key Numbers

| Metric | Value |
|--------|-------|
| Orders analysed | ~50,000 (synthetic) + Kaggle real-world data |
| Dark stores | 24 across 9 zones |
| Star schema tables | 6 (1 fact + 5 dimensions) |
| SQL analysis views | 8 |
| DAX measures | 15+ |
| Power BI report pages | 4 |

---

## 🏗️ Architecture

```
┌─────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Kaggle /   │───▶│  Python ETL  │───▶│  SQL Server  │───▶│  Power BI    │
│  Synthetic   │    │  (pandas)    │    │  Star Schema │    │  Dashboard   │
└─────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
                          │                    │
                          ▼                    ▼
                   ┌──────────────┐    ┌──────────────┐
                   │  ML Model    │    │  8 Analytical │
                   │  (sklearn)   │    │  Views        │
                   └──────────────┘    └──────────────┘
```

---

## 📁 Repository Structure

```
e2e-analytics/
├── README.md                          ← You are here
├── .gitignore
│
├── python/
│   ├── requirements.txt               ← Python dependencies
│   ├── download_kaggle_data.py        ← Download Kaggle data + generate star schema CSVs
│   └── train_model.py                 ← ML model (Random Forest, Gradient Boosting)
│
├── sql/
│   ├── 01_create_database.sql         ← Database + schemas
│   ├── 02_staging_tables.sql          ← Staging tables + BULK INSERT
│   ├── 03_clean_data.sql              ← De-dup, fix NULLs, flag bad timestamps
│   ├── 04_star_schema.sql             ← Fact + dimension tables with PK/FK
│   └── 05_analysis_views.sql          ← 8 analytical views (CTEs, window functions)
│
├── data/                              ← Generated CSV files (star schema)
│   ├── dim_store.csv
│   ├── dim_rider.csv
│   ├── dim_customer.csv
│   ├── dim_product.csv
│   ├── dim_date.csv
│   └── fact_orders.csv
│
├── models/                            ← Trained ML model + report
│   ├── delivery_time_model.pkl
│   ├── model_report.txt
│   └── feature_importance.csv
│
├── powerbi/
│   ├── dax_measures.md                ← All DAX measures + report layout
│   └── power_query_transforms.md      ← Power Query M code
│
└── docs/
    ├── index.html                     ← Interactive project showcase page
    └── data_dictionary.md             ← Full data dictionary
```

---

## 🚀 Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/YOUR_USERNAME/e2e-analytics.git
cd e2e-analytics
```

### 2. Install Python dependencies

```bash
pip install -r python/requirements.txt
```

### 3. Generate / download data

```bash
# Option A: Download from Kaggle (requires kaggle.json API key)
python python/download_kaggle_data.py

# Option B: The script auto-generates synthetic data if Kaggle isn't configured
python python/download_kaggle_data.py
```

### 4. Load into SQL Server

Run the SQL scripts in order on your SQL Server / SSMS:

```
sql/01_create_database.sql
sql/02_staging_tables.sql     ← update BULK INSERT paths
sql/03_clean_data.sql
sql/04_star_schema.sql
sql/05_analysis_views.sql
```

### 5. Train the ML model

```bash
python python/train_model.py
```

### 6. Connect Power BI

1. Open Power BI Desktop
2. **Get Data** → SQL Server → `localhost` / `E2E_Analytics`
3. Import the analytics views
4. Set up relationships as described in `powerbi/dax_measures.md`
5. Add the DAX measures
6. Build the four report pages

---

## 📊 Power BI Report Pages

| Page | Question Answered | Key Visuals |
|------|-------------------|-------------|
| **Overview** | How is the network performing overall? | KPI cards, monthly trend, on-time rate |
| **Store Drill-Down** | Which stores are worst? | Store ranking table, pick vs ride chart |
| **Time & Weather** | When and why do delays happen? | Hourly heatmap, rain impact analysis |
| **Cost of Delay** | What is the financial impact? | Refund waterfall, repeat rate comparison |

---

## 🤖 ML Model

The project includes a delivery-time prediction model trained with **scikit-learn**:

- **Models compared**: Linear Regression, Random Forest, Gradient Boosting
- **Features**: hour, day of week, weather, picking time, zone, rider tenure, customer segment
- **Target**: Total delivery time (minutes)
- **Output**: Best model saved as `.pkl`, performance report, feature importance

---

## 🔑 Key Findings

| Finding | Action |
|---------|--------|
| **24%** of 7 PM orders arrive late (4× morning rate) | Add riders to evening shift |
| **2.3×** longer picking time at Velachery & T Nagar | Re-slot fast movers by demand |
| **51%** on-time rate in heavy rain | Widen delivery promise in rain |
| **27-point** gap in repeat rate (on-time vs late) | Revenue case for fixing delays |

---

## 🛠️ Tech Stack

- **SQL Server** – T-SQL, SSMS, staging/clean/star schemas
- **Python 3.10+** – pandas, NumPy, scikit-learn, Kaggle API
- **Power BI Desktop** – DAX, Power Query M, row-level security
- **Git / GitHub** – Version control

---

## 📄 License

MIT License – see [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgements

- Dataset inspiration: [Kaggle Food Delivery Time Prediction](https://www.kaggle.com/datasets/gauravmalik26/food-delivery-dataset)
- Project structure follows the E2E Analytics SQL + Power BI framework
