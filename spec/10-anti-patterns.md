# 10. Anti-patterns

*MKB Standard v1.0 · 2026-09-23 · Normative*

This chapter lists practices that make the MKB rot, conflict or mislead its readers, whether a human or an agent follows them.
Items 1 to 8 come from the original brief; items 9 to 38 are specific to this standard.
Each entry gives the anti-pattern, why it hurts, and the rule that prevents it; the normative wording of each rule is in the chapter named.

## 10.1 From the brief

1. **One giant `Handoff.md` or any catch-all notes file.**
   - Why it hurts: it grows without bound, conflicts on every parallel edit and mixes knowledge, state and history until nobody can tell what is still true.
   - Prevented by: every record is its own file in the tree of [02-directory-structure.md](02-directory-structure.md) §2.1; a handoff covers one unfinished task in at most 30 lines ([06-handoff.md](06-handoff.md) §6.3); an existing monolithic file is migrated once ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.3).

2. **The same information in several documents.**
   - Why it hurts: the copies drift apart, and a reader cannot tell which one is right.
   - Prevented by: refer to records by bare ID and never copy content from one doc into another ([04-naming-and-linking.md](04-naming-and-linking.md) §4.8); record each discovery in its home doc ([05-agent-workflow.md](05-agent-workflow.md) §5.5).

3. **Documenting every code change; git records changes, the MKB records knowledge.**
   - Why it hurts: change logs bury the few facts that matter and are outdated by the next change.
   - Prevented by: trigger T22: when nothing durable changed, update nothing, and the commit message is the record ([05-agent-workflow.md](05-agent-workflow.md) §5.6).

4. **An ADR for a trivial implementation choice.**
   - Why it hurts: trivial ADRs dilute the decision log and freeze choices that should stay cheap to change.
   - Prevented by: write an ADR only when both conditions of [07-decisions.md](07-decisions.md) §7.1 hold, and never for naming, formatting, local refactors or bug fixes ([07-decisions.md](07-decisions.md) §7.2).

5. **Stale "current state" left indefinitely.**
   - Why it hurts: sessions act on a deployment, breakage or freeze that is no longer true.
   - Prevented by: dated `state/CURRENT.md` bullets, deleted when no longer true ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.12), and W5 at gardening ([09-lifecycle.md](09-lifecycle.md) §9.4).

6. **Dozens of unnecessary Markdown files: empty stubs, placeholder directories, one-file ceremonies.**
   - Why it hurts: readers open files that hold nothing, and the tree hides the few docs that matter.
   - Prevented by: a directory exists only once it holds a file, with no `.gitkeep` and no empty placeholder files ([02-directory-structure.md](02-directory-structure.md) §2.5); a record is created only when a trigger fires ([05-agent-workflow.md](05-agent-workflow.md) §5.6).

7. **Documentation as a replacement for reading the source code.**
   - Why it hurts: docs lag behind the code, so a change based on docs alone fits a system that no longer exists.
   - Prevented by: code and tests are the truth for what the system does, and a descriptive doc that disagrees with the code is wrong ([01-architecture.md](01-architecture.md) §1.7); never change code to match a descriptive doc ([05-agent-workflow.md](05-agent-workflow.md) §5.7).

8. **Making an agent read the entire MKB for every task.**
   - Why it hurts: it fills the context window and buries the few docs that bind the change.
   - Prevented by: the discovery algorithm triages hits by their front matter and reads at most 5 docs in full ([05-agent-workflow.md](05-agent-workflow.md) §5.3); INDEX routes instead of listing ([02-directory-structure.md](02-directory-structure.md) §2.4).

## 10.2 Specific to this standard

9. **Status tracked in two places: a task file plus a board, list or blocker file.**
   - Why it hurts: the copies disagree after the first missed edit, and the shared list becomes a hot file on parallel branches.
   - Prevented by: status lives only in the task's front matter, and board views are `git grep` queries, never committed files ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.8); a blocker is `status: blocked` plus `blocked_by` ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.7).

