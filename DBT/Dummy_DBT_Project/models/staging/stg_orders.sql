select

    order_id,

    customer_id,

    cast(order_date as date) as order_date,

    lower(trim(status)) as status,

    cast(order_total as decimal(18,2)) as order_total,

    cast(updated_at as timestamp) as updated_at

from {{ source('source', 'orders') }}