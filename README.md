# Manufacturing OEE & Downtime Analytics Platform

## One-line pitch
A SQL-first analytics platform that turns raw manufacturing production data into live OEE dashboards and automated downtime alerts — built end-to-end with MySQL, Apache Superset, Python, and a React embed layer.

## Problem statement
Manufacturing lines generate constant production and downtime data, but raw logs don't tell operators when something is going wrong. This project builds a pipeline that ingests raw machine data, models it relationally, computes industry-standard OEE (Overall Equipment Effectiveness) metrics using SQL window functions, visualizes it in Superset dashboards, and fires an alert when a machine's downtime crosses a threshold.

## Architecture
```
Raw CSV (production + downtime logs)
        │
        ▼
Python ETL script (clean, validate, load)
        │
        ▼
MySQL database (machines / production_logs / downtime_events / flagged_events)
        │
        ├──► Apache Superset (dashboards + Alerts & Reports)
        │
        └──► Flask API ──► React frontend (KPI cards + embedded Superset chart)
```

## Tech stack
- **SQL**: MySQL, CTEs, window functions (RANK, moving averages) for OEE, downtime trend, and defect-rate ranking
- **BI**: Apache Superset (Docker-deployed), native Alerts & Reports for threshold-based notifications
- **Python**: ETL script for data cleaning/loading, plus a Flask API layer
- **Frontend**: React — KPI summary cards + an embedded Superset chart via the Superset Embedded SDK

## Key features
1. **OEE calculation** — Availability × Performance × Quality, computed per machine per day
2. **Rolling 7-day downtime trend** using SQL window functions
3. **Defect-rate ranking** across machines
4. **Automated alerting** — Superset Alerts & Reports (or a Python-driven check) flags any machine exceeding a downtime threshold in the last 24 hours
5. **React dashboard view** — lightweight frontend summarizing the top KPIs alongside the live Superset chart

## What I'd extend with more time
- Predictive maintenance model (flag machines likely to fail before downtime occurs)
- Slack/email integration for the alert pipeline
- Role-based dashboard views for different stakeholders (line manager vs. plant head)

## Repo
[GitHub link here]
