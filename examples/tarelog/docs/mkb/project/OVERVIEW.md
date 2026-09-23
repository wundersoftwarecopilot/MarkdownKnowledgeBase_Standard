# Overview: TareLog

## Purpose
TareLog records every truck weighed on the two-lane weighbridge of the Northfield Aggregates gravel quarry and turns each weighing into a legal-for-trade ticket.
Every morning it builds a delivery report per haulage customer and delivers it before 06:00.
Installation and development setup are in `README.md` (Installation, Development); this file does not repeat them.

## Users and scope
- Weighbridge clerks: weigh trucks, print tickets and enter corrections in the web UI.
- The quarry office (marta): customers, trucks, products, the day view and its totals.
- Haulage customers, the largest being Beta Haulage: receive the daily delivery report; they have no login.
- In scope: reading the weighing indicators, tickets and corrections, daily reports, report delivery.
- Out of scope: invoicing (the quarry's accounting system imports the daily totals), gate barriers and plate cameras, access from outside the office network.

## Stack
- Python 3.12; an asyncio TCP client reads the indicators.
- FastAPI with Jinja2 templates for the web UI.
- SQLite in WAL mode, one file `data/tarelog.db` (ADR-001).
- paramiko for SFTP delivery; the standard library `smtplib` for report and alert e-mail.
- pytest for tests, ruff for linting and formatting.
- Production: one Debian-based Linux mini-PC in the weighbridge office, services run by systemd.

## Commands
Setup is in `README.md` (Development); these are the commands sessions use:
- `pytest`: the fast suite; needs no indicator and no network.
- `pytest -m sim`: reader tests against the WI-200 simulator (INT-WI200, section Test environment).
- `ruff check . && ruff format --check .`: lint and format check, as CI runs them.
- `python -m tarelog.gateway --config dev.toml`: the reader service against the simulator.
- `uvicorn tarelog.web.app:app --reload`: the web UI on port 8000.
- `python -m tarelog.reports --day 2026-09-21 --no-deliver`: rebuild one day's reports without sending them.
- `sh docs/mkb/tools/mkb-check.sh`: MKB consistency check.

## Glossary
- **Weighbridge**: the platform scale trucks drive onto; TareLog's has two lanes with one indicator each.
- **Indicator**: the WI-200 device that shows the platform weight and sends it as frames (INT-WI200).
- **Reading**: one stable weight taken by the reader service; raw material for a ticket, not a ticket.
- **Ticket**: the legal-for-trade record of one weighing with gross, tare and net weight; never edited.
- **Correction**: a new ticket that corrects an earlier one and references it.
- **Gross, tare, net**: loaded weight, empty weight of the truck, and their difference.
- **Report day**: the 24 hours one daily report covers (MODULE-REPORTS).
