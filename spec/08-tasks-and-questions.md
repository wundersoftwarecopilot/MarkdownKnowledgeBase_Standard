# 8. Tasks and questions

*MKB Standard v1.0 · 2026-09-23 · Normative*

This chapter defines tasks (one file per work item), claims, blockers, questions for people, the two state files and the use of an external issue tracker.
Task and question IDs are allocated as in [04-naming-and-linking.md](04-naming-and-linking.md) §4.3, and their commit subjects are listed in §4.6 of that chapter; the front matter schemas are in [03-metadata.md](03-metadata.md) §3.5.
Coordination commits, which go straight to the default branch, are defined in [12-concurrency.md](12-concurrency.md) §12.2.
Trigger rows `T<n>` are those of the update-trigger matrix in [05-agent-workflow.md](05-agent-workflow.md) §5.6; check codes `W<n>` are the `mkb-check.sh` warnings of [09-lifecycle.md](09-lifecycle.md) §9.7.
Examples use the fictional TareLog project of [examples/tarelog/WALKTHROUGH.md](../examples/tarelog/WALKTHROUGH.md).

## 8.1 When to create a task

- REQUIRED when the work will not be finished within the current session (at the latest when a session ends unfinished, T2), when it will be handed to or dispatched to another actor, or when it is discovered and deferred.
- NOT needed for work you finish in the current session (committed, and a PR opened where the project uses PRs); the commit or PR is the record.
- Size: one mergeable unit of roughly 1 to 3 sessions; larger work is split into several tasks; no subtasks, no epics.
- Every new task, including follow-ups found during work, is created on the default branch at once as a coordination commit `TASK-NNN: add` ([04-naming-and-linking.md](04-naming-and-linking.md) §4.3, step 6), so its number is visible before anything refers to it.
  Dispatched agents that cannot push to the default branch write `New task: <title>` in their `MKB for humans:` lines instead ([05-agent-workflow.md](05-agent-workflow.md) §5.8).

A task for every 10-minute fix is anti-pattern 33 of [10-anti-patterns.md](10-anti-patterns.md).

Example: TareLog created TASK-001 to TASK-004 at adoption.
While working on TASK-002, claude-code found that readings are lost while the report job holds the SQLite lock; it pushed TASK-006 at once and only then wrote `# TODO(TASK-006): buffer readings while the DB is locked.` in the code.
Codex cloud, which cannot push to `main`, reported a time-zone problem as `New task: Per-customer report time zone`; marta created TASK-005 from that line.

## 8.2 Task format

A task is the file `docs/mkb/tasks/TASK-NNN.md`, created from the skeleton `docs/mkb/templates/TASK.md` below, at most 60 lines.

```markdown
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
<!-- guide: 1-3 sentences: what and why; add "Out of scope: ..." when useful. -->

## Acceptance criteria
- [ ] <observable, checkable outcome>

## Notes
<!-- guide: optional dated one-liners "- YYYY-MM-DD <handle>: <text>", append-only, anyone may add; not a diary. -->

## Completion
<!-- guide: filled when done or dropped: "- YYYY-MM-DD <handle>: done in PR #N" (trunk-based: "done in <short SHA>"; or "dropped: <reason>, decided by <human>"), then "- Shipped:", "- Docs:", "- Follow-ups:", "- Deviations:". -->
```

Rules for this skeleton: the `## Notes` and `## Completion` headings always stay, even when empty.
Keys added later, template order preferred (not checked): `branch` after `owner`; `closed` after `created`; `blocked_by` after `closed`; `formerly` last.
Which keys each status requires or forbids (for example `branch` when `in-progress`, `closed` when `done` or `dropped`) is defined in [03-metadata.md](03-metadata.md) §3.5.

The elements a task needs map as follows: unique ID `id`; status `status`; priority `priority`; owner `owner`; description `## Goal`; acceptance criteria `## Acceptance criteria`; related files and components `code` and `related`; related decisions `related`; completion notes `## Completion`.

