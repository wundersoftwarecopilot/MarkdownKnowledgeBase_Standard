# 6. Handoff

*MKB Standard v1.0 · 2026-09-23 · Normative*

This chapter is the home of the handoff rules: where a handoff lives, what it holds, when it is written, overwritten and deleted, and how the next session reads it.

## 6.1 Purpose and boundary

A handoff is the transfer note for one unfinished task: where the work stands on the task's branch, what to do next, and what to read first.
It carries only what the next session needs to continue that task; it never duplicates the knowledge base.
`state/` describes the default branch; a handoff describes one unfinished task on its branch; neither holds knowledge.
The tests that separate knowledge, state and handoff are in [01-architecture.md](01-architecture.md) §1.6.
A handoff is the lowest authority (§6.6).
Humans write a handoff only when someone else will continue the work ([05-agent-workflow.md](05-agent-workflow.md) §5.1).
Rows T2, T3 and T4 of the trigger matrix fire the handoff steps ([05-agent-workflow.md](05-agent-workflow.md) §5.6).

## 6.2 File and location

Location: `docs/mkb/handoff/<work item ID>.md`, committed on the task branch (in trunk-based minimal projects, on the default branch).
It exists only while the task is unfinished.

- The file has no ID of its own and is named after the work item: `handoff/TASK-042.md`, or `handoff/GH-123.md` with an external tracker ([04-naming-and-linking.md](04-naming-and-linking.md) §4.2).
- It carries no front matter ([03-metadata.md](03-metadata.md) §3.1); `mkb-check.sh` applies only W1 and W4 to it, plus E3 when it contains front matter ([09-lifecycle.md](09-lifecycle.md) §9.7).
- The directory `handoff/` exists only once it holds a file ([02-directory-structure.md](02-directory-structure.md) §2.5); it lives on task branches and normally never on the default branch.
- A handoff reaches the default branch only in trunk-based work, with a partial PR (§6.5 item 5), or through a forgotten deletion, which gardening cleans up (W4, [09-lifecycle.md](09-lifecycle.md) §9.4).

## 6.3 Format

Create the file by copying `docs/mkb/templates/HANDOFF.md`, then delete every guide comment.

```markdown
# Handoff: TASK-NNN

Written YYYY-MM-DD by <handle> on branch `<branch>`.

## Where it stands
<!-- guide: 1-5 bullets: done, half-done, test and CI status; after writing this file, commit and push it together with all work; `git status` MUST be clean. -->

## Next steps
<!-- guide: numbered, concrete, in order; the first one can be started immediately. -->

## Watch out
<!-- guide: optional; traps specific to this in-flight work; durable gotchas go to a knowledge doc now, not here. -->

## Dead ends
<!-- guide: optional; approaches tried and rejected, one line each with the reason; a reason that stays true goes to a knowledge doc now, and the line names its ID. -->

## Read first
<!-- guide: IDs and paths the next session reads before anything else; pointers only, no copies. -->
```

- Required sections: Where it stands, Next steps, Read first.
- Optional sections: Watch out, Dead ends (delete the heading when empty).
- The sections are fixed; add no others.
- Hard limit: 30 lines including the H1.
- Line numbers in code references are allowed here only.
- The line under the H1 names the session's date, the writer's handle and the exact branch, in the forms of [04-naming-and-linking.md](04-naming-and-linking.md) §4.7.

## 6.4 What goes in and what never goes in

What goes in, by section:

| Content | Section |
|---|---|
| the state of the branch (pushed, CI result, what is half-done) | Where it stands |
| the exact next steps | Next steps |
| traps that apply only to this in-flight work | Watch out |
| approaches tried and rejected | Dead ends |
| IDs and paths to read first | Read first |

What never goes in:

| Never in a handoff | Where it goes instead |
|---|---|
| durable knowledge | its home doc, now; the handoff points to its ID ([05-agent-workflow.md](05-agent-workflow.md) §5.5) |
| decisions | an ADR ([07-decisions.md](07-decisions.md) §7.1) |
| project state | `state/CURRENT.md` ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.12) |
| task definition or completion notes | the task file ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.2) |
| a narrative of the session, praise, apologies | nowhere; the commits and the task's Completion are the record |
| code blocks longer than 5 lines, logs, stack traces, diffs, file lists that git already shows | nowhere; an exact error string that stays true goes in a `## Gotchas` line or a `TS-` doc ([05-agent-workflow.md](05-agent-workflow.md) §5.5) |
| secrets or credential values | nowhere in the MKB ([05-agent-workflow.md](05-agent-workflow.md) §5.5) |
| anything about other tasks | cross-task warnings go to `state/CURRENT.md`, section Warnings |

