---
id: DB-TICKETS
type: database
summary: Ticket database data/tarelog.db (SQLite, WAL) - readings, tickets, corrections, customers, daily totals, migrations, backup
code: [src/tarelog/tickets/, migrations/]
verified: 2026-09-01
related: [ADR-001, TS-SQLITE-LOCKED]
---
# DB-TICKETS: Ticket database

## Purpose
`data/tarelog.db` is TareLog's only database: one SQLite file in WAL mode on the weighbridge PC (ADR-001).
The reader service writes readings, the web UI writes tickets, corrections and the registers, and the report job writes the daily totals.
Every connection is opened by `src/tarelog/tickets/store.py` (`connect()`), which sets WAL mode, `synchronous=FULL` and the busy timeout from `db.busy_timeout_ms` (5000 ms).

## Entities
- `readings`: one stable weight per lane and stop, written by the reader service (SERVICE-GATEWAY); never changed.
- `tickets`: the legal-for-trade record of one weighing: ticket number, truck, customer, product, gross, tare and net in kilograms, the readings it was made from and the clerk who confirmed it.
- A correction is a new row in `tickets` whose `corrects_ticket_id` points to the ticket it corrects; the valid values of a weighing are those of the last ticket in that chain.
- `trucks`, `customers` and `products`: the registers the office maintains; a truck belongs to one customer and may carry a stored tare.
- `daily_totals`: net kilograms per customer, product and report day, recomputed by the report job every morning; derived data that can be deleted and rebuilt.
- `schema_migrations`: the numbers of the applied migrations.

## Invariants
- No `UPDATE` or `DELETE` ever runs on `readings` or `tickets`; triggers raise an error on both ([project/CONSTRAINTS.md](../../project/CONSTRAINTS.md), section Regulatory and legal).
- Ticket numbers are continuous and never reused; a failed insert burns no number.
- Weights are integer kilograms; timestamps are UTC in ISO 8601 text.

## Migrations
- Numbered plain SQL files, for example `migrations/0009_daily_totals.sql`, applied in order at release by `python -m tarelog.tickets.migrate`.
- Migrations only add tables, columns, indexes and triggers; they never rewrite ticket rows.
- There are no down migrations: a failed release is rolled back by restoring the copy taken before it and reinstalling the previous version.
- Before applying a migration on the weighbridge PC, copy the database with `sqlite3 data/tarelog.db ".backup /var/backups/tarelog/pre-migration.db"`.

## Gotchas
- A copy made with `cp data/tarelog.db` while the services run lacks recent tickets -> in WAL mode, committed data stays in `data/tarelog.db-wal` until a checkpoint -> copy with `.backup`, or stop all three units first.
- `sqlite3.OperationalError: database is locked` -> another connection holds the write lock past the busy timeout -> TS-SQLITE-LOCKED.
