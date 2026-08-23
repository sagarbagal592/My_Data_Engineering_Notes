## Section 1
Question 1 (easy):
You have a small dimension table (dim_country, ~250 rows, rarely changes) that several downstream models join against. Which materialization would you pick, and why — walk me through your reasoning using the Golden Rule?
---
Question 2 (easy-medium):
You add {{ config(materialized='table') }} inside a model file, but dbt_project.yml also sets +materialized: view for that folder. Which one wins, and why does dbt's config precedence work this way?
---
Question 3 (medium):
You have an incremental model on fct_events using unique_key='event_id' and incremental_strategy='merge'. After a few weeks in production, your data team notices some events that arrived late (e.g., an event with event_ts from 3 days ago shows up in today's load, but your incremental filter was where event_ts > (select max(event_ts) from {{ this }})). What's going wrong here, and how would you fix the filter logic to handle late-arriving data?
---
Answer:

    {% if is_incremental() %}
    where event_ts > (
        select dateadd('day', -3, max(event_ts)) from {{ this }}
    )
    {% endif %}
Explanition:
        This is a dbt incremental model filter. It is designed to process only a recent portion of the source data instead of rebuilding the entire target table every time.

        Let's break it down piece by piece.

        1. is_incremental()
        {% if is_incremental() %}

        is_incremental() is a dbt function that returns True when dbt is running the model incrementally.

        For example, suppose your model is:

        {{ config(materialized='incremental') }}


        select *
        from {{ source('app', 'events') }}


        {% if is_incremental() %}
            where ...
        {% endif %}

        There are two possible situations.

        First run / full refresh:

        is_incremental() = False

        So dbt effectively executes:

        select *
        from source_table

        All records are processed.

        Subsequent incremental run:

        is_incremental() = True

        So dbt includes the WHERE condition.

        2. {{ this }}
        from {{ this }}

        {{ this }} is a special dbt variable that refers to the current model's target table/view.

        For example, suppose your model is:

        models/marts/fct_events.sql

        and dbt creates:

        analytics.fct_events

        Then:

        {{ this }}

        will resolve approximately to:

        analytics.fct_events

        So:

        select max(event_ts) from {{ this }}

        becomes something like:

        select max(event_ts)
        from analytics.fct_events

        This is very important in incremental models because we want to look at what data has already been loaded.

        3. max(event_ts)
        select max(event_ts)
        from {{ this }}

        Suppose your existing target table contains:

        event_id	event_ts
        1	Aug 15 10:00
        2	Aug 16 12:00
        3	Aug 17 08:00
        4	Aug 18 15:00
        5	Aug 19 18:00

        Then:

        max(event_ts)

        returns:

        Aug 19 18:00

        This tells us:

        "The latest event currently present in my target table is Aug 19 18:00."

        4. dateadd('day', -3, max(event_ts))

        Now we have:

        dateadd('day', -3, max(event_ts))

        This means:

        Take the maximum event_ts and go 3 days backward.

        If:

        max(event_ts) = Aug 19 18:00

        then:

        dateadd('day', -3, max(event_ts))

        becomes approximately:

        Aug 16 18:00

        Why go backward?

        Because real-world data can arrive late.

        For example, suppose your target already contains data up to:

        Aug 19

        But an event that actually happened on:

        Aug 17

        arrives today.

        If you simply used:

        where event_ts > max(event_ts)

        that Aug 17 event would be ignored forever.

        By going back 3 days, you create a lookback window.

        5. The complete WHERE

        Now look at:

        where event_ts > (
            select dateadd('day', -3, max(event_ts)) from {{ this }}
        )

        Suppose:

        max(event_ts) = Aug 19

        Then:

        Aug 19 - 3 days = Aug 16

        So the condition effectively becomes:

        where event_ts > 'Aug 16'

        Therefore dbt processes:

        Aug 17
        Aug 18
        Aug 19
        Aug 20
        ...

        instead of processing the entire source table.

        6. Why the 3-day lookback?

        The -3 is a design choice.

        Imagine your source data looks like this:

        Event occurred       Arrived in warehouse
        ------------------------------------------
        Aug 17               Aug 17
        Aug 18               Aug 18
        Aug 19               Aug 19
        Aug 17               Aug 20  <-- late-arriving data

        If your target's latest timestamp is Aug 19, this condition:

        where event_ts > Aug 16

        will pick up the late-arriving Aug 17 record.

        So the model is saying:

        "I already processed data up to the latest timestamp, but every time I run, go back 3 days and reprocess that window in case late-arriving records have appeared."

        7. What does {% endif %} do?

        Finally:

        {% endif %}

        closes the Jinja if statement.

        So the complete logic is:

        Is this an incremental run?
                |
                +---- NO ----> Process all source records
                |
                +---- YES ---> Find latest event_ts in target
                                |
                                v
                            Go back 3 days
                                |
                                v
                            Process records
                            newer than that
        Putting it all together

        Your code:

        {% if is_incremental() %}
        where event_ts > (
            select dateadd('day', -3, max(event_ts)) from {{ this }}
        )
        {% endif %}

        essentially means:

        "When this dbt model runs incrementally, only process source records whose event_ts is within the last 3 days relative to the latest event_ts already present in the target table. On the first/full-refresh run, don't apply this filter."

        This pattern is commonly called a lookback window or incremental lookback strategy.

        One important thing to understand next is why this can create duplicate records and how unique_key + incremental strategies such as merge solve that problem.

---
Question 4 (medium-hard, scenario):
You're reviewing a teammate's PR. They wrote an ephemeral model called int_cleaned_orders that does a moderately expensive REGEXP_REPLACE and windowing operation, and it's ref()'d by 6 different downstream models in the marts layer. Build times have gotten noticeably slower since this was merged. What's likely happening, and what would you recommend instead?
---
Answer:
By materializing int_cleaned_orders as a table, dbt runs the expensive transformation once, persists the result, and all 6 downstream models simply SELECT from an already-computed table — cheap reads instead of 6x redundant compute. This directly follows the Golden Rule too: it "took too long" (in aggregate, via fan-out) so you escalate from a non-materialized/view-like approach to a table.

---
Question 5 (hardest, scenario-based):
You're designing a fct_orders incremental model on Snowflake, materialized incremental with unique_key='order_id', incremental_strategy='merge'. One day, a teammate adds a new column (discount_amount) to the upstream source and updates the model's SELECT to include it. They run dbt run (not --full-refresh). What happens, why, and what config would you add to handle this gracefully going forward?
---
## Section 2
---
Question 1 (easy):
You add a not_null test to order_id on your fct_orders model. You run dbt test and it fails. In plain terms, what SQL is dbt actually running behind the scenes to determine this test failed, and what would that query's result look like?
---
Question 2 (easy-medium):
Your company gets a fresh CSV export of "valid product categories" (12 rows, changes maybe twice a year) from the merchandising team. A teammate suggests loading this via source() pointing at a table an analyst manually uploads to the warehouse every time it changes. Would you agree with this approach, or suggest something else — and why?
---
Question 3 (medium, scenario):
You've got a relationships test on fct_orders.customer_id pointing to dim_customers.customer_id, with default severity: error. One morning, your CI pipeline fails this test — but after checking, you confirm this is expected and temporary: a batch of new customers signed up via a promo campaign and haven't synced into dim_customers yet due to a known 2-hour lag in that pipeline (not a bug). You need dbt build to stop hard-failing on this every morning without just deleting the test. What would you configure, and what's the trade-off of your choice?
---
Question 4 (medium-hard, scenario):
You're asked in an interview: "How would you test that the sum of line_item_amount in your stg_line_items model always equals order_total in fct_orders, per order?" Which type of test (generic or singular) fits this, and roughly how would you structure the SQL to make it return the correct pass/fail signal?
---
Question 5 (hardest, scenario-based):
You're setting up a new dbt project and need to decide your overall testing strategy for a marts layer with 40 models feeding executive dashboards. Your manager asks: "Should we write a unit test or a data test for validating that our calculate_ltv() macro (a moderately complex SQL formula involving discounts, refunds, and tiered pricing) produces mathematically correct output?" Walk me through your reasoning — which would you pick, why, and what's the key limitation of the one you don't pick?
---
