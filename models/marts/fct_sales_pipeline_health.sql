with opportunities as (
    select *
    from {{ ref('stg_crm_opportunities') }}
),

sales_people as (
    select *
    from {{ ref('stg_sales_people') }}
),

latest_stage as (
    select *
    from {{ ref('int_opportunity_latest_stage') }}
),

task_summary as (
    select *
    from {{ ref('int_opportunity_task_summary') }}
),

joined as (
    select
        opp.opportunity_id,
        opp.opportunity_name,
        opp.owner_id,
        sp.employee_name as owner_name,
        sp.employee_role as owner_role,
        coalesce(sp.is_active, false) as owner_is_active,
        sp.team_lead,
        opp.is_test_record,
        opp.amount,
        opp.opportunity_created_at,
        ls.latest_stage_name,
        ls.latest_stage_changed_at,
        case
            when ls.latest_stage_name in ('New','Qualified','Proposal','Negotiation') then 'active'
            when ls.latest_stage_name = 'On Hold' then 'on_hold'
            when ls.latest_stage_name = 'Closed Won' then 'won'
            when ls.latest_stage_name = 'Closed Lost' then 'lost'
            else 'unknown'
        end as pipeline_category,
        datediff('day', ls.latest_stage_changed_at::date, '{{ var("reporting_date") }}'::date) as days_in_current_stage,
        coalesce(ts.task_count, 0) as task_count,
        coalesce(ts.open_task_count, 0) as open_task_count,
        coalesce(ts.overdue_task_count, 0) as overdue_task_count,
        ts.latest_task_activity_at,
        datediff('day', ts.latest_task_activity_at::date, '{{ var("reporting_date") }}'::date) as days_since_last_task_activity
    from opportunities opp
    left join sales_people sp on opp.owner_id = sp.employee_id
    left join latest_stage ls on opp.opportunity_id = ls.opportunity_id
    left join task_summary ts on opp.opportunity_id = ts.opportunity_id
),

eligibility as (
    select 
        *,
        case
            when (
                is_test_record = false
                and owner_is_active = true
                and owner_role in ('Sales Representative', 'Sales Manager')
                and pipeline_category = 'active'
            ) then true
            else false
        end as is_eligible
    from joined
),

flags as (
    select 
        *,
        case when (
            is_eligible = true
            and days_in_current_stage > 14
            ) then true
            else false
        end as is_stale,
        case when days_since_last_task_activity <= 14 then true else false
        end as has_recent_follow_up
    from eligibility
),

follow_up as (
    select 
        *,
        case 
            when (
                is_eligible = true
                and (
                    is_stale = true
                    or overdue_task_count > 0
                    or has_recent_follow_up = false
                )
            ) then true 
            else false
        end as requires_follow_up
    from flags
),

final as (
    select
        *,
        case
            when requires_follow_up then
                array_to_string(
                    array_construct_compact(
                        case when is_stale then 'Stale stage' end,
                        case when overdue_task_count > 0 then 'Overdue tasks' end,
                        case when not has_recent_follow_up then 'No recent follow-up' end
                    ),
                    ', '
                )
        end as follow_up_reason
    from follow_up
)

select * from final