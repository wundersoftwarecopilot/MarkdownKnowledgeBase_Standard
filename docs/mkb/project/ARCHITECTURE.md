---
type: architecture
verified: 2026-09-24
---
# Architecture: MKB Standard

## System context
The product is a set of files, not a running system.
Its users are teams that adopt MKB in their own repositories: humans and agents such as Codex, Claude Code, Cursor, Gemini CLI, Aider, GitHub Copilot and Windsurf.
They copy one profile into their `docs/mkb/`, paste the agent block into their root `AGENTS.md` and run the checker.
The requirements come from the brief `Prompt_MarkdownKnowledgeBase_Standard.md`; there are no external systems.

## Components
| Component | Responsibility | Code | Doc |
|---|---|---|---|
| Specification | Normative rules in 13 chapters; each rule has one home chapter and other files cite it as `NN-name.md §N.M` instead of restating it | `spec/` | - |
| Rulebook | The rules condensed for agents in 16 self-contained sections, read one at a time; at most 500 lines above section 16 | `templates/full/docs/mkb/agents/RULES.md` | - |
| Agent block | The operational block between `<!-- MKB:BEGIN v1.0 -->` and `<!-- MKB:END -->`, at most 35 lines, pasted into an adopter's root `AGENTS.md` | `agent-instructions/AGENTS.tmpl.md` | - |
| Tool wiring | The `CLAUDE.md` import, pointer files for Cursor, Gemini CLI, Aider and Copilot, and the per-tool facts table with verification dates | `agent-instructions/` | - |
| Profiles | Copy-ready `docs/mkb/` trees; minimal lacks project/ARCHITECTURE.md and project/CONVENTIONS.md, and its INDEX differs from the full one only as spec/02 §2.4.4 lists | `templates/minimal/`, `templates/full/` | - |
| Record templates | The 11 skeletons copied when a record or project doc is created | `templates/full/docs/mkb/templates/` | - |
| Checker | POSIX sh around one awk program: errors E1-E5, warnings W1-W17 and the `next` ID allocator, specified in spec/09 §9.7 | `templates/full/docs/mkb/tools/mkb-check.sh` | - |
| Worked example | TareLog's MKB after eight sessions by two humans, Claude Code and Codex; `WALKTHROUGH.md` quotes its files | `examples/tarelog/` | - |
| Development aids | Link checker, checker test suite, frozen design contract, review round 1 data | `dev/` | - |
| Own MKB | Tracks the work on the standard itself (minimal profile) | `docs/mkb/` | - |

## Data flow
1. A rule change: edit the rule's home chapter in `spec/`, then every restatement of it (RULES.md, the agent block, INDEX templates, `README.md`, `templates/README.md`, `agent-instructions/README.md`, the example and its walkthrough), re-copy the shared files and run every command in [project/OVERVIEW.md](OVERVIEW.md), section Commands.
2. A checker change: edit `templates/full/docs/mkb/tools/mkb-check.sh`, add or update a case in `dev/mkb-check-tests/run-tests.sh`, update spec/09 §9.7 (and spec/03 for a front matter rule), re-copy, then run the suite and the example check.
3. An adoption elsewhere, which is what the standard ships: the commands in `templates/README.md` copy one profile into the target repository, and `agent-instructions/` supplies its `AGENTS.md` block and `CLAUDE.md`.

## Deployment
Nothing runs: the standard is published as the files of this repository, public on GitHub at https://github.com/wundersoftwarecopilot/MarkdownKnowledgeBase_Standard (remote `origin`).
The version is the string `MKB Standard v1.0` in status lines, `mkb_version: "1.0"` in INDEX and RULES, and `v1.0` in the agent block markers.

## Cross-cutting concerns
- Byte-identical copies and who edits which side: [project/CONVENTIONS.md](CONVENTIONS.md), section Code.
- Size budgets: spec/02 §2.3; the checker itself stays within 450 lines.
- Fixed dates: the status line of every spec chapter and README says `2026-09-23`, and example checks pass `--today 2026-09-23`, so age warnings stay reproducible; do not update them to today.
- Tool facts carry the date they were verified; re-check official documentation before changing one (spec/13 §13.5).
