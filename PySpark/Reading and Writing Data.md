# Reading and Writing of Data


## Read API

- `DataFrameReader.format(...).option("key", "value").schema(...).load()`

```py
spark.read.format("csv")\
    .option("mode", "FAILFAST")\
    .option("inferSchema", "true")\
    .option("path", "path/to/file(s)")\
    .schema(someSchema)\
    .load()
```

## Write API

- `DataFrameWriter.format(...).option(...).partitionBy(...).bucketBy(...).sortBy(...).save()`

```py
dataframe.write.format("csv")\
    .option("mode", "OVERWRITE")\
    .option("path", "path/to/file(s)")\
    .save()
```
![alt text](image-9.png)

