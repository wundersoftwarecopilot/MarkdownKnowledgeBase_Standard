# 7. Decisions

*MKB Standard v1.0 · 2026-09-23 · Normative*

An architecture decision record (ADR) keeps one decision together with its context, the alternatives weighed and its consequences.
This chapter says when to write an ADR, what it contains, who decides its status and how an accepted decision is replaced.
ADR IDs, their allocation and ID collisions are defined in [04-naming-and-linking.md](04-naming-and-linking.md) §4.1, §4.3 and §4.4; the ADR front matter schema is in [03-metadata.md](03-metadata.md) §3.5.
Trigger rows `T<n>` are those of the update-trigger matrix in [05-agent-workflow.md](05-agent-workflow.md) §5.6.
Examples use the fictional TareLog project of [examples/tarelog/WALKTHROUGH.md](../examples/tarelog/WALKTHROUGH.md).

## 7.1 When to write an ADR

Write an ADR when BOTH hold:

1. at least two viable alternatives were weighed, and
2. at least one of these is true:
   - the choice is expensive to reverse (data format, storage, public API, protocol, persisted schema);
   - it crosses a module or service boundary, or changes an external contract;
   - it adds or removes a significant dependency, service or piece of infrastructure;
   - it knowingly accepts a trade-off or risk (security, compliance, performance);
   - it sets a project-wide rule, or deviates from an existing ADR, constraint or convention;
   - a competent newcomer would plausibly "clean it up" back or reopen the debate.

A decision that passes this test becomes a `proposed` ADR on your branch when you make it ([05-agent-workflow.md](05-agent-workflow.md) §5.5, trigger T9).

Note: the first condition keeps out choices that nobody weighed; the second keeps out weighed choices that are cheap to change and that nobody will reopen.

Example: the TareLog ADRs written during work, and the condition each one meets.

| ADR | Alternatives weighed | Condition met |
|---|---|---|
| ADR-002 Render daily reports as PDF with headless Chromium | headless Chromium, ReportLab, HTML e-mail | adds a significant dependency (headless Chromium) |
| ADR-003 Deliver daily reports as CSV instead of PDF | CSV, or keep the PDF of ADR-002 | changes an external contract (the files Beta Haulage receives) and deviates from an existing ADR |

## 7.2 When not to write an ADR

Do NOT write an ADR for: naming, formatting, local refactors, bug fixes, a library choice internal to one module that is easy to change, anything already dictated by CONSTRAINTS.md or an accepted ADR (cite that ID instead), anything whose rationale fits in a code comment.
If unsure, record the reasoning in the task's Completion section; promote it to an ADR if someone reopens the debate.

An ADR for a trivial implementation choice is anti-pattern 4 of [10-anti-patterns.md](10-anti-patterns.md).

Example: TareLog work that got no ADR.

- Replacing the regular expression that parsed WI-200 frames with a real parser (TASK-002): internal to `src/tarelog/gateway/` and easy to change; the frame format it follows is a fact about the device and lives in INT-WI200.
- Never updating or deleting a stored ticket: already dictated by `docs/mkb/project/CONSTRAINTS.md` (tickets are legal-for-trade records), so there is nothing to decide.
- Retrying a failed SFTP upload 3 times before sending an alert e-mail (TASK-004): the rationale fits in a code comment next to the retry.

## 7.3 File and format

An ADR is the file `docs/mkb/decisions/ADR-NNN.md` (no slug), created from the skeleton `docs/mkb/templates/ADR.md` shown below, at most 100 lines.
The H1 states the decision (`# ADR-003: Deliver daily reports as CSV instead of PDF`).
`date` is the decision date (while `proposed`, the date proposed).

```markdown
---
id: ADR-NNN
type: adr
status: proposed
date: YYYY-MM-DD
related: [<ID>]
---
# ADR-NNN: <the decision as a short statement>

## Context
<!-- guide: facts and forces that led here, 3-10 lines; cite constraints by file and section, sources by link. -->

## Problem
<!-- guide: the question being decided, 1-2 sentences. -->

## Decision
<!-- guide: what we will do, specific enough to check code against. -->

## Alternatives considered
<!-- guide: at least one, "- <option>: why not" per line. -->

## Consequences
<!-- guide: what becomes easier, harder or riskier; what must now stay true; follow-up TASK IDs. -->
```

Keys added later, template order preferred (not checked): `deciders` after `date`; `supersedes` after `deciders`; `superseded_by` after `supersedes`; `formerly` last.

The elements a decision record needs map to the file as follows: context `## Context`; problem `## Problem`; decision `## Decision`; alternatives considered `## Alternatives considered`; consequences `## Consequences`; date `date`; related components and tasks `related`.