10. **Hand-maintained catalogs: INDEX listing every doc; committed generated boards or doc lists.**
    - Why it hurts: every new record edits the catalog, so it conflicts on parallel branches and falls out of date.
    - Prevented by: INDEX never lists individual tasks, ADRs, questions or knowledge docs, and changes only when the layout, routing, people or path overrides change ([02-directory-structure.md](02-directory-structure.md) §2.4); records are found by ID with `git grep` ([04-naming-and-linking.md](04-naming-and-linking.md) §4.8).

11. **`updated:` fields or "Last updated" lines.**
    - Why it hurts: the bumped line conflicts on every concurrent edit, and git already records edit dates.
    - Prevented by: `updated` is a field deliberately not used ([03-metadata.md](03-metadata.md) §3.6), and no "Last updated" lines anywhere ([12-concurrency.md](12-concurrency.md) §12.4).

12. **A handoff used as a diary, or restating the task.**
    - Why it hurts: the next session digs the next step out of a narrative, and the copied task text drifts from the task file.
    - Prevented by: fixed sections and at most 30 lines, with no narrative of the session and no task definition ([06-handoff.md](06-handoff.md) §6.3, §6.4).

13. **Durable knowledge parked in a handoff "for later".**
    - Why it hurts: nobody outside the task branch sees it, and it is lost when the handoff is deleted.
    - Prevented by: durable knowledge goes to its home doc now, and the handoff points to its ID ([06-handoff.md](06-handoff.md) §6.4); T3 moves lasting lines before the handoff is deleted ([05-agent-workflow.md](05-agent-workflow.md) §5.6).

14. **One shared handoff file that every session overwrites.**
    - Why it hurts: parallel sessions silently overwrite each other's notes.
    - Prevented by: one handoff per unfinished task, `handoff/TASK-NNN.md` on the task branch, with exactly one writer ([06-handoff.md](06-handoff.md) §6.2, §6.8).

15. **Editing another actor's claimed task or handoff.**
    - Why it hurts: two writers on one record lose each other's updates and blur who owns the work.
    - Prevented by: only the owner edits a claimed task, and anyone may append a Notes line ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.3); only the task owner writes its handoff ([06-handoff.md](06-handoff.md) §6.5).

16. **Invisible claims: a claim that was edited locally but never pushed, or made only in chat.**
    - Why it hurts: another actor claims the same task, and two actors do the same work.
    - Prevented by: claim before coding with a coordination commit pushed to the default branch, and never code on an unpushed claim ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.4).

