-- 1.1
BEGIN;

SET LOCAL search_path = public;

REVOKE CREATE ON SCHEMA public FROM PUBLIC;

CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id INT REFERENCES departments(dept_id),
    salary DECIMAL(10,2),
    manager_id INT REFERENCES employees(emp_id)
);

CREATE TABLE projects (
    project_id INT PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id INT REFERENCES departments(dept_id),
    budget DECIMAL(10,2)
);

INSERT INTO departments (dept_id, dept_name, location) VALUES
    (101, 'IT', 'New York'),
    (102, 'HR', 'Chicago'),
    (103, 'Finance', 'New York'),
    (104, 'Marketing', 'Boston');

INSERT INTO employees (emp_id, emp_name, dept_id, salary, manager_id) VALUES
    (1, 'John Smith', 101, 70000.00, NULL),
    (2, 'Alice Johnson', 101, 60000.00, 1),
    (3, 'Mary Wilson', 102, 45000.00, 1),
    (4, 'James Davis', 103, 80000.00, 1),
    (5, 'Tom Brown', NULL, 40000.00, 1);

INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
    (1, 'Website Redesign', 101, 100000.00),
    (2, 'Cloud Migration', 101, 150000.00),
    (3, 'Recruitment', 102, 30000.00),
    (4, 'Independent Research', NULL, 25000.00),
    (5, 'Database', 103, NULL);


-- 2.1
CREATE VIEW employee_details AS
SELECT e.emp_name, e.salary, d.dept_name, d.location
FROM employees AS e
JOIN departments AS d ON d.dept_id = e.dept_id;

SELECT * FROM employee_details ORDER BY emp_name;

SELECT 'Tom Brown is excluded because his dept_id is NULL and the INNER JOIN requires a matching department.' AS explanation;

-- 2.2
CREATE VIEW dept_statistics AS
SELECT d.dept_name,
       COUNT(e.emp_id) AS headcount,
       AVG(e.salary) AS average_salary,
       MAX(e.salary) AS maximum_salary,
       MIN(e.salary) AS minimum_salary
FROM departments AS d
LEFT JOIN employees AS e ON e.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name;

SELECT * FROM dept_statistics ORDER BY dept_name;

-- 2.3
CREATE VIEW project_overview AS
SELECT p.project_name, p.budget, d.dept_name, d.location,
       COALESCE(staff.team_size, 0) AS team_size
FROM projects AS p
LEFT JOIN departments AS d ON d.dept_id = p.dept_id
LEFT JOIN (
    SELECT dept_id, COUNT(*) AS team_size
    FROM employees
    GROUP BY dept_id
) AS staff ON staff.dept_id = p.dept_id;

SELECT * FROM project_overview ORDER BY project_name;

-- 2.4
CREATE VIEW high_earners AS
SELECT e.emp_name, e.salary, d.dept_name
FROM employees AS e
LEFT JOIN departments AS d ON d.dept_id = e.dept_id
WHERE e.salary > 55000;

SELECT * FROM high_earners ORDER BY salary DESC, emp_name;


-- 3.1
CREATE OR REPLACE VIEW employee_details AS
SELECT e.emp_name, e.salary, d.dept_name, d.location,
       CASE
           WHEN e.salary > 60000 THEN 'High'
           WHEN e.salary > 50000 THEN 'Medium'
           ELSE 'Standard'
       END AS salary_grade
FROM employees AS e
JOIN departments AS d ON d.dept_id = e.dept_id;

SELECT emp_name, salary, salary_grade FROM employee_details ORDER BY emp_name;

-- 3.2
ALTER VIEW high_earners RENAME TO top_performers;

SELECT * FROM top_performers ORDER BY salary DESC, emp_name;

-- 3.3
CREATE VIEW temp_view AS
SELECT emp_id, emp_name, salary
FROM employees
WHERE salary < 50000;

SELECT * FROM temp_view ORDER BY emp_id;

DROP VIEW IF EXISTS temp_view;


-- 4.1
CREATE VIEW employee_salaries AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees;

