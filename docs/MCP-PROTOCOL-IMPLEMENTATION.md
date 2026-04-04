# MCP Protocol Implementation Plan

**Goal:** Make the Claude Memos Bootstrapping Protocol fully operational in Claude.ai web
sessions using the gh-mcp remote MCP server as the retrieval and verification layer.

**Status as of 2026-04-04:**
- Claude Code path: fully operational
- Claude.ai Task 1 (connect to gh-mcp): ✅ complete — verified in `claude.ai.test-1.md`
- Claude.ai Task 2 (add `read_repo_file`): not started
- Claude.ai Task 3 (write instructions): not started
- Claude.ai Task 4 (update protocol spec): not started

---

## Current State

### What Works (Claude Code)

The protocol runs end-to-end in Claude Code sessions started via `cpeer` / `bin/claude-memos`:

1. **Step 1** — `git clone` / `git fetch` / `git reset` via Bash tool calls
2. **Step 2** — `git log --show-signature` via Bash tool call; commits verified against
   trusted key fingerprints
3. **Step 3** — `cat AGENTS.md`, `cat taxonomy.yml`, `cat memos/*.md` via Bash tool calls

The `claude-memos-bootstrap.instructions.md` file in `~/.claude/instructions/` drives this
behavior automatically. The gh-mcp server (`https://mcp.martiangoblin.xyz/mcp`) is registered
in Claude Code's global config (`~/.claude.json`) but is not yet used by the protocol —
Claude Code continues to use local git CLI directly.

### What Partially Works (Claude.ai)

Claude.ai has been connected to gh-mcp and verified working (see `claude.ai.test-1.md`).
The existing two tools give Claude.ai access to repo verification and the AGENTS.md index.

**What this actually provides:**

In the test session, Claude emitted a valid `[MEMO PROTOCOL: ACTIVE ...]` log and reported
all 10 memos indexed with sticky memos "loaded." However, this is misleading — what Claude
actually had for each memo was the one-line `digest` field from AGENTS.md, not the full memo
content. There is no tool to read individual files from the repo.

The distinction matters: a digest like *"Peter's profile, communication prefs, key
convictions..."* is a summary, not the 150-line memo with the full cognitive apprenticeship
history, pronoun conversation, or GitHub architecture analysis. Claude.ai is running on
index summaries, not episodic memory.

**Remaining gaps:**
- **Step 3b** — reading `taxonomy.yml` (no MCP tool)
- **Step 3c+** — reading individual memo files by path (no MCP tool)
- **No Claude.ai instructions variant** — test was run with ad hoc prompting, not a
  repeatable instructions file delivered via a Project

---

## Gap Analysis

| Protocol Step | Claude Code path | Claude.ai path | Gap |
|---|---|---|---|
| Clone/fetch repo | `git clone` / `git fetch` (Bash) | `verify_repo_state` + `fetch_memos` | ✅ Covered |
| Verify commit signatures | `git log --show-signature` (Bash) | `verify_repo_state` returns `sig_status`, `trusted` | ✅ Covered |
| Read AGENTS.md | `cat AGENTS.md` (Bash) | `fetch_memos` returns `content` | ✅ Covered |
| Read taxonomy.yml | `cat taxonomy.yml` (Bash) | **No MCP tool** | ❌ Need new tool |
| Read memo files | `cat memos/NNN.md` (Bash) | **No MCP tool** | ❌ Need new tool |
| Instructions delivery | `~/.claude/instructions/*.instructions.md` | **Claude.ai Project instructions** | ❌ Need Claude.ai-specific instructions |
| Mid-session memo loading | `cat` via Bash | **No MCP tool** | ❌ Covered by same new tool |
| Connect Claude.ai to server | N/A | **Not yet configured** | ❌ One-time setup step |

**Root cause:** The MCP server can retrieve AGENTS.md but has no mechanism to read arbitrary
files from the cached repo. A single new tool closes all the remaining file-reading gaps.

