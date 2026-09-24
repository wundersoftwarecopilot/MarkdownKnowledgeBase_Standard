#!/bin/sh
# Test suite for templates/full/docs/mkb/tools/mkb-check.sh (development aid, not part of the standard).
# Usage: sh run-tests.sh [shell-to-run-the-checker]   (default: sh)
SHX=${1:-sh}
CHK=${CHK:-/c/Wundev/MarkdownKnowledgeBase_MKB/templates/full/docs/mkb/tools/mkb-check.sh}
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/fixture.sh"
W=${TMPDIR:-/tmp}/mkb-check-work-$SHX-$$   # unique per run; outside any git work tree: two cases need that
rm -rf "$W"; mkdir -p "$W"
PASS=0 FAIL=0 CASE= N=0
TD=2026-09-23

clean "$W/tpl"
t() { CASE=$1; N=$((N + 1)); D=$W/c$N; cp -R "$W/tpl" "$D"; }
run() { OUT=$("$SHX" "$CHK" "$@" 2>"$W/.err"); RC=$?; ERR=$(cat "$W/.err"); }
chk() { run --root "$D" --no-git --today $TD "$@"; }
ok() { PASS=$((PASS + 1)); }
bad() { FAIL=$((FAIL + 1)); printf 'FAIL [%s] %s\n--- stdout:\n%s\n--- stderr:\n%s\n---\n' "$CASE" "$1" "$OUT" "$ERR"; }
has() { if printf '%s\n' "$OUT" | grep -qE -- "$1"; then ok; else bad "missing /$1/"; fi; }
hasnt() { if printf '%s\n' "$OUT" | grep -qE -- "$1"; then bad "unexpected /$1/"; else ok; fi; }
rc() { if [ "$RC" = "$1" ]; then ok; else bad "exit $RC, expected $1"; fi; }
cnt() { n=$(printf '%s\n' "$OUT" | grep -cE -- "$1"); if [ "$n" = "$2" ]; then ok; else bad "count of /$1/ is $n, expected $2"; fi; }
is() { if [ "$OUT" = "$1" ]; then ok; else bad "output '$OUT', expected '$1'"; fi; }
tot() { if printf '%s\n' "$OUT" | tail -n 1 | grep -qxF "mkb-check: $1 errors, $2 warnings"; then ok; else bad "totals not $1 errors, $2 warnings"; fi; }
fmt() { if printf '%s\n' "$OUT" | sed '$d' | grep -vE '^(ERROR E[1-6]|WARN W([1-9]|1[0-7])) [^ ]+: .+$' | grep -q .; then bad "malformed output line"; else ok; fi; }
# one error of code $1 on path $2 (message regex $3), nothing else, exit 1
only_err() { chk; has "^ERROR $1 docs/mkb/$2: .*$3"; cnt '^ERROR' 1; cnt '^WARN' 0; rc 1; fmt; }
# one warning of code $1 on path $2 (message regex $3), nothing else, exit 0
only_warn() { chk; has "^WARN $1 $2: .*$3"; cnt '^WARN' 1; cnt '^ERROR' 0; rc 0; fmt; }
# one error of code $1 on path $2 (message $3) plus exactly one W10 for the dangling ID $4 that the mutation creates
err_w10() { chk; has "^ERROR $1 docs/mkb/$2: .*$3"; cnt '^ERROR' 1; has "^WARN W10 [^ ]+: $4 "; cnt '^WARN' 1; rc 1; fmt; }
ed_() { f=$D/docs/mkb/$1; shift; sed -i "$@" "$f"; }
crlf() { find "$D" -name '*.md' | while IFS= read -r f; do sed -i 's/$/\r/' "$f"; done; }
gc() { GIT_AUTHOR_DATE="$1T12:00:00+00:00" GIT_COMMITTER_DATE="$1T12:00:00+00:00" git -C "$D" -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false commit -q --allow-empty -m "$2"; }
ginit() { git -C "$D" init -q -b main; git -C "$D" config core.autocrlf false; git -C "$D" add -A; gc "$1" init; }
gadd() { git -C "$D" add -A; gc "$1" "$2"; }
grun() { run --root "$D" --today $TD "$@"; }

# ---------- clean tree ----------
t clean; chk; tot 0 0; rc 0; cnt '^(ERROR|WARN)' 0
t clean-check-word; run --root "$D" --no-git --today $TD check; tot 0 0; rc 0
t clean-strict; chk --strict; tot 0 0; rc 0
t clean-crlf; crlf; chk; tot 0 0; rc 0
t clean-default-root; OUT=$(cd "$D" && "$SHX" "$CHK" --no-git --today $TD 2>/dev/null); RC=$?; tot 0 0; rc 0
t clean-default-today; chk_out=$(cd "$D" && "$SHX" "$CHK" --no-git 2>&1); OUT=$chk_out; has '^mkb-check: [0-9]+ errors, [0-9]+ warnings$'

# ---------- fenced-block rule ----------
t fence-outside; printf '%s\n' '> STALE 2000-01-01 x: y.' '<!-- guide: z -->' 'See TASK-999.' >> "$D/docs/mkb/knowledge/modules/MODULE-CORE.md"; chk
has '^WARN W8 docs/mkb/knowledge/modules/MODULE-CORE.md: '; has '^WARN W11 docs/mkb/knowledge/modules/MODULE-CORE.md: '
has '^WARN W10 docs/mkb/knowledge/modules/MODULE-CORE.md: TASK-999 '; cnt '^WARN' 3; cnt '^ERROR' 0; hasnt 'ADR-999|MODULE-NOPE'
t fence-unclosed-hides; printf '%s\n' '```text' '> STALE 2000-01-01 x: y' >> "$D/docs/mkb/knowledge/modules/MODULE-CORE.md"; chk; tot 0 0
t fence-crlf; crlf; printf '%s\r\n' '```text' '> STALE 2000-01-01 x: y' '<!-- guide: a -->' '```' '> STALE 2000-01-01 x: y' >> "$D/docs/mkb/knowledge/modules/MODULE-CORE.md"; chk; cnt '^WARN W8' 1; cnt '^WARN' 1
t fence-in-list; printf '%s\n' '' '1. Mark a wrong section like this:' '' '    ```markdown' '    > STALE 2000-01-01 x: y. Tracking TASK-123.' '    See MODULE-EXAMPLE.' '    ```' 'After TASK-124.' >> "$D/docs/mkb/knowledge/services/SERVICE-API.md"; only_warn W10 docs/mkb/knowledge/services/SERVICE-API.md 'TASK-124 '
t fence-in-blockquote; printf '%s\n' '' '> ```text' '> TASK-777 and INT-EXAMPLE' '> ```' '> After TASK-778.' >> "$D/docs/mkb/knowledge/services/SERVICE-API.md"; only_warn W10 docs/mkb/knowledge/services/SERVICE-API.md 'TASK-778 '
t fence-blockquote-ends; printf '%s\n' '' '> ```text' '> TASK-777' '' 'See TASK-778.' >> "$D/docs/mkb/knowledge/services/SERVICE-API.md"; only_warn W10 docs/mkb/knowledge/services/SERVICE-API.md 'TASK-778 '
t fence-quoted-close-inside; printf '%s\n' '' '```markdown' '> ```text' '> ```' 'TASK-779' '```' 'See TASK-780.' >> "$D/docs/mkb/knowledge/services/SERVICE-API.md"; only_warn W10 docs/mkb/knowledge/services/SERVICE-API.md 'TASK-780 '
t fence-indented-inside-fence; printf '%s\n' '' '```markdown' '1. Mark a wrong section like this:' '    ```text' '    TASK-781' '    ```' '```' 'See TASK-782.' >> "$D/docs/mkb/knowledge/services/SERVICE-API.md"; only_warn W10 docs/mkb/knowledge/services/SERVICE-API.md 'TASK-782 '

