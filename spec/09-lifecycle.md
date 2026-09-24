# 9. Lifecycle

*MKB Standard v1.0 · 2026-09-23 · Normative*

This chapter defines how records move from creation to closing, archival or deletion, and how the MKB prevents documentation rot.
It is the home of archival, knowledge maintenance, staleness signals, STALE banners, gardening, the `mkb-check.sh` specification and size budgets.
The rules for creating, updating and closing each record kind live in the chapters that the lifecycle matrix names.

## 9.1 Lifecycle matrix

| Record | Create | Update | Close | Archive | Delete |
|---|---|---|---|---|---|
| Task | [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.1 | owner ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.3) | `done` or `dropped` plus Completion | to `tasks/archive/` 30 days after `closed` (§9.2) | never |
| ADR | [07-decisions.md](07-decisions.md) §7.1 | while `proposed`, freely on its branch; after acceptance only [07-decisions.md](07-decisions.md) §7.5 | `rejected`, `superseded`, `deprecated` | never moves | never |
| Question | [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.9 | owner fills Answer | promotion ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.11) | - | at promotion |
| Knowledge doc | threshold of [05-agent-workflow.md](05-agent-workflow.md) §5.5, after searching for an existing doc | trigger matrix ([05-agent-workflow.md](05-agent-workflow.md) §5.6); `verified` after a check ([03-metadata.md](03-metadata.md) §3.3) | - | - | when the thing it describes is removed, or when merged into another doc |
| `state/CURRENT.md` bullet | project-level fact appears | re-date on re-verification | - | - | when no longer true; when unverified past the W5 threshold |
| `state/NEXT.md` entry | the lead | the lead | - | - | the lead prunes |
| Handoff | session ends with the task unfinished | overwritten by the owner | task done or dropped | - | in the closing PR; leftovers by gardening |
| `project/*` | adoption or first need | in place | - | - | if absorbed into README or CONTRIBUTING (then an INDEX override) |
| INDEX, RULES, templates, tools | adoption | layout change (INDEX); version upgrade (others) | - | - | never |

There is no `archive/` for anything but tasks.

Where each lifecycle rule is specified:

| Activity | Rule and home |
|---|---|
| Creating documents | a record is created only when its trigger fires ([05-agent-workflow.md](05-agent-workflow.md) §5.5, §5.6); a directory exists only once it holds a file ([02-directory-structure.md](02-directory-structure.md) §2.5) |
| Updating documents | walk the trigger matrix and update only the rows that fire ([05-agent-workflow.md](05-agent-workflow.md) §5.6) |
| Archiving documents | closed tasks only, 30 days after `closed` (§9.2.1) |
| Deleting obsolete information | delete rather than mark obsolete (§9.2.2) |
| Resolving questions | promote the answer to its permanent home, then delete the question ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.11) |
| Closing tasks | `done` inside the delivering PR, `dropped` after a human decision ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.5, §8.6) |
| Superseding decisions | a new ADR with `supersedes`, in one PR ([07-decisions.md](07-decisions.md) §7.6) |
| Detecting and removing rot | staleness signals, STALE banners, gardening and mkb-check (§9.4 to §9.7) |

## 9.2 Archival

Only tasks are archived.
ADRs never move: they stay in `decisions/` with their status; a rejected ADR records that an option was considered ([07-decisions.md](07-decisions.md) §7.4).
Everything else that becomes obsolete is deleted (§9.2.2).

### 9.2.1 Archiving closed tasks

Gardening runs `git mv docs/mkb/tasks/TASK-NNN.md docs/mkb/tasks/archive/` for every task `done` or `dropped` with `closed` more than 30 days ago, in a commit `mkb: archive closed tasks`.
Archived tasks are never edited or deleted.

