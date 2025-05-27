/*
There are 2 csv files present in this zip file. The data contains 120 years of olympics history. 
There are 2 datasets 
1- athletes : it has information about all the players participated in olympics
2- athlete_events : it has information about all the events happened over the year.
(athlete id refers to the id column in athlete table)
*/

/*
import these datasets in sql server and solve below problems:
*/

CREATE DATABASE olympic;
USE olympic;

# Executed athletes sql file for creating table
# Used table import wizard for athletes_events

SELECT * FROM athletes;
SELECT * FROM athlete_events;

/*
--1 which team has won the maximum gold medals over the years.
*/

SELECT 
	a.team, count(*) AS gold_count
FROM 
	athletes a
JOIN 
	athlete_events ae ON a.id = ae.athlete_id
WHERE 
	ae.medal = 'Gold'
GROUP BY 
	a.team
ORDER BY 
	gold_count DESC
LIMIT 1;


/*
--2 for each team print total silver medals and year in which they won maximum silver medal..output 3 columns
-- team,total_silver_medals, year_of_max_silver
*/

WITH total_silver AS (
	SELECT a.team,
        COUNT(*) AS total_silver_medals
    FROM
        athletes a
    JOIN
        athlete_events ae ON a.id = ae.athlete_id
    WHERE
        ae.medal = 'Silver'
    GROUP BY
        a.team
),
silver_by_year AS (
    SELECT 
        a.team,
        ae.year,
        COUNT(*) AS silver_count
    FROM 
        athletes a
    JOIN 
        athlete_events ae on a.id = ae.athlete_id
    WHERE 
        ae.medal = 'Silver'
    GROUP BY 
        a.team, ae.year
),
max_silver_year AS (
    SELECT 
        team,
        year AS year_of_max_silver
    FROM (
        SELECT 
            team, year, 
            RANK() OVER (PARTITION BY team ORDER BY silver_count DESC) AS rnk
        FROM silver_by_year
    ) ranked
    WHERE rnk = 1
)
SELECT 
    ts.team,
    ts.total_silver_medals,
    msy.year_of_max_silver
FROM 
    total_silver ts
JOIN 
    max_silver_year msy ON ts.team = msy.team
ORDER BY 
    ts.total_silver_medals DESC;


/*
--3 which player has won maximum gold medals  amongst the players 
--which have won only gold medal (never won silver or bronze) over the years
*/

WITH only_gold_winners AS (
  SELECT athlete_id
  FROM athlete_events
  WHERE medal IS NOT NULL
  GROUP BY athlete_id
  HAVING 
    SUM(medal = 'Silver') = 0 AND 
    SUM(medal = 'Bronze') = 0 AND 
    SUM(medal = 'Gold') > 0
),

gold_counts AS (
  SELECT 
    ae.athlete_id,
    a.name,
    COUNT(*) AS gold_medal_count
  FROM athlete_events ae
  JOIN athletes a ON ae.athlete_id = a.id
  WHERE ae.medal = 'Gold'
    AND ae.athlete_id IN (SELECT athlete_id FROM only_gold_winners)
  GROUP BY ae.athlete_id, a.name
)

SELECT 
  name, 
  gold_medal_count
FROM gold_counts
ORDER BY gold_medal_count DESC
;




/*
--4 in each year which player has won maximum gold medal . Write a query to print year,player name 
--and no of golds won in that year . In case of a tie print comma separated player names.
*/

WITH gold_per_year AS (
	SELECT ae.year, a.name, count(*) as gold_count
	FROM athletes a
	JOIN athlete_events ae on a.id = ae.athlete_id
	WHERE ae.medal = 'Gold'
	GROUP BY ae.year, a.name
),
ranked_gold AS (
	SELECT *,
    RANK () OVER (PARTITION BY year ORDER BY gold_count DESC) AS rnk
    FROM gold_per_year
    )
SELECT
	year, group_concat(name ORDER BY name) as top_players,
	max(gold_count) AS golds_won
FROM 
	ranked_gold
WHERE 
	rnk = 1
GROUP BY year
ORDER BY year;


/*
--5 in which event and year India has won its first gold medal,first silver medal and first bronze medal
--print 3 columns medal,year,sport
*/

