----------------------------------- Creating table for trip details ----------------------------
create table booking.trips (
    trip_id int Primary Key,
    customer_id int references booking.customers(customer_id),
    driver_id int references booking.drivers(driver_id),
    vehicle_id int references fleet.vehicles(vehicle_id),
    pickup_area varchar(100),
    dropoff_area varchar(100),
    trip_date date,
    pickup_time time,
    distance_km numeric(10,2),
    payment_method varchar(50),
    status varchar(50),
    fare_amount numeric(10,2),
    customer_rating int
);

-------------------------- Profiling the mess connected to trips table

select 
		trip_id, pickup_area, dropoff_area,trip_date, pickup_time, distance_km, 
		payment_method, status, fare_amount, customer_rating      
from staging_haraka.trips_staging;

--------------------------  Standardizing the pickup area and dropoff area

select
		case 
			when initcap(TRIM(pickup_area)) = 'Kasarrani' then 'Kasarani'
			when initcap(TRIM(pickup_area)) = 'Karren' then 'Karen'
			when initcap(TRIM(pickup_area)) = 'Kilimmani' then 'Kilimani'
			when initcap(TRIM(pickup_area)) = 'Burubburu' then 'Buruburu'
			when initcap(TRIM(pickup_area)) = 'Embakkasi' then 'Embakasi'
			when initcap(TRIM(pickup_area)) = 'Runnda' then 'Runda'
			when initcap(TRIM(pickup_area)) = 'Lavinngton' then 'Lavington'
			when initcap(TRIM(pickup_area)) = 'Langgata' then 'Langata'
			when initcap(TRIM(pickup_area)) = 'Westllands' then 'Westlands'
			when initcap(TRIM(pickup_area)) = 'Cbbd' then 'CBD'
			when initcap(TRIM(pickup_area)) = 'Cbd' then 'CBD'
			when initcap(TRIM(pickup_area)) = 'Parkllands' then 'Parklands'
			when initcap(TRIM(pickup_area)) = 'Soutth B' then 'South B'
			when initcap(TRIM(pickup_area)) = 'Soutth C' then 'South C'
			else initcap(trim(pickup_area))
		end as clean_pickuparea,
		case 
			when initcap(TRIM(dropoff_area)) = 'Kasarrani' then 'Kasarani'
			when initcap(TRIM(dropoff_area)) = 'Karren' then 'Karen'
			when initcap(TRIM(dropoff_area)) = 'Kilimmani' then 'Kilimani'
			when initcap(TRIM(dropoff_area)) = 'Burubburu' then 'Buruburu'
			when initcap(TRIM(dropoff_area)) = 'Embakkasi' then 'Embakasi'
			when initcap(TRIM(dropoff_area)) = 'Runnda' then 'Runda'
			when initcap(TRIM(dropoff_area)) = 'Lavinngton' then 'Lavington'
			when initcap(TRIM(dropoff_area)) = 'Langgata' then 'Langata'
			when initcap(TRIM(dropoff_area)) = 'Westllands' then 'Westlands'
			when initcap(TRIM(dropoff_area)) = 'Cbbd' then 'CBD'
			when initcap(TRIM(dropoff_area)) = 'Cbd' then 'CBD'
			when initcap(TRIM(dropoff_area)) = 'Parkllands' then 'Parklands'
			when initcap(TRIM(dropoff_area)) = 'Soutth B' then 'South B'
			when initcap(TRIM(dropoff_area)) = 'Soutth C' then 'South C'
			else initcap(trim(dropoff_area))
		end as clean_dropoffarea
from staging_haraka.trips_staging; 

------------------- Quality check for payment_method and status ---------------------------------

-------------------------- Profiling the mess in payment methods

select distinct payment_method 
from staging_haraka.trips_staging;

-------------------------- Profiling the mess in status

select distinct status 
from staging_haraka.trips_staging;

----------------------- Standardizing payment_method and status ------------------------------------

select
		case 
			when initcap(TRIM(payment_method)) = 'Mpesa' then 'M-Pesa'
			else initcap(TRIM(payment_method))
		end as payment_method,
		case 
			when initcap(TRIM(status)) = 'Complete' then 'Completed'
			when initcap(TRIM(status)) = 'No-Show' then 'No Show'
			else initcap(TRIM(status))
		end as status
from staging_haraka.trips_staging;

-------------------------- Quality check for trip_date and pickup time

-------------------------- Profiling the mess in trip_date

select trip_date, pickup_time  
from staging_haraka.trips_staging;

-------------------------- Standardizing trip date and time	
	
