# 1. Architecture

*MKB Standard v1.0 · 2026-09-23 · Normative*

This chapter states what the MKB is, the terms and principles the other chapters build on, where each kind of information lives, and which document wins when two disagree.

## 1.1 Purpose and scope

The Markdown Knowledge Base (MKB) is a set of small, purpose-specific Markdown files, versioned in git together with the code, that serves as the persistent, structured and discoverable memory of one software project for humans and AI agents.
Code and tests are the truth for what the system does; the MKB holds what code cannot show: intent, decisions, hard-won knowledge, current state, open work and handoffs.
It is designed for teams where Codex, Claude Code, other agents and human developers work concurrently on the same repository.

Scope of v1.0:
- One MKB per repository, at `docs/mkb/`.
- The operational agent block lives in the root `AGENTS.md`; the root `CLAUDE.md` imports it ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.5).
- Monorepos with several MKBs are out of scope for v1.0.
- Two profiles use the same paths: minimal for small projects, full for large multi-agent projects ([11-profiles.md](11-profiles.md)).
- The MKB is not a project-management tool: assignees, reviewers, estimates and due dates stay with the PR and the team's planning ([03-metadata.md](03-metadata.md) §3.6).
- The MKB is not a replacement for reading the source code: it records only what the code does not make evident ([05-agent-workflow.md](05-agent-workflow.md) §5.5).

Conformance is defined in [README.md](../README.md), section Conformance.

## 1.2 Conventions used in this standard

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY" and "OPTIONAL" in this standard are to be interpreted as described in BCP 14 ([RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174)) when, and only when, they appear in all capitals, as shown here.
This statement applies to every chapter; the other chapters do not repeat it.

Other conventions:
- Non-normative asides start with `Note:`; examples are labelled `Example:` and are informative.
- Placeholders are written in angle brackets (`<handle>`, `<path>/`, `<Project name>`) or as `NNN`, `YYYY-MM-DD` and `<NAME>`; `TASK-NNN` stands for any task ID.
- Rules say "default branch"; examples and commands say `main`.
- Paths use forward slashes and are relative to the repository root; paths of MKB files are often shortened relative to `docs/mkb/` (`state/CURRENT.md` for `docs/mkb/state/CURRENT.md`).
- Plain git commands work in sh and PowerShell; where a pipeline is needed, the sh form comes first and the PowerShell form second.
- Concrete IDs, handles and names in examples come from TareLog, the fictional project of `examples/tarelog/`; every company, vendor, device and customer name in it is fictional.
- A reference such as §5.3 names section 5.3 of chapter 5.

Glossary:

| Term | Meaning |
|---|---|
| record | Any MKB document with an ID: a task, ADR, question or knowledge doc. |
| knowledge doc | A record under `knowledge/`: a `MODULE-`, `SERVICE-`, `DB-`, `INT-` or `TS-` doc. |
| work item | A task, or an issue of an external tracker that replaces `tasks/` ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.13). |
| actor | A human or an agent. |
| human | A person working on the repository, known by a lowercase handle ([03-metadata.md](03-metadata.md) §3.4). |
| agent | An AI coding tool, known by a reserved handle such as `claude-code` or `codex`; parallel sessions of one tool share its handle. |
| lead | The human named as lead in INDEX section People and agents; keeps `state/NEXT.md` and is the escalation point for stale human claims, long-blocked tasks and conflicting ADRs. |
| owner | The handle in a record's `owner` field: for a task, the actor who claimed it, or `none` when unassigned; for a question, the human who must answer. |
| default branch | The branch that holds the project's merged state; `main` in examples. |
| claim, release | Taking a task visibly before coding (`status: in-progress`, `owner`, `branch`), and giving it back (`status: todo`, `owner: none`) ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4, §8.5). |
| coordination commit | A commit that changes only MKB coordination data (claims, releases, blocks, new tasks and questions, answers) and goes straight to the default branch ([12-concurrency.md](12-concurrency.md) §12.2). |
| session | One continuous stretch of work by one actor, from reading the MKB to stopping; for an agent, one run. |
| handoff | `handoff/TASK-NNN.md`: transfer notes for one unfinished task, kept on the task's branch ([06-handoff.md](06-handoff.md)). |
| promote | Move the answer of a question to its permanent home, then delete the question ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.11). |
| STALE banner | The line `> STALE YYYY-MM-DD <handle>: <what is wrong>. Tracking TASK-NNN.` that marks known-wrong text ([09-lifecycle.md](09-lifecycle.md) §9.5). |
| gardening | Running `mkb-check.sh` and resolving every finding; weekly in the full profile, monthly in the minimal profile ([09-lifecycle.md](09-lifecycle.md) §9.6). |
| descriptive doc | A doc that states what the system does and follows the code: knowledge docs, `project/ARCHITECTURE.md`, `project/OVERVIEW.md`, `state/` files and handoffs. |
| normative doc | A doc that states what the system must do and binds the code: `project/CONSTRAINTS.md`, accepted ADRs and `project/CONVENTIONS.md`. |
| profile | `minimal` or `full`, set in INDEX front matter ([11-profiles.md](11-profiles.md)). |

