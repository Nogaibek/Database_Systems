DROP SCHEMA IF EXISTS citybike CASCADE;
CREATE SCHEMA citybike;
SET search_path = citybike, public;

-- 1.1
CREATE TABLE stations (
    station_id INT PRIMARY KEY,
    station_name VARCHAR(80) NOT NULL,
    city VARCHAR(80) NOT NULL,
    capacity INT NOT NULL CHECK (capacity >= 0)
);

CREATE TABLE bikes (
    bike_id INT PRIMARY KEY,
    station_id INT REFERENCES stations(station_id),
    model VARCHAR(80) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('available', 'rented', 'maintenance'))
);

CREATE TABLE members (
    member_id INT PRIMARY KEY,
    member_name VARCHAR(100) NOT NULL,
    email VARCHAR(160) UNIQUE NOT NULL
);

CREATE TABLE rentals (
    rental_id INT PRIMARY KEY,
    bike_id INT NOT NULL REFERENCES bikes(bike_id),
    member_id INT NOT NULL REFERENCES members(member_id),
    start_station_id INT NOT NULL REFERENCES stations(station_id),
    end_station_id INT REFERENCES stations(station_id),
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP,
    fee NUMERIC(10,2) NOT NULL CHECK (fee >= 0),
    CHECK (end_date IS NULL OR end_date >= start_date)
);

-- 1.2
INSERT INTO stations VALUES
(10, 'Central', 'Almaty', 20),
(20, 'University', 'Almaty', 12),
(30, 'Riverside', 'Astana', 15),
(40, 'Old Town', 'Astana', 8),
(50, 'Depot', 'Almaty', 0);

INSERT INTO bikes VALUES
(1001,10,'City One','available'), (1002,10,'City Two','rented'),
(1003,20,'City One','available'), (1004,20,'Roadster','rented'),
(1005,30,'Roadster','available'), (1006,30,'City Two','maintenance'),
(1007,40,'City One','rented'), (1008,50,'Cargo','available');

INSERT INTO members VALUES
(1,'Aida Karim','aida@example.com'), (2,'Timur Sadyk','timur@example.com'),
(3,'Dana Omar','dana@example.com'), (4,'Arman Lee','arman@example.com'),
(5,'Mira Kim','mira@example.com'), (6,'No-Rental Member','none@example.com');

INSERT INTO rentals VALUES
(1,1001,1,10,20,'2025-01-02 08:00','2025-01-02 10:00',500.00),
(2,1002,2,10,10,'2025-01-03 09:00','2025-01-04 09:00',1200.00),
(3,1003,1,20,10,'2025-01-05 08:00','2025-01-10 08:00',2600.00),
(4,1004,3,20,30,'2025-01-07 10:00','2025-01-08 12:00',1400.00),
(5,1005,4,30,40,'2025-01-09 08:00','2025-01-15 08:00',3000.00),
(6,1006,2,30,30,'2025-01-11 11:00','2025-01-11 14:00',700.00),
(7,1007,5,40,10,'2025-01-12 08:00','2025-01-13 08:00',1500.00),
(8,1008,3,50,10,'2025-01-14 08:00','2025-01-20 08:00',3100.00),
(9,1001,1,10,20,'2025-01-16 08:00','2025-01-16 12:00',800.00),
(10,1002,2,10,30,'2025-01-18 09:00','2025-01-23 09:00',2700.00),
(11,1003,3,20,10,'2025-01-20 08:00','2025-01-21 08:00',1300.00),
(12,1004,4,20,40,'2025-01-22 10:00','2025-01-28 10:00',3200.00),
(13,1005,5,30,30,'2025-01-24 08:00','2025-01-24 10:00',600.00),
(14,1006,1,30,10,'2025-01-26 11:00','2025-02-01 11:00',3300.00),
(15,1007,2,40,20,'2025-01-28 08:00','2025-01-29 08:00',1500.00),
(16,1008,3,50,30,'2025-01-30 08:00','2025-02-05 08:00',3100.00),
(17,1001,4,10,10,'2025-02-02 08:00','2025-02-02 11:00',650.00),
(18,1002,5,10,40,'2025-02-04 09:00','2025-02-10 09:00',3400.00),
(19,1003,1,20,NULL,'2025-02-06 08:00',NULL,0.00),
(20,1004,2,20,30,'2025-02-08 10:00','2025-02-14 10:00',3200.00),
(21,1005,3,30,10,'2025-02-10 08:00','2025-02-11 08:00',1400.00),
(22,1007,4,40,NULL,'2025-02-12 08:00',NULL,0.00);

