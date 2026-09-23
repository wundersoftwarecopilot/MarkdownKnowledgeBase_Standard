---
id: INT-HAULER-SFTP
type: integration
summary: Beta Haulage SFTP server - daily CSV report upload, SSH key authentication, /inbound/tarelog/, 06:00 deadline, retries
code: [src/tarelog/delivery/sftp.py]
verified: 2026-09-16
related: [ADR-003, MODULE-REPORTS, TASK-004]
---
# INT-HAULER-SFTP: Beta Haulage SFTP delivery

## Purpose
Beta Haulage, the largest haulage customer, imports TareLog's daily delivery report into its ERP from its own SFTP server.
Their IT service desk runs the server; on the quarry side marta owns the relationship and agrees any change to the file with them.
Their file specification: [Beta Haulage delivery file specification v2](https://example.com/beta-haulage/delivery-file-spec-v2.pdf).
Upload code: `src/tarelog/delivery/sftp.py` (`upload_report()`), called by the report job (MODULE-REPORTS).

## Contract
- Host `sftp.beta-haulage.example.com`, port 22; the account name is the configuration key `delivery.sftp.user` in `/etc/tarelog/tarelog.toml`.
- One file per report day in `/inbound/tarelog/`, named after the report day, for example `northfield-2026-09-21.csv`.
- The file is uploaded with `.part` appended to its name and renamed when complete; their importer polls every 10 minutes for `*.csv` and moves imported files to `/inbound/tarelog/done/`.
- The file must be complete by 06:00 local time ([project/CONSTRAINTS.md](../../project/CONSTRAINTS.md), section Customer and contract).
- CSV as decided in ADR-003: UTF-8 without BOM, comma-separated, LF line endings, one header row.
- Columns in this order, which their ERP import depends on: `ticket_no,weighed_at,truck_id,product,gross_kg,tare_kg,net_kg,corrects_ticket_no`.
- `weighed_at` is ISO 8601 quarry-local time with its UTC offset; weights are integer kilograms; `corrects_ticket_no` is empty except on correction rows.
- A correction arrives as a new row in the file of the day it was made; rows already delivered are never re-sent changed.

## Authentication
- SSH key authentication only; the partner has disabled password login (resolves Q-001).
- The private key lives in the host's vault at `tarelog/sftp-key`; `sftp.py` reads it at runtime and never writes it to disk or to the repository.
- The server's host key is pinned in `/etc/tarelog/known_hosts`; an unknown host key aborts the upload.

## Limits and failure modes
- The server may be unreachable during its maintenance window, Sundays 01:00 to 03:00 local time; the 05:00 report run is outside it.
- A failed upload is retried 3 times, 5 minutes apart; after the third failure `sftp.py` sends an alert e-mail to the address in `delivery.alert_to`, leaving time to upload by hand before 06:00.
- A manual upload uses the same `.part` and rename steps; a file dropped straight under its final name can be imported half-written.

## Test environment
- A test account on the same host writes to `/inbound/test/`, which their importer never reads; its key lives in the vault at `tarelog/sftp-key-test`.
- `tests/delivery/` runs against a local SFTP server fixture and needs no network.

## Gotchas
- `OSError: Failure` when renaming the `.part` file -> SFTP rename does not overwrite, and that day's file is already there after a manual upload -> check `/inbound/tarelog/done/` with marta before re-sending; `sftp.py --resend` deletes the old file first.
- `ChannelException: (1, 'Administratively prohibited')` on the second of two uploads started together -> the partner server allows one SFTP session per account and rejects parallel uploads -> upload files one after another over a single session, as `sftp.py` does.
