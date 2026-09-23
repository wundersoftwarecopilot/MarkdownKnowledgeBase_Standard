---
id: TASK-002
type: task
status: done
priority: high
owner: claude-code
branch: claude-code/task-002-wi200-parser
created: 2026-09-01
closed: 2026-09-03
related: [SERVICE-GATEWAY, INT-WI200, TASK-006]
code: [src/tarelog/gateway/]
---
# TASK-002: Parse WI-200 frames with a real parser

## Goal
Replace the regular expression in `src/tarelog/gateway/reader.py` with a frame parser that works on the byte stream, so that lane 2 readings are no longer dropped.
Out of scope: changing indicator or converter settings.

## Acceptance criteria
- [x] Frames split across TCP reads are reassembled; lane 2 readings are stored again.
- [x] `US` frames are never stored.
- [x] A malformed frame raises `FrameError` and the parser resynchronizes at the next STX.
- [x] Recorded captures from both lanes in `tests/fixtures/wi200/` pass.

## Notes
- 2026-09-02 claude-code: readings are also lost while the report job holds the SQLite write lock; out of scope, tracked as TASK-006.

## Completion
- 2026-09-03 claude-code: done in PR #12
- Shipped: `src/tarelog/gateway/wi200.py` (`parse_frame()`) with one byte buffer per lane, used by `src/tarelog/gateway/reader.py`; captures from both lanes as fixtures.
- Docs: INT-WI200 (new), SERVICE-GATEWAY
- Follow-ups: TASK-006
- Deviations: none
