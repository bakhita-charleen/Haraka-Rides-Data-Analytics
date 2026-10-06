create schema fleet;

-------------------------- Creating table for vehicles
create table fleet.vehicles(
vehicle_id serial primary key,
vehicle_plate varchar(20) not null unique,
vehicle_make varchar(30),
vehicle_model varchar(30),
vehicle_year int,
vehicle_type varchar(30),
vehicle_status varchar(30) 
);

-- Cleaning the table and taking careof the inconsistent casing.
/* 
 * UPPER: Converts to uppercase
 * TRIM: Takes care of the extra spaces
 * INITCAP: Converts it into sentence case
 * CAST: Converts the initial text data type of the year to an integer
 * Where clause: Returns results where vehicle plate is not equal to blank.
 */

-------------------------- Query to precheck before running it in the insert clause

SELECT DISTINCT
    UPPER(TRIM(vehicle_plate)) AS vehicle_plate,
    INITCAP(TRIM(vehicle_make)) AS vehicle_make,
    INITCAP(TRIM(vehicle_model)) AS vehicle_model,
    CAST(vehicle_year AS INTEGER) AS vehicle_year,
    INITCAP(TRIM(vehicle_type)) AS vehicle_type,
    INITCAP(TRIM(vehicle_status)) AS vehicle_status
FROM staging_haraka.fleet_staging
WHERE TRIM(vehicle_plate) <> '';

					-------------------------- Inserting vehicle data ------------------------

insert into fleet.vehicles( vehicle_plate, vehicle_make, vehicle_model, vehicle_year, vehicle_type, vehicle_status)
select distinct 
	UPPER(TRIM(vehicle_plate )) as vehicle_plate,
    initcap(TRIM(vehicle_make )) as vehicle_make,
    initcap(TRIM(vehicle_model )) as vehicle_model,
    cast (vehicle_year as integer) as vehicle_year,
    initcap(TRIM(vehicle_type)) as vehicle_type,
    initcap(TRIM(vehicle_status)) as vehicle_status
FROM staging_haraka.fleet_staging
where trim (vehicle_plate ) <> '';


select *
from fleet.vehicles;

			-------------------------- Counts distinct vehicles
select count(*)
from fleet.vehicles;

-------------------------- Double check on the number of vehicles

SELECT COUNT(DISTINCT UPPER(TRIM(vehicle_plate)))
FROM staging_haraka.fleet_staging
WHERE TRIM(vehicle_plate) <> '';