-- 4.2
UPDATE employee_salaries
SET salary = 52000
WHERE emp_id = 1 AND emp_name = 'John Smith';

SELECT emp_id, emp_name, salary FROM employees WHERE emp_id = 1;

-- 4.3
INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary)
VALUES (6, 'Alice Johnson', 102, 58000);

SELECT emp_id, emp_name, dept_id, salary FROM employees WHERE emp_id = 6;

-- 4.4
CREATE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 101
WITH LOCAL CHECK OPTION;

DO $$
BEGIN
    INSERT INTO it_employees (emp_id, emp_name, dept_id, salary)
    VALUES (7, 'Bob Wilson', 103, 56000);
    RAISE EXCEPTION 'Exercise 4.4: expected CHECK OPTION violation';
EXCEPTION
    WHEN SQLSTATE '44000' THEN
        RAISE NOTICE 'Exercise 4.4 [%] %', SQLSTATE, SQLERRM;
END;
$$;


-- 5.1
CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT d.dept_id, d.dept_name,
       COALESCE(e.total_employees, 0) AS total_employees,
       COALESCE(e.total_salaries, 0) AS total_salaries,
       COALESCE(p.project_count, 0) AS project_count,
       COALESCE(p.total_project_budget, 0) AS total_project_budget
FROM departments AS d
LEFT JOIN (
    SELECT dept_id, COUNT(*) AS total_employees, SUM(salary) AS total_salaries
    FROM employees
    GROUP BY dept_id
) AS e ON e.dept_id = d.dept_id
LEFT JOIN (
    SELECT dept_id, COUNT(*) AS project_count, SUM(budget) AS total_project_budget
    FROM projects
    GROUP BY dept_id
) AS p ON p.dept_id = d.dept_id
WITH DATA;

SELECT * FROM dept_summary_mv ORDER BY dept_id;

-- 5.2
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES (7, 'Charlie Brown', 101, 57000);

SELECT 'before refresh' AS stage, total_employees, total_salaries
FROM dept_summary_mv
WHERE dept_id = 101;

REFRESH MATERIALIZED VIEW dept_summary_mv;

SELECT 'after refresh' AS stage, total_employees, total_salaries
FROM dept_summary_mv
WHERE dept_id = 101;

-- 5.3
CREATE UNIQUE INDEX dept_summary_mv_dept_id_uidx ON dept_summary_mv (dept_id);

COMMIT;

REFRESH MATERIALIZED VIEW CONCURRENTLY public.dept_summary_mv;

SELECT 'CONCURRENTLY lets other sessions read the previous snapshot during the refresh. It requires a populated view and a unique index covering all rows on plain columns.' AS explanation;

-- 5.4
BEGIN;

SET LOCAL search_path = public;

CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT dept_id, COUNT(*) AS project_count, SUM(budget) AS total_budget,
       AVG(budget) AS average_budget
FROM projects
GROUP BY dept_id
WITH NO DATA;

DO $$
BEGIN
    PERFORM 1 FROM project_stats_mv;
    RAISE EXCEPTION 'Exercise 5.4: expected unpopulated materialized view error';
EXCEPTION
    WHEN SQLSTATE '55000' THEN
        RAISE NOTICE 'Exercise 5.4 [%] %', SQLSTATE, SQLERRM;
END;
$$;

REFRESH MATERIALIZED VIEW project_stats_mv;

SELECT * FROM project_stats_mv ORDER BY dept_id NULLS LAST;


-- 6.1
CREATE ROLE analyst NOLOGIN;

CREATE ROLE data_viewer LOGIN PASSWORD 'viewer123';

CREATE ROLE report_user LOGIN PASSWORD 'report456';

SELECT rolname, rolcanlogin
FROM pg_roles
WHERE rolname IN ('analyst', 'data_viewer', 'report_user')
ORDER BY rolname;

-- 6.2
CREATE ROLE db_creator CREATEDB;

CREATE ROLE user_manager CREATEROLE;

CREATE ROLE admin_user SUPERUSER;

