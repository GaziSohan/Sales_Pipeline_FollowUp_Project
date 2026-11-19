select opportunity_id
from {{ ref('fct_sales_pipeline_health') }}
where is_stale and not is_eligible