Watch out and Dead ends hold this in-flight work only; a durable gotcha, or the reason behind a dead end that stays true, goes to a knowledge doc now, and the handoff line names its ID.
Dead ends and Watch out lines that turn out to stay true after the merge move out when the task finishes (T3, §6.5 item 3).

## 6.5 Writing and rotation

1. The owner overwrites it at the end of every session that leaves the task unfinished, and at checkpoints before long or risky operations, then commits and pushes it together with all work (a WIP commit on your own branch is fine); `git status` is clean afterwards.
   A handoff that is not pushed does not exist for the next session.
2. It is always overwritten whole by the owner; the previous version stays in git.
3. It is deleted in the PR that sets the task `done` or `dropped`, after its lines that stay true have moved (T3, [05-agent-workflow.md](05-agent-workflow.md) §5.6).
4. On release (T4) it stays on the released branch.
   The next owner creates their branch from that branch's tip ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4.1 step 5), and the handoff on the new branch is theirs to verify and overwrite.
5. If a partial PR merges while the task continues, the handoff may reach the default branch; the next session continues on a new branch and updates `branch:`.
6. Gardening deletes any handoff on the default branch whose task is `done` or `dropped`, or that has no task.
7. Only the task owner writes it; nobody edits another actor's handoff (after a takeover, the copy on your own branch is yours).

A session that ends unfinished with no task yet first creates the task, already claimed by its actor, and then writes the handoff (T2).

Example (TareLog session S7): on 2026-09-15 Codex overwrites `handoff/TASK-004.md` on `codex/task-004-sftp-delivery` and pushes everything, then releases TASK-004 because Luca leaves for a week.
On 2026-09-16 claude-code claims it and runs `git switch -c claude-code/task-004-sftp-delivery origin/codex/task-004-sftp-delivery`, so the handoff arrives on its own branch, where it verifies the handoff and from then on owns it.

## 6.6 Reading a handoff

A handoff is the lowest authority.
Verify it against the branch (`git log`, `git status`, tests) before acting.
From another checkout: `git show origin/<branch>:docs/mkb/handoff/TASK-NNN.md`.

