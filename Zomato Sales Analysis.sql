drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
		(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
		(2,'01-15-2015'),
		(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
		(3,'12-18-2019',1),
		(2,'07-20-2020',3),
		(1,'10-23-2019',2),
		(1,'03-19-2018',3),
		(3,'12-20-2016',2),
		(1,'11-09-2016',1),
		(1,'05-20-2016',3),
		(2,'09-24-2017',1),
		(1,'03-11-2017',2),
		(1,'03-11-2016',1),
		(3,'11-10-2016',1),
		(3,'12-07-2017',2),
		(3,'12-15-2016',2),
		(2,'11-08-2017',2),
		(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES (1,'p1',980),
		(2,'p2',870),
		(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

-- Total amount spent by each customer on 'Zomato'

select s.userid as Customers, sum(p.price) as Total_amount
from sales s join product p
on s.product_id = p.product_id
group by customers
order by customers;

-- How many days has each customer visited 'Zomato' ?

select userid as Customers, count(distinct created_date) as Number_of_Days from sales
group by Customers;

-- What was the first product bought by each customer ?

select userid, created_date, product_id from
(select *, rank() over(partition by userid order by created_date) as rank from sales) sub
where rank = 1;

-- Most purchased item and number of times it is purchased by all the customers

select userid, count(product_id) as Times_of_purchase from sales where product_id = 
(select product_id from sales
group by product_id
order by count(product_id) desc limit 1) group by userid;

-- Most Popular item for each customer

select * from
(select *, rank() over(partition by userid order by count desc) as rank from
(select userid, product_id, count(product_id) as count from sales
group by userid, product_id) sub1)sub2 where rank = 1;

-- first item bought by the customer after they become a member

select * from (select *, rank() over(partition by userid order by created_date) as rank from
(select s.userid, s.created_date, s.product_id, g.gold_signup_date
from sales s join goldusers_signup g
on s.userid = g.userid
where s.created_date > g.gold_signup_date) a)b where rank = 1;

-- Item bought by the customer just before they become a member

select * from (select *, rank() over(partition by userid order by created_date desc) as rank from
(select s.userid, s.created_date, s.product_id, g.gold_signup_date
from sales s join goldusers_signup g
on s.userid = g.userid
where s.created_date < g.gold_signup_date)a)b where rank = 1;

-- Total orders and amount spent by each customer before they become a member

select userid, count(product_id) as Total_Orders, sum(price) as Total_amount from
(select a.userid, a.created_date, a.product_id, a.price, g.gold_signup_date from
(select s.userid, s.created_date, s.product_id, p.price from sales s join product p
on s.product_id = p.product_id)a join goldusers_signup g
on a.userid = g.userid
where created_date < gold_signup_date) b group by userid;

/*	On Purchasing each product Zomato offers some points e.g.
Product P1 : for each Rs. 5 = 1 Zomato Point
Product P2 : for each Rs. 2 = 1 Zomato Point
Product P3 : for each Rs. 5 = 1 Zomato Point
Based on total points earned, Zomato also offers a cashback of Rs. 5 on each 2 Zomato Points
*/
-- (A) Find the Total Points and Cashback earned by each customer

select userid, sum(points) as total_points, (sum(points)*2.5) as cashback_earned from
(select a.*, case
	when product_name = 'p1' then price/5
	when product_name = 'p2' then price/2
	when product_name = 'p3' then price/5
 	else 0
end as points from
(select s.userid, p.product_name, p.price from sales s join product p
on s.product_id = p.product_id
order by userid, product_name) a) b group by userid

-- (B) Find the product for which highest points have been earned by each customer.

select * from
(select *, rank() over(partition by userid order by points desc) as rank from
(select userid, product_name, sum(points) as points from
(select a.*, case
	when product_name = 'p1' then price/5
	when product_name = 'p2' then price/2
	when product_name = 'p3' then price/5
 	else 0
end as points from
(select s.userid, p.product_name, p.price from sales s join product p
on s.product_id = p.product_id
order by userid, product_name) a) b group by userid, product_name) c) d where rank = 1;

-- Ranking of the transactions for each customer based on order date

select *, rank() over(partition by userid order by created_date) as rank from sales