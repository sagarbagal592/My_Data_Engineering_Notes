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