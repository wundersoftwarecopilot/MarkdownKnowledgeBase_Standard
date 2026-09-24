# 11. Profiles

*MKB Standard v1.0 · 2026-09-23 · Normative*

MKB v1.0 comes in two profiles: minimal, for small projects, and full, for large multi-agent projects.
Both use the same paths, record kinds, IDs and front matter, and both ship the same `agents/RULES.md`, templates and `mkb-check.sh`.
They differ in the files created at adoption and in the rules of §11.4.
Upgrading never moves or renames a file.

## 11.1 Choosing a profile

The profile is recorded in the front matter of `docs/mkb/INDEX.md` as `profile: minimal` or `profile: full` ([03-metadata.md](03-metadata.md) §3.5).
mkb-check reads it to choose the W5 threshold ([09-lifecycle.md](09-lifecycle.md) §9.7).

Choose with the upgrade triggers of §11.5:
- None of them holds: adopt the minimal profile, and upgrade when one starts to hold (§11.6).
- One of them already holds at adoption: adopt the full profile directly.

| | Minimal | Full |
|---|---|---|
| Made for | small projects: one human with one agent tool, mostly sequential work | large multi-agent projects: several humans and agent tools working in parallel on separate branches |
| Docs filled at adoption | INDEX, OVERVIEW, CONSTRAINTS, CURRENT, NEXT | the same, plus ARCHITECTURE (an agent drafts it from the code, a human reviews it) and CONVENTIONS (or an override to `CONTRIBUTING.md`) |
| Rule differences | the Minimal column of §11.4 | the Full column of §11.4 |

Starting with the minimal profile costs nothing later: the upgrade adds files and tightens rules, but moves no file and changes no ID (§11.6).
A repository conforms to MKB v1.0 in either profile when it has the files of its profile, the agent block in root `AGENTS.md`, and `mkb-check.sh` reports 0 errors ([README.md](../README.md), section Conformance).

Example: TareLog adopts the full profile directly, because two humans (marta and luca) and two agent tools (Claude Code and Codex) work in parallel from the first week; see [examples/tarelog/WALKTHROUGH.md](../examples/tarelog/WALKTHROUGH.md).

## 11.2 Minimal profile

Files at adoption, as in the tree of [02-directory-structure.md](02-directory-structure.md) §2.2:
- `docs/mkb/INDEX.md` with `profile: minimal`, `docs/mkb/agents/RULES.md`, `docs/mkb/project/OVERVIEW.md`, `docs/mkb/project/CONSTRAINTS.md`, `docs/mkb/state/CURRENT.md` and `docs/mkb/state/NEXT.md`;
- `docs/mkb/templates/` with the 11 templates, and `docs/mkb/tools/mkb-check.sh`;
- the MKB block in root `AGENTS.md`, root `CLAUDE.md` only if Claude Code is used, and the MKB lines in `.gitattributes`.

Created when first needed: `project/ARCHITECTURE.md` (copied from `templates/ARCHITECTURE.md`), `project/CONVENTIONS.md` (copied from `templates/CONVENTIONS.md`, or an INDEX override to `CONTRIBUTING.md`), `decisions/`, `tasks/`, `tasks/archive/`, `questions/`, `knowledge/<kind>/`, `handoff/`.
Until ARCHITECTURE and CONVENTIONS exist, INDEX names them as backticked paths in Layout and routes to them "(if it exists)" ([02-directory-structure.md](02-directory-structure.md) §2.4).
The standard repository ships this profile in `templates/minimal/`.

Rules: every rule of this standard applies, with the relaxations of the Minimal column of §11.4.
They make one actor working alone cheap:
- Trunk-based sequential work is allowed; one actor alone on the default branch makes the claim the first commit of the work, and SHOULD push it before writing code ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4).
- In trunk-based work the handoff is committed on the default branch ([06-handoff.md](06-handoff.md) §6.2), the done edit is a follow-up commit `TASK-NNN: done` ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.6), and a human decides an ADR in the session before the commit ([07-decisions.md](07-decisions.md) §7.4).
- Gardening is monthly, and W5 warns after 35 days, one gardening interval plus slack ([09-lifecycle.md](09-lifecycle.md) §9.6).
- Running `mkb-check.sh` in CI is optional.

Example: one developer with one agent tool, working trunk-based on a task that takes two sessions:
1. `git pull --rebase` on the default branch, then read `docs/mkb/INDEX.md` and `docs/mkb/state/CURRENT.md` ([05-agent-workflow.md](05-agent-workflow.md) §5.2).
2. The work will outlast the session, so create `docs/mkb/tasks/TASK-NNN.md` and push it at once ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.1).
3. Claim it: the claim is the first commit of the work, pushed before any code ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4).
4. Commit the work on the default branch, with subjects that start with `TASK-NNN:` ([04-naming-and-linking.md](04-naming-and-linking.md) §4.6).
5. The session ends unfinished: overwrite `docs/mkb/handoff/TASK-NNN.md`, then commit and push it with the work ([06-handoff.md](06-handoff.md) §6.5).
6. The next session reads the handoff, verifies it against `git log` and `git status`, and finishes the work.
7. The follow-up commit `TASK-NNN: done` sets `status: done`, fills Completion with the short SHA of the last code commit, and deletes the handoff ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.6).

