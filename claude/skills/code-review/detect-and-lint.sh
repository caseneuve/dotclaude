#!/usr/bin/env bash

# detect-and-lint.sh - Detect project type and run available linting/formatting/test tools
# Usage: detect-and-lint.sh [project-dir]
# Runs all detected tools and reports results

set -uo pipefail

PROJECT_DIR="${1:-$PWD}"
cd "$PROJECT_DIR" || exit 1

echo "=== PROJECT ANALYSIS ==="
echo "Directory: $PROJECT_DIR"
echo

# Track results
declare -A RESULTS
DETECTED_LANGS=()

# -----------------------------------------------------------------------------
# Detection Functions
# -----------------------------------------------------------------------------

detect_node() {
    [[ -f "package.json" ]]
}

detect_python() {
    [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]] || \
    [[ -f "Pipfile" ]] || [[ -f "setup.cfg" ]]
}

detect_clojure() {
    [[ -f "deps.edn" ]] || [[ -f "project.clj" ]] || [[ -f "bb.edn" ]]
}

detect_rust() {
    [[ -f "Cargo.toml" ]]
}

detect_go() {
    [[ -f "go.mod" ]]
}

detect_ruby() {
    [[ -f "Gemfile" ]]
}

detect_elixir() {
    [[ -f "mix.exs" ]]
}

# -----------------------------------------------------------------------------
# Runner Functions (return 0=pass, 1=fail, 2=skipped)
# -----------------------------------------------------------------------------

run_tool() {
    local name="$1"
    local cmd="$2"

    echo "--- $name ---"
    if eval "$cmd"; then
        echo "Result: PASS"
        RESULTS["$name"]="PASS"
        return 0
    else
        echo "Result: FAIL"
        RESULTS["$name"]="FAIL"
        return 1
    fi
}

skip_tool() {
    local name="$1"
    local reason="$2"
    RESULTS["$name"]="SKIP ($reason)"
}

# -----------------------------------------------------------------------------
# Node.js / JavaScript / TypeScript
# -----------------------------------------------------------------------------

run_node_tools() {
    DETECTED_LANGS+=("Node.js/JavaScript/TypeScript")

    local pkg_manager="npm"
    [[ -f "yarn.lock" ]] && pkg_manager="yarn"
    [[ -f "pnpm-lock.yaml" ]] && pkg_manager="pnpm"
    [[ -f "bun.lockb" ]] && pkg_manager="bun"

    echo "Package manager: $pkg_manager"
    echo

    # ESLint
    if [[ -f ".eslintrc" ]] || [[ -f ".eslintrc.js" ]] || [[ -f ".eslintrc.json" ]] || \
       [[ -f ".eslintrc.yml" ]] || [[ -f "eslint.config.js" ]] || \
       grep -q '"eslint"' package.json 2>/dev/null; then
        if command -v npx &>/dev/null; then
            run_tool "ESLint" "npx eslint . --max-warnings=0 2>&1 || npx eslint . 2>&1"
        fi
    else
        skip_tool "ESLint" "not configured"
    fi

    # Prettier
    if [[ -f ".prettierrc" ]] || [[ -f ".prettierrc.js" ]] || [[ -f ".prettierrc.json" ]] || \
       [[ -f "prettier.config.js" ]] || grep -q '"prettier"' package.json 2>/dev/null; then
        if command -v npx &>/dev/null; then
            run_tool "Prettier" "npx prettier --check . 2>&1"
        fi
    else
        skip_tool "Prettier" "not configured"
    fi

    # TypeScript
    if [[ -f "tsconfig.json" ]]; then
        if command -v npx &>/dev/null; then
            run_tool "TypeScript" "npx tsc --noEmit 2>&1"
        fi
    else
        skip_tool "TypeScript" "no tsconfig.json"
    fi

    # Biome (newer alternative to ESLint+Prettier)
    if [[ -f "biome.json" ]] || [[ -f "biome.jsonc" ]]; then
        if command -v npx &>/dev/null; then
            run_tool "Biome" "npx @biomejs/biome check . 2>&1"
        fi
    fi

    # Tests - check package.json for test script
    if grep -q '"test"' package.json 2>/dev/null; then
        run_tool "Tests (npm)" "$pkg_manager test 2>&1"
    else
        skip_tool "Tests (npm)" "no test script in package.json"
    fi
}

