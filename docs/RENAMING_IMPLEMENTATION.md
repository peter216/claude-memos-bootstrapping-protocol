# Renaming Implementation: claude-memos → llmemos

## Summary

The project is being renamed from `claude-memos-bootstrapping-protocol` to `llmemos`
to reflect its broadened scope as a vendor-agnostic framework for human-AI working
relationships. Provider-specific components are reorganized under a `providers/`
hierarchy using a `company.product` naming convention.

## Target Structure

```
llmemos/
├── core/                          # Vendor-agnostic: memo spec, taxonomy format,
│                                  # AGENTS.md template, prompt-wrapper protocol
├── providers/
│   ├── anthropic.claude-code/     # Claude Code hook, launcher, bootstrap instructions
│   └── anthropic.claude-ai/       # Claude.ai-specific path (future)
├── bin/                           # llmemos CLI launcher
└── docs/
```

## Checklist

### GitHub

- [ ] Rename repo `peter216/claude-memos-bootstrapping-protocol` → `peter216/llmemos`
- [ ] (Optional) Rename personal corpus repo `peter216/claude-memos` if desired
      — update `canonical-repo` in `AGENTS.md` if renamed

### Local filesystem

- [ ] Rename `~/git/claude-project/claude-memos-bootstrapping-protocol/` → `~/git/claude-project/llmemos/`
- [ ] Update remote URL after GitHub rename:
      `git -C ~/git/claude-project/llmemos remote set-url origin git@github.com:peter216/llmemos.git`

### Scripts

- [ ] Rename `bin/claude-memos` → `bin/llmemos`
- [ ] Rename `~/bin/claude-memos` (home bin symlink) → `~/bin/llmemos`
- [ ] Update default bootstrap file path constant in launcher:
      ```bash
      # Before
      readonly DEFAULT_BOOTSTRAP_FILE="${HOME}/.claude/instructions/claude-memos-bootstrap.instructions.md"
      # After
      readonly DEFAULT_BOOTSTRAP_FILE="${HOME}/.claude/instructions/llmemos-bootstrap.instructions.md"
      ```
- [ ] Update script header comment and internal references in launcher

### Files to rename (inside the protocol repo)

- [ ] `claude-memos-bootstrapping-protocol.md` → `llmemos-protocol.md`
- [ ] `claude-ai-project-claude-memos-instructions.md` → `claude-ai-project-llmemos-instructions.md`
      (or move to `providers/anthropic.claude-ai/`)

### Claude config files (`~/.claude/`)

- [ ] Rename `instructions/claude-memos-bootstrap.instructions.md` → `instructions/llmemos-bootstrap.instructions.md`
- [ ] Update `CLAUDE.md` — any references to protocol name or launcher
- [ ] Update `memory/protocol_trusted_keys_on_disk.md` — internal references
- [ ] Update `plans/claude-memos-1.0-migration.md` — internal references
- [ ] Update `permission-tracking.md` — internal references

### Internal content (grep and update across the repo)

Files in the protocol repo with `claude-memos` references:

- [ ] `README.md`
- [ ] `CHANGELOG.rst` / `CHANGELOG.pre-v1.0.0.md`
- [ ] `changelogs/changelog.yaml`
- [ ] `bin/claude-memo-publish.yml`
- [ ] `docs/MCP-PROTOCOL-IMPLEMENTATION.md`
- [ ] `docs/claude.ai.test-1.md`
- [ ] `docs/claude.ai.test-2.md`

Bulk find-and-replace targets:
- `claude-memos-bootstrapping-protocol` → `llmemos`
- `claude-memos` → `llmemos` (where referring to the project; preserve where referring to the personal corpus repo)
- `claude-memos-bootstrap.instructions.md` → `llmemos-bootstrap.instructions.md`

### envrc / direnv

- [ ] Check `~/git/claude-project/.envrc` for any `claude-memos`-related path exports
- [ ] Check `~/git/claude-project/claude-memos-bootstrapping-protocol/.envrc` for same

### Provider reorganization (separate PR / phase 2)

The structural reorganization into `core/` and `providers/anthropic.claude-code/`
is a larger refactor and should follow the rename in a separate commit or PR.
The rename alone is a safe first step that doesn't require moving files around.

## Naming Convention Reference

Provider directories follow `company.product` convention:

| Directory | Covers |
|---|---|
| `providers/anthropic.claude-code` | Claude Code CLI hooks, launcher, bootstrap |
| `providers/anthropic.claude-ai` | Claude.ai web/Projects integration (future) |
| `providers/openai.chatgpt` | ChatGPT integration (future) |
| `providers/google.gemini` | Gemini integration (future) |

## Notes

- The personal corpus repo (`peter216/claude-memos` or renamed equivalent) remains
  separate from the protocol repo. Users maintain their own corpus repos; `llmemos`
  is the tooling layer.
- `llmemos` = `llm` + `memos` (memoranda / memories). The double meaning is intentional.
- The rename does not require a protocol version bump — it is a project-level rename,
  not a protocol change.
