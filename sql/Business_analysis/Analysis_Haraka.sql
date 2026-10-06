--Booking-Side Questions
--B1. Which 5 drivers have completed the most trips? What does "completed" mean here, and which table tells you that?

select d.driver_name, count(t.trip_id) as completed_trips  
from booking.trips t 
join booking.drivers d 
on t.driver_id = d.driver_id
where t.status = 'Completed'
group by d.driver_name 
order by completed_trips desc
limit 5;

--B2. Which customers have never actually completed a trip - even if they show up in the customers table at all? 
-- Think about what kind of JOIN finds "nothing on the other side."

select
    c.customer_name,
    c.customer_area
from booking.customers c
left join booking.trips t
    on c.customer_id = t.customer_id
    and t.status = 'Completed'
where t.trip_id is null;

--B3. Total revenue broken down by payment method, counting only completed trips. What do you need to filter, 
-- and what do you need to group by?

select sum(fare_amount) as total_revenue, payment_method  
from booking.trips  
where status = 'Completed'
group by payment_method ;

--Fleet-Side Questions
--F1. Rank vehicles by total fuel cost. Which two tables does this need, and is a plain JOIN enough?

select v.vehicle_plate , sum(fl.fuel_cost) as total_fuel_cost
		-- rank() over (order by sum(fl.fuel_cost) desc nulls last) as fuel_cost_rank
from fleet.vehicles v  
left join fleet.fuel_logs fl
on fl.vehicle_id = v.vehicle_id 
group by v.vehicle_plate
order by total_fuel_cost desc nulls last;

--F2. Which vehicles have had more than 3 maintenance events, and what's their total maintenance spend? 
-- (Hint: this needs a HAVING, not a WHERE.)

select ml.vehicle_id, sum(ml.maintenance_cost) as total_maintenance_spend, count(ml.vehicle_id) as maintenance_count  
from fleet.maintenance_logs ml
group by ml.vehicle_id
having count(ml.vehicle_id) > 3
order by maintenance_count desc;

-- Solution 2_Having vehicle_plate

select v.vehicle_plate, sum(ml.maintenance_cost) as total_maintenance_spend, 
		count(ml.vehicle_id) as maintenance_count  
from fleet.maintenance_logs ml
join fleet.vehicles v 
on ml.vehicle_id = v.vehicle_id 
group by v.vehicle_plate 
having count(ml.vehicle_id) > 3
order by maintenance_count desc;

--F3. Is there a vehicle that has never had a single fuel log? 
-- How would you prove a row genuinely doesn't exist on the other side of a JOIN,
-- rather than just not showing up because of a mismatched key?

select v.vehicle_plate 
from fleet.vehicles v 
left join fleet.fuel_logs fl 
on v.vehicle_id = fl.vehicle_id 
where fl.fuel_log_id is null;

-- Cross-Schema Questions
-- X1. For completed trips, show the vehicle's plate, make, and model alongside the trip.
-- This is the simplest possible cross-schema JOIN - get comfortable with it before the harder ones below.

select t.trip_id, v.vehicle_plate, v.vehicle_make, v.vehicle_model, t.status    
from booking.trips t 
join fleet.vehicles v 
on t.vehicle_id = v.vehicle_id
where t.status = 'Completed';

--X2. Total revenue generated per vehicle (completed trips only). 
-- Some vehicles may have generated zero revenue - make sure your JOIN choice doesn't accidentally drop them from the result.

-- Solution One: Where (NULL) is assigned for vehicles that have no completed trips.
select v.vehicle_plate, sum(t.fare_amount)as total_revenue 
from fleet.vehicles v 
left join booking.trips t 
on v.vehicle_id = t.vehicle_id 
and t.status = 'Completed'
group by v.vehicle_plate
order by total_revenue desc nulls last; 

-- Solution Two: Where (0) is assigned for vehicles that have no completed trips.
select v.vehicle_plate,
		coalesce(sum(t.fare_amount), 0) as total_revenue
from fleet.vehicles v 
left join booking.trips t 
on v.vehicle_id = t.vehicle_id 
and t.status = 'Completed'
group by v.vehicle_plate
order by total_revenue desc; 

