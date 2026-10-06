create schema booking;

									-- Creating customer details

create table booking.customers(
customer_id serial primary key,
customer_name varchar(50) not null,
customer_phone varchar(20),
customer_area varchar(50)
);

------------------------ Standardizing customer_name, customer_area nad customer_phone
select
		initcap(TRIM(customer_name )) as clean_name,
		-- initcap(TRIM(customer_area )) as clean_area,
		case 
			when initcap(TRIM(customer_area )) = 'Kasarrani' then 'Kasarani'
			when initcap(TRIM(customer_area )) = 'Burubburu' then 'Buruburu'
			when initcap(TRIM(customer_area )) = 'Runnda' then 'Runda'
			when initcap(TRIM(customer_area )) = 'Lavinngton' then 'Lavington'
			when initcap(TRIM(customer_area )) = 'Langgata' then 'Langata'
			when initcap(TRIM(customer_area )) = 'Westllands' then 'Westlands'
			when initcap(TRIM(customer_area )) = 'Cbbd' then 'CBD'
			when initcap(TRIM(customer_area )) = 'Parkllands' then 'Parklands'
			when initcap(TRIM(customer_area )) = 'Soutth B' then 'South B'
			when initcap(TRIM(customer_area )) = 'Soutth C' then 'South C'
			else initcap(trim(customer_area ))
		end as clean_area,
		case
        when customer_phone is null or TRIM(customer_phone) = '' then NULL
        else '07' || REGEXP_REPLACE(
            REGEXP_REPLACE(customer_phone, '[^0-9]', '', 'g'),
            '^(07|2547|7)',
            ''
        )
    end as clean_number
from staging_haraka.trips_staging 
order by clean_name ;

---------------------- A subquery that checks whether a customer may be linked to more than one phone number
select clean_name,
		count(distinct clean_number) as phone_count
from (
        select
		initcap(TRIM(customer_name)) as clean_name,
		case
        when customer_phone is null or TRIM(customer_phone) = '' then NULL
        else '07' || REGEXP_REPLACE(
            REGEXP_REPLACE(customer_phone, '[^0-9]', '', 'g'),
            '^(07|2547|7)',
            ''
        )
    end as clean_number
	from staging_haraka.trips_staging
) as cleaned
group by clean_name
having count(distinct clean_number) > 1;

-------------------------- Query used when cleaning up customer_area
select initcap(TRIM(customer_area )) as clean_area
from staging_haraka.trips_staging 
where customer_area like 'E%';

--------------------------	 Correcting customer_area names
select 
		case 
			when initcap(TRIM(customer_area )) = 'Kasarrani' then 'Kasarani'
			when initcap(TRIM(customer_area )) = 'Burubburu' then 'Buruburu'
			when initcap(TRIM(customer_area )) = 'Runnda' then 'Runda'
			when initcap(TRIM(customer_area )) = 'Lavinngton' then 'Lavington'
			when initcap(TRIM(customer_area )) = 'Langgata' then 'Langata'
			when initcap(TRIM(customer_area )) = 'Westllands' then 'Westlands'
			when initcap(TRIM(customer_area )) = 'Cbbd' then 'CBD'
			when initcap(TRIM(customer_area )) = 'Parkllands' then 'Parklands'
			when initcap(TRIM(customer_area )) = 'Soutth B' then 'South B'
			when initcap(TRIM(customer_area )) = 'Soutth C' then 'South C'
			else initcap(TRIM(customer_area ))
		end as clean_area		
from staging_haraka.trips_staging; 


-------------------------- Query that selects distinct values - Zero duplication

