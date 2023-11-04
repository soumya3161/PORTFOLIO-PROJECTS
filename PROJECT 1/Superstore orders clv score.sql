select * from superstore_orders;


--in this superstore data the max order date is 2021 so for better analysis i added one year in 1st cte
with cte1 as(select customer_id,dateadd(year,1,order_date)as order_date,sales     
             from superstore_orders),
--finding recency,frequency and monetary in 2nd cte
cte2 as(select customer_id,
	       datediff(day,max(order_date),getdate()) as recency,
	       count(distinct order_date) as frequency,
	       sum(sales) as monetary
	from cte1
	group by customer_id),
--finding minimum maximum RFM in 3rd cte for further calculations 
cte3 as(select min(recency) as min_recency,
	       max(recency) as max_recency,
	       min(frequency) as min_frequency,
	       max(frequency) as max_frequency,
	       min(monetary) as min_monetary,
	       max(monetary) as max_monetary
	from cte2),
--applying formula (xi – min(x)) / (max(x) – min(x)) to normalize the numbers along with i multiplied weightages in 4th cte
--weightages depends on client or company 
--for me:
--recency 0.2
--frequency 0.5
--monetary 0.3 
cte4 as(select customer_id,
	       cast(((a.recency-b.min_recency)*1.0/(b.max_recency-b.min_recency))*0.2+  
	       ((a.frequency-b.min_frequency)*1.0/(b.max_frequency-b.min_frequency))*0.5+
	       ((a.monetary-b.min_monetary)*1.0/(b.max_monetary-b.min_monetary))*0.3 as decimal(5,2)) as clv_score
	from cte2 a,cte3 b)
--joined back to the main table to get each customer detail
select distinct o.customer_id,o.customer_name,c.clv_score
from superstore_orders o
inner join cte4 c
on o.customer_id=c.customer_id
order by c.clv_score desc