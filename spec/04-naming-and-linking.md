# 4. Naming and linking

*MKB Standard v1.0 · 2026-09-23 · Normative*

This chapter defines record IDs, file, branch and commit names, how numbered IDs are allocated, how collisions are resolved, and how documents, code and git refer to each other.
The front matter keys that carry IDs (`id`, `related`, `blocked_by`, `supersedes`, `superseded_by`, `formerly`) are defined in [03-metadata.md](03-metadata.md) §3.3.
Examples use the generic pattern IDs of this chapter (`TASK-042`, `ADR-007`) and IDs from the TareLog example ([examples/tarelog/WALKTHROUGH.md](../examples/tarelog/WALKTHROUGH.md)).

## 4.1 ID kinds and patterns

Every record has an ID, and the file name is the ID.
Handoffs have no ID of their own; the file is named after the work item ID.
There are no blocker IDs: a blocker is always an owned task or question ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.7).

| Kind | Pattern | Example | File |
|---|---|---|---|
| Task | `^TASK-[0-9]{3,}$` | `TASK-042` | `docs/mkb/tasks/TASK-042.md` or `docs/mkb/tasks/archive/TASK-042.md` |
| Decision | `^ADR-[0-9]{3,}$` | `ADR-007` | `docs/mkb/decisions/ADR-007.md` |
| Question | `^Q-[0-9]{3,}$` | `Q-003` | `docs/mkb/questions/Q-003.md` |
| Module | `^MODULE-[A-Z][A-Z0-9]*(-[A-Z0-9]+)*$` | `MODULE-REPORTS` | `docs/mkb/knowledge/modules/MODULE-REPORTS.md` |
| Service | `^SERVICE-[A-Z][A-Z0-9]*(-[A-Z0-9]+)*$` | `SERVICE-GATEWAY` | `docs/mkb/knowledge/services/SERVICE-GATEWAY.md` |
| Database | `^DB-[A-Z][A-Z0-9]*(-[A-Z0-9]+)*$` | `DB-TICKETS` | `docs/mkb/knowledge/database/DB-TICKETS.md` |
| Integration | `^INT-[A-Z][A-Z0-9]*(-[A-Z0-9]+)*$` | `INT-WI200` | `docs/mkb/knowledge/integrations/INT-WI200.md` |
| Troubleshooting | `^TS-[A-Z][A-Z0-9]*(-[A-Z0-9]+)*$` | `TS-SQLITE-LOCKED` | `docs/mkb/knowledge/troubleshooting/TS-SQLITE-LOCKED.md` |
| Handoff | no own ID | - | `docs/mkb/handoff/TASK-042.md` (named after the work item) |

Rules:
- Numbers are zero-padded to at least 3 digits (`TASK-007`, never `TASK-7`).
- After `TASK-999` comes `TASK-1000`; existing IDs are never re-padded.
- Knowledge IDs follow the naming rules of §4.5.
- IDs are written in uppercase, literally, everywhere (never "ADR 7", "adr-007", "Task 42").
- Grep contract for tooling: `\b(TASK|ADR|Q)-[0-9]{3,}\b` and `\b(MODULE|SERVICE|DB|INT|TS)-[A-Z][A-Z0-9]*(-[A-Z0-9]+)*\b`.
- Templates, RULES.md and INDEX.md use only placeholders (`TASK-NNN`, `ADR-NNN`, `Q-NNN`, `MODULE-<NAME>`), which never match the grep contract.
- They MUST NOT contain concrete example IDs.

Work items of an external issue tracker keep the tracker's key, such as `GH-123`, as their ID ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.13).
An ADR directory adopted in place keeps its native file names; its IDs in prose are `ADR-` plus the directory's number, such as `ADR-0007` ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.4).

## 4.2 File and directory names

| Thing | Rule | Example |
|---|---|---|
| Directories | lowercase; plural for collections, as in the full tree of [02-directory-structure.md](02-directory-structure.md) §2.1 | `decisions/`, `knowledge/integrations/` |
| Singleton docs | `UPPERCASE.md` | `INDEX.md`, `CURRENT.md`, `RULES.md` |
| ID docs | exactly `<ID>.md`; no slug | `ADR-007.md`, `INT-WI200.md` |
| Handoff files | `<work item ID>.md` | `handoff/TASK-042.md`, `handoff/GH-123.md` with an external tracker |
| Templates | `UPPERCASE.md` named after the record kind | `templates/TASK.md` |
| Checker | `tools/mkb-check.sh` | - |
| Case | never two names differing only in case | - |

