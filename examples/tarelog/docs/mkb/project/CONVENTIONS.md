# Conventions: TareLog

Normative project rules that tooling and `CONTRIBUTING.md` do not already enforce or state; link to them instead of copying.
Changes need a human's approval in review.

## Code
- Python style, formatting and type hints follow `CONTRIBUTING.md` (Style); ruff enforces them.
- Weights are `int` kilograms from the frame parser to the CSV file; never floats, never grams.
- Timestamps are timezone-aware `datetime` values in UTC; only `src/tarelog/web/` and `src/tarelog/reports/` convert them to quarry-local time.
- All database access goes through `src/tarelog/tickets/store.py`; no other module opens `data/tarelog.db`.
- Configuration comes from `/etc/tarelog/tarelog.toml`, read once at start-up; secrets come from the host vault by path, never from the TOML file.
- Services log with `logging.getLogger(__name__)`, one line per event; never `print()`.

## Tests
- Tests live in `tests/`, mirroring `src/tarelog/`; `pytest` passes offline, without indicators or network.
- Tests that need the WI-200 simulator carry `@pytest.mark.sim`; tests that need a real indicator carry `@pytest.mark.hardware`, run only on the weighbridge PC and never in CI.
- Every parser bug fix adds the offending capture to `tests/fixtures/wi200/`.
- Tests never open `data/tarelog.db`; the `tmp_db` fixture applies all migrations to a temporary file.
- Report changes are checked against the golden CSV files in `tests/reports/golden/`.

## Branches and commits
- Default branch `main`; work branches `<actor>/task-nnn-<slug>`; commit subjects start with the task ID ([agents/RULES.md](../agents/RULES.md), section 4).
- Changes without a task use a short imperative subject with the component as prefix, for example `gateway: log converter reconnects`.
- Releases are tags such as `v0.9.0` on `main`, made by marta or luca.

## Reviews and merging
- marta reviews every PR; luca reviews marta's PRs.
- Merge method: merge commit, never squash, so the history of a branch stays reachable after it merges.
- Required checks: `pytest` and ruff; the `mkb-check.sh` CI job is advisory and never blocks a merge.
- A PR that changes the CSV columns or the SFTP upload needs marta's approval, because she agrees such changes with Beta Haulage.
