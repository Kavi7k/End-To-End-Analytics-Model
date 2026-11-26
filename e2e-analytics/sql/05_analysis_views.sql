-- ============================================================
-- 05_analysis_views.sql
-- Analytical views using JOINs, CTEs, and window functions
-- These views are consumed by Power BI
-- ============================================================

USE E2E_Analytics;
GO

-- ============================================================
-- VIEW 1: Delivery breakdown per order
-- ============================================================
DROP VIEW IF EXISTS analytics.vw_delivery;
GO
CREATE VIEW analytics.vw_delivery AS
SELECT
    o.order_id,
    o.store_id,
    s.store_name,
    s.zone,
    r.shift                                                    AS rider_shift,
    r.tenure_months                                            AS rider_tenure,
    c.segment                                                  AS customer_segment,
    d.[date]                                                   AS order_date,
    d.month_name,
    d.[weekday],
    d.is_weekend,
    d.is_holiday,
    d.rain_mm,
    DATEPART(HOUR, o.placed_at)                                AS order_hour,
    DATEDIFF(MINUTE, o.placed_at, o.packed_at)                 AS pick_min,
    DATEDIFF(MINUTE, o.picked_up_at, o.delivered_at)           AS ride_min,
    DATEDIFF(MINUTE, o.placed_at, o.delivered_at)              AS total_min,
    o.order_value,
    o.refund_amount,
    o.rating,
    o.is_late,
    CASE WHEN DATEDIFF(MINUTE, o.placed_at, o.delivered_at) > 15
         THEN 1 ELSE 0 END                                    AS is_late_15
FROM dbo.fact_orders o
JOIN dbo.dim_store    s ON s.store_id    = o.store_id
JOIN dbo.dim_rider    r ON r.rider_id    = o.rider_id
JOIN dbo.dim_customer c ON c.customer_id = o.customer_id
JOIN dbo.dim_date     d ON d.date_id     = o.date_id;
GO

-- ============================================================
-- VIEW 2: Store KPI summary
-- ============================================================
DROP VIEW IF EXISTS analytics.vw_store_kpi;
GO
CREATE VIEW analytics.vw_store_kpi AS
SELECT
    store_name,
    zone,
    COUNT(*)                                                   AS total_orders,
    AVG(CAST(total_min AS FLOAT))                              AS avg_delivery_min,
    AVG(CAST(pick_min AS FLOAT))                               AS avg_pick_min,
    AVG(CAST(ride_min AS FLOAT))                               AS avg_ride_min,
    AVG(CAST(rating AS FLOAT))                                 AS avg_rating,
    SUM(CAST(is_late_15 AS INT)) * 100.0 / COUNT(*)            AS late_pct,
    SUM(refund_amount)                                         AS total_refunds,
    SUM(order_value)                                           AS total_revenue
FROM analytics.vw_delivery
GROUP BY store_name, zone;
GO

-- ============================================================
-- VIEW 3: Hourly late-rate by zone
-- ============================================================
DROP VIEW IF EXISTS analytics.vw_hourly_late;
GO
CREATE VIEW analytics.vw_hourly_late AS
SELECT
    zone,
    order_hour                                                 AS hr,
    COUNT(*)                                                   AS orders,
    AVG(CAST(is_late_15 AS FLOAT)) * 100                       AS late_pct
FROM analytics.vw_delivery
GROUP BY zone, order_hour;
GO

-- ============================================================
-- VIEW 4: Worst 3 hours per zone (window function)
-- ============================================================
DROP VIEW IF EXISTS analytics.vw_worst_hours;
GO
CREATE VIEW analytics.vw_worst_hours AS
WITH hourly AS (
    SELECT
        zone,
        order_hour AS hr,
        AVG(CAST(is_late_15 AS FLOAT)) AS late_rate
    FROM analytics.vw_delivery
    GROUP BY zone, order_hour
),
ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY zone ORDER BY late_rate DESC) AS rk
    FROM hourly
)
SELECT zone, hr, ROUND(late_rate * 100, 1) AS late_pct, rk
FROM ranked
WHERE rk <= 3;
GO

