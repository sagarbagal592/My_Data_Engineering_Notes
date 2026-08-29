# Complete End-to-End dbt Project --- ShopEasy E-commerce Analytics

Since you have already learned the individual dbt concepts, the best
next step is to build **one realistic project where all of those
concepts work together**.

This example uses an **e-commerce analytics platform** and covers:

-   Sources
-   Source tests
-   Source freshness
-   Documentation
-   `source()`
-   `ref()`
-   Staging models
-   Intermediate models
-   Mart models
-   Generic data tests
-   Singular data tests
-   Unit tests
-   Severity
-   `store_failures`
-   Packages
-   Snapshots
-   Jinja
-   Jinja `if/else`
-   Jinja `for` loops
-   Macros
-   Surrogate keys
-   Star schema
-   Complete dbt project architecture
-   Production execution flow
-   Documentation generation
-   Final DAG

> **Version note:** Current dbt documentation uses `data_tests:` as the
> preferred YAML key; `tests:` remains supported for backward
> compatibility. Unit tests are separate from data tests.

------------------------------------------------------------------------

# 1. Business Scenario

Imagine an e-commerce company:

**ShopEasy**

The application produces raw data:

``` text
customers
orders
order_items
products
payments
```

The application database is replicated into our warehouse.

We want to build:

``` text
Raw Source
   ↓
Source Definitions
   ↓
Source Tests + Freshness
   ↓
Staging
   ↓
Intermediate
   ↓
Snapshots
   ↓
Dimensions / Facts
   ↓
Data Tests
   ↓
Unit Tests
   ↓
Analytics / BI
```

Our final business questions are:

-   How much revenue did we generate?
-   What are our best-selling products?
-   Who are our customers?
-   What is the customer lifetime value?
-   What is the order success rate?
-   How have customer attributes changed over time?

------------------------------------------------------------------------

# 2. Overall Architecture

``` text
                         ┌─────────────────────┐
                         │   Application DB    │
                         │ PostgreSQL / MySQL  │
                         └──────────┬──────────┘
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │    RAW / BRONZE     │
                         │                     │
                         │ raw_customers       │
                         │ raw_orders          │
                         │ raw_order_items     │
                         │ raw_products        │
                         │ raw_payments        │
                         └──────────┬──────────┘
                                    │
                              source()
                                    │
                                    ▼
                  ┌─────────────────────────────────┐
                  │       DBT SOURCE LAYER          │
                  │                                 │
                  │ source definitions              │
                  │ source tests                    │
                  │ source freshness                │
                  │ source documentation             │
                  └───────────────┬─────────────────┘
                                  │
                                  ▼
                    ┌─────────────────────────┐
                    │      STAGING LAYER       │
                    │                          │
                    │ stg_customers            │
                    │ stg_orders               │
                    │ stg_order_items          │
                    │ stg_products             │
                    │ stg_payments             │
                    └────────────┬────────────┘
                                 │
                               ref()
                                 │
                                 ▼
                    ┌─────────────────────────┐
                    │    INTERMEDIATE LAYER    │
                    │                          │
                    │ int_order_items          │
                    │ int_orders_enriched      │
                    │ int_customer_orders      │
                    └────────────┬────────────┘
                                 │
                         ┌───────┴────────┐
                         │                │
                         ▼                ▼
                  ┌─────────────┐  ┌─────────────┐
                  │  SNAPSHOTS  │  │    TESTS    │
                  │             │  │             │
                  │ customers   │  │ generic     │
                  │ history     │  │ singular    │
                  └──────┬──────┘  │ unit        │
                         │         └─────────────┘
                         ▼
              ┌───────────────────────────┐
              │        MART LAYER         │
              │                           │
              │ dim_customers             │
              │ dim_products              │
              │ fct_orders                │
              │ fct_order_items           │
              └──────────────┬────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ BI / Analytics  │
                    │ Power BI        │
                    │ Tableau         │
                    │ Looker          │
                    └─────────────────┘
```

------------------------------------------------------------------------

# 3. Complete Project Structure

``` text
shopeasy_dbt/
│
├── dbt_project.yml
├── packages.yml
├── README.md
│
├── models/
│   │
│   ├── sources/
│   │   └── ecommerce_sources.yml
│   │
│   ├── staging/
│   │   └── ecommerce/
│   │       ├── stg_customers.sql
│   │       ├── stg_orders.sql
│   │       ├── stg_order_items.sql
│   │       ├── stg_products.sql
│   │       ├── stg_payments.sql
│   │       └── _ecommerce__models.yml
│   │
│   ├── intermediate/
│   │   └── ecommerce/
│   │       ├── int_order_items.sql
│   │       ├── int_orders_enriched.sql
│   │       ├── int_customer_orders.sql
│   │       └── _ecommerce__models.yml
│   │
│   └── marts/
│       │
│       └── ecommerce/
│           ├── dim_customers.sql
│           ├── dim_products.sql
│           ├── fct_orders.sql
│           ├── fct_order_items.sql
│           └── _ecommerce__models.yml
│
├── snapshots/
│   ├── customers_snapshot.yml
│   └── orders_snapshot.yml
│
├── tests/
│   ├── assert_order_total_matches_items.sql
│   ├── assert_no_negative_revenue.sql
│   └── assert_customer_order_count.sql
│
├── macros/
│   ├── generate_surrogate_key.sql
│   ├── cents_to_dollars.sql
│   └── conditional_column.sql
│
├── unit_tests/
│   └── ...
│
├── seeds/
│   └── country_codes.csv
│
└── analyses/
    └── customer_revenue_analysis.sql
```

