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
### 1.2 Singular Tests
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





