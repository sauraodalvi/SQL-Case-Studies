/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT
customer_id,
SUM(price) as total_spend
FROM dannys_diner.sales as S
INNER JOIN dannys_diner.menu as M
on S.product_id=M.product_id
GROUP BY customer_id 
ORDER BY total_spend DESC;

-- 2. How many days has each customer visited the restaurant?
SELECT
customer_id,
Count(distinct order_date) as days
FROM dannys_diner.sales
group by customer_id
order by days desc
;

-- 3. What was the first item from the menu purchased by each customer?
SELECT
customer_id, order_date, product_name
FROM dannys_diner.sales as s
INNER JOIN dannys_diner.menu as m
ON s.product_id=m.product_id
Order by customer_id, order_date ASC
;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
product_name, Count(order_date) as orders
FROM dannys_diner.sales as s
INNER JOIN dannys_diner.menu as m
ON s.product_id=m.product_id
group by product_name
order by orders desc;

-- 5. Which item was the most popular for each customer?
WITH TMP AS(
    SELECT
    product_name, customer_id, count(order_date) as orders,
    RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(order_date) DESC) as rnk
    FROM dannys_diner.sales as s
    INNER JOIN dannys_diner.menu as m
    ON s.product_id=m.product_id
    group by product_name, customer_id
 )
 SELECT * FROM TMP 
 WHERE rnk=1
;

-- 6. Which item was purchased first by the customer after they became a member?
WITH TMP AS
{
SELECT
s.customer_id,
join_date,
order_date,
RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date) as rnk,
product_name
FROM dannys_diner.sales as s
INNER JOIN dannys_diner.members as m
ON s.customer_id=m.customer_id
INNER JOIN dannys_diner.menu as menu
ON s.product_id=menu.product_id
}
Select * FROM TMP
WHERE rnk = 1
;

-- 7. Which item was purchased just before the customer became a member?
WITH TMP AS
(
SELECT
s.customer_id,
join_date,
order_date,
RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date) as rnk,
product_name
FROM dannys_diner.sales as s
INNER JOIN dannys_diner.members as m
ON s.customer_id=m.customer_id
INNER JOIN dannys_diner.menu as menu
ON s.product_id=menu.product_id
WHERE join_date>order_date
)
Select * FROM TMP
WHERE rnk=1;

-- 8. What is the total items and amount spent for each member before they became a member?
WITH TMP AS (
SELECT s.customer_id, join_date, order_date,
COUNT(product_name) as total_items, SUM(price) as total_amount
FROM dannys_diner.sales as s
INNER JOIN dannys_diner.members as m ON s.customer_id=m.customer_id
INNER JOIN dannys_diner.menu as menu ON s.product_id=menu.product_id
WHERE order_date < join_date
GROUP BY s.customer_id, join_date, order_date
)
SELECT 
customer_id,
sum(total_items) as total_items,
sum(total_amount) as total_amount
FROM TMP
GROUP BY tmp.customer_id
;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
customer_id,
SUM(
  CASE 
  WHEN product_name='sushi' THEN (price*20)
  ELSE price*10
  END)
  AS points
FROM dannys_diner.menu as m
INNER JOIN dannys_diner.sales as s ON m.product_id=s.product_id
Group BY s.customer_id
ORDER BY points DESC
;

-- Bonus 1. Recreate the following table output
SELECT s.customer_id, s.order_date, m.product_name, m.price, 
CASE WHEN s.order_date >= mem.join_date THEN 'Y'
     WHEN s.order_date < mem.join_date THEN 'N'  
     ELSE 'N' 
     END AS member 
FROM sales s 
LEFT JOIN menu m ON s.product_id = m.product_id 
LEFT JOIN members mem 
ON s.customer_id = mem.customer_id ;

-- Bonus 2. Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
WITH cte_bonus AS(
 SELECT s.customer_id, s.order_date, m.product_name, m.price, 
  CASE WHEN s.order_date >= mem.join_date THEN 'Y'
       WHEN s.order_date < mem.join_date THEN 'N'  
       ELSE 'N' 
       END AS member 
FROM sales s 
LEFT JOIN menu m ON s.product_id = m.product_id 
LEFT JOIN members mem 
ON s.customer_id = mem.customer_id) 

select *, 
CASE WHEN member = 'Y' THEN DENSE_RANK() OVER(PARTITION BY customer_id,member ORDER BY order_date)
ELSE 'Null'
END AS ranking 
from cte_bonus ;


