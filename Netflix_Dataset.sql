-- ------ Netflix Portfolio --------------

create database netflix_db;

-- ------- Table Creation ----------------
drop table if exists netflix;
-- ---------------------------------
TRUNCATE TABLE netflix;
-- -----------------------------------
create table netflix (
	show_id varchar(20) primary key,
    type varchar(20) not null,
    Title varchar(100) not null, 
    Director varchar(210) not null,
    casting varchar(1000) not null,
    country varchar(150) not null, 
    date_added varchar(50) not null,
    release_year int not null,
    rating varchar(50) not null, 
    duration varchar(50) not null,
    listed_in varchar(200) not null,
    description varchar (250) not null
);

-- adding primary key -------------------------

alter table netflix 
add constraint adding_primarykey primary key (show_id);
-- -----------------------------------------------
Select * from netflix;

-- -----------------------------------------------------
select count(*) from netflix;
select distinct type from netflix;

-- ____________________________________________________________________________________

-- 1. Count the number of Movies vs TV Shows
-- ____________________________________________________________________________________

select type , count(*) from netflix
group by type;

-- ____________________________________________________________________________________

-- 2. Find the most common rating for movies and TV shows
-- ___________________________________________________________________________________

-- involves grouping the columns and make a ranking 
-- based on orderby and conversion into table
select type, rating from
(select 
type, rating, count(*), RANK() OVER (PARTITION BY type ORDER BY count(*) desc)as ranking
from netflix 
group by type, rating) as t1
where ranking = 1;

-- ____________________________________________________________________________________
-- 3. List all movies released in a specific year (e.g., 2020)
-- ____________________________________________________________________________________

select title from netflix 
where type = 'Movie' and release_year = '2020'; 

-- ____________________________________________________________________________________

-- 4. Find the top 5 countries with the most content on Netflix
-- ___________________________________________________________________________________

WITH RECURSIVE split_countries AS (
    -- Anchor member: Get the first country before the comma
    SELECT 
        show_id, 
        TRIM(SUBSTRING_INDEX(country, ',', 1)) AS country_name,
        TRIM(SUBSTRING(country, LOCATE(',', country) + 1)) AS remaining_countries
    FROM netflix
    WHERE country LIKE '%,%' -- Only process rows with multiple countries

    UNION ALL

    -- Recursive member: Process the remaining part of the string
    SELECT 
        show_id,
        TRIM(SUBSTRING_INDEX(remaining_countries, ',', 1)) AS country_name,
        TRIM(SUBSTRING(remaining_countries, LOCATE(',', remaining_countries) + 1)) AS remaining_countries
    FROM split_countries
    WHERE remaining_countries LIKE '%,%'
)
SELECT country_name, COUNT(*) AS country_count
FROM (
    SELECT country_name
    FROM split_countries
    UNION ALL
    SELECT TRIM(country) AS country_name
    FROM netflix
    WHERE country NOT LIKE '%,%'
) AS all_countries
GROUP BY country_name
ORDER BY country_count DESC
LIMIT 5;

-- ____________________________________________________________________________________

-- 5. Identify the longest movie
-- ____________________________________________________________________________________

select * from netflix
where type= 'Movie'
and 
duration = (select max(duration) from netflix); 

-- ____________________________________________________________________________________
-- 6. Find content added in the last 5 years
-- ____________________________________________________________________________________

select 
	    *, str_to_date(date_added, '%M %d, %Y' ) as date
from netflix
where date_added <= DATE_SUB(CURDATE(), INTERVAL 5 YEAR);

-- ____________________________________________________________________________________
-- 7. Find all the movies/TV shows by director 'Rajiv Chilaka'!
-- ____________________________________________________________________________________

select title, Director from netflix
where type = 'Movie' and Director like '%K.S. Ravikumar%' ; 

-- ____________________________________________________________________________________
-- 8. List all TV shows with more than 5 seasons
-- ____________________________________________________________________________________
   select duration,  Type from netflix
   where type = 'TV Show' and CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) > 5;  
-- ____________________________________________________________________________________
-- 9. Count the number of content items in each genre
-- ____________________________________________________________________________________
WITH RECURSIVE split_listings AS (
    -- Anchor member: Get the first country before the comma
    SELECT 
        show_id, 
        TRIM(SUBSTRING_INDEX(listed_in , ',', 1)) AS listed_in,
        TRIM(SUBSTRING(listed_in, LOCATE(',', listed_in) + 1)) AS remaining_lists
    FROM netflix
    WHERE listed_in LIKE '%,%'-- Only process rows with multiple countries

    UNION ALL

    -- Recursive member: Process the remaining part of the string
    SELECT 
        show_id,
        TRIM(SUBSTRING_INDEX(remaining_lists, ',', 1)) AS listed_in,
        TRIM(SUBSTRING(remaining_lists, LOCATE(',', remaining_lists) + 1)) AS remaining_lists
    FROM split_listings
    WHERE remaining_lists LIKE '%,%'
)
SELECT listed_in, COUNT(*) AS list_count
FROM (
    SELECT listed_in
    FROM split_listings
    UNION ALL
    SELECT TRIM(country) AS listed_in
    FROM netflix
    WHERE listed_in NOT LIKE '%,%'
) AS all_lists
GROUP BY listed_in
ORDER BY list_count DESC;

-- ____________________________________________________________________________________
-- 10.Find each year and the average numbers of content release in India on netflix.return top 5 year with highest avg content release!
-- ____________________________________________________________________________________
select year(str_to_date(date_added, '%M %d, %Y' )) as date_new, 
count(*),
count(*)/ (select count(*) from netflix where country = 'India')* 100 as avg_content_per_year
from netflix 
where country like '%India%'
group by date_new; 
 -- ____________________________________________________________________________________
-- 11. List all movies that are documentaries
-- ____________________________________________________________________________________

 select * from netflix 
 where listed_in like '%Documentaries%';
 
 -- ____________________________________________________________________________________
-- 12. Find all content without a director
-- ____________________________________________________________________________________

select * from netflix
where Director = '' ;

-- ____________________________________________________________________________________
-- 13. Find how many movies actor 'Salman Khan' appeared in last 10 years!
-- ____________________________________________________________________________________

select * from netflix 
where lower(casting) like lower('%S%') and release_year > year(current_date())-10; 

-- -----------------------------------------------------------------------------------------
-- 14. Find the top 10 actors who have appeared in the 
-- highest number of movies produced in India.
-- ------------------------------------------------------------------------------------------
with recursive new_netflix_split as (
	select country, type,
	trim(substring_index(casting, ',', 1)) as actor,
	substring_index(casting, ',', 1) as other_actor
	from netflix

	union all

	select country, type,
	trim(substring_index(other_actor, ',', 1)) as actor,
	case
		WHEN other_actor LIKE '%,%' THEN SUBSTRING_INDEX(other_actor, ',', -1)
		ELSE NULL
	END
from new_netflix_split
where other_actor is not null
)

select country, count(type), actor from new_netflix_split
where country = 'India' 
group by actor
order by count(type) desc
limit  2;

-- ----------------------------------------------------------------------
 /*15.
Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
the description field. Label content containing these keywords as 'Bad' and all other 
content as 'Good'. Count how many items fall into each category. */
-- -------------------------------------------------------------------
with new_table as
(
select 
    * ,
	case 
    when 
    lower(description) like lower('%kill%') or 
    lower(description) like lower('%violence%') then 'Bad_Content'
    else 'Good_content'
    end category
	from netflix
    )
    
    select category, count(*) as total from new_table
    group by category ;

-- --------------------------------------------------------------------

