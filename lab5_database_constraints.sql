-- 1.1

CREATE OR REPLACE FUNCTION pg_temp.expect_error(statement TEXT, expected_state TEXT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    actual_state TEXT;
    error_message TEXT;
    error_detail TEXT;
BEGIN
    BEGIN
        EXECUTE statement;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS actual_state = RETURNED_SQLSTATE,
                                error_message = MESSAGE_TEXT,
                                error_detail = PG_EXCEPTION_DETAIL;
        IF actual_state <> expected_state THEN
            RAISE EXCEPTION 'Expected SQLSTATE %, received %: %', expected_state, actual_state, error_message;
        END IF;
        RAISE NOTICE 'SQLSTATE %: %; %', actual_state, error_message, error_detail;
        RETURN;
    END;
    RAISE EXCEPTION 'Expected SQLSTATE %, but statement succeeded: %', expected_state, statement;
END;
$$;

CREATE TABLE employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CHECK (salary > 0)
);

-- 1.2

CREATE TABLE products_catalog (
    product_id INTEGER,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0 AND discount_price > 0 AND discount_price < regular_price
    )
);

-- 1.3

CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);

-- 1.4

INSERT INTO employees VALUES
    (1, 'Alice', 'Smith', 18, 1500),
    (2, 'Bob', 'Jones', 65, 2500);
INSERT INTO products_catalog VALUES
    (1, 'Laptop', 1000, 900),
    (2, 'Phone', 500, 450);
INSERT INTO bookings VALUES
    (1, '2026-10-01', '2026-10-03', 1),
    (2, '2026-10-05', '2026-10-08', 10);
SELECT pg_temp.expect_error($test$INSERT INTO employees VALUES (3, 'Test', 'User', 17, 100)$test$, '23514');
SELECT pg_temp.expect_error($test$INSERT INTO employees VALUES (3, 'Test', 'User', 66, 100)$test$, '23514');
SELECT pg_temp.expect_error($test$INSERT INTO employees VALUES (3, 'Test', 'User', 25, 0)$test$, '23514');
SELECT pg_temp.expect_error($test$INSERT INTO employees VALUES (3, 'Test', 'User', 25, -1)$test$, '23514');
SELECT pg_temp.expect_error($test$INSERT INTO products_catalog VALUES (3, 'Test', 0, 1)$test$, '23514');
SELECT pg_temp.expect_error($test$INSERT INTO products_catalog VALUES (3, 'Test', 100, 0)$test$, '23514');
SELECT pg_temp.expect_error($test$INSERT INTO products_catalog VALUES (3, 'Test', 100, 100)$test$, '23514');
SELECT pg_temp.expect_error($test$INSERT INTO products_catalog VALUES (3, 'Test', 100, 110)$test$, '23514');
SELECT pg_temp.expect_error($test$INSERT INTO bookings VALUES (3, '2026-10-01', '2026-10-03', 0)$test$, '23514');
SELECT pg_temp.expect_error($test$INSERT INTO bookings VALUES (3, '2026-10-01', '2026-10-03', 11)$test$, '23514');
SELECT pg_temp.expect_error($test$INSERT INTO bookings VALUES (3, '2026-10-01', '2026-10-01', 2)$test$, '23514');
SELECT pg_temp.expect_error($test$INSERT INTO bookings VALUES (3, '2026-10-03', '2026-10-01', 2)$test$, '23514');

-- 2.1

