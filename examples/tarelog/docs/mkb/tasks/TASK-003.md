---
id: TASK-003
type: task
status: done
priority: high
owner: codex
branch: codex/task-003-daily-report
created: 2026-09-01
closed: 2026-09-02
related: [MODULE-REPORTS, ADR-002, TASK-005]
code: [src/tarelog/reports/]
---
# TASK-003: Daily delivery report per customer

## Goal
Generate each customer's daily delivery report from the tickets of the previous report day, so that marta no longer compiles it by hand.

## Acceptance criteria
- [x] One report per customer and report day lists every ticket, with each correction next to the ticket it corrects.
- [x] Totals per product match the day view of the web UI.
- [x] The report job runs from a systemd timer and has sent every report before 06:00 local time.
- [x] Golden-file tests cover two customers, one of them with a correction.

## Notes
- 2026-09-02 marta: dispatched to Codex cloud.

## Completion
- 2026-09-02 codex: done in PR #11
- Shipped: per-customer daily report in `src/tarelog/reports/`, rendered to PDF with headless Chromium and e-mailed by `src/tarelog/delivery/mailer.py`.
- Docs: MODULE-REPORTS (new), ADR-002
- Follow-ups: TASK-005
- Deviations: none
