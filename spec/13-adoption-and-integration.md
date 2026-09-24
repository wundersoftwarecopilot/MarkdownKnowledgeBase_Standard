# 13. Adoption and integration

*MKB Standard v1.0 · 2026-09-23 · Normative*

This chapter describes how to introduce the MKB into an existing repository, how it coexists with the documentation, ADRs, trackers and agent instruction files already there, and how to upgrade it.
Adoption never overwrites existing files: what exists is adopted in place, migrated once, or pointed to from `docs/mkb/INDEX.md`.

## 13.1 Adoption procedure

Choose the profile first ([11-profiles.md](11-profiles.md) §11.1); the files each profile creates at adoption are listed in [02-directory-structure.md](02-directory-structure.md) §2.2.

1. Inspect the repository: README, CONTRIBUTING, `docs/`, a site generator that builds `docs/` (GitHub Pages from `/docs`, MkDocs, Docusaurus, Sphinx), ADR directories, AGENTS.md, CLAUDE.md, `.cursor/rules`, `.cursorrules`, GEMINI.md, `.github/copilot-instructions.md`, `.gitattributes`, monolithic handoff or notes files, task lists such as `TODO.md` or `BACKLOG.md`, issue tracker usage.
2. Work on branch `<actor>/mkb-adopt`; a human reviews the PR.
3. Run the adoption commands of §13.1.1: they stop if `docs/mkb` exists, copy `templates/<profile>/docs/mkb` to `docs/mkb`, and append the lines of `templates/gitattributes-mkb.txt` to `.gitattributes` only where absent.
   Nothing existing is overwritten.
4. Fill INDEX (People and agents, Path overrides), OVERVIEW, CONSTRAINTS, CURRENT, NEXT; in the full profile also ARCHITECTURE (an agent drafts it from the code, a human reviews it) and CONVENTIONS.
   When `CONTRIBUTING.md` already covers conventions, delete `docs/mkb/project/CONVENTIONS.md` instead and add the conventions path override row with its row changes ([02-directory-structure.md](02-directory-structure.md) §2.4.5).
   Delete every guide comment.
5. Insert the MKB block into root `AGENTS.md` between its markers (create the file if missing); create or update root `CLAUDE.md`; add tool pointers only where needed (§13.5).
6. Migrate existing content (§13.2 to §13.4).
   Tasks and questions created during adoption are allocated as in [04-naming-and-linking.md](04-naming-and-linking.md) §4.3 but ride the adoption PR instead of coordination commits, because no other actor can allocate an ID before `docs/mkb` reaches the default branch.
7. Run `sh docs/mkb/tools/mkb-check.sh` (with `--adr-dir <dir>` when an ADR directory is adopted): zero errors.
   When a site generator builds `docs/`, also run the site build (§13.2.1).
8. Commit `mkb: adopt MKB v1.0 (<profile> profile)`.

Rules that also apply at adoption, each defined in its home chapter:

- Placeholders and guide comments in the copied files: [templates/README.md](../templates/README.md); a guide comment left in a real file is warning W11 ([09-lifecycle.md](09-lifecycle.md) §9.7).
- At most the 3 most-changed components get knowledge docs written from the code; nothing is bulk-generated; docs holding migrated facts are not counted (§13.3, [09-lifecycle.md](09-lifecycle.md) §9.3).
- Past decisions found in old notes become backfilled ADRs ([07-decisions.md](07-decisions.md) §7.8).
- Running the checker from PowerShell: [09-lifecycle.md](09-lifecycle.md) §9.7.
- Each local agent tool except Aider, whose claims the human makes (§13.5.3), makes one real coordination commit while a human watches (§13.5.4).

Example: TareLog adopted the full profile in session S1, on branch `claude-code/mkb-adopt` with PR #10, with an INDEX that names marta, luca, claude-code and codex and has no path override, because a CONVENTIONS.md was created for what `CONTRIBUTING.md` lacks; see [examples/tarelog/WALKTHROUGH.md](../examples/tarelog/WALKTHROUGH.md), section S1.

