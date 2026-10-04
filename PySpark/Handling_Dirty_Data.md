# Handling Dirty Data in Spark

- Production data is dirty. Not sometimes — always. Source systems send nulls where you expect values. Upstream teams change string formats without notice. CDC streams deliver duplicates on every rebalance. A column that was integers for two years suddenly contains the string "N/A" because someone edited a Google Sheet.

## Null Handling
- Nulls are the most common data quality issue and the most dangerous because they propagate silently. Any arithmetic on a null produces null. Any comparison with null returns null (not false). A join on a null key matches nothing. Your aggregation quietly drops null rows without warning.
## Detecting Nulls
```py
from pyspark.sql.functions import col, isnan, when, count

# Check for nulls in specific columns
df.filter(col("customer_id").isNull()).count()

# Count nulls per column across the entire DataFrame
df.select([
    count(when(col(c).isNull(), c)).alias(c)
    for c in df.columns
]).show()

# Check for both null AND NaN (common in float columns from pandas conversions)
df.filter(col("amount").isNull() | isnan(col("amount"))).count()

```
## Difference between Null and NaN
- PySpark distinguishes between null (missing value) and NaN (not a number, a special float value). isNull() catches nulls but not NaN. isnan() catches NaN but not nulls. When cleaning float columns — especially data that originated from pandas or CSV files — check for both. A column can contain a mix of nulls and NaN values that behave differently in aggregations.

## Use of fillna

- fillna() means: Find NULL values and replace them with the value I provide.

```py
df_clean = df.fillna({
    "customer_name": "Unknown",
    "amount": 0,
    "country_code": "XX",
    })

 # with coslesce we can write it as

 df.withColumn(
    "customer_name",
    coalesce(col("customer_name"), lit("Unknown"))
)
```

## Use of coalesce

- coalesce() = "Give me the first non-NULL value."
- coalesce() returns the first non-NULL value from left to right.
```py

df_clean = df.withColumn(
    "effective_email",
    coalesce(
        col("primary_email"),
        col("secondary_email"),
        lit("no-email@placeholder.com")
    )
)

# We have its SQL equivalent code as

COALESCE(
    primary_email,
    secondary_email,
    'no-email@placeholder.com'
)
```
- Think: Try primary → if NULL, try secondary → if NULL, use default.
- Example
```text
        primary_email       secondary_email
        ------------------------------------------
        a@gmail.com         b@gmail.com
        NULL                b@gmail.com
        NULL                NULL
        c@gmail.com         d@gmail.com
```
- after using above code, you get
```text
        effective_email
        ---------------------------
        a@gmail.com
        b@gmail.com
        no-email@placeholder.com
        c@gmail.com
```
```py
# Suppose you have  
coalesce(
    col("customer_name"),
    lit("Unknown")
    )

# Think of it as

        Option 1             Option 2
        ↓                     ↓
        customer_name       "Unknown"


 For each row

  Case 1:

            customer_name = "John"

            coalesce("John", "Unknown")
                    ↓
                "John"
 Case 2:

            customer_name = NULL

            coalesce(NULL, "Unknown")
                    ↓
                "Unknown"

#   Think coalesce() chooses the first non-NULL value from the arguments
```

- Another example for coalesce
```py
df_clean = df.withColumn(
    "display_name",
    coalesce(col("preferred_name"), col("full_name"), col("username"))
)
```

- When to use fillna vs coalesce: Use fillna when you want to replace nulls with a fixed default. Use coalesce when you have multiple candidate columns and want to pick the first non-null one. In practice, coalesce is more common in production because it handles the "fallback chain" pattern that appears everywhere in real data.

## Conditional Null Handling with when

```py
from pyspark.sql.functions import when

# Replace nulls conditionally based on other column values

df_clean = df.withColumn(
    "amount",
    when(col("amount").isNull() & (col("status") == "cancelled"), lit(0))
    .when(col("amount").isNull() & (col("status") == "pending"), lit(-1))
    .otherwise(col("amount"))
)

```