-- ════════════════════════════════════════════════
-- BLOCK 1: PRODUCTION LOG PHYSICAL COLUMNS
-- ════════════════════════════════════════════════

-- Step 1: Add all columns at once
ALTER TABLE production_log
ADD COLUMN IF NOT EXISTS duration_minutes   NUMERIC,
ADD COLUMN IF NOT EXISTS production_date    DATE,
ADD COLUMN IF NOT EXISTS days_since_maint   NUMERIC,
ADD COLUMN IF NOT EXISTS last_maint_type    VARCHAR(20);

-- Step 2: duration_minutes
-- How long each production run actually took
UPDATE production_log
SET duration_minutes =
    ROUND(
        EXTRACT(EPOCH FROM (end_time - start_time)) / 60
    , 2);

-- Step 3: production_date
-- Date-level key for joining sensor daily aggregates
UPDATE production_log
SET production_date = DATE(start_time);

-- Step 4: days_since_maint
-- For each production run, how many days since
-- last maintenance on that machine before run started
UPDATE production_log p
SET days_since_maint =
    ROUND(
        EXTRACT(EPOCH FROM (
            p.start_time -
            (
                SELECT MAX(m.maintenance_time)
                FROM maintenance_log m
                WHERE m.machine_id = p.machine_id
                AND m.maintenance_time <= p.start_time
            )
        )) / 86400
    , 2);

-- Step 5: last_maint_type
-- Was last maintenance preventive or corrective?
UPDATE production_log p
SET last_maint_type =
    (
        SELECT m.type
        FROM maintenance_log m
        WHERE m.machine_id = p.machine_id
        AND m.maintenance_time <= p.start_time
        ORDER BY m.maintenance_time DESC
        LIMIT 1
    );

-- Step 6: Verify all 4 columns
SELECT
    production_id,
    machine_id,
    start_time,
    end_time,
    duration_minutes,
    production_date,
    days_since_maint,
    last_maint_type
FROM production_log
ORDER BY start_time
LIMIT 10;

-- ════════════════════════════════════════════════
-- BLOCK 2: MAINTENANCE LOG PHYSICAL COLUMN
-- ════════════════════════════════════════════════

-- Step 1: Add corrective_event_flag
ALTER TABLE maintenance_log
ADD COLUMN IF NOT EXISTS corrective_event_flag INT DEFAULT 0;

-- Step 2: Populate
-- 1 = corrective (emergency breakdown)
-- 0 = preventive (scheduled)
UPDATE maintenance_log
SET corrective_event_flag =
    CASE
        WHEN type = 'corrective' THEN 1
        ELSE 0
    END;

-- Step 3: Verify
SELECT
    maintenance_id,
    machine_id,
    type,
    maintenance_time,
    downtime_minutes,
    corrective_event_flag
FROM maintenance_log
ORDER BY corrective_event_flag DESC;
-- ════════════════════════════════════════════════
-- BLOCK 3: SENSOR OUTLIER FLAG (PHYSICAL COLUMN)
-- Must be run before creating v_sensor_daily
-- ════════════════════════════════════════════════

-- Step 1: Add the column
ALTER TABLE sensor_readings
ADD COLUMN IF NOT EXISTS is_outlier INT DEFAULT 0;

-- Step 2: Flag the outliers based on PDF rules
UPDATE sensor_readings
SET is_outlier = 1
WHERE
    (unit = 'celsius' AND (value < 180 OR value > 220)) OR
    (unit = 'bar' AND (value < 5 OR value > 8)) OR
    (unit = 'mm/s' AND (value < 0.5 OR value > 2.5)) OR
    (unit = 'rpm' AND (value < 800 OR value > 1200)) OR
    (unit = 'kw' AND (value < 15 OR value > 35));

-- Step 3: Verify
SELECT
    unit,
    COUNT(*) AS total_readings,
    SUM(is_outlier) AS outlier_count,
    ROUND(SUM(is_outlier)::NUMERIC / COUNT(*) * 100, 2) AS outlier_pct
FROM sensor_readings
GROUP BY unit;

-- ════════════════════════════════════════════════
-- BLOCK 4: SENSOR DAILY AGGREGATION VIEW
-- This compresses 2.5M rows into daily summaries
-- One row per machine per day
-- ════════════════════════════════════════════════
-- DROP VIEW v_sensor_daily;
CREATE OR REPLACE VIEW v_sensor_daily AS
SELECT
    machine_id,
    DATE("timestamp") AS production_date,
    AVG(CASE WHEN sensor_type = 'temp_zone1' THEN value END) AS avg_temp_z1,
    MAX(CASE WHEN sensor_type = 'temp_zone1' THEN value END) AS max_temp_z1,
    AVG(CASE WHEN sensor_type = 'temp_zone2' THEN value END) AS avg_temp_z2,
    MAX(CASE WHEN sensor_type = 'temp_zone2' THEN value END) AS max_temp_z2,
    AVG(CASE WHEN sensor_type = 'vibration' THEN GREATEST(value,0) END) AS avg_vibration,
    MAX(CASE WHEN sensor_type = 'vibration' THEN GREATEST(value,0) END) AS max_vibration,
    AVG(CASE WHEN sensor_type = 'speed' THEN value END) AS avg_speed,
    AVG(CASE WHEN sensor_type = 'pressure_main' THEN GREATEST(value,0) END) AS avg_pressure,
    AVG(CASE WHEN sensor_type = 'power_consumption' THEN value END) AS avg_power,
    SUM(is_outlier) AS total_outlier_readings,
    ROUND(SUM(is_outlier)::NUMERIC / NULLIF(COUNT(*), 0) * 100, 2) AS outlier_rate_pct
FROM sensor_readings
WHERE value IS NOT NULL
GROUP BY machine_id, DATE("timestamp");

-- Verify
SELECT *
FROM v_sensor_daily
ORDER BY production_date, machine_id
LIMIT 10;

-- : Verify — no more negative vibration or extreme pressure
SELECT
    'vibration' AS sensor,
    ROUND(MIN(avg_vibration)::NUMERIC, 3)                   AS min_avg,
    ROUND(MAX(avg_vibration)::NUMERIC, 3)                   AS max_avg,
    COUNT(*) FILTER (WHERE avg_vibration < 0)      AS negative_count
FROM v_sensor_daily
UNION ALL
SELECT
    'pressure',
    ROUND(MIN(avg_pressure)::NUMERIC, 3),
    ROUND(MAX(avg_pressure)::NUMERIC, 3),
    COUNT(*) FILTER (WHERE avg_pressure < -1)
FROM v_sensor_daily;

-- ════════════════════════════════════════════════
-- BLOCK 4: MAINTENANCE DAILY AGGREGATION VIEW
-- This compresses 8k rows into ine machine id
-- One row per machine
-- ════════════════════════════════════════════════
-- Parts replacement summary per machine
--DROP VIEW parts_summary;
CREATE OR REPLACE VIEW parts_summary AS (
    SELECT
        machine_id,
        SUM(had_filter)    AS total_filter_replacements,
        SUM(had_lubricant) AS total_lubricant_replacements,
        SUM(had_motor)     AS total_motor_replacements,
        SUM(had_bearing)   AS total_bearing_replacements,
        SUM(had_sensor)    AS total_sensor_replacements,
        SUM(had_valve)     AS total_valve_replacements,
        SUM(had_belt)      AS total_belt_replacements,
        SUM(parts_count)   AS total_parts_replaced
    FROM maintenance_log
    GROUP BY machine_id
);

-- ================================================================