### 13.1.1 Copy commands

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
Never copy `templates/<profile>/.` over a repository: it would overwrite filled files.

The lines appended to `.gitattributes`, from [templates/gitattributes-mkb.txt](../templates/gitattributes-mkb.txt):

```text
# MKB: LF line endings for project memory and agent instruction files
docs/mkb/** text eol=lf
AGENTS.md text eol=lf
CLAUDE.md text eol=lf
```

They keep MKB and agent instruction files on LF line endings on every platform, which the formatting rules of [12-concurrency.md](12-concurrency.md) §12.4 need.
The profiles ship no `.gitattributes` of their own, because a copy would overwrite the adopter's file (LFS filters and other rules).

## 13.2 Integrating existing documentation

| Existing | Strategy |
|---|---|
| `README.md` | Adopt in place. It stays the human front door and wins for install and usage text. Add one line: "Project memory: `docs/mkb/INDEX.md`". OVERVIEW points to README sections and never copies them. |
| `CONTRIBUTING.md` | Adopt in place; authoritative for the contribution process. CONVENTIONS.md holds only what it lacks; if it covers everything, no CONVENTIONS.md and an INDEX override row ([02-directory-structure.md](02-directory-structure.md) §2.4). |
| Existing ADR directory (`docs/adr/`, `doc/adr/`, `docs/decisions/`; adr-tools `NNNN-slug.md`, MADR) | Adopt in place; never move or rename (external links and tooling depend on names). Everything else: §13.4. |
| A site generator that builds `docs/` (GitHub Pages from `/docs`, MkDocs, Docusaurus, Sphinx) | Exclude `docs/mkb/` from the build, or have the lead approve the exposure: §13.2.1. |
| Monolithic `Handoff.md`, `NOTES.md`, `STATUS.md`; task lists such as `TODO.md`, `BACKLOG.md` | Migrate once (§13.3). |
| `AGENTS.md` | Adopt in place; insert the MKB block between markers; move project knowledge found in it (architecture, module notes, status) into the MKB, leaving commands and style rules. |
| `CLAUDE.md` | Adopt in place; put the lines of its copy-ready form (§13.5.2) at its top; move project knowledge found in it (architecture, module notes, status) into the MKB and notes for every tool into AGENTS.md unless AGENTS.md already says them; keep Claude Code only notes. |
| `.cursor/rules/*.mdc`, `.cursorrules`, `GEMINI.md`, `.github/copilot-instructions.md` | Keep tool-specific rules; replace duplicated project rules with a one-line pointer to AGENTS.md; `.cursorrules` is legacy: move its content to AGENTS.md or `.cursor/rules/`. |
| Other docs (`docs/*.md`, runbooks, wiki) | Leave in place; add INDEX Routing rows or Path overrides pointing to them; migrate a doc into the MKB only when rewriting it anyway. |
| External issue tracker | §13.6. |

The agent instruction files and their wiring per tool are in §13.5.
Copying project knowledge into agent instruction files is anti-pattern 30 ([10-anti-patterns.md](10-anti-patterns.md)).

### 13.2.1 Documentation sites that build `docs/`

`docs/mkb/` holds tasks, questions, warnings and customer names, and MDX-based generators can fail on the templates' `<handle>` placeholders and HTML comments.
Exclude `docs/mkb/` in the generator's configuration (name the option only after checking that generator's documentation) and run the site build in the adoption PR.
If exclusion is not possible, the lead approves the exposure in the adoption PR before it merges.

Note: this standard names no exclusion option, because generators and their versions differ.

## 13.3 Migrating a monolithic Handoff.md

A monolithic `Handoff.md`, `NOTES.md` or `STATUS.md` is migrated once, then replaced by a stub; keeping one is anti-pattern 1 ([10-anti-patterns.md](10-anti-patterns.md)).

