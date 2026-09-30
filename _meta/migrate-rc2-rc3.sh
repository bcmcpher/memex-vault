#!/usr/bin/env bash
# migrate-rc2-rc3.sh — bring a vault forked at v1.0.0-rc.2 up to rc.3.
#
# Usage:
#   bash _meta/migrate-rc2-rc3.sh            # dry run: report what would change
#   bash _meta/migrate-rc2-rc3.sh --apply    # make the changes
#
# Run it after taking the template's rc.3 `_meta/` — it uses this vault's own
# `normalize.sh` and `lint.sh`, and refuses to run against the rc.2 ones.
#
# Why the order is fixed
# ----------------------
# rc.3's `normalize.sh` puts text in Unicode NFC (trial 2, T2-7), so the same
# archive normalizes to different bytes than it did under rc.2. Three things
# depend on those bytes, and each step below must see the output of the one
# before it:
#
#   1. `_meta/candidates/.gitkeep` — the folder is tracked from rc.3, so a
#      candidate write on a fresh clone has somewhere to go (T2-18).
#   2. Re-normalize every `.archive/` file. Lint section 12 now fails the quotes
#      that touch a character NFC changed (on trial 2: 9 quotes, one paper).
#   3. Normalize every extract `quote:` with the same script, so each quote is
#      the bytes it will be grepped for. Section 12 is whole again.
#   4. Write `archive-sha256:` on every source note with `raw::` (roadmap R2,
#      labelling half; `_meta/schema.md` § Source Archive Hash). Hashing
#      before step 2 would record bytes that no longer exist.
#
# Each step is idempotent, so the script is: a second `--apply` changes nothing.
# A dry run normalizes archives into a scratch directory and hashes those, so
# the hashes it reports are the ones `--apply` would write.
#
# What it does not do
# -------------------
# Three rc.3 changes need judgement, so this script prints a checklist from
# lint's own findings instead of editing: backwards `supersedes::`, missing
# `defines::` back-links, and atom → atom `part-of::`. It also does not delete
# `skills/*/references/vault-schema.md` — that is a `git rm` the fork makes
# itself, because a path-scoped copy of the template never carries a deletion.
#
# `.archive/` is gitignored, so git cannot undo step 2. `--apply` copies every
# archive it rewrites to a scratch directory first and prints where.
#
# Exit codes: 0 done (or dry run complete), 1 a step could not finish — an
# archive is missing, a hash already present does not match, normalize failed —
# 2 usage error or the vault is not ready for this script.

set -uo pipefail

VAULT="$(cd "$(dirname "$0")/.." && pwd)"
N="$VAULT/_meta/normalize.sh"
L="$VAULT/_meta/lint.sh"

usage() {
    echo "migrate-rc2-rc3.sh: usage: [--apply]" >&2
    exit 2
}

APPLY=0
case "$#:${1:-}" in
    0:)        ;;
    1:--apply) APPLY=1 ;;
    *)         usage ;;
esac

# ── Preconditions ────────────────────────────────────────────────────────────
# The rc.2 normalize.sh has no NFC step. Run with it, steps 2 and 3 would change
# nothing and step 4 would record hashes rc.3's lint then calls mismatched.
[ -f "$VAULT/_meta/schema.md" ] || { echo "migrate: $VAULT is not a vault (no _meta/schema.md)" >&2; exit 2; }
grep -q 'Unicode::Normalize' "$N" 2>/dev/null \
    || { echo "migrate: $N is not rc.3's (no NFC step); take the template's rc.3 _meta/ first" >&2; exit 2; }
grep -q 'archive-sha256' "$L" 2>/dev/null \
    || { echo "migrate: $L is not rc.3's (no archive-sha256 check); take the template's rc.3 _meta/ first" >&2; exit 2; }
perl -MUnicode::Normalize -e 1 2>/dev/null \
    || { echo "migrate: needs perl with Unicode::Normalize (normalize.sh uses it for NFC)" >&2; exit 2; }