What the minimal profile does not relax:
- Local agents that run in parallel each MUST use their own worktree ([12-concurrency.md](12-concurrency.md) §12.7).
- IDs and their allocation, front matter, the trigger matrix, handoff content, human decisions on ADRs and conflict resolution are the same as in the full profile.
- Gardening still runs `mkb-check.sh` and resolves every finding; only its cadence and the W5 threshold differ ([09-lifecycle.md](09-lifecycle.md) §9.6).
- When several actors do work in parallel, the claim and branch rules of [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4 still keep them from colliding; that situation is also an upgrade trigger (§11.5).

## 11.3 Full profile

Files at adoption: everything of §11.2 with `profile: full` in INDEX, plus:
- `docs/mkb/project/ARCHITECTURE.md`: an agent drafts it from the code, and a human reviews it ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.1);
- `docs/mkb/project/CONVENTIONS.md`, unless `CONTRIBUTING.md` already covers conventions; then no file is created and INDEX gets a path override row pointing to `CONTRIBUTING.md` ([02-directory-structure.md](02-directory-structure.md) §2.4);
- a CI job that runs `sh docs/mkb/tools/mkb-check.sh` (SHOULD, advisory).

Created when first needed: `decisions/`, `tasks/`, `tasks/archive/`, `questions/`, `knowledge/<kind>/`, `handoff/`.
The standard repository ships this profile in `templates/full/`.

Rules: the Full column of §11.4.
They let several humans and agents work at the same time without colliding:
- Every task gets its own branch, and its claim is visible to others before coding ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4, [12-concurrency.md](12-concurrency.md) §12.1).
- Gardening is weekly, and W5 warns after 14 days ([09-lifecycle.md](09-lifecycle.md) §9.6).
- The CI job is advisory and never blocks on warnings, so it runs without `--strict` ([09-lifecycle.md](09-lifecycle.md) §9.7).
- The CI job checks out the full history of every branch, because in a shallow clone mkb-check skips W2, W3, W6 and W14, and with branches missing it reports W6 falsely ([09-lifecycle.md](09-lifecycle.md) §9.7.2).

Example: in TareLog session S7, two Claude Code sessions work at the same time in separate worktrees on TASK-004 and TASK-007; both claims carry the handle `claude-code`, and their `branch` values tell them apart ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4).

Example: TareLog's INDEX says `profile: full`; its `project/CONVENTIONS.md` holds only what `CONTRIBUTING.md` lacks, so its Path overrides table keeps the row `| none | - | - |`.

## 11.4 Profile differences

| Rule | Minimal | Full |
|---|---|---|
| Files at adoption | [02-directory-structure.md](02-directory-structure.md) §2.2, minimal tree | [02-directory-structure.md](02-directory-structure.md) §2.2, full profile additions |
| One branch per task | SHOULD; trunk-based sequential work is allowed | MUST |
| Claim visible to others before coding | SHOULD; one actor alone on the default branch: the claim is the first commit of the work ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4) | MUST |
| One worktree per parallel local agent | MUST when agents run in parallel | MUST |
| Gardening cadence | monthly | weekly |
| `mkb-check.sh` in CI | optional | SHOULD (advisory, never blocks on warnings) |
| Staleness thresholds | [09-lifecycle.md](09-lifecycle.md) §9.4; W5 at 35 days | [09-lifecycle.md](09-lifecycle.md) §9.4; W5 at 14 days |

Everything else is identical in both profiles: paths, ID kinds, front matter schemas and vocabularies, the session workflow and trigger matrix, the handoff, ADR, task and question rules, the concurrency protocol, `agents/RULES.md`, the templates and `mkb-check.sh`.
`agents/RULES.md` carries this table as its section 14, so an agent reads both columns and applies the one that INDEX names.
The agent block in root `AGENTS.md` is also the same in both profiles; its claim step names the minimal-profile exception ([agent-instructions/AGENTS.tmpl.md](../agent-instructions/AGENTS.tmpl.md)).

## 11.5 Upgrade triggers

Upgrade a minimal MKB to the full profile when any of these holds:
- two or more actors regularly work in parallel on separate branches;
- a second agent tool or a second human joins;
- there are more than 5 ADRs or more than 10 knowledge docs;
- the team keeps re-explaining the architecture to agents.

