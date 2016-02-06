SELECT name FROM world WHERE name LIKE 'F%';

SELECT name FROM world WHERE name LIKE '%y';

SELECT name FROM world WHERE name LIKE '%x%';

SELECT name FROM world WHERE name LIKE '%land';

SELECT name FROM world WHERE name LIKE 'C%ia';

SELECT name FROM world WHERE name LIKE '%oo%';

SELECT name FROM world WHERE LOWER(name) LIKE '%a%a%a%';

SELECT name FROM world WHERE name LIKE '_t%' ORDER BY name;

SELECT name FROM world WHERE name LIKE '%o__o%';

SELECT name FROM world WHERE name LIKE '____';

SELECT name, capital, continent FROM world WHERE name = capital;

SELECT name FROM world WHERE capital LIKE '%City';

SELECT capital, name FROM world WHERE capital LIKE concat('%', name, '%');

SELECT name, capital FROM world WHERE capital LIKE concat('%', name, '%') and name != capital;

SELECT name, REPLACE(capital, name,'') as ext FROM world WHERE capital LIKE concat('%', name, '%') and name != capital;
