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
#   6. Graph health (inbox-only sources, isolated atoms, bloated atoms, broad topic maps)
#   7. Structural integrity (part-of/covers asymmetry, atom freshness, unknown relation fields)
#   8. Confidence and coverage (overconfident, underconfident, unvalidated, under-extracted)
#   9. Conflict acknowledgment (bare conflict links)
#  10. Tag vocabulary (unknown tags)
#   Summary counts

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

# ── 6. Graph Health ──────────────────────────────────────────────────────────

echo ""
echo "── 6. Graph Health ────────────────────────────────────────────────────────"

# 6a. Inbox-only sources: unread/unprocessed with no populated Connections
while IFS= read -r -d '' f; do
    status_line=$(grep "^status:" "$f" 2>/dev/null | head -1 || true)
    if echo "$status_line" | grep -q "unread\|unprocessed"; then
        has_connections=$(grep -cE "^(supports|introduces|demonstrates|cites|related)::[[:space:]]*\[\[" "$f" 2>/dev/null || true)
        if [ "$has_connections" -eq 0 ]; then
            label=$(realpath --relative-to="$VAULT" "$f")
            warn "$label — unread with no Connections wired (inbox-only; run memex-connect)"
        fi
    fi
done < <(find "$VAULT/sources" -name "*.md" ! -name ".gitkeep" -print0)

# 6b. Isolated atoms: no populated relation fields at all
while IFS= read -r -d '' f; do
    has_relations=$(grep -cE "^(extends|uses|contradicts|part-of|related|cites)::[[:space:]]*\[\[" "$f" 2>/dev/null || true)
    if [ "$has_relations" -eq 0 ]; then
        warn "atoms/$(basename "$f") — atom has no populated relation fields (fully isolated)"
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# 6c. Bloated atoms: high cites + high related + long body (soft heuristic — split candidate)
while IFS= read -r -d '' f; do
    cites_count=$(grep -c "^cites::" "$f" 2>/dev/null || true)
    related_count=$(grep -c "^related::" "$f" 2>/dev/null || true)
    line_count=$(wc -l < "$f")
    if [ "$cites_count" -gt 5 ] && [ "$related_count" -gt 4 ] && [ "$line_count" -gt 100 ]; then
        warn "atoms/$(basename "$f") — may cover multiple concepts (cites=$cites_count related=$related_count lines=$line_count); consider splitting"
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# 6d. Broad topic maps: many covers:: entries (sub-domain split candidate)
while IFS= read -r -d '' f; do
    covers_count=$(grep "^covers::" "$f" 2>/dev/null | grep -o "\[\[" | wc -l || true)
    if [ "$covers_count" -gt 15 ]; then
        warn "topics/concepts/$(basename "$f") — covers $covers_count atoms; consider splitting into sub-domains"
    fi
done < <(find "$VAULT/topics/concepts" -name "*.md" ! -name ".gitkeep" -print0)

ok "graph health check complete"

# ── 7. Structural Integrity ──────────────────────────────────────────────────

echo ""
echo "── 7. Structural Integrity ────────────────────────────────────────────────"

# 7a. atom part-of:: → topic covers:: asymmetry
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    while IFS= read -r line; do
        while IFS= read -r target; do
            topic_file=$(find "$VAULT/topics" -name "${target}.md" 2>/dev/null | head -1)
            if [ -z "$topic_file" ]; then
                warn "atoms/${atom_name}.md — part-of:: [[${target}]] but no matching topic file found"
                continue
            fi
            if ! grep -q "covers::.*\[\[${atom_name}\]\]" "$topic_file" 2>/dev/null; then
                warn "atoms/${atom_name}.md — part-of:: [[${target}]] but ${target}.md covers:: does not include [[${atom_name}]]"
            fi
        done < <(echo "$line" | grep -oE '\[\[[^]|]+' | tr -d '[')
    done < <(grep "^part-of::" "$f" 2>/dev/null || true)
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# 7b. topic covers:: → atom part-of:: asymmetry
while IFS= read -r -d '' f; do
    topic_name="$(basename "$f" .md)"
    topic_rel="$(realpath --relative-to="$VAULT" "$f")"
    while IFS= read -r line; do
        while IFS= read -r target; do
            atom_file=$(find "$VAULT/atoms" -name "${target}.md" 2>/dev/null | head -1)
            [ -z "$atom_file" ] && continue
            if ! grep -q "^part-of::.*\[\[${topic_name}\]\]" "$atom_file" 2>/dev/null; then
                warn "$topic_rel — covers:: [[${target}]] but atoms/${target}.md has no matching part-of:: [[${topic_name}]]"
            fi
        done < <(echo "$line" | grep -oE '\[\[[^]|]+' | tr -d '[')
    done < <(grep "^covers::" "$f" 2>/dev/null || true)
done < <(find "$VAULT/topics" -name "*.md" ! -name ".gitkeep" -print0)

