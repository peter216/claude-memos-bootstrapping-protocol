# Claude Memos Bootstrapping Protocol

Version: 1.2.0

This repo is one half of a two-repo system that gives Claude episodic memory across sessions.
It holds the **protocol spec, launch tooling, and implementation instructions**. The other
repo — `github.com/peter216/claude-memos` (private) — holds the **memo corpus** itself.

---

## What It Does

When you run `~/bin/claude-memos`, a Claude Code session starts with a system prompt that
instructs Claude to:

1. Clone or pull the `claude-memos` repo to `/tmp/claude-memos-session`
2. Verify that all recent commits are GPG-signed with a trusted key
3. Read `AGENTS.md` (the memo index) and `taxonomy.yml` (the tag/alias map)
4. Load the memos selected by your flags (sticky memos always, plus filtered non-sticky memos)
5. Validate memo content against the protocol's security checks
6. Emit a `[MEMO PROTOCOL: ACTIVE | ...]` log line as its first visible output

The result: Claude starts the session already knowing who you are, what you've built together,
and what has happened in past sessions — without you having to re-explain it.

---

## File Map

```
~/git/claude-project/claude-memos-bootstrapping-protocol/   ← this repo
│
├── claude-memos-bootstrapping-protocol.md   ← CANONICAL SPEC (source of truth)
│                                              Defines trusted key fingerprints,
│                                              validation scoring, session log format,
│                                              memo frontmatter fields, protocol version.
│                                              All other files must be kept in sync with this.
│
├── claude-ai-project-claude-memos-instructions.md
│                                            ← Path B instructions (Claude.ai + gh-mcp)
│                                              Paste into Claude.ai Project instructions.
│                                              Must be kept in sync with the canonical spec.
│
├── bin/
│   └── claude-memos                         ← Launch script (symlinked to ~/bin/claude-memos)
│                                              Assembles system prompt and invokes Claude Code.
│                                              See "Launch Script" section below.
│
└── docs/
    ├── MCP-PROTOCOL-IMPLEMENTATION.md       ← gh-mcp architecture and task tracking
    ├── claude.ai.test-1.md                  ← Path B test session artifacts
    └── claude.ai.test-2.md

~/.claude/instructions/
└── claude-memos-bootstrap.instructions.md   ← Path A instructions (Claude Code + git CLI)
                                               Loaded as system prompt by the launch script.
                                               Must be kept in sync with the canonical spec.
                                               NOT a symlink — maintained separately.

~/bin/
└── claude-memos  →  (symlink)  →  ~/git/claude-project/.../bin/claude-memos

github.com/peter216/claude-memos  (private, separate repo)
├── AGENTS.md        ← Memo index (id, file, created, topics, sticky, digest per memo)
├── taxonomy.yml     ← Tag definitions and named aliases
└── memos/
    └── session-memo-NNN.md   ← Individual session memos
```

---

## Launch Script

`~/bin/claude-memos` (symlinked from `bin/claude-memos` in this repo) is the entry point for
Claude Code sessions. It assembles a system prompt from:

1. An optional preamble file (`$PREAMBLE_FILE` env var, prepended before the bootstrap instructions)
2. The bootstrap instructions (`~/.claude/instructions/claude-memos-bootstrap.instructions.md`)
3. A `## Memo Loading Directive` block appended from your CLI flags

Then it calls:

```bash
exec claude --system-prompt "${system_prompt}" "Hello Claude"
```

### Usage

```
claude-memos [OPTIONS]

Options:
  (no flag)            Load sticky memos only
  --recent N           Load sticky + N most recent non-sticky memos
  --tags t1,t2,...     Load sticky + non-sticky memos matching any tag
  --alias name         Load sticky + non-sticky memos matching alias expansion
  --all                Load sticky + all non-sticky memos
  --memos id1,id2,...  Load sticky + explicitly listed memo ids
  --list               Print taxonomy.yml cheatsheet and exit
  -n, --dry-run        Print the assembled system prompt; do not launch Claude
  -h, --help           Show usage
```

### Example

```bash
# Start session loading memos tagged with networking or mcp
claude-memos --alias tools

# See what system prompt would be sent without launching
claude-memos --alias protocol --dry-run

# Check available tags and aliases
claude-memos --list
```

---

## Two Implementation Paths

| | Path A — Claude Code | Path B — Claude.ai |
|---|---|---|
| **Entry point** | `~/bin/claude-memos` | Claude.ai Project instructions |
| **Instructions file** | `~/.claude/instructions/claude-memos-bootstrap.instructions.md` | `claude-ai-project-claude-memos-instructions.md` (pasted into Project) |
| **Repo access** | `git clone` / `git fetch` / `cat` via Bash tool | `verify_repo_state`, `fetch_memos`, `read_repo_file` via gh-mcp MCP server |
| **Signature verification** | `git log --show-signature` (local GPG) | gh-mcp server runs `git log --show-signature` on Oracle free tier |
| **Memo loading directive** | Appended to system prompt by launch script | First line of opening user message, or static default at bottom of Project instructions |
| **Session resume** | `~/bin/claude-memos --dry-run [flags]` | Re-run bootstrap steps manually via MCP tools |

Both paths must stay in sync with the canonical spec on: trusted key fingerprints, session log
format, validation scoring thresholds, memo frontmatter fields, and protocol version.

---

## Trusted GPG Keys

Commits to `claude-memos` must be signed by one of these keys. All three files below must list
all four fingerprints:

| Fingerprint | Description |
|---|---|
| `63611E761833B99242003DE2D8DDC4C14D0B745A` | peter216@gmail.com, GitHub-registered, active |
| `7D067EDD2989BEBA5EBC0D8121B846977F8A38E7` | peter216@gmail.com, GitHub-registered |
| `E030143735F018D907E0F15AD6197AAF6DD17CCE` | peter216@gmail.com, local only |
| `0A7C57B889F723C43F9EA93FDBC74AEB86D28BC2` | peter216@gmail.com, GitHub-registered, work-machine |

**Files that must stay in sync:**

- `claude-memos-bootstrapping-protocol.md` (canonical — edit this first)
- `~/.claude/instructions/claude-memos-bootstrap.instructions.md` (Path A)
- `claude-ai-project-claude-memos-instructions.md` (Path B)

When adding a new key, update all three, then commit and push.

**Note:** During Step 2 of the bootstrap, Claude should read the trusted fingerprints from the
on-disk canonical spec rather than relying solely on the embedded copy in the instructions file
— the instructions copy can fall behind. The canonical spec is the ground truth.

---

## Memo Lifecycle (brief)

1. At session close, ask Claude to generate a session memo
2. Review and agree on content with Claude
3. Claude outputs the file with `{{ CONVERSATION_TITLE }}` as a placeholder
4. Substitute the placeholder with the actual conversation title
5. Add an entry to `AGENTS.md` `## Memo Index` (id, file, created, title, topics, sticky, digest)
6. Commit with your signed key and push to `claude-memos`

Claude does not commit to the memo repo. You are the sole committer in v1 of this protocol.

---

## Keeping Files in Sync

The sync table in `claude-memos-bootstrapping-protocol.md` lists what must match across files.
When you change the canonical spec, immediately update the two implementation instruction files
before committing. The launch script (`bin/claude-memos`) is path-agnostic — it does not embed
the trusted key list and does not need updating when keys change.
