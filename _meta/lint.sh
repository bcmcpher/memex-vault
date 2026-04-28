#!/usr/bin/env bash
# Karpathy Wiki — Programmatic Lint
#
# Usage:
#   bash _meta/lint.sh            # run from vault root
#   bash _meta/lint.sh /path/to/vault
#
# Checks:
#   1. Naming convention violations
#   2. Missing required frontmatter fields
#   3. Stale unread sources (>30 days)
#   4. Orphan atoms (no cites::, no backlinks from topics)
#   5. Archive mismatches (raw:: pointing to missing file)
#   6. Vault summary counts

set -euo pipefail

VAULT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"

RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
DIM='\033[0;90m'
NC='\033[0m'

issues=0

warn()  { echo -e "  ${YEL}WARN${NC}  $1"; ((issues++)) || true; }
error() { echo -e "  ${RED}FAIL${NC}  $1"; ((issues++)) || true; }
ok()    { echo -e "  ${GRN}OK${NC}    $1"; }

# ── 1. Naming convention ─────────────────────────────────────────────────────

echo ""
echo "── 1. Naming Conventions ──────────────────────────────────────────────────"

for medium in web video paper docs meeting; do
    dir="$VAULT/sources/$medium"
    [ -d "$dir" ] || continue
    while IFS= read -r -d '' f; do
        name="$(basename "$f")"
        if ! [[ "$name" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-.+ ]]; then
            error "sources/$medium/$name — missing YYYY-MM-DD prefix"
        fi
    done < <(find "$dir" -name "*.md" ! -name ".gitkeep" -print0)
done

while IFS= read -r -d '' f; do
    name="$(basename "$f")"
    if [[ "$name" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}- ]]; then
        warn "atoms/$(basename "$f") — atom has a date prefix (should be kebab-concept-name only)"
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

ok "naming check complete"

# ── 2. Required frontmatter fields ──────────────────────────────────────────

echo ""
echo "── 2. Required Frontmatter Fields ────────────────────────────────────────"

check_field() {
    local file="$1" field="$2" label="$3"
    if ! grep -q "^${field}:" "$file" 2>/dev/null; then
        warn "$label — missing field: $field"
    fi
}

for medium in web video paper docs; do
    dir="$VAULT/sources/$medium"
    [ -d "$dir" ] || continue
    while IFS= read -r -d '' f; do
        label="sources/$medium/$(basename "$f")"
        check_field "$f" "url"    "$label"
        check_field "$f" "status" "$label"
        check_field "$f" "saved"  "$label"
    done < <(find "$dir" -name "*.md" ! -name ".gitkeep" -print0)
done

dir="$VAULT/sources/meeting"
[ -d "$dir" ] && while IFS= read -r -d '' f; do
    label="sources/meeting/$(basename "$f")"
    check_field "$f" "date"    "$label"
    check_field "$f" "status"  "$label"
done < <(find "$dir" -name "*.md" ! -name ".gitkeep" -print0)

while IFS= read -r -d '' f; do
    label="atoms/$(basename "$f")"
    check_field "$f" "created"    "$label"
    check_field "$f" "confidence" "$label"
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

while IFS= read -r -d '' f; do
    label="glossary/$(basename "$f")"
    check_field "$f" "term"   "$label"
    check_field "$f" "domain" "$label"
done < <(find "$VAULT/glossary" -name "*.md" ! -name ".gitkeep" -print0)

ok "frontmatter check complete"

# ── 3. Stale unread sources (>30 days) ──────────────────────────────────────

echo ""
echo "── 3. Stale Unread Sources (>30 days) ────────────────────────────────────"

# Compute cutoff date (cross-platform: try GNU date first, fall back to BSD)
if cutoff=$(date -d "30 days ago" +%Y-%m-%d 2>/dev/null); then
    :
elif cutoff=$(date -v-30d +%Y-%m-%d 2>/dev/null); then
    :
else
    echo -e "  ${DIM}SKIP${NC}  cannot compute cutoff date on this platform"
    cutoff=""
fi

