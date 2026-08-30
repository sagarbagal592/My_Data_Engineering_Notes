# Core Abstractions: RDD, DataFrame, DataSets

The Core Idea:
- RDD, DataFrame and DataSet are Spark's three ways of representing a distributed collection of data. They differ in how much structure Spark knows about your data, and therefore how much Spark can optimize on your behalf. Spark's evolution has moved from RDD (original, low-level) to DataFrame (high-level, schema-aware, the modern default) — and in PySpark specifically, DataFrame is what you'll use for the vast majority of real work.

1. RDD (Resilient Distributed Dataset)
- An RDD is Spark's original, fundamental data structure: an immutable, distributed collection of objects that Spark can process in parallel.
    - **Resilient** — fault-tolerant. If a partition is lost (say, an executor crashes), Spark doesn't need a backup copy sitting somewhere — it recomputes just that partition using its lineage: the recorded sequence of transformations that produced it from the original data. This lineage is exactly the DAG (Directed Acyclic Graph)— a graph of computation steps where each step points forward to the next, with no loops back to an earlier step. Spark builds this graph as you write code, and it's what makes lineage-based recovery possible.
    - **Distributed** — split into partitions spread across the cluster.
    - **Dataset** — just a collection of data: numbers, tuples, custom objects, whatever your code works with.
- Key Properties:
    - RDDs are immutable (a transformation always produces a new RDD rather than modifying the existing one), and they're a low-level API — you manipulate them almost like ordinary Python collections (map, filter, reduce), which gives you total flexibility but means Spark has no idea what your data actually means, so it can't optimize much.

---
2. Transformations Vs Actions and Lazy Evaluation
- A transformation is any operation that returns a new RDD/DataFrame — .map(), .filter(), .select(), .groupBy().
- Transformations are lazy: Spark doesn't compute anything when you call them. It just adds a step to the plan. Why be lazy on purpose? -> Because it lets Spark see your whole pipeline before running any of it, so it can optimize the entire thing as a unit — combining steps, reordering operations, skipping unnecessary work — rather than blindly executing line by line. It's the difference between planning a full road trip route in advance versus deciding each turn only once you reach it.
- An action is an operation that actually triggers computation and either returns a result to the Driver or writes data out — .collect(), .count(), .show(), .write(). This is what creates a Job. The moment .show() fires, Spark takes the entire chain built up so far and executes it as one Job, splitting it into stages.

---

3. DataFrame
- A DataFrame is a distributed collection of data organized into named columns — conceptually a table, or a distributed version of a pandas DataFrame.
- What it adds over a raw RDD:
    - **Schema awareness** — Spark knows the column names and types, so it can validate operations and use that structure to optimize.
    - **Catalyst Optimizer** — Spark SQL's query optimizer inspects your DataFrame operations and rewrites them into a more efficient physical plan: pushing filters earlier, dropping unused columns, picking efficient join strategies. RDDs get none of this, since Spark can't see inside your raw Python functions.
    - A much higher-level API
    - **Consistent performance across languages** — because Catalyst optimizes the plan regardless of which language wrote it, a PySpark DataFrame job performs similarly to the same job in Scala. RDDs don't have this guarantee — PySpark RDD code can be noticeably slower due to Python-JVM serialization overhead.
- Under the hood, a DataFrame is still built on RDDs, but you'll rarely touch that layer directly.

---

4. DataSet
- A Dataset is a distributed collection of strongly-typed objects — available only in Scala and Java, the JVM languages.
- It combines RDD's compile-time type safety with DataFrame's Catalyst-powered performance. 

---

```py
# RDD approach — low-level, functional

rdd = sc.textFile("data.txt")
word_counts_rdd = (rdd.flatMap(lambda line: line.split(" "))
                       .map(lambda word: (word, 1))
                       .reduceByKey(lambda a, b: a + b))
                       

# DataFrame approach — high-level, declarative
df = spark.read.text("data.txt")
word_counts_df = (df.select(explode(split(df.value, " ")).alias("word"))
                     .groupBy("word")
                     .count())
```