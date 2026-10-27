-- 1.1
CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id INT REFERENCES departments(dept_id),
    salary DECIMAL(10,2)
);

CREATE TABLE projects (
    project_id INT PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id INT REFERENCES departments(dept_id),
    budget DECIMAL(10,2)
);

-- 1.2
INSERT INTO departments (dept_id, dept_name, location) VALUES
    (1, 'IT', 'New York'),
    (2, 'HR', 'Chicago'),
    (3, 'Finance', 'New York'),
    (4, 'Marketing', 'Boston');

INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
    (1, 'John Smith', 1, 70000.00),
    (2, 'Alice Johnson', 1, 60000.00),
    (3, 'Mary Wilson', 2, 45000.00),
    (4, 'James Davis', 3, 80000.00),
    (5, 'Tom Brown', NULL, 40000.00);

INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
    (1, 'Website Redesign', 1, 100000.00),
    (2, 'Cloud Migration', 1, 150000.00),
    (3, 'Recruitment', 2, 30000.00),
    (4, 'Independent Research', NULL, 25000.00);

-- 2.1
SELECT e.emp_id, e.emp_name, d.dept_id, d.dept_name
FROM employees AS e
CROSS JOIN departments AS d;

SELECT COUNT(*) AS row_count
FROM employees AS e
CROSS JOIN departments AS d;

-- 2.2.a
SELECT e.emp_id, e.emp_name, d.dept_id, d.dept_name
FROM employees AS e, departments AS d;

-- 2.2.b
SELECT e.emp_id, e.emp_name, d.dept_id, d.dept_name
FROM employees AS e
INNER JOIN departments AS d ON TRUE;

-- 2.3
SELECT e.emp_id, e.emp_name, p.project_id, p.project_name
FROM employees AS e
CROSS JOIN projects AS p;

-- 3.1
SELECT e.emp_id, e.emp_name, d.dept_name, d.location
FROM employees AS e
INNER JOIN departments AS d ON e.dept_id = d.dept_id;

-- 3.2
SELECT dept_id, e.emp_id, e.emp_name, d.dept_name, d.location
FROM employees AS e
INNER JOIN departments AS d USING (dept_id);

-- 3.3
SELECT emp_id, emp_name, dept_name, location
FROM employees
NATURAL INNER JOIN departments;

-- 3.4
SELECT e.emp_id, e.emp_name, d.dept_name, p.project_name
FROM employees AS e
INNER JOIN departments AS d ON e.dept_id = d.dept_id
INNER JOIN projects AS p ON d.dept_id = p.dept_id;

-- 4.1
SELECT e.emp_id, e.emp_name, d.dept_id, d.dept_name, d.location
FROM employees AS e
LEFT JOIN departments AS d ON e.dept_id = d.dept_id;

-- 4.2
SELECT e.emp_id, e.emp_name, dept_id, d.dept_name, d.location
FROM employees AS e
LEFT JOIN departments AS d USING (dept_id);

-- 4.3
SELECT e.emp_id, e.emp_name, e.dept_id
FROM employees AS e
LEFT JOIN departments AS d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;

-- 4.4
SELECT d.dept_id, d.dept_name, COUNT(e.emp_id) AS employee_count
FROM departments AS d
LEFT JOIN employees AS e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC, d.dept_id;

-- 5.1
SELECT d.dept_id, d.dept_name, d.location, e.emp_id, e.emp_name
FROM employees AS e
RIGHT JOIN departments AS d ON e.dept_id = d.dept_id;

-- 5.2
SELECT d.dept_id, d.dept_name, d.location, e.emp_id, e.emp_name
FROM departments AS d
LEFT JOIN employees AS e ON d.dept_id = e.dept_id;

-- 5.3
SELECT d.dept_id, d.dept_name, d.location
FROM employees AS e
RIGHT JOIN departments AS d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;

-- 6.1
SELECT e.emp_id, e.emp_name, e.dept_id AS employee_dept_id,
       d.dept_id, d.dept_name, d.location
FROM employees AS e
FULL OUTER JOIN departments AS d ON e.dept_id = d.dept_id;

-- 6.2
SELECT d.dept_id, d.dept_name, p.project_id, p.project_name,
       p.dept_id AS project_dept_id, p.budget
FROM departments AS d
FULL OUTER JOIN projects AS p ON d.dept_id = p.dept_id;

-- 6.3
SELECT e.emp_id, e.emp_name, d.dept_id, d.dept_name,
       CASE
           WHEN e.emp_id IS NULL THEN 'Department without employees'
           WHEN d.dept_id IS NULL THEN 'Employee without department'
       END AS record_type
FROM employees AS e
FULL OUTER JOIN departments AS d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL;

-- 7.1
SELECT e.emp_id, e.emp_name, d.dept_name, d.location
FROM employees AS e
LEFT JOIN departments AS d
    ON e.dept_id = d.dept_id AND d.location = 'New York';

-- 7.2
SELECT e.emp_id, e.emp_name, d.dept_name, d.location
FROM employees AS e
LEFT JOIN departments AS d ON e.dept_id = d.dept_id
WHERE d.location = 'New York';

-- 7.3
SELECT e.emp_id, e.emp_name, d.dept_name, d.location
FROM employees AS e
INNER JOIN departments AS d
    ON e.dept_id = d.dept_id AND d.location = 'New York';

SELECT e.emp_id, e.emp_name, d.dept_name, d.location
FROM employees AS e
INNER JOIN departments AS d ON e.dept_id = d.dept_id
WHERE d.location = 'New York';

-- 8.1
SELECT d.dept_id, d.dept_name, e.emp_id, e.emp_name,
       p.project_id, p.project_name
FROM departments AS d
LEFT JOIN employees AS e ON d.dept_id = e.dept_id
LEFT JOIN projects AS p ON d.dept_id = p.dept_id;

-- 8.2
ALTER TABLE employees
ADD COLUMN manager_id INT REFERENCES employees(emp_id);

UPDATE employees
SET manager_id = 1
WHERE emp_id IN (2, 3, 4, 5);

SELECT e.emp_id, e.emp_name, m.emp_id AS manager_id,
       m.emp_name AS manager_name
FROM employees AS e
LEFT JOIN employees AS m ON e.manager_id = m.emp_id;

-- 8.3
SELECT d.dept_id, d.dept_name, AVG(e.salary) AS average_salary
FROM departments AS d
INNER JOIN employees AS e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;
