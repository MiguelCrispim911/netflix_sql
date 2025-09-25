
CREATE TABLE netflix
(
show_id VARCHAR(20),
tipo VARCHAR(15),
title VARCHAR(110),
director VARCHAR(250),
casts VARCHAR(1000),
country VARCHAR(150),
date_added VARCHAR(20),
release_year	INT,
rating VARCHAR(30),
duration VARCHAR(150),
listed_in VARCHAR(80),
descriptions VARCHAR(300)
);

SHOW VARIABLES LIKE 'local_infile';

SET GLOBAL local_infile=1;

SELECT * FROM netflix;
-- Total de filas
SELECT
	COUNT(*) AS total_content
FROM netflix;

-- Verificar cuantos tipos diferentes existen

SELECT
	DISTINCT tipo
FROM netflix;

-- 15 problemas de negocios

-- 1. Count the number of movies and number of TV shows

SELECT * FROM netflix;

SELECT
	tipo, 
	COUNT(*) AS total_content
FROM netflix
GROUP BY tipo;


-- 2 Find the most common rating for movies and TV shows
SELECT * FROM netflix

SELECT
	tipo,
	rating
FROM 
(SELECT 
    tipo,
    rating,
    cantidad,
    RANK() OVER (PARTITION BY tipo ORDER BY cantidad DESC) AS ranking
FROM 
(
    SELECT 
        tipo,
        rating,
        COUNT(*) AS cantidad
    FROM netflix
    GROUP BY tipo, rating
) AS sub
) AS t1
WHERE
	ranking =1;



-- 3 List all movies released in a specific year (e.g., 2020)


SELECT * FROM netflix
WHERE 
	tipo='Movie'
	AND
	release_year= 2020;
	

-- 4 Find the top five countries with the most contnt in netflix
-- Note that some rows have more than 1 country
SELECT 
    TRIM(country_split) AS new_country,
    COUNT(n.show_id) AS total_content
FROM netflix n
JOIN JSON_TABLE(
        CONCAT('["', REPLACE(n.country, ',', '","'), '"]'),
        '$[*]' COLUMNS(country_split VARCHAR(255) PATH '$')
    ) AS jt
    ON 1=1
WHERE TRIM(country_split) <> '' 
  AND country_split IS NOT NULL
GROUP BY new_country
ORDER BY total_content DESC
LIMIT 5;



-- 5 Identify the longest movie


SELECT 
    title,
    CAST(REPLACE(duration, ' min', '') AS UNSIGNED) AS new_duration
FROM netflix
WHERE tipo = 'Movie'
  AND duration LIKE '%min'
  AND CAST(REPLACE(duration, ' min', '') AS UNSIGNED) = (
        SELECT MAX(CAST(REPLACE(duration, ' min', '') AS UNSIGNED))
        FROM netflix
        WHERE tipo = 'Movie'
          AND duration LIKE '%min'
  );



-- 6 Find content added in the last 5 years

SELECT *
FROM netflix
WHERE STR_TO_DATE(TRIM(date_added), '%M %e, %Y') >= DATE_SUB(CURDATE(), INTERVAL 5 YEAR);


-- 7 Find all the movies/TV shows by director 'Rajiv Chilaka':


SELECT * FROM netflix
WHERE LOWER(director) LIKE '%rajiv chilaka%'


-- 8 LIs all TV Shows with more than 5 seasons

SELECT 
    *,
    CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) AS new_duration
FROM netflix
WHERE tipo = 'TV Show'
  AND CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) > 5;
  
  
-- 9 Count the number of content items in each gender

SELECT 
    TRIM(genre) AS genre,
    COUNT(*) AS total_content
FROM netflix n
JOIN JSON_TABLE(
        CONCAT('["', REPLACE(n.listed_in, ',', '","'), '"]'),
        '$[*]' COLUMNS(genre VARCHAR(255) PATH '$')
    ) AS jt
    ON 1=1
WHERE TRIM(genre) <> '' 
  AND genre IS NOT NULL
GROUP BY genre
ORDER BY total_content DESC;


-- 10 Find each year and the avarage numbers of content release by India on netflix.
-- return top 5 year with highest avg content release


SELECT 
    YEAR(STR_TO_DATE(date_added, '%M %d, %Y')) AS ano,
    COUNT(*) AS yearly_content,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM netflix WHERE country = 'India')),2) AS abf_content_per_year
FROM netflix
WHERE country = 'India'
GROUP BY ano


-- 11 List all movies that are documentaries


SELECT * FROM netflix
WHERE
	LOWER(listed_in) LIKE '%documentaries%'
	
	
-- 12 Find all the content without a director
-- NOTE THAT in POstgreSQL would be is NULL
SELECT * FROM netflix
WHERE
	director =''

-- 13  Find how many movies the actor 'Salman Khan' appeared on in the last 10 years

SELECT * FROM netflix
WHERE
	LOWER(casts) LIKE '%Salman Khan%'
	AND
	release_year > EXTRACT(YEAR FROM CURRENT_DATE) - 10
	

-- 14  Find the top 10 actors who have appeared in the highest number of movies produce in India

WITH RECURSIVE actor_split AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(casts, ',', 1)) AS actor,
        SUBSTRING(casts, LENGTH(SUBSTRING_INDEX(casts, ',', 1)) + 2) AS rest
    FROM netflix
    WHERE LOWER(country) LIKE '%india%'
    
    UNION ALL
    
    SELECT
        TRIM(SUBSTRING_INDEX(rest, ',', 1)) AS actor,
        SUBSTRING(rest, LENGTH(SUBSTRING_INDEX(rest, ',', 1)) + 2)
    FROM actor_split
    WHERE rest <> ''
)
SELECT 
    actor,
    COUNT(*) AS total_content
FROM actor_split
WHERE actor <> ''
GROUP BY actor
ORDER BY total_content DESC
LIMIT 10;


-- 15 Categorize the content based on the oresebce if the keyword 'kill' and 'violence' in the
-- description field. Label content containonf these words as 'Bad' and all other content
-- as 'Good'. COunt how many items fall into each category.


WITH NEW_table
AS
(
SELECT 
	*, 
	CASE
	WHEN 
		LOWER(descriptions) LIKE '%kill%' OR
		LOWER(descriptions) LIKE '%violence%' THEN 'Bad_Content'
		ELSE 'Good Content'
	END category
FROM netflix
)
SELECT
	category,
	COUNT(*) AS total_content
FROM new_table
GROUP BY 1
