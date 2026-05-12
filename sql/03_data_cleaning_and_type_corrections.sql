-- =================================================
-- BLOCK - A | Delete duplicate records |
-- =================================================
SELECT
    timestamp,
    machine_id,
    sensor_id,
    value,
    unit,
    COUNT(*)
FROM sensor_readings
GROUP BY
    timestamp,
    machine_id,
    sensor_id,
    value,
    unit
HAVING COUNT(*) > 1
ORDER BY timestamp DESC;
-- ---------------------------------
WITH dup_groups AS (
  SELECT
    timestamp,
    machine_id,
    sensor_id,
    value,
    unit,
    COUNT(*) AS cnt
  FROM sensor_readings
  GROUP BY
    timestamp,
    machine_id,
    sensor_id,
    value,
    unit
  HAVING COUNT(*) > 1
)
SELECT
  s.timestamp,
  s.machine_id,
  s.sensor_id,
  s.value,
  s.unit,
  d.cnt AS "count"
FROM sensor_readings s
JOIN dup_groups d
  ON s.timestamp = d.timestamp
  AND s.machine_id = d.machine_id
  AND s.sensor_id = d.sensor_id
  AND s.value = d.value
  AND s.unit = d.unit
ORDER BY s.timestamp DESC, s.machine_id, s.sensor_id;

-- -----------------------------------------------------------
-- Count the total number of duplicate records
------------------------------------------------------
SELECT COUNT(*) FROM (
    SELECT
        timestamp,
        machine_id,
        sensor_id,
        value,
        unit,
        COUNT(*)
    FROM sensor_readings
    GROUP BY
        timestamp,
        machine_id,
        sensor_id,
        value,
        unit
    HAVING COUNT(*) > 1
) t;
-----------------------------------------------------------
-- Delete Duplicate records from `sensor_readings` table
----------------------------------------------------------
DELETE FROM sensor_readings a
USING sensor_readings b
WHERE a.ctid < b.ctid
AND a.timestamp = b.timestamp
AND a.machine_id = b.machine_id
AND a.sensor_id = b.sensor_id
AND a.value IS NOT DISTINCT FROM b.value
AND a.unit = b.unit;

----------------------------------
SELECT production_id, COUNT(*)
FROM production_log
GROUP BY production_id
HAVING COUNT(*) > 1;
----------------------------------
SELECT production_id, COUNT(*)
FROM quality_inspection
GROUP BY production_id
HAVING COUNT(*) > 1;
------------------------------
SELECT maintenance_id, COUNT(*)
FROM maintenance_log
GROUP BY maintenance_id
HAVING COUNT(*) > 1;
------------------------------
SELECT operator_id, COUNT(*)
FROM operators
GROUP BY operator_id
HAVING COUNT(*) > 1;


-- ==============================================
-- BLOCK B | Text format to JSON format |
-- ==============================================
-- fix the cert_o json type error
SELECT certifications
FROM operators
LIMIT 5;