WITH first_gold AS (
	SELECT ae.medal, ae.year AS first_year, ae.sport
	FROM athlete_events ae 
	JOIN athletes a ON a.id = ae.athlete_id
	WHERE a.team = 'India' AND ae.medal = 'Gold'
	GROUP BY ae.medal, ae.year, ae.sport
	ORDER BY ae.year 
	LIMIT 1
),
first_silver AS (
	SELECT ae.medal, ae.year as first_year, ae.sport
	FROM athlete_events ae 
	JOIN athletes a on a.id = ae.athlete_id
	WHERE a.team = 'India' and ae.medal = 'Silver'
	GROUP BY ae.medal, ae.year, ae.sport
	ORDER BY ae.year 
	LIMIT 1
),
first_bronze AS (
	SELECT ae.medal, ae.year AS first_year, ae.sport
	FROM athlete_events ae 
	JOIN athletes a ON a.id = ae.athlete_id
	WHERE a.team = 'India' AND ae.medal = 'Bronze'
	GROUP BY ae.medal, ae.year, ae.sport
	ORDER BY ae.year 
	LIMIT 1
)
SELECT * FROM first_gold
UNION ALL
SELECT * FROM first_silver
UNION ALL
SELECT * FROM first_bronze
;

/*
ALTERNATE

SELECT 
  medal,
  year AS first_year,
  sport
FROM (
  SELECT 
    ae.medal,
    ae.year,
    ae.sport,
    ROW_NUMBER() OVER (PARTITION BY ae.medal ORDER BY ae.year) AS rn
  FROM 
    athlete_events ae
  JOIN 
    athletes a ON ae.athlete_id = a.id
  WHERE 
    a.team = 'India' 
    AND ae.medal IS NOT NULL
) ranked_medals
WHERE rn = 1
ORDER BY 
  CASE 
    WHEN medal = 'Gold' THEN 1
    WHEN medal = 'Silver' THEN 2
    WHEN medal = 'Bronze' THEN 3
  END;
*/

/*
--6 find players who won gold medal in summer and winter olympics both.
*/


SELECT
	a.name
FROM
	athletes a
JOIN
	athlete_events ae ON a.id = ae.athlete_id
WHERE
    ae.medal = 'Gold'
GROUP BY
    a.id, a.name
HAVING
    COUNT(DISTINCT CASE WHEN ae.season = 'Summer' THEN 1 END) > 0
	AND COUNT(DISTINCT CASE WHEN ae.season = 'Winter' THEN 1 END) > 0 ;


/*
--7 find players who won gold, silver and bronze medal in a single olympics. print player name along with year.
*/

SELECT
	a.name, ae.year
FROM
	athletes a
JOIN
	athlete_events ae on a.id = ae.athlete_id
WHERE
	ae.medal IN ('Gold', 'Silver', 'Bronze')
GROUP BY
	a.id, a.name, ae.year
HAVING
	COUNT(DISTINCT CASE WHEN ae.medal = 'Gold' THEN 'Gold' END) > 0 
    AND COUNT(DISTINCT CASE WHEN ae.medal = 'Silver' THEN 'Silver' END) > 0
    AND COUNT(DISTINCT CASE WHEN ae.medal = 'Bronze' THEN 'Bronze' END) > 0;


/*
--8 find players who have won gold medals in consecutive 3 summer olympics in the same event .
 Consider only olympics 2000 onwards. 
--Assume summer olympics happens every 4 year starting 2000. print player name and event name.
*/

WITH filtered_data AS (
	SELECT
		a.name, ae.event, ae.year
    FROM
		athletes a 
    JOIN
		athlete_events ae on a.id = ae.athlete_id
    WHERE
		ae.medal = 'Gold' AND
        ae.season = 'Summer' AND
        ae.year >= 2000
),
row_ranks AS (
	SELECT name, event, year,
    ROW_NUMBER() OVER (PARTITION BY name, event ORDER BY year) AS rnk
    FROM filtered_data
),
grouped AS (
	SELECT name, event, year, rnk,
    year - rnk * 4 AS grp
    FROM row_ranks
),
consecutive AS (
	SELECT name, event, count(*) AS cnt
    FROM grouped
    GROUP BY name, event, grp
    HAVING COUNT(*) >= 3
)
SELECT name, event
FROM consecutive;
