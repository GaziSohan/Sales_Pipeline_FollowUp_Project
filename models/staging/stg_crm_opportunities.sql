with source as (
    select *
    from {{ref('src_crm_opportunities')}}
),

renamed as (
    select
        opportunity_id, 
        opportunity_name, 
        owner_id, 
        amount, 
        created_at as opportunity_created_at, 
        is_test_record
    from source
)

select * from renamed
