-- ============================================================
-- 02_staging_tables.sql
-- Creates staging tables and loads CSV files via BULK INSERT
-- ============================================================

USE E2E_Analytics;
GO

-- ---- Drop if re-running ----
DROP TABLE IF EXISTS stg.fact_orders;
DROP TABLE IF EXISTS stg.dim_store;
DROP TABLE IF EXISTS stg.dim_rider;
DROP TABLE IF EXISTS stg.dim_customer;
DROP TABLE IF EXISTS stg.dim_product;
DROP TABLE IF EXISTS stg.dim_date;
GO

-- ---- Staging: dim_store ----
CREATE TABLE stg.dim_store (
    store_id        INT,
    store_name      NVARCHAR(100),
    zone            NVARCHAR(50),
    opened_on       DATE,
    capacity        INT
);
GO

-- ---- Staging: dim_rider ----
CREATE TABLE stg.dim_rider (
    rider_id        INT,
    shift           NVARCHAR(20),
    tenure_months   INT
);
GO

-- ---- Staging: dim_customer ----
CREATE TABLE stg.dim_customer (
    customer_id     INT,
    segment         NVARCHAR(20),
    joined_on       DATE
);
GO

-- ---- Staging: dim_product ----
CREATE TABLE stg.dim_product (
    product_id      INT,
    category        NVARCHAR(50),
    avg_price       DECIMAL(10,2)
);
GO

-- ---- Staging: dim_date ----
CREATE TABLE stg.dim_date (
    date_id         INT,
    [date]          DATE,
    [day]           INT,
    [month]         INT,
    month_name      NVARCHAR(20),
    [weekday]       NVARCHAR(20),
    is_weekend      BIT,
    is_holiday      BIT,
    rain_mm         DECIMAL(5,1)
);
GO

-- ---- Staging: fact_orders ----
CREATE TABLE stg.fact_orders (
    order_id        NVARCHAR(20),
    store_id        INT,
    rider_id        INT,
    customer_id     INT,
    product_id      INT,
    date_id         INT,
    placed_at       DATETIME2,
    packed_at       DATETIME2,
    picked_up_at    DATETIME2,
    delivered_at    DATETIME2,
    order_value     DECIMAL(10,2),
    refund_amount   DECIMAL(10,2),
    rating          INT,
    is_late         BIT
);
GO

-- ============================================================
-- BULK INSERT  (adjust file paths to your local data/ folder)
-- ============================================================

/*
-- Uncomment and update the paths below to load from CSV:

BULK INSERT stg.dim_store
FROM 'C:\path\to\data\dim_store.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);

BULK INSERT stg.dim_rider
FROM 'C:\path\to\data\dim_rider.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);

BULK INSERT stg.dim_customer
FROM 'C:\path\to\data\dim_customer.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);

BULK INSERT stg.dim_product
FROM 'C:\path\to\data\dim_product.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);

BULK INSERT stg.dim_date
FROM 'C:\path\to\data\dim_date.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);

BULK INSERT stg.fact_orders
FROM 'C:\path\to\data\fact_orders.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);
*/

-- ---- Verify row counts ----
SELECT 'stg.dim_store'    AS [table], COUNT(*) AS [rows] FROM stg.dim_store
UNION ALL
SELECT 'stg.dim_rider',    COUNT(*) FROM stg.dim_rider
UNION ALL
SELECT 'stg.dim_customer', COUNT(*) FROM stg.dim_customer
UNION ALL
SELECT 'stg.dim_product',  COUNT(*) FROM stg.dim_product
UNION ALL
SELECT 'stg.dim_date',     COUNT(*) FROM stg.dim_date
UNION ALL
SELECT 'stg.fact_orders',  COUNT(*) FROM stg.fact_orders;
GO

PRINT '✅ Staging tables created. Uncomment BULK INSERT and update paths to load data.';
GO
