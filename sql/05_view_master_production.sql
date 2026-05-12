-- ==================================================
-- BLOCK A: MASTER PRODUCTION VIEW
-- One row per production run = 8000 rows
-- ==================================================

CREATE VIEW v_master_production AS
SELECT
    p.production_id,
    p.machine_id,
    p.product_id,
    p.operator_id,
    p.shift,
    p.production_date,
    p.duration_minutes,
    CASE WHEN p.batch_size > 0 THEN p.batch_size ELSE NULL END AS batch_size,
    p.days_since_maint,
    p.last_maint_type,
    p.environment_temp,
    p.environment_humidity,
    CASE
        WHEN p.environment_temp < 18 OR p.environment_temp > 25
          OR p.environment_humidity < 30 OR p.environment_humidity > 70
        THEN 1 ELSE 0
    END AS env_risk_flag,
    pr.product_family,
    pr.recommended_speed,
    pr.tolerance_spec_1,
    pr.tolerance_spec_2,
    s.avg_temp_z1,
    s.max_temp_z1,
    s.avg_temp_z2,
    s.max_temp_z2,
    s.avg_vibration,
    s.max_vibration,
    s.avg_speed AS sensor_avg_speed_rpm,
    s.avg_pressure,
    s.avg_power,
    s.outlier_rate_pct,
    ROUND(
        (CASE WHEN p.batch_size > 0 THEN p.batch_size ELSE 0 END)
        / NULLIF(p.duration_minutes / 60.0, 0)
    , 2) AS throughput_uph,
    ROUND(
        (
            (CASE WHEN p.batch_size > 0 THEN p.batch_size ELSE 0 END)
            / NULLIF(p.duration_minutes / 60.0, 0)
        )
        / NULLIF(pr.recommended_speed, 0) * 100
    , 2) AS prod_speed_efficiency_pct,
    ROUND(
        ABS(
            (CASE WHEN p.batch_size > 0 THEN p.batch_size ELSE 0 END)
            / NULLIF(p.duration_minutes / 60.0, 0)
            - pr.recommended_speed
        )
    , 3) AS speed_deviation_uph,
    CASE
        WHEN (
            ABS(
                (CASE WHEN p.batch_size > 0 THEN p.batch_size ELSE 0 END)
                / NULLIF(p.duration_minutes / 60.0, 0)
                - pr.recommended_speed
            )
        ) IS NULL THEN 'No Sensor Data'
        WHEN ABS(
            (CASE WHEN p.batch_size > 0 THEN p.batch_size ELSE 0 END)
            / NULLIF(p.duration_minutes / 60.0, 0)
            - pr.recommended_speed
        ) <= 0.3 THEN '1. On Spec (≤0.3 UPH)'
        WHEN ABS(
            (CASE WHEN p.batch_size > 0 THEN p.batch_size ELSE 0 END)
            / NULLIF(p.duration_minutes / 60.0, 0)
            - pr.recommended_speed
        ) <= 0.7 THEN '2. Slight (0.3–0.7 UPH)'
        WHEN ABS(
            (CASE WHEN p.batch_size > 0 THEN p.batch_size ELSE 0 END)
            / NULLIF(p.duration_minutes / 60.0, 0)
            - pr.recommended_speed
        ) <= 1.2 THEN '3. Moderate (0.7–1.2 UPH)'
        ELSE '4. High Dev (>1.2 UPH)'
    END AS speed_dev_bucket,
    q.pin_holes,
    q.num_defects,
    q.severity_score,
    q.defect_count,
    q.has_surface_crack,
    q.has_dimensional_error,
    q.has_contamination,
    q.has_incomplete_weld,
    q.has_burr,
    q.has_discoloration,
    q.inspector_id,
    ROUND(
        (EXTRACT(EPOCH FROM (q.inspect_time - p.end_time)) / 60)::NUMERIC
    , 2) AS inspect_delay_minutes,
    o.experience_months,
    o.cert_count
FROM production_log p
JOIN quality_inspection q ON p.production_id = q.production_id
JOIN product_catalog pr ON p.product_id = pr.product_id
JOIN operators o ON p.operator_id = o.operator_id
LEFT JOIN v_sensor_daily s ON p.machine_id = s.machine_id
                           AND p.production_date = s.production_date;

-- DROP VIEW v_master_production;
	
SELECT *
FROM v_master_production
LIMIT 20;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'v_master_production';
