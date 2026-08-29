select

    order_item_id,

    order_id,

    product_id,

    quantity,

    cast(unit_price as decimal(18,2)) as unit_price,

    quantity * unit_price as line_item_amount

from {{ source('source', 'order_items') }}