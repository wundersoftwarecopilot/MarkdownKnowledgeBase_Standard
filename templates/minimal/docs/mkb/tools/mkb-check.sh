#!/bin/sh
# mkb-check.sh: consistency checker and ID allocator of MKB Standard v1.0.
#   sh docs/mkb/tools/mkb-check.sh [--root DIR] [--no-git] [--adr-dir DIR] [--today YYYY-MM-DD] [--strict] [check]
#   sh docs/mkb/tools/mkb-check.sh [--root DIR] [--no-git] [--adr-dir DIR] next TASK|ADR|Q
# From PowerShell: & "$env:ProgramFiles\Git\bin\bash.exe" docs/mkb/tools/mkb-check.sh
# Output: "ERROR E<n> <path>: <message>", "WARN W<n> <path>: <message>", then "mkb-check: <e> errors, <w> warnings".
# Exit codes: 0 no errors (and no warnings under --strict); 1 errors found; 2 usage error.
# POSIX sh, git, grep -E, sed, awk, find, wc only; dates are computed in awk. Replaced only on MKB version upgrade.

usage() {
  echo "usage: sh docs/mkb/tools/mkb-check.sh [--root DIR] [--no-git] [--adr-dir DIR] [--today YYYY-MM-DD] [--strict] [check]" >&2
  echo "       sh docs/mkb/tools/mkb-check.sh [--root DIR] [--no-git] [--adr-dir DIR] next TASK|ADR|Q" >&2
  [ -n "$1" ] && echo "mkb-check: $1" >&2
  exit 2
}

ROOT= NOGIT=0 ADR= TODAY= STRICT=0 CMD=check KIND=
while [ $# -gt 0 ]; do
  case $1 in
    --root|--adr-dir|--today)
      [ $# -ge 2 ] || usage "$1 needs a value"
      case $1 in --root) ROOT=$2 ;; --adr-dir) ADR=$2 ;; *) TODAY=$2 ;; esac
      shift ;;
    --no-git) NOGIT=1 ;;
    --strict) STRICT=1 ;;
    check) CMD=check ;;
    next) [ $# -ge 2 ] || usage "next needs TASK, ADR or Q"; CMD=next KIND=$2; shift ;;
    *) usage "unknown argument: $1" ;;
  esac
  shift
done