CREATE TABLE customers (
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

-- 2.2

CREATE TABLE inventory (
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

-- 2.3

INSERT INTO customers VALUES
    (1, 'alice@example.com', '+77010000001', '2026-10-01'),
    (2, 'bob@example.com', NULL, '2026-10-02');
INSERT INTO inventory VALUES
    (1, 'Laptop', 10, 1000, '2026-10-01 09:00:00'),
    (2, 'Phone', 0, 500, '2026-10-02 10:00:00');
SELECT pg_temp.expect_error($test$INSERT INTO customers VALUES (NULL, 'test@example.com', '123', '2026-10-03')$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO customers VALUES (3, NULL, '123', '2026-10-03')$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO customers VALUES (3, 'test@example.com', '123', NULL)$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO inventory VALUES (NULL, 'Test', 1, 100, '2026-10-03 12:00:00')$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO inventory VALUES (3, NULL, 1, 100, '2026-10-03 12:00:00')$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO inventory VALUES (3, 'Test', NULL, 100, '2026-10-03 12:00:00')$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO inventory VALUES (3, 'Test', 1, NULL, '2026-10-03 12:00:00')$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO inventory VALUES (3, 'Test', 1, 100, NULL)$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO inventory VALUES (3, 'Test', -1, 100, CURRENT_TIMESTAMP)$test$, '23514');
SELECT pg_temp.expect_error($test$INSERT INTO inventory VALUES (3, 'Test', 1, 0, CURRENT_TIMESTAMP)$test$, '23514');

-- 3.1

CREATE TABLE users (
    user_id INTEGER,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    created_at TIMESTAMP
);

-- 3.2

CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    UNIQUE (student_id, course_code, semester)
);
INSERT INTO course_enrollments VALUES
    (1, 101, 'DB101', '2026-Fall'),
    (2, 101, 'DB101', '2027-Spring'),
    (3, 102, 'DB101', '2026-Fall');
SELECT pg_temp.expect_error($test$INSERT INTO course_enrollments VALUES (4, 101, 'DB101', '2026-Fall')$test$, '23505');

-- 3.3

ALTER TABLE users DROP CONSTRAINT users_username_key;
ALTER TABLE users DROP CONSTRAINT users_email_key;
ALTER TABLE users ADD CONSTRAINT unique_username UNIQUE (username);
ALTER TABLE users ADD CONSTRAINT unique_email UNIQUE (email);
INSERT INTO users VALUES
    (1, 'alice', 'alice@example.com', CURRENT_TIMESTAMP),
    (2, 'bob', 'bob@example.com', CURRENT_TIMESTAMP),
    (3, NULL, NULL, CURRENT_TIMESTAMP),
    (4, NULL, NULL, CURRENT_TIMESTAMP);
SELECT pg_temp.expect_error($test$INSERT INTO users VALUES (5, 'alice', 'other@example.com', CURRENT_TIMESTAMP)$test$, '23505');
SELECT pg_temp.expect_error($test$INSERT INTO users VALUES (5, 'other', 'alice@example.com', CURRENT_TIMESTAMP)$test$, '23505');

-- 4.1

CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);
INSERT INTO departments VALUES
    (1, 'IT', 'Almaty'),
    (2, 'Finance', 'Astana'),
    (3, 'HR', 'Almaty');
SELECT pg_temp.expect_error($test$INSERT INTO departments VALUES (1, 'Sales', 'Astana')$test$, '23505');
SELECT pg_temp.expect_error($test$INSERT INTO departments VALUES (NULL, 'Sales', 'Astana')$test$, '23502');

-- 4.2

CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);
INSERT INTO student_courses VALUES
    (101, 1, '2026-09-01', 'A'),
    (101, 2, '2026-09-01', 'B'),
    (102, 1, '2026-09-01', 'A');
SELECT pg_temp.expect_error($test$INSERT INTO student_courses VALUES (101, 1, '2026-09-02', 'C')$test$, '23505');
SELECT pg_temp.expect_error($test$INSERT INTO student_courses VALUES (NULL, 3, '2026-09-01', 'A')$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO student_courses VALUES (103, NULL, '2026-09-01', 'A')$test$, '23502');

-- 4.3