# ---------- E1 to E5 ----------
t E1-archive-dup; cp "$D/docs/mkb/tasks/TASK-003.md" "$D/docs/mkb/tasks/archive/TASK-003.md"; only_err E1 tasks/archive/TASK-003.md 'id TASK-003 also used by docs/mkb/tasks/TASK-003.md'
t E1-other-name; sed 's/^id: TASK-003$/id: TASK-003/' "$D/docs/mkb/tasks/TASK-003.md" > "$D/docs/mkb/tasks/TASK-009.md"; chk
has '^ERROR E1 docs/mkb/tasks/TASK-009.md: '; has '^ERROR E2 docs/mkb/tasks/TASK-009.md: file name differs from id TASK-003'; cnt '^ERROR' 2; rc 1
t E2; sed 's/^id: TASK-003$/id: TASK-010/' "$D/docs/mkb/tasks/TASK-003.md" > "$D/docs/mkb/tasks/TASK-009.md"; err_w10 E2 tasks/TASK-009.md 'TASK-010' TASK-010
t E2-knowledge; ed_ knowledge/services/SERVICE-API.md 's/^id: SERVICE-API/id: SERVICE-WEB/'; err_w10 E2 knowledge/services/SERVICE-API.md 'SERVICE-WEB' SERVICE-WEB
t E4-knowledge; sed 's/MODULE-CORE/INT-FOO/; s/^type: module/type: integration/' "$D/docs/mkb/knowledge/modules/MODULE-CORE.md" > "$D/docs/mkb/knowledge/modules/INT-FOO.md"; only_err E4 knowledge/modules/INT-FOO.md 'belongs in docs/mkb/knowledge/integrations/'
t E4-state; printf '# x\n' > "$D/docs/mkb/state/TASK-010.md"; only_err E4 state/TASK-010.md 'belongs in docs/mkb/tasks/'
t E4-task-in-questions; cp "$D/docs/mkb/tasks/TASK-003.md" "$D/docs/mkb/questions/TASK-003.md"; rm "$D/docs/mkb/tasks/TASK-003.md"; only_err E4 questions/TASK-003.md 'tasks/'
t E5-top; printf '# x\n' > "$D/docs/mkb/CLAUDE.md"; only_err E5 CLAUDE.md 'tool instruction file'
t E5-templates; printf '# x\n' > "$D/docs/mkb/templates/AGENTS.md"; only_err E5 templates/AGENTS.md ''
t E5-override; printf '# x\n' > "$D/docs/mkb/agents/AGENTS.override.md"; only_err E5 agents/AGENTS.override.md ''
t E5-gemini-lower; printf '# x\n' > "$D/docs/mkb/project/gemini.md"; only_err E5 project/gemini.md ''
t E6-current; rm "$D/docs/mkb/state/CURRENT.md"; only_err E6 state/CURRENT.md 'mandatory file is missing'
t E6-rules; rm "$D/docs/mkb/agents/RULES.md"; only_err E6 agents/RULES.md 'mandatory file is missing'
t E6-index; rm "$D/docs/mkb/INDEX.md"; only_err E6 INDEX.md 'mandatory file is missing'
t E6-min-set; rm "$D/docs/mkb/project/OVERVIEW.md" "$D/docs/mkb/project/CONSTRAINTS.md" "$D/docs/mkb/state/NEXT.md"; chk; cnt '^ERROR E6 ' 3; has '^ERROR E6 docs/mkb/project/OVERVIEW.md: '; has '^ERROR E6 docs/mkb/project/CONSTRAINTS.md: '; has '^ERROR E6 docs/mkb/state/NEXT.md: '; cnt '^WARN' 0; rc 1; fmt
t E6-full-architecture; rm "$D/docs/mkb/project/ARCHITECTURE.md"; only_err E6 project/ARCHITECTURE.md 'mandatory file is missing'
t E6-full-conventions; rm "$D/docs/mkb/project/CONVENTIONS.md"; only_err E6 project/CONVENTIONS.md 'mandatory file is missing'
t E6-conventions-override; rm "$D/docs/mkb/project/CONVENTIONS.md"; printf '%s\n' '' '## Path overrides' '| Kind | Lives at | Note |' '|---|---|---|' '| conventions | `CONTRIBUTING.md` | no project/CONVENTIONS.md; CONTRIBUTING.md is authoritative |' >> "$D/docs/mkb/INDEX.md"; chk; tot 0 0
t E6-override-in-fence; rm "$D/docs/mkb/project/CONVENTIONS.md"; printf '%s\n' '```markdown' '| conventions | `CONTRIBUTING.md` | example |' '```' >> "$D/docs/mkb/INDEX.md"; only_err E6 project/CONVENTIONS.md ''
t E6-minimal-lazy; ed_ INDEX.md 's/^profile: full/profile: minimal/'; rm "$D/docs/mkb/project/ARCHITECTURE.md" "$D/docs/mkb/project/CONVENTIONS.md"; chk; tot 0 0

