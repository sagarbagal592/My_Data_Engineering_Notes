# Aggregations
- A critical thing to internalize: every `groupBy` triggers a shuffle. Spark must redistribute data across the cluster so that all rows belonging to the same group land on the same partition. This is expensive. Understanding aggregations means understanding both the API and the performance cost underneath.

```py
from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col, count, sum, avg, min, max,
    countDistinct, approx_count_distinct,
    round, first, collect_list, collect_set,
    expr
)

import os
import sys

os.environ["PYSPARK_PYTHON"] = sys.executable
os.environ["PYSPARK_DRIVER_PYTHON"] = sys.executable

print("Python:", sys.executable)

from pyspark.sql import SparkSession

spark = (
    SparkSession.builder
    .appName("PySpark_Test_1")
    .master("local[*]")
    .config("spark.pyspark.python", sys.executable)
    .config("spark.pyspark.driver.python", sys.executable)
    .getOrCreate()
)

data = [
    ("2026-03-01", "electronics", "laptop", 1200.00, 3),
    ("2026-03-01", "electronics", "phone", 800.00, 7),
    ("2026-03-01", "clothing", "jacket", 150.00, 12),
    ("2026-03-01", "clothing", "shoes", 90.00, 20),
    ("2026-03-02", "electronics", "laptop", 1200.00, 5),
    ("2026-03-02", "electronics", "tablet", 600.00, 4),
    ("2026-03-02", "clothing", "jacket", 150.00, 8),
    ("2026-03-02", "clothing", "shoes", 90.00, 15),
    ("2026-03-03", "electronics", "phone", 800.00, 6),
    ("2026-03-03", "clothing", "jacket", 150.00, 10),
    ("2026-03-03", "clothing", "shoes", 90.00, 18),
    ("2026-03-03", "electronics", "laptop", 1200.00, 2),
]

df = spark.createDataFrame(
    data,
    schema=["order_date", "category", "product", "unit_price", "quantity"]
)

```

## groupBy + agg --> The core pattern

```py
df.groupBy("category").agg(
    count("*").alias("total_orders"),
    sum("quantity").alias("total_units"),
    round(avg("unit_price"), 2).alias("avg_price"),
).show()

```
- You can write `df.groupBy("category").count()` or `df.groupBy("category").sum("quantity")` — but these only compute a single aggregate at a time. In production, you almost always need multiple metrics per group. The .agg() method lets you compute them all in one pass.
- Always use `.agg()` with explicit `.alias()` for every aggregate column. Without aliases, Spark generates names like sum(quantity) and avg(unit_price) — these break downstream code that references columns by name and make your schema unreadable.

## Built-in Aggregate Functions

![alt text](image-6.png)