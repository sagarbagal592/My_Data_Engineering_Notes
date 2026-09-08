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
