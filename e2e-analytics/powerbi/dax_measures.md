# DAX Measures for Power BI Report

> Copy these measures into your Power BI model after connecting to the SQL views.

## Core KPI Measures

```dax
// 1. Total Orders
Total Orders = COUNTROWS(fact_orders)

// 2. On-Time Rate (%)
On-Time % =
DIVIDE(
    CALCULATE(COUNTROWS(fact_orders), fact_orders[is_late] = 0),
    COUNTROWS(fact_orders)
) * 100

// 3. Late Orders
Late Orders = CALCULATE(COUNTROWS(fact_orders), fact_orders[is_late] = 1)

// 4. Average Delivery Time (minutes)
Avg Delivery Min =
AVERAGEX(
    fact_orders,
    DATEDIFF(fact_orders[placed_at], fact_orders[delivered_at], MINUTE)
)

// 5. Average Picking Time (minutes)
Avg Pick Min =
AVERAGEX(
    fact_orders,
    DATEDIFF(fact_orders[placed_at], fact_orders[packed_at], MINUTE)
)

// 6. Average Ride Time (minutes)
Avg Ride Min =
AVERAGEX(
    fact_orders,
    DATEDIFF(fact_orders[picked_up_at], fact_orders[delivered_at], MINUTE)
)

// 7. Average Rating
Avg Rating =
AVERAGE(fact_orders[rating])

// 8. Refund Rate (%)
Refund Rate % =
DIVIDE(
    CALCULATE(COUNTROWS(fact_orders), fact_orders[refund_amount] > 0),
    COUNTROWS(fact_orders)
) * 100

// 9. Total Revenue
Total Revenue = SUM(fact_orders[order_value])

// 10. Total Refunds
Total Refunds = SUM(fact_orders[refund_amount])

// 11. Net Revenue
Net Revenue = [Total Revenue] - [Total Refunds]

// 12. Repeat Customer Rate
Repeat Rate % =
VAR _cust =
    SUMMARIZE(fact_orders, fact_orders[customer_id], "cnt", COUNTROWS(fact_orders))
VAR _repeat = COUNTROWS(FILTER(_cust, [cnt] > 1))
VAR _total = COUNTROWS(_cust)
RETURN DIVIDE(_repeat, _total) * 100

// 13. Orders per Store (avg)
Avg Orders per Store =
AVERAGEX(
    VALUES(dim_store[store_id]),
    CALCULATE(COUNTROWS(fact_orders))
)

// 14. P90 Delivery Time
P90 Delivery =
PERCENTILEX.INC(
    fact_orders,
    DATEDIFF(fact_orders[placed_at], fact_orders[delivered_at], MINUTE),
    0.9
)

// 15. Rating by Delivery Bucket
Delivery Bucket =
SWITCH(
    TRUE(),
    DATEDIFF(fact_orders[placed_at], fact_orders[delivered_at], MINUTE) < 10, "Under 10 min",
    DATEDIFF(fact_orders[placed_at], fact_orders[delivered_at], MINUTE) < 15, "10–15 min",
    DATEDIFF(fact_orders[placed_at], fact_orders[delivered_at], MINUTE) < 20, "15–20 min",
    "Over 20 min"
)
```

## Report Pages

| # | Page | Visuals | Slicers |
|---|------|---------|---------|
| 1 | **Overview** | KPI cards, monthly trend line, on-time rate bar chart | Date, Zone |
| 2 | **Store Drill-Down** | Store table with conditional formatting, pick vs ride clustered bar | Store, Zone |
| 3 | **Time & Weather** | Late rate by hour heatmap, rain impact bar chart | Date range, Weather |
| 4 | **Cost of Delay** | Refund waterfall, repeat rate comparison, rating by bucket | Date, Store |

## Relationships (Star Schema)

```
dim_store[store_id]       → fact_orders[store_id]       (1:*)
dim_rider[rider_id]       → fact_orders[rider_id]       (1:*)
dim_customer[customer_id] → fact_orders[customer_id]    (1:*)
dim_product[product_id]   → fact_orders[product_id]     (1:*)
dim_date[date_id]         → fact_orders[date_id]        (1:*)
```

## Row-Level Security (RLS)

```dax
// RLS Role: Zone Filter
// Table: dim_store
// DAX Filter:
[zone] = USERPRINCIPALNAME()
// (Map each user's email to their zone in the security settings)
```
