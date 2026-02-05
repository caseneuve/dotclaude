---
name: code-review
triggers:
  - code review
  - review changes
  - review my code
  - review diff
  - check my changes
  - CR
---

# code-review - Comprehensive Code Review Skill

Use this skill when the user wants a thorough review of their recent changes before committing or pushing.

## Overview

This skill performs a systematic code review of uncommitted changes, evaluating against project standards, language best practices, and general software engineering principles.

## Review Process

### Phase 1: Context Gathering

**1. Identify changes to review:**
```bash
# Unstaged + staged changes (default: since last commit)
git diff HEAD

# Just staged changes
git diff --cached

# Changes since specific commit/branch
git diff <base>..HEAD
```

**2. Detect project type and language:**
- Check for `package.json` (Node/JS/TS), `pyproject.toml`/`setup.py` (Python), `deps.edn`/`bb.edn`/`project.clj` (Clojure/Babashka), `Cargo.toml` (Rust), `go.mod` (Go), etc.
- Note the primary language(s) of changed files

**3. Read project documentation:**
- `README.md` - Project overview and conventions
- `CONTRIBUTING.md` - Contribution guidelines
- `ARCHITECTURE.md` or `docs/` - Design decisions
- `.editorconfig`, linter configs - Style standards
- Look for `CLAUDE.md` or similar AI-specific guidelines

**4. Sample existing code patterns:**
- Read 2-3 similar files to understand established patterns
- Note naming conventions, error handling style, test patterns

### Phase 2: Run Automated Checks

**Use the detection script to run all available tools:**
```bash
~/.claude/skills/code-review/detect-and-lint.sh [project-dir]
# Or with defaults (uses current dir):
~/.claude/skills/code-review/detect-and-lint.sh
```

This script automatically:
- Detects project type (Node, Python, Clojure, Rust, Go, Ruby, Elixir)
- Runs all available linters, formatters, type checkers, and tests
- Reports pass/fail/skip for each tool
- Returns non-zero exit code if any tool fails

**Supported tools by language:**

| Language | Linters/Formatters | Type Checkers | Tests | Security |
|----------|-------------------|---------------|-------|----------|
| **Node/JS/TS** | ESLint, Prettier, Biome | TypeScript | npm test | - |
| **Python** | Ruff, Black, isort, Flake8, Pylint | MyPy, Pyright | Pytest, unittest | Bandit |
| **Clojure** | clj-kondo, cljfmt, Eastwood | - | clj -M:test, lein test, bb test | - |
| **Rust** | Clippy, rustfmt | (built-in) | cargo test | cargo-audit |
| **Go** | go vet, gofmt, staticcheck, golangci-lint | (built-in) | go test | govulncheck |
| **Ruby** | RuboCop | - | RSpec, Minitest | Brakeman |
| **Elixir** | mix format, Credo | Dialyzer | mix test | Sobelow |

**Also checks:** Makefile targets (lint, test, check), pre-commit hooks, EditorConfig

### Phase 3: Manual Review

Review each changed file against the checklist below. Focus review effort proportionally to change size and risk.

---

## Review Checklist

### A. Language-Specific Best Practices

Evaluate against idioms and conventions for the detected language:

| Language                  | Key Considerations                                                                                |
|---------------------------|---------------------------------------------------------------------------------------------------|
| **Python**                | PEP 8, type hints, context managers, list comprehensions vs loops, avoid mutable defaults         |
| **Clojure/Babashka**      | Prefer pure functions, use threading macros, leverage destructuring, avoid atoms unless necessary |
| **JavaScript/TypeScript** | Prefer const, async/await over callbacks, proper error boundaries, strict TypeScript              |
| **Rust**                  | Ownership patterns, error handling with Result, avoid unwrap in production                        |
| **Go**                    | Error handling conventions, interface design, goroutine safety                                    |

### B. General Engineering Principles

