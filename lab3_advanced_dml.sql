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

-- Task 4
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

-- Task 6
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

-- Task 11
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

-- Task 15
DELETE FROM medical_departments
WHERE dept_name NOT IN (
    SELECT DISTINCT specialty
    FROM medical_staff
    WHERE specialty IS NOT NULL
);

-- Task 16
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