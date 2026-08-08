# Import all required libraries

 from pyspark.sql.functions import *
 from pyspark.sql.types import *
 from pyspark.sql.window import Window

 # In order to read a data frame

 df = spark.read.format("csv").option("header",True).option("inferSchema",True).load("path")

 # To display result

 display(df) OR df.display()

 # In order to customize your schema

 new_schema = df.schema
