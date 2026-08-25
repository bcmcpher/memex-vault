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
#   4. Orphan atoms (no cites::, no inbound links from curated nodes)
#   5. Archive mismatches (raw:: pointing to missing file)
#   6. Graph health (inbox-only sources, isolated atoms, bloated atoms, broad topic maps)
#   7. Structural integrity (orphan part-of, atom freshness, unknown relation fields)
#   8. Confidence and coverage (overconfident, underconfident, unvalidated, under-extracted)
#   9. Conflict acknowledgment (bare conflict links)
#  10. Tag vocabulary (unknown tags, from _meta/domain.md)
#  11. Schema conformance (type: present and correct, stage: in vocabulary,
#      status: absent)
#   Summary counts
#
# Exit status:
#   0 — no FAIL-level findings (warnings may still be present)
#   1 — one or more FAIL-level findings
#
# WARN is a soft signal for human review. FAIL means the vault is corrupt in a way
# no reviewer should have to notice: a misnamed source, or a raw:: pointing at a
# file that does not exist.

set -euo pipefail

VAULT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"

RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
DIM='\033[0;90m'
NC='\033[0m'

issues=0
fails=0

warn()  { echo -e "  ${YEL}WARN${NC}  $1"; ((issues++)) || true; }
error() { echo -e "  ${RED}FAIL${NC}  $1"; ((issues++)) || true; ((fails++)) || true; }
ok()    { echo -e "  ${GRN}OK${NC}    $1"; }

# Folders whose wikilinks count as real graph edges. _meta/ is excluded on purpose:
# the ingest log records `atoms:: [[Atom A]]` for every atom it touches, so counting
# it would make the orphan check below vacuous the moment the log has an entry.
CURATED=(sources atoms topics glossary)

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

# Presence only. Section 11 checks that type: and stage: carry legal *values*.
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
        check_field "$f" "stage"  "$label"
        check_field "$f" "saved"  "$label"
    done < <(find "$dir" -name "*.md" ! -name ".gitkeep" -print0)
done

dir="$VAULT/sources/meeting"
[ -d "$dir" ] && while IFS= read -r -d '' f; do
    label="sources/meeting/$(basename "$f")"
    check_field "$f" "date"    "$label"
    check_field "$f" "stage"   "$label"
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

# Topics, per the Node Types table in _meta/schema.md.
for sub in concepts projects research; do
    dir="$VAULT/topics/$sub"
    [ -d "$dir" ] || continue
    while IFS= read -r -d '' f; do
        label="topics/$sub/$(basename "$f")"
        check_field "$f" "title" "$label"
        [ "$sub" = "projects" ] && check_field "$f" "stage"    "$label"
        [ "$sub" = "research" ] && check_field "$f" "question" "$label"
    done < <(find "$dir" -name "*.md" ! -name ".gitkeep" -print0)
done

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
        stage_line=$(grep "^stage:" "$f" 2>/dev/null | head -1 || true)
        if echo "$stage_line" | grep -q "unread\|unprocessed"; then
            saved=$(grep "^saved:\|^date:" "$f" 2>/dev/null | head -1 | sed 's/^[^:]*: *//' || true)
            if [ -n "$saved" ] && [[ "$saved" < "$cutoff" ]]; then
                warn "$(realpath --relative-to="$VAULT" "$f") — stage=$( echo "$stage_line" | cut -d' ' -f2), saved/date=$saved"
            fi
        fi
    done < <(find "$VAULT/sources" -name "*.md" ! -name ".gitkeep" -print0)
    ok "stale source check complete (cutoff: $cutoff)"
fi

# ── 4. Orphan atoms ──────────────────────────────────────────────────────────

echo ""
echo "── 4. Orphan Atoms (no cites::, no inbound links) ────────────────────────"

# An atom is an orphan when it cites no evidence AND nothing in a curated folder
# links to it. Defined normatively in _meta/schema.md; _meta/index.md's Dataview
# query must stay in step with this. Does not test topic membership: that is
# derived from the atom's own part-of::, which is not an inbound link.

