# 5. Agent workflow

*MKB Standard v1.0 · 2026-09-23 · Normative*

This chapter is the home of the session workflow: what an actor reads before modifying code, how it finds the docs that bind its change, what it records while working, and what it updates before it stops.

## 5.1 Session overview

A session follows the same phases whatever the tool or the actor:

| Phase | What you do | Section |
|---|---|---|
| Before modifying code | update your branch, read the fixed files, know and claim your work item, find the docs that bind your change | §5.2, §5.3 |
| Small change | follow the lite path instead of the full workflow | §5.4 |
| While working | stay within constraints and accepted ADRs, record discoveries when you make them, resolve contradictions | §5.5, §5.7 |
| After working | walk the trigger matrix, report what needs a human | §5.6, §5.8 |

Humans follow the same rules; the only difference is that a human writes a handoff only when someone else will continue the work.

In one line: fetch and rebase onto the default branch, read a fixed small set of files, find everything else with `git grep` and front-matter triage (at most 5 docs read in full), claim before coding, record discoveries when you make them, walk the trigger matrix at the end, and update nothing when nothing durable changed.

What a session reads:

| Read | When |
|---|---|
| `docs/mkb/INDEX.md` | once per session |
| `docs/mkb/state/CURRENT.md` | every session |
| `docs/mkb/state/NEXT.md` | only when you must choose a task |
| the task file and its handoff | when you work on a task |
| docs found by discovery (§5.3) | front matter first; at most 5 in full |
| `docs/mkb/agents/RULES.md` | only the section a step needs (`git grep -n "^## " -- docs/mkb/agents/RULES.md` lists them); never whole |
| `tasks/archive/`, `templates/`, superseded or rejected ADRs, git history | never by default |

Adopting projects carry the rules of this chapter as sections 1 to 3 of `docs/mkb/agents/RULES.md` ([templates/full/docs/mkb/agents/RULES.md](../templates/full/docs/mkb/agents/RULES.md)).
The agent block in root `AGENTS.md` condenses them ([agent-instructions/AGENTS.tmpl.md](../agent-instructions/AGENTS.tmpl.md)); which tools load that file is in [13-adoption-and-integration.md](13-adoption-and-integration.md) §13.5.
Which document wins when two disagree is set by the authority orders of [01-architecture.md](01-architecture.md) §1.7.

Reading aids for this chapter:
- T1 to T22 are the rows of the trigger matrix (§5.6).
- W4, W5 and the other check codes are `mkb-check.sh` warnings ([09-lifecycle.md](09-lifecycle.md) §9.4).
- Commands write the default branch as `main`; a project whose default branch has another name uses that name.
- Without a remote, `origin/main` means local `main` ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.7).

## 5.2 Before modifying code

1. Update and read:
   - `git fetch`, then rebase your branch onto `origin/main` (on `main` itself: `git pull --rebase`), so that you see the claims, answers and docs that landed since your branch was cut;
   - `docs/mkb/INDEX.md` (skip if already read in this session);
   - `docs/mkb/state/CURRENT.md`;
   - `docs/mkb/state/NEXT.md`, only if you must choose a task.
2. Know your work item:
   - the task you were given, else the first ID in `state/NEXT.md` whose task on the default branch is `todo` with `owner: none` or you, else ask the human;
   - no task exists and the work will outlast this session, or will be handed to someone else: create one from `templates/TASK.md` ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.1; a coordination commit, [04-naming-and-linking.md](04-naming-and-linking.md) §4.3 step 6);
   - work you will finish in this session needs no task (if it ends unfinished after all, T2 creates one).
3. Read the task file.
   If its Notes say `released; partial work on branch <branch>`, read the handoff on that branch and take over from it ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4.1 step 5); otherwise read `handoff/TASK-NNN.md` on the task's branch if it exists.
   Verify its "Where it stands" against `git log` and `git status` before trusting it.
4. Claim before touching code ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4), unless the task is already yours (§8.4.1 step 7).
5. Run the discovery algorithm (§5.3).
6. If `state/CURRENT.md` has a bullet older than the W5 threshold (14 days in the full profile, 35 in the minimal profile), or `docs/mkb/handoff/` on the default branch holds a file whose task is `done`, `dropped` or missing (W4), add `Gardening due` to your `MKB for humans:` lines (§5.8); do not garden unasked, except micro-fixes ([09-lifecycle.md](09-lifecycle.md) §9.6).

