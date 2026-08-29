select

    o.order_id,

    o.customer_id,

    o.order_date,

    o.status,

    o.order_total,

    o.calculated_order_total,

    case
        when o.status = 'completed'
            then o.order_total
        else 0
    end as recognized_revenue

from {{ ref('int_orders_enriched') }} o