# ---------- E3: front matter (C.2, C.5) ----------
t E3-missing-key; ed_ tasks/TASK-003.md '/^priority:/d'; only_err E3 tasks/TASK-003.md 'missing required key priority'
t E3-unknown-key; ed_ tasks/TASK-008.md 's/^owner: none$/owner: none\ntitle: Dark mode/'; only_err E3 tasks/TASK-008.md 'unknown key title'
t E3-updated-key; ed_ knowledge/modules/MODULE-CORE.md 's/^verified: 2026-09-10$/verified: 2026-09-10\nupdated: 2026-09-11/'; only_err E3 knowledge/modules/MODULE-CORE.md 'unknown key updated'
t E3-bad-status; ed_ questions/Q-001.md 's/^status: open/status: pending/'; only_err E3 questions/Q-001.md 'invalid status pending'
t E3-bad-priority; ed_ tasks/TASK-003.md 's/^priority: high/priority: urgent/'; only_err E3 tasks/TASK-003.md 'invalid priority'
t E3-bad-type; ed_ tasks/TASK-003.md 's/^type: task/type: story/'; only_err E3 tasks/TASK-003.md 'invalid type story'
t E3-type-location; ed_ tasks/TASK-008.md 's/^type: task/type: adr/'; only_err E3 tasks/TASK-008.md 'does not fit this location, expected task'
t E3-invalid-date; ed_ tasks/TASK-002.md 's/^closed: 2026-09-10/closed: 2026-02-30/'; only_err E3 tasks/TASK-002.md 'invalid closed 2026-02-30'
t E3-quoted-date; ed_ knowledge/database/DB-MAIN.md 's/^verified: 2026-09-10/verified: "2026-09-10"/'; only_err E3 knowledge/database/DB-MAIN.md 'breaks the MKB YAML subset'
t E3-leap-ok; ed_ tasks/TASK-003.md 's/^created: 2026-09-05/created: 2024-02-29/'; chk; tot 0 0
t E3-leap-bad; ed_ tasks/TASK-003.md 's/^created: 2026-09-05/created: 2100-02-29/'; only_err E3 tasks/TASK-003.md 'invalid created'
t E3-empty-value; ed_ knowledge/integrations/INT-DEVICE.md 's/^verified: 2026-09-10$/verified: 2026-09-10\nrelated:/'; only_err E3 knowledge/integrations/INT-DEVICE.md 'invalid front matter line: related:'
t E3-empty-list; ed_ knowledge/services/SERVICE-API.md 's/^verified: 2026-09-10$/verified: 2026-09-10\nrelated: []/'; only_err E3 knowledge/services/SERVICE-API.md 'invalid flow list in related'
t E3-list-empty-item; ed_ knowledge/services/SERVICE-API.md 's/^verified: 2026-09-10$/verified: 2026-09-10\nrelated: [ADR-001, ]/'; only_err E3 knowledge/services/SERVICE-API.md 'invalid item in related'
t E3-scalar-for-list; ed_ tasks/TASK-003.md 's/^code: \[src\/core\/\]/code: src\/core\//'; only_err E3 tasks/TASK-003.md 'code must be a flow list'
t E3-list-for-scalar; ed_ decisions/ADR-002.md 's/^superseded_by: ADR-003/superseded_by: [ADR-003]/'; only_err E3 decisions/ADR-002.md 'superseded_by must be a single value'
t E3-13-keys; ed_ tasks/TASK-005.md 's/^code: .*/code: [src\/core\/parser.py]\nrelated: [ADR-001]\nformerly: TASK-006\nx_one: a\nx_two: b\nx_three: c/'; chk; has '^ERROR E3 docs/mkb/tasks/TASK-005.md: more than 12 keys'; has 'unknown key x_three'; cnt '^ERROR' 4; rc 1
t E3-two-blank-lines; ed_ decisions/ADR-004.md 's/^# ADR-004/\n# ADR-004/'; only_err E3 decisions/ADR-004.md 'H1 must follow'
t E3-text-before-h1; ed_ knowledge/troubleshooting/TS-DB-LOCKED.md 's/^# TS-DB-LOCKED/Intro text\n# TS-DB-LOCKED/'; only_err E3 knowledge/troubleshooting/TS-DB-LOCKED.md 'H1 must follow'
t E3-no-h1; printf -- '---\ntype: architecture\nverified: 2026-09-10\n---\n' > "$D/docs/mkb/project/ARCHITECTURE.md"; only_err E3 project/ARCHITECTURE.md 'H1 must follow'
t E3-branch-when-todo; ed_ tasks/TASK-003.md 's/^owner: none$/owner: none\nbranch: bob\/task-003-checksum/'; only_err E3 tasks/TASK-003.md 'branch is not allowed when status is todo'
t E3-branch-missing; ed_ tasks/TASK-005.md '/^branch:/d'; only_err E3 tasks/TASK-005.md 'branch is required when status is in-progress'
t E3-closed-missing; ed_ tasks/TASK-002.md '/^closed:/d'; only_err E3 tasks/TASK-002.md 'closed is required when status is done'
t E3-closed-forbidden; ed_ tasks/TASK-003.md 's/^created: 2026-09-05$/created: 2026-09-05\nclosed: 2026-09-06/'; only_err E3 tasks/TASK-003.md 'closed is not allowed when status is todo'
t E3-owner-none; ed_ tasks/TASK-005.md 's/^owner: claude-code/owner: none/'; only_err E3 tasks/TASK-005.md 'owner must not be none when status is in-progress'
t E3-blocked-by-forbidden; ed_ tasks/TASK-008.md 's/^created: 2026-07-01$/created: 2026-07-01\nblocked_by: [Q-001]/'; only_err E3 tasks/TASK-008.md 'blocked_by is not allowed when status is todo'
t E3-blocked-by-missing; ed_ tasks/TASK-004.md '/^blocked_by:/d'; only_err E3 tasks/TASK-004.md 'blocked_by is required when status is blocked'
t E3-blocked-by-bad-item; ed_ tasks/TASK-004.md 's/^blocked_by: .*/blocked_by: [Q-001, ADR-001]/'; only_err E3 tasks/TASK-004.md 'invalid blocked_by item ADR-001'
t E3-deciders-missing; ed_ decisions/ADR-001.md '/^deciders:/d'; only_err E3 decisions/ADR-001.md 'deciders is required when status is accepted'
t E3-deciders-agent; ed_ decisions/ADR-003.md 's/^deciders: .*/deciders: [alice, codex]/'; only_err E3 decisions/ADR-003.md 'invalid deciders item codex'
t E3-superseded-by-missing; ed_ decisions/ADR-002.md '/^superseded_by:/d'; only_err E3 decisions/ADR-002.md 'superseded_by is required when status is superseded'
t E3-superseded-by-forbidden; ed_ decisions/ADR-001.md 's/^deciders: \[alice\]$/deciders: [alice]\nsuperseded_by: ADR-003/'; only_err E3 decisions/ADR-001.md 'superseded_by is not allowed when status is accepted'
t E3-proposed-ok-with-deciders; ed_ decisions/ADR-004.md 's/^date: 2026-09-21$/date: 2026-09-21\ndeciders: [alice]/'; chk; tot 0 0
t E3-code-missing-module; ed_ knowledge/modules/MODULE-CORE.md '/^code:/d'; only_err E3 knowledge/modules/MODULE-CORE.md 'missing required key code'
t E3-code-optional-int; chk; hasnt 'INT-DEVICE'
t E3-summary-long; ed_ knowledge/services/SERVICE-API.md "s/^summary: .*/summary: $(printf 'x%.0s' $(seq 1 121))/"; only_err E3 knowledge/services/SERVICE-API.md 'invalid summary'
t E3-summary-120; ed_ knowledge/services/SERVICE-API.md "s/^summary: .*/summary: $(printf 'x%.0s' $(seq 1 120))/"; chk; tot 0 0
t E3-summary-120-utf8; ed_ knowledge/services/SERVICE-API.md "s/^summary: .*/summary: $(printf '\303\240%.0s' $(seq 1 120))/"
OUT=$(LC_ALL=C "$SHX" "$CHK" --root "$D" --no-git --today $TD 2>/dev/null); tot 0 0; OUT=$(LC_ALL=C.UTF-8 "$SHX" "$CHK" --root "$D" --no-git --today $TD 2>/dev/null); tot 0 0
t E3-summary-121-utf8; ed_ knowledge/services/SERVICE-API.md "s/^summary: .*/summary: $(printf '\303\240%.0s' $(seq 1 121))/"; only_err E3 knowledge/services/SERVICE-API.md 'invalid summary'
OUT=$(LC_ALL=C.UTF-8 "$SHX" "$CHK" --root "$D" --no-git --today $TD 2>/dev/null); tot 1 0
t E3-code-dotslash; ed_ tasks/TASK-003.md 's/^code: .*/code: [.\/src\/core\/]/'; only_err E3 tasks/TASK-003.md 'invalid code item ./src/core/'
t E3-code-glob; ed_ tasks/TASK-003.md 's/^code: .*/code: [src\/core\/*.py]/'; only_err E3 tasks/TASK-003.md 'invalid code item src/core/\*.py'
t E3-code-leading-slash; ed_ knowledge/services/SERVICE-API.md 's/^code: .*/code: [\/src\/api\/]/'; only_err E3 knowledge/services/SERVICE-API.md 'invalid code item /src/api/'
t E3-code-dir-no-slash; ed_ knowledge/services/SERVICE-API.md 's/^code: .*/code: [src\/api, src\/core\/parser.py]/'; only_err E3 knowledge/services/SERVICE-API.md 'invalid code item src/api$'
t E3-mkb-version-unquoted; ed_ agents/RULES.md 's/^mkb_version: .*/mkb_version: 1.0/'; only_err E3 agents/RULES.md 'invalid mkb_version 1.0'
t E3-profile; ed_ INDEX.md 's/^profile: full/profile: large/'; only_err E3 INDEX.md 'invalid profile large'
t E3-status-two-words; ed_ tasks/TASK-003.md 's/^status: todo$/status: todo in-progress/'; only_err E3 tasks/TASK-003.md 'invalid status todo in-progress'
t E3-priority-two-words; ed_ tasks/TASK-003.md 's/^priority: high$/priority: high normal/'; only_err E3 tasks/TASK-003.md 'invalid priority high normal'
t E3-profile-two-words; ed_ INDEX.md 's/^profile: full$/profile: minimal full/'; only_err E3 INDEX.md 'invalid profile minimal full'
t E3-adr-status-two-words; ed_ decisions/ADR-001.md 's/^status: accepted$/status: accepted rejected/'; only_err E3 decisions/ADR-001.md 'invalid status accepted rejected'
t E3-index-missing-profile; ed_ INDEX.md '/^profile:/d'; only_err E3 INDEX.md 'missing required key profile'
t E3-arch-missing-verified; ed_ project/ARCHITECTURE.md '/^verified:/d'; only_err E3 project/ARCHITECTURE.md 'missing required key verified'
t E3-fm-forbidden-overview; ed_ project/OVERVIEW.md '1s/^/---\ntype: overview\n---\n/'; only_err E3 project/OVERVIEW.md 'front matter is not allowed'
t E3-fm-forbidden-next; ed_ state/NEXT.md '1s/^/---\ntype: next\n---\n/'; only_err E3 state/NEXT.md 'front matter is not allowed'
t E3-fm-forbidden-handoff; ed_ handoff/TASK-005.md '1s/^/---\ntype: handoff\n---\n/'; only_err E3 handoff/TASK-005.md 'front matter is not allowed in a handoff'
t E3-question-owner-agent; ed_ questions/Q-001.md 's/^owner: alice/owner: claude-code/'; only_err E3 questions/Q-001.md 'invalid owner claude-code'
t E3-question-owner-none; ed_ questions/Q-001.md 's/^owner: alice/owner: none/'; only_err E3 questions/Q-001.md 'invalid owner none'
t E3-question-asked-by-none; ed_ questions/Q-001.md 's/^asked_by: .*/asked_by: none/'; only_err E3 questions/Q-001.md 'invalid asked_by none'
t E3-deciders-none; ed_ decisions/ADR-001.md 's/^deciders: \[alice\]$/deciders: [none]/'; only_err E3 decisions/ADR-001.md 'invalid deciders item none'
t E3-owner-uppercase; ed_ tasks/TASK-005.md 's/^owner: claude-code/owner: Bob/'; only_err E3 tasks/TASK-005.md 'invalid owner Bob'
t E3-owner-at; ed_ tasks/TASK-005.md 's/^owner: claude-code/owner: @bob/'; only_err E3 tasks/TASK-005.md 'breaks the MKB YAML subset: @bob'
t E3-colon-space; ed_ knowledge/database/DB-MAIN.md 's/^summary: .*/summary: SQLite store: WAL mode/'; only_err E3 knowledge/database/DB-MAIN.md 'breaks the MKB YAML subset'
t E3-space-hash; ed_ knowledge/database/DB-MAIN.md 's/^summary: .*/summary: SQLite store #1/'; only_err E3 knowledge/database/DB-MAIN.md 'breaks the MKB YAML subset'
t E3-hash-start; ed_ knowledge/troubleshooting/TS-DB-LOCKED.md 's/^summary: .*/summary: #1 cause of lost readings/'; only_err E3 knowledge/troubleshooting/TS-DB-LOCKED.md 'breaks the MKB YAML subset'
t E3-quote-start; ed_ knowledge/troubleshooting/TS-DB-LOCKED.md 's/^summary: .*/summary: "database is locked" errors during reports/'; only_err E3 knowledge/troubleshooting/TS-DB-LOCKED.md 'breaks the MKB YAML subset'
t E3-apostrophe-start; ed_ knowledge/troubleshooting/TS-DB-LOCKED.md "s/^summary: .*/summary: 'database is locked' errors during reports/"; only_err E3 knowledge/troubleshooting/TS-DB-LOCKED.md 'breaks the MKB YAML subset'
t E3-dash-space-start; ed_ knowledge/troubleshooting/TS-DB-LOCKED.md 's/^summary: .*/summary: - frames lost when the link drops/'; only_err E3 knowledge/troubleshooting/TS-DB-LOCKED.md 'breaks the MKB YAML subset'
t E3-question-space-start; ed_ knowledge/troubleshooting/TS-DB-LOCKED.md 's/^summary: .*/summary: ? frames lost/'; only_err E3 knowledge/troubleshooting/TS-DB-LOCKED.md 'breaks the MKB YAML subset'
t E3-comma-start; ed_ knowledge/troubleshooting/TS-DB-LOCKED.md 's/^summary: .*/summary: ,comma start/'; only_err E3 knowledge/troubleshooting/TS-DB-LOCKED.md 'breaks the MKB YAML subset'
t E3-dash-word-ok; ed_ knowledge/troubleshooting/TS-DB-LOCKED.md 's/^summary: .*/summary: -frames lost when the link drops/'; chk; tot 0 0
t E3-quoted-list-item; ed_ questions/Q-001.md 's/^related: .*/related: ["TASK-004"]/'; only_err E3 questions/Q-001.md 'invalid item in related'
t E3-bom; printf '\357\273\277' | cat - "$D/docs/mkb/tasks/TASK-003.md" > "$D/x"; mv "$D/x" "$D/docs/mkb/tasks/TASK-003.md"; only_err E3 tasks/TASK-003.md 'byte order mark'
t E3-trailing-space-delimiters; ed_ tasks/TASK-003.md '1s/^---$/--- /; 9s/^---$/---\t/'; chk; tot 0 0
t E3-whitespace-blank-line; ed_ decisions/ADR-004.md 's/^$/  /'; chk; tot 0 0
t E3-no-fm; ed_ knowledge/troubleshooting/TS-DB-LOCKED.md '1,7d'; only_err E3 knowledge/troubleshooting/TS-DB-LOCKED.md 'missing front matter'
t E3-unclosed-fm; ed_ questions/Q-001.md '9d'; only_err E3 questions/Q-001.md 'not closed'
t E3-dup-key; ed_ tasks/TASK-008.md 's/^owner: none$/owner: none\nowner: bob/'; only_err E3 tasks/TASK-008.md 'duplicate key owner'
t E3-comment-line; ed_ tasks/TASK-008.md 's/^owner: none$/owner: none\n# a comment/'; only_err E3 tasks/TASK-008.md 'invalid front matter line: # a comment'
t E3-nested; ed_ tasks/TASK-008.md 's/^owner: none$/owner: none\n  nested: x/'; only_err E3 tasks/TASK-008.md 'invalid front matter line'
t E3-bad-id; mv "$D/docs/mkb/tasks/TASK-008.md" "$D/docs/mkb/tasks/TASK-8.md"; ed_ tasks/TASK-8.md 's/^id: TASK-008/id: TASK-8/'; err_w10 E3 tasks/TASK-8.md 'invalid id TASK-8' TASK-008
t E3-bad-knowledge-id; mv "$D/docs/mkb/knowledge/integrations/INT-DEVICE.md" "$D/docs/mkb/knowledge/integrations/INT-45.md"; ed_ knowledge/integrations/INT-45.md 's/^id: INT-DEVICE/id: INT-45/'; ed_ decisions/ADR-003.md 's/INT-DEVICE/INT-45/'; err_w10 E3 knowledge/integrations/INT-45.md 'invalid id INT-45' INT-DEVICE
t E3-bad-branch; ed_ tasks/TASK-005.md 's/^branch: .*/branch: feature..x/'; only_err E3 tasks/TASK-005.md 'invalid branch'
t E3-pending-branch-ok; ed_ tasks/TASK-005.md 's/^branch: .*/branch: pending/'; chk; tot 0 0
t E3-related-scalar; ed_ questions/Q-001.md 's/^related: .*/related: TASK-004/'; only_err E3 questions/Q-001.md 'related must be a flow list'
t E3-related-lowercase; ed_ questions/Q-001.md 's/^related: .*/related: [task-004]/'; only_err E3 questions/Q-001.md 'invalid related item task-004'
t E3-related-tracker-ok; ed_ questions/Q-001.md 's/^related: .*/related: [TASK-004, GH-123, OPS-45]/'; chk; tot 0 0
t E3-formerly-bad; ed_ tasks/TASK-007.md 's/^formerly: .*/formerly: ADR-006/'; only_err E3 tasks/TASK-007.md 'invalid formerly ADR-006'
t E3-formerly-knowledge-cross-kind; ed_ knowledge/modules/MODULE-CORE.md 's/^verified: 2026-09-10$/verified: 2026-09-10\nformerly: SERVICE-CORE/'; chk; tot 0 0
t E3-formerly-knowledge-task; ed_ knowledge/modules/MODULE-CORE.md 's/^verified: 2026-09-10$/verified: 2026-09-10\nformerly: TASK-001/'; only_err E3 knowledge/modules/MODULE-CORE.md 'invalid formerly TASK-001'
t E3-blank-in-fm; ed_ tasks/TASK-008.md 's/^owner: none$/owner: none\n/'; only_err E3 tasks/TASK-008.md 'invalid front matter line: $'
t E3-knowledge-4-words; mv "$D/docs/mkb/knowledge/integrations/INT-DEVICE.md" "$D/docs/mkb/knowledge/integrations/INT-A-B-C-D.md"; ed_ knowledge/integrations/INT-A-B-C-D.md 's/^id: INT-DEVICE/id: INT-A-B-C-D/'; ed_ decisions/ADR-003.md 's/INT-DEVICE/INT-A-B-C-D/'; err_w10 E3 knowledge/integrations/INT-A-B-C-D.md 'invalid id' INT-DEVICE
t E3-crlf-still-checked; crlf; ed_ tasks/TASK-003.md '/^priority:/d'; only_err E3 tasks/TASK-003.md 'missing required key priority'