- W9 lists the tasks that are due (§9.4); archiving is step 3 of the gardening procedure (§9.6).
- An archived task keeps its ID and file name; its number is never reused ([04-naming-and-linking.md](04-naming-and-linking.md) §4.3), and E1 still compares its `id` with every other record (§9.7.5).
- `tasks/archive/` is never read by default ([05-agent-workflow.md](05-agent-workflow.md) §5.3) and is never authoritative ([01-architecture.md](01-architecture.md) §1.7).
- The board views exclude it ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.8); `git grep -n -w "<ID>" -- docs/mkb/tasks` still finds how a closed task ended.
- References to an archived task keep working, because IDs are written bare and never linked ([04-naming-and-linking.md](04-naming-and-linking.md) §4.8).

Example: in TareLog, TASK-003 has `closed: 2026-09-02`; the gardening of 2026-09-22 finds nothing to archive, and W9 first reports TASK-003 on 2026-10-03, 31 days after it closed.

### 9.2.2 Deleting obsolete information

Delete rather than mark obsolete, except: tasks (archived), ADRs (kept with status), and knowledge that is known wrong but not yet fixed (STALE banner, §9.5).
The moment each record is deleted is in the Delete column of §9.1.
Obsolete information is deleted and recovered from git when needed:

```sh
git log -S "<ID>"                # commits that added or removed a mention of the ID
git log --all -- '*<ID>.md'      # history of a record file, including a deleted one
```

Example: TareLog's Q-001 was deleted when its answer was promoted; `git grep -n -w Q-001 -- docs/mkb` finds the docs that carry the answer (ADR-003 cites Q-001 in its Context; INT-HAULER-SFTP and TASK-004 mark it `(resolves Q-001)`), and `git log --all -- '*Q-001.md'` shows the deleted file's history.

## 9.3 Knowledge maintenance

Knowledge docs are created at the threshold of [05-agent-workflow.md](05-agent-workflow.md) §5.5 and kept current by rows T11, T12, T14 and T22 of the trigger matrix ([05-agent-workflow.md](05-agent-workflow.md) §5.6).
Their structure is maintained as follows:

- Split: a knowledge doc over 150 lines is split into narrower IDs; the original keeps a short map pointing to the new IDs (or is deleted if the split is total).
- Rename: only during gardening, one commit, with `formerly` set and every reference repointed.
- Delete: with its component, in the same PR.
- Never bulk-generate knowledge docs for code nobody is changing; at adoption or upgrade, at most the 3 most-changed components get docs.

The most-changed paths, as a starting point for choosing those components:

```sh
git log --format= --name-only | sort | uniq -c | sort -rn | head
```

```powershell
git log --format= --name-only | Where-Object { $_ } | Group-Object | Sort-Object Count -Descending | Select-Object -First 10 Count, Name
```

Related rules, each in its home:
- New and renamed IDs follow the knowledge naming rules ([04-naming-and-linking.md](04-naming-and-linking.md) §4.5); `git grep -n -w "<OLD-ID>"` over the whole repository finds the references to repoint, code comments included.
- `verified` is bumped only after a check ([03-metadata.md](03-metadata.md) §3.3); W2, W3 and W16 report the docs whose check is due (§9.4).
- Two branches that create the same knowledge doc merge its content into one doc by hand ([04-naming-and-linking.md](04-naming-and-linking.md) §4.4).
- A doc that is known wrong and cannot be fixed now gets a STALE banner (§9.5).

## 9.4 Staleness signals

Every signal is an mkb-check warning; the thresholds are the same in both profiles except W5.
This table documents the checker: gardening runs `mkb-check.sh` and applies the action of each warning it prints; nobody walks the table by hand.

