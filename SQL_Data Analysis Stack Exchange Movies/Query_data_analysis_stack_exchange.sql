-- BASIC ANALYSIS
	-- 1. How many posts were each year?
SELECT
	year(CreationDate),
	count(Id) AS TotalofPost
FROM posts p 
GROUP BY year(CreationDate)

	-- 2. How many votes were made on each day of the week (Sunday, Monday, Tuesday, etc.)?
-- Opt.1-MySQL:
SELECT
	dayname(CreationDate) AS Dayofname,
	count(DISTINCT id) AS TotalofVote
FROM votes v 
GROUP BY dayname(CreationDate)
ORDER BY dayofweek(CreationDate) 

-- Opt.2-SQLSever:
SELECT
	datename(weekday, CreationDate) AS Dayofname,
	count(DISTINCT Id) AS TotalofVote
FROM votes v
GROUP BY datename(weekday, CreationDate)

	-- 3. List all comments created on September 19th, 2012
-- Opt.1:
SELECT
	*
FROM comments c
WHERE 
	cast(CreationDate AS date) = '2012-09-19'

-- Opt.2:
SELECT
	*
FROM comments c
WHERE 
	datediff(day, '2012-09-19', CreationDate) = 0

	-- 4. List all users under the age of 33, living in London
SELECT
	*
FROM users u
WHERE
	Age < 33
	AND Location LIKE '%London%'

-- ADVANCED ANALYSIS
	-- 1. Display the number of votes for each post title
SELECT
	Title,
	count(v.Id) AS TotalofVote
FROM posts p
INNER JOIN votes v
ON p.Id = v.Postid
GROUP BY Title

	-- 2. Display posts with comments created by users living in the same location as the post creator
-- Opt.1:
WITH User_post AS
(SELECT
	p.Id AS Post_ID,
	p.Title AS Post_title,
	p.OwnerUserID AS Post_by,
	u1.location AS Creator_location
FROM posts p
INNER JOIN users u1
ON p.OwnerUserID = u1.Id
), User_comment AS
(SELECT
	c.PostID AS Post_ID,
	c.Id AS Comment_id,
	c.`Text` AS Comment,
	c.UserID AS Comment_by,
	u2.location AS Commentor_location
FROM comments c
INNER JOIN users u2
ON c.UserId = u2.Id
)
SELECT
	*
FROM User_post up
INNER JOIN User_comment uc
ON up.Post_ID = uc.Post_ID
WHERE
	Creator_location = Commentor_location
	
-- Opt.2:
SELECT p.Id AS post_id,
       p.Title AS post_title,
       p.OwnerUserID AS created_by_user,
       u_p.Id AS user_id, 
       u_p.location AS creator_location,
       c.UserId AS commentor_id,
       u_c.location AS commentor_location
FROM posts p JOIN users u_p 
ON   p.OwnerUserID = u_p.Id
               JOIN comments c
ON   c.postId = p.Id
               JOIN users u_c
ON   c.UserID = u_c.Id
WHERE u_c.location = u_p.location

	-- 3. How many users have never voted?
-- Opt.1:
SELECT
	count(*) AS TotalofUser
FROM users u
WHERE
	Id NOT IN (SELECT 
					UserId
				FROM votes v)

-- Opt.2:
WITH No_vote AS 
    (
    SELECT id FROM users
    EXCEPT -- Get record from table a and discard from table b
    SELECT userID FROM votes  
    )
SELECT count(*) AS TotalofUser
FROM No_vote	

	-- 4. Display all posts having the highest amount of comments
WITH Rank_comment AS
(
SELECT
	PostId,
	count(Id) AS TotalofComment,
	DENSE_RANK() OVER(ORDER BY count(Id) DESC) AS _Rank
FROM comments c
GROUP BY PostId
)
SELECT
	Title
FROM posts p
INNER JOIN Rank_comment r
ON p.Id = r.PostId
WHERE _Rank = 1


-- If display the second-highest amount of comments 
WITH Top_comment AS
(
    SELECT  Title, 
            COUNT(*) AS number_of_comments , 
            DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS comment_count_ranking
    FROM posts p JOIN comments c
    ON   p.id = c.postid
    GROUP BY Title
    )
SELECT Title 
FROM Top_comment
WHERE comment_count_ranking = 2

	-- 5. For each post, how many votes are coming from users living in Canada ? What’s their percentage of the total number of votes (option)
-- Opt.1:
SELECT
	TB2.PostId,
	TotalofVote_Canada,
	TotalofVote_All,
	ROUND(TotalofVote_Canada/TotalofVote_All*100,2) AS PercentVote
FROM 
	(SELECT
		PostId,
		count(UserId) AS TotalofVote_Canada
	FROM votes v
	INNER JOIN users u
	ON v.UserId = u.Id
	WHERE
		Location LIKE '%Canada%'
	GROUP BY PostId) AS TB1
INNER JOIN (SELECT
				PostId,
				count(UserId) AS TotalofVote_All
			FROM votes v
			GROUP BY PostId) AS TB2
ON TB1.PostId = TB2.PostId