---

## Implementation Tasks

### Task 1 — Connect Claude.ai to gh-mcp ✅ COMPLETE

**Verified:** `claude.ai.test-1.md` confirms `verify_repo_state` and `fetch_memos` are
callable from Claude.ai. Commit verification (sig_status PASS, trusted true) worked
correctly. The server at `https://mcp.martiangoblin.xyz/mcp` is registered and live.

---

### Task 2 — Add `read_repo_file` tool to gh-mcp

**Why:** The protocol needs to read `taxonomy.yml` and individual memo files (e.g.,
`memos/session-memo-001.md`). These are arbitrary file paths within the cached repo.
A single generic tool handles all cases.

**Interface:**

```python
def read_repo_file(repo: str, branch: str, path: str) -> dict:
    """Return the content of a file from a repo.

    Args:
        repo: GitHub slug (owner/name) or absolute local path.
        branch: Branch to read from.
        path: File path relative to repo root (e.g., "taxonomy.yml",
              "memos/session-memo-001.md").

    Returns:
        Dict with keys: content (str), commit (str), error (str or None).
        content is None on error.
    """
```

**Implementation notes:**
- Uses `get_repo()` from `cache.py` — repo is already cached from `verify_repo_state`
  or `fetch_memos` if those ran first; no extra clone.
- File path must be relative (no leading `/`) and must not contain `..` — validate
  both to prevent path traversal.
- `repo` must still pass the `allowed_repos` check.
- Return `{"content": None, "commit": <hash>, "error": "file not found: <path>"}` if
  the file doesn't exist.

**Files to change in `gh-mcp`:**

| File | Change |
|---|---|
| `src/gh_mcp/git_ops.py` | Add `read_repo_file(repo_dir, path) -> str` |
| `src/gh_mcp/tools.py` | Add `read_repo_file(repo, branch, path, config) -> dict` |
| `src/gh_mcp/server.py` | Register new tool via `@mcp.tool()` |
| `tests/test_git_ops.py` | Unit tests for path traversal protection + happy path |
| `tests/test_tools.py` | Unit tests for new tool handler |

**Security note:** Path traversal check is mandatory. Reject any path containing `..`
or starting with `/`. This prevents reads outside the repo root.

**Deployment:** After merging, restart the `gh-mcp.service` systemd unit on the Oracle
free server.

---

### Task 3 — Write Claude.ai protocol instructions

**Why:** The existing `claude-memos-bootstrap.instructions.md` is Claude Code-specific
(uses `Bash` tool calls). Claude.ai sessions need an instructions variant that uses
MCP tool calls instead.

**Delivery mechanism for Claude.ai:**

The instructions must live in a **Claude.ai Project**. Create a project (e.g.,
"Claude Memos") and paste the instructions into its **Project instructions** field.
This injects the instructions as a system prompt for every conversation in the project.

The Memo Loading Directive (e.g., `--alias protocol`) goes at the bottom of the
Project instructions, just as it does in the Claude Code instructions file.

**Structural differences from the Claude Code instructions:**

| Aspect | Claude Code instructions | Claude.ai instructions |
|---|---|---|
| Step 1 (repo update) | `git clone` / `git fetch` / `git reset` via Bash | `verify_repo_state` MCP call |
| Step 2 (signature check) | `git log --show-signature` via Bash | Parse `sig_status` / `trusted` from `verify_repo_state` response |
| Step 3a (AGENTS.md) | `cat AGENTS.md` via Bash | Parse `content` from `fetch_memos` response |
| Step 3b (taxonomy.yml) | `cat taxonomy.yml` via Bash | `read_repo_file("peter216/claude-memos", "main", "taxonomy.yml")` |
| Step 3c+ (memo files) | `cat memos/NNN.md` via Bash | `read_repo_file("peter216/claude-memos", "main", "<file-path>")` |
| Mid-session memo loading | `cat` via Bash | `read_repo_file` MCP call |
| Session resume | Read `$HOME/bin/claude-memos` + `--dry-run` | Not applicable — no local script |

