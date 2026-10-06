-------------------------------------------- Creating maintenance_logs table ----------------------------------------------------

create table fleet.maintenance_logs ( 
maintenance_log_id serial primary key,
log_id int,
vehicle_id int references fleet.vehicles(vehicle_id),
event_date date,
service_type varchar(100),
maintenance_cost numeric (10,2),
mechanic_name varchar(100),
next_service_due date
);

------------------------------ Profiling the mess in maintenance_logs details ---------------------------------

select log_id, event_date, event_type, service_type,
		maintenance_cost, mechanic_name , next_service_due 
from staging_haraka.fleet_staging
where initcap(TRIM(event_type)) = 'Maintenance' ;

---------------------- Standardizing the event_date column ------------------------

select event_date,
		case 
			 -- Standard ISO format: 2025-05-09
			when event_date ~ '^\d{4}-\d{2}-\d{2}$' then TO_DATE(event_date, 'YYYY-MM-DD')
        -- Slashed format with 4-digit year (UK style): 19/05/2025
       		when event_date ~ '^\d{2}/\d{2}/\d{4}$' then TO_DATE(event_date, 'DD/MM/YYYY')
        -- Slashed format with 2-digit year (UK style): 02/02/25
        	when event_date ~ '^\d{2}/\d{2}/\d{2}$' then TO_DATE(event_date, 'DD/MM/YY')
        -- Hyphenated format with 4-digit year (US style): 06-25-2025
        	when event_date ~ '^\d{2}-\d{2}-\d{4}$' then TO_DATE(event_date, 'MM-DD-YYYY')
   		end as event_date
from staging_haraka.fleet_staging
where initcap(TRIM(event_type)) = 'Maintenance';

---------------------- Standardizing the service_type column ------------------------

select 
		initcap(TRIM(service_type)) as service_type
from staging_haraka.fleet_staging
where initcap(TRIM(event_type)) = 'Maintenance' ;

---------------------- Standardizing the maintenance_cost column ------------------------

select 
		cast(
		regexp_replace(maintenance_cost , '[^0-9.]','','g') as numeric (10,2)
		) as maintenance_cost
from staging_haraka.fleet_staging 
where initcap(TRIM(event_type)) = 'Maintenance';

---------------------- Standardizing the mechanic_name column ------------------------

select 
		initcap(TRIM(mechanic_name)) as mechanic_name
from staging_haraka.fleet_staging
where initcap(TRIM(event_type)) = 'Maintenance' ;

---------------------- Standardizing the next_service_due column ------------------------

select next_service_due,
		case 
			 -- Standard ISO format: 2025-05-09
			when next_service_due ~ '^\d{4}-\d{2}-\d{2}$' then TO_DATE(next_service_due, 'YYYY-MM-DD')
        -- Slashed format with 4-digit year (UK style): 19/05/2025
       		when next_service_due ~ '^\d{2}/\d{2}/\d{4}$' then TO_DATE(next_service_due, 'DD/MM/YYYY')
        -- Slashed format with 2-digit year (UK style): 02/02/25
        	when next_service_due ~ '^\d{2}/\d{2}/\d{2}$' then TO_DATE(next_service_due, 'DD/MM/YY')
        -- Hyphenated format with 4-digit year (US style): 06-25-2025
        	when next_service_due ~ '^\d{2}-\d{2}-\d{4}$' then TO_DATE(next_service_due, 'MM-DD-YYYY')
   		end as next_service_due
from staging_haraka.fleet_staging
where initcap(TRIM(event_type)) = 'Maintenance' ;

------------------------------------- Compiled Select Query ----------------------------------------------------------------

select
		case 
			when event_date ~ '^\d{4}-\d{2}-\d{2}$' then TO_DATE(event_date, 'YYYY-MM-DD')
       		when event_date ~ '^\d{2}/\d{2}/\d{4}$' then TO_DATE(event_date, 'DD/MM/YYYY')
        	when event_date ~ '^\d{2}/\d{2}/\d{2}$' then TO_DATE(event_date, 'DD/MM/YY')
        	when event_date ~ '^\d{2}-\d{2}-\d{4}$' then TO_DATE(event_date, 'MM-DD-YYYY')
   		end as event_date,
   		initcap(TRIM(service_type)) as service_type,
   		cast(
		regexp_replace(maintenance_cost , '[^0-9.]','','g') as numeric (10,2)
		) as maintenance_cost,
		initcap(TRIM(mechanic_name)) as mechanic_name,
		case 
			when next_service_due ~ '^\d{4}-\d{2}-\d{2}$' then TO_DATE(next_service_due, 'YYYY-MM-DD')
       		when next_service_due ~ '^\d{2}/\d{2}/\d{4}$' then TO_DATE(next_service_due, 'DD/MM/YYYY')
        	when next_service_due ~ '^\d{2}/\d{2}/\d{2}$' then TO_DATE(next_service_due, 'DD/MM/YY')
        	when next_service_due ~ '^\d{2}-\d{2}-\d{4}$' then TO_DATE(next_service_due, 'MM-DD-YYYY')
   		end as next_service_due