Important modern dbt distinction:

``` text
tests/
    ↓
data tests
    ├── singular
    └── generic

models/
    ↓
unit test YAML definitions
```

------------------------------------------------------------------------

# 4. `dbt_project.yml`

``` yaml
name: 'shopeasy_dbt'
version: '1.0.0'
config-version: 2

profile: 'shopeasy'

model-paths:
  - models

test-paths:
  - tests

snapshot-paths:
  - snapshots

macro-paths:
  - macros

seed-paths:
  - seeds

analysis-paths:
  - analyses

models:

  shopeasy_dbt:

    staging:
      +materialized: view
      +schema: staging

    intermediate:
      +materialized: view
      +schema: intermediate

    marts:
      +materialized: table
      +schema: marts

snapshots:
  shopeasy_dbt:
    +schema: snapshots
```

Think of this as:

``` text
staging      → views
intermediate → views
marts        → tables
snapshots    → historical tables
```

------------------------------------------------------------------------

# 5. Source Layer

Our raw database looks like:

``` text
raw.ecommerce.customers
raw.ecommerce.orders
raw.ecommerce.order_items
raw.ecommerce.products
raw.ecommerce.payments
```

We don't want to hard-code these names throughout our models.

Instead, we declare them as dbt sources.

------------------------------------------------------------------------

# 6. Source Definition

`models/sources/ecommerce_sources.yml`

``` yaml
version: 2

sources:

  - name: ecommerce
    database: raw
    schema: ecommerce

    description: >
      Raw e-commerce data loaded from the ShopEasy application database.

    config:
      freshness:
        warn_after:
          count: 6
          period: hour

        error_after:
          count: 12
          period: hour

      loaded_at_field: _etl_loaded_at

    tables:

      - name: customers

        description: >
          One record per customer from the ShopEasy application.

        columns:

          - name: customer_id

            description: >
              Unique identifier of the customer.

            data_tests:
              - not_null
              - unique

          - name: email

            description: Customer email address.

            data_tests:
              - not_null

      - name: orders

        description: >
          One record per customer order.

        columns:

          - name: order_id

            description: Unique identifier of the order.

            data_tests:
              - not_null
              - unique

          - name: customer_id

            description: Customer who placed the order.

            data_tests:
              - not_null

      - name: order_items

        description: >
          Individual products belonging to an order.

        columns:

          - name: order_item_id

            description: Unique identifier of the order item.

            data_tests:
              - not_null
              - unique

          - name: order_id

            description: Associated order.

            data_tests:
              - not_null

      - name: products

        description: >
          Product master data.

        columns:

          - name: product_id

            description: Unique identifier of the product.

            data_tests:
              - not_null
              - unique

      - name: payments

        description: >
          Payment transactions associated with orders.

        columns:

          - name: payment_id

            description: Unique payment identifier.

            data_tests:
              - not_null
              - unique
```

This one YAML file demonstrates:

-   Source
-   Source documentation
-   Source columns
-   Source tests
-   Source freshness

------------------------------------------------------------------------

# 7. What Does `source()` Do?

Create:

`models/staging/ecommerce/stg_customers.sql`

``` sql
select
    customer_id,
    first_name,
    last_name,
    email,
    country,
    created_at,
    updated_at

from {{ source('ecommerce', 'customers') }}
```

The important part is:

``` sql
{{ source('ecommerce', 'customers') }}
```

Conceptually:

``` text
source('ecommerce', 'customers')
        │
        ▼
raw.ecommerce.customers
```

`source()` also adds the dependency to the dbt DAG.

------------------------------------------------------------------------

# 8. Source Testing

We have:

``` yaml
data_tests:
  - not_null
  - unique
```

For example:

``` yaml
- name: customer_id
  data_tests:
    - not_null
    - unique
```

This means:

### Test 1

``` text
customer_id cannot be NULL
```

### Test 2

``` text
customer_id must be unique
```

A dbt data test is essentially a query that tries to find records that
violate your assertion. If zero failing records are returned, the test
passes.

------------------------------------------------------------------------

# 9. Source Freshness

We configured:

``` yaml
config:
  freshness:
    warn_after:
      count: 6
      period: hour

    error_after:
      count: 12
      period: hour

  loaded_at_field: _etl_loaded_at
```

Meaning:

``` text
Data loaded within 6 hours
        ↓
       PASS

6–12 hours old
        ↓
      WARN

More than 12 hours old
        ↓
      ERROR
```

Run:

``` bash
dbt source freshness
```

dbt uses the configured timestamp to determine how recently the source
was loaded.

------------------------------------------------------------------------

# 10. Staging Layer

The staging layer performs **light transformations**.

Typical staging responsibilities:

``` text
rename columns
cast data types
clean strings
standardize dates
normalize boolean values
remove obvious technical noise
```

It should generally **not** contain complex business logic.

------------------------------------------------------------------------

# 11. `stg_customers.sql`

``` sql
select

    customer_id,

    trim(first_name) as first_name,

    trim(last_name) as last_name,

    lower(trim(email)) as email,

    upper(trim(country)) as country,

    cast(created_at as timestamp) as created_at,

    cast(updated_at as timestamp) as updated_at

from {{ source('ecommerce', 'customers') }}
```

------------------------------------------------------------------------

# 12. `stg_orders.sql`

