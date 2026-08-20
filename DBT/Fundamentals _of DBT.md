# Fundamentals of dbt

## 1. What is dbt?

- dbt generally doesn't replace your data warehouse. It manages the SQL transformation layer that runs against your warehouse/lakehouse.
- dbt is a **Transformation Tool** that allows data engineers and analytics engineers to transform data inside a data warehouse/lakehouse using SQL, while providing features such as dependency management, testing, documentation, lineage, and reusable code.

### dbt is not primarily ETL

dbt doesn't primarily mean:

1. Extract data
2. Transform data
3. Load data

Instead, dbt is mainly focused on **Transformation**:

```text
Raw data ---> Warehouse ---> dbt ---> Analytics-ready data
                                  |
                                  v
                            TRANSFORMATION
```

This is why people often describe dbt as the **T** in ELT.

### Q: Is dbt an ETL tool?

**Answer:** dbt is primarily a transformation tool used in ELT architectures. It transforms data already loaded into a data warehouse or lakehouse using SQL. It also provides capabilities such as dependency management, testing, documentation, lineage, and reusable transformations.

---

## 2. Source

- **In dbt, the source function is used to reference raw/source tables that exist outside the dbt model.**
- First define the source in a YAML file:

```yaml
version: 2

sources:
  - name: source
    database: my_first_dbt_project
    schema: source
    tables:
      - name: fact_sales
      - name: fact_returns
```

### Using `source()`

Jinja code:

```jinja
{{ source('source_name', 'table_name') }}
```

Instead of writing:

```sql
SELECT *
FROM fact_sales
```

we write:

```sql
SELECT *
FROM {{ source('source', 'fact_sales') }}
```

### Why use `source()`?

Because it gives dbt additional information about the table.

So, `source()` is not just a shortcut for writing a table name. It makes the relationship between your dbt project and external raw data explicit and is helpful in building lineage.

> **Interview-ready definition:**  
> `source()` is a dbt Jinja function used to reference raw or external tables that are declared as sources in the dbt project's YAML configuration. Instead of hardcoding database and schema names in SQL, we use `{{ source('schema_name', 'table_name') }}`. This allows dbt to understand source lineage and also enables features such as source testing, documentation, and freshness checks.

### `source()` vs `ref()`

- **`source()`** is used when referring to a table that is external to dbt's model. (I am getting data from outside my dbt model)
- **`ref()`** is used when referring to another dbt model.(I am getting data from another dbt model)

### Source freshness

- Source freshness is very important concept because its let you answer: Is my upstream/source data arriving on time? or is it stale?

- It is diiferent from dbt testing whether the data is correct. Freshness is about when the data was last updated/loaded.
- We configure data freshness in source yml file.

```yaml
version: 2

sources:
  - name: source
    database: dbt_masterclass
    schema: source

    config:
      freshness:
        warn_after:
          count: 2
          period: hour

        error_after:
          count: 4
          period: hour

    tables:
      - name: dim_customers
        config:
          loaded_at_field: created_at # It is must we have column named 'created at'
        
```
#### loaded_at_field:

```
loaded_at_field: created_at
```
 - It tells dbt: 'use this timestamp column to determine when the source data was loaded'

        Suppose:

        dim_customers

        contains:

        customer_id | name  | created_at
        ------------|-------|-------------------
        101         | John  | 2026-08-19 15:00
        102         | Alice | 2026-08-19 15:00
        103         | Bob   | 2026-08-19 15:00

        dbt can look at:

        MAX(created_at)

        to determine the latest load timestamp.


### Source testing

- Source testing is not a completely separate testing framework from dbt testing. Source tests are dbt data tests that are attached to source tables rather than dbt models.

                    dbt data tests
                         │
             ┌───────────┴───────────┐
             │                       │
             ▼                       ▼
        Source tests            Model tests
             │                       │
        Test raw data           Test transformed data
    #### dbt tests:

    1. not_null
        Checks that a column doesn't contain NULL values.

            - name: customer_id
            data_tests:
                - not_null

            Conceptually, dbt checks:

            SELECT *
            FROM raw.customers
            WHERE customer_id IS NULL

            If rows are returned:

            TEST FAILED ❌

            If no rows are returned:

            TEST PASSED ✓

    2. unique

        - Checks whether values are unique.
    3. accepted values

        This checks whether a column contains only allowed values.

        For example:

            - name: status
            data_tests:
                - accepted_values:
                    arguments:
                    values: ['active', 'inactive']

            Suppose:

            status
            ------
            active
            active
            inactive
            active

            Passes.

            But:

            status
            ------
            active
            inactive
            deleted

            fails because:

            deleted

            isn't an accepted value.

    4. relationships

    - This is particularly useful for source testing.

            Suppose you have:

            raw.orders

            and:

            raw.customers

            Your orders table contains:

            order_id | customer_id
            ---------|------------
            1        | 101
            2        | 102
            3        | 103

            And customers contains:

            customer_id
            -----------
            101
            102
            103

            You expect every orders.customer_id to exist in customers.customer_id.

            You can test this using:

            - name: customer_id
            data_tests:
                - relationships:
                    arguments:
                    to: source('raw', 'customers')
                    field: customer_id

            Conceptually:

            orders.customer_id
                │
                ▼
            Does this customer exist?
                │
                ▼
            customers.customer_id

            If an order contains:

            customer_id = 999

            but customer 999 doesn't exist:

            TEST FAILED ❌
    - Example:
```yml
version: 2

sources:
  - name: source
  database: dbt_masterclass
    schema: source

    tables:

      - name: dim_customers

        config:
          freshness:
            warn_after:
              count: 2
              period: hour

            error_after:
              count: 4
              period: hour

        columns:

          - name: customer_id
            data_tests:
              - not_null
              - unique

          - name: status
            data_tests:
              - accepted_values:
                  arguments:
                    values:
                      - active
                      - inactive
```

### Source documentation

- Source documentation in dbt is the process of adding descriptions and metadata to your source data so that other data engineers, analysts, and stakeholders can understand what the source represents, what its tables mean, and what individual columns contain.
- complete example

        version: 2

        sources:

        - name: raw

            description: "Raw data ingested from operational systems."

            schema: raw

            tables:

            - name: customers

                description: "Customer information received from the CRM system."

                config:
                freshness:
                    warn_after:
                    count: 2
                    period: hour

                    error_after:
                    count: 4
                    period: hour

                columns:

                - name: customer_id
                    description: "Unique identifier assigned to each customer."

                    data_tests:
                    - not_null
                    - unique

                - name: customer_name
                    description: "Full name of the customer."

                - name: email
                    description: "Customer's registered email address."

                - name: created_at
                    description: "Timestamp when the customer record was created."
- Overall picture:


                                        raw.customers
                                    │
                ┌───────────────────┼───────────────────┐
                │                   │                   │
                ▼                   ▼                   ▼
        Documentation          Freshness             Tests
                │                   │                   │
        "What is it?"        "Is it recent?"       "Is it valid?"
                │                   │                   │
                └───────────────────┼───────────────────┘
                                    │
                                Data source

---

## 3. Model

A **model = one `.sql` file** in your `models/` directory containing a `SELECT` query.

No `CREATE TABLE`, no DDL — dbt generates that for you based on configuration.

The filename becomes the object name in the warehouse.

For example:

```text
models/staging/stg_orders.sql
```

becomes a table/view named:

```text
stg_orders
```

---

## 4. Materializations

### What is a materialization?

When dbt runs a model (`.sql` file), where and how should the resulting data be stored in the warehouse?

- The **SQL** tells dbt **what data you want**.
- The **materialization** tells dbt **how to create or store that result** in the data warehouse.

The four core materializations are:

1. `view`
2. `table`
3. `incremental`
4. `ephemeral`

---

### 4.1 `view`

With:

```jinja
{{ config(materialized='view') }}
```

dbt creates a database view instead of storing the query result as physical data.

It means the query is stored, but the resulting rows are generally not physically stored as a separate table.

**Think of it as:**

> `view` = store the query logic

#### Advantages

- Less storage
- Simple
- Good for staging

#### Disadvantage

- Every time downstream users query the view, the underlying SQL may need to execute.

---

### 4.2 `table`

With:

```jinja
{{ config(materialized='table') }}
```

dbt creates a physical table.

Tables are useful when your transformation is:

- Expensive
- Complex
- Frequently queried
- Used by dashboards
- Used by multiple downstream models

**Think of it as:**

> `table` = store the query result

---

### 4.3 `incremental`

Suppose you have an orders table with **1 billion rows**, and every day **5 million new rows** are added.

If you use a normal table materialization, dbt may rebuild the entire model, which is expensive.

With an incremental model, you can process only the new/changed data.

#### Basic incremental example

```jinja
{{ config(materialized='incremental') }}

SELECT
    order_id,
    customer_id,
    order_date,
    amount
FROM {{ source('raw', 'orders') }}

{% if is_incremental() %}

WHERE order_date > (
    SELECT MAX(order_date)
    FROM {{ this }}
)

{% endif %}
```

### Understanding `is_incremental()`

```jinja
{% if is_incremental() %}
```

It asks dbt whether this model is currently being built incrementally. If yes, the condition is applied.

This condition:

```sql
WHERE order_date > (
    SELECT MAX(order_date)
    FROM {{ this }}
)
```

means:

> Only process records newer than the latest record already present in the target table.

An incremental model can handle:

- New records
- Updated records
- Deleted records
- Late-arriving records

### Incremental strategies

Common incremental strategies include:

- `append`
- `merge`
- `delete + insert`
- `insert_overwrite`

---

### 4.4 `ephemeral`

The original notes introduce `ephemeral` as the fourth core materialization but do not provide additional explanation or an example for it.

---

## 5. Materialization Comparison

### `VIEW`

```text
VIEW
 |
 ├── Stores query logic
 ├── Doesn't generally store result data
 └── Good for lightweight transformations
```

### `TABLE`

```text
TABLE
 |
 ├── Stores result data
 ├── Rebuilt when dbt runs the model
 └── Good for expensive/important transformations
```

### `INCREMENTAL`

```text
INCREMENTAL
 |
 ├── Stores result data
 ├── Processes only required new/changed data
 └── Good for large datasets
```

### `EPHEMERAL`

```text
EPHEMERAL
 |
 ├── Doesn't create database object
 ├── SQL gets incorporated into downstream models
 └── Good for small reusable intermediate logic
```

---

## 6. Interview Question

### Q: You have a 2-billion-row fact table and every day only 10 million new records arrive. Which materialization would you choose?

**Answer:** I would consider an incremental materialization because rebuilding the entire 2-billion-row table every day would be expensive. With an incremental model, I can process only the new or changed records and merge them into the existing target table. I would also choose an appropriate incremental strategy and unique key based on whether the source contains inserts only or also updates.
