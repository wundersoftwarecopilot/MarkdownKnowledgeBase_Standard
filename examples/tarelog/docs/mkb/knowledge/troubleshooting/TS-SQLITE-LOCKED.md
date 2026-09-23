---
id: TS-SQLITE-LOCKED
type: troubleshooting
summary: sqlite3.OperationalError database is locked - a second writer holds the SQLite write lock past the busy timeout
code: [src/tarelog/tickets/store.py]
verified: 2026-09-01
related: [ADR-001, DB-TICKETS, SERVICE-GATEWAY]
---
# TS-SQLITE-LOCKED: Database is locked

## Symptom
The web UI shows "Could not save, try again" when a clerk saves a ticket or a correction, and `journalctl -u tarelog-web` or `journalctl -u tarelog-reader` shows:

```text
sqlite3.OperationalError: database is locked
```

## Cause
SQLite in WAL mode allows one writer at a time (ADR-001).
`src/tarelog/tickets/store.py` opens every connection with a busy timeout of 5000 ms; a writer that waits longer gets this error.
Lock holders seen so far: the report job's totals step at 05:00, about 20 seconds; an interactive `sqlite3` shell left inside an open transaction on the weighbridge PC; a graphical database browser left open with unsaved edits.

## Fix
1. On the weighbridge PC, find the processes holding the database: `sudo fuser -v /opt/tarelog/data/tarelog.db /opt/tarelog/data/tarelog.db-wal`.
2. An interactive session: commit or roll back, then close it.
3. The report job: wait until it finishes, usually within a minute, then save again.
4. Never delete `data/tarelog.db-wal` or `data/tarelog.db-shm` to release the lock: that loses committed tickets.

## Prevention
- Open ad-hoc sessions read-only: `sqlite3 -readonly /opt/tarelog/data/tarelog.db`.
- Keep every write transaction short and never do slow work (rendering, network calls) inside one (ADR-001).
