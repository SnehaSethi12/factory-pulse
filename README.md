# Factory Pulse — Manufacturing OEE & Downtime Analytics Platform

A full data integration pipeline that models factory production and downtime data in MySQL, surfaces insights through Apache Superset dashboards and native alerts, and includes a standalone Python service replicating the alert logic outside the BI layer.


---

## Overview

Manufacturing plants generate two continuous streams of data: **production output** (units made, units good/defective, planned vs. actual run time) and **downtime events** (when and why machines stop). This project integrates both into a single analytical model that answers real operational questions:

- Which machines are underperforming on OEE (Overall Equipment Effectiveness)?
- How much production time is being lost to downtime, and why?
- Which machines have the worst defect rates?
- Should someone be alerted right now about excessive downtime?

---

## Architecture

```
 ┌─────────────────┐      ┌──────────────────────┐      ┌────────────────────┐
 │   Seed Data      │ ──▶  │   MySQL Database      │ ──▶  │   Apache Superset   │
 │ (schema.sql +    │      │ manufacturing_        │      │  Dashboards + SQL   │
 │  insert_data.sql)│      │ analytics             │      │  Lab + Alerts       │
 └─────────────────┘      │                       │      └────────────────────┘
                           │  machines             │
                           │  production_logs      │      ┌────────────────────┐
                           │  downtime_events       │ ──▶  │  check_alerts.py    │
                           │  flagged_events        │      │  (standalone Python │
                           └──────────────────────┘      │  alert service)      │
                                                           └────────────────────┘
```

**Data flow:** Schema is created and seeded in MySQL → SQL queries (`queries.sql`) power both Superset charts and the alert-trigger logic → Superset visualizes the data on a dashboard and can independently fire native alerts → `check_alerts.py` runs the same threshold logic as a standalone Python service and writes results into `flagged_events`, demonstrating the alerting logic works even outside the BI tool.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Database | MySQL |
| BI / Visualization | Apache Superset 3.0 (Docker) |
| Scripting / Alerts | Python (`mysql-connector-python`) |
| Environment | Docker |

---

## Database Schema

Four related tables, normalized with foreign keys:

- **`machines`** — machine metadata (name, type, install date, production line)
- **`production_logs`** — daily production records per machine (planned/run minutes, units produced/good, ideal cycle time) — feeds OEE calculations
- **`downtime_events`** — individual downtime incidents per machine with reason codes and duration
- **`flagged_events`** — alert history, written to by both Superset's native alerting and the standalone Python script

Full definitions in [`schema.sql`](./schema.sql).

---

## Key SQL (`queries.sql`)

The queries demonstrate the SQL depth called for in the JD — CTEs, window functions, and aggregate reasoning:

1. **OEE calculation** — `Availability × Performance × Quality`, computed per machine per day via a CTE
2. **Rolling 7-day downtime average** — `AVG() OVER (PARTITION BY ... ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)`
3. **Defect rate ranking** — `RANK() OVER (ORDER BY defect_rate_pct DESC)` to surface the worst-performing machines
4. **Downtime breakdown by reason** — aggregate breakdown feeding the pie chart
5. **Alert-trigger query** — machines exceeding a 120-minute downtime threshold in a rolling 24-hour window; used both as a Superset native alert condition and as the logic inside `check_alerts.py`

---

## Dashboard

The **Manufacturing Analytics** dashboard in Superset combines four distinct chart types to tell a complete operational story:

| Chart | Type | Insight |
|---|---|---|
| OEE Trend by Machine | Line | Day-by-day OEE per machine, spotting consistently underperforming equipment |
| Downtime by Reason | Pie | Which failure categories (mechanical, changeover, material shortage, etc.) dominate lost time |
| Defect Rate Ranking | Bar | Machines ranked by defect percentage, using `RANK()` |
| Downtime Intensity Heatmap | Heatmap | Machine × week grid, colored by rolling downtime severity — quickly spots chronic problem machines |

![alt text](<Screenshot 2026-09-20 224114.png>)
<img width="1533" height="861" alt="image" src="https://github.com/user-attachments/assets/03c6dc96-f7d2-429f-993e-399eaf2406f0" />
<img width="1510" height="797" alt="Screenshot 2026-09-20 233815" src="https://github.com/user-attachments/assets/3260e649-8c12-4e2c-8b44-2c4c90f2324c" />

---

## Alerting

Two independent implementations of the same alert logic, deliberately built to show the pipeline works end-to-end, not just inside one tool:

1. **Superset native alert** — "High Downtime Alert" configured in Alerts & Reports, running query #5 on a schedule and notifying via email when any machine crosses the threshold.
2. **Standalone Python script (`check_alerts.py`)** — connects directly to MySQL, runs the identical threshold logic, prints/logs any triggered alerts, and writes them into `flagged_events`. This satisfies the JD's Python requirement independently of the BI layer and shows the alert logic isn't locked into Superset.

Example output:
```
[2026-09-20 22:59:52] ALERT: CNC-Mill-01 — 150 min downtime in last 24h (threshold: 120)
```
<img width="1920" height="1080" alt="Screenshot 2026-09-20 230018" src="https://github.com/user-attachments/assets/75eba246-f67d-403d-8ec7-91038afa3cdb" />

---


## Setup / Reproduction

1. Load the schema: run [`schema.sql`](./schema.sql) against a MySQL instance.
2. Seed sample data: run [`insert_data.sql`](./insert_data.sql).
3. Connect Superset to the database (SQLAlchemy URI: `mysql+pymysql://<user>:<password>@<host>:3306/manufacturing_analytics`).
4. Build charts from [`queries.sql`](./queries.sql) in Superset's SQL Lab, or import the dashboard directly if exported.
5. Configure the native alert in Superset's Alerts & Reports using query #5.
6. (Optional) Run the standalone alert checker:
   ```
   pip install mysql-connector-python
   python check_alerts.py
   ```

---

## Files

- `schema.sql` — database schema
- `insert_data.sql` — sample seed data
- `queries.sql` — the 5 core analytical/alert queries
- `check_alerts.py` — standalone Python alert service
- `README.md` — this file
