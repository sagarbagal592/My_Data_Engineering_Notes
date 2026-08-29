# Window Functions and `row_number()` in PySpark

------------------------------------------------------------------------

# What is a Window Function?

Imagine you have the following student marks:

      Student   Class     Marks
      --------- ------- -------
      John      A            90
      Alice     A            80
      Bob       A            95
      David     B            70
      Emma      B            85

You want to **rank students within each class** while keeping every row.

### Output

      Student   Class     Marks   Rank
      --------- ------- ------- ------
      Bob       A            95      1
      John      A            90      2
      Alice     A            80      3
      Emma      B            85      1
      David     B            70      2

A **Window Function** performs calculations across a group of rows while
**preserving every row**.

------------------------------------------------------------------------

# Why Not Use `groupBy()`?

``` python
df.groupBy("Class").max("Marks")
```

### Output

    Class     Max Marks
    ------- -----------
    A                95
    B                85

Notice that all student rows disappear because `groupBy()` aggregates
data.

Window Functions **do not remove rows**.

------------------------------------------------------------------------

# Real-Life Example

      Entire School

      Class A
      ---------
      John
      Alice
      Bob

      Class B
      ---------
      David
      Emma

Each class represents one **Window**.

------------------------------------------------------------------------

# Components of a Window Function

``` python
Window.partitionBy(...).orderBy(...)
```

## 1. partitionBy()

Creates logical groups.

``` python
Window.partitionBy("Class")
```

Internally Spark creates:

    ### Window 1

      Student
      ---------
      John
      Alice
      Bob

    ### Window 2

      Student
      ---------
      David
      Emma

------------------------------------------------------------------------

## 2. orderBy()

Sorts rows inside each partition.

``` python
Window.partitionBy("Class") \
      .orderBy(col("Marks").desc())
```

### Class A after sorting

      Student     Marks
      --------- -------
      Bob            95
      John           90
      Alice          80

### Class B after sorting

      Student     Marks
      --------- -------
      Emma           85
      David          70

------------------------------------------------------------------------

## 3. Apply a Window Function

Common window functions:

-   `row_number()`
-   `rank()`
-   `dense_rank()`
-   `lead()`
-   `lag()`

------------------------------------------------------------------------

# What is `row_number()`?

Assigns a **unique sequential number** within every partition.

``` python
from pyspark.sql.window import Window
from pyspark.sql.functions import row_number, col

window_spec = Window.partitionBy("Class") \
                    .orderBy(col("Marks").desc())

df = df.withColumn(
    "Row_Number",
    row_number().over(window_spec)
)
```

### Output

      Student   Class     Marks   Row_Number
      --------- ------- ------- ------------
      Bob       A            95            1
      John      A            90            2
      Alice     A            80            3
      Emma      B            85            1
      David     B            70            2

The numbering **restarts for every partition**.

------------------------------------------------------------------------

# How Spark Executes It

## Input

    Customer
  ----------
         101
         101
         101
         102
         102
         103

## Step 1: Partition

### Window 1

    Customer
  ----------
         101
         101
         101

### Window 2

    Customer
  ----------
         102
         102

### Window 3

    Customer
  ----------
         103

## Step 2: Sort by Last Updated

    Customer Last Updated
  ---------- --------------
         101 2025-05
         101 2025-04
         101 2025-03

## Step 3: Assign Row Numbers

    Customer Last Updated     Row_Number
  ---------- -------------- ------------
         101 2025-05                   1
         101 2025-04                   2
         101 2025-03                   3

------------------------------------------------------------------------

# Why is `row_number()` Used for Deduplication?

``` python
window_spec = Window.partitionBy("Customer") \
                    .orderBy(col("Updated_Date").desc())
```

### Before Filtering

    Customer Updated_Date     Row_Number
  ---------- -------------- ------------
         101 March                     1
         101 February                  2
         101 January                   3

``` python
df.filter(col("Row_Number") == 1)
```

### Final Result

    Customer Updated_Date
  ---------- --------------
         101 March

------------------------------------------------------------------------

# Why Do We Write `.over(window_spec)`?

`row_number()` alone doesn't know:

-   Which rows belong together?
-   How should they be sorted?

`.over(window_spec)` supplies the window definition.

``` python
row_number().over(window_spec)
```

------------------------------------------------------------------------

# `row_number()` vs `rank()` vs `dense_rank()`

### Input

      Employee     Salary
      ---------- --------
      A               100
      B                90
      C                90
      D                80

### row_number()

      Employee     Salary   Row Number
      ---------- -------- ------------
      A               100            1
      B                90            2
      C                90            3
      D                80            4

### rank()

      Employee     Salary   Rank
      ---------- -------- ------
      A               100      1
      B                90      2
      C                90      2
      D                80      4

### dense_rank()

      Employee     Salary   Dense Rank
      ---------- -------- ------------
      A               100            1
      B                90            2
      C                90            2
      D                80            3

------------------------------------------------------------------------

# Interview Questions

1. What is a Window Function?

A Window Function performs calculations over a group of rows while
preserving every row.

2. Why not use `groupBy()`?

Because `groupBy()` aggregates data and reduces rows, whereas Window
Functions preserve rows.

3. Why is `row_number()` used for deduplication?

It assigns `1` to the latest record (after ordering), making it easy to
keep only the latest version of each business key.

------------------------------------------------------------------------

# Summary

  -----------------------------------------------------------------------
      Concept                             Purpose
      ----------------------------------- -----------------------------------
      `partitionBy()`                     Creates logical groups

      `orderBy()`                         Sorts rows inside each group

      `row_number()`                      Assigns sequential numbers

      `.over(window_spec)`                Applies the window definition
---------------------------------------------------------------------------------
  Common Use Cases: Deduplication, Ranking, Latest Record, Running Totals, Lead/Lag
                                      
------------------------------------------------------------------------------