Note: because the file name is the whole ID, two records created with the same number are the same path and conflict loudly (§4.4); a slug such as `ADR-007-use-redis.md` would let them coexist silently.

Tool-named instruction files are forbidden under `docs/mkb/` ([02-directory-structure.md](02-directory-structure.md) §2.5).

## 4.3 Allocating numbered IDs

The next number is 1 + the highest number ever added on any fetched ref, not the highest number in your working tree.

1. `git fetch --all --quiet` (skip with no remote).
2. List every file ever added under the record directory on any ref:
   - Tasks: `git log --all --diff-filter=A --name-only --format= -- docs/mkb/tasks`
   - ADRs: `git log --all --diff-filter=A --name-only --format= -- docs/mkb/decisions` (or the ADR directory adopted in place, [13-adoption-and-integration.md](13-adoption-and-integration.md) §13.4)
   - Questions: `git log --all --diff-filter=A --name-only --format= -- docs/mkb/questions`
3. Also consider files you created but have not committed.
4. Next ID = highest number found + 1, zero-padded to at least 3 digits (in an adopted ADR directory: padded to the width of its existing numbers, for example `ADR-0008`).
5. Equivalent: `sh docs/mkb/tools/mkb-check.sh next TASK` (or `ADR`, `Q`; add `--adr-dir <dir>` for an adopted ADR directory).
6. Tasks and questions: create the file from its template and push it to the default branch at once as a coordination commit (`TASK-NNN: add`, `Q-NNN: ask <owner>`; recipe in [12-concurrency.md](12-concurrency.md) §12.2), before anything refers to the ID, including follow-ups found during work.
   The push is a compare-and-swap: a rejected push followed by an add/add conflict when you rebase the coordination worktree means someone took that number; `git rebase --abort`, allocate again from step 1, and retry.
   Protected default branch: the file goes in a one-file `mkb-coord` PR ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4.2 step 5).
   ADRs: create the file on your work branch (it stays `proposed` there, [07-decisions.md](07-decisions.md) §7.4) and push the branch soon.
7. Dispatched agents that cannot push to the default branch never allocate TASK or Q IDs: they write `New task: <title>` or `Question for <handle>: <question>` in their `MKB for humans:` lines ([05-agent-workflow.md](05-agent-workflow.md) §5.8), and the dispatching human creates the records.

POSIX sh pipeline; it prints the next ID, `TASK-001` when none exists:

```sh
git fetch --all --quiet
git log --all --diff-filter=A --name-only --format= -- docs/mkb/tasks \
  | grep -oE 'TASK-[0-9]+' | awk -F- '$2+0 > n { n = $2+0 } END { printf "TASK-%03d\n", n+1 }'
```

PowerShell equivalent of the task pipeline:

```powershell
git fetch --all --quiet
$max = (git log --all --diff-filter=A --name-only --format= -- docs/mkb/tasks |
  Select-String -Pattern 'TASK-(\d+)' -AllMatches |
  ForEach-Object { $_.Matches } | ForEach-Object { [int]$_.Groups[1].Value } |
  Measure-Object -Maximum).Maximum
'TASK-{0:D3}' -f ($max + 1)
```

For questions, replace `tasks` and `TASK` with `questions` and `Q`; for ADRs in `docs/mkb/decisions`, with `decisions` and `ADR`.