## 1.3 Design principles

The brief sets eight principles; each paragraph states the principle and how v1.0 meets it.

**1. Agent-first.** Agents discover relevant information without reading the entire documentation tree.
An agent reads two fixed files, `INDEX.md` and `state/CURRENT.md`, and finds everything else with `git grep` on `code` paths, IDs and exact error text.
It triages each hit by its first 16 lines and reads at most 5 docs in full ([05-agent-workflow.md](05-agent-workflow.md) §5.3).
The operational rules sit in one block of at most 35 lines in root `AGENTS.md`, which most agent tools load automatically.

**2. Human-readable.** Plain Markdown, easy to edit by hand, no proprietary format.
Metadata is a strict YAML subset of at most 12 one-line keys ([03-metadata.md](03-metadata.md) §3.2).
Prose is written one sentence per line, and nothing is generated: task boards are `git grep` queries, never committed files.

**3. Git-native.** Every document is version-controlled and every change is visible in git history.
MKB changes travel in the same commits and PRs as the code they describe; claims, answers and new tasks are coordination commits on the default branch ([12-concurrency.md](12-concurrency.md) §12.2).
Git replaces what other systems keep by hand: edit dates (no `updated` field), history (no history file) and deleted content.
Because the file name is the ID, the same ID created twice is an add/add conflict that git reports loudly ([04-naming-and-linking.md](04-naming-and-linking.md) §4.4).

**4. Modular.** Small documents, each with one responsibility.
Every task, decision, question, module, service, data store, integration and recurring failure is its own file.
Size budgets keep files small, for example at most 150 lines for a module doc, 60 for a task and 30 for a handoff, and `mkb-check.sh` warns when a file exceeds its budget ([09-lifecycle.md](09-lifecycle.md) §9.8).

**5. Discoverable.** A central index, metadata and cross-references.
`INDEX.md` is a near-static router: layout, routing by need, authority, people and path overrides; it never lists individual records ([02-directory-structure.md](02-directory-structure.md) §2.4).
Records carry front matter such as `summary`, `code`, `status` and `related` in their first lines, and refer to each other by bare IDs that `git grep -w` resolves in one step ([04-naming-and-linking.md](04-naming-and-linking.md) §4.8).

**6. Incremental.** Agents update only the documents their work affects.
After working, an actor walks the update-trigger matrix and updates only the rows that fire; if nothing durable changed, it updates nothing ([05-agent-workflow.md](05-agent-workflow.md) §5.6).
`state/CURRENT.md` changes only when a project-level fact changes, and `state/NEXT.md` only when the lead edits it.

**7. Auditable.** Important decisions have a durable record.
A decision with lasting effect is an ADR; agents write it as `proposed`, and only a human listed in `deciders` accepts or rejects it ([07-decisions.md](07-decisions.md) §7.4).
An accepted ADR's body is frozen and is replaced only by a superseding ADR, so the reasoning behind the code stays readable.
Task Completion sections and git history record what was delivered, when and by whom.

**8. Tool-independent.** The standard works with Codex, Claude Code, Cursor, Gemini CLI, Aider and human developers.
It needs only Markdown files and git; `mkb-check.sh` is POSIX sh plus git and runs in Git Bash on Windows, Linux and macOS.
One block in root `AGENTS.md` carries the rules, root `CLAUDE.md` imports it, and other tools get a pointer only where they do not read `AGENTS.md` ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.5).
Humans follow the same rules as agents ([05-agent-workflow.md](05-agent-workflow.md) §5.1).

## 1.4 The rules in one screen

1. Code shows what the system does; the MKB holds what code cannot show: intent, hard-won knowledge, state, open work and handoffs.
2. Every record has an ID, the file name is the ID, and you refer to it by bare ID; never copy content between docs.
3. Work you finish within the current session needs no task (the commit or PR is the record); any other work is one task file, one owner and one branch (the minimal profile allows trunk-based work), and its claim is visible to others before coding (a commit on the default branch, or a pushed task branch where the default branch is protected).
4. `state/` describes the default branch; a handoff describes one unfinished task on its branch; neither holds knowledge.
5. Record a discovery when you make it, in the doc where the next person will look.
6. Constraints and accepted ADRs bind; descriptive docs follow the code; only humans accept ADRs.
7. If nothing durable changed, update nothing; delete what is obsolete, because git remembers.