1. One session on `<actor>/mkb-adopt` (or `<actor>/mkb-migrate-handoff`), reviewed by a human; tell the team not to edit Handoff.md meanwhile (a Warnings bullet if the MKB already exists).
2. Read the whole file once and sort every paragraph:

| Paragraph content | Destination |
|---|---|
| durable fact about code, data, devices, vendors, environments | the knowledge doc of its component, device or vendor, created if missing (not counted by the adoption limit of [09-lifecycle.md](09-lifecycle.md) §9.3), or project/OVERVIEW.md or ARCHITECTURE.md |
| past significant decision | backfilled ADR ([07-decisions.md](07-decisions.md) §7.8) |
| non-negotiable rule stated by a person or document | project/CONSTRAINTS.md once a human states it in the session, citing them and the original source; otherwise a question to the lead |
| team-wide convention (code style, versioning, review) | project/CONVENTIONS.md, or `CONTRIBUTING.md` under a conventions path override; dropped where tooling or `CONTRIBUTING.md` already says the same |
| open work | tasks |
| open question | questions |
| current condition (build, deployments, known breakage) | state/CURRENT.md bullets dated with the migration date |
| priorities | state/NEXT.md (the lead confirms) |
| session narrative, logs, obsolete notes | dropped (git keeps them) |

3. Replace Handoff.md with the stub below; delete the stub at the first gardening 30 days later ([09-lifecycle.md](09-lifecycle.md) §9.6).
4. Put the paragraph-to-destination mapping in the PR description, not in the MKB.
5. A branch that still edits Handoff.md will conflict with the stub; port its new content into the MKB.

The stub:

```markdown
# Handoff.md has moved

This file was replaced by the Markdown Knowledge Base on YYYY-MM-DD; start at `docs/mkb/INDEX.md`.
Do not add content here; this stub is deleted at the first gardening after YYYY-MM-DD (30 days later).
```

The stub sends people and agents that open the old path to the INDEX, and its conflict with any branch that still edits the old file (step 5) makes a late edit loud instead of lost.
Note: `NOTES.md`, `STATUS.md` and task lists such as `TODO.md` follow the same steps (§13.2); their stub names the file it replaces, and a task list kept beside `tasks/` is anti-pattern 9 ([10-anti-patterns.md](10-anti-patterns.md)).

Example: TareLog's 600-line `Handoff.md` yielded SERVICE-GATEWAY, DB-TICKETS and TS-SQLITE-LOCKED and the backfilled ADR-001, whose Context starts `Recorded retroactively from Handoff.md on 2026-09-01.`; the full mapping table is in [examples/tarelog/WALKTHROUGH.md](../examples/tarelog/WALKTHROUGH.md), section S1.

## 13.4 Existing ADR directories

An ADR directory that exists before adoption (`docs/adr/`, `doc/adr/`, `docs/decisions/`; adr-tools `NNNN-slug.md`, MADR) is adopted in place; never move or rename it (external links and tooling depend on names).

- Old and new ADRs keep the directory's native format, file naming and numbering; no MKB front matter is added (MADR front matter would clash with the MKB schema).
- The MKB ADR rules apply ([07-decisions.md](07-decisions.md) §7.1 to §7.8: who decides, immutability, superseding); the MKB schema does not.
- New ADRs use the directory's own template; if it lacks any of Context, Problem, Decision, Alternatives considered or Consequences, add the missing ones as sections.
- Where [07-decisions.md](07-decisions.md) §7.4 and §7.8 set `deciders` and `date`, an ADR there records the deciders in its format's own deciders field if it has one, else as the line `Deciders: <handle>, <handle>` below the native status, and sets its native date the same way; the rules that name `deciders` read that field or line.
- The ID in prose is `ADR-` plus that number (`ADR-0007`) and names the file `<dir>/0007-*.md`, whose text does not contain the ID: open it with `git ls-files "<dir>/0007-*"`, because `git grep -w` for the ID finds only the docs that cite it; allocate with the adopted-directory variant of [04-naming-and-linking.md](04-naming-and-linking.md) §4.3 or `mkb-check.sh next ADR --adr-dir <dir>`.
- Legacy `Proposed` ADRs already on the default branch violate the rule that an ADR reaches the default branch only as `accepted` or `rejected` ([07-decisions.md](07-decisions.md) §7.4): the lead accepts or rejects each one during adoption.
- Because file name differs from ID, the duplicate-number check (§13.4.3) is mandatory before merges and in CI, and `mkb-check.sh` runs with `--adr-dir <that directory>` ([09-lifecycle.md](09-lifecycle.md) §9.7).