| Trigger | Why the minimal profile stops fitting | What the full profile adds |
|---|---|---|
| actors in parallel on separate branches | branches and visible claims are only SHOULD, so two actors can start the same task | one branch per task and claims visible before coding are MUST |
| a second agent tool or a second human | the same risk, and the newcomer learns the system from OVERVIEW and discovery alone | the same MUST rules, and `project/ARCHITECTURE.md` for orientation |
| more than 5 ADRs or more than 10 knowledge docs | more docs to route between, and more drift for monthly gardening to catch | a component table whose column Doc names each component's knowledge doc, and weekly gardening |
| re-explaining the architecture to agents | the architecture lives only in people's heads | `project/ARCHITECTURE.md`, drafted from the code and reviewed by a human |

List the records to count with plain git: `git ls-files -- docs/mkb/decisions` and `git ls-files -- docs/mkb/knowledge` print one file per line (for an adopted ADR directory, list that directory instead).

Note: no trigger is about code size; a large codebase changed by one actor at a time can stay in the minimal profile.

## 11.6 Upgrade steps

The upgrade is one MKB-only change; its steps are ordered so that INDEX never links to a file that does not exist yet.

1. Work on an MKB-only branch `<actor>/mkb-<slug>` ([04-naming-and-linking.md](04-naming-and-linking.md) §4.6); an INDEX change made by an agent goes through a PR that a human reviews ([02-directory-structure.md](02-directory-structure.md) §2.3).
2. If `docs/mkb/project/ARCHITECTURE.md` does not exist, copy `docs/mkb/templates/ARCHITECTURE.md` to it; an agent drafts it from the code, a human reviews it, and `verified` is set to the date the draft was checked against the code ([03-metadata.md](03-metadata.md) §3.3).
3. If `docs/mkb/project/CONVENTIONS.md` does not exist, copy `docs/mkb/templates/CONVENTIONS.md` to it and keep only the conventions that tooling and `CONTRIBUTING.md` do not cover; when `CONTRIBUTING.md` covers them all, add the conventions path override row to INDEX instead ([02-directory-structure.md](02-directory-structure.md) §2.4).
4. In `docs/mkb/INDEX.md`, set `profile: full`, and turn the backticked Layout rows of ARCHITECTURE and CONVENTIONS and the Routing rows "How the parts fit and where code lives" and "How code is written here" into their full-profile form; with a conventions override, keep the CONVENTIONS rows of the override ([02-directory-structure.md](02-directory-structure.md) §2.4).
   Add every new human or agent to `## People and agents` ([03-metadata.md](03-metadata.md) §3.4).
5. Add the CI job (SHOULD): it runs `sh docs/mkb/tools/mkb-check.sh` on a checkout with the full history of every branch, advisory, never blocking on warnings (§11.3).
6. Schedule weekly gardening ([09-lifecycle.md](09-lifecycle.md) §9.6).
7. Run `sh docs/mkb/tools/mkb-check.sh`: zero errors.
8. Commit it as an MKB-only change, with a subject that starts with `mkb:` ([04-naming-and-linking.md](04-naming-and-linking.md) §4.6).

Example: the lines of `docs/mkb/INDEX.md` that step 4 changes when no conventions override exists:

```diff
-profile: minimal
+profile: full
-| `project/ARCHITECTURE.md` | system context, components, data flow, deployment, code map | when needed |
+| [project/ARCHITECTURE.md](project/ARCHITECTURE.md) | system context, components, data flow, deployment, code map | always |
-| `project/CONVENTIONS.md` | project conventions not covered elsewhere (normative) | when needed, or see Path overrides |
+| [project/CONVENTIONS.md](project/CONVENTIONS.md) | project conventions not covered elsewhere (normative) | always |
-| How the parts fit and where code lives | project/ARCHITECTURE.md (if it exists) | component table, column Doc |
+| How the parts fit and where code lives | project/ARCHITECTURE.md | component table, column Doc |
-| How code is written here | project/CONVENTIONS.md (if it exists), else `CONTRIBUTING.md` | - |
+| How code is written here | project/CONVENTIONS.md | - |
```

From the merge on, the MUST rules of the Full column of §11.4 bind every actor: one branch per task, and a claim visible to others before coding.

The upgrade makes no file moves and no ID changes.
Every record keeps its path and ID, and `agents/RULES.md`, `docs/mkb/templates/` and `docs/mkb/tools/` stay as they are, because they are identical in both profiles.
The upgrade is not a reason to write knowledge docs in bulk: at adoption or upgrade, at most the 3 most-changed components get docs ([09-lifecycle.md](09-lifecycle.md) §9.3).

Note: once INDEX says `profile: full`, W5 warns after 14 days instead of 35, so step 7 may report older `state/CURRENT.md` bullets; re-verify and re-date them, or delete them ([09-lifecycle.md](09-lifecycle.md) §9.4).
