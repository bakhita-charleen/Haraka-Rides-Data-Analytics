------------------------ Creating fuel_logs table -----------------------

create table fleet.fuel_logs (
fuel_log_id serial primary key,
log_id int,
vehicle_id int references fleet.vehicles(vehicle_id),
event_date date,
liters numeric (10,2),
fuel_cost numeric(10,2),
odometer_reading numeric(10,2),
station_name varchar(100) 
);

------------------------------ Profiling the mess in fuel_logs details ---------------------------------

select log_id, event_date, event_type, liters, fuel_cost,
		odometer_reading, station_name  
from staging_haraka.fleet_staging; 

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
   		end as clean_event_date
from staging_haraka.fleet_staging
where initcap(TRIM(event_type)) = 'Fuel';

---------------------------- Qquality check on event_type column ------------------------------------------------------

select distinct event_type 
from staging_haraka.fleet_staging;

--------------------------------------- Standardizing event_type ---------------------------------------------------

select distinct 
			initcap(TRIM(event_type)) as event_type 
from staging_haraka.fleet_staging;

--------------------------------- Standardizing liters column ----------------------------------------------------

select liters,
		case
			when liters = '' then null 
			else cast(liters as numeric(10,2)) 
		end as liters
from staging_haraka.fleet_staging
where initcap(TRIM(event_type)) = 'Fuel';

--------------------------------- Standardizing fuel_cost column ----------------------------------------------------

select 
		cast(
		regexp_replace(fuel_cost , '[^0-9.]','','g') as numeric (10,2)
		) as fuel_cost
from staging_haraka.fleet_staging 
where initcap(TRIM(event_type)) = 'Fuel';

--------------------------------- Standardizing odometer_reading column ----------------------------------------------------

select 
		case 
			when odometer_reading = '' then null
			else cast(odometer_reading as numeric(10,2))
		end	as odometer_reading
from staging_haraka.fleet_staging 
where initcap(TRIM(event_type)) = 'Fuel';

--------------------------------- Standardizing station_name column ----------------------------------------------------

select distinct 
			initcap(TRIM(station_name))
from staging_haraka.fleet_staging 
where initcap(TRIM(event_type)) = 'Fuel';

------------------------------------- Compiled Select Query ----------------------------------------------------------------

select  
		----------- Event_date
		case 
			when event_date ~ '^\d{4}-\d{2}-\d{2}$' then TO_DATE(event_date, 'YYYY-MM-DD')
       		when event_date ~ '^\d{2}/\d{2}/\d{4}$' then TO_DATE(event_date, 'DD/MM/YYYY')
        	when event_date ~ '^\d{2}/\d{2}/\d{2}$' then TO_DATE(event_date, 'DD/MM/YY')
        	when event_date ~ '^\d{2}-\d{2}-\d{4}$' then TO_DATE(event_date, 'MM-DD-YYYY')
   		end as event_date,
   		----------- Liters
   		case
			when liters = '' then null 
			else cast(liters as numeric(10,2)) 
		end as liters,
		----------- fuel_cost
		cast(
		regexp_replace(fuel_cost , '[^0-9.]','','g') as numeric (10,2)
		) as fuel_cost,
		----------- odometer_reading
		case 
			when odometer_reading = '' then null
			else cast(odometer_reading as numeric(10,2))
		end	as odometer_reading,
		----------- station_name
		initcap(TRIM(station_name))	as station_name
from staging_haraka.fleet_staging 
where initcap(TRIM(event_type)) = 'Fuel';

------------------------------------- Final Select Query ----------------------------------------------------------------

select  
		f.log_id,
		v.vehicle_id,
		----------- Event_date
		case 
			when f.event_date ~ '^\d{4}-\d{2}-\d{2}$' then TO_DATE(f.event_date, 'YYYY-MM-DD')
       		when f.event_date ~ '^\d{2}/\d{2}/\d{4}$' then TO_DATE(f.event_date, 'DD/MM/YYYY')
        	when f.event_date ~ '^\d{2}/\d{2}/\d{2}$' then TO_DATE(f.event_date, 'DD/MM/YY')
        	when f.event_date ~ '^\d{2}-\d{2}-\d{4}$' then TO_DATE(f.event_date, 'MM-DD-YYYY')
   		end as event_date,
   		----------- Liters
   		case
			when f.liters = '' then null 
			else cast(f.liters as numeric(10,2)) 
		end as liters,
		----------- fuel_cost
		cast(
		regexp_replace(f.fuel_cost , '[^0-9.]','','g') as numeric (10,2)
		) as fuel_cost,
		----------- odometer_reading
		case 
			when f.odometer_reading = '' then null
			else cast(f.odometer_reading as numeric(10,2))
		end	as odometer_reading,
		----------- station_name
		initcap(TRIM(f.station_name))	as station_name
from staging_haraka.fleet_staging f
left join fleet.vehicles v on UPPER(TRIM(f.vehicle_plate)) = v.vehicle_plate 
where initcap(TRIM(f.event_type)) = 'Fuel';

-------------------------- Checking if log_id has any duplicates

SELECT log_id, COUNT(*)
FROM staging_haraka.fleet_staging 
where initcap(TRIM(event_type)) = 'Fuel'
GROUP BY log_id
HAVING COUNT(*) > 1; ------Has 4 duplicates

-------------------------------------------------- Inserting data into fleet.fuel_logs -------------------------------------------

insert into fleet.fuel_logs(log_id, vehicle_id, event_date, liters, fuel_cost, odometer_reading, station_name)
select  distinct
		cast(f.log_id as int) as log_id,
		v.vehicle_id,
		----------- Event_date
		case 
			when f.event_date ~ '^\d{4}-\d{2}-\d{2}$' then TO_DATE(f.event_date, 'YYYY-MM-DD')
       		when f.event_date ~ '^\d{2}/\d{2}/\d{4}$' then TO_DATE(f.event_date, 'DD/MM/YYYY')
        	when f.event_date ~ '^\d{2}/\d{2}/\d{2}$' then TO_DATE(f.event_date, 'DD/MM/YY')
        	when f.event_date ~ '^\d{2}-\d{2}-\d{4}$' then TO_DATE(f.event_date, 'MM-DD-YYYY')
   		end as event_date,
   		----------- Liters
   		case
			when f.liters = '' then null 
			else cast(f.liters as numeric(10,2)) 
		end as liters,
		----------- fuel_cost
		cast(
		regexp_replace(f.fuel_cost , '[^0-9.]','','g') as numeric (10,2)
		) as fuel_cost,
		----------- odometer_reading
		case 
			when f.odometer_reading = '' then null
			else cast(f.odometer_reading as numeric(10,2))
		end	as odometer_reading,
		----------- station_name
		initcap(TRIM(f.station_name))	as station_name
from staging_haraka.fleet_staging f
left join fleet.vehicles v on UPPER(TRIM(f.vehicle_plate)) = v.vehicle_plate 
where initcap(TRIM(f.event_type)) = 'Fuel';

-------------------------------------------------- SANITY CHECK FOR FUEL_LOGS TABLE
select *
from fleet.fuel_logs;