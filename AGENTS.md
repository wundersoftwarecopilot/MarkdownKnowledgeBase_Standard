# Agent instructions

This repository defines the MKB Standard: its sources are `spec/`, `templates/`, `agent-instructions/` and `examples/`; the work on it is tracked in this repository's own `docs/mkb/`.
There is no remote: wherever the block below says `origin/main`, use `main`, and skip `git fetch`, `git pull` and `git push` (`docs/mkb/agents/RULES.md`, section 5, no remote).
Shared MKB files are edited only under `templates/full/docs/mkb/` and then copied: `docs/mkb/project/CONVENTIONS.md`, section Code.

<!-- MKB:BEGIN v1.0 -->
## Project memory (MKB)

`docs/mkb/` is this repository's memory: intent, decisions, hard-won knowledge, current state, open work and handoffs.
Code and tests are the truth for behavior; `docs/mkb/project/CONSTRAINTS.md` and accepted ADRs are the truth for intent.
Full rules: `docs/mkb/agents/RULES.md`; `git grep -n "^## " -- docs/mkb/agents/RULES.md` lists its sections, read only the one you need. Never read the whole tree.
No remote (`git remote` prints nothing): `origin/main` means local `main`; skip every fetch, pull and push, and the fast-forward to `origin/<your-branch>`; make coordination commits with the no-remote recipe of RULES.md section 11 (a real checkout of `main`, no `--detach`).

Before changing code
1. `git fetch`, then `git merge --ff-only origin/<your-branch>` (keeps a reviewer's commits; refused: stop and ask the human) and rebase your branch onto `origin/main` (on main: only `git pull --rebase`). Read `docs/mkb/INDEX.md` and `docs/mkb/state/CURRENT.md`. Lite path, for a fix of at most 3 files that changes no interface, configuration, schema or dependency and is finished now: read the Warnings in CURRENT.md, run step 4 for your files and errors, make the fix, correct any doc it makes wrong, update nothing else.
2. Your task is the one you were given, else the `in-progress` task whose `branch` you are on, if it is yours (RULES.md section 5, claim step 7), else the first ID in `docs/mkb/state/NEXT.md` whose task on the default branch is `todo` with `owner: none` or you. Read `docs/mkb/tasks/TASK-NNN.md`, then its handoff `docs/mkb/handoff/TASK-NNN.md` on the task's branch, or on the branch its Notes name as released (take over from that branch: RULES.md section 5). Work that may outlast this session and has no task: create one from `docs/mkb/templates/TASK.md`.
3. Claim before coding, unless the task is already yours (RULES.md section 5, claim step 7): `git show origin/main:docs/mkb/tasks/TASK-NNN.md` must show `status: todo` and `owner: none` or you; otherwise (blocked, or claimed by another actor or session) do not claim it or code on it: tell the human, naming its `blocked_by` or `owner`. Set `status: in-progress`, `owner`, `branch`, and `code` with the paths you expect to touch; commit `TASK-NNN: claim` only in a temporary worktree of `origin/main` (RULES.md section 11), never on a work branch, after repeating the check on the file there; `git push origin HEAD:main`. The check failing there, a conflict on that file, or your claim commit vanishing in the rebase, means it is taken: pick another (a task you were given: tell the human). Then create `<you>/task-nnn-<slug>` from `origin/main` and push it at once. Cannot push to main, or cannot fetch or push at all: RULES.md section 5; never code on an unpushed claim. Minimal profile, alone on main: the claim is the first commit of your work.
4. Discover, don't browse: `git grep "^code:" -- docs/mkb/knowledge docs/mkb/tasks` and keep the docs whose entry is a prefix of a file you will touch, and the docs that `git grep -l -F "<path>" -- docs/mkb` finds for each path in the task's `code` and each file you will touch; then `git grep -l -w <ID>` for each ID you hold (the task's and the kept docs') and `git grep -l -F "<exact error text>"` for each error you chase, over `docs/mkb` and the decisions directory named in INDEX. Read front matter first; at most 5 docs in full; skip `tasks/archive/` and `templates/`. Another actor's `in-progress` task covers your files: tell the human before editing.

While working
5. CONSTRAINTS.md and accepted ADRs bind you. To deviate, write a `proposed` ADR or a question; never edit an accepted ADR; never accept or reject an ADR on your own authority: when a named human decides it in this session, record the status and list them in `deciders`.
6. A knowledge or architecture doc contradicts the code: fix the doc in the same commit, or add a `> STALE` banner and a task. Never change code to match a descriptive doc.
7. Record each discovery when you make it, in its home doc (RULES.md section 3), linked by bare ID, never copied. Out-of-scope work becomes a new `todo` task.
8. New TASK or Q: number from `sh docs/mkb/tools/mkb-check.sh next TASK` (or `Q`); create the file and push it to main at once as a coordination commit, before anything refers to it; if the file already exists in the coordination worktree, take a new number, never overwrite it. New ADR: `next ADR` (adopted ADR directory: RULES.md section 15), `status: proposed`, on your branch. Commit subjects start with the task ID.
9. Re-read an MKB file just before editing it and change only your lines; never regenerate it from memory, re-wrap prose or re-align tables.

Before you stop
10. Walk the trigger matrix (RULES.md section 3) and update only what your work changed. Nothing durable changed: update nothing.
11. Unfinished: overwrite `docs/mkb/handoff/TASK-NNN.md` (at most 30 lines: where it stands, next steps, read first), then commit and push everything including it; `git status` must be clean. No task yet: create it first, already claimed by you.
12. Blocked: create `docs/mkb/questions/Q-NNN.md` (owner: who must answer) or name the blocking task; set `status: blocked` and `blocked_by`; push that to the default branch.
13. Done: tick the criteria, set `status: done` and `closed`, fill `## Completion`, move lasting handoff lines to knowledge, delete your handoff file, all in the PR that delivers the work.
14. Add a dated bullet to `docs/mkb/state/CURRENT.md` only when a project-level fact changed; edit `docs/mkb/state/NEXT.md` only when a human asks.
15. End your PR description, or your final message, with the `MKB for humans:` lines (RULES.md section 1) for new questions, ADR decisions needed, NEXT suggestions, routing gaps and gardening due.
Never put secrets, credential values, logs, diffs or transcripts in the MKB; never create AGENTS.md or CLAUDE.md files under `docs/mkb/`.
<!-- MKB:END -->