Adopted ADR directory (sh; prints the next ID at the directory's width; `mkb-check.sh next ADR --adr-dir docs/adr` does the same, also from PowerShell through Git Bash, [09-lifecycle.md](09-lifecycle.md) §9.7):

```sh
git log --all --diff-filter=A --name-only --format= -- docs/adr | sed 's|.*/||' \
  | grep -oE '^[0-9]+' | awk '$1+0 > n { n = $1+0 } { w = length($1) } END { f = "ADR-%0" w "d\n"; printf f, n+1 }'
```

Numbers are never reused, including numbers of deleted questions and archived tasks.
Gaps are normal.

Note: step 6 makes a new TASK or Q number visible to every actor before anything refers to it, so a second creator of the same number fails at its own push while nothing depends on that number yet.

Example: in TareLog session S2, claude-code's allocation scan found `TASK-004` as the highest task and it committed `TASK-005: add` in its coordination worktree.
Its push was rejected because marta had pushed her own TASK-005 a minute earlier; the rebase stopped with `CONFLICT (add/add): Merge conflict in docs/mkb/tasks/TASK-005.md`.
It ran `git rebase --abort`, allocated again, and pushed `TASK-006: add`; nothing referred to TASK-005 yet, so no renumber and no `formerly` were needed.

## 4.4 Collisions and renumbering

Detection: two branches that add the same `<ID>.md` get an add/add conflict on rebase, merge or PR ("This branch has conflicts").
For tasks and questions this normally happens in the coordination worktree at creation time, where the fix is to take the next number (§4.3 step 6).
This section covers IDs that already live on a branch when the collision shows: ADRs, and IDs in `mkb-coord` PRs under a protected default branch.
Residual cases that git cannot see (an item created on a branch while another item with the same number was already archived, or an adopted ADR directory) are caught by `mkb-check.sh` error E1 ([09-lifecycle.md](09-lifecycle.md) §9.7) and by the duplicate-number one-liner of [13-adoption-and-integration.md](13-adoption-and-integration.md) §13.4.

Rule: the branch that merges second renumbers its own item.
The item on the default branch never changes.

Procedure:
1. Stop the rebase or merge: `git rebase --abort` (or `git merge --abort`).
   This avoids the reversed meaning of "ours" and "theirs" during a rebase.
2. Allocate the next free ID (§4.3) after fetching.
3. `git mv <dir>/<OLD-ID>.md <dir>/<NEW-ID>.md`, set `id: <NEW-ID>`, add `formerly: <OLD-ID>`.
4. Run `git diff origin/main...HEAD` and, only in lines your branch added that refer to your item, replace the old ID with the new one: other MKB files, code comments that cite it, and your handoff file name if the renumbered item is your own work item.
5. Leave every pre-existing line that refers to the default branch's item untouched.
6. Commit `mkb: renumber <OLD-ID> -> <NEW-ID> (ID collision)`, then run `git merge origin/main`, not a rebase: a rebase replays the commit that added `<OLD-ID>.md` and conflicts again, while a merge compares trees and sees no conflict.
   From then on this branch takes the default branch by merge (exception to [12-concurrency.md](12-concurrency.md) §12.1).
   Push, and write "Renumbered <OLD-ID> -> <NEW-ID> (collision)" in the PR description.
7. Already pushed commit messages keep the old ID; `formerly` lets `git grep -w <OLD-ID>` find both records.

Example: a branch whose proposed ADR-007 collides with an ADR-007 merged first ends with this front matter in `docs/mkb/decisions/ADR-008.md`:

```yaml
---
id: ADR-008
type: adr
status: proposed
date: 2026-09-20
formerly: ADR-007
---
```

Knowledge-name collision (two branches both created `INT-HAULER-SFTP.md`): both documented the same thing; merge the content into one doc by hand; keep the older `verified` unless you re-checked the merged doc against the merged code ([12-concurrency.md](12-concurrency.md) §12.6).

## 4.5 Knowledge names

Knowledge IDs are at most 40 characters, ASCII, singular, 1 to 3 words after the prefix, named after a stable noun from the code or the vendor (the component, device or symptom), never after a task.
The first character after a knowledge prefix is a letter, so tracker keys like `INT-45` are never mistaken for knowledge IDs.
The prefix fixes the directory (§4.1); which subject each prefix documents is in the per-file table of [02-directory-structure.md](02-directory-structure.md) §2.3.

Example (TareLog):

| ID | Named after |
|---|---|
| `SERVICE-GATEWAY` | the reader service in `src/tarelog/gateway/` |
| `MODULE-REPORTS` | the module `src/tarelog/reports/` |
| `DB-TICKETS` | the ticket store |
| `INT-WI200` | the WI-200 weighing indicator, the device model |
| `INT-HAULER-SFTP` | the haulage customer's SFTP interface |
| `TS-SQLITE-LOCKED` | the symptom |

Example of names to avoid: `MODULE-TASK-002` (named after a task), `INT-NEW-DELIVERY` (not a stable noun), `TS-READINGS-LOST-ON-LANE-2` (more than 3 words).

Note: a noun taken from the code keeps the code's spelling, as `MODULE-REPORTS` does for `src/tarelog/reports/`.

Search for an existing doc before creating one ([05-agent-workflow.md](05-agent-workflow.md) §5.5).
Splitting a doc into narrower IDs and renaming a doc (only during gardening, with `formerly`) follow [09-lifecycle.md](09-lifecycle.md) §9.3.
Two branches that create the same knowledge ID: §4.4.

## 4.6 Branches, commits and PRs

| Thing | Pattern | Example |
|---|---|---|
| Task branch | `<actor>/task-nnn-<slug>`; `<actor>` is the handle; `task-nnn` is the lowercase task ID; slug is lowercase kebab of 1 to 5 words, `[a-z0-9]+(-[a-z0-9]+){0,4}` | `claude-code/task-042-csv-export` |
| Tool-forced branch names | allowed; the real name is recorded in `branch:` | `codex/sftp-delivery-7f3a` |
| MKB-only branch | `<actor>/mkb-<slug>` | `claude-code/mkb-q-001-promote` |
| Gardening branch | `<actor>/mkb-garden-YYYY-MM-DD`, merged the same day | `claude-code/mkb-garden-2026-09-22` |
| Adoption branch | `<actor>/mkb-adopt` | `marta/mkb-adopt` |
| Branch names are lowercase | always (case-insensitive ref storage on Windows and macOS) | - |
| Commit subject with a task | `TASK-NNN: <imperative summary>` | `TASK-042: add CSV export` |
| Conventional Commits projects | the ID MUST appear in the subject, for example at the end in brackets | `feat(reports): add CSV export [TASK-042]` |
| New task (coordination commit at allocation, §4.3 step 6) | `TASK-NNN: add` | `TASK-006: add` |
| Claim | `TASK-NNN: claim` or, for a dispatched agent, `TASK-NNN: claim for <handle>` | `TASK-003: claim for codex` |
| Release | `TASK-NNN: release` | `TASK-004: release` |
| Block / unblock | `TASK-NNN: blocked on <IDs>` / `TASK-NNN: unblocked` | `TASK-004: blocked on Q-001` |
| Done, trunk-based only ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.6) | `TASK-NNN: done` | - |
| New question | `Q-NNN: ask <owner>` | `Q-001: ask marta` |
| Answer (the owner writes `## Answer` and sets `status: answered`) | `Q-NNN: answer` | `Q-001: answer` |
| Question resolved | `Q-NNN: resolved -> <destination IDs>` | `Q-001: resolved -> ADR-003, INT-HAULER-SFTP, TASK-004` |
| ADR decision | `ADR-NNN: accept` / `ADR-NNN: reject` | `ADR-002: accept` |
| MKB-only change | `mkb: <summary>` | `mkb: add INT-WI200 checksum rule`, `mkb: update NEXT` |
| Gardening | `mkb: gardening YYYY-MM-DD` | - |
| Archive | `mkb: archive closed tasks` | - |
| Renumber | `mkb: renumber <OLD-ID> -> <NEW-ID> (ID collision)` | `mkb: renumber ADR-007 -> ADR-008 (ID collision)` |
| Adoption | `mkb: adopt MKB v1.0 (<profile> profile)` | - |
| PR title | starts with the work item ID when there is one | `TASK-042: CSV export` |

