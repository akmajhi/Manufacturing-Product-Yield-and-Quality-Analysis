-- ════════════════════════════════════════════════
-- BLOCK C: OPERATOR SUMMARY VIEW
-- One row per operator = 15 rows
-- This is operator bubble chart source
-- ════════════════════════════════════════════════
-- DROP VIEW v_operator_summary;
CREATE OR REPLACE VIEW v_operator_summary AS
WITH operator_performance AS (
    SELECT
        operator_id,
        experience_months,
        cert_count,
        COUNT(*) AS total_runs,
        SUM(CASE WHEN batch_size > 0 THEN batch_size ELSE 0 END) AS total_units_produced,
        SUM(pin_holes) AS total_defects,
        ROUND(SUM(pin_holes)::NUMERIC / NULLIF(COUNT(*), 0) * 100, 2) AS operator_defect_rate_pct,
        ROUND(AVG(CASE WHEN pin_holes = 1 THEN severity_score END), 2) AS avg_severity_when_fail,
        ROUND(AVG(duration_minutes), 2) AS avg_duration_minutes,
        ROUND(AVG(days_since_maint), 2) AS avg_days_since_maint,
        ROUND(AVG(speed_deviation_uph)::NUMERIC, 3) AS avg_speed_deviation_uph,
        SUM(CASE WHEN shift = 'morning' THEN 1 ELSE 0 END) AS morning_runs,
        SUM(CASE WHEN shift = 'afternoon' THEN 1 ELSE 0 END) AS afternoon_runs,
        SUM(CASE WHEN shift = 'night' THEN 1 ELSE 0 END) AS night_runs
    FROM v_master_production
    GROUP BY operator_id, experience_months, cert_count
)
SELECT
    operator_id,
    experience_months,
    cert_count,
    total_runs,
    total_units_produced,
    total_defects,
    operator_defect_rate_pct,
    avg_severity_when_fail,
    avg_duration_minutes,
    avg_days_since_maint,
    avg_speed_deviation_uph,
    CASE
        WHEN morning_runs >= afternoon_runs AND morning_runs >= night_runs THEN 'morning'
        WHEN afternoon_runs >= night_runs THEN 'afternoon'
        ELSE 'night'
    END AS primary_shift,
    morning_runs,
    afternoon_runs,
    night_runs
FROM operator_performance;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'v_operator_summary';
