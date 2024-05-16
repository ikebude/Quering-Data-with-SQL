-- CASE STUDY: Danny’s Diner
-- QUERYING DATA WITH SQL
-- Mr Danny, a restaurant owner is interested in having information about his customers, 
-- especially about their visiting patterns, how much money they’ve spent and also, which menu items are their favorite. 
--  Having this deeper connection with his customers will help him deliver a better and more personalized experience for his loyal customers. 
--  He also needs these insights to help him decide whether he should expand the existing customer loyalty program or not.
--  3 key datasets were presented for analysis:
-- sales
-- menu
-- members

QUESTIONS
--1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price) as total_spent
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 2

--2. How many days has each customer visited the restaurant?
WITH sub1 AS 
(SELECT order_date,customer_id, COUNT(customer_id) as count
FROM dannys_diner.sales
GROUP BY 1,2
ORDER BY 1)

SELECT customer_id, COUNT (sub1.order_date)
FROM sub1
GROUP BY 1
ORDER BY 1

--3. What was the first item from the menu purchased by each customer?
WITH sub1 AS (
	SELECT	 s.customer_id, s.order_date, m.product_name,
	RANK() OVER(PARTITION BY customer_id ORDER BY order_date) as rank
	FROM 	dannys_diner.sales s
	LEFT JOIN dannys_diner.menu m
	ON  s.product_id = m.product_id
	ORDER BY 2)

SELECT DISTINCT customer_id, product_name, order_date
FROM sub1
WHERE rank = 1

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name,
       	COUNT(s.product_id)
FROM dannys_diner.sales s
JOIN dannys_diner.menu m
USING (product_id)
GROUP BY 1
ORDER BY 2 desc
LIMIT 1



--5. Which item was the most popular for each customer?
WITH sub1 AS (
SELECT  s.customer_id, 
               m.product_name, 
               COUNT(m.product_name) times_ordered, 
	RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(m.product_name)DESC) AS rank
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY  1, 2)
  
SELECT customer_id, product_name, times_ordered
FROM sub1
WHERE rank=1

--6. Which item was purchased first by the customer after they became a member?
WITH sub1 as (
    SELECT mb.customer_id, m.product_name, s.order_date, mb.join_date,
 		RANK() OVER(PARTITION BY mb.customer_id ORDER BY s.order_date) AS rank
	FROM dannys_diner.sales s
	LEFT JOIN dannys_diner.menu m
	ON s.product_id = m.product_id
	LEFT JOIN dannys_diner.members mb
	ON s.customer_id = mb.customer_id
	WHERE s.order_date > mb.join_date)
  
SELECT *
FROM sub1  
WHERE rank = 1
  
--7. Which item was purchased just before the customer became a member?
WITH sub1 AS (
	SELECT mb.customer_id, m.product_name, s.order_date, mb.join_date,
 		RANK() OVER(PARTITION BY mb.customer_id ORDER BY s.order_date desc) AS rank
	FROM dannys_diner.sales s
	LEFT JOIN dannys_diner.menu m
	ON s.product_id = m.product_id
	LEFT JOIN dannys_diner.members mb
	ON s.customer_id = mb.customer_id
	WHERE s.order_date < mb.join_date
	)
	
SELECT *
FROM sub1
WHERE rank = 1

--8. What is the total items and amount spent for each member before they became a member?
SELECT DISTINCT s.customer_id, m.product_name, COUNT(s.product_id), SUM(m.price) as total_spent
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
ON s.product_id = m.product_id
LEFT JOIN dannys_diner.members mb
ON s.customer_id = mb.customer_id
GROUP BY 1,2, s.order_date, mb.join_date
HAVING s.order_date < mb.join_date
ORDER BY 1

--9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH sub1 AS (
	SELECT s.customer_id, m.product_name, COUNT(s.product_id), SUM(m.price) as total_spent,
	CASE WHEN m.product_name= 'sushi' THEN 2 * 10 * SUM(m.price)
		 ELSE 10 * SUM(m.price) end as points
	FROM dannys_diner.sales s
	LEFT JOIN dannys_diner.menu m
	ON s.product_id = m.product_id
	LEFT JOIN dannys_diner.members mb
	ON s.customer_id = mb.customer_id
	GROUP BY 1,2
	) 
SELECT customer_id, SUM(points)
FROM sub1
GROUP BY 1
ORDER BY 1

--10. In the first week after a customer joins the program (including their join date), they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January? 
With sub1 AS (
	SELECT s.customer_id, m.product_name,s.order_date, mb.join_date, 
	COUNT(s.product_id), SUM(m.price) AS total_spent,
	CASE WHEN s.order_date BETWEEN mb.join_date - 1 AND mb.join_date + 7
		 OR m.product_name= 'sushi' THEN 2 * 10 * SUM(m.price)
		 ELSE 10 * SUM(m.price) END AS points
	FROM dannys_diner.sales s
	LEFT JOIN dannys_diner.menu m
	ON s.product_id = m.product_id
	LEFT JOIN dannys_diner.members mb
	ON s.customer_id = mb.customer_id
	GROUP BY 1,2,3,4
	) 
SELECT customer_id, SUM(points)
FROM sub1
GROUP BY 1
ORDER BY 1

-- INSIGHTS
-- •	Customer A has spent the most money in the restaurant, and this is closely followed by customer B with a difference of just $2.
-- •	Customer B however, has visited the store more than any other customer has.
-- •	Curry was most ordered item on the menu for first time customers.
-- •	Overall, Ramen was the most purchased item on the menu.
-- •	Data trends amongst the individual purchases showed ramen as the most frequent purchase amongst all customers as well.
-- •	Customers spent more money when the became members, compared to when they were not members of the loyalty program
-- •	The point-based reward system can drive purchase of a particular product on the menu if its points are more rewarding.

-- RECOMMENDATIONS
-- •	The natural endearment towards ramen shows that it is a stellar product and this should be maximized. Ramen should be highlighted and prominently displayed on the menu with a compelling and mouth-watering description.
-- •	Special deals or promotions that focus on ramen, such as a discount for ordering it, more reward points, or a complimentary drink or dessert should be considered
-- •	More data that can encourage targeted serving of customers should be collected e.g. addresses, opinion on delivery services, customer feedback etc.
-- •	A positive experience in the restaurant will definitely increase sales and drive customer repeat purchases. This refers to how customers are treated by staff.
-- •	Members are observed to spend more money, so strategies must be put in place to convert customers to members
-- •	The point-based reward system works and should be encouraged. This system does not have to be fixed but can be flexible to ensure that different products can be promoted at different times.


--These datasets were gotten from the Danny Ma’s 8 weeks SQL challenge.
--The Schema SQL code for the creation of permanent tables used for this project is attached below


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
