-- Part A
-- Task 1
CREATE TABLE medical_staff (
    staff_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    specialty VARCHAR(150) DEFAULT 'General Medicine',
    salary INTEGER DEFAULT 50000,
    hire_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(50) DEFAULT 'Active'
);

CREATE TABLE medical_departments (
    dept_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dept_name VARCHAR(150) NOT NULL,
    budget INTEGER NOT NULL,
    head_staff_id INTEGER REFERENCES medical_staff(staff_id)
);

CREATE TABLE clinical_trials (
    trial_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trial_name VARCHAR(200) NOT NULL,
    dept_id INTEGER REFERENCES medical_departments(dept_id) ON DELETE SET NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    budget INTEGER NOT NULL
);

INSERT INTO medical_departments (dept_name, budget)
VALUES
    ('Research', 250000),
    ('Emergency', 280000),
    ('Oncology', 350000);

INSERT INTO medical_staff (first_name, last_name, specialty, salary, hire_date, status)
VALUES
    ('Elena', 'Morozova', 'Cardiology', 90000, DATE '2019-06-15', 'Active'),
    ('Mark', 'Petrov', 'Pediatrics', 60000, DATE '2021-04-10', 'Active'),
    ('Nora', 'Kim', 'Neurology', 65000, DATE '2021-09-01', 'Active'),
    ('Oleg', 'Sidorov', NULL, 40000, DATE '2024-02-01', 'Resigned'),
    ('Rita', 'Volkova', NULL, 43000, DATE '2024-03-10', 'Active');

INSERT INTO clinical_trials (trial_name, dept_id, start_date, end_date, budget)
VALUES
    ('Completed Oncology Study', 3, DATE '2023-01-10', DATE '2023-12-20', 55000),
    ('Emergency Response Study', 2, DATE '2024-07-01', DATE '2026-12-31', 90000);

-- Part B
-- Task 2
INSERT INTO medical_staff (first_name, last_name, specialty)
VALUES ('Amina', 'Iskakova', 'Cardiology');

-- Task 3
INSERT INTO medical_staff (first_name, last_name, specialty, salary, hire_date, status)
VALUES ('David', 'Lee', 'Pediatrics', DEFAULT, DATE '2021-03-15', DEFAULT);

-- Task 4 ---
INSERT INTO medical_departments (dept_name, budget)
VALUES
    ('Chief Medical Officer', 450000),
    ('Senior Specialist', 320000),
    ('Junior Resident', 400000);

INSERT INTO clinical_trials (trial_name, dept_id, start_date, end_date, budget)
VALUES (
    'Neurology Innovation Trial',
    (SELECT dept_id FROM medical_departments WHERE dept_name = 'Senior Specialist' ORDER BY dept_id DESC LIMIT 1),
    DATE '2025-01-15',
    DATE '2026-06-30',
    90000
);

-- Task 5
INSERT INTO medical_staff (first_name, last_name, specialty, salary, hire_date, status)
VALUES ('Ivan', 'Romanov', 'Neurology', 55000 * 1.15, CURRENT_DATE, 'Resigned');

-- Task 6 ---
CREATE TEMPORARY TABLE temp_staff AS
SELECT *
FROM medical_staff
WHERE specialty = 'Cardiology';

-- Part C
-- Task 7
UPDATE medical_staff
SET salary = salary * 1.10;

-- Task 8
UPDATE medical_staff
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < DATE '2022-01-01';

-- Task 9
UPDATE medical_staff
SET specialty = CASE
    WHEN salary > 80000 THEN 'Chief Medical Officer'
    WHEN salary BETWEEN 55000 AND 80000 THEN 'Senior Specialist'
    ELSE 'Junior Resident'
END;

-- Task 10
UPDATE medical_staff
SET specialty = DEFAULT
WHERE status = 'Inactive';

-- Task 11 ---
UPDATE medical_departments AS md
SET budget = COALESCE(
    (
        SELECT ROUND(AVG(ms.salary) * 1.25)::INTEGER
        FROM medical_staff AS ms
        WHERE ms.specialty = md.dept_name
    ),
    md.budget
);