SELECT 
    initcap(TRIM(customer_name)) AS clean_name,
    -- MAX() picks the actual area name over a blank or NULL
    MAX(
        CASE 
            WHEN initcap(TRIM(customer_area)) IN ('Kasarrani', 'Kasarani') THEN 'Kasarani'
            WHEN initcap(TRIM(customer_area)) IN ('Burubburu', 'Buruburu') THEN 'Buruburu'
            WHEN initcap(TRIM(customer_area)) IN ('Runnda', 'Runda') THEN 'Runda'
            WHEN initcap(TRIM(customer_area)) IN ('Lavinngton', 'Lavington') THEN 'Lavington'
            WHEN initcap(TRIM(customer_area)) IN ('Langgata', 'Langata') THEN 'Langata'
            WHEN initcap(TRIM(customer_area)) IN ('Westllands', 'Westlands') THEN 'Westlands'
            WHEN initcap(TRIM(customer_area)) IN ('Cbbd', 'Cbd', 'CBD') THEN 'CBD'
            WHEN initcap(TRIM(customer_area)) IN ('Parkllands', 'Parklands') THEN 'Parklands'
            WHEN initcap(TRIM(customer_area)) IN ('Soutth B', 'South B') THEN 'South B'
            WHEN initcap(TRIM(customer_area)) IN ('Soutth C', 'South C') THEN 'South C'
            WHEN TRIM(customer_area) = '' THEN NULL -- Turn empty strings to NULL so MAX ignores them
            ELSE initcap(TRIM(customer_area))
        END
    ) AS clean_area,
    -- MAX() picks the actual phone number over a blank or NULL
    MAX(
        CASE
            WHEN customer_phone IS NULL OR TRIM(customer_phone) = '' THEN NULL
            ELSE '07' || REGEXP_REPLACE(
                REGEXP_REPLACE(customer_phone, '[^0-9]', '', 'g'),
                '^(2547|07|7)',
                ''
            )
        END
    ) AS clean_number
FROM staging_haraka.trips_staging
GROUP BY initcap(TRIM(customer_name)) 
order by clean_name; 

--------------------------- Inserting customer details into customer table----------------------------------------

insert into booking.customers (customer_name, customer_area, customer_phone)
SELECT 
    initcap(TRIM(customer_name)) AS customer_name,
    MAX(
        CASE 
            WHEN initcap(TRIM(customer_area)) IN ('Kasarrani', 'Kasarani') THEN 'Kasarani'
            WHEN initcap(TRIM(customer_area)) IN ('Burubburu', 'Buruburu') THEN 'Buruburu'
            WHEN initcap(TRIM(customer_area)) IN ('Runnda', 'Runda') THEN 'Runda'
            WHEN initcap(TRIM(customer_area)) IN ('Lavinngton', 'Lavington') THEN 'Lavington'
            WHEN initcap(TRIM(customer_area)) IN ('Langgata', 'Langata') THEN 'Langata'
            WHEN initcap(TRIM(customer_area)) IN ('Westllands', 'Westlands') THEN 'Westlands'
            WHEN initcap(TRIM(customer_area)) IN ('Cbbd', 'Cbd', 'CBD') THEN 'CBD'
            WHEN initcap(TRIM(customer_area)) IN ('Parkllands', 'Parklands') THEN 'Parklands'
            WHEN initcap(TRIM(customer_area)) IN ('Soutth B', 'South B') THEN 'South B'
            WHEN initcap(TRIM(customer_area)) IN ('Soutth C', 'South C') THEN 'South C'
            WHEN TRIM(customer_area) = '' THEN NULL -- Turn empty strings to NULL so MAX ignores them
            ELSE initcap(TRIM(customer_area))
        END
    ) AS customer_area,
    MAX(
        CASE
            WHEN customer_phone IS NULL OR TRIM(customer_phone) = '' THEN NULL
            ELSE '07' || REGEXP_REPLACE(
                REGEXP_REPLACE(customer_phone, '[^0-9]', '', 'g'),
                '^(2547|07|7)',
                ''
            )
        END
    ) AS customer_phone
FROM staging_haraka.trips_staging
GROUP BY initcap(TRIM(customer_name));


-------------------------- Sanity check for customer details
select *
from booking.customers;