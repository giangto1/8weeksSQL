CREATE SCHEMA pizza_runner;
SET search_path = pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" TIMESTAMP
);

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');

  --Data Cleaning
 with customer_cte as
(
select order_id, customer_id, pizza_id, 
  case when exclusions is null or exclusions = 'null' then ''
  else exclusions
  end as exclusions,
  case when extras is null or extras = 'null' then ''
  else extras
  end as extras,
  order_time
from pizza_runner.customer_orders
),
runner_cte as
(
SELECT 
    order_id, 
    runner_id, 
    CASE 
        WHEN pickup_time IS NULL OR pickup_time = 'null' THEN ''
        ELSE pickup_time
    END AS pickup_time, 
    CASE 
        WHEN distance IS NULL OR distance = 'null' THEN ''
        ELSE REGEXP_REPLACE(distance, 'km', '', 'g')
    END AS distance,
    CASE 
        WHEN duration IS NULL OR duration = 'null' THEN ''
        WHEN duration LIKE '%mins' THEN REGEXP_REPLACE(duration, 'mins', '', 'g')
        WHEN duration LIKE '%minute' THEN REGEXP_REPLACE(duration, 'minute', '', 'g')
        WHEN duration LIKE '%minutes' THEN REGEXP_REPLACE(duration, 'minutes', '', 'g')
        ELSE duration
    END AS duration,
    CASE 
        WHEN cancellation = 'null' OR cancellation IS NULL THEN ''
        ELSE cancellation
    END AS cancellation
FROM pizza_runner.runner_orders

),
combined_cte as
(
  select c.*, r.runner_id, r.pickup_time, r.distance, r.duration, r.cancellation
  from customer_cte c left join runner_cte r
  on c.order_id = r.order_id
)
    -- B. Runner and Customer Experience
    -- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
    runners_by_week as 
    (select 
    case when registration_date < '2021-01-07' and registration_date >= '2021-01-01' then 1
    	 when registration_date < '2021-01-14' and registration_date >= '2021-01-08' then 2
         else 3
    end week, 
    count(runner_id) as num_runners
    from pizza_runner.runners
    group by registration_date
    order by registration_date)
    
    select week, sum(num_runners) as num_runners_signed_up from runners_by_week group by week order by week
    ;

-- | week | num_runners_signed_up |
-- | ---- | --------------------- |
-- | 1    | 2                     |
-- | 2    | 1                     |
-- | 3    | 1                     |

---

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
    pickup_cte as 
    (SELECT
     	order_id, 
     	order_time,
        pickup_time,
        cast(EXTRACT(EPOCH FROM (CAST(pickup_time AS TIMESTAMP) - CAST(order_time AS TIMESTAMP)) / 60) as integer) AS time_for_pickup
    FROM combined_cte
    WHERE cancellation = ''
    group by order_id, order_time, pickup_time
     )

     select cast(avg(time_for_pickup) as integer) as avg_pickup_time from pickup_cte
     ;

-- | avg_pickup_time |
-- | --------------- |
-- | 16              |

---
-- Is there any relationship between the number of pizzas and how long the order takes to prepare?
    select 
    	order_id, 
    	count(pizza_id) as pizza_count,
        cast(EXTRACT(EPOCH FROM (CAST(pickup_time AS TIMESTAMP) - CAST(order_time AS TIMESTAMP)) / 60) as integer) as prepare_time
    from combined_cte
    where cancellation = ''
    group by order_id, pickup_time, order_time
    order by order_id;

-- | order_id | pizza_count | prepare_time |
-- | -------- | ----------- | ------------ |
-- | 1        | 1           | 11           |
-- | 2        | 1           | 10           |
-- | 3        | 2           | 21           |
-- | 4        | 3           | 29           |
-- | 5        | 1           | 10           |
-- | 7        | 1           | 10           |
-- | 8        | 1           | 20           |
-- | 10       | 2           | 16           |

