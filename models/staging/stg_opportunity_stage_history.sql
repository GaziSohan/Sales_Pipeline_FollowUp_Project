with source as (
    select *
    from {{ ref('src_opportunity_stage_history') }}
),

renamed as (
    select
        stage_event_id, 
        opportunity_id, 
        stage_name, 
        changed_at as stage_changed_at
    from source
)

select * from renamed