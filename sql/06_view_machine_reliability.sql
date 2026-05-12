-- ════════════════════════════════════════════════
-- BLOCK B: MACHINE RELIABILITY VIEW
-- One row per machine = 8 rows
-- This is Page 2 Tableau source
-- DON'T need to join this into master view
-- ════════════════════════════════════════════════
-- DROP VIEW v_machine_reliability;
DROP VIEW IF EXISTS v_machine_reliability;

CREATE VIEW v_machine_reliability AS
WITH date_range AS (
    SELECT
        machine_id,
        MIN(maintenance_time) AS first_event,
        MAX(maintenance_time) AS last_event,
        EXTRACT(DAYS FROM (MAX(maintenance_time) - MIN(maintenance_time))) AS operational_days
    FROM maintenance_log
    GROUP BY machine_id
),
corrective_stats AS (
    SELECT
        machine_id,
        COUNT(*) AS corrective_count,
        SUM(downtime_minutes) AS total_corrective_downtime,
        AVG(downtime_minutes) / 60.0 AS avg_mttr_hours
    FROM maintenance_log
    WHERE corrective_event_flag = 1
    GROUP BY machine_id
),
preventive_stats AS (
    SELECT
        machine_id,
        COUNT(*) AS preventive_count,
        SUM(downtime_minutes) AS total_preventive_downtime
    FROM maintenance_log
    WHERE corrective_event_flag = 0
    GROUP BY machine_id
),
production_volume AS (
    SELECT
        machine_id,
        COUNT(*) AS total_production_runs,
        SUM(CASE WHEN batch_size > 0 THEN batch_size ELSE 0 END) AS total_units_produced
    FROM production_log
    GROUP BY machine_id
),
defect_summary AS (
    SELECT
        p.machine_id,
        SUM(q.pin_holes) AS total_defects,
        ROUND(SUM(q.pin_holes)::NUMERIC / NULLIF(COUNT(*), 0) * 100, 2) AS machine_defect_rate_pct
    FROM production_log p
    JOIN quality_inspection q ON p.production_id = q.production_id
    GROUP BY p.machine_id
),
parts_summary AS (
    SELECT
        machine_id,
        SUM(had_filter) AS total_filter_replacements,
        SUM(had_lubricant) AS total_lubricant_replacements,
        SUM(had_motor) AS total_motor_replacements,
        SUM(had_bearing) AS total_bearing_replacements,
        SUM(had_sensor) AS total_sensor_replacements,
        SUM(had_valve) AS total_valve_replacements,
        SUM(had_belt) AS total_belt_replacements
    FROM maintenance_log
    GROUP BY machine_id
)
SELECT
    m.machine_id,
    ROUND(COALESCE(dr.operational_days, 365) / NULLIF(COALESCE(cs.corrective_count, 0), 0), 1) AS mtbf_days_raw,
    CASE
        WHEN COALESCE(cs.corrective_count, 0) = 0
        THEN ROUND(COALESCE(dr.operational_days, 365), 1)
        ELSE ROUND(COALESCE(dr.operational_days, 365)::NUMERIC / cs.corrective_count, 1)
    END AS mtbf_days,
    ROUND(COALESCE(cs.avg_mttr_hours, 0)::NUMERIC, 2) AS avg_mttr_hours,
    COALESCE(cs.total_corrective_downtime, 0) AS total_corrective_downtime,
    COALESCE(ps.total_preventive_downtime, 0) AS total_preventive_downtime,
    COALESCE(cs.total_corrective_downtime, 0) + COALESCE(ps.total_preventive_downtime, 0) AS total_downtime_minutes,
    ROUND(
        (COALESCE(cs.total_corrective_downtime, 0) + COALESCE(ps.total_preventive_downtime, 0))::NUMERIC
        / NULLIF(COALESCE(cs.corrective_count, 0) + COALESCE(ps.preventive_count, 0), 0)
    , 2) AS avg_downtime_per_event,
    COALESCE(cs.corrective_count, 0) AS corrective_count,
    COALESCE(ps.preventive_count, 0) AS preventive_count,
    COALESCE(cs.corrective_count, 0) + COALESCE(ps.preventive_count, 0) AS total_maintenance_events,
    ROUND(
        COALESCE(ps.preventive_count, 0)::NUMERIC
        / NULLIF(COALESCE(cs.corrective_count, 0) + COALESCE(ps.preventive_count, 0), 0) * 100
    , 2) AS pmp_pct,
    COALESCE(pv.total_production_runs, 0) AS total_production_runs,
    COALESCE(pv.total_units_produced, 0) AS total_units_produced,
    COALESCE(ds.total_defects, 0) AS total_defects,
    COALESCE(ds.machine_defect_rate_pct, 0) AS machine_defect_rate_pct,
    COALESCE(pt.total_filter_replacements, 0) AS total_filter_replacements,
    COALESCE(pt.total_lubricant_replacements, 0) AS total_lubricant_replacements,
    COALESCE(pt.total_motor_replacements, 0) AS total_motor_replacements,
    COALESCE(pt.total_bearing_replacements, 0) AS total_bearing_replacements,
    COALESCE(pt.total_sensor_replacements, 0) AS total_sensor_replacements,
    COALESCE(pt.total_valve_replacements, 0) AS total_valve_replacements,
    COALESCE(pt.total_belt_replacements, 0) AS total_belt_replacements
FROM (
    SELECT DISTINCT machine_id FROM maintenance_log
    UNION
    SELECT DISTINCT machine_id FROM production_log
) m
LEFT JOIN date_range dr ON dr.machine_id = m.machine_id
LEFT JOIN corrective_stats cs ON cs.machine_id = m.machine_id
LEFT JOIN preventive_stats ps ON ps.machine_id = m.machine_id
LEFT JOIN production_volume pv ON pv.machine_id = m.machine_id
LEFT JOIN defect_summary ds ON ds.machine_id = m.machine_id
LEFT JOIN parts_summary pt ON pt.machine_id = m.machine_id;

SELECT * FROM v_machine_reliability;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'v_machine_reliability';

SELECT COUNT(*) FROM v_master_production;
SELECT COUNT(DISTINCT production_id) FROM v_master_production;