while IFS= read -r -d '' f; do
    label="atoms/$(basename "$f")"
    slug="$(basename "$f" .md)"

    # A populated cites::, not merely the field's presence. _templates/atom.md ships
    # an empty `cites:: ` line, which Dataview reads as absent (`!cites` is true).
    has_cites=$(grep -cE "^cites::[[:space:]]*\[\[" "$f" 2>/dev/null || true)

    # Count inbound wikilinks from curated nodes, ignoring the atom's own file.
    # Matches both [[slug]] and anchored [[slug#Section]] / [[slug#^block]].
    inbound=0
    for dir in "${CURATED[@]}"; do
        [ -d "$VAULT/$dir" ] || continue
        n=$(grep -rlF --include='*.md' -e "[[${slug}]]" -e "[[${slug}#" \
                "$VAULT/$dir" 2>/dev/null | grep -vFx "$f" | wc -l || true)
        inbound=$((inbound + n))
    done

    if [ "$has_cites" -eq 0 ] && [ "$inbound" -eq 0 ]; then
        warn "$label — no cites:: and no inbound links from ${CURATED[*]}"
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
    stage_line=$(grep "^stage:" "$f" 2>/dev/null | head -1 || true)
    if echo "$stage_line" | grep -q "unread\|unprocessed"; then
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
    cites_count=$(grep -cE "^cites::[[:space:]]*\[\[" "$f" 2>/dev/null || true)
    related_count=$(grep -cE "^related::[[:space:]]*\[\[" "$f" 2>/dev/null || true)
    line_count=$(wc -l < "$f")
    if [ "$cites_count" -gt 5 ] && [ "$related_count" -gt 4 ] && [ "$line_count" -gt 100 ]; then
        warn "atoms/$(basename "$f") — may cover multiple concepts (cites=$cites_count related=$related_count lines=$line_count); consider splitting"
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# 6d. Broad topic maps: many member atoms (sub-domain split candidate)
# Membership is derived, so count atoms pointing here rather than reading the topic.
while IFS= read -r -d '' f; do
    topic_name="$(basename "$f" .md)"
    member_count=$(grep -rlE "^part-of::.*\[\[${topic_name}\]\]" \
        --include='*.md' "$VAULT/atoms" 2>/dev/null | wc -l || true)
    if [ "$member_count" -gt 15 ]; then
        warn "topics/concepts/$(basename "$f") — $member_count atoms declare part-of; consider splitting into sub-domains"
    fi
done < <(find "$VAULT/topics/concepts" -name "*.md" ! -name ".gitkeep" -print0)

ok "graph health check complete"

# ── 7. Structural Integrity ──────────────────────────────────────────────────

echo ""
echo "── 7. Structural Integrity ────────────────────────────────────────────────"

# 7a. Orphan part-of:: — names a topic file that does not exist.
# Membership is derived from this field alone, so a typo'd or stale target
# silently drops the atom out of its topic with no other symptom. There is no
# reciprocal check to make: the topic side is a query, and a query cannot drift.
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    while IFS= read -r line; do
        while IFS= read -r target; do
            if [ -z "$(find "$VAULT/topics" -name "${target}.md" 2>/dev/null | head -1)" ]; then
                warn "atoms/${atom_name}.md — part-of:: [[${target}]] but no matching topic file found"
            fi
        done < <(echo "$line" | grep -oE '\[\[[^]|]+' | tr -d '[')
    done < <(grep "^part-of::" "$f" 2>/dev/null || true)
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# 7c. Atom freshness: newest cited source saved > 18 months ago
if cutoff18=$(date -d "18 months ago" +%Y-%m-%d 2>/dev/null) || cutoff18=$(date -v-18m +%Y-%m-%d 2>/dev/null); then
    while IFS= read -r -d '' f; do
        atom_name="$(basename "$f" .md)"
        newest_saved=""
        while IFS= read -r line; do
            while IFS= read -r src_name; do
                src_file=$(find "$VAULT/sources" -name "${src_name}.md" 2>/dev/null | head -1)
                [ -z "$src_file" ] && continue
                saved=$(grep "^saved:" "$src_file" 2>/dev/null | head -1 | sed 's/^saved:[[:space:]]*//' || true)
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