# ---------- warnings ----------
t W1-task; i=0; while [ $i -lt 41 ]; do echo "- 2026-09-15 bob: note $i" >> "$D/docs/mkb/tasks/TASK-003.md"; i=$((i + 1)); done; only_warn W1 docs/mkb/tasks/TASK-003.md '61 lines, budget 60'
t W1-task-60; i=0; while [ $i -lt 40 ]; do echo "- 2026-09-15 bob: note $i" >> "$D/docs/mkb/tasks/TASK-003.md"; i=$((i + 1)); done; chk; tot 0 0
t W1-handoff; i=0; while [ $i -lt 17 ]; do echo "- line $i" >> "$D/docs/mkb/handoff/TASK-005.md"; i=$((i + 1)); done; only_warn W1 docs/mkb/handoff/TASK-005.md '31 lines, budget 30'
t W1-next; i=0; while [ $i -lt 9 ]; do echo "- TASK-003: again $i" >> "$D/docs/mkb/state/NEXT.md"; i=$((i + 1)); done; only_warn W1 docs/mkb/state/NEXT.md '16 lines, budget 15'
t W1-rules-section-16-exempt; seq 1 600 | sed 's/^/- project rule /' >> "$D/docs/mkb/agents/RULES.md"; chk; tot 0 0
rules_above() { f=$D/docs/mkb/agents/RULES.md; n=$(grep -n '^## 16\. ' "$f" | cut -d: -f1); { head -n $((n - 1)) "$f"; seq 1 $(($1 - n + 1)) | sed 's/^/standard line /'; tail -n +$n "$f"; } > "$f.x"; mv "$f.x" "$f"; }
t W1-rules-500-above; rules_above 500; chk; tot 0 0
t W1-rules-501-above; rules_above 501; only_warn W1 docs/mkb/agents/RULES.md '501 lines above section 16, budget 500'
t W4-done; cp "$D/docs/mkb/handoff/TASK-005.md" "$D/docs/mkb/handoff/TASK-002.md"; only_warn W4 docs/mkb/handoff/TASK-002.md 'TASK-002 is done'
t W4-dropped; cp "$D/docs/mkb/handoff/TASK-005.md" "$D/docs/mkb/handoff/TASK-007.md"; only_warn W4 docs/mkb/handoff/TASK-007.md 'TASK-007 is dropped'
t W4-missing; cp "$D/docs/mkb/handoff/TASK-005.md" "$D/docs/mkb/handoff/TASK-050.md"; only_warn W4 docs/mkb/handoff/TASK-050.md 'TASK-050 is missing'
t W4-no-work-item; cp "$D/docs/mkb/handoff/TASK-005.md" "$D/docs/mkb/handoff/notes.md"; only_warn W4 docs/mkb/handoff/notes.md 'no work item'
t W4-tracker-key-ok; cp "$D/docs/mkb/handoff/TASK-005.md" "$D/docs/mkb/handoff/GH-123.md"; chk; tot 0 0
t W5-old; ed_ state/CURRENT.md 's/^- 2026-09-15 alice/- 2026-09-01 alice/'; only_warn W5 docs/mkb/state/CURRENT.md 'dated 2026-09-01 is older than 14 days'
t W5-14-days-ok; ed_ state/CURRENT.md 's/^- 2026-09-15 alice/- 2026-09-09 alice/'; chk; tot 0 0
t W5-15-days; ed_ state/CURRENT.md 's/^- 2026-09-15 alice/- 2026-09-08 alice/'; only_warn W5 docs/mkb/state/CURRENT.md 'older than 14 days'
t W5-undated; echo "- Production is fine" >> "$D/docs/mkb/state/CURRENT.md"; only_warn W5 docs/mkb/state/CURRENT.md 'not in the form'
t W5-bad-date; echo "- 2026-02-31 alice: impossible day" >> "$D/docs/mkb/state/CURRENT.md"; only_warn W5 docs/mkb/state/CURRENT.md 'not in the form'
t W5-minimal-ok; ed_ INDEX.md 's/^profile: full/profile: minimal/'; ed_ state/CURRENT.md 's/^- 2026-09-15 alice/- 2026-09-01 alice/'; chk; tot 0 0
t W5-minimal-old; ed_ INDEX.md 's/^profile: full/profile: minimal/'; ed_ state/CURRENT.md 's/^- 2026-09-15 alice/- 2026-08-01 alice/'; only_warn W5 docs/mkb/state/CURRENT.md 'older than 35 days'
t W5-fenced-ignored; printf '%s\n' '```text' '- undated bullet in a fence' '- 2000-01-01 x: old' '```' >> "$D/docs/mkb/state/CURRENT.md"; chk; tot 0 0
t W7; ed_ questions/Q-001.md 's/^status: open/status: answered/'; only_warn W7 docs/mkb/questions/Q-001.md 'answered'
t W8-old; ed_ knowledge/modules/MODULE-CORE.md 's/^> STALE 2026-09-20/> STALE 2026-08-01/'; only_warn W8 docs/mkb/knowledge/modules/MODULE-CORE.md 'dated 2026-08-01 is older than 30 days'
t W8-30-days-ok; ed_ knowledge/modules/MODULE-CORE.md 's/^> STALE 2026-09-20/> STALE 2026-08-24/'; chk; tot 0 0
t W8-31-days; ed_ knowledge/modules/MODULE-CORE.md 's/^> STALE 2026-09-20/> STALE 2026-08-23/'; only_warn W8 docs/mkb/knowledge/modules/MODULE-CORE.md 'older than 30 days'
t W8-no-date; echo "> STALE soon bob: wrong." >> "$D/docs/mkb/project/OVERVIEW.md"; only_warn W8 docs/mkb/project/OVERVIEW.md 'without a valid date'
t W8-indented-ignored; echo "  > STALE 2000-01-01 bob: wrong." >> "$D/docs/mkb/project/OVERVIEW.md"; chk; tot 0 0
t W9; ed_ tasks/TASK-002.md 's/^closed: 2026-09-10/closed: 2026-08-01/'; only_warn W9 docs/mkb/tasks/TASK-002.md 'archive it'
t W9-30-days-ok; ed_ tasks/TASK-002.md 's/^closed: 2026-09-10/closed: 2026-08-24/'; chk; tot 0 0
t W9-archive-ignored; ed_ tasks/archive/TASK-001.md 's/^closed: 2026-07-01/closed: 2020-01-01/'; chk; tot 0 0
t W10-body; echo "See TASK-099, ADR-050, MODULE-MISSING, Q-050 and INT-45." >> "$D/docs/mkb/knowledge/modules/MODULE-CORE.md"; chk
has '^WARN W10 docs/mkb/knowledge/modules/MODULE-CORE.md: TASK-099 '; has '^WARN W10 docs/mkb/knowledge/modules/MODULE-CORE.md: ADR-050 '
has '^WARN W10 docs/mkb/knowledge/modules/MODULE-CORE.md: MODULE-MISSING '; hasnt 'Q-050|INT-45'; cnt '^WARN' 3; rc 0; fmt
t W10-frontmatter; ed_ questions/Q-001.md 's/^related: .*/related: [TASK-004, TASK-098]/'; only_warn W10 docs/mkb/questions/Q-001.md 'TASK-098'
t W10-formerly-exempt; chk; hasnt 'TASK-006'
t W10-word-boundary; echo "Not IDs: XTASK-099, TASK-0999a, MODULE-FOO_BAR, task-099." >> "$D/docs/mkb/project/OVERVIEW.md"; chk; tot 0 0
t W10-archive-resolves; echo "Follows TASK-001." >> "$D/docs/mkb/project/OVERVIEW.md"; chk; tot 0 0
t W10-archive-source-exempt; echo "Used MODULE-GONE and TASK-099." >> "$D/docs/mkb/tasks/archive/TASK-001.md"; chk; tot 0 0
t W10-archive-target-resolves; echo "Continues TASK-001." >> "$D/docs/mkb/tasks/TASK-003.md"; chk; tot 0 0
t E3-trailing-colon; ed_ knowledge/database/DB-MAIN.md 's/^summary: .*/summary: SQLite store:/'; only_err E3 knowledge/database/DB-MAIN.md 'breaks the MKB YAML subset'
t E3-tab-separator; ed_ tasks/TASK-008.md 's/^owner: none/owner:	none/'; chk; has '^ERROR E3 docs/mkb/tasks/TASK-008.md: invalid front matter line'; has 'missing required key owner'; cnt '^ERROR' 2; rc 1
t E3-code-dotdot; ed_ tasks/TASK-003.md 's/^code: .*/code: [src\/..\/etc\/]/'; only_err E3 tasks/TASK-003.md 'invalid code item'
t E3-fm-forbidden-current-crlf; crlf; ed_ state/CURRENT.md '1s/^/---\r\ntype: state\r\n---\r\n/'; only_err E3 state/CURRENT.md 'front matter is not allowed'
t W10-dedup; echo "TASK-099 TASK-099" >> "$D/docs/mkb/project/OVERVIEW.md"; echo "TASK-099" >> "$D/docs/mkb/project/OVERVIEW.md"; only_warn W10 docs/mkb/project/OVERVIEW.md 'TASK-099'
t W11; echo "<!-- guide: fill this -->" >> "$D/docs/mkb/project/OVERVIEW.md"; only_warn W11 docs/mkb/project/OVERVIEW.md 'guide comment'
t W11-inline-ignored; echo "Text <!-- guide: inline -->" >> "$D/docs/mkb/project/OVERVIEW.md"; chk; tot 0 0
t W12-all-resolved; ed_ state/NEXT.md '/^- TASK-003/d'; rm "$D/docs/mkb/questions/Q-001.md"; ed_ tasks/TASK-003.md 's/^status: todo/status: dropped/; s/^created: 2026-09-05$/created: 2026-09-05\nclosed: 2026-09-20/'; only_warn W12 docs/mkb/tasks/TASK-004.md 'clear the block'
t W12-partial; rm "$D/docs/mkb/questions/Q-001.md"; chk; tot 0 0
t W13-done; echo "- TASK-002: already done" >> "$D/docs/mkb/state/NEXT.md"; only_warn W13 docs/mkb/state/NEXT.md 'TASK-002 is listed but done'
t W13-missing; echo "- TASK-077: nobody wrote it" >> "$D/docs/mkb/state/NEXT.md"; chk; has '^WARN W13 docs/mkb/state/NEXT.md: TASK-077 is listed but its task is missing'; has '^WARN W10 docs/mkb/state/NEXT.md: TASK-077'; cnt '^WARN' 2
t W15; ed_ questions/Q-001.md 's/^created: 2026-09-15/created: 2026-09-01/'; only_warn W15 docs/mkb/questions/Q-001.md 'more than 14 days'
t W15-14-ok; ed_ questions/Q-001.md 's/^created: 2026-09-15/created: 2026-09-09/'; chk; tot 0 0
t W16-knowledge; ed_ knowledge/modules/MODULE-CORE.md 's/^verified: .*/verified: 2026-03-26/'; only_warn W16 docs/mkb/knowledge/modules/MODULE-CORE.md 'more than 180 days'
t W16-180-ok; ed_ knowledge/modules/MODULE-CORE.md 's/^verified: .*/verified: 2026-03-27/'; chk; tot 0 0
t W16-architecture; ed_ project/ARCHITECTURE.md 's/^verified: .*/verified: 2025-01-01/'; only_warn W16 docs/mkb/project/ARCHITECTURE.md 'verified 2025-01-01'
t W17; ed_ tasks/TASK-008.md 's/^created: .*/created: 2026-06-01/'; only_warn W17 docs/mkb/tasks/TASK-008.md 'propose dropping'
t W17-90-ok; ed_ tasks/TASK-008.md 's/^created: .*/created: 2026-06-25/'; chk; tot 0 0
t W17-done-ignored; ed_ tasks/TASK-007.md 's/^priority: normal/priority: low/; s/^created: .*/created: 2025-01-01/'; chk; tot 0 0
t W7-crlf; crlf; ed_ questions/Q-001.md 's/^status: open/status: answered/'; only_warn W7 docs/mkb/questions/Q-001.md 'answered'
t nogit-skips-W3; ed_ knowledge/modules/MODULE-CORE.md 's/^code: .*/code: [src\/missing\/]/'; chk; tot 0 0