# -----------------------------------------------------------------------------
# Python
# -----------------------------------------------------------------------------

run_python_tools() {
    DETECTED_LANGS+=("Python")

    # Ruff (fast linter + formatter)
    if command -v ruff &>/dev/null; then
        run_tool "Ruff (lint)" "ruff check . 2>&1"
        run_tool "Ruff (format)" "ruff format --check . 2>&1"
    elif [[ -f "pyproject.toml" ]] && grep -q 'ruff' pyproject.toml 2>/dev/null; then
        skip_tool "Ruff" "configured but not installed"
    fi

    # Black
    if command -v black &>/dev/null; then
        run_tool "Black" "black --check . 2>&1"
    elif [[ -f "pyproject.toml" ]] && grep -q 'black' pyproject.toml 2>/dev/null; then
        skip_tool "Black" "configured but not installed"
    fi

    # isort
    if command -v isort &>/dev/null; then
        run_tool "isort" "isort --check-only . 2>&1"
    fi

    # Flake8
    if command -v flake8 &>/dev/null && [[ -f ".flake8" ]] || [[ -f "setup.cfg" ]]; then
        run_tool "Flake8" "flake8 . 2>&1"
    fi

    # Pylint
    if command -v pylint &>/dev/null && [[ -f ".pylintrc" ]] || [[ -f "pylintrc" ]]; then
        run_tool "Pylint" "pylint **/*.py 2>&1"
    fi

    # MyPy
    if command -v mypy &>/dev/null; then
        if [[ -f "mypy.ini" ]] || [[ -f ".mypy.ini" ]] || \
           ([[ -f "pyproject.toml" ]] && grep -q '\[tool.mypy\]' pyproject.toml 2>/dev/null); then
            run_tool "MyPy" "mypy . 2>&1"
        fi
    fi

    # Pyright
    if command -v pyright &>/dev/null; then
        if [[ -f "pyrightconfig.json" ]] || \
           ([[ -f "pyproject.toml" ]] && grep -q '\[tool.pyright\]' pyproject.toml 2>/dev/null); then
            run_tool "Pyright" "pyright 2>&1"
        fi
    fi

    # Bandit (security)
    if command -v bandit &>/dev/null; then
        run_tool "Bandit (security)" "bandit -r . -q 2>&1"
    fi

    # Tests - pytest
    if command -v pytest &>/dev/null; then
        if [[ -d "tests" ]] || [[ -d "test" ]] || find . -maxdepth 1 -name '*_test.py' -o -name 'test_*.py' 2>/dev/null | head -1 | grep -q .; then
            run_tool "Pytest" "pytest --tb=short 2>&1"
        else
            skip_tool "Pytest" "no tests directory found"
        fi
    fi

    # Tests - unittest via pyproject.toml or setup.py
    if [[ -f "pyproject.toml" ]] && grep -q 'unittest' pyproject.toml 2>/dev/null; then
        run_tool "Unittest" "python -m unittest discover 2>&1"
    fi
}

# -----------------------------------------------------------------------------
# Clojure / Babashka
# -----------------------------------------------------------------------------

