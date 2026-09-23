# Constraints: TareLog

Normative: code, tasks and ADRs MUST respect every rule below.
Only humans change this file; an agent adds a rule only when a human states it in the session, and cites that human as the source.
Entry format: `- <rule>. Source: <person or document>, YYYY-MM-DD.`
Delete sections without entries; if none remain, write `None recorded as of YYYY-MM-DD.`

## Regulatory and legal
- Weighing tickets are legal-for-trade records: a stored ticket is never updated or deleted, and a correction is a new ticket that references the original. Source: marta, citing the legal metrology rules for weighing instruments used in trade, 2026-09-01.

## Customer and contract
- The daily delivery report for the previous day reaches Beta Haulage by 06:00 local time. Source: Beta Haulage delivery contract, 2026-09-01.

## Security and data
- Credentials (SFTP keys, SMTP passwords, tokens) are never stored in the repository, tests and examples included; code reads them at runtime from the host's vault. Source: marta, 2026-09-01.