from staging_haraka.fleet_staging
where initcap(TRIM(event_type)) = 'Maintenance';

-------------------------- Checking if log_id has any duplicates ------------------------

SELECT log_id, COUNT(*)
FROM staging_haraka.fleet_staging 
where initcap(TRIM(event_type)) = 'Maintenance'
GROUP BY log_id
HAVING COUNT(*) > 1;

--------------------------------------- Final Select Query ----------------------------------------------------------------

select
		cast(f.log_id as int) as log_id,
		v.vehicle_id,
		case 
			when f.event_date ~ '^\d{4}-\d{2}-\d{2}$' then TO_DATE(f.event_date, 'YYYY-MM-DD')
       		when f.event_date ~ '^\d{2}/\d{2}/\d{4}$' then TO_DATE(f.event_date, 'DD/MM/YYYY')
        	when f.event_date ~ '^\d{2}/\d{2}/\d{2}$' then TO_DATE(f.event_date, 'DD/MM/YY')
        	when f.event_date ~ '^\d{2}-\d{2}-\d{4}$' then TO_DATE(f.event_date, 'MM-DD-YYYY')
   		end as event_date,
   		initcap(TRIM(f.service_type)) as service_type,
   		cast(
		regexp_replace(f.maintenance_cost , '[^0-9.]','','g') as numeric (10,2)
		) as maintenance_cost,
		initcap(TRIM(f.mechanic_name)) as mechanic_name,
		case 
			when f.next_service_due ~ '^\d{4}-\d{2}-\d{2}$' then TO_DATE(f.next_service_due, 'YYYY-MM-DD')
       		when f.next_service_due ~ '^\d{2}/\d{2}/\d{4}$' then TO_DATE(f.next_service_due, 'DD/MM/YYYY')
        	when f.next_service_due ~ '^\d{2}/\d{2}/\d{2}$' then TO_DATE(f.next_service_due, 'DD/MM/YY')
        	when f.next_service_due ~ '^\d{2}-\d{2}-\d{4}$' then TO_DATE(f.next_service_due, 'MM-DD-YYYY')
   		end as next_service_due
from staging_haraka.fleet_staging f
left join fleet.vehicles v on UPPER(TRIM(f.vehicle_plate)) = v.vehicle_plate 
where initcap(TRIM(f.event_type)) = 'Maintenance';

--------------------------------------- Insert details to fleet.maintenance_logs -----------------------------------------

insert into fleet.maintenance_logs(log_id,vehicle_id, event_date, service_type, maintenance_cost, mechanic_name, next_service_due)
select
		cast(f.log_id as int) as log_id,
		v.vehicle_id,
		case 
			when f.event_date ~ '^\d{4}-\d{2}-\d{2}$' then TO_DATE(f.event_date, 'YYYY-MM-DD')
       		when f.event_date ~ '^\d{2}/\d{2}/\d{4}$' then TO_DATE(f.event_date, 'DD/MM/YYYY')
        	when f.event_date ~ '^\d{2}/\d{2}/\d{2}$' then TO_DATE(f.event_date, 'DD/MM/YY')
        	when f.event_date ~ '^\d{2}-\d{2}-\d{4}$' then TO_DATE(f.event_date, 'MM-DD-YYYY')
   		end as event_date,
   		initcap(TRIM(f.service_type)) as service_type,
   		cast(
		regexp_replace(f.maintenance_cost , '[^0-9.]','','g') as numeric (10,2)
		) as maintenance_cost,
		initcap(TRIM(f.mechanic_name)) as mechanic_name,
		case 
			when f.next_service_due ~ '^\d{4}-\d{2}-\d{2}$' then TO_DATE(f.next_service_due, 'YYYY-MM-DD')
       		when f.next_service_due ~ '^\d{2}/\d{2}/\d{4}$' then TO_DATE(f.next_service_due, 'DD/MM/YYYY')
        	when f.next_service_due ~ '^\d{2}/\d{2}/\d{2}$' then TO_DATE(f.next_service_due, 'DD/MM/YY')
        	when f.next_service_due ~ '^\d{2}-\d{2}-\d{4}$' then TO_DATE(f.next_service_due, 'MM-DD-YYYY')
   		end as next_service_due
from staging_haraka.fleet_staging f
left join fleet.vehicles v on UPPER(TRIM(f.vehicle_plate)) = v.vehicle_plate 
where initcap(TRIM(f.event_type)) = 'Maintenance';

-------------------------------------------------- SANITY CHECK FOR maintenance_LOGS TABLE
select *
from fleet.maintenance_logs;
