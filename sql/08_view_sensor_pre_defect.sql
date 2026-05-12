-- VIEW: Sensor Metrics on Defect Days
-- Flags production records that coincide with defect events (pin_holes = 1).
-- ================================================================================
CREATE OR REPLACE VIEW v_sensor_pre_defect AS
WITH defect_events AS (
    SELECT
        p.machine_id,
        p.production_date AS defect_date
    FROM v_master_production p
    JOIN quality_inspection q ON q.production_id = p.production_id
    WHERE q.pin_holes = 1
)
SELECT
    m.machine_id,
    m.production_date,
    m.avg_vibration,
    m.avg_temp_z1,
    m.avg_pressure,
    m.avg_power,
    CASE WHEN d.defect_date IS NOT NULL THEN 'Defect Day' ELSE NULL END AS day_type,
    (d.defect_date IS NOT NULL) AS is_defect_day
FROM v_master_production m
LEFT JOIN defect_events d
       ON d.machine_id  = m.machine_id
      AND d.defect_date = m.production_date;

SELECT production_id, COUNT(*)
FROM quality_inspection
GROUP BY production_id
HAVING COUNT(*) > 1;