# ---------- strict, exit codes, usage ----------
t strict-warn; ed_ questions/Q-001.md 's/^status: open/status: answered/'; chk; rc 0; chk --strict; rc 1; tot 0 1
t strict-err; ed_ tasks/TASK-003.md '/^priority:/d'; chk --strict; rc 1
t usage-unknown; run --bogus; rc 2; OUT=$ERR; has '^usage:'
t usage-root-missing; run --root "$D/nope" --no-git; rc 2
t usage-no-mkb; mkdir -p "$D/empty"; run --root "$D/empty" --no-git; rc 2
t usage-today-bad; chk --today 2026-13-01; rc 2
t usage-today-format; chk --today 20260923; rc 2
t usage-today-novalue; run --root "$D" --today; rc 2
t usage-next-kind; run --root "$D" --no-git next FOO; rc 2
t usage-next-nokind; run --root "$D" --no-git next; rc 2
t usage-next-no-mkb; mkdir -p "$D/empty"; run --root "$D/empty" --no-git next TASK; rc 2; is ''; git -C "$D/empty" init -q -b main; run --root "$D/empty" next Q; rc 2; is ''
t usage-next-adr-dir-missing; run --root "$D" --no-git --adr-dir docs/nope next ADR; rc 2; is ''
t usage-adr-dir-missing; chk --adr-dir docs/nope; rc 2

