# MKB Standard v1.0: Design Contract

Status: binding for every writer of the MKB Standard v1.0 deliverables.
Date: 2026-09-23.
Target repository: `C:\Wundev\MarkdownKnowledgeBase_MKB`.

This contract is the single source of truth.
Writers copy skeletons, vocabularies, patterns and rule wording from it.
If a writer finds a gap or contradiction, they MUST choose the simplest reading that is consistent with the rest of this contract, and they MUST list the gap in their return summary.
Writers MUST NOT invent new files, fields, statuses, ID kinds or directories.

Contents:
A. Decisions summary.
B. Canonical trees and per-file table.
C. Controlled vocabularies and front matter schemas.
D. IDs, naming, allocation and collisions.
E. Linking conventions.
F. Canonical skeletons of every file.
G. Agent workflow, discovery algorithm, update-trigger matrix.
H. Handoff rules.
I. ADR rules.
J. Task rules and claiming.
K. Questions and blockers.
L. Lifecycle, archival, staleness, gardening, size budgets, mkb-check.
M. Concurrency protocol.
N. Integration with existing docs and migration from a monolithic Handoff.md.
O. Anti-patterns.
P. Agent instruction block and per-tool wiring.
Q. Worked example outline (TareLog).
R. Deliverable layout of the standard repository, work packages and verification.
S. Style guide for writers.
T. Change log from red-team.

---

## A. Decisions summary

Each line states the chosen answer.
The source proposals were P1 (simplicity-first), P2 (concurrency-first) and P3 (discovery-first).

