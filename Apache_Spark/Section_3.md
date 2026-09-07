# Spark SQL and Data Frame

The Core Idea
- Spark SQL is the module that lets you query DataFrames using SQL syntax or DataFrame API — and critically, SQL queries and DataFrame method chains both get compiled into the same internal representation before Spark ever touches your data. The thing responsible for turning either one into a fast execution plan is the Catalyst Optimizer.
- Wich syntax you use is a style choice and not a performance one.
## spark sql, two syntaxes one plan
```py
df.createOrReplaceTempView("orders")
spark.sql("SELECT customer_id, SUM(amount) FROM orders GROUP BY customer_id").show()

# produces the identical execution plan as:
df.groupBy("customer_id").agg(sum("amount")).show()

# There is no performance difference between these two. Pick whichever is more readable for the task at hand
```
# Catalyst Optimizer: Stage by Stage
- Every query either SQL or DataFrame passes through same five stages before a single byte of data moves.
![alt text](image-1.png)

1. Unresolved Logical Plan:
    - Spark parses your SQL or DataFrame code into a tree of operations, but hasn't yet checked whether the columns or tables you referenced actually exist.
2. Logical Plan:
    - Spark's Analyzer checks your unresolved plan against the Catalog (Spark's internal metadata store of table/column names and types), resolving every reference. A typo'd column name gets caught here.
3. Optimized Logical Plan:
    - Catalyst applies rule-based rewrites
    1. **Predicate Pushdown**: if you filter after a join in your code, Catalyst will move that filter to run before the join whenever it's safe to — filtering first means less data to join, which is cheaper. Your code's order doesn't dictate execution order.
    2. **Column Pruning**: if your DataFrame has 50 columns but your query only touches 2, Catalyst (and the file reader, for columnar formats like Parquet) skips reading the other 48 entirely.
4. Physical Plan:
    - Catalyst can generate several possible execution strategies (e.g., different join algorithms) and picks the cheapest one using a cost model.