SELECT question, answer
FROM (VALUES
    (1, 'UNIQUE запрещает повторение ненулевых значений или комбинаций столбцов. В PostgreSQL 14 по умолчанию NULL не считается равным NULL, поэтому UNIQUE допускает несколько NULL. PRIMARY KEY объединяет уникальность и NOT NULL для каждого столбца ключа и задаёт основной идентификатор строки. Оба ограничения создают уникальный индекс; внешний ключ может ссылаться как на PRIMARY KEY, так и на подходящий UNIQUE.'),
    (2, 'Одностолбцовый PRIMARY KEY подходит, когда строка имеет один устойчивый уникальный идентификатор, например dept_id. Составной PRIMARY KEY нужен, когда уникальна именно комбинация, например (student_id, course_id) в таблице связей: каждый компонент отдельно может повторяться. Составной ключ прямо отражает предметную область, но требует хранить все его столбцы в ссылающихся внешних ключах. При использовании отдельного идентификатора естественную уникальность комбинации следует сохранить через UNIQUE.'),
    (3, 'PRIMARY KEY обозначает выбранный основной ключ таблицы, поэтому PostgreSQL разрешает только одно такое ограничение; оно может включать несколько столбцов. Другие независимые кандидатные ключи задаются отдельными UNIQUE, например username и email. Несколько UNIQUE защищают разные правила уникальности, а один PRIMARY KEY однозначно определяет основной идентификатор строки и используется как цель REFERENCES, если список столбцов не указан.')
) AS comparison(question, answer)
ORDER BY question;

-- 5.1

CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments (dept_id),
    hire_date DATE
);
INSERT INTO employees_dept VALUES
    (1, 'Alice Smith', 1, '2026-01-10'),
    (2, 'Bob Jones', 2, '2026-02-15');
SELECT pg_temp.expect_error($test$INSERT INTO employees_dept VALUES (3, 'Test User', 999, CURRENT_DATE)$test$, '23503');

-- 5.2

CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);
CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);
CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors (author_id),
    publisher_id INTEGER REFERENCES publishers (publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);
INSERT INTO authors VALUES
    (1, 'George Orwell', 'United Kingdom'),
    (2, 'Jane Austen', 'United Kingdom');
INSERT INTO publishers VALUES
    (1, 'Secker & Warburg', 'London'),
    (2, 'Penguin Books', 'London');
INSERT INTO books VALUES
    (1, 'Nineteen Eighty-Four', 1, 1, 1949, '9780451524935'),
    (2, 'Pride and Prejudice', 2, 2, 1813, '9780141439518');
SELECT pg_temp.expect_error($test$INSERT INTO books VALUES (3, 'Test', 999, 1, 2026, 'TEST-1')$test$, '23503');
SELECT pg_temp.expect_error($test$INSERT INTO books VALUES (3, 'Test', 1, 999, 2026, 'TEST-2')$test$, '23503');

-- 5.3

CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);
CREATE TABLE products_fk (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories (category_id) ON DELETE RESTRICT
);
CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);
CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders (order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk (product_id),
    quantity INTEGER CHECK (quantity > 0)
);
INSERT INTO categories VALUES (1, 'Electronics'), (2, 'Accessories');
INSERT INTO products_fk VALUES (1, 'Laptop', 1), (2, 'Mouse', 2);
INSERT INTO orders VALUES (1, '2026-10-01'), (2, '2026-10-02');
INSERT INTO order_items VALUES (1, 1, 1, 1), (2, 1, 2, 2), (3, 2, 2, 1);
SELECT pg_temp.expect_error($test$DELETE FROM categories WHERE category_id = 1$test$, '23503');
SELECT pg_temp.expect_error($test$INSERT INTO order_items VALUES (4, 2, 2, 0)$test$, '23514');
SELECT * FROM order_items ORDER BY item_id;
DELETE FROM orders WHERE order_id = 1;
SELECT * FROM order_items ORDER BY item_id;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM order_items WHERE order_id = 1)
       OR NOT EXISTS (SELECT 1 FROM order_items WHERE item_id = 3) THEN
        RAISE EXCEPTION 'ON DELETE CASCADE verification failed';
    END IF;
END;
$$;

-- 6.1

