# dotclaude

Personal Claude Code configuration. Skills, guidelines, and settings symlinked to `~/.claude`.

## Contents

```
claude/
├── CLAUDE.md                      # Agent development guidelines
├── journal/                       # Agent learning journal (post-mortems, learnings)
└── skills/
    ├── README.md                  # Skills index
    ├── code-review/               # Pre-commit code review
    │   ├── SKILL.md
    │   └── detect-and-lint.sh
    ├── pk-tmux/                   # Tmux session management
    │   ├── SKILL.md
    │   ├── tmux-create.sh
    │   ├── tmux-status.sh
    │   └── tmux-wait.sh
    ├── project-init/              # Generate CLAUDE.md for new projects
    │   └── SKILL.md
    └── journal/                   # Agent learning journal
        └── SKILL.md
```

## Installation

```bash
./bootstrap.sh
```

This symlinks all files from `claude/` to `~/.claude/`, preserving directory structure.

Options:
- `--force` — overwrite existing non-symlink files (default: skip with warning)

The script:
- Creates target directories as needed
- Skips files already correctly linked
- Replaces stale symlinks pointing elsewhere
- Warns about (or removes with `--force`) existing regular files

## Skills

| Skill        | Purpose                                                |
|--------------|--------------------------------------------------------|
| code-review  | Systematic review of uncommitted changes before commit |
| pk-tmux      | Background tasks and persistent terminal sessions      |
| project-init | Generate CLAUDE.md for a new project                   |
| journal      | Document mistakes (post-mortems) and learnings         |

See [claude/skills/README.md](claude/skills/README.md) for details.