``` sql
select

    order_id,

    customer_id,

    cast(order_date as date) as order_date,

    lower(trim(status)) as status,

    cast(order_total as decimal(18,2)) as order_total,

    cast(updated_at as timestamp) as updated_at

from {{ source('ecommerce', 'orders') }}
```

------------------------------------------------------------------------

# 13. `stg_order_items.sql`

``` sql
select

    order_item_id,

    order_id,

    product_id,

    quantity,

    cast(unit_price as decimal(18,2)) as unit_price,

    quantity * unit_price as line_item_amount

from {{ source('ecommerce', 'order_items') }}
```

------------------------------------------------------------------------

# 14. `stg_products.sql`

``` sql
select

    product_id,

    trim(product_name) as product_name,

    upper(trim(category)) as category,

    cast(price as decimal(18,2)) as price,

    cast(updated_at as timestamp) as updated_at

from {{ source('ecommerce', 'products') }}
```

------------------------------------------------------------------------

# 15. `stg_payments.sql`

``` sql
select

    payment_id,

    order_id,

    lower(trim(payment_method)) as payment_method,

    lower(trim(payment_status)) as payment_status,

    cast(amount as decimal(18,2)) as amount,

    cast(payment_date as timestamp) as payment_date

from {{ source('ecommerce', 'payments') }}
```

------------------------------------------------------------------------

# 16. Now `ref()` Comes Into Play

Suppose we want to create:

``` text
int_order_items
```

We don't write:

``` sql
from staging.stg_order_items
```

Instead:

``` sql
from {{ ref('stg_order_items') }}
```

Important dbt philosophy:

> Don't hard-code physical table names. Use dbt's DAG-aware references.

------------------------------------------------------------------------

# 17. Intermediate Layer

`int_order_items.sql`

``` sql
select

    oi.order_item_id,

    oi.order_id,

    oi.product_id,

    oi.quantity,

    oi.unit_price,

    oi.line_item_amount,

    p.product_name,

    p.category

from {{ ref('stg_order_items') }} oi

left join {{ ref('stg_products') }} p
    on oi.product_id = p.product_id
```

The DAG now becomes:

``` text
source.order_items
       ↓
stg_order_items
       ↓
int_order_items
       ↑
stg_products
       ↑
source.products
```

------------------------------------------------------------------------

# 18. `int_orders_enriched.sql`

``` sql
select

    o.order_id,

    o.customer_id,

    o.order_date,

    o.status,

    o.order_total,

    coalesce(sum(oi.line_item_amount), 0) as calculated_order_total

from {{ ref('stg_orders') }} o

left join {{ ref('stg_order_items') }} oi
    on o.order_id = oi.order_id

group by

    o.order_id,
    o.customer_id,
    o.order_date,
    o.status,
    o.order_total
```

Now we can compare:

``` text
order_total
      vs
calculated_order_total
```

That will become useful later for a **singular data test**.

------------------------------------------------------------------------

# 19. Marts

Now we build business-facing models.

The mart layer contains:

``` text
dim_customers
dim_products

fct_orders
fct_order_items
```

This is our **star schema**.

``` text
                dim_customers
                      │
                      │
                      ▼
dim_products ───► fct_orders ◄─── payments
                      │
                      │
                      ▼
                fct_order_items
```

------------------------------------------------------------------------

# 20. `dim_products.sql`

``` sql
select

    product_id,

    product_name,

    category,

    price

from {{ ref('stg_products') }}
```

------------------------------------------------------------------------

# 21. `fct_order_items.sql`

``` sql
select

    order_item_id,

    order_id,

    product_id,

    quantity,

    unit_price,

    line_item_amount

from {{ ref('int_order_items') }}
```

------------------------------------------------------------------------

# 22. `fct_orders.sql`

``` sql
select

    o.order_id,

    o.customer_id,

    o.order_date,

    o.status,

    o.order_total,

    o.calculated_order_total,

    case
        when o.status = 'completed'
            then o.order_total
        else 0
    end as recognized_revenue

from {{ ref('int_orders_enriched') }} o
```

Here we have business logic.

------------------------------------------------------------------------

# 23. Documentation

Document our mart models.

`models/marts/ecommerce/_ecommerce__models.yml`

``` yaml
version: 2

models:

  - name: dim_customers

    description: >
      Customer dimension containing one record per customer.

    columns:

      - name: customer_id

        description: >
          Unique identifier for the customer.

        data_tests:
          - not_null
          - unique

      - name: email

        description: >
          Customer email address.

        data_tests:
          - not_null


  - name: dim_products

    description: >
      Product dimension containing one record per product.

    columns:

      - name: product_id

        description: >
          Unique product identifier.

        data_tests:
          - not_null
          - unique

      - name: product_name

        description: >
          Display name of the product.


  - name: fct_orders

    description: >
      Order-level fact table containing one row per order.

    columns:

      - name: order_id

        description: >
          Unique order identifier.

        data_tests:
          - not_null
          - unique

      - name: customer_id

        description: >
          Customer who placed the order.

        data_tests:
          - not_null

          - relationships:
              to: ref('dim_customers')
              field: customer_id

      - name: order_total

        description: >
          Total monetary value of the order.

      - name: recognized_revenue

        description: >
          Revenue recognized from completed orders.
```

------------------------------------------------------------------------

# 24. Generic Data Tests

We've already used built-in generic tests:

``` yaml
- unique
- not_null
- relationships
```

These are **reusable assertions**.

For example:

``` yaml
data_tests:
  - unique
```

can be applied to:

``` text
customers.customer_id
orders.order_id
products.product_id
```

