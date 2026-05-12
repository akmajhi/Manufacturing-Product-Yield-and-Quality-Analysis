-- 1. Sensor table
CREATE TABLE sensor_readings (
    timestamp TIMESTAMP,
    machine_id INT,
    sensor_id VARCHAR(50),
    value DOUBLE PRECISION,
    unit VARCHAR(20)
);

-- 2. Prodcution Table
CREATE TABLE production_log (
    production_id VARCHAR(50) PRIMARY KEY,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    product_id VARCHAR(20),
    machine_id INT,
    operator_id VARCHAR(20),
    batch_size INT,
    shift VARCHAR(20),
    environment_temp DOUBLE PRECISION,
    environment_humidity DOUBLE PRECISION
);

-- 3. Product Table
CREATE TABLE product_catalog (
    product_id VARCHAR(20) PRIMARY KEY,
    product_family VARCHAR(50),
    tolerance_spec_1 DOUBLE PRECISION,
    tolerance_spec_2 DOUBLE PRECISION,
    recommended_speed INT
);

-- 4. Quality Table
CREATE TABLE quality_inspection (
    production_id VARCHAR(50) PRIMARY KEY,
    inspect_time TIMESTAMP,
    inspector_id VARCHAR(20),
    pin_holes INT,
    num_defects INT,
    defect_types TEXT,
    severity_score INT
);

-- 5. Maintenance Table
CREATE TABLE maintenance_log (
    maintenance_id VARCHAR(50) PRIMARY KEY,
    machine_id INT,
    maintenance_time TIMESTAMP,
    type VARCHAR(20),
    downtime_minutes INT,
    parts_replaced TEXT
);

-- 6. Operators Table
CREATE TABLE operators (
    operator_id VARCHAR(20) PRIMARY KEY,
    name_hash VARCHAR(100),
    experience_months INT,
    certifications TEXT,
    training_date DATE
);