| Check | Signal | Threshold | Action |
|---|---|---|---|
| W5 | `state/CURRENT.md` bullet | older than 14 days (full) or 35 days (minimal) | re-verify and re-date, or delete |
| W6 | `in-progress` task | no commit on its branch for 7 days; with `branch: pending`, task file unchanged on the default branch for 7 days | agent owner: release ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.5); human owner: ask; lead decides after 14 days; pending: the dispatching human releases |
| W14 | `blocked` task | file unchanged for 14 days | the lead re-plans, escalates or drops it |
| W15 | `open` question | `created` more than 14 days ago | remind the owner; the lead escalates |
| W7 | `answered` question | any | promote now ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.11) |
| W12 | `blocked` task | every `blocked_by` item resolved | clear the block (T8, [05-agent-workflow.md](05-agent-workflow.md) §5.6) |
| W2 | Knowledge doc | a `code` path changed on a later day than the doc itself | check the doc against that change: fix and bump `verified`, or STALE banner plus task |
| W3 | Knowledge doc | a `code` path no longer exists | rewrite or delete |
| W16 | Knowledge doc or ARCHITECTURE | `verified` older than 180 days | re-verify the whole doc against the code |
| W8 | `> STALE` banner | older than 30 days | fix the doc or delete it |
| W4 | Handoff on the default branch | task `done`, `dropped` or missing | move lasting lines (T3, [05-agent-workflow.md](05-agent-workflow.md) §5.6), then delete |
| W9 | Closed task | `closed` more than 30 days ago | archive (§9.2.1) |
| W17 | `low` task | `created` more than 90 days ago | propose dropping it to the lead |
| W13 | `state/NEXT.md` entry | task `done`, `dropped` or missing | tell the lead, who prunes it |
| W1 | Size budget | exceeded | split or trim (§9.3, §9.8) |

The exact condition each warning tests is in §9.7.6.
A warning whose action needs a human decision goes to the lead in the gardening PR description (§9.6).

## 9.5 STALE banners

A descriptive doc that contradicts the code gets a STALE banner and a task when the fix is large or out of scope ([05-agent-workflow.md](05-agent-workflow.md) §5.7); gardening does the same for content it does not understand (§9.6).
Exact form, directly under the H1 (whole doc) or under the affected `##` heading (one section):

```markdown
> STALE YYYY-MM-DD <handle>: <what is wrong>. Tracking TASK-NNN.
```

Text under a banner is not authoritative.
Removing the banner is part of the fix.
Never bump `verified` without actually checking the code.

- The tracking task exists before the banner names it: it is created as a coordination commit ([04-naming-and-linking.md](04-naming-and-linking.md) §4.3).
- The banner is not a status: knowledge docs have no `status` key ([03-metadata.md](03-metadata.md) §3.4).
- W8 reports a banner older than 30 days; the doc is then fixed or deleted (§9.4).
- Every banner in the MKB: `git grep -n "^> STALE [0-9]" -- docs/mkb`.
- mkb-check ignores banner lines inside fenced code blocks, so a doc can show the form (§9.7.4).

## 9.6 Gardening

Gardening means running `mkb-check.sh` and resolving every finding.

- Cadence: full profile weekly; minimal profile monthly; also when a session reports `Gardening due` or a routing gap ([05-agent-workflow.md](05-agent-workflow.md) §5.8).
- Who: any human or agent asked by a human; not a task (it fits in one sitting).
- Where: branch `<actor>/mkb-garden-YYYY-MM-DD`, merged the same day (its edits are broad but tiny).
- Procedure:
  1. Run `sh docs/mkb/tools/mkb-check.sh` (with git, so that every check runs) and fix every error.
  2. Resolve every warning with the action in §9.4; a warning that needs a human decision (a human's stale claim, dropping a task, pruning NEXT) goes into the PR description for the lead.
  3. Archive closed tasks (W9, §9.2.1).
  4. Add INDEX Routing rows for reported routing gaps.
  5. Delete a migration stub ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.3) whose date has passed.
  6. Prune `state/NEXT.md` only if the lead asked.
- Limits: gardening never changes code; never rewrites content it does not understand (it adds a STALE banner and a task instead); never releases a human's claim.
- Commit `mkb: gardening YYYY-MM-DD`; the PR description lists each finding in at most 5 lines.
- Micro-gardening: any session may fix a single false item it notices in a file it read anyway.

Between gardening runs, sessions do not garden unasked, except micro-fixes.
A session that sees a `state/CURRENT.md` bullet older than the W5 threshold, or a handoff on the default branch whose task is `done`, `dropped` or missing, adds `Gardening due` to its `MKB for humans:` lines ([05-agent-workflow.md](05-agent-workflow.md) §5.2).
A session that needed more than 5 docs adds a `Routing gap:` line ([05-agent-workflow.md](05-agent-workflow.md) §5.3), which step 4 turns into an INDEX Routing row.

