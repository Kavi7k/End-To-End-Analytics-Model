# Data Dictionary – E2E Analytics

## Fact Table

### `fact_orders`
| Column | Type | Description |
|--------|------|-------------|
| order_id | NVARCHAR(20) | Unique order identifier (PK) |
| store_id | INT | Dark store that fulfilled the order (FK → dim_store) |
| rider_id | INT | Delivery rider assigned (FK → dim_rider) |
| customer_id | INT | Customer who placed the order (FK → dim_customer) |
| product_id | INT | Primary product in the order (FK → dim_product) |
| date_id | INT | Calendar date of the order (FK → dim_date) |
| placed_at | DATETIME2 | Timestamp when customer placed the order |
| packed_at | DATETIME2 | Timestamp when store finished packing |
| picked_up_at | DATETIME2 | Timestamp when rider picked up the order |
| delivered_at | DATETIME2 | Timestamp when rider delivered to customer |
| order_value | DECIMAL(10,2) | Total order value in ₹ |
| refund_amount | DECIMAL(10,2) | Refund issued (₹0 if none) |
| rating | INT | Customer rating 1–5 (0 = not rated) |
| is_late | BIT | 1 if delivery exceeded 15-min promise |

## Dimension Tables

### `dim_store`
| Column | Type | Description |
|--------|------|-------------|
| store_id | INT | Primary key |
| store_name | NVARCHAR(100) | Dark store name (e.g., "Velachery") |
| zone | NVARCHAR(50) | City zone (North / South / East / West / Central) |
| opened_on | DATE | Store opening date |
| capacity | INT | Max concurrent orders the store can handle |

### `dim_rider`
| Column | Type | Description |
|--------|------|-------------|
| rider_id | INT | Primary key |
| shift | NVARCHAR(20) | Primary shift (Morning / Afternoon / Evening / Night) |
| tenure_months | INT | Months since the rider joined |

### `dim_customer`
| Column | Type | Description |
|--------|------|-------------|
| customer_id | INT | Primary key |
| segment | NVARCHAR(20) | Customer tier (New / Regular / Premium / VIP) |
| joined_on | DATE | Date the customer first ordered |

### `dim_product`
| Column | Type | Description |
|--------|------|-------------|
| product_id | INT | Primary key |
| category | NVARCHAR(50) | Product category (Groceries, Beverages, etc.) |
| avg_price | DECIMAL(10,2) | Average selling price in ₹ |

### `dim_date`
| Column | Type | Description |
|--------|------|-------------|
| date_id | INT | Primary key |
| date | DATE | Calendar date |
| day | INT | Day of month |
| month | INT | Month number (1–12) |
| month_name | NVARCHAR(20) | Month name (January, February, …) |
| weekday | NVARCHAR(20) | Day name (Monday, Tuesday, …) |
| is_weekend | BIT | 1 if Saturday or Sunday |
| is_holiday | BIT | 1 if public holiday |
| rain_mm | DECIMAL(5,1) | Rainfall in millimetres |