The logic doesn't need to be rewritten.

Generic tests are parameterized and reusable across models, columns,
sources, snapshots, and seeds.

------------------------------------------------------------------------

# 25. Accepted Values

We can also test order status.

``` yaml
- name: status

  data_tests:

    - accepted_values:
        values:
          - pending
          - processing
          - completed
          - cancelled
```

This catches:

``` text
completed
pending
processing
cancelled
```

but rejects:

``` text
COMPLETE
success
unknown
abc
```

------------------------------------------------------------------------

# 26. Severity

Suppose a missing customer ID is critical:

``` yaml
data_tests:

  - not_null:
      config:
        severity: error
```

But perhaps an unexpected order status is less critical:

``` yaml
data_tests:

  - accepted_values:
      values:
        - pending
        - processing
        - completed
        - cancelled

      config:
        severity: warn
```

Conceptually:

``` text
ERROR
 ↓
dbt test/build can fail

WARN
 ↓
dbt reports warning
```

This lets you distinguish:

``` text
Critical data quality problem
        vs
Potential data quality problem
```

------------------------------------------------------------------------

# 27. Custom Generic Test

Suppose the business says:

> Order total must never be negative.

Create:

`macros/test_positive_value.sql`

``` sql
{% test positive_value(model, column_name) %}

select *

from {{ model }}

where {{ column_name }} < 0

{% endtest %}
```

Then:

``` yaml
models:

  - name: fct_orders

    columns:

      - name: order_total

        data_tests:
          - positive_value
```

This is powerful because:

``` text
positive_value
      │
      ├── fct_orders.order_total
      ├── fct_payments.amount
      └── dim_products.price
```

One test definition can be reused everywhere.

------------------------------------------------------------------------

# 28. Singular Data Test

Now let's test something very specific.

Business requirement:

> `order_total` should equal the sum of its order items.

Create:

`tests/assert_order_total_matches_items.sql`

``` sql
select

    o.order_id,

    o.order_total,

    coalesce(sum(oi.line_item_amount), 0) as calculated_total

from {{ ref('fct_orders') }} o

left join {{ ref('fct_order_items') }} oi
    on o.order_id = oi.order_id

group by

    o.order_id,

    o.order_total

having

    abs(
        coalesce(sum(oi.line_item_amount), 0)
        - o.order_total
    ) > 0.01
```

This query returns **bad records**.

Therefore:

``` text
0 rows → PASS

1+ rows → FAIL
```

Because this is a one-off business assertion, it is a:

**singular data test**

------------------------------------------------------------------------

# 29. Another Singular Test

`tests/assert_no_negative_revenue.sql`

``` sql
select

    order_id,
    recognized_revenue

from {{ ref('fct_orders') }}

where recognized_revenue < 0
```

Again:

``` text
No rows → PASS
Rows → FAIL
```

------------------------------------------------------------------------

# 30. Generic vs Singular Test

This distinction is extremely important for interviews.

### Generic

Reusable:

``` text
"customer_id must be unique"
```

Can apply to:

``` text
customers
orders
products
payments
```

### Singular

Specific:

``` text
"order_total must equal sum(order_items)"
```

This particular business rule may only apply to orders.

Therefore:

``` text
Generic
   ↓
Reusable rule

Singular
   ↓
One-off business rule
```

------------------------------------------------------------------------

# 31. Unit Tests

Now comes a different type of testing.

Suppose we have:

``` sql
case
    when status = 'completed'
        then order_total
    else 0
end as recognized_revenue
```

We want to test the **SQL logic itself**.

We don't necessarily want to build the complete model against millions
of production rows.

Instead we can provide small fixture data.

Unit tests validate SQL modeling logic against small static inputs
before materializing the full model.

------------------------------------------------------------------------

# 32. Unit Test Example

A unit-test YAML can look like:

`models/marts/ecommerce/_fct_orders_unit_tests.yml`

``` yaml
version: 2

unit_tests:

  - name: test_recognized_revenue

    description: >
      Completed orders should recognize the full order total.
      Cancelled orders should recognize zero revenue.

    model: fct_orders

    given:

      - input: ref('int_orders_enriched')

        rows:

          - order_id: 1
            customer_id: 101
            order_date: '2026-08-01'
            status: 'completed'
            order_total: 100.00
            calculated_order_total: 100.00

          - order_id: 2
            customer_id: 102
            order_date: '2026-08-01'
            status: 'cancelled'
            order_total: 200.00
            calculated_order_total: 200.00

    expect:

      rows:

        - order_id: 1
          recognized_revenue: 100.00

        - order_id: 2
          recognized_revenue: 0.00
```

Conceptually:

``` text
INPUT

status = completed
order_total = 100

        ↓

MODEL LOGIC

case
    when status = 'completed'
    then order_total
    else 0
end

        ↓

EXPECTED

recognized_revenue = 100
```

And:

``` text
INPUT

status = cancelled
order_total = 200

        ↓

EXPECTED

recognized_revenue = 0
```

------------------------------------------------------------------------

# 33. Data Test vs Unit Test

This is one of the most important concepts.

### Unit test

Tests:

> **Did I write the SQL logic correctly?**

Example:

``` text
completed → revenue = order total
cancelled → revenue = 0
```

### Data test

Tests:

> **Does the actual resulting dataset satisfy my data-quality/business
> rules?**

Example:

``` text
order_id must be unique
customer_id cannot be null
order total must equal line items
```

So:

``` text
Unit Test
    ↓
SQL LOGIC

Data Test
    ↓
DATA QUALITY / BUSINESS ASSERTION
```

------------------------------------------------------------------------

# 34. Store Failures

Normally:

``` bash
dbt test
```

finds failing rows and reports the test failure.

For debugging:

``` bash
dbt test --store-failures
```

dbt persists failing records into the warehouse.

Conceptually:

``` text
fct_orders
     │
     │
     ▼
assert_order_total_matches_items
     │
     │ FAIL
     ▼
dbt_test__audit
     │
     ▼
failing records
```

You can then inspect the failure table:

``` sql
select *

from dbt_test__audit.<failure_table>
```

This is extremely useful when debugging production failures.

------------------------------------------------------------------------

# 35. Packages

A common package is:

``` text
dbt-utils
```

Packages are reusable dbt projects containing things such as:

``` text
macros
models
tests
```

that become available to your project.

------------------------------------------------------------------------

# 36. `packages.yml`

For example:

``` yaml
packages:

  - package: dbt-labs/dbt_utils
    version: "1.3.0"
```

Then:

``` bash
dbt deps
```

Install the package.

Now you can use package functionality such as:

``` sql
{{ dbt_utils.generate_surrogate_key([
    'customer_id'
]) }}
```

Or:

``` sql
{{ dbt_utils.generate_surrogate_key([
    'customer_id',
    'email'
]) }}
```

The exact package version should be chosen according to the adapter/dbt
version you are using.

------------------------------------------------------------------------

# 37. Why Packages?

Imagine you need:

``` text
surrogate key
date spine
pivot
union relations
cardinality tests
etc.
```

You could write everything yourself.

Or:

``` text
Community package
        ↓
Reusable macros/tests
        ↓
Your project
```

This is conceptually similar to:

``` text
Python

pip install pandas

        vs

dbt

dbt deps
```

But dbt packages are **dbt projects containing reusable dbt resources**,
not Python libraries.

------------------------------------------------------------------------

# 38. Snapshots

Suppose our customer table is mutable.

Today:

``` text
customer_id | country
------------|--------
101         | India
```

Tomorrow:

``` text
customer_id | country
------------|--------
101         | USA
```

The raw table has overwritten:

``` text
India
```

with:

``` text
USA
```

We lost history.

This is where snapshots come in.

dbt snapshots record changes to mutable data and implement a Type-2
Slowly Changing Dimension pattern.

------------------------------------------------------------------------

# 39. Customer Snapshot

Current dbt versions support defining snapshot configurations in YAML.

`snapshots/customers_snapshot.yml`

``` yaml
version: 2

snapshots:

  - name: customers_snapshot

    relation: source('ecommerce', 'customers')

    description: >
      Historical record of customer changes.

    config:

      schema: snapshots

      strategy: timestamp

      unique_key: customer_id

      updated_at: updated_at
```

The important pieces are:

``` text
strategy
unique_key
updated_at
```

Current snapshot documentation supports `timestamp` and `check`
strategies.

------------------------------------------------------------------------

# 40. Timestamp Snapshot Strategy

Suppose:

``` text
customer_id = 101

updated_at = 2026-08-01
country = India
```

Then later:

``` text
customer_id = 101

updated_at = 2026-08-10
country = USA
```

Snapshot produces something conceptually like:

``` text
customer_id | country | dbt_valid_from | dbt_valid_to
------------|---------|-----------------|--------------
101         | India   | Aug 1           | Aug 10
101         | USA     | Aug 10          | NULL
```

Therefore we can ask:

> What country was customer 101 in on August 5?

Answer:

``` text
India
```

------------------------------------------------------------------------

# 41. Check Snapshot Strategy

Sometimes there isn't a reliable `updated_at`.

Then we can use:

``` yaml
config:

  strategy: check

  unique_key: customer_id

  check_cols:
    - first_name
    - last_name
    - email
    - country
```

Now dbt checks whether these columns changed.

Conceptually:

``` text
Old row

customer_id = 101
country = India

        ↓

New row

customer_id = 101
country = USA

        ↓

CHANGE DETECTED
        ↓
New historical version
```

------------------------------------------------------------------------

# 42. Important Snapshot Design Lesson

Do **not** blindly snapshot a heavily transformed mart.

For example, this is usually a bad design:

``` text
source
   ↓
staging
   ↓
intermediate
   ↓
dim_customer
   ↓
snapshot
```

if `dim_customer` contains lots of transformations and joins.

Better:

``` text
Raw mutable source
       ↓
Customer snapshot
       ↓
Historical customer model
       ↓
dim_customer
```

The snapshot should generally capture the historical state of the
mutable entity rather than snapshotting an unstable, heavily transformed
reporting model.

This matters especially when the model contains joins because changes in
unrelated upstream tables could create apparent changes to the row.

------------------------------------------------------------------------

# 43. Jinja

Jinja allows us to make SQL dynamic.

You have already seen:

``` sql
{{ ref('stg_orders') }}
```

That's Jinja.

Important Jinja syntax:

``` text
{{ ... }}
{% ... %}
{# ... #}
```

------------------------------------------------------------------------

# 44. Jinja `{{ }}`

Used primarily to **output/render something**.

Example:

``` jinja
{{ ref('stg_orders') }}
```

Another example:

``` jinja
{{ var('environment') }}
```

------------------------------------------------------------------------

# 45. Jinja `{% %}`

Used for logic.

Example:

``` jinja
{% if target.name == 'prod' %}

    ...

{% else %}

    ...

{% endif %}
```