if [ -n "$cutoff" ]; then
    while IFS= read -r -d '' f; do
        status_line=$(grep "^status:" "$f" 2>/dev/null | head -1 || true)
        if echo "$status_line" | grep -q "unread\|unprocessed"; then
            saved=$(grep "^saved:\|^date:" "$f" 2>/dev/null | head -1 | sed 's/^[^:]*: *//')
            if [ -n "$saved" ] && [[ "$saved" < "$cutoff" ]]; then
                warn "$(realpath --relative-to="$VAULT" "$f") — status=$( echo "$status_line" | cut -d' ' -f2), saved/date=$saved"
            fi
        fi
    done < <(find "$VAULT/sources" -name "*.md" ! -name ".gitkeep" -print0)
    ok "stale source check complete (cutoff: $cutoff)"
fi

# ── 4. Orphan atoms ──────────────────────────────────────────────────────────

echo ""
echo "── 4. Orphan Atoms (no cites::, no covers:: backlinks) ───────────────────"

while IFS= read -r -d '' f; do
    label="atoms/$(basename "$f")"

    # Check for cites:: in the atom itself
    has_cites=$(grep -c "^cites::" "$f" 2>/dev/null || true)

    # Check if any topic covers:: this atom
    atom_link="[[$(basename "$f" .md)]]"
    covered=$(grep -rl "covers::.*${atom_link}" "$VAULT/topics" 2>/dev/null | wc -l || true)

    if [ "$has_cites" -eq 0 ] && [ "$covered" -eq 0 ]; then
        warn "$label — no cites:: and not covered by any topic map"
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

ok "orphan atom check complete"

# ── 5. Archive mismatches ────────────────────────────────────────────────────

echo ""
echo "── 5. Archive Mismatches (raw:: links) ───────────────────────────────────"

while IFS= read -r -d '' f; do
    while IFS= read -r line; do
        # Extract path after "raw:: " — strip leading ./ or vault-relative prefix
        raw_path=$(echo "$line" | sed 's/^raw:: *//')
        if [[ "$raw_path" == .archive/* ]]; then
            target="$VAULT/$raw_path"
        else
            target="$raw_path"
        fi
        if [ ! -f "$target" ]; then
            error "$(realpath --relative-to="$VAULT" "$f") — raw:: points to missing file: $raw_path"
        fi
    done < <(grep "^raw::" "$f" 2>/dev/null || true)
done < <(find "$VAULT/sources" -name "*.md" ! -name ".gitkeep" -print0)

ok "archive mismatch check complete"

# ── 6. Summary ───────────────────────────────────────────────────────────────

echo ""
echo "── Summary ────────────────────────────────────────────────────────────────"

count_md() { find "$1" -name "*.md" ! -name ".gitkeep" 2>/dev/null | wc -l; }

printf "  %-22s %s\n" "Sources (web):"     "$(count_md "$VAULT/sources/web")"
printf "  %-22s %s\n" "Sources (video):"   "$(count_md "$VAULT/sources/video")"
printf "  %-22s %s\n" "Sources (paper):"   "$(count_md "$VAULT/sources/paper")"
printf "  %-22s %s\n" "Sources (docs):"    "$(count_md "$VAULT/sources/docs")"
printf "  %-22s %s\n" "Sources (meeting):" "$(count_md "$VAULT/sources/meeting")"
printf "  %-22s %s\n" "Atoms:"             "$(count_md "$VAULT/atoms")"
printf "  %-22s %s\n" "Glossary terms:"    "$(count_md "$VAULT/glossary")"
printf "  %-22s %s\n" "Concept maps:"      "$(count_md "$VAULT/topics/concepts")"
printf "  %-22s %s\n" "Projects:"          "$(count_md "$VAULT/topics/projects")"
printf "  %-22s %s\n" "Research notes:"    "$(count_md "$VAULT/topics/research")"

echo ""
if [ "$issues" -eq 0 ]; then
    echo -e "  ${GRN}All checks passed.${NC}"
else
    echo -e "  ${YEL}${issues} issue(s) found.${NC} Review warnings above."
fi
echo ""
