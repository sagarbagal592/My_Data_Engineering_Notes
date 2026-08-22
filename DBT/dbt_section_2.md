# dbt_section_2: Sources,Seeds and Tests

- Section 1 was about building transformations. Section 2 is about trusting the inputs and outputs of those transformations.
- sources formalize where raw data comes from so dbt can track lineage and freshness on it. 
- seeds let you load small static CSVs as if they were source tables, version-controlled in git. 
- tests are assertions — SQL queries that should return zero rows if your data is healthy — run automatically via dbt test to catch data quality problems before they hit a dashboard.

---
## 1. Data Tests

- Data tests in dbt are used to check whether the data in your models is correct, complete, and consistent.
- Think of them as automated data quality checks.
- A dbt test is essentially a SQL query that looks for bad records.
- Data tests in dbt are automated data quality checks used to validate the data produced by our models. dbt provides built-in generic tests such as unique, not_null, accepted_values, and relationships, and we can also create custom singular SQL tests for business-specific rules. A test generally passes when its validation query returns zero violating records and fails when it finds bad records.
- For example:
    ```sql
    SELECT customer_id
    FROM customers
    WHERE customer_id IS NULL
    ```
    > If this query returns 0 rows, the test passes.
    > If it returns one or more rows, the test fails.
- So, remember: dbt data tests generally look for records that violate a rule.

                dbt test
                   |
                   ↓
             Run test SQL
                   |
          Does it return rows?
             /          \
           NO            YES
           ↓              ↓
         PASS           FAIL
- There are two types of tests:
    1. Data Tests
        - Generic Tests
            - unique
            - not null
            - accepted_values
            - relationships
        - Singular Tests
    2. Unit Tests

### 1.1 Generic Tests
1. unique
2. not_null
3. accepted_values
4. relationships

```yml
models:
  - name: customers

    columns:
      - name: customer_id
        data_tests:
          - unique
          - not_null

      - name: email
        data_tests:
          - not_null

      - name: order_status
        data_tests:
          - accepted_values:
              arguments:
                values:
                  - pending
                  - shipped
                  - delivered
                  - cancelled

      - name: customer_id
        data_tests:
          - relationships:
              arguments:
                to: ref('customers')
                field: customer_id
```
- running the tests: 
```yml
dbt test
or 
dbt test --select customers
```
### 1.1.1 Singular Tests
- A generic test is a reusable test definition.
- A singular test is a custom SQL test that you write for one specific business rule.
- For example:
```sql
SELECT *
FROM orders
WHERE order_amount < 0
```
- You might save it as:
> tests/orders_have_positive_amount.sql
- Then dbt can execute it as a test.
- The logic is:
    - Query returns 0 rows → PASS
    - Query returns rows   → FAIL
---

#### Things to remember

    | Concept           | Meaning                       |
    | ----------------- | ----------------------------- |
    | `unique`          | No duplicate values           |
    | `not_null`        | No NULL values                |
    | `accepted_values` | Only allowed values           |
    | `relationships`   | Foreign-key-like relationship |
    | Generic test      | Reusable test                 |
    | Singular test     | Custom SQL test               |
    | `dbt test`        | Executes data tests           |
    | Test passes       | No violating records found    |
    | Test fails        | Violating records found       |

---

### 1.2 Unit Test
- Data tests check the data after the model runs.
- Unit tests check whether the model's SQL logic behaves correctly for specific input examples.
- Example:
```sql
SELECT
    customer_id,
    amount,
    CASE
        WHEN amount > 1000 THEN 'High'
        ELSE 'Low'
    END AS customer_segment
FROM orders
```
- In unit test we are testing a small unit of transformation logic, rather than checking the entire dataset.
- Think:
```text
Data Test
   ↓
"Is my actual production data valid?"

Unit Test
   ↓
"Does my SQL transformation logic produce the expected result?"
```
- Unit tests are useful for complicated SQL logic such as: case, complex joins
- simple comparision:
```text
|                 | Unit Test                                | Data Test                           |
| --------------- | ---------------------------------------- | ----------------------------------- |
| Tests           | SQL/model logic                          | Actual data quality                 |
| Input           | Controlled/test data                     | Actual model data                   |
| Expected result | Explicitly defined                       | Usually zero violating rows         |
| Example         | `$500 → Medium`                          | `customer_id` isn't NULL            |
| Purpose         | Verify transformation behavior           | Detect bad production data          |
| Common tests    | Business logic, calculations, edge cases | `unique`, `not_null`, relationships |

```
---