[ -n "$ROOT" ] || ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || ROOT=.
cd "$ROOT" 2>/dev/null || usage "cannot enter root directory $ROOT"
ADR=$(printf '%s\n' "$ADR" | sed 's|\\|/|g'); ADR=${ADR%/}; ADR=${ADR#./}
[ -d docs/mkb ] || usage "no docs/mkb directory under $ROOT"
[ -z "$ADR" ] || [ -d "$ADR" ] || usage "--adr-dir $ADR is not a directory"
if [ "$NOGIT" = 0 ] && ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  NOGIT=1; echo "mkb-check: not a git work tree; running as with --no-git" >&2
fi
if [ "$NOGIT" = 0 ] && [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = true ]; then
  if [ "$CMD" = next ]; then [ "$KIND" = Q ] && usage "shallow clone: run git fetch --unshallow first"
  else NOGIT=1; echo "mkb-check: shallow clone; running as with --no-git" >&2; fi
fi

# next TASK|ADR|Q: 1 + the highest number ever added on any fetched ref, plus files not yet committed (docs/mkb/agents/RULES.md, section 4).
if [ "$CMD" = next ]; then
  case $KIND in
    TASK) d=docs/mkb/tasks ;;
    Q) d=docs/mkb/questions ;;
    ADR) d=${ADR:-docs/mkb/decisions} ;;
    *) usage "next needs TASK, ADR or Q" ;;
  esac
  a=0; [ "$KIND" = ADR ] && [ -n "$ADR" ] && a=1
  h=
  if [ "$NOGIT" = 0 ]; then
    if [ -n "$(git remote 2>/dev/null)" ]; then
      GIT_TERMINAL_PROMPT=0 git fetch --all --quiet || echo "mkb-check: git fetch failed; using the refs already fetched" >&2
    fi
    h=$(git log --all --no-renames --diff-filter=A --name-only --format= -- "$d" 2>/dev/null)
  fi
  w=; [ -d "$d" ] && w=$(find "$d" -type f)
  printf '%s\n%s\n' "$h" "$w" | awk -v k="$KIND" -v a="$a" -v d="$d/" '
    { sub(/\r$/, ""); sub(/^"/, ""); sub(/"$/, ""); p = $0; sub(/.*\//, ""); p = substr(p, 1, length(p) - length($0)) }
    a == 1 {
      if ((p == d || substr(p, length(p) - length(d)) == "/" d) && /\.md$/ && match($0, /^[0-9]+/)) { if (RLENGTH > w) w = RLENGTH; v = substr($0, 1, RLENGTH); sub(/^0+/, "", v); if (v + 0 > n) n = v + 0 }
      next
    }
    $0 ~ ("^" k "-[0-9]+\\.md$") { v = substr($0, length(k) + 2) + 0; if (v > n) n = v }
    END { printf "%s-%0" (w ? w : 3) "d\n", k, n + 1 }'
  exit 0
fi

[ -n "$TODAY" ] || TODAY=$(date +%Y-%m-%d)
DEFREF=
if [ "$NOGIT" = 0 ]; then
  DEFREF=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)
  [ -n "$DEFREF" ] || for r in origin/main origin/master main master; do
    git rev-parse -q --verify "$r^{commit}" >/dev/null 2>&1 && { DEFREF=$r; break; }
  done
fi

find docs/mkb ${ADR:+"$ADR"} -type f -name '*.md' |
LC_ALL=C MKB_TODAY=$TODAY MKB_NOGIT=$NOGIT MKB_ADR=$ADR MKB_STRICT=$STRICT MKB_DEFREF=$DEFREF awk '
function days(s,  y, m, d, e) {
  if (s !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) return -1
  y = substr(s, 1, 4) + 0; m = substr(s, 6, 2) + 0; d = substr(s, 9, 2) + 0
  if (y < 1 || m < 1 || m > 12 || d < 1 || d > substr("312931303130313130313031", 2 * m - 1, 2) - (m == 2 && (y % 4 || (y % 100 == 0 && y % 400)))) return -1
  y -= (m <= 2); e = y - int(y / 400) * 400
  return int(y / 400) * 146097 + e * 365 + int(e / 4) - int(e / 100) + int((153 * (m > 2 ? m - 3 : m + 9) + 2) / 5) + d - 1
}
function old(s, n,  k) { k = days(s); return k >= 0 && T - k > n }
function err(c, f, m) { print "ERROR " c " " f ": " m; ne++ }
function warn(c, f, m) { print "WARN " c " " f ": " m; nw++ }
function g(k) { return (k in V) ? V[k] : "" }
function inl(l, v) { return v !~ / / && index(" " l " ", " " v " ") > 0 }
function handle(s) { return s ~ /^[a-z][a-z0-9-]*$/ && length(s) <= 32 && s != "none" }
function human(s) { return handle(s) && !(s in AGENT) }
function idok(t, s,  w) {
  if (t == "task" || t == "adr" || t == "question") return s ~ ("^" PFX[t] "-[0-9][0-9][0-9][0-9]*$")
  return (t in KN) && s ~ ("^" PFX[t] "-[A-Z][A-Z0-9]*(-[A-Z0-9]+)*$") && length(s) <= 40 && split(s, w, "-") <= 4
}
function idtype(s,  i) { for (i = 1; i <= 8; i++) if (idok(TY[i], s)) return TY[i]; return "" }
function q(s) { gsub(/\047/, "\047\\\047\047", s); return "\047" s "\047" }
function run(c,  r, x) { r = ""; c = c " 2>/dev/null"; while ((c | getline x) > 0) if (x > r) r = x; close(c); return r }
function bads(x) { return x ~ /:[ \t]|:$|[ \t]#|^[][{}>|*&!%@`#,"\047]|^[-?:]([ \t]|$)/ }
function fence(s,  c, n, bq, x, ind) {
  match(s, /^[ \t]*(>[ \t]*)*/); x = substr(s, 1, RLENGTH); s = substr(s, RLENGTH + 1); bq = gsub(/>/, "", x); ind = length(x)
  if (FC != "" && bq < FQ) FC = ""
  c = substr(s, 1, 1)
  if (c != "`" && c != "~") return FC != ""
  n = 1; while (substr(s, n + 1, 1) == c) n++
  if (FC == "") { if (n < 3 || (c == "`" && index(substr(s, n + 1), "`"))) return 0; FC = c; FL = n; FQ = bq; FI = ind; return 1 }
  if (c == FC && n >= FL && bq == FQ && ind <= FI + 3 && substr(s, n + 1) ~ /^[ \t]*$/) FC = ""
  return 1
}
function refs(f, s,  t, b, p) {
  p = ""; if (REL ~ /^tasks\/archive\//) s = ""
  while (match(s, /(TASK|ADR|Q)-[0-9][0-9][0-9][0-9]*|(MODULE|SERVICE|DB|INT|TS)-[A-Z][A-Z0-9]*(-[A-Z0-9]+)*/)) {
    t = substr(s, RSTART, RLENGTH); b = RSTART > 1 ? substr(s, RSTART - 1, 1) : p
    p = substr(t, RLENGTH, 1); s = substr(s, RSTART + RLENGTH)
    if (b !~ /[A-Za-z0-9_]/ && substr(s, 1, 1) !~ /[A-Za-z0-9_]/ && t !~ /^Q-/ && !((f, t) in REF)) { REF[f, t] = 1; RF[++nr] = f; RI[nr] = t }
  }
}
function body(f, s,  k) {
  if (substr(s, 1, 8) == "> STALE ") {
    k = substr(s, 9, 10)
    if (days(k) < 0) warn("W8", f, "STALE banner without a valid date")
    else if (old(k, 30)) warn("W8", f, "STALE banner dated " k " is older than 30 days: fix the doc or delete it")
  }
  if (substr(s, 1, 11) == "<!-- guide:") warn("W11", f, "template guide comment left in place")
  refs(f, s)
  if (REL == "state/CURRENT.md" && s ~ /^[-*+] /) CB[++nc] = s
  if (REL == "state/NEXT.md" && s ~ /^- /) { k = substr(s, 3); sub(/[: ].*/, "", k); if (idok("task", k)) NX[++nx] = k }
  if (REL == "INDEX.md" && s ~ /^\| *conventions *\|/) OVC = 1
}
function cond(f, k, req, forb, st) {
  if (req && !(k in V)) err("E3", f, k " is required when status is " st)
  if (forb && (k in V)) err("E3", f, k " is not allowed when status is " st)
}
function val(f, ty, b, k,  v, j, x, ok) {
  v = V[k]; ok = 1
  if (k in LK) {
    if (IC[k] < 0) return
    if (!IC[k]) { err("E3", f, k " must be a flow list [a, b]"); return }
    for (j = 1; j <= IC[k]; j++) {
      x = IT[k, j]
      if (k == "blocked_by") ok = idok("task", x) || idok("question", x)
      else if (k == "deciders") ok = human(x)
      else if (k == "supersedes") ok = idok("adr", x)
      else if (k == "related") ok = x ~ /^[A-Z][A-Z0-9]*-[A-Z0-9]+(-[A-Z0-9]+)*$/
      else ok = x !~ /^\.?\/|[*?]|(^|\/)\.\.(\/|$)/ && (x ~ /\/$/ || system("test -d " q(x)))
      if (!ok) err("E3", f, "invalid " k " item " x)
    }
    return
  }
  if (IC[k]) { err("E3", f, k " must be a single value, not a list"); return }
  if (k == "id") { ok = idok(ty, v); if (v != b) err("E2", f, "file name differs from id " v) }
  else if (k == "status") ok = inl(STV[ty], v)
  else if (k == "priority") ok = inl("critical high normal low", v)
  else if (k == "owner") ok = (ty == "task") ? (v == "none" || handle(v)) : human(v)
  else if (k == "asked_by") ok = handle(v)
  else if (k == "branch") ok = v !~ /[ \t~^:?*\\[]|\.\.|@\{|^[-\/]|\/$|\.$|\.lock$|\/\//
  else if (k ~ /^(created|closed|date|verified)$/) ok = days(v) >= 0
  else if (k == "superseded_by") ok = idok("adr", v)
  else if (k == "formerly") ok = (ty in KN) ? (idtype(v) in KN) : idok(ty, v)
  else if (k == "summary") { x = v; gsub(/[\200-\277]/, "", x); ok = length(x) <= 120 }
  else if (k == "mkb_version") ok = v == "\"1.0\""
  else if (k == "profile") ok = inl("minimal full", v)
  if (!ok) err("E3", f, "invalid " k " " v)
}
function w6(f, br,  c) {
  if (br == "pending" || br == DEFNAME) {
    c = run("git log -1 --format=%cs " (DEFREF == "" ? "HEAD" : q(DEFREF)) " -- " q(f))
    if (old(c, 7)) warn("W6", f, "in progress; task file on the default branch unchanged since " c)
    return
  }
  c = run("git for-each-ref \047--format=%(committerdate:short)\047 " q("refs/heads/" br) " " q("refs/remotes/*/" br))
  if (c == "") warn("W6", f, "in progress; branch " br " not found")
  else if (old(c, 7)) warn("W6", f, "in progress; no commit on branch " br " since " c)
}
function file(f,  b, d, t, cls, s, nl, fm, fe, nk, n, i, j, k, v, x, p, st, ty, c, dd, h1, h2, ns, bom) {
  b = f; sub(/.*\//, "", b)
  if (f ~ /^docs\/mkb\// && tolower(b) ~ /^(agents|claude|gemini|agents\.override)\.md$/) err("E5", f, "tool instruction file inside docs/mkb")
  sub(/\.md$/, "", b); AD = ADR != "" && index(f, ADR "/") == 1
  if (AD && f == ADR "/" b ".md" && match(b, /^[0-9]+/)) {
    k = substr(b, 1, RLENGTH); sub(/^0+/, "", k); k += 0
    if (k in ADRN) err("E1", f, "leading number " k " also used by " ADRN[k]); else ADRN[k] = f
  }
  if (f !~ /^docs\/mkb\// || f ~ /^docs\/mkb\/templates\//) return
  REL = substr(f, 10); d = REL; sub(/[^\/]*$/, "", d); t = ""
  if (REL == "state/CURRENT.md") CP = f
  if (REL == "state/NEXT.md") NP = f
  if (AD) cls = "other"
  else if (d == "handoff/") cls = "handoff"
  else if (REL in SING) { cls = "fm"; t = SING[REL] }
  else if (REL in NOFM) cls = "nofm"
  else if (d ~ /^(decisions|tasks|questions|knowledge)\//) { cls = "fm"; if (d in DT) t = DT[d] }
  else cls = "other"
  if (cls != "handoff") HAVE[b] = 1
  if (cls != "handoff" && !AD) {
    k = idtype(b)
    if (k != "" && d != DIRT[k] && !(k == "task" && d == "tasks/archive/")) { err("E4", f, b " belongs in docs/mkb/" DIRT[k]); if (cls == "fm") t = k }
  }
  nl = fm = nk = ns = bom = 0; FC = ""; h1 = h2 = ""
  while ((getline s < f) > 0) {
    nl++; sub(/[ \t\r]+$/, "", s)
    if (nl == 1 && sub(/^\357\273\277/, "", s)) bom = 1
    if (nl == 1 && s == "---") { fm = 1; continue }
    if (fm == 1) { if (s == "---") { fm = 2; fe = nl } else { FMX[++nk] = s; if (cls != "handoff" && s !~ /^formerly:/) refs(f, s) } continue }
    if (fm == 2 && nl == fe + 1) h1 = s
    if (fm == 2 && nl == fe + 2) h2 = s
    if (!ns && REL == "agents/RULES.md" && s ~ /^## 16\. /) ns = nl - 1
    if (!fence(s) && cls != "handoff") body(f, s)
  }
  close(f)
  if (cls == "handoff") {
    if (fm) err("E3", f, "front matter is not allowed in a handoff")
    if (nl > 30) warn("W1", f, nl " lines, budget 30")
    HO[++nh] = f; HB[nh] = b; return
  }
  if (cls == "nofm" && fm) err("E3", f, "front matter is not allowed in this file")
  k = (REL in SB) ? SB[REL] : (t in BT) ? BT[t] : 0
  if (ns) nl = ns
  if (k && nl > k) warn("W1", f, nl " lines" (ns ? " above section 16" : "") ", budget " k)
  if (cls != "fm") return
  if (bom) err("E3", f, "the file starts with a UTF-8 byte order mark: save it as UTF-8 without BOM")
  if (!fm) { err("E3", f, "missing front matter"); return }
  if (fm == 1) { err("E3", f, "front matter is not closed by a line ---"); return }
  if (h1 !~ /^# / && (h1 != "" || h2 !~ /^# /)) err("E3", f, "the H1 must follow the closing --- (one blank line tolerated)")
  split("", V); split("", IC); n = 0
  for (i = 1; i <= nk; i++) {
    s = FMX[i]
    if (s !~ /^[a-z][a-z0-9_]*: +[^ \t]/) { err("E3", f, "invalid front matter line: " s); continue }
    k = s; sub(/:.*/, "", k); v = substr(s, length(k) + 2); gsub(/^[ \t]+|[ \t]+$/, "", v)
    if (k in V) { err("E3", f, "duplicate key " k); continue }
    V[k] = v; KO[++n] = k
    if (n == 13) err("E3", f, "more than 12 keys")
    if (substr(v, 1, 1) != "[") { if (k != "mkb_version" && bads(v)) { err("E3", f, "value of " k " breaks the MKB YAML subset: " v); IC[k] = -1 } continue }
    if (v !~ /^\[[^][{}]*\]$/ || v ~ /^\[[ \t]*\]$/) { err("E3", f, "invalid flow list in " k ": " v); IC[k] = -1; continue }
    IC[k] = split(substr(v, 2, length(v) - 2), x, ",")
    for (j = 1; j <= IC[k]; j++) {
      gsub(/^[ \t]+|[ \t]+$/, "", x[j]); IT[k, j] = x[j]
      if (x[j] == "" || bads(x[j])) { err("E3", f, "invalid item in " k ": " v); IC[k] = -1; break }
    }
  }
  if (!("type" in V)) { err("E3", f, "missing required key type"); return }
  ty = V["type"]
  if (!(ty in KEYS)) { err("E3", f, "invalid type " ty); return }
  if (t != "" && ty != t) { err("E3", f, "type " ty " does not fit this location, expected " t); return }
  for (i = 1; i <= n; i++) { k = KO[i]; if (!index(KEYS[ty], " " k " ")) err("E3", f, "unknown key " k); else if (IC[k] >= 0) val(f, ty, b, k) }
  c = split(REQ[ty], x, " ")
  for (i = 1; i <= c; i++) if (!(x[i] in V)) err("E3", f, "missing required key " x[i])
  st = g("status")
  if (ty == "task" && inl(STV[ty], st)) {
    if (st ~ /^(in-progress|done)$/ && g("owner") == "none") err("E3", f, "owner must not be none when status is " st)
    cond(f, "branch", st == "in-progress", st == "todo", st)
    cond(f, "closed", st ~ /^(done|dropped)$/, st !~ /^(done|dropped)$/, st)
    cond(f, "blocked_by", st == "blocked", st != "blocked", st)
  }
  if (ty == "adr" && inl(STV[ty], st)) { cond(f, "deciders", st != "proposed", 0, st); cond(f, "superseded_by", st == "superseded", st != "superseded", st) }
  if ("id" in V) { if (V["id"] in IDS) err("E1", f, "id " V["id"] " also used by " IDS[V["id"]]); else IDS[V["id"]] = f }
  if (ty == "index") PROFILE = g("profile")
  if (ty == "task") {
    TS[b] = st
    if (d == "tasks/" && st ~ /^(done|dropped)$/ && old(g("closed"), 30)) warn("W9", f, st " and closed " g("closed") ", more than 30 days ago: archive it")
    if (g("priority") == "low" && st !~ /^(done|dropped)$/ && old(g("created"), 90)) warn("W17", f, "low priority, created " g("created") ", more than 90 days ago: propose dropping it")
    if (st == "blocked" && IC["blocked_by"] > 0) { BK[++nb] = f; BI[nb] = ""; for (j = 1; j <= IC["blocked_by"]; j++) BI[nb] = BI[nb] " " IT["blocked_by", j] }
    if (!NOGIT && st == "in-progress" && ("branch" in V)) w6(f, V["branch"])
    if (!NOGIT && st == "blocked") { c = run("git log -1 --format=%cs -- " q(f)); if (old(c, 14)) warn("W14", f, "blocked and unchanged since " c) }
  }
  if (ty == "question" && st == "answered") warn("W7", f, "answered: promote the answer, then delete the question")
  if (ty == "question" && st == "open" && old(g("created"), 14)) warn("W15", f, "open since " g("created") ", more than 14 days: remind the owner")
  if (((ty in KN) || ty == "architecture") && old(g("verified"), 180)) warn("W16", f, "verified " g("verified") ", more than 180 days ago: re-verify the whole doc")
  if (!NOGIT && (ty in KN) && IC["code"] > 0) {
    p = ""
    for (j = 1; j <= IC["code"]; j++) { v = IT["code", j]; p = p " " q(v); if (system("test -e " q(v))) warn("W3", f, "code path " v " does not exist") }
    c = run("git log -1 --format=%cs --" p); dd = run("git log -1 --format=%cs -- " q(f))
    if (c != "" && dd != "" && c > dd) warn("W2", f, "code changed on " c ", after the last change of this doc on " dd)
  }
}
BEGIN {
  T = days(ENVIRON["MKB_TODAY"])
  if (T < 0) { print "mkb-check: --today must be a valid YYYY-MM-DD date" > "/dev/stderr"; bad = 1; exit 2 }
  NOGIT = ENVIRON["MKB_NOGIT"] + 0; STRICT = ENVIRON["MKB_STRICT"] + 0; ADR = ENVIRON["MKB_ADR"]
  DEFREF = ENVIRON["MKB_DEFREF"]; DEFNAME = DEFREF; sub(/^origin\//, "", DEFNAME)
  split("task adr question module service database integration troubleshooting", TY, " ")
  split("TASK ADR Q MODULE SERVICE DB INT TS", x, " ")
  split("tasks/ decisions/ questions/ knowledge/modules/ knowledge/services/ knowledge/database/ knowledge/integrations/ knowledge/troubleshooting/", y, " ")
  split("60 100 40 150 150 150 150 60", z, " ")
  for (i = 1; i <= 8; i++) {
    PFX[TY[i]] = x[i]; DIRT[TY[i]] = y[i]; DT[y[i]] = TY[i]; BT[TY[i]] = z[i]
    if (i > 3) { KN[TY[i]] = 1; KEYS[TY[i]] = " id type summary code verified related formerly "; REQ[TY[i]] = "id type summary verified" (i < 7 ? " code" : "") }
  }
  DT["tasks/archive/"] = "task"
  KEYS["task"] = " id type status priority owner branch created closed blocked_by related code formerly "
  KEYS["adr"] = " id type status date deciders supersedes superseded_by related formerly "
  KEYS["question"] = " id type status owner asked_by created related formerly "
  KEYS["index"] = " type mkb_version profile "; KEYS["rules"] = " type mkb_version "; KEYS["architecture"] = " type verified "
  REQ["task"] = "id type status priority owner created"; REQ["adr"] = "id type status date"
  REQ["question"] = "id type status owner asked_by created"; REQ["index"] = "type mkb_version profile"
  REQ["rules"] = "type mkb_version"; REQ["architecture"] = "type verified"
  STV["task"] = "todo in-progress blocked done dropped"; STV["adr"] = "proposed accepted rejected superseded deprecated"; STV["question"] = "open answered"
  c = split("claude-code codex cursor gemini-cli aider copilot windsurf agent", x, " "); for (i = 1; i <= c; i++) AGENT[x[i]] = 1
  c = split("blocked_by deciders supersedes related code", x, " "); for (i = 1; i <= c; i++) LK[x[i]] = 1
  SING["INDEX.md"] = "index"; SING["agents/RULES.md"] = "rules"; SING["project/ARCHITECTURE.md"] = "architecture"
  c = split("INDEX.md 120 agents/RULES.md 500 project/OVERVIEW.md 80 project/ARCHITECTURE.md 150 project/CONSTRAINTS.md 80 project/CONVENTIONS.md 120 state/CURRENT.md 40 state/NEXT.md 15", x, " ")
  for (i = 1; i < c; i += 2) SB[x[i]] = x[i + 1]
  c = split("project/OVERVIEW.md project/CONSTRAINTS.md project/CONVENTIONS.md state/CURRENT.md state/NEXT.md", x, " "); for (i = 1; i <= c; i++) NOFM[x[i]] = 1
}
{ sub(/\r$/, ""); if ($0 != "") F[++nfile] = $0 }
END {
  if (bad) exit 2
  for (i = 2; i <= nfile; i++) { tmp = F[i]; for (j = i - 1; j > 0 && F[j] > tmp; j--) F[j + 1] = F[j]; F[j + 1] = tmp }
  for (i = 1; i <= nfile; i++) if (!(F[i] in DONE)) { DONE[F[i]] = 1; file(F[i]) }
  c = split("INDEX.md agents/RULES.md project/OVERVIEW.md project/CONSTRAINTS.md state/CURRENT.md state/NEXT.md" (PROFILE == "full" ? " project/ARCHITECTURE.md" (OVC ? "" : " project/CONVENTIONS.md") : ""), x, " ")
  for (i = 1; i <= c; i++) if (!(("docs/mkb/" x[i]) in DONE)) err("E6", "docs/mkb/" x[i], "mandatory file is missing")
  lim = (PROFILE == "minimal") ? 35 : 14
  for (i = 1; i <= nc; i++) {
    s = CB[i]; k = substr(s, 3, 10)
    if (s !~ /^- [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [a-z][a-z0-9-]*: ./ || days(k) < 0) warn("W5", CP, "bullet not in the form - YYYY-MM-DD <handle>: <fact>: " substr(s, 1, 60))
    else if (old(k, lim)) warn("W5", CP, "bullet dated " k " is older than " lim " days: re-verify and re-date, or delete")
  }
  for (i = 1; i <= nh; i++) {
    b = HB[i]
    if (idok("task", b)) { if (!(b in HAVE)) warn("W4", HO[i], "its task " b " is missing"); else if (TS[b] ~ /^(done|dropped)$/) warn("W4", HO[i], "its task " b " is " TS[b] ": move lasting lines, then delete") }
    else if (b !~ /^[A-Z][A-Z0-9]*-[0-9]+$/) warn("W4", HO[i], "no work item named " b)
  }
  for (i = 1; i <= nb; i++) {
    c = split(BI[i], x, " "); k = 1
    for (j = 1; j <= c; j++) if ((x[j] in HAVE) && TS[x[j]] !~ /^(done|dropped)$/) k = 0
    if (k) warn("W12", BK[i], "every blocked_by item is missing, done or dropped: clear the block")
  }
  for (i = 1; i <= nx; i++) {
    b = NX[i]
    if (!(b in HAVE)) warn("W13", NP, b " is listed but its task is missing"); else if (TS[b] ~ /^(done|dropped)$/) warn("W13", NP, b " is listed but " TS[b])
  }
  for (i = 1; i <= nr; i++) {
    b = RI[i]; k = substr(b, 5); sub(/^0+/, "", k); k += 0
    if (!(b in HAVE) && !(b ~ /^ADR-/ && (k in ADRN))) warn("W10", RF[i], b " is referenced but has no file")
  }
  printf "mkb-check: %d errors, %d warnings\n", ne, nw
  exit ((ne || (STRICT && nw)) ? 1 : 0)
}'
