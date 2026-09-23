# Markdown Knowledge Base (MKB) Standard

*MKB Standard v1.0 · 2026-09-23*

The MKB is a set of small, purpose-specific Markdown files under `docs/mkb/` that serves as the persistent, Git-versioned memory of a software project for human developers and AI coding agents such as Codex, Claude Code, Cursor, Gemini CLI, Aider, GitHub Copilot and Windsurf.
It replaces the single ever-growing `Handoff.md`: every task, decision, question and piece of hard-won knowledge gets its own file named after its ID, so agents find what they need with `git grep` instead of reading everything, and parallel sessions merge cleanly or conflict loudly instead of silently overwriting each other.
One block in the root `AGENTS.md` tells agents what to read before changing code, how to claim work, and what to update before they stop; humans follow the same rules.
Two profiles use the same paths: minimal for small projects, full for teams where several humans and agents work concurrently; upgrading never moves or renames a file.
To adopt it, copy one profile into your project, fill five short files (seven in the full profile), insert one block into `AGENTS.md` and run the checker (Quick start below).

## The rules in one screen

1. Code shows what the system does; the MKB holds what code cannot show: intent, hard-won knowledge, state, open work and handoffs.
2. Every record has an ID, the file name is the ID, and you refer to it by bare ID; never copy content between docs.
3. One work item is one task file, one branch and one owner; the claim is visible to others before coding (a commit on the default branch, or a pushed task branch where the default branch is protected).
4. `state/` describes the default branch; a handoff describes one unfinished task on its branch; neither holds knowledge.
5. Record a discovery when you make it, in the doc where the next person will look.
6. Constraints and accepted ADRs bind; descriptive docs follow the code; only humans accept ADRs.
7. If nothing durable changed, update nothing; delete what is obsolete, because git remembers.

The specification in [spec/](spec/) details these rules; [spec/01-architecture.md](spec/01-architecture.md) §1.9 maps its chapters.

## Quick start

You need git, and `sh` for the checker (on Windows, Git Bash; from PowerShell see [spec/09-lifecycle.md](spec/09-lifecycle.md) §9.7).
Choose the full profile if an upgrade trigger of [spec/11-profiles.md](spec/11-profiles.md) §11.5 already holds (for example, two or more actors regularly working in parallel on separate branches); otherwise start with the minimal profile.

### Minimal profile

1. In your project, create the branch `<actor>/mkb-adopt` and inspect what already exists: README, CONTRIBUTING, `docs/` and any site generator that builds it, ADR directories, agent instruction files, `.gitattributes`, handoff or notes files, the issue tracker.
2. From the root of this repository, set `REPO` (sh) or `$repo` (PowerShell) to your project's path and run the adoption command in [templates/README.md](templates/README.md), section Adoption commands, with `<profile>` = `minimal`: it stops if `docs/mkb` exists, copies the profile to `docs/mkb/` and appends the `.gitattributes` lines only where absent.
3. Fill `docs/mkb/INDEX.md` (People and agents, Path overrides) and, under `docs/mkb/`, `project/OVERVIEW.md`, `project/CONSTRAINTS.md`, `state/CURRENT.md` and `state/NEXT.md`; delete every guide comment.
4. Insert the MKB block of [agent-instructions/AGENTS.tmpl.md](agent-instructions/AGENTS.tmpl.md) into your root `AGENTS.md` between its markers (create the file if missing); if you use Claude Code, create root `CLAUDE.md` from [agent-instructions/CLAUDE.tmpl.md](agent-instructions/CLAUDE.tmpl.md) or make `@AGENTS.md` the first line of the existing one; other tools: [agent-instructions/README.md](agent-instructions/README.md).
5. Keep existing docs in place and add the line "Project memory: `docs/mkb/INDEX.md`" to your README; adopt an existing ADR directory in place, exclude `docs/mkb/` from any site generator that builds `docs/`, and migrate a monolithic `Handoff.md` once ([spec/13-adoption-and-integration.md](spec/13-adoption-and-integration.md) §13.2 to §13.4).
6. Run `sh docs/mkb/tools/mkb-check.sh` (add `--adr-dir <dir>` for an adopted ADR directory) until it reports 0 errors; if a site generator builds `docs/`, run its build too.
7. Commit `mkb: adopt MKB v1.0 (minimal profile)` and have a human review the PR.

### Full profile

- In step 2 use `<profile>` = `full`: INDEX then says `profile: full`, and `project/ARCHITECTURE.md` and `project/CONVENTIONS.md` are created too.
- In step 3 also fill ARCHITECTURE (an agent drafts it from the code, a human reviews it) and CONVENTIONS; if `CONTRIBUTING.md` already covers conventions, delete `project/CONVENTIONS.md` and add an INDEX path override row instead ([spec/13-adoption-and-integration.md](spec/13-adoption-and-integration.md) §13.2).
- Add a CI job that runs `sh docs/mkb/tools/mkb-check.sh` (advisory, never blocking on warnings), and garden weekly ([spec/09-lifecycle.md](spec/09-lifecycle.md) §9.6).

After adoption, agents follow the block in `AGENTS.md`; people start with [spec/01-architecture.md](spec/01-architecture.md) and the worked example [examples/tarelog/WALKTHROUGH.md](examples/tarelog/WALKTHROUGH.md).

## Repository map

