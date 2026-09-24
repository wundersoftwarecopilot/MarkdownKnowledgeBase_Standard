---
type: rules
mkb_version: "1.0"
---
# MKB rules

Standard text of MKB Standard v1.0.
Do not edit above section 16, "Project-specific rules", which holds the project's own additions; the text above it is replaced when the MKB version is upgraded.
Commands write the default branch as `main`; a project whose default branch has another name uses that name.

## 1. Session workflow
Humans follow the same rules; the only differences are that a human writes a handoff only when someone else will continue the work, and may make coordination commits in a clean `main` instead of a temporary worktree (section 11).
After working, walk every row of the trigger matrix (section 3), update only the rows that fire, and end with the `MKB for humans:` lines below.
### Before modifying code
1. Update and read: `git fetch`, then `git merge --ff-only origin/<your-branch>` (it takes in commits a reviewer added, section 11), then rebase your branch onto `origin/main` (on `main` itself: `git pull --rebase`; a branch with a `mkb: renumber` commit merges instead, section 11), so that you see the claims, answers and docs that landed since your branch was cut; `docs/mkb/INDEX.md` (skip if already read in this session); `docs/mkb/state/CURRENT.md`; `docs/mkb/state/NEXT.md`, only if you must choose a task.
2. Know your work item: the task you were given, else the `in-progress` task whose `branch` you are on, if it is yours (section 5, claim step 7), else the first ID in `state/NEXT.md` whose task on the default branch is `todo` with `owner: none` or you, else ask the human. No task exists and the work will outlast this session, or will be handed to someone else: create one from `templates/TASK.md` (section 5; a coordination commit, section 4, allocation step 6). Work you will finish in this session needs no task (if it ends unfinished after all, T2 creates one).
3. Read the task file. If its Notes say `released; partial work on branch <branch>`, read the handoff on that branch and take over from it (section 5, claim step 5); otherwise read `handoff/TASK-NNN.md` on the task's branch if it exists. Verify its "Where it stands" against `git log` and `git status` before trusting it.
4. Claim before touching code (section 5), unless the task is already yours (section 5, claim step 7).
5. Run the discovery algorithm (section 2).
6. If `state/CURRENT.md` has a bullet older than the W5 threshold (14 days in the full profile, 35 in the minimal profile), or `docs/mkb/handoff/` on the default branch holds a file whose task is `done`, `dropped` or missing (W4), add `Gardening due` to your `MKB for humans:` lines; do not garden unasked, except micro-fixes (section 13).
### While working
1. Constraints and accepted ADRs bind you. To deviate, write a `proposed` ADR or open a question; never edit an accepted ADR; never decide an ADR's status on your own authority: write `accepted` or `rejected` only to record a decision a named human makes in this session, and list them in `deciders` (section 8).
2. Record a discovery when you make it, not at the end of the session, in its home doc (section 3), linked by bare ID, never copied. The knowledge threshold and where to write it: section 9.
3. A decision meeting the criteria of section 8 becomes a `proposed` ADR on your branch.
4. Work found outside your task's scope becomes a new task (`todo`, `owner: none`), pushed to the default branch at once (section 4, allocation step 6); do not widen your task.
5. Commit subjects start with the task ID; MKB changes go in the same commit or PR as the code they describe.
6. Re-read an MKB file from disk right before editing it and patch only the lines you mean to change (section 11).
7. Never put secrets, credential values, personal data of customers or patients, logs longer than 5 lines, stack traces, diffs or chat transcripts in the MKB.
### Lite path
The lite path applies only when ALL hold: the change touches at most 3 files; it adds or changes no interface, configuration key, dependency, schema or external contract; it will be finished in this session; no task needs claiming.
1. Read the `## Warnings` section of `state/CURRENT.md`.
2. For the files you touch and the errors you chase, run the code-owner match, the path search and the error-text search of section 2; read any hit that is CONSTRAINTS.md, an accepted ADR or a knowledge doc. Another actor's `in-progress` task whose `code` covers your files: tell the human before editing.
3. After the change, fix any doc your change makes wrong (T11, T19); otherwise update nothing (T22).
4. If anything surprises you, or the session ends with the work unfinished, switch to the full workflow (T2 creates the task).
### MKB for humans lines
Nobody is notified when a question or task file lands on the default branch, and unattended agents have no human in the session.
So whenever any line below applies, the agent ends its PR description with this block; in trunk-based work or without a PR, its final message ends with it.
Omit lines that do not apply; omit the block when none applies.
```text
MKB for humans:
Questions: Q-NNN (<owner>), Q-NNN (<owner>)
ADR decisions needed: ADR-NNN, ADR-NNN
NEXT suggestion: <ID> <why, at most 10 words>
Routing gap: <what was hard to find>
Gardening due
New task: <title>
Question for <handle>: <question>
```
- `Questions`: questions you created (section 6). `ADR decisions needed`: `proposed` ADRs in this PR (section 8). `NEXT suggestion`: T21. `Routing gap`: section 2. `Gardening due`: step 6 of "Before modifying code".
- `New task` and `Question for`: only dispatched agents that cannot push to the default branch (section 4, allocation step 7); the dispatching human creates those records. Humans read the block at review; the lead acts on NEXT suggestions and routing gaps.

## 2. Discovery
Run it after step 1 of section 1 (branch rebased onto `origin/main`), so the working tree holds the current docs and tasks; `git grep` searches tracked files; add `--untracked` to include files not yet committed.
1. Seeds S = IDs in the task's `related` and body + paths in the task's `code` + paths you expect to touch + exact error text you are investigating.
2. Code owners: `git grep "^code:" -- docs/mkb/knowledge docs/mkb/tasks` (one line per doc); keep every doc with an entry that is a prefix of a path in S; a directory entry ends with "/", a file entry matches only that file. Example: the line `docs/mkb/knowledge/services/SERVICE-<NAME>.md:code: [<path>/]` keeps `SERVICE-<NAME>` for a change to `<path>/<file>`.
3. For each ID in S: `git grep -l -w "<ID>" -- docs/mkb`. For each path in S: `git grep -l -F "<path>" -- docs/mkb` (mentions in prose). For each error text: `git grep -l -F "<exact error text>" -- docs/mkb/knowledge`.
4. Reverse hop: for each knowledge doc kept, `git grep -l -w "<its ID>" -- docs/mkb/decisions`. With an adopted ADR directory (INDEX Path overrides), search it wherever this names `docs/mkb/decisions`.
5. Ignore hits in `docs/mkb/templates/` and `docs/mkb/tasks/archive/`.
6. Triage each hit by reading only its first 16 lines (front matter + H1): `head -n 16 <file>` in sh, `Get-Content -TotalCount 16 <file>` in PowerShell. Keep it if its code overlaps your paths, its summary matches your work, or it is an ADR with status accepted; drop proposed/rejected/superseded/deprecated ADRs. A task that is in-progress, not yours (section 5, claim step 7), and whose code covers your paths: tell the human before you edit those paths.
7. Read in full, in this order, at most 5 docs: (1) project/CONSTRAINTS.md (always, when your change alters behavior); (2) accepted ADRs among the hits; (3) knowledge docs whose code covers your paths; (4) the relevant row or section of project/ARCHITECTURE.md; (5) anything else among the hits.
8. Follow related IDs one hop only, and only when the linked doc constrains your change.
9. Stop when, for every path you will touch, you can name: its knowledge doc (or "none"), the constraints and accepted ADRs that bind it, and the open questions, blocked tasks and other in-progress tasks that touch it.
10. Needed more than 5 docs? Read them, then add "Routing gap: <what was hard to find>" to your `MKB for humans:` lines (section 1); gardening adds a Routing row to INDEX.
11. No code owner AND no hit for `git grep -i "^summary:.*<word>" -- docs/mkb/knowledge`: the knowledge is missing, and you will probably write it.
12. Never read by default: `tasks/archive/`, `templates/`, superseded or rejected ADRs, git history.

