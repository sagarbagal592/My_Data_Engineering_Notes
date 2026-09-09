# Partitioning, Shuffling, Joins & Data Skew

# Partitioning

- In Spark, a partition is a chunk of data that is processed independently, and one task processes one partition in a particular stage. 
- When Spark reads data, the number of input partitions is mainly determined by the size of the source files and `spark.sql.files.maxPartitionBytes` (default ~128 MB).
- So, for example, 1 GB of input may result in roughly 8 input partitions (1024/128 = 8). Spark can also combine small files into partitions, so it is not necessarily one partition per file.
- When a transformation such as groupBy(), join(), or reduceByKey() causes a shuffle, Spark redistributes data across partitions, and the initial number of shuffle partitions is controlled by `spark.sql.shuffle.partitions` (default 200). - Therefore, you might have 8 tasks in the initial read stage and 200 shuffle partitions/tasks in the next stage.
- Too few shuffle partitions can create very large partitions and reduce parallelism, while too many can create many tiny partitions and increase overhead.
- With AQE (`spark.sql.adaptive.enabled=true`), Spark can examine the actual shuffle data at runtime and coalesce small partitions or otherwise adjust the execution plan, so the configured 200 is an initial/default setting rather than necessarily the final number of effective partitions.
- The key idea to remember is: input partitions are mainly driven by file splitting, shuffle partitions are initially driven by spark.sql.shuffle.partitions, and AQE can dynamically adjust post-shuffle partitioning.

## repartition (n) and coalesce(n)

repartition(n):
- Can increase or decrease partition count, and always trigger full shuffle. Since, evenly redistributing data across new count requires physically moving it. Its a wide transformation.

coalesce(n):
- can only decrease partition count, and avoids a full shuffle by simply merging existing partitions together without redistributing everything. Cheaper, but the trade-off is it can't balance data evenly — if your partitions are already lopsided, coalescing just merges the lopsidedness into fewer, still-lopsided partitions.

# Shuffle

- A shuffle means data has to move from its current partitions to new partitions, usually because Spark needs all records with the same key together.
- A Spark shuffle happens when data must be redistributed across partitions, such as during groupBy(), join(), or reduceByKey().
- On the map/upstream side, each task processes its partition, hashes/partitions records based on their keys, and writes the resulting shuffle data to local disk.
    - Why does Spark write to disk?
        - Because the downstream stage might not execute immediately on the same executor.
        - The shuffle data needs to be made available for downstream tasks.
        - So Spark produces shuffle files that downstream tasks can later fetch.
    - This creates major cost of shuffle -> Disk I/O
- On the reduce/downstream side, each task fetches its required data from the map tasks over the network, then reads, deserializes, merges, and processes it.
- Therefore, a shuffle is expensive because it involves multiple costs— CPU/serialization, disk I/O for shuffle writes, network I/O for shuffle reads, and deserialization/processing.
```text
CPU
 ↓
Serialization
 ↓
Disk I/O
 ↓
Network I/O
 ↓
Deserialization
 ↓
CPU

Serialization means converting objects/data into a format suitable for storage or transmission.
Spark objects
     ↓
Serialization
     ↓
Bytes
     ↓
Disk / Network
```
- A shuffle also creates a stage boundary: the upstream stage performs shuffle write, and the downstream stage performs shuffle read.
- Unlike a narrow transformation such as filter(), which processes each partition independently without moving data between partitions, a shuffle requires data redistribution.
- Calling .cache() does not eliminate a shuffle because caching and shuffling serve different purposes.
    - Caching means keep a DataFrame's computed partitions available for reuse.
    - Shuffle means Redistribute data between partitions
- The easiest way to remember it is: Process → Partition by key → Write to disk → Transfer over network → Read/Deserialize → Process.
![alt text](image-2.png)

# join strategy: broadcast join vs shuffle sort merge join

- When one side of the join is small enough (controlled by `spark.sql.autoBroadcastJoinThreshold`, default 10 MB), Spark can use a Broadcast Hash Join by sending a copy of the small DataFrame to every executor, allowing each executor to join its local partition of the large DataFrame using a hash lookup, without shuffling the large side.
- If neither side is small enough to broadcast, Spark generally uses a Shuffle Sort-Merge Join, where both DataFrames are shuffled based on the join key so matching keys land in the same partitions, then the partitions are sorted and merged locally.
- Shuffle involves disk I/O, network I/O, serialization/deserialization, and sorting, it is more expensive than a broadcast join.
- You can also explicitly request broadcast join:
```py
from pyspark.sql.functions import broadcast
big_df.join(broadcast(small_df), "key")

# "key" is the column on which you want to join the two DataFrames.
```
# Data Skew

- Data skew is an uneven distribution of data across Spark partitions, usually after a shuffle.
- For example, if most customers have a few orders but one customer has millions, a groupBy("customer_id") or join can send all records for that customer to the same partition because records with the same key must be colocated for correct processing. This creates a situation such as 199 tasks processing around 200 MB while one task processes 45 GB. That one task takes much longer, while the other executors finish and remain idle, making the entire stage wait for the slow task.
- Skew can be caused by dominant/hot keys, highly frequent values, or large numbers of NULL values.
- To diagnose it, use the Spark UI to compare task duration, shuffle-read size, shuffle-write size, input size, and spill, then investigate the data itself—for example, groupBy("customer_id").count().orderBy(...) can reveal unusually frequent keys.
- For fixing skew, **AQE (Adaptive Query Execution)** is usually worth trying first because Spark can detect oversized post-shuffle partitions at runtime and, for supported skewed operations such as joins, split them into smaller pieces.
- **Salting** is a manual technique where you add a random or deterministic suffix to a skewed key, such as turning C999 into C999_0, C999_1, etc., allowing the records to spread across multiple partitions; partial results must then be combined afterward.
- Another approach is to **isolate the problematic key**, process it separately with a tailored strategy, and then union the result with the normal data.
- The key decision is: confirm the skew first, identify the actual hot key, try AQE when appropriate, and use salting or separate processing when automatic handling isn't sufficient.

Example  — spotting and fixing skew.
You're aggregating revenue by customer_id, and the Spark UI shows one task taking 40 minutes while every other task in the stage finishes in 20 seconds. Investigating shows one customer_id — a bulk-order integrator — accounts for a huge share of all rows. Fix via salting:

```py
from pyspark.sql.functions import lit, floor, rand, concat

salted = df.withColumn('salted_key', concat(df.customer_id, lit("_"), floor(rand()*10)))

partial = salted.groupBy('salted_key', 'customer_id').sum('revenue')

final = partial.groupBy('customer_id').sum('sum(revenue)')
```