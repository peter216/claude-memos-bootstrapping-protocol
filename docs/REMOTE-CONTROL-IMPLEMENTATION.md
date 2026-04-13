# Remote Control Implementation Plan

**Goal:** Make the Claude Memos Bootstrapping Protocol operational in Claude Code web /
Remote Control sessions using the gh-mcp remote MCP server as the retrieval and
verification layer, delivered via a `CLAUDE.md` file in this repository.

**Status as of 2026-04-13:**
- Remote Control path (Path C): ✅ complete — `CLAUDE.md` created and verified in this session

---

## What Is Remote Control / Claude Code Web?

Claude Code is available as a CLI, desktop app, web app (claude.ai/code), and IDE
extensions. The **Remote Control** environment refers to Claude Code sessions running in
the web/cloud environment rather than on the user's local machine.

Key properties of this environment:

- Claude has access to a cloned copy of the project repository (this repo) via the
  local filesystem.
- The user's local `~/.claude/instructions/` path is **not** accessible — the normal
  Claude Code instruction delivery mechanism (the symlinked `claude-memos-bootstrap.instructions.md`)
  does not work.
- The gh-mcp MCP tools (`verify_repo_state`, `fetch_memos`, `read_repo_file`) **are**
  available when the server is registered in Claude Code's MCP configuration.
- `CLAUDE.md` in the project root is automatically read by Claude Code at session start
  and serves as the delivery mechanism for protocol instructions.

---

## Path Comparison

| Aspect | Path A (Claude Code, local) | Path B (Claude.ai) | Path C (Remote Control) |
|---|---|---|---|
| Environment | Local terminal / desktop app | Claude.ai web | Claude Code web / Remote Control |
| Instruction delivery | `~/.claude/instructions/*.instructions.md` via `bin/claude-memos` launcher | Claude.ai Project instructions | `CLAUDE.md` in project root (auto-loaded) |
| Repo verification | `git log --show-signature` via Bash | `verify_repo_state` MCP call | `verify_repo_state` MCP call |
| AGENTS.md | `cat AGENTS.md` via Bash | `fetch_memos` MCP call | `fetch_memos` MCP call |
| taxonomy.yml | `cat taxonomy.yml` via Bash | `read_repo_file` MCP call | `read_repo_file` MCP call |
| Memo files | `cat memos/NNN.md` via Bash | `read_repo_file` MCP call | `read_repo_file` MCP call |
| Mid-session loading | `cat` via Bash | `read_repo_file` MCP call | `read_repo_file` MCP call |
| Session resume | `bin/claude-memos --dry-run` | Manual re-bootstrap | Manual re-bootstrap |
| MCP server required | No (uses local git) | Yes | Yes |

---

## Implementation

### Delivery Mechanism

`CLAUDE.md` in the repository root is the delivery mechanism for Path C. Claude Code
reads this file automatically at the start of every session in the repository directory.
The file contains the full bootstrap protocol instructions (Steps 1–6) using MCP tool
calls, mirroring the Claude.ai Project instructions (Path B) in structure and content.

The `CLAUDE.md` content is equivalent to the Claude.ai Project instructions documented
in `docs/MCP-PROTOCOL-IMPLEMENTATION.md` Appendix A, with these differences:

- Version header updated to 1.3.0
- Implementation path noted as "Claude Code (Remote Control / Web)"
- Trusted key list includes the work-machine key added in v1.2.0

### Required Setup

For Path C to function, the gh-mcp server must be registered in Claude Code's MCP
configuration. The server is at `https://mcp.martiangoblin.xyz/mcp`.

Registration can be done via Claude Code settings (global `~/.claude.json`) or per-project
`.claude/settings.json`. Once registered, the `verify_repo_state`, `fetch_memos`, and
`read_repo_file` tools appear as available MCP tools at session start.

The Remote Control environment in Claude Code web sessions picks up MCP server
registrations from the project's cloud configuration.

---

## Known Limitations

| Limitation | Impact | Mitigation |
|---|---|---|
| `bin/claude-memos --dry-run` not available | No automated re-bootstrap after context purge | User must navigate to the project directory to get a fresh session |
| `CLAUDE.md` is in the protocol repo, not the memos repo | Protocol runs only when working in this directory | Document as the required launch point for Remote Control sessions |
| No per-session directive via launcher flags | Must put directive on first line of opening message | Documented in `CLAUDE.md` under Memo Loading Directive |
| MCP server must be pre-registered | If server is not registered, protocol falls back to ERROR | Register gh-mcp in Claude Code settings before starting sessions |

---

## Verification

This path was first verified in the session that created `CLAUDE.md` (2026-04-13), on
branch `claude/setup-remote-control-YQV1p`. The gh-mcp MCP tools
(`verify_repo_state`, `fetch_memos`, `read_repo_file`) were confirmed present in the
Remote Control environment via the session's available tool list.