## 3. Trigger matrix
| # | If your work... | Update |
|---|---|---|
| T1 | started a task | claim: `status: in-progress`, `owner`, `branch`, `code` (coordination) |
| T2 | stopped with the work unfinished | no task yet: first create it (section 5) already claimed, `status: in-progress`, `owner: <you>`, `branch: <current branch>` (coordination); then overwrite `handoff/TASK-NNN.md` on the task branch and commit and push everything including it; `git status` clean |
| T3 | finished a task | tick criteria; `status: done`; `closed`; fill `## Completion`; move each Dead ends or Watch out line of the handoff that stays true after the merge into the owning knowledge doc's `## Gotchas` (section 9 threshold) or a Notes line of the task; delete `handoff/TASK-NNN.md`; all in the delivering PR (trunk-based: section 5, done) |
| T4 | will not continue a task that someone else may continue | release: `status: todo`, `owner: none`, remove `branch`, Notes line naming the branch with partial work; keep the handoff on that branch (coordination) |
| T5 | showed a task should not be done | propose dropping it to a human; on their decision: `status: dropped`, `closed`, reason and decider in `## Completion` |
| T6 | needs an answer only a person can give | new `questions/Q-NNN.md` with `owner` = that person; task `status: blocked`, `blocked_by: [Q-NNN]`, Notes line (coordination) |
| T7 | is blocked by other work or an external party | existing or new task owned by whoever must act; `blocked_by: [TASK-NNN]` (coordination) |
| T8 | got an answer or saw a blocker resolved | promote the answer (section 6), delete the question; remove `blocked_by`; status back to `in-progress` if `branch` is set, otherwise `todo` (owner unchanged) (coordination; a PR when the promotion creates an ADR, section 6) |
| T9 | chose between real alternatives with lasting effect (section 8) | new ADR, `status: proposed`; a human listed in `deciders` accepts or rejects it before merge (section 8); list it under `ADR decisions needed` (section 1) |
| T10 | reverses or replaces an accepted ADR | new ADR with `supersedes`; old ADR gets `status: superseded` and `superseded_by`; same PR |
| T11 | changed the behavior, interface or invariants of a module, service, schema or integration | the knowledge doc whose `code` covers the change, in the same PR: check it against your change, fix what is wrong, bump `verified` |
| T12 | needed to reverse-engineer something undocumented, or met a gotcha (section 9 threshold) | extend the owning knowledge doc, or create one from its template; cross-cutting problems: a `TS-` doc |
| T13 | added, removed or re-bounded a component | the Components table in `project/ARCHITECTURE.md`; a knowledge doc if the component is not trivial |
| T14 | deleted a component, integration or store | delete its knowledge doc and its ARCHITECTURE row in the same PR; repoint references |
| T15 | changed build, run or test commands, the stack or dependencies | `project/OVERVIEW.md` (Stack, Commands), or `README.md` if that is where commands live |
| T16 | learned a non-negotiable rule | a human states it: `project/CONSTRAINTS.md` with source and date; otherwise a question to the lead |
| T17 | introduced a team-wide convention | `project/CONVENTIONS.md`, or `CONTRIBUTING.md` under a conventions path override, through a PR a human approves |
| T18 | changed a project-level fact of the default branch (build red or green, deployed version, known breakage, freeze) | a dated bullet in `state/CURRENT.md`, in the delivering PR or as a coordination commit |
| T19 | found a doc that contradicts the code | fix it now if small and in scope; otherwise a `> STALE` banner plus a task (section 9) |
| T20 | discovered work outside your scope | new task, `todo`, `owner: none`, pushed to the default branch at once (section 4, allocation step 6) |
| T21 | changed what should happen next | `NEXT suggestion: <ID> <why>` in your `MKB for humans:` lines (section 1); only the lead edits `state/NEXT.md` |
| T22 | changed nothing durable (local refactor, bug fix with no new knowledge, rename, formatting) | nothing; the commit message is the record. Exception: you touched a path in a knowledge doc's `code` and the doc is still right: bump its `verified` in the same PR |
- Walk every row; update only the rows that fire. "Coordination" means the change is pushed to the default branch immediately (section 11).

