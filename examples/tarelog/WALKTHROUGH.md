# TareLog walkthrough

*MKB Standard v1.0 · 2026-09-23 · Example (informative)*

This walkthrough follows one fictional project through its first three weeks with the MKB, in eight sessions from adoption (S1) to the first gardening (S8).
Every file the story ends with is in this directory, starting at [docs/mkb/INDEX.md](docs/mkb/INDEX.md); intermediate states (handoffs, a question before its resolution, diffs, command output) lived only on branches or in git history, so they appear only here.
Company, vendor, device and customer names are fictional; commit hashes are illustrative; transcripts are sh, and the spec chapters give the PowerShell forms.

## The project and the cast

TareLog is the weighbridge ticketing service of the gravel quarry Northfield Aggregates: it reads weights from two Ponderix WI-200 weighing indicators through serial-to-Ethernet converters, stores legal-for-trade tickets in SQLite, and delivers a daily report to each haulage customer, the largest being Beta Haulage.
Stack: Python 3.12, FastAPI with Jinja2, SQLite in WAL mode, paramiko, pytest, on one Linux mini-PC in the weighbridge office; the code under `src/tarelog/` is referenced, not included.
Before adoption the repository held `README.md`, `CONTRIBUTING.md` and a 603-line `Handoff.md`; the default branch is `main`, code goes through PRs merged with merge commits, and coordination commits go straight to `main`.

| Handle | Kind | Role |
|---|---|---|
| marta | human | lead: orders state/NEXT.md, accepts or rejects ADRs, talks to the customers, merges PRs |
| luca | human | developer and operations, part-time; works by hand and runs Codex CLI on his laptop |
| claude-code | agent | Claude Code in local worktrees on marta's machine, one worktree per session |
| codex | agent | Codex cloud tasks dispatched by marta (cannot push to main); Codex CLI run by luca (can push) |

## Starting point: the old Handoff.md

Lines 1 to 32 of 603; the rest is session logs, pasted test output and notes that contradict each other.

```markdown
# TareLog handoff

READ THIS WHOLE FILE BEFORE YOU CHANGE ANYTHING. Newest notes first.

## Session 2026-08-28 (claude)
- Lane 2 again: the regex in gateway/reader.py misses about 1 reading in 5 on lane 2; lane 1 is fine.
- Maybe the lane 2 converter cuts frames into 64-byte chunks? Not confirmed. Marta weighs lane 2 by hand meanwhile.

## Current status (2026-08-20)
- Production: v0.7.2 on the weighbridge PC, installed 2026-08-12 by Luca. CI green.
- Marta builds the customer reports by hand every morning from the day view totals.

## Open (priority order per Marta)
1. Real parser for lane 2
2. Automated daily report per customer
3. SFTP upload for Beta Haulage (they asked twice)
4. Backups: nothing copies tarelog.db anywhere

## Database
- 2026-03-10 Marta decided: SQLite in WAL mode, synchronous FULL, replacing the per-lane CSV files (v0.4). PostgreSQL was too much to run on the mini-PC with nobody on site.
- store.py sets busy_timeout 5000. "database is locked" = usually the 05:00 report timer recomputing daily_totals (about 20 s), or someone left a sqlite3 shell open.
- Never cp the db while the services run: the newest tickets are still in the -wal file. Use sqlite3 .backup.

## Rules from Marta
- Tickets are legal-for-trade records: never UPDATE or DELETE one; a correction is a new ticket pointing to the old one.
- Beta Haulage contract: their report must be there by 06:00. No passwords or keys in git, ever.

## Reader service
- tarelog-reader.service; tarelog.toml has gateway.stable_frames = 3 and gateway.min_weight_kg = 200; converters on raw TCP port 4001.

## Session 2026-07-30 (codex)
- Renamed helpers in web/day_view.py; looked at ReportLab for the reports, not sure yet.
```

Every session was told to read all of it, its status lines were weeks old, and knowledge, decisions, rules, open work and diary shared one hot file that 61 commits had touched.

## S1 2026-09-01: adoption

marta and claude-code, on branch `claude-code/mkb-adopt`; PR #10, merged by marta the same day.
Goal: adopt the MKB in the full profile, since two humans and two agent tools will work in parallel, and migrate Handoff.md once.

### What they read

The repository has no AGENTS.md, CLAUDE.md, `.gitattributes`, ADR directory or documentation site, so only `README.md` and `CONTRIBUTING.md` are adopted in place.
Knowledge docs are written only for the most-changed components: `git log --format= --name-only | sort | uniq -c | sort -rn | head -n 3` puts `Handoff.md` (61 commits), `src/tarelog/gateway/reader.py` (27) and `src/tarelog/tickets/store.py` (19) on top.
Then marta and claude-code read Handoff.md once, whole, and sort every paragraph (Key excerpt).

### What they wrote

| File | Change |
|---|---|
| `docs/mkb/` | copied from `templates/full/docs/mkb` with the adoption commands; INDEX People: marta, luca, claude-code, codex; Path overrides: none |
| `project/*.md` | OVERVIEW; ARCHITECTURE drafted by claude-code from the code, reviewed by marta, `verified: 2026-09-01`; CONSTRAINTS with the three rules marta states in the session; CONVENTIONS with only what `CONTRIBUTING.md` lacks |
| `state/*.md` | one bullet each in Health (v0.7.2, reports by hand), Focus (TASK-003, TASK-004) and Warnings (lane 2, TASK-002); NEXT: TASK-002, TASK-003, TASK-004, TASK-001 |
| ADR-001, TASK-001 to TASK-004, SERVICE-GATEWAY, DB-TICKETS, TS-SQLITE-LOCKED | ADR-001 backfilled (`accepted`, `date: 2026-03-10`, `deciders: [marta]`); tasks `todo`, `owner: none`; knowledge `verified: 2026-09-01` |
| `Handoff.md`, `AGENTS.md`, `CLAUDE.md`, `.gitattributes` | the 3-line stub; three project notes plus the MKB block; `@AGENTS.md`; the four MKB lines |
| TASK-001 (main, luca, after the merge) | `TASK-001: claim`, committed in luca's clean `main` (no temporary worktree): `in-progress`, `branch: luca/task-001-nightly-backup`, `code: [src/tarelog/tickets/backup.py]`, a Notes line on the NAS mount |

