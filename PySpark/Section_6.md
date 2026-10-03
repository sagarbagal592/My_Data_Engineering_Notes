# Window Functions
- A Window Function performs a calculation across a group of related rows without collapsing those rows into a single row
- Compute rankings, running totals, lead/lag, and moving averages with window functions.

## The Window Spec: partitionBy + orderBy + Frame

- Every window function in PySpark operates on a Window spec that defines three things:

1. `partitionBy` — which groups of rows to compute over (like GROUP BY, but without collapsing)
2. `orderBy` — the order of rows within each partition
3. `Frame` — which rows relative to the current row to include in the computation


# PySpark Window Functions — Detailed Explanation

A **Window Function** performs a calculation across a group of related rows **without collapsing those rows into a single row**.

That last part is the most important concept.

## Compare `groupBy()` vs Window

Suppose we have:

| employee | department | salary |
|---|---|---:|
| A | IT | 50000 |
| B | IT | 70000 |
| C | IT | 60000 |
| D | HR | 40000 |
| E | HR | 50000 |

If we do:

```python
df.groupBy("department").agg(
    avg("salary").alias("avg_salary")
)
```

we get:

| department | avg_salary |
|---|---:|
| IT | 60000 |
| HR | 45000 |

`groupBy()` **reduces multiple rows into one row per group**.

But if we use a window:

```python
from pyspark.sql.window import Window
from pyspark.sql.functions import avg

window_spec = Window.partitionBy("department")

df.withColumn(
    "avg_salary",
    avg("salary").over(window_spec)
)
```

we get:

| employee | department | salary | avg_salary |
|---|---|---:|---:|
| A |   IT | 50000 | 60000 |
| B | IT | 70000 | 60000 |
| C | IT | 60000 | 60000 |
| D | HR | 40000 | 45000 |
| E | HR | 50000 | 45000 |

The original rows are preserved.

---

# 1. What is a Window?

A window defines **which rows should be considered when calculating a value for each row**.

The basic structure is:

```python
Window.partitionBy(...).orderBy(...)
```

Then we apply a function using:

```python
function(...).over(window_spec)
```

For example:

```python
window_spec = Window \
    .partitionBy("department") \
    .orderBy("salary")
```

and:

```python
row_number().over(window_spec)
```

---

# 2. Three Important Parts of a Window

You should understand these three concepts very clearly:

```text
Window
  |
  +-- partitionBy()
  |
  +-- orderBy()
  |
  +-- frame
```

Let's understand each one.

---

# 3. `partitionBy()`

`partitionBy()` determines **which rows belong to the same logical group/window**.

Example:

```python
window_spec = Window.partitionBy("department")
```

For our data:

```text
IT
 ├── A
 ├── B
 └── C

HR
 ├── D
 └── E
```

Each department gets its own window.

So:

```python
avg("salary").over(window_spec)
```

calculates the average salary **within each department**.

---

# 4. `orderBy()`

`orderBy()` determines the **ordering of rows inside each partition**.

For example:

```python
window_spec = Window \
    .partitionBy("department") \
    .orderBy("salary")
```

For IT:

```text
A   50000
C   60000
B   70000
```

For HR:

```text
D   40000
E   50000
```

The ordering becomes important for functions such as:

- `row_number()`
- `rank()`
- `dense_rank()`
- `lag()`
- `lead()`
- running totals
- cumulative averages

---

# 5. Simple Example

Let's create a DataFrame.

```python
data = [
    ("A", "IT", 50000),
    ("B", "IT", 70000),
    ("C", "IT", 60000),
    ("D", "HR", 40000),
    ("E", "HR", 50000)
]

columns = ["employee", "department", "salary"]

df = spark.createDataFrame(data, columns)
```

Data:

```text
+--------+----------+------+
|employee|department|salary|
+--------+----------+------+
|A       |IT        |50000 |
|B       |IT        |70000 |
|C       |IT        |60000 |
|D       |HR        |40000 |
|E       |HR        |50000 |
+--------+----------+------+
```

