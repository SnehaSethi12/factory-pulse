-- Manufacturing OEE & Downtime Analytics — Core Queries
-- These are the queries that feed the Superset dashboards.
-- Point Superset's "SQL Lab" / chart datasource at these to build charts.

-- ============================================================
-- 1. OEE (Overall Equipment Effectiveness) per machine, per day
--    OEE = Availability x Performance x Quality
-- ============================================================
WITH oee_calc AS (
    SELECT
        m.machine_name,
        p.log_date,
        (p.run_minutes / NULLIF(p.planned_minutes, 0))                       AS availability,
        (p.units_produced * p.ideal_cycle_time_sec / 60.0)
            / NULLIF(p.run_minutes, 0)                                        AS performance,
        (p.units_good / NULLIF(p.units_produced, 0))                          AS quality
    FROM production_logs p
    JOIN machines m ON m.machine_id = p.machine_id
)
SELECT
    machine_name,
    log_date,
    ROUND(availability, 3)  AS availability,
    ROUND(performance, 3)   AS performance,
    ROUND(quality, 3)       AS quality,
    ROUND(availability * performance * quality, 3) AS oee
FROM oee_calc
ORDER BY log_date DESC, machine_name;


-- ============================================================
-- 2. Rolling 7-day average downtime per machine (window function)
-- ============================================================
WITH daily_downtime AS (
    SELECT
        m.machine_name,
        DATE(d.event_start) AS event_date,
        SUM(d.downtime_minutes) AS total_downtime
    FROM downtime_events d
    JOIN machines m ON m.machine_id = d.machine_id
    GROUP BY m.machine_name, DATE(d.event_start)
)
SELECT
    machine_name,
    event_date,
    total_downtime,
    ROUND(AVG(total_downtime) OVER (
        PARTITION BY machine_name
        ORDER BY event_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 1) AS rolling_7day_avg_downtime
FROM daily_downtime
ORDER BY machine_name, event_date;


-- ============================================================
-- 3. Rank machines by defect rate (window function: RANK)
-- ============================================================
WITH defect_summary AS (
    SELECT
        m.machine_name,
        SUM(p.units_produced) AS total_produced,
        SUM(p.units_produced - p.units_good) AS total_defects,
        ROUND(
            SUM(p.units_produced - p.units_good) * 100.0
            / NULLIF(SUM(p.units_produced), 0), 2
        ) AS defect_rate_pct
    FROM production_logs p
    JOIN machines m ON m.machine_id = p.machine_id
    GROUP BY m.machine_name
)
SELECT
    machine_name,
    total_produced,
    total_defects,
    defect_rate_pct,
    RANK() OVER (ORDER BY defect_rate_pct DESC) AS defect_rank
FROM defect_summary
ORDER BY defect_rank;


-- ============================================================
-- 4. Downtime breakdown by reason code (for a pie/bar chart)
-- ============================================================
SELECT
    reason_code,
    COUNT(*) AS event_count,
    SUM(downtime_minutes) AS total_minutes,
    ROUND(SUM(downtime_minutes) * 100.0
        / SUM(SUM(downtime_minutes)) OVER (), 1) AS pct_of_total_downtime
FROM downtime_events
GROUP BY reason_code
ORDER BY total_minutes DESC;


-- ============================================================
-- 5. Alert-trigger query: machines currently over a downtime threshold
--    Wire this into Superset's Alerts & Reports as the SQL condition,
--    or run it from the Python script to populate flagged_events.
-- ============================================================
SELECT
    m.machine_id,
    m.machine_name,
    SUM(d.downtime_minutes) AS downtime_last_24h
FROM downtime_events d
JOIN machines m ON m.machine_id = d.machine_id
WHERE d.event_start >= NOW() - INTERVAL 1 DAY
GROUP BY m.machine_id, m.machine_name
HAVING SUM(d.downtime_minutes) > 120;  -- threshold: 2 hours downtime in 24h