if command -v sha256sum >/dev/null 2>&1; then
    sha256_of() { sha256sum "$1" | cut -d' ' -f1; }
elif command -v shasum >/dev/null 2>&1; then
    sha256_of() { shasum -a 256 "$1" | cut -d' ' -f1; }
else
    echo "migrate: needs sha256sum or shasum" >&2; exit 2
fi

BOLD=$'\033[1m'; YEL=$'\033[1;33m'; RED=$'\033[0;31m'; DIM=$'\033[0;90m'; NC=$'\033[0m'
problems=0
problem() { printf '  %sFAIL%s  %s\n' "$RED" "$NC" "$1"; problems=$((problems + 1)); }
note()    { printf '  %s\n' "$1"; }
if [ "$APPLY" -eq 1 ]; then WOULD=""; else WOULD="would "; fi
# The past tense after --apply, "would <present>" in a dry run.
did() { if [ "$APPLY" -eq 1 ]; then echo "$2"; else echo "would $1"; fi; }

scratch="$(mktemp -d)"; trap 'rm -rf "$scratch"' EXIT

if [ "$APPLY" -eq 1 ]; then
    echo "${BOLD}Migrating $VAULT to rc.3${NC}"
else
    echo "${BOLD}Dry run on $VAULT — nothing is written; re-run with --apply${NC}"
fi

# Like lint's fm_value: a top-level frontmatter key's value, unquoted, with any
# trailing comment dropped. FM_FOUND says whether the key is there at all.
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

# ── 1. _meta/candidates/.gitkeep ─────────────────────────────────────────────
echo ""
echo "── 1. _meta/candidates/.gitkeep"
gitkeep="$VAULT/_meta/candidates/.gitkeep"
if [ -f "$gitkeep" ]; then
    note "${DIM}present${NC}"
else
    [ "$APPLY" -eq 1 ] && { mkdir -p "$VAULT/_meta/candidates" && : > "$gitkeep"; }
    note "${WOULD}create _meta/candidates/.gitkeep"
fi
# rc.2's .gitignore ignores the whole folder, which would ignore the .gitkeep too.
if git -C "$VAULT" rev-parse --git-dir >/dev/null 2>&1 \
   && git -C "$VAULT" check-ignore -q "_meta/candidates/.gitkeep" 2>/dev/null; then
    note "${YEL}.gitignore still ignores it${NC} — replace the '_meta/candidates/' line with the template's two:"
    note "    _meta/candidates/*"
    note "    !_meta/candidates/.gitkeep"
fi

# ── 2. Re-normalize .archive/ ────────────────────────────────────────────────
# NORMALIZED[path] is the file whose bytes step 4 hashes: the archive itself
# after --apply, its scratch copy in a dry run.
echo ""
echo "── 2. Re-normalize .archive/ to NFC"
declare -A NORMALIZED=()
backup=""
archives=0; changed=0
if [ ! -d "$VAULT/.archive" ]; then
    note "${DIM}no .archive/ — nothing to re-normalize (a fresh clone has none; run this where the archives live)${NC}"
else
    while IFS= read -r -d '' a; do
        rel=${a#"$VAULT"/}
        case "$a" in
            *.md|*.txt) ;;
            *) note "${DIM}skipped $rel (not .md or .txt; normalize.sh is for text)${NC}"; continue ;;
        esac
        archives=$((archives + 1))
        out="$scratch/archive-$archives"
        if ! bash "$N" < "$a" > "$out" 2> "$out.err"; then
            problem "$rel — normalize.sh failed: $(head -1 "$out.err")"
            continue
        fi
        if cmp -s "$a" "$out"; then
            NORMALIZED[$a]=$a
            continue
        fi
        changed=$((changed + 1))
        note "${WOULD}rewrite $rel"
        # normalize.sh warns when it drops a form feed: the archive still had page
        # breaks, so pdf-clean.sh never ran on it. Worth knowing; not this step's job.
        [ -s "$out.err" ] && sed 's/^/        /' "$out.err"
        if [ "$APPLY" -eq 1 ]; then
            if [ -z "$backup" ]; then
                backup="$(mktemp -d "${TMPDIR:-/tmp}/memex-rc3-archives.XXXXXX")"
            fi
            mkdir -p "$backup/$(dirname "$rel")"
            cp -p "$a" "$backup/$rel"
            cat "$out" > "$a"
            NORMALIZED[$a]=$a
        else
            NORMALIZED[$a]=$out
        fi
    done < <(find "$VAULT/.archive" -type f ! -name .gitkeep -print0 | sort -z)
    note "$changed of $archives archive(s) $(did change changed)"
    [ -n "$backup" ] && note "originals of the rewritten archives are in $backup"