How to read a handoff and how far to trust it: [06-handoff.md](06-handoff.md) §6.6.

Example: in TareLog session S4, claude-code resumes TASK-002 with `git fetch`, a clean rebase of `claude-code/task-002-wi200-parser` onto `origin/main`, and `handoff/TASK-002.md` verified against `git log` before the parser work continues.

## 5.3 Discovery algorithm

Discovery finds the few docs that bind your change without browsing the tree.
It searches IDs, `code` paths and error text with `git grep`, and reads front matter before it reads any doc in full.

```text
Seeds S = IDs in the task's related and body
        + paths in the task's code
        + paths you expect to touch
        + exact error text you are investigating
Code owners:          git grep "^code:" -- docs/mkb/knowledge docs/mkb/tasks
                      (one line per doc) keep every doc with an entry that is a prefix
                      of a path in S; a directory entry ends with "/", a file entry
                      matches only that file
For each ID in S:     git grep -l -w "<ID>" -- docs/mkb
For each path in S:   git grep -l -F "<path>" -- docs/mkb          (mentions in prose)
For each error text:  git grep -l -F "<exact error text>" -- docs/mkb/knowledge
Reverse hop:          for each knowledge doc kept, git grep -l -w "<its ID>" -- docs/mkb/decisions
With an adopted ADR directory (INDEX Path overrides), search it wherever this names docs/mkb/decisions.
Ignore hits in docs/mkb/templates/ and docs/mkb/tasks/archive/.
Triage each hit by reading only its first 16 lines (front matter + H1):
  keep it if its code overlaps your paths, its summary matches your work,
  or it is an ADR with status accepted; drop proposed/rejected/superseded/deprecated ADRs.
  A task that is in-progress, not yours (§8.4.1 step 7), and whose code
  covers your paths: tell the human before you edit those paths.
Read in full, in this order, at most 5 docs:
  1. project/CONSTRAINTS.md (always, when your change alters behavior)
  2. accepted ADRs among the hits
  3. knowledge docs whose code covers your paths
  4. the relevant row or section of project/ARCHITECTURE.md
  5. anything else among the hits
Follow related IDs one hop only, and only when the linked doc constrains your change.
Stop when, for every path you will touch, you can name:
  its knowledge doc (or "none"), the constraints and accepted ADRs that bind it,
  and the open questions, blocked tasks and other in-progress tasks that touch it.
Needed more than 5 docs? Read them, then add "Routing gap: <what was hard to find>"
  to your MKB for humans lines (§5.8); gardening adds a Routing row to INDEX.
No code owner AND no hit for git grep -i "^summary:.*<word>" -- docs/mkb/knowledge:
  the knowledge is missing, and you will probably write it.
Never read by default: tasks/archive/, templates/, superseded or rejected ADRs, git history.
```

Notes:
- Run discovery after step 1 of §5.2 (branch rebased onto `origin/main`), so the working tree holds the current docs and tasks.
- `git grep` searches tracked files; add `--untracked` to include files not yet committed.
- Triage reads 16 lines because they always hold the front matter and the H1 ([03-metadata.md](03-metadata.md) §3.2, rule 10).
- The Routing table of INDEX.md lists the same queries by need ([02-directory-structure.md](02-directory-structure.md) §2.4).
- The adopted ADR directory, if any, is named in the Path overrides of INDEX.md ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.4).

Triage command, sh first and PowerShell second:

```sh
head -n 16 docs/mkb/knowledge/services/SERVICE-GATEWAY.md
```

```powershell
Get-Content -TotalCount 16 docs/mkb/knowledge/services/SERVICE-GATEWAY.md
```

Example of the prefix match: the line `docs/mkb/knowledge/services/SERVICE-GATEWAY.md:code: [src/tarelog/gateway/]` keeps SERVICE-GATEWAY for a change to `src/tarelog/gateway/reader.py`.