| # | Item | Decision |
|---|---|---|
| A1 | Location | One MKB per repository at `docs/mkb/`. The operational agent block lives in the root `AGENTS.md`; the root `CLAUDE.md` imports it. Monorepos with several MKBs are out of scope for v1.0. |
| A2 | Canonical tree | The brief's tree is kept with these changes: tasks become one file per task (plus `tasks/archive/`); `state/BLOCKERS.md` is removed; questions become one file per question; `agents/` keeps only `RULES.md`; handoffs become one file per unfinished task on its branch; `handoff/HISTORY.md` is removed; `templates/` and `tools/` are added. (P2/P3, with P1's removal of HISTORY.) |
| A3 | Overlaps | BLOCKED.md and BLOCKERS.md: both removed, replaced by `status: blocked` plus `blocked_by`. NEXT.md vs TODO.md: TODO.md removed, NEXT.md kept as a lead-owned ordered list of IDs. state/CURRENT.md vs handoff/CURRENT.md: state describes the default branch, a handoff describes one unfinished task on its branch; handoff/CURRENT.md removed. HISTORY.md vs git log: HISTORY removed. ARCHITECTURE vs knowledge/modules: ARCHITECTURE is the one-row-per-component map, knowledge docs hold internals. agents/CLAUDE.md and agents/CODEX.md: removed. |
| A4 | Task storage | One file per task, `tasks/TASK-NNN.md`, status in front matter. The board is a `git grep` query, never a committed file. Closed tasks move to `tasks/archive/` 30 days after closing and are never deleted. (P2/P3.) |
| A5 | ID kinds | `TASK-NNN`, `ADR-NNN`, `Q-NNN` (at least 3 digits, zero-padded, never reused); knowledge IDs `MODULE-`, `SERVICE-`, `DB-`, `INT-`, `TS-` plus an UPPER-KEBAB name. The file name is the ID. Handoffs have no ID of their own; the file is named after the work item ID. No `BLK-` IDs. |
| A6 | ID allocation | Next number = 1 + the highest number ever added on any fetched ref, found with `git log --all --diff-filter=A --name-only --format= -- docs/mkb/<dir>` after `git fetch --all`, or with `mkb-check.sh next`. New TASK and Q files are pushed to the default branch as a coordination commit at the moment they are allocated, before anything refers to them; ADRs are allocated on the work branch. Dispatched agents that cannot push to the default branch never allocate TASK or Q IDs. |
| A7 | Collisions | Because the file name is the ID, the same ID created twice is an add/add conflict (loud). For TASK and Q the second creator's push is rejected and its rebase conflicts, so it takes the next number before anyone refers to it. For ADRs (and IDs created in protected-branch PRs) the branch that merges second renumbers its own item, records `formerly:`, and integrates by merge. Nothing on the default branch is ever renumbered. |
| A8 | Front matter | Strict YAML subset. Used only on INDEX, RULES, ARCHITECTURE, tasks, ADRs, questions and knowledge docs. No `updated`, `title`, `tags`, `created` on knowledge. Knowledge docs carry `summary`, `code` (optional for integration and troubleshooting) and `verified`. Keys are written in template order; order is not checked. |
| A9 | Vocabularies | `type` (11 values), `status` per type, `priority` = `critical`, `high`, `normal`, `low`; owners are lowercase handles or `none`, with reserved agent handles. |
| A10 | INDEX.md | A near-static router: layout, routing, authority, people and agents, path overrides, update rules. It never lists individual tasks, ADRs, questions or knowledge docs. |
| A11 | Authority | Three separate orders: what the system does (code wins), what it must do (CONSTRAINTS, then accepted ADRs), what is happening now (the human in the session, then task files on the default branch). (P1 structure, P2/P3 tables.) |
| A12 | Workflow | Fetch and rebase onto the default branch, fixed reads, then grep-based discovery (prefix match on `code`, IDs, error text, one reverse hop to ADRs) with front-matter triage, at most 5 docs read in full. A lite path for tiny changes is inlined in the agent block. Claim before coding. Record discoveries when made. Walk the trigger matrix at the end. Nothing durable changed: update nothing. What needs a human goes in fixed `MKB for humans:` lines (G.7). |
| A13 | Handoff | `handoff/TASK-NNN.md`, committed and pushed on the task branch, at most 30 lines, fixed sections, overwritten by the owner at the end of each session, deleted in the PR that completes the task after its lasting lines move to knowledge. A new owner after a release branches from the old branch and inherits it. Lowest authority. No HISTORY file. |
| A14 | ADR | `decisions/ADR-NNN.md` (no slug), sections Context, Problem, Decision, Alternatives considered, Consequences. Agents write `proposed`; only a human decides `accepted` or `rejected` and is listed in `deciders` (an agent may record a decision a named human makes in the session). A PR carrying a decision merges only with the approval of a listed decider. An ADR reaches the default branch only as `accepted` or `rejected`. Body frozen once accepted. Superseded only by a new ADR. |
| A15 | Tasks | Sections Goal, Acceptance criteria, Notes, Completion. A task is required for work that outlasts the session (created at the latest when a session ends unfinished) or is deferred or delegated. Claim before coding, visible to others. `done` is set inside the delivering PR (trunk-based: a follow-up commit). `dropped` needs a human decision. |
| A16 | Blockers | `status: blocked` plus `blocked_by: [TASK-/Q- IDs]`. Every blocker is an owned task or question; an external impediment becomes a task owned by the person who chases it. No blocker lists. (P2.) |
| A17 | Questions | One file per question, `questions/Q-NNN.md`, owner = the human who must answer. The answer is promoted to its permanent home with `(resolves Q-NNN)`, then the file is deleted. |
| A18 | State | `state/CURRENT.md`: dated one-line bullets in Health (exceptions and deployed versions only), Focus, Warnings, describing the default branch and deployments, edited only when a project-level fact changes. `state/NEXT.md`: ordered queue of at most 10 IDs, edited only by the lead (or an agent a human asks in the session). |
| A19 | Lifecycle | Obsolete information is deleted (git remembers). Only tasks are archived. Known-wrong text gets a `> STALE` banner plus a task. Gardening means running `mkb-check.sh` and resolving every finding; weekly in the full profile, monthly in the minimal profile. |
| A20 | Linking | Bare IDs everywhere, never linked. Relative Markdown links only between MKB docs that have no ID. Code and files outside `docs/mkb/` as backticked repo-root paths. No heading anchors, no line numbers in durable docs. |
| A21 | Naming | Singleton files UPPERCASE.md, directories lowercase, ID files `<ID>.md`, branches `<actor>/task-nnn-<slug>`, commit subjects start with the ID, MKB-only commits start with `mkb:`. |
| A22 | Profiles | Same paths in both profiles. Minimal requires 6 docs plus templates and the checker. Full adds ARCHITECTURE and CONVENTIONS at adoption plus stricter rules. Upgrading never moves or renames a file. |
| A23 | Concurrency | One work item, one branch, one writer, one worktree. Coordination commits (claims, releases, blocks, new tasks and questions, answers) go straight to the default branch from a per-session temporary worktree. Merge classes per file. Formatting for mergeability. Re-read before editing. Conflict cookbook. |
| A24 | Integration | README, CONTRIBUTING and an existing ADR directory (native format kept) are adopted in place via INDEX path overrides. A documentation site that builds `docs/` excludes `docs/mkb/`. Adoption never overwrites existing files. A monolithic Handoff.md is migrated once by triage and replaced by a 3-line stub for 30 days. An authoritative external tracker replaces `tasks/`. |
| A25 | Agent block | One block of at most 35 lines in root `AGENTS.md` between `<!-- MKB:BEGIN v1.0 -->` and `<!-- MKB:END -->`. Root `CLAUDE.md` starts with `@AGENTS.md`. Other tools get a pointer only where they do not read AGENTS.md. |
| A26 | Anti-patterns | 38 numbered anti-patterns (section O). |
| A27 | Worked example | TareLog: weighbridge ticketing, Python, SQLite. Full profile. Two humans, Claude Code, Codex (cloud and CLI). Eight sessions. |
| A28 | Standard repo | README, `spec/01..13`, `templates/{minimal,full}`, `templates/gitattributes-mkb.txt`, `agent-instructions/`, `examples/tarelog/`, root `.gitattributes`. No `templates/documents/` (templates live in each profile's `docs/mkb/templates/`). No live `.gitattributes` inside `templates/<profile>/`. No file in the standard repository is named `AGENTS.md`, `CLAUDE.md` or `GEMINI.md`; copy-ready versions use `.tmpl.md`. |
| A29 | Checker | `docs/mkb/tools/mkb-check.sh`: POSIX sh + git; errors and warnings; `next` subcommand for IDs. Shipped in both profiles; CI use recommended in full. |
| A30 | Formatting | One sentence per line in prose, never re-wrap, tables never column-aligned, LF line endings, UTF-8 without BOM. |

---

## B. Canonical trees and per-file table

### B.1 Full profile tree (every path that can exist)

```text
<repo>/
├── AGENTS.md                         MKB block between markers, plus project agent notes
├── CLAUDE.md                         "@AGENTS.md" plus Claude Code only notes
├── .gitattributes                    LF rules for MKB and agent files
└── docs/
    └── mkb/
        ├── INDEX.md
        ├── agents/
        │   └── RULES.md
        ├── project/
        │   ├── OVERVIEW.md
        │   ├── ARCHITECTURE.md
        │   ├── CONSTRAINTS.md
        │   └── CONVENTIONS.md
        ├── state/
        │   ├── CURRENT.md
        │   └── NEXT.md
        ├── decisions/
        │   └── ADR-NNN.md
        ├── tasks/
        │   ├── TASK-NNN.md
        │   └── archive/
        │       └── TASK-NNN.md
        ├── questions/
        │   └── Q-NNN.md
        ├── knowledge/
        │   ├── modules/
        │   │   └── MODULE-<NAME>.md
        │   ├── services/
        │   │   └── SERVICE-<NAME>.md
        │   ├── database/
        │   │   └── DB-<NAME>.md
        │   ├── integrations/
        │   │   └── INT-<NAME>.md
        │   └── troubleshooting/
        │       └── TS-<NAME>.md
        ├── handoff/
        │   └── TASK-NNN.md               only on task branches, normally never on the default branch
        ├── templates/
        │   ├── TASK.md
        │   ├── ADR.md
        │   ├── QUESTION.md
        │   ├── HANDOFF.md
        │   ├── MODULE.md
        │   ├── SERVICE.md
        │   ├── DB.md
        │   ├── INT.md
        │   ├── TS.md
        │   ├── ARCHITECTURE.md           skeleton of project/ARCHITECTURE.md
        │   └── CONVENTIONS.md            skeleton of project/CONVENTIONS.md
        └── tools/
            └── mkb-check.sh
```

### B.2 Minimal profile at adoption (exact files created)

```text
<repo>/
├── AGENTS.md                         (MKB block inserted)
├── CLAUDE.md                         (only if Claude Code is used)
├── .gitattributes                    (MKB lines added)
└── docs/mkb/
    ├── INDEX.md                      profile: minimal
    ├── agents/RULES.md
    ├── project/OVERVIEW.md
    ├── project/CONSTRAINTS.md
    ├── state/CURRENT.md
    ├── state/NEXT.md
    ├── templates/                    the 11 templates (9 record templates, ARCHITECTURE, CONVENTIONS)
    └── tools/mkb-check.sh
```

Created when first needed in the minimal profile: `project/ARCHITECTURE.md` (copied from `templates/ARCHITECTURE.md`), `project/CONVENTIONS.md` (copied from `templates/CONVENTIONS.md`, or an INDEX override to `CONTRIBUTING.md`), `decisions/`, `tasks/`, `tasks/archive/`, `questions/`, `knowledge/<kind>/`, `handoff/`.

### B.3 Full profile at adoption (exact files created)

Everything in B.2 with `profile: full` in INDEX, plus:
- `docs/mkb/project/ARCHITECTURE.md`
- `docs/mkb/project/CONVENTIONS.md`, unless `CONTRIBUTING.md` already covers conventions; then no file is created and INDEX gets a path override row pointing to `CONTRIBUTING.md` (and the CONVENTIONS rows of F.2, see F.2 "Rows that change with an override").
- A CI job that runs `sh docs/mkb/tools/mkb-check.sh` (SHOULD, advisory).

Created when first needed in the full profile: `decisions/`, `tasks/`, `tasks/archive/`, `questions/`, `knowledge/<kind>/`, `handoff/`.

### B.4 Creation rules

- A directory exists only once it holds a file. No `.gitkeep`, no empty placeholder files.
- A required singleton with nothing to say yet contains its skeleton headings and, where its skeleton says so, `None recorded as of YYYY-MM-DD.`
- Nothing named `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` or `AGENTS.override.md` may exist under `docs/mkb/`.

### B.5 Per-file table

Profile legend: `min` = created at adoption in both profiles. `full` = created at adoption in the full profile, created when needed in the minimal profile. `lazy` = created when first needed in both profiles.

| Path | Purpose | Profile | Updated by / when | Size budget | Front matter |
|---|---|---|---|---|---|
| `AGENTS.md` (MKB block) | Operational rules auto-loaded by most agents | min | A human; only when upgrading the MKB version (the block between markers is replaced whole) | block ≤ 35 lines | no |
| `CLAUDE.md` | Imports AGENTS.md for Claude Code | min, if Claude Code is used | A human; at adoption | own content ≤ 20 lines | no |
| `.gitattributes` (MKB lines) | LF line endings for MKB and agent files | min | A human; at adoption | 4 lines | no |
| `docs/mkb/INDEX.md` | Entry point: layout, routing, authority, people, overrides | min | A human, or an agent through a reviewed PR; only when layout, routing, people or overrides change; never per task | ≤ 120 lines | yes |
| `docs/mkb/agents/RULES.md` | Operational rulebook for reading and writing the MKB | min | Standard text replaced on MKB version upgrade; humans edit only the final section "Project-specific rules" | ≤ 500 lines | yes |
| `docs/mkb/project/OVERVIEW.md` | Purpose, users, scope, stack, commands, glossary | min | Anyone whose change alters scope, stack or commands, in the same PR | ≤ 80 lines | no |
| `docs/mkb/project/ARCHITECTURE.md` | System context, components, data flow, deployment, code map | full | Whoever adds, removes or re-bounds a component, in the same PR; `verified` bumped only after a check (C.3) | ≤ 150 lines | yes |
| `docs/mkb/project/CONSTRAINTS.md` | Non-negotiable rules with sources (normative) | min | Humans; an agent only when a human states the rule in the session, citing that human | ≤ 80 lines | no |
| `docs/mkb/project/CONVENTIONS.md` | Project conventions that tooling and CONTRIBUTING.md do not cover (normative) | full | Anyone through a PR approved by a human, when a convention changes | ≤ 120 lines | no |
| `docs/mkb/state/CURRENT.md` | Health, focus, warnings of the default branch as dated bullets | min | Anyone whose change alters a project-level fact (in the delivering PR or as a coordination commit); the lead writes Focus; gardening prunes | ≤ 40 lines | no |
| `docs/mkb/state/NEXT.md` | Ordered pickup queue of at most 10 IDs | min | The lead only; an agent only when a human asks in the session | ≤ 15 lines | no |
| `docs/mkb/decisions/ADR-NNN.md` | One decision | lazy | Author on a branch while `proposed`; a human sets `accepted`/`rejected`; afterwards only `status` and `superseded_by` change | ≤ 100 lines | yes |
| `docs/mkb/tasks/TASK-NNN.md` | One work item | lazy | Creator (a coordination commit at allocation); then only the owner (others append Notes lines; anyone may edit a task whose owner is `none`; the lead may edit any task; a promoter applying K.3 may edit the parts J.3 names) | ≤ 60 lines | yes |
| `docs/mkb/tasks/archive/TASK-NNN.md` | Tasks closed more than 30 days ago | lazy | Gardening moves files here with `git mv`; never edited afterwards | ≤ 60 lines | yes |
| `docs/mkb/questions/Q-NNN.md` | One open question for a person | lazy | Asker creates; owner answers; the promoter deletes it | ≤ 40 lines | yes |
| `docs/mkb/knowledge/modules/MODULE-<NAME>.md` | Internals of one code module | lazy | Whoever changes its behavior, interface or invariants, or learns a gotcha | ≤ 150 lines | yes |
| `docs/mkb/knowledge/services/SERVICE-<NAME>.md` | One runnable service: run, configure, operate | lazy | Whoever changes its runtime, configuration or deployment | ≤ 150 lines | yes |
| `docs/mkb/knowledge/database/DB-<NAME>.md` | One data store or schema area | lazy | Whoever changes that schema or its migrations | ≤ 150 lines | yes |
| `docs/mkb/knowledge/integrations/INT-<NAME>.md` | One external system, device, vendor or customer interface | lazy | Whoever learns or changes the contract | ≤ 150 lines | yes |
| `docs/mkb/knowledge/troubleshooting/TS-<NAME>.md` | One recurring or cross-cutting failure: symptom, cause, fix | lazy | Whoever solved a non-obvious failure that cost more than 30 minutes | ≤ 60 lines | yes |
| `docs/mkb/handoff/TASK-NNN.md` | Transfer notes for one unfinished task | lazy | The task owner, overwritten at the end of each session on the task branch; deleted in the PR that completes or drops the task | ≤ 30 lines | no |
| `docs/mkb/templates/*.md` | Skeletons copied when creating a record, `project/ARCHITECTURE.md` or `project/CONVENTIONS.md` | min | Replaced only on MKB version upgrade | ≤ 40 lines each | yes, with placeholders (except `HANDOFF.md` and `CONVENTIONS.md`, which have none) |
| `docs/mkb/tools/mkb-check.sh` | Consistency checker and ID allocator | min | Replaced only on MKB version upgrade | ≤ 450 lines | no |

Files that the brief proposed and that v1.0 does NOT use: `tasks/TODO.md`, `tasks/IN-PROGRESS.md`, `tasks/BLOCKED.md`, `tasks/DONE.md`, `state/BLOCKERS.md`, `questions/OPEN.md`, `agents/CODEX.md`, `agents/CLAUDE.md`, `handoff/CURRENT.md`, `handoff/HISTORY.md`.

### B.6 Deviations from the brief (for spec/02 §2.6)

| Brief | v1.0 | Reason |
|---|---|---|
| `tasks/TODO.md`, `IN-PROGRESS.md`, `BLOCKED.md`, `DONE.md` | `tasks/TASK-NNN.md` + `tasks/archive/` | A status change is a one-line edit in a file only its owner writes; parallel branches never conflict across tasks and conflict loudly on the same task; ID collisions become add/add conflicts; a task's whole history is `git log` of one file. |
| `state/BLOCKERS.md` | removed; `status: blocked` + `blocked_by` | A blocker list duplicates task status and becomes a hot file; every blocker must be an owned task or question so that someone clears it. |
| `state/NEXT.md` | kept, lead-owned, IDs only | Priority says how important; NEXT says in what order. One writer avoids conflicts. |
| `state/CURRENT.md` | kept; dated bullets; edited only on project-level change | Per-session updates on parallel branches guarantee conflicts and filler. |
| `questions/OPEN.md` | `questions/Q-NNN.md` | Per-question files never conflict; the directory listing is the open list; answers move to their home. |
| `agents/CODEX.md`, `agents/CLAUDE.md` | removed | Tools auto-load only specific root or nested files; a `CLAUDE.md` or `AGENTS.md` under `docs/mkb/` would be loaded as scoped instructions by Claude Code, Cursor or Copilot; two rule copies drift. |
| `handoff/CURRENT.md` | `handoff/TASK-NNN.md` on the task branch | One file per unfinished task has exactly one writer; a single CURRENT file is overwritten by every parallel session. |
| `handoff/HISTORY.md` | removed | It duplicates `git log` and task Completion sections, needs a cap and rotation, and is an append hot spot; handoff lines that stay true move to knowledge docs or task Notes before the handoff is deleted (T3). |
| Knowledge subdirectories created upfront | created lazily | Git does not track empty directories. |
| Front matter with `updated` | no `updated`; `verified`, `code`, `summary` added | Git records edit dates; a bumped line conflicts on every concurrent edit; `verified` records what git cannot know. |
| Block-style `related:` list in the brief's example | one-line flow lists `[a, b]` | One grep line returns the whole value. |
| "After working, update CURRENT and NEXT" | CURRENT only on project-level change; NEXT only by the lead | Avoids churn and conflicts; keeps priorities with a human. |
| (not in brief) | `templates/`, `tools/mkb-check.sh`, `tasks/archive/`, `.gitattributes`, branch naming, coordination commits, `formerly` | Each makes concurrent work merge cleanly or conflict loudly, or makes rules checkable. |

---

## C. Controlled vocabularies and front matter schemas

### C.1 Where front matter is used

Front matter is REQUIRED on: `INDEX.md`, `agents/RULES.md`, `project/ARCHITECTURE.md`, every task, ADR, question and knowledge doc, and the templates except `templates/HANDOFF.md` and `templates/CONVENTIONS.md`.
ADRs in a directory adopted in place (N.2) keep their native format and carry no MKB front matter.
Front matter is FORBIDDEN on: `project/OVERVIEW.md`, `project/CONSTRAINTS.md`, `project/CONVENTIONS.md`, `state/CURRENT.md`, `state/NEXT.md`, handoff files.

### C.2 Format rules (the MKB YAML subset)

1. The file starts with a line `---`; front matter ends at the next line `---`; the H1 is on the line right after it (canonical form, used by every skeleton). A blank line between the closing `---` and the H1 is tolerated; anything else there is an error (E3).
2. One `key: value` per line. No nested maps, no multi-line values, no YAML comments.
3. Keys are lowercase snake_case. Write them in the template order of C.5 and never reorder existing keys; order is not checked.
4. A value is either a scalar or a one-line flow list `[a, b, c]`.
5. Dates are unquoted `YYYY-MM-DD`. No times.
6. `mkb_version` is always quoted: `mkb_version: "1.0"`.
7. Handles are written without `@` (YAML reserves `@`). Prose may use `@marta`; front matter never does.
8. Optional keys with no value are omitted entirely. Never write `key:` with an empty value and never write `key: []`.
9. A scalar MUST NOT contain `: ` or ` #`; rephrase with a dash instead. It MUST NOT start with `[`, `{`, `>`, `|`, `*`, `&`, `!`, `%`, `@` or a backtick (except list values, which are flow lists).
10. At most 12 keys, so that the first 16 lines of a file show the front matter and the H1 (12 keys, 2 delimiters, the H1, and room for the tolerated blank line).

### C.3 Field dictionary

| Key | Value | Used by |
|---|---|---|
| `id` | the record ID; MUST equal the file name without `.md` | task, adr, question, knowledge |
| `type` | vocabulary C.4.1 | every file with front matter |
| `status` | vocabulary C.4.2 for the type | task, adr, question |
| `priority` | `critical`, `high`, `normal`, `low` | task |
| `owner` | handle or `none` (task); human handle (question) | task, question |
| `branch` | exact git branch name, or `pending` when a dispatched cloud agent has not created its branch yet | task |
| `created` | date the record was created | task, question |
| `closed` | date the task was set to `done` or `dropped` | task |
| `blocked_by` | flow list of TASK- and Q- IDs, non-empty | task |
| `date` | date of the decision (acceptance or rejection); while `proposed`, the date proposed | adr |
| `deciders` | flow list of human handles, non-empty | adr |
| `supersedes` | flow list of ADR IDs | adr |
| `superseded_by` | one ADR ID | adr |
| `asked_by` | handle of the asker | question |
| `summary` | one line, at most 120 characters, containing the words people will grep for | knowledge |
| `code` | flow list of repo-root-relative paths, no leading `/` or `./`, no globs, directories end with `/` | knowledge (required for module, service, database; optional for integration, troubleshooting); task (optional; SHOULD be set at claim, J.4) |
| `verified` | date someone last checked the doc against the code on the default branch: the whole doc when it is created and at the 180-day re-check (W16); the parts a change affects when that change touches one of its `code` paths (T11) | knowledge, architecture |
| `related` | flow list of IDs (MKB IDs or external tracker keys such as `GH-123`) | task, adr, question, knowledge |
| `formerly` | the previous ID of this record after a renumber or rename | task, adr, question, knowledge |
| `mkb_version` | `"1.0"` | index, rules |
| `profile` | `minimal` or `full` | index |

### C.4 Vocabularies

#### C.4.1 `type`

| Value | File |
|---|---|
| `index` | `INDEX.md` |
| `rules` | `agents/RULES.md` |
| `architecture` | `project/ARCHITECTURE.md` |
| `task` | `tasks/TASK-NNN.md`, `tasks/archive/TASK-NNN.md` |
| `adr` | `decisions/ADR-NNN.md` |
| `question` | `questions/Q-NNN.md` |
| `module` | `knowledge/modules/MODULE-<NAME>.md` |
| `service` | `knowledge/services/SERVICE-<NAME>.md` |
| `database` | `knowledge/database/DB-<NAME>.md` |
| `integration` | `knowledge/integrations/INT-<NAME>.md` |
| `troubleshooting` | `knowledge/troubleshooting/TS-<NAME>.md` |

#### C.4.2 `status` per type

| Type | Values | Meaning |
|---|---|---|
| task | `todo` | not started; claimable if `owner` is `none` or your handle |
| task | `in-progress` | claimed; has `owner` and `branch` |
| task | `blocked` | cannot proceed until every item in `blocked_by` is resolved; may be owned or unowned |
| task | `done` | delivered; `closed` and `## Completion` filled; set inside the delivering PR |
| task | `dropped` | will not be done; `closed` and a reason in `## Completion`; needs a human decision |
| adr | `proposed` | draft; exists only on branches |
| adr | `accepted` | binding; body frozen |
| adr | `rejected` | considered and declined; kept as a record |
| adr | `superseded` | replaced by the ADR in `superseded_by` |
| adr | `deprecated` | no longer applies and has no replacement (for example, the component was removed) |
| question | `open` | waiting for its owner's answer |
| question | `answered` | `## Answer` filled; waiting for promotion and deletion |

Knowledge docs, ARCHITECTURE, INDEX and RULES have no `status`.
Known-wrong knowledge is marked with a `> STALE` banner (section L.5), not a status.

#### C.4.3 `priority` (tasks only)

| Value | Meaning |
|---|---|
| `critical` | Drop other work: the default branch is broken, production is down, or there is a legal, safety or data-loss risk. |
| `high` | Needed for the current Focus in `state/CURRENT.md`, or blocks other tasks. |
| `normal` | Default. |
| `low` | Nice to have; gardening may propose dropping it after 90 days. |

#### C.4.4 Handles and `owner`

- A handle matches `^[a-z][a-z0-9-]{0,31}$`.
- Reserved agent handles: `claude-code`, `codex`, `cursor`, `gemini-cli`, `aider`, `copilot`, `windsurf`, `agent` (any other agent tool).
- Human handles: the person's lowercase forge or git handle; MUST NOT equal a reserved agent handle.
- Every handle used in a project SHOULD appear in INDEX `## People and agents`.
- `owner: none` means unassigned.
- Parallel sessions of the same tool share its handle; the `branch` field tells them apart (J.4 step 7 defines when an owned task is yours). Never invent handles like `claude-2`.
- `deciders` MUST contain only human handles.
- A question's `owner` MUST be a human handle.

### C.5 Schemas per document type (keys listed in template order)

R = required, C = conditional (rule in the last column), O = optional.

#### index

| Key | Req | Rule |
|---|---|---|
| `type` | R | `index` |
| `mkb_version` | R | `"1.0"` |
| `profile` | R | `minimal` or `full` |

#### rules

| Key | Req | Rule |
|---|---|---|
| `type` | R | `rules` |
| `mkb_version` | R | `"1.0"` |

#### architecture

| Key | Req | Rule |
|---|---|---|
| `type` | R | `architecture` |
| `verified` | R | date |

#### task

| Key | Req | Rule |
|---|---|---|
| `id` | R | `TASK-NNN` |
| `type` | R | `task` |
| `status` | R | task vocabulary |
| `priority` | R | priority vocabulary |
| `owner` | R | handle or `none`; MUST NOT be `none` when `in-progress` or `done` |
| `branch` | C | required when `in-progress`; forbidden when `todo` (removed on release); optional when `blocked`, `done` or `dropped` (kept for history) |
| `created` | R | date |
| `closed` | C | required when `done` or `dropped`; forbidden otherwise |
| `blocked_by` | C | required when `blocked`; forbidden otherwise |
| `related` | O | IDs |
| `code` | O | paths |
| `formerly` | O | previous ID |

#### adr

| Key | Req | Rule |
|---|---|---|
| `id` | R | `ADR-NNN` |
| `type` | R | `adr` |
| `status` | R | adr vocabulary |
| `date` | R | date |
| `deciders` | C | required for every status except `proposed` |
| `supersedes` | O | ADR IDs |
| `superseded_by` | C | required when `superseded`; forbidden otherwise |
| `related` | O | IDs (components and tasks) |
| `formerly` | O | previous ID |

#### question

| Key | Req | Rule |
|---|---|---|
| `id` | R | `Q-NNN` |
| `type` | R | `question` |
| `status` | R | `open` or `answered` |
| `owner` | R | human handle who must answer |
| `asked_by` | R | handle |
| `created` | R | date |
| `related` | O | IDs |
| `formerly` | O | previous ID |

There is deliberately no `blocks` key: the blocked task's `blocked_by` is the single source.

#### module, service, database, integration

| Key | Req | Rule |
|---|---|---|
| `id` | R | knowledge ID with the prefix matching the type |
| `type` | R | `module`, `service`, `database` or `integration` |
| `summary` | R | ≤ 120 characters |
| `code` | C | required (at least one path) for `module`, `service` and `database`; optional for `integration` (omit it while no code talks to the system yet) |
| `verified` | R | date |
| `related` | O | IDs |
| `formerly` | O | previous ID |

#### troubleshooting

Same as above with `type: troubleshooting`; `code` is optional (omit it for environment or toolchain problems).
W2 and W3 do not apply to a doc without `code`.

### C.6 Fields deliberately not used

| Field | Why not |
|---|---|
| `updated` | Git records edit dates; a bumped line conflicts on every concurrent edit. |
| `title` | The H1 is the title. |
| `tags` | `summary`, IDs and grep do the job. |
| `created` on knowledge and ADRs | Git records it; ADRs have `date`. |
| `owner` on knowledge docs | `git log` and `git blame` show authors. |
| `assignee`, `reviewer`, `estimate`, `due` | The PR and the team's planning carry these; the MKB is not a project-management tool. |
| `blocks` on questions | Duplicates the task's `blocked_by`. |
| `status` on knowledge | Replaced by the `> STALE` banner. |

---

## D. IDs, naming, allocation and collisions

### D.1 ID patterns

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
- Numbers are zero-padded to at least 3 digits (`TASK-007`, never `TASK-7`). After `TASK-999` comes `TASK-1000`; existing IDs are never re-padded.
- Knowledge IDs are at most 40 characters, ASCII, singular, 1 to 3 words after the prefix, named after a stable noun from the code or the vendor (the component, device or symptom), never after a task.
- The first character after a knowledge prefix is a letter, so tracker keys like `INT-45` are never mistaken for knowledge IDs.
- IDs are written in uppercase, literally, everywhere (never "ADR 7", "adr-007", "Task 42").
- Grep contract for tooling: `\b(TASK|ADR|Q)-[0-9]{3,}\b` and `\b(MODULE|SERVICE|DB|INT|TS)-[A-Z][A-Z0-9]*(-[A-Z0-9]+)*\b`.
- Templates, RULES.md and INDEX.md use only placeholders (`TASK-NNN`, `ADR-NNN`, `Q-NNN`, `MODULE-<NAME>`), which never match the grep contract. They MUST NOT contain concrete example IDs.

### D.2 File and directory names

| Thing | Rule | Example |
|---|---|---|
| Directories | lowercase; plural for collections, as in B.1 | `decisions/`, `knowledge/integrations/` |
| Singleton docs | `UPPERCASE.md` | `INDEX.md`, `CURRENT.md`, `RULES.md` |
| ID docs | exactly `<ID>.md`; no slug | `ADR-007.md`, `INT-WI200.md` |
| Handoff files | `<work item ID>.md` | `handoff/TASK-042.md`, `handoff/GH-123.md` with an external tracker |
| Templates | `UPPERCASE.md` named after the record kind | `templates/TASK.md` |
| Checker | `tools/mkb-check.sh` | - |
| Case | never two names differing only in case | - |

### D.3 Branches, commits and PRs

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
| New task (coordination commit at allocation, D.4 step 6) | `TASK-NNN: add` | `TASK-006: add` |
| Claim | `TASK-NNN: claim` or, for a dispatched agent, `TASK-NNN: claim for <handle>` | `TASK-003: claim for codex` |
| Release | `TASK-NNN: release` | `TASK-004: release` |
| Block / unblock | `TASK-NNN: blocked on <IDs>` / `TASK-NNN: unblocked` | `TASK-004: blocked on Q-001` |
| Done, trunk-based only (J.6) | `TASK-NNN: done` | - |
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

### D.4 Allocating numbered IDs

1. `git fetch --all --quiet` (skip with no remote).
2. List every file ever added under the record directory on any ref:
   - Tasks: `git log --all --diff-filter=A --name-only --format= -- docs/mkb/tasks`
   - ADRs: `git log --all --diff-filter=A --name-only --format= -- docs/mkb/decisions` (or the ADR directory adopted in place, N.2)
   - Questions: `git log --all --diff-filter=A --name-only --format= -- docs/mkb/questions`
3. Also consider files you created but have not committed.
4. Next ID = highest number found + 1, zero-padded to at least 3 digits (in an adopted ADR directory: padded to the width of its existing numbers, for example `ADR-0008`).
5. Equivalent: `sh docs/mkb/tools/mkb-check.sh next TASK` (or `ADR`, `Q`; add `--adr-dir <dir>` for an adopted ADR directory).
6. Tasks and questions: create the file from its template and push it to the default branch at once as a coordination commit (`TASK-NNN: add`, `Q-NNN: ask <owner>`; M.2 recipe), before anything refers to the ID, including follow-ups found during work. The push is a compare-and-swap: a rejected push followed by an add/add conflict when you rebase the coordination worktree means someone took that number; `git rebase --abort`, allocate again from step 1, and retry. Protected default branch: the file goes in a one-file `mkb-coord` PR (J.4a step 5). ADRs: create the file on your work branch (it stays `proposed` there, I.4) and push the branch soon.
7. Dispatched agents that cannot push to the default branch never allocate TASK or Q IDs: they write `New task: <title>` or `Question for <handle>: <question>` in their `MKB for humans:` lines (G.7), and the dispatching human creates the records.

POSIX sh pipeline (for RULES.md and spec/04); it prints the next ID, `TASK-001` when none exists:

```sh
git fetch --all --quiet
git log --all --diff-filter=A --name-only --format= -- docs/mkb/tasks \
  | grep -oE 'TASK-[0-9]+' | awk -F- '$2+0 > n { n = $2+0 } END { printf "TASK-%03d\n", n+1 }'
```

Adopted ADR directory (sh; prints the next ID at the directory's width; `mkb-check.sh next ADR --adr-dir docs/adr` does the same):

```sh
git log --all --diff-filter=A --name-only --format= -- docs/adr | sed 's|.*/||' \
  | grep -oE '^[0-9]+' | awk '$1+0 > n { n = $1+0 } { w = length($1) } END { f = "ADR-%0" w "d\n"; printf f, n+1 }'
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

Numbers are never reused, including numbers of deleted questions and archived tasks.
Gaps are normal.

### D.5 Collisions and renumbering

Detection: two branches that add the same `<ID>.md` get an add/add conflict on rebase, merge or PR ("This branch has conflicts").
For tasks and questions this normally happens in the coordination worktree at creation time, where the fix is to take the next number (D.4 step 6).
This section covers IDs that already live on a branch when the collision shows: ADRs, and IDs in `mkb-coord` PRs under a protected default branch.
Residual cases that git cannot see (an item created on a branch while another item with the same number was already archived, or an adopted ADR directory) are caught by `mkb-check.sh` error E1 and by the duplicate-number one-liner in N.4.

Rule: the branch that merges second renumbers its own item. The item on the default branch never changes.

Procedure:
1. Stop the rebase or merge: `git rebase --abort` (or `git merge --abort`). This avoids the reversed meaning of "ours" and "theirs" during a rebase.
2. Allocate the next free ID (D.4) after fetching.
3. `git mv <dir>/<OLD-ID>.md <dir>/<NEW-ID>.md`, set `id: <NEW-ID>`, add `formerly: <OLD-ID>`.
4. Run `git diff origin/main...HEAD` and, only in lines your branch added that refer to your item, replace the old ID with the new one: other MKB files, code comments that cite it, and your handoff file name if the renumbered item is your own work item.
5. Leave every pre-existing line that refers to the default branch's item untouched.
6. Commit `mkb: renumber <OLD-ID> -> <NEW-ID> (ID collision)`, then run `git merge origin/main`, not a rebase: a rebase replays the commit that added `<OLD-ID>.md` and conflicts again, while a merge compares trees and sees no conflict. From then on this branch takes the default branch by merge (exception to M.1). Push, and write "Renumbered <OLD-ID> -> <NEW-ID> (collision)" in the PR description.
7. Already pushed commit messages keep the old ID; `formerly` lets `git grep -w <OLD-ID>` find both records.

Knowledge-name collision (two branches both created `INT-HAULER-SFTP.md`): both documented the same thing; merge the content into one doc by hand; keep the older `verified` unless you re-checked the merged doc against the merged code (M.6).

### D.6 Dates and handles in text

- Dates everywhere are `YYYY-MM-DD`. No times, no time zones, no locale formats.
- Dated one-liners (state bullets, task Notes, Completion first line, question Answer, STALE banner) use the form `YYYY-MM-DD <handle>: <text>`.
- Prose may write `@marta`; fixed formats use the bare handle.

---

## E. Linking conventions

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
| MKB from code | ID in a comment where code embodies a non-obvious decision or pending work | `# Half-up rounding per ADR-004.` / `# TODO(TASK-006): buffer readings while the DB is locked.` |
| MKB from git | ID at the start of the commit subject, in the branch name and in the PR title | `TASK-042: add CSV export` |

Additional rules:
- Inside INDEX.md the Routing and Authority sections name MKB paths as plain text (for example `project/OVERVIEW.md` without backticks or link), because the Layout table already links them.
- Line numbers are allowed only in handoff files.
- A durable doc (knowledge, ADR, project, state) never refers to a handoff file.
- Markdown links MUST point to files that exist in the same tree; templates contain no relative links.
- Why IDs are never linked: the file name is the ID, so `git grep -w`, `find -name "<ID>.md"` and a forge's file finder (type the ID) resolve it in one step, and bare IDs survive archiving and directory moves.

---

## F. Canonical skeletons of every file

Writers copy these verbatim.
Placeholders are in angle brackets (`<Project name>`, `<handle>`, `<path>/`) or are `NNN`, `YYYY-MM-DD`, `<NAME>`.
Guide comments have the exact form `<!-- guide: ... -->`; whoever creates a real file from a skeleton MUST delete every guide comment and every optional section that stays empty.
Skeletons that contain inner code fences are shown inside `~~~~` fences.

### F.1 `docs/mkb/INDEX.md` (full profile)

~~~~markdown
---
type: index
mkb_version: "1.0"
profile: full
---
# MKB Index: <Project name>

This folder is the project memory for humans and AI agents, following MKB Standard v1.0.
Code and tests are the truth for what the system does; this folder holds what code cannot show: intent, decisions, hard-won knowledge, current state, open work and handoffs.
Do not read it all: follow the routes below and find records by ID with `git grep`.

## Start here
1. [state/CURRENT.md](state/CURRENT.md): the condition of the default branch; read it every session.
2. Your task `tasks/TASK-NNN.md` and, on the task's branch, its handoff `handoff/TASK-NNN.md`.
3. No task yet: the first ID in [state/NEXT.md](state/NEXT.md) whose task on the default branch is `todo` with `owner: none` or you.
4. How to read and write the MKB: [agents/RULES.md](agents/RULES.md).

## Layout
| Path | Holds | Exists |
|---|---|---|
| [project/OVERVIEW.md](project/OVERVIEW.md) | purpose, users, scope, stack, commands, glossary | always |
| [project/ARCHITECTURE.md](project/ARCHITECTURE.md) | system context, components, data flow, deployment, code map | always |
| [project/CONSTRAINTS.md](project/CONSTRAINTS.md) | non-negotiable rules with sources (normative) | always |
| [project/CONVENTIONS.md](project/CONVENTIONS.md) | project conventions not covered elsewhere (normative) | always |
| [state/CURRENT.md](state/CURRENT.md) | health, focus and warnings as dated bullets | always |
| [state/NEXT.md](state/NEXT.md) | ordered pickup queue of IDs, kept by the lead | always |
| `decisions/ADR-NNN.md` | one decision each | when needed |
| `tasks/TASK-NNN.md` | one work item each, status in front matter | when needed |
| `tasks/archive/` | tasks closed more than 30 days ago; never read by default | when needed |
| `questions/Q-NNN.md` | open questions only a person can answer | when needed |
| `knowledge/modules/MODULE-<NAME>.md` | internals of one code module | when needed |
| `knowledge/services/SERVICE-<NAME>.md` | one runnable service: run, configure, operate | when needed |
| `knowledge/database/DB-<NAME>.md` | one data store or schema area | when needed |
| `knowledge/integrations/INT-<NAME>.md` | one external system, device or partner interface | when needed |
| `knowledge/troubleshooting/TS-<NAME>.md` | one recurring failure: symptom, cause, fix | when needed |
| `handoff/TASK-NNN.md` | notes for one unfinished task; lives on the task's branch | when needed |
| [agents/RULES.md](agents/RULES.md) | rules for reading and writing the MKB | always |
| `templates/` | skeletons to copy when creating a record, project/ARCHITECTURE.md or project/CONVENTIONS.md | always |
| `tools/mkb-check.sh` | consistency checks: `sh docs/mkb/tools/mkb-check.sh` | always |

## Routing
| You need | Read | Find it with |
|---|---|---|
| What the project is, stack, commands | project/OVERVIEW.md, then `README.md` | - |
| How the parts fit and where code lives | project/ARCHITECTURE.md | component table, column Doc |
| What must never be broken | project/CONSTRAINTS.md, then accepted ADRs | `git grep -l "^status: accepted" -- docs/mkb/decisions` |
| How code is written here | project/CONVENTIONS.md | - |
| Why something is the way it is | decisions/ | `git grep -l -w "<ID or term>" -- docs/mkb/decisions` |
| Docs about code you will touch | knowledge docs whose `code` entry is a prefix of your path, then ADRs citing them | `git grep "^code:" -- docs/mkb/knowledge docs/mkb/tasks`, then `git grep -l -w "<doc ID>" -- docs/mkb/decisions` |
| Any doc on a topic | knowledge summaries | `git grep -i "^summary:.*<word>" -- docs/mkb/knowledge` |
| An error you are seeing | knowledge/ | `git grep -l -F "<exact error text>" -- docs/mkb/knowledge` |
| Everything about one record | all | `git grep -n -w "<ID>" -- docs/mkb` |
| What to work on | state/NEXT.md, then open tasks | `git grep -l "^status: todo" origin/main -- docs/mkb/tasks` |
| Who is working on what | tasks in progress | `git grep -l "^status: in-progress" origin/main -- docs/mkb/tasks` |
| What is blocked and on what | blocked tasks | `git grep "^blocked_by:" origin/main -- docs/mkb/tasks` |
| Questions waiting for people | questions/ | `git grep "^owner:" origin/main -- docs/mkb/questions` |
| Health, deployments, warnings | state/CURRENT.md | - |
| Where an unfinished task stopped | its handoff on the task's branch, or on the branch its Notes name as released | `git show origin/<branch>:docs/mkb/handoff/TASK-NNN.md` |
| How a closed task ended | its Completion section | `git grep -n -w "<ID>" -- docs/mkb/tasks` |
| Docs known to be wrong | STALE banners | `git grep -n "^> STALE [0-9]" -- docs/mkb` |
| How to write MKB docs | agents/RULES.md, templates/ | - |

Status queries read `origin/main` (without a remote: `main`), because claims and answers land there first; their output paths start with `origin/main:`.

## Authority
- What the system does: code and tests on the default branch, then knowledge docs and project/ARCHITECTURE.md, then state/CURRENT.md, then handoffs. A descriptive doc that disagrees with the code is wrong.
- What the system must do: project/CONSTRAINTS.md, then accepted ADRs (a superseding ADR wins), then project/ARCHITECTURE.md and project/CONVENTIONS.md, then the task's acceptance criteria.
- What is happening now: the human in your session, then task files on the default branch, then state/CURRENT.md, then handoffs.
- Never authoritative: proposed, rejected, superseded or deprecated ADRs; open questions; text under a `> STALE` banner; `tasks/archive/`; `templates/`.

## People and agents
| Handle | Kind | Role |
|---|---|---|
| <handle> | human | lead: orders state/NEXT.md, accepts or rejects ADRs |
| <handle> | agent | <tool and how it runs, for example local worktrees or cloud tasks> |

## Path overrides
| Kind | Lives at | Note |
|---|---|---|
| none | - | - |

## Updating the MKB
1. Update only what your work changed: trigger matrix in [agents/RULES.md](agents/RULES.md), section 3.
2. Refer to records by bare ID; never copy content from one doc into another.
3. This file changes only when the layout, routing, people or path overrides change, never per task.
4. What needs a human (questions, ADR decisions, NEXT suggestions, routing gaps) goes in the `MKB for humans:` lines of your PR description: [agents/RULES.md](agents/RULES.md), section 1.
~~~~

### F.2 `docs/mkb/INDEX.md` (minimal profile)

Identical to F.1 except exactly these four differences.

1. Front matter line `profile: minimal`.
2. The Layout rows for ARCHITECTURE and CONVENTIONS become (backticked paths, not links, because the files do not exist yet):

```markdown
| `project/ARCHITECTURE.md` | system context, components, data flow, deployment, code map | when needed |
| `project/CONVENTIONS.md` | project conventions not covered elsewhere (normative) | when needed, or see Path overrides |
```

3. The Routing rows become:

```markdown
| How the parts fit and where code lives | project/ARCHITECTURE.md (if it exists) | component table, column Doc |
| How code is written here | project/CONVENTIONS.md (if it exists), else `CONTRIBUTING.md` | - |
```

4. Nothing else changes.

Path override rows (both profiles, examples of the exact form):

```markdown
| conventions | `CONTRIBUTING.md` | no project/CONVENTIONS.md; CONTRIBUTING.md is authoritative |
| decisions | `docs/adr/NNNN-<slug>.md` | adr-tools directory adopted in place, native format; IDs are ADR-NNNN; run mkb-check with `--adr-dir docs/adr` |
| tasks | <tracker URL> | tracker is authoritative; no tasks/ |
```

When a project adds its first override row, it deletes the `| none | - | - |` row.

Rows that change with an override (both profiles, so that no link points to a missing file):
- conventions: the CONVENTIONS Layout row becomes the backticked row of difference 2, and the Routing row "How code is written here" becomes the row of difference 3. This applies in the full profile too when B.3 replaces CONVENTIONS.md by the override.
- decisions: the Layout row `decisions/ADR-NNN.md` names the adopted directory; the Routing row "What must never be broken" becomes the row below; "Why something is the way it is" greps the adopted directory instead of `docs/mkb/decisions`.

```markdown
| What must never be broken | project/CONSTRAINTS.md, then accepted ADRs in `docs/adr/` | `git grep -l -i -E '^(status: *"?)?accepted' -- docs/adr` |
```

- tasks: the Layout rows for `tasks/` and the Routing rows "What to work on", "Who is working on what" and "What is blocked and on what" name the tracker and its saved queries instead of `git grep` commands.

### F.3 `docs/mkb/agents/RULES.md`

RULES.md is standard text, identical in both profiles, not a skeleton with placeholders.
It MUST contain these sections in this order and MUST agree word for word with the rules in this contract where a rule is stated (paraphrase explanations only).
It uses only placeholder IDs (D.1): where this contract gives concrete example IDs, branch names or commit subjects, RULES.md writes them with placeholders (`TASK-NNN`, `<OLD-ID>`, `<handle>`, `<path>`).
It contains no `<!-- guide:` comments.
Budget ≤ 500 lines. WP8 drafts RULES.md first and reports its measured line count; compact tables are preferred to prose, and rules are never paraphrased to save lines.
Each `##` section is self-contained, so an agent reads only the section it needs; `git grep -n "^## " -- docs/mkb/agents/RULES.md` prints the line where each section starts.

~~~~markdown
---
type: rules
mkb_version: "1.0"
---
# MKB rules

Standard text of MKB Standard v1.0.
Do not edit above the section "Project-specific rules"; it is replaced when the MKB version is upgraded.
The project's own additions go in section 16.

## 1. Session workflow
## 2. Discovery
## 3. Trigger matrix
## 4. IDs, names and links
## 5. Claiming and task status
## 6. Blockers and questions
## 7. Handoffs
## 8. ADRs
## 9. Knowledge docs and STALE banners
## 10. State files
## 11. Concurrency and conflicts
## 12. Formatting and front matter
## 13. Gardening
## 14. Profile differences
## 15. Path overrides and adopted directories
## 16. Project-specific rules
None.
~~~~

Required content per section (source in this contract):
1. Session workflow: before / during / after steps (G.1 to G.3), the lite path (G.4) and the `MKB for humans:` lines (G.7).
2. Discovery: the algorithm (G.2) with both sh and PowerShell forms of `head -n 16` (`Get-Content -TotalCount 16 <file>`).
3. Trigger matrix: the full table G.5, verbatim.
4. IDs, names and links: patterns (D.1), file names (D.2), branches and commit subjects (D.3 table), allocation with both command forms (D.4), collision procedure with `<OLD-ID>` and `<NEW-ID>` placeholders (D.5), linking table (E) with placeholder examples.
5. Claiming and task status: when to create a task (J.1), format lines for Completion and Notes (J.2), status transitions and edit rights (J.3), claim recipe (J.4, including "yours", takeover and the cannot-push rule), protected default branch (J.4a), no remote (J.4b), release, stale claims and drop (J.5), done (J.6), board views (J.7).
6. Blockers and questions: K.1 to K.4.
7. Handoffs: H.1 to H.6.
8. ADRs: I.1, I.2, I.4, I.5, I.6.
9. Knowledge docs and STALE banners: knowledge creation threshold (G.3), where gotchas go, split rule, STALE banner (L.5) shown in a code fence.
10. State files: CURRENT and NEXT rules (K.5, K.6).
11. Concurrency and conflicts: model (M.1), coordination commits with the temporary-worktree recipe in sh and PowerShell (M.2), protected default branch and no-remote variants, lost-update guard (M.5), conflict cookbook (M.6).
12. Formatting and front matter: M.4, the MKB YAML subset (C.2), the vocabularies (C.4), and one compact table per type listing its keys in template order with the required and conditional rules of C.5.
13. Gardening: procedure and cadence (L.6), the staleness table with its check codes (L.4), `mkb-check.sh` usage lines (L.7).
14. Profile differences: table in L.9 of this contract.
15. Path overrides and adopted directories: the INDEX rows that change with an override (F.2), an adopted ADR directory (N.2 row: native format, ID form, which statuses bind, `--adr-dir`), an external issue tracker (J.9).
16. Project-specific rules: the single line `None.` in the template.

The skeletons of `project/ARCHITECTURE.md` and `project/CONVENTIONS.md` are not in RULES.md: they ship as `docs/mkb/templates/ARCHITECTURE.md` and `docs/mkb/templates/CONVENTIONS.md` (F.6, F.7), so a minimal project creates them by copying a template like any record.

### F.4 `docs/mkb/project/OVERVIEW.md`

```markdown
# Overview: <Project name>

## Purpose
<!-- guide: what the system does and why it exists, 2-5 lines; point to `README.md` sections instead of copying them. -->

## Users and scope
<!-- guide: who uses it; what is in scope; what is out of scope (non-goals). -->

## Stack
<!-- guide: languages, frameworks, runtime, data stores, key libraries; one line each. -->

## Commands
<!-- guide: build, test, run, lint; or "See `README.md` (Development)." when README already has them. -->

## Glossary
<!-- guide: optional; domain terms an agent could misread, one line each: "- **Term**: meaning." -->
```

### F.5 `docs/mkb/project/CONSTRAINTS.md`

```markdown
# Constraints: <Project name>

Normative: code, tasks and ADRs MUST respect every rule below.
Only humans change this file; an agent adds a rule only when a human states it in the session, and cites that human as the source.
Entry format: `- <rule>. Source: <person or document>, YYYY-MM-DD.`
Delete sections without entries; if none remain, write `None recorded as of YYYY-MM-DD.`

## Regulatory and legal
<!-- guide: laws, standards, certifications, audit duties. -->

## Customer and contract
<!-- guide: commitments to customers or partners: deadlines, formats, service levels. -->

## Platform and environment
<!-- guide: fixed runtimes, operating systems, hardware, network limits. -->

## Security and data
<!-- guide: secret handling, personal data, retention, access rules. -->

## Performance and capacity
<!-- guide: hard limits on latency, throughput, size or cost. -->
```

### F.6 `docs/mkb/project/ARCHITECTURE.md` (also shipped byte-identical as `docs/mkb/templates/ARCHITECTURE.md`)

```markdown
---
type: architecture
verified: YYYY-MM-DD
---
# Architecture: <Project name>

## System context
<!-- guide: who and what is outside the system (users, external systems by INT- ID), 3-8 lines. -->

## Components
<!-- guide: one row per component; internals belong in the knowledge doc named in column Doc; a component needing more than 5 lines of text here gets a knowledge doc instead. -->
| Component | Responsibility | Code | Doc |
|---|---|---|---|
| <name> | <one line> | `<path>/` | <ID or -> |

## Data flow
<!-- guide: the 1-3 main flows as numbered steps naming components. -->

## Deployment
<!-- guide: where each component runs, how it is released, environment names. -->

## Cross-cutting concerns
<!-- guide: optional; configuration, logging, security, error handling: one line each with a pointer. -->
```

### F.7 `docs/mkb/project/CONVENTIONS.md` (also shipped byte-identical as `docs/mkb/templates/CONVENTIONS.md`)

```markdown
# Conventions: <Project name>

Normative project rules that tooling and `CONTRIBUTING.md` do not already enforce or state; link to them instead of copying.
Changes need a human's approval in review.

## Code
<!-- guide: naming, structure, error handling and logging rules that no linter enforces. -->

## Tests
<!-- guide: where tests live, how to run subsets, markers, fixtures, what must be tested. -->

## Branches and commits
<!-- guide: default branch name; branch form `<actor>/task-nnn-<slug>`; commit subject `TASK-NNN: <summary>`; project additions. -->

## Reviews and merging
<!-- guide: who reviews, merge method (merge, squash or rebase), required checks. -->
```

### F.8 `docs/mkb/state/CURRENT.md`

```markdown
# Current state: <Project name>

The condition of the default branch and its deployments, one dated bullet per fact: `- YYYY-MM-DD <handle>: <fact> (<IDs>)`.
Edit only the bullets your work changes; re-date a bullet when you re-verify it; delete it when it is no longer true.
Branch progress belongs in handoffs and finished work in task Completion sections, never here.

## Health
<!-- guide: exceptions and deployments only: the default branch is red, known broken functionality, deployed version per environment; never "CI green", which the forge already shows. -->

## Focus
<!-- guide: 1-3 bullets written by the lead: the current goal or milestone and its date. -->

## Warnings
<!-- guide: what every session must know right now: freezes, manual workarounds, "do not touch X until Y". -->
```

### F.9 `docs/mkb/state/NEXT.md`

```markdown
# Next: <Project name>

The ordered pickup queue, highest first, kept by the lead named in [INDEX.md](../INDEX.md); agents edit it only when a human asks in the session.
Take the first ID in this list whose task on the default branch is `todo` with `owner: none` or you; skip the others.
Entry format: `- <ID>: <why now, at most 10 words>`. At most 10 entries.

- <ID>: <why now>
```

### F.10 `docs/mkb/templates/TASK.md`

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

### F.11 `docs/mkb/templates/ADR.md`

```markdown
---
id: ADR-NNN
type: adr
status: proposed
date: YYYY-MM-DD
related: [<ID>]
---
# ADR-NNN: <the decision as a short statement>

## Context
<!-- guide: facts and forces that led here, 3-10 lines; cite constraints by file and section, sources by link. -->

## Problem
<!-- guide: the question being decided, 1-2 sentences. -->

## Decision
<!-- guide: what we will do, specific enough to check code against. -->

## Alternatives considered
<!-- guide: at least one, "- <option>: why not" per line. -->

## Consequences
<!-- guide: what becomes easier, harder or riskier; what must now stay true; follow-up TASK IDs. -->
```

Keys added later, template order preferred (not checked): `deciders` after `date`; `supersedes` after `deciders`; `superseded_by` after `supersedes`; `formerly` last.

### F.12 `docs/mkb/templates/QUESTION.md`

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

### F.13 `docs/mkb/templates/HANDOFF.md`

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
<!-- guide: optional; approaches tried and rejected, one line each with the reason. -->

## Read first
<!-- guide: IDs and paths the next session reads before anything else; pointers only, no copies. -->
```

### F.14 `docs/mkb/templates/MODULE.md`

```markdown
---
id: MODULE-<NAME>
type: module
summary: <one line of at most 120 characters with the words people will search for>
code: [<path>/]
verified: YYYY-MM-DD
related: [<ID>]
---
# MODULE-<NAME>: <short title>

## Purpose
<!-- guide: 2-4 lines: what this module is responsible for and what it is not. -->

## Interfaces
<!-- guide: entry points other code uses, one line each: `<path>` (`<symbol>`): what it does. -->

## How it works
<!-- guide: only what the code does not make obvious: flows, state, formats, concurrency. -->

## Invariants
<!-- guide: optional; rules the code cannot enforce by itself, one line each. -->

## Gotchas
<!-- guide: optional; "- <symptom with exact error text> -> <cause> -> <fix>", one line each. -->

## Testing
<!-- guide: optional; how to test this module: fixtures, simulators, slow or hardware-bound tests. -->
```

### F.15 `docs/mkb/templates/SERVICE.md`

```markdown
---
id: SERVICE-<NAME>
type: service
summary: <one line of at most 120 characters with the words people will search for>
code: [<path>/]
verified: YYYY-MM-DD
related: [<ID>]
---
# SERVICE-<NAME>: <short title>

## Purpose
<!-- guide: 2-4 lines: what this runnable unit does and who calls it. -->

## Run and deploy
<!-- guide: how to run it locally, where it is deployed, how a release happens. -->

## Configuration
<!-- guide: configuration key names and where their values live; never values of secrets. -->

## Dependencies
<!-- guide: optional; what it needs at runtime (stores, queues, other services), by ID where one exists. -->

## Operations
<!-- guide: optional; health check, logs location, restart and recovery steps. -->

## Gotchas
<!-- guide: optional; "- <symptom with exact error text> -> <cause> -> <fix>", one line each. -->
```

### F.16 `docs/mkb/templates/DB.md`

```markdown
---
id: DB-<NAME>
type: database
summary: <one line of at most 120 characters with the words people will search for>
code: [<path>/]
verified: YYYY-MM-DD
related: [<ID>]
---
# DB-<NAME>: <short title>

## Purpose
<!-- guide: which data this store or schema area holds, which engine, who writes and reads it. -->

## Entities
<!-- guide: meaning and relationships of the main tables or collections; not column lists that migrations already show. -->

## Invariants
<!-- guide: optional; data rules the schema cannot enforce, one line each. -->

## Migrations
<!-- guide: how migrations are written, named and applied; rules for backfills and rollbacks. -->

## Gotchas
<!-- guide: optional; "- <symptom with exact error text> -> <cause> -> <fix>", one line each. -->
```

### F.17 `docs/mkb/templates/INT.md`

```markdown
---
id: INT-<NAME>
type: integration
summary: <one line of at most 120 characters with the words people will search for>
code: [<path>/]
verified: YYYY-MM-DD
related: [<ID>]
---
# INT-<NAME>: <short title>

## Purpose
<!-- guide: which external system, device or partner; who owns it on their side; link to the vendor documentation. -->

## Contract
<!-- guide: protocol, message or file formats, endpoints, versions, timing. -->

## Authentication
<!-- guide: the method and where the credential lives (vault path, environment variable name); never a value; "None." if none. -->

## Limits and failure modes
<!-- guide: optional; rate limits, timeouts, known outages, retries expected by the other side. -->

## Test environment
<!-- guide: optional; sandbox, simulator or fixture files and how to use them. -->

## Gotchas
<!-- guide: optional; "- <symptom with exact error text> -> <cause> -> <fix>", one line each. -->
```

`code` is deleted from INT docs while no code talks to the system yet (C.5); add it when code appears.

### F.18 `docs/mkb/templates/TS.md`

~~~~markdown
---
id: TS-<NAME>
type: troubleshooting
summary: <one line of at most 120 characters with the words people will search for>
code: [<path>/]
verified: YYYY-MM-DD
related: [<ID>]
---
# TS-<NAME>: <symptom in a few words>

## Symptom
<!-- guide: where it shows up (command, service, CI job), then the exact error text below so grep finds it. -->

```text
<exact error text>
```

## Cause
<!-- guide: the root cause in 1-5 lines. -->

## Fix
<!-- guide: numbered steps that resolve it. -->

## Prevention
<!-- guide: optional; what stops it from recurring (check, test, config), with IDs. -->
~~~~

`code` is deleted from TS docs about environment or toolchain problems.

### F.19 Handoff, question and task entries in shared files

Not used in v1.0: `handoff/CURRENT.md`, `handoff/HISTORY.md`, `questions/OPEN.md` entries, `tasks/*.md` status lists, `agents/CODEX.md`, `agents/CLAUDE.md`.
Every record is its own file (F.10 to F.13).

### F.20 Root `AGENTS.md` (copy-ready form `agent-instructions/AGENTS.tmpl.md`)

~~~~markdown
# Agent instructions

<!-- Project-specific agent notes (build, test, style) go above the MKB block. Keep this file small: some tools cap instruction size. -->

<the MKB block from section P.1, verbatim, including its BEGIN and END marker lines>
~~~~

### F.21 Root `CLAUDE.md` (copy-ready form `agent-instructions/CLAUDE.tmpl.md`)

```markdown
@AGENTS.md

Tools that do not expand the import above: read `AGENTS.md` at the repository root and follow its section Project memory (MKB).

<!-- Cursor, and possibly GitHub Copilot, also read this file: notes below must be tool-neutral, or go in AGENTS.md. Do not copy AGENTS.md content here. -->
```

The first line is exactly `@AGENTS.md` as plain text; it MUST NOT be inside backticks or a code block (Claude Code ignores imports there).

### F.22 `.gitattributes` lines (shipped as `templates/gitattributes-mkb.txt`; appended to the adopter's `.gitattributes` only where absent, N.6)

```text
# MKB: LF line endings for project memory and agent instruction files
docs/mkb/** text eol=lf
AGENTS.md text eol=lf
CLAUDE.md text eol=lf
```

### F.23 Stub replacing a migrated monolithic `Handoff.md`

```markdown
# Handoff.md has moved

This file was replaced by the Markdown Knowledge Base on YYYY-MM-DD; start at `docs/mkb/INDEX.md`.
Do not add content here; this stub is deleted at the first gardening after YYYY-MM-DD (30 days later).
```

### F.24 Tool pointer files (optional; see P.3)

`agent-instructions/cursor/mkb.mdc`:

```markdown
---
description: MKB project memory protocol
alwaysApply: true
---
Follow the "Project memory (MKB)" section of AGENTS.md at the repository root.
```

`agent-instructions/gemini/settings.json`:

```json
{
  "context": {
    "fileName": ["AGENTS.md", "GEMINI.md"]
  }
}
```

`agent-instructions/aider/.aider.conf.yml`:

```yaml
read: [AGENTS.md, docs/mkb/INDEX.md, docs/mkb/state/CURRENT.md]
```

`agent-instructions/copilot/copilot-instructions.md`:

```markdown
Follow the "Project memory (MKB)" section of AGENTS.md at the repository root.
```

---

## G. Agent workflow, discovery algorithm, update-trigger matrix

Humans follow the same rules; the only difference is that a human writes a handoff only when someone else will continue the work.

### G.1 Before modifying code

1. Update and read:
   - `git fetch`, then rebase your branch onto `origin/main` (on `main` itself: `git pull --rebase`), so that you see the claims, answers and docs that landed since your branch was cut;
   - `docs/mkb/INDEX.md` (skip if already read in this session);
   - `docs/mkb/state/CURRENT.md`;
   - `docs/mkb/state/NEXT.md`, only if you must choose a task.
2. Know your work item:
   - the task you were given, else the first ID in `state/NEXT.md` whose task on the default branch is `todo` with `owner: none` or you, else ask the human;
   - no task exists and the work will outlast this session, or will be handed to someone else: create one from `templates/TASK.md` (J.1; a coordination commit, D.4 step 6);
   - work you will finish in this session needs no task (if it ends unfinished after all, T2 creates one).
3. Read the task file. If its Notes say `released; partial work on branch <branch>`, read the handoff on that branch and take over from it (J.4 step 5); otherwise read `handoff/TASK-NNN.md` on the task's branch if it exists. Verify its "Where it stands" against `git log` and `git status` before trusting it.
4. Claim before touching code (J.4), unless the task is already yours (J.4 step 7).
5. Run the discovery algorithm (G.2).
6. If `state/CURRENT.md` has a bullet older than the W5 threshold (14 days in the full profile, 35 in the minimal profile), or `docs/mkb/handoff/` on the default branch holds a file whose task is `done`, `dropped` or missing (W4), add `Gardening due` to your `MKB for humans:` lines (G.7); do not garden unasked, except micro-fixes (L.6).

### G.2 Discovery algorithm

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
  A task that is in-progress, not yours (J.4 step 7), and whose code covers your paths:
  tell the human before you edit those paths.
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
  to your MKB for humans lines (G.7); gardening adds a Routing row to INDEX.
No code owner AND no hit for git grep -i "^summary:.*<word>" -- docs/mkb/knowledge:
  the knowledge is missing, and you will probably write it.
Never read by default: tasks/archive/, templates/, superseded or rejected ADRs, git history.
```

Notes for writers:
- Run discovery after step 1 of G.1 (branch rebased onto `origin/main`), so the working tree holds the current docs and tasks.
- `git grep` searches tracked files; add `--untracked` to include files not yet committed.
- `head -n 16 <file>` in sh; `Get-Content -TotalCount 16 <file>` in PowerShell.
- Example of the prefix match: the line `docs/mkb/knowledge/services/SERVICE-GATEWAY.md:code: [src/tarelog/gateway/]` keeps SERVICE-GATEWAY for a change to `src/tarelog/gateway/reader.py`.

### G.3 While working

1. Constraints and accepted ADRs bind you. To deviate, write a `proposed` ADR or open a question; never edit an accepted ADR; never decide an ADR's status on your own authority: write `accepted` or `rejected` only to record a decision a named human makes in this session, and list them in `deciders` (I.4).
2. Record a discovery when you make it, not at the end of the session, in its home doc (G.5), linked by bare ID, never copied.
3. Knowledge threshold: write it down only if the code does not make it evident within 5 minutes AND at least one holds: it cost more than 30 minutes to learn; it lives outside the repository (device, vendor, production, customer); it spans several files; it is an invariant the code cannot enforce.
4. Where to write it, in order of preference: a code comment if it concerns one place in the code; a section of an existing doc (search first); a new doc last.
5. A gotcha about one module, service, store or integration goes in that doc's `## Gotchas`; a cross-cutting or environment problem goes in a `TS-` doc. Quote exact error strings so grep finds them.
6. A decision meeting I.1 becomes a `proposed` ADR on your branch.
7. Work found outside your task's scope becomes a new task (`todo`, `owner: none`), pushed to the default branch at once (D.4 step 6); do not widen your task.
8. Commit subjects start with the task ID; MKB changes go in the same commit or PR as the code they describe.
9. Re-read an MKB file from disk right before editing it and patch only the lines you mean to change (M.5).
10. Never put secrets, credential values, personal data of customers or patients, logs longer than 5 lines, stack traces, diffs or chat transcripts in the MKB.

### G.4 Lite path

The lite path applies only when ALL hold:
- the change touches at most 3 files;
- it adds or changes no interface, configuration key, dependency, schema or external contract;
- it will be finished in this session;
- no task needs claiming.

Steps (the agent block P.1 item 1 carries them inline):
1. Read the `## Warnings` section of `state/CURRENT.md`.
2. For the files you touch and the errors you chase, run the code-owner match, the path search and the error-text search of G.2; read any hit that is CONSTRAINTS.md, an accepted ADR or a knowledge doc. Another actor's `in-progress` task whose `code` covers your files: tell the human before editing.
3. After the change, fix any doc your change makes wrong (T11, T19); otherwise update nothing (T22).
4. If anything surprises you, or the session ends with the work unfinished, switch to the full workflow (T2 creates the task).

### G.5 After working: update-trigger matrix

Walk every row; update only the rows that fire.
"Coordination" means the change is pushed to the default branch immediately (M.2).

| # | If your work... | Update |
|---|---|---|
| T1 | started a task | claim: `status: in-progress`, `owner`, `branch` (coordination) |
| T2 | stopped with the work unfinished | no task yet: first create it (J.1) already claimed, `status: in-progress`, `owner: <you>`, `branch: <current branch>` (coordination); then overwrite `handoff/TASK-NNN.md` on the task branch and commit and push everything including it; `git status` clean |
| T3 | finished a task | tick criteria; `status: done`; `closed`; fill `## Completion`; move each Dead ends or Watch out line of the handoff that stays true after the merge into the owning knowledge doc's `## Gotchas` (G.3 threshold) or a Notes line of the task; delete `handoff/TASK-NNN.md`; all in the delivering PR (trunk-based: J.6) |
| T4 | will not continue a task that someone else may continue | release: `status: todo`, `owner: none`, remove `branch`, Notes line naming the branch with partial work; keep the handoff on that branch (coordination) |
| T5 | showed a task should not be done | propose dropping it to a human; on their decision: `status: dropped`, `closed`, reason and decider in `## Completion` |
| T6 | needs an answer only a person can give | new `questions/Q-NNN.md` with `owner` = that person; task `status: blocked`, `blocked_by: [Q-NNN]`, Notes line (coordination) |
| T7 | is blocked by other work or an external party | existing or new task owned by whoever must act; `blocked_by: [TASK-NNN]` (coordination) |
| T8 | got an answer or saw a blocker resolved | promote the answer (K.3), delete the question; remove `blocked_by`; status back to `in-progress` if `branch` is set, otherwise `todo` (owner unchanged) (coordination; a PR when the promotion creates an ADR, K.3) |
| T9 | chose between real alternatives with lasting effect (I.1) | new ADR, `status: proposed`; a human listed in `deciders` accepts or rejects it before merge (I.4); list it under `ADR decisions needed` (G.7) |
| T10 | reverses or replaces an accepted ADR | new ADR with `supersedes`; old ADR gets `status: superseded` and `superseded_by`; same PR |
| T11 | changed the behavior, interface or invariants of a module, service, schema or integration | the knowledge doc whose `code` covers the change, in the same PR: check it against your change, fix what is wrong, bump `verified` |
| T12 | needed to reverse-engineer something undocumented, or met a gotcha (G.3 threshold) | extend the owning knowledge doc, or create one from its template; cross-cutting problems: a `TS-` doc |
| T13 | added, removed or re-bounded a component | the Components table in `project/ARCHITECTURE.md`; a knowledge doc if the component is not trivial |
| T14 | deleted a component, integration or store | delete its knowledge doc and its ARCHITECTURE row in the same PR; repoint references |
| T15 | changed build, run or test commands, the stack or dependencies | `project/OVERVIEW.md` (Stack, Commands), or `README.md` if that is where commands live |
| T16 | learned a non-negotiable rule | a human states it: `project/CONSTRAINTS.md` with source and date; otherwise a question to the lead |
| T17 | introduced a team-wide convention | `project/CONVENTIONS.md` through a PR a human approves |
| T18 | changed a project-level fact of the default branch (build red or green, deployed version, known breakage, freeze) | a dated bullet in `state/CURRENT.md`, in the delivering PR or as a coordination commit |
| T19 | found a doc that contradicts the code | fix it now if small and in scope; otherwise a `> STALE` banner plus a task (L.5) |
| T20 | discovered work outside your scope | new task, `todo`, `owner: none`, pushed to the default branch at once (D.4 step 6) |
| T21 | changed what should happen next | `NEXT suggestion: <ID> <why>` in your `MKB for humans:` lines (G.7); only the lead edits `state/NEXT.md` |
| T22 | changed nothing durable (local refactor, bug fix with no new knowledge, rename, formatting) | nothing; the commit message is the record. Exception: you touched a path in a knowledge doc's `code` and the doc is still right: bump its `verified` in the same PR |

### G.6 Resolving contradictions

| An agent finds that... | It does |
|---|---|
| a descriptive doc (knowledge, ARCHITECTURE, OVERVIEW, state, handoff) contradicts the code, and the fix is small and in scope | fix the doc in the same commit; mention it in the commit message; bump `verified` for what you checked (C.3) |
| the same, but the fix is large or out of scope | add a `> STALE` banner (L.5) and a task; do not rely on the stale text |
| the code violates CONSTRAINTS.md or an accepted ADR | never edit the constraint or ADR to match the code; fix the code only if that is inside your task, citing the ID in a comment; otherwise open a question to the lead and mention it in your handoff |
| the task's acceptance criteria contradict an accepted ADR or a constraint | stop that part; open a question, or draft a `proposed` superseding ADR, and wait for a human |
| a human in the session tells you to break an accepted ADR or a constraint | point out the conflict; if they confirm, write the superseding ADR (`deciders` = that human) or have them edit CONSTRAINTS.md, before or together with the code |
| two accepted ADRs conflict without a `supersedes` link | follow the newer one and open a question to the lead |
| a handoff or state bullet contradicts the code | the code wins; fix or delete the item |

### G.7 Reporting to humans: the `MKB for humans:` lines

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

- `Questions`: questions you created (K.2). `ADR decisions needed`: `proposed` ADRs in this PR (I.4). `NEXT suggestion`: T21. `Routing gap`: G.2. `Gardening due`: G.1 step 6.
- `New task` and `Question for`: only agents that cannot push to the default branch (D.4 step 7); the dispatching human creates those records.
- Humans read the block at review; the lead acts on NEXT suggestions and routing gaps.

---

## H. Handoff rules

H.1 Location: `docs/mkb/handoff/<work item ID>.md`, committed on the task branch (in trunk-based minimal projects, on the default branch).
It exists only while the task is unfinished.

H.2 Format: skeleton F.13.
Required sections: Where it stands, Next steps, Read first.
Optional sections: Watch out, Dead ends (delete the heading when empty).
Hard limit: 30 lines including the H1.
Line numbers in code references are allowed here only.

H.3 What goes in: the state of the branch (pushed, CI result, what is half-done), the exact next steps, traps that apply only to this in-flight work, approaches tried and rejected, IDs and paths to read first.

H.4 What never goes in:
- durable knowledge (it goes to its home doc now; the handoff points to its ID);
- decisions (ADR), project state (state/CURRENT.md), task definition or completion notes (task file);
- a narrative of the session, praise, apologies;
- code blocks longer than 5 lines, logs, stack traces, diffs, file lists that git already shows;
- secrets or credential values;
- anything about other tasks (cross-task warnings go to `state/CURRENT.md`, section Warnings).

H.5 Writing and rotation:
1. The owner overwrites it at the end of every session that leaves the task unfinished, and at checkpoints before long or risky operations, then commits and pushes it together with all work (a WIP commit on your own branch is fine); `git status` is clean afterwards. A handoff that is not pushed does not exist for the next session.
2. It is always overwritten whole by the owner; the previous version stays in git.
3. It is deleted in the PR that sets the task `done` or `dropped`, after its lines that stay true have moved (T3).
4. On release (T4) it stays on the released branch. The next owner creates their branch from that branch's tip (J.4 step 5), and the handoff on the new branch is theirs to verify and overwrite.
5. If a partial PR merges while the task continues, the handoff may reach the default branch; the next session continues on a new branch and updates `branch:`.
6. Gardening deletes any handoff on the default branch whose task is `done` or `dropped`, or that has no task.
7. Only the task owner writes it; nobody edits another actor's handoff (after a takeover, the copy on your own branch is yours).

H.6 Reading: a handoff is the lowest authority.
Verify it against the branch (`git log`, `git status`, tests) before acting.
From another checkout: `git show origin/<branch>:docs/mkb/handoff/TASK-NNN.md`.

H.7 Parallel safety: different tasks write different files on different branches; git refuses to check out one branch in two worktrees; one task has one owner.
The remaining case, two actors on one branch, is a rule violation (M.1).

H.8 Why no `handoff/CURRENT.md` and no `HISTORY.md`: one shared CURRENT file is overwritten by every parallel session; HISTORY duplicates `git log` and task Completion sections.
History queries: `git log --format="%cs %an %s" -- docs/mkb/tasks`, and `git log -p origin/<branch> -- docs/mkb/handoff/TASK-NNN.md` while the task branch exists.
Squash merges and automatic branch deletion drop a handoff's history by design; that is acceptable because T3 moves every Dead ends or Watch out line that stays true into a knowledge doc or the task's Notes before the handoff is deleted.

---

## I. ADR rules

I.1 Write an ADR when BOTH hold:
1. at least two viable alternatives were weighed, and
2. at least one of these is true:
   - the choice is expensive to reverse (data format, storage, public API, protocol, persisted schema);
   - it crosses a module or service boundary, or changes an external contract;
   - it adds or removes a significant dependency, service or piece of infrastructure;
   - it knowingly accepts a trade-off or risk (security, compliance, performance);
   - it sets a project-wide rule, or deviates from an existing ADR, constraint or convention;
   - a competent newcomer would plausibly "clean it up" back or reopen the debate.

I.2 Do NOT write an ADR for: naming, formatting, local refactors, bug fixes, a library choice internal to one module that is easy to change, anything already dictated by CONSTRAINTS.md or an accepted ADR (cite that ID instead), anything whose rationale fits in a code comment.
If unsure, record the reasoning in the task's Completion section; promote it to an ADR if someone reopens the debate.

I.3 File and format: `decisions/ADR-NNN.md`, skeleton F.11, at most 100 lines.
The H1 states the decision (`# ADR-003: Deliver daily reports as CSV instead of PDF`).
`date` is the decision date (while `proposed`, the date proposed).

I.4 Status lifecycle and who decides:
- `proposed` -> `accepted` or `rejected`: only a human, normally during PR review; the human adds themselves to `deciders` and sets `date`.
- `accepted` -> `superseded` (by a new ADR) or `deprecated` (no longer applies, no replacement).
- Agents create ADRs only as `proposed` and never decide an ADR's status on their own authority. An agent MAY write `accepted`, `rejected` or `deprecated` only to record a decision that a named human stated in the current session, and then lists that human in `deciders`.
- An ADR reaches the default branch only as `accepted` or `rejected`: a PR containing a `proposed` ADR MUST NOT be merged until a human decides it. In trunk-based work the human decides in the session before the commit.
- A PR that adds an ADR as `accepted` or `rejected`, or changes an ADR's status, MUST NOT merge unless a human listed in that ADR's `deciders` approves it in review or merges it personally. In trunk-based work an agent records a decision only while that human is in the session.
- `proposed` ADRs waiting for a decision are listed under `ADR decisions needed` in the PR's `MKB for humans:` lines (G.7).
- Rejected ADRs are kept: they record "we considered this".

I.5 Immutability: once accepted, only `status`, `superseded_by` and typo or broken-link fixes may change.
Anything that changes substance needs a new ADR.

I.6 Superseding (one PR):
1. Write the new ADR with `supersedes: [ADR-old]`; its Context says what changed; it replaces the whole old decision, restating any part that survives.
2. On the old ADR set `status: superseded` and `superseded_by: ADR-new`; change nothing else.
3. `git grep -n -w "ADR-old" -- docs/mkb` and repoint knowledge docs, ARCHITECTURE and CONVENTIONS that rely on it.
4. Create tasks for code that must change; code comments citing the old ID are updated when that code is next touched.

Deprecating: only a human sets `status: deprecated`, and nothing else in the ADR changes; the reason goes in the commit message and in the task that removed the component.

I.7 ADRs and code: code that embodies a non-obvious decision SHOULD cite the ADR ID in a comment.

I.8 Backfilled ADRs (migration): `status: accepted`, `date` = the original decision date if the source states it, else the adoption date; `deciders` = the human who confirms during adoption that the decision still holds; the first line of Context is `Recorded retroactively from <source> on YYYY-MM-DD.`

---

## J. Task rules and claiming

J.1 When to create a task:
- REQUIRED when the work will not be finished within the current session (at the latest when a session ends unfinished, T2), when it will be handed to or dispatched to another actor, or when it is discovered and deferred.
- NOT needed for work you finish in the current session (committed, and a PR opened where the project uses PRs); the commit or PR is the record.
- Size: one mergeable unit of roughly 1 to 3 sessions; larger work is split into several tasks; no subtasks, no epics.
- Every new task, including follow-ups found during work, is created on the default branch at once as a coordination commit `TASK-NNN: add` (D.4 step 6), so its number is visible before anything refers to it. Agents that cannot push to the default branch write `New task: <title>` in their `MKB for humans:` lines instead (G.7).

J.2 Format: skeleton F.10, at most 60 lines.
Brief-required elements map as follows: unique ID `id`; status `status`; priority `priority`; owner `owner`; description `## Goal`; acceptance criteria `## Acceptance criteria`; related files and components `code` and `related`; related decisions `related`; completion notes `## Completion`.
Completion first line: `- YYYY-MM-DD <handle>: done in PR #N` (trunk-based: `done in <short SHA>`, naming the last code commit; the done edit itself is the follow-up commit of J.6), then `- Shipped: ...`, `- Docs: <IDs created or updated>`, `- Follow-ups: <IDs or none>`, `- Deviations: <from acceptance criteria, or none>`.
Notes lines: `- YYYY-MM-DD <handle>: <text>`, append-only, anyone may add one to any task.

J.3 Status transitions:

| From | To | Who | Where |
|---|---|---|---|
| (new) | `todo` | anyone | coordination commit `TASK-NNN: add` (D.4 step 6) |
| `todo` | `in-progress` | the claimer (or a human for a dispatched agent) | coordination (claim) |
| `todo` | `blocked` | anyone, for an unowned task; the lead | coordination |
| `in-progress` | `blocked` | the owner | coordination |
| `blocked` | `in-progress` if `branch` is set, otherwise `todo` (owner unchanged) | the owner, or whoever resolved the blocker (K.3) | coordination, or the promotion PR (K.3 step 3) |
| `in-progress` | `todo` | the owner (release), or the gardener for a stale agent claim | coordination |
| `in-progress` | `done` | the owner | the delivering PR |
| any open status | `dropped` | the owner or lead, after a human decision | PR or coordination |
| `done`, `dropped` | - | terminal; reopening means a new task that cites the old ID | - |

Edit rights: only the owner edits a claimed task; anyone may append a Notes line; anyone may edit a task whose owner is `none`; the lead may edit any task; whoever promotes an answer (K.3) may edit the Goal and Acceptance criteria of the tasks the question blocks, marking each changed line `(resolves Q-NNN)`, and may remove `blocked_by` and set `status` as in T8.

J.4 Claiming protocol (direct push to the default branch allowed):
1. `git fetch origin`.
2. `git show origin/main:docs/mkb/tasks/TASK-NNN.md | head -n 16` MUST show `status: todo` with `owner: none` or your handle. Never judge by your local copy.
3. Make the claim as a coordination commit in a temporary worktree of `origin/main` (M.2 recipe), never on a work branch: set `status: in-progress`, `owner: <you>`, `branch: <you>/task-nnn-<slug>`, and `code` with the paths you expect to touch (SHOULD, so that others' overlap checks see them, G.2); commit `TASK-NNN: claim`; `git push origin HEAD:main`.
4. Push rejected: fetch, rebase the temporary worktree onto `origin/main`, push again. A conflict in `TASK-NNN.md` means someone else claimed it: `git rebase --abort`, remove the temporary worktree, pick another task. If after the rebase `git rev-list --count origin/main..HEAD` prints `0`, your claim commit was dropped because an identical claim (same handle, another session of your tool) is already there: the task is taken; pick another task.
5. Create your branch `<you>/task-nnn-<slug>` from the updated `origin/main` (in its own worktree when agents work in parallel locally) and push it at once. Takeover: if the task's Notes contain `released; partial work on branch <old-branch>`, read `git show origin/<old-branch>:docs/mkb/handoff/TASK-NNN.md`, create your branch from that tip instead (`git switch -c <you>/task-nnn-<slug> origin/<old-branch>`), rebase it onto `origin/main`, push it, and verify the handoff against it; the handoff is now yours to overwrite; never push to the old branch.
6. Dispatched agents that cannot push to the default branch (for example Codex cloud and the Copilot coding agent): the dispatching human makes the claim commit `TASK-NNN: claim for <handle>` before dispatch, with `branch: pending` if the tool names the branch later; the agent or the human replaces `pending` with the real name in the PR.
7. When a task is yours: `owner` is your handle, AND `branch` is the branch you were told to resume or are on, AND `git worktree list` does not show that branch checked out in another worktree. `branch: pending` is yours only if you are the dispatched session. A task with your handle that fails this test belongs to another session of your tool: pick another task or ask the human.
8. Minimal profile, one actor working on the default branch (L.9): the claim is the first commit of your work and SHOULD be pushed before you write code.
9. Cannot fetch or push (sandbox, network or permissions, P.2): stop before coding and ask the human to push the claim; never code on an unpushed claim.

J.4a Protected default branch (no direct push):
1. The task must be `todo` on `origin/main`, and `git branch -r` must show no branch containing `task-nnn` other than branches named in the task's release Notes.
2. Create `<you>/task-nnn-<slug>`, commit the claim edit on it, push it immediately; the pushed branch name is the claim.
3. Fetch again; if another `task-nnn` branch now exists, the branch whose claim commit is older keeps the task; the other actor stops; ties go to the lead.
4. Dispatched agents whose tool names its own branch: before dispatch, the dispatching human pushes a claim branch `<agent handle>/task-nnn-<slug>` that holds only the claim commit (`TASK-NNN: claim for <handle>`); the tool's real branch is recorded in `branch:` inside the agent's PR; the human deletes the claim branch when that PR merges or the task is released.
5. The front-matter claim reaches the default branch with the PR. Other coordination changes, new tasks and questions included, use one-file PRs labelled `mkb-coord`, merged by the first human who sees them; an ID collision between two open `mkb-coord` PRs is fixed by renumbering the later one (D.5), which nothing refers to yet.

J.4b No remote: "origin/main" means local `main`; skip fetch and push; branch checks use `git branch`; coordination commits follow M.2 (no-remote variant).

J.5 Release, abandon and drop:
- Release (T4): `status: todo`, `owner: none`, remove `branch`, Notes line `- YYYY-MM-DD <handle>: released; partial work on branch <branch>, see its handoff`.
- Stale claim: `in-progress` with no commit on its branch for 7 days. Agent owner: the gardener or any human may release it. Human owner: ask them; after 14 days the lead decides.
- Stale dispatch: `in-progress` with `branch: pending` and no change to the task file on the default branch for 7 days (W6): the dispatched agent produced no PR; the dispatching human releases it.
- Drop: only after a human decision; Completion line `- YYYY-MM-DD <handle>: dropped: <reason>, decided by <human handle>`.

J.6 Done: set in the delivering PR, so the default branch says `done` only after the work merges.
Trunk-based work: the done edit is a separate follow-up commit `TASK-NNN: done` right after the last code commit, whose short SHA the Completion line names (a commit cannot contain its own hash).
There is no `review` status: an open PR signals review.

J.7 Board views (queries, never committed files; they read `origin/main`, or `main` without a remote):

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

J.8 Archival: gardening runs `git mv docs/mkb/tasks/TASK-NNN.md docs/mkb/tasks/archive/` for every task `done` or `dropped` with `closed` more than 30 days ago, in a commit `mkb: archive closed tasks`.
Archived tasks are never edited or deleted.

J.9 External issue tracker: if the team's tasks already live in GitHub Issues, Jira or similar, that tracker is authoritative: `tasks/` is not used; work item IDs are the tracker keys (`GH-123`); handoffs are `handoff/GH-123.md`; claims are the tracker's assignee; `state/NEXT.md` lists tracker keys; INDEX gets a path override row `| tasks | <tracker URL> | tracker is authoritative; no tasks/ |`.
Questions, ADRs, knowledge and state stay in the MKB.

---

## K. Questions, blockers and state files

K.1 When to ask: only when an answer from a specific person or external party is needed and the decision is outside your authority.
If the decision is yours, make it (and write an ADR if I.1 applies).

K.2 Creating a question: file from F.12, at most 40 lines; `owner` = the human who must answer (for an external party, the human who will get the answer); created at allocation as a coordination commit `Q-NNN: ask <owner>` (D.4 step 6) so the owner sees it on the default branch.
If it blocks a task, the same commit sets that task `blocked` with `blocked_by: [Q-NNN]` and adds a Notes line.
A push notifies nobody: the asker also lists the question under `Questions` in its `MKB for humans:` lines (G.7).
An agent that cannot push to the default branch writes `Question for <handle>: <question>` there instead, and the dispatching human creates the question file.

K.3 Resolution flow:
1. The owner (or an agent relaying an answer given in chat or a PR comment, quoting it verbatim with attribution `YYYY-MM-DD <handle> (via chat): ...`) writes the answer under `## Answer` and sets `status: answered`, as a coordination commit `Q-NNN: answer`.
2. The next session that touches the question, or the answerer, promotes the answer to its permanent home and writes `(resolves Q-NNN)` there:

| The answer... | Goes to |
|---|---|
| decides between alternatives with lasting effect | a new ADR (its Context cites Q-NNN) |
| is a fact about an external system | an `INT-` doc |
| is a fact about the code or domain | a knowledge doc, or project/OVERVIEW.md Glossary |
| is an external non-negotiable rule | project/CONSTRAINTS.md (a human writes it or states it in the session) |
| scopes or changes a task | that task's Goal or Acceptance criteria, each changed line marked `(resolves Q-NNN)` (J.3 lets the promoter edit them) |
| makes the question moot | nowhere; say so in the commit message |

3. In the same commit (`Q-NNN: resolved -> <destination IDs>`): delete the question file; remove the ID from every `blocked_by`; set those tasks back to `in-progress` if `branch` is set, otherwise `todo` (owner unchanged). This is a coordination commit, except when the promotion creates an ADR: then the resolution rides an `<actor>/mkb-<slug>` PR, because the ADR needs a human decision before merge (I.4), and the question and the blocked tasks stay as they are on the default branch until that PR merges.
4. There is no RESOLVED file: `git grep -w Q-NNN` finds where the answer lives; git keeps the question.

K.4 Blockers:
- A blocked task has `status: blocked` and `blocked_by: [IDs]`, each a TASK or Q ID.
- An external impediment (vendor outage, missing access, hardware) becomes a task owned by the human who chases it, for example a task "Get the Beta Haulage SFTP test account reactivated" owned by `marta`.
- The reason lives in the blocking item; the blocked task adds a Notes line.
- Blocker list view: `git grep "^blocked_by:" -- docs/mkb/tasks`.
- A blocker whose items are all resolved is cleared at once (T8); gardening checks for forgotten ones (mkb-check W12).

K.5 `state/CURRENT.md`:
- Describes the default branch and deployments, never branch progress or finished work.
- Sections Health, Focus, Warnings; every bullet `- YYYY-MM-DD <handle>: <fact> (<IDs>)`.
- Health: exceptions and deployments only: the default branch is red, known broken functionality, deployed version per environment. Never "CI green": the forge already shows it, and it would need re-dating forever. Warnings: what every session must know now. Focus: 1 to 3 bullets written by the lead.
- Edited only when a project-level fact changes: in the PR that changes it, or as a coordination commit for facts that change outside a PR (deployments, outages, freezes).
- Re-date a bullet when you re-verify it; delete it when it stops being true; bullets older than the W5 threshold (14 days in the full profile, 35 days in the minimal profile, one gardening interval plus slack) are re-verified or deleted at gardening.
- Micro-gardening: if you know a bullet is false, fix it in the commit where you notice it.

K.6 `state/NEXT.md`:
- Ordered list of at most 10 entries `- <ID>: <why now, at most 10 words>`, highest first, `-` bullets (not numbers, so reordering does not renumber).
- Written only by the lead, or by an agent when a human asks in the session.
- Readers take the first ID in `state/NEXT.md` whose task on the default branch is `todo` with `owner: none` or you, and skip the others; the lead prunes finished entries (W13).

---

## L. Lifecycle, archival, staleness, gardening, budgets, mkb-check

### L.1 Lifecycle matrix

| Record | Create | Update | Close | Archive | Delete |
|---|---|---|---|---|---|
| Task | J.1 | owner (J.3) | `done` or `dropped` plus Completion | to `tasks/archive/` 30 days after `closed` | never |
| ADR | I.1 | while `proposed`, freely on its branch; after acceptance only I.5 | `rejected`, `superseded`, `deprecated` | never moves | never |
| Question | K.1 | owner fills Answer | promotion (K.3) | - | at promotion |
| Knowledge doc | G.3 threshold, after searching for an existing doc | trigger matrix; `verified` after a check (C.3) | - | - | when the thing it describes is removed, or when merged into another doc |
| state/CURRENT.md bullet | project-level fact appears | re-date on re-verification | - | - | when no longer true; when unverified past the W5 threshold |
| state/NEXT.md entry | the lead | the lead | - | - | the lead prunes |
| Handoff | session ends with the task unfinished | overwritten by the owner | task done or dropped | - | in the closing PR; leftovers by gardening |
| project/* | adoption or first need | in place | - | - | if absorbed into README or CONTRIBUTING (then an INDEX override) |
| INDEX, RULES, templates, tools | adoption | layout change (INDEX); version upgrade (others) | - | - | never |

There is no `archive/` for anything but tasks.
Obsolete information is deleted and recovered from git when needed (`git log -S "<ID>"`, `git log --all -- '*<ID>.md'`).

### L.2 Knowledge doc maintenance

- Split: a knowledge doc over 150 lines is split into narrower IDs; the original keeps a short map pointing to the new IDs (or is deleted if the split is total).
- Rename: only during gardening, one commit, with `formerly` set and every reference repointed.
- Delete: with its component, in the same PR.
- Never bulk-generate knowledge docs for code nobody is changing; at adoption or upgrade, at most the 3 most-changed components get docs (`git log --format= --name-only | sort | uniq -c | sort -rn | head`).

### L.3 Deleting obsolete information

Delete rather than mark obsolete, except: tasks (archived), ADRs (kept with status), and knowledge that is known wrong but not yet fixed (STALE banner).

### L.4 Staleness signals (every signal is an mkb-check warning; same thresholds in both profiles except W5)

This table documents the checker: gardening runs `mkb-check.sh` and applies the action of each warning it prints; nobody walks the table by hand.

| Check | Signal | Threshold | Action |
|---|---|---|---|
| W5 | `state/CURRENT.md` bullet | older than 14 days (full) or 35 days (minimal) | re-verify and re-date, or delete |
| W6 | `in-progress` task | no commit on its branch for 7 days; with `branch: pending`, task file unchanged on the default branch for 7 days | agent owner: release (J.5); human owner: ask; lead decides after 14 days; pending: the dispatching human releases |
| W14 | `blocked` task | file unchanged for 14 days | the lead re-plans, escalates or drops it |
| W15 | `open` question | `created` more than 14 days ago | remind the owner; the lead escalates |
| W7 | `answered` question | any | promote now (K.3) |
| W12 | `blocked` task | every `blocked_by` item resolved | clear the block (T8) |
| W2 | Knowledge doc | a `code` path changed on a later day than the doc itself | check the doc against that change: fix and bump `verified`, or STALE banner plus task |
| W3 | Knowledge doc | a `code` path no longer exists | rewrite or delete |
| W16 | Knowledge doc or ARCHITECTURE | `verified` older than 180 days | re-verify the whole doc against the code |
| W8 | `> STALE` banner | older than 30 days | fix the doc or delete it |
| W4 | Handoff on the default branch | task `done`, `dropped` or missing | move lasting lines (T3), then delete |
| W9 | Closed task | `closed` more than 30 days ago | archive (J.8) |
| W17 | `low` task | `created` more than 90 days ago | propose dropping it to the lead |
| W13 | `state/NEXT.md` entry | task `done`, `dropped` or missing | tell the lead, who prunes it |
| W1 | Size budget | exceeded | split or trim |

### L.5 STALE banner

Exact form, directly under the H1 (whole doc) or under the affected `##` heading (one section):

```markdown
> STALE YYYY-MM-DD <handle>: <what is wrong>. Tracking TASK-NNN.
```

Text under a banner is not authoritative.
Removing the banner is part of the fix.
Never bump `verified` without actually checking the code.

### L.6 Gardening

- Cadence: full profile weekly; minimal profile monthly; also when a session reports `Gardening due` or a routing gap (G.7).
- Who: any human or agent asked by a human; not a task (it fits in one sitting).
- Where: branch `<actor>/mkb-garden-YYYY-MM-DD`, merged the same day (its edits are broad but tiny).
- Procedure:
  1. Run `sh docs/mkb/tools/mkb-check.sh` (with git, so that every check runs) and fix every error.
  2. Resolve every warning with the action in L.4; a warning that needs a human decision (a human's stale claim, dropping a task, pruning NEXT) goes into the PR description for the lead.
  3. Archive closed tasks (W9, J.8).
  4. Add INDEX Routing rows for reported routing gaps.
  5. Delete a migration stub (F.23) whose date has passed.
  6. Prune `state/NEXT.md` only if the lead asked.
- Limits: gardening never changes code; never rewrites content it does not understand (it adds a STALE banner and a task instead); never releases a human's claim.
- Commit `mkb: gardening YYYY-MM-DD`; the PR description lists each finding in at most 5 lines.
- Micro-gardening: any session may fix a single false item it notices in a file it read anyway.

### L.7 `docs/mkb/tools/mkb-check.sh` specification

Usage:

```text
sh docs/mkb/tools/mkb-check.sh [--root DIR] [--no-git] [--adr-dir DIR] [--today YYYY-MM-DD] [--strict] [check]
sh docs/mkb/tools/mkb-check.sh [--root DIR] [--no-git] [--adr-dir DIR] next TASK|ADR|Q
```

- `--root DIR`: repository root containing `docs/mkb/`; default: `git rev-parse --show-toplevel`, else the current directory.
- `--no-git`: skip checks W2, W3, W6, W14; `next` scans only the working tree.
- `--adr-dir DIR`: an ADR directory adopted in place (N.2), relative to the root. Its files keep their native format: mkb-check applies no front-matter or file-name checks to them (E2, E3 and E4 are skipped there); E1 becomes "two files in DIR with the same leading number" (the N.4 check); W10 resolves `ADR-<n>` to a file `DIR/<n>-*.md`, comparing numbers as integers; `next ADR` prints 1 + the highest leading number of any file ever added to DIR on any ref (D.4), padded to the width of the existing numbers, as `ADR-<n>`. Default: `docs/mkb/decisions` with the normal checks.
- `--today`: date used for age checks (default: the system date); used for reproducible runs.
- `--strict`: warnings also make the exit code 1.
- Exit codes: 0 no errors (and no warnings under `--strict`); 1 errors found; 2 usage error.
- Output lines: `ERROR E<n> <path>: <message>`, `WARN W<n> <path>: <message>`, final line `mkb-check: <e> errors, <w> warnings`.
- `next` prints one ID, for example `TASK-008`; with no existing record it prints the first number (`TASK-001`).
- Scope: `docs/mkb/**/*.md` excluding `docs/mkb/templates/`, plus the `--adr-dir` directory for the checks named above.
- Record checks (E1 to E4 and the front matter checks) apply to `decisions/`, `tasks/` (including `archive/`), `questions/`, `knowledge/` and the singletons that C.1 requires front matter on. Files under `handoff/` get only W1 and W4, plus E3 when they contain front matter; the same E3 fires for any file on which C.1 forbids front matter.
- Lines inside fenced code blocks (opened by three or more backticks or tildes) are ignored by W5, W8, W10 and W11, so RULES.md and knowledge docs can show formats in fences.
- Implementation: POSIX sh, git, grep -E, sed, awk, find, wc only; no bash arrays; date arithmetic in awk (days-from-civil), never `date -d` or `date -v`; strips `\r` so CRLF files do not break parsing; runs in Git Bash on Windows, Linux and macOS; at most 450 lines; LF line endings.
- From PowerShell: `& "$env:ProgramFiles\Git\bin\bash.exe" docs/mkb/tools/mkb-check.sh`.

Errors:

| Code | Check |
|---|---|
| E1 | the same `id` value in two files (including `tasks/archive/`) |
| E2 | an ID file whose name differs from its `id` |
| E3 | front matter violates C.2 or C.5: missing required key, unknown key, invalid vocabulary value, invalid date, handle or ID pattern, a conditional key rule broken, or a line other than one blank line between the closing `---` and the H1 (key order is not checked) |
| E4 | an ID file in the wrong directory for its prefix (for example `MODULE-` outside `knowledge/modules/`) |
| E5 | a file named `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` or `AGENTS.override.md` under `docs/mkb/` |

Warnings:

| Code | Check |
|---|---|
| W1 | file over its size budget (B.5) |
| W2 | the last commit touching any of a doc's `code` paths is dated after the last commit touching the doc itself (`git log -1 --format=%cs -- <paths>` and `-- <doc>`, compared as strings; same-day commits, and a commit that touches both, never warn) |
| W3 | a `code` path does not exist |
| W4 | a handoff file whose task is `done`, `dropped` or missing |
| W5 | a `state/CURRENT.md` bullet not in the dated form, or older than 14 days (`profile: full`) or 35 days (`profile: minimal`), read from INDEX |
| W6 | an `in-progress` task whose branch has no commit for 7 days or is not found; with `branch: pending`, the last commit touching the task file on the default branch is used, and so it is when `branch` is the default branch |
| W7 | a question with `status: answered` |
| W8 | a line starting with `> STALE ` whose date is older than 30 days |
| W9 | a `done` or `dropped` task in `tasks/` with `closed` more than 30 days ago |
| W10 | a TASK, ADR or knowledge ID referenced in `docs/mkb/` with no file (Q IDs are exempt: resolved questions are deleted by design; values of `formerly` are exempt) |
| W11 | a line starting with `<!-- guide:` outside `docs/mkb/templates/` |
| W12 | a `blocked` task whose `blocked_by` items are all missing, `done` or `dropped` |
| W13 | `state/NEXT.md` lists a task that is `done`, `dropped` or missing |
| W14 | a `blocked` task whose file has not changed for 14 days |
| W15 | an `open` question with `created` more than 14 days ago |
| W16 | a knowledge doc or `project/ARCHITECTURE.md` whose `verified` is older than 180 days |
| W17 | a `low` task that is not `done` or `dropped` with `created` more than 90 days ago |

### L.8 Size budgets

As in B.5.
Also: AGENTS.md MKB block ≤ 35 lines; each template ≤ 40 lines; handoff ≤ 30 lines; RULES.md ≤ 500 lines.

### L.9 Profile differences (table for RULES.md section 14 and spec/11)

| Rule | Minimal | Full |
|---|---|---|
| Files at adoption | B.2 | B.3 |
| One branch per task | SHOULD; trunk-based sequential work is allowed | MUST |
| Claim visible to others before coding | SHOULD; one actor alone on the default branch: the claim is the first commit of the work (J.4 step 8) | MUST |
| One worktree per parallel local agent | MUST when agents run in parallel | MUST |
| Gardening cadence | monthly | weekly |
| `mkb-check.sh` in CI | optional | SHOULD (advisory, never blocks on warnings) |
| Staleness thresholds | L.4; W5 at 35 days | L.4; W5 at 14 days |

---

## M. Concurrency protocol

### M.1 Model

- One work item, one branch, one writer. Parallel local agents each use their own `git worktree`; git refuses to check out one branch in two worktrees.
- Never push to or force-push a branch you did not create; a cloud agent and a local agent never share a branch.
- Exception: once the session that owns a PR branch has ended, a human reviewer MAY add commits to it (for example to set an ADR to `accepted` during review); never force-push it.
- Two actors on one task at the same time is a claim violation, not a merge problem: the later actor stops.
- Rebase your branch onto the default branch at session start and before every push (push your own rebased branch with `git push --force-with-lease`); keep branches to a few days.
- Exception: after a renumber (D.5) a branch takes the default branch by `git merge origin/main` until it merges.

### M.2 Coordination commits

Coordination commits change only MKB coordination data and go straight to the default branch: claims, releases, block and unblock, new tasks and new questions (at allocation, D.4 step 6), answers, resolutions (except when the promotion creates an ADR, K.3), `state/CURRENT.md` facts that change outside a PR, and `state/NEXT.md` edits by the lead.
Everything else rides the work branch and reaches the default branch with the PR.

Recipe. It does not disturb your working tree and works from any worktree. The temporary worktree has a unique path under the system temp directory, so parallel sessions that share a handle never collide, and tools whose sandbox allows writes only to the workspace and temp directories can use it (P.2a).

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

Protected default branch: coordination changes become one-file PRs labelled `mkb-coord`, merged by the first human who sees them; claims use J.4a.
No remote: the same recipe with `git worktree add "$d" main` (a real checkout of `main`, no `--detach`, no fetch or push) when `main` is not checked out anywhere; otherwise commit in the worktree that has `main` checked out only if its working tree is clean; otherwise ask the human.

### M.3 Hot files and merge classes

| File | Class | Concurrent writers | Merge outcome |
|---|---|---|---|
| `tasks/TASK-NNN.md` | per-item | no (owner only; others append Notes) | different tasks: clean; same task: loud conflict on status, owner, branch |
| `decisions/ADR-NNN.md` | per-item, frozen | no | ID collision: add/add conflict |
| `questions/Q-NNN.md` | per-item | sequential (asker, then owner) | clean |
| `knowledge/**/<ID>.md` | per-item | occasionally | one sentence per line keeps conflicts to the sentence; parallel bumps conflict on the `verified` line (M.6); same new subject: add/add |
| `handoff/TASK-NNN.md` | per-branch | never | never conflicts |
| `state/CURRENT.md` | record file | yes, rarely | different bullets: clean unless adjacent; same bullet: loud |
| `state/NEXT.md` | single writer | no (lead) | clean |
| INDEX, project/*, RULES, templates, tools | slow reference | rarely | resolved by hand with human review |

### M.4 Formatting for mergeability (all MKB files)

- One sentence per line in prose; never hard-wrap or re-flow a paragraph.
- Tables use minimal spacing `| a | b |` with the separator `|---|---|`, never column-aligned.
- Lists use `-`; ordered lists use `1.`; `state/NEXT.md` uses `-` so reordering does not renumber.
- Append new items at the designated spot; never sort, reorder or reformat existing lines.
- LF line endings (F.22), UTF-8 without BOM.
- No "Last updated" lines anywhere.
- New front matter keys go in template order (C.5); existing keys are never reordered.

### M.5 Lost-update guard

An agent's in-context copy of a file may be hours old.
Re-read the file from disk right before editing it, patch only the lines you mean to change, and never write a whole MKB file regenerated from memory.
If the file changed since you first read it, merge your intent into the new content.

### M.6 Conflict cookbook (MKB files only)

| Conflict | Resolution |
|---|---|
| add/add on `tasks/TASK-NNN.md` or `questions/Q-NNN.md` in the coordination worktree | ID taken at creation: abort the rebase, allocate the next number, retry (D.4 step 6) |
| add/add on `decisions/ADR-NNN.md`, or on an ID already on a branch | ID collision: the branch merging second renumbers its own item (D.5) |
| add/add on a knowledge doc | same subject documented twice: merge the content into one doc |
| a knowledge doc's `verified` line | both sides bumped it: keep the older date, unless you re-check the merged doc against the merged code |
| task `status`, `owner`, `branch` lines | claim race: the default branch wins; the other actor stops and picks another task |
| task Notes, acceptance criteria, `related`, `code` | keep both sides; Notes in date order |
| `state/CURRENT.md` bullets | keep both sides; for the same bullet keep the newer date; a deletion wins when the fact is no longer true |
| `state/NEXT.md` | the lead's version wins |
| a handoff file | two writers on one branch (rule violation): the later session re-reads and rewrites it by hand |
| an accepted ADR body | restore the default branch's version; move the change into a superseding ADR |
| knowledge or project prose | resolve sentence by sentence against the code; if unsure keep both and add a STALE banner |
| INDEX.md | keep the union of rows |
| RULES.md above section 16, templates, tools | take the default branch's version |

Never resolve MKB conflicts with `-X ours`, `-X theirs` or "accept all"; during a rebase "ours" means the upstream side.

### M.7 Parallel agents

- Local parallel agents: one worktree and one branch each, named `<actor>/task-nnn-<slug>`.
- Cloud agents: the dispatching human claims (J.4 step 6, or J.4a step 4 on a protected default branch) and selects the task branch when resuming, so the agent sees its handoff.
- Humans editing inside an agent's worktree or branch while it runs is forbidden.
- Hot-file edits SHOULD be separate small commits so they re-apply easily after a rebase.

---

## N. Integration with existing docs and migration

### N.1 Adoption procedure (both profiles)

1. Inspect the repository: README, CONTRIBUTING, `docs/`, a site generator that builds `docs/` (GitHub Pages from `/docs`, MkDocs, Docusaurus, Sphinx), ADR directories, AGENTS.md, CLAUDE.md, `.cursor/rules`, `.cursorrules`, GEMINI.md, `.github/copilot-instructions.md`, `.gitattributes`, monolithic handoff or notes files, issue tracker usage.
2. Work on branch `<actor>/mkb-adopt`; a human reviews the PR.
3. Run the adoption commands of N.6: they stop if `docs/mkb` exists, copy `templates/<profile>/docs/mkb` to `docs/mkb`, and append the F.22 lines to `.gitattributes` only where absent. Nothing existing is overwritten.
4. Fill INDEX (People and agents, Path overrides), OVERVIEW, CONSTRAINTS, CURRENT, NEXT; in the full profile also ARCHITECTURE (an agent drafts it from the code, a human reviews it) and CONVENTIONS (or an override to CONTRIBUTING.md). Delete every guide comment.
5. Insert the MKB block (P.1) into root `AGENTS.md` between its markers (create the file if missing); create or update root `CLAUDE.md` (F.21); add tool pointers only where needed (P.3).
6. Migrate existing content (N.2 to N.5).
7. Run `sh docs/mkb/tools/mkb-check.sh` (with `--adr-dir <dir>` when an ADR directory is adopted): zero errors. When a site generator builds `docs/`, also run the site build (N.2).
8. Commit `mkb: adopt MKB v1.0 (<profile> profile)`.

### N.2 Existing documentation

| Existing | Strategy |
|---|---|
| `README.md` | Adopt in place. It stays the human front door and wins for install and usage text. Add one line: "Project memory: `docs/mkb/INDEX.md`". OVERVIEW points to README sections and never copies them. |
| `CONTRIBUTING.md` | Adopt in place; authoritative for the contribution process. CONVENTIONS.md holds only what it lacks; if it covers everything, no CONVENTIONS.md and an INDEX override row. |
| Existing ADR directory (`docs/adr/`, `doc/adr/`, `docs/decisions/`; adr-tools `NNNN-slug.md`, MADR) | Adopt in place; never move or rename (external links and tooling depend on names). INDEX override row plus the changed Routing rows (F.2). Old and new ADRs keep the directory's native format, file naming and numbering; no MKB front matter is added (MADR front matter would clash with the MKB schema). The MKB ADR rules apply (I.1 to I.8: who decides, immutability, superseding); the MKB schema does not. New ADRs use the directory's own template; if it lacks any of Context, Problem, Decision, Alternatives considered or Consequences, add the missing ones as sections. The ID in prose is `ADR-` plus that number (`ADR-0007`); allocate with D.4 (adopted variant) or `mkb-check.sh next ADR --adr-dir <dir>`. Native statuses read as MKB statuses: `Proposed` -> `proposed`, `Accepted` -> `accepted`, `Rejected` -> `rejected`, `Deprecated` -> `deprecated`, `Superseded by N` -> `superseded`. Legacy `Proposed` ADRs already on the default branch violate I.4: the lead accepts or rejects each one during adoption. Because file name differs from ID, the duplicate-number check (N.4) is mandatory before merges and in CI, and `mkb-check.sh` runs with `--adr-dir <that directory>` (L.7). |
| A site generator that builds `docs/` (GitHub Pages from `/docs`, MkDocs, Docusaurus, Sphinx) | `docs/mkb/` holds tasks, questions, warnings and customer names, and MDX-based generators can fail on the templates' `<handle>` placeholders and HTML comments. Exclude `docs/mkb/` in the generator's configuration (name the option only after checking that generator's documentation) and run the site build in the adoption PR. If exclusion is not possible, the lead approves the exposure in the adoption PR before it merges. |
| Monolithic `Handoff.md`, `NOTES.md`, `STATUS.md` | Migrate once (N.3). |
| `AGENTS.md` | Adopt in place; insert the MKB block between markers; move project knowledge found in it (architecture, module notes, status) into the MKB, leaving commands and style rules. |
| `CLAUDE.md` | Adopt in place; first line `@AGENTS.md`; remove content that duplicates AGENTS.md; keep Claude-only notes. |
| `.cursor/rules/*.mdc`, `.cursorrules`, `GEMINI.md`, `.github/copilot-instructions.md` | Keep tool-specific rules; replace duplicated project rules with a one-line pointer to AGENTS.md; `.cursorrules` is legacy: move its content to AGENTS.md or `.cursor/rules/`. |
| Other docs (`docs/*.md`, runbooks, wiki) | Leave in place; add INDEX Routing rows or Path overrides pointing to them; migrate a doc into the MKB only when rewriting it anyway. |
| External issue tracker | J.9. |

### N.3 Migrating a monolithic Handoff.md

1. One session on `<actor>/mkb-adopt` (or `<actor>/mkb-migrate-handoff`), reviewed by a human; tell the team not to edit Handoff.md meanwhile (a Warnings bullet if the MKB already exists).
2. Read the whole file once and sort every paragraph:

| Paragraph content | Destination |
|---|---|
| durable fact about code, data, devices, vendors, environments | knowledge doc, or project/OVERVIEW.md or ARCHITECTURE.md |
| past significant decision | backfilled ADR (I.8) |
| non-negotiable rule stated by a person or document | project/CONSTRAINTS.md with source |
| open work | tasks |
| open question | questions |
| current condition (build, deployments, known breakage) | state/CURRENT.md bullets dated with the migration date |
| priorities | state/NEXT.md (the lead confirms) |
| session narrative, logs, obsolete notes | dropped (git keeps them) |

3. Replace Handoff.md with the stub F.23; delete the stub at the first gardening 30 days later.
4. Put the paragraph-to-destination mapping in the PR description, not in the MKB.
5. A branch that still edits Handoff.md will conflict with the stub; port its new content into the MKB.

### N.4 Duplicate-number check for adopted ADR directories

```sh
ls docs/adr | grep -oE '^[0-9]+' | sort | uniq -d     # must print nothing
```

```powershell
Get-ChildItem docs/adr -Name | Select-String '^\d+' | ForEach-Object { $_.Matches[0].Value } | Group-Object | Where-Object Count -gt 1
```

### N.5 Upgrading the MKB version (for spec/13)

Replace the block between `<!-- MKB:BEGIN v...` and `<!-- MKB:END -->`; replace RULES.md above section 16 by hand (keep section 16); replace `docs/mkb/templates/` and `docs/mkb/tools/` with the upgrade commands of N.6 (they never touch INDEX, project/, state/ or records); set `mkb_version` in INDEX and RULES; one commit `mkb: upgrade to MKB v<version>`.

### N.6 Copy commands (for `templates/README.md`, N.1 step 3 and N.5)

Run from the root of the standard repository; `<profile>` is `minimal` or `full`; the target repository path is in `REPO` (sh) or `$repo` (PowerShell).

Adoption (sh):

```sh
if [ -e "$REPO/docs/mkb" ]; then echo "docs/mkb already exists: stop"; else
  mkdir -p "$REPO/docs" && cp -R templates/<profile>/docs/mkb "$REPO/docs/mkb"
  f="$REPO/.gitattributes"; touch "$f"; [ -n "$(tail -c 1 "$f")" ] && echo >> "$f"
  while IFS= read -r l; do grep -qxF -- "$l" "$f" || printf '%s\n' "$l" >> "$f"; done < templates/gitattributes-mkb.txt
fi
```

Adoption (PowerShell):

```powershell
if (Test-Path "$repo/docs/mkb") { "docs/mkb already exists: stop" } else {
  New-Item -ItemType Directory -Force "$repo/docs" | Out-Null
  Copy-Item -Recurse templates/<profile>/docs/mkb "$repo/docs/mkb"
  $f = Join-Path $repo ".gitattributes"; $have = @(if (Test-Path $f) { Get-Content $f })
  $add = @(Get-Content templates/gitattributes-mkb.txt | Where-Object { $have -cnotcontains $_ })
  if ($add.Count) { $pre = if ((Test-Path $f) -and (Get-Content $f -Raw) -and -not (Get-Content $f -Raw).EndsWith("`n")) { "`n" } else { "" }; [IO.File]::AppendAllText($f, $pre + ($add -join "`n") + "`n") }
}
```

Each block is one compound statement, so a stop leaves nothing half done even when pasted into an interactive shell; the `.gitattributes` lines are written with LF endings.

Upgrade (sh, then PowerShell); `git rm` keeps the old files in history:

```sh
git -C "$REPO" rm -r -q docs/mkb/templates docs/mkb/tools
cp -R templates/<profile>/docs/mkb/templates templates/<profile>/docs/mkb/tools "$REPO/docs/mkb/"
```

```powershell
git -C $repo rm -r -q docs/mkb/templates docs/mkb/tools
Copy-Item -Recurse templates/<profile>/docs/mkb/templates, templates/<profile>/docs/mkb/tools "$repo/docs/mkb/"
```

Never copy `templates/<profile>/.` over a repository: it would overwrite filled files.

---

## O. Anti-patterns (numbered; spec/10 uses exactly this list and numbering)

From the brief:
1. One giant `Handoff.md` or any catch-all notes file.
2. The same information in several documents.
3. Documenting every code change; git records changes, the MKB records knowledge.
4. An ADR for a trivial implementation choice.
5. Stale "current state" left indefinitely.
6. Dozens of unnecessary Markdown files: empty stubs, placeholder directories, one-file ceremonies.
7. Documentation as a replacement for reading the source code.
8. Making an agent read the entire MKB for every task.

Specific to this standard:
9. Status tracked in two places: a task file plus a board, list or blocker file.
10. Hand-maintained catalogs: INDEX listing every doc; committed generated boards or doc lists.
11. `updated:` fields or "Last updated" lines.
12. A handoff used as a diary, or restating the task.
13. Durable knowledge parked in a handoff "for later".
14. One shared handoff file that every session overwrites.
15. Editing another actor's claimed task or handoff.
16. Invisible claims: a claim that was edited locally but never pushed, or made only in chat.
17. Two writers on one branch or worktree (a cloud agent and a local agent; a human inside an agent's worktree).
18. Regenerating an MKB file from memory instead of patching the current file.
19. Reformatting, re-wrapping, re-sorting or column-aligning shared files.
20. Resolving MKB conflicts with `-X ours`, `-X theirs` or "accept all".
21. Allocating IDs from a stale local tree; keeping a new TASK or Q file on a branch instead of pushing it to the default branch at once; reusing a deleted or archived number; renumbering an ID on the default branch.
22. Slugs in ID file names (`ADR-007-use-redis.md`), which make ID collisions silent.
23. Editing an accepted ADR's body; an agent accepting or rejecting an ADR on its own authority; merging a decision that no listed decider approved (I.4); editing a constraint to match the code.
24. Merging a `proposed` ADR to the default branch.
25. Bumping `verified` without checking the code.
26. Undated state bullets; editing `state/CURRENT.md` for branch progress or finished work.
27. Agents reordering `state/NEXT.md` unasked.
28. Linking to heading anchors or code line numbers in durable docs; linking IDs instead of writing them bare.
29. Docs that restate code: function lists, parameter tables, diagrams of the obvious.
30. Project knowledge copied into AGENTS.md, CLAUDE.md or tool rule files; parallel per-tool rule sets.
31. Tool-named files (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`) under `docs/mkb/`.
32. Secrets, credential values, personal data of customers or patients, logs, stack traces or diffs in any MKB file.
33. A task for every 10-minute fix; two task systems (MKB tasks mirroring an issue tracker).
34. Bulk-generated knowledge docs for code nobody is changing.
35. "I will update the docs later": MKB updates belong in the same PR as the change.
36. Blockers without an owner: `blocked_by` pointing at nothing actionable, or a reason written only in prose.
37. Reading `tasks/archive/`, `templates/` or superseded ADRs by default.
38. Leaving template guide comments in real files.

Each anti-pattern in spec/10 gets: the anti-pattern (bold, one line), why it hurts (one line), the rule that prevents it (one line with a chapter reference).

---

## P. Agent instruction block and per-tool wiring

### P.1 The block (verbatim; 29 lines including markers)

```markdown
<!-- MKB:BEGIN v1.0 -->
## Project memory (MKB)

`docs/mkb/` is this repository's memory: intent, decisions, hard-won knowledge, current state, open work and handoffs.
Code and tests are the truth for behavior; `docs/mkb/project/CONSTRAINTS.md` and accepted ADRs are the truth for intent.
Full rules: `docs/mkb/agents/RULES.md`; `git grep -n "^## " -- docs/mkb/agents/RULES.md` lists its sections, read only the one you need. Never read the whole tree.

Before changing code
1. `git fetch`, then rebase your branch onto `origin/main` (on main: `git pull --rebase`). Read `docs/mkb/INDEX.md` and `docs/mkb/state/CURRENT.md`. Lite path, for a fix of at most 3 files that changes no interface, configuration, schema or dependency and is finished now: read the Warnings in CURRENT.md, run step 4 for your files and errors, make the fix, correct any doc it makes wrong, update nothing else.
2. Your task is the one you were given, else the first ID in `docs/mkb/state/NEXT.md` whose task on the default branch is `todo` with `owner: none` or you. Read `docs/mkb/tasks/TASK-NNN.md`, then its handoff `docs/mkb/handoff/TASK-NNN.md` on the task's branch, or on the branch its Notes name as released (take over from that branch: RULES.md section 5). Work that may outlast this session and has no task: create one from `docs/mkb/templates/TASK.md`.
3. Claim before coding: `git show origin/main:docs/mkb/tasks/TASK-NNN.md` must show `status: todo` and `owner: none` or you. Set `status: in-progress`, `owner`, `branch`; commit `TASK-NNN: claim` only in a temporary worktree of `origin/main` (RULES.md section 11), never on a work branch; `git push origin HEAD:main`. A conflict on that file, or your claim commit vanishing in the rebase, means it is taken: pick another. Then create `<you>/task-nnn-<slug>` from `origin/main` and push it at once. Cannot push to main, or cannot fetch or push at all: RULES.md section 5; never code on an unpushed claim. Minimal profile, alone on main: the claim is the first commit of your work.
4. Discover, don't browse: `git grep "^code:" -- docs/mkb/knowledge docs/mkb/tasks` and keep the docs whose entry is a prefix of a file you will touch; then `git grep -l -w <ID>` for each ID you hold (the task's and the kept docs') and `git grep -l -F "<exact error text>"` for each error you chase, over `docs/mkb` and the decisions directory named in INDEX. Read front matter first; at most 5 docs in full; skip `tasks/archive/` and `templates/`. Another actor's `in-progress` task covers your files: tell the human before editing.

While working
5. CONSTRAINTS.md and accepted ADRs bind you. To deviate, write a `proposed` ADR or a question; never edit an accepted ADR; never accept or reject an ADR on your own authority: when a named human decides it in this session, record the status and list them in `deciders`.
6. A knowledge or architecture doc contradicts the code: fix the doc in the same commit, or add a `> STALE` banner and a task. Never change code to match a descriptive doc.
7. Record each discovery when you make it, in its home doc (RULES.md section 3), linked by bare ID, never copied. Out-of-scope work becomes a new `todo` task.
8. New TASK or Q: number from `sh docs/mkb/tools/mkb-check.sh next TASK` (or `Q`); create the file and push it to main at once as a coordination commit, before anything refers to it. New ADR: `next ADR` (adopted ADR directory: RULES.md section 15), `status: proposed`, on your branch. Commit subjects start with the task ID.
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
```

Writers MUST reproduce this block byte for byte in `agent-instructions/AGENTS.tmpl.md` and `examples/tarelog/AGENTS.tmpl.md`.
Adopters whose default branch is not named `main` replace `main` in the block's commands, as in RULES.md and INDEX.md; that is the only edit allowed.
Spec chapters refer to `agent-instructions/AGENTS.tmpl.md` instead of quoting the block.

### P.2 Per-tool wiring (facts verified 2026-09-23 from the research sheet; "UNVERIFIED" marks what the sheet could not confirm)

| Tool | What it loads natively | MKB wiring | Status |
|---|---|---|---|
| Codex CLI, IDE extension, desktop app | In each directory from the project root down to the working directory, `AGENTS.override.md` if present, else `AGENTS.md` (at most one per directory); merged root first, later files override; stops at 32 KiB combined (`project_doc_max_bytes`). | The block in root `AGENTS.md`. If the repository has a root `AGENTS.override.md`, Codex skips root `AGENTS.md` there: put the block in the override file or remove the override. Check with `codex --ask-for-approval never "Summarize the current instructions."` | verified |
| Codex cloud | UNVERIFIED (not on the cloud doc page; only a search snippet says it reads AGENTS.md). | Same root `AGENTS.md`. The dispatching human claims the task (J.4 step 6) and selects the task branch when resuming. At adoption, ask a cloud task to summarize its instructions to confirm. | UNVERIFIED |
| Claude Code | CLAUDE.md files in the working directory and above at launch (concatenated, closest last); subdirectory CLAUDE.md files on demand when Claude reads files there; `@path` imports (max 4 hops; ignored inside code spans and code blocks). Reads AGENTS.md natively only from v2.1.277, and by default only when no CLAUDE.md exists; not on Bedrock or other third-party providers, with telemetry disabled, or before v2.1.277. | Root `CLAUDE.md` whose first line is `@AGENTS.md` as plain text, then only Claude-specific notes; the docs state the import never loads the file twice. On Windows use the import, not a symlink. Never put a CLAUDE.md under `docs/mkb/`: it would load as instructions for that subtree. | verified |
| Cursor | Root `AGENTS.md` (plain Markdown); nested `AGENTS.md` for its subtree; root `CLAUDE.md` always applied; `.cursor/rules/*.mdc` with `description`, `globs`, `alwaysApply`; plain `.md` in `.cursor/rules` ignored; `.cursorrules` is legacy. | Nothing required. Optional `.cursor/rules/mkb.mdc` (F.24) for teams that rely on rules. Cursor sees the literal `@AGENTS.md` line of CLAUDE.md; whether it expands it is UNVERIFIED and harmless because it reads AGENTS.md anyway. | verified; import expansion UNVERIFIED |
| Gemini CLI | `GEMINI.md` (global, workspace and parents, just-in-time for accessed directories); `context.fileName` in `.gemini/settings.json` accepts a string or array; imports `@./file.md`. | `.gemini/settings.json` from F.24. Check with `/memory show`. | verified |
| Aider | Nothing automatically; `/read`, `--read` or `read:` in `.aider.conf.yml`. | `.aider.conf.yml` from F.24. Aider cannot run the discovery greps or claims itself: the human runs discovery (`/read` the docs found), claims and handoffs. | verified (no native discovery found) |
| GitHub Copilot on GitHub.com (cloud agent, code review, Chat) | `.github/copilot-instructions.md` (repository-wide); `.github/instructions/**/NAME.instructions.md` with `applyTo`; agent instructions from `AGENTS.md` anywhere (nearest wins) or a single root `CLAUDE.md` or `GEMINI.md`; the docs say agent instructions "are currently not supported by all Copilot features". | Nothing required for the cloud agent. Optional one-line pointer in `.github/copilot-instructions.md` (F.24) for features that do not read AGENTS.md; which features those are is UNVERIFIED. Which file wins when both root `AGENTS.md` and root `CLAUDE.md` exist is UNVERIFIED; the plain fallback line in `CLAUDE.md` (F.21) covers the case where only `CLAUDE.md` is read. At adoption, ask the Copilot agent to summarize its instructions. The cloud agent follows the dispatcher-claims rule. | verified; feature coverage and AGENTS.md/CLAUDE.md precedence UNVERIFIED |
| GitHub Copilot in VS Code | Settings `chat.useAgentsMdFile`, `chat.useNestedAgentsMdFiles` (off by default), `chat.useClaudeMdFile`; `.instructions.md` files; sources are additive. | Ensure `chat.useAgentsMdFile` is enabled (its default is UNVERIFIED); leave nested files off. | partly UNVERIFIED |
| Windsurf / Devin Desktop (Cascade) | `AGENTS.md` or `agents.md`; root file always on; subdirectory file scoped to that directory; parent directories up to the git root. | Nothing required. | verified |

Size facts to cite: Codex caps combined instructions at 32 KiB by default; Claude Code docs advise under 200 lines per file; Cursor advises under 500 lines per rule.
The block is about 30 lines, well inside all three.

### P.2a What coordination commits need from a local agent tool

Not in the research sheet: every item is UNVERIFIED and is checked at adoption.

| Tool | Needs | Status |
|---|---|---|
| Codex CLI | Network access for `git fetch` and `git push`, and writes to the system temp directory for the coordination worktree (M.2). Its default sandbox may disable network access: approve those commands when asked, or enable network access for its workspace-write sandbox in its configuration (reported as `network_access = true` under `[sandbox_workspace_write]`). | UNVERIFIED |
| Claude Code | Permission to run `git fetch`, `git push` and `git worktree`, and to write in the system temp directory; allow these in its permission settings so that claims do not stall on prompts. | UNVERIFIED |
| Codex cloud, Copilot coding agent | Cannot push to the default branch: the dispatching human claims (J.4 step 6, J.4a step 4) and creates the tasks and questions they request (D.4 step 7). Network access after setup is UNVERIFIED. | UNVERIFIED |

Adoption check: have each local agent tool make one real coordination commit (for example its first claim) while a human watches.
An agent that cannot fetch or push stops before coding and asks the human to push the claim (J.4 step 9).

### P.3 Recommended wiring (for agent-instructions/README.md and spec/13)

1. The block inline in root `AGENTS.md`, once.
2. Root `CLAUDE.md` = `@AGENTS.md` plus Claude-only notes.
3. `.gemini/settings.json` if Gemini CLI is used.
4. `.aider.conf.yml` if Aider is used.
5. No `.cursor/rules/mkb.mdc` and no `.github/copilot-instructions.md` unless the team needs them (both optional pointers).
6. Re-check tool behavior at gardening when tool versions change; tool loading rules change between versions.
7. Give local agents the network and git permissions of P.2a, and check them at adoption.

---

## Q. Worked example outline: TareLog

### Q.1 Project

TareLog is a fictional weighbridge ticketing service for a gravel quarry run by the fictional Northfield Aggregates.
It reads weights from two fictional WI-200 weighing indicators (fictional vendor Ponderix) through serial-to-Ethernet converters, stores weighing tickets in SQLite, and delivers daily delivery reports to the fictional haulage customer Beta Haulage.
All company, vendor, device and customer names are fictional; URLs use `example.com`.

Stack: Python 3.12, FastAPI web UI, SQLite in WAL mode, asyncio TCP client, pytest, Jinja2; headless Chromium for PDF (removed during the example); SFTP via paramiko.
Runs on a Linux mini-PC in the weighbridge office.
Code paths (referenced, not present in the example): `src/tarelog/gateway/` (reader service), `src/tarelog/gateway/wi200.py` (frame parser), `src/tarelog/gateway/reader.py`, `src/tarelog/tickets/` (ticket store, `store.py`), `src/tarelog/reports/`, `src/tarelog/delivery/`, `src/tarelog/web/`, `migrations/`, `tests/`, `data/tarelog.db` (live database, never committed).
Pre-existing docs: `README.md`, `CONTRIBUTING.md` (Python style, pytest), a 600-line `Handoff.md` accumulated over months of agent sessions.
Default branch `main`; code goes through PRs; direct pushes to `main` are allowed for coordination commits.

### Q.2 Cast

| Handle | Kind | Role |
|---|---|---|
| `marta` | human | tech lead: owns state/NEXT.md, accepts ADRs, talks to the customer, merges PRs |
| `luca` | human | developer and operations, part-time; works by hand and runs Codex CLI on his laptop |
| `claude-code` | agent | Claude Code in local worktrees on Marta's machine |
| `codex` | agent | Codex cloud tasks dispatched by Marta (cannot push to main), and Codex CLI run by Luca (can push) |

### Q.3 Sessions (year 2026)

S1, 09-01, marta + claude-code, branch `claude-code/mkb-adopt`, PR #10 merged the same day. Adoption, full profile.
- Triage of Handoff.md (WALKTHROUGH shows a 30-to-40-line excerpt of the old file and the mapping table).
- Creates: INDEX (profile full; People: marta, luca, claude-code, codex; Path override: none, because CONVENTIONS.md is created for what CONTRIBUTING.md lacks), agents/RULES.md, templates/*, tools/mkb-check.sh, project/OVERVIEW.md, project/ARCHITECTURE.md (drafted by claude-code, reviewed by marta, `verified: 2026-09-01`), project/CONSTRAINTS.md, project/CONVENTIONS.md, state/CURRENT.md, state/NEXT.md.
- Knowledge from Handoff.md: `SERVICE-GATEWAY`, `DB-TICKETS`, `TS-SQLITE-LOCKED` (all `verified: 2026-09-01`).
- `ADR-001` "Store weighing tickets in SQLite in WAL mode", backfilled: accepted, `date: 2026-03-10`, `deciders: [marta]`, Context starts "Recorded retroactively from Handoff.md on 2026-09-01."
- Constraints: tickets are legal-for-trade records, never updated or deleted, corrections are new tickets referencing the original (source marta, metrology rules); reports reach the customer by 06:00 local time (source: Beta Haulage contract); credentials never in the repository (source marta).
- Tasks: TASK-001 "Nightly backup of the ticket database" (normal), TASK-002 "Parse WI-200 frames with a real parser" (high), TASK-003 "Daily delivery report per customer" (high), TASK-004 "Deliver daily reports to the customer SFTP" (high), all `created: 2026-09-01`.
- NEXT: TASK-002, TASK-003, TASK-004, TASK-001.
- CURRENT: Health `- 2026-09-01 marta: Production weighbridge PC runs v0.7.2; daily reports are compiled by hand.` (no "CI green" bullet, K.5); Focus `- 2026-09-01 marta: Automated per-customer reports and delivery (TASK-003, TASK-004).`; Warning `- 2026-09-01 marta: Lane 2 readings are dropped by the regex parser; weigh lane 2 manually (TASK-002).`
- Handoff.md becomes the stub (F.23); AGENTS.md block inserted; CLAUDE.md `@AGENTS.md`; `.gitattributes` lines.
- Later that day: luca claims TASK-001 on main (`TASK-001: claim`, branch `luca/task-001-nightly-backup`).

S2, 09-02, claude-code on TASK-002, branch `claude-code/task-002-wi200-parser` in its own worktree.
- Claim commit on main (`TASK-002: claim`, with `code: [src/tarelog/gateway/]`) via the temporary-worktree recipe.
- Discovery: `git grep "^code:" -- docs/mkb/knowledge docs/mkb/tasks` prints one line per doc; the entry `src/tarelog/gateway/` of SERVICE-GATEWAY is a prefix of `src/tarelog/gateway/wi200.py`; the reverse hop `git grep -l -w SERVICE-GATEWAY -- docs/mkb/decisions` finds no ADR; `git grep -l -w SERVICE-GATEWAY -- docs/mkb` adds ARCHITECTURE; reads 3 docs (CONSTRAINTS, SERVICE-GATEWAY, ARCHITECTURE row). WALKTHROUGH shows the `^code:` output.
- Discovery during work: creates `INT-WI200` (frame format; ST stable vs US unstable frames, US must never be stored; converters deliver 64-byte chunks so frames split across TCP reads; literal error `FrameError: missing ETX`).
- 11:29 finds that readings are lost while the report job holds the SQLite lock: fetches, opens a temporary coordination worktree (allocation scan max = 004), creates TASK-005 "Buffer readings while SQLite is locked" (high) and commits `TASK-005: add`. 11:31 the push is rejected: marta pushed her own TASK-005 at 11:30 (S3). Fetch and rebase of the coordination worktree: `CONFLICT (add/add): Merge conflict in docs/mkb/tasks/TASK-005.md`; `git rebase --abort`, allocates again (TASK-006), recreates the file, pushes `TASK-006: add`. Nothing referred to TASK-005 yet, so no renumber and no `formerly` are needed. Only then it writes `# TODO(TASK-006): buffer readings while the DB is locked.` in `src/tarelog/gateway/reader.py` on its branch.
- Session ends unfinished: overwrites `handoff/TASK-002.md` on the branch (full text shown in WALKTHROUGH, at most 30 lines), then commits and pushes everything including it.

S3, 09-02 (in parallel with S2), codex cloud on TASK-003, dispatched by marta.
- Marta claims on main: `TASK-003: claim for codex`, `owner: codex`, `branch: pending`, Notes "dispatched to Codex cloud".
- Codex creates `MODULE-REPORTS`; weighs PDF via headless Chromium vs ReportLab vs HTML e-mail and writes `ADR-002` "Render daily reports as PDF with headless Chromium" as `proposed`.
- It notices that customers in other time zones need a different report day. As a dispatched agent it allocates no task ID (D.4 step 7).
- Finishes: TASK-003 `done`, `closed: 2026-09-02`, `branch: codex/task-003-daily-report` (replacing `pending`), Completion; opens PR #11 at 11:20, whose description ends with `MKB for humans:`, `ADR decisions needed: ADR-002`, `New task: Per-customer report time zone`.
- 11:30 marta reads PR #11 and creates TASK-005 "Per-customer report time zone" (normal, `todo`, `owner: none`) as the coordination commit `TASK-005: add`.

S4, 09-03, marta then claude-code.
- Marta reviews PR #11, sets ADR-002 `accepted`, `date: 2026-09-03`, `deciders: [marta]` (commit `ADR-002: accept` on the PR branch, M.1 exception) and merges it as the listed decider (I.4).
- claude-code resumes TASK-002: `git fetch`, rebases its branch onto `origin/main` (clean), reads its handoff and verifies it against `git log`, finishes the parser.
- Updates SERVICE-GATEWAY (parser location, `verified: 2026-09-03`) and INT-WI200 (`verified: 2026-09-03`).
- TASK-002 `done`, `closed: 2026-09-03`, Completion with "Follow-ups: TASK-006"; checks the handoff's Dead ends line (reading one frame per TCP read fails) against INT-WI200, where it is already recorded, then deletes `handoff/TASK-002.md` (T3); deletes the lane-2 Warning bullet in CURRENT. Marta merges PR #12.
- 09-04 marta deploys v0.8.0 and, as a coordination commit, replaces the v0.7.2 Health bullet with `- 2026-09-04 marta: Production weighbridge PC runs v0.8.0; daily PDF reports e-mailed to customers at 06:00 (TASK-003).` (it becomes stale in S7).

S5, 09-08, luca runs Codex CLI on TASK-004 (Luca approves its `git fetch` and `git push` calls, P.2a).
- Codex claims on main itself (`TASK-004: claim`, `owner: codex`, `branch: codex/task-004-sftp-delivery`).
- Discovery: MODULE-REPORTS, CONSTRAINTS (credentials, 06:00), ADR-002.
- The customer spec mentions both key and password authentication: Codex opens `Q-001` "Does the Beta Haulage SFTP server require key authentication or password authentication?" (`owner: marta`, `asked_by: codex`) and sets TASK-004 `blocked`, `blocked_by: [Q-001]`, Notes line, as one coordination commit via the temporary worktree (`Q-001: ask marta`); its final message ends with `MKB for humans:` and `Questions: Q-001 (marta)`.
- Overwrites `handoff/TASK-004.md` on its branch (full text in WALKTHROUGH), then commits and pushes everything including it.

S6, 09-10, marta, then claude-code on branch `claude-code/mkb-q-001-promote`, PR #14 merged the same day.
- Marta fills Q-001 Answer: "2026-09-10 marta: Key authentication only; they also said their ERP imports CSV only, so PDF is not needed." and sets `status: answered` (coordination commit `Q-001: answer`).
- claude-code first creates TASK-007 "Remove the Chromium PDF pipeline" (normal, `todo`) as the coordination commit `TASK-007: add`.
- Because the promotion creates an ADR, the resolution rides PR #14 instead of a coordination commit (K.3 step 3). claude-code promotes: new `INT-HAULER-SFTP` (key auth, key stored in the host's vault at `tarelog/sftp-key`, target directory `/inbound/tarelog/`, deadline 06:00; "(resolves Q-001)"; no `code` key yet, because no code talks to the server (C.5); `verified: 2026-09-10`); new `ADR-003` "Deliver daily reports as CSV instead of PDF" (`supersedes: [ADR-002]`, drafted by claude-code, accepted by marta in the PR as the listed decider, `deciders: [marta]`, `date: 2026-09-10`, Context cites Q-001, Consequences cite TASK-007); ADR-002 gets only `status: superseded` and `superseded_by: ADR-003`; MODULE-REPORTS repointed to ADR-003; TASK-004 acceptance criteria updated with "(resolves Q-001)" (the promoter may edit them although codex owns the task, J.3), `blocked_by` removed, status back to `in-progress` because `branch` is set; Q-001 file deleted. Commit `Q-001: resolved -> ADR-003, INT-HAULER-SFTP, TASK-004`. The PR description ends with `MKB for humans:`, `ADR decisions needed: ADR-003`, `NEXT suggestion: TASK-007 PDF pipeline is dead code after ADR-003`.
- Marta edits NEXT to TASK-004, TASK-007, TASK-006, TASK-005 and replaces the Focus bullet with `- 2026-09-10 marta: CSV delivery to Beta Haulage live before 2026-10-01 (TASK-004, TASK-007).`

S7, 09-14 to 09-17, three actors in parallel, including a cross-tool takeover.
- 09-14 luca, by hand, adds checksum support in `src/tarelog/gateway/wi200.py` without touching INT-WI200 (drift for S8).
- 09-15 codex (Luca's CLI) resumes TASK-004 from its handoff after rebasing; implements CSV upload with key auth in `src/tarelog/delivery/sftp.py`; updates INT-HAULER-SFTP (adds `code: [src/tarelog/delivery/sftp.py]`, `verified: 2026-09-15`). Luca leaves for a week that evening: codex overwrites `handoff/TASK-004.md` (next step: retry 3 times, then alert e-mail) and commits and pushes everything; Luca releases the task as the coordination commit `TASK-004: release` (`status: todo`, `owner: none`, `branch` removed, Notes `- 2026-09-15 luca: released; partial work on branch codex/task-004-sftp-delivery, see its handoff`).
- 09-16 marta asks claude-code to finish TASK-004 before the 10-01 deadline. claude-code claims it (`TASK-004: claim`, `branch: claude-code/task-004-sftp-delivery`), creates its branch from `origin/codex/task-004-sftp-delivery` (`git switch -c claude-code/task-004-sftp-delivery origin/codex/task-004-sftp-delivery`), rebases it onto `origin/main`, pushes it, reads Codex's handoff and verifies it against the branch (J.4 step 5). It adds the retry and the alert e-mail, updates INT-HAULER-SFTP (`verified: 2026-09-16`) and MODULE-REPORTS (`verified: 2026-09-16`); TASK-004 `done`, `closed: 2026-09-16`; PR #15 forgets to delete `handoff/TASK-004.md` (inherited from Codex's branch); marta merges it 09-16.
- 09-16 a second claude-code session, in its own worktree, claims TASK-007 (`branch: claude-code/task-007-remove-chromium`; same handle, told apart by `branch`, J.4 step 7), removes the Chromium pipeline, removes the "PDF renderer" row from ARCHITECTURE and re-verifies the whole doc (`verified: 2026-09-17`), updates MODULE-REPORTS. On 09-17 its rebase onto `origin/main` (after PR #15) conflicts on the `verified` line of MODULE-REPORTS; it re-checks the merged doc against the merged code and keeps `verified: 2026-09-17` (M.6).
- 09-17 the same session sees TASK-005 is ambiguous: opens `Q-002` "Should a report day end at quarry-local midnight or at midnight in each customer's time zone?" (`owner: marta`, `asked_by: claude-code`, `created: 2026-09-17`, `related: [TASK-005, MODULE-REPORTS]`) and sets the unowned TASK-005 `blocked`, `blocked_by: [Q-002]` (coordination commit `Q-002: ask marta`). TASK-007 `done`, `closed: 2026-09-17`; PR #16, whose description ends with `MKB for humans:` and `Questions: Q-002 (marta)`, is merged.
- 09-17 marta deploys v0.9.0 and adds the Health bullet `- 2026-09-17 marta: Production weighbridge PC runs v0.9.0; CSV reports reach Beta Haulage by 06:00 (TASK-004, TASK-007).` as a coordination commit, but forgets to delete the v0.8.0 bullet; she replaces the Focus bullet with `- 2026-09-17 marta: Reliable readings on both lanes before the October peak (TASK-006).`, prunes TASK-004 and TASK-007 from NEXT and rewords the TASK-006 and TASK-005 entries (coordination commit `mkb: update NEXT`).

S8, 09-22, claude-code, gardening asked by marta, branch `claude-code/mkb-garden-2026-09-22`, PR #17 merged the same day, commit `mkb: gardening 2026-09-22`.
Findings (the PR description, 5 lines):
1. W5 stale state: the v0.8.0 Health bullet (2026-09-04, 18 days old, PDF reports) contradicts ADR-003 and TASK-007 and is replaced by the 09-17 bullet: deleted.
2. W4: `handoff/TASK-004.md` on main while TASK-004 is done: its Dead ends line (the partner server rejects parallel uploads) moved into INT-HAULER-SFTP `## Gotchas` (T3), then the handoff deleted.
3. W2 drift: INT-WI200 and SERVICE-GATEWAY (both last touched 09-03) share `src/tarelog/gateway/`, changed 09-14 by luca: INT-WI200 gains a checksum section, SERVICE-GATEWAY is still correct; both set to `verified: 2026-09-22`.
4. W6: TASK-001 `in-progress` owned by `luca`, no commit on `luca/task-001-nightly-backup` since 09-04 (18 days): human owner, so not released; flagged to marta, who decides (L.4); Warning bullet added about manual backups.
5. mkb-check after the fixes: 0 errors, 1 warning (the W6 of finding 4, waiting for marta); nothing to archive (oldest `closed` is 2026-09-02); the Handoff.md stub stays until the first gardening after 2026-10-01.

### Q.4 End state on `main` after S8 (exact file list of `examples/tarelog/`)

```text
examples/tarelog/
├── WALKTHROUGH.md
├── AGENTS.tmpl.md                 project notes + the P.1 block verbatim
├── CLAUDE.tmpl.md                 identical to agent-instructions/CLAUDE.tmpl.md
├── Handoff.md                     the F.23 stub dated 2026-09-01
├── .gitattributes                 the adopter's file: identical to templates/gitattributes-mkb.txt (F.22)
└── docs/mkb/
    ├── INDEX.md                   profile: full
    ├── agents/RULES.md            byte-identical to templates/full/docs/mkb/agents/RULES.md
    ├── project/OVERVIEW.md
    ├── project/ARCHITECTURE.md    verified: 2026-09-17
    ├── project/CONSTRAINTS.md
    ├── project/CONVENTIONS.md
    ├── state/CURRENT.md
    ├── state/NEXT.md
    ├── decisions/ADR-001.md       accepted, date 2026-03-10
    ├── decisions/ADR-002.md       superseded, superseded_by ADR-003
    ├── decisions/ADR-003.md       accepted, supersedes [ADR-002]
    ├── tasks/TASK-001.md          in-progress, owner luca, branch luca/task-001-nightly-backup
    ├── tasks/TASK-002.md          done, closed 2026-09-03, owner claude-code
    ├── tasks/TASK-003.md          done, closed 2026-09-02, owner codex
    ├── tasks/TASK-004.md          done, closed 2026-09-16, owner claude-code, branch claude-code/task-004-sftp-delivery; Notes hold luca's release line
    ├── tasks/TASK-005.md          blocked, owner none, blocked_by [Q-002]
    ├── tasks/TASK-006.md          todo, owner none (no formerly: the collision was caught at creation)
    ├── tasks/TASK-007.md          done, closed 2026-09-17, owner claude-code
    ├── questions/Q-002.md         open, owner marta
    ├── knowledge/services/SERVICE-GATEWAY.md          verified 2026-09-22
    ├── knowledge/integrations/INT-WI200.md            verified 2026-09-22
    ├── knowledge/integrations/INT-HAULER-SFTP.md      verified 2026-09-16, code [src/tarelog/delivery/sftp.py]
    ├── knowledge/database/DB-TICKETS.md               verified 2026-09-01
    ├── knowledge/modules/MODULE-REPORTS.md            verified 2026-09-17
    ├── knowledge/troubleshooting/TS-SQLITE-LOCKED.md  verified 2026-09-01
    ├── templates/                 the 11 files, byte-identical to templates/full/docs/mkb/templates/
    └── tools/mkb-check.sh         byte-identical to templates/full/docs/mkb/tools/mkb-check.sh
```

There is no `handoff/` directory on main at the end (both handoffs appear in full inside WALKTHROUGH.md).

End-state contents that MUST match:
- `state/NEXT.md` entries: `- TASK-006: readings lost while the report job holds the database` and `- TASK-005: after Q-002 is answered`.
- `state/CURRENT.md`: Health `- 2026-09-17 marta: Production weighbridge PC runs v0.9.0; CSV reports reach Beta Haulage by 06:00 (TASK-004, TASK-007).` (the only Health bullet); Focus `- 2026-09-17 marta: Reliable readings on both lanes before the October peak (TASK-006).`; Warnings `- 2026-09-22 claude-code: Nightly backup (TASK-001) is not running yet; copy `data/tarelog.db` by hand before any migration.` (writers may escape or rephrase the inner backticks, keeping the meaning).
- Priorities: TASK-001 normal, TASK-002 high, TASK-003 high, TASK-004 high, TASK-005 normal, TASK-006 high, TASK-007 normal.
- `created`: TASK-001 to TASK-004 2026-09-01; TASK-005 and TASK-006 2026-09-02; TASK-007 2026-09-10.
- ADR-001 `related: [DB-TICKETS, TS-SQLITE-LOCKED]`; ADR-002 `related: [TASK-003, MODULE-REPORTS]`; ADR-003 `related: [TASK-004, TASK-007, MODULE-REPORTS, INT-HAULER-SFTP]`.
- Every ID referenced anywhere in the example resolves to a file, except Q-001 (resolved and deleted).
- `sh templates/full/docs/mkb/tools/mkb-check.sh --root examples/tarelog --no-git --today 2026-09-23` prints `mkb-check: 0 errors, 0 warnings` and exits 0.

### Q.5 WALKTHROUGH.md structure

```text
# TareLog walkthrough
(status line per S.3, "Example (informative)")
## The project and the cast
## Starting point: the old Handoff.md (excerpt, 30-40 lines, fictional)
## S1 ... S8 (one ## section each), each with:
   - Who, when, branch, goal (2-3 lines)
   - What they read: discovery commands and their (short) output
   - What they wrote: table File | Change
   - Key excerpt: a diff, a file excerpt or a command transcript (at most 25 lines)
   - Rule illustrated: one line per rule with a spec chapter reference
## End state (the tree of Q.4 and the mkb-check output)
## What the rules prevented (table: situation | without MKB | with MKB)
```

Length target 450 to 700 lines.
It MUST show in full: the S1 triage mapping table, the S2 `^code:` discovery output, `handoff/TASK-002.md` (S2), the S2 rejected push with the add/add conflict in the coordination worktree and the retry as TASK-006, `handoff/TASK-004.md` (S5), the Q-001 file before resolution, the ADR-002 front matter after S6, the S7 takeover commands and luca's release Notes line, the `MKB for humans:` lines of PR #14, and the S8 findings.

---

## R. Deliverable layout of the standard repository

### R.1 File list

```text
C:\Wundev\MarkdownKnowledgeBase_MKB\
├── Prompt_MarkdownKnowledgeBase_Standard.md      (existing brief; do not modify)
├── .gitattributes                                 one line: "* text=auto eol=lf"
├── README.md
├── spec/
│   ├── 01-architecture.md
│   ├── 02-directory-structure.md
│   ├── 03-metadata.md
│   ├── 04-naming-and-linking.md
│   ├── 05-agent-workflow.md
│   ├── 06-handoff.md
│   ├── 07-decisions.md
│   ├── 08-tasks-and-questions.md
│   ├── 09-lifecycle.md
│   ├── 10-anti-patterns.md
│   ├── 11-profiles.md
│   ├── 12-concurrency.md
│   └── 13-adoption-and-integration.md
├── templates/
│   ├── README.md
│   ├── gitattributes-mkb.txt                      the F.22 lines (not active: not named .gitattributes)
│   ├── minimal/
│   │   └── docs/mkb/
│   │       ├── INDEX.md
│   │       ├── agents/RULES.md
│   │       ├── project/OVERVIEW.md
│   │       ├── project/CONSTRAINTS.md
│   │       ├── state/CURRENT.md
│   │       ├── state/NEXT.md
│   │       ├── templates/{TASK,ADR,QUESTION,HANDOFF,MODULE,SERVICE,DB,INT,TS,ARCHITECTURE,CONVENTIONS}.md
│   │       └── tools/mkb-check.sh
│   └── full/
│       └── docs/mkb/
│           ├── INDEX.md
│           ├── agents/RULES.md
│           ├── project/{OVERVIEW,ARCHITECTURE,CONSTRAINTS,CONVENTIONS}.md
│           ├── state/{CURRENT,NEXT}.md
│           ├── templates/{TASK,ADR,QUESTION,HANDOFF,MODULE,SERVICE,DB,INT,TS,ARCHITECTURE,CONVENTIONS}.md
│           └── tools/mkb-check.sh
├── agent-instructions/
│   ├── README.md
│   ├── AGENTS.tmpl.md
│   ├── CLAUDE.tmpl.md
│   ├── cursor/mkb.mdc
│   ├── gemini/settings.json
│   ├── aider/.aider.conf.yml
│   └── copilot/copilot-instructions.md
└── examples/
    └── tarelog/                                   (tree in Q.4)
```

Why no `templates/documents/`: the templates live inside each profile at `docs/mkb/templates/`, which is where adopting projects use them; a third copy would drift.
Why `.tmpl.md`: Claude Code loads nested `CLAUDE.md` files, and Codex, Cursor and Copilot load nested `AGENTS.md` files, as instructions; real names anywhere in this repository would inject MKB instructions into sessions working on the standard itself. Adopters rename on copy: `AGENTS.tmpl.md` -> `AGENTS.md`, `CLAUDE.tmpl.md` -> `CLAUDE.md`.

Why no `.gitattributes` inside `templates/<profile>/`: a copy command would overwrite the adopter's own file (LFS filters and other rules); adopters append the lines of `templates/gitattributes-mkb.txt` where absent (N.6).
The root `.gitattributes` (`* text=auto eol=lf`) keeps every file of this repository LF, templates and example included.
`examples/tarelog/.gitattributes` shows the adopter's end state; it is active for its own subtree, which is harmless.

Identity requirements (verified with `diff`):
- `templates/minimal/docs/mkb/{agents,templates,tools}` = `templates/full/docs/mkb/{agents,templates,tools}` = `examples/tarelog/docs/mkb/{agents,templates,tools}`.
- `templates/minimal/docs/mkb/project/{OVERVIEW,CONSTRAINTS}.md` and `state/*` = the full versions.
- `templates/full/docs/mkb/project/ARCHITECTURE.md` = `templates/full/docs/mkb/templates/ARCHITECTURE.md`; `templates/full/docs/mkb/project/CONVENTIONS.md` = `templates/full/docs/mkb/templates/CONVENTIONS.md`.
- `templates/gitattributes-mkb.txt` = `examples/tarelog/.gitattributes` = F.22.
- The P.1 block in `agent-instructions/AGENTS.tmpl.md` = the block in `examples/tarelog/AGENTS.tmpl.md`.
- `examples/tarelog/CLAUDE.tmpl.md` = `agent-instructions/CLAUDE.tmpl.md`.

### R.2 Coverage of the brief's deliverables

| # | Deliverable | Files |
|---|---|---|
| 1 | Specification of the architecture | `spec/01-architecture.md` (plus all of `spec/`) |
| 2 | Canonical directory structure | `spec/02-directory-structure.md`, `templates/full/` |
| 3 | Document templates | `templates/minimal/`, `templates/full/` (singletons and `docs/mkb/templates/`), `templates/README.md` |
| 4 | Metadata conventions | `spec/03-metadata.md` |
| 5 | Naming conventions | `spec/04-naming-and-linking.md` |
| 6 | Agent workflow | `spec/05-agent-workflow.md`, `templates/*/docs/mkb/agents/RULES.md` |
| 7 | Handoff rules | `spec/06-handoff.md` |
| 8 | ADR rules | `spec/07-decisions.md` |
| 9 | Task rules | `spec/08-tasks-and-questions.md` |
| 10 | Lifecycle and archival rules | `spec/09-lifecycle.md` |
| 11 | Anti-patterns | `spec/10-anti-patterns.md` |
| 12 | Minimal version | `spec/11-profiles.md`, `templates/minimal/` |
| 13 | Full version | `spec/11-profiles.md`, `templates/full/` |
| 14 | Agent instructions | `agent-instructions/`, `spec/13-adoption-and-integration.md` §13.5 |
| 15 | Realistic multi-agent example | `examples/tarelog/` |
| - | Concurrent Codex + Claude Code + humans | `spec/12-concurrency.md` |
| - | Integration with existing docs | `spec/13-adoption-and-integration.md` |

### R.3 Spec chapter outlines (section numbers are normative; each rule has ONE home chapter; other chapters reference it)

`spec/01-architecture.md` (target 150-250 lines):
1.1 Purpose and scope (one MKB per repository; monorepos out of scope in v1.0).
1.2 Conventions used in this standard (RFC 2119 and RFC 8174 keywords; glossary: record, work item, actor, human, agent, lead, owner, default branch, coordination commit, session, handoff, gardening, descriptive vs normative doc).
1.3 Design principles (the brief's eight principles, one paragraph each with how v1.0 meets it).
1.4 The rules in one screen (the seven rules from README).
1.5 Record kinds and their homes (table: the brief's nine categories -> location -> chapter).
1.6 Knowledge, state and handoff (the three tests: "still true in 3 months?" -> knowledge; "would someone not continuing my work need it?" -> state; otherwise handoff).
1.7 Authority and precedence (the three orders from INDEX Authority; the contradiction table G.6).
1.8 How an agent uses the MKB in one session (a 10-line walk-through pointing to chapter 5).
1.9 Chapter map.

`spec/02-directory-structure.md` (200-300 lines):
2.1 Full tree (B.1). 2.2 Minimal tree (B.2, B.3). 2.3 Per-file reference (B.5). 2.4 INDEX.md: role, sections, update protocol, never a catalog (F.1, F.2). 2.5 Creation rules (B.4). 2.6 Deviations from the original brief (B.6).

`spec/03-metadata.md` (200-300 lines):
3.1 Where front matter is used (C.1). 3.2 The MKB YAML subset (C.2). 3.3 Field dictionary (C.3). 3.4 Vocabularies (C.4). 3.5 Schemas per type (C.5) with one complete example per type using TareLog IDs. 3.6 Fields deliberately not used (C.6).

`spec/04-naming-and-linking.md` (200-300 lines):
4.1 ID kinds and patterns (D.1). 4.2 File and directory names (D.2). 4.3 Allocating numbered IDs (D.4). 4.4 Collisions and renumbering (D.5). 4.5 Knowledge names. 4.6 Branches, commits and PRs (D.3). 4.7 Dates and handles in text (D.6). 4.8 Linking conventions (E). 4.9 Referencing the MKB from code and git.

`spec/05-agent-workflow.md` (250-350 lines):
5.1 Session overview. 5.2 Before modifying code (G.1). 5.3 Discovery algorithm (G.2). 5.4 Lite path (G.4). 5.5 While working (G.3). 5.6 Update-trigger matrix (G.5). 5.7 Resolving contradictions (G.6, referencing 1.7). 5.8 Reporting to humans: the `MKB for humans:` lines (G.7). 5.9 Session checklist (a copyable checklist of 15 lines at most).

`spec/06-handoff.md` (150-250 lines):
6.1 Purpose and boundary. 6.2 File and location (H.1). 6.3 Format (F.13, H.2). 6.4 What goes in and what never goes in (H.3, H.4). 6.5 Writing and rotation (H.5). 6.6 Reading a handoff (H.6). 6.7 Parallel safety (H.7). 6.8 Why there is no handoff/CURRENT.md or HISTORY.md (H.8). 6.9 A good and a bad handoff (short side-by-side example).

`spec/07-decisions.md` (200-300 lines):
7.1 When to write an ADR (I.1). 7.2 When not to (I.2). 7.3 File and format (I.3, F.11). 7.4 Statuses and who decides (I.4). 7.5 Immutability (I.5). 7.6 Superseding and deprecating (I.6). 7.7 ADRs and code (I.7). 7.8 Backfilled ADRs (I.8). 7.9 Relation to Nygard, adr-tools and MADR (facts from the research sheet; adopted directories per 13.4).

`spec/08-tasks-and-questions.md` (250-350 lines):
8.1 When to create a task (J.1). 8.2 Task format (J.2, F.10). 8.3 Status model and edit rights (J.3). 8.4 Claiming protocol (J.4, J.4a, J.4b). 8.5 Release, stale claims and dropping (J.5). 8.6 Completion (J.6). 8.7 Blockers (K.4). 8.8 Board views (J.7). 8.9 Questions: when to ask (K.1, K.2). 8.10 Question format (F.12). 8.11 Resolution flow (K.3). 8.12 State files: CURRENT and NEXT (K.5, K.6). 8.13 Using an external issue tracker (J.9).

`spec/09-lifecycle.md` (250-350 lines):
9.1 Lifecycle matrix (L.1). 9.2 Archival (J.8, L.3). 9.3 Knowledge maintenance (L.2). 9.4 Staleness signals (L.4). 9.5 STALE banners (L.5). 9.6 Gardening (L.6). 9.7 mkb-check (L.7, full specification). 9.8 Size budgets (B.5, L.8).

`spec/10-anti-patterns.md` (120-200 lines):
10.1 From the brief (items 1-8). 10.2 Specific to this standard (items 9-38). Format per O.

`spec/11-profiles.md` (150-250 lines):
11.1 Choosing a profile. 11.2 Minimal profile (files, rules). 11.3 Full profile (files, rules). 11.4 Profile differences (L.9). 11.5 Upgrade triggers: any of two or more actors regularly working in parallel on separate branches; a second agent tool or a second human joins; more than 5 ADRs or more than 10 knowledge docs; the team keeps re-explaining the architecture to agents. 11.6 Upgrade steps: agent drafts ARCHITECTURE from the code, human reviews; CONVENTIONS or an INDEX override; set `profile: full` and update INDEX Layout and Routing rows; enable the CI check; schedule weekly gardening; no file moves, no ID changes.

`spec/12-concurrency.md` (250-350 lines):
12.1 Model (M.1). 12.2 Coordination commits (M.2, protected branch, no remote). 12.3 Hot files and merge classes (M.3). 12.4 Formatting for mergeability (M.4). 12.5 Lost-update guard (M.5). 12.6 Conflict cookbook (M.6). 12.7 Parallel agents, worktrees and cloud agents (M.7). 12.8 Why the design is merge-safe (short table: collision kind -> how it surfaces).

`spec/13-adoption-and-integration.md` (250-350 lines):
13.1 Adoption procedure (N.1, with the copy commands of N.6). 13.2 Integrating existing documentation (N.2, including documentation sites that build `docs/`). 13.3 Migrating a monolithic Handoff.md (N.3). 13.4 Existing ADR directories (N.2 row, N.4, the F.2 rows that change, `--adr-dir`). 13.5 Agent instruction files and per-tool wiring (P.2, P.2a, P.3; refers to `agent-instructions/`). 13.6 External issue trackers (reference 8.13). 13.7 Repositories without a remote (J.4b, M.2). 13.8 Upgrading the MKB version (N.5, N.6).

`README.md` (100-160 lines):
- Title `# Markdown Knowledge Base (MKB) Standard`, status line (S.3).
- What it is (5 lines).
- The rules in one screen (exactly these seven):
  1. Code shows what the system does; the MKB holds what code cannot show: intent, hard-won knowledge, state, open work and handoffs.
  2. Every record has an ID, the file name is the ID, and you refer to it by bare ID; never copy content between docs.
  3. One work item is one task file, one branch and one owner; the claim is visible to others before coding (a commit on the default branch, or a pushed task branch where the default branch is protected).
  4. `state/` describes the default branch; a handoff describes one unfinished task on its branch; neither holds knowledge.
  5. Record a discovery when you make it, in the doc where the next person will look.
  6. Constraints and accepted ADRs bind; descriptive docs follow the code; only humans accept ADRs.
  7. If nothing durable changed, update nothing; delete what is obsolete, because git remembers.
- Quick start: minimal profile (steps from N.1 condensed to 7 lines), full profile (3 extra lines).
- Repository map (table path -> contents).
- Deliverables coverage (R.2).
- Conformance: a repository conforms to MKB v1.0 when it has the files of its profile (B.2 or B.3), the P.1 block in root AGENTS.md, and `mkb-check.sh` reports 0 errors.
- Versioning: semantic, `MKB Standard v1.0`, block markers carry the version.

`templates/README.md` (40-90 lines): what each profile contains, the adoption and upgrade commands of N.6 verbatim (sh and PowerShell; never a copy of `templates/<profile>/.` over a repository), `gitattributes-mkb.txt`, that guide comments and placeholders must be filled or deleted, that `project/ARCHITECTURE.md` and `project/CONVENTIONS.md` are created later by copying `docs/mkb/templates/ARCHITECTURE.md` and `CONVENTIONS.md`, that the agent files come from `agent-instructions/` and are renamed on copy, the placeholder list.

`agent-instructions/README.md` (60-120 lines): the P.2 table, the P.3 recommendation, install steps for an existing AGENTS.md (insert between markers) and CLAUDE.md, rename-on-copy, how to verify per tool (only commands from P.2).

### R.4 Suggested work packages (one writer each)

| WP | Files | Depends on contract sections |
|---|---|---|
| WP1 | `README.md`, `templates/README.md`, root `.gitattributes` | A, B, N.6, R, S |
| WP2 | `spec/01`, `spec/02`, `spec/03` | A, B, C, F.1, F.2 |
| WP3 | `spec/04`, `spec/05`, `spec/06` | D, E, G, H |
| WP4 | `spec/07`, `spec/08` | I, J, K |
| WP5 | `spec/09`, `spec/10`, `spec/11` | L, O |
| WP6 | `spec/12`, `spec/13` | M, N, P |
| WP7 | all singleton and template files in `templates/minimal/` and `templates/full/` (F.1-F.18, including `docs/mkb/templates/ARCHITECTURE.md` and `CONVENTIONS.md`), and `templates/gitattributes-mkb.txt` (F.22) | C, F |
| WP8 | `agents/RULES.md` (one file, then copied); drafted first, reports its measured line count (≤ 500) | F.3 and everything it references |
| WP9 | `tools/mkb-check.sh` (one file, then copied) | C, D, L.7 |
| WP10 | `agent-instructions/**` | F.20, F.21, F.24, P |
| WP11 | `examples/tarelog/WALKTHROUGH.md` | Q |
| WP12 | `examples/tarelog/**` except WALKTHROUGH (copies made by the integrator) | Q, F |
| Integrator | copies, identity checks, R.5 | all; uses `check_links.py` from the orchestrator's scratchpad (already written; not a deliverable): it checks that relative Markdown links outside code resolve and their `#anchor` targets exist, that YAML front matter parses, and lists the 15 longest files |

### R.5 Integrator verification (all MUST pass before commit)

Searches use `grep -r` with `--exclude-dir=.git --exclude-dir=.claude`, never `git grep`: the files are still untracked when these checks run, and `git grep` ignores untracked files.

1. `find . \( -name .git -o -name .claude \) -prune -o \( -name AGENTS.md -o -name CLAUDE.md -o -name GEMINI.md -o -name AGENTS.override.md \) -print` prints nothing.
2. Identity checks of R.1 with `diff -r` / `cmp`.
3. `sh templates/full/docs/mkb/tools/mkb-check.sh --root examples/tarelog --no-git --today 2026-09-23` prints `mkb-check: 0 errors, 0 warnings`.
4. `mkb-check.sh` is NOT run on `templates/minimal` or `templates/full`: their placeholders (`YYYY-MM-DD`, `<handle>`) are invalid values by design. Templates are checked by item 5 (YAML front matter parses) and by review against section F.
5. Link and front matter check: `python <scratchpad>/check_links.py <repo>` (R.4, Integrator) reports 0 errors.
6. Size budgets: every MKB file in templates and the example within B.5; the P.1 block ≤ 35 lines; RULES.md ≤ 500 lines.
7. `grep -rnE --exclude-dir=.git --exclude-dir=.claude --exclude=Prompt_MarkdownKnowledgeBase_Standard.md '\b(TBD|FIXME)\b|TODO([^(.]|$)' .` finds nothing; `TODO(TASK-NNN)` code comments and the file name `TODO.md` in deviation notes are intended and not matched.
8. The names `HISTORY.md`, `BLOCKERS.md`, `OPEN.md`, `IN-PROGRESS.md`, `handoff/CURRENT.md` appear only in spec/02 §2.6, spec/06 §6.8, spec/10, spec/13 migration text and README deviation notes.
9. Every file starts with its prescribed H1 and (spec, README, WALKTHROUGH) status line.
10. No emojis: `LC_ALL=C.UTF-8 grep -rnP --exclude-dir=.git --exclude-dir=.claude "[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}]" .` finds nothing (the locale is needed for `-P` in Git Bash).
11. All files UTF-8 without BOM, LF endings.

---

## S. Style guide for writers

S.1 Language and tone:
- US English (behavior, color, organization).
- Plain, direct, precise; short sentences; no marketing, no filler, no rhetorical questions, no exclamation marks, no emojis.
- Procedures in the imperative ("Run", "Set"); rules in the third person with RFC 2119 keywords ("An agent MUST ...").
- Address the reader as "you" in procedures; never "we".

S.2 Normative language:
- MUST, MUST NOT, SHOULD, SHOULD NOT, MAY in uppercase, only when normative, per RFC 2119 and RFC 8174.
- Spec chapter 01 section 1.2 states this once; other chapters do not repeat it.
- Non-normative asides start with `Note:`; examples are labelled `Example:`.
- Rule wording from this contract is copied, not paraphrased, where it states a limit, a value, a pattern or a procedure step.

S.3 File headers:
- Spec chapter H1: `# N. Title` with N without leading zero, for example `# 5. Agent workflow`.
- Line 3 of every spec chapter, README and WALKTHROUGH is the status line in italics: `*MKB Standard v1.0 · 2026-09-23 · Normative*` (spec chapters), `*MKB Standard v1.0 · 2026-09-23*` (README), `*MKB Standard v1.0 · 2026-09-23 · Example (informative)*` (WALKTHROUGH), `*MKB Standard v1.0 · 2026-09-23 · Informative*` (templates/README.md, agent-instructions/README.md).
- Adoptable MKB files (templates, RULES, example docs) carry no status line; their version is `mkb_version` in INDEX and RULES.
- The version string is always exactly `MKB Standard v1.0`; the date is always `2026-09-23`.

S.4 Headings:
- Exactly one H1 per file.
- Spec sections `## N.M Title` and subsections `### N.M.K Title`; nothing deeper than `####`.
- Sentence case ("Agent workflow", not "Agent Workflow").
- No "Summary", "Conclusion" or "Introduction" sections.

S.5 Cross-references:
- Between chapters: `[05-agent-workflow.md](05-agent-workflow.md) §5.3` (link to the file, section number in text, never an anchor).
- From README to spec: relative links `[spec/05-agent-workflow.md](spec/05-agent-workflow.md)`.
- Each rule has one home chapter (R.3); other chapters reference it in one line instead of restating it.

S.6 Formatting:
- One sentence per line; no hard wrapping.
- Tables: `| a | b |` with `|---|---|`; never column-aligned.
- Bullets `-`; ordered lists `1.`.
- Code fences always carry a language: `sh`, `powershell`, `yaml`, `markdown`, `text`, `diff`, `json`.
- When showing a file that itself contains a code fence, wrap it in `~~~~` fences.
- Commands: plain git commands once (they work in sh and PowerShell); when a pipeline is needed, give sh first and PowerShell second.
- Placeholders in angle brackets; IDs in rules as `TASK-NNN`; concrete IDs only in examples, and examples use TareLog. Exception: the generic pattern examples of sections D and E (`TASK-042`, `ADR-007`, `ADR-008`, `Q-003`, `GH-123`, `OPS-45`, `claude-code/task-042-csv-export`) are kept as they are when spec/03, spec/04, spec/05 or spec/08 copy those tables. RULES.md, INDEX.md and templates use placeholders only (D.1).
- Paths: forward slashes, repo-root-relative, backticked.
- ASCII in fixed formats (front matter, dated lines, entry formats, `->` arrows); prose may use `§` and `·`.
- UTF-8 without BOM; LF line endings; file ends with one newline.

S.7 Terminology (use exactly):
- "default branch" in rules; `main` in examples and commands.
- "actor" for a human or an agent; "agent" for an AI tool; "lead" for the human named as lead in INDEX.
- "work item" for a task or an external tracker issue.
- "coordination commit", "handoff", "gardening", "claim", "release", "promote" (an answer), "STALE banner".
- "knowledge doc" (not "knowledge file"); "record" for any document with an ID.
- Tool names: Codex, Claude Code, Cursor, Gemini CLI, Aider, GitHub Copilot, Windsurf.

S.8 Scope discipline:
- Writers MUST NOT add files, fields, statuses, ID kinds, sections or rules beyond this contract.
- Writers MUST NOT state tool behavior beyond P.2; anything else about tools is omitted or marked UNVERIFIED exactly as in P.2.
- Writers MUST NOT use real company, vendor or customer names in examples.
- Each writer returns: the list of files written with line counts, and any gap or contradiction found in this contract.

---

## T. Change log from red-team

Three red-team reviews (52 issues) were applied on 2026-09-23. All 52 were accepted; none was rejected. Where two issues overlapped, one fix covers both; where an issue offered alternatives, the chosen one is named.

| Issue | Decision | Reason |
|---|---|---|
| 1 | ACCEPTED | C.2.1 now says the H1 is on the line right after the closing `---` (what every skeleton already does); one blank line is tolerated; E3 checks it; rule 10 keeps 16 lines. |
| 2 | ACCEPTED | D.5 step 6 integrates with `git merge origin/main` after the renumber commit (tested: a rebase replays the add and conflicts again); M.1 has the exception. |
| 3 | ACCEPTED | P.1 item 5 and G.3.1 now allow an agent to record a decision a named human makes in the session, matching I.4 and G.6. |
| 4 | ACCEPTED | F.3 extended: section 4 adds D.2, D.3 and E; section 5 adds J.2, J.4a, J.4b, J.7; section 12 adds C.4 and a compact C.5; section 13 adds L.4; budget raised (see 23). |
| 5 | ACCEPTED | D.5 uses `<OLD-ID>`/`<NEW-ID>`; W10's RULES exemption dropped; W5, W8, W10, W11 ignore fenced blocks; W8 and W11 match line starts; STALE route is `^> STALE [0-9]`. |
| 6 | ACCEPTED | L.7 scope rule: record checks only on record directories and singletons with front matter; handoffs get W1, W4, and E3 only if they have front matter. |
| 7 | ACCEPTED | M.2 worktree path is unique per call under the system temp dir (`mktemp -d`, GUID in PowerShell), with `git worktree prune` first and "remove only the worktree you created" (tested). |
| 8 | ACCEPTED | J.3 lets the promoter edit Goal, Acceptance criteria, `blocked_by` and status of blocked tasks; K.3 step 3 routes an ADR-creating resolution through a PR. |
| 9 | ACCEPTED | `next` takes `--adr-dir` and pads to the directory width; D.4 has the adopted-directory pipeline; status mapping completed; legacy Proposed decided at adoption; format per 26. |
| 10 | ACCEPTED | R.5 uses `grep -r` (files are untracked when checked); item 7 no longer matches `TODO(` or `TODO.md`; `check_links.py` defined and assigned to the integrator in R.4. |
| 11 | ACCEPTED | Profiles no longer ship `.gitattributes`; N.6 adoption commands refuse an existing `docs/mkb` and append the F.22 lines only where absent (tested in sh and PowerShell). |
| 12 | ACCEPTED | S7 now has marta pruning TASK-004 and TASK-007 from NEXT (`mkb: update NEXT`). |
| 13 | ACCEPTED | D.3 gains `TASK-NNN: add`, `Q-NNN: answer` and the trunk-based `TASK-NNN: done`. |
| 14 | ACCEPTED | One pickup sentence in F.1, F.9, G.1, K.6 and P.1: first NEXT ID whose task on the default branch is `todo` with `owner: none` or you. |
| 15 | ACCEPTED | T8, K.3 and J.3: back to `in-progress` if `branch` is set, otherwise `todo`, owner unchanged. |
| 16 | ACCEPTED | Trunk-based: Completion names the last code commit; the done edit is a follow-up commit `TASK-NNN: done` (J.2, J.6, D.3, F.10). |
| 17 | ACCEPTED | `INT-STRIPE` replaced by `INT-HAULER-SFTP`; S.6 allows the generic D/E pattern examples in spec/03, 04, 05 and 08. |
| 18 | ACCEPTED | F.2 "Rows that change with an override" applies the backticked CONVENTIONS rows in the full profile too. |
| 19 | ACCEPTED | The sh allocation pipeline prints the next ID (`TASK-001` on empty history; tested). |
| 20 | ACCEPTED | README rule 3 reworded ("visible to others"); L.9 aligned; dispatched claims on a protected branch use the claim branch of issue 50; "Cursor background agents" dropped from J.4. |
| 21 | ACCEPTED | Same fix as 11, plus upgrade commands that replace only `templates/` and `tools/` (via `git rm`, so history keeps them); N.1 step 3 and N.5 cite N.6. |
| 22 | ACCEPTED | W2 compares the last code-path commit date with the doc's own last commit date (day granularity, so squash and rebase merges do not warn); `verified` redefined; T11 and T22 bump it after checking the change; W16 keeps the whole-doc re-check. |
| 23 | ACCEPTED | ARCHITECTURE and CONVENTIONS skeletons moved to `docs/mkb/templates/` (11 templates); RULES budget 500 lines, measured by WP8 first; RULES section 15 now covers path overrides. |
| 24 | ACCEPTED | J.4 step 5 takeover from a released branch; H.5.4; S7 shows a Codex-to-Claude-Code takeover of TASK-004; Q.4 updated. |
| 25 | ACCEPTED | T2 and P.1 item 11: no task yet at session end means create it already claimed, then write its handoff; J.1 and G.4 point there. |
| 26 | ACCEPTED | Adopted ADR directories keep their native format (no MKB front matter); mkb-check skips E2-E4 there and runs the duplicate-number check as E1; F.2 gives the replacement Routing row; P.1 item 4 searches the decisions directory named in INDEX. |
| 27 | ACCEPTED | W16 and W17 added; L.4 documents the checker (check column); gardening means resolving mkb-check findings; cadence weekly or monthly, "every 10 merged PRs" deleted; stub deletion kept as one gardening step. |
| 28 | ACCEPTED | Health holds exceptions and deployed versions only, never "CI green"; W5 threshold 14 days (full) or 35 (minimal); G.1 step 6 uses observable signals only; S1, S8 and Q.4 changed. |
| 29 | ACCEPTED | G.7 defines the `MKB for humans:` lines; T9, T21, K.2, I.4, G.1 step 6, G.2 and P.1 item 15 point to it. |
| 30 | ACCEPTED | N.1 step 1 inspects site generators; N.2 row excludes `docs/mkb/` and runs the site build, or the lead approves the exposure. |
| 31 | ACCEPTED | Key order is no longer checked (C.2.3, E3); templates list the preferred order. |
| 32 | ACCEPTED | Lite path inlined in P.1 item 1; pickup rule fixed in item 2; minimal-profile note in item 3; the block is 29 lines. |
| 33 | ACCEPTED | T3 moves lasting Dead ends and Watch out lines to knowledge or task Notes before deleting the handoff; H.8 explains the squash-merge loss. |
| 34 | ACCEPTED | I.4: a PR carrying an ADR decision merges only when a listed decider approves or merges it; trunk-based needs that human in the session; anti-pattern 23 cites it. |
| 35 | ACCEPTED | J.7 gains a one-line-per-open-task board command in sh and PowerShell (tested); never committed. |
| 36 | ACCEPTED | `code` optional for `integration` (C.5, C.3, F.17); S6 shows INT-HAULER-SFTP without `code` until S7. |
| 37 | ACCEPTED | Discovery uses a prefix match on `git grep "^code:"` plus a reverse hop to ADRs; "missing knowledge" needs both the code-owner and the summary search empty; S2 shows it. |
| 38 | ACCEPTED | P.1 item 3 and J.4: read the task with `git show origin/main:`, commit the claim only in a temporary worktree, push with `HEAD:main`, then create and push the branch. |
| 39 | ACCEPTED | J.4 step 4 detects a dropped identical claim with `git rev-list --count` (tested); J.4 step 7 defines "yours"; worktree path as in 7. |
| 40 | ACCEPTED | New TASK and Q files are pushed to the default branch at allocation (compare-and-swap); dispatched agents never allocate them; D.5 now mainly covers ADRs; S2 and S3 show a rejected push and retry instead of a renumber. |
| 41 | ACCEPTED | G.1 step 1 and P.1 item 1 fetch and rebase first; status queries in INDEX and J.7 read `origin/main`. |
| 42 | ACCEPTED | The handoff is written first, then committed and pushed with all work (P.1 item 11, T2, H.5.1, F.13). |
| 43 | ACCEPTED | Same fix as 24; P.1 item 2 and G.1 step 3 name the released branch in Notes. |
| 44 | ACCEPTED | Error-text search added to P.1 item 4 and the lite path; another actor's in-progress task covering your paths is reported to the human; task `code` SHOULD be set at claim. |
| 45 | ACCEPTED | P.2a lists what Codex CLI and Claude Code need (all UNVERIFIED); temp-dir worktree; J.4 step 9 and P.1 item 3: never code on an unpushed claim. |
| 46 | ACCEPTED | F.21 adds a plain fallback line and a tool-neutral note; P.2 marks Copilot's AGENTS.md/CLAUDE.md precedence UNVERIFIED, with an adoption check. |
| 47 | ACCEPTED | Same fix as 3. |
| 48 | ACCEPTED | W6 covers `branch: pending` after 7 days without a change to the task file; J.5 and L.4 name the dispatching human. |
| 49 | ACCEPTED | M.6 row for the `verified` line (keep the older date unless re-checked); S7 shows it. |
| 50 | ACCEPTED | J.4a step 4: the dispatching human pushes a claim-only branch `<agent handle>/task-nnn-<slug>` and deletes it after merge or release. |
| 51 | ACCEPTED | Same fix as 8. |
| 52 | ACCEPTED | Lite path inline in P.1; P.1 cites RULES.md sections and says how to find them; skeletons moved out of RULES.md (as 23). |
