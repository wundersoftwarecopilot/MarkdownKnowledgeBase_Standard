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
4. How to read and write the MKB: [agents/RULES.md](agents/RULES.md); `git grep -n "^## " -- docs/mkb/agents/RULES.md` lists its sections, read only the one you need, and section 16, Project-specific rules, every session.

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
- What the system must do: project/CONSTRAINTS.md, then accepted ADRs (a superseding ADR wins), then project/CONVENTIONS.md, then the task's acceptance criteria.
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
