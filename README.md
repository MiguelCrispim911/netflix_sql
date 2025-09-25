# Netflix MOvies and TV Shows Data analysis using MySQL


![Netflix Logo](https://github.com/MiguelCrispim911/netflix_sql/blob/main/Netflix-Logo.jpg)

## Overview
This project presents a detailed analysis of Netflix’s movies and TV shows catalog using SQL. The main goal is to extract valuable insights and answer different business-related questions based on the dataset. This document outlines the objectives, business problems, solutions, as well as the findings and overall conclusions of the project.

## Objectives
- Examine the distribution of content between movies and TV shows.
- Identify the most common age ratings for each type of content.
- Analyze titles by release year, country of origin, and duration.
- Explore and classify content based on specific criteria and keywords.

## Dataset
The dataset used for this project was obtained from Kaggle.

## Schema
A netflix table was created containing columns such as: show_id, tipo, title, director, casts, country, date_added, release_year, rating, duration, listed genres, and descriptions.


<pre> CREATE TABLE netflix
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
</pre>

## Business Problems and Solutions

### 1. Determine how many titles are movies versus TV shows.
<pre>
SELECT
	tipo, 
	COUNT(*) AS total_content
FROM netflix
GROUP BY tipo;
</pre>

### 2. Identify the most frequent rating for each type of content.
<pre>
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
</pre>
### 3. Retrieve all movies released in a specific year.
<pre>
SELECT * FROM netflix
WHERE 
	tipo='Movie'
	AND
	release_year= 2020;
</pre>
### 4. Find the top 5 countries with the largest number of titles available on Netflix.
<pre>
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
</pre>
### 5. Identify the longest movie in terms of duration.
<pre>
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
</pre>
### 6. List all content added to Netflix within the last 5 years.

<pre>
SELECT *
FROM netflix
WHERE STR_TO_DATE(TRIM(date_added), '%M %e, %Y') >= DATE_SUB(CURDATE(), INTERVAL 5 YEAR);
</pre>

### 7. Filter content directed by a specific person (e.g., Rajiv Chilaka).

<pre>
SELECT * FROM netflix
WHERE LOWER(director) LIKE '%rajiv chilaka%'
</pre>
	
### 8. List TV shows with more than 5 seasons.

<pre>
SELECT 
    *,
    CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) AS new_duration
FROM netflix
WHERE tipo = 'TV Show'
  AND CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) > 5;
</pre>	
	
### 9. Count the number of titles in each available genre.

<pre>
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
</pre>

	
### 10. Analyze India’s yearly releases and return the 5 years with the highest average release ratio.
<pre>
SELECT 
    YEAR(STR_TO_DATE(date_added, '%M %d, %Y')) AS ano,
    COUNT(*) AS yearly_content,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM netflix WHERE country = 'India')),2) AS abf_content_per_year
FROM netflix
WHERE country = 'India'
GROUP BY ano
</pre>

### 11. Retrieve all movies categorized as documentaries.

<pre>
SELECT * FROM netflix
WHERE
	LOWER(listed_in) LIKE '%documentaries%'
	
	
-- 12 Find all the content without a director
-- NOTE THAT in POstgreSQL would be is NULL
SELECT * FROM netflix
WHERE
	director =''
</pre>

### 12. Identify all content without a director assigned.

<pre>
SELECT * FROM netflix
WHERE
	director =''

### 13. Find how many movies actor Salman Khan appeared in during the last 10 years.

SELECT * FROM netflix
WHERE
	LOWER(casts) LIKE '%Salman Khan%'
	AND
	release_year > EXTRACT(YEAR FROM CURRENT_DATE) - 10
</pre>

### 14. List the top 10 actors who appeared in the highest number of Indian-produced movies.

<pre>
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
</pre>

### 15. Categorize content based on whether the description includes keywords like kill or violence.
<pre>
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
</pre>pre>

## Findings and Conclusion

- Content distribution: The dataset shows a diverse balance between movies and TV shows, covering a wide variety of genres and ratings.
- Ratings insights: Identifying the most frequent ratings helps understand the primary target audience of Netflix’s content.
- Geographic patterns: The analysis highlights the countries with the largest content contributions, with India being a strong contributor.
- Content categorization: Using keyword-based classification provides insights into the tone and nature of the available titles.

Conclusion: This analysis provides a comprehensive overview of Netflix’s catalog. The findings can help guide decisions on content acquisition, strategy, and audience targeting.
