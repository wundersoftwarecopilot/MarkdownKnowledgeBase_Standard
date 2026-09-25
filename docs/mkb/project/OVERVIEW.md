# Overview: MKB Standard

## Purpose
This repository defines the Markdown Knowledge Base (MKB) Standard v1.0: a Git-native, file-per-record project memory for repositories where Codex, Claude Code and humans work concurrently.
The requirements are in `Prompt_MarkdownKnowledgeBase_Standard.md` (the brief); what the standard is and how to adopt it is in `README.md`.
This `docs/mkb/` is the repository's own MKB (minimal profile), used to track the work on the standard itself.

## Users and scope
Users: developers and AI coding agents who adopt MKB in other repositories.
In scope: the specification (`spec/`), the copy-ready profiles (`templates/`), the agent instruction files (`agent-instructions/`), the TareLog example (`examples/tarelog/`) and the checker `mkb-check.sh`.
Out of scope: tooling beyond the checker; monorepos with several MKBs (`spec/01-architecture.md`, section 1.1).

## Stack
- Markdown (GFM) with the MKB YAML front matter subset (`spec/03-metadata.md`).
- `mkb-check.sh`: POSIX sh, awk and git; its source is `templates/full/docs/mkb/tools/mkb-check.sh`.
- Development aids in `dev/`: `check_links.py` (Python 3.11 with PyYAML), the checker test suite `mkb-check-tests/`, the design contract `DESIGN-CONTRACT.md` and the review data `review-round-1.json`.
- Windows 11 with Git Bash; default branch `main`; remote `origin`: https://github.com/wundersoftwarecopilot/MarkdownKnowledgeBase_Standard (public; over HTTPS, the SSH key of this PC is not registered on GitHub).

## Commands
- Links, anchors and front matter of every Markdown file: `python dev/check_links.py .`
- Checker on the example: `sh templates/full/docs/mkb/tools/mkb-check.sh --root examples/tarelog --no-git --today 2026-09-23 --strict`
- Checker test suite (several minutes; no per-case filter): `sh dev/mkb-check-tests/run-tests.sh`; a first argument such as `dash` runs the checker under that shell, and `CHK=<path>` tests another copy of the checker.
- Checker on any tree, for example a hand-made fixture: `sh templates/full/docs/mkb/tools/mkb-check.sh --root <dir> --no-git --today YYYY-MM-DD`
- Checker on this repository's own MKB: `sh docs/mkb/tools/mkb-check.sh`; next free ID: `sh docs/mkb/tools/mkb-check.sh next TASK` (or `Q`, `ADR`).
- Re-copy the shared files after editing them under `templates/full/docs/mkb/`: `for d in templates/minimal/docs/mkb examples/tarelog/docs/mkb docs/mkb; do cp templates/full/docs/mkb/agents/RULES.md $d/agents/; cp templates/full/docs/mkb/tools/mkb-check.sh $d/tools/; cp templates/full/docs/mkb/templates/*.md $d/templates/; done`

## Glossary
- **Brief**: `Prompt_MarkdownKnowledgeBase_Standard.md`, the original requirements.
- **Design contract**: `dev/DESIGN-CONTRACT.md`, the decisions every writer of the first draft (`7a880f9`) followed; section R lists the deliverables and their verification, section S the style guide. It is a frozen record: where it disagrees with `spec/`, the spec wins.
- **Finding**: an item `F01` to `F63` of `dev/review-round-1.json`, with evidence, verdict and verified fix.