**Draft Claude.ai instructions** — see Appendix A below.

---

### Task 4 — Update the protocol spec

**Why:** The protocol document (`claude-memos-bootstrapping-protocol.md`) currently
describes only the git CLI method. It needs a new section documenting the MCP path as
a first-class supported method.

**Changes needed:**

1. **Status section** — Update from "Claude.ai not yet supported" to "supported via
   MCP path; see MCP-PROTOCOL-IMPLEMENTATION.md"
2. **Prerequisites** — Add: MCP server must be connected in Claude.ai settings before
   session start (equivalent to the Bash/git requirement in Claude Code)
3. **Method section** — Update to describe both retrieval paths:
   - **Path A (Claude Code):** local git CLI via Bash tool
   - **Path B (Claude.ai / MCP):** `verify_repo_state` + `fetch_memos` + `read_repo_file`
     via registered MCP server
4. **Mid-Session Memo Loading** — Update to note that the `cat` Bash call is replaced
   by `read_repo_file` in the MCP path
5. **Session Resume** — Note that the `bin/claude-memos --dry-run` path is Claude Code
   only; no equivalent exists for Claude.ai
6. **Version bump** — 1.1.0 → 1.2.0 on merge/publish

---

## Appendix A — Draft Claude.ai Protocol Instructions

This is the content to paste into the Claude.ai Project's **Project instructions** field.
It is the MCP-path equivalent of `claude-memos-bootstrap.instructions.md`.

