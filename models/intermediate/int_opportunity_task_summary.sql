with tasks as (
    select *
    from {{ ref('stg_crm_tasks') }}
    where opportunity_id is not null
),

summary as (
    select 
        opportunity_id,
        count(*) as task_count,
        count(case when task_status != 'Completed' then 1 else NULL end) as open_task_count,
        count_if(
            task_status != 'Completed'
            and due_date is not null
            and due_date < '{{ var("reporting_date") }}'::date
        ) as overdue_task_count,
        max(task_completed_at) as latest_task_completed_at,
        max(task_created_at) as latest_task_created_at,
        coalesce(max(task_completed_at),max(task_created_at)) as latest_task_activity_at
    from tasks
    group by opportunity_id
)

select * from summary