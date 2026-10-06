				---------------------------- Creating a table for driver details ---------------------------------
create table booking.drivers(
driver_id serial primary key,
driver_name varchar(50) not null,
driver_phone varchar(20)
);

		-------------------------- Profiling details concerning driver tables

select distinct
				driver_name, driver_phone  
from staging_haraka.trips_staging
order by driver_name ;

		-------------------------- Standardizing driver details

select 
		initcap(TRIM(driver_name)) as clean_name,
		case
        when driver_phone is null or TRIM(driver_phone) = '' then NULL
        else '07' || REGEXP_REPLACE(
            REGEXP_REPLACE(driver_phone, '[^0-9]', '', 'g'),
            '^(07|2547|7)',
            ''
        )
    end as clean_number
from staging_haraka.trips_staging 
order by clean_name;

			-------------------------- Removing duplicates

select distinct
		initcap(TRIM(driver_name)) as clean_name,
		case
        when driver_phone is null or TRIM(driver_phone) = '' then NULL
        else '07' || REGEXP_REPLACE(
            REGEXP_REPLACE(driver_phone, '[^0-9]', '', 'g'),
            '^(07|2547|7)',
            ''
        )
    end as clean_number
from staging_haraka.trips_staging 
order by clean_name, clean_number;

-------------------------- Checking for entries where driver_phone is empty

select driver_name, driver_phone  
from staging_haraka.trips_staging 
where driver_phone = '';

	--------------------------Filtering null phone_numbers after removing duplicate entries

select distinct
		initcap(TRIM(driver_name)) as clean_name,
		case
        when driver_phone is null or TRIM(driver_phone) = '' then NULL
        else '07' || REGEXP_REPLACE(
            REGEXP_REPLACE(driver_phone, '[^0-9]', '', 'g'),
            '^(07|2547|7)',
            ''
        )
    end as clean_number
from staging_haraka.trips_staging 
where TRIM(driver_phone) <> ''
order by clean_name, clean_number;

	--------------------------- Insert statement for the drivers table

insert into booking.drivers(driver_name, driver_phone)
select distinct
		initcap(TRIM(driver_name)) as driver_name,
		case
        when driver_phone is null or TRIM(driver_phone) = '' then NULL
        else '07' || REGEXP_REPLACE(
            REGEXP_REPLACE(driver_phone, '[^0-9]', '', 'g'),
            '^(07|2547|7)',
            ''
        )
    end as driver_number
from staging_haraka.trips_staging 
where TRIM(driver_phone) <> '' ;

-------------------------- Sanity check for drivers table
select *
from booking.drivers;