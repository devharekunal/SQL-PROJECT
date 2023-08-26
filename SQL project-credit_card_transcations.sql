SELECT * FROM namaste_sql.credit_card_transcations;


-- 1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
with cte1 as
(select city,sum(amount) as total_amount
from credit_card_transcations
group by city),
cte2 as
(select sum(amount) as total from credit_card_transcations)
select cte1.*,round((total_amount/total * 100),2) as precentage_contribution from cte1,cte2
order by total_amount desc;

WITH cte1 AS (
  SELECT city, SUM(amount) AS total_amount
  FROM credit_card_transcations
  GROUP BY city
),
cte2 AS (
  SELECT SUM(amount) AS total FROM credit_card_transcations
)
SELECT cte1.*, ROUND((total_amount / (SELECT total FROM cte2) * 100), 2) AS percentage_contribution
FROM cte1
ORDER BY total_amount DESC;

# 2- write a query to print highest spend month and amount spent in that month for each card type
SELECT *
FROM (
    SELECT
        card_type,
        MONTH(STR_TO_DATE(transaction_date, '%d-%b-%y')) AS mth,
        YEAR(STR_TO_DATE(transaction_date, '%d-%b-%y')) AS yr,
        SUM(amount) AS total_amount,
        ROW_NUMBER() OVER (PARTITION BY card_type ORDER BY SUM(amount) DESC) AS rw
    FROM credit_card_transcations
    GROUP BY card_type, mth, yr
) x
WHERE rw = 1;


#3- write a query to print the transaction details(all columns from the table) for each card type when
#it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
with cte as (
select *,sum(amount) over(partition by card_type order by transaction_date,transaction_id) as amount_spend
from credit_card_transcations),
cte1 as(
select * from cte
where amount_spend >=1000000)
select * from
( select *,row_number() over (partition by card_type order by amount_spend) as rw_no
from cte1) x
where rw_no=1;

#4- write a query to find city which had lowest percentage spend for gold card type
with cte1 as(
select city,sum(amount) as gold_spend
from credit_card_transcations
where card_type = 'Gold'
group by city),
cte2 as(
select sum(amount) as total_city_amount
from credit_card_transcations)
select city,(gold_spend/total_city_amount) *100 as percent_spend
from cte2,cte1
order by percent_spend
limit 1;


WITH cte1 AS (
    SELECT
        city,
        SUM(amount) AS gold_spend
    FROM credit_card_transcations
    WHERE card_type = 'Gold'
    GROUP BY city
),
cte2 AS (
    SELECT
        city,
        SUM(amount) AS total_city_amount
    FROM credit_card_transcations
    GROUP BY city
)
SELECT
    cte1.city,
    (cte1.gold_spend / cte2.total_city_amount) * 100 AS percent_spend
FROM cte1
JOIN cte2 ON cte1.city = cte2.city
ORDER BY percent_spend ASC
LIMIT 1;


#5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
with cte1 as
(select city,exp_type,sum(amount) as total_amount
from credit_card_transcations
group by city,exp_type)
select city,
max(case when low=1 then exp_type end) as lowest_exp_type,
min(case when high=1 then exp_type end) as highest_exp_type
from
(select *,
row_number() over(partition by city order by total_amount desc) as high,
row_number() over(partition by city order by total_amount ) as low
from cte1) a
group by city;

-- 6- write a query to find percentage contribution of spends by females for each expense type
select exp_type,sum(amount),
sum(case when gender='F' then amount else 0 end)/sum(amount) as percentage_female_contribution
from credit_card_transcations
group by exp_type
order by percentage_female_contribution desc;

-- 7- which card and expense type combination saw highest month over month growth in Jan-2014
with cte as
(select card_type,exp_type,
MONTH(STR_TO_DATE(transaction_date, '%d-%b-%y')) AS mth,
year(STR_TO_DATE(transaction_date, '%d-%b-%y')) AS yr,
sum(amount) as amount
from credit_card_transcations
group by card_type,exp_type,mth,yr)

select *, amount-pre as month_growth
from
(select *,lag(amount) over(partition by card_type,exp_type order by yr,mth) as pre from cte) a
where mth=1 and yr=2014
order by month_growth desc
limit 1;

#9- during weekends which city has highest total spend to total no of transcations ratio 
select city,sum(amount)/count(1) as ratio 
from credit_card_transcations
where dayofweek(STR_TO_DATE(transaction_date, '%d-%b-%y')) in (1,7)
group by city
order by ratio desc
limit 1;

#10- which city took least number of days to reach its 500th transaction after the first transaction in that city
with cte as
(select city,transaction_date,row_number() over(partition by city order by transaction_date) as rw
from credit_card_transcations)
select city,datediff(max(STR_TO_DATE(transaction_date, '%d-%b-%y')),min(STR_TO_DATE(transaction_date, '%d-%b-%y'))) as datediff1
from cte
where rw=1 or rw=500
group by city
having count(*)=2
order by datediff1 
limit 1;

