# Introduction
- Every PySpark application starts with exactly one object: the `SparkSession`. It is your entry point to everything — reading data, creating DataFrames, running SQL, accessing the Spark catalog. If you do not have a SparkSession, you do not have Spark.

![alt text](image.png)

# creating a sparksession
```py
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName('my_spark').getOrCreate()
```