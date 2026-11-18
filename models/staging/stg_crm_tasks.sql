with source as (
    select *
    from {{ ref('src_crm_tasks') }}
),

renamed as (
    select
        task_id, 
        opportunity_id, 
        task_status, 
        created_at as task_created_at, 
        due_date, 
        completed_at as task_completed_at
    from source
)

select * from renamed