Note: §9.4 gives no action for W10 and W11, which are consistency checks rather than staleness signals.
Resolve W10 by repointing the reference to the record's current ID, or by removing it when the record is gone for good, as renames and deletions do (§9.3).
Resolve W11 by deleting the guide comment, which should have been deleted when the file was created from its skeleton.

Example: TareLog session S8 in [examples/tarelog/WALKTHROUGH.md](../examples/tarelog/WALKTHROUGH.md) is a gardening run on `claude-code/mkb-garden-2026-09-22`.
Its PR description lists, in five lines, a W5 Health bullet deleted, a W4 handoff deleted once its lasting line was found already in INT-HAULER-SFTP, W2 drift checked on INT-WI200 and SERVICE-GATEWAY, a W6 claim of a human owner flagged to the lead instead of released, and the final mkb-check result.

## 9.7 mkb-check

`docs/mkb/tools/mkb-check.sh` is the consistency checker and ID allocator of the MKB, shipped in both profiles.
The standard repository ships it as [templates/full/docs/mkb/tools/mkb-check.sh](../templates/full/docs/mkb/tools/mkb-check.sh), with an identical copy in `templates/minimal/`.
This section is its normative specification.
Gardening runs it (§9.6), adoption requires zero errors ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.1), and its use in CI depends on the profile ([11-profiles.md](11-profiles.md) §11.4).
It is replaced only on MKB version upgrade ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.8).

### 9.7.1 Usage

```text
sh docs/mkb/tools/mkb-check.sh [--root DIR] [--no-git] [--adr-dir DIR] [--today YYYY-MM-DD] [--strict] [check]
sh docs/mkb/tools/mkb-check.sh [--root DIR] [--no-git] [--adr-dir DIR] next TASK|ADR|Q
```

The first form runs the checks; the second prints the next free ID (§9.7.7).
From PowerShell: `& "$env:ProgramFiles\Git\bin\bash.exe" docs/mkb/tools/mkb-check.sh`.

### 9.7.2 Options

- `--root DIR`: repository root containing `docs/mkb/`; default: `git rev-parse --show-toplevel`, else the current directory.
- `--no-git`: skip checks W2, W3, W6, W14; `next` scans only the working tree.
  Outside a git work tree it runs as with `--no-git`; in a shallow clone, whose history is incomplete, `check` runs as with `--no-git` and `next` exits 2 without printing an ID (run `git fetch --unshallow` first).
- `--adr-dir DIR`: an ADR directory adopted in place ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.4), relative to the root.
  Its files keep their native format: mkb-check applies no front-matter or file-name checks to them (E2, E3 and E4 are skipped there); E1 becomes "two files in DIR with the same leading number" (the duplicate-number check of [13-adoption-and-integration.md](13-adoption-and-integration.md) §13.4); W10 resolves `ADR-<n>` to a file `DIR/<n>-*.md`, comparing numbers as integers; `next ADR` prints 1 + the highest leading number of any file ever added to DIR on any ref ([04-naming-and-linking.md](04-naming-and-linking.md) §4.3), padded to the width of the existing numbers, as `ADR-<n>`.
  Default: `docs/mkb/decisions` with the normal checks.
- `--today YYYY-MM-DD`: date used for age checks (default: the system date); used for reproducible runs.
- `--strict`: warnings also make the exit code 1.

### 9.7.3 Exit codes and output

- Exit codes: 0 no errors (and no warnings under `--strict`); 1 errors found; 2 usage error.
- Output lines: `ERROR E<n> <path>: <message>`, `WARN W<n> <path>: <message>`, final line `mkb-check: <e> errors, <w> warnings`.

This standard fixes the form of each line and the final line; it does not fix the wording of `<message>` or the order of the `ERROR` and `WARN` lines above the final line.

Example: `sh docs/mkb/tools/mkb-check.sh --today 2026-09-22` in TareLog before the fixes of session S8 (messages as the shipped `mkb-check.sh` words them):

