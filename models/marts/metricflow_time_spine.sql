{{ config(materialized='table') }}

with days as (
    {{ dbt.date_spine('day', "to_date('2026-01-01')", "to_date('2027-01-01')") }}
)

select cast(date_day as date) as date_day
from days