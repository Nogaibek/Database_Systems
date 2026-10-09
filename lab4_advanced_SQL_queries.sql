DROP TABLE IF EXISTS assignments;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    department VARCHAR(50) NOT NULL,
    salary NUMERIC(12, 2) NOT NULL,
    hire_date DATE NOT NULL,
    manager_id INTEGER REFERENCES employees(employee_id),
    email VARCHAR(255)
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    budget NUMERIC(14, 2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR(20) NOT NULL
);

CREATE TABLE assignments (
    assignment_id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES employees(employee_id),
    project_id INTEGER NOT NULL REFERENCES projects(project_id),
    hours_worked NUMERIC(8, 2) NOT NULL CHECK (hours_worked >= 0),
    assignment_date DATE NOT NULL
);

INSERT INTO employees (first_name, last_name, department, salary, hire_date, manager_id, email) VALUES
('Alice', 'Smith', 'IT', 85000.00, '2018-03-15', NULL, 'alice.smith@example.com'),
('Bob', 'Johnson', 'IT', 68000.00, '2021-06-10', 1, 'bob.johnson@example.com'),
('Carol', 'Williams', 'Sales', 62000.00, '2019-09-01', NULL, 'carol.williams@example.com'),
('David', 'Brown', 'Sales', 72000.00, '2022-01-20', 3, NULL),
('Eva', 'Jones', 'HR', 60000.00, '2020-07-05', NULL, 'eva.jones@example.com'),
('Frank', 'Miller', 'IT', 75000.00, '2017-11-12', 1, 'frank.miller@example.com'),
('Grace', 'Davis', 'Finance', 95000.00, '2023-02-14', NULL, 'grace.davis@example.com'),
('Henry', 'Wilson', 'Finance', 67000.00, '2021-10-30', 7, 'henry.wilson@example.com'),
('Irene', 'Taylor', 'HR', 58000.00, '2019-04-18', 5, 'irene.taylor@example.com'),
('Jack', 'Anderson', 'Sales', 66000.00, '2020-12-01', 3, 'jack.anderson@example.com'),
('Kate', 'Moore', 'IT', 64000.00, '2024-03-11', 1, NULL),
('Leo', 'Martin', 'Operations', 59000.00, '2022-08-23', NULL, 'leo.martin@example.com');

INSERT INTO projects (project_name, budget, start_date, end_date, status) VALUES
('Cloud Migration', 200000.00, '2024-01-01', '2024-12-31', 'Active'),
('Sales Dashboard', 125000.00, '2024-02-01', '2024-10-31', 'Active'),
('HR Portal', 90000.00, '2024-03-01', '2024-08-31', 'Completed'),
('Security Audit', 160000.00, '2024-04-01', NULL, 'Active'),
('Archive Cleanup', 50000.00, '2024-05-01', NULL, 'Planned');

INSERT INTO assignments (employee_id, project_id, hours_worked, assignment_date) VALUES
(1, 1, 80.00, '2024-01-15'),
(2, 1, 75.00, '2024-01-20'),
(6, 1, 60.00, '2024-02-01'),
(11, 1, 20.00, '2024-03-15'),
(3, 2, 70.00, '2024-02-10'),
(4, 2, 65.00, '2024-02-20'),
(10, 2, 40.00, '2024-03-01'),
(5, 3, 45.00, '2024-03-10'),
(9, 3, 35.00, '2024-03-12'),
(1, 4, 55.00, '2024-04-10'),
(2, 4, 50.00, '2024-04-15'),
(6, 4, 55.00, '2024-04-20'),
(7, 4, 30.00, '2024-04-25');

-- Task 1.1
SELECT first_name || ' ' || last_name AS full_name, department, salary
FROM employees;

-- Task 1.2
SELECT DISTINCT department
FROM employees;

-- Task 1.3
SELECT project_name, budget,
       CASE
           WHEN budget > 150000 THEN 'Large'
           WHEN budget BETWEEN 100000 AND 150000 THEN 'Medium'
           ELSE 'Small'
       END AS budget_category
FROM projects;

-- Task 1.4
SELECT first_name || ' ' || last_name AS full_name,
       COALESCE(email, 'No email provided') AS email
FROM employees;

-- Task 2.1
SELECT *
FROM employees
WHERE hire_date > DATE '2020-01-01';

-- Task 2.2
SELECT *
FROM employees
WHERE salary BETWEEN 60000 AND 70000;

-- Task 2.3
SELECT *
FROM employees
WHERE last_name ILIKE 'S%' OR last_name ILIKE 'J%';

-- Task 2.4
SELECT *
FROM employees
WHERE manager_id IS NOT NULL
  AND department = 'IT';

