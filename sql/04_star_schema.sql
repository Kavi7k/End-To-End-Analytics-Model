-- ============================================================
-- 04_star_schema.sql
-- Creates the production star schema with PK/FK constraints
-- ============================================================

USE E2E_Analytics;
GO

-- ======== DIMENSION TABLES ========

-- dim_store
DROP TABLE IF EXISTS dbo.dim_store;
CREATE TABLE dbo.dim_store (
    store_id    INT PRIMARY KEY,
    store_name  NVARCHAR(100) NOT NULL,
    zone        NVARCHAR(50)  NOT NULL,
    opened_on   DATE,
    capacity    INT
);
INSERT INTO dbo.dim_store
SELECT store_id, store_name, zone, opened_on, capacity
FROM clean.dim_store;
GO

-- dim_rider
DROP TABLE IF EXISTS dbo.dim_rider;
CREATE TABLE dbo.dim_rider (
    rider_id        INT PRIMARY KEY,
    shift           NVARCHAR(20),
    tenure_months   INT
);
INSERT INTO dbo.dim_rider
SELECT rider_id, shift, tenure_clean
FROM clean.dim_rider;
GO

-- dim_customer
DROP TABLE IF EXISTS dbo.dim_customer;
CREATE TABLE dbo.dim_customer (
    customer_id INT PRIMARY KEY,
    segment     NVARCHAR(20),
    joined_on   DATE
);
INSERT INTO dbo.dim_customer
SELECT customer_id, segment, joined_on
FROM clean.dim_customer;
GO

-- dim_product
DROP TABLE IF EXISTS dbo.dim_product;
CREATE TABLE dbo.dim_product (
    product_id  INT PRIMARY KEY,
    category    NVARCHAR(50),
    avg_price   DECIMAL(10,2)
);
INSERT INTO dbo.dim_product
SELECT product_id, category, avg_price
FROM clean.dim_product;
GO

-- dim_date
DROP TABLE IF EXISTS dbo.dim_date;
CREATE TABLE dbo.dim_date (
    date_id     INT PRIMARY KEY,
    [date]      DATE NOT NULL,
    [day]       INT,
    [month]     INT,
    month_name  NVARCHAR(20),
    [weekday]   NVARCHAR(20),
    is_weekend  BIT DEFAULT 0,
    is_holiday  BIT DEFAULT 0,
    rain_mm     DECIMAL(5,1) DEFAULT 0
);
INSERT INTO dbo.dim_date
SELECT date_id, [date], [day], [month], month_name, [weekday],
       is_weekend, is_holiday, rain_mm
FROM clean.dim_date;
GO

-- ======== FACT TABLE ========

DROP TABLE IF EXISTS dbo.fact_orders;
CREATE TABLE dbo.fact_orders (
    order_id        NVARCHAR(20) PRIMARY KEY,
    store_id        INT NOT NULL REFERENCES dbo.dim_store(store_id),
    rider_id        INT NOT NULL REFERENCES dbo.dim_rider(rider_id),
    customer_id     INT NOT NULL REFERENCES dbo.dim_customer(customer_id),
    product_id      INT NOT NULL REFERENCES dbo.dim_product(product_id),
    date_id         INT NOT NULL REFERENCES dbo.dim_date(date_id),
    placed_at       DATETIME2 NOT NULL,
    packed_at       DATETIME2,
    picked_up_at    DATETIME2,
    delivered_at    DATETIME2,
    order_value     DECIMAL(10,2),
    refund_amount   DECIMAL(10,2) DEFAULT 0,
    rating          INT CHECK (rating BETWEEN 0 AND 5),
    is_late         BIT DEFAULT 0
);
INSERT INTO dbo.fact_orders
SELECT order_id, store_id, rider_id, customer_id, product_id, date_id,
       placed_at, packed_at, picked_up_at, delivered_at,
       order_value, refund_amount, rating, is_late
FROM clean.fact_orders
WHERE bad_timestamp = 0;
GO

-- ---- Verify ----
SELECT 'dim_store'    AS [table], COUNT(*) AS [rows] FROM dbo.dim_store
UNION ALL SELECT 'dim_rider',    COUNT(*) FROM dbo.dim_rider
UNION ALL SELECT 'dim_customer', COUNT(*) FROM dbo.dim_customer
UNION ALL SELECT 'dim_product',  COUNT(*) FROM dbo.dim_product
UNION ALL SELECT 'dim_date',     COUNT(*) FROM dbo.dim_date
UNION ALL SELECT 'fact_orders',  COUNT(*) FROM dbo.fact_orders;
GO

PRINT '✅ Star schema created with PK/FK constraints.';
GO