```text
WARN W2 docs/mkb/knowledge/integrations/INT-WI200.md: code changed on 2026-09-14, after the last change of this doc on 2026-09-03
WARN W2 docs/mkb/knowledge/services/SERVICE-GATEWAY.md: code changed on 2026-09-14, after the last change of this doc on 2026-09-03
WARN W6 docs/mkb/tasks/TASK-001.md: in progress; no commit on branch luca/task-001-nightly-backup since 2026-09-04
WARN W5 docs/mkb/state/CURRENT.md: bullet dated 2026-09-04 is older than 14 days: re-verify and re-date, or delete
WARN W4 docs/mkb/handoff/TASK-004.md: its task TASK-004 is done: move lasting lines, then delete
mkb-check: 0 errors, 5 warnings
```

The run exits 0: without `--strict`, warnings alone do not change the exit code.

### 9.7.4 Scope

- Scope: `docs/mkb/**/*.md` excluding `docs/mkb/templates/`, plus the `--adr-dir` directory for the checks named above.
- Record checks (E1 to E4 and the front matter checks) apply to `decisions/`, `tasks/` (including `archive/`), `questions/`, `knowledge/` and the singletons that [03-metadata.md](03-metadata.md) §3.1 requires front matter on (`INDEX.md`, `agents/RULES.md`, `project/ARCHITECTURE.md`).
- Files under `handoff/` get only W1 and W4, plus E3 when they contain front matter; the same E3 fires for any file on which [03-metadata.md](03-metadata.md) §3.1 forbids front matter.
- Lines inside fenced code blocks (opened by three or more backticks or tildes) are ignored by W5, W8, W10 and W11, so RULES.md and knowledge docs can show formats in fences.

Note: `docs/mkb/templates/` is outside the scope because its placeholders (`YYYY-MM-DD`, `<handle>`) are invalid values by design.

### 9.7.5 Errors

| Code | Check |
|---|---|
| E1 | the same `id` value in two files (including `tasks/archive/`) |
| E2 | an ID file whose name differs from its `id` |
| E3 | front matter violates [03-metadata.md](03-metadata.md) §3.2 or §3.5: missing required key, unknown key, invalid vocabulary value, invalid date, handle or ID pattern, a conditional key rule broken, or a line other than one blank line between the closing `---` and the H1 (key order is not checked) |
| E4 | an ID file in the wrong directory for its prefix (for example `MODULE-` outside `knowledge/modules/`) |
| E5 | a file named `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` or `AGENTS.override.md` under `docs/mkb/` |

### 9.7.6 Warnings

| Code | Check |
|---|---|
| W1 | file over its size budget (§9.8) |
| W2 | the last commit touching any of a doc's `code` paths is dated after the last commit touching the doc itself (`git log -1 --format=%cs -- <paths>` and `-- <doc>`, compared as strings; same-day commits, and a commit that touches both, never warn) |
| W3 | a `code` path does not exist |
| W4 | a handoff file whose task is `done`, `dropped` or missing |
| W5 | a `state/CURRENT.md` bullet not in the dated form, or older than 14 days (`profile: full`) or 35 days (`profile: minimal`), read from INDEX |
| W6 | an `in-progress` task whose branch has no commit for 7 days or is not found; with `branch: pending`, the last commit touching the task file on the default branch is used, and so it is when `branch` is the default branch |
| W7 | a question with `status: answered` |
| W8 | a line starting with `> STALE ` whose date is older than 30 days |
| W9 | a `done` or `dropped` task in `tasks/` with `closed` more than 30 days ago |
| W10 | a TASK, ADR or knowledge ID referenced in `docs/mkb/` with no file (Q IDs are exempt: resolved questions are deleted by design; values of `formerly` are exempt) |
| W11 | a line starting with `<!-- guide:` outside `docs/mkb/templates/` |
| W12 | a `blocked` task whose `blocked_by` items are all missing, `done` or `dropped` |
| W13 | `state/NEXT.md` lists a task that is `done`, `dropped` or missing |
| W14 | a `blocked` task whose file has not changed for 14 days |
| W15 | an `open` question with `created` more than 14 days ago |
| W16 | a knowledge doc or `project/ARCHITECTURE.md` whose `verified` is older than 180 days |
| W17 | a `low` task that is not `done` or `dropped` with `created` more than 90 days ago |

