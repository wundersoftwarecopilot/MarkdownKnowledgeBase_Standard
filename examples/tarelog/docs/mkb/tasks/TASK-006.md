---
id: TASK-006
type: task
status: todo
priority: high
owner: none
created: 2026-09-02
related: [SERVICE-GATEWAY, TS-SQLITE-LOCKED, TASK-002]
code: [src/tarelog/gateway/reader.py]
---
# TASK-006: Buffer readings while SQLite is locked

## Goal
When another connection holds the SQLite write lock longer than the busy timeout, the reader's insert fails with `sqlite3.OperationalError: database is locked` and the reading is dropped.
Keep such readings and write them once the lock is free, so that no stable weight is lost.
Out of scope: shortening the report job's transaction.

## Acceptance criteria
- [ ] A reading that cannot be written is kept in a bounded in-memory queue per lane and written in order once the database accepts writes again.
- [ ] No reading is lost while a test holds the write lock for 60 seconds with `BEGIN IMMEDIATE`.
- [ ] A full queue logs an error per dropped reading, and the web UI status page shows the queue length per lane.
- [ ] The `TODO(TASK-006)` comment in `src/tarelog/gateway/reader.py` is gone.

## Notes
- 2026-09-02 claude-code: found during TASK-002; the failing insert in `src/tarelog/gateway/reader.py` carries a `TODO(TASK-006)` comment.

## Completion