SELECT rolname, rolcreatedb, rolcreaterole, rolsuper
FROM pg_roles
WHERE rolname IN ('db_creator', 'user_manager', 'admin_user')
ORDER BY rolname;

-- 6.3
GRANT SELECT ON departments, employees, projects TO analyst;

GRANT ALL PRIVILEGES ON employee_details TO data_viewer;

GRANT SELECT, INSERT ON employees TO report_user;

-- 6.4
CREATE ROLE hr_team NOLOGIN;

CREATE ROLE finance_team NOLOGIN;

CREATE ROLE it_team NOLOGIN;

CREATE ROLE hr_user1 LOGIN INHERIT;

CREATE ROLE hr_user2 LOGIN INHERIT;

CREATE ROLE finance_user1 LOGIN INHERIT;

GRANT hr_team TO hr_user1, hr_user2;

GRANT finance_team TO finance_user1;

GRANT UPDATE ON employees TO hr_team;

GRANT SELECT ON projects TO finance_team;

GRANT SELECT ON it_employees TO it_team;

SELECT has_table_privilege('hr_user1', 'public.employees', 'UPDATE') AS hr_update_before;

-- 6.5
REVOKE UPDATE ON employees FROM hr_team;

REVOKE hr_team FROM hr_user2;

REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;

SELECT has_table_privilege('hr_user1', 'public.employees', 'UPDATE') AS hr_update,
       pg_has_role('hr_user2', 'hr_team', 'MEMBER') AS hr_user2_member,
       has_table_privilege('data_viewer', 'public.employee_details', 'SELECT') AS viewer_select;

-- 6.6
ALTER ROLE analyst LOGIN PASSWORD 'lab7_analyst_temp';

ALTER ROLE user_manager SUPERUSER;

ALTER ROLE analyst PASSWORD NULL;

ALTER ROLE data_viewer CONNECTION LIMIT 5;

SELECT rolname, rolcanlogin, rolsuper, rolconnlimit,
       rolpassword IS NULL AS password_is_null
FROM pg_authid
WHERE rolname IN ('analyst', 'user_manager', 'data_viewer')
ORDER BY rolname;


-- 7.1
CREATE ROLE read_only NOLOGIN;

GRANT USAGE ON SCHEMA public TO read_only;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

CREATE ROLE junior_analyst LOGIN INHERIT;

CREATE ROLE senior_analyst LOGIN INHERIT;

GRANT read_only TO junior_analyst, senior_analyst;

GRANT INSERT, UPDATE, DELETE ON employees, projects TO senior_analyst;

SELECT r.rolname,
       has_table_privilege(r.oid, 'public.employees', 'SELECT') AS can_select,
       has_table_privilege(r.oid, 'public.employees', 'UPDATE') AS can_update
FROM pg_roles AS r
WHERE r.rolname IN ('junior_analyst', 'senior_analyst')
ORDER BY r.rolname;

-- 7.2
CREATE ROLE project_manager NOLOGIN;

GRANT USAGE ON SCHEMA public TO project_manager;

GRANT SELECT ON departments, employees TO project_manager;

ALTER VIEW dept_statistics OWNER TO project_manager;

ALTER TABLE projects OWNER TO project_manager;

SELECT viewname AS object_name, viewowner AS owner
FROM pg_views
WHERE schemaname = 'public' AND viewname = 'dept_statistics'
UNION ALL
SELECT tablename, tableowner
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'projects';

-- 7.3
CREATE ROLE temp_owner NOLOGIN;

CREATE TABLE temp_table (id INT PRIMARY KEY);

ALTER TABLE temp_table OWNER TO temp_owner;

REASSIGN OWNED BY temp_owner TO CURRENT_USER;

DROP OWNED BY temp_owner;

DROP ROLE temp_owner;

SELECT to_regclass('public.temp_table') IS NOT NULL AS table_preserved,
       NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'temp_owner') AS role_removed;

-- 7.4
CREATE VIEW hr_employee_view WITH (security_barrier = true) AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 102;

CREATE VIEW finance_employee_view WITH (security_barrier = true) AS
SELECT emp_id, emp_name, salary
FROM employees;