# 7d. Unvalidated atom: all cited sources are stage: unread
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    cites_lines=$(grep -E "^cites::[[:space:]]*\[\[" "$f" 2>/dev/null || true)
    [ -z "$cites_lines" ] && continue
    all_unread=true
    while IFS= read -r line; do
        while IFS= read -r src_name; do
            src_file=$(find "$VAULT/sources" -name "${src_name}.md" 2>/dev/null | head -1)
            [ -z "$src_file" ] && continue
            src_stage=$(grep "^stage:" "$src_file" 2>/dev/null | head -1 | sed 's/^stage:[[:space:]]*//' || true)
            if [ "$src_stage" != "unread" ]; then
                all_unread=false
                break 2
            fi
        done < <(echo "$line" | grep -oE '\[\[[^]|]+' | tr -d '[')
    done <<< "$cites_lines"
    if $all_unread; then
        warn "atoms/${atom_name}.md — all cited sources are stage: unread (confidence based on unread material)"
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
#
# Every count below matches a *populated* field (`field:: [[Target]]`), never the
# bare presence of the line. The templates ship empty `cites:: ` / `related:: `
# lines as authoring prompts, and Dataview reads those as absent — see the note
# in section 4. Counting them would flag every freshly-created note.

echo ""
echo "── 8. Confidence and Coverage ─────────────────────────────────────────────"

# 8a. Overconfident atom: confidence: high with fewer than 3 cites::
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    confidence=$(grep "^confidence:" "$f" 2>/dev/null | head -1 | sed 's/^confidence:[[:space:]]*//' || true)
    if [ "$confidence" = "high" ]; then
        cites_count=$(grep -cE "^cites::[[:space:]]*\[\[" "$f" 2>/dev/null || true)
        if [ "$cites_count" -lt 3 ]; then
            warn "atoms/${atom_name}.md — confidence: high with only $cites_count cites:: (needs 3+ for high confidence)"
        fi
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# 8b. Underconfident atom: confidence: low with 2+ processed sources
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    confidence=$(grep "^confidence:" "$f" 2>/dev/null | head -1 | sed 's/^confidence:[[:space:]]*//' || true)
    if [ "$confidence" = "low" ]; then
        processed_count=0
        while IFS= read -r line; do
            while IFS= read -r src_name; do
                src_file=$(find "$VAULT/sources" -name "${src_name}.md" 2>/dev/null | head -1)
                [ -z "$src_file" ] && continue
                src_stage=$(grep "^stage:" "$src_file" 2>/dev/null | head -1 | sed 's/^stage:[[:space:]]*//' || true)
                if [ "$src_stage" = "processed" ]; then
                    processed_count=$((processed_count + 1))
                fi
            done < <(echo "$line" | grep -oE '\[\[[^]|]+' | tr -d '[')
        done < <(grep "^cites::" "$f" 2>/dev/null || true)
        if [ "$processed_count" -ge 2 ]; then
            warn "atoms/${atom_name}.md — confidence: low but $processed_count processed sources support it (upgrade candidate)"
        fi
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# 8c. Unvalidated confidence: all cites:: sources are stage: unread
# (complements Section 7d — same detection, framed as a confidence signal)
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    cites_lines=$(grep -E "^cites::[[:space:]]*\[\[" "$f" 2>/dev/null || true)
    [ -z "$cites_lines" ] && continue
    all_unread=true
    while IFS= read -r line; do
        while IFS= read -r src_name; do
            src_file=$(find "$VAULT/sources" -name "${src_name}.md" 2>/dev/null | head -1)
            [ -z "$src_file" ] && continue
            src_stage=$(grep "^stage:" "$src_file" 2>/dev/null | head -1 | sed 's/^stage:[[:space:]]*//' || true)
            if [ "$src_stage" != "unread" ]; then
                all_unread=false
                break 2
            fi
        done < <(echo "$line" | grep -oE '\[\[[^]|]+' | tr -d '[')
    done <<< "$cites_lines"
    if $all_unread; then
        warn "atoms/${atom_name}.md — confidence assigned but all cited sources are still unread"
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# 8d. Under-extracted source: stage: processed, body > 100 lines, atom connections < 2
while IFS= read -r -d '' f; do
    label=$(realpath --relative-to="$VAULT" "$f")
    src_stage=$(grep "^stage:" "$f" 2>/dev/null | head -1 | sed 's/^stage:[[:space:]]*//' || true)
    if [ "$src_stage" = "processed" ]; then
        line_count=$(wc -l < "$f")
        if [ "$line_count" -gt 100 ]; then
            introduces_count=$(grep -cE "^introduces::[[:space:]]*\[\[" "$f" 2>/dev/null || true)
            supports_count=$(grep -cE "^supports::[[:space:]]*\[\[" "$f" 2>/dev/null || true)
            atom_connections=$((introduces_count + supports_count))
            if [ "$atom_connections" -lt 2 ]; then
                warn "$label — stage: processed, $line_count lines, but only $atom_connections atom connections (introduces+supports); may be under-extracted"
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
            conflict_field=$(grep -oE "^(contradicts|refutes)::" "$f" | head -1 || true)
            warn "atoms/${atom_name}.md — has ${conflict_field} but no explanatory prose in body (bare conflict link)"
        fi
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