---

# 6. Average Salary Using Window

```python
from pyspark.sql.window import Window
from pyspark.sql.functions import avg

window_spec = Window.partitionBy("department")

df = df.withColumn(
    "avg_salary",
    avg("salary").over(window_spec)
)
```

Result:

```text
+--------+----------+------+----------+
|employee|department|salary|avg_salary|
+--------+----------+------+----------+
|A       |IT        |50000 |60000     |
|B       |IT        |70000 |60000     |
|C       |IT        |60000 |60000     |
|D       |HR        |40000 |45000     |
|E       |HR        |50000 |45000     |
+--------+----------+------+----------+
```

Notice:

**No `orderBy()` is required here.**

Why?

Because we're simply calculating an aggregate across the entire partition.

---

# 7. Window Ranking Functions

This is one of the most common interview topics.

Suppose:

```text
employee department salary
A        IT         50000
B        IT         70000
C        IT         60000
D        HR         40000
E        HR         50000
```

We want to rank employees by salary **within each department**.

```python
from pyspark.sql.functions import row_number

window_spec = Window \
    .partitionBy("department") \
    .orderBy("salary")

df.withColumn(
    "rank",
    row_number().over(window_spec)
)
```

Result:

```text
IT:

A  50000  1
C  60000  2
B  70000  3

HR:

D  40000  1
E  50000  2
```

---

# 8. `row_number()`

`row_number()` assigns a unique sequential number.

```python
row_number().over(window_spec)
```

Example:

| employee | salary | row_number |
|---|---:|---:|
| A | 50000 | 1 |
| C | 60000 | 2 |
| B | 70000 | 3 |

Even if two employees have the same salary, they receive different numbers.

---

# 9. `rank()`

Now suppose:

```text
A  50000
B  70000
C  70000
D  60000
```

Using:

```python
rank().over(window_spec)
```

we get:

| employee | salary | rank |
|---|---:|---:|
| A | 50000 | 1 |
| D | 60000 | 2 |
| B | 70000 | 3 |
| C | 70000 | 3 |

Notice the tie.

Both B and C get rank `3`.

The next rank would be `5`.

This is called **gapped ranking**.

---

# 10. `dense_rank()`

```python
dense_rank().over(window_spec)
```

For:

```text
A 50000
D 60000
B 70000
C 70000
E 80000
```

### `rank()`

```text
50000 → 1
60000 → 2
70000 → 3
70000 → 3
80000 → 5
```

### `dense_rank()`

```text
50000 → 1
60000 → 2
70000 → 3
70000 → 3
80000 → 4
```

### Interview shortcut

```text
row_number()
    ↓
No ties

rank()
    ↓
Ties + gaps

dense_rank()
    ↓
Ties + no gaps
```

---

# 11. `lag()`

`lag()` lets you access a **previous row**.

Suppose:

| date | sales |
|---|---:|
| Jan 1 | 100 |
| Jan 2 | 150 |
| Jan 3 | 120 |
| Jan 4 | 200 |

We want the previous day's sales.

```python
from pyspark.sql.functions import lag

window_spec = Window.orderBy("date")

df.withColumn(
    "previous_sales",
    lag("sales").over(window_spec)
)
```

Result:

| date | sales | previous_sales |
|---|---:|---:|
| Jan 1 | 100 | null |
| Jan 2 | 150 | 100 |
| Jan 3 | 120 | 150 |
| Jan 4 | 200 | 120 |

---

# 12. `lead()`

`lead()` is the opposite of `lag()`.

It gives you the **next row**.

```python
from pyspark.sql.functions import lead

df.withColumn(
    "next_sales",
    lead("sales").over(window_spec)
)
```

Result:

| date | sales | next_sales |
|---|---:|---:|
| Jan 1 | 100 | 150 |
| Jan 2 | 150 | 120 |
| Jan 3 | 120 | 200 |
| Jan 4 | 200 | null |

---

# 13. `lag()` with an Offset

You can specify how many rows to go back.

```python
lag("sales", 2)
```

means:

> Give me the value from two rows before.

Example:

```text
date    sales
Jan 1   100
Jan 2   150
Jan 3   120
Jan 4   200
```

```python
lag("sales", 2)
```

gives:

```text
Jan 1 → null
Jan 2 → null
Jan 3 → 100
Jan 4 → 150
```

---

# 14. Running Total

This is another extremely important window-function use case.

Suppose:

| date | sales |
|---|---:|
| Jan 1 | 100 |
| Jan 2 | 200 |
| Jan 3 | 150 |
| Jan 4 | 300 |

We want:

```text
Jan 1 → 100
Jan 2 → 300
Jan 3 → 450
Jan 4 → 750
```

We can use:

```python
from pyspark.sql.functions import sum

window_spec = Window \
    .orderBy("date") \
    .rowsBetween(
        Window.unboundedPreceding,
        Window.currentRow
    )

df.withColumn(
    "running_total",
    sum("sales").over(window_spec)
)
```

Result:

| date | sales | running_total |
|---|---:|---:|
| Jan 1 | 100 | 100 |
| Jan 2 | 200 | 300 |
| Jan 3 | 150 | 450 |
| Jan 4 | 300 | 750 |

---

# 15. Understanding `rowsBetween()`

This:

```python
.rowsBetween(
    Window.unboundedPreceding,
    Window.currentRow
)
```

means:

> Start from the first row in the window and continue until the current row.

For Jan 3:

```text
Jan 1
Jan 2
Jan 3 ← current row
```

So:

```text
100 + 200 + 150 = 450
```

---

# 16. Why Do We Need a Window Frame?

A window can have:

```text
PARTITION
    |
    +-----------------------+
    |       Window          |
    |                       |
    |  rows considered      |
    |  for current row      |
    +-----------------------+
```

The **window frame** determines which rows inside that partition are considered for the calculation of the current row.

---

# 17. `rowsBetween()`

You can explicitly define the frame.

For example:

```python
.rowsBetween(-2, 0)
```

means:

> Current row + previous 2 rows.

Suppose:

```text
sales

100
200
300
400
500
```

Then:

| sales | frame |
|---:|---|
| 100 | 100 |
| 200 | 100, 200 |
| 300 | 100, 200, 300 |
| 400 | 200, 300, 400 |
| 500 | 300, 400, 500 |

This is useful for **moving averages**.

---

# 18. Moving Average

Suppose we want a 3-day moving average.

```python
from pyspark.sql.functions import avg

window_spec = Window \
    .orderBy("date") \
    .rowsBetween(-2, 0)

df.withColumn(
    "moving_avg",
    avg("sales").over(window_spec)
)
```

For:

```text
100
200
300
400
500
```

we get approximately:

```text
100
150
200
300
400
```

Because:

```text
Row 1:
100 / 1 = 100

Row 2:
100 + 200 / 2 = 150

Row 3:
100 + 200 + 300 / 3 = 200

Row 4:
200 + 300 + 400 / 3 = 300

Row 5:
300 + 400 + 500 / 3 = 400
```

---

# 19. `RANGE` vs `ROWS`

This is an important interview topic.

There are two concepts:

```text
ROWS
RANGE
```

They are **not always equivalent**.

## `ROWS`

`ROWS` works based on the **physical row position**.

For example:

```python
.rowsBetween(-2, 0)
```

means:

```text
previous 2 physical rows
+
current row
```

## `RANGE`

`RANGE` works based on the **value of the ordering column**.

This becomes especially important when there are duplicate ordering values.

Suppose:

| date | sales |
|---|---:|
| Jan 1 | 100 |
| Jan 1 | 200 |
| Jan 2 | 300 |