-- 2
-- 2.1
CREATE OR REPLACE FUNCTION rental_days(p_rental_id INT)
RETURNS INT LANGUAGE plpgsql AS $$
DECLARE v_days INT;
BEGIN
    SELECT (end_date::date - start_date::date) INTO v_days
    FROM rentals WHERE rental_id = p_rental_id;
    RETURN v_days;
END;
$$;
SELECT rental_id, rental_days(rental_id) AS days FROM rentals WHERE rental_id = 19;
SELECT rental_days(999) AS missing_rental_days;

-- 2.2
CREATE OR REPLACE FUNCTION member_rental_count(p_member_id INT)
RETURNS BIGINT LANGUAGE sql AS $$
    SELECT COUNT(*) FROM rentals WHERE member_id = p_member_id
$$;
SELECT member_id, member_rental_count(member_id) FROM members ORDER BY member_id;

-- 2.3
CREATE OR REPLACE FUNCTION station_city(p_station_id INT)
RETURNS VARCHAR LANGUAGE sql AS $$
    SELECT city FROM stations WHERE station_id = p_station_id
$$;
SELECT station_city(10);

-- 2.4
SELECT rental_id, rental_days(rental_id) AS duration_days
FROM rentals
WHERE rental_days(rental_id) > 4
ORDER BY duration_days DESC;

-- 3
-- 3.1
CREATE OR REPLACE FUNCTION fee_with_discount(p_fee NUMERIC, p_percent NUMERIC)
RETURNS NUMERIC LANGUAGE sql IMMUTABLE AS $$
    SELECT round(p_fee * (1 - p_percent / 100), 2)
$$;
SELECT fee_with_discount(1000, 15);

-- 3.2
CREATE OR REPLACE FUNCTION member_stats(
    IN p_member_id INT,
    OUT rental_cnt BIGINT,
    OUT total_fee NUMERIC,
    OUT last_start TIMESTAMP
)
LANGUAGE sql AS $$
    SELECT COUNT(r.rental_id), COALESCE(SUM(r.fee),0), MAX(r.start_date)
    FROM rentals r WHERE r.member_id = p_member_id
$$;
SELECT member_stats(1);
SELECT * FROM member_stats(1);

-- 3.3
CREATE OR REPLACE FUNCTION apply_late_fee(INOUT p_fee NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    p_fee := p_fee + 5.00;
END;
$$;
SELECT apply_late_fee(12.50);

-- 3.4
CREATE OR REPLACE FUNCTION fee_summary(VARIADIC p_fees NUMERIC[])
RETURNS TABLE(total NUMERIC, average NUMERIC, largest NUMERIC)
LANGUAGE sql IMMUTABLE AS $$
    SELECT COALESCE(SUM(x),0), AVG(x), MAX(x) FROM unnest(p_fees) AS u(x)
$$;
SELECT * FROM fee_summary(10, 20, 30);

-- 3.5
-- IN: pass a member ID to a read-only lookup. INOUT: accept and return a fee after applying a surcharge. VARIADIC: accept any number of fee amounts for a summary. OUT: return several named statistics from one call.

-- 4
-- 4.1
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT)
RETURNS NUMERIC LANGUAGE sql STABLE AS $$
    SELECT COALESCE(SUM(fee),0) FROM rentals WHERE member_id = p_member_id
$$;
SELECT total_fees(1);

-- 4.2
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT, p_from_date DATE)
RETURNS NUMERIC LANGUAGE sql STABLE AS $$
    SELECT COALESCE(SUM(fee),0) FROM rentals
    WHERE member_id = p_member_id AND start_date::date >= p_from_date
$$;
SELECT total_fees(1, DATE '2025-02-01');

