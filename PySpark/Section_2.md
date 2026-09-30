# DataFrames Basics

- A DataFrame is the most common Structured API in Spark — it simply represents a table of data with rows and columns, similar to a table in a relational database or a DataFrame in pandas/R.
- A pandas DataFrame lives in memory on one machine. A PySpark DataFrame is a description of a computation distributed across a cluster. When you call `df.filter(...)`, nothing happens — Spark just records the operation in a DAG. This distinction matters because it changes how you think about debugging, performance, and data validation.
![alt text](image-2.png)
- To allow every executor to perform work in parallel, Spark breaks up the data into chunks called partitions. A DataFrame's partitions represent how the data is physically distributed across the cluster during execution.
## spark types
- Spark maintains its own type system through the Catalyst engine. You can import Spark types in your code:
```py
from pyspark.sql.types import *

# Common Types: StringType, IntegerType, LongType, DoubleType, BooleanType, DateType, TimestampType, ArrayType, MapType, StructType.
```

## Creating DataFrames:
- There are three common ways to create DataFrame. Each serves different purpose.
![alt text](image-3.png)

1. Creating DataFrame from list of rows (Used for Testing and Prototyping)

```py
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName('my_spark_session').getOrCreate()  # Here we are taking into consideration about .config()

data = [
    ('alice','engineering',95000),
    ('bob','marketing',72000),
    ('carol','engineering',110000)
    ]
schema = ['name','department','salary']

df = spark.createDataFrame(data,schema)

df.show()


Output->

+-----+-----------+------+
| name| department|salary|
+-----+-----------+------+
|alice|engineering| 95000|
|  bob|  marketing| 72000|
|carol|engineering|110000|
+-----+-----------+------+
```