# 7c. Atom freshness: newest cited source saved > 18 months ago
if cutoff18=$(date -d "18 months ago" +%Y-%m-%d 2>/dev/null) || cutoff18=$(date -v-18m +%Y-%m-%d 2>/dev/null); then
    while IFS= read -r -d '' f; do
        atom_name="$(basename "$f" .md)"
        newest_saved=""
        while IFS= read -r line; do
            while IFS= read -r src_name; do
                src_file=$(find "$VAULT/sources" -name "${src_name}.md" 2>/dev/null | head -1)
                [ -z "$src_file" ] && continue
                saved=$(grep "^saved:" "$src_file" 2>/dev/null | head -1 | sed 's/^saved:[[:space:]]*//')
                [ -z "$saved" ] && continue
                if [ -z "$newest_saved" ] || [[ "$saved" > "$newest_saved" ]]; then
                    newest_saved="$saved"
                fi
            done < <(echo "$line" | grep -oE '\[\[[^]|]+' | tr -d '[')
        done < <(grep "^cites::" "$f" 2>/dev/null || true)
        if [ -n "$newest_saved" ] && [[ "$newest_saved" < "$cutoff18" ]]; then
            warn "atoms/${atom_name}.md — newest cited source saved $newest_saved (>18 months ago); may be stale"
        fi
    done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)
fi

