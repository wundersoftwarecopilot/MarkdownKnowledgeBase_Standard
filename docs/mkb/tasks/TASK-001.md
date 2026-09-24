---
id: TASK-001
type: task
status: in-progress
priority: high
owner: claude-code
branch: main
created: 2026-09-23
related: [Q-001]
code: [spec/, templates/, agent-instructions/, examples/, README.md]
---
# TASK-001: Apply review round 1 to MKB Standard v1.0

## Goal
Fix the problems that review round 1 confirmed in the first complete draft (commit `7a880f9`), so that the standard can be adopted in other repositories.
Every finding, with its evidence, verdict and verified fix, is in `dev/review-round-1.json`.
Out of scope: features the brief does not ask for.

## Acceptance criteria
- [ ] The 7 findings with `verdict: not-run` (F16, F25, F57, F58, F59, F60, F62) are verified, and their verdicts are recorded in `dev/review-round-1.json`.
- [ ] Every confirmed finding is fixed, or skipped with a one-line reason under Completion.
- [ ] The copies of `agents/RULES.md`, `templates/` and `tools/` in `templates/minimal/docs/mkb/`, `examples/tarelog/docs/mkb/` and `docs/mkb/` are byte-identical to `templates/full/docs/mkb/` again.
- [ ] `python dev/check_links.py .` reports 0 errors, and the example passes the checker with `--strict` with 0 errors and 0 warnings.
- [ ] `sh dev/mkb-check-tests/run-tests.sh` reports 0 failures, and `sh docs/mkb/tools/mkb-check.sh` reports 0 errors on this repository.
- [ ] Every verification item of `dev/DESIGN-CONTRACT.md` section R.5 passes; item 1 excludes the root `AGENTS.md` and `CLAUDE.md` of this repository.

## Notes
- 2026-09-23 claude-code: the review workflow stopped at the session limit after verification; no fix has been applied yet.
- 2026-09-24 claude-code: fixes run as five area clusters in parallel, then integration, independent audit per cluster and repair; `dev/DESIGN-CONTRACT.md` is left frozen and the spec is authoritative.

## Completion
