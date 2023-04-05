USE airbnb_10_cities;

 -- DROP TABLE IF EXISTS listings;

/*Data Loading */

-- Create and Insert listings Table into MySQL
CREATE TABLE listings (
  listing_id BIGINT NULL,
  host_id BIGINT NULL,
  host_since VARCHAR(255) NULL,
  host_response_time VARCHAR(255) NULL,
  host_response_rate VARCHAR(255) NULL,
  host_acceptance_rate VARCHAR(255) NULL,
  host_is_superhost VARCHAR(255) NULL,
  host_total_listings_count VARCHAR(255) NULL,
  host_has_profile_pic VARCHAR(255) NULL,
  host_identity_verified VARCHAR(255) NULL,
  neighbourhood VARCHAR(255) NULL,
  district VARCHAR(255) NULL,
  city VARCHAR(255) NULL,
  latitude VARCHAR(255) NULL,
  longitude VARCHAR(255) NULL,
  property_type VARCHAR(255) NULL,
  room_type VARCHAR(255) NULL,
  accommodates VARCHAR(255) NULL,
  bedrooms VARCHAR(255) NULL,
  price VARCHAR(255) NULL,
  minimum_nights VARCHAR(255) NULL,
  maximum_nights VARCHAR(255) NULL,
  review_scores_rating VARCHAR(255) NULL,
  review_scores_accuracy VARCHAR(255) NULL,
  review_scores_cleanliness VARCHAR(255) NULL,
  review_scores_checkin VARCHAR(255) NULL,
  review_scores_communication VARCHAR(255) NULL,
  review_scores_location VARCHAR(255) NULL,
  review_scores_value VARCHAR(255) NULL,
  instant_bookable VARCHAR(255) NULL
);


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/listings.csv'
INTO TABLE listings
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- Changing listings table data type, add NULL values to empty strings

UPDATE listings SET
host_since = NULLIF(host_since,''), 
host_response_time = NULLIF(host_response_time, ''), 
host_response_rate = NULLIF(host_response_rate, ''), 
host_acceptance_rate = NULLIF(host_acceptance_rate, ''), 
host_total_listings_count = NULLIF(host_total_listings_count, ''), 
latitude = NULLIF(latitude, ''), 
longitude = NULLIF(longitude, ''), 
accommodates = NULLIF(accommodates, ''), 
bedrooms = NULLIF(bedrooms, ''), 
price = NULLIF(price, ''), 
minimum_nights = NULLIF(minimum_nights, ''), 
maximum_nights = NULLIF(maximum_nights, ''), 
review_scores_rating = NULLIF(review_scores_rating, ''), 
review_scores_accuracy = NULLIF(review_scores_accuracy, ''), 
review_scores_cleanliness = NULLIF(review_scores_cleanliness, ''), 
review_scores_checkin = NULLIF(review_scores_checkin, ''), 
review_scores_communication = NULLIF(review_scores_communication, ''), 
review_scores_location = NULLIF(review_scores_location, ''), 
review_scores_value = NULLIF(review_scores_value, '');

ALTER TABLE listings 
MODIFY COLUMN host_since DATE NULL,
MODIFY COLUMN host_response_time VARCHAR(255) NULL,
MODIFY COLUMN host_response_rate FLOAT NULL,
MODIFY COLUMN host_acceptance_rate FLOAT NULL,
MODIFY COLUMN host_total_listings_count INT NULL,
MODIFY COLUMN neighbourhood VARCHAR(255) NULL,
MODIFY COLUMN district VARCHAR(255) NULL,
MODIFY COLUMN city VARCHAR(255) NULL,
MODIFY COLUMN latitude FLOAT NULL,
MODIFY COLUMN longitude FLOAT NULL,
MODIFY COLUMN property_type VARCHAR(255) NULL,
MODIFY COLUMN room_type VARCHAR(255) NULL,
MODIFY COLUMN accommodates INT NULL,
MODIFY COLUMN bedrooms INT NULL,
MODIFY COLUMN price DECIMAL(10,2) NULL,
MODIFY COLUMN minimum_nights INT NULL,
MODIFY COLUMN maximum_nights INT NULL,
MODIFY COLUMN review_scores_rating FLOAT NULL,
MODIFY COLUMN review_scores_accuracy FLOAT NULL,
MODIFY COLUMN review_scores_cleanliness FLOAT NULL,
MODIFY COLUMN review_scores_checkin FLOAT NULL,
MODIFY COLUMN review_scores_communication FLOAT NULL,
MODIFY COLUMN review_scores_location FLOAT NULL,
MODIFY COLUMN review_scores_value FLOAT NULL;

