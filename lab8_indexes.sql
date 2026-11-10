-- 1.1
BEGIN;
SET LOCAL search_path = public;

CREATE TABLE IF NOT EXISTS departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id INT REFERENCES departments(dept_id),
    salary DECIMAL(10,2),
    manager_id INT REFERENCES employees(emp_id)
);

CREATE TABLE IF NOT EXISTS projects (
    project_id INT PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id INT REFERENCES departments(dept_id),
    budget DECIMAL(10,2)
);

INSERT INTO departments (dept_id, dept_name, location) VALUES
    (101, 'IT', 'New York'),
    (102, 'HR', 'Chicago'),
    (103, 'Finance', 'New York'),
    (104, 'Marketing', 'Boston')
ON CONFLICT (dept_id) DO NOTHING;

INSERT INTO employees (emp_id, emp_name, dept_id, salary, manager_id) VALUES
    (1, 'John Smith', 101, 70000, NULL),
    (2, 'Alice Johnson', 101, 60000, 1),
    (3, 'Mary Wilson', 102, 45000, 1),
    (4, 'James Davis', 103, 80000, 1),
    (5, 'Tom Brown', NULL, 40000, 1)
ON CONFLICT (emp_id) DO NOTHING;

INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
    (1, 'Website Redesign', 101, 100000),
    (2, 'Cloud Migration', 101, 150000),
    (3, 'Recruitment', 102, 30000),
    (4, 'Independent Research', NULL, 25000),
    (5, 'Database', 103, NULL)
ON CONFLICT (project_id) DO NOTHING;

-- 2.1
CREATE INDEX emp_salary_idx ON employees USING btree (salary);

SELECT tablename, indexname, indexdef, COUNT(*) OVER () AS total_indexes
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('departments', 'employees', 'projects')
ORDER BY tablename, indexname;

-- 2.2
CREATE INDEX emp_dept_idx ON employees (dept_id);

-- An index on the referencing dept_id helps PostgreSQL find matching employees for selective joins, parent-key checks and cascading updates or deletes
-- The foreign key declaration does not create this index automatically

-- 2.3
SELECT i.tablename, i.indexname, i.indexdef,
       CASE c.contype
           WHEN 'p' THEN 'Primary key constraint'
           WHEN 'u' THEN 'Unique constraint'
           WHEN 'x' THEN 'Exclusion constraint'
           ELSE 'Standalone index'
       END AS index_origin
FROM pg_indexes AS i
JOIN pg_namespace AS n ON n.nspname = i.schemaname
JOIN pg_class AS idx ON idx.relnamespace = n.oid AND idx.relname = i.indexname
LEFT JOIN pg_constraint AS c ON c.conindid = idx.oid
    AND c.contype IN ('p', 'u', 'x')
WHERE i.schemaname = 'public'
ORDER BY i.tablename, i.indexname;

-- 3.1
CREATE INDEX emp_dept_salary_idx ON employees (dept_id, salary);

SELECT emp_id, emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary >= 55000
ORDER BY salary;

EXPLAIN
SELECT emp_id, emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary >= 55000;

-- The leftmost key dept_id identifies a contiguous slice of the B-tree
-- Within that slice the salary bound narrows the scan
-- A filter on dept_id alone can also use the prefix

-- 3.2
CREATE INDEX emp_salary_dept_idx ON employees (salary, dept_id);

EXPLAIN
SELECT emp_id, emp_name
FROM employees
WHERE salary BETWEEN 55000 AND 70000 AND dept_id = 101;

-- With salary first, the index is ordered by salary across all departments
-- A salary range can span multiple departments
-- Putting dept_id first limits this query to a single department before applying the salary range

-- 4.1
ALTER TABLE employees ADD COLUMN email VARCHAR(254);

UPDATE employees
SET email = 'employee' || emp_id || '@example.com';

CREATE UNIQUE INDEX emp_email_unique_idx ON employees (email);

