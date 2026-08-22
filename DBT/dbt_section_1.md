# dbt_section_1

## 1. What is dbt?

- dbt generally doesn't replace your data warehouse. It manages the SQL transformation layer that runs against your warehouse/lakehouse.
- dbt is a **Transformation Tool** that allows data engineers and analytics engineers to transform data inside a data warehouse/lakehouse using SQL, while providing features such as dependency management, testing, documentation, lineage, and reusable code.
- The key philosophical shift dbt brought: "T" happens inside the warehouse, in SQL, as software — with git, code review, CI/CD, and modularity — instead of in a black-box ETL tool.
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
{{ source('schema_name', 'table_name') }}
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
       - Checks that a column doesn't contain NULL values.

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

- A **model = one `.sql` file** in your `models/` directory containing a `SELECT` query.

- No `CREATE TABLE`, no DDL — dbt generates that for you based on configuration.

- The filename becomes the object name in the warehouse.
- A dbt model is a SQL-based transformation represented by a .sql file in a dbt project. When dbt runs the model, it compiles the SQL and Jinja, resolves dependencies such as ref() and source(), and materializes the result in the target warehouse as a view, table, incremental model, or ephemeral transformation. Models can also have tests, documentation, contracts, and lineage.
- A source represents data that already exists outside dbt, while a model represents a transformation managed by dbt. We reference sources using source() and other dbt models using ref().
- The important part is that dbt doesn't just execute the SQL. It also manages things like:

        dependencies
        materialization
        testing
        documentation
        lineage
        compilation
        deployment
- What happens when you run `dbt run`

        SQL file
        ↓
        Parse
        ↓
        Compile Jinja
        ↓
        Resolve dependencies
        ↓
        Apply materialization
        ↓
        Execute SQL in warehouse
        ↓
        Create/update database object
- Model is not necessarily a table

            dbt model
        │
        ├── materialized as VIEW
        │
        ├── materialized as TABLE
        │
        ├── materialized as INCREMENTAL
        │
        └── materialized as EPHEMERAL
- model = sql transformation defination
- materialization = how the result of that model is represented/stored
For example:

```text
models/staging/stg_orders.sql
```

becomes a table/view named:

```text
stg_orders
```

---
## 4. ref()

- ref() is a dbt Jinja function used to reference another dbt model. It resolves the model to the appropriate database relation and, importantly, tells dbt that the current model depends on that upstream model. dbt uses these dependencies to build the DAG, determine execution order, generate lineage, and support environment-specific relation resolution.
- source() is used to reference tables that exist outside dbt and have been declared as sources, while ref() is used to reference models created and managed by dbt. source() represents the entry point into the dbt transformation layer, while ref() establishes dependencies between dbt models.
- example

        SELECT *
        FROM {{ ref('stg_customers') }}

        This means: Use the output of the stg_customers dbt model as the input to this model.
- ref() create dependency
- ref() does two major things:

                        ref()
                        │
                ┌─────────┴─────────┐
                ▼                   ▼
        Resolve the relation    Create dependency
                │                   │
                ▼                   ▼
        Actual warehouse       DAG / lineage /
        object                   execution order

---

## 5. Materializations

### What is a materialization?

When dbt runs a model (`.sql` file), where and how should the resulting data be stored in the warehouse?

- The **SQL** tells dbt **what data you want**.
- The **materialization** tells dbt **how to create or store that result** in the data warehouse.

The five core materializations are:

1. `view`
2. `table`
3. `incremental`
4. `ephemeral`
5. `materialized_view`

---

### 5.1 `view`

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

### 5.2 `table`

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

### 5.3 `incremental`

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

> `is_incremental()`: a Jinja macro that's True only when (a) the model is materialized incremental, (b) the table already exists, and (c) you're not doing a full-refresh run. On the very first run, this whole {% if %} block is skipped and dbt builds the full table.

> `{{ this }}`: refers to the model's own current table — used to look up "what's the latest data I already have."

> unique_key: tells dbt how to identify a row for update-vs-insert logic.