-- Task 3.1
SELECT UPPER(first_name || ' ' || last_name) AS full_name_upper,
       CHAR_LENGTH(last_name) AS last_name_length,
       LEFT(SPLIT_PART(email, '@', 1), 3) AS email_prefix_first_3
FROM employees;

-- Task 3.2
SELECT first_name || ' ' || last_name AS full_name,
       salary * 12 AS annual_salary,
       ROUND(salary / 12, 2) AS monthly_salary,
       salary * 0.10 AS raise_amount
FROM employees;

-- Task 3.3
SELECT 'Project: ' || project_name || ' - Budget: $' || budget || ' - Status: ' || status AS project_summary
FROM projects;

-- Task 3.4
SELECT first_name || ' ' || last_name AS full_name,
       EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date))::INTEGER AS completed_years
FROM employees;

-- Task 4.1
SELECT department, ROUND(AVG(salary), 2) AS average_salary
FROM employees
GROUP BY department;

-- Task 4.2
SELECT p.project_name,
       COALESCE(SUM(a.hours_worked), 0) AS total_hours
FROM projects AS p
LEFT JOIN assignments AS a ON a.project_id = p.project_id
GROUP BY p.project_id, p.project_name;

-- Task 4.3
SELECT department, COUNT(*) AS employee_count
FROM employees
GROUP BY department
HAVING COUNT(*) > 1;

-- Task 4.4
SELECT MIN(salary) AS lowest_salary,
       MAX(salary) AS highest_salary,
       SUM(salary) AS total_payroll
FROM employees;

-- Task 5.1
SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
FROM employees
WHERE salary > 65000
UNION
SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
FROM employees
WHERE hire_date > DATE '2020-01-01';

-- Task 5.2
SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
FROM employees
WHERE department = 'IT'
INTERSECT
SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
FROM employees
WHERE salary > 65000;

-- Task 5.3
SELECT employee_id, first_name || ' ' || last_name AS full_name, department, salary
FROM employees
EXCEPT
SELECT e.employee_id, e.first_name || ' ' || e.last_name AS full_name, e.department, e.salary
FROM employees AS e
JOIN assignments AS a ON a.employee_id = e.employee_id;

-- Task 6.1
SELECT e.*
FROM employees AS e
WHERE EXISTS (
    SELECT 1
    FROM assignments AS a
    WHERE a.employee_id = e.employee_id
);

-- Task 6.2
SELECT DISTINCT e.*
FROM employees AS e
JOIN assignments AS a ON a.employee_id = e.employee_id
JOIN projects AS p ON p.project_id = a.project_id
WHERE p.status = 'Active';

-- Task 6.3
SELECT *
FROM employees
WHERE salary > ANY (
    SELECT salary
    FROM employees
    WHERE department = 'Sales'
);

-- Task 7.1
SELECT e.first_name || ' ' || e.last_name AS full_name,
       e.department,
       ROUND(COALESCE(AVG(a.hours_worked), 0), 2) AS average_hours_per_assignment,
       RANK() OVER (PARTITION BY e.department ORDER BY e.salary DESC) AS department_salary_rank
FROM employees AS e
LEFT JOIN assignments AS a ON a.employee_id = e.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name, e.department, e.salary;

-- Task 7.2
SELECT p.project_name,
       SUM(a.hours_worked) AS total_hours,
       COUNT(DISTINCT a.employee_id) AS employee_count
FROM projects AS p
JOIN assignments AS a ON a.project_id = p.project_id
GROUP BY p.project_id, p.project_name
HAVING SUM(a.hours_worked) > 150;

-- Task 7.3
WITH department_stats AS (
    SELECT department,
           COUNT(*) AS employee_count,
           ROUND(AVG(salary), 2) AS average_salary,
           MIN(salary) AS minimum_salary,
           MAX(salary) AS maximum_salary
    FROM employees
    GROUP BY department
),
highest_paid AS (
    SELECT DISTINCT ON (department)
           department,
           first_name || ' ' || last_name AS highest_paid_employee
    FROM employees
    ORDER BY department, salary DESC, employee_id
)
SELECT ds.department,
       ds.employee_count,
       ds.average_salary,
       hp.highest_paid_employee,
       ds.minimum_salary >= ALL (VALUES (50000::NUMERIC), (55000::NUMERIC)) AS meets_minimum_thresholds,
       ds.maximum_salary <= ALL (VALUES (100000::NUMERIC), (120000::NUMERIC)) AS meets_maximum_thresholds
FROM department_stats AS ds
JOIN highest_paid AS hp ON hp.department = ds.department
ORDER BY ds.department;