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
#  12. Extract grounding (every claim's quote present in the normalized archive)
#  13. Provenance blocks (generated:/verified: shape, actor form, stale sign-off)
#   Summary counts
#
# Exit status:
#   0 — no FAIL-level findings (warnings may still be present)
#   1 — one or more FAIL-level findings
#   2 — the linter itself broke before reaching a verdict; says nothing about the
#       vault. Kept distinct from 1 so a bug here can never be read as corruption.
#
# WARN is a soft signal for human review. FAIL means the vault is corrupt in a way
# no reviewer should have to notice: a misnamed source, a raw:: pointing at a file
# that does not exist, or an extracted claim quoting text the source never
# contained.

set -euo pipefail

VAULT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"

RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
DIM='\033[0;90m'
NC='\033[0m'

issues=0
fails=0
finished=false

# Phase 0 made exit 1 mean "a FAIL-level finding exists". A `set -e` abort exits
# 1 too, so a bug in this script reads to any caller as a corrupt vault. This
# trap keeps the two apart: only a run that reaches the summary is a verdict.
# (Not hypothetical — an unguarded `grep` in a command substitution did exactly
# this in section 13 during Phase 4, and the fixture reported a clean exit 1.)
on_exit() {
    local code=$?
    if [ "$code" -ne 0 ] && [ "$finished" = false ]; then
        echo -e "\n  ${RED}ERROR${NC} lint.sh exited before reaching a verdict — this is a bug in"
        echo    "        the linter, not a finding about the vault. Do not read it as a FAIL."
        echo    "        Re-run with 'bash -x _meta/lint.sh' to find the aborting command."
        exit 2
    fi
}
trap on_exit EXIT

warn()  { echo -e "  ${YEL}WARN${NC}  $1"; ((issues++)) || true; }
error() { echo -e "  ${RED}FAIL${NC}  $1"; ((issues++)) || true; ((fails++)) || true; }
ok()    { echo -e "  ${GRN}OK${NC}    $1"; }

# Folders whose wikilinks count as real graph edges. _meta/ is excluded on purpose:
# the ingest log records `atoms:: [[Atom A]]` for every atom it touches, so counting
# it would make the orphan check below vacuous the moment the log has an entry.
CURATED=(sources atoms topics glossary)

# Count the wikilink targets on a relation field, not the lines carrying them.
# `_meta/schema.md` blesses `introduces:: [[A]], [[B]]` on one line — "multiple
# targets on a single relation field ... expected and correct" — so a `grep -c`
# here reports 1 where the vault means 2. That undercount made 8d flag
# well-atomized sources as under-extracted and left 6c's thresholds unreachable;
# Phase 2's item 14 fixed the same greps to require `[[` but kept counting lines.
#
# Requires a populated field, exactly as item 14 did: a bare `cites:: ` template
# prompt contributes nothing. Targets are deduplicated, matching backing_sources.
#
# Takes an alternation of bare field names: count_links "$f" 'introduces|supports'
count_links() {
    local f="$1" fields="$2"
    grep -hE "^(${fields})::[[:space:]]*\[\[" "$f" 2>/dev/null \
        | grep -oE '\[\[[^]]+\]\]' | sort -u | wc -l || true
}