The tasks ride PR #10 instead of coordination commits, because no other actor can allocate a TASK ID before the adoption merges; mkb-check reports 0 errors before the commit `mkb: adopt MKB v1.0 (full profile)`.

### Key excerpt

The triage mapping, kept in the PR #10 description and never in the MKB:

| Handoff.md content | Destination |
|---|---|
| "READ THIS WHOLE FILE" banner; session logs 2026-05-04 to 2026-08-28 (about 380 lines, including the 64-byte chunk guess and the ReportLab note); pasted test output | dropped; git keeps them |
| Current status: v0.7.2 in production, reports built by hand | state/CURRENT.md, Health bullet dated 2026-09-01 |
| Current status: "CI green" | dropped: Health holds exceptions and deployments only |
| 2026-08-28 log: Marta weighs lane 2 by hand | state/CURRENT.md, Warnings bullet (TASK-002) |
| Open, items 1 to 4, and their order | TASK-002, TASK-003, TASK-004, TASK-001; state/NEXT.md in that order, confirmed by marta |
| Database: SQLite in WAL mode since 2026-03-10, and why | ADR-001, backfilled |
| Database: busy timeout and the usual lock holders | TS-SQLITE-LOCKED |
| Database: `.backup` instead of `cp`; "Migrations" (lines 380-401) | DB-TICKETS |
| Reader service | SERVICE-GATEWAY |
| Rules from Marta (three rules) | project/CONSTRAINTS.md, one per section, each with source and date |
| "How to run" (lines 402-431) | project/OVERVIEW.md, Commands |
| "Code style" (lines 432-470) | dropped where `CONTRIBUTING.md` says the same; the rest to project/CONVENTIONS.md |
| "How it fits together" (lines 471-520) | project/ARCHITECTURE.md, redrafted from the code |

### Rule illustrated

- A monolithic Handoff.md is migrated once by triage and replaced by a stub for 30 days: [spec/13-adoption-and-integration.md](../../spec/13-adoption-and-integration.md) §13.3.
- A past decision found in the old file becomes an accepted ADR with a named decider: [spec/07-decisions.md](../../spec/07-decisions.md) §7.8.
- Health holds exceptions and deployed versions, never "CI green": [spec/08-tasks-and-questions.md](../../spec/08-tasks-and-questions.md) §8.12.
- At adoption, knowledge docs only for the most-changed components: [spec/09-lifecycle.md](../../spec/09-lifecycle.md) §9.3.

## S2 2026-09-02: a parser, a new task and an ID collision

claude-code, in its own worktree on branch `claude-code/task-002-wi200-parser`.
Goal: TASK-002, the first ID in state/NEXT.md whose task is `todo` with `owner: none`: replace the regex that drops lane 2 readings.

### What they read

`git show origin/main:docs/mkb/tasks/TASK-002.md | head -n 16` shows `status: todo` and `owner: none`; claude-code claims the task on main, then runs discovery:

```text
$ git grep "^code:" -- docs/mkb/knowledge docs/mkb/tasks
docs/mkb/knowledge/database/DB-TICKETS.md:code: [src/tarelog/tickets/, migrations/]
docs/mkb/knowledge/services/SERVICE-GATEWAY.md:code: [src/tarelog/gateway/]
docs/mkb/knowledge/troubleshooting/TS-SQLITE-LOCKED.md:code: [src/tarelog/tickets/store.py]
docs/mkb/tasks/TASK-001.md:code: [src/tarelog/tickets/backup.py]
docs/mkb/tasks/TASK-002.md:code: [src/tarelog/gateway/]
docs/mkb/tasks/TASK-003.md:code: [src/tarelog/reports/]
$ git grep -l -w SERVICE-GATEWAY -- docs/mkb/decisions
$ git grep -i "^summary:.*frame" -- docs/mkb/knowledge
$ git grep -l -F "database is locked" -- docs/mkb/knowledge      # 11:29, an error in a lane 2 log
docs/mkb/knowledge/database/DB-TICKETS.md
docs/mkb/knowledge/troubleshooting/TS-SQLITE-LOCKED.md
```

- `src/tarelog/gateway/` of SERVICE-GATEWAY is a prefix of `src/tarelog/gateway/wi200.py`, the reverse hop finds no ADR, and `git grep -l -w SERVICE-GATEWAY -- docs/mkb` adds ARCHITECTURE (DB-TICKETS and TS-SQLITE-LOCKED are dropped at `head -n 16`).
- TASK-001 and TASK-003 (dispatched by marta at 08:50) are in progress, but their `code` does not overlap; read in full: CONSTRAINTS, SERVICE-GATEWAY and the Reader service row of ARCHITECTURE.
- No summary mentions frames, and the frame format lives in a device outside the repository, so claude-code writes INT-WI200 as it learns it.
- The error search shows that TS-SQLITE-LOCKED already names the 05:00 totals step; new is that the reader drops the reading instead of retrying, which is outside TASK-002.

### What they wrote

| File | Change |
|---|---|
| TASK-002 (main) | `TASK-002: claim` from a temporary worktree: `in-progress`, `owner: claude-code`, `branch`, `code: [src/tarelog/gateway/]` |
| INT-WI200 (branch) | new: frame layout, `ST` stable vs `US` unstable (never stored), 64-byte converter chunks, `FrameError: missing ETX` |
| TASK-006 (main) | `TASK-006: add`: "Buffer readings while SQLite is locked", `high`, `todo`, `owner: none` |
| `src/tarelog/gateway/reader.py`, TASK-002 (branch) | `# TODO(TASK-006): buffer readings while the DB is locked.` above the failing insert, written only after the push; a TASK-002 Notes line pointing to TASK-006 |
| `handoff/TASK-002.md` (branch) | written at the end of the session, then committed and pushed with all work |

### Key excerpt

The allocation at 11:29 and the rejected push at 11:31, in the coordination worktree:

```text
$ git fetch origin && git worktree prune
$ d="$(mktemp -d)" && git worktree add --detach "$d" origin/main
HEAD is now at 8e41b07 TASK-002: claim
$ sh docs/mkb/tools/mkb-check.sh next TASK
TASK-005
$ cp docs/mkb/templates/TASK.md "$d/docs/mkb/tasks/TASK-005.md"    # then fill it in
$ git -C "$d" add -A && git -C "$d" commit -q -m "TASK-005: add"
$ git -C "$d" push origin HEAD:main
To git.example.com:northfield/tarelog.git
 ! [rejected]        HEAD -> main (fetch first)
error: failed to push some refs to 'git.example.com:northfield/tarelog.git'
$ git -C "$d" fetch origin && git -C "$d" rebase origin/main
Auto-merging docs/mkb/tasks/TASK-005.md
CONFLICT (add/add): Merge conflict in docs/mkb/tasks/TASK-005.md
error: could not apply 2c9f1e4... TASK-005: add
$ git -C "$d" rebase --abort
$ sh docs/mkb/tools/mkb-check.sh next TASK
TASK-006
$ git -C "$d" reset -q --hard origin/main    # write TASK-006.md, same title and body
$ git -C "$d" add -A && git -C "$d" commit -q -m "TASK-006: add" && git -C "$d" push origin HEAD:main
To git.example.com:northfield/tarelog.git
   5d0a3c8..f17b2e9  HEAD -> main
$ git worktree remove --force "$d"
```

Marta had pushed her own TASK-005 at 11:30 (S3); nothing referred to claude-code's TASK-005 yet, so nothing is renumbered and TASK-006 has no `formerly`.
`handoff/TASK-002.md` at the end of the session:

```markdown
# Handoff: TASK-002

Written 2026-09-02 by claude-code on branch `claude-code/task-002-wi200-parser`.

## Where it stands
- `src/tarelog/gateway/wi200.py` (`parse_frame()`) cuts frames from one byte buffer per lane; `reader.py` still uses the old regex.
- `pytest -m sim tests/gateway/`: 2 of 41 fail, both lane 2 frames split at a 64-byte chunk boundary.
- INT-WI200 is written on this branch; this file is pushed with all work.

## Next steps
1. In `parse_frame()` (wi200.py:88), after a `FrameError` keep the bytes from the next STX instead of clearing the buffer; rerun the sim tests.
2. Replace the regex in `reader.py` with `parse_frame()`; `US` and `OL` frames never reach `readings`.
3. Update SERVICE-GATEWAY (where parsing lives) and bump `verified` on it and on INT-WI200.

## Watch out
- The `TODO(TASK-006)` above the insert in `reader.py` is TASK-006; do not buffer readings in this task.

## Dead ends
- Reading one frame per `recv()` call: fails on lane 2, whose converter sends 64-byte chunks (INT-WI200).

## Read first
- TASK-002, INT-WI200, SERVICE-GATEWAY, `tests/fixtures/wi200/lane2-busy.bin` (the failing capture)
```

### Rule illustrated

- The claim is a coordination commit from a temporary worktree of `origin/main`, pushed before any code: [spec/08-tasks-and-questions.md](../../spec/08-tasks-and-questions.md) §8.4.
- Discovery is a prefix match on `code`, path, ID and error-text searches, a reverse hop to ADRs, triage by front matter, at most 5 docs: [spec/05-agent-workflow.md](../../spec/05-agent-workflow.md) §5.3.
- A new TASK file is pushed at allocation; a rejected push and an add/add conflict mean "take the next number": [spec/04-naming-and-linking.md](../../spec/04-naming-and-linking.md) §4.3.
- The handoff has fixed sections, at most 30 lines, and is written before the final push: [spec/06-handoff.md](../../spec/06-handoff.md) §6.3.

## S3 2026-09-02: a dispatched cloud agent

codex in Codex cloud, dispatched by marta at 08:50, in parallel with S2; the tool names its branch `codex/task-003-daily-report`; PR #11 opens at 11:20.
Goal: TASK-003, generate each customer's daily report, which marta still compiles by hand.

### What they read

Marta checks on `origin/main` that TASK-003 is `todo` with `owner: none`, and claims it for codex before dispatching.
codex reads INDEX, CURRENT and TASK-003; no knowledge doc owns `src/tarelog/reports/` and `git grep -i "^summary:.*report" -- docs/mkb/knowledge` prints nothing, so it reads CONSTRAINTS (06:00), DB-TICKETS and the Reports row of ARCHITECTURE, and writes the missing MODULE-REPORTS.

### What they wrote

| File | Change |
|---|---|
| TASK-003 (main, marta) | `TASK-003: claim for codex` (Key excerpt) |
| MODULE-REPORTS, ADR-002 (branch) | new; ADR-002 `proposed`, `date: 2026-09-02`: PDF with headless Chromium, alternatives ReportLab and HTML e-mail |
| ARCHITECTURE, OVERVIEW (branch) | new rows "PDF renderer" and "Delivery" (T13); headless Chromium in Stack (T15) |
| TASK-003 (branch) | `done`, `closed: 2026-09-02`, `branch: codex/task-003-daily-report` instead of `pending`, Completion |
| TASK-005 (main, marta, 11:30) | `TASK-005: add`: "Per-customer report time zone", `normal`, `todo`, `owner: none` |

### Key excerpt

Marta's claim for the dispatched agent, then the end of the PR #11 description:

```diff
@@ -4,4 +4,6 @@
-status: todo
+status: in-progress
 priority: high
-owner: none
+owner: codex
+branch: pending
 created: 2026-09-01
+code: [src/tarelog/reports/]
@@ -20,0 +23 @@
+- 2026-09-02 marta: dispatched to Codex cloud.
```

```text
MKB for humans:
ADR decisions needed: ADR-002
New task: Per-customer report time zone
```

codex noticed that customers in other time zones need a different report day; as a dispatched agent that cannot push to main, it allocates no ID.
At 11:30 marta creates TASK-005 from that line, with the Notes line `- 2026-09-02 marta: created from the New task line of PR #11 (codex, TASK-003).`

### Rule illustrated

- A dispatched agent that cannot push gets its claim from the human, with `branch: pending` until the tool names the branch: [spec/08-tasks-and-questions.md](../../spec/08-tasks-and-questions.md) §8.4.
- An agent writes an ADR only as `proposed`: [spec/07-decisions.md](../../spec/07-decisions.md) §7.4.
- Dispatched agents never allocate TASK or Q IDs; the human creates the record from the `New task:` line: [spec/04-naming-and-linking.md](../../spec/04-naming-and-linking.md) §4.3.
- What needs a human goes in the `MKB for humans:` lines: [spec/05-agent-workflow.md](../../spec/05-agent-workflow.md) §5.8.