select
    -- 1. STANDARDIZE THE TRIP DATE
    case
        -- Standard ISO format: 2025-05-09
        when trip_date ~ '^\d{4}-\d{2}-\d{2}$' then TO_DATE(trip_date, 'YYYY-MM-DD')
        -- Slashed format with 4-digit year (UK style): 19/05/2025
        when trip_date ~ '^\d{2}/\d{2}/\d{4}$' then TO_DATE(trip_date, 'DD/MM/YYYY')
        -- Slashed format with 2-digit year (UK style): 02/02/25
        when trip_date ~ '^\d{2}/\d{2}/\d{2}$' then TO_DATE(trip_date, 'DD/MM/YY')
        -- Hyphenated format with 4-digit year (US style): 06-25-2025
        when trip_date ~ '^\d{2}-\d{2}-\d{4}$' then TO_DATE(trip_date, 'MM-DD-YYYY')
    end as clean_trip_date,
    -- 2. STANDARDIZE THE PICKUP TIME
    -- Safely converts "17:39" text format into a clean TIME data type
    CAST(pickup_time AS TIME) as clean_pickup_time
from staging_haraka.trips_staging;


----------------------------  Quality check for distance, fare_amount nad customer rating

select distance_km, fare_amount, customer_rating  
from staging_haraka.trips_staging;

-------------------------- Standardizing distance_km : Option 1
select 
		case 
			when distance_km = '' then null 
			else abs(cast(distance_km as numeric(10,2)))
		end as distance_km
from staging_haraka.trips_staging;

-- Standardizing distance_km : Option 2
select abs(cast(nullif(distance_km,'') as numeric)) as clean_distance
from staging_haraka.trips_staging;
		
--------------------------Standardizing fare_amount

select 
		cast(
		regexp_replace(fare_amount, '[^0-9.]','','g') as numeric (10,2)
		) as fare_amount
from staging_haraka.trips_staging;

-------------------------- Profiling customer_rating

-------------------------- Checking where customer_rating is greater than 5

select *
from staging_haraka.trips_staging
where customer_rating = '6';

-------------------------- Standardizing customer_rating

select
    case
        when customer_rating = '' then null 
        when cast(customer_rating as int) not between 1 and 5 then null
        else cast(customer_rating as int)
    end as customer_rating
from staging_haraka.trips_staging;

-- Option 2
select case 
	when cast(nullif(customer_rating,'') as int) not in (1,2,3,4,5) then null
	else cast(nullif(customer_rating,'')as int)
	end as clean_rating
from staging_haraka.trips_staging;

-------------------------- Checking if trip_id has any duplicates

SELECT trip_id, COUNT(*)
FROM staging_haraka.trips_staging
GROUP BY trip_id
HAVING COUNT(*) > 1;

-------------------------- Confirming entries are exactly the same

select *
from staging_haraka.trips_staging 
where trip_id = '46';

-------------------------- Final select query for trip details -----------------------------------