### 13.4.1 Status mapping

Native statuses read as MKB statuses:

| Native status | MKB status |
|---|---|
| `Proposed` | `proposed` |
| `Accepted` | `accepted` |
| `Rejected` | `rejected` |
| `Deprecated` | `deprecated` |
| `Superseded by N` | `superseded` |

Only `accepted` ADRs bind; the others are never authoritative ([01-architecture.md](01-architecture.md) §1.7).

### 13.4.2 INDEX rows that change

Add a path override row to INDEX (the first override row replaces the `| none | - | - |` row, [02-directory-structure.md](02-directory-structure.md) §2.4), for example for an adr-tools directory at `docs/adr/`:

```markdown
| decisions | `docs/adr/NNNN-<slug>.md` | adr-tools directory adopted in place, native format; ID ADR-NNNN is the file `docs/adr/NNNN-*.md`, whose text does not contain it; run mkb-check with `--adr-dir docs/adr` |
```

The Layout row `decisions/ADR-NNN.md` names the adopted directory; the Routing row "What must never be broken" becomes the row below; "Why something is the way it is" and "Docs about code you will touch" grep the adopted directory instead of `docs/mkb/decisions`.

```markdown
| What must never be broken | project/CONSTRAINTS.md, then accepted ADRs in `docs/adr/` | `git grep -l -i -E '^(status: *"?)?accepted' -- docs/adr` |
```

Discovery searches the adopted directory wherever it names `docs/mkb/decisions` ([05-agent-workflow.md](05-agent-workflow.md) §5.3), and the discovery item of the agent block searches the decisions directory named in INDEX (§13.5.1).
What `--adr-dir` changes in the checker's errors, warnings and `next ADR` is defined in [09-lifecycle.md](09-lifecycle.md) §9.7.

### 13.4.3 Duplicate-number check

Because the file name is not the ID, two ADRs with the same number do not collide in git; this check must print nothing:

```sh
ls docs/adr | grep -E '^[0-9][^/]*\.md$' | grep -oE '^[0-9]+' | sort | uniq -d     # must print nothing
```

```powershell
Get-ChildItem docs/adr -Name -Filter *.md | Select-String '^\d+' | ForEach-Object { $_.Matches[0].Value } | Group-Object | Where-Object Count -gt 1
```

A duplicate is an ID collision: the branch that merges second renumbers its own ADR ([04-naming-and-linking.md](04-naming-and-linking.md) §4.4).

## 13.5 Agent instruction files and per-tool wiring

The copy-ready agent files and their install steps are in [agent-instructions/](../agent-instructions/README.md); this section is their normative home.

### 13.5.1 The MKB block

The operational rules for agents are one block of at most 35 lines in root `AGENTS.md`, between the lines `<!-- MKB:BEGIN v1.0 -->` and `<!-- MKB:END -->`.
The v1.0 block is 30 lines including the markers; its text is in [agent-instructions/AGENTS.tmpl.md](../agent-instructions/AGENTS.tmpl.md) and is not repeated here.
It covers:

- Repositories without a remote (the line before item 1): `origin/main` means local `main` (§13.7).
- Before changing code (items 1 to 4): fetch and rebase, read INDEX and CURRENT, the lite path, pick the task and read its handoff, claim, discovery.
- While working (items 5 to 9): what binds, docs that contradict the code, recording discoveries, new IDs, editing MKB files safely.
- Before you stop (items 10 to 15): the trigger matrix, the handoff, blockers, done, state files, the `MKB for humans:` lines.
- A final line on secrets and on files that must never be created under `docs/mkb/`.

Rules for the block:

- Adopters whose default branch is not named `main` replace `main` in the block's commands (the only edit allowed in the block) and in INDEX.md; RULES.md is not edited, because its opening lines say that commands write the default branch as `main`.
- Project-specific agent notes (build, test, style) go above the MKB block; keep the file small, because some tools cap instruction size.
- An existing `AGENTS.md` is adopted in place (§13.2): the block is inserted between its markers.
- The block changes only when the MKB version is upgraded, and then it is replaced whole (§13.8).
- Other tools get a pointer only where they do not read AGENTS.md (§13.5.5).
- Nothing named `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` or `AGENTS.override.md` may exist under `docs/mkb/` ([02-directory-structure.md](02-directory-structure.md) §2.5).

The standard repository ships the agent files as `AGENTS.tmpl.md` and `CLAUDE.tmpl.md`, because Claude Code loads nested `CLAUDE.md` files, and Codex, Cursor and Copilot load nested `AGENTS.md` files, as instructions; real names in the standard repository would inject MKB instructions into sessions working on the standard itself.
Adopters rename on copy: `AGENTS.tmpl.md` -> `AGENTS.md`, `CLAUDE.tmpl.md` -> `CLAUDE.md`.

### 13.5.2 Root CLAUDE.md

Root `CLAUDE.md` imports `AGENTS.md`; its copy-ready form is [agent-instructions/CLAUDE.tmpl.md](../agent-instructions/CLAUDE.tmpl.md).

- The first line is exactly `@AGENTS.md` as plain text; it MUST NOT be inside backticks or a code block (Claude Code ignores imports there).
- Below it, a plain fallback line tells tools that do not expand the import to read `AGENTS.md` at the repository root and follow its section Project memory (MKB).
- Notes below it are for Claude Code only and each starts with `Claude Code only:`, because Cursor and GitHub Copilot also read this file; notes for every tool go in AGENTS.md, and AGENTS.md content is never copied into it.
- Its own content stays within 20 lines ([02-directory-structure.md](02-directory-structure.md) §2.3).

### 13.5.3 Per-tool wiring

Facts verified 2026-09-23; UNVERIFIED marks what could not be confirmed.
Tool loading rules change between versions, so the wiring is re-checked at gardening when tool versions change (§13.5.5).

