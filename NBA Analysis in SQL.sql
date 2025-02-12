-- Which are the top 10 NBA teams with the highest total wins and losses from 2019 to 2023 ?
 
select team_name, sum(wins) as total_wins,sum(losses) as total_losses
from (
 select team_name_home as team_name,
 sum(case 
          when wl_home = 'W' then 1 else 0 end) as wins ,
 sum(case 
		  when wl_home = 'L' then 1 else 0 end) as losses
 from nba.game
 where game_date between '2019-01-01' and '2023-12-31'
 group by team_name_home
 union all
 select team_name_away AS team_name,
 sum(case 
         when wl_away = 'W' then 1 else 0 end) as wins,
 sum(case 
          when wl_away = 'L' then 1 else 0 end) as losses
 from nba.game
 where game_date between '2019-01-01' and '2023-12-31'
 group by team_name_away
) as t
group by team_name
order by total_wins desc
limit 10;


-- What is the total number of wins and losses for each NBA team in each season from 2019 to 2023 ? 

select season , team_name , sum(wins) as total_wins , sum(losses) as total_losses
from (
 select season , team_name_home as team_name ,
 sum(case 
         when wl_home = 'W' then 1 else 0 end) as wins,
 sum(case 
         when wl_home = 'L' then 1 else 0 end) as losses
 from nba.game g join nba.game_summary gs
 on g.game_id = gs.game_id
 where game_date between '2019-01-01' and '2023-12-31'
 group by season , team_name_home
 union all 
 select season , team_name_away ,
 sum(case 
         when wl_away = 'W' then 1 else 0 end) as wins,
 sum(case 
         when wl_away = 'L' then 1 else 0 end) as losses
 from nba.game g join nba.game_summary gs 
 on g.game_id = gs.game_id 
 where game_date between '2019-01-01' and '2023-12-31'
 group by season , team_name_away ) as t
group by season , team_name
order by total_wins desc ;

-- Which NBA teams had the longest winning streaks in each season from 2019 to 2023?

with game_results as (
 select season,team_name,game_date,
 case 
     when wl = 'W' then 1 else 0 end as win,
 lag(case 
         when wl = 'W' then 1 else 0 end) 
         over (partition by team_name order by game_date) as prev_win
 from (
 select season,team_name_home as team_name,game_date,wl_home as wl
 from nba.game g join nba.game_summary gs 
 on g.game_id = gs.game_id
 where game_date between '2019-01-01' and '2023-12-31'
 union all
 select season,
 team_name_away as team_name,game_date,wl_away as wl
 from nba.game g join nba.game_summary gs 
 on g.game_id = gs.game_id
 where game_date between '2019-01-01' and '2023-12-31') as all_games
),
win_streaks as ( 
select season,team_name,game_date,win,
case
	when win = 1 and (prev_win = 1 or prev_win is null) then 1 else 0 end as streak_start
from game_results
),
streak_groups as (
 select season,team_name,game_date,win,streak_start,
 sum(streak_start) over (partition by team_name order by game_date) as streak_group
 from win_streaks
)
select season,team_name, max(streak_length) as longest_win_streak
from (
 select season,team_name,streak_group, count(*) as streak_length
 from streak_groups
 where win = 1
 group by season, team_name, streak_group
) as streak_lengths
group by season, team_name
order by longest_win_streak desc
limit 10;

-- Which NBA teams had the longest lossing streaks in each season from 2019 to 2023?

with game_results as (
 select season,
 team_name,game_date,
 case when wl = 'L' then 1 else 0 end as loss,
 lag(case 
         when wl = 'L' then 1 else 0 end) 
         over (partition by team_name order by game_date) as prev_loss
from (
 select season,team_name_home as team_name,game_date,wl_home as wl
 from nba.game g join nba.game_summary gs 
 on g.game_id = gs.game_id
 where game_date between '2019-01-01' and '2023-12-31'
 union all
 select season,team_name_away as team_name,game_date,wl_away as wl
 from nba.game g join nba.game_summary gs 
 on g.game_id = gs.game_id
 where game_date between '2019-01-01' and '2023-12-31') as all_games
),
loss_streaks as ( 
 select season,team_name,game_date,loss,
 case when loss = 1 and (prev_loss = 1 or prev_loss is null) then 1 else 0 end as streak_start
 from game_results
),
streak_groups as (
 select season,team_name,game_date,loss,streak_start,
 sum(streak_start) over (partition by team_name order by game_date) as streak_group
 from loss_streaks
)
select season,team_name, max(streak_length) as longest_loss_streak
from (
 select season,team_name,streak_group,count(*) as streak_length
 from streak_groups
 where loss = 1
 group by season, team_name, streak_group
) as streak_lengths
group by season, team_name
order by longest_loss_streak desc
limit 10;

-- How many players are currently active and inactive in the NBA? 