## 2. Seeds

- A dbt seed is a CSV file that you keep inside your dbt project and load into your data warehouse as a table.
> Seed = CSV file → dbt → database table
- Don't treat seeds as your general-purpose data ingestion mechanism. They're best suited for small reference data that you want to version-control alongside your dbt project.
- A source represents data that already exists in your warehouse and comes from an external system. A seed is data that you provide inside the dbt project itself.
- Don't use seeds as a replacement for your main data ingestion pipeline. Because seeds are intended primarily for small, static or slowly changing reference data.
- seed gives you version control, code review, reproducibility, easy deployment, ability to reference data using ref(). All this characteristics make clarification that why not to use source instead of seeds.
- When should I use seed:

       Small reference data
             ↓
        Country mappings
        Currency mappings
        Status mappings
        Business rules
        Small lookup tables
        Static configuration data
- ref() with seeds
    - Even though a seed is a CSV file, you don't reference the CSV directly from your SQL model.
    - you use:
        ```sql
        {{ ref('country_codes') }}
        ```
- For example, 

        suppose you have a small mapping file:

        country_code,country_name
        IN,India
        US,United States
        UK,United Kingdom
        AU,Australia

        You can store it in your dbt project:

        my_dbt_project/
        │
        ├── models/
        ├── tests/
        ├── seeds/
        │   └── country_codes.csv
        ├── macros/
        └── dbt_project.yml

        When you run:

        dbt seed

        dbt loads the CSV into your warehouse as a table.

- Seeds are mainly useful for small, relatively static datasets that your transformations need
- For example:

        Country mappings
                IN → India
                US → United States
                UK → United Kingdom

        Currency mappings
                USD → US Dollar
                INR → Indian Rupee
                EUR → Euro

        Business mappings
                product_code → product_category
                Manually maintained reference data
                sales_region → region_manager

        Instead of manually creating these tables in your warehouse, you can keep the CSV in Git and let dbt manage it.
- We can define data types inside seed and also perform seed tests.

---
## 3. Test Configuration: severity and store_failures
- In dbt, test severity controls how a failed test is classified, typically as a warning or an error. warn_if and error_if can be used to define thresholds based on the number of failing records. store_failures: true tells dbt to persist the rows returned by the failing test query, which is useful for debugging and investigating data-quality issues.
- Think of it this way:
```text
dbt test
   ↓
Test finds bad records
   ↓
What should dbt do?
   ├── severity → How serious is the failure?
   └── store_failures → Should bad records be saved?
```
### 3.1 Severity

- severity determines whether a test result should be treated as an actual failure or just a warning
- There are two main values:
```yml
severity: error # This is the default behaviour
severity: warn
```
```yml
- name: customer_id
  data_tests:
    - relationships:
        to: ref('dim_customers')
        field: customer_id
        config:
          severity: warn
          where: "order_date > '2025-01-01'"
          store_failures: true
```
- for `severity: error` dbt treats it as an error and it will block the pipeline. This is appropriate for critical rule such as:
    - primary key must be unique
    - primary key must not be null
    - critical referential integrity
- for `severity:warn` dbt reports a warning instead of a normal test error. This is helpful when a rule is important but you dont necessarily want it to block your pipeline.

#### warn_if and error_if

```yml
- accepted_values:
    arguments:
      values:
        - active
        - inactive
    config:
      warn_if: ">0"
      error_if: ">10"
```
conceptually:
```text
Imagine the test finds: 5 invalid records
Then:
    5 > 0  → warning
    5 > 10 → false
WARNING
```
### 3.2 store_failures

- Normally, when a test fails, dbt tells you that the test failed, but you may want to inspect the actual bad records.
- dbt stores the failing rows in a database relation, typically in a test-failure schema/relation.




