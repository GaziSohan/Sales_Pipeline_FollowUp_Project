select opportunity_id
from {{ ref('fct_sales_pipeline_health') }}
where (requires_follow_up and follow_up_reason is null)
   or (not requires_follow_up and follow_up_reason is not null)