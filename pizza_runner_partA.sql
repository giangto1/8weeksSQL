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

-- CASE STUDY QUESTIONS
-- A. Pizza Metrics
-- How many pizzas were ordered?
select count(*) as num_pizzas from combined_cte;

-- | num_pizzas |
-- | ---------- |
-- | 14         |

---

-- How many unique customer orders were made?
select count(distinct order_id) as num_unique_customer_orders from combined_cte;
-- | num_unique_customer_orders |
-- | -------------------------- |
-- | 14                         |


-- How many successful orders were delivered by each runner?
    select runner_id, count(order_id) as num_successful_orders
    from runner_cte
    where cancellation = ''
    group by runner_id
    order by runner_id;

-- | runner_id | num_successful_orders |
-- | --------- | --------------------- |
-- | 1         | 4                     |
-- | 2         | 3                     |
-- | 3         | 1                     |

---

-- How many of each type of pizza was delivered?
    select p.pizza_name, count(c.order_id) as num_pizzas
    from combined_cte c join pizza_runner.pizza_names p
    on p.pizza_id = c.pizza_id
    where c.cancellation = ''
    group by c.pizza_id, p.pizza_name
    order by c.pizza_id;

-- | pizza_name | num_pizzas |
-- | ---------- | ---------- |
-- | Meatlovers | 9          |
-- | Vegetarian | 3          |

---

-- How many Vegetarian and Meatlovers were ordered by each customer?
    select customer_id, 
    sum(case when pizza_id = 1 then 1 else 0 end) as num_meatlover,
    sum(case when pizza_id = 2 then 1 else 0 end) as num_vegetarian
    from customer_cte
    group by customer_id
    order by customer_id;

-- | customer_id | num_meatlover | num_vegetarian |
-- | ----------- | ------------- | -------------- |
-- | 101         | 2             | 1              |
-- | 102         | 2             | 1              |
-- | 103         | 3             | 1              |
-- | 104         | 3             | 0              |
-- | 105         | 0             | 1              |

---

-- What was the maximum number of pizzas delivered in a single order?
    pizza_count_cte as
    (select order_id, count(pizza_id)as num_pizzas from combined_cte
    group by order_id)
    select max(num_pizzas) as num_pizzas_in_1_order
    from pizza_count_cte;

-- | num_pizzas_in_1_order |
-- | --------------------- |
-- | 3                     |

---

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
select customer_id,
        sum(case when exclusions != '' or extras != '' then 1 else 0 end) as num_pizzas_with_change,
        sum(case when exclusions = '' and extras = '' then 1 else 0 end) as num_pizzas_no_change
from combined_cte c 
where cancellation = ''
group by customer_id
order by customer_id;

-- | customer_id | num_pizzas_with_change | num_pizzas_no_change |
-- | ----------- | ---------------------- | -------------------- |
-- | 101         | 0                      | 2                    |
-- | 102         | 0                      | 3                    |
-- | 103         | 3                      | 0                    |
-- | 104         | 2                      | 1                    |
-- | 105         | 1                      | 0                    |

---

-- How many pizzas were delivered that had both exclusions and extras?
    select count(pizza_id) as num_delivered_with_change
    from combined_cte
    where exclusions != '' and extras != '' and cancellation = '';

-- | num_delivered_with_change |
-- | ------------------------- |
-- | 1                         |

---

-- What was the total volume of pizzas ordered for each hour of the day?
    select extract(hour from order_time) as hr_of_day, count(customer_id) as num_pizzas
    from customer_cte
    group by extract(hour from order_time)
    order by extract(hour from order_time);

-- | hr_of_day | num_pizzas |
-- | --------- | ---------- |
-- | 11        | 1          |
-- | 13        | 3          |
-- | 18        | 3          |
-- | 19        | 1          |
-- | 21        | 3          |
-- | 23        | 3          |

---

-- What was the volume of orders for each day of the week?
    select to_char(order_time,'day') as date_of_week, count(order_id) as num_orders
    from customer_cte
    group by to_char(order_time,'day');

-- | date_of_week | num_orders |
-- | ------------ | ---------- |
-- | wednesday    | 5          |
-- | thursday     | 3          |
-- | friday       | 1          |
-- | saturday     | 5          |

---