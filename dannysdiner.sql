CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

-- 1. What is the total amount each customer spent at the restaurant?
SELECT
  	sales.customer_id,
    sum(menu.price) as spent
FROM dannys_diner.sales sales, dannys_diner.menu menu
where sales.product_id = menu.product_id
group by sales.customer_id
order by sales.customer_id;

    /* --------------------
       Case Study Questions
       --------------------*/
    
    -- 1. What is the total amount each customer spent at the restaurant?

    SELECT
      	sales.customer_id,
        sum(menu.price) as spent
    FROM dannys_diner.sales sales, dannys_diner.menu menu
    where sales.product_id = menu.product_id
    group by sales.customer_id
    order by sales.customer_id;

-- | customer_id | spent |
-- | ----------- | ----- |
-- | A           | 76    |
-- | B           | 74    |
-- | C           | 36    |

-- ---
    -- 2. How many days has each customer visited the restaurant?
    SELECT
      	sales.customer_id,
        count(distinct sales.order_date) as days_ordered
    FROM dannys_diner.sales sales
    group by sales.customer_id
    order by sales.customer_id;

-- | customer_id | days_ordered |
-- | ----------- | ------------ |
-- | A           | 4            |
-- | B           | 6            |
-- | C           | 2            |

---

    -- 3. What was the first item from the menu purchased by each customer?
with cte as (
	select s.customer_id, s.order_date, s.product_id, m.product_name,
	rank() over (partition by customer_id order by order_date) as 	bought_order
	from dannys_diner.sales s inner join dannys_diner.menu m on s.product_id = m.product_id
)
select distinct customer_id, product_name
from cte
where bought_order = 1;

-- | customer_id | product_name |
-- | ----------- | ------------ |
-- | A           | curry        |
-- | A           | sushi        |
-- | B           | curry        |
-- | C           | ramen        |

---
    -- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
    with cte as(
      select s.customer_id, s.product_id, m.product_name,
          count(s.product_id) over (partition by s.product_id) as num_products
      from dannys_diner.sales s inner join dannys_diner.menu m 
      on s.product_id = m.product_id
    )

    select distinct product_name, num_products
    from cte
    where num_products = (select max(num_products) from cte)
    ;

-- | product_name | num_products |
-- | ------------ | ------------ |
-- | ramen        | 8            |

---

    -- 5. Which item was the most popular for each customer?
  with cte as(
    select s.customer_id, s.product_id, m.product_name,
        count(s.product_id) as num_products,
        dense_rank() over (partition by s.customer_id order by count(s.customer_id) desc) as rank
    from dannys_diner.sales s inner join dannys_diner.menu m 
    on s.product_id = m.product_id
    group by s.customer_id, m.product_name, s.product_id
  )

  select customer_id, product_name, num_products from cte where rank=1;

-- | customer_id | product_name | num_products |
-- | ----------- | ------------ | ------------ |
-- | A           | ramen        | 3            |
-- | B           | curry        | 2            |
-- | B           | sushi        | 2            |
-- | B           | ramen        | 2            |
-- | C           | ramen        | 3            |

---


    -- 6. Which item was purchased first by the customer after they became a member?

with cte as(
  select s.customer_id,
  s.product_id,
  row_number() over (partition by s.customer_id order by s.order_date) as rank
  from dannys_diner.sales s join dannys_diner.members m on 
  s.customer_id = m.customer_id
  where s.order_date > m.join_date
  group by s.customer_id, s.product_id, s.order_date
)

select cte.customer_id, m.product_name
from cte join dannys_diner.menu m
on cte.product_id = m.product_id
where cte.rank = 1
;

-- | customer_id | product_name |
-- | ----------- | ------------ |
-- | B           | sushi        |
-- | A           | ramen        |

---
    -- 7. Which item was purchased just before the customer became a member?

    with cte as(
      select s.customer_id,
      s.product_id,
      rank() over (partition by s.customer_id order by s.order_date desc) as rank
      from dannys_diner.sales s join dannys_diner.members m on 
      s.customer_id = m.customer_id
      where s.order_date < m.join_date
      group by s.customer_id, s.product_id, s.order_date
    )

    select cte.customer_id, m.product_name
    from cte join dannys_diner.menu m
    on cte.product_id = m.product_id
    where cte.rank = 1
    order by cte.customer_id
    ;

-- | customer_id | product_name |
-- | ----------- | ------------ |
-- | A           | sushi        |
-- | A           | curry        |
-- | B           | sushi        |

---

    -- 8. What is the total items and amount spent for each member before they became a member?
    with cte as(
    select  s.customer_id, 
    		s.product_id,
            m.price,
      		s.order_date
    from dannys_diner.sales s 
    join dannys_diner.menu m
    on s.product_id = m.product_id
    join dannys_diner.members m2
    on s.customer_id = m2.customer_id and s.order_date < m2.join_date 
    group by s.customer_id, s.product_id, m.price, s.order_date
    order by s.customer_id
    )
    
    select customer_id, count(product_id) as num_items, sum(price) as total_money
    from cte
    group by customer_id;

-- | customer_id | num_items | total_money |
-- | ----------- | --------- | ----------- |
-- | A           | 2         | 25          |
-- | B           | 3         | 40          |

---

    -- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
    with cte as(
      select s.customer_id, s.product_id,
        case
          when s.product_id = 1 then m.price * 20
          else m.price * 10
        end as money_spent
      from dannys_diner.sales s join dannys_diner.menu m
      on s.product_id = m.product_id
      order by s.customer_id
    )
    
    select customer_id, sum(money_spent) as pts
    from cte
    group by customer_id;

-- | customer_id | pts |
-- | ----------- | --- |
-- | A           | 860 |
-- | B           | 940 |
-- | C           | 360 |

---

    -- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
    with cte as(
    select s.customer_id, s.product_id,
      case
      	when s.order_date <= m2.join_date + 6 then m.price * 20
      	when s.order_date >= '2021-02-01' then 0
      	else m.price * 10
      end as points
    from dannys_diner.sales s join dannys_diner.menu m
    on s.product_id = m.product_id
    join dannys_diner.members m2
    on s.customer_id = m2.customer_id and s.order_date >= m2.join_date
     order by s.customer_id
    )
    
    select customer_id, sum(points) as total_pts from cte
    group by customer_id;

-- | customer_id | total_pts |
-- | ----------- | --------- |
-- | A           | 1020      |
-- | B           | 320       |

---

