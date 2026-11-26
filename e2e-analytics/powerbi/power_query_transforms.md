# Power Query (M) Transforms

> These are applied inside Power BI when you connect to SQL Server.

## Connection Setup

1. **Get Data** → SQL Server
2. Server: `localhost` (or your SQL Server instance)
3. Database: `E2E_Analytics`
4. Import mode (recommended for this dataset size)

## Transform: fact_orders

```powerquery
let
    Source = Sql.Database("localhost", "E2E_Analytics",
        [Query="SELECT * FROM analytics.vw_delivery"]),
    // Rename for clarity
    Renamed = Table.RenameColumns(Source, {
        {"total_min", "Delivery Minutes"},
        {"pick_min", "Picking Minutes"},
        {"ride_min", "Riding Minutes"},
        {"order_value", "Order Value (₹)"},
        {"refund_amount", "Refund (₹)"}
    }),
    // Set data types
    Typed = Table.TransformColumnTypes(Renamed, {
        {"Delivery Minutes", Int64.Type},
        {"Picking Minutes", Int64.Type},
        {"Riding Minutes", Int64.Type},
        {"Order Value (₹)", Currency.Type},
        {"Refund (₹)", Currency.Type},
        {"rating", Int64.Type},
        {"order_date", type date}
    })
in
    Typed
```

## Transform: dim_date (Date Table)

```powerquery
let
    Source = Sql.Database("localhost", "E2E_Analytics",
        [Query="SELECT * FROM dbo.dim_date"]),
    Typed = Table.TransformColumnTypes(Source, {
        {"date", type date},
        {"rain_mm", type number}
    }),
    AddQuarter = Table.AddColumn(Typed, "Quarter",
        each "Q" & Text.From(Date.QuarterOfYear([date])),
        type text)
in
    AddQuarter
```
