\c postgres postgres
CREATE EXTENSION mysql_fdw;
CREATE SERVER mysql_svr FOREIGN DATA WRAPPER mysql_fdw;
CREATE USER MAPPING FOR postgres SERVER mysql_svr OPTIONS(username 'foo', password 'bar');

CREATE FOREIGN TABLE department(department_id int, department_name text) SERVER mysql_svr OPTIONS(dbname 'testdb', table_name 'department');
CREATE FOREIGN TABLE employee(emp_id int, emp_name text, emp_dept_id int) SERVER mysql_svr OPTIONS(dbname 'testdb', table_name 'employee');
CREATE FOREIGN TABLE empdata(emp_id int, emp_dat bytea) SERVER mysql_svr OPTIONS(dbname 'testdb', table_name 'empdata');
CREATE FOREIGN TABLE numbers(a int, b varchar(255)) SERVER mysql_svr OPTIONS (dbname 'testdb', table_name 'numbers');

SELECT * FROM department LIMIT 10;
SELECT * FROM employee LIMIT 10;
SELECT * FROM empdata LIMIT 10;

INSERT INTO department VALUES(generate_series(1,100), 'dept - ' || generate_series(1,100));
INSERT INTO employee VALUES(generate_series(1,100), 'emp - ' || generate_series(1,100), generate_series(1,100));
INSERT INTO empdata  VALUES(1, decode ('01234567', 'hex'));

insert into numbers values(1, 'One');
insert into numbers values(2, 'Two');
insert into numbers values(3, 'Three');
insert into numbers values(4, 'Four');
insert into numbers values(5, 'Five');
insert into numbers values(6, 'Six');
insert into numbers values(7, 'Seven');
insert into numbers values(8, 'Eight');
insert into numbers values(9, 'Nine');

SELECT count(*) FROM department;
SELECT count(*) FROM employee;
SELECT count(*) FROM empdata;

EXPLAIN (COSTS FALSE) SELECT * FROM department d, employee e WHERE d.department_id = e.emp_dept_id LIMIT 10;

EXPLAIN (COSTS FALSE) SELECT * FROM department d, employee e WHERE d.department_id IN (SELECT department_id FROM department) LIMIT 10;

SELECT * FROM department d, employee e WHERE d.department_id = e.emp_dept_id LIMIT 10;
SELECT * FROM department d, employee e WHERE d.department_id IN (SELECT department_id FROM department) LIMIT 10;
SELECT * FROM empdata;

DELETE FROM employee WHERE emp_id = 10;

SELECT COUNT(*) FROM department LIMIT 10;
SELECT COUNT(*) FROM employee WHERE emp_id = 10;

UPDATE employee SET emp_name = 'Updated emp' WHERE emp_id = 20;
SELECT emp_id, emp_name FROM employee WHERE emp_name like 'Updated emp';

UPDATE empdata SET emp_dat = decode ('0123', 'hex');
SELECT * FROM empdata;

SELECT * FROM employee LIMIT 10;
SELECT * FROM employee WHERE emp_id IN (1);
SELECT * FROM employee WHERE emp_id IN (1,3,4,5);
SELECT * FROM employee WHERE emp_id IN (10000,1000);

SELECT * FROM employee WHERE emp_id NOT IN (1) LIMIT 5;
SELECT * FROM employee WHERE emp_id NOT IN (1,3,4,5) LIMIT 5;
SELECT * FROM employee WHERE emp_id NOT IN (10000,1000) LIMIT 5;

SELECT * FROM employee WHERE emp_id NOT IN (SELECT emp_id FROM employee WHERE emp_id IN (1,10));
SELECT * FROM employee WHERE emp_name NOT IN ('emp - 1', 'emp - 2') LIMIT 5;
SELECT * FROM employee WHERE emp_name NOT IN ('emp - 10') LIMIT 5;

create or replace function test_param_where() returns void as $$
DECLARE
  n varchar;
BEGIN
  FOR x IN 1..9 LOOP
    select b into n from numbers where a=x;
    raise notice 'Found number %', n;
  end loop;
  return;
END
$$ LANGUAGE plpgsql;

SELECT test_param_where();

DELETE FROM employee;
DELETE FROM department;
DELETE FROM empdata;
DELETE FROM numbers;

DROP FUNCTION test_param_where();
DROP FOREIGN TABLE numbers;

-- Check timestamp functions
CREATE FOREIGN TABLE times(id int, dt timestamp) SERVER mysql_svr OPTIONS(dbname 'testdb', table_name 'times');

INSERT INTO times VALUES
(1, '2015-01-10 11:24:35'),
(2, '2015-01-10 15:24:35'),
(3, '2015-01-10 17:24:35'),
(4, '2015-01-10 19:24:35'),
(5, '2015-01-10 21:24:35'),
(6, '2015-01-14 21:24:35'),
(7, '2015-01-14 22:24:35'),
(8, '2015-02-14 02:24:35'),
(9, '2015-02-14 05:24:35'),
(10, '2015-02-14 09:24:35'),
(11, '2016-02-14 09:24:35'),
(12, '2016-03-14 09:24:35'),
(13, '2016-03-16 09:24:35');

EXPLAIN (VERBOSE, COSTS OFF) SELECT * FROM times WHERE dt >= ('2016-03-14'::timestamptz - interval '1 month');
SELECT * FROM times WHERE dt >= ('2015-01-10 19:24:35'::timestamptz - interval '1 month') AND dt <= date_trunc('microseconds', now());
EXPLAIN (VERBOSE, COSTS OFF) SELECT * FROM times WHERE dt >= ('2015-01-10 19:24:35'::timestamptz - interval '1 month') AND dt <= date_trunc('year', now());
EXPLAIN (VERBOSE, COSTS OFF) SELECT * FROM times WHERE dt >= ('2015-01-10 19:24:35'::timestamptz - interval '1 month') AND dt <= date_trunc('month', now());
EXPLAIN (VERBOSE, COSTS OFF) SELECT * FROM times WHERE dt >= ('2015-01-10 19:24:35'::timestamptz - interval '1 month') AND dt <= date_trunc('day', now());

DELETE FROM times;

DROP FOREIGN TABLE department;
DROP FOREIGN TABLE employee;
DROP FOREIGN TABLE empdata;
DROP FOREIGN TABLE times;
DROP USER MAPPING FOR postgres SERVER mysql_svr;
DROP SERVER mysql_svr;
DROP EXTENSION mysql_fdw CASCADE;