Completion first line: `- YYYY-MM-DD <handle>: done in PR #N` (trunk-based: `done in <short SHA>`, naming the last code commit; the done edit itself is the follow-up commit of §8.6), then `- Shipped: ...`, `- Docs: <IDs created or updated>`, `- Follow-ups: <IDs or none>`, `- Deviations: <from acceptance criteria, or none>`.
Notes lines: `- YYYY-MM-DD <handle>: <text>`, append-only, anyone may add one to any task.

Example: the Completion section of TareLog's TASK-002.

```markdown
## Completion
- 2026-09-03 claude-code: done in PR #12
- Shipped: `src/tarelog/gateway/wi200.py` (`parse_frame()`) with one byte buffer per lane, used by `src/tarelog/gateway/reader.py`; captures from both lanes as fixtures.
- Docs: INT-WI200 (new), SERVICE-GATEWAY
- Follow-ups: TASK-006
- Deviations: none
```

## 8.3 Status model and edit rights

| From | To | Who | Where |
|---|---|---|---|
| (new) | `todo` | anyone | coordination commit `TASK-NNN: add` ([04-naming-and-linking.md](04-naming-and-linking.md) §4.3, step 6) |
| (new) | `in-progress` | the creator, at session end with no task yet (T2) | coordination commit `TASK-NNN: add` with `owner` and `branch` already set ([04-naming-and-linking.md](04-naming-and-linking.md) §4.3, step 6) |
| `todo` | `in-progress` | the claimer (or a human for a dispatched agent) | coordination (claim, §8.4) |
| `todo` | `blocked` | anyone, for an unowned task; the lead | coordination |
| `in-progress` | `blocked` | the owner | coordination |
| `blocked` | `in-progress` if `branch` is set, otherwise `todo` (owner unchanged) | the owner, or whoever resolved the blocker (§8.11) | coordination, or the promotion PR (§8.11 step 3) |
| `in-progress` | `todo` | the owner (release), or the gardener for a stale agent claim | coordination |
| `in-progress` | `done` | the owner | the delivering PR |
| any open status | `dropped` | the owner or lead, after a human decision | PR or coordination |
| `done`, `dropped` | - | terminal; reopening means a new task that cites the old ID | - |

Edit rights: only the owner edits a claimed task; anyone may append a Notes line; anyone may edit a task whose owner is `none`; the lead may edit any task; whoever promotes an answer (§8.11) may edit the Goal and Acceptance criteria of the tasks the question blocks, marking each changed line `(resolves Q-NNN)`, and may remove `blocked_by` and set `status` as in T8.

The meaning of each status is in [03-metadata.md](03-metadata.md) §3.4.2.

Example: TareLog's TASK-004 went `todo` (adoption, 2026-09-01) -> `in-progress` (claimed by codex, 2026-09-08) -> `blocked` (Q-001, 2026-09-08) -> `in-progress` (Q-001 resolved in PR #14 while `branch` was set, 2026-09-10) -> `todo` (released by codex, 2026-09-15) -> `in-progress` (claimed by claude-code, 2026-09-16) -> `done` (PR #15, 2026-09-16).

## 8.4 Claiming protocol

A claim sets `status: in-progress`, `owner` and `branch` on the task so that others see the work is taken before anyone writes code.
Use §8.4.1 when you may push directly to the default branch, §8.4.2 when the default branch is protected, and §8.4.3 when the repository has no remote.
A claim visible to others before coding is a MUST in the full profile and a SHOULD in the minimal profile ([11-profiles.md](11-profiles.md) §11.4).

### 8.4.1 Direct push to the default branch allowed

1. `git fetch origin`.
2. `git show origin/main:docs/mkb/tasks/TASK-NNN.md | head -n 16` MUST show `status: todo` with `owner: none` or your handle.
   PowerShell: `git show origin/main:docs/mkb/tasks/TASK-NNN.md | Select-Object -First 16`.
   Never judge by your local copy.
   Otherwise (`blocked`, or claimed by another actor or session), do not claim the task or code on it: tell the human, naming its `blocked_by` or `owner`.
