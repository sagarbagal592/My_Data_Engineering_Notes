# Difference Between `concat()` and `concat_ws()` in PySpark

In PySpark, both **`concat()`** and **`concat_ws()`** are used to combine multiple columns/strings, but the main difference is that **`concat_ws()` allows you to specify a separator**.

## 1. `concat()`

`concat()` simply joins the values together **without adding any separator**.

```python
from pyspark.sql.functions import concat, col

df = df.withColumn(
    "full_name",
    concat(col("first_name"), col("last_name"))
)
```

If:

| first_name | last_name |
|---|---|
| Sagar | Bagal |
| Rahul | Patil |

Result:

| full_name |
|---|
| SagarBagal |
| RahulPatil |

If you want a space, you have to explicitly provide it:

```python
from pyspark.sql.functions import concat, lit, col

df = df.withColumn(
    "full_name",
    concat(
        col("first_name"),
        lit(" "),
        col("last_name")
    )
)
```

Result:

| full_name |
|---|
| Sagar Bagal |
| Rahul Patil |

---

# 2. `concat_ws()`

`ws` means **with separator**.

Syntax:

```python
concat_ws(separator, column1, column2, ...)
```

For example:

```python
from pyspark.sql.functions import concat_ws, col

df = df.withColumn(
    "full_name",
    concat_ws(
        " ",
        col("first_name"),
        col("last_name")
    )
)
```

Result:

| first_name | last_name | full_name |
|---|---|---|
| Sagar | Bagal | Sagar Bagal |
| Rahul | Patil | Rahul Patil |

Here:

```python
concat_ws(" ", ...)
```

means:

> Concatenate the values using a **space** as the separator.

You can use any separator:

```python
concat_ws("-", col("year"), col("month"), col("day"))
```

Result:

```text
2026-08-09
```

Or:

```python
concat_ws(",", col("city"), col("state"))
```

Result:

```text
Mumbai,Maharashtra
```

---

# 3. Important difference with NULL values

This is another useful difference to know.

Suppose:

| first_name | middle_name | last_name |
|---|---|---|
| Sagar | NULL | Bagal |

With `concat()`:

```python
concat(
    col("first_name"),
    col("middle_name"),
    col("last_name")
)
```

you can get:

```text
NULL
```

because `concat()` propagates the NULL.

With:

```python
concat_ws(
    " ",
    col("first_name"),
    col("middle_name"),
    col("last_name")
)
```

the result is typically:

```text
Sagar Bagal
```

`concat_ws()` **skips NULL values** when joining the columns.

This makes `concat_ws()` particularly convenient when you're constructing strings from columns that may contain NULLs.

---

## Quick comparison

| Feature | `concat()` | `concat_ws()` |
|---|---|---|
| Concatenates columns | ✅ | ✅ |
| Separator built in | ❌ | ✅ |
| Need `lit()` for separator | Yes | No |
| Handles NULL conveniently | ❌ | ✅ Skips NULLs |
| Best use | Simple joining | Joining with delimiter |

### Easy way to remember

```python
concat(a, b, c)
```

➡️ **Just join**

```text
ABC
```

Whereas:

```python
concat_ws("-", a, b, c)
```

➡️ **Join with separator**

```text
A-B-C
```

### In real Data Engineering work

For creating things like:

```text
full_name
address
date_key
composite_key
```

I would often prefer **`concat_ws()`** when a separator is required:

```python
df = df.withColumn(
    "customer_key",
    concat_ws(
        "_",
        col("country"),
        col("city"),
        col("customer_id")
    )
)
```

For example:

```text
IN_Mumbai_1001
```

That's a very common PySpark pattern.