-- Step 1: Fix the certifications column formatting
-- Replace [ with ["  and  ] with "]  and  , with ","
UPDATE operators
SET certifications = 
    CASE 
        -- handle empty array
        WHEN certifications = '[]' THEN '[]'
        -- handle non-empty: wrap each item with double quotes
        ELSE '["' || 
             replace(
                 replace(
                     replace(certifications, '[', ''),
                     ']', ''
                 ),
                 ', ', '", "'
             ) 
             || '"]'
    END;
	
SELECT certifications
FROM operators
LIMIT 5;
-- --------------------------
ALTER TABLE operators
ALTER COLUMN certifications
TYPE jsonb
USING certifications::jsonb;

-- -----------------------------------------------
-- fix the json type error

UPDATE quality_inspection
SET defect_types =
CASE
    WHEN defect_types = '[]' THEN '[]'
    ELSE
        '["' ||
        replace(
            replace(
                replace(
                    replace(defect_types, '[', ''),
                ']', ''),
            '"', ''),            -- remove broken quotes
        ', ', '", "')
        || '"]'
END;

SELECT defect_types
FROM quality_inspection
LIMIT 10;
-- ----------------------


ALTER TABLE quality_inspection
ALTER COLUMN defect_types
TYPE jsonb
USING defect_types::jsonb;
-- --------------------------------------
UPDATE maintenance_log
SET parts_replaced = 
    CASE 
        WHEN parts_replaced = '[]' THEN '[]'
        ELSE '["' || 
             replace(
                 replace(
                     replace(parts_replaced, '[', ''),
                     ']', ''
                 ),
                 ', ', '", "'
             ) 
             || '"]'
    END;

-- Convert to JSONB
select parts_replaced
from maintenance_log
limit 5;

ALTER TABLE maintenance_log
ALTER COLUMN parts_replaced
TYPE jsonb
USING parts_replaced::jsonb;

-- =======================================
-- BLOCK C | JSON to make flag column |
-- =======================================
-- DEALING WITH JSON datatypes
----------------------------------
------------------------------
-- 1. Quality + Flag method
------------------------------
--  Add flag columns
ALTER TABLE quality_inspection
ADD COLUMN IF NOT EXISTS has_surface_crack INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS has_dimensional_error INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS has_contamination INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS has_incomplete_weld INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS has_burr INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS has_discoloration INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS defect_count INT DEFAULT 0;

-- populate flag to the respective column
UPDATE quality_inspection
SET
  has_surface_crack = CASE WHEN defect_types IS NOT NULL AND (defect_types ? 'surface_crack') THEN 1 ELSE 0 END,
  has_dimensional_error = CASE WHEN defect_types IS NOT NULL AND (defect_types ? 'dimensional_error') THEN 1 ELSE 0 END,
  has_contamination = CASE WHEN defect_types IS NOT NULL AND (defect_types ? 'contamination') THEN 1 ELSE 0 END,
  has_incomplete_weld = CASE WHEN defect_types IS NOT NULL AND (defect_types ? 'incomplete_weld') THEN 1 ELSE 0 END,
  has_burr = CASE WHEN defect_types IS NOT NULL AND (defect_types ? 'burr') THEN 1 ELSE 0 END,
  has_discoloration = CASE WHEN defect_types IS NOT NULL AND (defect_types ? 'discoloration') THEN 1 ELSE 0 END,
  defect_count = CASE
                   WHEN defect_types IS NOT NULL AND jsonb_typeof(defect_types) = 'array'
                     THEN jsonb_array_length(defect_types)
                   ELSE 0
                 END;

-- count and verify the data
SELECT
    SUM(has_surface_crack)      AS total_surface_crack,
    SUM(has_dimensional_error)  AS total_dimensional_error,
    SUM(has_contamination)      AS total_contamination,
    SUM(has_incomplete_weld)    AS total_incomplete_weld,
    SUM(has_burr)               AS total_burr,
    SUM(has_discoloration)      AS total_discoloration
FROM quality_inspection;

select * 
from quality_inspection
limit 20;
--------------------------------------------------------------------
-- 2. operators + count_certifications
-------------------------------------------
ALTER TABLE operators
ADD COLUMN IF NOT EXISTS cert_count INT DEFAULT 0;

-- populate the data into the columns
UPDATE operators
SET cert_count = CASE
  WHEN certifications IS NOT NULL AND jsonb_typeof(certifications) = 'array'
    THEN jsonb_array_length(certifications)
  ELSE 0
END;

-- verify
select *
from operators;

----------------------------------------------------------------
-- 3. maintenance + flag
-------------------------------------------------------
--  Add flag columns
ALTER TABLE maintenance_log
ADD COLUMN IF NOT EXISTS parts_count INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS had_filter INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS had_lubricant INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS had_motor INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS had_bearing INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS had_sensor INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS had_valve INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS had_belt INT DEFAULT 0;

-- populate
UPDATE maintenance_log
SET
  parts_count = CASE
                  WHEN parts_replaced IS NOT NULL AND jsonb_typeof(parts_replaced) = 'array'
                    THEN jsonb_array_length(parts_replaced)
                  ELSE 0
                END,
  had_filter = CASE WHEN parts_replaced IS NOT NULL AND (parts_replaced ? 'filter') THEN 1 ELSE 0 END,
  had_lubricant = CASE WHEN parts_replaced IS NOT NULL AND (parts_replaced ? 'lubricant') THEN 1 ELSE 0 END,
  had_motor = CASE WHEN parts_replaced IS NOT NULL AND (parts_replaced ? 'motor') THEN 1 ELSE 0 END,
  had_bearing = CASE WHEN parts_replaced IS NOT NULL AND (parts_replaced ? 'bearing') THEN 1 ELSE 0 END,
  had_sensor = CASE WHEN parts_replaced IS NOT NULL AND (parts_replaced ? 'sensor') THEN 1 ELSE 0 END,
  had_valve = CASE WHEN parts_replaced IS NOT NULL AND (parts_replaced ? 'valve') THEN 1 ELSE 0 END,
  had_belt = CASE WHEN parts_replaced IS NOT NULL AND (parts_replaced ? 'belt') THEN 1 ELSE 0 END;

-- sum and verify
SELECT
  SUM(parts_count) AS total_parts_replaced,
  SUM(had_filter) AS total_filter_replacements,
  SUM(had_lubricant) AS total_lubricant_replacements,
  SUM(had_motor) AS total_motor_replacements,
  SUM(had_bearing) AS total_bearing_replacements,
  SUM(had_sensor) AS total_sensor_replacements,
  SUM(had_valve) AS total_valve_replacements,
  SUM(had_belt) AS total_belt_replacements
FROM maintenance_log;

select *
from maintenance_log
limit 20;


-- ============================================================