3. Make the claim as a coordination commit in a temporary worktree of `origin/main`, or, for a human, in a clean `main` (both in [12-concurrency.md](12-concurrency.md) §12.2.1), never on a work branch.
   The recipe fetches again, so first repeat the step-2 check on `docs/mkb/tasks/TASK-NNN.md` in the worktree where you commit; if it no longer shows `status: todo` with `owner: none` or your handle, the task was claimed since step 2: remove the temporary worktree and pick another task.
   Then set `status: in-progress`, `owner: <you>`, `branch: <you>/task-nnn-<slug>`, and `code` with the paths you expect to touch (SHOULD, so that others' overlap checks see them, [05-agent-workflow.md](05-agent-workflow.md) §5.3); commit `TASK-NNN: claim`; `git push origin HEAD:main`.
4. Push rejected: fetch.
   If `git rev-list --count HEAD..origin/main` prints `0`, nobody pushed first and the server refuses direct pushes (`! [remote rejected]`): the default branch is protected; do not retry; remove the temporary worktree (on `main`: `git reset --keep origin/main`) and claim as in §8.4.2.
   Otherwise rebase the temporary worktree onto `origin/main` and push again.
   A conflict in `TASK-NNN.md` means someone else claimed it: `git rebase --abort`, remove the temporary worktree (on `main`: `git reset --keep origin/main`), pick another task.
   If after the rebase `git rev-list --count origin/main..HEAD` prints `0`, your claim commit was dropped because an identical claim (same handle, another session of your tool) is already there: the task is taken; pick another task.
   For a task you were given, "pick another task" in steps 3 and 4 means: do not code on it; tell the human, naming its `owner`.
5. Create your branch `<you>/task-nnn-<slug>` from the updated `origin/main` (in its own worktree when agents work in parallel locally) and push it at once.
   Takeover: if the task's Notes contain `released; partial work on branch <old-branch>`, read `git show origin/<old-branch>:docs/mkb/handoff/TASK-NNN.md`, create your branch from that tip instead (`git switch -c <you>/task-nnn-<slug> origin/<old-branch>`), rebase it onto `origin/main` (merge instead if `git log origin/main..HEAD` shows a `mkb: renumber` commit, [12-concurrency.md](12-concurrency.md) §12.1), push it, and verify the handoff against it; the handoff is now yours to overwrite; never push to the old branch.
6. Dispatched agents that cannot push to the default branch (for example Codex cloud and the GitHub Copilot cloud agent): the dispatching human makes the claim commit `TASK-NNN: claim for <handle>` before dispatch, with `branch: pending` if the tool names the branch later; the agent or the human replaces `pending` with the real name in the PR.
7. When a task is yours: `owner` is your handle, AND `branch` is the branch you were told to resume or are on, AND `git worktree list` does not show that branch checked out in another worktree.
   `branch: pending` is yours only if you are the dispatched session.
   A task with your handle that fails this test belongs to another session of your tool: pick another task or ask the human.
8. Minimal profile, one actor working on the default branch ([11-profiles.md](11-profiles.md) §11.4): the claim is the first commit of your work and SHOULD be pushed before you write code.
9. Cannot fetch or push (sandbox, network or permissions, [13-adoption-and-integration.md](13-adoption-and-integration.md) §13.5): stop before coding and ask the human to push the claim; never code on an unpushed claim.

Example: the diff of claude-code's coordination commit `TASK-002: claim` on 2026-09-02.

```diff
-status: todo
+status: in-progress
 priority: high
-owner: none
+owner: claude-code
+branch: claude-code/task-002-wi200-parser
 created: 2026-09-01
+code: [src/tarelog/gateway/]
```

Example: before dispatching TASK-003 to Codex cloud, marta made the commit `TASK-003: claim for codex` with `owner: codex` and `branch: pending`; the agent's PR replaced `pending` with `codex/task-003-daily-report`.

### 8.4.2 Protected default branch

1. `git fetch --prune origin`; without `--prune`, branches deleted on the remote, such as released claim branches, stay listed by `git branch -r`.
   The task must be `todo` on `origin/main`, and `git branch -r` must show no branch containing `/task-nnn-` other than branches named in the task's release Notes.
2. Create `<you>/task-nnn-<slug>`, commit the claim edit on it, push it immediately; the pushed branch name is the claim.
3. `git fetch --prune origin` again; if `git branch -r` now shows a branch containing `/task-nnn-` other than yours and those named in the task's release Notes, stop before coding and ask the lead; the lead gives the task to one actor, and the others delete their claim branches.
4. Dispatched agents whose tool names its own branch: before dispatch, the dispatching human pushes a claim branch `<agent handle>/task-nnn-<slug>` that holds only the claim commit (`TASK-NNN: claim for <handle>`); the tool's real branch is recorded in `branch:` inside the agent's PR; the human deletes the claim branch when that PR merges or the task is released.
5. The front-matter claim reaches the default branch with the PR.
   Other coordination changes, new tasks and questions included, use one-file PRs labelled `mkb-coord`, merged by the first human who sees them; an ID collision between two open `mkb-coord` PRs is fixed by renumbering the later one ([04-naming-and-linking.md](04-naming-and-linking.md) §4.4), which nothing refers to yet.

### 8.4.3 No remote

"origin/main" means local `main`; skip every fetch, pull and push, and the fast-forward to `origin/<your-branch>`; branch checks use `git branch`; coordination commits follow the no-remote variant of [12-concurrency.md](12-concurrency.md) §12.2.
Repositories without a remote are covered as a whole in [13-adoption-and-integration.md](13-adoption-and-integration.md) §13.7.

## 8.5 Release, stale claims and dropping

- Release (T4): `status: todo`, `owner: none`, remove `branch`, Notes line `- YYYY-MM-DD <handle>: released; partial work on branch <branch>, see its handoff`.
- Stale claim: `in-progress` with no commit on its branch for 7 days.
  Agent owner: the gardener or any human may release it.
  Human owner: ask them; after 14 days the lead decides.
- Stale dispatch: `in-progress` with `branch: pending` and no change to the task file on the default branch for 7 days (W6): the dispatched agent produced no PR; the dispatching human releases it.
- Drop: only after a human decision; Completion line `- YYYY-MM-DD <handle>: dropped: <reason>, decided by <human handle>`.

The handoff of a released task stays on the released branch for the next owner ([06-handoff.md](06-handoff.md) §6.5), who takes over as in §8.4.1 step 5.
`mkb-check.sh` reports stale claims and stale dispatches as W6; gardening never releases a human's claim ([09-lifecycle.md](09-lifecycle.md) §9.6).
Proposing a drop to a human is trigger T5.

Example: before luca left for a week, codex, the owner, made the coordination commit `TASK-004: release` from luca's Codex CLI, adding the Notes line `- 2026-09-15 codex: released; partial work on branch codex/task-004-sftp-delivery, see its handoff`.

## 8.6 Completion

Done: set in the delivering PR, so the default branch says `done` only after the work merges.
Trunk-based work: the done edit is a separate follow-up commit `TASK-NNN: done` right after the last code commit, whose short SHA the Completion line names (a commit cannot contain its own hash).
There is no `review` status: an open PR signals review.

The rest of finishing a task (ticking the criteria, `closed`, `## Completion`, moving lasting handoff lines, deleting the handoff) happens in the same PR: trigger T3; the Completion format is in §8.2.
Closed tasks are archived 30 days after `closed` and never deleted ([09-lifecycle.md](09-lifecycle.md) §9.2).

Example: TASK-004 got `status: done`, `closed: 2026-09-16` and its Completion section in PR #15, which delivered the SFTP upload; `main` said `in-progress` until marta merged the PR.

## 8.7 Blockers

- A blocked task has `status: blocked` and `blocked_by: [IDs]`, each a TASK or Q ID.
- An external impediment (vendor outage, missing access, hardware) becomes a task owned by the human who chases it, for example a task "Get the Beta Haulage SFTP test account reactivated" owned by `marta`.
- The reason lives in the blocking item; the blocked task adds a Notes line.
- Blocker list view: `git grep "^blocked_by:" origin/main -- docs/mkb/tasks`.
- A blocker whose items are all resolved is cleared at once (T8); gardening checks for forgotten ones (mkb-check W12).

Setting a block is trigger T6 (a question for a person) or T7 (other work or an external party); clearing it is T8.
A blocked task whose file has not changed for 14 days is W14 ([09-lifecycle.md](09-lifecycle.md) §9.4).
There is no blocker list file: status lives only in the task files (anti-pattern 9), and a blocker without an owner is anti-pattern 36.

Example: when claude-code opened Q-002 on 2026-09-17, the coordination commit `Q-002: ask marta` set the unowned TASK-005 to `status: blocked` with `blocked_by: [Q-002]` and added the Notes line `- 2026-09-17 claude-code: blocked on Q-002; the goal does not say where a customer's report day ends.`

## 8.8 Board views

Board views are queries, never committed files; they read `origin/main`, or `main` without a remote:

```sh
git grep -e "^status:" -e "^priority:" -e "^owner:" origin/main -- docs/mkb/tasks ':(exclude)docs/mkb/tasks/archive'
git grep -l "^status: todo" origin/main -- docs/mkb/tasks
git grep -l "^status: in-progress" origin/main -- docs/mkb/tasks
git grep "^blocked_by:" origin/main -- docs/mkb/tasks
git grep "^# TASK-" origin/main -- docs/mkb/tasks ':(exclude)docs/mkb/tasks/archive'
```

One line per open task (`<title> | <status> <priority> <owner>`), run in an up-to-date checkout of `main`:

```sh
awk '/^status:/{s=$2} /^priority:/{p=$2} /^owner:/{o=$2} /^# TASK-/{if (s!="done" && s!="dropped") print substr($0,3) " | " s " " p " " o; nextfile}' docs/mkb/tasks/TASK-*.md
```

```powershell
Get-ChildItem docs/mkb/tasks/TASK-*.md | ForEach-Object { $h = Get-Content $_ -TotalCount 16; $v = @{}; $h | Where-Object { $_ -match '^(status|priority|owner): (.+)$' } | ForEach-Object { $v[$Matches[1]] = $Matches[2] }; $t = ($h | Where-Object { $_ -like '# TASK-*' } | Select-Object -First 1).Substring(2); if ($v.status -notin 'done','dropped') { "$t | $($v.status) $($v.priority) $($v.owner)" } }
```

INDEX carries the same queries as Routing rows ([02-directory-structure.md](02-directory-structure.md) §2.4).
Committed boards and generated lists are anti-pattern 10.

## 8.9 Questions: when to ask

Ask only when an answer from a specific person or external party is needed and the decision is outside your authority.
If the decision is yours, make it (and write an ADR if [07-decisions.md](07-decisions.md) §7.1 applies).

Creating a question: file from the skeleton of §8.10, at most 40 lines; `owner` = the human who must answer (for an external party, the human who will get the answer); created at allocation as a coordination commit `Q-NNN: ask <owner>` ([04-naming-and-linking.md](04-naming-and-linking.md) §4.3, step 6) so the owner sees it on the default branch.
If it blocks a task, the same commit sets that task `blocked` with `blocked_by: [Q-NNN]` and adds a Notes line.
A push notifies nobody: the asker also lists the question under `Questions` in its `MKB for humans:` lines ([05-agent-workflow.md](05-agent-workflow.md) §5.8).
A dispatched agent that cannot push to the default branch writes `Question for <handle>: <question>` there instead, and the dispatching human creates the question file.

This is trigger T6.
An `open` question whose `created` is more than 14 days ago is W15: the owner is reminded and the lead escalates ([09-lifecycle.md](09-lifecycle.md) §9.4).

Example: on 2026-09-08 Codex, working on TASK-004 through luca's CLI, found that the customer specification mentions both key and password authentication.
It created Q-001 "Does the Beta Haulage SFTP server require key authentication or password authentication?" with `owner: marta`, and set TASK-004 `blocked` with `blocked_by: [Q-001]` and a Notes line, in one coordination commit `Q-001: ask marta`.
Its final message ended with the lines `MKB for humans:` and `Questions: Q-001 (marta)`.

## 8.10 Question format

A question is the file `docs/mkb/questions/Q-NNN.md`, created from the skeleton `docs/mkb/templates/QUESTION.md`:

```markdown
---
id: Q-NNN
type: question
status: open
owner: <human handle who must answer>
asked_by: <handle>
created: YYYY-MM-DD
related: [<ID>]
---
# Q-NNN: <the question, ending with a question mark>

## Context
<!-- guide: why it matters and which work waits for it (IDs), 2-5 lines. -->

## Options
<!-- guide: optional; "- A: <option>" per line; mark the asker's recommendation with "(recommended)". -->

## Answer
<!-- guide: left empty by the asker; the answerer writes "YYYY-MM-DD <handle>: <answer>" and sets status: answered. -->
```

The question's `owner` is always a human handle ([03-metadata.md](03-metadata.md) §3.4.4).
There is deliberately no `blocks` key: the blocked task's `blocked_by` is the single source ([03-metadata.md](03-metadata.md) §3.5).

## 8.11 Resolution flow

1. The owner (or an agent relaying an answer given in chat or a PR comment, quoting it verbatim with attribution `YYYY-MM-DD <handle> (via chat): ...`) writes the answer under `## Answer` and sets `status: answered`, as a coordination commit `Q-NNN: answer`.
2. The next session that touches the question, or the answerer, promotes the answer to its permanent home and writes `(resolves Q-NNN)` there (a new ADR cites Q-NNN in its Context instead):

   | The answer... | Goes to |
   |---|---|
   | decides between alternatives with lasting effect | a new ADR (its Context cites Q-NNN) |
   | is a fact about an external system | an `INT-` doc |
   | is a fact about the code or domain | a knowledge doc, or project/OVERVIEW.md Glossary |
   | is an external non-negotiable rule | project/CONSTRAINTS.md (a human writes it or states it in the session) |
   | scopes or changes a task | that task's Goal or Acceptance criteria, each changed line marked `(resolves Q-NNN)` (§8.3 lets the promoter edit them) |
   | makes the question moot | nowhere; say so in the commit message |

3. In the same commit (`Q-NNN: resolved -> <destination IDs>`): delete the question file; remove the ID from every `blocked_by`; set those tasks back to `in-progress` if `branch` is set, otherwise `todo` (owner unchanged).
   This is a coordination commit, except when the promotion creates an ADR: then the resolution rides an `<actor>/mkb-<slug>` PR, because the ADR needs a human decision before merge ([07-decisions.md](07-decisions.md) §7.4), and the question and the blocked tasks stay as they are on the default branch until that PR merges.
4. There is no RESOLVED file: `git grep -w Q-NNN` finds where the answer lives; git keeps the question.

An `answered` question is W7: promote it now.
Getting an answer or seeing a blocker resolved is trigger T8.

Example: on 2026-09-10 marta answered Q-001 in the coordination commit `Q-001: answer`.

```markdown
## Answer
2026-09-10 marta: Key authentication only; they also said their ERP imports CSV only, so PDF is not needed.
```

The answer decides between alternatives with lasting effect and states facts about an external system, so claude-code promoted it in PR #14 from the branch `claude-code/mkb-q-001-promote`: ADR-003, whose Context cites Q-001; INT-HAULER-SFTP; and the acceptance criteria of TASK-004, each changed line marked `(resolves Q-001)`.
The same commit, `Q-001: resolved -> ADR-003, INT-HAULER-SFTP, TASK-004`, deleted Q-001, removed `blocked_by` from TASK-004 and set it back to `in-progress`, because its `branch` was set.

## 8.12 State files: CURRENT and NEXT

### 8.12.1 Current state

`docs/mkb/state/CURRENT.md`:

- Describes the default branch and deployments, never branch progress or finished work.
- Sections Health, Focus, Warnings; every bullet `- YYYY-MM-DD <handle>: <fact> (<IDs>)`.
- Health: exceptions and deployments only: the default branch is red, known broken functionality, deployed version per environment.
  Never "CI green": the forge already shows it, and it would need re-dating forever.
  Warnings: what every session must know now.
  Focus: 1 to 3 bullets written by the lead.
- Edited only when a project-level fact changes: in the PR that changes it, or as a coordination commit for facts that change outside a PR (deployments, outages, freezes).
- Re-date a bullet when you re-verify it; delete it when it stops being true; bullets older than the W5 threshold (14 days in the full profile, 35 days in the minimal profile, one gardening interval plus slack) are re-verified or deleted at gardening.
- Micro-gardening: if you know a bullet is false, fix it in the commit where you notice it.

A changed project-level fact is trigger T18.

### 8.12.2 Next queue

`docs/mkb/state/NEXT.md`:

- Ordered list of at most 10 entries `- <ID>: <why now, at most 10 words>`, highest first, `-` bullets (not numbers, so reordering does not renumber).
- Written only by the lead, or by an agent when a human asks in the session.
- Readers take the first ID in `state/NEXT.md` whose task on the default branch is `todo` with `owner: none` or you, and skip the others; the lead prunes finished entries (W13).

An agent whose work changes what should happen next writes a `NEXT suggestion:` line instead (trigger T21, [05-agent-workflow.md](05-agent-workflow.md) §5.8).

Example: TareLog's state files on `main` after the gardening of 2026-09-22, which deleted a 2026-09-04 Health bullet that still described PDF reports (W5).
The sections of `state/CURRENT.md`:

```markdown
## Health
- 2026-09-17 marta: Production weighbridge PC runs v0.9.0; CSV reports reach Beta Haulage by 06:00 (TASK-004, TASK-007).

## Focus
- 2026-09-17 marta: Reliable readings on both lanes before the October peak (TASK-006).

## Warnings
- 2026-09-22 claude-code: Nightly backup (TASK-001) is not running yet; copy `data/tarelog.db` by hand before any migration.
```

The entries of `state/NEXT.md`; a reader takes TASK-006, whose task is `todo` with `owner: none`, while TASK-005 waits in the queue until Q-002 is answered:

```markdown
- TASK-006: readings lost while the report job holds the database
- TASK-005: after Q-002 is answered
```

## 8.13 Using an external issue tracker

If the team's tasks already live in GitHub Issues, Jira or similar, that tracker is authoritative: `tasks/` is not used; work item IDs are the tracker keys (`GH-123`); handoffs are `handoff/GH-123.md`; claims are the tracker's assignee; `state/NEXT.md` lists tracker keys; INDEX gets a path override row `| tasks | <tracker URL> | tracker is authoritative; no tasks/ |`.
Questions, ADRs, knowledge and state stay in the MKB.

The INDEX Layout and Routing rows that change with this override are listed in [02-directory-structure.md](02-directory-structure.md) §2.4; adoption with a tracker is covered in [13-adoption-and-integration.md](13-adoption-and-integration.md) §13.6.
MKB tasks that mirror the tracker are anti-pattern 33 (two task systems).
