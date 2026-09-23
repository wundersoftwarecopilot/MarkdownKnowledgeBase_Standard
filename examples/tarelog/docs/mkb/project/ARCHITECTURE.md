---
type: architecture
verified: 2026-09-17
---
# Architecture: TareLog

## System context
- Weighbridge clerks use the web UI on the office PC; the quarry office uses it for customers, trucks and the day view.
- Two Ponderix WI-200 weighing indicators, one per lane, reached through serial-to-Ethernet converters on the office network (INT-WI200).
- Beta Haulage receives its daily CSV report on its SFTP server (INT-HAULER-SFTP).
- The other customers receive the same CSV by e-mail through the quarry's SMTP relay; delivery failures raise an alert e-mail to the operations mailbox.
- The quarry's accounting system imports the daily totals; TareLog does no invoicing.

## Components
| Component | Responsibility | Code | Doc |
|---|---|---|---|
| Reader service | Keeps a TCP connection per lane, parses WI-200 frames, stores stable weights as readings | `src/tarelog/gateway/` | SERVICE-GATEWAY |
| Ticket store | Readings, tickets, corrections and registers in SQLite; the only code that opens the database | `src/tarelog/tickets/` | DB-TICKETS |
| Web UI | Operator pages: live weights, weighing, tickets, corrections, day view | `src/tarelog/web/` | - |
| Reports | Daily totals and one CSV report per customer and report day | `src/tarelog/reports/` | MODULE-REPORTS |
| Delivery | Sends each report by SFTP or e-mail, retries, alerts operations | `src/tarelog/delivery/` | INT-HAULER-SFTP |
| Migrations | Numbered SQL schema changes applied at release | `migrations/` | DB-TICKETS |

## Data flow
1. Weighing: indicator -> converter -> reader service, which cuts frames with `src/tarelog/gateway/wi200.py` and writes a reading once the weight is stable; the clerk confirms the reading in the web UI, which writes the ticket through the ticket store.
2. Daily report: `tarelog-report.timer` starts the report job at 05:00; it recomputes the daily totals of the previous report day, writes one CSV per customer and hands each file to delivery, which uploads it (Beta Haulage) or e-mails it (the others) before 06:00.
3. Correction: a clerk or the office creates a correction ticket in the web UI that references the original; the original stays unchanged and the next daily report lists the correction.

## Deployment
- Everything runs on one Linux mini-PC in the weighbridge office, installed in `/opt/tarelog`, as three systemd units: `tarelog-reader.service`, `tarelog-web.service` and `tarelog-report.timer` (which starts `tarelog-report.service`).
- The live database is `data/tarelog.db` under `/opt/tarelog`; it is never committed.
- Release: marta or luca tags a version on `main`, installs the wheel on the mini-PC, applies migrations and restarts the units; the deployed version is recorded in [state/CURRENT.md](../state/CURRENT.md).
- There is one environment, production; development runs on laptops against the WI-200 simulator.

## Cross-cutting concerns
- Configuration: `/etc/tarelog/tarelog.toml`, read once at start-up; each service's keys are in its knowledge doc.
- Secrets: host vault paths only ([project/CONSTRAINTS.md](CONSTRAINTS.md), section Security and data).
- Storage: one SQLite file in WAL mode with one writer at a time (ADR-001).
- Report format: CSV for every customer (ADR-003).
- Time: timestamps are stored in UTC and shown or reported in quarry-local time.
- Logging: journald per unit, read with `journalctl -u` and the unit name.
