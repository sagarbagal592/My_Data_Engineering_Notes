# Pandas for Data Engineering — Complete ETL Guide

## 1. What is Pandas?

**Pandas** is a Python library used to work with structured/tabular data.

Think of it as:

> **Pandas = Python + Excel-like tables + SQL-like transformations**

The central object is a **DataFrame**.

```python
import pandas as pd

df = pd.DataFrame({
    "customer_id": [101, 102, 103],
    "name": ["John", "Alice", "Bob"],
    "amount": [500, 700, 300]
})

print(df)
```

Output:

```text
   customer_id   name  amount
0          101   John     500
1          102  Alice     700
2          103    Bob     300
```

You can think of a DataFrame as a table:

| customer_id | name | amount |
|---:|---|---:|
| 101 | John | 500 |
| 102 | Alice | 700 |
| 103 | Bob | 300 |

---

# 2. Where Pandas Fits in an ETL Pipeline

A typical Pandas ETL pipeline looks like:

```text
         SOURCE
           │
           ▼
    ┌──────────────┐
    │ Extract      │
    │ CSV / JSON   │
    │ Excel / DB   │
    │ API          │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ Transform    │
    │              │
    │ Clean        │
    │ Filter       │
    │ Join         │
    │ Aggregate    │
    │ Deduplicate  │
    │ Derive cols  │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ Validate     │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ Load         │
    │ CSV / DB     │
    │ Parquet      │
    │ Data Lake    │
    └──────────────┘
```

For example:

```text
orders.csv
   ↓
pd.read_csv()
   ↓
clean data
   ↓
filter invalid orders
   ↓
remove duplicates
   ↓
join customer data
   ↓
calculate revenue
   ↓
aggregate
   ↓
write Parquet
```

---

# 3. Important Pandas Concepts for Data Engineers

You should be comfortable with:

- DataFrame
- Series
- Index
- Columns
- Data types
- Missing values
- Vectorized operations
- Filtering
- Sorting
- Grouping
- Aggregation
- Joining
- Merging
- Concatenation
- Pivoting
- Window-like operations
- Date/time operations
- String operations
- Deduplication
- Reading/writing files
- Database interaction
- Validation

---

# 4. Creating a DataFrame

## From Dictionary

```python
df = pd.DataFrame({
    "id": [1, 2, 3],
    "name": ["John", "Alice", "Bob"],
    "salary": [50000, 60000, 70000]
})
```

## From List

```python
data = [
    [1, "John", 50000],
    [2, "Alice", 60000],
    [3, "Bob", 70000]
]

df = pd.DataFrame(
    data,
    columns=["id", "name", "salary"]
)
```

---

# 5. Reading Data — Extract

This is the **E** in ETL.

## CSV

```python
df = pd.read_csv("orders.csv")
```

## Excel

```python
df = pd.read_excel("orders.xlsx")
```

## JSON

```python
df = pd.read_json("orders.json")
```

## Parquet

```python
df = pd.read_parquet("orders.parquet")
```

## SQL Database

```python
import pandas as pd
import sqlalchemy

engine = sqlalchemy.create_engine(
    "postgresql://user:password@localhost:5432/mydb"
)

df = pd.read_sql(
    "SELECT * FROM orders",
    engine
)
```

For Data Engineering, `read_sql()` is particularly useful.

---

# 6. Inspecting the Data

After extracting data, the first thing a Data Engineer usually does is inspect it.

## `head()`

```python
df.head()
```

Returns the first five rows by default.

## `tail()`

```python
df.tail()
```

Returns the last five rows by default.

## `shape`

```python
df.shape
```

Example:

```text
(10000, 8)
```

Meaning:

```text
10000 rows
8 columns
```

## `info()`

```python
df.info()
```

This gives:

- number of rows
- columns
- data types
- null counts
- memory usage

Very useful during ETL development.

## `describe()`

```python
df.describe()
```

Provides statistics such as:

- count
- mean
- std
- min
- 25%
- 50%
- 75%
- max

---

# 7. Selecting Columns

Suppose:

```text
customer_id | name | city | salary
```

## Select One Column

```python
df["name"]
```

This returns a **Series**.

## Select Multiple Columns

```python
df[["customer_id", "name"]]
```

---

# 8. Filtering Rows

This is one of the most important Pandas operations.

Suppose:

```python
df[df["salary"] > 50000]
```

Equivalent SQL:

```sql
SELECT *
FROM employees
WHERE salary > 50000;
```

## Multiple Conditions

```python
df[
    (df["salary"] > 50000) &
    (df["city"] == "Pune")
]
```

SQL equivalent:

```sql
WHERE salary > 50000
AND city = 'Pune'
```

## OR Condition

```python
df[
    (df["city"] == "Pune") |
    (df["city"] == "Mumbai")
]
```

### Important

With Pandas conditions:

- `&` means AND
- `|` means OR
- `~` means NOT

Use parentheses around individual conditions.

---

# 9. `loc` and `iloc`

These are important for interviews.

## `loc`

