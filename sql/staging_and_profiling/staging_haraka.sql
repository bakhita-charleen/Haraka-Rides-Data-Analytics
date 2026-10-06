create schema staging_haraka;


--------------------------------------------- Staging table for trips -------------------------------------------------------------

CREATE TABLE staging_haraka.trips_staging (
	trip_id text,
	customer_name text,
	customer_phone text,
	customer_area text,
	driver_name text,
	driver_phone text,
	vehicle_plate text,
	vehicle_make text,
	vehicle_model text,
	pickup_area text,
	dropoff_area text,
	trip_date text,
	pickup_time text,
	distance_km text,
	payment_method text,
	status text,
	fare_amount text,
	customer_rating text
);

----------------------------------- SANITY CHECK: Counting no of entries in the trips table =-------------------------------------

select count(*)
from staging_haraka.trips_staging;

--------------------------------------------- Staging table for fleet ------------------------------------------------------------

CREATE TABLE staging_haraka.fleet_staging (
	log_id text,
	vehicle_plate text,
	vehicle_make text,
	vehicle_model text,
	vehicle_year text,
	vehicle_type text,
	vehicle_status text,
	event_type text,
	event_date text,
	liters text,
	fuel_cost text,
	odometer_reading text,
	station_name text,
	service_type text,
	maintenance_cost text,
	mechanic_name text,
	next_service_due text
);

-------------------------------- SANITY CHECK: Counting no of entries in the fleet table------------------------------------------

select count(*)
from staging_haraka.fleet_staging;

-------------------------------- Checking distinct customer name in the trips staging ---------------------------------------------
select distinct customer_name
from staging_haraka.trips_staging;

-------------------------------- Checking distinct status type in the trips staging -----------------------------------------------
select distinct status 
from staging_haraka.trips_staging;
--
---------------------------------------- Identifying the frequency of each status type---------------------------------------------
select
    status,
    count(*) as frequency
from staging_haraka.trips_staging
group by status
order by frequency desc;

------------------------------------------ Identifying the frequency of each customer area------------------------------------------
select
    customer_area,
    count(*) as frequency
from staging_haraka.trips_staging
group by customer_area 
order by frequency desc;

-- -------------------------------------Identifying the frequency of each payment method--------------------------------------------
select
    payment_method,
    count(*) as frequency
from staging_haraka.trips_staging
group by payment_method  
order by frequency desc;

-- ------------------------------------- Identifying the frequency of each vehicle plate --------------------------------------------
select
    vehicle_plate, 
    count (*) as frequency
from staging_haraka.trips_staging
group by vehicle_plate 
order by frequency desc;

---------------------------------------------- Checking distinct phone_numbers in the trips staging table-----------------------------
select distinct customer_phone 
from staging_haraka.trips_staging
limit 20;

---------------------------------------------- Checking distinct date types in the trips staging table---------------------------------
select distinct trip_date 
from staging_haraka.trips_staging
limit 20;

------------------------------------------- Checking distinct pickup_time in the trips staging table -----------------------------------
select distinct pickup_time 
from staging_haraka.trips_staging
limit 20;

-------------------------------------------- Checking distinct currency in the trips staging table --------------------------------------
select distinct fare_amount  
from staging_haraka.trips_staging
limit 20;

-------------------------------------------- Checking for nulls in the column customer_phone  --------------------------------------------
select count(*)
from staging_haraka.trips_staging 
where customer_phone is null;

-------------------------------------------- Checking for blanks --------------------------------------------=============================
select count (*)
from staging_haraka.trips_staging 
where trim (customer_phone)='';

---------------------------------------------- Distinct plates in trips staging ----------------------------------------------------------
select distinct vehicle_plate, count (*) as frequency
from staging_haraka.trips_staging 
group by vehicle_plate
order by frequency desc;

------------------------------------------------------------ Distinct plates in fleet staging----------------------------------------------
select distinct vehicle_plate, count (*) as frequency
from staging_haraka.fleet_staging
group by vehicle_plate
order by frequency desc;

------------------------------------------------------ Checking if there is negative distance values --------------------------------------
select *
from staging_haraka.trips_staging
where distance_km LIKE '-%';

------------------------------------------------ Checking if there is rating outside of 1-5 ------------------------------------------------
select *
from staging_haraka.trips_staging
where customer_rating not in ('1','2','3','4','5');

select *,
    COUNT(*) AS duplicate_count
FROM staging_haraka.trips_staging
GROUP BY
    trip_id,
    customer_name,
    customer_phone,
    customer_area,
    driver_name,
    driver_phone,
    vehicle_plate,
    vehicle_make,
    vehicle_model,
    pickup_area,
    dropoff_area,
    trip_date,
    pickup_time,
    distance_km,
    payment_method,
    status,
    fare_amount,
    customer_rating
HAVING COUNT(*) > 1;

------------------------------------------------ Counting distinct rows to identify the duplicate count ----------------------------
select count (*) as distinct_rows
from (
    select distinct *
    from staging_haraka.trips_staging
)as t;

---------------------------------------------- Checking for nulls in column vehicle_year ----------------------------
select vehicle_year
from staging_haraka.fleet_staging 
where vehicle_year is null ;

--------------------------------------- Checking for blanks and nulls in column customer_name ----------------------------------------------
select customer_name
from staging_haraka.trips_staging 
where customer_name is null 
or TRIM(customer_name) = '' ;

------------------------------------------------ Checking for blanks and nulls in column customer_area -------------------------------------
select *
from staging_haraka.trips_staging 
where customer_area is null 
or TRIM(customer_area) = '' ;

------------------------------------------------ Checking blank phone numbers --------------------------------------------------------------
select *
from staging_haraka.trips_staging
where trim(customer_phone) = '';

select *
from staging_haraka.trips_staging 
limit 20;

select count(*)
from staging_haraka.trips_staging;

select *
from staging_haraka.fleet_staging;
limit 40;