-- ============================================================
-- VIEW 5: Rain impact analysis
-- ============================================================
DROP VIEW IF EXISTS analytics.vw_rain_impact;
GO
CREATE VIEW analytics.vw_rain_impact AS
SELECT
    CASE
        WHEN rain_mm = 0           THEN 'Dry'
        WHEN rain_mm BETWEEN 0.1 AND 5  THEN 'Light rain'
        ELSE 'Heavy rain'
    END                                                        AS weather,
    COUNT(*)                                                   AS orders,
    AVG(CAST(total_min AS FLOAT))                              AS avg_delivery_min,
    AVG(CAST(is_late_15 AS FLOAT)) * 100                       AS late_pct,
    AVG(CAST(rating AS FLOAT))                                 AS avg_rating
FROM analytics.vw_delivery
GROUP BY
    CASE
        WHEN rain_mm = 0           THEN 'Dry'
        WHEN rain_mm BETWEEN 0.1 AND 5  THEN 'Light rain'
        ELSE 'Heavy rain'
    END;
GO

-- ============================================================
-- VIEW 6: Monthly trend
-- ============================================================
DROP VIEW IF EXISTS analytics.vw_monthly_trend;
GO
CREATE VIEW analytics.vw_monthly_trend AS
SELECT
    DATEPART(MONTH, order_date) AS month_num,
    month_name,
    COUNT(*)                                                   AS orders,
    AVG(CAST(total_min AS FLOAT))                              AS avg_delivery_min,
    AVG(CAST(is_late_15 AS FLOAT)) * 100                       AS late_pct,
    SUM(order_value)                                           AS revenue,
    SUM(refund_amount)                                         AS refunds
FROM analytics.vw_delivery
GROUP BY DATEPART(MONTH, order_date), month_name;
GO

-- ============================================================
-- VIEW 7: Customer repeat analysis (CTE + window)
-- ============================================================
DROP VIEW IF EXISTS analytics.vw_customer_repeat;
GO
CREATE VIEW analytics.vw_customer_repeat AS
WITH customer_orders AS (
    SELECT
        o.customer_id,
        c.segment,
        COUNT(*)                                               AS order_count,
        AVG(CAST(is_late AS FLOAT))                            AS pct_late,
        AVG(CAST(o.rating AS FLOAT))                           AS avg_rating,
        SUM(o.order_value)                                     AS total_spent,
        DATEDIFF(DAY, MIN(o.placed_at), MAX(o.placed_at))      AS days_active
    FROM dbo.fact_orders o
    JOIN dbo.dim_customer c ON c.customer_id = o.customer_id
    GROUP BY o.customer_id, c.segment
)
SELECT
    segment,
    COUNT(*) AS customers,
    AVG(CAST(order_count AS FLOAT)) AS avg_orders,
    AVG(pct_late) * 100 AS avg_late_pct,
    AVG(avg_rating) AS avg_rating,
    AVG(total_spent) AS avg_spend,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS repeat_pct
FROM customer_orders
GROUP BY segment;
GO

-- ============================================================
-- VIEW 8: Rider performance ranking (window function)
-- ============================================================
DROP VIEW IF EXISTS analytics.vw_rider_ranking;
GO
CREATE VIEW analytics.vw_rider_ranking AS
WITH rider_stats AS (
    SELECT
        o.rider_id,
        r.shift,
        r.tenure_months,
        COUNT(*) AS deliveries,
        AVG(DATEDIFF(MINUTE, o.placed_at, o.delivered_at) * 1.0) AS avg_min,
        AVG(CAST(o.rating AS FLOAT)) AS avg_rating,
        SUM(CAST(o.is_late AS INT)) * 100.0 / COUNT(*) AS late_pct
    FROM dbo.fact_orders o
    JOIN dbo.dim_rider r ON r.rider_id = o.rider_id
    GROUP BY o.rider_id, r.shift, r.tenure_months
)
SELECT *,
    RANK() OVER (ORDER BY avg_min ASC) AS speed_rank,
    RANK() OVER (ORDER BY avg_rating DESC) AS rating_rank,
    NTILE(4) OVER (ORDER BY late_pct ASC) AS performance_quartile
FROM rider_stats;
GO

PRINT '✅ All 8 analytics views created.';
GO
