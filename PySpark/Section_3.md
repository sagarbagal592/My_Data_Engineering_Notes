# Transformations (select, filter, withColumn, when/otherwise)

## select -> choosing and transforming columns

```py
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, when, lit, upper, concat, year, current_date

spark = SparkSession.builder.master("local[*]").getOrCreate()

data = [
    (1, "alice", "engineering", 95000, "2022-03-15", "active"),
    (2, "bob", "marketing", 72000, "2021-07-01", "active"),
    (3, "carol", "engineering", 110000, "2019-11-20", "active"),
    (4, "dave", "sales", 68000, "2023-01-10", "inactive"),
    (5, "eve", "engineering", 125000, "2018-06-05", "active"),
    (6, "frank", "marketing", 78000, "2022-09-12", "inactive"),
]

df = spark.createDataFrame(
    data,
    schema=["emp_id", "name", "department", "salary", "hire_date", "status"]
)

```
- `select` is how you pick which columns to keep and how to reshape them. It is the PySpark equivalent of a SQL SELECT clause.
- We can write select statement in following ways-
```py
df.select('emp_id','name','salary').show()

df.select(df.emp_id, df.name, df.salary).show()

df.select(col('emp_id'), col('name'), col('salary')).show()
```

## Column expression in select

- select is not just for picking columns — it accepts full column expressions
```py
df.select(
    col('emp_id'),
    upper(col('name')).alias('name'),
    round(col('salary')/12,2).alias('monthly_salary'),
    concat(col('department'), lit('_team')).alias('team')
    ).show()
```

## Using actual SQL in PySpark with selectexpr

- Use `selectExpr` when translating SQL queries into PySpark. It is especially useful for CASE WHEN logic and type casting (CAST(salary AS DOUBLE)).

```py
df.selectExpr(
    "emp_id",
    "UPPER(name) AS name_upper",
    "salary / 12 AS monthly_salary",
    "CASE WHEN salary > 100000 THEN 'senior' ELSE 'standard' END AS band"
).show()

```
## filter/where ---> selecting rows

```py
# Single condition
df.filter(col("department") == "engineering").show()

# Equivalent
df.where(col("department") == "engineering").show()

#Multiple conditions

# AND — use &
df.filter(
    (col("department") == "engineering") & (col("salary") > 100000)
).show()

# OR — use |
df.filter(
    (col("department") == "engineering") | (col("department") == "marketing")
).show()

# NOT — use ~
df.filter(~(col("status") == "inactive")).show()

# Useful filter patterens

# IN list
df.filter(col("department").isin("engineering", "marketing")).show()

# NULL checks
df.filter(col("name").isNotNull()).show()
df.filter(col("name").isNull()).show()

# String patterns
df.filter(col("name").startswith("a")).show()
df.filter(col("name").contains("ar")).show()
df.filter(col("name").like("%ol")).show()  # SQL-style LIKE

# Between (inclusive)
df.filter(col("salary").between(70000, 100000)).show()

```

## withColumn ---> Adding or Replacing columns

- `withColumn` adds a new column (or replaces an existing one if the name matches)
```py
# Add a new column
df_with_bonus = df.withColumn("bonus", col("salary") * 0.1)

# Replace an existing column
df_upper = df.withColumn("name", upper(col("name")))


# Chaining Multiple withColumn Calls


result = (
    df
    .withColumn("bonus", col("salary") * 0.1)
    .withColumn("total_comp", col("salary") + col("bonus"))
    .withColumn("name", upper(col("name")))
    .withColumn("hire_year", year(col("hire_date")))
)
result.show()


# If you are on Spark 3.3 or later, withColumns lets you add multiple columns in a single call

result = df.withColumns({
    "bonus": col("salary") * 0.1,
    "name_upper": upper(col("name")),
    "hire_year": year(col("hire_date")),
})


```

## when/otherwise - conditional logic

- when is PySpark's equivalent of SQL's CASE WHEN. It is how you implement conditional column logic — categorization, bucketing, flag creation, null handling.

```py
df_with_band = df.withColumn(
    "salary_band",
    when(col("salary") >= 100000, "senior")
    .when(col("salary") >= 80000, "mid")
    .otherwise("junior")
)
df_with_band.select("name", "salary", "salary_band").show()


# Using when/otherwise inside select

df.select(
    col("emp_id"),
    col("name"),
    when(col("status") == "active", lit(1)).otherwise(lit(0)).alias("is_active"),
    when(col("salary") > 100000, col("salary") * 0.15)
        .otherwise(col("salary") * 0.10)
        .alias("bonus"),
).show()

```
## Renaming and Dropping Columns

- select and drop are two sides of the same coin: with select you name the columns to keep, with drop you name the ones to remove.

```py
# Rename
df.withColumnRenamed("DEST_COUNTRY_NAME", "dest").columns

# Drop one column
df.drop("ORIGIN_COUNTRY_NAME").columns

# Drop multiple
df.drop("ORIGIN_COUNTRY_NAME", "DEST_COUNTRY_NAME")
```



## Union — Appending Rows

- To append rows, both DataFrames must have the same schema and number of columns.

```py
from pyspark.sql import Row
newRows = [
    Row("New Country", "Other Country", 5),
    Row("New Country 2", "Other Country 3", 1)
]
newDF = spark.createDataFrame(newRows, df.schema)

df.union(newDF)\
    .where("count = 1")\
    .where(col("ORIGIN_COUNTRY_NAME") != "United States")\
    .show()

```

## Sorting rows

```py
from pyspark.sql.functions import desc, asc

df.sort("count").show(5)

df.orderBy("count", "DEST_COUNTRY_NAME").show(5)

df.orderBy(col("count").desc(), col("DEST_COUNTRY_NAME").asc()).show(2)
```
## Limit

```py
df.limit(5).show()

df.orderBy(expr("count desc")).limit(6).show()

```


## Key Takeaways
- Use `col("name")` consistently — it works everywhere and handles special characters
- `select` accepts full column expressions, not just column names — use it for projections and renaming with `.alias()`
- `selectExpr` lets you write SQL expressions as strings — great for quick aggregations and computed columns
- filter conditions must be wrapped in parentheses when using & (AND), | (OR), or ~ (NOT)
- `withColumn` returns a new DataFrame — the original is unchanged — and Catalyst optimizes chained calls into a single pass
- `when/otherwise` is your `CASE WHEN`, Always include `.otherwise()` explicitly to avoid silent nulls
- Use `repartition` to increase partitions or partition by column, `coalesce` to reduce without shuffle
- Never call `collect()` on large datasets — use `take()` or `limit().show()` for debugging
