# CLAUDE.md — Agent Development Guide

## Rules

### MUST

- Follow TDD: RED (failing test) → GREEN (implement) → REFACTOR
- Work iteratively in small, contained chunks (see Development Flow below)
- DRY: extract common patterns, no boilerplate
- YAGNI: no dead code, no speculative features
- Separate pure and impure code (Functional Core, Imperative Shell)
- Keep functions short (5-15 lines) and flat (no deep nesting)
- Use type hints / specs for function contracts
- Ask before making changes (unless instructed otherwise)
- Use fixtures, factories, parametrization in tests

### MUST NOT

- Commit or push without explicit permission
- Write tests after implementation
- Write all tests upfront then all implementations (work iteratively instead)
- Add verbose docstrings (prefer semantic naming)
- Add comments unless necessary (comments lie)
- Run destructive code without sandboxing
- Mix pure computation with I/O in same function

### PREFER

- Editing existing files over creating new ones
- Short pure functions over nested conditionals
- Meaningful names over documentation
- Early returns and guard clauses over deep nesting
- Existing codebase patterns (unless clearly wrong)

## Development Flow

```
Pick small chunk → Test (RED) → Review → Implement (GREEN) → Review → Refactor → Next chunk
```

**Iterative, incremental development:**

1. **Pick a small, contained chunk** — reduce complexity, keep context manageable
2. **Write tests for CURRENT chunk only** — show to user for review
3. **Implement that chunk** — show to user for review
4. **Refactor if needed**
5. **Repeat** — next chunk

Never do big changes all at once. Never write all tests beforehand then all implementations. Work in tight feedback loops with continuous review.

Agent is the pair programming partner. Human navigates, agent drives.

## Safety Rules

Destructive operations (delete, cleanup, purge) require:

- Sandbox containment to designated output directories
- Temp directories in tests, never real paths
- Defensive tests: refuse `.`, `..`, paths outside sandbox
- Path validation: resolve to absolute, verify inside allowed directory
- When in doubt, don't run it — ask first

## Skills

| Skill                                        | Trigger               | Purpose                                  |
|----------------------------------------------|-----------------------|------------------------------------------|
| [code-review](skills/code-review/SKILL.md)   | `/code-review`, `/CR` | Review uncommitted changes before commit |
| [pk-tmux](skills/pk-tmux/SKILL.md)           | `/tmux`               | Background tasks and persistent sessions |
| [project-init](skills/project-init/SKILL.md) | `/init`               | Generate CLAUDE.md for a new project     |