- [ ] **DRY (Don't Repeat Yourself)**: Is there duplicated logic that should be extracted?
- [ ] **YAGNI (You Aren't Gonna Need It)**: Is there speculative code, unused parameters, or over-engineering?
- [ ] **Single Responsibility**: Does each function/module do one thing well?
- [ ] **Pure vs Impure Separation**: Is pure logic separated from side effects (I/O, state mutation)?
- [ ] **Function Length**: Are functions short and focused? (Flag functions > 30 lines for review)
- [ ] **Nesting Depth**: Is there deeply nested logic? (Flag > 3 levels; suggest early returns, guard clauses, extraction)
- [ ] **Naming**: Are names descriptive and consistent with codebase conventions?

### C. Documentation Quality

- [ ] **No Redundant Comments**: Comments explain "why", not "what" (code should be self-documenting)
- [ ] **No Obvious Docstrings**: Avoid `"""Returns the user."""` on `def get_user():`
- [ ] **Necessary Context Preserved**: Complex algorithms, business logic, workarounds ARE documented
- [ ] **Updated Documentation**: If behavior changed, are docs/comments updated?

### C.1 Documentation & Tracking Updates Required

**Check if changes require updates to docs, TODOs, or issue trackers:**

1. **Documentation locations to check:**
   - `README.md` - Project overview, setup, usage examples
   - `CLAUDE.md` - AI-specific guidelines and context
   - `docs/` directory - Detailed documentation
   - `CHANGELOG.md` - Version history
   - `API.md` or similar - API documentation

2. **TODOs and issue tracking to check:**
   - `TODO.md` or `TODOs.md` - Project task list
   - `NEXT_STEPS.md` or similar - Planned work
   - `issues/` directory - Local issue tracking
   - In-code `TODO:` / `FIXME:` / `XXX:` comments
   - GitHub/GitLab issues referenced in code or commits

3. **Evaluate if updates are needed for:**
   - [ ] **New Features**: Document new functionality
   - [ ] **Changed Behavior**: Update affected docs
   - [ ] **New Config/CLI Options**: Document settings, env vars, flags
   - [ ] **API Changes**: Update API docs for new/changed endpoints
   - [ ] **Breaking Changes**: Clearly document in CHANGELOG
   - [ ] **Completed TODOs**: Remove or mark done any resolved TODOs
   - [ ] **New TODOs Introduced**: Ensure in-code TODOs are tracked
   - [ ] **Issue References**: Update related issues (close, comment, link)

### D. Test Quality

- [ ] **Tests Exist**: Are new code paths covered by tests?
- [ ] **Tests Are Real**: Do tests verify actual behavior, not just call functions?
- [ ] **Regression-Proof**: Would tests catch if this code broke? Do they test edge cases?
- [ ] **No Tautologies**: Tests don't just assert that mocks return mocked values
- [ ] **Test Isolation**: Tests don't depend on external state or execution order
- [ ] **Readable Tests**: Test names describe the scenario and expected outcome

### E. Security

- [ ] **No Hardcoded Credentials**: No API keys, passwords, tokens in code
- [ ] **No Credential Leaks**: Secrets not logged, not in error messages, not in URLs
- [ ] **Input Validation**: User input validated/sanitized before use
- [ ] **SQL Injection**: Using parameterized queries, not string concatenation
- [ ] **Path Traversal**: File paths validated, no user-controlled `../` exploitation
- [ ] **Dependency Security**: New dependencies from trusted sources?

### F. Error Handling

- [ ] **Errors Not Swallowed**: No empty catch blocks or ignored errors
- [ ] **Appropriate Granularity**: Not catching overly broad exception types
- [ ] **Helpful Error Messages**: Errors include context for debugging
- [ ] **Recovery Strategy**: Is error handling recover, retry, or fail-fast appropriate?

### G. Consistency

- [ ] **Matches Codebase Style**: Follows patterns established in existing code
- [ ] **Consistent Naming**: New names follow existing conventions
- [ ] **Consistent Error Handling**: Same approach as rest of codebase

---

## Nice-to-Have Checks

### H. Performance (if applicable)

- [ ] **No Obvious N+1**: Database/API calls not in loops
- [ ] **Appropriate Data Structures**: Using sets for lookups, avoiding repeated list scans
- [ ] **Resource Cleanup**: Files, connections, handles properly closed
- [ ] **Unnecessary Work**: No redundant computations, fetches, or allocations

### I. Complexity Metrics

- [ ] **Cyclomatic Complexity**: Flag functions with many branches/paths
- [ ] **Cognitive Complexity**: Code is easy to follow linearly
- [ ] **Dependency Count**: New dependencies justified and minimal

### J. API Design (if public interfaces changed)

- [ ] **Backward Compatibility**: Breaking changes intentional and documented?
- [ ] **Consistent Interface Style**: Matches existing API patterns
- [ ] **Appropriate Defaults**: Sensible defaults, explicit required params

---

## Output Format

Structure the review for easy parsing by both humans and LLM agents:

```markdown
# Code Review: [brief description of changes]

## Summary
[1-2 sentence overview of the changes and overall assessment]

## Automated Checks
- Tests: PASS/FAIL (X passed, Y failed)
- Linter: PASS/FAIL (N issues)
- Types: PASS/FAIL (N errors)

## Findings

### Critical (must fix)
- [ ] **[FILE:LINE]** [Category]: [Issue description]
  - Current: `[code snippet]`
  - Suggested: `[fixed code]`
  - Reason: [why this matters]

### Important (should fix)
- [ ] **[FILE:LINE]** [Category]: [Issue description]
  - [Details]

### Minor (consider fixing)
- [ ] **[FILE:LINE]** [Category]: [Issue description]

### Positive Observations
- [What was done well - reinforces good patterns]

## Test Coverage Assessment
[Analysis of test quality for the changes]

## Security Assessment
[Any security considerations, or "No security issues identified"]

## Documentation & Tracking Status
[IMPORTANT: This section tells you what needs updating before commit]

### Documentation Updates Required
- [ ] `README.md`: [What needs updating, or "No updates needed"]
- [ ] `CHANGELOG.md`: [What to add, or "No updates needed"]
- [ ] `docs/`: [Specific files and what to update]
- [ ] Other: [Any other doc files]

### TODOs/Issues Updates Required
- [ ] `TODO.md`: [Items to add/remove/update, or "No updates needed"]
- [ ] In-code TODOs: [Any TODO comments to add/remove]
- [ ] Issues: [Issue numbers to close/update/create]

**Action Required**: If any items above are checked, update them BEFORE committing.

## Recommendations
1. [Prioritized action item]
2. [Next action item]
...
```

---

## Example Invocations

```
User: review my changes
User: code review
User: CR before I commit
User: review the diff against main
```

## Questions to Ask if Unclear

- "Should I review all uncommitted changes, or just staged changes?"
- "Is there a specific base branch/commit to compare against?"
- "Are there specific areas you want me to focus on?"
- "Should I run the full test suite or skip tests?"

## Tips for Effective Reviews

1. **Proportional Effort**: Spend more time on core logic, less on boilerplate
2. **Context Matters**: A quick script has different standards than production code
3. **Be Constructive**: Every criticism should include a suggestion
4. **Acknowledge Good Work**: Point out well-written code to reinforce patterns
5. **Prioritize**: Critical/security issues first, style nitpicks last
