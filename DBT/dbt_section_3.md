# dbt_section_3: Jinja, Macros and Packages
- jinja is a templating language written in python
- dbt uses Jinja to add programming capabilities to SQL.
- Normally sql is static
```sql
SELECT order_id, customer_id, order_total FROM orders;
```
- With jinja, you can make sql dynamic
```sql
SELECT order_id, customer_id, order_total FROM {{ref('stg_orders')}}
```
- Here, `ref('stg_orders')` is a jinja syntax. dbt processes the jinja first and generates sql, which is then send to your warehouse/database.
> Databricks does not understand Jinja. dbt understands Jinja and converts it into SQL before sending the SQL to Databricks.
- SQL is excellent for querying and transforming data, but SQL by itself isn't particularly good at things such as:
    - conditional logic
    - loops
    - variables
    - reusable SQL
    - dynamic SQL generation
    - environment-specific behavior
    - metadata-driven transformations
---
## 3.1 Jinja syntax
- There are three major jinja delimeter types:
```text
| Delimiter | Purpose        |
| --------- | -------------- |
| `{{ }}`   | Output a value |-> Give me a value
| `{% %}`   | Execute logic  |-> Do something
| `{# #}`   | Comment        |-> Don't output this

```
### 3.1.1 {{}}- expression/output delimeter
- It means evaluate this expression and put its result into the generated sql
### 3.1.2 { % % }-statement/logic delimeter
- This is used when you want jinja to perform some logic, rather than simply output a value
- Example
```jinja
{% set country = 'India' %} # here you are saying create a jinja variable called country
```
### conditional logic
- You can use
```jinja
{% if %}
{% else %}
{% endif %}
```
### 3.1.3 {# #}- comment delimeter
- jinja comments are removed during compilation. A sql comment can remain in compiled sql.

## 3.2 jinja variables
- You can create variable using `set` -> `{% set table_name = 'customers' %}`
- Then 
```jinja
SELECT * FROM {{table_name}}
            
SELECT * FROM customers # This is compiled sql
```
- Variable containing a list
```jinja
{% set columns = ['customer_id','customer_name','email'] %}

You can use jinja to iterate over it

SELECT
{%  for column in columns %}
    {{column}} {% if not loop.last %}, {% endif %}
{% endfor %}
FROM customers
```
- Result
```sql
SELECT 
    customer_id,
    customer_name,
    email
FROM customers
```
## 3.3 Jinja for loop
- jinja supports loop
```jinja
{% for column in columns%}
    {{column}}
{% endfor %}
```
### 3.3.1 loop object
- Inside a jinja loop, you have access to special object `loop`
```jinja
{% for column in columns%}
    {{column}}
    {{loop.index}} OR {{loop.first}} OR {{loop.last}}
{% endfor %}
```
### 3.3.2 if/elif/else
```jinja
{% if condition %}
    ...
{% elif another_condition %}
    ...
{% else %}
    ...
{% endif %}
```
### 3.3.3 is_incremental()

## 3.4 {{source('schema_name','table_name')}}, {{ref(model_name)}}

## 3.5 var() user defined dbt variables

- dbt allows you to define variables
```yml
# project.yml

vars:
    country: India
```
- Then in your model
```jinja
SELECT *
FROM customers
WHERE country = '{{ var("country") }}'
```
## 3.6 target - current dbt execution environment
```jinja
{{target.name}} OR {{target.databse}} OR {{target.schema}}
```
## 3.7 {{this}}- current model

## 3.8 macros
- A macro is essentially a reusable piece of Jinja/SQL logic.
- Suppose you repeatedly need
```sql
UPPER(TRIM(customer_name))
```
- Instead of repeating it everywhere, you can create a macro
```jinja
{% macro clean_string(column_name) %}
    UPPER(TRIM({{ column_name }}))
{% endmacro %}
```
- Then use
```jinja
{{ clean_string('customer_name') }}
```
### 3.8.1 Two very different kinds of macro returns

1. Macro 1: returns sql text

> for example
```jinja
{% set macro cents_to_dollar(column_name) %}
    {{ column_name }}/100
{% endmacro %}
```
> You might call
```sql
SELECT
    {{cents_to_dollar('amount_cents')}} as amount_dollar
FROM {{ref(orders)}}
```
> The macro effectively produces sql text
```sql
SELECT
    amount_cents/100 as amount_dollar
FROM models.bronze.orders
```

2. Macro 2: return a list

> Now I write my macro as

```yml
{% set macro get_payment_methods() %}
    {% set methods = var('payment_methods',
                        ['cerdit card','paypal','BHIM','Bank Transfer']
                        )
    %}
    {{ return(methods) }}
{% endmacro %}

# here I also write 
{% set methods = ['cerdit card','paypal','BHIM','Bank Transfer'] %}
# But, by using var() we will provide default value that can be overwrite during dbt run
# This way we include dynamic nature
```
> Then your model could contain

```sql
SELECT
    order_id,

    {% for method in get_payment_methods() %}

        SUM(
            CASE
                WHEN payment_method = '{{ method }}'
                THEN 1
                ELSE 0
            END
        ) AS {{ method }}_count

        {% if not loop.last %},{% endif %}

    {% endfor %}

FROM {{ ref('stg_payments') }}

GROUP BY order_id
```

```text
Here the important part is 
{{ return(methods) }}
This tells dbt:
    Return the actual Jinja object methods from the macro.
    and NOT generate sql text representing this object.
The return jinja object we can iterate over.
```
- A macro can be used either to generate SQL text or to return a Jinja value for further Jinja processing. For a SQL-expression macro such as cents_to_dollars(), the macro output becomes part of the compiled SQL. 
But when a macro returns a Jinja list that will be consumed by a for loop, we should use dbt's return() mechanism to return the actual list object. Otherwise, we risk treating the list as rendered text rather than as a Jinja collection that the caller can iterate over.

## 3.9 adapter
- This is especially useful when creating a macros that need to behave differently depending on the warehouse/database.
```jinja
{% if target.type = 'databricks'%}
    ---
{% endif %}
```
- This allows you to write warehouse specific logic

## 3.10 var()
- In dbt var() is dbt jinja function used to retrieve a variable.
- The basic syntax is
```jinja
{{ var('variable_name') }} # This is type 1 where I define variable without a default value
                           # Here I need to make sure to pass variable value at runtime else it will be a error
{{ var('variable_name','default_value') }} # Type 2 where I provide default value explicitly
```


```yml
# In dbt_project.yml

name: pysparkdbt

vars:
  variable_name: value
```
```bash
# Or during runtime

dbt run --vars '{"variable_name": 'value'}'

# If you already define value then it will override and if not then it will use this value.
```
- This means: dbt, give me the value of variable named `variable_name`
- The value of the variable can be defined in dbt_project.yml or passed at runtime using `--vars`
- Example:

```sql
SELECT *
FROM {{ ref('fct_orders') }}

{% if var('is_test_run', true) %}
    LIMIT 100
{% endif %}
```
```text
- Here I have defined variable with default value true. 
    Means if I not provide any value during runtime it will still utilise that default value
- If I run: dbt run --vars '{'is_test_run':false}' then it will simply override 
    the default value and as per logic limit 100 will be skipped.
```

## 3.11 Example
```text
Suppose I have a table orders:
    contains columnns order_id, status
    status = placed, shipped, delivered, cancelled

If I want to count status for each order_id
```

```sql
SELECT
    order_id,
    sum(case when status = "placed" then 1 else 0 end) as placed_count,
    sum(case when status = "shipped" then 1 else 0 end) as shipped_count,
    sum(case when status = "delivered" then 1 else 0 end) as delivered_count,
    sum(case when status = "cancelled" then 1 else 0 end) as cancelled_count
FROM orders
GROUP BY order_id;
```
> With jinja I make above static sql code dynamic!
```sql
{% set list = ['placed','shipped','delivered','cancelled'] %}

SELECT
    order_id,
    {% for i in list %}
        sum(case when status = {{i}} then 1 else 0 end) as {{i}}_count
        {% if not loop.last %},{% endif %}
    {% endfor %}
    FROM {{ref(orders)}}
    GROUP BY order_id;
```

## Packages in DBT
- dbt packages are one of the most useful features in dbt because they allow you to reuse dbt code written by other people or other teams instead of building everything yourself.
- A model is a transformation in your dbt project. A package is a reusable collection of dbt resources.
- In dbt, you can install a package and use its:
   - macros
   - models
   - tests
   - seeds
   - snapshots
   - documentation
   - other dbt resources
- dbt packages are reusable collections of dbt resources such as macros, models, tests, and other project components. They allow teams to reuse functionality instead of implementing common transformations and utilities from scratch. Packages are declared in `packages.yml` and installed using `dbt deps`. Package versions can be managed through dependency configuration and `package-lock.yml`, which helps make builds reproducible.
- `dbt deps` resolves and installs the packages declared in `packages.yml`. It doesn't execute models; it prepares the project's dependencies.
- `packages.yml`->What dependencies do I want?
- `package-lock.yml`-> What dependency versions were resolved?
#### Why do we need packages:
- Imagine you're working on a dbt project and you need to:
    - generate surrogate keys
    - perform common date transformations
    - build data quality tests
    - analyze source freshness
    - perform common utility transformations
    - generate standardized staging models
- Instead of writing code multiple times you can leverage existing package.
- A dbt package contain:
```text
Package
│
├── macros/
│   ├── macro1.sql
│   ├── macro2.sql
│   └── macro3.sql
│
├── models/
│   ├── model1.sql
│   └── model2.sql
│
├── tests/
│
├── seeds/
│
├── snapshots/
│
├── analyses/
│
├── dbt_project.yml
│
└── README.md
```
### The most common use: Reusable macro
```text
Suppose someone has created a package containing:

{% macro cents_to_dollars(column_name) %}
    {{ column_name }} / 100.0
{% endmacro %}

After installing the package, you may be able to call:

{{ package_name.cents_to_dollars('amount_cents') }}

Instead of creating that macro yourself.
```
### How do we install package
```text
dbt uses a file called:

packages.yml

This file defines the packages your project depends on.

For example:

packages:
  - package: dbt-labs/dbt_utils
    version: 1.3.0

Then run:

dbt deps

This tells dbt:

Download/install all packages specified in packages.yml.

packages.yml is essentially your dependency definition file.

packages:
  - package: dbt-labs/dbt_utils
    version: 1.3.0
```
### What is dbt utils
- One of the most widely used dbt package is dbt utils.
- It is maintained by dbt labs and provides reuable macros and other functionality.

### packages.yml vs package-lock.yml
```text
You'll encounter another file:

package-lock.yml

This is an important distinction.

packages.yml

Defines what your project wants.

For example:

packages:
  - package: dbt-labs/dbt_utils
    version: 1.3.0
package-lock.yml

Records the dependency resolution that dbt actually uses.

Conceptually:

        packages.yml
            ↓
        declared dependency
            ↓
        dependency resolution
            ↓
        package-lock.yml
            ↓
        reproducible dependency installation

You should generally commit the lock file to version control so your team/CI environment can reproduce the dependency set.
```
### Important terminology

    | Term                      | Meaning                                                 |
    | ------------------------- | ------------------------------------------------------- |
    | **Package**               | Reusable collection of dbt resources                    |
    | **`packages.yml`**        | Declares project dependencies                           |
    | **`dbt deps`**            | Installs/resolves packages                              |
    | **`dbt_packages/`**       | Directory containing installed packages                 |
    | **`package-lock.yml`**    | Records resolved package dependencies/versions          |
    | **Dependency**            | Package your project relies on                          |
    | **Package registry**      | Repository/catalog from which packages can be installed |
    | **Git package**           | Package installed from a Git repository                 |
    | **Namespace**             | Name used to distinguish package resources              |
    | **Macro**                 | Reusable Jinja/dbt logic                                |
    | **Package model**         | dbt model supplied by a package                         |
    | **Transitive dependency** | Dependency of one of your dependencies                  |
    | **Version pinning**       | Restricting a package to a specific version             |
    | **Private package**       | Internally maintained package                           |


