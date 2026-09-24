# 3. Metadata

*MKB Standard v1.0 · 2026-09-23 · Normative*

This chapter defines the YAML front matter of MKB files: where it is used, its syntax, every field, the controlled vocabularies and the schema of each document type.
`mkb-check.sh` reports every violation as error E3 ([09-lifecycle.md](09-lifecycle.md) §9.7).

## 3.1 Where front matter is used

Front matter is REQUIRED on: `INDEX.md`, `agents/RULES.md`, `project/ARCHITECTURE.md`, every task, ADR, question and knowledge doc, and the templates except `templates/HANDOFF.md` and `templates/CONVENTIONS.md`.
ADRs in a directory adopted in place ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.4) keep their native format and carry no MKB front matter.
Front matter MUST NOT appear on: `project/OVERVIEW.md`, `project/CONSTRAINTS.md`, `project/CONVENTIONS.md`, `state/CURRENT.md`, `state/NEXT.md`, handoff files.

## 3.2 The MKB YAML subset

1. The file starts with a line `---`; front matter ends at the next line `---`; the H1 is on the line right after it (canonical form, used by every skeleton).
   A blank line between the closing `---` and the H1 is tolerated; anything else there is an error (E3).
2. One `key: value` per line.
   No nested maps, no multi-line values, no YAML comments.
3. Keys are lowercase snake_case.
   Write them in the template order of §3.5 and never reorder existing keys; order is not checked.
4. A value is either a scalar or a one-line flow list `[a, b, c]`.
5. Dates are unquoted `YYYY-MM-DD`.
   No times.
6. `mkb_version` is always quoted: `mkb_version: "1.0"`.
7. Handles are written without `@` (YAML reserves `@`).
   Prose may use `@marta`; front matter never does.
8. Optional keys with no value are omitted entirely.
   Never write `key:` with an empty value and never write `key: []`.
9. A scalar MUST NOT contain `: ` or ` #`, nor end with `:`; rephrase with a dash instead.
   It MUST NOT start with `[`, `]`, `{`, `}`, `>`, `|`, `*`, `&`, `!`, `%`, `@`, `#`, `,`, `"`, `'` or a backtick, nor with `-` or `?` followed by a space or the end of the value (except list values, which are flow lists, and `mkb_version`, which rule 6 quotes).
10. At most 12 keys, so that the first 16 lines of a file show the front matter and the H1 (12 keys, 2 delimiters, the H1, and room for the tolerated blank line).

## 3.3 Field dictionary

