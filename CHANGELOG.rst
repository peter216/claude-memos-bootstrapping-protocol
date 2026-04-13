================================
mind.netdevconnect Release Notes
================================

.. contents:: Topics

v1.3.0
======

Release Summary
---------------

This release adds the Remote Control path (Path C) for Claude Code web sessions. The
protocol is now operational on three paths: Path A (Claude Code local, git CLI), Path B
(Claude.ai, gh-mcp MCP server), and Path C (Claude Code Remote Control / web, gh-mcp
MCP server via CLAUDE.md).

Minor Changes
-------------

- ``CLAUDE.md`` — new Path C (Remote Control / Claude Code web) bootstrap instructions
  file; delivers the MCP-based protocol via CLAUDE.md read automatically by Claude Code
  at session start; equivalent to Claude.ai Project instructions (Path B) in logic and
  tool sequence.
- ``docs/REMOTE-CONTROL-IMPLEMENTATION.md`` — new document describing Path C setup,
  requirements, path comparison table, and known limitations.
- ``claude-memos-bootstrapping-protocol.md`` — bump to v1.3.0; add Path C throughout
  (Status, Known Capability Dependency, Method, Mid-Session Loading, Session Resume);
  update implementation files table; update path labels to A/B/C consistently.

v1.2.0
======

Release Summary
---------------

This release adds full Claude.ai support via the gh-mcp remote MCP server. The protocol
is now operational on two paths: Claude Code (Path A, git CLI) and Claude.ai (Path B,
gh-mcp). The Memo Loading Directive can now be specified per-session in the opening user
message, removing the need to edit Project instructions between sessions.

Major Changes
-------------

- Claude.ai path (Path B) is now fully operational. The gh-mcp server
  (``https://mcp.martiangoblin.xyz/mcp``) exposes three MCP tools — ``verify_repo_state``,
  ``fetch_memos``, and ``read_repo_file`` — providing signature verification, AGENTS.md
  parsing, and individual memo file retrieval. Claude.ai sessions use the Project
  instructions in ``docs/MCP-PROTOCOL-IMPLEMENTATION.md`` Appendix A.

Minor Changes
-------------

- ``read_repo_file(repo, branch, path)`` added to gh-mcp server. Reads any file from the
  cached repo by path relative to the repo root. Includes path traversal protection
  (rejects absolute paths and ``..`` components). Closes the file-reading gap that
  previously left Claude.ai with index digests only.
- Memo Loading Directive now resolved from the opening user message first, then the static
  default in the Project/instructions file, then sticky-only. Allows per-session overrides
  (e.g., ``--alias protocol`` or ``--tags finance`` on the first line of a message) without
  editing the Claude.ai Project instructions.
- ``claude-memos-bootstrapping-protocol.md`` updated: Method section now documents Path A
  and Path B explicitly; Session Resume covers both paths; Known Capability Dependency
  updated to describe approved retrieval paths; AGENTS.md frontmatter example updated to
  protocol-version 1.2.0.
- ``claude-memos-bootstrap.instructions.md`` version bumped to 1.2.0. No behavioural
  changes to the Claude Code path.

v1.1.0
======

Release Summary
---------------

This release introduces a minor update to the claude-memos tool, allowing mid-session memo loading. It also introduces the antsibull-changelog tool method for managing changelogs.

Minor Changes
-------------

- Add `Session Resume` section to README

v1.0.0
======

Release Summary
---------------

This release introduces a major update to the claude-memos tool, enhancing its functionality and improving the bootstrapping protocol for memo management. Key features include new command-line flags for better memo handling, a revised repository structure, and an updated memo lifecycle process. These changes aim to streamline the user experience and provide more efficient memo organization and retrieval.

Major Changes
-------------

- Co-Authored-By - Claude Sonnet 4.6 <noreply@anthropic.com>
- Mid-Session Memo Loading - At any point during a session, Peter may request additional memos by id, tag, alias, or name.
- bin/claude-memos - add --recent, --tags, --alias, --all, --memos, --list flags; inject Memo Loading Directive into system prompt; add MEMO_REPO_PATH and TAXONOMY_FILE env vars; fix --help reference from cpeer to claude-memos
- bootstrap instructions (claude-memos-bootstrap.instructions.md via symlink) - bump to v1.0.0; rewrite Step 3 for index-based loading with taxonomy resolution and directive-driven memo selection; update session log format to show loaded/total counts; update session close instructions for sticky/index model
- claude-memos-bootstrapping-protocol.md - bump to v1.0.0; update Repo Structure to require taxonomy.yml and memos/ directory; update Memo Structure to document that sticky lives in AGENTS.md index only (not memo frontmatter); add sub-file convention; update Memo Lifecycle with index update step
