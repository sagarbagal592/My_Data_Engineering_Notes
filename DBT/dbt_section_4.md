# DBT Snapshots
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
