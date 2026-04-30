
    
    

with all_values as (

    select
        payment_type as value_field,
        count(*) as n_records

    from "nyc_taxi"."main_staging"."stg_yellow_taxi_trips"
    group by payment_type

)

select *
from all_values
where value_field not in (
    '1','2','3','4','5','6'
)