select distinct 
		cast(trip_id as int),
		case 
			when initcap(TRIM(pickup_area)) = 'Kasarrani' then 'Kasarani'
			when initcap(TRIM(pickup_area)) = 'Karren' then 'Karen'
			when initcap(TRIM(pickup_area)) = 'Kilimmani' then 'Kilimani'
			when initcap(TRIM(pickup_area)) = 'Burubburu' then 'Buruburu'
			when initcap(TRIM(pickup_area)) = 'Embakkasi' then 'Embakasi'
			when initcap(TRIM(pickup_area)) = 'Runnda' then 'Runda'
			when initcap(TRIM(pickup_area)) = 'Lavinngton' then 'Lavington'
			when initcap(TRIM(pickup_area)) = 'Langgata' then 'Langata'
			when initcap(TRIM(pickup_area)) = 'Westllands' then 'Westlands'
			when initcap(TRIM(pickup_area)) = 'Cbbd' then 'CBD'
			when initcap(TRIM(pickup_area)) = 'Cbd' then 'CBD'
			when initcap(TRIM(pickup_area)) = 'Parkllands' then 'Parklands'
			when initcap(TRIM(pickup_area)) = 'Soutth B' then 'South B'
			when initcap(TRIM(pickup_area)) = 'Soutth C' then 'South C'
			else initcap(trim(pickup_area))
		end as pickup_area,
		case 
			when initcap(TRIM(dropoff_area)) = 'Kasarrani' then 'Kasarani'
			when initcap(TRIM(dropoff_area)) = 'Karren' then 'Karen'
			when initcap(TRIM(dropoff_area)) = 'Kilimmani' then 'Kilimani'
			when initcap(TRIM(dropoff_area)) = 'Burubburu' then 'Buruburu'
			when initcap(TRIM(dropoff_area)) = 'Embakkasi' then 'Embakasi'
			when initcap(TRIM(dropoff_area)) = 'Runnda' then 'Runda'
			when initcap(TRIM(dropoff_area)) = 'Lavinngton' then 'Lavington'
			when initcap(TRIM(dropoff_area)) = 'Langgata' then 'Langata'
			when initcap(TRIM(dropoff_area)) = 'Westllands' then 'Westlands'
			when initcap(TRIM(dropoff_area)) = 'Cbbd' then 'CBD'
			when initcap(TRIM(dropoff_area)) = 'Cbd' then 'CBD'
			when initcap(TRIM(dropoff_area)) = 'Parkllands' then 'Parklands'
			when initcap(TRIM(dropoff_area)) = 'Soutth B' then 'South B'
			when initcap(TRIM(dropoff_area)) = 'Soutth C' then 'South C'
			else initcap(trim(dropoff_area))
		end as dropoff_area,
		-- 1. STANDARDIZE THE TRIP DATE
    	case
        -- Standard ISO format: 2025-05-09
       		 when trip_date ~ '^\d{4}-\d{2}-\d{2}$' then TO_DATE(trip_date, 'YYYY-MM-DD')
        -- Slashed format with 4-digit year (UK style): 19/05/2025
      		 when trip_date ~ '^\d{2}/\d{2}/\d{4}$' then TO_DATE(trip_date, 'DD/MM/YYYY')
        -- Slashed format with 2-digit year (UK style): 02/02/25
        	when trip_date ~ '^\d{2}/\d{2}/\d{2}$' then TO_DATE(trip_date, 'DD/MM/YY')
        -- Hyphenated format with 4-digit year (US style): 06-25-2025
        	when trip_date ~ '^\d{2}-\d{2}-\d{4}$' then TO_DATE(trip_date, 'MM-DD-YYYY')
    	end as trip_date,
    -- 2. STANDARDIZE THE PICKUP TIME
    -- Safely converts "17:39" text format into a clean TIME data type
    	CAST(pickup_time AS TIME) as pickup_time,
    	abs(cast(nullif(distance_km,'') as numeric)) as distance_km,
		case 
			when initcap(TRIM(payment_method)) = 'Mpesa' then 'M-Pesa'
			else initcap(TRIM(payment_method))
		end as payment_method,
		case 
			when initcap(TRIM(status)) = 'Complete' then 'Completed'
			when initcap(TRIM(status)) = 'No-Show' then 'No Show'
			else initcap(TRIM(status))
		end as status,
		cast(
		regexp_replace(fare_amount, '[^0-9.]','','g') as numeric (10,2)
		) as fare_amount,
		case
			when nullif(customer_rating, '') is null or customer_rating = 'NULL' then null 
			when cast(customer_rating as int) not between 1 and 5 then null
			else cast(customer_rating as int)
		end as customer_rating	
from staging_haraka.trips_staging ; 

-------------------------- Sanity check to see if customer details are matching

select
    s.trip_id,
    s.customer_name,
    s.customer_phone,
    c.customer_id,
    c.customer_name AS matched_customer
from staging_haraka.trips_staging s
left join  booking.customers c on initcap(TRIM(s.customer_name)) = c.customer_name;

-------------------------- Sanity check to see if driver details are matching

select
    s.trip_id,
    s.driver_name,
    s.driver_phone,
    d.driver_id,
    d.driver_name AS matched_driver
from staging_haraka.trips_staging s
left join booking.drivers d
    on initcap(TRIM(s.driver_name)) = d.driver_name;

-------------------------- Sanity check to see if driver details are matching

select s.trip_id,
		s.vehicle_plate,
		v.vehicle_id,
		v.vehicle_plate as matched_vehicle
from staging_haraka.trips_staging s
left join fleet.vehicles v 
on UPPER(TRIM(s.vehicle_plate)) = v.vehicle_plate; 

------------------------- Inserting data into trips table --------------------

insert into booking.trips(trip_id, customer_id, driver_id, vehicle_id, pickup_area,
							dropoff_area, trip_date, pickup_time, distance_km, payment_method, 
							status, fare_amount, customer_rating)
