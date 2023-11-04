--Credit card transaction history
--Total 986 cities in this dataset
--Total 3years of data 2013,14,15 in this dataset
--4 types of card - Silver,Signature,Gold,Platinum
--6 types expences - Entertainment,Food,Bills,Fuel,Travel,Grocery

-- Top 5 cities with highest spends and their percentage contribution of total credit card spends 

select top 5 city,cast(sum(amount)/(select sum(amount) from credit_card_transactions) as decimal(5,3)) as total_contribution
from credit_card_transactions
group by city
order by total_contribution desc;

-- Highest spend month and amount spent in that month for each card type

with cte as(select card_type,datepart(year,date) as year,datepart(month,date) as month,sum(amount) as total_amount,
                   rank()over(partition by card_type order by sum(amount) desc) as rn
            from credit_card_transactions
            group by card_type,datepart(year,date),datepart(month,date))
select card_type,year,month,total_amount from cte
where rn=1;

-- Transaction details for each card type when it reaches a cumulative of 1000000 total spends

with cte1 as(select index_no,city,date,card_type,exp_type,gender,amount,
                    sum(amount)over(partition by card_type order by date,index_no) as cum_sum
             from credit_card_transactions),
cte2 as(select index_no,city,date,card_type,exp_type,gender,amount,cum_sum,
               rank()over(partition by card_type order by cum_sum) as rnk
        from cte1
        where cum_sum>=1000000)
select index_no,city,date,card_type,exp_type,gender,amount,cum_sum
from cte2
where rnk=1;

-- City which had lowest percentage spend for gold card type

with cte as(select city ,(sum(case when card_type='Gold' then amount else null end)*1.0/sum(amount))*100 as percentage_spent_on_gold_card
            from credit_card_transactions
            group by city)
select top 1 city,percentage_spent_on_gold_card
from cte
where percentage_spent_on_gold_card is not null
order by percentage_spent_on_gold_card;

-- City wise highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

with cte as(select city,exp_type, sum(amount) as total_amount,
                   rank()over(partition by city order by sum(amount) desc) as rnk_desc,
				   rank()over(partition by city order by sum(amount)) as rnk_asc
            from credit_card_transactions
            group by city,exp_type)
select city,
       max(case when rnk_desc=1 then exp_type else null end) as highest_expense_type,
	   max(case when rnk_asc=1 then exp_type else null end) as lowest_expense_type
from cte
group by city;

-- Percentage contribution of spends by females for each expense type

select exp_type,cast((sum(case when gender='F' then amount else 0 end)*1.0/sum(amount))*100 as decimal(5,2)) as percentage_contribution_female
from credit_card_transactions
group by exp_type;

-- Card and expense type combination saw highest month over month growth in Jan-2014 

with cte1 as(select card_type,exp_type,datepart(year,date) as year,datepart(month,date) as month , sum(amount) as total_amount
             from credit_card_transactions
             group by card_type,exp_type,datepart(year,date),datepart(month,date)),
cte2 as(select card_type,exp_type,year,month,total_amount,
               lag(total_amount)over(partition by card_type,exp_type order by year,month) as prev_month_amount	           
        from cte1)
select top 1 card_type,Exp_Type,cast((total_amount-prev_month_amount)/prev_month_amount as decimal(5,2)) as growth_rate
from cte2
where year=2014 and month=1
order by growth_rate desc;

-- City has highest total spend to total no of transcations ratio during weekends

select top 1 city,sum(amount)/count(*) as total_spend_to_total_no_of_transcations_ratio
from credit_card_transactions
where datepart(weekday,date) in(1,7)
    --datename(weekday,date) in('Saturday','Sunday')
group by city
order by total_spend_to_total_no_of_transcations_ratio desc;

-- City took least number of days to reach its 500th transaction after the first transaction in that city

with cte as(select city,date,row_number()over(partition by city order by date,index_no) as rn
            from credit_card_transactions)
select top 1 city, datediff(day,min(date),max(date)) as date_diff
from cte
where rn=1 or rn=500
group by city
having count(*)>1
order by date_diff




