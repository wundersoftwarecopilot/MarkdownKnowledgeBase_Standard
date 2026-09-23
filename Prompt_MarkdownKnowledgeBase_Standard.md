Create a reusable project documentation standard called **Markdown Knowledge Base (MKB)**.

The goal is to establish a consistent, agent-friendly documentation architecture for software projects worked on by AI coding agents such as Codex, Claude Code, Cursor, and other autonomous or semi-autonomous agents.

## Core concept

Do NOT create one large `Handoff.md` file.

Instead, create a structured, modular, Git-versioned **Markdown Knowledge Base** where project knowledge is divided into small, purpose-specific Markdown documents.

The system must distinguish between:

- permanent project knowledge
- architectural decisions
- technical documentation
- current project state
- tasks
- blockers
- open questions
- agent instructions
- session handoffs

The documentation itself should become the persistent memory of the project.

A handoff should only communicate what changed, what is currently relevant, and what the next agent should know. It must NOT duplicate the entire project knowledge base.

## Design principles

The MKB must be:

1. **Agent-first**
   - Optimized for AI coding agents.
   - Agents should be able to discover relevant information without reading the entire documentation tree.

2. **Human-readable**
   - Plain Markdown.
   - Easy to edit manually.
   - No proprietary database format.

3. **Git-native**
   - Every document is version-controlled.
   - Changes to knowledge are visible in Git history.

4. **Modular**
   - Avoid giant Markdown files.
   - Each document should have one clear responsibility.

5. **Discoverable**
   - Provide a central index.
   - Documents must contain metadata and cross-references where useful.

6. **Incremental**
   - Agents should update only the documents affected by their work.

7. **Auditable**
   - Important architectural and project decisions must have a durable record.

8. **Tool-independent**
   - The standard must work with Codex, Claude Code, Cursor, Gemini CLI, Aider, and human developers.

## Proposed directory structure

Create the following standard structure, adapting names only when there is a strong reason:

```text
docs/
└── mkb/
    ├── INDEX.md
    │
    ├── project/
    │   ├── OVERVIEW.md
    │   ├── ARCHITECTURE.md
    │   ├── CONSTRAINTS.md
    │   └── CONVENTIONS.md
    │
    ├── decisions/
    │   ├── ADR-001.md
    │   ├── ADR-002.md
    │   └── ...
    │
    ├── tasks/
    │   ├── TODO.md
    │   ├── IN-PROGRESS.md
    │   ├── BLOCKED.md
    │   └── DONE.md
    │
    ├── knowledge/
    │   ├── troubleshooting/
    │   ├── modules/
    │   ├── services/
    │   ├── database/
    │   └── integrations/
    │
    ├── state/
    │   ├── CURRENT.md
    │   ├── BLOCKERS.md
    │   └── NEXT.md
    │
    ├── questions/
    │   └── OPEN.md
    │
    ├── agents/
    │   ├── RULES.md
    │   ├── CODEX.md
    │   └── CLAUDE.md
    │
    └── handoff/
        ├── CURRENT.md
        └── HISTORY.md
```

Do not blindly create every file if the project does not need it. Define which parts are mandatory and which are optional.

## Metadata standard

Define a consistent YAML front matter format for documents where metadata is useful.

For example:

```yaml
---
id: TASK-042
type: task
status: in-progress
priority: high
owner: codex
created: 2026-09-23
updated: 2026-09-23
related:
  - ADR-007
  - MODULE-ORDER
---
```

Define a controlled vocabulary for:

- `type`
- `status`
- `priority`
- `owner`

Do not introduce metadata that provides little practical value.

## INDEX.md

Define `INDEX.md` as the entry point for the entire MKB.

It should explain:

- what the MKB is
- how the documentation is organized
- where an agent should look for different types of information
- which documents are authoritative
- how agents should update the MKB

The INDEX should function as a navigation map rather than duplicating the actual knowledge.

## Agent workflow

Define a standard workflow that every AI agent should follow.

### Before modifying code

The agent should:

1. Read `docs/mkb/INDEX.md`.
2. Identify the relevant project/module documentation.
3. Check relevant decisions.
4. Check current state and blockers.
5. Check related tasks.
6. Avoid reading unrelated documentation unnecessarily.