------------------------------------------------------------------------

# 46. Jinja If/Else

Suppose production should use a stricter filter.

``` sql
select *

from {{ ref('stg_orders') }}

{% if target.name == 'prod' %}

where status != 'test'

{% else %}

where 1 = 1

{% endif %}
```

Conceptually:

``` text
target = prod
      ↓
where status != 'test'
```

Development:

``` text
target = dev
      ↓
where 1 = 1
```

Key concept:

> Jinja executes while dbt is compiling the SQL. It is not SQL itself.

------------------------------------------------------------------------

# 47. Jinja For Loop

Suppose we have:

``` text
sales
returns
discount
tax
shipping
```

Instead of:

``` sql
select
    sales,
    returns,
    discount,
    tax,
    shipping
```

we can use:

``` jinja
{% set metrics = [
    'sales',
    'returns',
    'discount',
    'tax',
    'shipping'
] %}

select

    order_id,

    {% for metric in metrics %}

        {{ metric }}

        {% if not loop.last %}
            ,
        {% endif %}

    {% endfor %}

from {{ ref('fct_orders') }}
```

Jinja generates SQL equivalent to:

``` sql
select
    order_id,
    sales,
    returns,
    discount,
    tax,
    shipping

from ...
```

------------------------------------------------------------------------

# 48. Jinja For Loop With Business Logic

Here's a more useful example.

``` jinja
{% set statuses = [
    'pending',
    'processing',
    'completed',
    'cancelled'
] %}

select

    customer_id,

    {% for status in statuses %}

        sum(
            case
                when status = '{{ status }}'
                then 1
                else 0
            end
        ) as {{ status }}_orders

        {% if not loop.last %}
            ,
        {% endif %}

    {% endfor %}

from {{ ref('stg_orders') }}

group by customer_id
```

This produces:

``` sql
select

    customer_id,

    sum(case when status = 'pending'
        then 1 else 0 end) as pending_orders,

    sum(case when status = 'processing'
        then 1 else 0 end) as processing_orders,

    sum(case when status = 'completed'
        then 1 else 0 end) as completed_orders,

    sum(case when status = 'cancelled'
        then 1 else 0 end) as cancelled_orders

from ...

group by customer_id
```

This is where Jinja becomes genuinely powerful.

------------------------------------------------------------------------

# 49. Jinja + Macro

Instead of repeatedly writing:

``` sql
quantity * unit_price
```

we could create a macro.

`macros/cents_to_dollars.sql`

``` jinja
{% macro cents_to_dollars(column_name) %}

    {{ column_name }} / 100.0

{% endmacro %}
```

Then:

``` sql
select

    order_id,

    {{ cents_to_dollars('amount_cents') }} as amount

from {{ ref('stg_payments') }}
```

The macro generates:

``` sql
amount_cents / 100.0
```

------------------------------------------------------------------------

# 50. Surrogate Keys

In our dimension model we may want:

``` text
customer_sk
```

rather than using:

``` text
customer_id
```

A simple custom macro:

``` jinja
{% macro generate_customer_key(customer_id) %}

    md5(cast({{ customer_id }} as varchar))

{% endmacro %}
```

Then:

``` sql
select

    {{ generate_customer_key('customer_id') }}
        as customer_sk,

    customer_id,

    first_name,

    last_name

from {{ ref('stg_customers') }}
```

Packages such as `dbt_utils` also provide reusable functionality for
common patterns like surrogate keys.

------------------------------------------------------------------------

# 51. Complete `dim_customers`

Let's combine concepts.

``` sql
select

    {{ dbt_utils.generate_surrogate_key([
        'customer_id'
    ]) }} as customer_sk,

    customer_id,

    first_name,

    last_name,

    email,

    country,

    created_at,

    updated_at

from {{ ref('stg_customers') }}
```

Now:

``` text
stg_customers
      │
      │ ref()
      ▼
dim_customers
      │
      ▼
analytics users
```

------------------------------------------------------------------------

# 52. Complete Testing Architecture

Our project now has multiple testing levels.

``` text
                         TESTING
                            │
             ┌──────────────┼───────────────┐
             │              │               │
             ▼              ▼               ▼
       SOURCE TESTS     DATA TESTS      UNIT TESTS
             │              │               │
             │              ├── Generic     │
             │              │               │
             │              └── Singular    │
             │                              │
             ▼                              ▼
       Raw data quality              SQL logic
```

------------------------------------------------------------------------

# 53. Source Tests

Example:

``` yaml
sources:

  - name: ecommerce

    tables:

      - name: customers

        columns:

          - name: customer_id

            data_tests:
              - unique
              - not_null
```

Question answered:

> Is my upstream data valid?

------------------------------------------------------------------------

# 54. Generic Data Tests

Example:

``` yaml
models:

  - name: fct_orders

    columns:

      - name: order_id

        data_tests:
          - unique
          - not_null
```

Question answered:

> Does my model satisfy standard data-quality rules?

------------------------------------------------------------------------

# 55. Singular Data Tests

Example:

``` sql
select ...

from {{ ref('fct_orders') }}

having calculated_total != order_total
```

Question answered:

> Does this specific business rule hold?

------------------------------------------------------------------------

# 56. Unit Tests

Example:

``` text
completed order
     ↓
revenue = order_total

cancelled order
     ↓
revenue = 0
```

Question answered:

> Does my transformation logic behave correctly for controlled inputs?

------------------------------------------------------------------------

