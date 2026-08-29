select

    product_id,

    trim(product_name) as product_name,

    upper(trim(category)) as category,

    cast(price as decimal(18,2)) as price,

    cast(updated_at as timestamp) as updated_at

from {{ source('source', 'products') }}