# Resolve an atom's cites:: into the distinct source files standing behind them.
# A citation is one of two shapes: a bare source ([[slug]] or [[slug#Section]]),
# or a claim inside an extract ([[ext-slug#^cNN]]), which resolves through that
# extract's extracted-from::.
#
# Phase 3 made the second shape the *preferred* one — `high` confidence requires
# it — so a check that only understands the first silently skips the best-cited
# atoms in the vault. Four checks were written that way (7c, 7d, 8b, 8c) and each
# was quietly wrong on any atom citing an extract: 7d and 8c reported "all cited
# sources unread" because they resolved nothing at all.
#
# Emits one absolute path per line, deduplicated. Prints nothing when an atom has
# no resolvable citations.
backing_sources() {
    local f="$1" target note ext_file src
    {
        while IFS= read -r target; do
            note="${target%%#*}"
            [ -z "$note" ] && continue
            case "$note" in
                ext-*)
                    ext_file="$VAULT/extracts/${note}.md"
                    if [ -f "$ext_file" ]; then
                        src=$(grep -m1 "^extracted-from::" "$ext_file" 2>/dev/null \
                              | grep -oE '\[\[[^]|]+' | tr -d '[' | head -1 || true)
                        [ -n "$src" ] && note="$src"
                    fi
                    ;;
            esac
            find "$VAULT/sources" -name "${note}.md" 2>/dev/null | head -1
        done < <(grep -E "^cites::" "$f" 2>/dev/null \
                 | grep -oE '\[\[[^]]+\]\]' | sed 's/^\[\[//; s/\]\]$//' || true)
    } | grep -v '^$' | sort -u || true
}