# ---------- next ----------
t next-empty; mkdir -p "$D/e/docs/mkb"; for k in TASK ADR Q; do run --root "$D/e" --no-git next $k; is "$k-001"; rc 0; done
t next-empty-git; mkdir -p "$D/e/docs/mkb"; git -C "$D/e" init -q -b main; for k in TASK ADR Q; do run --root "$D/e" next $k; is "$k-001"; done
t next-worktree; run --root "$D" --no-git next TASK; is TASK-009; run --root "$D" --no-git next ADR; is ADR-005; run --root "$D" --no-git next Q; is Q-002
t next-history; ginit 2026-09-01
git -C "$D" checkout -q -b other; printf '# x\n' > "$D/docs/mkb/tasks/TASK-012.md"; gadd 2026-09-02 add12; git -C "$D" checkout -q main
printf '# q\n' > "$D/docs/mkb/questions/Q-004.md"; gadd 2026-09-03 addq4; rm "$D/docs/mkb/questions/Q-004.md"; gadd 2026-09-04 delq4
git -C "$D" mv docs/mkb/tasks/TASK-008.md docs/mkb/tasks/archive/TASK-008.md; gadd 2026-09-05 archive
grun next TASK; is TASK-013; grun next Q; is Q-005; grun next ADR; is ADR-005
run --root "$D" --no-git next TASK; is TASK-009; run --root "$D" --no-git next Q; is Q-002
printf '# x\n' > "$D/docs/mkb/tasks/TASK-020.md"; grun next TASK; is TASK-021
t next-1000; for n in 998 999; do printf '# x\n' > "$D/docs/mkb/tasks/TASK-$n.md"; done; run --root "$D" --no-git next TASK; is TASK-1000
t next-from-subdir; ginit 2026-09-01; OUT=$(cd "$D/src/core" && "$SHX" "$CHK" next Q 2>/dev/null); is Q-002
t next-renamed-on-branch; ginit 2026-09-01; git -C "$D" checkout -q -b other; git -C "$D" mv docs/mkb/decisions/ADR-004.md docs/mkb/decisions/ADR-007.md; gadd 2026-09-02 renumber; git -C "$D" checkout -q main; grun next ADR; is ADR-008
t shallow-clone; ginit 2026-09-01; git -C "$D" branch claude-code/task-005-parser; S=$W/s$N; git clone -q --depth 1 -c core.autocrlf=false "file://$D" "$S"
run --root "$S" next Q; rc 2; is ''; OUT=$ERR; has 'shallow clone: run git fetch --unshallow first'; run --root "$S" next TASK; rc 0; is TASK-009; run --root "$S" next ADR; rc 0; is ADR-005
run --root "$S" --today $TD; rc 0; tot 0 0; OUT=$ERR; has 'shallow clone; running as with --no-git'