Used for **label-based selection**.

```python
df.loc[0, "name"]
```

Select rows based on labels.

Example:

```python
df.loc[
    df["salary"] > 50000,
    ["name", "salary"]
]
```

Meaning:

> Give me name and salary where salary > 50000.

## `iloc`

Used for **position-based selection**.

```python
df.iloc[0]
```

First row.

```python
df.iloc[0:5]
```

First five rows.

```python
df.iloc[:, 0:2]
```

All rows, first two columns.

### Interview Difference

```text
loc  → label based
iloc → integer position based
```

---

# 10. Adding a Column

Suppose:

```text
price | quantity
100   | 5
200   | 3
```

Create revenue:

```python
df["revenue"] = df["price"] * df["quantity"]
```

Result:

```text
price | quantity | revenue
100   | 5        | 500
200   | 3        | 600
```

This is called a **derived column**.

Very common in ETL.

---

# 11. Transforming Columns

Suppose:

```python
df["name"] = df["name"].str.upper()
```

Before:

```text
John
Alice
Bob
```

After:

```text
JOHN
ALICE
BOB
```

Other examples:

```python
df["name"].str.lower()
df["name"].str.strip()
df["name"].str.title()
```

---

# 12. String Transformations

Pandas provides the `.str` accessor.

## Convert to Lowercase

```python
df["email"].str.lower()
```

## Check Whether Email Contains Gmail

```python
df["email"].str.contains("@gmail.com")
```

## Extract Part of a String

```python
df["email"].str.split("@").str[1]
```

Example:

```text
john@gmail.com
```

becomes:

```text
gmail.com
```

## Replace

```python
df["city"] = df["city"].str.replace(
    "Bombay",
    "Mumbai"
)
```

Other useful string operations:

```python
df["name"].str.startswith("A")
df["name"].str.endswith("n")
df["name"].str.contains("ali", case=False)
df["name"].str.len()
df["name"].str.replace("old", "new")
```

---

# 13. Handling NULL Values

Very important in ETL.

Suppose:

```text
customer_id | city
101         | Pune
102         | NaN
103         | Mumbai
```

## Check Nulls

```python
df.isnull()
```

## Count Nulls

```python
df.isnull().sum()
```

Example:

```text
customer_id    0
city           1
```

You can also use:

```python
df.isna()
df.isna().sum()
```

---

# 14. `fillna()`

Replace missing values.

```python
df["city"] = df["city"].fillna("Unknown")
```

Or:

```python
df["salary"] = df["salary"].fillna(0)
```

You can also use the mean:

```python
df["salary"] = df["salary"].fillna(
    df["salary"].mean()
)
```

Other options include:

```python
df["column"].fillna(method="ffill")
df["column"].fillna(method="bfill")
```

For current Pandas versions, prefer the dedicated forward/backward fill methods where appropriate.

---

# 15. `dropna()`

Remove rows containing nulls.

```python
df = df.dropna()
```

Only for a specific column:

```python
df = df.dropna(
    subset=["customer_id"]
)
```

This is often safer in ETL.

For example:

> Customer ID cannot be NULL, so reject rows where customer_id is missing.

---

# 16. Replacing Values

```python
df["status"] = df["status"].replace(
    "Y",
    "Yes"
)
```

Multiple replacements:

```python
df["status"] = df["status"].replace({
    "Y": "Yes",
    "N": "No"
})
```

---

# 17. Changing Data Types

Very important in ETL.

```python
df["customer_id"] = df["customer_id"].astype(int)
```

Convert to string:

```python
df["customer_id"] = df["customer_id"].astype(str)
```

Convert to float:

```python
df["amount"] = df["amount"].astype(float)
```

You can also use `pd.to_numeric()` when source data may contain invalid values:

```python
df["amount"] = pd.to_numeric(
    df["amount"],
    errors="coerce"
)
```

Invalid numeric values become `NaN` when `errors="coerce"` is used.

---

# 18. Date Transformations

Suppose:

```text
order_date
2026-09-01
2026-09-02
```

Convert to datetime:

```python
df["order_date"] = pd.to_datetime(
    df["order_date"]
)
```

Now you can extract:

```python
df["year"] = df["order_date"].dt.year
```

```python
df["month"] = df["order_date"].dt.month
```

```python
df["day"] = df["order_date"].dt.day
```

```python
df["month_name"] = df["order_date"].dt.month_name()
```

```python
df["day_of_week"] = df["order_date"].dt.day_name()
```

Other useful operations:

```python
df["quarter"] = df["order_date"].dt.quarter
df["week"] = df["order_date"].dt.isocalendar().week
```

---

# 19. Filtering by Date

```python
df[
    df["order_date"] >= "2026-01-01"
]
```

For a date range:

```python
df[
    (df["order_date"] >= "2026-01-01") &
    (df["order_date"] < "2026-02-01")
]
```

This is useful for incremental ETL.

---

# 20. Sorting

```python
df.sort_values("amount")
```

Descending:

