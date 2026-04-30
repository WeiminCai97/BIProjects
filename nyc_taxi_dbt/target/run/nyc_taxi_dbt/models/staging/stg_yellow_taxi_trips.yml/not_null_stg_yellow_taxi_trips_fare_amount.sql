
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select fare_amount
from "nyc_taxi"."main_staging"."stg_yellow_taxi_trips"
where fare_amount is null



  
  
      
    ) dbt_internal_test