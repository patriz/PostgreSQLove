# SQL-Training-Advanced
- https://www.udemy.com/practice-advanced-sql-with-mysql

## Index
### Basic
```sql
ALTER TABLE `salary` DROP INDEX `idx_salary_amount`;
```

```sql
explain SELECT * 
FROM `sample_staff`.`salary`
WHERE 1=1
	AND `salary`.`salary_amount` > 100000
	AND `salary`.`from_date` >= '1998-01-01'
LIMIT 10000
;
```

```sql
ALTER TABLE `salary` ADD INDEX `idx_salary_amount` (`salary_amount`);
```

### Practices
```sql
-- https://github.com/michaljuhas/SQL-training-advanced/blob/master/S03-Indexes/S03-P01-Practice.md

ANALYZE TABLE `sample_staff`.`employee`;

CREATE INDEX idx_personal_code_2chars ON `sample_staff`.`employee`. (personal_code(2));

EXPLAIN SELECT * from employee where personal_code = 'AA-751492';

SELECT * FROM employee USE INDEX (`idx_personal_code_2chars`)
WHERE personal_code = 'AA-751492';

SELECT * 
FROM employee USE INDEX (`ak_employee`)
WHERE 1=1
	AND personal_code = 'AA-751492';

SELECT /* Select all indexes from table 'employee' and their size */
	sum(`stat_value`) AS pages,
	`index_name` AS index_name,
	sum(`stat_value`) * @@innodb_page_size / 1024 / 1024 AS size_mb
FROM `mysql`.`innodb_index_stats`
WHERE 1=1
	AND `table_name` = 'employee'
	AND `database_name` = 'sample_staff'
	AND `stat_description` = 'Number of pages in the index'
GROUP BY
	`index_name`
;
```

```sql
-- https://github.com/michaljuhas/SQL-training-advanced/blob/master/S03-Indexes/S03-P02-Practice.md

ANALYZE TABLE `sample_staff`.`contract`;

SHOW INDEX FROM `sample_staff`.`contract`;

-- 145ms -> 0.6ms
EXPLAIN SELECT SQL_NO_CACHE `contract`.`archive_code`
FROM `contract`
WHERE 1=1
	AND `contract`.`archive_code` = 'DA970'
	AND `contract`.`deleted_flag` = 0
	AND `contract`.`sign_date` >= '1990-01-01'
;

ALTER TABLE contract ADD INDEX idx_archive_code_sign_date (archive_code, sign_date);

-- 86.3ms -> 0.4ms
SELECT SQL_NO_CACHE `contract`.`archive_code`
FROM `contract`
WHERE 1=1
	AND `contract`.`archive_code` = 'DA970'
	AND `contract`.`deleted_flag` = 0
;
```

## Partioning
```sql
-- Sub partioning
CREATE TABLE `test` (`id` INT, `purchased` DATE)
	PARTITION BY RANGE( YEAR(`purchased`) )
	SUBPARTITION BY HASH( TO_DAYS(`purchased`) )
	SUBPARTITIONS 10 (
		PARTITION p0 VALUES LESS THAN (1990),
		PARTITION p1 VALUES LESS THAN (2000),
		PARTITION p2 VALUES LESS THAN MAXVALUE
	)
;
```

```sql
-- Select a list of all partionins
SELECT
	`table_name`,
	`partition_ordinal_position`,
	`table_rows`,
	`partition_method`,
	`partitions`.*
FROM information_schema.partitions
WHERE 1=1
	AND `table_schema` = 'sample_staff'
	AND `table_name` = 'invoice'
;
```