| Tool | What it loads natively | MKB wiring | Status |
|---|---|---|---|
| Codex CLI, IDE extension, desktop app | In each directory from the project root down to the working directory, `AGENTS.override.md` if present, else `AGENTS.md` (at most one per directory); merged root first, later files override; stops at 32 KiB combined (`project_doc_max_bytes`). | The block in root `AGENTS.md`. If the repository has a root `AGENTS.override.md`, Codex skips root `AGENTS.md` there: put the block in the override file or remove the override. Check with `codex --ask-for-approval never "Summarize the current instructions."` | verified |
| Codex cloud | `AGENTS.md`: the cloud environments page says the agent uses it to find project-specific lint and test commands. Whether it loads the whole file as instructions, and nested files and the 32 KiB cap as Codex CLI does, is UNVERIFIED. | Same root `AGENTS.md`. The dispatching human claims the task ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4) and selects the task branch when resuming. At adoption, ask a cloud task to summarize its instructions to confirm. | verified; scope of loading UNVERIFIED |
| Claude Code | CLAUDE.md files in the working directory and above at launch (concatenated, closest last); subdirectory CLAUDE.md files on demand when Claude reads files there; `@path` imports (max 4 hops; ignored inside code spans and code blocks). Reads AGENTS.md natively only from v2.1.277, and by default only when no CLAUDE.md exists; not with the built-in `agents-md` plugin disabled, in some cases not in the first session after an upgrade from v2.1.276 or earlier, and before v2.1.281 not in some sessions, such as those on Amazon Bedrock or with telemetry disabled. | Root `CLAUDE.md` whose first line is `@AGENTS.md` as plain text, then only Claude-specific notes; the docs state the import never loads the file twice. On Windows use the import, not a symlink. Never put a CLAUDE.md under `docs/mkb/`: it would load as instructions for that subtree. Check with `/context`: root `CLAUDE.md` is listed under Memory files. | verified 2026-09-24 |
| Cursor | Root `AGENTS.md` (plain Markdown); nested `AGENTS.md` for its subtree; root `CLAUDE.md` always applied; `.cursor/rules/*.mdc` with `description`, `globs`, `alwaysApply`; plain `.md` in `.cursor/rules` ignored; `.cursorrules` is legacy. | Nothing required. Optional `.cursor/rules/mkb.mdc` (§13.5.5) for teams that rely on rules. Cursor sees the literal `@AGENTS.md` line of CLAUDE.md; whether it expands it is UNVERIFIED and harmless because it reads AGENTS.md anyway. | verified; import expansion UNVERIFIED |
| Gemini CLI | `GEMINI.md` (global, workspace and parents, just-in-time for accessed directories); `context.fileName` in `.gemini/settings.json` accepts a string or array; imports `@./file.md`. | `.gemini/settings.json` from §13.5.5. Check with `/memory show`. | verified |
| Aider | Nothing automatically; `/read`, `--read` or `read:` in `.aider.conf.yml`. | `.aider.conf.yml` from §13.5.5. Aider cannot run the discovery greps or claims itself: the human runs discovery (`/read` the docs found), claims and handoffs. | verified (no native discovery found) |
| GitHub Copilot cloud agent, and code review on GitHub.com | `.github/copilot-instructions.md` (repository-wide); `.github/instructions/**/NAME.instructions.md` with `applyTo`; the cloud agent reads `AGENTS.md` anywhere (nearest wins) or a single root `CLAUDE.md` or `GEMINI.md`; code review reads `AGENTS.md` only. | Nothing required. Which file wins when both root `AGENTS.md` and root `CLAUDE.md` exist is UNVERIFIED; the plain fallback line in `CLAUDE.md` (§13.5.2) covers the case where only `CLAUDE.md` is read. At adoption, ask the cloud agent to summarize its instructions. The cloud agent follows the dispatcher-claims rule. | verified; AGENTS.md/CLAUDE.md precedence UNVERIFIED |
| GitHub Copilot Chat on GitHub.com, Visual Studio, JetBrains IDEs, Eclipse and Xcode, and code review in VS Code, Visual Studio, JetBrains IDEs and Xcode | `.github/copilot-instructions.md`, and in some of them path-specific `.instructions.md` files; none reads `AGENTS.md`, `CLAUDE.md` or `GEMINI.md` (GitHub's [custom instructions support matrix](https://docs.github.com/en/copilot/reference/custom-instructions-support)). | The one-line pointer in `.github/copilot-instructions.md` (§13.5.5) if the team uses any of these. | verified |
| GitHub Copilot in VS Code | Settings `chat.useAgentsMdFile` (on by default), `chat.useNestedAgentsMdFiles` (off by default), `chat.useClaudeMdFile` (on by default); `.instructions.md` files; sources are additive. | Keep `chat.useAgentsMdFile` enabled; leave nested files off. | verified |
| GitHub Copilot CLI | `.github/copilot-instructions.md`; `AGENTS.md`, `CLAUDE.md` (also `.claude/CLAUDE.md`) and `GEMINI.md` in the repository root, the working directory, the directories between them and the directories of files it works on; it combines all files found, with no general precedence order. | Nothing required. Check with `/instructions`. | verified |
| Windsurf / Devin Desktop (Cascade) | `AGENTS.md` or `agents.md`; root file always on; subdirectory file scoped to that directory; parent directories up to the git root. | Nothing required. | verified |

Size facts: Codex caps combined instructions at 32 KiB by default; Claude Code docs advise under 200 lines per file; Cursor advises under 500 lines per rule.
The block is 30 lines including its markers, well inside all three.

### 13.5.4 What coordination commits need from a local agent tool

Facts verified 2026-09-23; items are UNVERIFIED unless their Status says otherwise.
Every item is checked at adoption.

| Tool | Needs | Status |
|---|---|---|
| Codex CLI | Network access for `git fetch` and `git push`, writes to the system temp directory for the coordination worktree ([12-concurrency.md](12-concurrency.md) §12.2), and writes to the repository's Git directory. Its default workspace-write sandbox keeps network access off and keeps `.git` read-only, including the Git directory that a worktree's `.git` file points to, so enabling network access (`network_access = true` under `[sandbox_workspace_write]`) is not enough: every git command that writes (`git fetch`, `git worktree`, `git add`, `git commit`, `git rebase`, `git push`) must run outside the sandbox. Approve those commands when asked, or allow them with `prefix_rule` entries with `decision = "allow"` in `~/.codex/rules/default.rules`; the recipe runs most of them as `git -C <dir> ...`, which a pattern such as `["git", "commit"]` does not match, so they need the pattern `["git", "-C"]`, which allows every `git -C` command, `reset --hard` included. | verified 2026-09-24 |
| Claude Code | Permission to run `git fetch`, `git push` and `git worktree`, and to write in the system temp directory; allow these in its permission settings so that claims do not stall on prompts. | UNVERIFIED |
| Codex cloud, Copilot coding agent | Cannot push to the default branch: the dispatching human claims ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4) and creates the tasks and questions they request ([04-naming-and-linking.md](04-naming-and-linking.md) §4.3). Codex cloud turns agent internet access off by default after the setup script (it can be enabled per environment), so `git fetch` fails there unless the dispatcher enables it; Copilot coding agent network access is UNVERIFIED. | partly UNVERIFIED |

