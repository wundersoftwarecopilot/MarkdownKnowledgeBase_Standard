# Handoff: TASK-001

Written 2026-09-23 by claude-code on branch `main`.

## Where it stands
- `7a880f9` is the first verified draft: 0 link errors, example 0/0 with `--strict`, checker suite 187 cases passing.
- Review round 1 (7 lenses, then an adversarial check of each finding) found 50 confirmed problems (blockers F01, F02), 6 refuted, 7 not verified; it stopped at the session limit before any fix.
- No finding is fixed yet; each one's `verified_fix` in `dev/review-round-1.json` says what to change and where.

## Next steps
1. Verify the 7 `not-run` findings (all in `mkb-check.sh` except F25) and record each verdict in `dev/review-round-1.json`.
2. Fix F01 and F02 first: the claim and new-task compare-and-swap, and the PowerShell allocation pipeline (RULES.md sections 4, 5 and 11; spec chapters 04, 08 and 12).
3. Apply the other confirmed findings grouped by their `area` field; do the `cross` items last, because they touch several files.
4. Re-copy the shared files from `templates/full/docs/mkb/` (project/CONVENTIONS.md, section Code), run the acceptance checks of TASK-001, commit, close the task.

## Watch out
- The agent block may change (F09, F10, F11, F37): keep `agent-instructions/AGENTS.tmpl.md`, `examples/tarelog/AGENTS.tmpl.md` and the root `AGENTS.md` identical, at most 35 lines.
- RULES.md is at 498 of 500 lines; F13 is about that budget, so decide it before adding text to RULES.md.
- The checker suite must run outside any git work tree; `run-tests.sh` now works in `$TMPDIR`.

## Read first
- TASK-001, Q-001, `dev/review-round-1.json`, `dev/DESIGN-CONTRACT.md` sections R and S.