```sql
-- https://github.com/michaljuhas/SQL-training-advanced/blob/master/S05-Variables/S05-P01-Practice.md

SHOW GLOBAL VARIABLES;

SET @focus_date = '2000-01-01';

SET @company_average_salary := (
  SELECT
    ROUND(AVG(`salary`.`salary_amount`), 2) AS company_average_salary
  FROM `sample_staff`.`salary`
  WHERE 1=1
    AND @focus_date BETWEEN `salary`.`from_date` AND IFNULL(`salary`.`to_date`, '2002-08-01')
);

SELECT
	`department_id` AS department_id,
	`department_name` AS department_name,
	`department_average_salary` AS department_average_salary,
	@company_average_salary AS company_average_salary,
	CASE
		WHEN `department_average_salary` > @company_average_salary THEN "higher"
		WHEN `department_average_salary` = @company_average_salary THEN "same"
		ELSE "lower"
	END AS department_vs_company
FROM (
SELECT
	`department`.`id` AS department_id,
	`department`.`name` AS department_name,
	AVG(`salary`.`salary_amount`) AS department_average_salary
FROM `sample_staff`.`salary`
INNER JOIN `sample_staff`.`department_employee_rel` ON 1=1
	AND `department_employee_rel`.`employee_id` = `salary`.`employee_id`
	AND @focus_date BETWEEN `department_employee_rel`.`from_date` AND IFNULL(`department_employee_rel`.`to_date`, '2002-08-01')
INNER JOIN `sample_staff`.`department` ON 1=1
	AND `department`.`id` = `department_employee_rel`.`department_id`
WHERE 1=1
	AND @focus_date BETWEEN `salary`.`from_date` AND IFNULL(`salary`.`to_date`, '2002-08-01')
GROUP BY
	`department`.`id`,
	`department`.`name`
) xTMP
;
```

## Analytics
```sql
-- Row Number

SELECT
	`id`,
	`employee_id`,
	`salary_amount`,
	`from_date`,
	`to_date`
FROM `sample_staff`.`salary`
WHERE `salary`.`employee_id` = 10004
;

-- Salary Analysis
SET @row_number = 0;
SET @dummy_salary_amount = 0;
SET @dummy_employee_id = 0;

SELECT
	`id`,
	`employee_id`,
	`salary_amount`,
	`from_date`,
	`to_date`,
	IF(`salary_amount` < @dummy_salary_amount AND @dummy_salary_amount != 0, '⇣', '⇡') AS comparison,
	CAST((`salary_amount` - @dummy_salary_amount) AS DECIMAL(10, 0)) as diff,
	@row_number := IF(`employee_id` != @dummy_employee_id, 1, @row_number + 1) AS '@row_number',
	@dummy_salary_amount := `salary_amount` AS '@dummy_salary_amount',
	@dummy_employee_id := `employee_id` AS '@dummy_employee_id'
FROM (
	SELECT
		`id`,
		`employee_id`,
		`salary_amount`,
		`from_date`,
		`to_date`
	FROM `salary`
	WHERE `salary`.`employee_id` = 10004
	ORDER BY `salary`.`from_date` ASC
) xTMP
;
```

```sql
-- 1986년부터 2001년까지 연봉 상승률
SET @row_number = 0;
SET @dummy_salary_amount = 0;
SET @dummy_employee_id = 0;

SELECT
	employee_id,
	ROUND(AVG(`@row_number`), 1) AS average_month_when_salary_increase
FROM (
	SELECT
		`id`,
		`employee_id`,
		`salary_amount`,
		`from_date`,
		`to_date`,
		IF(`salary_amount` < @dummy_salary_amount AND @dummy_salary_amount != 0, '⇣', '⇡') AS comparison,
		CAST((`salary_amount` - @dummy_salary_amount) AS DECIMAL(10, 0)) as diff,
		@row_number := IF(`employee_id` != @dummy_employee_id, 1, @row_number + 1) AS '@row_number',
		@dummy_salary_amount := `salary_amount` AS '@dummy_salary_amount',
		@dummy_employee_id := `employee_id` AS '@dummy_employee_id'
	FROM (
		SELECT
			`id`,
			`employee_id`,
			`salary_amount`,
			`from_date`,
			`to_date`
		FROM `salary`
		WHERE `salary`.`employee_id` = 10004
		ORDER BY `salary`.`from_date` ASC
	) xTMP
) xTMP2
WHERE 1=1
	AND comparison = '⇡'
GROUP BY
	employee_id
;
```

## Functions