Adoption check: have each local agent tool except Aider, whose claims the human makes (§13.5.3), make one real coordination commit (for example its first claim) while a human watches.
An agent that cannot fetch or push stops before coding and asks the human to push the claim ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4).

Example: in TareLog session S5, Luca runs Codex CLI and approves its `git fetch`, `git worktree`, `git add`, `git commit` and `git push` calls, so Codex makes its own claim of TASK-004 on `main`.

### 13.5.5 Recommended wiring

1. The block inline in root `AGENTS.md`, once.
2. Root `CLAUDE.md` = `@AGENTS.md` plus Claude-only notes.
3. `.gemini/settings.json` if Gemini CLI is used.
4. `.aider.conf.yml` if Aider is used.
5. No `.cursor/rules/mkb.mdc` and no `.github/copilot-instructions.md` unless the team needs them (both optional pointers).
6. Re-check tool behavior at gardening when tool versions change; tool loading rules change between versions.
7. Give local agents the network and git permissions of §13.5.4, and check them at adoption.

The pointer files ship in `agent-instructions/`:

| File in this repository | Copy to, in the adopting repository | When |
|---|---|---|
| [agent-instructions/gemini/settings.json](../agent-instructions/gemini/settings.json) | `.gemini/settings.json` | Gemini CLI is used |
| [agent-instructions/aider/.aider.conf.yml](../agent-instructions/aider/.aider.conf.yml) | `.aider.conf.yml` | Aider is used |
| [agent-instructions/cursor/mkb.mdc](../agent-instructions/cursor/mkb.mdc) | `.cursor/rules/mkb.mdc` | optional pointer, only if the team needs it |
| [agent-instructions/copilot/copilot-instructions.md](../agent-instructions/copilot/copilot-instructions.md) | `.github/copilot-instructions.md` | optional pointer, only if the team needs it |

