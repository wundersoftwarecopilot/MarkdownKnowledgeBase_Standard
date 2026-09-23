# Clean fixture builder for the mkb-check test suite (sourced by run-tests.sh). Not a deliverable.
# mk PATH <<EOF writes $D/PATH.
mk() { mkdir -p "$(dirname "$D/$1")"; cat > "$D/$1"; }

clean() {
D=$1; rm -rf "$D"; mkdir -p "$D"
mk docs/mkb/INDEX.md <<'EOF'
---
type: index
mkb_version: "1.0"
profile: full
---
# MKB Index: Demo

This folder is the project memory.

## Start here
1. [state/CURRENT.md](state/CURRENT.md): read it every session.
2. Your task `tasks/TASK-NNN.md` and its handoff `handoff/TASK-NNN.md`.
EOF
mk docs/mkb/agents/RULES.md <<'EOF'
---
type: rules
mkb_version: "1.0"
---
# MKB rules

## 9. Knowledge docs and STALE banners

Mark known-wrong text with this banner:

```markdown
> STALE YYYY-MM-DD <handle>: <what is wrong>. Tracking TASK-NNN.
```

## 16. Project-specific rules
None.
EOF
mk docs/mkb/project/OVERVIEW.md <<'EOF'
# Overview: Demo

## Purpose
Demo system that reads scale weights.
EOF
mk docs/mkb/project/CONSTRAINTS.md <<'EOF'
# Constraints: Demo

## Security and data
- Credentials never in the repository. Source: alice, 2026-09-01.
EOF
mk docs/mkb/project/ARCHITECTURE.md <<'EOF'
---
type: architecture
verified: 2026-09-10
---
# Architecture: Demo

## Components
| Component | Responsibility | Code | Doc |
|---|---|---|---|
| core | parsing | `src/core/` | MODULE-CORE |
| api | HTTP API | `src/api/` | SERVICE-API |
EOF
mk docs/mkb/project/CONVENTIONS.md <<'EOF'
# Conventions: Demo

## Code
- Use snake_case.
EOF
mk docs/mkb/state/CURRENT.md <<'EOF'
# Current state: Demo

The condition of the default branch and its deployments, one dated bullet per fact: `- YYYY-MM-DD <handle>: <fact> (<IDs>)`.

## Health
- 2026-09-20 alice: Production runs v1.2.0 (TASK-002).

## Focus
- 2026-09-15 alice: Ship the parser (TASK-005).

## Warnings
- 2026-09-22 claude-code: Do not touch the lane 2 config until TASK-005 lands.
EOF
mk docs/mkb/state/NEXT.md <<'EOF'
# Next: Demo

The ordered pickup queue, highest first.
Entry format: `- <ID>: <why now, at most 10 words>`. At most 10 entries.

- TASK-003: needed for the release
- TASK-004: after Q-001 is answered
EOF
mk docs/mkb/decisions/ADR-001.md <<'EOF'
---
id: ADR-001
type: adr
status: accepted
date: 2026-09-02
deciders: [alice]
related: [MODULE-CORE, TASK-002]
---
# ADR-001: Parse frames in the core module

## Context
Frames arrive in chunks.

## Decision
Buffer until ETX.
EOF
mk docs/mkb/decisions/ADR-002.md <<'EOF'
---
id: ADR-002
type: adr
status: superseded
date: 2026-09-03
deciders: [alice]
superseded_by: ADR-003
related: [SERVICE-API]
---
# ADR-002: Render reports as PDF

## Decision
PDF.
EOF
mk docs/mkb/decisions/ADR-003.md <<'EOF'
---
id: ADR-003
type: adr
status: accepted
date: 2026-09-10
deciders: [alice, bob]
supersedes: [ADR-002]
related: [SERVICE-API, INT-DEVICE]
---
# ADR-003: Deliver reports as CSV

## Decision
CSV.
EOF
mk docs/mkb/decisions/ADR-004.md <<'EOF'
---
id: ADR-004
type: adr
status: proposed
date: 2026-09-21
related: [DB-MAIN]
---

# ADR-004: Use WAL mode

## Decision
WAL.
EOF
mk docs/mkb/tasks/archive/TASK-001.md <<'EOF'
---
id: TASK-001
type: task
status: done
priority: normal
owner: alice
created: 2026-06-01
closed: 2026-07-01
---
# TASK-001: Set up the repository

## Goal
Create the repository.

## Acceptance criteria
- [x] Repository exists

## Notes

## Completion
- 2026-07-01 alice: done in PR #1
EOF
mk docs/mkb/tasks/TASK-002.md <<'EOF'
---
id: TASK-002
type: task
status: done
priority: high
owner: alice
branch: alice/task-002-release
created: 2026-09-01
closed: 2026-09-10
related: [ADR-001]
---
# TASK-002: Release v1.2.0

## Goal
Release.

## Acceptance criteria
- [x] Released

## Notes

## Completion
- 2026-09-10 alice: done in PR #2
EOF
mk docs/mkb/tasks/TASK-003.md <<'EOF'
---
id: TASK-003
type: task
status: todo
priority: high
owner: none
created: 2026-09-05
code: [src/core/]
---
# TASK-003: Add checksum validation

## Goal
Validate checksums.

## Acceptance criteria
- [ ] Bad frames are rejected

## Notes

## Completion
EOF
mk docs/mkb/tasks/TASK-004.md <<'EOF'
---
id: TASK-004
type: task
status: blocked
priority: normal
owner: none
created: 2026-09-10
blocked_by: [Q-001, TASK-003]
related: [Q-001]
---
# TASK-004: Deliver reports by SFTP

## Goal
Deliver.

## Acceptance criteria
- [ ] Delivered

## Notes
- 2026-09-15 claude-code: blocked on Q-001.

## Completion
EOF
mk docs/mkb/tasks/TASK-005.md <<'EOF'
---
id: TASK-005
type: task
status: in-progress
priority: critical
owner: claude-code
branch: claude-code/task-005-parser
created: 2026-09-12
code: [src/core/parser.py]
---
# TASK-005: Parse frames with a real parser

## Goal
Parser.

## Acceptance criteria
- [ ] Lane 2 works

## Notes

## Completion
EOF
mk docs/mkb/tasks/TASK-007.md <<'EOF'
---
id: TASK-007
type: task
status: dropped
priority: normal
owner: bob
created: 2026-09-11
closed: 2026-09-18
formerly: TASK-006
---
# TASK-007: Render PDF

## Goal
PDF.

## Acceptance criteria
- [ ] PDF

## Notes

## Completion
- 2026-09-18 bob: dropped: CSV only, decided by alice
EOF
mk docs/mkb/tasks/TASK-008.md <<'EOF'
---
id: TASK-008
type: task
status: todo
priority: low
owner: none
created: 2026-07-01
---
# TASK-008: Dark mode for the web UI

## Goal
Dark mode.

## Acceptance criteria
- [ ] Dark

## Notes

## Completion
EOF
mk docs/mkb/questions/Q-001.md <<'EOF'
---
id: Q-001
type: question
status: open
owner: alice
asked_by: claude-code
created: 2026-09-15
related: [TASK-004]
---
# Q-001: Key or password authentication?

## Context
TASK-004 waits for it.

## Answer
EOF
mk docs/mkb/knowledge/modules/MODULE-CORE.md <<'EOF'
---
id: MODULE-CORE
type: module
summary: Frame parser and checksum validation for scale readings
code: [src/core/]
verified: 2026-09-10
related: [ADR-001]
---
# MODULE-CORE: Frame parser

## Purpose
Parses frames. Resolved questions such as Q-099 are deleted by design.

> STALE 2026-09-20 bob: the checksum section is outdated. Tracking TASK-003.

## How it works
~~~~markdown
Example of a banner inside an outer fence:
```markdown
> STALE 2000-01-01 x: y
<!-- guide: this is only an example -->
See TASK-999 and MODULE-NOPE.
```
> STALE 2000-01-01 x: still inside the outer fence
~~~~

```text
<!-- guide: fenced -->
> STALE 2000-01-01 x: y
ADR-999
```

## Gotchas
- `FrameError: missing ETX` -> frames split across reads -> buffer them (see SERVICE-API).
EOF
mk docs/mkb/knowledge/services/SERVICE-API.md <<'EOF'
---
id: SERVICE-API
type: service
summary: HTTP API service that exposes tickets and reports
code: [src/api/, src/core/parser.py]
verified: 2026-09-10
---
# SERVICE-API: HTTP API

## Purpose
Serves tickets.
EOF
mk docs/mkb/knowledge/database/DB-MAIN.md <<'EOF'
---
id: DB-MAIN
type: database
summary: SQLite ticket store in WAL mode
code: [migrations/]
verified: 2026-09-10
related: [ADR-004]
---
# DB-MAIN: Ticket store

## Purpose
Tickets.
EOF
mk docs/mkb/knowledge/integrations/INT-DEVICE.md <<'EOF'
---
id: INT-DEVICE
type: integration
summary: Weighing indicator frame protocol over TCP
verified: 2026-09-10
---
# INT-DEVICE: Weighing indicator

## Contract
Frames end with ETX.
EOF
mk docs/mkb/knowledge/troubleshooting/TS-DB-LOCKED.md <<'EOF'
---
id: TS-DB-LOCKED
type: troubleshooting
summary: database is locked errors during report generation
verified: 2026-09-10
related: [DB-MAIN]
---
# TS-DB-LOCKED: database is locked

## Symptom

```text
sqlite3.OperationalError: database is locked
```
EOF
mk docs/mkb/handoff/TASK-005.md <<'EOF'
# Handoff: TASK-005

Written 2026-09-22 by claude-code on branch `claude-code/task-005-parser`.

## Where it stands
- Parser half done; see TASK-999 (not checked in handoffs).
<!-- guide: not checked in handoffs -->
> STALE 2000-01-01 x: not checked in handoffs

## Next steps
1. Finish the parser.

## Read first
- MODULE-CORE
EOF
mk docs/mkb/templates/TASK.md <<'EOF'
---
id: TASK-NNN
type: task
status: todo
priority: normal
owner: none
created: YYYY-MM-DD
related: [<ID>]
code: [<path>/]
---
# TASK-NNN: <imperative title>

## Goal
<!-- guide: 1-3 sentences: what and why. -->
EOF
mk docs/mkb/templates/HANDOFF.md <<'EOF'
# Handoff: TASK-NNN

Written YYYY-MM-DD by <handle> on branch `<branch>`.
EOF
mk src/core/parser.py <<'EOF'
def parse(frame): return frame
EOF
mk src/api/app.py <<'EOF'
app = None
EOF
mk migrations/001_init.sql <<'EOF'
create table t (id integer);
EOF
}