```python
df.sort_values(
    "amount",
    ascending=False
)
```

Multiple columns:

```python
df.sort_values(
    ["customer_id", "order_date"]
)
```

You can also sort by different directions:

```python
df.sort_values(
    ["customer_id", "amount"],
    ascending=[True, False]
)
```

---

# 21. Removing Duplicates

Very important in ETL.

```python
df.drop_duplicates()
```

Suppose your business key is:

```text
order_id
```

Then:

```python
df.drop_duplicates(
    subset=["order_id"]
)
```

Keep the latest record:

```python
df = df.sort_values("updated_at")

df = df.drop_duplicates(
    subset=["order_id"],
    keep="last"
)
```

This is conceptually similar to the Spark/SQL pattern:

```sql
ROW_NUMBER() OVER (
    PARTITION BY order_id
    ORDER BY updated_at DESC
)
```

For an explicit latest-record approach, it is often clearer to sort descending:

```python
df = df.sort_values(
    "updated_at",
    ascending=False
)

df = df.drop_duplicates(
    subset=["order_id"],
    keep="first"
)
```

---

# 22. `apply()`

You can apply a Python function to a column.

```python
def categorize(amount):
    if amount >= 1000:
        return "High"
    elif amount >= 500:
        return "Medium"
    else:
        return "Low"
```

Then:

```python
df["category"] = df["amount"].apply(
    categorize
)
```

However, **don't automatically use `apply()` for everything**.

When possible, vectorized Pandas operations are generally preferable.

For example, instead of:

```python
df["amount"].apply(lambda x: x * 2)
```

prefer:

```python
df["amount"] * 2
```

---

# 23. Conditional Transformation

You can use `np.where()`.

```python
import numpy as np

df["customer_type"] = np.where(
    df["amount"] >= 1000,
    "Premium",
    "Regular"
)
```

Conceptually:

```sql
CASE
    WHEN amount >= 1000 THEN 'Premium'
    ELSE 'Regular'
END
```

For multiple conditions, `np.select()` is useful.

```python
conditions = [
    df["amount"] >= 1000,
    df["amount"] >= 500
]

choices = [
    "High",
    "Medium"
]

df["category"] = np.select(
    conditions,
    choices,
    default="Low"
)
```

---

# 24. `groupby()` — Extremely Important

This is one of the most important Pandas operations for Data Engineering.

Suppose:

```text
customer_id | amount
101         | 500
101         | 700
102         | 300
102         | 900
```

Calculate total amount per customer:

```python
df.groupby("customer_id")["amount"].sum()
```

Equivalent SQL:

```sql
SELECT
    customer_id,
    SUM(amount)
FROM orders
GROUP BY customer_id;
```

---

# 25. Multiple Aggregations

```python
df.groupby("customer_id")["amount"].agg(
    ["sum", "mean", "min", "max", "count"]
)
```

You can also use named aggregations:

```python
result = df.groupby("customer_id").agg(
    total_amount=("amount", "sum"),
    avg_amount=("amount", "mean"),
    order_count=("order_id", "count")
)
```

This is very useful when creating **Gold-layer analytical datasets**.

---

# 26. `groupby()` with Multiple Columns

```python
df.groupby(
    ["customer_id", "product_id"]
)["amount"].sum()
```

Equivalent to:

```sql
GROUP BY customer_id, product_id
```

---

# 27. Merge — JOIN

This is one of the most important Pandas operations for a Data Engineer.

Suppose:

### Customers

```text
customer_id | name
101         | John
102         | Alice
```

### Orders

```text
order_id | customer_id | amount
1        | 101         | 500
2        | 102         | 700
```

Join them:

```python
result = orders.merge(
    customers,
    on="customer_id",
    how="inner"
)
```

SQL equivalent:

```sql
SELECT *
FROM orders o
INNER JOIN customers c
    ON o.customer_id = c.customer_id;
```

---

# 28. Different Join Types

Pandas supports:

```python
how="inner"
how="left"
how="right"
how="outer"
```

## Inner

```python
orders.merge(
    customers,
    on="customer_id",
    how="inner"
)
```

Only matching records.

## Left

```python
orders.merge(
    customers,
    on="customer_id",
    how="left"
)
```

Keep all orders.

## Right

```python
orders.merge(
    customers,
    on="customer_id",
    how="right"
)
```

Keep all customers.

## Outer

```python
orders.merge(
    customers,
    on="customer_id",
    how="outer"
)
```

Keep everything from both DataFrames.

---

# 29. Join Using Different Column Names

Suppose:

```text
orders.customer_id
customers.id
```

Then:

```python
orders.merge(
    customers,
    left_on="customer_id",
    right_on="id",
    how="left"
)
```

---

# 30. Merge Validation

A useful Data Engineering technique is to validate the expected relationship.

For example:

```python
orders.merge(
    customers,
    on="customer_id",
    how="left",
    validate="many_to_one"
)
```

This says:

> Many orders can belong to one customer.

If the customer table unexpectedly contains duplicate customer IDs, Pandas can raise an error instead of silently creating duplicate output rows.