# 57. Source Freshness

Question:

> Is upstream data arriving on time?

Example:

``` text
Expected:
every 2 hours

Actual:
last loaded 14 hours ago

        ↓

ERROR
```

------------------------------------------------------------------------

# 58. Snapshot

Question:

> What did the data look like in the past?

Example:

``` text
customer country:

Aug 1  → India
Aug 10 → USA
Aug 20 → UK
```

------------------------------------------------------------------------

# 59. Documentation

Question:

> What does this model/column mean?

Example:

``` yaml
description: >
  Revenue recognized from completed orders.
```

Documentation makes the warehouse understandable to:

``` text
Data Engineers
Analytics Engineers
Data Analysts
BI Developers
Business Users
```

------------------------------------------------------------------------

# 60. Final DAG

After everything is connected:

``` text
                    RAW
                     │
          ┌──────────┼──────────┐
          │          │          │
          ▼          ▼          ▼
      customers    orders    products
          │          │          │
          ▼          ▼          ▼
    stg_customers stg_orders stg_products
          │          │          │
          │          └────┬─────┘
          │               │
          │               ▼
          │       int_orders_enriched
          │               │
          │               ▼
          │          fct_orders
          │
          ▼
    customers_snapshot
          │
          ▼
    dim_customers


products
   │
   ▼
stg_products
   │
   ▼
int_order_items
   │
   ▼
fct_order_items
```

And tests sit across this graph:

``` text
SOURCE
  │
  ├── source tests
  └── freshness
  │
  ▼
STAGING
  │
  └── generic tests
  │
  ▼
INTERMEDIATE
  │
  └── unit tests
  │
  ▼
MART
  │
  ├── generic tests
  ├── singular tests
  └── unit tests
```

------------------------------------------------------------------------

# 61. How You Actually Run This Project

During development:

``` bash
dbt debug
```

Check your connection.

Then:

``` bash
dbt deps
```

Install packages.

Then:

``` bash
dbt source freshness
```

Check upstream data freshness.

Then:

``` bash
dbt build
```

This is the command I would use most often in a real dbt project.

Conceptually:

``` text
build
 │
 ├── models
 ├── seeds
 ├── snapshots
 └── tests
```

------------------------------------------------------------------------

# 62. Run Only Sources

``` bash
dbt test --select "source:*"
```

------------------------------------------------------------------------

# 63. Run Only Data Tests

``` bash
dbt test --select "test_type:data"
```

This excludes unit tests.

------------------------------------------------------------------------

# 64. Run Unit Tests

You can select unit tests separately depending on your dbt version and
selector setup.

Conceptually:

``` text
dbt test
    │
    ├── data tests
    └── unit tests
```

The important conceptual difference is that unit tests don't require you
to build the full production-sized model first; they exercise model
logic using controlled fixture inputs.

------------------------------------------------------------------------

# 65. Run Snapshot

``` bash
dbt snapshot
```

This updates your snapshot tables with detected changes.

------------------------------------------------------------------------

# 66. Store Failures

For debugging:

``` bash
dbt test --store-failures
```

Then inspect the generated failure tables.

Remember:

``` text
Normal test
     ↓
find failures
     ↓
report

store_failures
     ↓
persist failures
     ↓
query/debug them
```

------------------------------------------------------------------------

# 67. Generate Documentation

``` bash
dbt docs generate
```

Then:

``` bash
dbt docs serve
```

The documentation site gives you a browsable representation of:

``` text
models
sources
columns
descriptions
tests
dependencies
lineage
```

------------------------------------------------------------------------

# 68. Complete Production Flow

Imagine a production job runs every morning.

### Step 1 --- Check source freshness

``` bash
dbt source freshness
```

``` text
Are upstream systems delivering data?
```

### Step 2 --- Install dependencies

``` bash
dbt deps
```

### Step 3 --- Build

``` bash
dbt build
```

### Step 4 --- Snapshot

Depending on your orchestration design:

``` bash
dbt snapshot
```

### Step 5 --- Tests

``` text
source tests
generic tests
singular tests
unit tests
```

### Step 6 --- Publish

``` text
marts
   ↓
Power BI / Tableau / Looker
```

------------------------------------------------------------------------

# 69. More Realistic Production DAG

In practice I'd think of the system as:

``` text
              ┌───────────────────┐
              │  Application DB   │
              └─────────┬─────────┘
                        │
                        ▼
              ┌───────────────────┐
              │     RAW DATA      │
              └─────────┬─────────┘
                        │
                        ▼
             ┌──────────────────────┐
             │ SOURCE DEFINITIONS   │
             │                      │
             │ Tests                │
             │ Freshness            │
             │ Documentation        │
             └──────────┬───────────┘
                        │
                     source()
                        │
                        ▼
             ┌──────────────────────┐
             │       STAGING        │
             │                      │
             │ stg_customers        │
             │ stg_orders           │
             │ stg_products         │
             │ stg_order_items      │
             └──────────┬───────────┘
                        │
                      ref()
                        │
                        ▼
             ┌──────────────────────┐
             │    INTERMEDIATE      │
             │                      │
             │ joins                │
             │ calculations         │
             │ business preparation │
             └──────────┬───────────┘
                        │
                  ┌─────┴──────┐
                  │            │
                  ▼            ▼
             SNAPSHOTS      TESTING
                  │            │
                  │       ┌────┼────┐
                  │       │    │    │
                  │       ▼    ▼    ▼
                  │     Generic Singular Unit
                  │
                  └───────┬───────┘
                          │
                          ▼
                 ┌──────────────────┐
                 │      MARTS       │
                 │                  │
                 │ dim_customers    │
                 │ dim_products     │
                 │ fct_orders       │
                 │ fct_order_items  │
                 └────────┬─────────┘
                          │
                          ▼
                    BI / Analytics
```

