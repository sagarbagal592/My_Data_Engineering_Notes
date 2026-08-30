# Spark Fundamentals and Architecture

![Spark Architecture](image.png)

---
The core idea:
- Apache Spark is a distributed computing engine: it processes very large datasets by splitting the work across many machines and running the pieces in parallel, then combining the results — instead of one machine grinding through everything alone. Its biggest advantage over its predecessor, Hadoop MapReduce, is that it does most of this in memory (RAM) instead of constantly writing intermediate results to disk, which makes it dramatically faster, especially for workloads that touch the same data repeatedly.

- Two terms to lock in immediately:
    - Distributed computing — splitting one big computation across multiple machines that coordinate to produce a single result.
    - In-memory processing — keeping intermediate data in RAM rather than writing it to disk between steps. RAM is roughly 100x faster to read/write than disk.

Why Spark Exists?

- Before Spark, Hadoop MapReduce was the standard for processing huge datasets. It works in two phases — Map (transform) and Reduce (aggregate) — but after every phase, it writes results to disk before the next one starts. For multi-step pipelines, or anything iterative (like training a model, which needs many passes over the same data), that disk I/O adds up to a serious slowdown.
- Spark (built at UC Berkeley, donated to Apache in 2013) fixes this by keeping data in memory across operations whenever it fits, and by offering a much richer API than just "map" and "reduce."
- Spark did not replace all of Hadoop. It mainly replaced the MapReduce processing engine. Spark still commonly runs on Hadoop infrastructure — reading from HDFS (Hadoop's storage layer) and using YARN (Hadoop's resource manager) to get its machines. Spark itself has no built-in permanent storage system.

## Sparks Architecture

1. **Driver** — the process running your actual application code. It doesn't process data itself — it builds the execution plan, splits work into tasks, sends them to executors, and collects results.

2. **Cluster Manager** — an external service that hands out machines/resources to your application. It doesn't know or care what your code does; it just allocates CPU and memory. Spark supports Standalone (Spark's own simple manager), YARN (Hadoop's resource manager, common on-prem), and Kubernetes (container-based, increasingly the default in cloud setups).

3. **Worker Node** — a physical or virtual machine with spare CPU/RAM to offer.

4. **Executor** — a JVM (Java Virtual Machine — the runtime that executes Java/Scala bytecode, which Spark itself is built on) process launched on a worker node, dedicated to your application for its whole lifetime. This is what actually runs computations and holds cached data. Each executor has a number of "cores" (slots), and each core runs one task at a time.

5. **Task** — the smallest unit of work: one computation applied to one partition of data (a partition is just one chunk of your dataset — Spark splits data into many chunks so it can work on them in parallel). A task runs inside one executor core.

**Note**: A common point of confusion: a Worker Node is a machine; an Executor is a process running on it. One worker node can host more than one executor depending on configuration — they are not the same thing.


## SparkContext and SparkSession

1. **SparkContext** — the original entry point into Spark. It's what actually connects your Driver to the Cluster Manager. It was the primary API before Spark 2.0, tied closely to the RDD API.
2. **SparkSession** — introduced in Spark 2.0 as a single unified entry point that wraps SparkContext (plus the old SQLContext and HiveContext). In modern code, you just create a SparkSession, and it manages a SparkContext internally.
```python
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName('MyFirstApp').getOrCreate()
```