# ---------- adopted ADR directory ----------
adrdir() { rm -rf "$D/docs/mkb/decisions"; mkdir -p "$D/docs/adr"; for f in 0001-record-architecture-decisions 0002-parse-frames 0003-render-pdf 0004-use-csv; do printf '# %s\n\nDate: 2026-09-01\n\n## Status\n\nAccepted\n' "$f" > "$D/docs/adr/$f.md"; done; printf 'not an ADR\n' > "$D/docs/adr/README.md"; }
t adr-clean; adrdir; chk --adr-dir docs/adr; tot 0 0; rc 0
t adr-trailing-slash; adrdir; chk --adr-dir ./docs/adr/; tot 0 0
t adr-without-flag; adrdir; chk; has '^WARN W10 .*ADR-001'
t adr-dup; adrdir; printf '# dup\n' > "$D/docs/adr/0002-other-choice.md"; chk --adr-dir docs/adr; has '^ERROR E1 docs/adr/0002-parse-frames.md: leading number 2 also used by docs/adr/0002-other-choice.md'; cnt '^ERROR' 1; rc 1
t adr-w10; adrdir; echo "See ADR-0004, ADR-0009 and ADR-004." >> "$D/docs/mkb/project/OVERVIEW.md"; chk --adr-dir docs/adr; has '^WARN W10 docs/mkb/project/OVERVIEW.md: ADR-0009 '; cnt '^WARN' 1
t adr-next; adrdir; run --root "$D" --no-git --adr-dir docs/adr next ADR; is ADR-0005; run --root "$D" --no-git --adr-dir docs/adr next TASK; is TASK-009
t adr-next-history; adrdir; ginit 2026-09-01; printf '# x\n' > "$D/docs/adr/0007-temp.md"; gadd 2026-09-02 add7; rm "$D/docs/adr/0007-temp.md"; gadd 2026-09-03 del7
grun --adr-dir docs/adr next ADR; is ADR-0008; run --root "$D" --no-git --adr-dir docs/adr next ADR; is ADR-0005
t adr-next-empty; mkdir -p "$D/docs/adr2"; run --root "$D" --no-git --adr-dir docs/adr2 next ADR; is ADR-001
t adr-next-other-files; adrdir; mkdir -p "$D/docs/adr/assets"; printf 'png' > "$D/docs/adr/assets/2024-05-lane-layout.png"; printf 'x' > "$D/docs/adr/0009-notes.txt"; run --root "$D" --no-git --adr-dir docs/adr next ADR; is ADR-0005
t adr-next-backslash; adrdir; run --root "$D" --no-git --adr-dir '.\docs\adr\' next ADR; is ADR-0005
ginit 2026-09-01; grun --adr-dir docs/adr next ADR; is ADR-0005
t adr-next-quoted-path; adrdir; ginit 2026-09-01; f="$D/docs/adr/0010-caff$(printf '\303\250').md"; printf '# x\n' > "$f"; gadd 2026-09-02 add10; rm "$f"; gadd 2026-09-03 del10; grun --adr-dir docs/adr next ADR; is ADR-0011
t adr-leading-zeros; adrdir; for n in 0008 0010; do printf '# x\n' > "$D/docs/adr/$n-d.md"; done; echo "See ADR-0010." >> "$D/docs/mkb/project/OVERVIEW.md"; chk --adr-dir docs/adr; tot 0 0; run --root "$D" --no-git --adr-dir docs/adr next ADR; is ADR-0011
t adr-in-mkb; mkdir -p "$D/docs/mkb/adr"; printf '# ADR 1\n\nSee TASK-003.\n<!-- guide: x -->\n' > "$D/docs/mkb/adr/0001-first.md"; chk --adr-dir docs/mkb/adr; has '^WARN W11 docs/mkb/adr/0001-first.md: '; cnt '^ERROR' 0; cnt '^WARN' 1