select 
 case when is_active = 0 then 'Not active' 
  else 'active' end as is_active , 
count(*) as player_count
from nba.player
group by is_active 
order by player_count desc;
 
 
 -- Who are the top 10 NBA players with the highest total personal fouls per season from 2019 to 2023 ?
 
select full_name,position,season, sum(total_personal_fouls) as total_personal_fouls
from (
 select concat(dc.first_name,' ',dc.last_name) as full_name, dc.position as position ,dh.season , 
 sum(pf_home) as total_personal_fouls
 from nba.draft_combine_stats dc join nba.draft_history dh 
 on dc.player_id = dh.person_id join nba.game g
 on dh.team_id = g.team_id_home
 where game_date between '2019-01-01' and '2023-12-31'
 group by full_name , dc.position , dh.season
 union all 
 SELECT concat(dc.first_name,' ',dc.last_name) as full_name, dc.position as position,dh.season, sum(pf_away) as total_personal_fouls
 FROM nba.draft_combine_stats dc join nba.draft_history dh 
 on dc.player_id = dh.person_id join nba.game g
 on dh.team_id = g.team_id_away
 where game_date between '2019-01-01' and '2023-12-31'
 group by full_name , dc.position ,dh.season ) e
 group by full_name , position , season
 order by total_personal_fouls desc
 limit 10;
 
 -- Who are the top 10 NBA players with the highest total points from 2019 to 2023 ?
 
 select full_name,position, sum(total_points) as total_point
 from (
 select concat(dc.first_name,' ',dc.last_name) as full_name, dc.position as position , sum(fgm_home) as total_points 
 from nba.draft_combine_stats dc join nba.draft_history dh
 on dc.player_id = dh.person_id join nba.game g 
 on dh.team_id = g.team_id_home 
 where game_date between '2019-01-01' and '2023-12-31'
 group by full_name , dc.position 
 union all 
 SELECT concat(dc.first_name,' ',dc.last_name) as full_name, dc.position as position, sum(fgm_away) as total_points 
 FROM nba.draft_combine_stats dc join nba.draft_history dh 
 on dc.player_id = dh.person_id join nba.game g 
 on dh.team_id = g.team_id_away 
 where game_date between '2019-01-01' and '2023-12-31'
 group by full_name , dc.position ) e 
 group by full_name , position 
 order by total_point desc 
 limit 10;
 
 -- How do players drafted in the first and second rounds compare in terms of total points scored in each season? 
 
select * 
from(
 select full_name, round_number, season, sum(total_points) as total_point,
 row_number() over (partition by season order by sum(total_points) desc) as ranks
from (
 select concat(dc.first_name, ' ', dc.last_name) as full_name, dh.round_number, dh.season, 
 sum(g.fgm_home) as total_points
 from nba.draft_combine_stats dc 
 join nba.draft_history dh 
 on dc.player_id = dh.person_id 
 join nba.game g on dh.team_id = g.team_id_home
 where dh.round_number in (1, 2) and game_date between '2019-01-01' and '2023-12-31'
 group by full_name, dh.round_number, dh.season
 union all
 select concat(dc.first_name, ' ', dc.last_name) as full_name, dh.round_number, dh.season, 
 sum(g.fgm_away) as total_points
 from nba.draft_combine_stats dc join nba.draft_history dh 
 on dc.player_id = dh.person_id join nba.game g 
 on dh.team_id = g.team_id_away
 where dh.round_number in (1, 2) and game_date between '2019-01-01' and '2023-12-31'
 group by full_name, dh.round_number, dh.season ) e
 group by full_name, round_number, season
) ranked
where ranks <= 10
order by season desc
limit 10;

-- How do players drafted in the first and second rounds compare in terms of total points scored in each season? 

select full_name,round_number,season,sum(total_points) as total_point
from (
 select concat(dc.first_name,' ',dc.last_name) as full_name,dh.round_number,dh.season, 
 sum(fgm_home) as total_points
 from nba.draft_combine_stats dc join nba.draft_history dh 
 on dc.player_id = dh.person_id join nba.game g
 on dh.team_id = g.team_id_home
 where dh.round_number in (1,2) and game_date between '2019-01-01' and '2023-12-31'
 group by full_name , dh.round_number , dh.season
 union all 
 select concat(dc.first_name,' ',dc.last_name) as full_name,dh.round_number,dh.season, 
 sum(fgm_away) as total_points
 FROM nba.draft_combine_stats dc join nba.draft_history dh 
 on dc.player_id = dh.person_id join nba.game g
 on dh.team_id = g.team_id_away
 where dh.round_number in (1,2) and game_date between '2019-01-01' and '2023-12-31'
 group by full_name , dh.round_number , dh.season ) e
 group by full_name , round_number , season
 order by total_point desc 
 limit 10;