Example: discovery for TareLog TASK-002 in session S2 (full output in [examples/tarelog/WALKTHROUGH.md](../examples/tarelog/WALKTHROUGH.md), section S2):
1. Seeds: TASK-002, the task's `code` entry `src/tarelog/gateway/`, and the file to change, `src/tarelog/gateway/wi200.py`.
2. Code owners: SERVICE-GATEWAY, whose entry `src/tarelog/gateway/` is a prefix of `src/tarelog/gateway/wi200.py`.
3. `git grep -l -w SERVICE-GATEWAY -- docs/mkb` adds `docs/mkb/project/ARCHITECTURE.md`.
4. Reverse hop: `git grep -l -w SERVICE-GATEWAY -- docs/mkb/decisions` finds no ADR.
5. Read in full: CONSTRAINTS.md, SERVICE-GATEWAY and the Reader service row of ARCHITECTURE.md, 3 docs.

## 5.4 Lite path

The lite path applies only when ALL hold:
- the change touches at most 3 files;
- it adds or changes no interface, configuration key, dependency, schema or external contract;
- it will be finished in this session;
- no task needs claiming.

Steps (item 1 of the agent block in [agent-instructions/AGENTS.tmpl.md](../agent-instructions/AGENTS.tmpl.md) carries them inline):
1. Read the `## Warnings` section of `state/CURRENT.md`.
2. For the files you touch and the errors you chase, run the code-owner match, the path search and the error-text search of §5.3; read any hit that is CONSTRAINTS.md, an accepted ADR or a knowledge doc.
   Another actor's `in-progress` task whose `code` covers your files: tell the human before editing.
3. After the change, fix any doc your change makes wrong (T11, T19); otherwise update nothing (T22).
4. If anything surprises you, or the session ends with the work unfinished, switch to the full workflow (T2 creates the task).

Note: in the agent block the lite path comes after the fetch and rebase of §5.2 step 1, so it also works on current docs.

Example: fixing an off-by-one error in the ticket list pagination in `src/tarelog/web/`, finished in the same session, takes the lite path; if the fix turns out to need a schema change, the session switches to the full workflow.

## 5.5 While working

1. Constraints and accepted ADRs bind you.
   To deviate, write a `proposed` ADR or open a question; never edit an accepted ADR; never decide an ADR's status on your own authority: write `accepted` or `rejected` only to record a decision a named human makes in this session, and list them in `deciders` ([07-decisions.md](07-decisions.md) §7.4).
2. Record a discovery when you make it, not at the end of the session, in its home doc (§5.6), linked by bare ID, never copied.
3. Knowledge threshold: write it down only if the code does not make it evident within 5 minutes AND at least one holds: it cost more than 30 minutes to learn; it lives outside the repository (device, vendor, production, customer); it spans several files; it is an invariant the code cannot enforce.
4. Where to write it, in order of preference: a code comment if it concerns one place in the code; a section of an existing doc (search first); a new doc last.
5. A gotcha about one module, service, store or integration goes in that doc's `## Gotchas`; a cross-cutting or environment problem goes in a `TS-` doc.
   Quote exact error strings so grep finds them.
6. A decision meeting the ADR criteria of [07-decisions.md](07-decisions.md) §7.1 becomes a `proposed` ADR on your branch.
7. Work found outside your task's scope becomes a new task (`todo`, `owner: none`), pushed to the default branch at once ([04-naming-and-linking.md](04-naming-and-linking.md) §4.3 step 6); do not widen your task.
8. Commit subjects start with the task ID; MKB changes go in the same commit or PR as the code they describe.
9. Re-read an MKB file from disk right before editing it and patch only the lines you mean to change ([12-concurrency.md](12-concurrency.md) §12.5).
10. Never put secrets, credential values, personal data of customers or patients, logs longer than 5 lines, stack traces, diffs or chat transcripts in the MKB.

Example: in TareLog session S2, claude-code learns that the serial-to-Ethernet converters deliver 64-byte chunks, so WI-200 frames split across TCP reads.
The fact lives outside the repository and took time to learn, so it goes into a new INT-WI200 at once (T12), with the literal error `FrameError: missing ETX` so grep finds it.

## 5.6 Update-trigger matrix

Walk every row; update only the rows that fire.
"Coordination" means the change is pushed to the default branch immediately ([12-concurrency.md](12-concurrency.md) §12.2).

