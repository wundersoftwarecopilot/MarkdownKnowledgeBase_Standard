# 2. Directory structure

*MKB Standard v1.0 · 2026-09-23 · Normative*

This chapter fixes every path the MKB uses, which files each profile creates at adoption, what each file is for, and how `INDEX.md` routes readers to them.
The content of each file is defined by its skeleton in `templates/full/docs/mkb/` and by the chapter named in §2.3.

## 2.1 Full tree

Every path that can exist in an MKB, in the full profile:

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

The three root files are shared with the project: the MKB adds a block to `AGENTS.md`, an import line to `CLAUDE.md` and four lines to `.gitattributes` ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.1, §13.5).
Content that stays outside `docs/mkb/`, such as `CONTRIBUTING.md` or an existing ADR directory, is reached through INDEX path overrides (§2.4.5) or Routing rows ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.2).

## 2.2 Minimal tree

Both profiles use the same paths; upgrading from minimal to full never moves or renames a file ([11-profiles.md](11-profiles.md) §11.6).

### 2.2.1 Minimal profile at adoption

Exact files created:

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

### 2.2.2 Full profile at adoption

Everything in §2.2.1 with `profile: full` in INDEX, plus:
- `docs/mkb/project/ARCHITECTURE.md`
- `docs/mkb/project/CONVENTIONS.md`, unless `CONTRIBUTING.md` already covers conventions; then no file is created and INDEX gets a path override row pointing to `CONTRIBUTING.md` (and the CONVENTIONS rows of INDEX change as described in §2.4.5, "Rows that change with an override").
- A CI job that runs `sh docs/mkb/tools/mkb-check.sh` (SHOULD, advisory).

Created when first needed in the full profile: `decisions/`, `tasks/`, `tasks/archive/`, `questions/`, `knowledge/<kind>/`, `handoff/`.

Choosing a profile: [11-profiles.md](11-profiles.md) §11.1.

## 2.3 Per-file reference

Profile legend:
- `min` = created at adoption in both profiles.
- `full` = created at adoption in the full profile, created when needed in the minimal profile.
- `lazy` = created when first needed in both profiles.