Other useful options include:

```python
validate="one_to_one"
validate="one_to_many"
validate="many_to_many"
```

---

# 31. Concatenation

`concat()` is different from `merge()`.

Suppose you have:

```text
orders_jan
orders_feb
orders_mar
```

Stack them vertically:

```python
all_orders = pd.concat(
    [orders_jan, orders_feb, orders_mar]
)
```

Conceptually:

```text
JAN
 ↓
FEB
 ↓
MAR
```

This is similar to:

```sql
UNION ALL
```

You can reset the index:

```python
all_orders = pd.concat(
    [orders_jan, orders_feb, orders_mar],
    ignore_index=True
)
```

---

# 32. `merge()` vs `concat()`

Remember this for interviews:

| Pandas | SQL concept |
|---|---|
| `merge()` | JOIN |
| `concat()` | UNION / stacking |
| `groupby()` | GROUP BY |
| `query()` | WHERE |
| `drop_duplicates()` | DISTINCT / dedup |
| `sort_values()` | ORDER BY |
| `assign()` | Derived columns |
| `pivot_table()` | Pivot/aggregation |

---

# 33. `query()`

Instead of:

```python
df[
    (df["amount"] > 500) &
    (df["status"] == "COMPLETE")
]
```

you can write:

```python
df.query(
    "amount > 500 and status == 'COMPLETE'"
)
```

This is often easier to read.

---

# 34. Pivot Tables

Suppose:

```text
region | product | revenue
Pune   | A       | 100
Pune   | B       | 200
Mumbai | A       | 300
Mumbai | B       | 400
```

You can create:

```python
pd.pivot_table(
    df,
    values="revenue",
    index="region",
    columns="product",
    aggfunc="sum"
)
```

Useful for analytical transformations.

---

# 35. Melt — Wide to Long

Suppose:

```text
customer | Jan | Feb | Mar
101      | 100 | 200 | 300
```

Convert to:

```text
customer | month | revenue
101      | Jan   | 100
101      | Feb   | 200
101      | Mar   | 300
```

Use:

```python
pd.melt(
    df,
    id_vars=["customer"],
    var_name="month",
    value_name="revenue"
)
```

This is called **unpivoting**.

---

# 36. Window-Like Operations

Pandas can perform operations similar to SQL window functions.

Suppose:

```text
customer_id | order_date | amount
101         | Jan 1      | 500
101         | Jan 2      | 700
101         | Jan 3      | 300
```

Calculate cumulative amount:

```python
df["running_total"] = (
    df.groupby("customer_id")["amount"]
      .cumsum()
)
```

Result:

```text
customer | amount | running_total
101      | 500    | 500
101      | 700    | 1200
101      | 300    | 1500
```

This is similar to:

```sql
SUM(amount) OVER (
    PARTITION BY customer_id
    ORDER BY order_date
)
```

Make sure the data is sorted appropriately before order-dependent operations:

```python
df = df.sort_values(
    ["customer_id", "order_date"]
)

df["running_total"] = (
    df.groupby("customer_id")["amount"]
      .cumsum()
)
```

---

# 37. Ranking

```python
df["rank"] = (
    df.groupby("customer_id")["amount"]
      .rank(
          method="dense",
          ascending=False
      )
)
```

Conceptually similar to SQL:

```sql
DENSE_RANK() OVER (
    PARTITION BY customer_id
    ORDER BY amount DESC
)
```

---

# 38. `shift()`

Very useful for comparing current and previous rows.

```python
df["previous_amount"] = df["amount"].shift(1)
```

Example:

```text
amount | previous_amount
500    | NaN
700    | 500
300    | 700
```

Within customers:

```python
df["previous_amount"] = (
    df.groupby("customer_id")["amount"]
      .shift(1)
)
```

This is similar to SQL `LAG()`.

---

# 39. Difference Between Current and Previous Value

```python
df["change"] = (
    df["amount"] -
    df["previous_amount"]
)
```

Or, more directly:

```python
df["change"] = (
    df.groupby("customer_id")["amount"]
      .diff()
)
```

Very useful for:

- incremental processing
- trend analysis
- transaction comparison
- detecting changes

---

# 40. Rolling / Moving Calculations

Pandas can perform rolling-window calculations.

Example:

```python
df["rolling_3_avg"] = (
    df["amount"]
      .rolling(3)
      .mean()
)
```

Within each customer:

```python
df["rolling_3_avg"] = (
    df.groupby("customer_id")["amount"]
      .rolling(3)
      .mean()
      .reset_index(level=0, drop=True)
)
```

Conceptually this can be related to SQL window frames.

---

# 41. Reading Multiple Files

Imagine:

```text
data/
    orders_2026_01.csv
    orders_2026_02.csv
    orders_2026_03.csv
```

You can use Python's `glob`.

```python
import glob
import pandas as pd

files = glob.glob("data/orders_*.csv")

dfs = []

for file in files:
    df = pd.read_csv(file)
    dfs.append(df)

orders = pd.concat(
    dfs,
    ignore_index=True
)
```