## S4 2026-09-03: a decision and a resumed task

marta reviews PR #11; then claude-code, in a new session in the same worktree, resumes TASK-002 and delivers PR #12, which marta merges.
Goals: decide ADR-002 and merge PR #11; finish TASK-002.

### What they read

Marta reads PR #11, ADR-002 and the `MKB for humans:` lines; claude-code updates its branch and checks the task and the handoff:

```text
$ git fetch origin && git merge --ff-only origin/claude-code/task-002-wi200-parser && git rebase origin/main
Already up to date.
Successfully rebased and updated refs/heads/claude-code/task-002-wi200-parser.
$ git show origin/main:docs/mkb/tasks/TASK-002.md | grep -e "^owner:" -e "^branch:"
owner: claude-code
branch: claude-code/task-002-wi200-parser
$ git log --oneline -1 && git status --short && pytest -m sim tests/gateway/ -q
6e2b8f1 TASK-002: parser work in progress, handoff
2 failed, 39 passed in 3.12s
```

Its handle, its branch, and `git worktree list` shows that branch in no other worktree: the task is its own; the last commit, the clean tree and the 2 failures match "Where it stands", so the handoff can be trusted.

### What they wrote

| File | Change |
|---|---|
| ADR-002, TASK-003 (PR #11, marta) | `ADR-002: accept`: `accepted`, `date: 2026-09-03`, `deciders: [marta]`; TASK-003 Follow-ups and `related` name TASK-005; marta merges |
| `src/tarelog/gateway/`, SERVICE-GATEWAY, INT-WI200 (PR #12) | parser finished, all 41 captures pass; SERVICE-GATEWAY says where parsing lives and gains a Gotchas line pointing to TASK-006; both docs `verified: 2026-09-03` |
| TASK-002 (PR #12) | criteria ticked, `done`, `closed: 2026-09-03`, Completion with "Follow-ups: TASK-006" |
| `handoff/TASK-002.md`, CURRENT (PR #12) | handoff deleted (T3): `git grep -l -F "recv()" -- docs/mkb/knowledge` shows its Dead ends line is already in INT-WI200, and its Watch out line ends with the task; the lane 2 Warning deleted |
| CURRENT (main, marta, 09-04) | after deploying v0.8.0, the Health bullet replaced in a coordination commit |

### Key excerpt

The two edits of `state/CURRENT.md`, in PR #12 and in marta's coordination commit of 09-04:

```diff
@@ -14 +13,0 @@
-- 2026-09-01 marta: Lane 2 readings are dropped by the regex parser; weigh lane 2 manually (TASK-002).
@@ -8 +8 @@
-- 2026-09-01 marta: Production weighbridge PC runs v0.7.2; daily reports are compiled by hand.
+- 2026-09-04 marta: Production weighbridge PC runs v0.8.0; daily PDF reports e-mailed to customers at 06:00 (TASK-003).
```

### Rule illustrated

- A PR carrying an ADR decision merges only with the approval of a human listed in `deciders`: [spec/07-decisions.md](../../spec/07-decisions.md) §7.4.
- Once the author's session has ended, a human reviewer may add commits to its PR branch: [spec/12-concurrency.md](../../spec/12-concurrency.md) §12.1.
- Verify a handoff against `git log`, `git status` and tests before trusting it: [spec/06-handoff.md](../../spec/06-handoff.md) §6.6.
- Lasting handoff lines move to knowledge, then the handoff is deleted in the delivering PR: [spec/06-handoff.md](../../spec/06-handoff.md) §6.5.
- CURRENT changes only with a project-level fact; a deployment is a coordination commit: [spec/08-tasks-and-questions.md](../../spec/08-tasks-and-questions.md) §8.12.

## S5 2026-09-08: a question blocks a task

codex, run by luca in Codex CLI on his laptop, on branch `codex/task-004-sftp-delivery`; luca approves each git command it runs that needs the network or writes to `.git` (`git fetch`, `git worktree`, `git commit`, `git push`).
Goal: TASK-004, now the first ID in NEXT that is `todo` with `owner: none`: upload the daily report to the Beta Haulage SFTP server.

### What they read

After checking TASK-004 on `origin/main` and claiming it, codex finds no knowledge doc whose `code` covers `src/tarelog/delivery/`, so it searches for the path and hops to ADRs:

```text
$ git grep -l -F "src/tarelog/delivery/" -- docs/mkb
docs/mkb/knowledge/modules/MODULE-REPORTS.md
docs/mkb/tasks/TASK-003.md
docs/mkb/tasks/TASK-004.md
$ git grep -l -w MODULE-REPORTS -- docs/mkb/decisions
docs/mkb/decisions/ADR-002.md
```

Read in full: CONSTRAINTS (credentials never in the repository, 06:00), ADR-002 (accepted) and MODULE-REPORTS.
The customer's file specification names both key and password authentication; which one their server accepts is for marta to find out, so codex asks instead of guessing.

### What they wrote

| File | Change |
|---|---|
| TASK-004 (main) | `TASK-004: claim`: `in-progress`, `owner: codex`, `branch: codex/task-004-sftp-delivery`, `code: [src/tarelog/delivery/]` |
| `src/tarelog/delivery/sftp.py` (branch) | upload as `.part`, then rename; authentication left as a stub |
| Q-001, TASK-004 (main, one commit) | Q-001 `owner: marta`, `asked_by: codex`; TASK-004 `blocked`, `blocked_by: [Q-001]`, Notes `- 2026-09-08 codex: blocked on Q-001; the customer's file specification names both key and password authentication.` |
| `handoff/TASK-004.md` (branch) | written, then committed and pushed with all work |

### Key excerpt

The question and the block reach main as one coordination commit, `Q-001: ask marta`, from a temporary worktree; codex's final message ends with:

```text
MKB for humans:
Questions: Q-001 (marta)
```

`handoff/TASK-004.md` on `codex/task-004-sftp-delivery`:

```markdown
# Handoff: TASK-004

Written 2026-09-08 by codex on branch `codex/task-004-sftp-delivery`.

## Where it stands
- Blocked on Q-001: key or password authentication is not known yet.
- `src/tarelog/delivery/sftp.py` (`upload_report()`) uploads to `/inbound/tarelog/` as `<name>.part`, then renames; authentication is a stub.
- `pytest tests/delivery/`: 6 passed, 2 skipped (authentication); this file is pushed with all work.

## Next steps
1. Read the answer: `git grep -n -w Q-001 -- docs/mkb` finds it in Q-001 or, once resolved, where it was promoted.
2. Implement that method in `sftp.py:41`, reading the secret from the host vault, never from `tarelog.toml`; unskip the 2 tests.
3. Add the retry and the alert of the task's acceptance criteria.

## Watch out
- The local SFTP fixture accepts any key and any password: a green test says nothing about the partner server.

## Read first
- TASK-004, Q-001, MODULE-REPORTS, ADR-002, `tests/delivery/conftest.py` (the local SFTP server fixture)
```

### Rule illustrated

- A path search and a reverse hop find the binding ADR even where no doc owns the path: [spec/05-agent-workflow.md](../../spec/05-agent-workflow.md) §5.3.
- Ask only what is outside your authority; the question's owner is the human who must answer: [spec/08-tasks-and-questions.md](../../spec/08-tasks-and-questions.md) §8.9.
- The question, the block and the Notes line land in one coordination commit; the blocked task keeps its `branch`: [spec/08-tasks-and-questions.md](../../spec/08-tasks-and-questions.md) §8.7.
- The handoff is overwritten at session end and pushed with all work: [spec/06-handoff.md](../../spec/06-handoff.md) §6.5.

## S6 2026-09-10: an answer, a promotion and a superseded decision

marta answers Q-001 on main; claude-code promotes the answer on branch `claude-code/mkb-q-001-promote`; PR #14 is merged the same day.
Goal: move the answer to its permanent homes and unblock TASK-004.

### What they read

claude-code reads Q-001 and TASK-004, then looks for everything that relies on the decision the answer reverses:

```text
$ git grep -l -w ADR-002 -- docs/mkb
docs/mkb/decisions/ADR-002.md
docs/mkb/knowledge/modules/MODULE-REPORTS.md
docs/mkb/project/ARCHITECTURE.md
docs/mkb/tasks/TASK-003.md
```

The answer holds a fact about an external system (key authentication) and a choice with lasting effect (CSV instead of PDF) that reverses ADR-002.
So the fact goes to a new INT doc and the choice to a new ADR that supersedes ADR-002; the resolution rides a PR because that ADR needs marta's decision, and TASK-003, closed, keeps its reference.

### What they wrote

| File | Change |
|---|---|
| Q-001 (main, marta) | `Q-001: answer`: Answer line, `status: answered` |
| TASK-007 (main, claude-code) | `TASK-007: add`: "Remove the Chromium PDF pipeline", `normal`, `todo`, `owner: none`, before ADR-003 cites it; it names no ADR yet, because ADR-003 exists only on the branch |
| INT-HAULER-SFTP (PR #14) | new: key authentication "(resolves Q-001)", key in the vault at `tarelog/sftp-key`, `/inbound/tarelog/`, 06:00; no `code` yet; `verified: 2026-09-10` |
| ADR-003 (PR #14) | new, drafted `proposed` by claude-code; marta accepts it in review: `deciders: [marta]`, `date: 2026-09-10`, `supersedes: [ADR-002]` |
| ADR-002, MODULE-REPORTS, ARCHITECTURE, TASK-007 (PR #14) | ADR-002 gets only `status: superseded` and `superseded_by: ADR-003`; the other three now cite ADR-003, TASK-007 in its Goal and `related` (its owner is `none`, so anyone may edit it) |
| TASK-004, Q-001 (PR #14) | TASK-004: two criteria rewritten "(resolves Q-001)", `blocked_by` removed, back to `in-progress` because `branch` is set; Q-001 deleted; commit `Q-001: resolved -> ADR-003, INT-HAULER-SFTP, TASK-004` |
| NEXT, CURRENT (main, marta, after the merge) | NEXT: TASK-004, TASK-007, TASK-006, TASK-005; Focus `- 2026-09-10 marta: CSV delivery to Beta Haulage live before 2026-10-01 (TASK-004, TASK-007).` |

### Key excerpt

The Q-001 file on main after `Q-001: answer`, right before the resolution:

```markdown
---
id: Q-001
type: question
status: answered
owner: marta
asked_by: codex
created: 2026-09-08
related: [TASK-004, MODULE-REPORTS]
---
# Q-001: Does the Beta Haulage SFTP server require key authentication or password authentication?

## Context
TASK-004 uploads the daily report to the Beta Haulage SFTP server and is blocked until this is known.
Their file specification v2 names both SSH key and password authentication and does not say which one their server accepts.
Credentials never go in the repository ([project/CONSTRAINTS.md](../project/CONSTRAINTS.md), section Security and data), so either secret would be read from the host vault.

## Options
- A: SSH key authentication; the private key lives in the host vault. (recommended)
- B: Password authentication; the password lives in the host vault.

## Answer
2026-09-10 marta: Key authentication only; they also said their ERP imports CSV only, so PDF is not needed.
```

The ADR-002 front matter after S6 (only `status` and `superseded_by` changed), then the end of the PR #14 description:

```yaml
---
id: ADR-002
type: adr
status: superseded
date: 2026-09-03
deciders: [marta]
superseded_by: ADR-003
related: [TASK-003, MODULE-REPORTS]
---
```

```text
MKB for humans:
ADR decisions needed: ADR-003
NEXT suggestion: TASK-007 PDF pipeline is dead code after ADR-003
```

### Rule illustrated

- The owner answers in a coordination commit; the answer is promoted with `(resolves Q-001)` (the new ADR cites Q-001 in its Context instead), the question deleted, and an ADR-creating promotion rides a PR: [spec/08-tasks-and-questions.md](../../spec/08-tasks-and-questions.md) §8.11.
- The new ADR carries `supersedes`; the old one changes only `status` and `superseded_by`: [spec/07-decisions.md](../../spec/07-decisions.md) §7.6.
- A new ADR is cited only on its own branch until that branch merges: [spec/04-naming-and-linking.md](../../spec/04-naming-and-linking.md) §4.3.
- The promoter may edit the blocked task's criteria and status although another actor owns it: [spec/08-tasks-and-questions.md](../../spec/08-tasks-and-questions.md) §8.3.
- An INT doc has no `code` until code talks to the system: [spec/03-metadata.md](../../spec/03-metadata.md) §3.5.

## S7 2026-09-14 to 09-17: three actors and a takeover

Three actors and two agent tools, working toward TASK-004's 2026-10-01 deadline and TASK-007.

- 09-14: luca, by hand, merges PR #13 (`luca/wi200-checksum`), which adds checksum support in `src/tarelog/gateway/wi200.py` without touching INT-WI200.
- 09-15: codex, in luca's Codex CLI, rebases its branch, implements the CSV upload with key authentication, overwrites and pushes its handoff, and releases the task because luca leaves for a week.
- 09-16: claude-code session A takes over TASK-004 at marta's request, while session B claims TASK-007 in its own worktree.
- 09-17: session B delivers TASK-007 and asks Q-002; marta deploys v0.9.0 and updates CURRENT and NEXT.

### What they read

Session A reads the task and Codex's handoff on the released branch (Key excerpt).
Session B's `git worktree list` shows both sessions under the one handle, on `claude-code/task-004-sftp-delivery` and `claude-code/task-007-remove-chromium`, told apart by branch.

### What they wrote

| File | Change |
|---|---|
| `src/tarelog/gateway/wi200.py` (PR #13, luca, 09-14) | `gateway: accept WI-200 frames with checksum`; lane 2 set to `CS=ON`; INT-WI200 not updated |
| `sftp.py`, INT-HAULER-SFTP, handoff (codex branch, 09-15) | CSV upload with key authentication; INT-HAULER-SFTP `code: [src/tarelog/delivery/sftp.py]`, a Gotchas line for `ChannelException: (1, 'Administratively prohibited')` written when the parallel upload failed, `verified: 2026-09-15`; handoff overwritten (next step: retry 3 times, then alert e-mail; Dead ends: parallel uploads rejected, pointing to INT-HAULER-SFTP) |
| TASK-004 (main, codex, 09-15; session A, 09-16) | `TASK-004: release` (Key excerpt); then `TASK-004: claim` with `branch: claude-code/task-004-sftp-delivery` |
| PR #15 (session A, 09-16) | retries and alert e-mail; INT-HAULER-SFTP and MODULE-REPORTS `verified: 2026-09-16`; TASK-004 `done`, `closed: 2026-09-16`; the inherited `handoff/TASK-004.md` is not deleted |
| TASK-007 (main, session B, 09-16) | `TASK-007: claim`, `branch: claude-code/task-007-remove-chromium` |
| PR #16 (session B, 09-17) | Chromium pipeline deleted; ARCHITECTURE loses the "PDF renderer" row and is re-verified whole, `verified: 2026-09-17`; OVERVIEW Stack updated; TASK-007 `done`, `closed: 2026-09-17` |
| MODULE-REPORTS (PR #16) | the rebase onto `origin/main` conflicts on `verified` (`2026-09-16` from PR #15, `2026-09-17` on the branch); session B re-checks the merged doc against the merged code and keeps `2026-09-17` |
| Q-002, TASK-005 (main, session B, 09-17) | `Q-002: ask marta`; the unowned TASK-005 `blocked`, `blocked_by: [Q-002]`; PR #16 ends with `Questions: Q-002 (marta)` |
| CURRENT, NEXT (main, marta, 09-17) | v0.9.0 Health bullet added, the v0.8.0 bullet left in place by mistake; Focus `- 2026-09-17 marta: Reliable readings on both lanes before the October peak (TASK-006).`; `mkb: update NEXT` prunes TASK-004 and TASK-007 |

### Key excerpt

Codex's release on 09-15, a coordination commit made in luca's Codex CLI:

```diff
@@ -4,4 +4,3 @@
-status: in-progress
+status: todo
 priority: high
-owner: codex
-branch: codex/task-004-sftp-delivery
+owner: none
@@ -24,0 +24 @@
+- 2026-09-15 codex: released; partial work on branch codex/task-004-sftp-delivery, see its handoff
```

Session A's takeover on 09-16, in a new worktree of its own:

```text
$ git fetch origin
$ git show origin/main:docs/mkb/tasks/TASK-004.md | grep -e "^status:" -e "^owner:" -e "released;"
status: todo
owner: none
- 2026-09-15 codex: released; partial work on branch codex/task-004-sftp-delivery, see its handoff
$ git show origin/codex/task-004-sftp-delivery:docs/mkb/handoff/TASK-004.md | sed -n '/^## Next steps/,/^$/p'
## Next steps
1. In `upload_report()` (sftp.py:57), retry a failed upload 3 times, 5 minutes apart.
2. After the third failure, send an alert e-mail to `delivery.alert_to` through `src/tarelog/delivery/mailer.py`.
3. Test both with the local SFTP fixture, then close TASK-004.

$ git -C "$d" commit -q -am "TASK-004: claim" && git -C "$d" push -q origin HEAD:main    # temporary worktree
$ git switch -c claude-code/task-004-sftp-delivery origin/codex/task-004-sftp-delivery
branch 'claude-code/task-004-sftp-delivery' set up to track 'origin/codex/task-004-sftp-delivery'.
Switched to a new branch 'claude-code/task-004-sftp-delivery'
$ git rebase origin/main
Successfully rebased and updated refs/heads/claude-code/task-004-sftp-delivery.
$ git push -q -u origin claude-code/task-004-sftp-delivery
$ git log --oneline -1 && pytest tests/delivery/ -q
4d8e2a1 TASK-004: retry plan in the handoff before release
8 passed in 2.07s
```

The branch matches the handoff, whose copy on session A's own branch is now its to follow; nobody pushes to Codex's branch again.

### Rule illustrated

- A change to an integration's behavior updates its knowledge doc in the same PR (T11); PR #13 skipped it: [spec/05-agent-workflow.md](../../spec/05-agent-workflow.md) §5.6.
- Release by the owner: `todo`, `owner: none`, no `branch`, and a Notes line naming the branch that holds the partial work: [spec/08-tasks-and-questions.md](../../spec/08-tasks-and-questions.md) §8.3, §8.5.
- Takeover: claim, branch from the released branch's tip, rebase, push, verify the handoff; never push to the old branch: [spec/08-tasks-and-questions.md](../../spec/08-tasks-and-questions.md) §8.4.
- Parallel sessions of one tool share a handle and use one worktree and one branch each: [spec/12-concurrency.md](../../spec/12-concurrency.md) §12.7.
- A conflict on `verified`: keep the older date unless you re-check the merged doc against the merged code: [spec/12-concurrency.md](../../spec/12-concurrency.md) §12.6.

## S8 2026-09-22: gardening

claude-code, asked by marta, on branch `claude-code/mkb-garden-2026-09-22`; one commit `mkb: gardening 2026-09-22`; PR #17 merged the same day.
Goal: the weekly gardening of the full profile: run mkb-check with git and resolve every finding.

### What they read

```text
$ sh docs/mkb/tools/mkb-check.sh
WARN W2 docs/mkb/knowledge/integrations/INT-WI200.md: code changed on 2026-09-14, after the last change of this doc on 2026-09-03
WARN W2 docs/mkb/knowledge/services/SERVICE-GATEWAY.md: code changed on 2026-09-14, after the last change of this doc on 2026-09-03
WARN W6 docs/mkb/tasks/TASK-001.md: in progress; no commit on branch luca/task-001-nightly-backup since 2026-09-04
WARN W5 docs/mkb/state/CURRENT.md: bullet dated 2026-09-04 is older than 14 days: re-verify and re-date, or delete
WARN W4 docs/mkb/handoff/TASK-004.md: its task TASK-004 is done: move lasting lines, then delete
mkb-check: 0 errors, 5 warnings
$ git log -1 --format="%cs %h %an %s" -- src/tarelog/gateway/
2026-09-14 5c2e9a7 luca gateway: accept WI-200 frames with checksum
$ git grep -l -F "Administratively prohibited" -- docs/mkb/knowledge
docs/mkb/knowledge/integrations/INT-HAULER-SFTP.md
```

- W2: commit 5c2e9a7 adds an optional `*` and two hex digits before ETX, checked by XOR, and a new `FrameError: bad checksum`, none of which INT-WI200 describes, while SERVICE-GATEWAY refers to INT-WI200 for the frame format and stays correct.
- W4: the handoff's Dead ends line is already in INT-HAULER-SFTP (the grep prints its path), and its Watch out line ended with the task, so nothing moves before the handoff is deleted.
- W5 and W6: the v0.8.0 bullet speaks of PDF reports, which ADR-003 and TASK-007 ended, and TASK-001's owner is a human, so gardening does not release the claim.

### What they wrote

| File | Change |
|---|---|
| `state/CURRENT.md` | v0.8.0 Health bullet deleted; Warnings `- 2026-09-22 claude-code: Nightly backup (TASK-001) is not running yet; copy data/tarelog.db by hand before any migration.` (the path is in backticks in the file) |
| `handoff/TASK-004.md` | deleted |
| INT-WI200 | Checksum subsection under Contract, a checksum row in the field table, `FrameError: bad checksum` in Gotchas, "checksum" in the summary; `verified: 2026-09-22` |
| SERVICE-GATEWAY | checked against the 09-14 change, still correct: `verified: 2026-09-22` |
| TASK-001 | unchanged: a human's claim; the decision goes to marta in the PR description |

### Key excerpt

The PR #17 description, one line per finding:

```text
mkb: gardening 2026-09-22

1. W5: the v0.8.0 Health bullet (2026-09-04, PDF reports) contradicts ADR-003 and TASK-007 and is replaced by the 2026-09-17 bullet: deleted.
2. W4: handoff/TASK-004.md reached main in PR #15 although TASK-004 is done: its Dead ends line (the partner server rejects parallel uploads) is already in INT-HAULER-SFTP Gotchas, so the handoff is deleted.
3. W2: src/tarelog/gateway/ changed on 2026-09-14 (luca, checksums) after INT-WI200 and SERVICE-GATEWAY (2026-09-03): INT-WI200 gains a Checksum section, SERVICE-GATEWAY is still correct; both verified 2026-09-22.
4. W6: TASK-001 (luca) has no commit on luca/task-001-nightly-backup since 2026-09-04: a human's claim, so not released; @marta please decide. Warning bullet added: back up data/tarelog.db by hand.
5. mkb-check after the fixes: 0 errors, 1 warning (the W6 of finding 4, waiting for marta); nothing to archive (oldest closed is 2026-09-02); the Handoff.md stub stays until the first gardening after 2026-10-01.
```

The line checked by finding 2, as it stands in the handoff's Dead ends and in INT-HAULER-SFTP, section Gotchas, where Codex wrote it on 09-15:

```markdown
- Uploading several report days in parallel, one SFTP session each: the second session fails with `ChannelException: (1, 'Administratively prohibited')`; the partner allows one session per account (INT-HAULER-SFTP).
- `ChannelException: (1, 'Administratively prohibited')` on the second of two uploads started together -> the partner server allows one SFTP session per account and rejects parallel uploads -> upload files one after another over a single session, as `sftp.py` does.
```

### Rule illustrated

- Gardening means running mkb-check with git and resolving every finding with the action of its check: [spec/09-lifecycle.md](../../spec/09-lifecycle.md) §9.6.
- `verified` is bumped only after checking the code: [spec/09-lifecycle.md](../../spec/09-lifecycle.md) §9.5.
- Gardening never releases a human's claim; the lead decides: [spec/08-tasks-and-questions.md](../../spec/08-tasks-and-questions.md) §8.5.
- Closed tasks move to `tasks/archive/` only 30 days after `closed`: [spec/09-lifecycle.md](../../spec/09-lifecycle.md) §9.2.

## End state

The files on `main` after S8, as they are in this directory (`agents/RULES.md`, `templates/` and `tools/` are the standard files, copied unchanged):

```text
examples/tarelog/
├── WALKTHROUGH.md
├── AGENTS.tmpl.md                 project notes + the MKB block of agent-instructions/AGENTS.tmpl.md, verbatim
├── CLAUDE.tmpl.md                 identical to agent-instructions/CLAUDE.tmpl.md
├── Handoff.md                     the stub of spec/13-adoption-and-integration.md §13.3, dated 2026-09-01
├── .gitattributes                 the adopter's file: identical to templates/gitattributes-mkb.txt
└── docs/mkb/
    ├── INDEX.md                   profile: full
    ├── agents/RULES.md            byte-identical to templates/full/docs/mkb/agents/RULES.md
    ├── project/OVERVIEW.md
    ├── project/ARCHITECTURE.md    verified: 2026-09-17
    ├── project/CONSTRAINTS.md
    ├── project/CONVENTIONS.md
    ├── state/CURRENT.md
    ├── state/NEXT.md
    ├── decisions/ADR-001.md       accepted, date 2026-03-10
    ├── decisions/ADR-002.md       superseded, superseded_by ADR-003
    ├── decisions/ADR-003.md       accepted, supersedes [ADR-002]
    ├── tasks/TASK-001.md          in-progress, owner luca, branch luca/task-001-nightly-backup
    ├── tasks/TASK-002.md          done, closed 2026-09-03, owner claude-code
    ├── tasks/TASK-003.md          done, closed 2026-09-02, owner codex
    ├── tasks/TASK-004.md          done, closed 2026-09-16, owner claude-code, branch claude-code/task-004-sftp-delivery; Notes hold codex's release line
    ├── tasks/TASK-005.md          blocked, owner none, blocked_by [Q-002]
    ├── tasks/TASK-006.md          todo, owner none (no formerly: the collision was caught at creation)
    ├── tasks/TASK-007.md          done, closed 2026-09-17, owner claude-code
    ├── questions/Q-002.md         open, owner marta
    ├── knowledge/services/SERVICE-GATEWAY.md          verified 2026-09-22
    ├── knowledge/integrations/INT-WI200.md            verified 2026-09-22
    ├── knowledge/integrations/INT-HAULER-SFTP.md      verified 2026-09-16, code [src/tarelog/delivery/sftp.py]
    ├── knowledge/database/DB-TICKETS.md               verified 2026-09-01
    ├── knowledge/modules/MODULE-REPORTS.md            verified 2026-09-17
    ├── knowledge/troubleshooting/TS-SQLITE-LOCKED.md  verified 2026-09-01
    ├── templates/                 the 11 files, byte-identical to templates/full/docs/mkb/templates/
    └── tools/mkb-check.sh         byte-identical to templates/full/docs/mkb/tools/mkb-check.sh
```

There is no `handoff/` directory, because both handoffs lived on branches; Q-001 is the only ID without a file, because a resolved question is deleted and `git grep -w Q-001` finds where its answer lives.

```text
$ sh templates/full/docs/mkb/tools/mkb-check.sh --root examples/tarelog --no-git --today 2026-09-23
mkb-check: 0 errors, 0 warnings
```

`--no-git` skips W2, W3, W6 and W14, because this directory ships without the story's git history and code; in the story's own repository the W6 of TASK-001 stays until marta decides.
The board on 2026-09-23, from the one-line view run in a checkout of `main`:

```text
$ awk '/^status:/{s=$2} /^priority:/{p=$2} /^owner:/{o=$2} /^# TASK-/{if (s!="done" && s!="dropped") print substr($0,3) " | " s " " p " " o; nextfile}' docs/mkb/tasks/TASK-*.md
TASK-001: Nightly backup of the ticket database | in-progress normal luca
TASK-005: Per-customer report time zone | blocked normal none
TASK-006: Buffer readings while SQLite is locked | todo high none
```

A session that starts on 2026-09-23 without a task takes TASK-006, the first ID in state/NEXT.md that is `todo` with `owner: none`, and skips TASK-005, which waits for marta's answer to Q-002.

## What the rules prevented

| Situation | Without MKB | With MKB |
|---|---|---|
| A new session needs context (S2, S4) | reads 603 lines of Handoff.md, half of them obsolete | reads INDEX, CURRENT and its task, then 3 docs found by `git grep` |
| Two actors take the next task number in the same minute (S2, S3) | two different tasks called TASK-005, and a code comment pointing at the wrong one | the second push is rejected, the add/add conflict shows at once, and claude-code takes TASK-006 before anything cites it |
| A cloud agent that cannot push finds follow-up work (S3) | the idea stays in a PR comment, or the agent invents a number | a `New task:` line, and marta creates TASK-005 |
| An agent picks a report format with lasting effect, and a customer answer later overturns it (S3, S6) | the choice ships silently, then its reasoning is edited away or dead PDF code lingers | ADR-002 waits for marta's decision; ADR-003 supersedes it and keeps it as a record; TASK-007 removes the dead code |
| Work waits on a person (S5, S7) | the blocker lives in chat, and the task looks abandoned | Q-001 and Q-002 are owned by marta, the tasks carry `blocked_by`, and the `MKB for humans:` lines tell her |
| A developer leaves mid-task (S7) | partial work sits on a branch nobody knows about, and the next agent starts over | codex's release line names the branch; claude-code continues from its tip and its handoff |
| Two sessions of one tool run at once and both update MODULE-REPORTS (S7) | they share a checkout, and the later merge silently wins | one worktree and one branch each, told apart by `branch`; a loud conflict on `verified`, resolved by re-checking the merged doc |
| Code changes without its doc (S7, PR #13) | INT-WI200 stays wrong until a lane 2 incident | W2 flags it at the next weekly gardening (S8) |
| A handoff outlives its task, and a deployment bullet goes stale (S7, S8) | stale notes on main read as current: customers still get PDF reports, and the lasting line is lost with the branch | W4 and W5: the handoff and the old bullet are deleted; the lasting line has been in INT-HAULER-SFTP since the session that hit the error |
| A human's claim goes quiet (S8) | an agent grabs luca's half-done backup, or the backup is forgotten | W6 goes to marta; gardening never releases a human's claim; a Warning says to back up by hand |
| Out-of-scope work turns up (S2) | the parser task widens, or the finding is forgotten | TASK-006 is on main within minutes, and `TODO(TASK-006)` in the code points to it |