Create the file on your work branch, numbered with `sh docs/mkb/tools/mkb-check.sh next ADR`; it stays `proposed` there ([04-naming-and-linking.md](04-naming-and-linking.md) §4.3).
Delete every guide comment when you fill the file (anti-pattern 38).
In a project that adopted an existing ADR directory, new ADRs go there instead (§7.9).

## 7.4 Statuses and who decides

- `proposed` -> `accepted` or `rejected`: only a human, normally during PR review; the human adds themselves to `deciders` and sets `date`.
- `accepted` -> `superseded` (by a new ADR) or `deprecated` (no longer applies, no replacement).
- Agents create ADRs only as `proposed` and never decide an ADR's status on their own authority.
  An agent MAY write `accepted`, `rejected` or `deprecated` only to record a decision that a named human stated in the current session, and then lists that human in `deciders`.
- An ADR reaches the default branch only as `accepted` or `rejected`: a PR containing a `proposed` ADR MUST NOT be merged until a human decides it.
  In trunk-based work the human decides in the session before the commit.
- A PR that adds an ADR as `accepted` or `rejected`, or changes an ADR's status, MUST NOT merge unless a human listed in that ADR's `deciders` approves it in review or merges it personally.
  In trunk-based work an agent records a decision only while that human is in the session.
- `proposed` ADRs waiting for a decision are listed under `ADR decisions needed` in the PR's `MKB for humans:` lines ([05-agent-workflow.md](05-agent-workflow.md) §5.8).
- Rejected ADRs are kept: they record "we considered this".

The transitions at a glance:

| From | To | Who | Where |
|---|---|---|---|
| (new) | `proposed` | anyone; the only status an agent writes on its own authority | the work branch |
| `proposed` | `accepted` or `rejected` | a human, who is added to `deciders` | the PR (commit `ADR-NNN: accept` or `ADR-NNN: reject`) |
| `accepted` | `superseded` | whoever writes the superseding ADR (§7.6) | the PR of the superseding ADR |
| `accepted` | `deprecated` | only a human (§7.6) | the commit that records the human's decision |

Backfilled ADRs are created as `accepted` directly (§7.8).

Only accepted ADRs bind; proposed, rejected, superseded and deprecated ADRs are never authoritative ([01-architecture.md](01-architecture.md) §1.7).
Status values and their meanings are in [03-metadata.md](03-metadata.md) §3.4.2; the commit subjects are in [04-naming-and-linking.md](04-naming-and-linking.md) §4.6.
A human reviewer who sets the status on an agent's PR branch adds a commit to a branch they did not create, which [12-concurrency.md](12-concurrency.md) §12.1 allows once the session that owns the branch has ended.
When a human in the session tells an agent to break an accepted ADR, the agent follows [05-agent-workflow.md](05-agent-workflow.md) §5.7.

Example: Codex cloud drafted ADR-002 as `proposed` on its branch and listed it as `ADR decisions needed: ADR-002` in the `MKB for humans:` lines of PR #11.
Marta reviewed the PR, set `status: accepted`, `date: 2026-09-03` and `deciders: [marta]` in the commit `ADR-002: accept` on the PR branch, and merged the PR as the listed decider.

## 7.5 Immutability

Once accepted, only `status`, `superseded_by` and typo or broken-link fixes may change.
Anything that changes substance needs a new ADR.

- Code that violates an accepted ADR never leads to editing the ADR to match the code ([05-agent-workflow.md](05-agent-workflow.md) §5.7).
- A merge conflict in an accepted ADR body is resolved by restoring the default branch's version and moving the change into a superseding ADR ([12-concurrency.md](12-concurrency.md) §12.6).
- Editing an accepted ADR's body is anti-pattern 23.

Note: a frozen body is what makes a bare ID a stable reference; code comments, knowledge docs and tasks that cite an accepted ADR keep meaning what they meant when they were written.

## 7.6 Superseding and deprecating

Superseding (one PR):

1. Write the new ADR with `supersedes: [ADR-old]`; its Context says what changed; it replaces the whole old decision, restating any part that survives.
2. On the old ADR set `status: superseded` and `superseded_by: ADR-new`; change nothing else.
3. `git grep -n -w "ADR-old" -- docs/mkb` and repoint knowledge docs, ARCHITECTURE and CONVENTIONS that rely on it.
4. Create tasks for code that must change; code comments citing the old ID are updated when that code is next touched.

The new ADR starts as `proposed` like any other and needs a human decision before the PR merges (§7.4).
This is trigger T10.

Deprecating: only a human sets `status: deprecated`, and nothing else in the ADR changes; the reason goes in the commit message and in the task that removed the component.

Example: after Q-001 was answered, claude-code drafted ADR-003 in PR #14 and marta accepted it in review as the listed decider.
The front matter and H1 of both ADRs after the merge:

```markdown
---
id: ADR-002
type: adr
status: superseded
date: 2026-09-03
deciders: [marta]
superseded_by: ADR-003
related: [TASK-003, MODULE-REPORTS]
---
# ADR-002: Render daily reports as PDF with headless Chromium
```

```markdown
---
id: ADR-003
type: adr
status: accepted
date: 2026-09-10
deciders: [marta]
supersedes: [ADR-002]
related: [TASK-004, TASK-007, MODULE-REPORTS, INT-HAULER-SFTP]
---
# ADR-003: Deliver daily reports as CSV instead of PDF
```

ADR-002 kept its `date` and body; only `status` and `superseded_by` changed.
Step 3 repointed MODULE-REPORTS from ADR-002 to ADR-003; for step 4, the Consequences of ADR-003 cite TASK-007 "Remove the Chromium PDF pipeline".

## 7.7 ADRs and code

Code that embodies a non-obvious decision SHOULD cite the ADR ID in a comment.

The comment carries the bare ID, as every reference from code to the MKB does ([04-naming-and-linking.md](04-naming-and-linking.md) §4.9).
When an ADR is superseded, such comments are updated when that code is next touched (§7.6, step 4).

Example: `# SQLite in WAL mode per ADR-001.` above the connection setup in `src/tarelog/tickets/store.py`.

Discovery reaches ADRs from the code side: a knowledge doc whose `code` covers the path you will touch leads, by one reverse hop, to the ADRs that name its ID ([05-agent-workflow.md](05-agent-workflow.md) §5.3).

Note: the reverse hop finds an ADR only if the ADR names the knowledge doc's ID, in `related` or in its text; ADR-003 lists MODULE-REPORTS and INT-HAULER-SFTP in `related`, so a change under their `code` paths leads to it.

## 7.8 Backfilled ADRs

Backfilled ADRs (migration): `status: accepted`, `date` = the original decision date if the source states it, else the adoption date; `deciders` = the human who confirms during adoption that the decision still holds; the first line of Context is `Recorded retroactively from <source> on YYYY-MM-DD.`

A backfilled ADR comes from migrating a monolithic handoff or notes file, where a paragraph describing a past significant decision becomes an ADR ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.3).
It enters the default branch as `accepted`, so the rule of §7.4 applies: a human listed in its `deciders` approves the adoption PR in review or merges it personally.

Example: the first lines of TareLog's ADR-001, backfilled on 2026-09-01 from the old `Handoff.md`, which states the original decision date:

```markdown
---
id: ADR-001
type: adr
status: accepted
date: 2026-03-10
deciders: [marta]
related: [DB-TICKETS, TS-SQLITE-LOCKED]
---
# ADR-001: Store weighing tickets in SQLite in WAL mode

## Context
Recorded retroactively from Handoff.md on 2026-09-01.
```

## 7.9 Relation to Nygard, adr-tools and MADR

MKB ADRs build on the lightweight format that Michael Nygard described in 2011, whose records have the sections Context, Decision, Status and Consequences.

| MKB element | Relation to Nygard's format |
|---|---|
| `## Context`, `## Decision`, `## Consequences` | same sections |
| `status` | moved from a body section to the front matter, so `git grep -l "^status: accepted" -- docs/mkb/decisions` lists the binding decisions |
| `## Problem` | added: the question being decided, kept apart from the facts in Context |
| `## Alternatives considered` | added: the options weighed, which the test of §7.1 depends on |
| `date`, `deciders`, `supersedes`, `superseded_by`, `related` | MKB-specific: grep-based discovery and the rule that only humans decide (§7.4) |
| file name `ADR-NNN.md`, no slug | MKB-specific: the same ID created twice is an add/add conflict ([04-naming-and-linking.md](04-naming-and-linking.md) §4.4); slugs make ID collisions silent (anti-pattern 22) |

Existing ADR directories, such as adr-tools directories with file names `NNNN-slug.md` or directories of MADR files, are adopted in place: they are never moved or renamed, and old and new ADRs keep the directory's native format, file naming and numbering.
No MKB front matter is added to them, because MADR front matter would clash with the MKB schema.
The MKB ADR rules of §7.1 to §7.8 apply to them; the MKB schema does not.
How new ADRs there get the five MKB sections, how their IDs are written (`ADR-0007`), how native statuses read as MKB statuses, and how numbers are allocated and checked for duplicates is defined in [13-adoption-and-integration.md](13-adoption-and-integration.md) §13.4.
The agent block searches the decisions directory named in INDEX, so agents find adopted ADRs with the same discovery commands (item 4 of `agent-instructions/AGENTS.tmpl.md`).
