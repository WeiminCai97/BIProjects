
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select dropoff_at
from "nyc_taxi"."main_staging"."stg_yellow_taxi_trips"
where dropoff_at is null



  
  
      
    ) dbt_internal_test