run_clojure_tools() {
    DETECTED_LANGS+=("Clojure/Babashka")

    # clj-kondo
    if command -v clj-kondo &>/dev/null; then
        run_tool "clj-kondo" "clj-kondo --lint src:test 2>&1 || clj-kondo --lint src 2>&1 || clj-kondo --lint . 2>&1"
    else
        skip_tool "clj-kondo" "not installed"
    fi

    # cljfmt (check formatting)
    if command -v cljfmt &>/dev/null; then
        run_tool "cljfmt" "cljfmt check 2>&1"
    elif [[ -f "deps.edn" ]] && grep -q 'cljfmt' deps.edn 2>/dev/null; then
        run_tool "cljfmt (deps)" "clojure -M:cljfmt check 2>&1"
    fi

    # Eastwood (linter)
    if [[ -f "deps.edn" ]] && grep -q 'eastwood' deps.edn 2>/dev/null; then
        run_tool "Eastwood" "clojure -M:eastwood 2>&1"
    fi

    # Tests
    if [[ -f "bb.edn" ]]; then
        if grep -q ':test' bb.edn 2>/dev/null; then
            run_tool "Tests (bb)" "bb test 2>&1"
        elif [[ -d "test" ]]; then
            run_tool "Tests (bb)" "bb -m cognitect.test-runner 2>&1 || echo 'No test runner configured'"
        fi
    elif [[ -f "deps.edn" ]]; then
        if grep -q ':test' deps.edn 2>/dev/null; then
            run_tool "Tests (clj)" "clojure -M:test 2>&1"
        elif [[ -d "test" ]]; then
            run_tool "Tests (clj)" "clojure -M -m cognitect.test-runner 2>&1"
        fi
    elif [[ -f "project.clj" ]]; then
        run_tool "Tests (lein)" "lein test 2>&1"
    fi
}

# -----------------------------------------------------------------------------
# Generic tools (Makefile, pre-commit, etc.)
# -----------------------------------------------------------------------------

run_generic_tools() {
    # Makefile targets
    if [[ -f "Makefile" ]]; then
        if grep -q '^lint:' Makefile; then
            run_tool "make lint" "make lint 2>&1"
        fi
        if grep -q '^test:' Makefile; then
            run_tool "make test" "make test 2>&1"
        fi
        if grep -q '^check:' Makefile; then
            run_tool "make check" "make check 2>&1"
        fi
    fi

    # pre-commit
    if [[ -f ".pre-commit-config.yaml" ]] && command -v pre-commit &>/dev/null; then
        run_tool "pre-commit" "pre-commit run --all-files 2>&1"
    fi

    # EditorConfig check
    if [[ -f ".editorconfig" ]] && command -v editorconfig-checker &>/dev/null; then
        run_tool "EditorConfig" "editorconfig-checker 2>&1"
    fi
}

# -----------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------

echo "=== DETECTED PROJECT TYPES ==="

detect_node && run_node_tools
detect_python && run_python_tools
detect_clojure && run_clojure_tools
detect_rust && run_rust_tools
detect_go && run_go_tools
detect_ruby && run_ruby_tools
detect_elixir && run_elixir_tools

if [[ ${#DETECTED_LANGS[@]} -eq 0 ]]; then
    echo "No specific project type detected"
fi

echo
run_generic_tools

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

echo
echo "=== SUMMARY ==="
echo "Languages: ${DETECTED_LANGS[*]:-None detected}"
echo

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

# Count results and build output (avoid subshell from pipe)
OUTPUT=""
for tool in "${!RESULTS[@]}"; do
    result="${RESULTS[$tool]}"
    if [[ "$result" == "PASS" ]]; then
        ((PASS_COUNT++))
        OUTPUT+="  PASS: $tool"$'\n'
    elif [[ "$result" == "FAIL" ]]; then
        ((FAIL_COUNT++))
        OUTPUT+="  FAIL: $tool"$'\n'
    else
        ((SKIP_COUNT++))
        OUTPUT+="  SKIP: $tool - ${result#SKIP }"$'\n'
    fi
done

# Display sorted output
printf '%s' "$OUTPUT" | sort

echo
echo "Total: $PASS_COUNT passed, $FAIL_COUNT failed, $SKIP_COUNT skipped"

if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
fi
exit 0