Parallel sessions of the same tool share its handle as `<actor>`; the `branch` field of the task tells them apart ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4.1 step 7).
One work item has one branch and one writer ([12-concurrency.md](12-concurrency.md) §12.1).
MKB changes go in the same commit or PR as the code they describe ([05-agent-workflow.md](05-agent-workflow.md) §5.5).

## 4.7 Dates and handles in text

- Dates everywhere are `YYYY-MM-DD`.
- No times, no time zones, no locale formats.
- Dated one-liners (state bullets, task Notes, Completion first line, question Answer, STALE banner) use the form `YYYY-MM-DD <handle>: <text>`.
- Prose may write `@marta`; fixed formats use the bare handle.

The handle pattern and the reserved agent handles are defined in [03-metadata.md](03-metadata.md) §3.4; front matter never writes `@` ([03-metadata.md](03-metadata.md) §3.2).

Example (TareLog; a state bullet, a task Notes line, a question answer):

```markdown
- 2026-09-17 marta: Production weighbridge PC runs v0.9.0; CSV reports reach Beta Haulage by 06:00 (TASK-004, TASK-007).
- 2026-09-15 luca: released; partial work on branch codex/task-004-sftp-delivery, see its handoff
2026-09-10 marta: Key authentication only; they also said their ERP imports CSV only, so PDF is not needed.
```

## 4.8 Linking conventions

