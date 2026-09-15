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
#   3. (retired in rc.2 — temporal threshold, roadmap M11a; number kept)
#   4. Orphan atoms (no cites::, no inbound links from curated nodes)
#   5. Archive mismatches (raw:: pointing to missing file)
#   6. Graph health (inbox-only sources, isolated atoms, bloated atoms, broad topic maps)
#   7. Structural integrity (orphan part-of, atom freshness, unknown relation fields,
#      topic tree shape)
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
#   2 — the linter itself broke before reaching a verdict, or cannot run in this
#       shell (bash < 4); says nothing about the vault. Kept distinct from 1 so a
#       bug here can never be read as corruption.
#
# WARN is a soft signal for human review. FAIL means the vault is corrupt in a way
# no reviewer should have to notice: a misnamed source, a raw:: pointing at a file
# that does not exist, or an extracted claim quoting text the source never
# contained.

# Needs bash 4: associative arrays and mapfile. Stock macOS ships bash 3.2 as
# /bin/bash, where both fail at runtime and the trap below would misreport that as
# a linter bug. Refuse up front instead, before anything else runs.
if [ -z "${BASH_VERSINFO:-}" ] || [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    echo "lint.sh needs bash >= 4 (running under ${BASH_VERSION:-a non-bash shell})." >&2
    echo "On macOS: brew install bash, then run 'bash _meta/lint.sh' with it first on PATH." >&2
    exit 2
fi

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

# fm_value <file> <key>: the key's value from the frontmatter, and only from it.
# Sets REPLY to the value, FM_FOUND to 1 when the key is present (even with an
# empty value) and 0 otherwise.
#
# Lint used to read frontmatter with `grep "^key:" | head -1` over the whole file,
# which misread three ways (roadmap M20, audited 2026-09-15): a body line counted
# as the field — `status:` inside a fenced YAML example FAILed the vault, and a
# prose `stage:` line hid a missing one; a trailing space, CR or quotes made
# `confidence: high ` not equal "high", silencing 8a/8c/12f; and an empty value
# counted as present. This reads between the fences, takes the first occurrence,
# and strips CR, surrounding whitespace, a trailing " #comment" and one pair of
# quotes — which is what a YAML reader such as Dataview sees.
fm_value() {
    local out
    out=$(awk -v k="$2" 'BEGIN { SQ = "\047" }
        NR == 1 { if ($0 !~ /^---[[:space:]]*$/) exit; fm = 1; next }
        fm && /^---[[:space:]]*$/ { exit }
        fm && index($0, k ":") == 1 {
            v = substr($0, length(k) + 2)
            sub(/\r$/, "", v); sub(/[[:space:]]+#.*$/, "", v)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
            if (v ~ /^".*"$/ || v ~ ("^" SQ ".*" SQ "$")) v = substr(v, 2, length(v) - 2)
            print "=" v; exit
        }' "$1" 2>/dev/null || true)
    if [ -n "$out" ]; then FM_FOUND=1; REPLY=${out#=}; else FM_FOUND=0; REPLY=""; fi
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
# Sets REPLY to the resolved paths, one per line, deduplicated — empty when an atom
# has no resolvable citations. Memoized per atom: 7c, 7d and 8a-8c all ask.
backing_sources() {
    local f="$1" target note paths=""
    if [ -n "${BACKING[$f]+x}" ]; then
        REPLY=${BACKING[$f]}
        return 0
    fi
    while IFS= read -r target; do
        target="${target%%|*}"          # [[slug|display text]] names slug
        note="${target%%#*}"
        [ -z "$note" ] && continue
        case "$note" in
            ext-*)
                if [ -z "${EXT_SOURCE[$note]+x}" ]; then
                    EXT_SOURCE[$note]=""
                    if [ -f "$VAULT/extracts/${note}.md" ]; then
                        EXT_SOURCE[$note]=$(grep -m1 "^extracted-from::" "$VAULT/extracts/${note}.md" 2>/dev/null \
                              | grep -oE '\[\[[^]|]+' | tr -d '[' | head -1 || true)
                    fi
                fi
                if [ -n "${EXT_SOURCE[$note]}" ]; then
                    note="${EXT_SOURCE[$note]}"
                fi
                ;;
        esac
        if [ -n "${SRC_PATH[$note]+x}" ]; then
            paths+="${SRC_PATH[$note]}"$'\n'
        fi
    done < <(grep -E "^cites::" "$f" 2>/dev/null \
             | grep -oE '\[\[[^]]+\]\]' | sed 's/^\[\[//; s/\]\]$//' || true)
    BACKING[$f]=$(printf '%s' "$paths" | grep -v '^$' | sort -u || true)
    REPLY=${BACKING[$f]}
}

# ── Lookup tables ────────────────────────────────────────────────────────────
# Built once, so no check pays per citation (roadmap M16). backing_sources() used
# to run a find over sources/ for every citation, and 7c, 7d, 8a, 8b and 8c each
# re-resolved every atom: ~1,360 find/grep pairs on a 22-atom vault, extrapolating
# to ~26,000 at 200 sources. 7a, 12a and 12e ran the same per-item find.
#
# `find ROOT... -name "$slug.md" | head -1` answers with the first match in find's
# traversal order, so each table keeps the first path it meets in that same order
# and a duplicate basename resolves exactly as before. The one difference: -name
# read a slug as a glob, and a table key is literal — no real slug contains * ? [.
#
# Paths print as ${f#"$VAULT"/} rather than `realpath --relative-to`, which forked
# once per file and is GNU-only. Every path here comes from a find rooted at
# "$VAULT/...", so stripping that prefix gives the same answer.
declare -A BACKING=() EXT_SOURCE=() SRC_PATH=() NOTE_PATH=() TOPIC_PATH=() \
           SRC_STAGE=() SRC_SAVED=() ANCHOR_FOUND=() STAGE_VOCAB=() \
           LIST_MEMBER=() LIST_INDEXED=()

while IFS= read -r -d '' p; do
    b="${p##*/}"; b="${b%.md}"
    if [ -n "$b" ] && [ -z "${SRC_PATH[$b]+x}" ]; then SRC_PATH[$b]=$p; fi
done < <(find "$VAULT/sources" -name "*.md" -print0 2>/dev/null)

while IFS= read -r -d '' p; do
    b="${p##*/}"; b="${b%.md}"
    if [ -n "$b" ] && [ -z "${NOTE_PATH[$b]+x}" ]; then NOTE_PATH[$b]=$p; fi
done < <(find "$VAULT/extracts" "$VAULT/sources" "$VAULT/atoms" -name "*.md" -print0 2>/dev/null)

while IFS= read -r -d '' p; do
    b="${p##*/}"; b="${b%.md}"
    if [ -n "$b" ] && [ -z "${TOPIC_PATH[$b]+x}" ]; then TOPIC_PATH[$b]=$p; fi
done < <(find "$VAULT/topics" -name "*.md" -print0 2>/dev/null)

# field_targets <file> <field>: wikilink targets on `field::` lines outside fenced
# code, one per line, deduplicated. Dataview ignores inline fields in a code
# block, and so must anything that builds structure from them: the shipped
# getting-started.md shows `part-of:: [[getting-started]]` inside a fence as a
# worked example, which read as the map naming itself as parent.
field_targets() {
    awk -v k="$2" '/^[[:space:]]*(```|~~~)/ { fence = !fence; next }
                   !fence && index($0, k "::") == 1 {
                       s = $0
                       while (match(s, /\[\[[^]|#]+/)) { print substr(s, RSTART + 2, RLENGTH - 2); s = substr(s, RSTART + RLENGTH) }
                   }' "$1" 2>/dev/null | sort -u || true
}

# Topic tree (_meta/schema.md § Topic Hierarchy). CM_PARENTS[map] holds the
# parents a concept map names on its own part-of::, one per line; a key exists for
# every concept map, so it doubles as "is this slug a concept map". CM_HAS_CHILD
# marks every concept map some other map names as its parent — i.e. non-leaves.
declare -A CM_PARENTS=() CM_HAS_CHILD=()
while IFS= read -r -d '' p; do
    b="${p##*/}"; b="${b%.md}"
    CM_PARENTS[$b]=$(field_targets "$p" part-of)
done < <(find "$VAULT/topics/concepts" -name "*.md" ! -name ".gitkeep" -print0 2>/dev/null)
for b in "${!CM_PARENTS[@]}"; do
    while IFS= read -r par; do
        if [ -n "$par" ]; then CM_HAS_CHILD[$par]=1; fi
    done <<< "${CM_PARENTS[$b]}"
done

# A note's frontmatter stage: / saved:, via fm_value — once per file instead of
# once per citation per section. Sets REPLY.
note_stage() {
    if [ -z "${SRC_STAGE[$1]+x}" ]; then
        fm_value "$1" stage; SRC_STAGE[$1]=$REPLY
    fi
    REPLY=${SRC_STAGE[$1]}
}
note_saved() {
    if [ -z "${SRC_SAVED[$1]+x}" ]; then
        fm_value "$1" saved; SRC_SAVED[$1]=$REPLY
    fi
    REPLY=${SRC_SAVED[$1]}
}

# Does <file> contain <anchor> anywhere (grep -F)? Memoized per pair for 12e.
anchor_in() {
    local key="$1"$'\x1f'"$2"
    if [ -z "${ANCHOR_FOUND[$key]+x}" ]; then
        if grep -qF -- "$2" "$1" 2>/dev/null; then ANCHOR_FOUND[$key]=1; else ANCHOR_FOUND[$key]=0; fi
    fi
    [ "${ANCHOR_FOUND[$key]}" = 1 ]
}

# list_has <name> <list> <word> — `echo "$list" | grep -qx "$word"` without the
# fork. For a plain word (letters, digits, - and _: every real tag, relation field,
# medium and stage value) a full-line match is string equality, so a set indexed
# once per list answers it. Any other word still takes the original grep, so the
# match semantics never change.
list_has() {
    local name="$1" list="$2" word="$3" line
    if [[ ! $word =~ ^[A-Za-z0-9_][A-Za-z0-9_-]*$ ]]; then
        echo "$list" | grep -qx "$word"
        return
    fi
    if [ -z "${LIST_INDEXED[$name]+x}" ]; then
        LIST_INDEXED[$name]=1
        while IFS= read -r line; do
            if [ -n "$line" ]; then LIST_MEMBER["$name"$'\x1f'"$line"]=1; fi
        done <<< "$list"
    fi
    [ -n "${LIST_MEMBER["$name"$'\x1f'"$word"]+x}" ]
}

# ── Source independence (finding 7, M15) ────────────────────────────────────
# `_meta/schema.md` § Confidence Values counts *independent* sources: two are not
# independent when one cites the other, directly or through a chain in the vault,
# or they share an author (`authors:`, `channel:`, `tool:`). Counting sources
# instead made 8b call seven correctly-hedged atoms upgrade candidates in trial 1;
# Hagmann and Cammoun share six authors and are one unit. The schema's third test,
# "one restates the other", is a judgement and stays with memex-trust-audit.
#
# A person is first initial + surname, letters only, hyphens read as spaces:
# "Klaas E. Stephan" matches "K. Stephan" and "Julio E. Villalón-Reina" matches
# "J. Villalon Reina", but "Cao T. Do" does not match "Kim Q. Do" — surname alone
# chained two unrelated author groups into one through exactly that pair.
# `channel:` and `tool:` compare as whole values, case-insensitively. Non-ASCII
# letters are dropped on both sides, so one name spelled with and without
# diacritics in different notes will not match.
#
# A source carrying none of those fields cannot be checked. It counts as its own
# unit and is reported as unchecked, so the number never reads as a verdict.
#
# Sets UNITS_ALL / UNCHK_ALL (every backing source) and UNITS_PROC / UNCHK_PROC
# (stage: processed only) per atom path, and VAULT_UNITS / VAULT_UNCHECKED /
# VAULT_SOURCES for the summary.
declare -A UNITS_ALL=() UNCHK_ALL=() UNITS_PROC=() UNCHK_PROC=()
VAULT_UNITS=0; VAULT_UNCHECKED=0; VAULT_SOURCES=0
compute_independence() {
    local input="" slug p src kind a b c
    for slug in "${!SRC_PATH[@]}"; do
        input+="M"$'\t'"$slug"$'\t'"${SRC_PATH[$slug]}"$'\n'
    done
    while IFS= read -r -d '' p; do
        backing_sources "$p"
        while IFS= read -r src; do
            [ -z "$src" ] && continue
            note_stage "$src"
            input+="A"$'\t'"$p"$'\t'"$src"$'\t'"${REPLY:-none}"$'\n'
        done <<< "$REPLY"
    done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0 2>/dev/null)

    while IFS=$'\t' read -r kind p a b c; do
        case "$kind" in
            U) UNITS_ALL[$p]=$a;  UNCHK_ALL[$p]=$b ;;
            P) UNITS_PROC[$p]=$a; UNCHK_PROC[$p]=$b ;;
            V) VAULT_UNITS=$p; VAULT_UNCHECKED=$a; VAULT_SOURCES=$b ;;
        esac
    done < <(printf '%s' "$input" | LC_ALL=C awk -F'\t' '
        function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
        function person(s,   n, part, first, last) {
            gsub(QUOTES, "", s); s = trim(s)
            if (s == "" || tolower(s) ~ /^et al\.?$/) return ""
            gsub(/-/, " ", s)
            n = split(s, part, /[ \t]+/)
            last = tolower(part[n]); gsub(/[^a-z]/, "", last)
            if (last == "") return ""
            first = tolower(part[1]); gsub(/[^a-z]/, "", first)
            return (n > 1 ? substr(first, 1, 1) "." : "") last
        }
        function addkey(p, kind, s,   k) {
            if (kind == "named") { gsub(QUOTES, "", s); k = tolower(trim(s)); if (k == "") return; k = "=" k }
            else { k = person(s); if (k == "") return }
            if (!((p, k) in has)) { has[p, k] = 1; nk[p]++; keys[p] = keys[p] SUBSEP k; holders[k] = holders[k] SUBSEP p }
        }
        function read_source(p,   line, lineno, fm, inlist, s, n, arr, i, t) {
            lineno = 0; fm = 0; inlist = ""
            while ((getline line < p) > 0) {
                lineno++
                if (lineno == 1 && line ~ /^---[ \t]*$/) { fm = 1; continue }
                if (fm && line ~ /^---[ \t]*$/) { fm = 0; continue }
                if (fm) {
                    if (inlist != "" && line ~ /^[ \t]*-/) { s = line; sub(/^[ \t]*-[ \t]*/, "", s); addkey(p, inlist, s); continue }
                    inlist = ""
                    if (line ~ /^authors:/) {
                        s = trim(substr(line, 9))
                        if (s ~ /^\[/) { sub(/^\[/, "", s); sub(/\][ \t]*$/, "", s); n = split(s, arr, ","); for (i = 1; i <= n; i++) addkey(p, "person", arr[i]) }
                        else if (s == "") inlist = "person"
                        else addkey(p, "person", s)
                    } else if (line ~ /^(channel|tool):/) {
                        s = line; sub(/^(channel|tool):/, "", s); addkey(p, "named", s)
                    }
                } else if (line ~ /^cites::/) {
                    s = line
                    while (match(s, /\[\[[^]]+\]\]/)) {
                        t = substr(s, RSTART + 2, RLENGTH - 4); s = substr(s, RSTART + RLENGTH)
                        sub(/[#|].*/, "", t)
                        if ((t in slugpath) && slugpath[t] != p) cite[p, ++ncite[p]] = slugpath[t]
                    }
                }
            }
            close(p)
        }
        function dependent(a, b,   n, k, i) {
            if (((a, b) in reach) || ((b, a) in reach)) return 1
            n = split(keys[a], k, SUBSEP)
            for (i = 2; i <= n; i++) if ((b, k[i]) in has) return 1
            return 0
        }
        # Independent units among set[1..n]: connected components of "dependent".
        function units(set, n,   i, j, par, r, cnt, x, y) {
            for (i = 1; i <= n; i++) par[i] = i
            for (i = 1; i <= n; i++) for (j = i + 1; j <= n; j++) if (dependent(set[i], set[j])) {
                x = i; while (par[x] != x) x = par[x]
                y = j; while (par[y] != y) y = par[y]
                if (x != y) par[x] = y
            }
            cnt = 0
            for (i = 1; i <= n; i++) { x = i; while (par[x] != x) x = par[x]; if (!(x in r)) { r[x] = 1; cnt++ } }
            return cnt
        }
        function unchecked(set, n,   i, c) { c = 0; for (i = 1; i <= n; i++) if (!(set[i] in nk)) c++; return c }
        # Vault-wide units without testing every pair, which is quadratic in
        # sources: union the holders of each author key, then each cites:: reach.
        function root(x) { while (vpar[x] != x) x = vpar[x]; return x }
        function join(a, b,   x, y) { x = root(a); y = root(b); if (x != y) vpar[x] = y }
        function vault_units(   i, k, n, h, j, pr, cnt, seen2) {
            for (i = 1; i <= nsrc; i++) vpar[srcs[i]] = srcs[i]
            for (k in holders) { n = split(holders[k], h, SUBSEP); for (j = 3; j <= n; j++) join(h[2], h[j]) }
            for (pr in reach) { split(pr, h, SUBSEP); join(h[1], h[2]) }
            cnt = 0
            for (i = 1; i <= nsrc; i++) { k = root(srcs[i]); if (!(k in seen2)) { seen2[k] = 1; cnt++ } }
            return cnt
        }

        BEGIN { QUOTES = "[\"\047]" }
        $1 == "M" { slugpath[$2] = $3; if (!($3 in isrc)) { isrc[$3] = 1; srcs[++nsrc] = $3 }; next }
        $1 == "A" { all[$2, ++nall[$2]] = $3; if ($4 == "processed") proc[$2, ++nproc[$2]] = $3; next }
        END {
            for (i = 1; i <= nsrc; i++) read_source(srcs[i])
            # Directed reachability over cites:: between sources, one BFS per source.
            for (i = 1; i <= nsrc; i++) {
                a = srcs[i]; head = 1; tail = 0; delete seen; delete q
                for (j = 1; j <= ncite[a]; j++) { q[++tail] = cite[a, j] }
                while (head <= tail) {
                    x = q[head++]; if (x in seen) continue
                    seen[x] = 1; reach[a, x] = 1
                    for (j = 1; j <= ncite[x]; j++) q[++tail] = cite[x, j]
                }
            }
            for (atom in nall) {
                delete set; for (i = 1; i <= nall[atom]; i++) set[i] = all[atom, i]
                printf "U\t%s\t%d\t%d\n", atom, units(set, nall[atom]), unchecked(set, nall[atom])
                delete set; for (i = 1; i <= nproc[atom]; i++) set[i] = proc[atom, i]
                printf "P\t%s\t%d\t%d\n", atom, units(set, nproc[atom] + 0), unchecked(set, nproc[atom] + 0)
            }
            delete set; for (i = 1; i <= nsrc; i++) set[i] = srcs[i]
            printf "V\t%d\t%d\t%d\n", vault_units(), unchecked(set, nsrc), nsrc
        }')
}

# Sources that have an extract: the target of some extract's extracted-from::,
# resolved the same way 12a resolves it.
declare -A EXTRACTED=() CLOSE_READ=()
while IFS= read -r line; do
    if [[ $line =~ extracted-from::.*\[\[([^]|#]+) ]] && [ -n "${SRC_PATH[${BASH_REMATCH[1]}]+x}" ]; then
        EXTRACTED[${SRC_PATH[${BASH_REMATCH[1]}]}]=1
    fi
done < <(grep -rh -m1 --include='*.md' "^extracted-from::" "$VAULT/extracts" 2>/dev/null || true)

# read_closely <atom> <resolved sources>: has anything this atom rests on been
# read claim by claim? Yes when it carries a block-anchored citation into an
# extract, or when any cited source has an extract. Memoized; used by 7d and 8c.
read_closely() {
    local f="$1" src
    if [ -z "${CLOSE_READ[$f]+x}" ]; then
        CLOSE_READ[$f]=0
        if grep -qE '^cites::.*\[\[ext-[^]|]*#\^' "$f" 2>/dev/null; then
            CLOSE_READ[$f]=1
        else
            while IFS= read -r src; do
                if [ -n "$src" ] && [ -n "${EXTRACTED[$src]+x}" ]; then CLOSE_READ[$f]=1; break; fi
            done <<< "$2"
        fi
    fi
    [ "${CLOSE_READ[$f]}" = 1 ]
}

# " — independence unchecked for K source(s) …" when K > 0, else nothing.
unchecked_note() {
    if [ "${1:-0}" -gt 0 ]; then
        printf ' — independence unchecked for %s source(s) with no authors:/channel:/tool:' "$1"
    fi
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
    if ! list_has media "$source_media" "$medium"; then
        warn "sources/$medium/ exists but is not declared in _meta/domain.md § Source Types — its notes are unchecked"
    fi
done < <(find "$VAULT/sources" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)

while IFS= read -r -d '' f; do
    name="$(basename "$f")"
    if [[ "$name" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}- ]]; then
        warn "atoms/$(basename "$f") — atom has a date prefix (should be kebab-concept-name only)"
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# Atoms and glossary terms share one wikilink namespace: Obsidian resolves [[x]] by
# filename, and _meta/schema.md § Disambiguation Policy forbids two notes sharing
# one. Nothing enforced it, and deep-extract mode B once proposed three glossary
# stubs whose slugs were atoms in the same run (trial-1 finding 10). The glossary
# is a disjoint set by design (M7); this is the guard that keeps it disjoint.
#   FAIL — a filename present in both atoms/ and glossary/
#   WARN — a glossary slug equal to an atom's alias, slugified
slugify() {
    local x="${1,,}"
    x="${x//[^a-z0-9]/-}"
    while [[ $x == *--* ]]; do x="${x//--/-}"; done
    x="${x#-}"; x="${x%-}"
    REPLY=$x
}
if [ -d "$VAULT/glossary" ]; then
    declare -A ALIAS_OWNER=()
    while IFS= read -r -d '' f; do
        aliases_line=$(awk 'NR == 1 && /^---[[:space:]]*$/ { fm = 1; next }
                            fm && /^---[[:space:]]*$/ { exit }
                            fm && /^aliases:/ { inl = 1; sub(/^aliases:[[:space:]]*/, ""); sub(/^\[/, ""); sub(/\][[:space:]]*$/, ""); if ($0 != "") print; next }
                            fm && inl && /^[[:space:]]*-/ { sub(/^[[:space:]]*-[[:space:]]*/, ""); print; next }
                            { inl = 0 }' "$f" 2>/dev/null | tr '\n' ',' || true)
        IFS=',' read -ra alias_arr <<< "$aliases_line"
        for alias in "${alias_arr[@]}"; do
            alias="${alias//[\"\']/}"
            slugify "$alias"
            if [ -n "$REPLY" ] && [ -z "${ALIAS_OWNER[$REPLY]+x}" ]; then ALIAS_OWNER[$REPLY]="atoms/$(basename "$f")"; fi
        done
    done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0 2>/dev/null)

    while IFS= read -r -d '' g; do
        term="$(basename "$g" .md)"
        if [ -f "$VAULT/atoms/${term}.md" ]; then
            error "glossary/${term}.md — atoms/${term}.md has the same filename; [[${term}]] is ambiguous (schema.md § Disambiguation Policy)"
        elif [ -n "${ALIAS_OWNER[$term]+x}" ]; then
            warn "glossary/${term}.md — matches an alias of ${ALIAS_OWNER[$term]}; one concept may be in two notes"
        fi
    done < <(find "$VAULT/glossary" -name "*.md" ! -name ".gitkeep" -print0)
fi

ok "naming check complete"

# ── 2. Required frontmatter fields ──────────────────────────────────────────

echo ""
echo "── 2. Required Frontmatter Fields ────────────────────────────────────────"

# Present in the frontmatter with a non-empty value. Section 11 checks that type:
# and stage: carry legal *values*.
check_field() {
    local file="$1" field="$2" label="$3"
    fm_value "$file" "$field"
    if [ "$FM_FOUND" -eq 0 ]; then
        warn "$label — missing field: $field"
    elif [ -z "$REPLY" ]; then
        warn "$label — empty field: $field"
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

# ── 3. (retired) ─────────────────────────────────────────────────────────────
# "Stale unread sources (>30 days)" was removed in rc.2 (roadmap M11a). It asked
# the question memex-stale's old Check 1 asked, with a different number, and on
# the first real vault neither produced a finding: how long a source has sat
# unread measures the vault's age, not the source. The number is kept so every
# "section N" reference elsewhere stays valid.

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
                error "${f#"$VAULT"/} — raw:: points to missing file: $raw_path"
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
    note_stage "$f"
    if [[ $REPLY == *unread* || $REPLY == *unprocessed* ]]; then
        has_connections=$(grep -cE "^(supports|introduces|demonstrates|cites|related)::[[:space:]]*\[\[" "$f" 2>/dev/null || true)
        if [ "$has_connections" -eq 0 ]; then
            label=${f#"$VAULT"/}
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

# 6c. Bloated atoms: high cites + high related + a body well above this vault's
# own median (soft heuristic — split candidate).
#
# Size is body characters, not lines. Atom prose is one long-wrapped line per
# paragraph, so the old `lines > 100` could not fire on any real atom: trial-1
# atoms spanned 38-56 lines but 1,417-8,976 characters (roadmap M11c). The
# cites:: line is excluded because it grows with evidence, not with scope, and
# alone reached a fifth of the largest body. The trigger is 2x the vault's median
# rather than a constant, so it calibrates per fork the way tag vocabulary does.
# Below BLOAT_MIN_ATOMS a median means nothing, and the check SKIPs.
BLOAT_MIN_ATOMS=10
body_chars() {
    awk 'NR == 1 && /^---[[:space:]]*$/ { fm = 1; next }
         fm && /^---[[:space:]]*$/      { fm = 0; next }
         fm || /^cites::/               { next }
                                        { n += length($0) + 1 }
         END                            { print n + 0 }' "$1"
}
mapfile -t atom_sizes < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0 2>/dev/null \
    | while IFS= read -r -d '' f; do body_chars "$f"; done | sort -n)
atom_n=${#atom_sizes[@]}
if [ "$atom_n" -lt "$BLOAT_MIN_ATOMS" ]; then
    echo -e "  ${DIM}SKIP${NC}  6c bloated atoms — $atom_n atoms, need $BLOAT_MIN_ATOMS for a meaningful median"
else
    if (( atom_n % 2 )); then
        bloat_median=${atom_sizes[atom_n / 2]}
    else
        bloat_median=$(( (atom_sizes[atom_n / 2 - 1] + atom_sizes[atom_n / 2]) / 2 ))
    fi
    bloat_limit=$(( 2 * bloat_median ))
    while IFS= read -r -d '' f; do
        cites_count=$(count_links "$f" 'cites')
        related_count=$(count_links "$f" 'related')
        chars=$(body_chars "$f")
        if [ "$cites_count" -gt 5 ] && [ "$related_count" -gt 4 ] && [ "$chars" -gt "$bloat_limit" ]; then
            warn "atoms/$(basename "$f") — may cover multiple concepts (cites=$cites_count related=$related_count body=$chars chars, limit=$bloat_limit = 2x median); consider splitting"
        fi
    done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)
fi

# 6d. Broad topic maps: many member atoms (sub-domain split candidate)
# Membership is derived, so count atoms pointing here rather than reading the topic.
# Leaves only: a concept map with sub-topics has already been split, and its
# breadth is its children's (_meta/schema.md § Topic Hierarchy).
while IFS= read -r -d '' f; do
    topic_name="$(basename "$f" .md)"
    [ -n "${CM_HAS_CHILD[$topic_name]+x}" ] && continue
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
            if [ -z "$target" ] || [ -z "${TOPIC_PATH[$target]+x}" ]; then
                warn "atoms/${atom_name}.md — part-of:: [[${target}]] but no matching topic file found"
            fi
        done < <(echo "$line" | grep -oE '\[\[[^]|]+' | tr -d '[')
    done < <(grep "^part-of::" "$f" 2>/dev/null || true)
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# 7a, topics. A topic's own part-of:: names its parent. Only concept maps are in
# the tree, and a concept map's parent must be another concept map. Neither lint
# nor memex-reconcile checked these before the hierarchy existed.
while IFS= read -r -d '' f; do
    rel=${f#"$VAULT"/}
    while IFS= read -r target; do
        [ -z "$target" ] && continue
        if [ -z "${TOPIC_PATH[$target]+x}" ]; then
            warn "$rel — part-of:: [[${target}]] but no matching topic file found"
        elif [[ $rel != topics/concepts/* ]]; then
            warn "$rel — part-of:: [[${target}]], but only concept maps have a parent; projects and research questions sit outside the topic tree"
        elif [ -z "${CM_PARENTS[$target]+x}" ]; then
            warn "$rel — part-of:: [[${target}]] is not a concept map; a concept map's parent must be one"
        fi
    done < <(field_targets "$f" part-of)
done < <(find "$VAULT/topics" -name "*.md" ! -name ".gitkeep" -print0 2>/dev/null)

# 7f. Topic tree shape: a concept map names at most one parent, and walking parents
# upward ends at a root. A cycle warns once for each map on it.
mapfile -t tree_maps < <(printf '%s\n' "${!CM_PARENTS[@]}" | grep -v '^$' | sort)
for cm in "${tree_maps[@]}"; do
    n_par=$(printf '%s\n' "${CM_PARENTS[$cm]}" | grep -c . || true)
    if [ "$n_par" -gt 1 ]; then
        warn "topics/concepts/${cm}.md — names $n_par parents ($(printf '%s\n' "${CM_PARENTS[$cm]}" | paste -sd, -)); a concept map has at most one"
    fi
    cur=$cm; steps=0
    while [ "$steps" -le "${#tree_maps[@]}" ]; do
        par=$(printf '%s\n' "${CM_PARENTS[$cur]:-}" | head -1)
        [ -z "$par" ] && break
        [ -z "${CM_PARENTS[$par]+x}" ] && break          # dangling or not a concept map: 7a reports it
        if [ "$par" = "$cm" ]; then
            warn "topics/concepts/${cm}.md — is on a part-of:: cycle; walking parents upward must end at a root"
            break
        fi
        cur=$par; steps=$((steps + 1))
    done
done

# 7g. An atom names one concept map, and it is a leaf. Project and research
# memberships are additive and not counted. Naming none is a gap, not an error —
# _meta/index.md lists uncategorized atoms.
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    atom_maps=()
    while IFS= read -r target; do
        if [ -n "$target" ] && [ -n "${CM_PARENTS[$target]+x}" ]; then atom_maps+=("$target"); fi
    done < <(field_targets "$f" part-of)
    if [ "${#atom_maps[@]}" -gt 1 ]; then
        warn "atoms/${atom_name}.md — names ${#atom_maps[@]} concept maps ($(IFS=,; echo "${atom_maps[*]}")); an atom names one leaf, and its ancestors derive"
    elif [ "${#atom_maps[@]}" -eq 1 ] && [ -n "${CM_HAS_CHILD[${atom_maps[0]}]+x}" ]; then
        warn "atoms/${atom_name}.md — part-of:: [[${atom_maps[0]}]] has sub-topics; name the leaf this atom belongs to"
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# 7c. Atom freshness: newest cited source saved > 18 months ago
if cutoff18=$(date -d "18 months ago" +%Y-%m-%d 2>/dev/null) || cutoff18=$(date -v-18m +%Y-%m-%d 2>/dev/null); then
    while IFS= read -r -d '' f; do
        atom_name="$(basename "$f" .md)"
        newest_saved=""
        backing_sources "$f"
        while IFS= read -r src_file; do
            [ -z "$src_file" ] && continue
            note_saved "$src_file"; saved=$REPLY
            [ -z "$saved" ] && continue
            if [ -z "$newest_saved" ] || [[ "$saved" > "$newest_saved" ]]; then
                newest_saved="$saved"
            fi
        done <<< "$REPLY"
        if [ -n "$newest_saved" ] && [[ "$newest_saved" < "$cutoff18" ]]; then
            warn "atoms/${atom_name}.md — newest cited source saved $newest_saved (>18 months ago); may be stale"
        fi
    done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)
fi

# 7d. Unchecked evidence: nothing the atom cites has been read claim by claim.
#
# This used to test for every cited source being `stage: unread`. But `read` is
# the one stage value no skill can verify — "a human read this" is self-reported,
# and reported aspirationally — so the check fired on papers just read 37 claims
# deep, whose stage: lagged because deep-extract mode A may not touch the source
# note, and stayed silent on sources marked read that nobody had read (trial-1
# finding 11). It now keys on evidence the vault can check: a block-anchored
# cites:: [[ext-...#^cNN]], or a cited source that has an extract. stage: read
# survives as an annotation that nothing here depends on.
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    backing_sources "$f"; resolved=$REPLY
    # No resolvable source is a dangling-link problem, not an evidence one — do
    # not report it here.
    [ -z "$resolved" ] && continue
    if ! read_closely "$f" "$resolved"; then
        warn "atoms/${atom_name}.md — no cited source has been read claim by claim (no block-anchored cites::, and no cited source has an extract)"
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# 7e. Unknown relation field: body field not in schema taxonomy
schema_file="$VAULT/_meta/schema.md"
if [ -f "$schema_file" ]; then
    valid_fields=$(awk '/^## Valid Relation Fields/{f=1} f && /^```$/{b=!b; next} f && b{print} f && /^---$/ && !b && NR>1{exit}' "$schema_file" | grep -v "^$")
    if [ -n "$valid_fields" ]; then
        while IFS= read -r -d '' f; do
            label=${f#"$VAULT"/}
            while IFS= read -r field; do
                if ! list_has fields "$valid_fields" "$field"; then
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

compute_independence

# 8a. Overconfident atom: confidence: high backed by fewer than 3 independent units.
#
# Counts *distinct backing sources* via backing_sources(), not cites:: lines.
# Since Phase 3 an atom can cite [[ext-slug#^c01]], [[ext-slug#^c07]] and
# [[ext-slug#^c12]] — three citations, three claims, but ONE source, which is
# `low` under the rubric and sailed past the old line count.
#
# Those sources are then grouped into independent units (see
# compute_independence): shared author, or a cites:: chain between them. "One
# restates the other" is still a judgement that `memex-trust-audit` owns, so the
# unit count remains an upper bound — it can only under-report.
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    fm_value "$f" confidence; confidence=$REPLY
    if [ "$confidence" = "high" ]; then
        backing_sources "$f"
        source_count=0
        if [ -n "$REPLY" ]; then
            mapfile -t backing_list <<< "$REPLY"
            source_count=${#backing_list[@]}
        fi
        units=${UNITS_ALL[$f]:-0}
        if [ "$units" -lt 3 ]; then
            warn "atoms/${atom_name}.md — confidence: high backed by $source_count distinct source(s) in $units independent unit(s)$(unchecked_note "${UNCHK_ALL[$f]:-0}") (needs 3+ independent for high)"
        fi
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# 8b. Underconfident atom: confidence: low with processed sources in 2+ independent
# units. Counting sources alone was trial 1's noisiest check (finding 7): seven
# false positives in one run, every one two sources from one author group.
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    fm_value "$f" confidence; confidence=$REPLY
    if [ "$confidence" = "low" ]; then
        processed_count=0
        backing_sources "$f"
        while IFS= read -r src_file; do
            [ -z "$src_file" ] && continue
            note_stage "$src_file"; src_stage=$REPLY
            if [ "$src_stage" = "processed" ]; then
                processed_count=$((processed_count + 1))
            fi
        done <<< "$REPLY"
        if [ "$processed_count" -ge 2 ] && [ "${UNITS_PROC[$f]:-0}" -ge 2 ]; then
            warn "atoms/${atom_name}.md — confidence: low but $processed_count processed sources in ${UNITS_PROC[$f]} independent units support it$(unchecked_note "${UNCHK_PROC[$f]:-0}") (upgrade candidate)"
        fi
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# 8c. Unchecked confidence: confidence: medium or high resting on the same
# unchecked evidence 7d reports. 7d says it of any atom; this says it only where a
# confidence above low claims more than anyone has checked, so a low atom is not
# warned twice. Same verifiable test as 7d, for the same reason (finding 11).
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    fm_value "$f" confidence; confidence=$REPLY
    case "$confidence" in medium|high) ;; *) continue ;; esac
    backing_sources "$f"; resolved=$REPLY
    [ -z "$resolved" ] && continue
    if ! read_closely "$f" "$resolved"; then
        warn "atoms/${atom_name}.md — confidence: $confidence but no cited source has been read claim by claim"
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# 8d. Under-extracted source: stage: processed, body > 100 lines, atom connections < 2
while IFS= read -r -d '' f; do
    label=${f#"$VAULT"/}
    note_stage "$f"; src_stage=$REPLY
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
    fm_value "$f" confidence; confidence=$REPLY
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
        label=${f#"$VAULT"/}
        # Extract tags line from frontmatter
        # Inline `tags: [a, b]` or a block list; rendered as "[a, b]" either way.
        tags_line=$(awk '/^---[[:space:]]*$/ { fm++; if (fm == 2) exit; next }
                         fm == 1 && inl && /^[[:space:]]*-/ { t = $0; sub(/^[[:space:]]*-[[:space:]]*/, "", t); out = out (out == "" ? "" : ", ") t; next }
                         fm == 1 && inl { exit }
                         fm == 1 && /^tags:/ { v = $0; sub(/^tags:[[:space:]]*/, "", v); if (v != "") { print v; exit }; inl = 1; next }
                         END { if (inl) print "[" out "]" }' "$f" 2>/dev/null || true)
        [ -z "$tags_line" ] && continue
        # Parse inline YAML array: tags: [a, b, c] or tags: []
        if [[ "$tags_line" =~ \[([^]]*)\] ]]; then
            tags_content="${BASH_REMATCH[1]}"
            [[ -z "${tags_content//[ ,]/}" ]] && continue
            IFS=',' read -ra tag_arr <<< "$tags_content"
            for raw_tag in "${tag_arr[@]}"; do
                # Trim surrounding whitespace, then drop quotes — the old echo|sed, in-process.
                tag="${raw_tag#"${raw_tag%%[![:space:]]*}"}"
                tag="${tag%"${tag##*[![:space:]]}"}"
                tag=${tag//[\"\']/}
                [ -z "$tag" ] && continue
                if ! list_has tags "$valid_tags" "$tag"; then
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
        rel=${f#"$VAULT"/}

        # 11c. status: is forbidden everywhere in the vault, candidates included.
        fm_value "$f" status
        if [ "$FM_FOUND" -eq 1 ]; then
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
            fm_value "$f" type; actual=$REPLY
            if [ -z "$actual" ]; then
                error "$rel — missing required field: type: (expected \"$expected\")"
            elif [ "$actual" != "$expected" ]; then
                error "$rel — type: \"$actual\" but $(dirname "$rel") declares \"$expected\" in _meta/domain.md"
            fi
        fi

        # 11b. stage: value must be in the vocabulary for this node type.
        section=$(stage_section_for "$rel")
        if [ -n "$section" ]; then
            fm_value "$f" stage; stage_val=$REPLY
            if [ -n "$stage_val" ]; then
                if [ -z "${STAGE_VOCAB[$section]+x}" ]; then
                    STAGE_VOCAB[$section]=$(stage_vocab "$section")
                fi
                allowed=${STAGE_VOCAB[$section]}
                if [ -n "$allowed" ] && ! list_has "stage:$section" "$allowed" "$stage_val"; then
                    error "$rel — stage: \"$stage_val\" not valid for $section ($(echo "$allowed" | tr '\n' '/' | sed 's#/$##'))"
                fi
            fi
        fi
    done < <(find "$VAULT/sources" "$VAULT/atoms" "$VAULT/topics" "$VAULT/glossary" \
                  "$VAULT/extracts" "$VAULT/_meta/candidates" -name "*.md" ! -name ".gitkeep" -print0 2>/dev/null)
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
            src_file=${SRC_PATH[$src_target]-}
            if [ -z "$src_file" ]; then
                error "$rel — extracted-from:: [[${src_target}]] but no such file in sources/"
            fi
            if [ "ext-${src_target}" != "$slug" ]; then
                warn "$rel — filename should be ext-${src_target}.md to match extracted-from::"
            fi
        fi

        # 12b. claims: is the one derived number the schema keeps in frontmatter,
        # because Dataview cannot count block ids. Cross-check so it cannot drift.
        fm_value "$f" claims; declared=$REPLY
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
        #
        # Two passes, so the archive is read once per extract rather than grepped
        # once per quote — at 200 sources that is ~8,000 greps (roadmap M16). Pass 1
        # strips each quote: line exactly as the old `echo | sed` did ("- quote:",
        # then one opening and one closing double quote).
        quotes=()
        while IFS= read -r qline; do
            quote=$qline
            if [[ $quote =~ ^[[:space:]]*-[[:space:]]*quote:[[:space:]]* ]]; then
                quote=${quote:${#BASH_REMATCH[0]}}
            fi
            quote=${quote#\"}
            if [[ $quote =~ \"[[:space:]]*$ ]]; then
                quote=${quote:0:${#quote}-${#BASH_REMATCH[0]}}
            fi
            quotes+=("$quote")
        done < <(grep -E '^[[:space:]]*-[[:space:]]*quote:' "$f" 2>/dev/null || true)

        # One awk per extract answers every non-empty quote, in order: is it a
        # substring of the archive? A quote holds no newline, so matching against
        # the whole file cannot cross a line, which is what `grep -F` guarantees;
        # LC_ALL=C makes the comparison bytewise, as grep -F is on valid UTF-8.
        found=()
        if [ -n "$archive" ] && [ "${#quotes[@]}" -gt 0 ]; then
            mapfile -t found < <(
                for quote in "${quotes[@]}"; do [ -n "$quote" ] && printf '%s\n' "$quote"; done \
                | LC_ALL=C awk 'BEGIN { while ((getline line < ARGV[1]) > 0) buf = buf line "\n"
                                        ARGV[1] = "" }
                                { print (index(buf, $0) ? 1 : 0) }' "$archive"
            )
        fi

        i=0
        for quote in "${quotes[@]}"; do
            if [ -z "$quote" ]; then
                error "$rel — empty quote: line"
                continue
            fi
            if [ -z "$archive" ]; then
                unverifiable=$((unverifiable + 1))
                continue
            fi
            if [ "${found[i]:-0}" = 1 ]; then
                grounded=$((grounded + 1))
            else
                hint=""
                case "$quote" in
                    *...*) hint=" [contains an ellipsis — quotes must be contiguous; emit two quote: lines]" ;;
                esac
                error "$rel — quote not found in $(basename "$archive"): \"$(echo "$quote" | cut -c1-70)\"$hint"
            fi
            i=$((i + 1))
        done
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
    label=${f#"$VAULT"/}
    while IFS= read -r ref; do
        target="${ref%%#*}"
        anchor="${ref#*#}"
        tfile=""
        if [ -n "$target" ]; then tfile=${NOTE_PATH[$target]-}; fi
        if [ -z "$tfile" ]; then
            warn "$label — cites:: [[${target}#${anchor}]] but no such note"
        elif ! anchor_in "$tfile" "$anchor"; then
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
    fm_value "$f" confidence; confidence=$REPLY
    if [ "$confidence" = "high" ]; then
        anchored=$(grep -cE '^cites::.*\[\[[^]|]+#\^' "$f" 2>/dev/null || true)
        if [ "$anchored" -eq 0 ]; then
            warn "atoms/${atom_name}.md — confidence: high with no block-anchored cites:: (capped at medium without claim-level grounding)"
        fi
    fi
done < <(find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep" -print0)

# 12g. Unlogged promotion: an atom cites [[ext-slug#^cNN]] on a cites:: line, but
# that extract's ## Promotion Log has no "^cNN -> atoms/<atom>.md" row. Either the
# append failed or a promotion was never logged. The log exists for idempotence —
# mode B reads it so claims are not offered twice — and a silently failed append
# looks identical to success (trial-1 finding 13). This is the standing half of
# that finding; post-write assertions in the skills are deferred.
#
# Rows are read once per extract. A target may be written atoms/x.md, atoms/x,
# x.md, x or [[x]]; all name the same atom.
declare -A PROMO_ROW=() PROMO_READ=()
promo_rows() {
    local ext="$1" file="$VAULT/extracts/$1.md" id target
    [ -n "${PROMO_READ[$ext]+x}" ] && return 0
    PROMO_READ[$ext]=1
    [ -f "$file" ] || return 0
    while IFS=$'\t' read -r id target; do
        target="${target#\[\[}"; target="${target%%\]\]*}"; target="${target%%|*}"
        target="${target#atoms/}"; target="${target%.md}"
        PROMO_ROW["$ext"$'\x1f'"$id"$'\x1f'"$target"]=1
    done < <(awk '/^## Promotion Log/ { f = 1; next }
                  f && /^## /           { exit }
                  f && match($0, /^[[:space:]]*-[[:space:]]*\^c[0-9]+[[:space:]]*->[[:space:]]*[^[:space:]]+/) {
                      s = substr($0, RSTART, RLENGTH)
                      id = s; sub(/^[[:space:]]*-[[:space:]]*/, "", id); sub(/[[:space:]]*->.*/, "", id)
                      t = s; sub(/.*->[[:space:]]*/, "", t)
                      print id "\t" t
                  }' "$file" 2>/dev/null)
}
while IFS= read -r -d '' f; do
    atom_name="$(basename "$f" .md)"
    while IFS= read -r ref; do
        ext="${ref%%#*}"; id="${ref#*#}"
        [ -f "$VAULT/extracts/${ext}.md" ] || continue   # 12e already reports it
        promo_rows "$ext"
        if [ -z "${PROMO_ROW["$ext"$'\x1f'"$id"$'\x1f'"$atom_name"]+x}" ]; then
            warn "atoms/${atom_name}.md — cites [[${ext}#${id}]] but ${ext}'s Promotion Log has no row for ${id} -> atoms/${atom_name}.md (failed append, or a promotion nobody logged)"
        fi
    done < <(grep -E '^cites::' "$f" 2>/dev/null | grep -oE '\[\[ext-[^]|#]+#\^c[0-9]+' | sed 's/^\[\[//' | sort -u || true)
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

# A mapping value as YAML reads it: drop a trailing " #comment", surrounding space
# and one pair of quotes. `by: "human:x"` and `at: 2026-09-15 # ok` are both valid.
unquote() {
    local v="$1"
    v="${v%%[[:space:]]#*}"
    v="${v#"${v%%[![:space:]]*}"}"; v="${v%"${v##*[![:space:]]}"}"
    if [[ $v == \"*\" || $v == \'*\' ]]; then v="${v:1:${#v}-2}"; fi
    printf '%s' "$v"
}

# Actor form: <producer>/<version>, human:<id>, or process:<id>
actor_ok() {
    case "$1" in
        human:?*|process:?*) return 0 ;;
        */?*)               return 0 ;;
        *)                  return 1 ;;
    esac
}

while IFS= read -r -d '' f; do
    label=${f#"$VAULT"/}
    fm_value "$f" generated; has_gen=$FM_FOUND
    fm_value "$f" verified;  has_ver=$FM_FOUND
    [ "$has_gen" -eq 1 ] || [ "$has_ver" -eq 1 ] || continue
    prov_checked=$((prov_checked + 1))

    # 13a. generated: — a mapping with both by: and at:
    if [ "$has_gen" -eq 1 ]; then
        gen_by=$(awk '/^generated:/{f=1;next} f&&(/^[a-z]/||/^---[[:space:]]*$/){exit} f&&/^[[:space:]]+by:/{sub(/^[[:space:]]+by:[[:space:]]*/,"");print;exit}' "$f")
        gen_at=$(awk '/^generated:/{f=1;next} f&&(/^[a-z]/||/^---[[:space:]]*$/){exit} f&&/^[[:space:]]+at:/{sub(/^[[:space:]]+at:[[:space:]]*/,"");print;exit}' "$f")
        gen_by=$(unquote "$gen_by"); gen_at=$(unquote "$gen_at")
        if [ -z "$gen_by" ] || [ -z "$gen_at" ]; then
            warn "$label — generated: is missing by: or at:"
        else
            actor_ok "$gen_by" || warn "$label — generated.by '$gen_by' is not a valid actor string (<producer>/<version>, human:<id>, process:<id>)"
            echo "$gen_at" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || warn "$label — generated.at '$gen_at' is not YYYY-MM-DD"
        fi
    fi

    # 13b. verified: — a list, every entry carrying by: and at:
    # The frontmatter fence terminates the block as well as the next top-level
    # key. verified: is usually the LAST key, so a parser that stops only at
    # /^[a-z]/ runs on into the body and reads prose as provenance — it read
    # 'confounded by: resolution,' as an actor string the first time any atom
    # carried a real sign-off. Silent on 4 of 5 atoms purely by luck.
    if [ "$has_ver" -eq 1 ]; then
        ver_block=$(awk '/^verified:/{f=1;next} f&&(/^[a-z]/||/^---[[:space:]]*$/){exit} f{print}' "$f")
        entry_count=$(printf '%s\n' "$ver_block" | grep -cE '^[[:space:]]*-[[:space:]]' || true)
        if [ "$entry_count" -eq 0 ]; then
            warn "$label — verified: is present but has no list entries (expected '- by:' / '  at:')"
        else
            by_count=$(printf '%s\n' "$ver_block" | grep -cE '^[[:space:]]*-?[[:space:]]*by:' || true)
            at_count=$(printf '%s\n' "$ver_block" | grep -cE '^[[:space:]]*-?[[:space:]]*at:' || true)
            if [ "$by_count" -ne "$entry_count" ] || [ "$at_count" -ne "$entry_count" ]; then
                warn "$label — verified: has $entry_count entr(ies) but $by_count by: and $at_count at: (each entry needs both)"
            fi
            while IFS= read -r vb; do
                vb=$(unquote "$vb")
                actor_ok "$vb" || warn "$label — verified.by '$vb' is not a valid actor string"
                case "$vb" in
                    human:*) ;;
                    *) warn "$label — verified.by '$vb' is not a human: actor — verified: records human sign-off only" ;;
                esac
            done < <(printf '%s\n' "$ver_block" | grep -oE 'by:[[:space:]]*[^[:space:]]+' | sed 's/^by:[[:space:]]*//')
        fi

        # 13c. Stale sign-off: newest verified.at older than updated:
        newest_ver=$(printf '%s\n' "$ver_block" | grep -oE "at:[[:space:]]*[\"']?[0-9]{4}-[0-9]{2}-[0-9]{2}" \
                     | sed -E "s/^at:[[:space:]]*[\"']?//" | sort | tail -1 || true)
        fm_value "$f" updated; updated=$REPLY
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
printf "  %-22s %s\n" "Sources (code):"    "$(count_md "$VAULT/sources/code")"
printf "  %-22s %s\n" "Sources (meeting):" "$(count_md "$VAULT/sources/meeting")"
units_line="$VAULT_UNITS of $VAULT_SOURCES sources"
[ "$VAULT_UNCHECKED" -gt 0 ] && units_line+=" ($VAULT_UNCHECKED with no authors:/channel:/tool:, unchecked)"
printf "  %-22s %s\n" "Independent units:" "$units_line"
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
