select

    payment_id,

    order_id,

    lower(trim(payment_method)) as payment_method,

    lower(trim(payment_status)) as payment_status,

    cast(amount as decimal(18,2)) as amount,

    cast(payment_date as timestamp) as payment_date

from {{ source('source', 'payments') }}