---
-- Is there any relationship between the number of pizzas and how long the order takes to prepare?
    prepare_cte as
    (select 
    	order_id, 
    	count(pizza_id) as pizza_count,
        cast(EXTRACT(EPOCH FROM (CAST(pickup_time AS TIMESTAMP) - CAST(order_time AS TIMESTAMP)) / 60) as integer) as prepare_time
    from combined_cte
    where cancellation = ''
    group by order_id, pickup_time, order_time
    order by order_id)
    
    select  
        pizza_count, 
    	cast(avg(prepare_time) as integer) as avg_prepare_time
    from prepare_cte
    group by pizza_count
    order by pizza_count
    ;

-- | pizza_count | avg_prepare_time |
-- | ----------- | ---------------- |
-- | 1           | 12               |
-- | 2           | 19               |
-- | 3           | 29               |

---
    -- What was the average distance travelled for each customer?
    select 
    	customer_id, 
        cast(avg(cast(distance as float)) as integer) as avg_distance_travelled
    from combined_cte 
    where cancellation = ''
    group by customer_id
    order by customer_id;

-- | customer_id | avg_distance_travelled |
-- | ----------- | ---------------------- |
-- | 101         | 20                     |
-- | 102         | 17                     |
-- | 103         | 23                     |
-- | 104         | 10                     |
-- | 105         | 25                     |

---
-- What was the average distance travelled for each customer?
    select 
    	customer_id, 
        cast(avg(cast(distance as float)) as decimal(4,2)) as avg_distance_travelled
    from combined_cte 
    where cancellation = ''
    group by customer_id
    order by customer_id;

-- | customer_id | avg_distance_travelled |
-- | ----------- | ---------------------- |
-- | 101         | 20.00                  |
-- | 102         | 16.73                  |
-- | 103         | 23.40                  |
-- | 104         | 10.00                  |
-- | 105         | 25.00                  |

---
-- What was the difference between the longest and shortest delivery times for all orders?
    select 
    	max(cast(duration as integer)) - min(cast(duration as integer)) as diff_between_logest_and_shortest_delivery_time
    from runner_cte
    where cancellation = '';

-- | diff_between_logest_and_shortest_delivery_time |
-- | ---------------------------------------------- |
-- | 30                                             |

---
 -- What was the average speed for each runner for each delivery and do you notice any trend for these values?
    speed_cte as
    (select 
    	runner_id,
        order_id, 
    	cast(distance as float) / (cast(duration as float)/60) as speed_km_per_hr
    from combined_cte
    where cancellation = ''
     )
     select runner_id, order_id, cast(avg(speed_km_per_hr) as decimal(4,2)) as avg_speed
     from speed_cte
     group by runner_id, order_id
     order by runner_id;

-- | runner_id | order_id | avg_speed |
-- | --------- | -------- | --------- |
-- | 1         | 1        | 37.50     |
-- | 1         | 2        | 44.44     |
-- | 1         | 3        | 40.20     |
-- | 1         | 10       | 60.00     |
-- | 2         | 4        | 35.10     |
-- | 2         | 7        | 60.00     |
-- | 2         | 8        | 93.60     |
-- | 3         | 5        | 40.00     |

---
-- What is the successful delivery percentage for each runner?
    successful_delivery_cnt as 
        (select 
        	runner_id,
            sum(case when cancellation = '' then 1 else 0 end) as num_successful_deliveries,
            sum(case when cancellation != '' then 1 else 0 end) as num_unsuccessful_deliveries
        from runner_cte
        group by runner_id
        )
        
    select runner_id, cast(cast(num_successful_deliveries as decimal(3,2)) / (num_successful_deliveries + num_unsuccessful_deliveries) as decimal(3,2)) as successful_delivery_percentage
        from successful_delivery_cnt
        order by runner_id;

-- | runner_id | successful_delivery_percentage |
-- | --------- | ------------------------------ |
-- | 1         | 1.00                           |
-- | 2         | 0.75                           |
-- | 3         | 0.50                           |

---

