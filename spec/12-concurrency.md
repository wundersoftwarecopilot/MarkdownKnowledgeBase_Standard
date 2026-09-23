# 12. Concurrency

*MKB Standard v1.0 · 2026-09-23 · Normative*

This chapter defines how humans, local agents and cloud agents work on one repository at the same time.
Concurrent MKB work either merges cleanly or conflicts loudly; the rules below remove the cases where it would merge silently into a wrong state.
Claims, blockers and questions are defined in [08-tasks-and-questions.md](08-tasks-and-questions.md); this chapter defines the git mechanics they rely on.

## 12.1 Model

- One work item, one branch, one writer.
  Parallel local agents each use their own `git worktree`; git refuses to check out one branch in two worktrees.
- Never push to or force-push a branch you did not create; a cloud agent and a local agent never share a branch.
- Exception: once the session that owns a PR branch has ended, a human reviewer MAY add commits to it (for example to set an ADR to `accepted` during review); never force-push it.
- Two actors on one task at the same time is a claim violation, not a merge problem: the later actor stops.
- Rebase your branch onto the default branch at session start and before every push (push your own rebased branch with `git push --force-with-lease`); keep branches to a few days.
- Exception: after a renumber ([04-naming-and-linking.md](04-naming-and-linking.md) §4.4) a branch takes the default branch by `git merge origin/main` until it merges.

Rebasing a work branch at session start and before a push:

```sh
git fetch origin
git rebase origin/main
git push --force-with-lease
```

Note: unlike `--force`, `--force-with-lease` refuses the push when the remote branch has moved since your last fetch.

### 12.1.1 Where a change lands

Every MKB change reaches the default branch by one of two routes, and a handoff never leaves its task branch in normal operation.

| Change | Route | Visible to other actors |
|---|---|---|
| Coordination data: claims, releases, blocks, new tasks and questions, answers, resolutions, `state/CURRENT.md` facts that change outside a PR, `state/NEXT.md` edits by the lead | a coordination commit straight to the default branch (§12.2) | at once, after their next fetch |
| Code and the MKB changes that describe it: knowledge docs, ADRs, project docs, the task's `done` edit | the work branch | when the PR merges |
| The handoff of an unfinished task | the task branch ([06-handoff.md](06-handoff.md) §6.2) | when the branch is pushed |

Because claims and answers land on the default branch first, status queries read `origin/main`, not the local tree ([02-directory-structure.md](02-directory-structure.md) §2.4).
For the same reason a claim is checked with `git show origin/main:<path>`, never against a local copy ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4).

## 12.2 Coordination commits