### While working

The agent should:

- update task state when appropriate
- record important discoveries
- record architectural decisions
- avoid documenting trivial implementation details
- avoid duplicating existing knowledge
- link related documents instead of copying content

### After working

The agent should:

1. Update the relevant knowledge documents.
2. Update task status.
3. Record new decisions if necessary.
4. Update blockers if necessary.
5. Update `state/CURRENT.md`.
6. Update `state/NEXT.md`.
7. Create/update the handoff only with information relevant to the next agent/session.

## Handoff design

Define a strict distinction between:

### Knowledge

Long-lived information that should remain useful after the current task.

Store it in the appropriate MKB document.

### State

Information about the current condition of the project.

Store it under `state/`.

### Handoff

Information specifically intended to transfer context from one agent/session to another.

Store it under `handoff/`.

The handoff should NOT become a duplicate of the knowledge base.

## Decision records

Use an ADR-style format for important decisions.

Each decision should contain:

- context
- problem
- decision
- alternatives considered
- consequences
- date
- related components/tasks

Define when an agent should create an ADR and when it should NOT.

## Task model

Define a simple task format that supports:

- unique IDs
- status
- priority
- owner
- description
- acceptance criteria
- related files/components
- related decisions
- completion notes

Avoid turning the Markdown task system into an unnecessarily complex project-management system.

## Linking and references

Define conventions for cross-referencing:

- tasks
- decisions
- modules
- services
- documents
- external resources

Prefer stable IDs over fragile references where appropriate.

For example:

```text
TASK-042
ADR-007
MODULE-ORDER
SERVICE-API
```

Explain when IDs should be used and when normal Markdown links are sufficient.

## Lifecycle rules

Define rules for:

- creating documents
- updating documents
- archiving documents
- deleting obsolete information
- resolving questions
- closing tasks
- superseding decisions

The MKB must actively prevent documentation rot.

## Anti-patterns

Explicitly document what agents must NOT do.

Examples:

- Do not create one giant `Handoff.md`.
- Do not duplicate the same information in multiple documents.
- Do not document every code change.
- Do not create an ADR for trivial implementation choices.
- Do not leave stale "current state" information indefinitely.
- Do not create dozens of unnecessary Markdown files.
- Do not use documentation as a replacement for the actual source code.
- Do not make the agent read the entire MKB for every task.

## Agent instruction

Create a concise section that can eventually be copied into `AGENTS.md`, `CLAUDE.md`, or similar agent instruction files.

It should tell an AI coding agent:

> The repository uses a Markdown Knowledge Base. Before significant work, discover the relevant MKB documents. Treat the MKB as persistent project memory. Update it when your work changes project knowledge, decisions, state, tasks, blockers, or next steps. Do not duplicate information unnecessarily.

Improve this wording and make it operational rather than merely descriptive.

## Deliverables

Do not merely create example Markdown files.

Create a complete **MKB Standard** that another developer can adopt in a completely different software project.

The deliverables should include:

1. A specification explaining the MKB architecture.
2. The canonical directory structure.
3. Document templates.
4. Metadata conventions.
5. Naming conventions.
6. Agent workflow.
7. Handoff rules.
8. ADR rules.
9. Task rules.
10. Lifecycle and archival rules.
11. Anti-patterns.
12. A minimal version for small projects.
13. A full version for large multi-agent projects.
14. Agent instructions suitable for `AGENTS.md` / `CLAUDE.md`.
15. At least one realistic example showing multiple agents working on the same project and updating the MKB.

## Important

Before implementing anything, inspect the existing repository.

Do NOT overwrite or restructure existing project documentation blindly.

If the repository already has documentation conventions, preserve useful existing information and explain how the MKB standard should integrate with them.

The final result should be practical enough that a team could adopt it as an internal standard for **Codex + Claude Code + human developers working concurrently on the same repository**.

Prefer simplicity over bureaucracy.

The goal is not "more documentation".

The goal is to create a **persistent, structured, discoverable project memory for both humans and AI agents**.