5. RRDs(executed):
    - The selected plan finally runs, using Tungsten (Spark's execution engine for CPU/memory efficiency) to generate optimized bytecode directly rather than running generic interpreted operators — this is called whole-stage code generation.

# Common transformations and join types

- select, filter/where, withColumn, drop, orderBy, groupBy + .agg(), distinct, dropDuplicates.

joins:
- inner, left, right and full. There are two more joins
    - left_semi: Keep the left side row that have match on right, but never bring right side columns into the result.
    - left_anti: keep left side row that have no match on right.
    - Both joins return columns from left table/dataframe.
```py
# Let say we have two tables customers and orders

df1 = customers.join(orders, customers.customer_id == orders.custome_id, 'left_semi')
df2 = customers.join(orders, customers.customer_id == orders.custome_id, 'left_anti')

df1.show()
df2.show()
```

# UDFs (User Defined Functions):

- A UDF is a custom code you register with spark for logic the built-in function dont cover.
```py
 from pyspark.sql.functions import udf
 from pyspark.sql.types import StringType()

 def categorize(amount):
    return 'High' if amount > 1000 else 'Medium' if amount > 100 else 'low'

 categorize_udf = udf(categorize, StringType())

 df.withColumn('Tier', categorize_udf(df.amount))

```
- Catalyst cannot see inside a UDF. It's an opaque box, so no pushdown, no pruning, no reordering can happen around it.
- For Python UDFs specifically, there's a physical cost: Spark's engine runs in the JVM, but your Python function can only run in a Python process. So for every row, data gets serialized out of the JVM, sent to Python, processed, serialized back, and returned — a real, per-row round trip.
- Best practice: prefer built-in functions (pyspark.sql.functions) whenever an equivalent exists. When custom Python logic is genuinely unavoidable, Pandas UDFs (vectorized, using Apache Arrow — a fast columnar in-memory format) are far faster, since they batch many rows into one call instead of round-tripping row by row.

# Window Function

- A window function computes a value per row based on related group of rows without collapsing those rows unlike .groupBy()
```py
from pyspark.sql.functions import rank
from pyspark.sql.window import Window

df = df.withColumn('dept_rank', rank().over(Window.partitionBy(df.department).orderBy(df.salary).desc()))

df.show()
```
- partitionBy()
    - defines the window(group) like groupBy() but rows stays separate
- orderBy()
    - define row order within each window. Needed for ranking or running totals.
- rank(), dense_rank(), row_number()
    - differ in tie handling. rank leaves gap after a tie (1,1,3), dense_rank doesnt (1,1,2), row_number never ties (1,2,3)
- Example: Need to find top 3 earners from each department
```py
from pyspark.sql.window import Window
from pyspark.sql.functions import row_number

df = df.withColumn('earners',row_number().over(Window.partitionBy('department').orderBy(df.salary.desc())))

df = df.filter(df.earners <= 3)

df.show()

```
- groupBy("department").max("salary") only ever gets you the single max per department, and it collapses every other column — you lose the individual employee rows entirely. Window functions solve a category of problem groupBy cannot, by design.
# Common misconceptions and mistakes

- "select() before filter() means Spark selects first." No — Catalyst reorders freely; pushdown typically filters as early as possible regardless of code order.
- "UDFs are just as fast since they do equivalent work." False, especially in Python — lost optimizer visibility plus real JVM↔Python serialization cost.
- "groupBy can get me top N per group." No — groupBy collapses rows; only window functions preserve individual rows while ranking within a group.
- "rank() and row_number() are interchangeable." No — tie-handling differs.
- "SQL syntax is slower than the DataFrame API" (or vice versa). False — identical plan, identical performance, for equivalent logic.

# Revision
- SQL and the DataFrame API compile to the identical Catalyst plan — pick whichever's convenient.
- Pipeline: unresolved logical plan → logical plan (schema-validated) → optimized logical plan (pushdown, pruning) → physical plan (strategy chosen) → execution (Tungsten-compiled bytecode on executors).
- left_semi filters using another table; left_anti finds rows missing from it.
- UDFs are Catalyst-invisible; Python UDFs add JVM <-> Python serialization cost — prefer built-ins, or Pandas UDFs when unavoidable.
- Window functions (partitionBy + orderBy) compute per-row values over a group without collapsing rows — the only way to solve "top N per group."

# Section 3 Quiz

Question 1: In your own words, why do the SQL syntax and the DataFrame API have identical performance for equivalent logic? What's actually happening underneath that makes this true?

Answer:
- A SQL string gets parsed into a logical plan tree — an internal, structured representation of "read this, filter on that, select these columns."
- A chain of DataFrame calls like .filter().select() builds that exact same kind of tree directly, just via method calls instead of text parsing. 
- So by the time Catalyst even starts its work, there is no "SQL version" and "DataFrame version" of the plan. They've already converged into one single, indistinguishable object (the unresolved logical plan). Catalyst has no way to tell which syntax produced the tree in front of it, because that information is gone the moment parsing/building finishes.There is nothing left to distinguish by the time optimization begins.

-------

Question 2: Why specifically are Python UDFs slower than Spark's built-in functions — and would this same performance gap exist if you wrote your UDF in Scala instead of Python? Why or why not?

Answer:
- Spark engine built on jvm. If we write an pyhon UDF it need an python interpreter, that means data from jvm get serialized in python process, data got processed and again serialized back to jvm. This will increase overhead makes application slower. Also an python udf is opaque box for spark as spark doesnt know what is inside your udf so no pushdown, no pruning will happen.
- Scala compiles to JVM bytecode, and Spark's engine is the JVM. So a Scala UDF runs natively, in-process, right alongside the rest of the execution — no serialization boundary to cross, because there's no second runtime involved at all. But, Catalyst still can't see inside a Scala UDF either. It's still an opaque box to the optimizer — no pushdown, no pruning, no reordering around it.
- Python UDF — pays two separate costs: serialization overhead and lost optimizer visibility.
- Scala UDF — pays only one of those two costs: lost optimizer visibility, but not serialization.

----

Question 3: You have a DataFrame of orders and want every order row tagged with the running total of revenue for its customer, ordered by date — each individual order row must survive in the output, just with this new column added. Would you reach for groupBy or a window function here, and write the actual code for the window spec that would compute this running total?

Answer:

- Here window function is the right choice
- code
```py
from pyspark.sql.functions import sum as _sum
from pyspark.sql.window import Window

window_spec = (
    Window.partitionBy("customer_id")
          .orderBy("order_date")
          .rowsBetween(Window.unboundedPreceding, Window.currentRow)
)

df = df.withColumn("running_total_revenue", _sum("revenue").over(window_spec))
df.show()
```

---

Question 4: Suppose a customer has two orders on the exact same order_date, and you're using the default window frame (no explicit rowsBetween). What running_total_revenue value would each of those two same-day orders show? Is that what someone asking for a "running total" would actually want?

Answer:

---

Question 5: We've established a UDF-based filter blocks predicate pushdown. Does it also block projection pruning? Suppose your DataFrame has 20 columns, your UDF only reads column A, and your final .select() only needs columns A and B. Would the other 18 columns still get skipped when reading from the source, despite the UDF's presence? Why or why not?

Answer:


---

