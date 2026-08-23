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
## 3.9 adapter
- This is especially useful when creating a macros that need to behave differently depending on the warehouse/database.
```jinja
{% if target.type = 'databricks'%}
    ---
{% endif %}
```
- This allows you to write warehouse specific logic