- Which handoff to read (on the task's branch, or on the released branch its Notes name): [05-agent-workflow.md](05-agent-workflow.md) §5.2 step 3.
- A handoff that contradicts the code: the code wins; fix or delete the item ([05-agent-workflow.md](05-agent-workflow.md) §5.7).
- The full authority orders: [01-architecture.md](01-architecture.md) §1.7.
- A durable doc never refers to a handoff file ([04-naming-and-linking.md](04-naming-and-linking.md) §4.8); a handoff is found through its task's `branch` field or release Notes line.

Example (TareLog session S7, before the takeover):

```sh
git show origin/codex/task-004-sftp-delivery:docs/mkb/handoff/TASK-004.md
```

## 6.7 Parallel safety

Different tasks write different files on different branches; git refuses to check out one branch in two worktrees; one task has one owner.
The remaining case, two actors on one branch, is a rule violation ([12-concurrency.md](12-concurrency.md) §12.1).
If it happens anyway, the later session re-reads the handoff and rewrites it by hand ([12-concurrency.md](12-concurrency.md) §12.6).

## 6.8 Why there is no `handoff/CURRENT.md` or `HISTORY.md`

The brief proposed `handoff/CURRENT.md` and `handoff/HISTORY.md`; v1.0 uses neither ([02-directory-structure.md](02-directory-structure.md) §2.6).
One shared CURRENT file is overwritten by every parallel session; HISTORY duplicates `git log` and task Completion sections.

History queries (the second works while the task branch exists):

```sh
git log --format="%cs %an %s" -- docs/mkb/tasks
git log -p origin/<branch> -- docs/mkb/handoff/TASK-NNN.md
```

Squash merges and automatic branch deletion drop a handoff's history by design; that is acceptable because T3 moves every Dead ends or Watch out line that stays true into a knowledge doc or the task's Notes before the handoff is deleted.

## 6.9 A good and a bad handoff

Both versions describe TareLog TASK-004 at the end of Codex's session on 2026-09-15, before it releases the task.
The handoffs of sessions S2 and S5 are shown in full in [examples/tarelog/WALKTHROUGH.md](../examples/tarelog/WALKTHROUGH.md).

### 6.9.1 Good

```markdown
# Handoff: TASK-004

Written 2026-09-15 by codex on branch `codex/task-004-sftp-delivery`.

## Where it stands
- CSV upload with key authentication works in `src/tarelog/delivery/sftp.py` (`upload_report()`); its tests pass locally and in CI.
- Not started: retry after a failed upload, and the alert e-mail.
- INT-HAULER-SFTP updated (`code`, a Gotchas line on parallel sessions, `verified: 2026-09-15`); branch pushed, `git status` clean.

## Next steps
1. In `upload_report()` (sftp.py:57), retry a failed upload 3 times, 5 minutes apart.
2. After the third failure, send an alert e-mail to `delivery.alert_to` through `src/tarelog/delivery/mailer.py`.
3. Test both with the local SFTP fixture, then close TASK-004.

## Watch out
- `src/tarelog/delivery/sftp.py:88` catches the paramiko timeout and only logs it; the retry replaces that `except` block instead of wrapping it.

## Dead ends
- Uploading several report days in parallel, one SFTP session each: the second session fails with `ChannelException: (1, 'Administratively prohibited')`; the partner allows one session per account (INT-HAULER-SFTP).

## Read first
- TASK-004 (criteria marked `resolves Q-001`), INT-HAULER-SFTP, ADR-003.
- [project/CONSTRAINTS.md](../project/CONSTRAINTS.md), sections Customer and contract (06:00 deadline) and Security and data.
```

Why it works:
- The file name names the task; the line under the H1 names the date, the writer and the branch.
- Where it stands can be checked against `git log`, `git status` and CI in a minute.
- The next steps are numbered and concrete, and the first one can be started immediately.
- The line numbers in Next steps and Watch out are allowed because a handoff is not a durable doc.
- The durable facts about the partner server (key authentication, vault path, target directory) are already in INT-HAULER-SFTP; the handoff only points to it.
- The Dead ends line rests on a lasting fact about the partner server, so Codex wrote it into INT-HAULER-SFTP, section Gotchas, when the error occurred (§6.4); the line names that doc, and T3 finds nothing left to move.
- It has 23 lines, within the limit of 30.

### 6.9.2 Bad

```markdown
# Handoff

## Session log 2026-09-15
Great progress today, sorry it took so long!
I read the whole docs/mkb tree first to get the full picture.
Password login failed, then key login worked once I found the key.

## Important info
- The SFTP key is in the vault at tarelog/sftp-key; files go to /inbound/tarelog/.
- We decided to send CSV instead of PDF because their ERP imports CSV only.
- Production runs v0.8.0.
- TASK-006 is also urgent: readings get lost while the report job holds the database lock.

## Last error
Traceback (most recent call last):
  File "src/tarelog/delivery/sftp.py", line 41, in connect
  ... (60 more lines pasted here)

## Remaining
- finish the retry stuff
```

### 6.9.3 What is wrong with the bad one

| In the bad handoff | Problem | Rule |
|---|---|---|
| `# Handoff` without the "Written" line | the task, date, writer and branch are unknown | §6.3 |
| Session log, "Great progress", "sorry" | a narrative of the session, praise, apologies | §6.4 |
| reading the whole tree | discovery skipped | [05-agent-workflow.md](05-agent-workflow.md) §5.3 |
| vault path and target directory | durable knowledge copied from INT-HAULER-SFTP instead of pointing to it | §6.4 |
| "We decided to send CSV" | a decision, already recorded as ADR-003 | §6.4 |
| "Production runs v0.8.0" | project state | §6.4 |
| TASK-006 is urgent | about another task; ordering goes to a `NEXT suggestion` line, warnings to `state/CURRENT.md` | §6.4, [05-agent-workflow.md](05-agent-workflow.md) §5.8 |
| the traceback | a stack trace | §6.4 |
| "finish the retry stuff" | no numbered, concrete next steps; no Read first section | §6.3 |
| sections Session log, Important info, Last error, Remaining | sections outside the fixed set | §6.3 |