```sql
-- Functions

SELECT /* Is multinight? */
	@checkin_date := '2016-05-09' AS checkin_date,
	@checkout_date := '2016-05-10' AS checkout_date,
	CASE
		WHEN DATEDIFF(@checkout_date, @checkin_date) = 1 THEN 0
		ELSE 1
	END AS is_multinight
;

DROP FUNCTION IF EXISTS `FC_IS_MULTINIGHT`;

DELIMITER //

CREATE FUNCTION `FC_IS_MULTINIGHT` (
	checkin_date DATE,
	checkout_date DATE
) RETURNS TINYINT(1)
BEGIN
	RETURN CASE
		WHEN DATEDIFF(checkout_date, checkin_date) = 1 THEN FALSE
		ELSE TRUE
	END;
END;
//

DELIMITER ;
```

```sql
SELECT
	@checkin_date := '2016-05-09' AS checkin_date,
	@checkout_date := '2016-05-10' AS checkout_date,
	FC_IS_MULTINIGHT(@checkin_date, @checkout_date) AS is_multinight
;

DROP PROCEDURE IF EXISTS `SEL_EMPLOYEE_COUNT`;

DELIMITER //

CREATE DEFINER=`staff`@`%` PROCEDURE `SEL_EMPLOYEE_COUNT`()
SQL SECURITY INVOKER
BEGIN
  SELECT COUNT(*) FROM `sample_staff`.`employee`;
END;
//

DELIMITER ;

-- Call the new procedure
CALL SEL_EMPLOYEE_COUNT();
```

```sql
-- Create a function that will return distance between 2 coordinates in meters.

DROP FUNCTION IF EXISTS `FC_GET_DISTANCE`;

DELIMITER //

CREATE FUNCTION `FC_GET_DISTANCE` (
	in_latitude_from FLOAT,
	in_longitude_from FLOAT,
	in_latitude_to FLOAT,
	in_longitude_to FLOAT
) RETURNS float
BEGIN
	RETURN
		ROUND(
			6371 * 1000 /* R is earth’s radius in meters (6371km) */
			* ACOS(
				COS( RADIANS(in_latitude_from) )
		      	* COS( RADIANS(in_latitude_to ) )
		      	* COS( RADIANS(in_longitude_to ) - RADIANS(in_longitude_from) )
		      + SIN( RADIANS(in_latitude_from) )
		      	* SIN( RADIANS(in_latitude_to ) )
	      	)
		);
END;
//

DELIMITER ;

SELECT FC_GET_DISTANCE(13.756331, 100.501765, 13.756262, 100.505891) AS distance_in_meters;
```

## Procecures

### Function vs Procedure

```sql
-- Functions

SELECT INET_ATON('32.12.45.193');
SELECT INET_NTOA(537669057);

SELECT
	@checkin_date := '2016-05-09' AS checkin_date,
	@checkout_date := '2016-05-10' AS checkout_date,
	FC_IS_MULTINIGHT(@checkin_date, @checkout_date) AS is_multinight
;

-- INS_USER_LOGIN

DROP PROCEDURE IF EXISTS `INS_USER_LOGIN`;

DELIMITER //

CREATE PROCEDURE `INS_USER_LOGIN` (
	in_user_id INT(11),
	in_ip_address VARCHAR(20)
)
BEGIN
	INSERT INTO `sample_staff`.`user_login`
		(`user_id`, `login_dt`, `ip_address`, `insert_dt`, `insert_process_code`)
	VALUES
		(in_user_id, NOW(), INET_ATON(in_ip_address), NOW(), 'INS_USER_LOGIN');
END;
//

DELIMITER ;

CALL INS_USER_LOGIN(1, '32.12.45.193');
```

