DROP TABLE Employee;

CREATE TABLE Employee (
    empname text    NOT NULL,
    salary 	        integer
);

CREATE TABLE Employee_audit (
    operation   char(1) 	  NOT NULL,
    stamp       timestamp 	NOT NULL,
    userid		  text		    NOT NULL,
    empname		  text		    NOT NULL,
    salary		  integer
);

CREATE FUNCTION emp_stamp() RETURNS trigger as $emp_stamp$
    BEGIN
        -- Check that empname and salary are given
        IF NEW.empname is NULL THEN
            RAISE EXCEPTION 'Employee Name column cannot be null';
        END IF;

        IF NEW.salary IS NULL THEN
            RAISE EXCEPTION '% cannot have null salary', NEW.empname;
        END IF;

        IF NEW.salary < 0 THEN
            RAISE EXCEPTION '% cannot have a negative salary', NEW.empname;
        END IF;

        RETURN NEW;
    END;
$emp_stamp$ LANGUAGE plpgsql;

CREATE TRIGGER emp_stamp BEFORE INSERT OR UPDATE ON "Employee"
    FOR EACH ROW EXECUTE PROCEDURE emp_stamp();


CREATE OR REPLACE FUNCTION process_emp_audit() RETURNS TRIGGER AS $emp_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
            INSERT INTO Employee_audit SELECT 'D', now(), user, OLD.*;
            RETURN OLD;
        ELSIF (TG_OP = 'UPDATE') THEN
            INSERT INTO EMployee_audit SELECT 'U', now(), user, NEW.*;
            RETURN NEW;
        ELSIF (TG_OP = 'INSERT') THEN
            INSERT INTO Employee_audit SELECT 'I', now(), user, NEW.*;
            RETURN NEW;
        END IF;
        RETURN NULL; -- result is ignored since this is an AFTER trigger
    END;
$emp_audit$ LANGUAGE plpgsql;

CREATE TRIGGER emp_audit
AFTER INSERT OR UPDATE OR DELETE ON "Employee"
    FOR EACH ROW EXECUTE PROCEDURE process_emp_audit();