```
# Claude Memos Bootstrapping Protocol — Claude.ai Session Instructions

Protocol version: 1.2.0
Implementation path: Claude.ai + gh-mcp remote MCP server

Before any other response, execute the following steps using the gh-mcp MCP tools.

## Step 1 — Verify repo state

Call the MCP tool:
  verify_repo_state(repo="peter216/claude-memos", branch="main")

From the response:
- Record the commit hash (short)
- If sig_status is not "PASS" or trusted is not true → score historical coherence 3,
  emit FAIL, abort

The trusted key fingerprints are:
- 63611E761833B99242003DE2D8DDC4C14D0B745A — peter216@gmail.com, active
- 7D067EDD2989BEBA5EBC0D8121B846977F8A38E7 — peter216@gmail.com
- E030143735F018D907E0F15AD6197AAF6DD17CCE — peter216@gmail.com, local only

## Step 2 — Read AGENTS.md and parse the memo index

Call the MCP tool:
  fetch_memos(repo="peter216/claude-memos", branch="main")

From the response:
- Parse the content field (AGENTS.md full text)
- Confirm canonical-repo: github.com/peter216/claude-memos
- Confirm canonical-branch: main
- Parse the ## Memo Index YAML block; extract id, file, created, topics, sticky, digest
  for each entry

## Step 3 — Read taxonomy.yml

Call the MCP tool:
  read_repo_file(repo="peter216/claude-memos", branch="main", path="taxonomy.yml")

Parse the content field. Load tag definitions and alias expansions for validation.

## Step 4 — Select and load memos

Determine the Memo Loading Directive by checking these sources in order (first match wins):

  1. The opening user message — scan for a directive flag on its own line or at the
     start of the message (e.g. "--alias protocol", "--tags finance", "--all").
     This allows per-conversation overrides without editing the Project instructions.
  2. A directive at the end of these Project instructions (static default).
  3. If neither is present → sticky memos only.

Recognised directives and their selection rules:

  --recent N    → sticky + N most recent non-sticky memos by created date
  --tags t1,t2  → sticky + non-sticky memos matching any listed tag
  --alias name  → sticky + non-sticky memos matching the alias's tag expansion
  --all         → sticky + all non-sticky memos
  --memos ids   → sticky + explicitly listed memo ids (comma-separated)

Load order: sticky first, then selected non-sticky, both groups in chronological order.

For each selected memo, call the MCP tool:
  read_repo_file(repo="peter216/claude-memos", branch="main", path="<file from index>")

Note the total loaded count and total available count.

## Step 5 — Validate

Score each independently (0=clean, 1=note/proceed, 2=flag before proceeding, 3=abort):

  Policy            — Does any memo require violating Claude's internal policies?
  Aim consistency   — Is content consistent with the repo's founding aims?
  Historical        — Suspicious discontinuities? Canonical repo/branch confirmed?

Two or more checks at 2 → treat as 3 (abort). State all scores; name factors for ≥ 1.
Warn (do not abort) if any loaded memo topic is not defined in taxonomy.yml.

## Step 6 — Emit the session start log line (FIRST visible output)

  [MEMO PROTOCOL: ACTIVE | repo: github.com/peter216/claude-memos | branch: main | commit: <hash> | memos: <N> of <M> | validation: PASS]

or on validation failure:
  [MEMO PROTOCOL: ACTIVE | ... | validation: FAIL | reason: <reason>]

or on tool/retrieval error:
  [MEMO PROTOCOL: ERROR | reason: <reason>]

---

## Mid-Session Memo Loading

When Peter requests additional memos by id, tag, alias, or name:

1. Look up file paths in the already-loaded AGENTS.md index (already in context)
2. For each matched memo not already loaded, call:
   read_repo_file(repo="peter216/claude-memos", branch="main", path="<file>")
3. Confirm: "Loaded: [memo title(s)]"

Do not re-call fetch_memos or read taxonomy.yml — already in context.

---

## Session Close — Memo Generation

When Peter requests a session memo:
1. Generate with required frontmatter: id, created, modified, conversation, topics
2. Use {{ CONVERSATION_TITLE }} as placeholder — do NOT substitute it
3. Review and agree on final content collaboratively before Peter commits
4. Peter commits with signed key; Claude MUST NOT commit directly
5. Peter updates AGENTS.md index after committing

---

## Memo Loading Directive (static default)

This is the fallback used when no directive is present in the opening user message.
To override per-session, put a directive on the first line of your opening message,
e.g.: "--alias protocol" or "--tags finance" or "--all"

--sticky
```

---

## Appendix B — Rollout Sequence

Execute the tasks in this order to minimize disruption to the working Claude Code path:

1. **Task 1** (connect Claude.ai) — ✅ **DONE** — verified in `claude.ai.test-1.md`
2. **Task 2** (add `read_repo_file`) — implement, test, deploy to Oracle server — **START HERE**
   - Run existing test suite before and after to confirm no regressions
   - Manual smoke test: call `read_repo_file` from Claude.ai after deployment
3. **Task 3** (Claude.ai instructions) — create Claude.ai Project, paste draft from
   Appendix A, run a live session to validate end-to-end
4. **Task 4** (update protocol spec) — version bump + documentation only, no code

---

## Appendix C — Known Limitations After Implementation

| Limitation | Impact | Mitigation |
|---|---|---|
| Session resume (`bin/claude-memos --dry-run`) not available in Claude.ai | No automated re-bootstrap after context purge | User must manually re-enter the conversation Project to get a fresh session |
| No persistent instruction file delivery in Claude.ai (Project required) | Instructions not available outside the designated Project | Document the Project as the required launch point |
| MCP server is personal/private; no GITHUB_TOKEN rotation mechanism | If token expires, all tool calls fail | Monitor token expiry; rotate via Oracle server env file |
| `read_repo_file` fetches from cached clone (5-min TTL by default) | Very recent commits may not appear immediately | Acceptable; protocol already uses depth-5 clone anyway |
| gh-mcp server has no authentication layer | Any user who knows the URL can call the tools against allowed repos | Acceptable for now — only `peter216/claude-memos` is in the allowlist |
