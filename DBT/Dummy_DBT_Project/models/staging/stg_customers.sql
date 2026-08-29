SELECT * FROM {{ source('source','customers') }}

```text
In staging layer we perform light transformation like:

    rename columns
    cast data types
    clean strings
    standardize dates
    normalize boolean values
    remove obvious technical noise
```
# So above query can be written as:

select

    customer_id,

    trim(first_name) as first_name,

    trim(last_name) as last_name,

    lower(trim(email)) as email,

    upper(trim(country)) as country,

    cast(created_at as timestamp) as created_at,

    cast(updated_at as timestamp) as updated_at

from {{ source('source', 'customers') }}