| # | If your work... | Update |
|---|---|---|
| T1 | started a task | claim: `status: in-progress`, `owner`, `branch` (coordination) |
| T2 | stopped with the work unfinished | no task yet: first create it ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.1) already claimed, `status: in-progress`, `owner: <you>`, `branch: <current branch>` (coordination); then overwrite `handoff/TASK-NNN.md` on the task branch and commit and push everything including it; `git status` clean |
| T3 | finished a task | tick criteria; `status: done`; `closed`; fill `## Completion`; move each Dead ends or Watch out line of the handoff that stays true after the merge into the owning knowledge doc's `## Gotchas` (§5.5 threshold) or a Notes line of the task; delete `handoff/TASK-NNN.md`; all in the delivering PR (trunk-based: [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.6) |
| T4 | will not continue a task that someone else may continue | release: `status: todo`, `owner: none`, remove `branch`, Notes line naming the branch with partial work; keep the handoff on that branch (coordination) |
| T5 | showed a task should not be done | propose dropping it to a human; on their decision: `status: dropped`, `closed`, reason and decider in `## Completion` |
| T6 | needs an answer only a person can give | new `questions/Q-NNN.md` with `owner` = that person; task `status: blocked`, `blocked_by: [Q-NNN]`, Notes line (coordination) |
| T7 | is blocked by other work or an external party | existing or new task owned by whoever must act; `blocked_by: [TASK-NNN]` (coordination) |
| T8 | got an answer or saw a blocker resolved | promote the answer ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.11), delete the question; remove `blocked_by`; status back to `in-progress` if `branch` is set, otherwise `todo` (owner unchanged) (coordination; a PR when the promotion creates an ADR, §8.11) |
| T9 | chose between real alternatives with lasting effect ([07-decisions.md](07-decisions.md) §7.1) | new ADR, `status: proposed`; a human listed in `deciders` accepts or rejects it before merge (§7.4); list it under `ADR decisions needed` (§5.8) |
| T10 | reverses or replaces an accepted ADR | new ADR with `supersedes`; old ADR gets `status: superseded` and `superseded_by`; same PR |
| T11 | changed the behavior, interface or invariants of a module, service, schema or integration | the knowledge doc whose `code` covers the change, in the same PR: check it against your change, fix what is wrong, bump `verified` |
| T12 | needed to reverse-engineer something undocumented, or met a gotcha (§5.5 threshold) | extend the owning knowledge doc, or create one from its template; cross-cutting problems: a `TS-` doc |
| T13 | added, removed or re-bounded a component | the Components table in `project/ARCHITECTURE.md`; a knowledge doc if the component is not trivial |
| T14 | deleted a component, integration or store | delete its knowledge doc and its ARCHITECTURE row in the same PR; repoint references |
| T15 | changed build, run or test commands, the stack or dependencies | `project/OVERVIEW.md` (Stack, Commands), or `README.md` if that is where commands live |
| T16 | learned a non-negotiable rule | a human states it: `project/CONSTRAINTS.md` with source and date; otherwise a question to the lead |
| T17 | introduced a team-wide convention | `project/CONVENTIONS.md` through a PR a human approves |
| T18 | changed a project-level fact of the default branch (build red or green, deployed version, known breakage, freeze) | a dated bullet in `state/CURRENT.md`, in the delivering PR or as a coordination commit |
| T19 | found a doc that contradicts the code | fix it now if small and in scope; otherwise a `> STALE` banner plus a task ([09-lifecycle.md](09-lifecycle.md) §9.5) |
| T20 | discovered work outside your scope | new task, `todo`, `owner: none`, pushed to the default branch at once ([04-naming-and-linking.md](04-naming-and-linking.md) §4.3 step 6) |
| T21 | changed what should happen next | `NEXT suggestion: <ID> <why>` in your `MKB for humans:` lines (§5.8); only the lead edits `state/NEXT.md` |
| T22 | changed nothing durable (local refactor, bug fix with no new knowledge, rename, formatting) | nothing; the commit message is the record. Exception: you touched a path in a knowledge doc's `code` and the doc is still right: bump its `verified` in the same PR |

Note: T1 to T8 change tasks, questions and handoffs; T9 and T10 change ADRs; T11 to T17 change knowledge and project docs; T18 and T21 concern the state files; T19 and T20 handle contradicting docs and new work; T22 is the common case.

Note: the brief asked every session to update `state/CURRENT.md` and `state/NEXT.md`; this matrix changes CURRENT only on a project-level fact (T18) and leaves NEXT to the lead (T21), which avoids churn and conflicts ([02-directory-structure.md](02-directory-structure.md) §2.6).

