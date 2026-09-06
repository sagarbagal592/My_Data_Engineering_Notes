# Spark SQL and Data Frame

The Core Idea
- Spark SQL is the module that lets you query DataFrames using SQL syntax or DataFrame API — and critically, SQL queries and DataFrame method chains both get compiled into the same internal representation before Spark ever touches your data. The thing responsible for turning either one into a fast execution plan is the Catalyst Optimizer.

```py
df.createOrReplaceTempView("orders")
spark.sql("SELECT customer_id, SUM(amount) FROM orders GROUP BY customer_id").show()

# produces the identical execution plan as:
df.groupBy("customer_id").agg(sum("amount")).show()

# There is no performance difference between these two. Pick whichever is more readable for the task at hand
```
# Catalyst Optimizer: Stage by Stage

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