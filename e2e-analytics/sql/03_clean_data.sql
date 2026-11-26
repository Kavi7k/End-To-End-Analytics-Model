-- ============================================================
-- 03_clean_data.sql
-- Cleans staging data: removes duplicates, fixes NULLs,
-- flags impossible timestamps
-- ============================================================

USE E2E_Analytics;
GO

-- ---- Clean fact_orders ----
DROP TABLE IF EXISTS clean.fact_orders;
GO

-- Remove duplicate orders (keep the latest by placed_at)
-- Fix NULL ratings → 0
-- Flag impossible timestamps (delivered before placed)
WITH ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY order_id
               ORDER BY placed_at DESC
           ) AS rn
    FROM stg.fact_orders
)
SELECT
    order_id,
    store_id,
    rider_id,
    customer_id,
    product_id,
    date_id,
    placed_at,
    packed_at,
    picked_up_at,
    delivered_at,
    order_value,
    COALESCE(refund_amount, 0) AS refund_amount,
    COALESCE(rating, 0)        AS rating,
    is_late,
    CASE WHEN delivered_at < placed_at THEN 1 ELSE 0 END AS bad_timestamp
INTO clean.fact_orders
FROM ranked
WHERE rn = 1;
GO

-- ---- Clean dim tables (copy with validation) ----
DROP TABLE IF EXISTS clean.dim_store;
SELECT * INTO clean.dim_store FROM stg.dim_store WHERE store_id IS NOT NULL;
GO

DROP TABLE IF EXISTS clean.dim_rider;
SELECT *,
       CASE WHEN tenure_months < 0 THEN 0 ELSE tenure_months END AS tenure_clean
INTO clean.dim_rider
FROM stg.dim_rider
WHERE rider_id IS NOT NULL;
GO

DROP TABLE IF EXISTS clean.dim_customer;
SELECT * INTO clean.dim_customer FROM stg.dim_customer WHERE customer_id IS NOT NULL;
GO

DROP TABLE IF EXISTS clean.dim_product;
SELECT * INTO clean.dim_product FROM stg.dim_product WHERE product_id IS NOT NULL;
GO

DROP TABLE IF EXISTS clean.dim_date;
SELECT * INTO clean.dim_date FROM stg.dim_date WHERE date_id IS NOT NULL;
GO

-- ---- Before / After counts ----
SELECT
    'fact_orders' AS [table],
    (SELECT COUNT(*) FROM stg.fact_orders) AS staging_rows,
    (SELECT COUNT(*) FROM clean.fact_orders) AS clean_rows,
    (SELECT COUNT(*) FROM stg.fact_orders) - (SELECT COUNT(*) FROM clean.fact_orders) AS removed
UNION ALL
SELECT
    'dim_store',
    (SELECT COUNT(*) FROM stg.dim_store),
    (SELECT COUNT(*) FROM clean.dim_store),
    (SELECT COUNT(*) FROM stg.dim_store) - (SELECT COUNT(*) FROM clean.dim_store);
GO

-- ---- Quality checks ----
SELECT 'Bad timestamps'       AS issue, COUNT(*) AS cnt FROM clean.fact_orders WHERE bad_timestamp = 1
UNION ALL
SELECT 'Missing ratings',     COUNT(*) FROM clean.fact_orders WHERE rating = 0
UNION ALL
SELECT 'Negative refunds',    COUNT(*) FROM clean.fact_orders WHERE refund_amount < 0
UNION ALL
SELECT 'NULL store_id',       COUNT(*) FROM clean.fact_orders WHERE store_id IS NULL;
GO

PRINT '✅ Data cleaned. Check the before/after counts above.';
GO