select distinct
		cast(s.trip_id as int) as trip_id,
		c.customer_id,
		d.driver_id,
		v.vehicle_id,
		-- Pickup area
		case 
			when initcap(TRIM(s.pickup_area)) = 'Kasarrani' then 'Kasarani'
			when initcap(TRIM(s.pickup_area)) = 'Karren' then 'Karen'
			when initcap(TRIM(s.pickup_area)) = 'Kilimmani' then 'Kilimani'
			when initcap(TRIM(s.pickup_area)) = 'Burubburu' then 'Buruburu'
			when initcap(TRIM(s.pickup_area)) = 'Embakkasi' then 'Embakasi'
			when initcap(TRIM(s.pickup_area)) = 'Runnda' then 'Runda'
			when initcap(TRIM(s.pickup_area)) = 'Lavinngton' then 'Lavington'
			when initcap(TRIM(s.pickup_area)) = 'Langgata' then 'Langata'
			when initcap(TRIM(s.pickup_area)) = 'Westllands' then 'Westlands'
			when initcap(TRIM(s.pickup_area)) = 'Cbbd' then 'CBD'
			when initcap(TRIM(s.pickup_area)) = 'Cbd' then 'CBD'
			when initcap(TRIM(s.pickup_area)) = 'Parkllands' then 'Parklands'
			when initcap(TRIM(s.pickup_area)) = 'Soutth B' then 'South B'
			when initcap(TRIM(s.pickup_area)) = 'Soutth C' then 'South C'
			else initcap(trim(s.pickup_area))
		end as pickup_area,
		--Drop off area
		case 
			when initcap(TRIM(s.dropoff_area)) = 'Kasarrani' then 'Kasarani'
			when initcap(TRIM(s.dropoff_area)) = 'Karren' then 'Karen'
			when initcap(TRIM(s.dropoff_area)) = 'Kilimmani' then 'Kilimani'
			when initcap(TRIM(s.dropoff_area)) = 'Burubburu' then 'Buruburu'
			when initcap(TRIM(s.dropoff_area)) = 'Embakkasi' then 'Embakasi'
			when initcap(TRIM(s.dropoff_area)) = 'Runnda' then 'Runda'
			when initcap(TRIM(s.dropoff_area)) = 'Lavinngton' then 'Lavington'
			when initcap(TRIM(s.dropoff_area)) = 'Langgata' then 'Langata'
			when initcap(TRIM(s.dropoff_area)) = 'Westllands' then 'Westlands'
			when initcap(TRIM(s.dropoff_area)) = 'Cbbd' then 'CBD'
			when initcap(TRIM(s.dropoff_area)) = 'Cbd' then 'CBD'
			when initcap(TRIM(s.dropoff_area)) = 'Parkllands' then 'Parklands'
			when initcap(TRIM(s.dropoff_area)) = 'Soutth B' then 'South B'
			when initcap(TRIM(s.dropoff_area)) = 'Soutth C' then 'South C'
			else initcap(trim(s.dropoff_area))
		end as dropoff_area,
		-- Trip_date
    	case
	    	when s.trip_date ~ '^\d{4}-\d{2}-\d{2}$' then TO_DATE(s.trip_date, 'YYYY-MM-DD')
      		when s.trip_date ~ '^\d{2}/\d{2}/\d{4}$' then TO_DATE(s.trip_date, 'DD/MM/YYYY')
        	when s.trip_date ~ '^\d{2}/\d{2}/\d{2}$' then TO_DATE(s.trip_date, 'DD/MM/YY')
        	when s.trip_date ~ '^\d{2}-\d{2}-\d{4}$' then TO_DATE(s.trip_date, 'MM-DD-YYYY')
    	end as trip_date,
    	-- Pick_up time
    	CAST(s.pickup_time AS TIME) as pickup_time,
    	-- Distance_km
    	abs(cast(nullif(s.distance_km,'') as numeric)) as distance_km,
    	-- Payment method
		case 
			when initcap(TRIM(s.payment_method)) = 'Mpesa' then 'M-Pesa'
			else initcap(TRIM(s.payment_method))
		end as payment_method,
		-- Status
		case 
			when initcap(TRIM(s.status)) = 'Complete' then 'Completed'
			when initcap(TRIM(s.status)) = 'No-Show' then 'No Show'
			else initcap(TRIM(s.status))
		end as status,
		-- Fare_amount
		cast(
		regexp_replace(s.fare_amount, '[^0-9.]','','g') as numeric (10,2)
		) as fare_amount,
		-- Customer_rating
		case
			when nullif(s.customer_rating, '') is null or s.customer_rating = 'NULL' then null 
			when cast(s.customer_rating as int) not between 1 and 5 then null
			else cast(s.customer_rating as int)
		end as customer_rating
from staging_haraka.trips_staging s
left join booking.customers c on initcap(TRIM(s.customer_name)) = c.customer_name 
left join booking.drivers d on initcap(TRIM(s.driver_name)) = d.driver_name 
left join fleet.vehicles v on UPPER(TRIM(s.vehicle_plate)) = v.vehicle_plate ;


-------------------------- Sanity check for trips table
select *
from booking.trips;