This is a common simple ETL pattern.

---

# 42. Loading Data

After transformation, you need to load the result.

## CSV

```python
df.to_csv(
    "output/orders_clean.csv",
    index=False
)
```

## Parquet

```python
df.to_parquet(
    "output/orders.parquet",
    index=False
)
```

For Data Engineering, **Parquet is generally much more suitable than CSV** for analytical data because it is columnar and preserves data types.

---

# 43. Loading Into a Database

Using SQLAlchemy:

```python
df.to_sql(
    "orders",
    engine,
    if_exists="append",
    index=False
)
```

Possible values:

```text
if_exists="fail"
if_exists="replace"
if_exists="append"
```

For example:

```python
df.to_sql(
    "orders",
    engine,
    if_exists="append",
    index=False
)
```

means:

> Insert the DataFrame rows into the existing orders table.

For production workloads, database-specific bulk-loading mechanisms may be more efficient than row-oriented inserts through `to_sql()`.

---

# 44. Complete Pandas ETL Example

Imagine we receive:

```text
customers.csv
orders.csv
```

### customers.csv

```text
customer_id,name,city
101, John ,Pune
102,Alice,Mumbai
103,Bob,Pune
```

### orders.csv

```text
order_id,customer_id,amount,status,order_date
1,101,500,COMPLETE,2026-01-01
2,101,700,COMPLETE,2026-01-02
3,102,300,CANCELLED,2026-01-03
4,103,900,COMPLETE,2026-01-04
```

Our ETL:

```python
import pandas as pd

# --------------------------------
# 1. EXTRACT
# --------------------------------

customers = pd.read_csv("customers.csv")
orders = pd.read_csv("orders.csv")


# --------------------------------
# 2. CLEAN CUSTOMERS
# --------------------------------

customers["name"] = (
    customers["name"]
    .str.strip()
    .str.title()
)


# --------------------------------
# 3. CLEAN ORDERS
# --------------------------------

orders["order_date"] = pd.to_datetime(
    orders["order_date"]
)

orders["amount"] = orders["amount"].astype(float)


# --------------------------------
# 4. REMOVE DUPLICATES
# --------------------------------

orders = orders.drop_duplicates(
    subset=["order_id"]
)


# --------------------------------
# 5. FILTER VALID ORDERS
# --------------------------------

orders = orders[
    orders["status"] == "COMPLETE"
]


# --------------------------------
# 6. JOIN CUSTOMER DATA
# --------------------------------

orders = orders.merge(
    customers,
    on="customer_id",
    how="left"
)


# --------------------------------
# 7. DERIVE COLUMNS
# --------------------------------

orders["year"] = (
    orders["order_date"].dt.year
)

orders["month"] = (
    orders["order_date"].dt.month
)


# --------------------------------
# 8. AGGREGATION
# --------------------------------

customer_summary = (
    orders
    .groupby(["customer_id", "name"])
    .agg(
        total_revenue=("amount", "sum"),
        order_count=("order_id", "count"),
        avg_order_value=("amount", "mean")
    )
    .reset_index()
)


# --------------------------------
# 9. LOAD
# --------------------------------

customer_summary.to_parquet(
    "customer_summary.parquet",
    index=False
)
```

---

# 45. What Happens in This Pipeline?

Think about it as:

```text
customers.csv ───────┐
                     │
                     ▼
                  EXTRACT
                     │
orders.csv ──────────┘
                     │
                     ▼
                   CLEAN
                     │
                     ▼
               DEDUPLICATE
                     │
                     ▼
                  FILTER
                     │
                     ▼
                   JOIN
                     │
                     ▼
              DERIVE COLUMNS
                     │
                     ▼
                AGGREGATE
                     │
                     ▼
                  PARQUET
```

This is a genuine small-scale ETL pipeline.

---

# 46. A More Realistic Production-Style Structure

Instead of putting everything in one script, you can separate responsibilities.

```text
pandas_etl/
│
├── config/
│   └── config.yaml
│
├── data/
│   ├── raw/
│   └── processed/
│
├── src/
│   ├── extract.py
│   ├── transform.py
│   ├── validate.py
│   ├── load.py
│   └── pipeline.py
│
├── logs/
│
└── requirements.txt
```

## `extract.py`

```python
import pandas as pd

def extract_orders(path):
    return pd.read_csv(path)
```

## `transform.py`

```python
def transform_orders(df):

    df["order_date"] = pd.to_datetime(
        df["order_date"]
    )

    df = df.drop_duplicates(
        subset=["order_id"]
    )

    df = df[
        df["status"] == "COMPLETE"
    ]

    return df
```

## `validate.py`

