---
id: TASK-004
type: task
status: done
priority: high
owner: claude-code
branch: claude-code/task-004-sftp-delivery
created: 2026-09-01
closed: 2026-09-16
related: [INT-HAULER-SFTP, ADR-003, MODULE-REPORTS]
code: [src/tarelog/delivery/]
---
# TASK-004: Deliver daily reports to the customer SFTP

## Goal
Upload each day's report to the Beta Haulage SFTP server, so that it arrives by 06:00 without anyone sending it by hand.
Out of scope: the other customers, who keep receiving their report by e-mail.

## Acceptance criteria
- [x] The daily report is uploaded as the CSV file of ADR-003 to `/inbound/tarelog/` on the Beta Haulage SFTP server (resolves Q-001).
- [x] Authentication uses the SSH key read at runtime from the host vault at `tarelog/sftp-key`; the code has no password path (resolves Q-001).
- [x] The file is complete on the server by 06:00 local time: it is uploaded under a temporary name and renamed when complete.
- [x] A failed upload is retried 3 times, 5 minutes apart; after the third failure an alert e-mail goes to the operations mailbox.

## Notes
- 2026-09-08 codex: blocked on Q-001; the customer's file specification names both key and password authentication.
- 2026-09-15 luca: released; partial work on branch codex/task-004-sftp-delivery, see its handoff

## Completion
- 2026-09-16 claude-code: done in PR #15
- Shipped: `src/tarelog/delivery/sftp.py` uploads the CSV with key authentication (codex, 2026-09-15), retries 3 times and sends the alert e-mail (claude-code, 2026-09-16).
- Docs: INT-HAULER-SFTP, MODULE-REPORTS
- Follow-ups: none
- Deviations: none
