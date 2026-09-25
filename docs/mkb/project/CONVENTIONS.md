# Conventions: MKB Standard

Normative project rules that tooling and `CONTRIBUTING.md` do not already enforce or state; link to them instead of copying.
Changes need a human's approval in review.

## Code
- Shared MKB files are edited only under `templates/full/docs/mkb/` (`agents/RULES.md`, `templates/`, `tools/mkb-check.sh`) and then copied byte for byte to `templates/minimal/docs/mkb/`, `examples/tarelog/docs/mkb/` and this repository's `docs/mkb/`; `dev/DESIGN-CONTRACT.md` section R.1 lists every identity requirement.
- The agent block between `<!-- MKB:BEGIN v1.0 -->` and `<!-- MKB:END -->` is identical in `agent-instructions/AGENTS.tmpl.md`, `examples/tarelog/AGENTS.tmpl.md` and the root `AGENTS.md`.
- The only files named `AGENTS.md` or `CLAUDE.md` are the two at the repository root, which wire this repository's own MKB; copy-ready versions elsewhere use `.tmpl.md`.
- Text follows the style guide in `dev/DESIGN-CONTRACT.md` section S: US English, one sentence per line, RFC 2119 keywords only when normative, version string `MKB Standard v1.0`.

## Tests
- Every change to `mkb-check.sh` adds or updates a case in `dev/mkb-check-tests/run-tests.sh`, and the whole suite passes before the commit.
- Before a commit that changes the standard, run every command in [project/OVERVIEW.md](OVERVIEW.md), section Commands.

## Branches and commits
- Trunk-based work on `main` (minimal profile): commit at every milestone; push to `origin` only when claudio asks, so until then the local commit is the only copy.
- Commit subjects start with the task ID (`TASK-NNN: <summary>`), or with `mkb:` for MKB-only changes.

## Reviews and merging
- claudio reviews and approves; there are no pull requests.