## 4. IDs, names and links
| Kind | Pattern | File |
|---|---|---|
| Task | `^TASK-[0-9]{3,}$` | `docs/mkb/tasks/TASK-NNN.md` or `docs/mkb/tasks/archive/TASK-NNN.md` |
| Decision | `^ADR-[0-9]{3,}$` | `docs/mkb/decisions/ADR-NNN.md` |
| Question | `^Q-[0-9]{3,}$` | `docs/mkb/questions/Q-NNN.md` |
| Module, service, database, integration, troubleshooting | `^MODULE-`, `^SERVICE-`, `^DB-`, `^INT-`, `^TS-`, each followed by `[A-Z][A-Z0-9]*(-[A-Z0-9]+)*$` | `docs/mkb/knowledge/` + `modules/MODULE-<NAME>.md`, `services/SERVICE-<NAME>.md`, `database/DB-<NAME>.md`, `integrations/INT-<NAME>.md`, `troubleshooting/TS-<NAME>.md` |
| Handoff | no own ID | `docs/mkb/handoff/TASK-NNN.md` (named after the work item) |
- Numbers are zero-padded to at least 3 digits (a one-digit number N is written `TASK-00N`, never `TASK-N`). After number 999 comes 1000 (four digits); existing IDs are never re-padded.
- Knowledge IDs are at most 40 characters, ASCII, singular, 1 to 3 words after the prefix, named after a stable noun from the code or the vendor (the component, device or symptom), never after a task. The first character after a knowledge prefix is a letter, so tracker keys such as `INT-` plus digits are never mistaken for knowledge IDs.
- IDs are written in uppercase, literally, everywhere (never "ADR N", "adr-NNN", "Task NN").
- Grep contract for tooling: `\b(TASK|ADR|Q)-[0-9]{3,}\b` and `\b(MODULE|SERVICE|DB|INT|TS)-[A-Z][A-Z0-9]*(-[A-Z0-9]+)*\b`. Templates, RULES.md and INDEX.md use only placeholders (`TASK-NNN`, `ADR-NNN`, `Q-NNN`, `MODULE-<NAME>`), which never match the grep contract.
### File names
- Directories: lowercase; plural for collections (`decisions/`, `knowledge/integrations/`). Case: never two names differing only in case.
- Singleton docs: `UPPERCASE.md` (`INDEX.md`, `CURRENT.md`, `RULES.md`). Templates: `UPPERCASE.md` named after the record kind (`templates/TASK.md`). Checker: `tools/mkb-check.sh`.
- ID docs: exactly `<ID>.md`; no slug (`ADR-NNN.md`, `INT-<NAME>.md`). Handoff files: `<work item ID>.md` (`handoff/TASK-NNN.md`, `handoff/GH-N.md` with an external tracker).
### Branches, commits and PRs
| Thing | Pattern |
|---|---|
| Task branch | `<actor>/task-nnn-<slug>`; `<actor>` is the handle; `task-nnn` is the lowercase task ID; slug is lowercase kebab of 1 to 5 words, `[a-z0-9]+(-[a-z0-9]+){0,4}` |
| Other branches | tool-forced branch names: allowed; the real name is recorded in `branch:`. MKB-only branch: `<actor>/mkb-<slug>`. Gardening branch: `<actor>/mkb-garden-YYYY-MM-DD`, merged the same day. Adoption branch: `<actor>/mkb-adopt`. Branch names are lowercase: always (case-insensitive ref storage on Windows and macOS). |
| Commit subject with a task | `TASK-NNN: <imperative summary>`; Conventional Commits projects: the ID MUST appear in the subject, for example at the end in brackets (`<type>(<scope>): <summary> [TASK-NNN]`) |
| Task coordination commits | new task (coordination commit at allocation, step 6 below): `TASK-NNN: add`. Claim: `TASK-NNN: claim` or, for a dispatched agent, `TASK-NNN: claim for <handle>`. Release: `TASK-NNN: release`. Block / unblock: `TASK-NNN: blocked on <IDs>` / `TASK-NNN: unblocked`. Done, trunk-based only (section 5): `TASK-NNN: done`. |
| Question commits | new question: `Q-NNN: ask <owner>`. Answer (the owner writes `## Answer` and sets `status: answered`): `Q-NNN: answer`. Question resolved: `Q-NNN: resolved -> <destination IDs>`. |
| ADR decision | `ADR-NNN: accept` / `ADR-NNN: reject` |
| MKB-only commits | MKB-only change: `mkb: <summary>`. Gardening: `mkb: gardening YYYY-MM-DD`. Archive: `mkb: archive closed tasks`. Renumber: `mkb: renumber <OLD-ID> -> <NEW-ID> (ID collision)`. Adoption: `mkb: adopt MKB v1.0 (<profile> profile)`. |
| PR title | starts with the work item ID when there is one |
### Allocating numbered IDs
1. `git fetch --all --quiet` (skip with no remote); in a shallow clone, run `git fetch --unshallow` first, because a shallow history hides the numbers of deleted questions.
2. List every file ever added under the record directory on any ref: `git log --all --no-renames --diff-filter=A --name-only --format= -- docs/mkb/<dir>` with `<dir>` = `tasks`, `decisions` (or the ADR directory adopted in place, section 15) or `questions`.
3. Also consider files you created but have not committed.
4. Next ID = highest number found + 1, zero-padded to at least 3 digits (in an adopted ADR directory: padded to the width of its existing numbers, for example `ADR-NNNN`).
5. Equivalent: `sh docs/mkb/tools/mkb-check.sh next TASK` (or `ADR`, `Q`; add `--adr-dir <dir>` for an adopted ADR directory), or the pipelines below (sh prints the next task ID, number 001 when none exists; PowerShell second).
6. Tasks and questions: create the file from its template and push it to the default branch at once as a coordination commit (`TASK-NNN: add`, `Q-NNN: ask <owner>`; section 11 recipe), before anything refers to the ID, including follow-ups found during work. At adoption they ride the adoption PR instead: no other actor can allocate an ID before `docs/mkb` reaches the default branch. If the file already exists in the worktree where you commit, someone took that number after your scan: never overwrite it; remove the temporary worktree and allocate again from step 1. The push is a compare-and-swap: a rejected push followed by an add/add conflict when you rebase the coordination worktree means someone took that number; `git rebase --abort`, allocate again from step 1, and retry. Protected default branch: the file goes in a one-file `mkb-coord` PR (section 5, protected default branch step 5). ADRs: create the file on your work branch (it stays `proposed` there, section 8) and push the branch soon. Until that branch merges, cite the new ADR only in files on that branch, never in a coordination commit: a renumber (below) rewrites only the lines your branch added.
7. Dispatched agents that cannot push to the default branch never allocate TASK or Q IDs: they write `New task: <title>` or `Question for <handle>: <question>` in their `MKB for humans:` lines (section 1), and the dispatching human creates the records.
```sh
git fetch --all --quiet
git log --all --no-renames --diff-filter=A --name-only --format= -- docs/mkb/tasks \
  | grep -oE 'TASK-[0-9]+' | awk -F- '$2+0 > n { n = $2+0 } END { printf "TASK-%03d\n", n+1 }'
```
```powershell
git fetch --all --quiet
$max = (git log --all --no-renames --diff-filter=A --name-only --format= -- docs/mkb/tasks |
  Select-String -Pattern 'TASK-(\d+)' -AllMatches |
  ForEach-Object { $_.Matches } | ForEach-Object { [int]$_.Groups[1].Value } |
  Measure-Object -Maximum).Maximum
'TASK-{0:D3}' -f ([int]$max + 1)
```
Numbers are never reused, including numbers of deleted questions and archived tasks.
Gaps are normal.
### Collisions and renumbering
- Detection: two branches that add the same `<ID>.md` get an add/add conflict on rebase, merge or PR ("This branch has conflicts"). For tasks and questions this normally happens in the coordination worktree at creation time, where the fix is to take the next number (allocation step 6).
- The procedure below covers IDs that already live on a branch when the collision shows: ADRs, and IDs in `mkb-coord` PRs under a protected default branch. Residual cases that git cannot see (an item created on a branch while another item with the same number was already archived, or an adopted ADR directory) are caught by `mkb-check.sh` error E1 and by the duplicate-number check of section 15. Rule: the branch that merges second renumbers its own item. The item on the default branch never changes.
1. Stop the rebase or merge: `git rebase --abort` (or `git merge --abort`). This avoids the reversed meaning of "ours" and "theirs" during a rebase.
2. Allocate the next free ID (above) after fetching.
3. `git mv <dir>/<OLD-ID>.md <dir>/<NEW-ID>.md`, set `id: <NEW-ID>`, start the H1 with `# <NEW-ID>:`, add `formerly: <OLD-ID>`.
4. Run `git diff origin/main...HEAD` and, only in lines your branch added that refer to your item, replace the old ID with the new one: other MKB files, code comments that cite it, and your handoff file name if the renumbered item is your own work item.
5. Leave every pre-existing line that refers to the default branch's item untouched.
6. Commit `mkb: renumber <OLD-ID> -> <NEW-ID> (ID collision)`, then run `git merge origin/main`, not a rebase: a rebase replays the commit that added `<OLD-ID>.md` and conflicts again, while a merge compares trees and sees no conflict. From then on this branch takes the default branch by merge (exception to section 11). Push, and write "Renumbered <OLD-ID> -> <NEW-ID> (collision); merge with a merge commit or squash, not rebase-merge" in the PR description.
7. Already pushed commit messages keep the old ID; `formerly` lets `git grep -w <OLD-ID>` find both records.
- Knowledge-name collision (two branches both created the same `INT-<NAME>.md`): both documented the same thing; merge the content into one doc by hand; keep the older `verified` unless you re-checked the merged doc against the merged code (section 11).
### Links
| Target | Form | Example |
|---|---|---|
| Any MKB record with an ID (task, ADR, question, knowledge) | Bare ID, never a Markdown link, in prose, lists, tables and front matter | `Blocked by Q-NNN; see ADR-NNN and INT-<NAME>.` |
| An MKB doc without an ID (INDEX, RULES, project/*, state/*) from inside `docs/mkb/` | Relative Markdown link whose text is the path relative to `docs/mkb/` | `[project/CONSTRAINTS.md](../project/CONSTRAINTS.md)` |
| A section of a doc | Name the section in words after the link or path; never a `#anchor` link | `[project/CONSTRAINTS.md](../project/CONSTRAINTS.md), section <name>` |
| Code | Backticked repo-root-relative path, optionally followed by the symbol in backticks; never line numbers in durable docs | `` `<path>/<file>` (`<symbol>()`) `` |
| Files outside `docs/mkb/` (README, CONTRIBUTING, config) | Backticked repo-root-relative path, never a Markdown link | `` `README.md` (<section>) `` |
| MKB paths from root files (AGENTS.md, CLAUDE.md) | Backticked repo-root-relative path | `` `docs/mkb/agents/RULES.md` `` |
| External resource | Markdown link with descriptive text; never a URL carrying a token or credentials; volatile vendor pages MAY add `(checked YYYY-MM-DD)` | `[<vendor> manual, section <n>](<URL>)` |
| GitHub issue / PR / commit; other trackers | `GH-N`, `PR #N`, short SHA of at least 7 characters; other trackers: the tracker's native key | `done in PR #N (<short SHA>)` |
| MKB from code | ID in a comment where code embodies a non-obvious decision or pending work | `# <rule> per ADR-NNN.` / `# TODO(TASK-NNN): <pending work>.` |
| MKB from git | ID at the start of the commit subject, in the branch name and in the PR title | `TASK-NNN: <summary>` |
- Line numbers are allowed only in handoff files; a durable doc (knowledge, ADR, project, state) never refers to a handoff file.
- Markdown links MUST point to files that exist in the same tree; templates contain no relative links. Inside INDEX.md the Routing and Authority sections name MKB paths as plain text, because the Layout table already links them.

## 5. Claiming and task status
- A task is REQUIRED when the work will not be finished within the current session (at the latest when a session ends unfinished, T2), when it will be handed to or dispatched to another actor, or when it is discovered and deferred. It is NOT needed for work you finish in the current session (committed, and a PR opened where the project uses PRs); the commit or PR is the record.
- Size: one mergeable unit of roughly 1 to 3 sessions; larger work is split into several tasks; no subtasks, no epics.
- Every new task, including follow-ups found during work, is created on the default branch at once as a coordination commit `TASK-NNN: add` (section 4, allocation step 6), so its number is visible before anything refers to it. Dispatched agents that cannot push to the default branch write `New task: <title>` in their `MKB for humans:` lines instead (section 1).
- Format: `templates/TASK.md`, at most 60 lines; the `## Notes` and `## Completion` headings always stay, even when empty. Notes lines: `- YYYY-MM-DD <handle>: <text>`, append-only, anyone may add one to any task. Completion first line: `- YYYY-MM-DD <handle>: done in PR #N` (trunk-based: `done in <short SHA>`, naming the last code commit; the done edit itself is the follow-up commit described under done below), then `- Shipped: ...`, `- Docs: <IDs created or updated>`, `- Follow-ups: <IDs or none>`, `- Deviations: <from acceptance criteria, or none>`.
### Status transitions and edit rights
| From | To | Who | Where |
|---|---|---|---|
| (new) | `todo` | anyone | coordination commit `TASK-NNN: add` (section 4, allocation step 6) |
| (new) | `in-progress` | the creator, at session end with no task yet (T2) | coordination commit `TASK-NNN: add` with `owner` and `branch` already set (section 4, allocation step 6) |
| `todo` | `in-progress` | the claimer (or a human for a dispatched agent) | coordination (claim) |
| `todo` | `blocked` | anyone, for an unowned task; the lead | coordination |
| `in-progress` | `blocked` | the owner | coordination |
| `blocked` | `in-progress` if `branch` is set, otherwise `todo` (owner unchanged) | the owner, or whoever resolved the blocker (section 6) | coordination, or the promotion PR (section 6, resolution step 3) |
| `in-progress` | `todo` | the owner (release), or the gardener for a stale agent claim | coordination |
| `in-progress` | `done` | the owner | the delivering PR |
| any open status | `dropped` | the owner or lead, after a human decision | PR or coordination |
| `done`, `dropped` | - | terminal; reopening means a new task that cites the old ID | - |
- Edit rights: only the owner edits a claimed task; anyone may append a Notes line; anyone may edit a task whose owner is `none`; the lead may edit any task; whoever promotes an answer (section 6) may edit the Goal and Acceptance criteria of the tasks the question blocks, marking each changed line `(resolves Q-NNN)`, and may remove `blocked_by` and set `status` as in T8.
### Claim (direct push to the default branch allowed)
1. `git fetch origin`.
2. `git show origin/main:docs/mkb/tasks/TASK-NNN.md | head -n 16` MUST show `status: todo` with `owner: none` or your handle. Never judge by your local copy. Otherwise (blocked, or claimed by another actor or session), do not claim the task or code on it: tell the human, naming its `blocked_by` or `owner`.
3. Make the claim as a coordination commit in a temporary worktree of `origin/main` (section 11 recipe; a human may use a clean `main`, section 11), never on a work branch. The recipe fetches again, so first repeat the step-2 check on `docs/mkb/tasks/TASK-NNN.md` in the worktree where you commit; if it no longer shows `status: todo` with `owner: none` or your handle, the task was claimed since step 2: remove the temporary worktree and pick another task. Then set `status: in-progress`, `owner: <you>`, `branch: <you>/task-nnn-<slug>`, and `code` with the paths you expect to touch (SHOULD, so that others' overlap checks see them, section 2); commit `TASK-NNN: claim`; `git push origin HEAD:main`.
4. Push rejected: fetch. If `git rev-list --count HEAD..origin/main` prints `0`, nobody pushed first and the server refuses direct pushes (`! [remote rejected]`): the default branch is protected; do not retry; remove the temporary worktree (on `main`: `git reset --keep origin/main`) and claim as in the protected default branch subsection. Otherwise rebase the temporary worktree onto `origin/main` and push again. A conflict in `TASK-NNN.md` means someone else claimed it: `git rebase --abort`, remove the temporary worktree (on `main`: `git reset --keep origin/main`), pick another task. If after the rebase `git rev-list --count origin/main..HEAD` prints `0`, your claim commit was dropped because an identical claim (same handle, another session of your tool) is already there: the task is taken; pick another task.
5. Create your branch `<you>/task-nnn-<slug>` from the updated `origin/main` (in its own worktree when agents work in parallel locally) and push it at once. Takeover: if the task's Notes contain `released; partial work on branch <old-branch>`, read `git show origin/<old-branch>:docs/mkb/handoff/TASK-NNN.md`, create your branch from that tip instead (`git switch -c <you>/task-nnn-<slug> origin/<old-branch>`), rebase it onto `origin/main` (merge instead if it has a `mkb: renumber` commit, section 11), push it, and verify the handoff against it; the handoff is now yours to overwrite; never push to the old branch.
6. Dispatched agents that cannot push to the default branch (for example Codex cloud and the Copilot coding agent): the dispatching human makes the claim commit `TASK-NNN: claim for <handle>` before dispatch, with `branch: pending` if the tool names the branch later; the agent or the human replaces `pending` with the real name in the PR.
7. When a task is yours: `owner` is your handle, AND `branch` is the branch you were told to resume or are on, AND `git worktree list` does not show that branch checked out in another worktree. `branch: pending` is yours only if you are the dispatched session. A task with your handle that fails this test belongs to another session of your tool: pick another task or ask the human.
8. Minimal profile, one actor working on the default branch (section 14): the claim is the first commit of your work and SHOULD be pushed before you write code.
9. Cannot fetch or push (sandbox, network or permissions): stop before coding and ask the human to push the claim; never code on an unpushed claim.
### Protected default branch (no direct push)
1. `git fetch --prune origin` (`--prune` drops branches deleted on the remote, such as released claim branches); the task must be `todo` on `origin/main`, and `git branch -r` must show no branch containing `/task-nnn-` other than branches named in the task's release Notes.
2. Create `<you>/task-nnn-<slug>`, commit the claim edit on it, push it immediately; the pushed branch name is the claim.
3. `git fetch --prune origin` again; if `git branch -r` now shows a branch containing `/task-nnn-` other than yours and those named in the task's release Notes, stop before coding and ask the lead; the lead gives the task to one actor, and the others delete their claim branches.
4. Dispatched agents whose tool names its own branch: before dispatch, the dispatching human pushes a claim branch `<agent handle>/task-nnn-<slug>` that holds only the claim commit (`TASK-NNN: claim for <handle>`); the tool's real branch is recorded in `branch:` inside the agent's PR; the human deletes the claim branch when that PR merges or the task is released.
5. The front-matter claim reaches the default branch with the PR. Other coordination changes, new tasks and questions included, use one-file PRs labelled `mkb-coord`, merged by the first human who sees them; an ID collision between two open `mkb-coord` PRs is fixed by renumbering the later one (section 4), which nothing refers to yet.
### No remote
"origin/main" means local `main`; skip every fetch, pull and push; branch checks use `git branch`; coordination commits follow section 11 (no-remote variant).
### Release, stale claims, drop and done
- Release (T4): `status: todo`, `owner: none`, remove `branch`, Notes line `- YYYY-MM-DD <handle>: released; partial work on branch <branch>, see its handoff`.
- Stale claim: `in-progress` with no commit on its branch for 7 days. Agent owner: the gardener or any human may release it. Human owner: ask them; after 14 days the lead decides.
- Stale dispatch: `in-progress` with `branch: pending` and no change to the task file on the default branch for 7 days (W6): the dispatched agent produced no PR; the dispatching human releases it.
- Drop: only after a human decision; Completion line `- YYYY-MM-DD <handle>: dropped: <reason>, decided by <human handle>`.
- Done: set in the delivering PR, so the default branch says `done` only after the work merges. Trunk-based work: the done edit is a separate follow-up commit `TASK-NNN: done` right after the last code commit, whose short SHA the Completion line names (a commit cannot contain its own hash). There is no `review` status: an open PR signals review.
### Board views
Queries, never committed files; they read `origin/main`, or `main` without a remote; the `awk` line and the PowerShell line print one line per open task (`<title> | <status> <priority> <owner>`), run in an up-to-date checkout of `main`.
```sh
git grep -e "^status:" -e "^priority:" -e "^owner:" origin/main -- docs/mkb/tasks ':(exclude)docs/mkb/tasks/archive'
git grep -l "^status: todo" origin/main -- docs/mkb/tasks
git grep -l "^status: in-progress" origin/main -- docs/mkb/tasks
git grep "^blocked_by:" origin/main -- docs/mkb/tasks
git grep "^# TASK-" origin/main -- docs/mkb/tasks ':(exclude)docs/mkb/tasks/archive'
awk '/^status:/{s=$2} /^priority:/{p=$2} /^owner:/{o=$2} /^# TASK-/{if (s!="done" && s!="dropped") print substr($0,3) " | " s " " p " " o; nextfile}' docs/mkb/tasks/TASK-*.md
```
```powershell
Get-ChildItem docs/mkb/tasks/TASK-*.md | ForEach-Object { $h = Get-Content $_ -TotalCount 16; $v = @{}; $h | Where-Object { $_ -match '^(status|priority|owner): (.+)$' } | ForEach-Object { $v[$Matches[1]] = $Matches[2] }; $t = ($h | Where-Object { $_ -like '# TASK-*' } | Select-Object -First 1).Substring(2); if ($v.status -notin 'done','dropped') { "$t | $($v.status) $($v.priority) $($v.owner)" } }
```

## 6. Blockers and questions
- When to ask: only when an answer from a specific person or external party is needed and the decision is outside your authority. If the decision is yours, make it (and write an ADR if section 8 applies).
- Creating a question: file from `templates/QUESTION.md`, at most 40 lines; `owner` = the human who must answer (for an external party, the human who will get the answer); created at allocation as a coordination commit `Q-NNN: ask <owner>` (section 4, allocation step 6) so the owner sees it on the default branch. If it blocks a task, the same commit sets that task `blocked` with `blocked_by: [Q-NNN]` and adds a Notes line.
- A push notifies nobody: the asker also lists the question under `Questions` in its `MKB for humans:` lines (section 1). A dispatched agent that cannot push to the default branch writes `Question for <handle>: <question>` there instead, and the dispatching human creates the question file.
### Resolution
| The answer... | Goes to |
|---|---|
| decides between alternatives with lasting effect | a new ADR (its Context cites Q-NNN) |
| is a fact about an external system | an `INT-` doc |
| is a fact about the code or domain | a knowledge doc, or project/OVERVIEW.md Glossary |
| is an external non-negotiable rule | project/CONSTRAINTS.md (a human writes it or states it in the session) |
| scopes or changes a task | that task's Goal or Acceptance criteria, each changed line marked `(resolves Q-NNN)` (section 5 lets the promoter edit them) |
| makes the question moot | nowhere; say so in the commit message |
1. The owner (or an agent relaying an answer given in chat or a PR comment, quoting it verbatim with attribution `YYYY-MM-DD <handle> (via chat): ...`) writes the answer under `## Answer` and sets `status: answered`, as a coordination commit `Q-NNN: answer`.
2. The next session that touches the question, or the answerer, promotes the answer to its permanent home (table above) and writes `(resolves Q-NNN)` there; a new ADR cites Q-NNN in its Context instead.
3. In the same commit (`Q-NNN: resolved -> <destination IDs>`): delete the question file; remove the ID from every `blocked_by`; set those tasks back to `in-progress` if `branch` is set, otherwise `todo` (owner unchanged). This is a coordination commit, except when the promotion creates an ADR: then the resolution rides an `<actor>/mkb-<slug>` PR, because the ADR needs a human decision before merge (section 8), and the question and the blocked tasks stay as they are on the default branch until that PR merges.
4. There is no RESOLVED file: `git grep -w Q-NNN` finds where the answer lives; git keeps the question.
### Blockers
- A blocked task has `status: blocked` and `blocked_by: [IDs]`, each a TASK or Q ID. The reason lives in the blocking item; the blocked task adds a Notes line.
- An external impediment (vendor outage, missing access, hardware) becomes a task owned by the human who chases it, for example a task "Get the <vendor> test account reactivated" owned by `<handle>`.
- Blocker list view: `git grep "^blocked_by:" origin/main -- docs/mkb/tasks`. A blocker whose items are all resolved is cleared at once (T8); gardening checks for forgotten ones (mkb-check W12).

## 7. Handoffs
- Location: `docs/mkb/handoff/<work item ID>.md`, committed on the task branch (in trunk-based minimal projects, on the default branch). It exists only while the task is unfinished.
- Format: `templates/HANDOFF.md`. Required sections: Where it stands, Next steps, Read first. Optional sections: Watch out, Dead ends (delete the heading when empty). Hard limit: 30 lines including the H1. Line numbers in code references are allowed here only.
- What goes in: the state of the branch (pushed, CI result, what is half-done), the exact next steps, traps that apply only to this in-flight work, approaches tried and rejected, IDs and paths to read first.
- What never goes in: durable knowledge (it goes to its home doc now; the handoff points to its ID); decisions (ADR), project state (state/CURRENT.md), task definition or completion notes (task file); a narrative of the session, praise, apologies; code blocks longer than 5 lines, logs, stack traces, diffs, file lists that git already shows; secrets or credential values; anything about other tasks (cross-task warnings go to `state/CURRENT.md`, section Warnings).
- Reading: a handoff is the lowest authority. Verify it against the branch (`git log`, `git status`, tests) before acting. From another checkout: `git show origin/<branch>:docs/mkb/handoff/TASK-NNN.md`.
- Writing and rotation:
  1. The owner overwrites it at the end of every session that leaves the task unfinished, and at checkpoints before long or risky operations, then commits and pushes it together with all work (a WIP commit on your own branch is fine); `git status` is clean afterwards. A handoff that is not pushed does not exist for the next session.
  2. It is always overwritten whole by the owner; the previous version stays in git.
  3. It is deleted in the PR that sets the task `done` or `dropped`, after its lines that stay true have moved (T3).
  4. On release (T4) it stays on the released branch. The next owner creates their branch from that branch's tip (section 5, claim step 5), and the handoff on the new branch is theirs to verify and overwrite.
  5. If a partial PR merges while the task continues, the handoff may reach the default branch; the next session continues on a new branch and updates `branch:`.
  6. Gardening deletes any handoff on the default branch whose task is `done` or `dropped`, or that has no task.
  7. Only the task owner writes it; nobody edits another actor's handoff (after a takeover, the copy on your own branch is yours).

## 8. ADRs
File `decisions/ADR-NNN.md` from `templates/ADR.md`, at most 100 lines; the H1 states the decision; `date` is the decision date (while `proposed`, the date proposed).
### When to write one
Write an ADR when BOTH hold:
1. at least two viable alternatives were weighed, and
2. at least one of these is true: the choice is expensive to reverse (data format, storage, public API, protocol, persisted schema); it crosses a module or service boundary, or changes an external contract; it adds or removes a significant dependency, service or piece of infrastructure; it knowingly accepts a trade-off or risk (security, compliance, performance); it sets a project-wide rule, or deviates from an existing ADR, constraint or convention; a competent newcomer would plausibly "clean it up" back or reopen the debate.
- Do NOT write an ADR for: naming, formatting, local refactors, bug fixes, a library choice internal to one module that is easy to change, anything already dictated by CONSTRAINTS.md or an accepted ADR (cite that ID instead), anything whose rationale fits in a code comment.
- If unsure, record the reasoning in the task's Completion section; promote it to an ADR if someone reopens the debate.
### Status and who decides
- `proposed` -> `accepted` or `rejected`: only a human, normally during PR review; the human adds themselves to `deciders` and sets `date`. `accepted` -> `superseded` (by a new ADR) or `deprecated` (no longer applies, no replacement).
- Agents create ADRs only as `proposed` and never decide an ADR's status on their own authority. An agent MAY write `accepted`, `rejected` or `deprecated` only to record a decision that a named human stated in the current session, and then lists that human in `deciders`.
- An ADR reaches the default branch only as `accepted` or `rejected`: a PR containing a `proposed` ADR MUST NOT be merged until a human decides it. In trunk-based work the human decides in the session before the commit.
- A PR that adds an ADR as `accepted` or `rejected`, or changes an ADR's status, MUST NOT merge unless a human listed in that ADR's `deciders` approves it in review or merges it personally. In trunk-based work an agent records a decision only while that human is in the session.
- `proposed` ADRs waiting for a decision are listed under `ADR decisions needed` in the PR's `MKB for humans:` lines (section 1). Rejected ADRs are kept: they record "we considered this".
- Immutability: once accepted, only `status`, `superseded_by` and typo or broken-link fixes may change. Anything that changes substance needs a new ADR.
### Superseding (one PR) and deprecating
1. Write the new ADR with `supersedes: [ADR-old]`; its Context says what changed; it replaces the whole old decision, restating any part that survives.
2. On the old ADR set `status: superseded` and `superseded_by: ADR-new`; change nothing else.
3. `git grep -n -w "ADR-old" -- docs/mkb` and repoint knowledge docs, ARCHITECTURE and CONVENTIONS that rely on it.
4. Create tasks for code that must change; code comments citing the old ID are updated when that code is next touched.
- Deprecating: only a human sets `status: deprecated`, and nothing else in the ADR changes; the reason goes in the commit message and in the task that removed the component.

## 9. Knowledge docs and STALE banners
- Threshold: write it down only if the code does not make it evident within 5 minutes AND at least one holds: it cost more than 30 minutes to learn; it lives outside the repository (device, vendor, production, customer); it spans several files; it is an invariant the code cannot enforce.
- Where to write it, in order of preference: a code comment if it concerns one place in the code; a section of an existing doc (search first); a new doc last, from its template.
- A gotcha about one module, service, store or integration goes in that doc's `## Gotchas`; a cross-cutting or environment problem goes in a `TS-` doc. Quote exact error strings so grep finds them.
- `verified` is the date someone last checked the doc against the code on the default branch: the whole doc when it is created and at the 180-day re-check (W16); the parts a change affects when that change touches one of its `code` paths (T11).
- Split: a knowledge doc over 150 lines is split into narrower IDs; the original keeps a short map pointing to the new IDs (or is deleted if the split is total). Rename: only during gardening, one commit, with `formerly` set and every reference repointed. Delete: with its component, in the same PR. Never bulk-generate knowledge docs for code nobody is changing; at adoption or upgrade, at most the 3 most-changed components get docs written from the code (`git log --format= --name-only | sort | uniq -c | sort -rn | head`); a knowledge doc created to hold facts migrated from an old notes file is not counted.
- A doc that contradicts the code: fix it now if small and in scope; otherwise a STALE banner plus a task (T19).
- STALE banner, exact form, directly under the H1 (whole doc) or under the affected `##` heading (one section):
```markdown
> STALE YYYY-MM-DD <handle>: <what is wrong>. Tracking TASK-NNN.
```
Text under a banner is not authoritative.
Removing the banner is part of the fix.
Never bump `verified` without actually checking the code.

## 10. State files
- `state/CURRENT.md` describes the default branch and deployments, never branch progress or finished work.
- Sections Health, Focus, Warnings; every bullet `- YYYY-MM-DD <handle>: <fact> (<IDs>)`.
- Health: exceptions and deployments only: the default branch is red, known broken functionality, deployed version per environment. Never "CI green": the forge already shows it, and it would need re-dating forever. Warnings: what every session must know now. Focus: 1 to 3 bullets written by the lead.
- Edited only when a project-level fact changes: in the PR that changes it, or as a coordination commit for facts that change outside a PR (deployments, outages, freezes).
- Re-date a bullet when you re-verify it; delete it when it stops being true; bullets older than the W5 threshold (14 days in the full profile, 35 days in the minimal profile, one gardening interval plus slack) are re-verified or deleted at gardening. Micro-gardening: if you know a bullet is false, fix it in the commit where you notice it.
- `state/NEXT.md`: ordered list of at most 10 entries `- <ID>: <why now, at most 10 words>`, highest first, `-` bullets (not numbers, so reordering does not renumber); written only by the lead, or by an agent when a human asks in the session.
- Readers take the first ID in `state/NEXT.md` whose task on the default branch is `todo` with `owner: none` or you, and skip the others; the lead prunes finished entries (W13).

## 11. Concurrency and conflicts
- One work item, one branch, one writer; two actors on one task at the same time is a claim violation, not a merge problem: the later actor stops. Parallel local agents each use their own `git worktree`; git refuses to check out one branch in two worktrees.
- Never push to or force-push a branch you did not create; a cloud agent and a local agent never share a branch. Exception: once the session that owns a PR branch has ended, a human reviewer MAY add commits to it (for example to set an ADR to `accepted` during review); never force-push it.
- Rebase your branch onto the default branch at session start and before every push (push your own rebased branch with `git push --force-with-lease`); at session start, first run `git merge --ff-only origin/<your-branch>`, because the lease does not protect commits a reviewer added that you fetched but did not take in (if the fast-forward is refused, both sides have new commits: ask the human); keep branches to a few days. Exception: a branch whose `git log origin/main..HEAD` shows a `mkb: renumber` commit (section 4) takes the default branch by `git merge origin/main`, never a rebase, until it merges.
- Lost-update guard: an agent's in-context copy of a file may be hours old. Re-read the file from disk right before editing it, patch only the lines you mean to change, and never write a whole MKB file regenerated from memory. If the file changed since you first read it, merge your intent into the new content.
### Coordination commits
Coordination commits change only MKB coordination data and go straight to the default branch: claims, releases, block and unblock, new tasks and new questions (at allocation, section 4), answers, resolutions (except when the promotion creates an ADR, section 6), `state/CURRENT.md` facts that change outside a PR, and `state/NEXT.md` edits by the lead.
Everything else rides the work branch and reaches the default branch with the PR.
The recipe (sh, then PowerShell) does not disturb your working tree and works from any worktree; its temporary worktree has a unique path under the system temp directory, so parallel sessions that share a handle never collide; a sandboxed agent tool may need approval to run the recipe's git commands, because they write to the repository's Git directory.
```sh
git fetch origin
git worktree prune                                   # forget worktrees whose directory is gone (crashed sessions)
d="$(mktemp -d)"                                     # new empty directory, unique per call
git worktree add --detach "$d" origin/main
# edit the one MKB file (or the file plus the task it blocks) inside "$d"
git -C "$d" add -A
git -C "$d" commit -m "TASK-NNN: blocked on Q-NNN"
git -C "$d" push origin HEAD:main
# rejected: git -C "$d" fetch origin; if git -C "$d" rev-list --count HEAD..origin/main prints 0, the default branch is protected (below): stop; else git -C "$d" rebase origin/main and push again
# a conflict in the same MKB file means someone changed it first: git -C "$d" rebase --abort, re-read, decide again
git worktree remove --force "$d"                     # only the worktree you created in this step
git fetch origin && git rebase origin/main           # in your work branch, after committing your work
```
```powershell
git fetch origin
git worktree prune
$d = Join-Path ([IO.Path]::GetTempPath()) ("mkb-coord-" + [guid]::NewGuid())
git worktree add --detach $d origin/main
# edit the one MKB file (or the file plus the task it blocks) inside $d
git -C $d add -A
git -C $d commit -m "TASK-NNN: blocked on Q-NNN"
git -C $d push origin HEAD:main
# rejected: fetch; rev-list --count HEAD..origin/main prints 0: protected (below), stop; else rebase origin/main and push again, as in sh
git worktree remove --force $d                        # only the worktree you created in this step
git fetch origin; git rebase origin/main              # in your work branch, after committing your work
```
A human whose working tree is clean may skip the temporary worktree: `git switch main`, `git pull --ff-only`, and `git status -sb` must print only `## main...origin/main` (otherwise use the recipe); edit, `git add -A`, `git commit -m "<subject>"`, `git push origin HEAD:main`; rejected: as in the recipe, run in `main` (protected: `git reset --keep origin/main`, then the PR route below); a conflict in the same MKB file: `git rebase --abort`, `git reset --keep origin/main`, re-read, decide again.
Protected default branch: coordination changes become one-file PRs labelled `mkb-coord`, merged by the first human who sees them; claims use section 5 (protected default branch).
No remote: the same recipe with `git worktree add "$d" main` (a real checkout of `main`, no `--detach`, no fetch or push) when `main` is not checked out anywhere; otherwise commit in the worktree that has `main` checked out only if its working tree is clean; otherwise ask the human.
### Conflict cookbook (MKB files only)
| Conflict | Resolution |
|---|---|
| add/add on `tasks/TASK-NNN.md` or `questions/Q-NNN.md` in the coordination worktree | ID taken at creation: abort the rebase, allocate the next number, retry (section 4, allocation step 6) |
| add/add on `decisions/ADR-NNN.md`, or on an ID already on a branch | your branch already has `mkb: renumber <that ID> -> <NEW-ID>` in `git log origin/main..HEAD`: `git rebase --abort`, then `git merge origin/main`; never renumber it again (section 4, renumbering step 6); otherwise ID collision: the branch merging second renumbers its own item (section 4) |
| add/add on a knowledge doc | same subject documented twice: merge the content into one doc |
| a knowledge doc's `verified` line | both sides bumped it: keep the older date, unless you re-check the merged doc against the merged code |
| task `status`, `owner`, `branch` lines, both sides a claim | claim race: the default branch wins; the other actor stops and picks another task |
| task `status` line, one side a `done` or `dropped` edit (for example a PR's done edit against a release on the default branch) | not a claim race: stop and ask the lead which side wins; `owner`, `branch` and `closed` may have merged without a conflict, so set them to match the chosen `status`, then run `mkb-check.sh`: no E3 |
| task Notes, acceptance criteria, `related`, `code` | keep both sides; Notes in date order |
| `state/CURRENT.md` bullets | keep both sides; for the same bullet keep the newer date; a deletion wins when the fact is no longer true |
| `state/NEXT.md` | the lead's version wins |
| a handoff file | two writers on one branch (rule violation): the later session re-reads and rewrites it by hand |
| an accepted ADR body | restore the default branch's version; move the change into a superseding ADR |
| knowledge or project prose | resolve sentence by sentence against the code; if unsure keep both and add a STALE banner |
| INDEX.md | keep the union of rows |
| RULES.md above section 16, templates, tools | take the default branch's version |
- Never resolve MKB conflicts with `-X ours`, `-X theirs` or "accept all"; during a rebase "ours" means the upstream side.

## 12. Formatting and front matter
- One sentence per line in prose; never hard-wrap or re-flow a paragraph.
- Tables use minimal spacing `| a | b |` with the separator `|---|---|`, never column-aligned.
- Lists use `-`; ordered lists use `1.`; `state/NEXT.md` uses `-` so reordering does not renumber.
- Append new items at the designated spot; never sort, reorder or reformat existing lines.
- LF line endings, UTF-8 without BOM. No "Last updated" lines anywhere.
### The MKB YAML subset
Front matter is REQUIRED on `INDEX.md`, `agents/RULES.md`, `project/ARCHITECTURE.md`, every task, ADR, question and knowledge doc, and the templates except `templates/HANDOFF.md` and `templates/CONVENTIONS.md`.
It is FORBIDDEN on `project/OVERVIEW.md`, `project/CONSTRAINTS.md`, `project/CONVENTIONS.md`, `state/CURRENT.md`, `state/NEXT.md` and handoff files; ADRs in a directory adopted in place (section 15) carry none.
1. The file starts with a line `---`; front matter ends at the next line `---`; the H1 is on the line right after it (canonical form, used by every skeleton). A blank line between the closing `---` and the H1 is tolerated; anything else there is an error (E3).
2. One `key: value` per line. No nested maps, no multi-line values, no YAML comments.
3. Keys are lowercase snake_case. Write them in the template order of the table below and never reorder existing keys; order is not checked.
4. A value is either a scalar or a one-line flow list `[a, b, c]`.
5. Dates are unquoted `YYYY-MM-DD`. No times.
6. `mkb_version` is always quoted: `mkb_version: "1.0"`.
7. Handles are written without `@` (YAML reserves `@`). Prose may use `@<handle>`; front matter never does.
8. Optional keys with no value are omitted entirely. Never write `key:` with an empty value and never write `key: []`.
9. A scalar MUST NOT contain `: ` or ` #`; rephrase with a dash instead. It MUST NOT start with `[`, `]`, `{`, `}`, `>`, `|`, `*`, `&`, `!`, `%`, `@`, `#`, `,`, `"`, `'` or a backtick, nor with `-` or `?` followed by a space or the end of the value (except list values, which are flow lists, and `mkb_version`, which rule 6 quotes).
10. At most 12 keys, so that the first 16 lines of a file show the front matter and the H1 (12 keys, 2 delimiters, the H1, and room for the tolerated blank line).
### Vocabularies
| Field | Values and meaning |
|---|---|
| task `status` | `todo`: not started; claimable if `owner` is `none` or your handle. `in-progress`: claimed; has `owner` and `branch`. `blocked`: cannot proceed until every item in `blocked_by` is resolved; may be owned or unowned. `done`: delivered; `closed` and `## Completion` filled; set inside the delivering PR. `dropped`: will not be done; `closed` and a reason in `## Completion`; needs a human decision. |
| adr `status` | `proposed`: draft; exists only on branches. `accepted`: binding; body frozen. `rejected`: considered and declined; kept as a record. `superseded`: replaced by the ADR in `superseded_by`. `deprecated`: no longer applies and has no replacement (for example, the component was removed). |
| question `status` | `open`: waiting for its owner's answer. `answered`: `## Answer` filled; waiting for promotion and deletion. |
| task `priority` | `critical`: drop other work: the default branch is broken, production is down, or there is a legal, safety or data-loss risk. `high`: needed for the current Focus in `state/CURRENT.md`, or blocks other tasks. `normal`: default. `low`: nice to have; gardening may propose dropping it after 90 days. |
- Knowledge docs, ARCHITECTURE, INDEX and RULES have no `status`; known-wrong knowledge gets a STALE banner (section 9).
- A handle matches `^[a-z][a-z0-9-]{0,31}$` and is not `none`. Reserved agent handles: `claude-code`, `codex`, `cursor`, `gemini-cli`, `aider`, `copilot`, `windsurf`, `agent` (any other agent tool).
- Human handles: the person's lowercase forge or git handle; MUST NOT equal a reserved agent handle. Every handle used in a project SHOULD appear in INDEX `## People and agents`. `owner: none` means unassigned. `deciders` MUST contain only human handles. A question's `owner` MUST be a human handle.
- Parallel sessions of the same tool share its handle; the `branch` field tells them apart (section 5, claim step 7 defines when an owned task is yours). Never invent handles like `claude-2`.
### Keys per type
| `type` | File | Keys in template order (R required, C conditional, O optional) |
|---|---|---|
| `index` | `INDEX.md` | `type` R; `mkb_version` R `"1.0"`; `profile` R `minimal` or `full` |
| `rules` | `agents/RULES.md` | `type` R; `mkb_version` R `"1.0"` |
| `architecture` | `project/ARCHITECTURE.md` | `type` R; `verified` R date |
| `task` | `tasks/TASK-NNN.md`, `tasks/archive/TASK-NNN.md` | `id` R `TASK-NNN`; `type` R; `status` R task vocabulary; `priority` R priority vocabulary; `owner` R (handle or `none`; MUST NOT be `none` when `in-progress` or `done`); `branch` C (required when `in-progress`; forbidden when `todo`, removed on release; optional when `blocked`, `done` or `dropped`, kept for history); `created` R date; `closed` C (required when `done` or `dropped`; forbidden otherwise); `blocked_by` C (required when `blocked`; forbidden otherwise; flow list of TASK- and Q- IDs, non-empty); `related` O IDs; `code` O paths (SHOULD be set at claim); `formerly` O previous ID |
| `adr` | `decisions/ADR-NNN.md` | `id` R `ADR-NNN`; `type` R; `status` R adr vocabulary; `date` R (date of the decision, acceptance or rejection; while `proposed`, the date proposed); `deciders` C (required for every status except `proposed`; flow list of human handles, non-empty); `supersedes` O ADR IDs; `superseded_by` C (one ADR ID; required when `superseded`; forbidden otherwise); `related` O IDs (components and tasks); `formerly` O previous ID |
| `question` | `questions/Q-NNN.md` | `id` R `Q-NNN`; `type` R; `status` R `open` or `answered`; `owner` R human handle who must answer; `asked_by` R handle; `created` R date; `related` O IDs; `formerly` O previous ID |
| `module`, `service`, `database`, `integration` | `knowledge/modules/MODULE-<NAME>.md`, `knowledge/services/SERVICE-<NAME>.md`, `knowledge/database/DB-<NAME>.md`, `knowledge/integrations/INT-<NAME>.md` | `id` R knowledge ID with the prefix matching the type; `type` R; `summary` R at most 120 characters; `code` C (required, at least one path, for `module`, `service` and `database`; optional for `integration`: omit it while no code talks to the system yet); `verified` R date (section 9); `related` O IDs; `formerly` O previous ID |
| `troubleshooting` | `knowledge/troubleshooting/TS-<NAME>.md` | same keys as the row above with `type: troubleshooting`; `code` is optional (omit it for environment or toolchain problems) |
- Values: `id` MUST equal the file name without `.md`; `related` is a flow list of IDs (MKB IDs or external tracker keys); `code` is a flow list of repo-root-relative paths, no leading `/` or `./`, no globs, directories end with `/`; `branch` is the exact git branch name, or `pending` when a dispatched cloud agent has not created its branch yet; `summary` is one line containing the words people will grep for; `formerly` is the previous ID of this record after a renumber or rename.
- W2 and W3 do not apply to a doc without `code`. There is deliberately no `blocks` key on questions: the blocked task's `blocked_by` is the single source.

## 13. Gardening
- Cadence: full profile weekly; minimal profile monthly; also when a session reports `Gardening due` or a routing gap (section 1).
- Who: any human or agent asked by a human; not a task (it fits in one sitting). Where: branch `<actor>/mkb-garden-YYYY-MM-DD`, merged the same day (its edits are broad but tiny).
- Procedure:
  1. Run `sh docs/mkb/tools/mkb-check.sh` (with git, so that every check runs) and fix every error.
  2. Resolve every warning with the action in the table below; a warning that needs a human decision (a human's stale claim, dropping a task, pruning NEXT) goes into the PR description for the lead.
  3. Archive closed tasks (W9): `git mv docs/mkb/tasks/TASK-NNN.md docs/mkb/tasks/archive/` for every task `done` or `dropped` with `closed` more than 30 days ago, in a commit `mkb: archive closed tasks`. Archived tasks are never edited or deleted.
  4. Add INDEX Routing rows for reported routing gaps.
  5. Delete a migration stub (a `Handoff.md` replaced by a pointer to `docs/mkb/INDEX.md`) whose date has passed.
  6. Prune `state/NEXT.md` only if the lead asked.
- Limits: gardening never changes code; never rewrites content it does not understand (it adds a STALE banner and a task instead); never releases a human's claim.
- Commit `mkb: gardening YYYY-MM-DD`; the PR description lists each finding in at most 5 lines. Micro-gardening: any session may fix a single false item it notices in a file it read anyway.
### Staleness checks
| Check | Signal | Threshold | Action |
|---|---|---|---|
| W5 | `state/CURRENT.md` bullet | older than 14 days (full) or 35 days (minimal) | re-verify and re-date, or delete |
| W6 | `in-progress` task | no commit on its branch for 7 days; with `branch: pending`, task file unchanged on the default branch for 7 days | agent owner: release (section 5); human owner: ask; lead decides after 14 days; pending: the dispatching human releases |
| W14 | `blocked` task | file unchanged for 14 days | the lead re-plans, escalates or drops it |
| W15 | `open` question | `created` more than 14 days ago | remind the owner; the lead escalates |
| W7 | `answered` question | any | promote now (section 6) |
| W12 | `blocked` task | every `blocked_by` item resolved | clear the block (T8) |
| W2 | Knowledge doc | a `code` path changed on a later day than the doc itself | check the doc against that change: fix and bump `verified`, or STALE banner plus task |
| W3 | Knowledge doc | a `code` path no longer exists | rewrite or delete |
| W16 | Knowledge doc or ARCHITECTURE | `verified` older than 180 days | re-verify the whole doc against the code |
| W8 | `> STALE` banner | older than 30 days | fix the doc or delete it |
| W4 | Handoff on the default branch | task `done`, `dropped` or missing | move lasting lines (T3), then delete |
| W9 | Closed task | `closed` more than 30 days ago | archive (procedure step 3) |
| W17 | `low` task | `created` more than 90 days ago | propose dropping it to the lead |
| W13 | `state/NEXT.md` entry | task `done`, `dropped` or missing | tell the lead, who prunes it |
| W1 | Size budget | exceeded | split or trim |
- This table documents the checker: gardening runs `mkb-check.sh` and applies the action of each warning it prints; nobody walks the table by hand. W10 and W11 are consistency checks, not staleness signals, so the table has no row for them: resolve W10 by repointing the reference to the record's current ID, or by removing it when the record is gone for good, as renames and deletions do (section 9); resolve W11 by deleting the guide comment, which should have been deleted when the file was created from its template.
- Size budgets in lines (W1): INDEX 120; RULES 500 above section 16; OVERVIEW 80; ARCHITECTURE 150; CONSTRAINTS 80; CONVENTIONS 120; CURRENT 40; NEXT 15; ADR 100; task 60; question 40; module, service, database and integration docs 150; TS- docs 60; handoff 30; each template 40.
### mkb-check.sh
```text
sh docs/mkb/tools/mkb-check.sh [--root DIR] [--no-git] [--adr-dir DIR] [--today YYYY-MM-DD] [--strict] [check]
sh docs/mkb/tools/mkb-check.sh [--root DIR] [--no-git] [--adr-dir DIR] next TASK|ADR|Q
```
- `--root DIR`: repository root containing `docs/mkb/` (default: `git rev-parse --show-toplevel`, else the current directory). `--no-git`: skip checks W2, W3, W6, W14; `next` scans only the working tree. `--adr-dir DIR`: an ADR directory adopted in place (section 15). `--today`: date used for age checks. `--strict`: warnings also make the exit code 1. From PowerShell: `& "$env:ProgramFiles\Git\bin\bash.exe" docs/mkb/tools/mkb-check.sh`.
- Exit codes: 0 no errors (and no warnings under `--strict`); 1 errors found; 2 usage error. Output lines: `ERROR E<n> <path>: <message>`, `WARN W<n> <path>: <message>`, final line `mkb-check: <e> errors, <w> warnings`.
- Errors: E1 the same `id` value in two files (including `tasks/archive/`); E2 an ID file whose name differs from its `id`; E3 front matter violates section 12; E4 an ID file in the wrong directory for its prefix; E5 a file named `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` or `AGENTS.override.md` under `docs/mkb/`; E6 a mandatory file is missing: INDEX, RULES, OVERVIEW, CONSTRAINTS, CURRENT, NEXT, and with `profile: full` also ARCHITECTURE, and CONVENTIONS unless INDEX has the `conventions` override row (section 15).

## 14. Profile differences
| Rule | Minimal | Full |
|---|---|---|
| Files at adoption | INDEX, RULES, OVERVIEW, CONSTRAINTS, CURRENT, NEXT, `templates/`, `tools/mkb-check.sh`; ARCHITECTURE and CONVENTIONS are created when first needed | the minimal files plus `project/ARCHITECTURE.md` and `project/CONVENTIONS.md` (or an INDEX path override to `CONTRIBUTING.md`) |
| One branch per task | SHOULD; trunk-based sequential work is allowed | MUST |
| Claim visible to others before coding | SHOULD; one actor alone on the default branch: the claim is the first commit of the work (section 5, claim step 8) | MUST |
| One worktree per parallel local agent | MUST when agents run in parallel | MUST |
| Gardening cadence | monthly | weekly |
| `mkb-check.sh` in CI | optional | SHOULD (advisory, never blocks on warnings) |
| Staleness thresholds | section 13; W5 at 35 days | section 13; W5 at 14 days |

## 15. Path overrides and adopted directories
- INDEX `## Path overrides` rows have the exact form of the first three rows below; when a project adds its first override row, it deletes the `| none | - | - |` row.
- Rows that change with an override (both profiles, so that no link points to a missing file); the replacement rows are the last three below:
  - conventions: the CONVENTIONS Layout row and the Routing row "How code is written here" become rows four and five; this applies in the full profile too when `CONTRIBUTING.md` replaces CONVENTIONS.md.
  - decisions: the Layout row `decisions/ADR-NNN.md` names the adopted directory; the Routing row "What must never be broken" becomes row six; "Why something is the way it is" and "Docs about code you will touch" grep the adopted directory instead of `docs/mkb/decisions`.
  - tasks: the Layout rows for `tasks/` and the Routing rows "What to work on", "Who is working on what" and "What is blocked and on what" name the tracker and its saved queries instead of `git grep` commands.
```markdown
| conventions | `CONTRIBUTING.md` | no project/CONVENTIONS.md; CONTRIBUTING.md is authoritative |
| decisions | `docs/adr/NNNN-<slug>.md` | adr-tools directory adopted in place, native format; ID ADR-NNNN is the file `docs/adr/NNNN-*.md`, whose text does not contain it; run mkb-check with `--adr-dir docs/adr` |
| tasks | <tracker URL> | tracker is authoritative; no tasks/ |
| `project/CONVENTIONS.md` | project conventions not covered elsewhere (normative) | when needed, or see Path overrides |
| How code is written here | project/CONVENTIONS.md (if it exists), else `CONTRIBUTING.md` | - |
| What must never be broken | project/CONSTRAINTS.md, then accepted ADRs in `docs/adr/` | `git grep -l -i -E '^(status: *"?)?accepted' -- docs/adr` |
```
### Adopted ADR directory
- An existing ADR directory (`docs/adr/`, `doc/adr/`, `docs/decisions/`; adr-tools `NNNN-slug.md`, MADR) is adopted in place; never move or rename it (external links and tooling depend on names).
- Old and new ADRs keep the directory's native format, file naming and numbering; no MKB front matter is added. The MKB ADR rules apply (section 8: who decides, immutability, superseding); the MKB schema does not. Where section 8 sets `deciders` and `date`, record the deciders in the format's own deciders field if it has one, else as the line `Deciders: <handle>, <handle>` below the native status, and set the native date the same way; the rules that name `deciders` read that field or line.
- New ADRs use the directory's own template; if it lacks any of Context, Problem, Decision, Alternatives considered or Consequences, add the missing ones as sections.
- The ID in prose is `ADR-` plus that number (`ADR-NNNN`) and names the file `<dir>/NNNN-*.md`, whose text does not contain the ID: open it with `git ls-files "<dir>/NNNN-*"`, because `git grep -w` for the ID finds only the docs that cite it; allocate with `sh docs/mkb/tools/mkb-check.sh next ADR --adr-dir <dir>` (1 + the highest leading number of any `.md` file ever added directly in the directory on any ref, padded to the width of the existing numbers).
- Native statuses read as MKB statuses: `Proposed` -> `proposed`, `Accepted` -> `accepted`, `Rejected` -> `rejected`, `Deprecated` -> `deprecated`, `Superseded by N` -> `superseded`; only `accepted` ADRs bind. Legacy `Proposed` ADRs already on the default branch violate section 8: the lead accepts or rejects each one during adoption.
- Because file name differs from ID, the duplicate-number check (sh, then PowerShell) is mandatory before merges and in CI, and `mkb-check.sh` runs with `--adr-dir <that directory>` (it skips E2, E3 and E4 there; E1 becomes two files with the same leading number).
```sh
ls docs/adr | grep -oE '^[0-9]+' | sort | uniq -d     # must print nothing
```
```powershell
Get-ChildItem docs/adr -Name | Select-String '^\d+' | ForEach-Object { $_.Matches[0].Value } | Group-Object | Where-Object Count -gt 1
```
### External issue tracker
If the team's tasks already live in GitHub Issues, Jira or similar, that tracker is authoritative: `tasks/` is not used; work item IDs are the tracker keys (`GH-N`); handoffs are `handoff/GH-N.md`; claims are the tracker's assignee; `state/NEXT.md` lists tracker keys; INDEX gets the `tasks` path override row above.
Questions, ADRs, knowledge and state stay in the MKB.

## 16. Project-specific rules
None.