Detailed in: rule 1 in §1.6; rule 2 in [04-naming-and-linking.md](04-naming-and-linking.md); rule 3 in [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.1 and §8.4 and [11-profiles.md](11-profiles.md) §11.4; rule 4 in §1.6 and [06-handoff.md](06-handoff.md); rule 5 in [05-agent-workflow.md](05-agent-workflow.md) §5.5; rule 6 in §1.7 and [07-decisions.md](07-decisions.md); rule 7 in [05-agent-workflow.md](05-agent-workflow.md) §5.6 and [09-lifecycle.md](09-lifecycle.md).

## 1.5 Record kinds and their homes

The brief names nine categories of information; each has exactly one home.

| Brief category | Lives in | Chapter |
|---|---|---|
| Permanent project knowledge | `project/OVERVIEW.md`, `project/ARCHITECTURE.md`, `project/CONSTRAINTS.md`, `project/CONVENTIONS.md` | [02-directory-structure.md](02-directory-structure.md) §2.3 |
| Architectural decisions | `decisions/ADR-NNN.md` | [07-decisions.md](07-decisions.md) |
| Technical documentation | knowledge docs: `knowledge/modules/MODULE-<NAME>.md`, `knowledge/services/SERVICE-<NAME>.md`, `knowledge/database/DB-<NAME>.md`, `knowledge/integrations/INT-<NAME>.md`, `knowledge/troubleshooting/TS-<NAME>.md` | [05-agent-workflow.md](05-agent-workflow.md) §5.5, [09-lifecycle.md](09-lifecycle.md) §9.3 |
| Current project state | `state/CURRENT.md` (health, focus, warnings) and `state/NEXT.md` (pickup queue) | [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.12 |
| Tasks | `tasks/TASK-NNN.md`; closed tasks later move to `tasks/archive/` | [08-tasks-and-questions.md](08-tasks-and-questions.md) |
| Blockers | `status: blocked` and `blocked_by` in the blocked task; every blocker is an owned task or question | [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.7 |
| Open questions | `questions/Q-NNN.md`, deleted once the answer is promoted | [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.9 to §8.11 |
| Agent instructions | the MKB block in root `AGENTS.md`, root `CLAUDE.md`, `agents/RULES.md` | [05-agent-workflow.md](05-agent-workflow.md), [13-adoption-and-integration.md](13-adoption-and-integration.md) §13.5 |
| Session handoffs | `handoff/TASK-NNN.md` on the task's branch | [06-handoff.md](06-handoff.md) |

`INDEX.md` routes to all of them ([02-directory-structure.md](02-directory-structure.md) §2.4); `templates/` holds the skeletons for new files and `tools/mkb-check.sh` checks the whole tree ([09-lifecycle.md](09-lifecycle.md) §9.7).

## 1.6 Knowledge, state and handoff

Apply these tests in order to anything worth writing down; the first test that answers yes decides where it goes.

1. "Still true in 3 months?" -> knowledge: a knowledge doc, a `project/` file, or an ADR when it records a decision ([05-agent-workflow.md](05-agent-workflow.md) §5.5 says when it is worth writing and where).
2. "Would someone not continuing my work need it?" -> state: a dated bullet in `state/CURRENT.md`, and only when it is a project-level fact of the default branch ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.12).
3. Otherwise -> handoff: `handoff/TASK-NNN.md` on the task's branch, read by the next session on that task ([06-handoff.md](06-handoff.md)).

Open work is always a task and an unanswered question is always a question file (§1.5), whatever the tests say.

| | Knowledge | State | Handoff |
|---|---|---|---|
| Describes | how the system works and why | the default branch and its deployments now | one unfinished task on its branch |
| Written | when the discovery is made | when a project-level fact changes | at the end of every session that leaves the task unfinished |
| Removed | when what it describes is removed | when the fact stops being true | in the PR that completes or drops the task |
| Authority (§1.7) | below code and tests | below knowledge docs | lowest |

Example: in TareLog, "WI-200 frames marked US (unstable) must never be stored" goes to INT-WI200 (knowledge), "Production weighbridge PC runs v0.9.0" goes to `state/CURRENT.md` (state), and "next step: retry 3 times, then send an alert e-mail" goes to `handoff/TASK-004.md` (handoff).

## 1.7 Authority and precedence

### 1.7.1 The three orders

Authority is three separate orders, because what the system does, what it must do and what is happening now have different sources of truth.
Each order runs from highest to lowest; the Authority section of `INDEX.md` repeats it for every reader of the MKB.

- What the system does: code and tests on the default branch, then knowledge docs and `project/ARCHITECTURE.md`, then `state/CURRENT.md`, then handoffs.
  A descriptive doc that disagrees with the code is wrong.
- What the system must do: `project/CONSTRAINTS.md`, then accepted ADRs (a superseding ADR wins), then `project/CONVENTIONS.md`, then the task's acceptance criteria.
- What is happening now: the human in your session, then task files on the default branch, then `state/CURRENT.md`, then handoffs.
- Never authoritative: proposed, rejected, superseded or deprecated ADRs; open questions; text under a `> STALE` banner; `tasks/archive/`; `templates/`.

### 1.7.2 Resolving contradictions

The contradiction table, which applies these orders case by case, is in [05-agent-workflow.md](05-agent-workflow.md) §5.7.
Humans resolve contradictions the same way.

## 1.8 How an agent uses the MKB in one session

A session follows the MKB block in root `AGENTS.md` (copy-ready in `agent-instructions/AGENTS.tmpl.md`); [05-agent-workflow.md](05-agent-workflow.md) specifies every step.

1. Fetch and rebase onto the default branch, then read `INDEX.md` and `state/CURRENT.md` ([05-agent-workflow.md](05-agent-workflow.md) §5.2).
2. Take the task you were given, else the first ID in `state/NEXT.md` whose task on the default branch is `todo` with `owner: none` or you; read the task and its handoff on the task's branch.
3. Claim the task with a coordination commit on the default branch before touching code, then create and push the task branch ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4).
4. Discover, don't browse: match `code` entries against the paths you will touch, grep for IDs and exact error text, triage hits by their first 16 lines, read at most 5 docs in full ([05-agent-workflow.md](05-agent-workflow.md) §5.3).
5. Work within `project/CONSTRAINTS.md` and accepted ADRs; to deviate, write a `proposed` ADR or open a question.
6. Record each discovery when you make it, in its home doc, linked by bare ID; out-of-scope work becomes a new task ([05-agent-workflow.md](05-agent-workflow.md) §5.5).
7. Before stopping, walk the update-trigger matrix and update only the rows that fire; if nothing durable changed, update nothing ([05-agent-workflow.md](05-agent-workflow.md) §5.6).
8. Unfinished: overwrite the handoff, then commit and push everything; done: set the task `done` in the delivering PR and delete the handoff ([06-handoff.md](06-handoff.md) §6.5).
9. End the PR description, or the final message, with the `MKB for humans:` lines ([05-agent-workflow.md](05-agent-workflow.md) §5.8).
10. A fix of at most 3 files that changes no interface, configuration, schema or dependency and is finished now takes the lite path instead ([05-agent-workflow.md](05-agent-workflow.md) §5.4).

## 1.9 Chapter map

| Chapter | Covers |
|---|---|
| [01-architecture.md](01-architecture.md) | scope, conventions, principles, record kinds, knowledge versus state versus handoff, authority |
| [02-directory-structure.md](02-directory-structure.md) | full and minimal trees, per-file reference, INDEX.md, creation rules, deviations from the brief |
| [03-metadata.md](03-metadata.md) | front matter: where it is used, the YAML subset, fields, vocabularies, schemas per type |
| [04-naming-and-linking.md](04-naming-and-linking.md) | ID kinds, file names, ID allocation, collisions, branches and commits, dates and handles, links |
| [05-agent-workflow.md](05-agent-workflow.md) | the session workflow, discovery, lite path, update-trigger matrix, reporting to humans |
| [06-handoff.md](06-handoff.md) | handoff files: format, content, rotation, reading |
| [07-decisions.md](07-decisions.md) | ADRs: when to write one, format, statuses, immutability, superseding, backfilling |
| [08-tasks-and-questions.md](08-tasks-and-questions.md) | tasks, claiming, completion, blockers, questions, state files, external trackers |
| [09-lifecycle.md](09-lifecycle.md) | lifecycle, archival, staleness, STALE banners, gardening, `mkb-check.sh`, size budgets |
| [10-anti-patterns.md](10-anti-patterns.md) | the 38 numbered anti-patterns |
| [11-profiles.md](11-profiles.md) | minimal and full profiles, upgrade triggers and steps |
| [12-concurrency.md](12-concurrency.md) | parallel work: coordination commits, merge classes, formatting, conflict cookbook |
| [13-adoption-and-integration.md](13-adoption-and-integration.md) | adoption, existing docs and ADR directories, Handoff.md migration, agent instruction files, upgrades |

Companion files:

| File | Covers |
|---|---|
| [README.md](../README.md) | overview, quick start, repository map, conformance, versioning |
| [templates/README.md](../templates/README.md) | profile contents, adoption and upgrade commands, placeholders |
| [agent-instructions/README.md](../agent-instructions/README.md) | the agent block, `CLAUDE.md` import and per-tool wiring |
| [examples/tarelog/WALKTHROUGH.md](../examples/tarelog/WALKTHROUGH.md) | the worked example: eight sessions of two humans, Claude Code and Codex on one repository |

Note: readers new to the MKB read this chapter, chapters 5 and 8, and then the walkthrough.