| Path | Contents |
|---|---|
| [spec/](spec/) | The normative specification in 13 chapters; start with [spec/01-architecture.md](spec/01-architecture.md). |
| [templates/minimal/](templates/minimal/) | The minimal profile: a `docs/mkb/` tree ready to copy into a project. |
| [templates/full/](templates/full/) | The full profile: the same tree plus `project/ARCHITECTURE.md` and `project/CONVENTIONS.md`. |
| [templates/gitattributes-mkb.txt](templates/gitattributes-mkb.txt) | The LF line-ending rules appended to a project's `.gitattributes` at adoption. |
| [templates/README.md](templates/README.md) | Profile contents, adoption and upgrade commands, placeholders. |
| [templates/full/docs/mkb/tools/mkb-check.sh](templates/full/docs/mkb/tools/mkb-check.sh) | The consistency checker and ID allocator (POSIX sh and git), identical in both profiles. |
| [agent-instructions/](agent-instructions/) | The MKB block for `AGENTS.md`, the `CLAUDE.md` import, optional pointers for Cursor, Gemini CLI, Aider and GitHub Copilot, and per-tool wiring. |
| [examples/tarelog/](examples/tarelog/) | A fictional project's MKB after eight sessions by two humans, Claude Code and Codex; read [examples/tarelog/WALKTHROUGH.md](examples/tarelog/WALKTHROUGH.md) first. |
| [.gitattributes](.gitattributes) | `* text=auto eol=lf`: every file of this repository has LF line endings. |
| [Prompt_MarkdownKnowledgeBase_Standard.md](Prompt_MarkdownKnowledgeBase_Standard.md) | The original brief this standard answers. |
| [docs/mkb/](docs/mkb/INDEX.md) | This repository's own MKB (minimal profile): state and open work on the standard itself. |
| [dev/](dev/) | Development aids: design contract, link checker, checker test suite, review data (see Q-001 in `docs/mkb/questions/`). |

Note: apart from the root `AGENTS.md` and `CLAUDE.md`, which wire this repository's own project memory in `docs/mkb/`, no file in this repository is named `AGENTS.md`, `CLAUDE.md` or `GEMINI.md`, because agents working on the standard itself would load such files as instructions; copy-ready versions use `.tmpl.md` and are renamed on copy.

## Deliverables coverage

The brief, [Prompt_MarkdownKnowledgeBase_Standard.md](Prompt_MarkdownKnowledgeBase_Standard.md), asks for 15 deliverables and two cross-cutting concerns; this table shows where each is answered.
Where v1.0 departs from the directory structure the brief proposed, and why: [spec/02-directory-structure.md](spec/02-directory-structure.md) §2.6.

| # | Deliverable | Files |
|---|---|---|
| 1 | Specification of the architecture | [spec/01-architecture.md](spec/01-architecture.md) (plus all of [spec/](spec/)) |
| 2 | Canonical directory structure | [spec/02-directory-structure.md](spec/02-directory-structure.md), [templates/full/](templates/full/) |
| 3 | Document templates | [templates/minimal/](templates/minimal/), [templates/full/](templates/full/) (singletons and `docs/mkb/templates/`), [templates/README.md](templates/README.md) |
| 4 | Metadata conventions | [spec/03-metadata.md](spec/03-metadata.md) |
| 5 | Naming conventions | [spec/04-naming-and-linking.md](spec/04-naming-and-linking.md) |
| 6 | Agent workflow | [spec/05-agent-workflow.md](spec/05-agent-workflow.md), `templates/*/docs/mkb/agents/RULES.md` |
| 7 | Handoff rules | [spec/06-handoff.md](spec/06-handoff.md) |
| 8 | ADR rules | [spec/07-decisions.md](spec/07-decisions.md) |
| 9 | Task rules | [spec/08-tasks-and-questions.md](spec/08-tasks-and-questions.md) |
| 10 | Lifecycle and archival rules | [spec/09-lifecycle.md](spec/09-lifecycle.md) |
| 11 | Anti-patterns | [spec/10-anti-patterns.md](spec/10-anti-patterns.md) |
| 12 | Minimal version | [spec/11-profiles.md](spec/11-profiles.md), [templates/minimal/](templates/minimal/) |
| 13 | Full version | [spec/11-profiles.md](spec/11-profiles.md), [templates/full/](templates/full/) |
| 14 | Agent instructions | [agent-instructions/](agent-instructions/), [spec/13-adoption-and-integration.md](spec/13-adoption-and-integration.md) §13.5 |
| 15 | Realistic multi-agent example | [examples/tarelog/](examples/tarelog/) |
| - | Concurrent Codex + Claude Code + humans | [spec/12-concurrency.md](spec/12-concurrency.md) |
| - | Integration with existing docs | [spec/13-adoption-and-integration.md](spec/13-adoption-and-integration.md) |

## Conformance

A repository conforms to MKB v1.0 when all of these hold:

- It has the files of its profile at adoption ([spec/02-directory-structure.md](spec/02-directory-structure.md) §2.2).
- Its root `AGENTS.md` contains the MKB block of [agent-instructions/AGENTS.tmpl.md](agent-instructions/AGENTS.tmpl.md) between its markers, unchanged except that `main` may be replaced by the name of the project's default branch.
- `sh docs/mkb/tools/mkb-check.sh` (with `--adr-dir <dir>` when an ADR directory is adopted in place) reports 0 errors.

Warnings do not affect conformance; gardening resolves them ([spec/09-lifecycle.md](spec/09-lifecycle.md) §9.6).

## Versioning

This is `MKB Standard v1.0`; versions of the standard follow semantic versioning.
A project records the version it adopted in `mkb_version: "1.0"` in `docs/mkb/INDEX.md` and `docs/mkb/agents/RULES.md`, and in the marker `<!-- MKB:BEGIN v1.0 -->` that opens the agent block.
Upgrading replaces the agent block, RULES.md above its section 16, `docs/mkb/templates/` and `docs/mkb/tools/`, and sets `mkb_version`; `project/`, `state/` and records stay as they are ([spec/13-adoption-and-integration.md](spec/13-adoption-and-integration.md) §13.8).