Example: in TareLog session S5, Codex's rows T1 (claim of TASK-004), T6 (Q-001 and the block, in one coordination commit) and T2 (its handoff) fired.

## 5.7 Resolving contradictions

The authority orders behind this table are in [01-architecture.md](01-architecture.md) §1.7.

| An agent finds that... | It does |
|---|---|
| a descriptive doc (knowledge, ARCHITECTURE, OVERVIEW, state, handoff) contradicts the code, and the fix is small and in scope | fix the doc in the same commit; mention it in the commit message; bump `verified` for what you checked ([03-metadata.md](03-metadata.md) §3.3) |
| the same, but the fix is large or out of scope | add a `> STALE` banner ([09-lifecycle.md](09-lifecycle.md) §9.5) and a task; do not rely on the stale text |
| the code violates CONSTRAINTS.md or an accepted ADR | never edit the constraint or ADR to match the code; fix the code only if that is inside your task, citing the ID in a comment; otherwise open a question to the lead and mention it in your handoff |
| the task's acceptance criteria contradict an accepted ADR or a constraint | stop that part; open a question, or draft a `proposed` superseding ADR, and wait for a human |
| a human in the session tells you to break an accepted ADR or a constraint | point out the conflict; if they confirm, write the superseding ADR (`deciders` = that human) or have them edit CONSTRAINTS.md, before or together with the code |
| two accepted ADRs conflict without a `supersedes` link | follow the newer one and open a question to the lead |
| a handoff or state bullet contradicts the code | the code wins; fix or delete the item |

Never change code to match a descriptive doc.

## 5.8 Reporting to humans: the `MKB for humans:` lines

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

- `Questions`: questions you created ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.9).
- `ADR decisions needed`: `proposed` ADRs in this PR ([07-decisions.md](07-decisions.md) §7.4).
- `NEXT suggestion`: T21.
- `Routing gap`: §5.3.
- `Gardening due`: §5.2 step 6.
- `New task` and `Question for`: only agents that cannot push to the default branch ([04-naming-and-linking.md](04-naming-and-linking.md) §4.3 step 7); the dispatching human creates those records.
- Humans read the block at review; the lead acts on NEXT suggestions and routing gaps.

Example: the description of TareLog PR #14, which resolves Q-001 through a new ADR, ends with:

```text
MKB for humans:
ADR decisions needed: ADR-003
NEXT suggestion: TASK-007 PDF pipeline is dead code after ADR-003
```

Example: Codex cloud cannot push to the default branch, so the description of TareLog PR #11 ends with:

```text
MKB for humans:
ADR decisions needed: ADR-002
New task: Per-customer report time zone
```

## 5.9 Session checklist

Copy this list into a session prompt or a PR template; each line points to the section that holds the rule.

```markdown
- [ ] `git fetch`; rebase onto `origin/main`; read INDEX.md and state/CURRENT.md (§5.2)
- [ ] At most 3 files, no interface, configuration, schema or dependency change, done now: lite path (§5.4)
- [ ] Work item: the given task, else the first eligible ID in state/NEXT.md, else ask; outlasts the session: create a task
- [ ] Read the task, then its handoff; verify the handoff against `git log` and `git status` (§6.6)
- [ ] Claim pushed to the default branch before coding; never code on an unpushed claim (§8.4)
- [ ] Discovery: code owners, IDs, paths, error text, reverse hop; at most 5 docs in full (§5.3)
- [ ] Another actor's in-progress task covers your paths: tell the human before editing
- [ ] Constraints and accepted ADRs bind; record each discovery when made, by bare ID (§5.5)
- [ ] Out-of-scope work: new `todo` task pushed at once; re-read MKB files before editing them
- [ ] Before you stop: walk T1 to T22; nothing durable changed: update nothing (§5.6)
- [ ] Unfinished: handoff overwritten, everything committed and pushed, `git status` clean (§6.5)
- [ ] Blocked: question or blocking task, `status: blocked`, `blocked_by`, pushed (§8.7)
- [ ] Done: criteria ticked, `done`, `closed`, Completion, handoff deleted, all in the delivering PR
- [ ] PR description or final message ends with the `MKB for humans:` lines (§5.8)
```