| Target | Form | Example |
|---|---|---|
| Any MKB record with an ID (task, ADR, question, knowledge) | Bare ID, never a Markdown link, in prose, lists, tables and front matter | `Blocked by Q-001; see ADR-003 and INT-HAULER-SFTP.` |
| An MKB doc without an ID (INDEX, RULES, project/*, state/*) from inside `docs/mkb/` | Relative Markdown link whose text is the path relative to `docs/mkb/` | `[project/CONSTRAINTS.md](../../project/CONSTRAINTS.md)` |
| A section of a doc | Name the section in words after the link or path; never a `#anchor` link | `[project/CONSTRAINTS.md](../project/CONSTRAINTS.md), section Security and data` |
| Code | Backticked repo-root-relative path, optionally followed by the symbol in backticks; never line numbers in durable docs | `` `src/tarelog/gateway/wi200.py` (`parse_frame()`) `` |
| Files outside `docs/mkb/` (README, CONTRIBUTING, config) | Backticked repo-root-relative path, never a Markdown link | `` `README.md` (Installation) `` |
| MKB paths from root files (AGENTS.md, CLAUDE.md) | Backticked repo-root-relative path | `` `docs/mkb/agents/RULES.md` `` |
| External resource | Markdown link with descriptive text; never a URL carrying a token or credentials; volatile vendor pages MAY add `(checked YYYY-MM-DD)` | `[WI-200 protocol manual, section 4.2](https://example.com/wi200-manual.pdf)` |
| GitHub issue / PR / commit | `GH-123`, `PR #14`, short SHA of at least 7 characters | `done in PR #14 (4be1c2a)` |
| Other trackers | the tracker's native key | `OPS-45` |

In short: an ID when the target has one; a relative link for an MKB doc without an ID; a backticked path for anything else in the repository; a Markdown link only for resources outside the repository.
References from code and git are in §4.9.

Additional rules:
- Inside INDEX.md the Routing and Authority sections name MKB paths as plain text (for example `project/OVERVIEW.md` without backticks or link), because the Layout table already links them.
- Line numbers are allowed only in handoff files.
- A durable doc (knowledge, ADR, project, state) never refers to a handoff file.
- Markdown links MUST point to files that exist in the same tree; templates contain no relative links.
- Why IDs are never linked: the file name is the ID, so `git grep -w`, `find -name "<ID>.md"` and a forge's file finder (type the ID) resolve it in one step, and bare IDs survive archiving and directory moves.

Example: relative links as the skeletons write them.

| From | Link |
|---|---|
| `docs/mkb/INDEX.md` | `[state/CURRENT.md](state/CURRENT.md)` |
| `docs/mkb/state/NEXT.md` | `[INDEX.md](../INDEX.md)` |
| `docs/mkb/decisions/ADR-003.md` | `[project/CONSTRAINTS.md](../project/CONSTRAINTS.md), section Security and data` |
| `docs/mkb/knowledge/integrations/INT-WI200.md` | `[project/CONSTRAINTS.md](../../project/CONSTRAINTS.md)` |

## 4.9 Referencing the MKB from code and git

| Target | Form | Example |
|---|---|---|
| MKB from code | ID in a comment where code embodies a non-obvious decision or pending work | `# Half-up rounding per ADR-004.` / `# TODO(TASK-006): buffer readings while the DB is locked.` |
| MKB from git | ID at the start of the commit subject, in the branch name and in the PR title | `TASK-042: add CSV export` |

From code:
- A new TASK or Q ID is on the default branch before any code comment refers to it (§4.3 step 6).
- Code that embodies a non-obvious decision SHOULD cite the ADR ID in a comment ([07-decisions.md](07-decisions.md) §7.7); code comments citing a superseded ADR are updated when that code is next touched ([07-decisions.md](07-decisions.md) §7.6).

Example: in TareLog session S2, claude-code wrote `# TODO(TASK-006): buffer readings while the DB is locked.` in `src/tarelog/gateway/reader.py` only after `TASK-006: add` was on `main`.

From git:
- Commit subjects, branch names and PR titles follow §4.6, so every change to a work item can be found by its ID.
- The lowercase task ID in the branch name lets `git branch -r` show which branches exist for a task ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4.2 step 1).
- After a renumber, already pushed commit messages keep the old ID (§4.4 step 7).

Everything about one ID (plain git commands; they work in sh and PowerShell):

```sh
git grep -n -w "TASK-042" -- docs/mkb
git grep -n -w "TASK-042"
git log --oneline --grep "TASK-042"
git log --all -- '*TASK-042.md'
```

The first command lists every MKB mention, the second adds code, the third lists commits whose message cites the ID, and the fourth shows the history of the record file, also after it was deleted or archived.