-- 4.3
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT, p_from_date DATE DEFAULT DATE '2025-01-01')
RETURNS NUMERIC LANGUAGE sql STABLE AS $$
    SELECT COALESCE(SUM(fee),0) FROM rentals
    WHERE member_id = p_member_id AND start_date::date >= p_from_date
$$;

-- 4.4
DROP FUNCTION total_fees(INTEGER);
SELECT total_fees(1);

-- 4.5
CREATE OR REPLACE FUNCTION total_fees(p_member_name VARCHAR)
RETURNS NUMERIC LANGUAGE sql STABLE AS $$
    SELECT COALESCE(SUM(r.fee),0) FROM members m JOIN rentals r USING (member_id)
    WHERE m.member_name = p_member_name
$$;
SELECT total_fees('Aida Karim'::VARCHAR);

-- 5
-- 5.1
CREATE OR REPLACE FUNCTION find_bikes(p_pattern TEXT)
RETURNS TABLE(bike_id INT, model VARCHAR, status VARCHAR)
LANGUAGE sql STABLE AS $$
    SELECT b.bike_id, b.model, b.status FROM bikes b WHERE b.model ILIKE p_pattern
$$;
SELECT * FROM find_bikes('%city%');
SELECT find_bikes('%city%');

-- 5.2
CREATE OR REPLACE FUNCTION member_history(p_member_id INT)
RETURNS TABLE(rental_id INT, member_name VARCHAR, bike_model VARCHAR, start_date TIMESTAMP, end_date TIMESTAMP, fee NUMERIC)
LANGUAGE sql STABLE AS $$
    SELECT r.rental_id, m.member_name, b.model, r.start_date, r.end_date, r.fee
    FROM rentals r JOIN members m USING (member_id) JOIN bikes b USING (bike_id)
    WHERE r.member_id = p_member_id ORDER BY r.start_date
$$;
SELECT * FROM member_history(1);

-- 5.3
CREATE OR REPLACE FUNCTION member_history_renamed(p_member_id INT)
RETURNS TABLE(history_rental_id INT, history_member_name VARCHAR, bike_model VARCHAR, started_at TIMESTAMP, ended_at TIMESTAMP, fee NUMERIC)
LANGUAGE sql STABLE AS $$
    SELECT r.rental_id, m.member_name, b.model, r.start_date, r.end_date, r.fee
    FROM rentals r JOIN members m USING (member_id) JOIN bikes b USING (bike_id)
    WHERE r.member_id = p_member_id ORDER BY r.start_date
$$;
CREATE OR REPLACE FUNCTION member_history_qualified(p_member_id INT)
RETURNS TABLE(rental_id INT, member_name VARCHAR, bike_model VARCHAR, start_date TIMESTAMP, end_date TIMESTAMP, fee NUMERIC)
LANGUAGE plpgsql STABLE AS $$
BEGIN
    RETURN QUERY SELECT r.rental_id, m.member_name, b.model, r.start_date, r.end_date, r.fee
    FROM rentals AS r JOIN members AS m USING (member_id) JOIN bikes AS b USING (bike_id)
    WHERE r.member_id = p_member_id ORDER BY r.start_date;
END;
$$;
SELECT * FROM member_history_renamed(1);
SELECT * FROM member_history_qualified(1);

-- 5.4
CREATE OR REPLACE FUNCTION station_board(p_city TEXT)
RETURNS TABLE(station_id INT, station_name VARCHAR, bike_count INT)
LANGUAGE sql STABLE AS $$
    SELECT s.station_id, s.station_name, COUNT(b.bike_id)::INT
    FROM stations s LEFT JOIN bikes b USING (station_id)
    WHERE s.city = p_city GROUP BY s.station_id, s.station_name ORDER BY s.station_id
$$;
SELECT * FROM station_board('Almaty');

-- 6
-- 6.1
DO $$
<<rental_report>>
DECLARE v_count BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_count FROM rentals;
    RAISE NOTICE 'Rental rows: %', v_count;
END rental_report;
$$;

