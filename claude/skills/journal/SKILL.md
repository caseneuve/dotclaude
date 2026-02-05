---
name: journal
triggers:
  - journal
  - post-mortem
  - postmortem
  - document mistake
  - learning
  - lesson learned
---

# journal - Agent Learning Journal

Use this skill to document mistakes, learnings, and patterns for future reference. Entries are stored in `~/.claude/journal/` for agents to consult.

## Entry Types

| Type          | Trigger             | Purpose                                         |
|---------------|---------------------|-------------------------------------------------|
| `post-mortem` | `/post-mortem`      | Document mistakes, bad behavior, failures       |
| `learning`    | `/journal learning` | Document useful patterns, discoveries, insights |

## Storage

```
~/.claude/journal/
├── YYYY-MM-DD-post-mortem-brief-slug.md
├── YYYY-MM-DD-learning-brief-slug.md
└── ...
```

## Process

### 1. Gather context

Ask the user (or recall from conversation):
- What happened?
- What was the impact?
- What's the lesson?

### 2. Create entry

Use the appropriate template below. File naming:
```
~/.claude/journal/YYYY-MM-DD-{type}-{slug}.md
```

Where `slug` is 2-4 words, lowercase, hyphenated (e.g., `deleted-user-files`, `wrong-test-pattern`).

### 3. Confirm with user

Show the entry before writing. The user may want to add context or adjust.

---

## Templates

### Post-Mortem Template

For documenting mistakes and failures.

```markdown
---
type: post-mortem
date: YYYY-MM-DD
project: [project name or path]
tags: [relevant tags: destructive, test, build, git, etc.]
severity: [low | medium | high | critical]
---

# [Brief title describing what went wrong]

## What Happened

[Factual description of the incident]

## Root Cause

[Why did this happen? What led to the mistake?]

## Impact

[What was the outcome? Data loss? Broken build? Wasted time?]

## Prevention

[How to avoid this in the future. Be specific and actionable.]

## Checklist Addition

[If applicable: specific check to add to code-review or workflow]
```

### Learning Template

For documenting useful patterns and insights.

```markdown
---
type: learning
date: YYYY-MM-DD
project: [project name or path]
tags: [relevant tags]
---

# [Brief title describing the learning]

## Context

[When/where did this come up?]

## Insight

[What was learned? What's the pattern or technique?]

## Application

[When to apply this learning in the future]

## Example

[Optional: code snippet or concrete example]
```

---

## Reading Journal Entries

When starting work on a project, agents should check for relevant journal entries:

```bash
# List recent entries
ls -la ~/.claude/journal/

# Search for relevant post-mortems
grep -l "project: $(basename $(pwd))" ~/.claude/journal/*.md
grep -l "tags:.*destructive" ~/.claude/journal/*.md

# Read specific entry
cat ~/.claude/journal/YYYY-MM-DD-post-mortem-slug.md
```

## Example Entries

### Post-Mortem Example

```markdown
---
type: post-mortem
date: 2025-02-05
project: babagen
tags: [destructive, cleanup, file-deletion]
severity: critical
---

# Cleanup function deleted all files in public directory

## What Happened

Ran `cleanup-orphaned-posts` which deleted all directories in project root including .git because the content directory had no `.md` files (was pointing to wrong path).

## Root Cause

Function didn't validate that content-slugs was non-empty before computing orphaned directories. Empty set meant ALL directories were "orphaned".  The agent didn't follow established practice of FCIS (had mixed logic inside one function) and violated TDD rule, instead of writing tests which would ensure safety, it roguely ran the broken function.

## Impact

All directories in the root project lost, including .git, hours of unpushed work was lost.

## Prevention

- Always follow established good practices (in this case FCIS, TDD) that would prevent you from writing such broken code
- Always check for empty input sets before destructive operations
- Add defensive test: "refuses to delete when source data is empty"
- Return nil/no-op when input validation fails

## Checklist Addition

Add to code-review: "Destructive functions have empty-input guards"
```

### Learning Example

```markdown
---
type: learning
date: 2025-02-05
project: general
tags: [testing, tdd]
---

# Write tests for current chunk only

## Context

User frustrated when agent wrote 10 tests upfront then implemented all at once.

## Insight

Work in tight loops: one test -> implement -> refactor -> next test. This keeps context small, allows course correction, and produces better code.

## Application

When implementing features, resist urge to write all tests first. Pick smallest testable chunk, write ONE test, implement, repeat.
```

---

## Example Invocations

```
User: /post-mortem
User: /journal learning
User: document this mistake
User: let's do a post-mortem on what just happened
```