# 7d. Unvalidated atom: all cited sources are status: unread
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    cites_lines=$(grep "^cites::" "$f" 2>/dev/null || true)
    [ -z "$cites_lines" ] && continue
    all_unread=true
    while IFS= read -r line; do
        while IFS= read -r src_name; do
            src_file=$(find "$VAULT/sources" -name "${src_name}.md" 2>/dev/null | head -1)
            [ -z "$src_file" ] && continue
            src_status=$(grep "^status:" "$src_file" 2>/dev/null | head -1 | sed 's/^status:[[:space:]]*//')
            if [ "$src_status" != "unread" ]; then
                all_unread=false
                break 2
            fi
        done < <(echo "$line" | grep -oE '\[\[[^]|]+' | tr -d '[')
    done <<< "$cites_lines"
    if $all_unread; then
        warn "atoms/${atom_name}.md — all cited sources are status: unread (confidence based on unread material)"
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# 7e. Unknown relation field: body field not in schema taxonomy
schema_file="$VAULT/_meta/schema.md"
if [ -f "$schema_file" ]; then
    valid_fields=$(awk '/^## Valid Relation Fields/{f=1} f && /^```$/{b=!b; next} f && b{print} f && /^---$/ && !b && NR>1{exit}' "$schema_file" | grep -v "^$")
    if [ -n "$valid_fields" ]; then
        while IFS= read -r -d '' f; do
            label=$(realpath --relative-to="$VAULT" "$f")
            while IFS= read -r field; do
                if ! echo "$valid_fields" | grep -qx "$field"; then
                    warn "$label — unknown relation field: ${field}::"
                fi
            done < <(awk 'BEGIN{fm=0} /^---$/{fm++; next} fm>=2 && /^[a-z][a-z-]*::/{sub(/::.*/, ""); print}' "$f" 2>/dev/null)
        done < <(find "$VAULT/sources" "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0 2>/dev/null)
    fi
fi

ok "structural integrity check complete"

# ── 8. Confidence and Coverage ───────────────────────────────────────────────

echo ""
echo "── 8. Confidence and Coverage ─────────────────────────────────────────────"

# 8a. Overconfident atom: confidence: high with fewer than 3 cites::
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    confidence=$(grep "^confidence:" "$f" 2>/dev/null | head -1 | sed 's/^confidence:[[:space:]]*//')
    if [ "$confidence" = "high" ]; then
        cites_count=$(grep -c "^cites::" "$f" 2>/dev/null || true)
        if [ "$cites_count" -lt 3 ]; then
            warn "atoms/${atom_name}.md — confidence: high with only $cites_count cites:: (needs 3+ for high confidence)"
        fi
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# 8b. Underconfident atom: confidence: low with 2+ processed sources
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    confidence=$(grep "^confidence:" "$f" 2>/dev/null | head -1 | sed 's/^confidence:[[:space:]]*//')
    if [ "$confidence" = "low" ]; then
        processed_count=0
        while IFS= read -r line; do
            while IFS= read -r src_name; do
                src_file=$(find "$VAULT/sources" -name "${src_name}.md" 2>/dev/null | head -1)
                [ -z "$src_file" ] && continue
                src_status=$(grep "^status:" "$src_file" 2>/dev/null | head -1 | sed 's/^status:[[:space:]]*//')
                if [ "$src_status" = "processed" ]; then
                    processed_count=$((processed_count + 1))
                fi
            done < <(echo "$line" | grep -oE '\[\[[^]|]+' | tr -d '[')
        done < <(grep "^cites::" "$f" 2>/dev/null || true)
        if [ "$processed_count" -ge 2 ]; then
            warn "atoms/${atom_name}.md — confidence: low but $processed_count processed sources support it (upgrade candidate)"
        fi
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# 8c. Unvalidated confidence: all cites:: sources are status: unread
# (complements Section 7d — same detection, framed as a confidence signal)
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    cites_lines=$(grep "^cites::" "$f" 2>/dev/null || true)
    [ -z "$cites_lines" ] && continue
    all_unread=true
    while IFS= read -r line; do
        while IFS= read -r src_name; do
            src_file=$(find "$VAULT/sources" -name "${src_name}.md" 2>/dev/null | head -1)
            [ -z "$src_file" ] && continue
            src_status=$(grep "^status:" "$src_file" 2>/dev/null | head -1 | sed 's/^status:[[:space:]]*//')
            if [ "$src_status" != "unread" ]; then
                all_unread=false
                break 2
            fi
        done < <(echo "$line" | grep -oE '\[\[[^]|]+' | tr -d '[')
    done <<< "$cites_lines"
    if $all_unread; then
        warn "atoms/${atom_name}.md — confidence assigned but all cited sources are still unread"
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# 8d. Under-extracted source: status: processed, body > 100 lines, atom connections < 2
while IFS= read -r -d '' f; do
    label=$(realpath --relative-to="$VAULT" "$f")
    src_status=$(grep "^status:" "$f" 2>/dev/null | head -1 | sed 's/^status:[[:space:]]*//')
    if [ "$src_status" = "processed" ]; then
        line_count=$(wc -l < "$f")
        if [ "$line_count" -gt 100 ]; then
            introduces_count=$(grep -c "^introduces::" "$f" 2>/dev/null || true)
            supports_count=$(grep -c "^supports::" "$f" 2>/dev/null || true)
            atom_connections=$((introduces_count + supports_count))
            if [ "$atom_connections" -lt 2 ]; then
                warn "$label — status: processed, $line_count lines, but only $atom_connections atom connections (introduces+supports); may be under-extracted"
            fi
        fi
    fi
done < <(find "$VAULT/sources" -name "*.md" ! -name ".gitkeep" -print0)

ok "confidence and coverage check complete"

# ── 9. Conflict Acknowledgment ───────────────────────────────────────────────

echo ""
echo "── 9. Conflict Acknowledgment ─────────────────────────────────────────────"

# 9a. Bare conflict link: atom has contradicts:: or refutes:: but no prose in body
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    has_conflict=$(grep -cE "^(contradicts|refutes)::[[:space:]]*\[\[" "$f" 2>/dev/null || true)
    if [ "$has_conflict" -gt 0 ]; then
        # Prose: a body line that is not empty, not a # header, not a field line,
        # not an HTML comment, and has at least 10 characters
        has_prose=$(awk 'BEGIN{fm=0} /^---$/{fm++; next} fm>=2 && /^[^#[:space:]]/ && !/^[a-z][a-z-]*::/ && !/^<!--/ && length($0)>=10{print; exit}' "$f" 2>/dev/null)
        if [ -z "$has_prose" ]; then
            conflict_field=$(grep -oE "^(contradicts|refutes)::" "$f" | head -1)
            warn "atoms/${atom_name}.md — has ${conflict_field} but no explanatory prose in body (bare conflict link)"
        fi
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

ok "conflict acknowledgment check complete"

# ── 10. Tag Vocabulary ───────────────────────────────────────────────────────

echo ""
echo "── 10. Tag Vocabulary ─────────────────────────────────────────────────────"

schema_file="$VAULT/_meta/schema.md"
valid_tags=$(awk '/^## Tags/{f=1; next} f && /^## /{exit} f && /^- /{sub(/^- /, ""); print}' "$schema_file" 2>/dev/null | grep -v "^$" || true)

if [ -z "$valid_tags" ]; then
    echo -e "  ${DIM}SKIP${NC}  no ## Tags section found in schema.md — define vocabulary to enable this check"
else
    while IFS= read -r -d '' f; do
        label=$(realpath --relative-to="$VAULT" "$f")
        # Extract tags line from frontmatter
        tags_line=$(awk '/^---$/{fm++; next} fm==1 && /^tags:/{print; exit} fm==2{exit}' "$f" 2>/dev/null || true)
        [ -z "$tags_line" ] && continue
        # Parse inline YAML array: tags: [a, b, c] or tags: []
        if [[ "$tags_line" =~ \[([^]]*)\] ]]; then
            tags_content="${BASH_REMATCH[1]}"
            [[ -z "$(echo "$tags_content" | tr -d ' ,')" ]] && continue
            IFS=',' read -ra tag_arr <<< "$tags_content"
            for raw_tag in "${tag_arr[@]}"; do
                tag=$(echo "$raw_tag" | sed "s/^[[:space:]]*//;s/[[:space:]]*$//;s/[\"']//g")
                [ -z "$tag" ] && continue
                if ! echo "$valid_tags" | grep -qx "$tag"; then
                    warn "$label — unknown tag: '$tag' (not in schema.md ## Tags)"
                fi
            done
        fi
    done < <(find "$VAULT/atoms" "$VAULT/sources" -name "*.md" ! -name ".gitkeep" -print0 2>/dev/null)
    ok "tag vocabulary check complete"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

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