If we order by:

```python
orderBy("date")
```

then both Jan 1 rows have the same ordering value.

A `RANGE` frame can treat rows with the same ordering value as peers.

This is why **running totals with duplicate dates can behave differently depending on whether you use `ROWS` or `RANGE`**.

For deterministic row-by-row cumulative calculations, explicitly using:

```python
.rowsBetween(
    Window.unboundedPreceding,
    Window.currentRow
)
```

is often clearer.

---

# 20. Multiple `partitionBy()` Columns

You can partition using multiple columns.

Suppose:

```text
country | department | employee | salary
India   | IT         | A        | 50000
India   | IT         | B        | 70000
India   | HR         | C        | 40000
USA     | IT         | D        | 80000
```

You can do:

```python
window_spec = Window.partitionBy(
    "country",
    "department"
)
```

Now the logical groups are:

```text
India + IT
India + HR
USA + IT
```

This is useful in real-world analytics.

---

# 21. Example: Top 2 Employees Per Department

This is a **very common interview question**.

We have:

```text
employee department salary
A        IT         50000
B        IT         70000
C        IT         60000
D        HR         40000
E        HR         50000
F        HR         45000
```

We want the top 2 employees from every department.

First:

```python
from pyspark.sql.functions import row_number, col

window_spec = Window \
    .partitionBy("department") \
    .orderBy(col("salary").desc())
```

Then:

```python
df_ranked = df.withColumn(
    "rn",
    row_number().over(window_spec)
)
```

Then:

```python
df_ranked.filter(col("rn") <= 2)
```

Result:

```text
IT
B 70000
C 60000

HR
E 50000
F 45000
```

### Why can't we simply use `groupBy()`?

Because we need to preserve individual employee rows.

That's exactly where window functions are useful.

---

# 22. Find the Highest Salary Per Department

You can also use:

```python
window_spec = Window.partitionBy("department")

df.withColumn(
    "max_salary",
    max("salary").over(window_spec)
)
```

Result:

| employee | department | salary | max_salary |
|---|---|---:|---:|
| A | IT | 50000 | 70000 |
| B | IT | 70000 | 70000 |
| C | IT | 60000 | 70000 |
| D | HR | 40000 | 50000 |
| E | HR | 50000 | 50000 |

Then:

```python
df.filter(col("salary") == col("max_salary"))
```

gives employees having the highest salary.

---

# 23. Difference From Previous Row

Another practical use case.

Suppose:

| date | sales |
|---|---:|
| Jan 1 | 100 |
| Jan 2 | 150 |
| Jan 3 | 120 |
| Jan 4 | 200 |

We can calculate:

```python
previous_sales = lag("sales").over(window_spec)
```

Then:

```python
df = df.withColumn(
    "previous_sales",
    lag("sales").over(window_spec)
)

df = df.withColumn(
    "difference",
    col("sales") - col("previous_sales")
)
```

Result:

| date | sales | previous_sales | difference |
|---|---:|---:|---:|
| Jan 1 | 100 | null | null |
| Jan 2 | 150 | 100 | 50 |
| Jan 3 | 120 | 150 | -30 |
| Jan 4 | 200 | 120 | 80 |

This is frequently used for:

- day-over-day changes
- month-over-month changes
- price changes
- customer activity changes
- transaction analysis

---

# 24. Window Functions With Dates

Suppose we have:

```text
customer_id | order_date | amount
1           | 2026-01-01 | 100
1           | 2026-01-05 | 200
1           | 2026-01-10 | 150
2           | 2026-01-02 | 300
2           | 2026-01-08 | 500
```

We can define:

```python
window_spec = Window \
    .partitionBy("customer_id") \
    .orderBy("order_date")
```

Now:

```python
lag("amount").over(window_spec)
```

means:

> Give me the previous order amount for the same customer.

Result:

| customer | date | amount | previous |
|---|---|---:|---:|
| 1 | Jan 1 | 100 | null |
| 1 | Jan 5 | 200 | 100 |
| 1 | Jan 10 | 150 | 200 |
| 2 | Jan 2 | 300 | null |
| 2 | Jan 8 | 500 | 300 |

Notice how `partitionBy("customer_id")` prevents customer 1's last order from being compared with customer 2's first order.

---

# 25. A Very Important Mental Model

When you see:

```python
Window.partitionBy("customer_id").orderBy("order_date")
```

read it in English as:

> **For each customer, sort their records by order date.**

Then:

```python
lag("amount").over(window_spec)
```

means:

> **For each customer, give me the previous order amount.**

And:

```python
row_number().over(window_spec)
```

means:

> **For each customer, number their orders chronologically.**

This mental translation makes window functions much easier.

---

# 26. Common Window Functions

You should know these for interviews.

## Ranking

```python
row_number()
rank()
dense_rank()
percent_rank()
ntile()
```

## Navigation

```python
lag()
lead()
```

## Aggregations

```python
sum()
avg()
min()
max()
count()
```

## Statistical

```python
stddev()
variance()
```

---

# 27. Common Patterns You Should Memorize

## Pattern 1 — Ranking

```python
window_spec = Window \
    .partitionBy("department") \
    .orderBy(col("salary").desc())

df.withColumn(
    "rank",
    row_number().over(window_spec)
)
```

---

## Pattern 2 — Previous Value

```python
window_spec = Window \
    .partitionBy("customer_id") \
    .orderBy("order_date")

df.withColumn(
    "previous_amount",
    lag("amount").over(window_spec)
)
```

---

## Pattern 3 — Next Value

```python
df.withColumn(
    "next_amount",
    lead("amount").over(window_spec)
)
```

---

## Pattern 4 — Running Total

```python
window_spec = Window \
    .partitionBy("customer_id") \
    .orderBy("order_date") \
    .rowsBetween(
        Window.unboundedPreceding,
        Window.currentRow
    )

df.withColumn(
    "running_total",
    sum("amount").over(window_spec)
)
```

---

## Pattern 5 — Moving Average

```python
window_spec = Window \
    .partitionBy("customer_id") \
    .orderBy("order_date") \
    .rowsBetween(-2, 0)

df.withColumn(
    "moving_avg",
    avg("amount").over(window_spec)
)
```

---

# 28. `partitionBy()` vs Spark Physical Partitioning

This is a **very important Data Engineer interview distinction**.

When you write:

```python
Window.partitionBy("department")
```

this does **not** mean:

> Save the DataFrame physically partitioned by department.

It means:

> Define logical groups for the window calculation.

This is different from:

```python
df.repartition("department")
```

`repartition()` controls Spark's **physical data distribution**.

So:

```text
Window.partitionBy()
        ↓
Logical grouping for calculation

repartition()
        ↓
Physical redistribution of data
```

Don't confuse them.

---

# 29. What Happens Internally?

This is useful for Spark interviews.

Suppose:

```python
Window.partitionBy("department").orderBy("salary")
```

Spark needs rows belonging to the same department together and ordered appropriately.

That can involve a **shuffle**.

Conceptually:

```text
Original Data
     |
     v
Shuffle
     |
     v
Rows grouped by department
     |
     v
Sort within required ordering
     |
     v
Window calculation
```

Therefore, window operations can be expensive on large datasets.

Especially:

```python
partitionBy(...)
orderBy(...)
```

because Spark may need to redistribute and sort data.

---

# 30. Why Window Functions Can Be Expensive

Imagine 1 billion rows.

You execute:

```python
Window.partitionBy("customer_id").orderBy("order_date")
```

Spark may need to:

1. Shuffle data by `customer_id`
2. Sort rows according to `order_date`
3. Execute the window calculation

So in Spark UI you may see substantial:

- shuffle read
- shuffle write
- sort
- task execution time