17. **Two writers on one branch or worktree (a cloud agent and a local agent; a human inside an agent's worktree).**
    - Why it hurts: commits interleave, pushes are rejected or overwrite each other, and nobody knows which state is current.
    - Prevented by: one work item, one branch, one writer, one worktree ([12-concurrency.md](12-concurrency.md) §12.1, §12.7).

18. **Regenerating an MKB file from memory instead of patching the current file.**
    - Why it hurts: the in-context copy may be hours old, so the rewrite silently erases other actors' changes.
    - Prevented by: re-read the file from disk right before editing it, and patch only the lines you mean to change ([12-concurrency.md](12-concurrency.md) §12.5).

19. **Reformatting, re-wrapping, re-sorting or column-aligning shared files.**
    - Why it hurts: a formatting change touches many lines and turns the next parallel edit into a conflict.
    - Prevented by: one sentence per line, tables never column-aligned, and existing lines never sorted, reordered or reformatted ([12-concurrency.md](12-concurrency.md) §12.4).

20. **Resolving MKB conflicts with `-X ours`, `-X theirs` or "accept all".**
    - Why it hurts: it drops the other side's claims, answers or facts unread, and during a rebase "ours" means the upstream side.
    - Prevented by: resolve each MKB conflict by file kind with the conflict cookbook ([12-concurrency.md](12-concurrency.md) §12.6).

21. **Allocating IDs from a stale local tree; keeping a new TASK or Q file on a branch instead of pushing it to the default branch at once; reusing a deleted or archived number; renumbering an ID on the default branch.**
    - Why it hurts: two records get the same number, or existing references suddenly point at a different record.
    - Prevented by: allocate from every fetched ref, push a new TASK or Q file to the default branch at once, and never reuse a number ([04-naming-and-linking.md](04-naming-and-linking.md) §4.3); the branch that merges second renumbers its own item ([04-naming-and-linking.md](04-naming-and-linking.md) §4.4).

22. **Slugs in ID file names (`ADR-007-use-redis.md`), which make ID collisions silent.**
    - Why it hurts: two branches that add the same number with different slugs merge without a conflict, so the duplicate reaches the default branch unnoticed.
    - Prevented by: ID docs are named exactly `<ID>.md`, with no slug ([04-naming-and-linking.md](04-naming-and-linking.md) §4.2); E2 reports a file name that differs from its `id` ([09-lifecycle.md](09-lifecycle.md) §9.7).

23. **Editing an accepted ADR's body; an agent accepting or rejecting an ADR on its own authority; merging a decision that no listed decider approved; editing a constraint to match the code.**
    - Why it hurts: the record of what was decided changes silently, and binding rules end up decided by no human.
    - Prevented by: an accepted ADR's body is frozen ([07-decisions.md](07-decisions.md) §7.5); only a human decides an ADR, and a PR carrying a decision merges only with the approval of a listed decider ([07-decisions.md](07-decisions.md) §7.4); a constraint or ADR is never edited to match the code ([05-agent-workflow.md](05-agent-workflow.md) §5.7).

24. **Merging a `proposed` ADR to the default branch.**
    - Why it hurts: an undecided draft lands where readers and discovery expect only decided records.
    - Prevented by: an ADR reaches the default branch only as `accepted` or `rejected` ([07-decisions.md](07-decisions.md) §7.4).

25. **Bumping `verified` without checking the code.**
    - Why it hurts: the date vouches for a doc nobody checked, and W16 stops asking for the re-check.
    - Prevented by: `verified` records a real check ([03-metadata.md](03-metadata.md) §3.3); never bump `verified` without actually checking the code ([09-lifecycle.md](09-lifecycle.md) §9.5).

26. **Undated state bullets; editing `state/CURRENT.md` for branch progress or finished work.**
    - Why it hurts: nobody can tell whether a bullet is still true, and per-session edits on parallel branches conflict.
    - Prevented by: every bullet has the form `- YYYY-MM-DD <handle>: <fact> (<IDs>)` and describes the default branch and deployments, never branch progress or finished work ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.12); W5 reports undated bullets ([09-lifecycle.md](09-lifecycle.md) §9.7).

27. **Agents reordering `state/NEXT.md` unasked.**
    - Why it hurts: priorities are the lead's call, and a second writer conflicts with the lead.
    - Prevented by: only the lead writes `state/NEXT.md`, or an agent when a human asks in the session ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.12); agents write a `NEXT suggestion:` line instead ([05-agent-workflow.md](05-agent-workflow.md) §5.8).

28. **Linking to heading anchors or code line numbers in durable docs; linking IDs instead of writing them bare.**
    - Why it hurts: anchors and line numbers break on the next edit, and a link to a record breaks when the record is archived or moved.
    - Prevented by: bare IDs everywhere, never linked; sections named in words; line numbers only in handoffs ([04-naming-and-linking.md](04-naming-and-linking.md) §4.8).

29. **Docs that restate code: function lists, parameter tables, diagrams of the obvious.**
    - Why it hurts: they are outdated by the next refactor and cost reading time without adding knowledge.
    - Prevented by: the knowledge threshold: write down only what the code does not make evident within 5 minutes and what meets one of its four conditions ([05-agent-workflow.md](05-agent-workflow.md) §5.5).