Adoption never overwrites an existing file: where the destination already exists, merge the pointer into it by hand.

Example: TareLog uses Claude Code and Codex, so it wires only root `AGENTS.md` and root `CLAUDE.md`.

## 13.6 External issue trackers

If the team's tasks already live in GitHub Issues, Jira or similar, that tracker is authoritative and `tasks/` is not used; work item IDs, handoffs, claims and `state/NEXT.md` then follow [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.13.
Step 1 of §13.1 finds out whether this applies.

At adoption, add this path override row to INDEX:

```markdown
| tasks | <tracker URL> | tracker is authoritative; no tasks/ |
```

The Layout rows for `tasks/` and the Routing rows "What to work on", "Who is working on what" and "What is blocked and on what" then name the tracker and its saved queries instead of `git grep` commands ([02-directory-structure.md](02-directory-structure.md) §2.4).
Mirroring the tracker in `tasks/` is anti-pattern 33 ([10-anti-patterns.md](10-anti-patterns.md)).

## 13.7 Repositories without a remote

A repository without a remote still needs the coordination rules when several local agents work in parallel worktrees: their shared default branch is local `main`.

| Where the standard uses the remote | Without a remote | Defined in |
|---|---|---|
| `origin/main` in claim checks, status queries and board views | local `main` | [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4, §8.8 |
| `git fetch`, `git pull` and `git push` | skipped | [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4 |
| Branch checks (`git branch -r`) | `git branch` | [08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4 |
| ID allocation | step 1 (`git fetch --all`) is skipped | [04-naming-and-linking.md](04-naming-and-linking.md) §4.3 |
| Coordination commits | the temporary worktree holds a real checkout of `main`, with no fetch or push | [12-concurrency.md](12-concurrency.md) §12.2.4 |
| Session start: fetch, fast-forward to `origin/<your-branch>`, then rebase onto `origin/main` | rebase onto `main` | [05-agent-workflow.md](05-agent-workflow.md) §5.2 |

Note: git refuses to check out one branch in two worktrees, which is why the no-remote recipe first checks whether `main` is checked out elsewhere.

## 13.8 Upgrading the MKB version

An upgrade replaces only the standard parts of an adoption: the agent block, RULES.md above section 16, `docs/mkb/templates/` and `docs/mkb/tools/`.

1. Replace the block between `<!-- MKB:BEGIN v...` and `<!-- MKB:END -->` in root `AGENTS.md`.
2. Replace RULES.md above section 16 by hand (keep section 16).
3. Replace `docs/mkb/templates/` and `docs/mkb/tools/` with the upgrade commands below (they never touch INDEX, project/, state/ or records).
4. Set `mkb_version` in INDEX and RULES.
5. Make one commit `mkb: upgrade to MKB v<version>`.

Upgrade (sh, then PowerShell); `git rm` keeps the old files in history and `git add` stages the new ones for the one upgrade commit:

```sh
git -C "$REPO" rm -r -q docs/mkb/templates docs/mkb/tools
cp -R templates/<profile>/docs/mkb/templates templates/<profile>/docs/mkb/tools "$REPO/docs/mkb/"
git -C "$REPO" add docs/mkb/templates docs/mkb/tools
```

```powershell
git -C $repo rm -r -q docs/mkb/templates docs/mkb/tools
Copy-Item -Recurse templates/<profile>/docs/mkb/templates, templates/<profile>/docs/mkb/tools "$repo/docs/mkb/"
git -C $repo add docs/mkb/templates docs/mkb/tools
```

Run them from the root of the new version of the standard repository, as in §13.1.1; the warning there applies: never copy `templates/<profile>/.` over a repository.

Note: the new block arrives with `main` in its commands; a project whose default branch has another name makes its one allowed edit again (§13.5.1).
Note: moving from the minimal to the full profile is not a version upgrade and moves no file: [11-profiles.md](11-profiles.md) §11.6.
Version numbering, and the version carried in the block markers: [README.md](../README.md).