CREATE TABLE ecom_customers (
    customer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    registration_date DATE NOT NULL
);
CREATE TABLE ecom_products (
    product_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC NOT NULL CHECK (price >= 0),
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
);
CREATE TABLE ecom_orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES ecom_customers (customer_id) ON DELETE RESTRICT,
    order_date DATE NOT NULL,
    total_amount NUMERIC NOT NULL CHECK (total_amount >= 0),
    status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);
CREATE TABLE order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES ecom_orders (order_id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES ecom_products (product_id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price >= 0)
);
INSERT INTO ecom_customers VALUES
    (1, 'Alice Smith', 'alice@example.com', '+77010000001', '2026-10-01'),
    (2, 'Bob Jones', 'bob@example.com', NULL, '2026-10-02'),
    (3, 'Carol Brown', 'carol@example.com', '+77010000003', '2026-10-03'),
    (4, 'David Wilson', 'david@example.com', '+77010000004', '2026-10-04'),
    (5, 'Emma Davis', 'emma@example.com', NULL, '2026-10-05');
INSERT INTO ecom_products VALUES
    (1, 'Laptop', '15-inch laptop', 1000, 10),
    (2, 'Phone', 'Smartphone', 500, 20),
    (3, 'Mouse', NULL, 25, 50),
    (4, 'Keyboard', 'USB keyboard', 50, 30),
    (5, 'Gift', 'Promotional item', 0, 0);
INSERT INTO ecom_orders VALUES
    (1, 1, '2026-10-06', 1000, 'pending'),
    (2, 2, '2026-10-07', 1000, 'processing'),
    (3, 3, '2026-10-08', 75, 'shipped'),
    (4, 4, '2026-10-09', 100, 'delivered'),
    (5, 5, '2026-10-10', 0, 'cancelled');
INSERT INTO order_details VALUES
    (1, 1, 1, 1, 1000),
    (2, 2, 2, 2, 500),
    (3, 3, 3, 3, 25),
    (4, 4, 4, 2, 50),
    (5, 5, 5, 1, 0);