30. **Project knowledge copied into AGENTS.md, CLAUDE.md or tool rule files; parallel per-tool rule sets.**
    - Why it hurts: the copies drift, each tool follows a different version, and instruction files grow toward the tools' size limits.
    - Prevented by: one MKB block in root `AGENTS.md`, a root `CLAUDE.md` that imports it, and pointers only for tools that need them ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.5); adoption moves project knowledge found in `AGENTS.md` into the MKB ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.2).

31. **Tool-named files (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`) under `docs/mkb/`.**
    - Why it hurts: Claude Code, Cursor or GitHub Copilot would load such a file as scoped instructions for that subtree.
    - Prevented by: nothing named `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` or `AGENTS.override.md` may exist under `docs/mkb/` ([02-directory-structure.md](02-directory-structure.md) §2.5); E5 reports one ([09-lifecycle.md](09-lifecycle.md) §9.7).

32. **Secrets, credential values, personal data of customers or patients, logs, stack traces or diffs in any MKB file.**
    - Why it hurts: the MKB is committed and shared, git history keeps a leaked secret after it is deleted, and logs bury the knowledge.
    - Prevented by: never put secrets, credential values, personal data of customers or patients, logs longer than 5 lines, stack traces, diffs or chat transcripts in the MKB ([05-agent-workflow.md](05-agent-workflow.md) §5.5, [06-handoff.md](06-handoff.md) §6.4).

33. **A task for every 10-minute fix; two task systems (MKB tasks mirroring an issue tracker).**
    - Why it hurts: the ceremony slows small fixes, and mirrored trackers disagree about status.
    - Prevented by: no task for work finished in the current session ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.1); with an authoritative external tracker, `tasks/` is not used ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.13).

34. **Bulk-generated knowledge docs for code nobody is changing.**
    - Why it hurts: nobody verifies them, so they mislead discovery from the day they are written.
    - Prevented by: at adoption or upgrade, at most the 3 most-changed components get docs ([09-lifecycle.md](09-lifecycle.md) §9.3).

35. **"I will update the docs later": MKB updates belong in the same PR as the change.**
    - Why it hurts: later rarely comes, and meanwhile the default branch holds code and docs that disagree.
    - Prevented by: MKB changes go in the same commit or PR as the code they describe, and a discovery is recorded when it is made ([05-agent-workflow.md](05-agent-workflow.md) §5.5); T11 updates the knowledge doc in the same PR ([05-agent-workflow.md](05-agent-workflow.md) §5.6).

36. **Blockers without an owner: `blocked_by` pointing at nothing actionable, or a reason written only in prose.**
    - Why it hurts: nobody is responsible for clearing the blocker, so the task stays blocked.
    - Prevented by: every blocker is an owned task or question, and an external impediment becomes a task owned by the human who chases it ([08-tasks-and-questions.md](08-tasks-and-questions.md) §8.7); W12 and W14 catch forgotten blocks ([09-lifecycle.md](09-lifecycle.md) §9.4).

37. **Reading `tasks/archive/`, `templates/` or superseded ADRs by default.**
    - Why it hurts: it spends context on text that is not authoritative and may contradict the current rules.
    - Prevented by: discovery never reads them by default ([05-agent-workflow.md](05-agent-workflow.md) §5.3), and they are never authoritative ([01-architecture.md](01-architecture.md) §1.7).

38. **Leaving template guide comments in real files.**
    - Why it hurts: they add noise to every read and make a filled doc look unfinished.
    - Prevented by: whoever creates a real file from a skeleton deletes every guide comment, as adoption does ([13-adoption-and-integration.md](13-adoption-and-integration.md) §13.1); W11 reports leftovers ([09-lifecycle.md](09-lifecycle.md) §9.7).