DO $$
BEGIN
    INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
    VALUES (9000, 'Duplicate Email Test', 101, 50000, 'employee1@example.com');
    RAISE EXCEPTION 'Expected a unique index violation';
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE '4.1 [%] %', SQLSTATE, SQLERRM;
END;
$$;

-- 4.2
ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;

SELECT i.indexname, i.indexdef, c.conname AS constraint_name
FROM pg_indexes AS i
JOIN pg_class AS idx ON idx.oid = to_regclass(format('%I.%I', i.schemaname, i.indexname))
LEFT JOIN pg_constraint AS c ON c.conindid = idx.oid AND c.contype = 'u'
WHERE i.schemaname = 'public' AND i.tablename = 'employees'
  AND i.indexname IN ('emp_email_unique_idx', 'employees_phone_key')
ORDER BY i.indexname;

-- Both definitions enforce uniqueness with a unique B-tree
-- The phone constraint also has a pg_constraint entry and owns its backing index

-- 5.1
CREATE INDEX emp_salary_desc_idx ON employees (salary DESC);

SET LOCAL enable_seqscan = off;

EXPLAIN
SELECT emp_id, emp_name, salary
FROM employees
ORDER BY salary DESC;

SET LOCAL enable_seqscan = DEFAULT;

-- An ordered B-tree scan can return salaries in descending order without a separate Sort
-- PostgreSQL can also scan the ascending single-column index backward for this order

-- 5.2
CREATE INDEX proj_budget_nulls_first_idx ON projects (budget NULLS FIRST);

SELECT project_name, budget
FROM projects
ORDER BY budget ASC NULLS FIRST;

SET LOCAL enable_seqscan = off;

EXPLAIN
SELECT project_name, budget
FROM projects
ORDER BY budget ASC NULLS FIRST;

SET LOCAL enable_seqscan = DEFAULT;

-- 6.1
CREATE INDEX emp_name_lower_idx ON employees (LOWER(emp_name));

SELECT emp_id, emp_name
FROM employees
WHERE LOWER(emp_name) = LOWER('JOHN SMITH');

-- The index stores LOWER(emp_name)
-- An equality predicate using that expression can look up the normalized value directly

-- 6.2
ALTER TABLE employees ADD COLUMN hire_date DATE;

UPDATE employees
SET hire_date = make_date(2020 + emp_id % 5, 6, 15);

CREATE INDEX emp_hire_year_idx ON employees (EXTRACT(YEAR FROM hire_date));

SELECT emp_id, emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2021
ORDER BY emp_id;

EXPLAIN
SELECT emp_id, emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2021;

-- 7.1
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

-- 7.2
DROP INDEX emp_salary_dept_idx;

-- The lab retains the salary index and the department-first composite index
-- Removing the unused salary-first composite index saves storage and avoids maintaining its entries on writes

-- 7.3
REINDEX INDEX employees_salary_index;

-- REINDEX rebuilds an index after significant bloat or damage
-- A large bulk change can justify a rebuild if measurements show excessive bloat
-- ANALYZE refreshes planner statistics

-- 8.1
ANALYZE departments;
ANALYZE employees;

EXPLAIN (ANALYZE, BUFFERS, TIMING OFF)
SELECT e.emp_name, e.salary, d.dept_name
FROM employees AS e
JOIN departments AS d ON d.dept_id = e.dept_id
WHERE d.dept_id IN (101, 103) AND e.salary > 60000;

CREATE INDEX emp_salary_filter_idx
ON employees (dept_id, salary) INCLUDE (emp_name)
WHERE salary > 60000;

EXPLAIN (ANALYZE, BUFFERS, TIMING OFF)
SELECT e.emp_name, e.salary, d.dept_name
FROM employees AS e
JOIN departments AS d ON d.dept_id = e.dept_id
WHERE d.dept_id IN (101, 103) AND e.salary > 60000;

-- The partial index stores only employees above 60000 
-- The included name can support an index-only scan of employees when visibility permits
-- The planner may still choose a sequential scan on the sample data

-- 8.2
CREATE INDEX proj_high_budget_idx ON projects (budget)
WHERE budget > 80000;