```python
def validate_orders(df):

    required_columns = [
        "order_id",
        "customer_id",
        "amount"
    ]

    missing_columns = [
        col
        for col in required_columns
        if col not in df.columns
    ]

    if missing_columns:
        raise ValueError(
            f"Missing columns: {missing_columns}"
        )

    if df["customer_id"].isna().any():
        raise ValueError(
            "customer_id contains NULL values"
        )

    if (df["amount"] < 0).any():
        raise ValueError(
            "Negative amounts found"
        )

    if df["order_id"].duplicated().any():
        raise ValueError(
            "Duplicate order_id found"
        )

    return True
```

## `load.py`

```python
def load_orders(df, path):

    df.to_parquet(
        path,
        index=False
    )
```

## `pipeline.py`

```python
from extract import extract_orders
from transform import transform_orders
from validate import validate_orders
from load import load_orders


def run_pipeline():

    df = extract_orders(
        "data/raw/orders.csv"
    )

    df = transform_orders(df)

    validate_orders(df)

    load_orders(
        df,
        "data/processed/orders.parquet"
    )


if __name__ == "__main__":
    run_pipeline()
```

This is much closer to how you would structure an actual ETL application.

---

# 47. Pandas vs SQL vs PySpark

Since you're preparing for Data Engineering interviews, this comparison is important.

| Operation | Pandas | SQL | PySpark |
|---|---|---|---|
| Filter | `df[df.x > 10]` | `WHERE x > 10` | `filter()` |
| Select | `df[["a","b"]]` | `SELECT a,b` | `select()` |
| Join | `merge()` | `JOIN` | `join()` |
| Group | `groupby()` | `GROUP BY` | `groupBy()` |
| Aggregate | `agg()` | `SUM()` etc. | `agg()` |
| Sort | `sort_values()` | `ORDER BY` | `orderBy()` |
| Dedup | `drop_duplicates()` | `DISTINCT` / window logic | `dropDuplicates()` |
| Null handling | `fillna()` | `COALESCE()` | `fillna()` |
| Union | `concat()` | `UNION ALL` | `union()` |
| Window | `groupby()+cumsum()` etc. | Window functions | `Window` |
| Read CSV | `read_csv()` | DB-dependent | `spark.read.csv()` |
| Write Parquet | `to_parquet()` | DB-dependent | `write.parquet()` |

---

# 48. Pandas vs PySpark — The Most Important Difference

The fundamental difference is **scale and execution model**.

## Pandas

```text
Data
 ↓
Usually memory of one machine
 ↓
CPU/RAM of that machine
 ↓
Result
```

## Spark

```text
                 Driver
                   │
          ┌────────┼────────┐
          ▼        ▼        ▼
      Executor  Executor  Executor
          │        │        │
       Data      Data      Data
```

Spark distributes processing across machines/executors.

Therefore:

> **Pandas is generally appropriate when the dataset comfortably fits within available memory and the processing requirements are manageable on one machine. Spark is designed for distributed processing of much larger datasets.**

Pandas can also process larger-than-memory data in some specialized approaches, but standard Pandas DataFrames are primarily in-memory, so memory constraints remain an important consideration.

---

# 49. Pandas Is Not Lazy

This is an important difference from Spark.

In Spark:

```python
df.filter(...)
df.select(...)
```

are transformations and Spark builds a logical plan.

Execution happens when you call an action such as:

```python
df.count()
df.show()
df.collect()
```

Pandas generally executes operations immediately.

For example:

```python
df["revenue"] = df["price"] * df["quantity"]
```

The computation happens immediately.

So:

```text
Spark → lazy evaluation
Pandas → eager/immediate execution
```

---

# 50. Pandas Vectorization

A very important performance concept.

Prefer:

```python
df["total"] = df["price"] * df["quantity"]
```

over:

```python
df["total"] = df.apply(
    lambda row: row["price"] * row["quantity"],
    axis=1
)
```

The first uses vectorized operations and is generally more efficient.

For large Pandas datasets, avoid unnecessary Python-level loops.

---

# 51. Data Validation in ETL

A production pipeline should not simply transform data.

It should validate it.

For example:

```python
assert df["customer_id"].notna().all()
```

Check duplicates:

```python
assert not df["order_id"].duplicated().any()
```

Check amounts:

```python
assert (df["amount"] >= 0).all()
```

Check required columns:

```python
required_columns = [
    "order_id",
    "customer_id",
    "amount"
]

assert all(
    col in df.columns
    for col in required_columns
)
```

In production, explicit exceptions with useful error messages are often preferable to bare `assert` statements for critical data-quality checks.

---

# 52. Handling Bad Records

A mature ETL pipeline might separate:

```text
                 Raw Data
                     │
              ┌──────┴──────┐
              │             │
           Valid          Invalid
              │             │
              ▼             ▼
        Processed        Rejects
              │
              ▼
            Target
```

For example:

```python
valid = df[
    df["customer_id"].notna() &
    (df["amount"] >= 0)
]

invalid = df[
    df["customer_id"].isna() |
    (df["amount"] < 0)
]
```

Then:

```python
valid.to_parquet(
    "valid/orders.parquet"
)

invalid.to_csv(
    "rejects/orders.csv",
    index=False
)
```

This is a useful production pattern.

You can also add a rejection reason:

