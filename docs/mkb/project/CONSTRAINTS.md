# Constraints: MKB Standard

Normative: code, tasks and ADRs MUST respect every rule below.
Only humans change this file; an agent adds a rule only when a human states it in the session, and cites that human as the source.
Entry format: `- <rule>. Source: <person or document>, YYYY-MM-DD.`
Delete sections without entries; if none remain, write `None recorded as of YYYY-MM-DD.`

## Customer and contract
- The standard answers the brief `Prompt_MarkdownKnowledgeBase_Standard.md`; every one of its 15 deliverables stays covered. Source: the brief, 2026-09-23.
- Prefer simplicity over bureaucracy: the goal is persistent, structured, discoverable project memory for humans and agents, not more documentation. Source: the brief, 2026-09-23.
- The brief is not modified. Source: `dev/DESIGN-CONTRACT.md` section R.1, 2026-09-23.

## Platform and environment
- The standard works with Codex, Claude Code, Cursor, Gemini CLI, Aider and human developers, without a proprietary format. Source: the brief, 2026-09-23.
- `mkb-check.sh` uses only POSIX sh, git, grep -E, sed, awk, find and wc; it runs in Git Bash on Windows, Linux and macOS, in at most 450 lines. Source: `dev/DESIGN-CONTRACT.md` section L.7, 2026-09-23.

## Security and data
- No API keys, credentials or other secrets in any file of this repository. Source: claudio's global agent instructions, 2026-09-23.
