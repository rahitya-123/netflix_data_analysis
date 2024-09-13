---handling foreign characters
SELECT *
FROM netflix_raw
WHERE show_id = 's5023';

---remove dupliactes
SELECT show_id
	, count(*)
FROM netflix_raw
GROUP BY show_id
HAVING count(*) > 1;--- no duplicates interms of show_id

SELECT *
FROM netflix_raw
WHERE CONCAT (
		upper(title)
		, type
		) IN (
		SELECT CONCAT (
				upper(title)
				, type
				)
		FROM netflix_raw
		GROUP BY CONCAT (
				upper(title)
				, type
				)
		HAVING count(*) > 1
		)
ORDER BY title;-- duplicates found with title and type combination

WITH cte
AS (
	SELECT *
		, ROW_NUMBER() OVER (
			PARTITION BY title
			, type ORDER BY show_id
			) AS rn
	FROM netflix_raw
	)
SELECT *
FROM cte
WHERE rn = 1;

---new table for listed in,director,cast,country
SELECT show_id
	, trim(value) AS genre
INTO netflix_genre
FROM netflix_raw
CROSS APPLY string_split(listed_in, ',');

SELECT *
FROM netflix_genre;


---date type conversions for dates,remove nulls in duration column

select * from netflix_raw;
select * from netflix_raw where duration is null;

WITH cte
AS (
	SELECT *
		, ROW_NUMBER() OVER (
			PARTITION BY title
			, type ORDER BY show_id
			) AS rn
	FROM netflix_raw
	)
SELECT show_id
	, type
	, title
	, cast(date_added AS DATE) AS date_added
	, release_year
	, rating
	, CASE 
		WHEN duration IS NULL
			THEN rating
		ELSE duration
		END AS duration
	, description
INTO netflix_stg
FROM cte
WHERE rn = 1;


select * from netflix_stg;

---populate missing values in country column

INSERT INTO netflix_country
SELECT show_id
	, m.country
FROM netflix_raw nr
INNER JOIN (
	SELECT director
		, country
	FROM netflix_directors nd
	INNER JOIN netflix_country nc ON nd.show_id = nc.show_id
	) m ON nr.director = m.director
WHERE nr.country IS NULL;


/* 1.For each director count the no of movies and tv shows created by them in seperate columns 
for directors who have created tv shows and movies both*/
SELECT nd.director AS director
	, count(DISTINCT CASE 
			WHEN n.type = 'movie'
				THEN n.show_id
			END) AS no_of_movies
	, count(DISTINCT CASE 
			WHEN n.type = 'TV Show'
				THEN n.show_id
			END) AS no_of_tv_shows
FROM netflix_stg n
INNER JOIN netflix_directors nd ON n.show_id = nd.show_id
GROUP BY nd.director
HAVING count(DISTINCT n.type) > 1;


--- 2.which country has highest number of comedy movies
SELECT TOP 1 nc.country
	, count(DISTINCT ng.show_id) AS no_of_movies
FROM netflix_genre ng
INNER JOIN netflix_country nc ON ng.show_id = nc.show_id
INNER JOIN netflix_stg n ON ng.show_id = n.show_id
WHERE ng.genre = 'Comedies'
	AND n.type = 'Movie'
GROUP BY nc.country
ORDER BY no_of_movies DESC;


--- 3.for each year (as per date added to netflix), which director has maximum no of movies released
WITH cte
AS (
	SELECT YEAR(date_added) AS date_year
		, nd.director
		, count(n.show_id) AS no_of_movies
	FROM netflix_stg n
	INNER JOIN netflix_directors nd ON n.show_id = nd.show_id
	WHERE n.type = 'movie'
	GROUP BY YEAR(date_added)
		, nd.director
	)
	, cte2
AS (
	SELECT *
		, ROW_NUMBER() OVER (
			PARTITION BY date_year ORDER BY no_of_movies DESC
				, director
			) AS rn
	FROM cte
	)
SELECT *
FROM cte2
WHERE rn = 1;


---4.what is average duration of movies in each genre
SELECT ng.genre
	, avg(cast(REPLACE(duration, 'min', '') AS INT)) AS avg_duration
FROM netflix_stg n
INNER JOIN netflix_genre ng ON n.show_id = ng.show_id
WHERE n.type = 'movie'
GROUP BY ng.genre;


/* 5.find the list of directors who have created both horror and comedy movies.display director names along with no of comedy
and horror movies directed  by them */
SELECT nd.director
	, count(DISTINCT CASE 
			WHEN ng.genre = 'comedies'
				THEN n.show_id
			END) AS no_of_comedies
	, count(DISTINCT CASE 
			WHEN ng.genre = 'horror_movies'
				THEN n.show_id
			END) AS no_of_horrors
FROM netflix_stg n
INNER JOIN netflix_genre ng ON n.show_id = ng.show_id
INNER JOIN netflix_directors nd ON n.show_id = nd.show_id
WHERE n.type = 'movie'
	AND ng.genre IN (
		'comedies'
		, 'horror movies'
		)
GROUP BY nd.director
HAVING COUNT(DISTINCT ng.genre) = 2;