ok "conflict acknowledgment check complete"

# ── 10. Tag Vocabulary ───────────────────────────────────────────────────────

echo ""
echo "── 10. Tag Vocabulary ─────────────────────────────────────────────────────"

# Vocabulary lives in _meta/domain.md, not schema.md: tags are the most
# instance-specific thing in the vault, so a fork edits one file. Each of the
# three sections is a fenced list, one tag per line.
domain_file="$VAULT/_meta/domain.md"
valid_tags=$(awk '
    /^## (Domain|Type|Stage) Tags/ {f=1; b=0; next}
    f && /^## /                    {f=0; b=0}
    f && /^```/                    {b=!b; next}
    f && b                         {print}
' "$domain_file" 2>/dev/null | sed 's/[[:space:]]*$//' | grep -v "^$" | grep -v "^#" || true)

if [ -z "$valid_tags" ]; then
    echo -e "  ${DIM}SKIP${NC}  no tag sections found in _meta/domain.md — define vocabulary to enable this check"
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
                    warn "$label — unknown tag: '$tag' (not in _meta/domain.md)"
                fi
            done
        fi
    done < <(find "$VAULT/atoms" "$VAULT/sources" -name "*.md" ! -name ".gitkeep" -print0 2>/dev/null)
    ok "tag vocabulary check complete"
fi

# ── 11. Schema Conformance ───────────────────────────────────────────────────

echo ""
echo "── 11. Schema Conformance ─────────────────────────────────────────────────"

# Three FAIL-level invariants, all schema-driven — the vocabularies are read from
# _meta/domain.md and _meta/schema.md, never hard-coded here. A fork that renames
# a node type edits the OKF Types table and this section follows.
#
#  11a. type: present, and matching the folder's declared type
#  11b. stage: drawn from the vocabulary for that node type
#  11c. status: absent — it is the exporter's output field (see schema.md
#       § Stage Values); hand-writing it would diverge from what export emits

domain_file="$VAULT/_meta/domain.md"
schema_file="$VAULT/_meta/schema.md"

# folder|Type, longest-prefix wins
okf_types=$(awk '
    /^## OKF Types/ {f=1; b=0; next}
    f && /^## /     {f=0; b=0}
    f && /^```/     {b=!b; next}
    f && b          {print}
' "$domain_file" 2>/dev/null | grep -v "^$" | grep -v "^#" || true)

# Allowed stage: values for one "### <Name>" subsection of schema.md § Stage Values.
# The section names are structure and live here; the values are data and live there.
stage_vocab() {
    awk -v want="### $1" '
        $0 == want      {f=1; next}
        f && /^#/       {exit}
        f && /^\| `/    {line=$0; sub(/^\|[[:space:]]*`/, "", line); sub(/`.*/, "", line); print line}
    ' "$schema_file" 2>/dev/null
}

# Which Stage Values subsection governs a given vault-relative path.
stage_section_for() {
    case "$1" in
        sources/meeting/*)  echo "Meeting"   ;;
        sources/*)          echo "Sources"   ;;
        glossary/*)         echo "Glossary"  ;;
        topics/projects/*)  echo "Projects"  ;;
        _meta/candidates/*) echo "Candidate" ;;
        *)                  echo ""          ;;
    esac
}

if [ -z "$okf_types" ]; then
    echo -e "  ${DIM}SKIP${NC}  no OKF Types table in _meta/domain.md — cannot validate type:"
else
    while IFS= read -r -d '' f; do
        rel=$(realpath --relative-to="$VAULT" "$f")

        # 11c. status: is forbidden everywhere in the vault, candidates included.
        if grep -q "^status:" "$f" 2>/dev/null; then
            error "$rel — carries status:; the vault field is stage: (see schema.md § Stage Values)"
        fi

        # 11a. Longest-prefix folder match against the OKF Types table.
        expected=""
        matched_len=0
        while IFS='|' read -r folder typename; do
            [ -z "$folder" ] && continue
            case "$rel" in
                "$folder"/*)
                    if [ "${#folder}" -gt "$matched_len" ]; then
                        expected="$typename"
                        matched_len=${#folder}
                    fi
                    ;;
            esac
        done <<< "$okf_types"

        if [ -n "$expected" ]; then
            actual=$(grep "^type:" "$f" 2>/dev/null | head -1 | sed 's/^type:[[:space:]]*//;s/[[:space:]]*$//' || true)
            if [ -z "$actual" ]; then
                error "$rel — missing required field: type: (expected \"$expected\")"
            elif [ "$actual" != "$expected" ]; then
                error "$rel — type: \"$actual\" but $(dirname "$rel") declares \"$expected\" in _meta/domain.md"
            fi
        fi

        # 11b. stage: value must be in the vocabulary for this node type.
        section=$(stage_section_for "$rel")
        if [ -n "$section" ]; then
            stage_val=$(grep "^stage:" "$f" 2>/dev/null | head -1 | sed 's/^stage:[[:space:]]*//;s/[[:space:]]*$//' || true)
            if [ -n "$stage_val" ]; then
                allowed=$(stage_vocab "$section")
                if [ -n "$allowed" ] && ! echo "$allowed" | grep -qx "$stage_val"; then
                    error "$rel — stage: \"$stage_val\" not valid for $section ($(echo "$allowed" | tr '\n' '/' | sed 's#/$##'))"
                fi
            fi
        fi
    done < <(find "$VAULT/sources" "$VAULT/atoms" "$VAULT/topics" "$VAULT/glossary" \
                  "$VAULT/_meta/candidates" -name "*.md" ! -name ".gitkeep" -print0 2>/dev/null)
    ok "schema conformance check complete"
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
elif [ "$fails" -eq 0 ]; then
    echo -e "  ${YEL}${issues} warning(s).${NC} Review above."
else
    echo -e "  ${RED}${fails} failure(s)${NC}, $((issues - fails)) warning(s). Review above."
fi
echo ""

# FAIL gates; WARN does not. See the exit-status note at the top of this file.
if [ "$fails" -gt 0 ]; then
    exit 1
fi
exit 0
