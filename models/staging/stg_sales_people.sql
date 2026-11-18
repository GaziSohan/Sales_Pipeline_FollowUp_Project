with source as (
    select *
    from {{ ref('src_sales_people') }}
),

renamed as (
    select
        employee_id, 
        employee_name, 
        role as employee_role, 
        team_lead, 
        is_active
    from source
)

select * from renamed