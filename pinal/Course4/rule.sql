DROP TABLE shoelace_data;
DROP TABLE unit;
DROP TABLE shoelace;

CREATE TABLE shoelace_data (
    sl_name     text,       -- primary key
    sl_avail    integer,    -- available number of paris
    sl_color    text,       -- shoelace color
    sl_len      real,       -- shoelace length
    sl_unit     text        -- length unit
);

INSERT INTO shoelace_data VALUES ('sl1', 5, 'black', 80.0, 'cm');
INSERT INTO shoelace_data VALUES ('sl2', 5, 'black', 100.0, 'cm');
INSERT INTO shoelace_data VALUES ('sl3', 0, 'black', 35.0, 'inch');
INSERT INTO shoelace_data VALUES ('sl4', 8, 'black', 40.0, 'inch');
INSERT INTO shoelace_data VALUES ('sl5', 4, 'brown', 1.0, 'm');
INSERT INTO shoelace_data VALUES ('sl6', 0, 'brown', 0.9, 'm');
INSERT INTO shoelace_data VALUES ('sl7', 7, 'brown', 60, 'cm');
INSERT INTO shoelace_data VALUES ('sl8', 1, 'brown', 40, 'inch');

CREATE TABLE unit (
    un_name text,
    un_fact real
);

INSERT INTO unit VALUES ('cm', 1.0);
INSERT INTO unit VALUES ('m', 100.0);
INSERT INTO unit VALUES ('inch', 2.54);


SELECT s.sl_name,
    s.sl_avail,
    s.sl_color,
    s.sl_len,
    s.sl_unit,
    s.sl_len * u.un_fact AS sl_len_cm 
FROM shoelace_data s, unit u
WHERE s.sl_unit = u.un_name;

CREATE TABLE shoelace (
    sl_name     text,       -- primary key
    sl_avail    integer,    -- available number of paris
    sl_color    text,       -- shoelace color
    sl_len      real,       -- shoelace length
    sl_unit     text,       -- length unit
    sl_len_cm	real	        -- calculated len
 );

CREATE RULE "_RETURN" AS ON SELECT TO shoelace DO INSTEAD
    SELECT s.sl_name,
        s.sl_avail,
        s.sl_color,
        s.sl_len,
        s.sl_unit,
        s.sl_len * u.un_fact AS sl_len_cm 
    FROM shoelace_data s, unit u
    WHERE s.sl_unit = u.un_name;

SELECT * FROM shoelace;
