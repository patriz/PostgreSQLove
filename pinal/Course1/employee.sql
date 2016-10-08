CREATE TABLE "Employee"
(
  "ID" integer,
  "EmployeeName" character varying(256),
  "Age" integer,
  "Birthdate" date,
  "IsCurrentEmployee" bit(1) NOT NULL DEFAULT B'1'::"bit"
);

INSERT INTO "Employee"("ID", "EmployeeName", "Age", "Birthdate") VALUES (1, 'Mark', 35, '1975/12/1');
INSERT INTO "Employee"("ID", "EmployeeName", "Age", "Birthdate") VALUES (2, 'Robert', 35, '1975/12/1');
INSERT INTO "Employee"("ID", "EmployeeName", "Age", "Birthdate", "IsCurrentEmployee") VALUES (3, 'John', 35, '1975/12/1', B'1');
INSERT INTO "Employee"("ID", "EmployeeName", "Age", "Birthdate") VALUES (4, 'Sid', 35, '1975/12/1');
INSERT INTO "Employee"("ID", "EmployeeName", "Age", "Birthdate", "IsCurrentEmployee", "MacAddress") VALUES (5, 'Philbert', 35, '1975/12/1', B'1', '08-00-2b-01-02-fa');

SELECT *
FROM "Employee";

--DELETE FROM "Employee";

--ALTER TABLE public."Employee" ADD COLUMN "IsCurrentEmployee" bit(1);
--ALTER TABLE public."Employee" ALTER COLUMN "IsCurrentEmployee" SET NOT NULL;
--ALTER TABLE public."Employee" ALTER COLUMN "IsCurrentEmployee" SET NOT NULL;
--ALTER TABLE public."Employee" ALTER COLUMN "IsCurrentEmployee" SET DEFAULT B'1'::"bit";

CREATE TABLE "Customer"
(
  "Name" character varying(256),
  "Birthdate" date,
  "Zipcode" character varying(10)
);

INSERT INTO "Customer" ("Name", "Birthdate", "Zipcode") VALUES ('Mike', 'June 6, 1976', '01256');
INSERT INTO "Customer" ("Name", "Birthdate", "Zipcode") VALUES ('John', '06-Jan-1986', '00256');
INSERT INTO "Customer" ("Name", "Birthdate", "Zipcode") VALUES ('Duke', 'January 16, 1996', '12958');
INSERT INTO "Customer" ("Name", "Birthdate", "Zipcode") VALUES ('Vikky', '2001/01/01', '00001');

SELECT *
FROM "Customer";

SELECT *
FROM "Customer"
WHERE "Zipcode" LIKE '0%';

SELECT *
FROM "Customer"
WHERE EXTRACT(MONTH FROM "Birthdate") = 1;