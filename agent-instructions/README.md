# Agent instruction files

*MKB Standard v1.0 · 2026-09-23 · Informative*

This directory holds the copy-ready files that wire AI coding agents to the MKB.
The normative home of this material is [spec/13-adoption-and-integration.md](../spec/13-adoption-and-integration.md) §13.5; this page repeats its tables for adopters.
The copy-ready source of the MKB block is [AGENTS.tmpl.md](AGENTS.tmpl.md); spec chapters refer to that file instead of quoting the block.

## Files

| File | Copy to | When |
|---|---|---|
| [AGENTS.tmpl.md](AGENTS.tmpl.md) | `AGENTS.md` | always |
| [CLAUDE.tmpl.md](CLAUDE.tmpl.md) | `CLAUDE.md` | if Claude Code is used |
| [gemini/settings.json](gemini/settings.json) | `.gemini/settings.json` | if Gemini CLI is used |
| [aider/.aider.conf.yml](aider/.aider.conf.yml) | `.aider.conf.yml` | if Aider is used |
| [cursor/mkb.mdc](cursor/mkb.mdc) | `.cursor/rules/mkb.mdc` | optional pointer, only if the team needs it |
| [copilot/copilot-instructions.md](copilot/copilot-instructions.md) | `.github/copilot-instructions.md` | optional pointer, only if the team needs it |

"Copy to" paths are relative to the root of the adopting repository.
Rename on copy: `AGENTS.tmpl.md` -> `AGENTS.md`, `CLAUDE.tmpl.md` -> `CLAUDE.md`.
Why `.tmpl.md`: Claude Code loads nested `CLAUDE.md` files, and Codex, Cursor and Copilot load nested `AGENTS.md` files, as instructions; real names anywhere in this repository would inject MKB instructions into sessions working on the standard itself.

## Recommended wiring

1. The block inline in root `AGENTS.md`, once.
2. Root `CLAUDE.md` = `@AGENTS.md` plus Claude-only notes.
3. `.gemini/settings.json` if Gemini CLI is used.
4. `.aider.conf.yml` if Aider is used.
5. No `.cursor/rules/mkb.mdc` and no `.github/copilot-instructions.md` unless the team needs them (both optional pointers).
6. Re-check tool behavior at gardening when tool versions change; tool loading rules change between versions.
7. Give local agents the network and git permissions of section What coordination commits need from a local agent tool, and check them at adoption.

## Installing

These steps carry out step 5 of the adoption procedure and the agent-file rows of the integration table in [spec/13-adoption-and-integration.md](../spec/13-adoption-and-integration.md) §13.1 and §13.2; nothing existing is overwritten.

Root `AGENTS.md`:

1. No root `AGENTS.md` yet: copy `AGENTS.tmpl.md` to the repository root as `AGENTS.md`.
2. Root `AGENTS.md` exists: keep it, and insert the MKB block of `AGENTS.tmpl.md`, from the line `<!-- MKB:BEGIN v1.0 -->` through the line `<!-- MKB:END -->`, below its project notes; project-specific agent notes (build, test, style) stay above the block.
3. Move project knowledge found in the existing file (architecture, module notes, status) into the MKB, leaving commands and style rules.
4. Never edit the text between the markers. Adopters whose default branch is not named `main` replace `main` in the block's commands, as in RULES.md and INDEX.md; that is the only edit allowed.
5. A root `AGENTS.override.md` exists: Codex skips root `AGENTS.md` there; put the block in the override file or remove the override.
6. An MKB version upgrade replaces the block between the markers whole: [spec/13-adoption-and-integration.md](../spec/13-adoption-and-integration.md) §13.8.

Root `CLAUDE.md`:

1. No root `CLAUDE.md` yet: copy `CLAUDE.tmpl.md` to the repository root as `CLAUDE.md`.
2. Root `CLAUDE.md` exists: put the lines of `CLAUDE.tmpl.md` at its top, remove content that duplicates `AGENTS.md`, and keep Claude-only notes below them.
3. The first line is exactly `@AGENTS.md` as plain text, never inside backticks or a code block (Claude Code ignores imports there). On Windows use the import, not a symlink.
4. Keep its own content at most 20 lines; notes must be tool-neutral, or go in `AGENTS.md`, because Cursor, and possibly GitHub Copilot, also read this file.

