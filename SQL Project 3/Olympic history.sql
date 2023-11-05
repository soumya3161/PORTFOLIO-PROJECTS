/*The data contains 120 years of olympics history. There are 2 daatsets 
1- athletes : it has information about all the players participated in olympics
2- athlete_events : it has information about all the events happened over the year.(athlete id refers to the id column in athlete table)*/


select * from athletes;
select * from athlete_events;

--Team has won the maximum gold medals over the years.
-- 1st approach
with cte as(select a.team,count(distinct ae.event) as total_gold_medals
            from athletes a
            inner join athlete_events ae
            on a.id=ae.athlete_id
			where ae.medal='Gold'
            group by a.team)
select top 1 team,total_gold_medals
from cte
order by total_gold_medals desc
--2nd approach
select team,total_gold_medals
from(select a.team,count(distinct ae.event) as total_gold_medals, rank()over(order by count(distinct ae.event) desc) as rn
     from athletes a
     inner join athlete_events ae
     on a.id=ae.athlete_id
     where ae.medal='Gold'
     group by a.team) as x
where rn=1

--For each teamt total silver medals and year in which they won maximum silver medal.

with cte as(select a.team,ae.year,count(distinct ae.event) as silver_medals,
                   rank()over(partition by team order by count(distinct ae.event) desc) as rn
			from athletes a
			inner join athlete_events ae
			on a.id=ae.athlete_id
			where ae.medal='Silver'
			group by a.team,ae.year)
select team,sum(silver_medals) as total_silver_medals,max(case when rn=1 then year end) as year_of_max_silver
from cte
group by team;

--Player has won maximum gold medals  amongst the players 
--who have won only gold medal (never won silver or bronze) over the years

select top 1 a.id,a.name,count(*) as gold_medal
from athletes a
inner join athlete_events ae
on a.id=ae.athlete_id
where a.id not in(select distinct athlete_id from athlete_events where medal in ('Silver','Bronze'))
and ae.medal='Gold'
group by a.id,a.name
order by gold_medal desc

--In each year which player has won maximum gold medal and no of golds won in that year . 
--In case of a tie we need to print comma separated player names.

with cte as(select ae.year,a.name,count(*) as total_gold_medals,
                   rank()over(partition by ae.year order by count(*) desc) as rn
            from athletes a
            inner join athlete_events ae
            on a.id=ae.athlete_id
            where ae.medal='Gold'
            group by ae.year,a.name)
select year,string_agg(name,', ') as player_name,total_gold_medals
from cte
where rn=1
group by year,total_gold_medals
order by year

--Event and year in which  India has won its first gold medal,first silver medal and first bronze medal
--output columns-medal,year,sport

with cte as(select ae.medal,ae.year,ae.sport,
                    rank()over(partition by ae.medal order by ae.year) as rn
            from athletes a
            inner join athlete_events ae
            on a.id=ae.athlete_id
            where a.team='India' and ae.medal <>'NA')
select distinct medal,year,sport
from cte
where rn=1

--Players who won gold medal in summer and winter olympics both.

select a.name
from athletes a
inner join athlete_events ae
on a.id=ae.athlete_id
where ae.medal='Gold'
group by a.name
having count(distinct ae.season)=2

--Players who won gold, silver and bronze medal in a single olympics. 
--output columns- player name, year.

select a.name,ae.year
from athletes a
inner join athlete_events ae
on ae.athlete_id=a.id
where ae.medal<>'NA'
group by a.name,ae.year
having count(distinct medal)=3

--Players who have won gold medals in consecutive 3 summer olympics in the same event . Considering only olympics 2000 onwards. 
--Assuming summer olympics happens every 4 year starting 2000. 
--output columns-print player name,event name.

with cte as(select a.name,ae.year,ae.event,
				   lag(year,1)over(partition by a.name,ae.event order by year) as prev_year,
				   lead(year,1)over(partition by a.name,ae.event order by year) as next_year
			from athletes a
			inner join athlete_events ae
			on a.id=ae.athlete_id
			where ae.medal='Gold' and ae.year>=2000 and ae.season='Summer')
select name,event,prev_year,year,next_year
from cte
where year=prev_year+4 and year=next_year-4


