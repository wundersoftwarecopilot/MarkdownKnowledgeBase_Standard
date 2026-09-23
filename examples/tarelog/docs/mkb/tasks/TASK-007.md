---
id: TASK-007
type: task
status: done
priority: normal
owner: claude-code
branch: claude-code/task-007-remove-chromium
created: 2026-09-10
closed: 2026-09-17
related: [ADR-003, MODULE-REPORTS]
code: [src/tarelog/reports/]
---
# TASK-007: Remove the Chromium PDF pipeline

## Goal
ADR-003 replaced PDF reports by CSV, so the headless Chromium pipeline is dead code.
Remove it from the code, the dependencies, the deployment and the docs.

## Acceptance criteria
- [x] No code renders PDF; the PDF templates and the Chromium launcher are deleted.
- [x] Chromium is gone from the dependencies and from the install steps in `README.md` (Installation).
- [x] Customers who received the PDF by e-mail receive the CSV attachment instead.
- [x] [project/ARCHITECTURE.md](../project/ARCHITECTURE.md) has no PDF renderer row and is re-verified.

## Notes

## Completion
- 2026-09-17 claude-code: done in PR #16
- Shipped: deleted `src/tarelog/reports/pdf.py` and `src/tarelog/reports/templates/`; `src/tarelog/delivery/mailer.py` attaches the CSV.
- Docs: MODULE-REPORTS, [project/ARCHITECTURE.md](../project/ARCHITECTURE.md) (whole doc re-verified), [project/OVERVIEW.md](../project/OVERVIEW.md) (Stack)
- Follow-ups: none
- Deviations: none
