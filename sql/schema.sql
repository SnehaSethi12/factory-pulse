-- Manufacturing OEE & Downtime Analytics — Schema
-- Load this first, then run your ETL script to populate from the raw CSV.

CREATE DATABASE IF NOT EXISTS manufacturing_analytics;
USE manufacturing_analytics;

CREATE TABLE machines (
    machine_id      INT PRIMARY KEY AUTO_INCREMENT,
    machine_name    VARCHAR(100) NOT NULL,
    machine_type    VARCHAR(50),
    install_date    DATE,
    line_id         VARCHAR(20)
);

CREATE TABLE production_logs (
    log_id          INT PRIMARY KEY AUTO_INCREMENT,
    machine_id      INT NOT NULL,
    log_date        DATE NOT NULL,
    planned_minutes INT NOT NULL,          -- scheduled production time
    run_minutes     INT NOT NULL,          -- actual time machine was running
    units_produced  INT NOT NULL,
    units_good      INT NOT NULL,          -- non-defective units
    ideal_cycle_time_sec DECIMAL(6,2),     -- for performance rate calc
    FOREIGN KEY (machine_id) REFERENCES machines(machine_id)
);

CREATE TABLE downtime_events (
    event_id        INT PRIMARY KEY AUTO_INCREMENT,
    machine_id      INT NOT NULL,
    event_start     DATETIME NOT NULL,
    event_end       DATETIME,
    downtime_minutes INT,
    reason_code     VARCHAR(50),           -- e.g. 'mechanical_failure', 'changeover', 'material_shortage'
    FOREIGN KEY (machine_id) REFERENCES machines(machine_id)
);

CREATE TABLE flagged_events (
    flag_id         INT PRIMARY KEY AUTO_INCREMENT,
    machine_id      INT NOT NULL,
    flagged_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    metric_name     VARCHAR(50),           -- e.g. 'oee', 'downtime_rate'
    metric_value    DECIMAL(6,2),
    threshold       DECIMAL(6,2),
    severity        VARCHAR(20),           -- 'warning' / 'critical'
    FOREIGN KEY (machine_id) REFERENCES machines(machine_id)
);