# Source media come from _meta/domain.md § Source Types rather than a literal
# list here: a fork that adds sources/hearing/ must get the same filename and
# frontmatter checks as the shipped five without editing this script. Falls back
# to the shipped set if the block is missing, so a half-edited domain.md degrades
# to the old behaviour instead of silently checking nothing.
#
# `meeting` is the one medium name with behaviour attached — section 2 checks it
# for date: instead of url:/saved:. A fork that renames it keeps every other
# check and loses that one; _meta/domain.md § Source Types says so.
source_media=$(awk '
    /^## Source Types/ {f=1; b=0; next}
    f && /^## /        {f=0; b=0}
    f && /^```/        {b=!b; next}
    f && b             {print}
' "$VAULT/_meta/domain.md" 2>/dev/null | sed 's/[[:space:]]*$//' \
  | grep -v "^$" | grep -v "^#" || true)

[ -z "$source_media" ] && source_media="web video paper docs meeting"

# ── 1. Naming convention ─────────────────────────────────────────────────────

echo ""
echo "── 1. Naming Conventions ──────────────────────────────────────────────────"

for medium in $source_media; do
    dir="$VAULT/sources/$medium"
    if [ ! -d "$dir" ]; then
        warn "_meta/domain.md declares source type '$medium' but sources/$medium/ does not exist"
        continue
    fi
    while IFS= read -r -d '' f; do
        name="$(basename "$f")"
        if ! [[ "$name" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-.+ ]]; then
            error "sources/$medium/$name — missing YYYY-MM-DD prefix"
        fi
    done < <(find "$dir" -name "*.md" ! -name ".gitkeep" -print0)
done

# The mirror: a folder under sources/ that _meta/domain.md never declares. Its
# notes are legal on disk but invisible to every medium-driven check above, and
# section 11a has no type: to hold them to. Silent holes are the failure mode a
# fork hits, so name them.
while IFS= read -r -d '' dir; do
    medium="$(basename "$dir")"
    if ! echo "$source_media" | grep -qx "$medium"; then
        warn "sources/$medium/ exists but is not declared in _meta/domain.md § Source Types — its notes are unchecked"
    fi
done < <(find "$VAULT/sources" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)

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

for medium in $source_media; do
    [ "$medium" = "meeting" ] && continue   # checked separately just below
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

dir="$VAULT/extracts"
[ -d "$dir" ] && while IFS= read -r -d '' f; do
    label="extracts/$(basename "$f")"
    check_field "$f" "title"     "$label"
    check_field "$f" "extracted" "$label"
    check_field "$f" "claims"    "$label"
done < <(find "$dir" -name "*.md" ! -name ".gitkeep" -print0)

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

# .archive/ is gitignored, so a fresh clone has none of it. Absent *entirely* is
# the clone case and SKIPs; a file missing while the folder exists is a real
# mismatch and FAILs. Without that split every clone would fail lint on the first
# raw:: it met — the same trap section 12 avoids, and the same reasoning.
if [ ! -d "$VAULT/.archive" ]; then
    echo -e "  ${DIM}SKIP${NC}  no .archive/ directory — raw:: targets unverifiable (expected on a fresh clone)"
else
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
fi

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
    cites_count=$(count_links "$f" 'cites')
    related_count=$(count_links "$f" 'related')
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
        while IFS= read -r src_file; do
            saved=$(grep "^saved:" "$src_file" 2>/dev/null | head -1 | sed 's/^saved:[[:space:]]*//' || true)
            [ -z "$saved" ] && continue
            if [ -z "$newest_saved" ] || [[ "$saved" > "$newest_saved" ]]; then
                newest_saved="$saved"
            fi
        done < <(backing_sources "$f")
        if [ -n "$newest_saved" ] && [[ "$newest_saved" < "$cutoff18" ]]; then
            warn "atoms/${atom_name}.md — newest cited source saved $newest_saved (>18 months ago); may be stale"
        fi
    done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)
fi

# 7d. Unvalidated atom: all cited sources are stage: unread
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    resolved=$(backing_sources "$f")
    # No resolvable source is a dangling-link problem, not an unread one — do not
    # report it here, or every extract-only atom reads as unvalidated.
    [ -z "$resolved" ] && continue
    all_unread=true
    while IFS= read -r src_file; do
        src_stage=$(grep "^stage:" "$src_file" 2>/dev/null | head -1 | sed 's/^stage:[[:space:]]*//' || true)
        if [ "$src_stage" != "unread" ]; then
            all_unread=false
            break
        fi
    done <<< "$resolved"
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
        done < <(find "$VAULT/sources" "$VAULT/atoms" "$VAULT/extracts" -name "*.md" ! -name ".gitkeep" -print0 2>/dev/null)
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

# 8a. Overconfident atom: confidence: high backed by fewer than 3 distinct sources.
#
# Counts *distinct backing sources* via backing_sources(), not cites:: lines.
# Since Phase 3 an atom can cite [[ext-slug#^c01]], [[ext-slug#^c07]] and
# [[ext-slug#^c12]] — three citations, three claims, but ONE source, which is
# `low` under the rubric and sailed past the old line count.
#
# Independence is NOT tested here: "same author", "one restates the other" and
# "one cites the other through a chain" are judgements, and `memex-trust-audit`
# owns them. This count is therefore an upper bound — it can only under-report.
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    confidence=$(grep "^confidence:" "$f" 2>/dev/null | head -1 | sed 's/^confidence:[[:space:]]*//' || true)
    if [ "$confidence" = "high" ]; then
        source_count=$(backing_sources "$f" | grep -c . || true)
        if [ "$source_count" -lt 3 ]; then
            warn "atoms/${atom_name}.md — confidence: high backed by only $source_count distinct source(s) (needs 3+ independent for high)"
        fi
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# 8b. Underconfident atom: confidence: low with 2+ processed sources
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    confidence=$(grep "^confidence:" "$f" 2>/dev/null | head -1 | sed 's/^confidence:[[:space:]]*//' || true)
    if [ "$confidence" = "low" ]; then
        processed_count=0
        while IFS= read -r src_file; do
            src_stage=$(grep "^stage:" "$src_file" 2>/dev/null | head -1 | sed 's/^stage:[[:space:]]*//' || true)
            if [ "$src_stage" = "processed" ]; then
                processed_count=$((processed_count + 1))
            fi
        done < <(backing_sources "$f")
        if [ "$processed_count" -ge 2 ]; then
            warn "atoms/${atom_name}.md — confidence: low but $processed_count processed sources support it (upgrade candidate)"
        fi
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# 8c. Unvalidated confidence: all cites:: sources are stage: unread
# (complements Section 7d — same detection, framed as a confidence signal)
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    resolved=$(backing_sources "$f")
    [ -z "$resolved" ] && continue
    all_unread=true
    while IFS= read -r src_file; do
        src_stage=$(grep "^stage:" "$src_file" 2>/dev/null | head -1 | sed 's/^stage:[[:space:]]*//' || true)
        if [ "$src_stage" != "unread" ]; then
            all_unread=false
            break
        fi
    done <<< "$resolved"
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
            atom_connections=$(count_links "$f" 'introduces|supports')
            if [ "$atom_connections" -lt 2 ]; then
                warn "$label — stage: processed, $line_count lines, but only $atom_connections atom connections (introduces+supports); may be under-extracted"
            fi
        fi
    fi
done < <(find "$VAULT/sources" -name "*.md" ! -name ".gitkeep" -print0)

# 8e. Contradicted high-confidence atom: confidence: high with a live conflict.
#
# The rubric's third requirement for `high` — "no unaddressed contradicts:: or
# refutes::" — went unchecked until Phase 4. Both directions count: an atom the
# vault disputes is disputed whether it holds the link or the other atom does.
#
# Distinct from 9a, which asks whether *any* conflict link was explained in prose
# regardless of confidence. This asks whether `high` is still earned.
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    confidence=$(grep "^confidence:" "$f" 2>/dev/null | head -1 | sed 's/^confidence:[[:space:]]*//' || true)
    [ "$confidence" = "high" ] || continue
    outgoing=$(count_links "$f" 'contradicts|refutes')
    incoming=$(grep -rlE "^(contradicts|refutes)::.*\[\[${atom_name}(#[^]]*)?\]\]" \
               "$VAULT/atoms" 2>/dev/null | grep -cv "^${f}$" || true)
    total=$((outgoing + incoming))
    if [ "$total" -gt 0 ]; then
        warn "atoms/${atom_name}.md — confidence: high with $total live contradicts::/refutes:: relation(s) (high requires none unaddressed)"
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

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

# ── 12. Extract Grounding ────────────────────────────────────────────────────

echo ""
echo "── 12. Extract Grounding ──────────────────────────────────────────────────"

# The anti-fabrication check, and the reason Phase 0 had to make FAIL a real gate
# first. Every claim in extracts/ carries a verbatim quote; this section greps for
# that quote in the source's normalized raw:: archive. A quote that is not there
# is a FAIL — fabrication is deep extraction's characteristic failure mode, and
# this is the only defense with no LLM anywhere in the verification loop.
#
# It works only against normalized text. Raw pdftotext output is hard-wrapped and
# full of ligatures and smart quotes, so a naive grep -F would fail on almost
# every multi-line quote and the check would be pure noise. _meta/normalize.sh is
# what makes exact match hold by construction; every skill that writes an archive
# pipes through it.
#
# A missing archive is a SKIP, never a FAIL: .archive/ is gitignored, so it is
# absent on every clone, and *unverifiable* is not *fabricated*. The guarantee is
# local-only by construction. See _meta/schema.md § Extract Claims.

extracts_dir="$VAULT/extracts"
have_extracts=""
if [ -d "$extracts_dir" ]; then
    have_extracts=$(find "$extracts_dir" -name "*.md" ! -name ".gitkeep" -print -quit 2>/dev/null || true)
fi

if [ -z "$have_extracts" ]; then
    echo -e "  ${DIM}SKIP${NC}  no extracts/ — run memex-deep-extract to build the evidence layer"
else
    grounded=0
    unverifiable=0

    while IFS= read -r -d '' f; do
        rel="extracts/$(basename "$f")"
        slug="$(basename "$f" .md)"

        # 12a. extracted-from:: is the extract's only record of provenance, and
        # the filename is supposed to be the source's with an ext- prefix. A
        # dangling one detaches the whole file: there is nothing left to check
        # the quotes against.
        src_target=$(grep "^extracted-from::" "$f" 2>/dev/null | head -1 \
                     | grep -oE '\[\[[^]|#]+' | tr -d '[' || true)
        src_file=""
        if [ -z "$src_target" ]; then
            error "$rel — no extracted-from:: (an extract with no source cannot be grounded)"
        else
            src_file=$(find "$VAULT/sources" -name "${src_target}.md" 2>/dev/null | head -1)
            if [ -z "$src_file" ]; then
                error "$rel — extracted-from:: [[${src_target}]] but no such file in sources/"
            fi
            if [ "ext-${src_target}" != "$slug" ]; then
                warn "$rel — filename should be ext-${src_target}.md to match extracted-from::"
            fi
        fi

        # 12b. claims: is the one derived number the schema keeps in frontmatter,
        # because Dataview cannot count block ids. Cross-check so it cannot drift.
        declared=$(grep "^claims:" "$f" 2>/dev/null | head -1 | sed 's/^claims:[[:space:]]*//;s/[[:space:]]*$//' || true)
        claim_ids=$(grep -cE '\^c[0-9]+[[:space:]]*$' "$f" 2>/dev/null || true)
        if [ -n "$declared" ] && [ "$declared" != "$claim_ids" ]; then
            warn "$rel — claims: $declared but $claim_ids block ids in the body"
        fi

        # Duplicate ids would make cites:: [[extract#^c07]] resolve ambiguously,
        # which silently breaks the provenance the whole layer exists to provide.
        dupes=$(grep -oE '\^c[0-9]+[[:space:]]*$' "$f" 2>/dev/null | sed 's/[[:space:]]*$//' | sort | uniq -d || true)
        if [ -n "$dupes" ]; then
            error "$rel — duplicate claim ids: $(echo "$dupes" | tr '\n' ' ')"
        fi

        # Resolve the archive once per extract.
        archive=""
        if [ -n "$src_file" ]; then
            raw_path=$(grep "^raw::" "$src_file" 2>/dev/null | head -1 | sed 's/^raw:: *//' || true)
            if [ -n "$raw_path" ]; then
                case "$raw_path" in
                    /*) archive="$raw_path"        ;;
                    *)  archive="$VAULT/$raw_path" ;;
                esac
                [ -f "$archive" ] || archive=""
            fi
        fi

        # 12c. Every claim needs a quote. "A claim with no checkable quote is not
        # a claim" is the design's phrasing, and it is a FAIL for that reason.
        quote_count=$(grep -cE '^[[:space:]]*-[[:space:]]*quote:' "$f" 2>/dev/null || true)
        if [ "$quote_count" -lt "$claim_ids" ]; then
            error "$rel — $claim_ids claims but only $quote_count quote: lines"
        fi

        # 12d. The grounding itself.
        while IFS= read -r qline; do
            quote=$(echo "$qline" | sed 's/^[[:space:]]*-[[:space:]]*quote:[[:space:]]*//; s/^"//; s/"[[:space:]]*$//')
            if [ -z "$quote" ]; then
                error "$rel — empty quote: line"
                continue
            fi
            if [ -z "$archive" ]; then
                unverifiable=$((unverifiable + 1))
                continue
            fi
            if grep -qF -- "$quote" "$archive" 2>/dev/null; then
                grounded=$((grounded + 1))
            else
                hint=""
                case "$quote" in
                    *...*) hint=" [contains an ellipsis — quotes must be contiguous; emit two quote: lines]" ;;
                esac
                error "$rel — quote not found in $(basename "$archive"): \"$(echo "$quote" | cut -c1-70)\"$hint"
            fi
        done < <(grep -E '^[[:space:]]*-[[:space:]]*quote:' "$f" 2>/dev/null || true)
    done < <(find "$extracts_dir" -name "*.md" ! -name ".gitkeep" -print0)

    if [ "$unverifiable" -gt 0 ]; then
        echo -e "  ${DIM}SKIP${NC}  $unverifiable quote(s) unverifiable — no archive on disk (expected on a fresh clone)"
    fi
    ok "grounding check complete ($grounded quote(s) verified)"
fi

# 12e. Dangling block anchor: a note cites [[target#^id]] that does not exist.
# Provenance that resolves to nothing is worse than none — the atom reads as
# claim-grounded and is not.
while IFS= read -r -d '' f; do
    label=$(realpath --relative-to="$VAULT" "$f")
    while IFS= read -r ref; do
        target="${ref%%#*}"
        anchor="${ref#*#}"
        tfile=$(find "$VAULT/extracts" "$VAULT/sources" "$VAULT/atoms" -name "${target}.md" 2>/dev/null | head -1)
        if [ -z "$tfile" ]; then
            warn "$label — cites:: [[${target}#${anchor}]] but no such note"
        elif ! grep -qF -- "$anchor" "$tfile" 2>/dev/null; then
            warn "$label — cites:: [[${target}#${anchor}]] but ${target} has no block ${anchor}"
        fi
    done < <(grep -oE '\[\[[^]|]+#\^[A-Za-z0-9-]+' "$f" 2>/dev/null | sed 's/^\[\[//' || true)
done < <(find "$VAULT/atoms" "$VAULT/sources" "$VAULT/topics" "$VAULT/glossary" \
              -name "*.md" ! -name ".gitkeep" -print0 2>/dev/null)

# 12f. confidence: high with no block-anchored citation. Per _meta/schema.md
# § Confidence Values, `high` requires claim-level grounding — an atom resting on
# three filenames has not been checked, it has been counted. Complements 8a,
# which checks how many sources there are; this checks how specific they are.
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    confidence=$(grep "^confidence:" "$f" 2>/dev/null | head -1 | sed 's/^confidence:[[:space:]]*//' || true)
    if [ "$confidence" = "high" ]; then
        anchored=$(grep -cE '^cites::.*\[\[[^]|]+#\^' "$f" 2>/dev/null || true)
        if [ "$anchored" -eq 0 ]; then
            warn "atoms/${atom_name}.md — confidence: high with no block-anchored cites:: (capped at medium without claim-level grounding)"
        fi
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

ok "extract grounding check complete"

# ── 13. Provenance blocks ────────────────────────────────────────────────────
#
# `generated:` and `verified:` (_meta/schema.md § Provenance) both use the OKF
# actor convention, and `verified:` gained a writer in Phase 4 —
# `memex-trust-audit`. A field with a writer needs a check, or the shape drifts
# and nothing notices.
#
# All WARN. A malformed provenance block is bad bookkeeping, not corruption: the
# note's content is unaffected and no other check depends on it.

echo ""
echo "── 13. Provenance Blocks ──────────────────────────────────────────────────"

prov_checked=0

# Actor form: <producer>/<version>, human:<id>, or process:<id>
actor_ok() {
    case "$1" in
        human:?*|process:?*) return 0 ;;
        */?*)               return 0 ;;
        *)                  return 1 ;;
    esac
}

while IFS= read -r -d '' f; do
    label=$(realpath --relative-to="$VAULT" "$f")
    grep -qE "^(generated|verified):" "$f" 2>/dev/null || continue
    prov_checked=$((prov_checked + 1))

    # 13a. generated: — a mapping with both by: and at:
    if grep -qE "^generated:" "$f" 2>/dev/null; then
        gen_by=$(awk '/^generated:/{f=1;next} f&&/^[a-z]/{exit} f&&/^[[:space:]]+by:/{sub(/^[[:space:]]+by:[[:space:]]*/,"");print;exit}' "$f")
        gen_at=$(awk '/^generated:/{f=1;next} f&&/^[a-z]/{exit} f&&/^[[:space:]]+at:/{sub(/^[[:space:]]+at:[[:space:]]*/,"");print;exit}' "$f")
        if [ -z "$gen_by" ] || [ -z "$gen_at" ]; then
            warn "$label — generated: is missing by: or at:"
        else
            actor_ok "$gen_by" || warn "$label — generated.by '$gen_by' is not a valid actor string (<producer>/<version>, human:<id>, process:<id>)"
            echo "$gen_at" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || warn "$label — generated.at '$gen_at' is not YYYY-MM-DD"
        fi
    fi

    # 13b. verified: — a list, every entry carrying by: and at:
    if grep -qE "^verified:" "$f" 2>/dev/null; then
        ver_block=$(awk '/^verified:/{f=1;next} f&&/^[a-z]/{exit} f{print}' "$f")
        entry_count=$(printf '%s\n' "$ver_block" | grep -cE '^[[:space:]]*-[[:space:]]' || true)
        if [ "$entry_count" -eq 0 ]; then
            warn "$label — verified: is present but has no list entries (expected '- by:' / '  at:')"
        else
            by_count=$(printf '%s\n' "$ver_block" | grep -cE '^[[:space:]]*-?[[:space:]]*by:' || true)
            at_count=$(printf '%s\n' "$ver_block" | grep -cE '^[[:space:]]*at:' || true)
            if [ "$by_count" -ne "$entry_count" ] || [ "$at_count" -ne "$entry_count" ]; then
                warn "$label — verified: has $entry_count entr(ies) but $by_count by: and $at_count at: (each entry needs both)"
            fi
            while IFS= read -r vb; do
                actor_ok "$vb" || warn "$label — verified.by '$vb' is not a valid actor string"
                case "$vb" in
                    human:*) ;;
                    *) warn "$label — verified.by '$vb' is not a human: actor — verified: records human sign-off only" ;;
                esac
            done < <(printf '%s\n' "$ver_block" | grep -oE 'by:[[:space:]]*[^[:space:]]+' | sed 's/^by:[[:space:]]*//')
        fi

        # 13c. Stale sign-off: newest verified.at older than updated:
        newest_ver=$(printf '%s\n' "$ver_block" | grep -oE 'at:[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}' \
                     | sed 's/^at:[[:space:]]*//' | sort | tail -1 || true)
        updated=$(grep -m1 "^updated:" "$f" 2>/dev/null | sed 's/^updated:[[:space:]]*//' || true)
        if [ -n "$newest_ver" ] && [ -n "$updated" ]; then
            if [[ "$updated" > "$newest_ver" ]]; then
                warn "$label — signed off $newest_ver but updated $updated (sign-off predates the current content)"
            fi
        fi
    fi
done < <(find "$VAULT/atoms" "$VAULT/sources" "$VAULT/topics" "$VAULT/glossary" "$VAULT/extracts" \
             -name "*.md" ! -name ".gitkeep" -print0 2>/dev/null)

if [ "$prov_checked" -eq 0 ]; then
    echo -e "  ${DIM}SKIP${NC}  no generated: or verified: blocks yet"
fi
ok "provenance block check complete"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "── Summary ────────────────────────────────────────────────────────────────"

count_md() { find "$1" -name "*.md" ! -name ".gitkeep" 2>/dev/null | wc -l; }

printf "  %-22s %s\n" "Sources (web):"     "$(count_md "$VAULT/sources/web")"
printf "  %-22s %s\n" "Sources (video):"   "$(count_md "$VAULT/sources/video")"
printf "  %-22s %s\n" "Sources (paper):"   "$(count_md "$VAULT/sources/paper")"
printf "  %-22s %s\n" "Sources (docs):"    "$(count_md "$VAULT/sources/docs")"
printf "  %-22s %s\n" "Sources (meeting):" "$(count_md "$VAULT/sources/meeting")"
printf "  %-22s %s\n" "Extracts:"          "$(count_md "$VAULT/extracts")"
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

finished=true

# FAIL gates; WARN does not. See the exit-status note at the top of this file.
if [ "$fails" -gt 0 ]; then
    exit 1
fi
exit 0