> incremental_strategy: merge (default on most warehouses — upsert via MERGE), append (just insert, no updates — fastest, but duplicates possible), delete+insert (used where MERGE isn't supported), insert_overwrite (partition-level replace, common on BigQuery/Spark).

> `--full-refresh` flag: forces dbt to drop and rebuild the incremental table from scratch (e.g., after a logic change or schema change).

### Incremental strategies

Common incremental strategies include:

- `append`
- `merge`
- `delete + insert`
- `insert_overwrite`
- `microbatch`

        Incremental materialization
                |
                +-- append
                |      └── Insert new rows
                |
                +-- merge
                |      └── Insert + Update (upsert)
                |
                +-- delete+insert
                |      └── Delete matching + Insert
                |
                +-- insert_overwrite
                |      └── Replace affected partitions
                |
                +-- microbatch
                        └── Process time-based batches

### dbt feature: on_schema_change

- dbt provides

        {{ config(
            materialized='incremental',
            unique_key='order_id',
            incremental_strategy='merge',
            on_schema_change='.....'
        ) }}
- You can configure how dbt handles changes to the columns in your source/model
- There are four common options
    - 1. ignore
    - 2. fail
    - 3. append_new_columns
    - 4. sync_all_columns
1. ignore

        {{ config(
            materialized='incremental',
            on_schema_change='ignore'
        ) }}

    > This essentially says: Don't modify the existing target schema when the model's columns change.

2. fail

        {{ config(
            materialized='incremental',
            on_schema_change='fail'
        ) }}

    > This says: If the schema changes, stop the dbt run and tell me.

3. append_new_columns

        {{ config(
            materialized='incremental',
            on_schema_change='append_new_columns'
        ) }}
        
    > Now dbt can add the new column to the existing target table.

4. sync_all_columns
   > This goes further and synchronizes the target schema with the model schema, including adding/removing columns depending on the adapter's capabilities.

### dbt run -- full-refresh

- A normal dbt run doesn't rebuild the entire incremental target. The behavior of the new column depends on the on_schema_change configuration. With append_new_columns, dbt can add the new column to the target, but existing historical rows won't necessarily be backfilled. If I need the new column populated for all historical records, I would run dbt run --full-refresh, which rebuilds the incremental model from the entire source.

                  dbt run
                     |
             What materialization?
                     |
          ┌──────────┴──────────┐
          ↓                     ↓
      table/view            incremental
                                |
                     ┌──────────┴─────────┐
                     ↓                    ↓
               normal run            --full-refresh
                     ↓                    ↓
              incremental            rebuild
                update               everything

---

### 5.4 `ephemeral`

The original notes introduce `ephemeral` as the fourth core materialization but do not provide additional explanation or an example for it.

---

### 5.5 `materialized_view`

- A materialized view is like a combination of a view + table.
- A normal view stores only the SQL definition. So if you query the view 100 times, the underlying query may need to execute 100 times.
- A materialized view stores the result of the query physically. So querying it can be much faster because the result is already computed.
- The database then refreshes the materialized view when needed, depending on the database/platform.
- dbt asks the underlying warehouse to create/manage a materialized view rather than a regular view or table.
## Materialization Comparison

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
```text
| Materialization     | Stores data? | Main idea                                          |
| ------------------- | ------------ | -------------------------------------------------- |
| `view`              | ❌ No         | Store SQL, calculate when queried                  |
| `table`             | ✅ Yes        | Store complete result                              |
| `incremental`       | ✅ Yes        | Store result and update only changed/new data      |
| `ephemeral`         | ❌ No         | Inline SQL as a CTE                                |
| `materialized_view` | ✅ Yes        | Store query result and let the database refresh it |

```


### Configuring materialization

- Config precedence (highest wins): in-model config block > dbt_project.yml > default (view).

### The Golden Rule of Materializations:
- Start with models as views. When they take too long to query, make them tables. When the tables take too long to build, make them incremental.

---


### Q: You have a 2-billion-row fact table and every day only 10 million new records arrive. Which materialization would you choose?

**Answer:** I would consider an incremental materialization because rebuilding the entire 2-billion-row table every day would be expensive. With an incremental model, I can process only the new or changed records and merge them into the existing target table. I would also choose an appropriate incremental strategy and unique key based on whether the source contains inserts only or also updates.

---

### Common Misconceptions & Mistakes

- "Incremental = always faster." Not necessarily — the initial build is still a full table scan (as slow as table), and incremental models add complexity (late-arriving data, backfills, schema drift) that a plain table doesn't have. Don't reach for incremental prematurely — follow the Golden Rule.
- Hardcoding schema names instead of ref()/source() — breaks the DAG, breaks environment portability (dev vs prod), and dbt can no longer determine build order or lineage.
- Forgetting unique_key on a merge-strategy incremental model — without it, dbt can't tell what to update vs. insert, and you can silently get duplicate rows.
- Thinking ephemeral models are "free" performance-wise — they're inlined as CTEs into every downstream model that references them, so if 10 models ref() the same ephemeral model, that CTE logic gets recompiled and re-executed 10 times. Overusing ephemeral models on expensive logic can hurt performance.
- Not understanding is_incremental() runs False on first run — people are sometimes confused why a fresh dbt run on an incremental model builds the entire table rather than "nothing" (since there's nothing to compare against yet).
- Confusing materialized_view (warehouse-native, DB-managed refresh) with dbt's incremental (dbt-orchestrated batch refresh) — these solve a similar problem differently and interviewers like probing which one you'd pick and why

-------
 
### How This Is Tested in Interviews

- "Walk me through what materialization you'd choose for X scenario" (staging layer, a slowly changing dimension, a 2B-row events table) — they're testing the Golden Rule reasoning, not memorization.
- "What happens on the first run of an incremental model?" / "How does is_incremental() work under the hood?"
- "Your incremental model has duplicate rows in production — how do you debug it?" (answer usually touches on missing/wrong unique_key, late-arriving data past your filter window, or append strategy misuse)
- Scenario: "A colleague hardcoded a table name instead of using ref() — what breaks?" (DAG ordering, dbt docs lineage graph, environment promotion via dbt build --target prod)
- "Compare table vs incremental vs materialized_view — when would you use each?"

---

### Revision Summary
- A model = a .sql SELECT file; dbt handles the DDL.
- ref() links dbt models together and builds the DAG; source() points to raw, un-transformed tables.
- 5 materializations: view (default, no storage), table (full rebuild), incremental (only new/changed rows), ephemeral (inlined CTE, not built), materialized_view (warehouse-managed refresh).
- Golden Rule: view → table → incremental, escalate only when performance demands it.
- Incremental models rely on is_incremental(), {{ this }}, unique_key, and an incremental_strategy (merge/append/delete+insert/insert_overwrite).
- --full-refresh rebuilds an incremental model from scratch.

---
