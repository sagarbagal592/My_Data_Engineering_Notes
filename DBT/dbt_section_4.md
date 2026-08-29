# DBT Snapshots
### The Analogy

Imagine a customer's shipping address changes in your source system on March 1st. If you just keep overwriting that value, by June you have no idea the customer used to live somewhere else — history is erased. A snapshot is like a photo album for your data: every time you run it, dbt takes a "photo" of the current state, and if something's changed since the last photo, it closes out the old photo (marks it as no-longer-current) and inserts a new one — while keeping every old photo permanently in the album. You can flip back through the album and answer "what did this record look like on any given date in the past?"

- It is important concept when you start working with historical data and slowly changing dimension(SCD type 2)
- A dbt snapshot allows you to capture changes to records over time.
- A dbt snapshot is a dbt feature used to track changes in source data over time. It captures different versions of a record instead of simply retaining the latest value. Snapshots are commonly used to implement Slowly Changing Dimension Type 2. dbt identifies records using a unique key and detects changes using strategies such as timestamp or check. It then maintains metadata such as dbt_valid_from and dbt_valid_to to indicate the period during which each version of a record was valid.
```text
Normally, if a source table changes, you may lose the previous value.

For example, today:

    customer_id	 name	 city
    C001	     Sagar	 Pune

Tomorrow, the source changes:

customer_id	  name	  city
C001	      Sagar	  Mumbai

If you simply query the source table, you only see:

C001 → Sagar → Mumbai

You have lost the information that the customer previously lived in Pune.

A dbt snapshot preserves that history.
```
### snapshot and SCD type 2
- dbt snapshots are commonly used to implement SCD Type 2.
- Type 2 means: Instead of overwriting the old value, create a new row and preserve the old row.

### How does a snapshot knows something changed
- It is defined by snapshot strategy. There are two strategy:
    1. timestamp
    2. check
    
### timestamp strategy
- The timestamp strategy is generally preferred when the source table has a reliable column such as: updated_at
```sql
{% snapshot customer_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='updated_at'
    )
}}

select
    customer_id,
    customer_name,
    city,
    updated_at
from {{ source('raw', 'customers') }}

{% endsnapshot %}
```
> When dbt runs a snapshot it creates a snapshot table. It contains your source columns plus metadata columns.

    | customer_id | name  | city   | updated_at | dbt_scd_id | dbt_valid_from | dbt_valid_to |
    | ----------- | ----- | ------ | ---------- | ---------- | -------------- | ------------ |
    | C001        | Sagar | Pune   | Jan 1      | abc        | Jan 1          | Feb 15       |
    | C001        | Sagar | Mumbai | Feb 15     | xyz        | Feb 15         | NULL         |

### check strategy
- What if your source does not have updated_at column? How can dbt know that record changed?
- In this case use check strategy
```sql
{% snapshot customer_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='customer_id',
        strategy='check',
        check_cols=['customer_name', 'city']
    )
}}

select
    customer_id,
    customer_name,
    city
from {{ source('raw', 'customers') }}

{% endsnapshot %}
```
### How to run dbt snapshot

`dbt snapshot`
- This tells dbt, execute my snapshot definitions and capture changes.

## What is Dimension
- A dimension is a table containing descriptive attributes about business entities such as customers, products, stores, or dates. Dimensions provide the context used to analyze measures stored in fact tables.
- A dimension is a table that stores descriptive information about business entities.
- Think: Dimension = Who / What / Where / When / Which
- Example:
    - Who bought something? → Customer
    - What was bought? → Product
    - Where did the sale happen? → Store
    - When did it happen? → Date
    - Which employee handled it? → Employee
## What is fact
- A fact table stores business events or measurements.
- Think: Fact = What happened + measurable numbers
- Dimension tells us about something. Fact tells us what happened involving that something.

## What is START Schema
- A star schema is data warehouse design where a central fact table is surrounded by multiple dimension tables.

                        dim_customer
                            |
                            |
        dim_product -----> fct_sales <----- dim_date
                            |
                            |
                        dim_store

- Star Schema is a dimensional modeling technique where a central fact table containing business measurements is connected to surrounding dimension tables containing descriptive attributes.