# ---------- git-backed checks ----------
t git-clean; git -C "$D" init -q -b main; git -C "$D" config core.autocrlf false; git -C "$D" add -A; gc 2026-09-20 init; git -C "$D" branch claude-code/task-005-parser; grun; tot 0 0; rc 0
t git-W2; ginit 2026-09-01; git -C "$D" branch claude-code/task-005-parser; echo "# change" >> "$D/src/core/parser.py"; gadd 2026-09-10 code
grun; has '^WARN W2 docs/mkb/knowledge/modules/MODULE-CORE.md: code changed on 2026-09-10, after the last change of this doc on 2026-09-01'; has '^WARN W2 docs/mkb/knowledge/services/SERVICE-API.md: '; hasnt 'W2 docs/mkb/knowledge/database'
run --root "$D" --no-git --today $TD; tot 0 0
t git-W2-same-day; ginit 2026-09-01; echo "# change" >> "$D/src/core/parser.py"; gadd 2026-09-01 code-same-day; git -C "$D" branch claude-code/task-005-parser; grun; hasnt 'W2'
t git-W2-both; ginit 2026-09-01; echo "# change" >> "$D/src/core/parser.py"; echo "More." >> "$D/docs/mkb/knowledge/modules/MODULE-CORE.md"; gadd 2026-09-10 both; git -C "$D" branch claude-code/task-005-parser
grun; hasnt 'W2 docs/mkb/knowledge/modules/MODULE-CORE.md'; has 'W2 docs/mkb/knowledge/services/SERVICE-API.md'
t git-W2-doc-later; ginit 2026-09-01; echo "# change" >> "$D/src/core/parser.py"; gadd 2026-09-10 code; echo "Checked." >> "$D/docs/mkb/knowledge/modules/MODULE-CORE.md"; gadd 2026-09-12 doc; grun; hasnt 'W2 docs/mkb/knowledge/modules/MODULE-CORE.md'
t git-W3; ed_ knowledge/modules/MODULE-CORE.md 's/^code: .*/code: [src\/core\/, src\/missing\/]/'; ginit 2026-09-20; git -C "$D" branch claude-code/task-005-parser; grun; has '^WARN W3 docs/mkb/knowledge/modules/MODULE-CORE.md: code path src/missing/ does not exist'; cnt '^WARN' 1
run --root "$D" --no-git --today $TD; tot 0 0
t git-W6-old-branch; ginit 2026-09-01; git -C "$D" branch claude-code/task-005-parser; grun; has '^WARN W6 docs/mkb/tasks/TASK-005.md: in progress; no commit on branch claude-code/task-005-parser since 2026-09-01'
t git-W6-fresh-branch; ginit 2026-09-01; git -C "$D" checkout -q -b claude-code/task-005-parser; echo "# wip" >> "$D/src/core/parser.py"; gadd 2026-09-20 wip; git -C "$D" checkout -q main
grun; hasnt 'W6'
t git-W6-remote-only; ginit 2026-09-01; git -C "$D" checkout -q -b tmp; gc 2026-09-20 wip; git -C "$D" update-ref refs/remotes/origin/claude-code/task-005-parser HEAD; git -C "$D" checkout -q main; git -C "$D" branch -D -q tmp; grun; hasnt 'W6'
t git-W6-not-found; ginit 2026-09-20; grun; has '^WARN W6 docs/mkb/tasks/TASK-005.md: in progress; branch claude-code/task-005-parser not found'
t git-W6-pending-old; ed_ tasks/TASK-005.md 's/^branch: .*/branch: pending/'; ginit 2026-09-01; gc 2026-09-20 unrelated; grun; has '^WARN W6 docs/mkb/tasks/TASK-005.md: in progress; task file on the default branch unchanged since 2026-09-01'
t git-W6-pending-fresh; ed_ tasks/TASK-005.md 's/^branch: .*/branch: pending/'; ginit 2026-09-01; echo "- 2026-09-20 alice: dispatched" >> "$D/docs/mkb/tasks/TASK-005.md"; gadd 2026-09-20 note; grun; hasnt 'W6'
t git-W6-default-branch; ed_ tasks/TASK-005.md 's/^branch: .*/branch: main/'; ginit 2026-09-01; gc 2026-09-22 unrelated; grun; has '^WARN W6 docs/mkb/tasks/TASK-005.md: in progress; task file on the default branch unchanged since 2026-09-01'
t git-W14-old; ginit 2026-09-01; git -C "$D" branch claude-code/task-005-parser; grun; has '^WARN W14 docs/mkb/tasks/TASK-004.md: blocked and unchanged since 2026-09-01'
t git-W14-fresh; ginit 2026-09-01; echo "- 2026-09-20 bob: still waiting" >> "$D/docs/mkb/tasks/TASK-004.md"; gadd 2026-09-20 note; git -C "$D" checkout -q -b claude-code/task-005-parser; gc 2026-09-21 wip; git -C "$D" checkout -q main; grun; hasnt 'W14'; hasnt 'W6'
t git-nogit-silent; ginit 2026-09-01; git -C "$D" branch claude-code/task-005-parser; echo "# change" >> "$D/src/core/parser.py"; gadd 2026-09-10 code; run --root "$D" --no-git --today $TD; tot 0 0
t git-default-root-subdir; git -C "$D" init -q -b main; git -C "$D" config core.autocrlf false; git -C "$D" add -A; gc 2026-09-20 init; git -C "$D" branch claude-code/task-005-parser
OUT=$(cd "$D/src/core" && "$SHX" "$CHK" --today $TD 2>&1); tot 0 0
t not-a-repo-note; run --root "$D" --today $TD; tot 0 0; OUT=$ERR; has 'not a git work tree'

echo "RESULT ($SHX): $PASS passed, $FAIL failed, $N cases"
[ "$FAIL" = 0 ] && rm -rf "$W"
[ "$FAIL" = 0 ]
