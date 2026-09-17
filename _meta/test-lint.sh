#!/usr/bin/env bash
# test-lint.sh — regression tests for _meta/lint.sh.
#
# Why this exists (roadmap R9, was F3). `lint.sh` is 1,700 lines of bash and the
# vault's only executable state oracle, and until rc.3 it was verified by reading
# its output on a real vault and deciding the output looked right. Two things got
# through that: M20, a provenance parser that read note prose as provenance and
# shipped that way in v1.0.0-rc.1; and the section 7h hole, where a `cites::`
# naming a note that does not exist linted clean at exit 0 — found by reading
# another project's linter, not by testing this one.
#
# Each fixture is a *sparse overlay*, not a whole vault: it holds only the notes
# under test. The harness builds a scaffold around it from this repo's real
# `_meta/schema.md` and `_meta/domain.md`, so a fixture tests lint rather than
# re-stating the schema — and a schema change that breaks lint shows up here.
#
# Expectations record the exit code, every FAIL/WARN line sorted, and the summary
# counts. Sorted because `find` order is not guaranteed; counts because they are
# what section 8 reads. OK/SKIP lines are deliberately not recorded: they change
# for reasons that are not regressions.
#
# Usage:
#   bash _meta/test-lint.sh              # run every fixture
#   bash _meta/test-lint.sh naming       # run one
#   bash _meta/test-lint.sh --update     # rewrite every expect file
#
# **Read a diff before accepting `--update`.** An expectation captured from wrong
# behaviour enshrines the bug, which is the one failure mode a harness like this
# has that no linter has.

set -uo pipefail

VAULT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURES="$VAULT/_meta/lint-fixtures"
UPDATE=0
SELECT=""

for arg in "$@"; do
    case "$arg" in
        --update) UPDATE=1 ;;
        -*) echo "unknown flag: $arg" >&2; exit 2 ;;
        *)  SELECT="$arg" ;;
    esac
done

[ -d "$FIXTURES" ] || { echo "no fixtures at $FIXTURES" >&2; exit 2; }

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; DIM=$'\033[0;90m'; NC=$'\033[0m'

# Build a minimal but real vault in $1, then overlay fixture $2.
scaffold() {
    local root="$1" fixture="$2"
    mkdir -p "$root/_meta" "$root/atoms" "$root/extracts" "$root/glossary" \
             "$root/topics/concepts" "$root/topics/projects" "$root/topics/research" \
             "$root/sources/web" "$root/sources/video" "$root/sources/paper" \
             "$root/sources/docs" "$root/sources/meeting" "$root/.archive"
    # lint reads exactly these two from _meta (plus candidates/, which may be absent)
    cp "$VAULT/_meta/schema.md" "$VAULT/_meta/domain.md" "$root/_meta/"
    find "$root" -type d -exec touch {}/.gitkeep \;
    # notes under test
    if [ -d "$fixture/vault" ]; then
        (cd "$fixture/vault" && find . -type f -print0) \
            | while IFS= read -r -d '' rel; do
                  mkdir -p "$root/$(dirname "$rel")"
                  cp "$fixture/vault/$rel" "$root/$rel"
              done
    fi
    # archives are gitignored under .archive/, so fixtures keep them in archive/
    if [ -d "$fixture/archive" ]; then
        cp "$fixture/archive/"* "$root/.archive/" 2>/dev/null || true
    fi
}

# Normalize lint output into a stable expectation.
normalize() {
    local root="$1" exit_code="$2" plain
    # Read stdin once. Two pipelines over the same stdin silently gives the second
    # one nothing, which made every expect file record an empty summary block.
    plain="$(sed -e 's/\x1b\[[0-9;]*m//g' -e "s#${root}/##g")"
    echo "exit=$exit_code"
    printf '%s\n' "$plain" | grep -E '^  (FAIL|WARN)' | sed 's/^  //' | LC_ALL=C sort
    echo "--- summary ---"
    printf '%s\n' "$plain" | grep -E '^  [A-Z][a-z].*: +' | sed -e 's/^  //' -e 's/  \+/ /g'
}

pass=0; fail=0; updated=0
for dir in "$FIXTURES"/*/; do
    name="$(basename "$dir")"
    [ -n "$SELECT" ] && [ "$SELECT" != "$name" ] && continue
    [ -f "$dir/README.md" ] || { echo "${YELLOW}SKIP${NC}  $name — no README.md saying what it tests"; continue; }

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    scaffold "$tmp" "$dir"
    raw="$(bash "$VAULT/_meta/lint.sh" "$tmp" 2>&1)"; code=$?
    got="$(printf '%s\n' "$raw" | normalize "$tmp" "$code")"
    rm -rf "$tmp"; trap - EXIT

    if [ "$UPDATE" = 1 ]; then
        printf '%s\n' "$got" > "$dir/expect"
        echo "${DIM}WROTE${NC} $name"
        updated=$((updated + 1))
        continue
    fi

    if [ ! -f "$dir/expect" ]; then
        echo "${RED}FAIL${NC}  $name — no expect file; run with --update and read the diff"
        fail=$((fail + 1)); continue
    fi

    if [ "$got" = "$(cat "$dir/expect")" ]; then
        echo "${GREEN}PASS${NC}  $name"
        pass=$((pass + 1))
    else
        echo "${RED}FAIL${NC}  $name"
        diff <(cat "$dir/expect") <(printf '%s\n' "$got") | sed 's/^/        /'
        fail=$((fail + 1))
    fi
done

echo ""
if [ "$UPDATE" = 1 ]; then
    echo "${DIM}$updated expectation(s) rewritten. Read the diff before committing.${NC}"
    exit 0
fi
if [ "$fail" -gt 0 ]; then
    echo "${RED}$fail fixture(s) failed${NC}, $pass passed."
    exit 1
fi
echo "${GREEN}All $pass fixture(s) passed.${NC}"
