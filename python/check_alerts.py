"""
check_alerts.py
Manufacturing OEE & Downtime Analytics — Alert Checker

This script connects to the local MySQL database, runs the downtime
threshold query, and inserts any triggered alerts into the
flagged_events table. In production this would run on a schedule
(cron / Task Scheduler / Superset's own Alerts & Reports feature) --
here it demonstrates the same logic as a standalone Python component,
satisfying the JD's Python requirement independently of Superset.

Install dependency first:
    pip install mysql-connector-python
"""

import mysql.connector
from datetime import datetime

# ---- Connection settings: update these to match your local setup ----
DB_CONFIG = {
    "host": "127.0.0.1",
    "user": "root",
    "password": "",          # <-- put your MySQL root password here
    "database": "manufacturing_analytics"
}

DOWNTIME_THRESHOLD_MINUTES = 120  # 2 hours in a 24h window


def get_connection():
    return mysql.connector.connect(**DB_CONFIG)


def find_machines_over_threshold(cursor):
    """
    Same logic as query #5 in queries.sql:
    machines whose downtime in the last 24h exceeds the threshold.
    """
    query = """
        SELECT
            m.machine_id,
            m.machine_name,
            SUM(d.downtime_minutes) AS downtime_last_24h
        FROM downtime_events d
        JOIN machines m ON m.machine_id = d.machine_id
        WHERE d.event_start >= NOW() - INTERVAL 1 DAY
        GROUP BY m.machine_id, m.machine_name
        HAVING SUM(d.downtime_minutes) > %s
    """
    cursor.execute(query, (DOWNTIME_THRESHOLD_MINUTES,))
    return cursor.fetchall()


def insert_flag(cursor, machine_id, downtime_value):
    severity = "critical" if downtime_value > 180 else "warning"
    insert_query = """
        INSERT INTO flagged_events
            (machine_id, metric_name, metric_value, threshold, severity)
        VALUES (%s, %s, %s, %s, %s)
    """
    cursor.execute(insert_query, (
        machine_id, "downtime_minutes_24h", downtime_value,
        DOWNTIME_THRESHOLD_MINUTES, severity
    ))


def main():
    conn = get_connection()
    cursor = conn.cursor()

    triggered = find_machines_over_threshold(cursor)

    if not triggered:
        print(f"[{datetime.now()}] No machines over threshold. All clear.")
    else:
        for machine_id, machine_name, downtime_value in triggered:
            insert_flag(cursor, machine_id, downtime_value)
            print(f"[{datetime.now()}] ALERT: {machine_name} — "
                  f"{downtime_value} min downtime in last 24h "
                  f"(threshold: {DOWNTIME_THRESHOLD_MINUTES})")
        conn.commit()

    cursor.close()
    conn.close()


if __name__ == "__main__":
    main()