```python
invalid = df[
    df["customer_id"].isna() |
    (df["amount"] < 0)
].copy()

invalid["reject_reason"] = np.select(
    [
        invalid["customer_id"].isna(),
        invalid["amount"] < 0
    ],
    [
        "Missing customer_id",
        "Negative amount"
    ],
    default="Unknown"
)
```

---

# 53. Incremental ETL with Pandas

Suppose your source has:

```text
order_id
order_date
updated_at
```

You don't want to process the entire dataset every day.

You can filter:

```python
last_processed = "2026-09-20"

df = df[
    df["updated_at"] > last_processed
]
```

Then process only changed records.

Conceptually:

```text
Source
  │
  ├── old records → skip
  │
  └── new/updated records
            ↓
         Pandas
            ↓
          Target
```

In real production systems, the watermark would usually come from a metadata/control table rather than a hardcoded string.

A more robust approach is to convert the timestamp explicitly:

```python
df["updated_at"] = pd.to_datetime(
    df["updated_at"]
)

last_processed = pd.Timestamp(
    "2026-09-20"
)

incremental_df = df[
    df["updated_at"] > last_processed
]
```

---

# 54. Pandas in a Real Data Engineering Architecture

A possible architecture:

```text
                  SOURCE SYSTEMS
                        │
             ┌──────────┼──────────┐
             ▼          ▼          ▼
           API         CSV        DB
             │          │          │
             └──────────┼──────────┘
                        ▼
                   RAW / BRONZE
                        │
                        ▼
                  PANDAS ETL
                        │
          ┌─────────────┼─────────────┐
          ▼             ▼             ▼
       Clean          Join         Validate
          │             │             │
          └─────────────┼─────────────┘
                        ▼
                 PROCESSED DATA
                        │
                        ▼
                    PARQUET
                        │
                        ▼
                  DATA LAKE / DB
                        │
                        ▼
                 ANALYTICS / BI
```

For larger workloads, you would often replace the Pandas processing layer with Spark, SQL/dbt, or another distributed/warehouse-native processing approach.

---

# 55. Pandas Operations You Should Know for Interviews

## Reading/Writing

```python
pd.read_csv()
pd.read_json()
pd.read_parquet()
pd.read_sql()

df.to_csv()
df.to_parquet()
df.to_sql()
```

## Exploration

```python
head()
tail()
info()
describe()
shape
columns
dtypes
```

## Selection

```python
df["column"]
df[["col1", "col2"]]
loc[]
iloc[]
```

## Filtering

```python
df[df["amount"] > 100]
query()
isin()
between()
```

## Transformation

```python
assign()
apply()
map()
replace()
astype()
str.*
dt.*
```

## Missing Data

```python
isna()
isnull()
notna()
fillna()
dropna()
```

## Deduplication

```python
drop_duplicates()
duplicated()
```

## Aggregation

```python
groupby()
agg()
sum()
mean()
count()
min()
max()
```

## Joining

```python
merge()
join()
concat()
```

## Reshaping

```python
pivot()
pivot_table()
melt()
```

## Window-like Operations

```python
shift()
rank()
cumsum()
cumcount()
rolling()
diff()
```

## Sorting

```python
sort_values()
sort_index()
```

## Dates

```python
pd.to_datetime()
dt.year
dt.month
dt.day
dt.date
dt.day_name()
```

---

# 56. How to Learn Pandas for Data Engineering

Since the goal is **Data Engineering rather than Data Science**, don't spend too much time on plotting or machine-learning-related Pandas functionality.

Focus on this sequence:

```text
1. DataFrame / Series
        ↓
2. Read / Write
        ↓
3. Select / Filter
        ↓
4. Data Cleaning
        ↓
5. Type Conversion
        ↓
6. String Operations
        ↓
7. Date Operations
        ↓
8. Deduplication
        ↓
9. GroupBy / Aggregation
        ↓
10. Merge / Join
        ↓
11. Concat
        ↓
12. Pivot / Melt
        ↓
13. Window-like Operations
        ↓
14. Validation
        ↓
15. Incremental Processing
        ↓
16. Build Complete ETL
        ↓
17. Orchestrate with Airflow
```

---

# 57. Key Interview Mental Model

When an interviewer asks:

> "How would you build an ETL pipeline using Pandas?"

Think:

```text
1. EXTRACT
   ↓
   Read CSV/API/DB/JSON/Parquet

2. PROFILE
   ↓
   shape, info, dtypes, nulls, duplicates

3. CLEAN
   ↓
   null handling
   type conversion
   string cleaning
   date conversion

4. TRANSFORM
   ↓
   filters
   derived columns
   business rules

5. JOIN
   ↓
   merge customer/product/reference data

6. DEDUPLICATE
   ↓
   business key + latest timestamp

7. AGGREGATE
   ↓
   groupby + agg

8. VALIDATE
   ↓
   schema
   nulls
   duplicates
   ranges
   row counts

9. LOAD
   ↓
   Parquet / database / data lake

10. ORCHESTRATE
   ↓
   Airflow / scheduler

11. MONITOR
   ↓
   logs
   metrics
   alerts
```