SELECT pg_temp.expect_error($test$INSERT INTO ecom_customers VALUES (NULL, 'Test', 'test@example.com', NULL, '2026-10-11')$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO ecom_customers VALUES (6, NULL, 'test@example.com', NULL, '2026-10-11')$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO ecom_customers VALUES (6, 'Test', NULL, NULL, '2026-10-11')$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO ecom_customers VALUES (6, 'Test', 'test@example.com', NULL, NULL)$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO ecom_customers VALUES (1, 'Test', 'test@example.com', NULL, '2026-10-11')$test$, '23505');
SELECT pg_temp.expect_error($test$INSERT INTO ecom_products VALUES (NULL, 'Test', NULL, 100, 1)$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO ecom_products VALUES (6, NULL, NULL, 100, 1)$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO ecom_products VALUES (6, 'Test', NULL, NULL, 1)$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO ecom_products VALUES (6, 'Test', NULL, 100, NULL)$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO ecom_products VALUES (1, 'Test', NULL, 100, 1)$test$, '23505');
SELECT pg_temp.expect_error($test$INSERT INTO ecom_orders VALUES (NULL, 1, '2026-10-11', 100, 'pending')$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO ecom_orders VALUES (6, NULL, '2026-10-11', 100, 'pending')$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO ecom_orders VALUES (6, 1, NULL, 100, 'pending')$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO ecom_orders VALUES (6, 1, '2026-10-11', NULL, 'pending')$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO ecom_orders VALUES (6, 1, '2026-10-11', 100, NULL)$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO ecom_orders VALUES (1, 1, '2026-10-11', 100, 'pending')$test$, '23505');
SELECT pg_temp.expect_error($test$INSERT INTO order_details VALUES (NULL, 1, 1, 1, 100)$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO order_details VALUES (6, NULL, 1, 1, 100)$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO order_details VALUES (6, 1, NULL, 1, 100)$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO order_details VALUES (6, 1, 1, NULL, 100)$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO order_details VALUES (6, 1, 1, 1, NULL)$test$, '23502');
SELECT pg_temp.expect_error($test$INSERT INTO order_details VALUES (1, 1, 1, 1, 100)$test$, '23505');
SELECT pg_temp.expect_error($test$INSERT INTO ecom_customers VALUES (6, 'Test', 'alice@example.com', NULL, CURRENT_DATE)$test$, '23505');
SELECT pg_temp.expect_error($test$INSERT INTO ecom_products VALUES (6, 'Test', NULL, -1, 1)$test$, '23514');
SELECT pg_temp.expect_error($test$INSERT INTO ecom_products VALUES (6, 'Test', NULL, 100, -1)$test$, '23514');
SELECT pg_temp.expect_error($test$INSERT INTO ecom_orders VALUES (6, 999, CURRENT_DATE, 100, 'pending')$test$, '23503');
SELECT pg_temp.expect_error($test$INSERT INTO ecom_orders VALUES (6, 1, CURRENT_DATE, -1, 'pending')$test$, '23514');
SELECT pg_temp.expect_error($test$INSERT INTO ecom_orders VALUES (6, 1, CURRENT_DATE, 100, 'unknown')$test$, '23514');
SELECT pg_temp.expect_error($test$INSERT INTO order_details VALUES (6, 999, 1, 1, 100)$test$, '23503');
SELECT pg_temp.expect_error($test$INSERT INTO order_details VALUES (6, 1, 999, 1, 100)$test$, '23503');
SELECT pg_temp.expect_error($test$INSERT INTO order_details VALUES (6, 1, 1, 0, 100)$test$, '23514');
SELECT pg_temp.expect_error($test$INSERT INTO order_details VALUES (6, 1, 1, 1, -1)$test$, '23514');
SELECT pg_temp.expect_error($test$DELETE FROM ecom_customers WHERE customer_id = 1$test$, '23503');
SELECT pg_temp.expect_error($test$DELETE FROM ecom_products WHERE product_id = 1$test$, '23503');
BEGIN;
DELETE FROM ecom_orders WHERE order_id = 1;
SELECT COUNT(*) AS remaining_details_for_deleted_order FROM order_details WHERE order_id = 1;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM order_details WHERE order_id = 1)
       OR (SELECT COUNT(*) FROM order_details) <> 4 THEN
        RAISE EXCEPTION 'E-commerce ON DELETE CASCADE verification failed';
    END IF;
END;
$$;
ROLLBACK;

SELECT 'ecom_customers' AS table_name, COUNT(*) AS row_count FROM ecom_customers
UNION ALL SELECT 'ecom_products', COUNT(*) FROM ecom_products
UNION ALL SELECT 'ecom_orders', COUNT(*) FROM ecom_orders
UNION ALL SELECT 'order_details', COUNT(*) FROM order_details;

SELECT o.order_id, o.total_amount, SUM(d.quantity * d.unit_price) AS calculated_total,
       o.total_amount = SUM(d.quantity * d.unit_price) AS totals_match
FROM ecom_orders AS o
JOIN order_details AS d ON d.order_id = o.order_id
GROUP BY o.order_id, o.total_amount
ORDER BY o.order_id;

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM ecom_customers) < 5
       OR (SELECT COUNT(*) FROM ecom_products) < 5
       OR (SELECT COUNT(*) FROM ecom_orders) < 5
       OR (SELECT COUNT(*) FROM order_details) < 5 THEN
        RAISE EXCEPTION 'Expected at least five records per e-commerce table';
    END IF;
    IF EXISTS (
        SELECT 1 FROM ecom_orders AS o
        LEFT JOIN order_details AS d ON d.order_id = o.order_id
        GROUP BY o.order_id, o.total_amount
        HAVING o.total_amount <> COALESCE(SUM(d.quantity * d.unit_price), 0)
    ) THEN
        RAISE EXCEPTION 'Order total verification failed';
    END IF;
END;
$$;

DROP FUNCTION pg_temp.expect_error(TEXT, TEXT);
