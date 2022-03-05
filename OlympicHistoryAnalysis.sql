                                      -- Olympic analysis -- 
select * from olympic_history
select * from noc_regions

-- How many olympics games have been held?

select count(distinct games) as Total_Olympic_Games 
from olympic_history

-- List down all Olympics games held so far

select distinct YEAR, Season, city
from Olympic_History 
order by year

-- Mention the total no of nations who participated in each olympics game?

select games,count(distinct nr.region) as Countries_Participated 
from olympic_history oh
join noc_regions nr
on oh.noc = nr.noc
group by games
order by games

-- Which year saw the highest and lowest no of countries participating in olympics

with tot_countries as 
	(select games,count(distinct nr.region) as Countries_Participated 
	from olympic_history oh
	join noc_regions nr
	on oh.noc = nr.noc
	group by games)

select  distinct
	concat(FIRST_VALUE(games) over(order by Countries_Participated),
	'-', FIRST_VALUE(Countries_Participated) over(order by Countries_Participated)) as Lowest_Countries,
	CONCAT(FIRST_VALUE(games) over(order by Countries_Participated desc),
	'-',FIRST_VALUE(Countries_Participated) over(order by Countries_Participated desc)) as Highets_Countries
	from tot_countries
	order by 1


-- Which nation has participated in all of the olympic games

select nr.region as country, count(distinct games) as total_participated_games
from olympic_history oh
join noc_regions nr
on oh.NOC = nr.NOC
group by nr.region
order by total_participated_games desc

--Identify the sport which was played in all summer olympics

with t1 as 
	(select count(distinct games) as total_summer_games
	from Olympic_History
	where Season = 'Summer'),
	t2 as 
	(select distinct sport,Games
	from Olympic_History
	where Season = 'Summer'),
	t3 as 
	(select sport,count(games) as total_games
	from t2
	group by sport)

select * from
	t3 join t1
	on t3.total_games = t1.total_summer_games

--Which sport were just played only once in the olympics.

with T1 as 
	(select distinct games,sport
	from Olympic_History
	group by games,Sport),
T2 as 
	(select sport, count(games) as no_of_games
	from T1 group by Sport)
select t2.*,t1.games
from T2
join T1
on t1.sport = t2.sport
where t2.no_of_games = 1
order by Sport

--Fetch the total no of sports played in each olympic games.

select distinct games, COUNT(distinct sport) as total_no_of_sports_played
from Olympic_History
group by games 
order by games 


--Fetch oldest athletes to win a gold medal 
with cte as 
(select *,
rank() over(order by age desc) as rk
from Olympic_History
where Medal = 'Gold')

select * from cte 
where age is not null

--Find the Ratio of male and female athletes participated in all olympic games.

with t1 as 
	(select sex,COUNT(1) as cnt
	from Olympic_History
	group by Sex),
T2 as 
	(select *, ROW_NUMBER() over(order by cnt) as rn
	from t1),
min_cnt as 
	(select cnt from T2 where rn = 1 ),
max_cnt as
	(select cnt from T2 where rn = 2 )


select CONCAT('1 :', ROUND(max_cnt.cnt::decimal/min_cnt.cnt, 2)) as ratio
from max_cnt,min_cnt

--Fetch the top 5 athletes who have won the most gold medals

with t1 as
            (select name, team, count(1) as total_gold_medals
            from olympic_history
            where medal = 'Gold'
            group by name, team),
        t2 as
            (select *, dense_rank() over (order by total_gold_medals desc) as rnk
            from t1)

 select name, team, total_gold_medals
 from t2
 where rnk <= 5;

--Fetch the top 5 athletes who have won the most medals (gold/silver/bronze)


with cte as 
	(select name,team,count(Medal) as total_medals_won 
	from Olympic_History
	where Medal in ('Gold','Silver','Bronze')
	group by name,Team,Sport),
ct as 
	(select *,ROW_NUMBER() over(order by total_medals_won desc) as rw
	from cte)


select name,team,total_medals_won 
from ct
where rw <= 5 

--Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won

with t1 as 
	(select nr.region as region, count(medal) as total_medal
	from Olympic_History oh
	join noc_regions nr
	on oh.NOC = nr.NOC
	where Medal in ('Gold','Silver','Bronze')
	group by nr.region),
	t2 as 
	(select *,row_number() over(order by total_medal desc) as rnk
	from t1)
select region,total_medal,rnk from t2
where rnk <= 5 

--List down total gold, silver and bronze medals won by each country

select country,[Gold],[Silver],[Bronze] from 
(select nr.region as Country, medal
from Olympic_History oh
join noc_regions nr
on oh.NOC = nr.NOC
where Medal <> 'NA') t
pivot(count(medal) for medal in ([Gold],[Silver],[Bronze]) ) as pvt
order by Gold,Silver,Bronze desc
