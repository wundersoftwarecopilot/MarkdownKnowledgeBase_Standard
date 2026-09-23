---
id: TASK-001
type: task
status: in-progress
priority: normal
owner: luca
branch: luca/task-001-nightly-backup
created: 2026-09-01
related: [DB-TICKETS]
code: [src/tarelog/tickets/backup.py]
---
# TASK-001: Nightly backup of the ticket database

## Goal
Take a consistent copy of `data/tarelog.db` every night, so that a disk failure on the weighbridge PC loses at most one day of tickets.
Out of scope: off-site copies.

## Acceptance criteria
- [ ] A systemd timer runs the backup at 02:00 with the SQLite online backup API, never a plain file copy (DB-TICKETS).
- [ ] Copies land on the office NAS share and the 30 newest are kept.
- [ ] A failed backup sends an alert e-mail to the operations mailbox.
- [ ] A restore from a copy is tested once on a spare machine, and the restore steps are added to DB-TICKETS.

## Notes
- 2026-09-01 luca: the office NAS share is mounted at `/mnt/nas-backup` on the weighbridge PC.

## Completion