SELECT project_name, budget
FROM projects
WHERE budget > 80000
ORDER BY budget;

-- Indexing only qualifying projects reduces the number of entries
-- On a larger table this can reduce disk and cache usage
-- PostgreSQL can use the index when the query predicate implies budget > 80000

-- 8.3
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF)
SELECT emp_name, salary FROM employees WHERE salary > 60000;

SET LOCAL enable_seqscan = off;

EXPLAIN (ANALYZE, BUFFERS, TIMING OFF)
SELECT emp_name, salary FROM employees WHERE salary > 60000;

SET LOCAL enable_seqscan = DEFAULT;

-- For a small table it can be cheaper to read its few pages in sequence
-- Temporarily discouraging sequential scans shows an available index plan
-- The actual costs and buffers depend on the data and server

-- 9.1
CREATE INDEX dept_name_hash_idx ON departments USING hash (dept_name);

SET LOCAL enable_seqscan = off;

EXPLAIN SELECT * FROM departments WHERE dept_name = 'IT';

SET LOCAL enable_seqscan = DEFAULT;

-- Hash indexes are suited to exact equality lookups, such as finding a department by its full name

-- 9.2
CREATE INDEX proj_name_hash_idx ON projects USING hash (project_name);

SET LOCAL enable_seqscan = off;

EXPLAIN SELECT * FROM projects WHERE project_name = 'Database';

EXPLAIN SELECT * FROM projects WHERE project_name > 'Database';

CREATE INDEX proj_name_btree_idx ON projects USING btree (project_name);

EXPLAIN SELECT * FROM projects WHERE project_name = 'Database';

EXPLAIN SELECT * FROM projects WHERE project_name > 'Database';

SET LOCAL enable_seqscan = DEFAULT;

-- Both index types can serve equality
-- The B-tree preserves key order and supports the greater-than predicate
-- The hash index cannot serve that predicate

-- 10.1
SELECT tbl.relname AS table_name, idx.relname AS index_name,
       am.amname AS index_type,
       pg_relation_size(idx.oid) AS size_bytes,
       pg_size_pretty(pg_relation_size(idx.oid)) AS index_size
FROM pg_index AS i
JOIN pg_class AS idx ON idx.oid = i.indexrelid
JOIN pg_class AS tbl ON tbl.oid = i.indrelid
JOIN pg_namespace AS n ON n.oid = idx.relnamespace
JOIN pg_am AS am ON am.oid = idx.relam
WHERE n.nspname = 'public'
ORDER BY size_bytes DESC, index_name;

-- A hash index allocates a metapage, bucket pages and, when needed, overflow and bitmap pages
-- Its initial page allocation differs from the root and leaf page layout of a B-tree

-- 10.2
DROP INDEX proj_name_hash_idx;

-- 10.3
CREATE VIEW index_documentation AS
SELECT i.tablename AS table_name, i.indexname AS index_name, i.indexdef AS definition,
       documentation.objective
FROM pg_indexes AS i
JOIN (VALUES
    ('employees_salary_index', 'Salary range filters'),
    ('emp_dept_idx', 'Department joins and foreign key lookups'),
    ('emp_dept_salary_idx', 'Department equality with a salary range'),
    ('emp_email_unique_idx', 'Enforce unique email addresses'),
    ('emp_salary_desc_idx', 'Return salaries in descending order'),
    ('proj_budget_nulls_first_idx', 'Sort project budgets with NULL values first'),
    ('emp_name_lower_idx', 'Case-insensitive employee name lookups'),
    ('emp_hire_year_idx', 'Filter employees by hiring year'),
    ('emp_salary_filter_idx', 'Cover department and salary queries for high earners'),
    ('proj_high_budget_idx', 'Filter projects with budgets above 80000'),
    ('dept_name_hash_idx', 'Exact department name lookups'),
    ('proj_name_btree_idx', 'Project name equality and range lookups')
) AS documentation(index_name, objective) ON documentation.index_name = i.indexname
WHERE i.schemaname = 'public';

SELECT * FROM index_documentation ORDER BY table_name, index_name;
