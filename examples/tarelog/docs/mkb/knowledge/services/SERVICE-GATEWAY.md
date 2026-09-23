---
id: SERVICE-GATEWAY
type: service
summary: Reader service tarelog-reader - reads both lanes' WI-200 indicators over TCP and stores stable readings in SQLite
code: [src/tarelog/gateway/]
verified: 2026-09-22
related: [INT-WI200, DB-TICKETS, TS-SQLITE-LOCKED, TASK-006]
---
# SERVICE-GATEWAY: Weighbridge reader service

## Purpose
`tarelog-reader` keeps one TCP connection to each lane's WI-200 indicator (INT-WI200), turns stable weights into readings and writes them to table `readings` (DB-TICKETS).
The connection loop and the stability rule live in `src/tarelog/gateway/reader.py`; frames are cut and validated by `src/tarelog/gateway/wi200.py` (`parse_frame()`), whose format is described in INT-WI200.
It also serves the live weight of each lane to the web UI over the Unix socket `/run/tarelog/live.sock`.
It never creates tickets: a clerk turns readings into tickets in the web UI.

## Run and deploy
- Locally: `python -m tarelog.gateway --config dev.toml`, against the simulator of INT-WI200, section Test environment.
- Production: systemd unit `tarelog-reader.service` on the weighbridge PC, installed with every release ([project/ARCHITECTURE.md](../../project/ARCHITECTURE.md), section Deployment).
- A restart loses nothing stored; a truck standing on the platform during the restart is read again once its weight is stable.

## Configuration
Keys in `/etc/tarelog/tarelog.toml`:
- `gateway.lane`: one table per lane with `id`, `host` and `port`.
- `gateway.stable_frames`: identical consecutive `ST` frames needed before a reading is taken; 3 in production.
- `gateway.min_weight_kg`: below this weight the platform counts as empty and no reading is taken; 200 in production.
- `db.path` and `db.busy_timeout_ms`: shared with the other services (DB-TICKETS).

## Dependencies
- The two converters and indicators (INT-WI200).
- The ticket database, table `readings`, through `src/tarelog/tickets/store.py` (DB-TICKETS).

## Operations
- Logs: `journalctl -u tarelog-reader`; one line per reading, plus every `FrameError` and every reconnect.
- Health: the web UI status page shows the age of the last frame per lane; more than 10 seconds means the connection to that lane is down.
- Reconnect: after a closed or refused connection the reader retries with a backoff from 1 to 30 seconds, forever; no restart is needed.
- Restart: `sudo systemctl restart tarelog-reader`; safe at any time except while a clerk is confirming a weighing.

## Gotchas
- Readings missing around 05:00 while the log shows `sqlite3.OperationalError: database is locked` -> the report job holds the write lock longer than the 5-second busy timeout, and the reader drops the reading instead of retrying -> buffering is TASK-006; find other lock holders with TS-SQLITE-LOCKED.