fi

# ── 3. Normalize extract quotes ──────────────────────────────────────────────
# A quote is parsed exactly as lint section 12 parses it: strip "- quote:", then
# one opening and one closing double quote. Only the text between is replaced,
# so indentation and quoting are kept byte-for-byte.
echo ""
echo "── 3. Normalize extract quote: lines"
quotes=0; qchanged=0; qfiles=0
for f in "$VAULT"/extracts/*.md; do
    [ -f "$f" ] || continue
    rel=${f#"$VAULT"/}
    mapfile -t lines < "$f"
    dirty=0
    for i in "${!lines[@]}"; do
        line=${lines[i]}
        [[ $line =~ ^[[:space:]]*-[[:space:]]*quote:[[:space:]]* ]] || continue
        head=${BASH_REMATCH[0]}
        quote=${line:${#head}}
        if [[ $quote == \"* ]]; then head+='"'; quote=${quote:1}; fi
        tail=""
        if [[ $quote =~ \"[[:space:]]*$ ]]; then
            tail=${BASH_REMATCH[0]}
            quote=${quote:0:${#quote}-${#tail}}
        fi
        [ -n "$quote" ] || continue
        quotes=$((quotes + 1))
        if ! new=$(printf '%s\n' "$quote" | bash "$N" 2>/dev/null); then
            problem "$rel:$((i + 1)) — normalize.sh failed on this quote"
            continue
        fi
        [ "$new" = "$quote" ] && continue
        qchanged=$((qchanged + 1)); dirty=1
        lines[i]="$head$new$tail"
        note "${WOULD}rewrite $rel:$((i + 1))"
    done
    [ "$dirty" -eq 1 ] || continue
    qfiles=$((qfiles + 1))
    if [ "$APPLY" -eq 1 ]; then
        # Keep a missing final newline missing.
        if [ -n "$(tail -c1 "$f")" ]; then
            printf '%s\n' "${lines[@]}" | head -c -1 > "$scratch/extract"
        else
            printf '%s\n' "${lines[@]}" > "$scratch/extract"
        fi
        cat "$scratch/extract" > "$f"
    fi
done
note "$qchanged of $quotes quote(s) in $qfiles extract(s) $(did change changed)"

# ── 4. Backfill archive-sha256: ──────────────────────────────────────────────
# Present exactly when raw:: is. Written after the source's other bibliographic
# fields — before generated:, where memex-seed puts it — or, failing that, last.
# A hash that is already there and disagrees is not overwritten: it was recorded
# by rc.3 tooling, so the archive changed since, and that is the user's to judge.
echo ""
echo "── 4. Backfill archive-sha256:"
hashed=0; present=0
while IFS= read -r -d '' f; do
    rel=${f#"$VAULT"/}
    raw_path=$(grep -m1 "^raw::" "$f" 2>/dev/null | sed 's/^raw::[[:space:]]*//; s/[[:space:]]*$//' || true)
    fm_value "$f" archive-sha256; have=$REPLY; has_key=$FM_FOUND
    if [ -z "$raw_path" ]; then
        [ "$has_key" -eq 1 ] && problem "$rel — archive-sha256: with no raw::; remove it or add the raw:: it belongs to"
        continue
    fi
    [[ $raw_path == /* ]] || raw_path="$VAULT/$raw_path"
    target=${NORMALIZED[$raw_path]:-}
    if [ -z "$target" ]; then
        if [ -f "$raw_path" ]; then
            target=$raw_path   # not .md/.txt, or outside .archive/: hash as-is
        else
            problem "$rel — raw:: ${raw_path#"$VAULT"/} is missing; restore the archive and re-run"
            continue
        fi
    fi
    want=$(sha256_of "$target")
    if [ -n "$have" ]; then
        if [ "$have" = "$want" ]; then
            present=$((present + 1))
        else
            problem "$rel — archive-sha256: $have does not match ${raw_path#"$VAULT"/} ($want); left as is"
        fi
        continue
    fi
    hashed=$((hashed + 1))
    note "${WOULD}write archive-sha256: on $rel"
    [ "$APPLY" -eq 1 ] || continue
    awk -v h="$want" -v had="$has_key" '
        NR == 1 && /^---[[:space:]]*$/ { fm = 1; print; next }
        fm && !done && had == 1 && index($0, "archive-sha256:") == 1 {
            print "archive-sha256: " h; done = 1; next }
        fm && !done && had == 0 && (/^generated:/ || /^---[[:space:]]*$/) {
            print "archive-sha256: " h; done = 1 }
        fm && /^---[[:space:]]*$/ { fm = 0 }
        { print }' "$f" > "$scratch/source"
    cat "$scratch/source" > "$f"
done < <(find "$VAULT/sources" -name "*.md" ! -name .gitkeep -print0 | sort -z)
note "$hashed hash(es) $(did "be written" written), $present already present and matching"

# ── Checklist ────────────────────────────────────────────────────────────────
# The judgement steps, from lint's own findings, so the list is exactly what
# lint will keep warning about until each is done. In a dry run lint reads the
# vault before steps 1-4; none of these three depends on them.
echo ""
echo "${BOLD}── Checklist: judgement steps (not done by this script)${NC}"
lint_out=$(bash "$L" "$VAULT" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true)
section() {  # title, grep -E pattern, what to do
    local hits
    hits=$(printf '%s\n' "$lint_out" | /usr/bin/grep -E "$2" | sed 's/^[[:space:]]*WARN[[:space:]]*//' || true)
    if [ -z "$hits" ]; then
        note "[x] $1 — none"
    else
        note "[ ] $1 — $(printf '%s\n' "$hits" | wc -l | tr -d ' ') ($3)"
        printf '%s\n' "$hits" | sed 's/^/        /'
    fi
}
digests=$(find "$VAULT/skills" -path '*/references/vault-schema.md' 2>/dev/null | sed "s|^$VAULT/||" | sort)
if [ -z "$digests" ]; then
    note "[x] Delete the per-skill schema digests — none left"
else
    note "[ ] Delete the per-skill schema digests — $(printf '%s\n' "$digests" | wc -l | tr -d ' ') (git rm -r skills/*/references/vault-schema.md)"
fi
section "Flip backwards supersedes::" \
    'supersedes:: \[\[.*(which is newer|supersedes this atom)' \
    "the successor holds supersedes::; see _meta/schema.md § Retirement"
section "Add defines:: back-links" \
    'no note carries defines::' \
    "add defines:: [[term]] to the source or atom that uses it"
section "Retype atom → atom part-of::" \
    'part-of:: is topic-only' \
    "part-of:: is topic-only; use extends:: or uses::"

echo ""
if [ "$problems" -gt 0 ]; then
    echo "${RED}$problems step problem(s) above.${NC} Fix them and re-run; the steps already done are not redone."
    exit 1
fi
if [ "$APPLY" -eq 1 ]; then
    echo "Done. Run bash _meta/lint.sh and bash _meta/test-lint.sh, work the checklist, then re-run memex-init."
else
    echo "Dry run complete. Re-run with --apply to make these changes."
fi