------------------------------------------------------------------------

# 70. Where Each dbt Concept Fits

  -----------------------------------------------------------------------
  Concept                 Where                   Purpose
  ----------------------- ----------------------- -----------------------
  `source()`              Staging                 Reference raw tables

  Source tests            Sources                 Validate upstream data

  Source freshness        Sources                 Detect stale pipelines

  Documentation           YAML                    Explain data assets

  `ref()`                 Models                  Reference other dbt
                                                  models

  Staging models          `models/staging`        Light transformations

  Intermediate models     `models/intermediate`   Reusable transformation
                                                  logic

  Mart models             `models/marts`          Business-facing data

  Generic tests           YAML                    Reusable data-quality
                                                  rules

  Singular tests          `tests/*.sql`           One-off business
                                                  assertions

  Unit tests              Model YAML              Validate SQL logic with
                                                  fixtures

  `severity`              Test config             WARN vs ERROR

  `store_failures`        Tests                   Persist failing rows

  Packages                `packages.yml`          Reuse community code

  Snapshots               `snapshots/`            Track historical
                                                  changes

  Jinja                   `.sql`/YAML             Dynamic
                                                  SQL/configuration

  `if/else`               Jinja                   Conditional SQL
                                                  generation

  `for` loop              Jinja                   Generate repetitive SQL

  Macros                  `macros/`               Reusable SQL generation

  Seeds                   `seeds/`                Small static reference
                                                  datasets
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 71. The Most Important Mental Model

Don't think of dbt as:

> "A tool where I write SQL files."

Think of dbt as:

> **A framework for building a dependency-aware, tested, documented
> transformation graph inside a data warehouse.**

Your SQL is only one part.

The full system is:

``` text
                    DBT
                     │
      ┌──────────────┼───────────────┐
      │              │               │
      ▼              ▼               ▼
 Transformation   Quality         Governance
      │              │               │
      │              │               │
      ▼              ▼               ▼
    Models         Tests        Documentation
      │              │
      │              ├── Generic
      │              ├── Singular
      │              └── Unit
      │
      ├── source()
      ├── ref()
      ├── Jinja
      ├── Macros
      └── Packages
                     │
                     ▼
                  History
                     │
                     └── Snapshots
```

------------------------------------------------------------------------

# 72. Recommended Hands-On Build Order

Since you've already learned the concepts individually, **don't just
read this example**.

Build it as a hands-on project in this order:

``` text
PHASE 1
│
├── Create dbt project
├── Configure warehouse
└── Create raw tables
        ↓
PHASE 2
│
├── sources.yml
├── source documentation
├── source tests
└── source freshness
        ↓
PHASE 3
│
├── staging models
├── source()
└── ref()
        ↓
PHASE 4
│
├── intermediate models
└── joins/business preparation
        ↓
PHASE 5
│
├── snapshots
└── SCD Type 2
        ↓
PHASE 6
│
├── dimensions
├── facts
└── star schema
        ↓
PHASE 7
│
├── generic tests
├── custom generic tests
├── singular tests
├── severity
└── store_failures
        ↓
PHASE 8
│
├── unit tests
└── test complex SQL logic
        ↓
PHASE 9
│
├── Jinja
├── if/else
├── for loops
└── macros
        ↓
PHASE 10
│
├── packages
├── dbt_utils
└── reusable functionality
        ↓
PHASE 11
│
├── documentation
├── lineage
└── dbt docs
        ↓
PHASE 12
│
└── dbt build
```

That sequence will make the concepts connect naturally rather than
feeling like a collection of unrelated dbt features.

------------------------------------------------------------------------

# 73. Final Summary

The complete architecture can be remembered as:

``` text
                         DBT PROJECT
                              │
                              ▼
                         RAW SOURCES
                              │
                         source()
                              │
                              ▼
                     SOURCE VALIDATION
                     ├── Tests
                     ├── Freshness
                     └── Documentation
                              │
                              ▼
                         STAGING
                              │
                            ref()
                              │
                              ▼
                       INTERMEDIATE
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    ▼                   ▼
                SNAPSHOTS            TESTING
                    │                   │
                    │          ┌────────┼────────┐
                    │          │        │        │
                    │       Generic  Singular   Unit
                    │
                    └──────────┬───────────────┘
                               │
                               ▼
                             MARTS
                        ┌──────┴──────┐
                        │             │
                     DIMENSIONS      FACTS
                        │             │
                        └──────┬──────┘
                               │
                               ▼
                         BI / ANALYTICS
```

The key mental model is:

``` text
source()
    ↓
Raw data

ref()
    ↓
dbt model dependency

Models
    ↓
Transformation

Generic tests
    ↓
Reusable data-quality rules

Singular tests
    ↓
Specific business assertions

Unit tests
    ↓
SQL transformation logic

Snapshots
    ↓
Historical changes

Jinja
    ↓
Dynamic SQL

Macros
    ↓
Reusable SQL generation

Packages
    ↓
Reusable dbt functionality

Documentation
    ↓
Understandability + lineage

dbt build
    ↓
Build + test the project
```

This is the type of architecture you should be comfortable explaining in
a Data Engineer / Analytics Engineer interview.