This is why window functions should be used thoughtfully.

---

# 31. `groupBy()` vs Window — Interview Question

### `groupBy()`

```python
df.groupBy("department").agg(
    avg("salary")
)
```

Produces:

```text
department | avg_salary
```

The original employee rows disappear.

### Window

```python
window_spec = Window.partitionBy("department")

df.withColumn(
    "avg_salary",
    avg("salary").over(window_spec)
)
```

Produces:

```text
employee | department | salary | avg_salary
```

The original rows remain.

### Interview answer

> `groupBy()` aggregates rows and reduces the number of rows, whereas a window function performs calculations across related rows while preserving the original row-level granularity.

---

# 32. The Most Important Concept: `OVER`

In SQL you might write:

```sql
AVG(salary) OVER (
    PARTITION BY department
)
```

PySpark equivalent:

```python
avg("salary").over(
    Window.partitionBy("department")
)
```

So you can think of:

```python
.over(window_spec)
```

as:

> **Apply this function using this window definition.**

---

# 33. Complete Example

Let's put several concepts together.

```python
from pyspark.sql.window import Window
from pyspark.sql.functions import (
    col,
    row_number,
    lag,
    sum,
    avg
)

window_spec = (
    Window
    .partitionBy("customer_id")
    .orderBy("order_date")
)

df = (
    df
    .withColumn(
        "order_number",
        row_number().over(window_spec)
    )
    .withColumn(
        "previous_amount",
        lag("amount").over(window_spec)
    )
)
```

For a running total:

```python
running_window = (
    Window
    .partitionBy("customer_id")
    .orderBy("order_date")
    .rowsBetween(
        Window.unboundedPreceding,
        Window.currentRow
    )
)

df = df.withColumn(
    "running_total",
    sum("amount").over(running_window)
)
```

You could then have:

| customer | date | amount | order_number | previous | running_total |
|---|---|---:|---:|---:|---:|
| 1 | Jan 1 | 100 | 1 | null | 100 |
| 1 | Jan 5 | 200 | 2 | 100 | 300 |
| 1 | Jan 10 | 150 | 3 | 200 | 450 |
| 2 | Jan 2 | 300 | 1 | null | 300 |
| 2 | Jan 8 | 500 | 2 | 300 | 800 |

---

# 34. Window Function Cheat Sheet

| Requirement | Function |
|---|---|
| Give every row a unique sequence | `row_number()` |
| Ranking with gaps | `rank()` |
| Ranking without gaps | `dense_rank()` |
| Previous row | `lag()` |
| Next row | `lead()` |
| Running total | `sum().over()` + frame |
| Moving average | `avg().over()` + frame |
| Maximum per group | `max().over()` |
| Minimum per group | `min().over()` |
| Average per group | `avg().over()` |
| Count per group | `count().over()` |
| Top N per group | `row_number()` + filter |

---

# 35. Interview-Level Summary

If an interviewer asks:

**"What is a window function in PySpark?"**

You can answer:

> A window function allows us to perform calculations across a set of related rows while preserving the individual rows in the DataFrame. We define a window using `Window.partitionBy()`, `orderBy()`, and optionally a window frame such as `rowsBetween()`. Common window functions include `row_number`, `rank`, `dense_rank`, `lag`, `lead`, and aggregate functions such as `sum` and `avg`.

Then explain:

```python
Window.partitionBy("customer_id") \
      .orderBy("order_date")
```

as:

> For every customer, order their records by order date and perform the window calculation within that customer.

The **four concepts I'd make sure you can explain confidently in an interview are:**

```text
                 Window Function
                       |
          +------------+------------+
          |            |            |
     partitionBy    orderBy       frame
          |            |            |
       WHO?         ORDER?       WHICH ROWS?
          |            |            |
     customer_id   order_date    rowsBetween()
```

Once these three pieces—**partition, order, frame**—are clear, almost every PySpark window-function problem becomes much easier.