# Slowly Changing Dimension (SCD)
- A dimension is a table which stores descriptive information. Suppose we have a dim_customer table. One of the customer currently lives in Pune, after few months customer shifted to Mumbai. Now we have to store those records the first is Pune and latest is Mumbai. How we store? What is the strategy? SCD answer those questions.
- There are three types of SCD.
## SCD Type 1
- It is the simplest approach
- Rule: Overwrite the old value with new value.
## SCD Type 2
- Rule: Never overwrite the old value create new row for new value.
- Surrogate key helps in distinguishing between old and latest value
- it captures point-in-time history of a mutable table by inserting new rows for changes rather than updating in place, tagging each row with a validity window (dbt_valid_from / dbt_valid_to).
```text
Type 2 metadata columns dbt auto-adds
---------------------------------------------------------------------------------------|
Column	      |      Meaning                                                           |
------------- |------------------------------------------------------------------------|
dbt_scd_id	  |      A unique hash identifying this specific version/row of the record |
dbt_valid_from|	   Timestamp this version became active                                |
dbt_valid_to  |	   Timestamp this version stopped being active (NULL = still current)  |
---------------------------------------------------------------------------------------|
```
- SCD Type 2 with fact table
```text
dim_customer

| customer_sk | customer_id | city   | valid_from | valid_to |
| ----------: | ----------- | ------ | ---------- | -------- |
|         101 | C001        | Pune   | Jan 1      | Feb 15   |
|         205 | C001        | Mumbai | Feb 15     | NULL     |

fct_orders

| order_id | customer_sk | order_date | amount |
| -------- | ----------: | ---------- | -----: |
| O001     |         101 | Jan 20     |    500 |
| O002     |         205 | Mar 10     |    700 |

Notice:

O001 → customer_sk 101 → Pune
O002 → customer_sk 205 → Mumbai

This allows historical analysis
```
## SCD Type 3
- Rule: Keep the current value and previous value in the same row.
```text
For example:

| customer_id | current_city | previous_city |
| ----------- | ------------ | ------------- |
| C001        | Mumbai       | Pune          |


When the customer moves again:

Mumbai → Delhi

the row becomes:

| customer_id | current_city | previous_city |
| ----------- | ------------ | ------------- |
| C001        | Delhi        | Mumbai        |

```

# Handling Hard Deletes
- A hard delete occurs when a record is physically removed from the source. In current dbt snapshots, I can use the hard_deletes configuration. With invalidate, dbt closes the existing snapshot record when it detects that the source record has disappeared. With new_record, dbt also records the deletion as a new snapshot record, which is useful when I need an explicit deletion history. ignore, leaves the existing snapshot record unchanged
- There are three cinfigurations in modern hard delets:
    - hard_deletes = 'ignore'
    - hard_deletes = 'invalidate'
    - hard_deletes = 'new_record'

```sql
{% snapshot customer_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='updated_at',
        hard_deletes='new_record'/'ignore'/'invalidate'
    )
}}

select
    customer_id,
    customer_name,
    city,
    updated_at
from {{ source('raw', 'customers') }}

{% endsnapshot %}
```
1. hard_deletes = 'ignore'
```text
This is essentially:

Do nothing when a source record disappears.

Suppose the snapshot contains:

| customer_id | city   | dbt_valid_from | dbt_valid_to |
| ----------- | ------ | -------------- | ------------ |
| C001        | Pune   | Aug 1          | NULL         |
| C002        | Mumbai | Aug 1          | NULL         |


Then C002 is deleted from the source.

With:

hard_deletes: 'ignore'

the snapshot continues to have:

| customer_id | city   | dbt_valid_from | dbt_valid_to |
| ----------- | ------ | -------------- | ------------ |
| C001        | Pune   | Aug 1          | NULL         |
| C002        | Mumbai | Aug 1          | NULL         |


So the warehouse still considers the C002 version open.

This is usually not what you want if you need accurate deletion history.
```
2. hard_deletes = 'invalidate'
```text
This means:

When a source record disappears, close its current snapshot version.

Suppose:

Before deletion
| customer_id | city   | dbt_valid_from | dbt_valid_to |
| ----------- | ------ | -------------- | ------------ |
| C001        | Pune   | Aug 1          | NULL         |
| C002        | Mumbai | Aug 1          | NULL         |


C002 is deleted.

Run the snapshot again.

Now conceptually:

| customer_id | city   | dbt_valid_from | dbt_valid_to |
| ----------- | ------ | -------------- | ------------ |
| C001        | Pune   | Aug 1          | NULL         |
| C002        | Mumbai | Aug 1          | Aug 27       |


So dbt says:

"C002 was valid until the time I detected the deletion."

This is useful when you simply want to invalidate the existing record.
```

3. hard_deletes = 'new_record'
```text
This is more interesting.

Instead of only closing the old record, dbt creates a new snapshot record representing the deletion.

Conceptually:

Before:

| customer_id | city   | dbt_valid_from | dbt_valid_to |
| ----------- | ------ | -------------- | ------------ |
| C002        | Mumbai | Aug 1          | NULL         |


After deletion:

| customer_id | city   | dbt_valid_from | dbt_valid_to | dbt_is_deleted |
| ----------- | ------ | -------------- | ------------ | -------------- |
| C002        | Mumbai | Aug 1          | Aug 27       | false          |
| C002        | Mumbai | Aug 27         | NULL         | true           |


The exact metadata/schema depends on your dbt version and configuration, but the key idea is:

    new record
        ↓
    represents deletion

This gives you an explicit deletion event.
```