Tool pointers and other files:

1. Copy only the pointer files that Recommended wiring calls for.
2. `.gemini/settings.json` already exists: add `AGENTS.md` to its `context.fileName` value instead of replacing the file. `.aider.conf.yml` already exists: add the three paths to its `read:` list.
3. Existing `.cursor/rules/*.mdc`, `.cursorrules`, `GEMINI.md` or `.github/copilot-instructions.md`: keep tool-specific rules; replace duplicated project rules with a one-line pointer to AGENTS.md; `.cursorrules` is legacy: move its content to AGENTS.md or `.cursor/rules/`.
4. Nothing named `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` or `AGENTS.override.md` may exist under `docs/mkb/`.
5. The adoption commands in [templates/README.md](../templates/README.md) add the `.gitattributes` lines that keep `AGENTS.md` and `CLAUDE.md` on LF line endings.

## Per-tool wiring

Facts verified 2026-09-23; UNVERIFIED marks what could not be confirmed.

| Tool | What it loads natively | MKB wiring | Status |
|---|---|---|---|
| Codex CLI, IDE extension, desktop app | In each directory from the project root down to the working directory, `AGENTS.override.md` if present, else `AGENTS.md` (at most one per directory); merged root first, later files override; stops at 32 KiB combined (`project_doc_max_bytes`). | The block in root `AGENTS.md`. If the repository has a root `AGENTS.override.md`, Codex skips root `AGENTS.md` there: put the block in the override file or remove the override. Check with `codex --ask-for-approval never "Summarize the current instructions."` | verified |
| Codex cloud | UNVERIFIED (not on the cloud doc page; only a search snippet says it reads AGENTS.md). | Same root `AGENTS.md`. The dispatching human claims the task ([spec/08-tasks-and-questions.md](../spec/08-tasks-and-questions.md) §8.4) and selects the task branch when resuming. At adoption, ask a cloud task to summarize its instructions to confirm. | UNVERIFIED |
| Claude Code | CLAUDE.md files in the working directory and above at launch (concatenated, closest last); subdirectory CLAUDE.md files on demand when Claude reads files there; `@path` imports (max 4 hops; ignored inside code spans and code blocks). Reads AGENTS.md natively only from v2.1.277, and by default only when no CLAUDE.md exists; not on Bedrock or other third-party providers, with telemetry disabled, or before v2.1.277. | Root `CLAUDE.md` whose first line is `@AGENTS.md` as plain text, then only Claude-specific notes; the docs state the import never loads the file twice. On Windows use the import, not a symlink. Never put a CLAUDE.md under `docs/mkb/`: it would load as instructions for that subtree. | verified |
| Cursor | Root `AGENTS.md` (plain Markdown); nested `AGENTS.md` for its subtree; root `CLAUDE.md` always applied; `.cursor/rules/*.mdc` with `description`, `globs`, `alwaysApply`; plain `.md` in `.cursor/rules` ignored; `.cursorrules` is legacy. | Nothing required. Optional `.cursor/rules/mkb.mdc` ([cursor/mkb.mdc](cursor/mkb.mdc)) for teams that rely on rules. Cursor sees the literal `@AGENTS.md` line of CLAUDE.md; whether it expands it is UNVERIFIED and harmless because it reads AGENTS.md anyway. | verified; import expansion UNVERIFIED |
| Gemini CLI | `GEMINI.md` (global, workspace and parents, just-in-time for accessed directories); `context.fileName` in `.gemini/settings.json` accepts a string or array; imports `@./file.md`. | `.gemini/settings.json` from [gemini/settings.json](gemini/settings.json). Check with `/memory show`. | verified |
| Aider | Nothing automatically; `/read`, `--read` or `read:` in `.aider.conf.yml`. | `.aider.conf.yml` from [aider/.aider.conf.yml](aider/.aider.conf.yml). Aider cannot run the discovery greps or claims itself: the human runs discovery (`/read` the docs found), claims and handoffs. | verified (no native discovery found) |
| GitHub Copilot on GitHub.com (cloud agent, code review, Chat) | `.github/copilot-instructions.md` (repository-wide); `.github/instructions/**/NAME.instructions.md` with `applyTo`; agent instructions from `AGENTS.md` anywhere (nearest wins) or a single root `CLAUDE.md` or `GEMINI.md`; the docs say agent instructions "are currently not supported by all Copilot features". | Nothing required for the cloud agent. Optional one-line pointer in `.github/copilot-instructions.md` ([copilot/copilot-instructions.md](copilot/copilot-instructions.md)) for features that do not read AGENTS.md; which features those are is UNVERIFIED. Which file wins when both root `AGENTS.md` and root `CLAUDE.md` exist is UNVERIFIED; the plain fallback line in `CLAUDE.md` ([CLAUDE.tmpl.md](CLAUDE.tmpl.md)) covers the case where only `CLAUDE.md` is read. At adoption, ask the Copilot agent to summarize its instructions. The cloud agent follows the dispatcher-claims rule ([spec/08-tasks-and-questions.md](../spec/08-tasks-and-questions.md) §8.4). | verified; feature coverage and AGENTS.md/CLAUDE.md precedence UNVERIFIED |
| GitHub Copilot in VS Code | Settings `chat.useAgentsMdFile`, `chat.useNestedAgentsMdFiles` (off by default), `chat.useClaudeMdFile`; `.instructions.md` files; sources are additive. | Ensure `chat.useAgentsMdFile` is enabled (its default is UNVERIFIED); leave nested files off. | partly UNVERIFIED |
| Windsurf / Devin Desktop (Cascade) | `AGENTS.md` or `agents.md`; root file always on; subdirectory file scoped to that directory; parent directories up to the git root. | Nothing required. | verified |

