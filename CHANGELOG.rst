================================
mind.netdevconnect Release Notes
================================

.. contents:: Topics

v1.0.1
======

Release Summary
---------------

This release introduces a major update to the claude-memos tool, enhancing its functionality and improving the bootstrapping protocol for memo management. Key features include new command-line flags for better memo handling, a revised repository structure, and an updated memo lifecycle process. These changes aim to streamline the user experience and provide more efficient memo organization and retrieval.

Major Changes
-------------

- Co-Authored-By - Claude Sonnet 4.6 <noreply@anthropic.com>
- Mid-Session Memo Loading - At any point during a session, Peter may request additional memos by id, tag, alias, or name.
- bin/claude-memos - add --recent, --tags, --alias, --all, --memos, --list flags; inject Memo Loading Directive into system prompt; add MEMO_REPO_PATH and TAXONOMY_FILE env vars; fix --help reference from cpeer to claude-memos
- bootstrap instructions (claude-memos-bootstrap.instructions.md via symlink) - bump to v1.0.1; rewrite Step 3 for index-based loading with taxonomy resolution and directive-driven memo selection; update session log format to show loaded/total counts; update session close instructions for sticky/index model
- claude-memos-bootstrapping-protocol.md - bump to v1.0.1; update Repo Structure to require taxonomy.yml and memos/ directory; update Memo Structure to document that sticky lives in AGENTS.md index only (not memo frontmatter); add sub-file convention; update Memo Lifecycle with index update step