-- 6.2
DO $$
DECLARE fee_total NUMERIC := 100;
BEGIN
    RAISE NOTICE 'Checkpoint 1 outer fee_total=%', fee_total;
    DECLARE fee_total NUMERIC := 250;
    BEGIN
        RAISE NOTICE 'Checkpoint 2 inner fee_total=%', fee_total;
        fee_total := fee_total + 25;
        RAISE NOTICE 'Checkpoint 3 inner fee_total=%', fee_total;
    END;
    RAISE NOTICE 'Checkpoint 4 outer fee_total=%', fee_total;
END;
$$;

-- 6.3
DO $$
DECLARE outer_value INT;
BEGIN
    DECLARE inner_value INT := 7;
    BEGIN
        outer_value := inner_value;
    END;
    RAISE NOTICE 'Re-factored value in outer scope: %', outer_value;
END;
$$;

-- 6.4
CREATE OR REPLACE FUNCTION fee_split(
    IN p_from_date DATE,
    OUT before_total NUMERIC,
    OUT after_total NUMERIC
)
LANGUAGE sql STABLE AS $$
    SELECT COALESCE(SUM(fee) FILTER (WHERE start_date::date < p_from_date),0),
           COALESCE(SUM(fee) FILTER (WHERE start_date::date >= p_from_date),0)
    FROM rentals
$$;
SELECT * FROM fee_split(DATE '2025-02-01');

-- 7
-- 7.1
CREATE OR REPLACE FUNCTION station_load(p_station_id INT)
RETURNS TABLE(bike_count BIGINT, capacity_percent NUMERIC)
LANGUAGE sql STABLE AS $$
    SELECT COUNT(b.bike_id),
           CASE WHEN s.capacity = 0 THEN 0::NUMERIC
                ELSE round(COUNT(b.bike_id)::NUMERIC * 100 / s.capacity, 2) END
    FROM stations s LEFT JOIN bikes b USING (station_id)
    WHERE s.station_id = p_station_id GROUP BY s.capacity
$$;
SELECT * FROM station_load(50);

-- 7.2
CREATE OR REPLACE FUNCTION top_members(p_limit INT DEFAULT 3)
RETURNS TABLE(member_id INT, member_name VARCHAR, revenue NUMERIC)
LANGUAGE sql STABLE AS $$
    SELECT m.member_id, m.member_name, COALESCE(SUM(r.fee),0) AS revenue
    FROM members m LEFT JOIN rentals r USING (member_id)
    GROUP BY m.member_id, m.member_name ORDER BY revenue DESC, m.member_id LIMIT p_limit
$$;
SELECT * FROM top_members();

-- 7.3
CREATE OR REPLACE FUNCTION rental_invoice(p_rental_id INT)
RETURNS TABLE(rental_id INT, billable_days INT, invoice_amount NUMERIC)
LANGUAGE sql STABLE AS $$
    SELECT r.rental_id,
           GREATEST(CURRENT_DATE - r.start_date::date, 1),
           round(r.fee + GREATEST(CURRENT_DATE - r.start_date::date, 1) * 500, 2)
    FROM rentals r WHERE r.rental_id = p_rental_id AND r.end_date IS NULL
$$;
SELECT * FROM rental_invoice(19);

-- 7.4
CREATE OR REPLACE FUNCTION city_report(p_city TEXT)
RETURNS TABLE(station_id INT, station_name VARCHAR, rental_count BIGINT)
LANGUAGE sql STABLE AS $$
    SELECT s.station_id, s.station_name, COUNT(r.rental_id)
    FROM stations s LEFT JOIN rentals r ON r.start_station_id = s.station_id
    WHERE s.city = p_city GROUP BY s.station_id, s.station_name ORDER BY s.station_id
$$;
CREATE OR REPLACE FUNCTION city_report(p_city TEXT, p_from_date DATE)
RETURNS TABLE(station_id INT, station_name VARCHAR, rental_count BIGINT)
LANGUAGE sql STABLE AS $$
    SELECT s.station_id, s.station_name, COUNT(r.rental_id)
    FROM stations s LEFT JOIN rentals r
      ON r.start_station_id = s.station_id AND r.start_date::date >= p_from_date
    WHERE s.city = p_city GROUP BY s.station_id, s.station_name ORDER BY s.station_id
$$;
SELECT * FROM city_report('Almaty');
SELECT * FROM city_report('Almaty', DATE '2025-02-01');