| Key | Value | Used by |
|---|---|---|
| `id` | the record ID; MUST equal the file name without `.md` | task, adr, question, knowledge |
| `type` | vocabulary §3.4.1 | every file with front matter |
| `status` | vocabulary §3.4.2 for the type | task, adr, question |
| `priority` | `critical`, `high`, `normal`, `low` | task |
| `owner` | handle or `none` (task); human handle (question) | task, question |
| `branch` | exact git branch name, or `pending` when a dispatched cloud agent has not created its branch yet | task |
| `created` | date the record was created | task, question |
| `closed` | date the task was set to `done` or `dropped` | task |
| `blocked_by` | flow list of TASK- and Q- IDs, non-empty | task |
| `date` | date of the decision (acceptance or rejection); while `proposed`, the date proposed | adr |
| `deciders` | flow list of human handles, non-empty | adr |
| `supersedes` | flow list of ADR IDs | adr |
| `superseded_by` | one ADR ID | adr |
| `asked_by` | handle of the asker | question |
| `summary` | one line, at most 120 characters, containing the words people will grep for | knowledge |
| `code` | flow list of repo-root-relative paths, no leading `/` or `./`, no globs, directories end with `/` | knowledge (required for module, service, database; optional for integration, troubleshooting); task (optional; SHOULD be set at claim, [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4) |
| `verified` | date someone last checked the doc against the code on the default branch: the whole doc when it is created and at the 180-day re-check (W16, [09-lifecycle.md](09-lifecycle.md) §9.4); the parts a change affects when that change touches one of its `code` paths (T11, [05-agent-workflow.md](05-agent-workflow.md) §5.6) | knowledge, architecture |
| `related` | flow list of IDs (MKB IDs or external tracker keys such as `GH-123`) | task, adr, question, knowledge |
| `formerly` | the previous ID of this record after a renumber or rename | task, adr, question, knowledge |
| `mkb_version` | `"1.0"` | index, rules |
| `profile` | `minimal` or `full` | index |

ID patterns: [04-naming-and-linking.md](04-naming-and-linking.md) §4.1.

## 3.4 Vocabularies

### 3.4.1 `type`

| Value | File |
|---|---|
| `index` | `INDEX.md` |
| `rules` | `agents/RULES.md` |
| `architecture` | `project/ARCHITECTURE.md` |
| `task` | `tasks/TASK-NNN.md`, `tasks/archive/TASK-NNN.md` |
| `adr` | `decisions/ADR-NNN.md` |
| `question` | `questions/Q-NNN.md` |
| `module` | `knowledge/modules/MODULE-<NAME>.md` |
| `service` | `knowledge/services/SERVICE-<NAME>.md` |
| `database` | `knowledge/database/DB-<NAME>.md` |
| `integration` | `knowledge/integrations/INT-<NAME>.md` |
| `troubleshooting` | `knowledge/troubleshooting/TS-<NAME>.md` |

### 3.4.2 `status` per type

| Type | Values | Meaning |
|---|---|---|
| task | `todo` | not started; claimable if `owner` is `none` or your handle |
| task | `in-progress` | claimed; has `owner` and `branch` |
| task | `blocked` | cannot proceed until every item in `blocked_by` is resolved; may be owned or unowned |
| task | `done` | delivered; `closed` and `## Completion` filled; set inside the delivering PR |
| task | `dropped` | will not be done; `closed` and a reason in `## Completion`; needs a human decision |
| adr | `proposed` | draft; exists only on branches |
| adr | `accepted` | binding; body frozen |
| adr | `rejected` | considered and declined; kept as a record |
| adr | `superseded` | replaced by the ADR in `superseded_by` |
| adr | `deprecated` | no longer applies and has no replacement (for example, the component was removed) |
| question | `open` | waiting for its owner's answer |
| question | `answered` | `## Answer` filled; waiting for promotion and deletion |

Knowledge docs, ARCHITECTURE, INDEX and RULES have no `status`.
Known-wrong knowledge is marked with a `> STALE` banner ([09-lifecycle.md](09-lifecycle.md) §9.5), not a status.
Who may change a status, and when: [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.3 (tasks), [07-decisions.md](07-decisions.md) §7.4 (ADRs), [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.11 (questions).

### 3.4.3 `priority` (tasks only)

| Value | Meaning |
|---|---|
| `critical` | Drop other work: the default branch is broken, production is down, or there is a legal, safety or data-loss risk. |
| `high` | Needed for the current Focus in `state/CURRENT.md`, or blocks other tasks. |
| `normal` | Default. |
| `low` | Nice to have; gardening may propose dropping it after 90 days. |

### 3.4.4 Handles and `owner`

- A handle matches `^[a-z][a-z0-9-]{0,31}$` and is not `none`.
- Reserved agent handles: `claude-code`, `codex`, `cursor`, `gemini-cli`, `aider`, `copilot`, `windsurf`, `agent` (any other agent tool).
- Human handles: the person's lowercase forge or git handle; MUST NOT equal a reserved agent handle.
- Every handle used in a project SHOULD appear in INDEX `## People and agents`.
- `owner: none` means unassigned.
- Parallel sessions of the same tool share its handle; the `branch` field tells them apart ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4 step 7 defines when an owned task is yours).
  Never invent handles like `claude-2`.
- `deciders` MUST contain only human handles.
- A question's `owner` MUST be a human handle.

## 3.5 Schemas per document type

Keys are listed in template order.
R = required, C = conditional (rule in the last column), O = optional.
Each schema is followed by a TareLog record as it stands at the end of the worked example ([examples/tarelog/WALKTHROUGH.md](../examples/tarelog/WALKTHROUGH.md)).

### 3.5.1 index, rules and architecture

| Type | Key | Req | Rule |
|---|---|---|---|
| index | `type` | R | `index` |
| index | `mkb_version` | R | `"1.0"` |
| index | `profile` | R | `minimal` or `full` |
| rules | `type` | R | `rules` |
| rules | `mkb_version` | R | `"1.0"` |
| architecture | `type` | R | `architecture` |
| architecture | `verified` | R | date |

Example (TareLog `INDEX.md`):
```markdown
---
type: index
mkb_version: "1.0"
profile: full
---
# MKB Index: TareLog
```

Example (`agents/RULES.md`, identical in every project):
```markdown
---
type: rules
mkb_version: "1.0"
---
# MKB rules
```

Example (TareLog `project/ARCHITECTURE.md`):
```markdown
---
type: architecture
verified: 2026-09-17
---
# Architecture: TareLog
```

### 3.5.2 task

| Key | Req | Rule |
|---|---|---|
| `id` | R | `TASK-NNN` |
| `type` | R | `task` |
| `status` | R | task vocabulary |
| `priority` | R | priority vocabulary |
| `owner` | R | handle or `none`; MUST NOT be `none` when `in-progress` or `done` |
| `branch` | C | required when `in-progress`; forbidden when `todo` (removed on release); optional when `blocked`, `done` or `dropped` (kept for history) |
| `created` | R | date |
| `closed` | C | required when `done` or `dropped`; forbidden otherwise |
| `blocked_by` | C | required when `blocked`; forbidden otherwise |
| `related` | O | IDs |
| `code` | O | paths |
| `formerly` | O | previous ID |

Example (TareLog):
```markdown
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
```

Note: TareLog's TASK-005 is `blocked` with `owner: none`, no `branch`, and `blocked_by: [Q-002]` after `created`.

### 3.5.3 adr

| Key | Req | Rule |
|---|---|---|
| `id` | R | `ADR-NNN` |
| `type` | R | `adr` |
| `status` | R | adr vocabulary |
| `date` | R | date |
| `deciders` | C | required for every status except `proposed` |
| `supersedes` | O | ADR IDs |
| `superseded_by` | C | required when `superseded`; forbidden otherwise |
| `related` | O | IDs (components and tasks) |
| `formerly` | O | previous ID |

Example (TareLog):
```markdown
---
id: ADR-003
type: adr
status: accepted
date: 2026-09-10
deciders: [marta]
supersedes: [ADR-002]
related: [TASK-004, TASK-007, MODULE-REPORTS, INT-HAULER-SFTP]
---
# ADR-003: Deliver daily reports as CSV instead of PDF
```

### 3.5.4 question

| Key | Req | Rule |
|---|---|---|
| `id` | R | `Q-NNN` |
| `type` | R | `question` |
| `status` | R | `open` or `answered` |
| `owner` | R | human handle who must answer |
| `asked_by` | R | handle |
| `created` | R | date |
| `related` | O | IDs |
| `formerly` | O | previous ID |

There is deliberately no `blocks` key: the blocked task's `blocked_by` is the single source.

Example (TareLog):
```markdown
---
id: Q-002
type: question
status: open
owner: marta
asked_by: claude-code
created: 2026-09-17
related: [TASK-005, MODULE-REPORTS]
---
# Q-002: Should a report day end at quarry-local midnight or at midnight in each customer's time zone?
```

### 3.5.5 module, service, database, integration

| Key | Req | Rule |
|---|---|---|
| `id` | R | knowledge ID with the prefix matching the type |
| `type` | R | `module`, `service`, `database` or `integration` |
| `summary` | R | ≤ 120 characters |
| `code` | C | required (at least one path) for `module`, `service` and `database`; optional for `integration` (omit it while no code talks to the system yet) |
| `verified` | R | date |
| `related` | O | IDs |
| `formerly` | O | previous ID |

Example (TareLog module):
```markdown
---
id: MODULE-REPORTS
type: module
summary: Daily delivery report per customer - daily totals, CSV report files, report day boundary, 05:00 report timer
code: [src/tarelog/reports/]
verified: 2026-09-17
related: [ADR-003, DB-TICKETS, INT-HAULER-SFTP, TASK-005]
---
# MODULE-REPORTS: Daily delivery reports
```

Example (TareLog service):
```markdown
---
id: SERVICE-GATEWAY
type: service
summary: Reader service tarelog-reader - reads both lanes' WI-200 indicators over TCP and stores stable readings in SQLite
code: [src/tarelog/gateway/]
verified: 2026-09-22
related: [INT-WI200, DB-TICKETS, TS-SQLITE-LOCKED, TASK-006]
---
# SERVICE-GATEWAY: Weighbridge reader service
```

Example (TareLog database):
```markdown
---
id: DB-TICKETS
type: database
summary: SQLite ticket database data/tarelog.db in WAL mode - readings, tickets, corrections, daily totals, migrations, backup
code: [src/tarelog/tickets/, migrations/]
verified: 2026-09-01
related: [ADR-001, TS-SQLITE-LOCKED]
---
# DB-TICKETS: Ticket database
```

Example (TareLog integration):
```markdown
---
id: INT-HAULER-SFTP
type: integration
summary: Beta Haulage SFTP server - daily CSV report upload, SSH key authentication, /inbound/tarelog/, 06:00 deadline, retries
code: [src/tarelog/delivery/sftp.py]
verified: 2026-09-16
related: [ADR-003, MODULE-REPORTS, TASK-004]
---
# INT-HAULER-SFTP: Beta Haulage SFTP delivery
```

Note: from its creation on 2026-09-10 until 2026-09-15 INT-HAULER-SFTP had no `code` key, because no code talked to the server yet.

### 3.5.6 troubleshooting

Same as §3.5.5 with `type: troubleshooting`; `code` is optional (omit it for environment or toolchain problems).
W2 and W3 ([09-lifecycle.md](09-lifecycle.md) §9.4) do not apply to a doc without `code`.

Example (TareLog):
```markdown
---
id: TS-SQLITE-LOCKED
type: troubleshooting
summary: sqlite3.OperationalError database is locked - a second writer holds the SQLite write lock past the busy timeout
code: [src/tarelog/tickets/store.py]
verified: 2026-09-01
related: [ADR-001, DB-TICKETS, SERVICE-GATEWAY]
---
# TS-SQLITE-LOCKED: Database is locked
```

## 3.6 Fields deliberately not used

| Field | Why not |
|---|---|
| `updated` | Git records edit dates; a bumped line conflicts on every concurrent edit. |
| `title` | The H1 is the title. |
| `tags` | `summary`, IDs and grep do the job. |
| `created` on knowledge and ADRs | Git records it; ADRs have `date`. |
| `owner` on knowledge docs | `git log` and `git blame` show authors. |
| `assignee`, `reviewer`, `estimate`, `due` | The PR and the team's planning carry these; the MKB is not a project-management tool. |
| `blocks` on questions | Duplicates the task's `blocked_by`. |
| `status` on knowledge | Replaced by the `> STALE` banner. |
