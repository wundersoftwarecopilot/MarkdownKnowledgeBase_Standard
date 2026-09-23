---
id: TASK-005
type: task
status: blocked
priority: normal
owner: none
created: 2026-09-02
blocked_by: [Q-002]
related: [MODULE-REPORTS, TASK-003]
---
# TASK-005: Per-customer report time zone

## Goal
Some customers' head offices are in another time zone and read the report's days and times in their own time zone.
Give each customer a report time zone and apply it to that customer's daily report.

## Acceptance criteria
- [ ] Each customer has a report time zone, set in the web UI and defaulting to the quarry's.
- [ ] The report day of each customer follows the answer to Q-002, and MODULE-REPORTS describes it.
- [ ] Tickets weighed between 22:00 and 02:00 quarry-local time appear in exactly one report per customer, including on the nights the clocks change (tested).

## Notes
- 2026-09-02 marta: created from the New task line of PR #11 (codex, TASK-003).
- 2026-09-17 claude-code: blocked on Q-002; the goal does not say where a customer's report day ends.

## Completion
