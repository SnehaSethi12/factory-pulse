import { useState } from 'react'

const SUPERSET_DASHBOARD_URL = 'http://localhost:8088/superset/dashboard/10/?standalone=1'

const stats = [
  {
    label: 'Average OEE',
    value: '0.68',
    unit: '',
    detail: 'across 8 machines, last 30 days',
    status: 'warning',
  },
  {
    label: 'Total Downtime',
    value: '142.5',
    unit: 'hrs',
    detail: 'accumulated this period',
    status: 'ok',
  },
  {
    label: 'Worst Performer',
    value: 'INJ-MOLDER-02',
    unit: '',
    detail: '2.08% defect rate — highest on the floor',
    status: 'critical',
  },
  {
    label: 'Active Alerts',
    value: '1',
    unit: '',
    detail: 'CNC-Mill-01 — 150 min downtime / 24h',
    status: 'critical',
  },
]

function StatPanel({ label, value, unit, detail, status }) {
  return (
    <div className={`stat-panel stat-panel--${status}`}>
      <span className="stat-panel__label">{label}</span>
      <div className="stat-panel__value-row">
        <span className="stat-panel__value">{value}</span>
        {unit && <span className="stat-panel__unit">{unit}</span>}
      </div>
      <span className="stat-panel__detail">{detail}</span>
    </div>
  )
}

export default function App() {
  const [frameFailed, setFrameFailed] = useState(false)

  return (
    <div className="shell">
      <header className="masthead">
        <div className="masthead__identity">
          <span className="masthead__mark">FP</span>
          <div>
            <h1 className="masthead__title">Factory Pulse</h1>
            <p className="masthead__subtitle">Manufacturing OEE &amp; Downtime Analytics</p>
          </div>
        </div>
        <div className="masthead__meta">
          <span className="masthead__line">Line status: 8 machines monitored</span>
          <span className="masthead__line masthead__line--dim">
            Last sync {new Date().toLocaleString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true })}
          </span>
        </div>
      </header>

      <section className="stat-grid">
        {stats.map((s) => (
          <StatPanel key={s.label} {...s} />
        ))}
      </section>

      <section className="console">
        <div className="console__bar">
          <span className="console__bar-label">Manufacturing Analytics — Live Dashboard</span>
          <a className="console__bar-link" href={SUPERSET_DASHBOARD_URL} target="_blank" rel="noreferrer">
            Open in Superset
          </a>
        </div>
        <div className="console__screen">
          {!frameFailed ? (
            <iframe
              title="Manufacturing Analytics Dashboard"
              src={SUPERSET_DASHBOARD_URL}
              onError={() => setFrameFailed(true)}
            />
          ) : (
            <div className="console__fallback">
              <p>Dashboard couldn't load here.</p>
              <p className="console__fallback-detail">
                Superset blocks embedding by default — enable it under Settings → Embed Dashboard,
                or open it directly using the link above.
              </p>
            </div>
          )}
        </div>
      </section>
    </div>
  )
}