### 9.7.7 The next subcommand

- `next` prints one ID, for example `TASK-008`; with no existing record it prints the first number (`TASK-001`).
- The ID is the one the allocation procedure of [04-naming-and-linking.md](04-naming-and-linking.md) §4.3 yields: the highest number found, plus 1, zero-padded to at least 3 digits.
- With `--no-git` it scans only the working tree; with `--adr-dir` it follows §9.7.2.
- Fetch before running it, so that every ref is current, and push a new TASK or Q file to the default branch at once: steps 1 and 6 of [04-naming-and-linking.md](04-naming-and-linking.md) §4.3.

Example: after session S8, `sh docs/mkb/tools/mkb-check.sh next TASK` in TareLog prints `TASK-008`, because TASK-007 is the highest task ever added.

### 9.7.8 Implementation requirements

- POSIX sh, git, `grep -E`, `sed`, `awk`, `find`, `wc` only; no bash arrays.
- Date arithmetic in awk (days-from-civil), never `date -d` or `date -v`.
- Strips `\r` so CRLF files do not break parsing.
- Runs in Git Bash on Windows, Linux and macOS.
- At most 450 lines; LF line endings.

## 9.8 Size budgets

Every MKB file has a line budget, so that a read stays cheap and a growing doc is split before it turns into a catch-all.
mkb-check reports a file over its budget as W1; the action is to split or trim it (§9.4), and a knowledge doc is split into narrower IDs (§9.3).

| File | Budget |
|---|---|
| `AGENTS.md` (MKB block) | block ≤ 35 lines |
| `CLAUDE.md` | own content ≤ 20 lines |
| `.gitattributes` (MKB lines) | 4 lines |
| `docs/mkb/INDEX.md` | ≤ 120 lines |
| `docs/mkb/agents/RULES.md` | ≤ 500 lines |
| `docs/mkb/project/OVERVIEW.md` | ≤ 80 lines |
| `docs/mkb/project/ARCHITECTURE.md` | ≤ 150 lines |
| `docs/mkb/project/CONSTRAINTS.md` | ≤ 80 lines |
| `docs/mkb/project/CONVENTIONS.md` | ≤ 120 lines |
| `docs/mkb/state/CURRENT.md` | ≤ 40 lines |
| `docs/mkb/state/NEXT.md` | ≤ 15 lines |
| `docs/mkb/decisions/ADR-NNN.md` | ≤ 100 lines |
| `docs/mkb/tasks/TASK-NNN.md`, `docs/mkb/tasks/archive/TASK-NNN.md` | ≤ 60 lines |
| `docs/mkb/questions/Q-NNN.md` | ≤ 40 lines |
| `docs/mkb/knowledge/modules/MODULE-<NAME>.md`, `docs/mkb/knowledge/services/SERVICE-<NAME>.md`, `docs/mkb/knowledge/database/DB-<NAME>.md`, `docs/mkb/knowledge/integrations/INT-<NAME>.md` | ≤ 150 lines |
| `docs/mkb/knowledge/troubleshooting/TS-<NAME>.md` | ≤ 60 lines |
| `docs/mkb/handoff/TASK-NNN.md` | ≤ 30 lines |
| `docs/mkb/templates/*.md` | ≤ 40 lines each |
| `docs/mkb/tools/mkb-check.sh` | ≤ 450 lines |

- The per-file reference of [02-directory-structure.md](02-directory-structure.md) §2.3 lists the same budgets with each file's purpose and update rule.
- The handoff budget is a hard limit that includes the H1 ([06-handoff.md](06-handoff.md) §6.3).
- W1 covers only the files in mkb-check's scope (§9.7.4); the root files, `docs/mkb/templates/` and `mkb-check.sh` itself are outside it.
- The AGENTS.md block budget keeps the block well inside the instruction size limits of agent tools ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.5).
