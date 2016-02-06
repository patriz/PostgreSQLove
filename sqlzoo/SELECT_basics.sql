SELECT population FROM world WHERE name = 'Germany';

SELECT name, gdp/population FROM world WHERE area > 5000000;

SELECT name, population FROM world WHERE name IN ('Ireland', 'Iceland', 'Denmark');

SELECT name, area FROM world WHERE area BETWEEN 200000 AND 250000
