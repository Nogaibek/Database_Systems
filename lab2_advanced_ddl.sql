--part1
--task1.1
CREATE DATABASE hospital_main
    WITH
    OWNER = postgres
    TEMPLATE = template0
    ENCODING = 'UTF-8';

CREATE DATABASE hospital_archive
    WITH
    CONNECTION LIMIT = 50
    TEMPLATE = template0;

CREATE DATABASE hospital_test
    WITH
    IS_TEMPLATE = true
    CONNECTION LIMIT = 15;


--task1.2
CREATE TABLESPACE patient_data
LOCATION '/Users/danial/pgdata/patients';

CREATE TABLESPACE clinical_data
OWNER postgres
LOCATION '/Users/danial/pgdata/clinical';

CREATE DATABASE hospital_distributed
    WITH
    TEMPLATE = template0
    ENCODING = 'LATIN9'
    LC_CTYPE = 'C'
    LC_COLLATE = 'C'
    TABLESPACE = patient_data;




--part2
--task2.1
CREATE TABLE patients (
    patient_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone CHAR(15),
    date_of_birth DATE,
    registration_date DATE,
    body_mass_index DECIMAL(5,2),
    is_insured BOOLEAN,
    emergency_contact_priority SMALLINT
);

CREATE TABLE doctors (
    doctor_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    office_number VARCHAR(20),
    hire_date DATE,
    salary DECIMAL(12,2),
    is_board_certified BOOLEAN,
    years_experience INTEGER
);

CREATE TABLE medical_procedures (
    procedure_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    procedure_code CHAR(8),
    procedure_title VARCHAR(100),
    description TEXT,
    complexity_level SMALLINT,
    max_daily_patients INTEGER,
    base_fee DECIMAL(10,2),
    requires_anesthesia BOOLEAN,
    created_at TIMESTAMP
);


--task2.2
CREATE TABLE appointment_schedule (
    schedule_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    procedure_id INTEGER,
    doctor_id INTEGER,
    examination_room VARCHAR(20),
    appointment_date DATE,
    start_time TIME,
    end_time TIME,
    duration INTERVAL
);

CREATE TABLE patient_visit_records (
    record_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INTEGER,
    procedure_id INTEGER,
    triage_level VARCHAR(20),
    visit_year INTEGER,
    urgency_code CHAR(2),
    vitals_score DECIMAL(4,1),
    check_in_timestamp TIMESTAMPTZ,
    last_monitored TIMESTAMPTZ
);




--part3
--task3.1
ALTER TABLE patients
ADD COLUMN middle_name VARCHAR(30),
ADD COLUMN patient_status VARCHAR(20);

ALTER TABLE patients
ALTER COLUMN phone TYPE VARCHAR(20);

ALTER TABLE patients
ALTER COLUMN patient_status SET DEFAULT 'ACTIVE';

ALTER TABLE patients
ALTER COLUMN body_mass_index SET DEFAULT 0.00;


ALTER TABLE doctors
ADD COLUMN department_code CHAR(5),
ADD COLUMN specialization_details TEXT;

ALTER TABLE doctors
ALTER COLUMN years_experience TYPE SMALLINT;

ALTER TABLE doctors
ALTER COLUMN is_board_certified SET DEFAULT false;

ALTER TABLE doctors
ADD COLUMN last_licensure_renewal DATE;


ALTER TABLE medical_procedures
ADD COLUMN prerequisite_procedure_id INTEGER,
ADD COLUMN risk_tier SMALLINT;

ALTER TABLE medical_procedures
ALTER COLUMN procedure_code TYPE VARCHAR(10);

ALTER TABLE medical_procedures
ALTER COLUMN complexity_level SET DEFAULT 1;

ALTER TABLE medical_procedures
ADD COLUMN insurance_covered BOOLEAN DEFAULT true;


--taskl3.2
ALTER TABLE appointment_schedule
ADD COLUMN room_capacity INTEGER,
ADD COLUMN consultation_type VARCHAR(15),
ADD COLUMN equipment_needed TEXT;

ALTER TABLE appointment_schedule
DROP COLUMN duration;

ALTER TABLE appointment_schedule
ALTER COLUMN examination_room TYPE VARCHAR(30);


ALTER TABLE patient_visit_records
ADD COLUMN followup_priority DECIMAL(3,1),
ADD COLUMN discharge_date DATE;

ALTER TABLE patient_visit_records
ALTER COLUMN urgency_code TYPE VARCHAR(5);

ALTER TABLE patient_visit_records
ALTER COLUMN followup_priority SET DEFAULT 0.0;

ALTER TABLE patient_visit_records
DROP COLUMN last_monitored;




--part4
--task4.1
CREATE TABLE departments (
    department_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_name VARCHAR(100),
    department_code CHAR(5),
    building_wing VARCHAR(50),
    contact_phone VARCHAR(15),
    annual_budget DECIMAL(15,2),
    established_year INTEGER
);

CREATE TABLE pharmacy_inventory (
    medication_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    barcode_ndc CHAR(13),
    medication_name VARCHAR(200),
    generic_name VARCHAR(100),
    manufacturer VARCHAR(100),
    approval_date DATE,
    unit_price DECIMAL(10,2),
    is_available BOOLEAN,
    stock_timestamp TIMESTAMP
);

CREATE TABLE patient_prescriptions (
    prescription_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INTEGER,
    medication_id INTEGER,
    prescribed_date DATE,
    start_date DATE,
    end_date DATE,
    copay_amount DECIMAL(10,2),
    prescription_status VARCHAR(20)
);


--task4.2
ALTER TABLE doctors
ADD COLUMN department_id INTEGER;

ALTER TABLE patients
ADD COLUMN primary_doctor_id INTEGER;

ALTER TABLE medical_procedures
ADD COLUMN department_id INTEGER;


CREATE TABLE triage_scale (
    triage_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    triage_code CHAR(2),
    min_score DECIMAL(3,1),
    max_score DECIMAL(3,1),
    severity_weight DECIMAL(5,2)
);


CREATE TABLE clinic_shifts (
    shift_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shift_name VARCHAR(20),
    fiscal_year INTEGER,
    start_date DATE,
    end_date DATE,
    roster_lock_timestamp TIMESTAMPTZ,
    is_active BOOLEAN
);




--part5
--task5.1
DROP TABLE IF EXISTS patient_prescriptions;
DROP TABLE IF EXISTS pharmacy_inventory;
DROP TABLE IF EXISTS triage_scale;

CREATE TABLE triage_scale (
    triage_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    triage_code CHAR(2),
    min_score DECIMAL(3,1),
    max_score DECIMAL(3,1),
    severity_weight DECIMAL(5,2),
    description TEXT
);

DROP TABLE IF EXISTS clinic_shifts CASCADE;

CREATE TABLE clinic_shifts (
    shift_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shift_name VARCHAR(20),
    fiscal_year INTEGER,
    start_date DATE,
    end_date DATE,
    roster_lock_timestamp TIMESTAMPTZ,
    is_active BOOLEAN
);


--task5.2
ALTER DATABASE hospital_test IS_TEMPLATE = false;
DROP DATABASE IF EXISTS hospital_test;

DROP DATABASE IF EXISTS hospital_distributed;

CREATE DATABASE hospital_backup
    WITH
    TEMPLATE = hospital_main;