| Path | Purpose | Profile | Updated by / when | Size budget | Front matter |
|---|---|---|---|---|---|
| `AGENTS.md` (MKB block) | Operational rules auto-loaded by most agents | min | A human; only when upgrading the MKB version (the block between markers is replaced whole) | block ≤ 35 lines | no |
| `CLAUDE.md` | Imports AGENTS.md for Claude Code | min, if Claude Code is used | A human; at adoption | own content ≤ 20 lines | no |
| `.gitattributes` (MKB lines) | LF line endings for MKB and agent files | min | A human; at adoption | 4 lines | no |
| `docs/mkb/INDEX.md` | Entry point: layout, routing, authority, people, overrides | min | A human, or an agent through a reviewed PR; only when layout, routing, people or overrides change; never per task | ≤ 120 lines | yes |
| `docs/mkb/agents/RULES.md` | Operational rulebook for reading and writing the MKB | min | Standard text replaced on MKB version upgrade; humans edit only the final section "Project-specific rules" | ≤ 500 lines | yes |
| `docs/mkb/project/OVERVIEW.md` | Purpose, users, scope, stack, commands, glossary | min | Anyone whose change alters scope, stack or commands, in the same PR | ≤ 80 lines | no |
| `docs/mkb/project/ARCHITECTURE.md` | System context, components, data flow, deployment, code map | full | Whoever adds, removes or re-bounds a component, in the same PR; `verified` bumped only after a check ([03-metadata.md](03-metadata.md) §3.3) | ≤ 150 lines | yes |
| `docs/mkb/project/CONSTRAINTS.md` | Non-negotiable rules with sources (normative) | min | Humans; an agent only when a human states the rule in the session, citing that human | ≤ 80 lines | no |
| `docs/mkb/project/CONVENTIONS.md` | Project conventions that tooling and CONTRIBUTING.md do not cover (normative) | full | Anyone through a PR approved by a human, when a convention changes | ≤ 120 lines | no |
| `docs/mkb/state/CURRENT.md` | Health, focus, warnings of the default branch as dated bullets | min | Anyone whose change alters a project-level fact (in the delivering PR or as a coordination commit); the lead writes Focus; gardening prunes | ≤ 40 lines | no |
| `docs/mkb/state/NEXT.md` | Ordered pickup queue of at most 10 IDs | min | The lead only; an agent only when a human asks in the session | ≤ 15 lines | no |
| `docs/mkb/decisions/ADR-NNN.md` | One decision | lazy | Author on a branch while `proposed`; a human sets `accepted`/`rejected`; afterwards only `status` and `superseded_by` change | ≤ 100 lines | yes |
| `docs/mkb/tasks/TASK-NNN.md` | One work item | lazy | Creator (a coordination commit at allocation); then only the owner (others append Notes lines; anyone may edit a task whose owner is `none`; the lead may edit any task; a promoter applying [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.11 may edit the parts §8.3 names) | ≤ 60 lines | yes |
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

Front matter rules: [03-metadata.md](03-metadata.md).
Size budgets are checked by `mkb-check.sh` warning W1 ([09-lifecycle.md](09-lifecycle.md) §9.8).

## 2.4 INDEX.md

### 2.4.1 Role

`docs/mkb/INDEX.md` is the entry point of the MKB and a near-static router: layout, routing, authority, people and agents, path overrides, update rules.
It never lists individual tasks, ADRs, questions or knowledge docs.
A catalog of records would change with every record, so every parallel branch would edit it and it would go stale whenever a session forgot it; the Routing commands produce the same lists from the records themselves ([10-anti-patterns.md](10-anti-patterns.md), item 10).
Its front matter is `type: index`, `mkb_version` and `profile` ([03-metadata.md](03-metadata.md) §3.5).
The complete skeletons are `templates/full/docs/mkb/INDEX.md` and `templates/minimal/docs/mkb/INDEX.md`.

### 2.4.2 Sections

| Section | Holds |
|---|---|
| (three lines under the H1) | what the folder is, that code and tests are the truth for what the system does, and that nobody reads it all |
| Start here | the first reads, in order: `state/CURRENT.md`; your task and, on its branch, its handoff; no task yet: the first ID in `state/NEXT.md` whose task on the default branch is `todo` with `owner: none` or you; only the section of `agents/RULES.md` you need |
| Layout | one row per path of §2.1 with what it holds and whether it exists `always` or `when needed`; files that exist are relative links, the others backticked paths |
| Routing | one row per need: what to read and the `git grep` command that finds it (§2.4.3) |
| Authority | the three orders and the never-authoritative list of [01-architecture.md](01-architecture.md) §1.7.1 |
| People and agents | every handle used in the project, its kind (`human` or `agent`) and its role; the lead is named here |
| Path overrides | kinds of content that live outside `docs/mkb/` (§2.4.5), or a single `none` row |
| Updating the MKB | update only what your work changed; refer by bare ID and never copy; INDEX changes only with layout, routing, people or overrides; what needs a human goes in the `MKB for humans:` lines |

### 2.4.3 Routing

The Routing section of the full-profile INDEX:

```markdown
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
```

Status queries read `origin/main` (without a remote: `main`), because claims and answers land there first; their output paths start with `origin/main:`.
The discovery algorithm that uses these commands: [05-agent-workflow.md](05-agent-workflow.md) §5.3.

### 2.4.4 Minimal-profile differences

The minimal-profile INDEX is identical to the full-profile INDEX except exactly these four differences.

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

### 2.4.5 Path overrides

Path override rows (both profiles, examples of the exact form):

```markdown
| conventions | `CONTRIBUTING.md` | no project/CONVENTIONS.md; CONTRIBUTING.md is authoritative |
| decisions | `docs/adr/NNNN-<slug>.md` | adr-tools directory adopted in place, native format; IDs are ADR-NNNN; run mkb-check with `--adr-dir docs/adr` |
| tasks | <tracker URL> | tracker is authoritative; no tasks/ |
```

When a project adds its first override row, it deletes the `| none | - | - |` row.

Rows that change with an override (both profiles, so that no link points to a missing file):
- conventions: the CONVENTIONS Layout row becomes the backticked row of difference 2 in §2.4.4, and the Routing row "How code is written here" becomes the row of difference 3.
  This applies in the full profile too when §2.2.2 replaces CONVENTIONS.md by the override.
- decisions: the Layout row `decisions/ADR-NNN.md` names the adopted directory; the Routing row "What must never be broken" becomes the row below; "Why something is the way it is" greps the adopted directory instead of `docs/mkb/decisions`.

```markdown
| What must never be broken | project/CONSTRAINTS.md, then accepted ADRs in `docs/adr/` | `git grep -l -i -E '^(status: *"?)?accepted' -- docs/adr` |
```

- tasks: the Layout rows for `tasks/` and the Routing rows "What to work on", "Who is working on what" and "What is blocked and on what" name the tracker and its saved queries instead of `git grep` commands.

Adopted ADR directories: [13-adoption-and-integration.md](13-adoption-and-integration.md) §13.4.
External trackers: [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.13.

### 2.4.6 Update protocol

- INDEX is updated by a human, or by an agent through a reviewed PR; only when layout, routing, people or overrides change; never per task.
- Budget: ≤ 120 lines.
- Gardening adds Routing rows for the routing gaps that sessions report in their `MKB for humans:` lines ([09-lifecycle.md](09-lifecycle.md) §9.6, [05-agent-workflow.md](05-agent-workflow.md) §5.8).
- An MKB version upgrade changes only `mkb_version` in INDEX ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.8).
- A merge conflict in INDEX keeps the union of rows ([12-concurrency.md](12-concurrency.md) §12.6).

## 2.5 Creation rules

- A directory exists only once it holds a file.
  No `.gitkeep`, no empty placeholder files.
- A required singleton with nothing to say yet contains its skeleton headings and, where its skeleton says so, `None recorded as of YYYY-MM-DD.`
- Nothing named `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` or `AGENTS.override.md` may exist under `docs/mkb/`.
- Records, `project/ARCHITECTURE.md` and `project/CONVENTIONS.md` are created by copying their skeleton from `docs/mkb/templates/`.
- Guide comments have the exact form `<!-- guide: ... -->`; whoever creates a real file from a skeleton MUST delete every guide comment and every optional section that stays empty.
- A new TASK, ADR or Q file takes its number as described in [04-naming-and-linking.md](04-naming-and-linking.md) §4.3.
- Adoption never overwrites existing files ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.1).

## 2.6 Deviations from the original brief

The brief proposed a directory structure and allowed changes "only when there is a strong reason"; this table lists every change and its reason.

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

Files that the brief proposed and that v1.0 does NOT use: `tasks/TODO.md`, `tasks/IN-PROGRESS.md`, `tasks/BLOCKED.md`, `tasks/DONE.md`, `state/BLOCKERS.md`, `questions/OPEN.md`, `agents/CODEX.md`, `agents/CLAUDE.md`, `handoff/CURRENT.md`, `handoff/HISTORY.md`.