--X3. Are there any vehicles marked 'Under Repair' in the fleet system that still show up carrying trips in the booking system?
--  What would that finding mean for the business, if it existed?

select v.vehicle_plate, v.vehicle_status  
from fleet.vehicles v
join booking.trips t 
on v.vehicle_id = t.vehicle_id 
where v.vehicle_status = 'Under Repair'
and t.status = 'Completed' ;

--------------------------Subquery Challenges
--S1. Which customers ride further than average? "Average" of what, exactly - and does that number need to come from a subquery,
-- or can you get it another way?

------ Step 1: Find average distance
------ Step 2: Find customers who ride further than the average

------------------------- Step One -- Inner query finding average distance

select avg(distance_km)
from booking.trips;  -- Avg distance = 17.8524421593830334

-------------------------- Step Two

select customer_id, avg(distance_km) as average_distance 
from booking.trips
group by customer_id
having AVG(distance_km) > 17.8524421593830334 
order by average_distance desc;

-------------------------- Subquery

select c.customer_name, avg(distance_km) as average_distance 
from booking.customers c  
join  booking.trips t
on t.customer_id = c.customer_id 
group by c.customer_name
having AVG(distance_km) > (select avg(distance_km) from booking.trips)
order by average_distance desc ;


--S2. Which vehicles spend more on fuel than the average vehicle's total fuel spend? 
--Notice this needs an average OF AN AGGREGATE (each vehicle's own total) - not a plain average of every row in fuel_logs. 
-- Think about what has to happen first before you can average it.

-- Step One:Find how much each vehicle spends on fuel
-- Step Two: Find average of the totals
-- Step Three Compare each vehicle's total against the average
-- Step Four - Subquery

-------------------------- Step One

select vehicle_id, sum(fuel_cost) as total_fuelcost 
from fleet.fuel_logs 
group by vehicle_id ;

-------------------------- Step Two

select AVG(total_fuelcost) as avg_fuelcost -- 34414.545454545455
from ( select vehicle_id, sum(fuel_cost) as total_fuelcost 
		from fleet.fuel_logs 
		group by vehicle_id
) as vehicle_totals; --

-------------------------- Step Three 

select vehicle_id, 
		sum(fuel_cost) as total_fuelcost
from fleet.fuel_logs
group by vehicle_id
having sum(fuel_cost) >  34414.545454545455
order by total_fuelcost desc;

-------------------------- Subquery

select v.vehicle_plate, sum(fuel_cost) as total_fuelcost 
from fleet.fuel_logs fl
join fleet.vehicles v 
on fl.vehicle_id = v.vehicle_id 
group by vehicle_plate 
having sum(fuel_cost) > 
	(select AVG(total_fuelcost)
	from ( 
			select vehicle_id, sum(fuel_cost) as total_fuelcost 
			from fleet.fuel_logs 
			group by vehicle_id) as vehicle_totals )
order by total_fuelcost desc ;


--S3. For each completed trip, is its fare higher than the average fare for that same payment method? 
-- This is a correlated subquery - the "average" is different depending on which row you're looking at.

-- Take each completed trip > look at its payment method > find the average fare for that payment method > 
-- check whether that trip's fare is higher.

-- Step One: Find average fare per payment method
-- Step Two: Find if fare is higher than average

-- Step One

select payment_method, AVG(fare_amount )
from booking.trips
where status = 'Completed'
group by payment_method; 

--Step Two

select t.trip_id, t.payment_method, t.fare_amount  
from booking.trips t
where t.status = 'Completed'
and t.fare_amount > ( 
						select AVG(t2.fare_amount)
						from booking.trips t2 
						where t2.status = 'Completed'
						and t.payment_method = t2.payment_method 
);



--Capstone - Vehicle Profitability Report
--
--Produce one result: for every vehicle, its total revenue (completed trips), total fuel cost, total maintenance cost, 
-- and net profit (revenue minus both costs). Rank vehicles from most to least profitable. 
-- Then, as a group, write 3-4 sentences on what you'd recommend management do about the least profitable vehicle(s). 
-- There is more than one reasonable way to structure this query - CTEs are worth considering
--  once you have more than two aggregates to bring together.

-- Step One: Total Revenue

select v.vehicle_plate, SUM(t.fare_amount) as total_revenue 
from fleet.vehicles v 
join booking.trips t 
on v.vehicle_id = t.vehicle_id 
where t.status = 'Completed' 
group by v.vehicle_plate ;

-- Step Two: Total Fuel Cost

select v.vehicle_plate, SUM(fl.fuel_cost) as total_fuelcost 
from fleet.vehicles v 
join fleet.fuel_logs fl
on v.vehicle_id = fl.vehicle_id 
group by v.vehicle_plate;

--Step Three: Total Maintenance Cost

select v.vehicle_plate, SUM(ml.maintenance_cost) as total_maintenancecost 
from fleet.vehicles v 
join fleet.maintenance_logs ml 
on v.vehicle_id = ml.vehicle_id 
group by v.vehicle_plate;

-- Step Four: Subquery in the join statement

select 
		v.vehicle_plate, 
		r.total_revenue,
		f.total_fuelcost,
		m.total_maintenancecost,
		f.total_fuelcost + m.total_maintenancecost as expenditure_cost,
		r.total_revenue - (f.total_fuelcost + m.total_maintenancecost) as net_profit,
		rank () over (order by r.total_revenue - (f.total_fuelcost + m.total_maintenancecost) desc) as net_profitrank
from fleet.vehicles v 
join ( select v.vehicle_id, SUM(t.fare_amount) as total_revenue 
		from fleet.vehicles v 
		join booking.trips t 
		on v.vehicle_id = t.vehicle_id 
		where t.status = 'Completed' 
		group by v.vehicle_id
)r -- for revenue
	on v.vehicle_id = r.vehicle_id
join ( 
		select v.vehicle_id, SUM(fl.fuel_cost) as total_fuelcost 
		from fleet.vehicles v 
		join fleet.fuel_logs fl
		on v.vehicle_id = fl.vehicle_id 
		group by v.vehicle_id
) f -- for fuel
	on v.vehicle_id = f.vehicle_id
join ( 
		select v.vehicle_id, SUM(ml.maintenance_cost) as total_maintenancecost 
		from fleet.vehicles v 
		join fleet.maintenance_logs ml 
		on v.vehicle_id = ml.vehicle_id 
		group by v.vehicle_id
) m -- alias for maintenance
	on v.vehicle_id = m.vehicle_id
;

------------------------------------ CTE WAY ----------------------------------------

with revenue as ( select v.vehicle_id, SUM(t.fare_amount) as total_revenue 
		from fleet.vehicles v 
		join booking.trips t 
		on v.vehicle_id = t.vehicle_id 
		where t.status = 'Completed' 
		group by v.vehicle_id 
),
fuel as ( select v.vehicle_id, SUM(fl.fuel_cost) as total_fuelcost 
		from fleet.vehicles v 
		join fleet.fuel_logs fl
		on v.vehicle_id = fl.vehicle_id 
		group by v.vehicle_id
),
maintenance as (select v.vehicle_id, SUM(ml.maintenance_cost) as total_maintenancecost 
		from fleet.vehicles v 
		join fleet.maintenance_logs ml 
		on v.vehicle_id = ml.vehicle_id 
		group by v.vehicle_id
) 
select 
		v.vehicle_plate,
		r.total_revenue,
		f.total_fuelcost,
		m.total_maintenancecost,
		f.total_fuelcost + m.total_maintenancecost as expenditure_cost,
		r.total_revenue - (f.total_fuelcost + m.total_maintenancecost) as net_profit,
		rank () over (order by r.total_revenue - (f.total_fuelcost + m.total_maintenancecost) desc) as net_profitrank
from fleet.vehicles v
join revenue r on v.vehicle_id = r.vehicle_id
join fuel f on v.vehicle_id = f.vehicle_id
join maintenance m on v.vehicle_id = m.vehicle_id ;