Coordination commits change only MKB coordination data and go straight to the default branch: claims, releases, block and unblock, new tasks and new questions (at allocation, [04-naming-and-linking.md](04-naming-and-linking.md) §4.3), answers, resolutions (except when the promotion creates an ADR, [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.11), `state/CURRENT.md` facts that change outside a PR, and `state/NEXT.md` edits by the lead.
Everything else rides the work branch and reaches the default branch with the PR.

Each coordination change is defined in its home chapter; commit subjects are in [04-naming-and-linking.md](04-naming-and-linking.md) §4.6.

| Coordination change | Defined in |
|---|---|
| claim | [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4 |
| release | [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.5 |
| block and unblock | [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.7 |
| new task, at allocation | [04-naming-and-linking.md](04-naming-and-linking.md) §4.3, [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.1 |
| new question, at allocation | [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.9 |
| answer, and a resolution that creates no ADR | [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.11 |
| `state/CURRENT.md` fact that changes outside a PR (deployment, outage, freeze) | [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.12 |
| `state/NEXT.md` edit by the lead | [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.12 |

### 12.2.1 Recipe

The recipe does not disturb your working tree and works from any worktree.
The temporary worktree has a unique path under the system temp directory, so parallel sessions that share a handle never collide, and tools whose sandbox allows writes only to the workspace and temp directories can use it ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.5.4).

```sh
git fetch origin
git worktree prune                                   # forget worktrees whose directory is gone (crashed sessions)
d="$(mktemp -d)"                                     # new empty directory, unique per call
git worktree add --detach "$d" origin/main
# edit the one MKB file (or the file plus the task it blocks) inside "$d"
git -C "$d" add -A
git -C "$d" commit -m "TASK-NNN: blocked on Q-NNN"
git -C "$d" push origin HEAD:main
# rejected: git -C "$d" fetch origin, then git -C "$d" rebase origin/main, then push again
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
# rejected: fetch, rebase origin/main and push again, as in sh
git worktree remove --force $d                        # only the worktree you created in this step
git fetch origin; git rebase origin/main              # in your work branch, after committing your work
```

An agent that cannot fetch or push stops before coding and asks the human to push the claim ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4); what each local tool needs is in [13-adoption-and-integration.md](13-adoption-and-integration.md) §13.5.4.

### 12.2.2 When the push is rejected

The push to `main` succeeds only when nobody changed the default branch since your fetch, so it works as a compare-and-swap.
After a rejected push, fetch and rebase the temporary worktree onto `origin/main`, then read the result:

- The rebase is clean and `git rev-list --count origin/main..HEAD` does not print `0`: someone changed other files; push again.
- An add/add conflict on a new `tasks/TASK-NNN.md` or `questions/Q-NNN.md`: someone took that number; abort and allocate again ([04-naming-and-linking.md](04-naming-and-linking.md) §4.3).
- A conflict on the task file you are claiming, or a count of `0` after a clean claim rebase (an identical claim is already there): the task is taken; pick another ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4).
- A conflict on any other MKB file: someone changed it first; abort, re-read, decide again.

Example: in TareLog session S2 (2026-09-02), claude-code allocated TASK-005 in its temporary worktree while marta pushed her own TASK-005 between claude-code's fetch and its push.

```text
$ git -C "$d" push origin HEAD:main
 ! [rejected]        HEAD -> main (fetch first)
$ git -C "$d" fetch origin
$ git -C "$d" rebase origin/main
CONFLICT (add/add): Merge conflict in docs/mkb/tasks/TASK-005.md
$ git -C "$d" rebase --abort
```

claude-code allocated again, created TASK-006 and pushed `TASK-006: add`.
Nothing referred to TASK-005 yet, so nothing was renumbered; only after that push did claude-code cite TASK-006 in a code comment on its branch.

### 12.2.3 Protected default branch

Protected default branch: coordination changes become one-file PRs labelled `mkb-coord`, merged by the first human who sees them; claims use the protected-branch variant of the claiming protocol, in which the pushed task branch is the claim ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4).
An ID collision between two open `mkb-coord` PRs is fixed by renumbering the later one ([04-naming-and-linking.md](04-naming-and-linking.md) §4.4).

Note: until an `mkb-coord` PR merges, its change is not on `origin/main`, so status queries do not show it yet.

### 12.2.4 No remote

No remote: the same recipe with `git worktree add "$d" main` (a real checkout of `main`, no `--detach`, no fetch or push) when `main` is not checked out anywhere; otherwise commit in the worktree that has `main` checked out only if its working tree is clean; otherwise ask the human.

```sh
git worktree prune
d="$(mktemp -d)"
git worktree add "$d" main                           # refused while main is checked out in another worktree
# edit the one MKB file inside "$d"
git -C "$d" add -A
git -C "$d" commit -m "TASK-NNN: claim"
git worktree remove --force "$d"
git rebase main                                      # in your work branch, after committing your work
```

```powershell
git worktree prune
$d = Join-Path ([IO.Path]::GetTempPath()) ("mkb-coord-" + [guid]::NewGuid())
git worktree add $d main
# edit the one MKB file inside $d
git -C $d add -A
git -C $d commit -m "TASK-NNN: claim"
git worktree remove --force $d
git rebase main
```

Every other adaptation for a repository without a remote is listed in [13-adoption-and-integration.md](13-adoption-and-integration.md) §13.7.

## 12.3 Hot files and merge classes

| File | Class | Concurrent writers | Merge outcome |
|---|---|---|---|
| `tasks/TASK-NNN.md` | per-item | no (owner only; others append Notes) | different tasks: clean; same task: loud conflict on status, owner, branch |
| `decisions/ADR-NNN.md` | per-item, frozen | no | ID collision: add/add conflict |
| `questions/Q-NNN.md` | per-item | sequential (asker, then owner) | clean |
| `knowledge/**/<ID>.md` | per-item | occasionally | one sentence per line keeps conflicts to the sentence; parallel bumps conflict on the `verified` line (§12.6); same new subject: add/add |
| `handoff/TASK-NNN.md` | per-branch | never | never conflicts |
| `state/CURRENT.md` | record file | yes, rarely | different bullets: clean unless adjacent; same bullet: loud |
| `state/NEXT.md` | single writer | no (lead) | clean |
| INDEX, project/*, RULES, templates, tools | slow reference | rarely | resolved by hand with human review |

The classes mean:

- Per-item: one file per record, so work on different records touches different files.
- Per-branch: the file lives on one task branch and has one writer, the task owner.
- Record file: several actors add, re-date or delete separate dated bullets.
- Single writer: one person writes the file.
- Slow reference: the file changes rarely, through reviewed PRs.

No committed file lists tasks, blockers or questions: the board and the blocker and question views are `git grep` queries ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.8), so there is no shared list to conflict on.
Why the brief's shared lists became per-item files: [02-directory-structure.md](02-directory-structure.md) §2.6.

## 12.4 Formatting for mergeability

These rules apply to all MKB files.

- One sentence per line in prose; never hard-wrap or re-flow a paragraph.
- Tables use minimal spacing `| a | b |` with the separator `|---|---|`, never column-aligned.
- Lists use `-`; ordered lists use `1.`; `state/NEXT.md` uses `-` so reordering does not renumber.
- Append new items at the designated spot; never sort, reorder or reformat existing lines.
- LF line endings ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.1.1), UTF-8 without BOM.
- No "Last updated" lines anywhere.
- New front matter keys go in template order ([03-metadata.md](03-metadata.md) §3.5); existing keys are never reordered.

| Rule | What it prevents |
|---|---|
| One sentence per line | Hard-wrapped, a change to one sentence re-flows the rest of the paragraph, so any parallel edit to that paragraph conflicts. |
| Tables never column-aligned | One wider cell re-pads every row, so two edits to different rows conflict. |
| `-` bullets in `state/NEXT.md` | Reordering a numbered list rewrites every number. |
| Append, never sort or reformat | A re-sorted file turns every line into a change. |
| LF line endings | Mixed CRLF and LF checkouts make every line differ. |
| No "Last updated" lines | Every edit changes the same line, so every pair of edits conflicts. |
| Front matter keys never reordered | A reorder rewrites the block that every claim and status change also edits. |

Example: a correction to one sentence of INT-WI200 is a one-line diff, so a parallel edit to a non-adjacent sentence of the same paragraph merges cleanly.

```diff
 The WI-200 sends stable (ST) and unstable (US) frames; US frames are never stored.
-Each TCP read holds one frame.
+A frame can span several TCP reads, because the converters deliver 64-byte chunks.
 A frame without ETX raises `FrameError: missing ETX`.
```

## 12.5 Lost-update guard

An agent's in-context copy of a file may be hours old.
Re-read the file from disk right before editing it, patch only the lines you mean to change, and never write a whole MKB file regenerated from memory.
If the file changed since you first read it, merge your intent into the new content.

Git cannot see this failure.
A file rewritten from a stale copy is an ordinary edit on your branch: it merges cleanly and silently reverts the lines that others added in between.
The guard is the only protection, which is why the agent block repeats it ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.5.1) and why regenerating a file from memory is anti-pattern 18 ([10-anti-patterns.md](10-anti-patterns.md)).

Note: `git diff -- <file>` before committing shows whether the diff holds only the lines you meant to change.

## 12.6 Conflict cookbook

The cookbook covers MKB files only.

| Conflict | Resolution |
|---|---|
| add/add on `tasks/TASK-NNN.md` or `questions/Q-NNN.md` in the coordination worktree | ID taken at creation: abort the rebase, allocate the next number, retry ([04-naming-and-linking.md](04-naming-and-linking.md) §4.3) |
| add/add on `decisions/ADR-NNN.md`, or on an ID already on a branch | ID collision: the branch merging second renumbers its own item ([04-naming-and-linking.md](04-naming-and-linking.md) §4.4) |
| add/add on a knowledge doc | same subject documented twice: merge the content into one doc |
| a knowledge doc's `verified` line | both sides bumped it: keep the older date, unless you re-check the merged doc against the merged code |
| task `status`, `owner`, `branch` lines | claim race: the default branch wins; the other actor stops and picks another task |
| task Notes, acceptance criteria, `related`, `code` | keep both sides; Notes in date order |
| `state/CURRENT.md` bullets | keep both sides; for the same bullet keep the newer date; a deletion wins when the fact is no longer true |
| `state/NEXT.md` | the lead's version wins |
| a handoff file | two writers on one branch (rule violation): the later session re-reads and rewrites it by hand |
| an accepted ADR body | restore the default branch's version; move the change into a superseding ADR |
| knowledge or project prose | resolve sentence by sentence against the code; if unsure keep both and add a STALE banner ([09-lifecycle.md](09-lifecycle.md) §9.5) |
| INDEX.md | keep the union of rows |
| RULES.md above section 16, templates, tools | take the default branch's version |

Never resolve MKB conflicts with `-X ours`, `-X theirs` or "accept all"; during a rebase "ours" means the upstream side.

Resolving a conflict during a rebase:

```sh
git status                                           # lists the conflicted files
# edit each conflicted MKB file by hand, following the table above
git add <file>
git rebase --continue
```

Note: during a rebase, the side marked `HEAD` in the conflict markers is the upstream side (the default branch plus your commits already replayed), and the other side is the commit being replayed.
Note: `sh docs/mkb/tools/mkb-check.sh` after a hand resolution catches front matter that the merge left invalid (error E3, [09-lifecycle.md](09-lifecycle.md) §9.7).

Example: in TareLog session S7, the TASK-007 session's rebase onto `origin/main` after PR #15 conflicted on the `verified` line of MODULE-REPORTS, which both branches had bumped.
The session re-checked the merged doc against the merged code and kept `verified: 2026-09-17`.

## 12.7 Parallel agents, worktrees and cloud agents

- Local parallel agents: one worktree and one branch each, named `<actor>/task-nnn-<slug>`.
- Cloud agents: the dispatching human claims ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4, including its protected-branch variant) and selects the task branch when resuming, so the agent sees its handoff.
- Humans editing inside an agent's worktree or branch while it runs is forbidden.
- Hot-file edits SHOULD be separate small commits so they re-apply easily after a rebase.

### 12.7.1 Local worktrees

A local agent claims first (§12.2.1), then creates its branch (in its own worktree when agents work in parallel locally) and pushes it at once ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4).

Example: the second claude-code session of TareLog session S7 starts TASK-007 next to the checkout that holds TASK-004.

```sh
git fetch origin
git worktree add -b claude-code/task-007-remove-chromium ../tarelog-task-007 origin/main
git -C ../tarelog-task-007 push -u origin claude-code/task-007-remove-chromium
```

Once the work is merged or released, `git worktree remove ../tarelog-task-007` removes the checkout; a released branch stays on the remote with its handoff.

### 12.7.2 Sessions that share a handle

Parallel sessions of the same tool share its handle; the `branch` field tells them apart; never invent handles like `claude-2` ([03-metadata.md](03-metadata.md) §3.4).
When an owned task is yours, and when it belongs to another session of your tool, is defined in [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4.

Example: in TareLog session S7, two claude-code sessions hold TASK-004 (`branch: claude-code/task-004-sftp-delivery`) and TASK-007 (`branch: claude-code/task-007-remove-chromium`), each in its own worktree.

A task can also pass between tools: a released task's next owner branches from the released branch and takes over its handoff ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4, [06-handoff.md](06-handoff.md) §6.5).
TareLog session S7 shows a Codex-to-Claude-Code takeover of TASK-004.

### 12.7.3 Agents that cannot push to the default branch

| Actor | Claims | New TASK and Q IDs | Branch |
|---|---|---|---|
| Human, or local agent that can push to the default branch | itself, as a coordination commit | allocates them and pushes the files at once ([04-naming-and-linking.md](04-naming-and-linking.md) §4.3) | its own, in its own worktree |
| Dispatched agent that cannot push to the default branch (for example Codex cloud and the Copilot coding agent) | the dispatching human, before dispatch, with `branch: pending` if the tool names the branch later ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4) | never allocates them; writes `New task: <title>` or `Question for <handle>: <question>` lines, and the dispatching human creates the records ([05-agent-workflow.md](05-agent-workflow.md) §5.8) | the tool's own branch, recorded in `branch:` in its PR |

A dispatched task that stays `in-progress` with `branch: pending` and no change to its file on the default branch for 7 days is a stale dispatch; the dispatching human releases it ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.5).

Example: in TareLog session S3, marta claims TASK-003 for Codex cloud with `TASK-003: claim for codex` and `branch: pending`; Codex ends PR #11 with `New task: Per-customer report time zone`, and marta creates TASK-005 from it.

## 12.8 Why the design is merge-safe

| Collision | How it surfaces | Outcome |
|---|---|---|
| Two actors claim the same task | the later claim push is rejected and its rebase conflicts on `tasks/TASK-NNN.md`; an identical claim from another session with the same handle leaves `git rev-list --count origin/main..HEAD` at `0` | the later actor picks another task ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4) |
| Two actors create the same TASK or Q number | the later push is rejected, then an add/add conflict in the coordination worktree | abort, allocate the next number, retry ([04-naming-and-linking.md](04-naming-and-linking.md) §4.3) |
| Two branches add the same ADR number, or two open `mkb-coord` PRs add the same ID | add/add conflict on rebase, merge or PR | the branch that merges second renumbers its own item ([04-naming-and-linking.md](04-naming-and-linking.md) §4.4) |
| A duplicate git cannot see (a new item whose number an archived task already has; an adopted ADR directory) | `mkb-check.sh` error E1; the duplicate-number check of [13-adoption-and-integration.md](13-adoption-and-integration.md) §13.4 | renumber ([04-naming-and-linking.md](04-naming-and-linking.md) §4.4) |
| Two branches change different tasks | nothing: different files | - |
| Two branches change the claim lines of one task | loud conflict on `status`, `owner`, `branch` | the default branch wins (§12.6) |
| Two local sessions on one branch | git refuses to check out one branch in two worktrees | each session takes its own branch (§12.7) |
| Two actors on one task from different checkouts | the later actor's claim check shows the task `in-progress` with another owner or branch ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4) | claim violation: the later actor stops (§12.1) |
| Parallel edits to one knowledge doc | conflicts only on sentences both sides changed, and on a doubly bumped `verified` line | the cookbook (§12.6) |
| Two new knowledge docs with the same name | add/add conflict | merge the content into one doc (§12.6) |
| Parallel `state/CURRENT.md` edits | clean for different bullets unless adjacent; loud for the same bullet | the cookbook (§12.6) |
| `state/NEXT.md`, handoffs | cannot collide: one writer each | - |
| Boards, blocker lists, question lists | cannot collide: they are queries, not files ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.8) | - |
| A file regenerated from a stale in-context copy | nothing: git merges it as an ordinary edit | prevented by the lost-update guard (§12.5) |
| A claim edited locally but never pushed | nothing: other actors cannot see it | prevented: never code on an unpushed claim ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4) |

In the last two rows nothing surfaces at all; only the rules prevent them.
The concurrency anti-patterns are items 15 to 21 of [10-anti-patterns.md](10-anti-patterns.md).
