with ranked as (
    select
    *,
    row_number() over(partition by opportunity_id order by stage_changed_at desc, stage_event_id desc) as opp_stage_rank
    from {{ ref('stg_opportunity_stage_history') }}
)

select
    opportunity_id,
    stage_name as latest_stage_name,
    stage_changed_at as latest_stage_changed_at
from ranked
where opp_stage_rank = 1