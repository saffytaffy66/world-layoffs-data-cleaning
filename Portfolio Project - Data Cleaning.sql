-- SQL Data Cleaning Project

-- https://www.kaggle.com/datasets/swaptr/layoffs-2022?resource=download

SELECT  *
FROM layoffs;

-- Data Cleaning Process:

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null Values or Blank Values
-- 4. Remove Columns/Rows Not Needed

-- I will build a staging database as my working document

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT  *
FROM layoffs;

-- 1. Remove Duplicates
-- I notice there is currently no unique ID, will need to add row ID to identify duplicates

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date` ) as row_num
FROM layoffs_staging
ORDER BY row_num DESC;

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date` ) as row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Testing to see if values are duplicates

SELECT *
FROM layoffs_staging
WHERE company = "Oda";

-- Values are not duplicates -- will need to revise code
-- Will now partition by all columns in the dataset to identify true duplicates

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions ) as row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Testing again to see if duplicates are identified

SELECT *
FROM layoffs_staging
WHERE company = "Casper";

-- Testing was successful: duplicates identified
-- Moving forward with removing duplicates

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions ) as row_num
FROM layoffs_staging
)
DELETE
FROM duplicate_cte
WHERE row_num > 1;

-- Could not update CTE, creating v2 staging table to remove duplicate values

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, 
industry, total_laid_off, percentage_laid_off, `date`, 
stage, country, funds_raised_millions ) AS row_num
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Duplicate delete was successful


-- 2. Standardizing Data

-- By company
SELECT company, (TRIM(company))
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- By industry
SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY 1;

-- I notice that industries with "crypto" can be merged

SELECT *
FROM layoffs_staging2
WHERE industry LIKE "Crypto%";

UPDATE layoffs_staging2
SET industry = "Crypto"
WHERE industry LIKE "Crypto%";

SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY 1;

-- Crypto merge was successful

-- By location
SELECT DISTINCT(location)
FROM layoffs_staging2
ORDER BY 1;

-- BY country
SELECT DISTINCT(country)
FROM layoffs_staging2
ORDER BY 1;

-- I noticed "United States" and "United States."

SELECT DISTINCT country, TRIM(TRAILING "." FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING "." FROM country)
WHERE country LIKE "United States%";

SELECT DISTINCT(country)
FROM layoffs_staging2
ORDER BY 1;

-- Country update was successful

-- By date
SELECT `date`
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, "%m/%d/%Y");

-- Changed `date` to a date format, still need to change data type

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

SELECT *
FROM layoffs_staging2;

-- Change data type was successful

-- 3. Null and Blank Values

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = "";

SELECT *
FROM layoffs_staging2
WHERE company = "Airbnb";

-- I notice there is a row for "Airbnb" with industry of "Travel" -- will populate blank value with "Travel" for consistency

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = "";

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT *
FROM layoffs_staging2
WHERE company = "Airbnb";

-- Industry update was successful

-- 4. Remove Columns/Rows as Needed

-- I'd like to use the cleaned data for exploratory analysis based on total_laid_off and percentage_laid_off
-- I will remove all rows with null values for these columns

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2;

-- I will also remove row_num as this column is unnecessary

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2;