GRANT USAGE ON SCHEMA public TO hr_team, finance_team, it_team;

GRANT SELECT ON hr_employee_view TO hr_team;

GRANT SELECT ON finance_employee_view TO finance_team;

SET LOCAL ROLE hr_user1;

SELECT emp_id, emp_name, dept_id,
       has_table_privilege(current_user, 'public.employees', 'SELECT') AS base_select
FROM hr_employee_view
ORDER BY emp_id;

RESET ROLE;

SET LOCAL ROLE finance_user1;

SELECT *,
       has_table_privilege(current_user, 'public.employees', 'SELECT') AS base_select
FROM finance_employee_view
ORDER BY emp_id;

RESET ROLE;


-- 8.1
CREATE VIEW dept_dashboard AS
SELECT d.dept_id, d.dept_name,
       COALESCE(e.headcount, 0) AS headcount,
       e.average_salary,
       COALESCE(p.project_count, 0) AS project_count,
       COALESCE(p.total_budget, 0) AS total_budget,
       COALESCE(p.total_budget, 0) / NULLIF(COALESCE(e.headcount, 0), 0) AS budget_per_employee
FROM departments AS d
LEFT JOIN (
    SELECT dept_id, COUNT(*) AS headcount, AVG(salary) AS average_salary
    FROM employees
    GROUP BY dept_id
) AS e ON e.dept_id = d.dept_id
LEFT JOIN (
    SELECT dept_id, COUNT(*) AS project_count, SUM(budget) AS total_budget
    FROM projects
    GROUP BY dept_id
) AS p ON p.dept_id = d.dept_id;

SELECT * FROM dept_dashboard ORDER BY dept_id;

-- 8.2
ALTER TABLE projects ADD COLUMN created_date DATE NOT NULL DEFAULT CURRENT_DATE;

CREATE VIEW high_budget_projects AS
SELECT p.project_id, p.project_name, p.budget, d.dept_name, p.created_date,
       CASE
           WHEN p.budget >= 100000 THEN 'Requires executive approval'
           ELSE 'Requires department approval'
       END AS approval_status
FROM projects AS p
LEFT JOIN departments AS d ON d.dept_id = p.dept_id
WHERE p.budget > 75000;

SELECT * FROM high_budget_projects ORDER BY budget DESC, project_id;

-- 8.3
CREATE ROLE viewer_role NOLOGIN INHERIT;

CREATE ROLE entry_role NOLOGIN INHERIT;

CREATE ROLE analyst_role NOLOGIN INHERIT;

CREATE ROLE manager_role NOLOGIN INHERIT;

GRANT USAGE ON SCHEMA public TO viewer_role;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;

GRANT viewer_role TO entry_role;

GRANT INSERT ON employees, projects TO entry_role;

GRANT entry_role TO analyst_role;

GRANT UPDATE ON employees, projects TO analyst_role;

GRANT analyst_role TO manager_role;

GRANT DELETE ON employees, projects TO manager_role;

CREATE ROLE alice LOGIN INHERIT;

CREATE ROLE bob LOGIN INHERIT;

CREATE ROLE charlie LOGIN INHERIT;

GRANT viewer_role TO alice;

GRANT analyst_role TO bob;

GRANT manager_role TO charlie;

SELECT r.rolname, t.table_name,
       has_table_privilege(r.oid, t.table_name, 'SELECT') AS can_select,
       has_table_privilege(r.oid, t.table_name, 'INSERT') AS can_insert,
       has_table_privilege(r.oid, t.table_name, 'UPDATE') AS can_update,
       has_table_privilege(r.oid, t.table_name, 'DELETE') AS can_delete
FROM pg_roles AS r
CROSS JOIN (VALUES ('public.employees'), ('public.projects')) AS t(table_name)
WHERE r.rolname IN ('alice', 'entry_role', 'bob', 'charlie')
ORDER BY CASE r.rolname WHEN 'alice' THEN 1 WHEN 'entry_role' THEN 2
                        WHEN 'bob' THEN 3 ELSE 4 END, t.table_name;

COMMIT;
