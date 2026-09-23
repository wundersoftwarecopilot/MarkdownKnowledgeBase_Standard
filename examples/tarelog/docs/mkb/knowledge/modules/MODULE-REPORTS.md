---
id: MODULE-REPORTS
type: module
summary: Daily delivery report per customer - daily totals, CSV report files, report day boundary, 05:00 report timer
code: [src/tarelog/reports/]
verified: 2026-09-17
related: [ADR-003, DB-TICKETS, INT-HAULER-SFTP, TASK-005]
---
# MODULE-REPORTS: Daily delivery reports

## Purpose
Builds each customer's daily delivery report from the tickets of one report day and writes it as a CSV file (ADR-003).
Also recomputes the daily totals that the web UI day view and the accounting export read.
Sending the files is not its job: it hands them to `src/tarelog/delivery/`, which uploads by SFTP (INT-HAULER-SFTP) or e-mails them (`src/tarelog/delivery/mailer.py`).

## Interfaces
- `src/tarelog/reports/job.py` (`run_daily()`): entry point of `tarelog-report.service`, which `tarelog-report.timer` starts at 05:00; totals first, then one CSV per customer, then delivery.
- `src/tarelog/reports/daily.py` (`build_report()`): the ticket and correction rows of one customer and report day.
- `src/tarelog/reports/csv_out.py` (`write_csv()`): writes the rows in the column order of INT-HAULER-SFTP.
- `python -m tarelog.reports --day 2026-09-21 --customer beta-haulage --no-deliver`: rebuilds one report without sending it.

## How it works
- A report day runs from 00:00 to 24:00 quarry-local time, the same for every customer; the quarry's time zone is `site.timezone` in `/etc/tarelog/tarelog.toml`.
- Per-customer report time zones are TASK-005, which waits for the answer to Q-002.
- Each run covers the previous report day; files go to one directory per customer under `/var/lib/tarelog/reports/` and are kept 90 days.
- A correction appears in the report of the day it was made, with `corrects_ticket_no` set; the corrected ticket's row stays as it was in its own day's report.
- The totals step deletes and rewrites the report day's rows of `daily_totals` (DB-TICKETS) in one write transaction.
- Delivery is called once per file; a failed delivery does not stop the files of other customers.
- Reports are CSV only; the PDF pipeline with headless Chromium was removed by TASK-007.

## Invariants
- A report is built from stored tickets only; running it twice for the same day yields the same bytes, which resends rely on.
- Tickets are only read, never changed ([project/CONSTRAINTS.md](../../project/CONSTRAINTS.md), section Regulatory and legal).
- The column order is an external contract with Beta Haulage (INT-HAULER-SFTP); changing it needs their agreement.

## Gotchas
- `sqlite3.OperationalError: database is locked` in the reader or web UI log around 05:00 -> the totals step holds the write lock for about 20 seconds -> never add slow work inside that transaction; readings lost meanwhile are TASK-006, other lock holders are in TS-SQLITE-LOCKED.
- A customer's report is empty although its trucks weighed that day -> those trucks are registered to another customer -> fix the truck in the web UI register and rebuild with `--no-deliver` before sending.

## Testing
- `pytest tests/reports/` compares generated files with the golden CSV files in `tests/reports/golden/`; regenerate them only when the column contract changes.
- Report day edge cases use tickets at 23:59 and 00:01 quarry-local time, including the nights the clocks change.