ALTER TABLE listings ADD COLUMN price_usd DECIMAL(10,2);
UPDATE listings SET price_usd = ROUND((price / (CASE city 
WHEN 'Bangkok' THEN 34.08 
WHEN 'Cape Town' THEN 17.79
WHEN 'Hong Kong' THEN 7.85
WHEN 'Istanbul' THEN 19.18
WHEN 'Mexico City' THEN 18.02
WHEN 'Paris' THEN 0.92
WHEN 'Rio de Janeiro' THEN 5.06
WHEN 'Sydney' THEN 1.5
ELSE 1 END)),2);

-- Create and insert Review Table. In this table there is no NULL value so we can directly load data without applying the steps above

-- DROP TABLE IF EXISTS reviews;


CREATE TABLE reviews (
listing_id BIGINT NULL,
review_id BIGINT NULL,
date DATE  NULL,
reviewer_id BIGINT NULL);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Reviews.csv'
INTO TABLE reviews
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;


/* Data Exploration */

-- Differences in the Airbnb market between cities:
 
-- 1. Which city has the highest amount of listing_id, host_id: PARIS -> HONG KONG

SELECT city, COUNT(DISTINCT listing_id) Total_listings, COUNT(DISTINCT host_id) Total_hosts, ROUND(AVG(price_usd),2) Average_Price FROM listings
GROUP BY 1
ORDER BY 2 DESC, 3 DESC, 4 DESC;

WITH market_ranking AS (
SELECT city, COUNT(DISTINCT listing_id) Total_listings, AVG(price_usd) Average_Price FROM listings
GROUP BY 1
ORDER BY 1,2)

SELECT city, RANK() OVER ( ORDER BY Average_Price) affordability_ranking, RANK() OVER ( ORDER BY Total_listings) accessibility_ranking
FROM market_ranking;

-- 2. Average price per room type and how easy it is to find each room

SELECT city, room_type, 100*COUNT(room_type)/ SUM(COUNT(room_type)) OVER(PARTITION BY city) Percentage_of_room, AVG(price_usd) FROM listings
GROUP BY 1,2;

-- 3. Are you likely to find a good deal in each city

WITH cte AS (
  SELECT 
    city, 
    AVG(price_usd) AS avg_price
  FROM listings
  GROUP BY city
)
SELECT 
  l.city, COUNT(DISTINCT l.listing_id), cte.avg_price,
  ROUND(100 * SUM(CASE WHEN l.price < cte.avg_price THEN 1 ELSE 0 END) / COUNT(l.listing_id), 2) AS percent_better_price
FROM 
  listings l
  JOIN cte ON l.city = cte.city
GROUP BY l.city
ORDER BY 4 DESC;

Select * FROM listings;

-- 4. Living Cost per person per city
SELECT city, ROUND(AVG (price_usd/accommodates),2) FROM listings
GROUP BY 1
ORDER BY 2;

-- 5. How old is the Airbnb market in each city
SELECT sub.*, RANK() OVER (PARTITION BY sub.year_time ORDER BY sub.total_listings DESC) ranking FROM (
SELECT YEAR(host_since) year_time,city, COUNT(DISTINCT listing_id) total_listings FROM listings
where host_since  IS NOT NULL
GROUP BY  year_time, city) sub
ORDER BY 1,4;


-- 6. Maximum Listings belong to an owner in each cities

WITH number_listing_per_host AS(
SELECT city, host_id, count(DISTINCT listing_id) total_listings FROM listings
GROUP BY 1 ,2
ORDER BY 3 DESC)

SELECT sub.city, sub.host_id, sub.total_listings FROM
(SELECT city,host_id, total_listings, ROW_NUMBER() OVER (PARTITION BY city ORDER BY total_listings DESC) Ranking FROM number_listing_per_host) AS sub
WHERE sub.Ranking =1
ORDER BY sub.total_listings DESC;

