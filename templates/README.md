# MKB templates

*MKB Standard v1.0 · 2026-09-23 · Informative*

This directory holds the two MKB profiles, ready to copy into a project, and the `.gitattributes` lines that go with them; the commands below copy a profile without overwriting any existing file.
Choosing a profile, and moving a project from minimal to full without moving any file: [spec/11-profiles.md](../spec/11-profiles.md) §11.1 and §11.6; the whole adoption procedure: [spec/13-adoption-and-integration.md](../spec/13-adoption-and-integration.md) §13.1.

## Profile contents

Both [minimal/](minimal/) and [full/](full/) contain, under `docs/mkb/`: `INDEX.md`, `agents/RULES.md`, `project/OVERVIEW.md`, `project/CONSTRAINTS.md`, `state/CURRENT.md`, `state/NEXT.md`, `templates/` and `tools/mkb-check.sh`, identical in both profiles except `INDEX.md`, which says `profile: minimal` or `profile: full` and lists ARCHITECTURE and CONVENTIONS as "when needed" in the minimal profile.
The full profile also contains `project/ARCHITECTURE.md` and `project/CONVENTIONS.md`, byte-identical to their templates; a minimal project creates them when first needed by copying `docs/mkb/templates/ARCHITECTURE.md` and `docs/mkb/templates/CONVENTIONS.md`.
`templates/` holds 11 files: the 9 record templates (`TASK.md`, `ADR.md`, `QUESTION.md`, `HANDOFF.md`, `MODULE.md`, `SERVICE.md`, `DB.md`, `INT.md`, `TS.md`) plus `ARCHITECTURE.md` and `CONVENTIONS.md`.
A new record is a copy of its template named after its ID, for example `docs/mkb/templates/TASK.md` copied to `docs/mkb/tasks/TASK-NNN.md`.

## Adoption commands

Run from the root of the standard repository; `<profile>` is `minimal` or `full`; the target repository path is in `REPO` (sh) or `$repo` (PowerShell).
Example: set `REPO=../tarelog` or `$repo = "../tarelog"`, and write `templates/full/docs/mkb` where the commands say `templates/<profile>/docs/mkb`.

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

## Upgrade commands

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

Never copy `templates/<profile>/.` over a repository: it would overwrite filled files.
These commands never touch INDEX, `project/`, `state/` or records; the rest of an upgrade (the agent block, RULES.md above section 16, `mkb_version`) is in [spec/13-adoption-and-integration.md](../spec/13-adoption-and-integration.md) §13.8.

## gitattributes-mkb.txt

[gitattributes-mkb.txt](gitattributes-mkb.txt) holds a comment line and three rules that give `docs/mkb/**`, `AGENTS.md` and `CLAUDE.md` LF line endings (`text eol=lf`); the adoption commands append each of its lines to the project's `.gitattributes` only where absent.
It is not named `.gitattributes`, so it is not active here, and no profile ships a `.gitattributes`: copying one would overwrite the adopter's own file (LFS filters and other rules).

## Placeholders and guide comments

When you create a real file from a template, or fill a singleton copied with a profile, replace every placeholder (table below; `mkb-check.sh` reports a placeholder date, handle or ID left in front matter as error E3) and:

- Delete every guide comment, which has the exact form `<!-- guide: ... -->`; `mkb-check.sh` warns (W11) about any left outside `docs/mkb/templates/`.
- Delete every optional section that stays empty (its guide comment says "optional"); a task's `## Notes` and `## Completion` headings always stay.
- Delete optional front matter keys that have no value, such as `related` or `code`; never write `key:` empty or `key: []` ([spec/03-metadata.md](../spec/03-metadata.md) §3.2).
- Keep the lines that describe an entry format, such as `Entry format: ...` in `project/CONSTRAINTS.md` and `state/NEXT.md`; their placeholders describe the format.
- Never fill `docs/mkb/templates/` itself: the templates stay skeletons, `mkb-check.sh` does not check them, and only an MKB version upgrade replaces them.

| Placeholder | Replace with |
|---|---|
| `<handle>`, `<human handle who must answer>` | A lowercase handle without `@`, such as `marta` or `claude-code` ([spec/03-metadata.md](../spec/03-metadata.md) §3.4). |
| `TASK-NNN`, `ADR-NNN`, `Q-NNN` | The next free ID from `sh docs/mkb/tools/mkb-check.sh next TASK` (or `ADR`, `Q`) ([spec/04-naming-and-linking.md](../spec/04-naming-and-linking.md) §4.3). |
| `MODULE-<NAME>`, `SERVICE-<NAME>`, `DB-<NAME>`, `INT-<NAME>`, `TS-<NAME>` | A knowledge ID such as `INT-WI200` ([spec/04-naming-and-linking.md](../spec/04-naming-and-linking.md) §4.5). |
| `YYYY-MM-DD` | A date such as `2026-09-23`, unquoted in front matter. |
| `<path>/`, `<path>` | A repo-root-relative path; a directory ends with `/`. |
| `<ID>`, `<ID or ->` | An MKB ID or an external tracker key; `-` in the Doc column of ARCHITECTURE when there is none. |
| Any other `<...>` | The text it describes, for example `<Project name>`, `<branch>`, `<imperative title>` or `<exact error text>`. |

## Agent instruction files

The profiles contain no `AGENTS.md` or `CLAUDE.md`: those come from [agent-instructions/](../agent-instructions/) and are renamed on copy, `AGENTS.tmpl.md` -> `AGENTS.md` and `CLAUDE.tmpl.md` -> `CLAUDE.md` (steps for each tool: [agent-instructions/README.md](../agent-instructions/README.md)).
A project that already has a root `AGENTS.md` receives only the block between `<!-- MKB:BEGIN v1.0 -->` and `<!-- MKB:END -->`; an existing root `CLAUDE.md` gets `@AGENTS.md` as its first line.