Size facts: Codex caps combined instructions at 32 KiB by default; Claude Code docs advise under 200 lines per file; Cursor advises under 500 lines per rule.
The block is 29 lines including its markers, well inside all three.

## What coordination commits need from a local agent tool

Every item is UNVERIFIED and is checked at adoption (section Verifying per tool).

| Tool | Needs | Status |
|---|---|---|
| Codex CLI | Network access for `git fetch` and `git push`, and writes to the system temp directory for the coordination worktree ([spec/12-concurrency.md](../spec/12-concurrency.md) §12.2). Its default sandbox may disable network access: approve those commands when asked, or enable network access for its workspace-write sandbox in its configuration (reported as `network_access = true` under `[sandbox_workspace_write]`). | UNVERIFIED |
| Claude Code | Permission to run `git fetch`, `git push` and `git worktree`, and to write in the system temp directory; allow these in its permission settings so that claims do not stall on prompts. | UNVERIFIED |
| Codex cloud, Copilot coding agent | Cannot push to the default branch: the dispatching human claims ([spec/08-tasks-and-questions.md](../spec/08-tasks-and-questions.md) §8.4) and creates the tasks and questions they request ([spec/04-naming-and-linking.md](../spec/04-naming-and-linking.md) §4.3). Network access after setup is UNVERIFIED. | UNVERIFIED |

## Verifying per tool

Run these checks at adoption, and again at gardening when a tool version changes.

| Tool | Check |
|---|---|
| Codex CLI | `codex --ask-for-approval never "Summarize the current instructions."` |
| Codex cloud | ask a cloud task to summarize its instructions |
| Claude Code | - |
| Cursor | - |
| Gemini CLI | `/memory show` |
| Aider | - |
| GitHub Copilot on GitHub.com | ask the Copilot agent to summarize its instructions |
| GitHub Copilot in VS Code | `chat.useAgentsMdFile` is enabled and nested files are off |
| Windsurf | - |

A `-` means this standard gives no check command for that tool.
For every local agent tool: have it make one real coordination commit (for example its first claim) while a human watches.
An agent that cannot fetch or push stops before coding and asks the human to push the claim ([spec/08-tasks-and-questions.md](../spec/08-tasks-and-questions.md) §8.4).
