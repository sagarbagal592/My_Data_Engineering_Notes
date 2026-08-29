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