```sql
-- SEL_USER_LOGIN

DROP PROCEDURE IF EXISTS `SEL_USER_LOGIN`;

DELIMITER //

CREATE PROCEDURE `SEL_USER_LOGIN` (
	in_user_id INT(11)
)
BEGIN
	SELECT
		`user_login`.`id` AS `user_login_id`,
		`user_login`.`user_id`,
		`user`.`name` AS `user_name`,
		INET_NTOA(`user_login`.`ip_address`) AS `ip_address`,
		`user_login`.`login_dt`
	FROM `sample_staff`.`user_login`
	INNER JOIN `sample_staff`.`user` ON 1=1
		AND `user`.`id` = `user_login`.`user_id`
	WHERE 1=1
		AND `user_login`.`deleted_flag` = 0
		AND `user_login`.`user_id` = `in_user_id`
	ORDER BY
		`user_login`.`id` DESC
	LIMIT 1;
END;
//

DELIMITER ;
```

```sql
-- Call the new procedure
CALL SEL_USER_LOGIN(1);

SHOW VARIABLES LIKE 'event_scheduler';

SET GLOBAL event_scheduler = 1;

DROP TABLE IF EXISTS `event_logger`;

CREATE TABLE `event_logger` (
	`id` INT(11) NOT NULL AUTO_INCREMENT,
	`event_name` VARCHAR(35) NOT NULL,
	`counter` INT(11) NOT NULL DEFAULT 0,
	`insert_dt` DATETIME NOT NULL,
	`insert_user_id` INT(11) NOT NULL DEFAULT '-1',
	`update_dt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`update_user_id` INT(11) NOT NULL DEFAULT '-1',
	`update_process_code` VARCHAR(255) DEFAULT NULL,
	`deleted_flag` TINYINT(4) NOT NULL DEFAULT '0',
	PRIMARY KEY(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `event_logger` (`id`, `event_name`, `counter`, `insert_dt`)
	VALUES (NULL, 'Test event', '0', NOW());
```

Create `event_counter`
```sql
-- event_counter

DROP EVENT IF EXISTS `sample_staff`.`ev_test_event_counter`;

DELIMITER //

CREATE EVENT `sample_staff`.`ev_test_event_counter`
	ON SCHEDULE EVERY 1 SECOND
	STARTS NOW()
	ENDS NOW() + INTERVAL 1 MINUTE
	COMMENT 'Test event'
	DO
		BEGIN
			UPDATE `event_logger`
			SET counter = counter + 1
			WHERE event_name = 'Test event'
			;
		END
//

DELIMITER ;

SHOW EVENTS;
```

### Practices
#### 01
Create a new view `v_average_salary` which will return average salary per month/year per department. The view should have the following columns:
- department_id
- department_name
- average_salary_amount
- month_year (i.e. '02/1985')

Then, create a procedure `GET_DEPARTMENT_AVERAGE_SALARY` with a similar query inside as the view, but in addition also having an input attribute `in_department_id` to restrict the query for a selected department.

You will be able to fetch average salary for a specific department in 2 ways:
View: SELECT * FROM v_average_salary WHERE department_id = 2;
Procedure: SELECT * FROM GET_DEPARTMENT_AVERAGE_SALARY(2);

```sql
-- Practice 01
SELECT 
	`department`.`id` AS department_id,
	`department`.`name` AS department_name,
	ROUND(AVG(`salary_amount`), 2) AS average_salary_amount,
	CONCAT(LPAD(MONTH(invoice.invoiced_date), 2, '0'), '/', YEAR(invoice.invoiced_date)) AS month_year
FROM `sample_staff`.`invoice`
INNER JOIN `department_employee_rel` ON 1=1
AND `department_employee_rel`.`employee_id` = invoice.employee_id
	AND `invoice`.`invoiced_date` BETWEEN `department_employee_rel`.`from_date` AND IFNULL(`department_employee_rel`.`to_date`, '2002-08-01')
INNER JOIN `department` ON 1=1
  AND `department`.`id` = `department_employee_rel`.`department_id`
INNER JOIN `salary` ON 1=1
  AND `salary`.`employee_id` = `invoice`.`employee_id`
  AND `invoice`.`invoiced_date` BETWEEN `salary`.`from_date` AND IFNULL(`salary`.`to_date`, '2002-08-01')
WHERE 1=1
GROUP BY
	`department`.`id`,
  `department`.`name`,
	CONCAT(LPAD(MONTH(invoice.invoiced_date), 2, '0'), '/', YEAR(invoice.invoiced_date))
;

EXPLAIN SELECT * FROM v_average_salary WHERE department_id = 2;
```

#### 02
There is a stored function `INS_USER_LOGIN_DATA_GENERATOR` which simulates users logging to 
your website or mobile app and writing data to `sample_staff.user_login`

```sql
SHOW VARIABLES LIKE 'event_scheduler';

SET GLOBAL event_scheduler = 1;

DROP PROCEDURE IF EXISTS `INS_USER_LOGIN_DATA_GENERATOR`;

DELIMITER //

CREATE PROCEDURE `INS_USER_LOGIN_DATA_GENERATOR`()
BEGIN
	DECLARE p_ip_address VARCHAR(20);
	DECLARE p_user_id INT;
	DECLARE p_loop_counter INT DEFAULT 10;
	
	WHILE p_loop_counter > 0 DO
		INSERT INTO `sample_staff`.`user_login` 
			(`user_id`, `login_dt`, `ip_address`, `insert_dt`, `insert_process_code`)
		SELECT
			`user`.`id` AS user_id,
	  		NOW() AS login_dt,
	  		INET_ATON(`ip_address_varchar20`.`ip_address`) AS ip_address,
	  		NOW(),
	  		'INS_USER_LOGIN_DATA_GENERATOR' AS insert_process_code
	  	FROM `sample_staff`.`user`
	  	INNER JOIN `sample_ip`.`ip_address_varchar20` ON 1=1
	  		AND `sample_ip`.`ip_address_varchar20`.`id` < 100
	  	ORDER BY RAND()
	  	LIMIT 1000
	  	;
	  	
	  	SET p_loop_counter = p_loop_counter - 1;
	  END WHILE;
END;
//	

DELIMITER ;

CALL `INS_USER_LOGIN_DATA_GENERATOR`();
```

#### 03
```sql
- Create Event

DROP EVENT IF EXISTS `sample_staff`.`ev_generate_login_data`;

CREATE EVENT `sample_staff`.`ev_generate_login_data`
	ON SCHEDULE EVERY 30 SECOND
	STARTS NOW()
	ENDS NOW() + INTERVAL 1 HOUR
	COMMENT 'Randomly generate data to sample_staff.user_login table.'
	DO CALL `INS_USER_LOGIN_DATA_GENERATOR`()
;

-- Practice 03: Create a new procedure INS_USER_STAT to aggregate stats about user logins

DROP PROCEDURE IF EXISTS `INS_USER_STAT`;

DELIMITER //

CREATE PROCEDURE `INS_USER_STAT`(
	in_user_id INT
)
BEGIN
	INSERT INTO `sample_staff`.`user_stat`
    (`user_id`, `date`, `hour`, `login_count`, `insert_dt`, `insert_process_code`)
    SELET
		xTMP.user_id,
      	login_date,
      	login_hour,
      	login_count,
      	insert_dt,
      	insert_process_code
    FROM (
      	SELECT
      		`user_login`.`user_id` AS user_id,
        	DATE(user_login.login_dt) AS login_date,
       		HOUR(user_login.login_dt) AS login_hour,
        	COUNT(*) AS login_count,
      		NOW() AS insert_dt,
      		'INS_USER_STAT' AS insert_process_code
      	FROM `sample_staff`.`user_login`
      	WHERE 1=1
        	AND `user_login`.`user_id` = in_user_id
      	GROUP BY
        	`user_login`.`user_id`,
        	DATE(user_login.login_dt),
        	HOUR(user_login.login_dt)
    ) xTMP
  	ON DUPLICATE KEY UPDATE
    	user_stat.login_count = xTMP.login_count,
    	user_stat.update_process_code = CASE
      		WHEN user_stat.login_count != xTMP.login_count THEN 'INS_USER_STAT'
      		ELSE user_stat.update_process_code
    		END,
    	user_stat.update_dt = CASE
			WHEN user_stat.login_count != xTMP.login_count THEN NOW()
			ELSE user_stat.update_dt
			END
  	;
END;
// 
DELIMITER ;

CALL `INS_USER_STAT`(10001);
```