This is the complete ETL mindset.

---

# 58. Pandas vs PySpark vs SQL — When to Use What?

| Situation | Pandas | SQL | PySpark |
|---|---|---|---|
| Small file processing | Excellent | Possible | Usually unnecessary |
| Local data cleaning | Excellent | Possible | Usually unnecessary |
| Database transformation | Possible | Excellent | Possible |
| Large relational transformations in warehouse | Not ideal | Excellent | Possible |
| Very large datasets | Limited by memory | Depends on warehouse | Excellent |
| Distributed processing | No | Depends on platform | Yes |
| Quick prototyping | Excellent | Excellent | More setup |
| API extraction | Excellent | No | Possible |
| Complex ETL on large data lake | Usually not ideal | Depends | Excellent |
| Data engineering learning | Excellent foundation | Essential | Essential |

The important point is:

> **Pandas is one tool in a Data Engineer's toolkit, not the universal replacement for SQL or Spark.**

---

# 59. How Pandas Relates to Your Data Engineering Stack

If your stack includes:

```text
Python
Pandas
SQL
Spark / PySpark
Airflow
dbt
Databricks
AWS
Git/GitHub
```

a useful mental model is:

```text
                    DATA SOURCES
                         │
               ┌─────────┴─────────┐
               │                   │
             APIs                  DB
               │                   │
               └─────────┬─────────┘
                         │
                    Python/Pandas
                  small-scale ETL
                         │
                         ▼
                    Raw / Bronze
                         │
                         ▼
                    Spark / SQL
                 large-scale ETL
                         │
                         ▼
                  Silver / Gold
                         │
                         ▼
                       dbt
               transformation/modeling
                         │
                         ▼
                    Data Warehouse
                         │
                         ▼
                    BI / Analytics

                    Airflow
                       │
              Orchestrates pipeline
```

Pandas can therefore be used for:

- API ingestion
- CSV processing
- Excel processing
- small reference datasets
- data validation
- preprocessing
- local ETL
- prototyping
- testing transformations
- preparing data before loading it elsewhere

---

# 60. Final Revision Cheat Sheet

```text
Pandas
│
├── Data Structures
│   ├── DataFrame
│   └── Series
│
├── Extract
│   ├── read_csv()
│   ├── read_json()
│   ├── read_parquet()
│   ├── read_excel()
│   └── read_sql()
│
├── Inspect
│   ├── head()
│   ├── tail()
│   ├── info()
│   ├── describe()
│   ├── shape
│   ├── columns
│   └── dtypes
│
├── Select
│   ├── []
│   ├── loc[]
│   └── iloc[]
│
├── Filter
│   ├── boolean conditions
│   ├── query()
│   ├── isin()
│   └── between()
│
├── Clean
│   ├── isna()
│   ├── fillna()
│   ├── dropna()
│   ├── replace()
│   └── drop_duplicates()
│
├── Transform
│   ├── astype()
│   ├── apply()
│   ├── map()
│   ├── str.*
│   ├── dt.*
│   └── np.where()
│
├── Aggregate
│   ├── groupby()
│   ├── agg()
│   ├── sum()
│   ├── count()
│   ├── mean()
│   ├── min()
│   └── max()
│
├── Join
│   ├── merge()
│   └── join()
│
├── Combine
│   └── concat()
│
├── Reshape
│   ├── pivot()
│   ├── pivot_table()
│   └── melt()
│
├── Window-like
│   ├── shift()
│   ├── rank()
│   ├── cumsum()
│   ├── diff()
│   └── rolling()
│
├── Validate
│   ├── schema
│   ├── null checks
│   ├── duplicate checks
│   ├── range checks
│   └── referential checks
│
└── Load
    ├── to_csv()
    ├── to_parquet()
    └── to_sql()
```

## Most Important Interview Comparisons

```text
Pandas             SQL                 PySpark
-------------------------------------------------------
filter             WHERE               filter()
merge              JOIN                join()
groupby            GROUP BY            groupBy()
agg                aggregate           agg()
sort_values        ORDER BY            orderBy()
concat             UNION ALL           union()
drop_duplicates    DISTINCT/dedup      dropDuplicates()
fillna             COALESCE            fillna()
shift              LAG                 lag()
rank               RANK/DENSE_RANK     rank()
cumsum             SUM OVER            sum + Window
```

## Most Important Concept

Remember:

> **Pandas is an in-memory, Python-based tabular data-processing library. It is excellent for small-to-medium ETL workloads, local processing, API/file ingestion, data cleaning, validation, transformation, and prototyping. For large distributed datasets, Spark or warehouse-native SQL is generally more appropriate.**

For Data Engineering interviews, learn Pandas not just as a collection of commands, but as a way to implement the complete:

**Extract → Profile → Clean → Transform → Join → Deduplicate → Aggregate → Validate → Load → Orchestrate → Monitor**

ETL lifecycle.