-- Opt.2:
SELECT
	PostId,
	sum(CASE WHEN Location LIKE '%Canada%' THEN 1
	ELSE 0 END) AS Vote_from_Canada,
	count(UserId) AS Total_Vote,
	round(sum(CASE WHEN Location LIKE '%Canada%' THEN 1
	ELSE 0 END)/count(UserId)*100,2) AS Percent_Vote
FROM votes v
INNER JOIN users u
ON v.UserId = u.Id
GROUP BY PostId

	-- 6. How many hours in average, it takes to the first comment to be posted after a creation of a new post (option)
-- Opt.1:
WITH first_comment AS
(SELECT
	*
FROM (SELECT
		*,
		DENSE_RANK() OVER(PARTITION BY PostId ORDER BY CreationDate) as _Num
	FROM comments c) AS TB3
WHERE
	_Num = 1)
SELECT
	avg(hour(timediff(f.CreationDate,p.CreationDate))) AS AvgHour
FROM posts p
INNER JOIN first_comment f
ON p.Id = f.PostId

-- Opt.2-SQL server:
WITH first_comment AS
(SELECT
	*
FROM (SELECT
		*,
		DENSE_RANK() OVER(PARTITION BY PostId ORDER BY CreationDate) as _Num
	FROM comments c) AS TB3
WHERE
	_Num = 1)
SELECT
	avg(datediff(hour, p.CreationDate, f.CreationDate)) AS AvgHour
FROM posts p
INNER JOIN first_comment f
ON p.Id = f.PostId

-- Opt.3:
WITH comment_timming AS
(SELECT 
	c.PostId,
	p.CreationDate AS post_create_date,
	c.Id,
	c.CreationDate AS comment_create_date,
	ROW_NUMBER() OVER(PARTITION BY c.PostId ORDER BY c.CreationDate) as _Num
FROM posts p
INNER JOIN comments c
ON p.Id = c.PostId)
SELECT
	avg(datediff(hour, post_create_date, comment_create_date)) AS AvgHour
FROM comment_timming
WHERE
	_Num = 1

	-- 7. What's the most common post tag? (option)
-- Opt.1-MySQL:
WITH Tb_Tag AS 
(SELECT
	Id,
	substring_index(substring_index(Tags, '<', numbers.n), '<', -1) AS Post_tag
FROM 
	(SELECT 2 AS n UNION ALL
	 SELECT 3 UNION ALL SELECT 4 UNION ALL
	 SELECT 5 UNION ALL SELECT 6) AS numbers
INNER JOIN 	posts p
ON 	char_length(Tags) - char_length(REPLACE(Tags,'<','')) >= numbers.n-1)
SELECT
	Post_tag,
	count(t1.Id) AS TotalofTag
FROM Tb_Tag t1
GROUP BY Post_tag
ORDER BY count(t1.Id) DESC
LIMIT 1

-- Opt.2-SQL server:
SELECT TOP 1
	Post_tag,
	count(*) AS TotalofPost
	FROM (
			SELECT
				Id,
				VALUE AS Post_tag
			FROM posts p 
			CROSS APPLY STRING_SPLIT(Tags, '>')) AS TBA
WHERE Post_tag != ''
GROUP BY Post_tag
ORDER BY  count(*) DESC

	-- 8. Create a pivot table displaying how many posts were created for each year (Y axis) and each month (X axis)
-- Opt.1:
SELECT
	year(CreationDate) AS _Year,
	count(CASE WHEN month(CreationDate) = 1 THEN Id ELSE NULL END) AS 'January',
	count(CASE WHEN month(CreationDate) = 2 THEN Id ELSE NULL END) AS 'Febuary',
	count(CASE WHEN month(CreationDate) = 3 THEN Id ELSE NULL END) AS 'March',
	count(CASE WHEN month(CreationDate) = 4 THEN Id ELSE NULL END) AS 'April',
	count(CASE WHEN month(CreationDate) = 5 THEN Id ELSE NULL END) AS 'May',
	count(CASE WHEN month(CreationDate) = 6 THEN Id ELSE NULL END) AS 'June',
	count(CASE WHEN month(CreationDate) = 7 THEN Id ELSE NULL END) AS 'July',
	count(CASE WHEN month(CreationDate) = 8 THEN Id ELSE NULL END) AS 'August',
	count(CASE WHEN month(CreationDate) = 9 THEN Id ELSE NULL END) AS 'September',
	count(CASE WHEN month(CreationDate) = 10 THEN Id ELSE NULL END) AS 'October',
	count(CASE WHEN month(CreationDate) = 11 THEN Id ELSE NULL END) AS 'November',
	count(CASE WHEN month(CreationDate) = 12 THEN Id ELSE NULL END) AS 'December'
FROM posts p
GROUP BY _Year

-- Opt.2-SQL server:
SELECT *   
FROM (  
    SELECT year(CreationDate) AS 'Year', DATENAME(MONTH,CreationDate) AS 'Month', id 
    FROM posts
  ) AS S  
PIVOT   
     (   
    count(id)
    FOR  [Month] IN ([January], [February], [March], [April], [May], [June], [July], [August], [September], [October], [November], [December]) 
   ) AS PVT
ORDER BY [Year]