-- Task 12
UPDATE medical_staff
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE specialty = 'Pediatrics';

-- Part D
-- Task 13
DELETE FROM medical_staff
WHERE status = 'Resigned';

-- Task 14
DELETE FROM medical_staff
WHERE salary < 45000
  AND hire_date > DATE '2023-01-01'
  AND specialty IS NULL;

-- Task 15 ---
DELETE FROM medical_departments
WHERE dept_name NOT IN (
    SELECT DISTINCT specialty
    FROM medical_staff
    WHERE specialty IS NOT NULL
);

-- Task 16 ---
DELETE FROM clinical_trials
WHERE end_date < DATE '2024-01-01'
RETURNING *;

-- Part E
-- Task 17
INSERT INTO medical_staff (first_name, last_name, specialty, salary)
VALUES ('Sofia', 'Ivanova', NULL, NULL);

-- Task 18
UPDATE medical_staff
SET specialty = 'Unassigned'
WHERE specialty IS NULL;

-- Task 19
DELETE FROM medical_staff
WHERE salary IS NULL
   OR specialty IS NULL;

-- Part F
-- Task 20 ---
INSERT INTO medical_staff (first_name, last_name, specialty, salary)
VALUES ('Maya', 'Alimova', 'Neurology', 62000)
RETURNING staff_id, first_name || ' ' || last_name AS full_name;

-- Task 21 ---
WITH previous_salaries AS (
    SELECT staff_id, salary AS old_salary
    FROM medical_staff
    WHERE specialty = 'Neurology'
), updated_staff AS (
    UPDATE medical_staff AS ms
    SET salary = ms.salary + 6000
    FROM previous_salaries AS ps
    WHERE ms.staff_id = ps.staff_id
    RETURNING ms.staff_id, ms.salary AS new_salary
)
SELECT us.staff_id, ps.old_salary, us.new_salary
FROM updated_staff AS us
JOIN previous_salaries AS ps ON ps.staff_id = us.staff_id;

-- Task 22 ---
DELETE FROM medical_staff
WHERE hire_date < DATE '2020-01-01'
RETURNING *;

-- Part G
-- Task 23 ---
INSERT INTO medical_staff (first_name, last_name, specialty, salary, status)
SELECT 'Arman', 'Tulegenov', 'General Medicine', 52000, 'Inactive'
WHERE NOT EXISTS (
    SELECT 1
    FROM medical_staff
    WHERE first_name = 'Arman'
      AND last_name = 'Tulegenov'
);

-- Task 24 ---
UPDATE medical_staff AS ms
SET salary = ms.salary * CASE
    WHEN md.budget > 300000 THEN 1.10
    ELSE 1.05
END
FROM medical_departments AS md
WHERE ms.specialty = md.dept_name;

-- Task 25 ---
INSERT INTO medical_staff (first_name, last_name, specialty, salary)
VALUES
    ('Bulk', 'One', 'Senior Specialist', 50000),
    ('Bulk', 'Two', 'Senior Specialist', 51000),
    ('Bulk', 'Three', 'Senior Specialist', 52000),
    ('Bulk', 'Four', 'Senior Specialist', 53000),
    ('Bulk', 'Five', 'Senior Specialist', 54000);

UPDATE medical_staff
SET salary = salary * 1.10
WHERE first_name = 'Bulk'
  AND last_name IN ('One', 'Two', 'Three', 'Four', 'Five');

-- Task 26 ---
CREATE TABLE staff_archive (LIKE medical_staff INCLUDING ALL);

WITH moved_staff AS (
    DELETE FROM medical_staff
    WHERE status = 'Inactive'
    RETURNING *
)
INSERT INTO staff_archive
SELECT * FROM moved_staff;

-- Task 27 ---
UPDATE clinical_trials AS ct
SET end_date = ct.end_date + 45
WHERE ct.budget > 60000
  AND (
      SELECT COUNT(*)
      FROM medical_staff AS ms
      WHERE ms.specialty = (
          SELECT md.dept_name
          FROM medical_departments AS md
          WHERE md.dept_id = ct.dept_id
      )
  ) > 2;