#!/usr/bin/env bash
# test-tools.sh — regression tests for the archive scripts.
#
# `normalize.sh`, `pdf-clean.sh` and `validate-archive.sh` decide the bytes of
# every archive, and lint section 12 grounds quotes against those bytes. Their
# contracts — exit codes, idempotence, what NFC folds — were only ever checked by
# hand, and trial 2 found three of them broken (T2-3, T2-5, T2-7). Each case below
# pins one. Inputs are built inline, so this means the same in CI as on a laptop.
#
# Usage:
#   bash _meta/test-tools.sh
# Exit 0 all pass, 1 on any failure.

set -uo pipefail

VAULT="$(cd "$(dirname "$0")/.." && pwd)"
N="$VAULT/_meta/normalize.sh"
P="$VAULT/_meta/pdf-clean.sh"
V="$VAULT/_meta/validate-archive.sh"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; NC=$'\033[0m'
pass=0; fail=0
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

check() {  # name, expected, actual
    if [ "$2" = "$3" ]; then
        echo "${GREEN}PASS${NC}  $1"; pass=$((pass + 1))
    else
        echo "${RED}FAIL${NC}  $1"
        echo "        expected: $2"
        echo "        got:      $3"
        fail=$((fail + 1))
    fi
}
status() { "$@" >/dev/null 2>&1; echo $?; }

# ── normalize.sh ─────────────────────────────────────────────────────────────
# A sample touching every step: control byte, ligature, smart quotes, dash,
# nbsp, a hard wrap, a hyphenated break, a list, a fence, blank-line runs.
printf '\xef\xbb\xbfThe \xef\xac\x81rst \xe2\x80\x9cquote\xe2\x80\x9d \xe2\x80\x94 p\x02 10\r\n' >  "$tmp/in.txt"
printf 'wraps here and hyphen-\nated word\xc2\xa0end.\n\n\n\n- item one\n- item two\n\n```\ncode   kept\n```\n' >> "$tmp/in.txt"
printf 'Ohm \xe2\x84\xa6 and e\xcc\x81\n' >> "$tmp/in.txt"

bash "$N" < "$tmp/in.txt" > "$tmp/once.txt" 2>/dev/null
bash "$N" < "$tmp/once.txt" > "$tmp/twice.txt" 2>/dev/null
check "normalize: idempotent" "same" "$(cmp -s "$tmp/once.txt" "$tmp/twice.txt" && echo same || echo differs)"
check "normalize: file argument equals stdin" "same" \
    "$(bash "$N" "$tmp/in.txt" 2>/dev/null | cmp -s - "$tmp/once.txt" && echo same || echo differs)"
cp "$tmp/in.txt" "$tmp/inplace.txt"; bash "$N" --in-place "$tmp/inplace.txt" 2>/dev/null
check "normalize: --in-place equals stdin" "same" \
    "$(cmp -s "$tmp/inplace.txt" "$tmp/once.txt" && echo same || echo differs)"

# T2-7: NFC. U+2126 OHM SIGN -> U+03A9; e + U+0301 -> U+00E9.
check "normalize: NFC folds U+2126 to U+03A9" "ce a9" \
    "$(printf '\xe2\x84\xa6' | bash "$N" 2>/dev/null | od -An -tx1 -N2 | xargs)"
check "normalize: NFC composes a combining sequence" "c3 a9" \
    "$(printf 'e\xcc\x81' | bash "$N" 2>/dev/null | od -An -tx1 -N2 | xargs)"
check "normalize: invalid UTF-8 passes through byte-for-byte" "78 ff fe 79 0a" \
    "$(printf 'x\xff\xfey\n' | bash "$N" 2>/dev/null | od -An -tx1 | xargs)"
check "normalize: superscript kept (NFC, not NFKC)" "c2 b2" \
    "$(printf '\xc2\xb2' | bash "$N" 2>/dev/null | od -An -tx1 -N2 | xargs)"

# T2-3: an unknown flag is a usage error, not a filename.
check "normalize: unknown flag exits 2"   2 "$(status bash "$N" --help < /dev/null)"
check "normalize: missing file exits 2"   2 "$(status bash "$N" "$tmp/nope")"
check "normalize: two files exits 2"      2 "$(status bash "$N" "$tmp/in.txt" "$tmp/in.txt")"
check "normalize: bare --in-place exits 2" 2 "$(status bash "$N" --in-place)"

# T2-5b: dropping a form feed warns on stderr.
check "normalize: warns when it drops a form feed" "warned" \
    "$(printf 'A\fB\n' | bash "$N" 2>&1 >/dev/null | grep -q 'form feed' && echo warned || echo silent)"
check "normalize: no warning without a form feed" "" \
    "$(printf 'A B\n' | bash "$N" 2>&1 >/dev/null)"

# ── pdf-clean.sh ─────────────────────────────────────────────────────────────
: > "$tmp/pages.txt"
pagename=([1]=one [2]=two [3]=three [4]=four)   # words: digits would mask equal
for p in 1 2 3 4; do
    [ "$p" -gt 1 ] && printf '\f' >> "$tmp/pages.txt"
    # Six body lines, each unique after digit masking, so the margins (first 2,
    # last 3 non-blank lines) hold furniture and body, and only furniture recurs.
    printf 'Journal of Tests\n' >> "$tmp/pages.txt"
    for w in alpha bravo charlie delta echo foxtrot; do
        printf 'Body %s line on page %s.\n' "$w" "${pagename[$p]}" >> "$tmp/pages.txt"
    done
    printf '%s\n' "$p" >> "$tmp/pages.txt"
done
check "pdf-clean: keeps every body line" "24" \
    "$(bash "$P" "$tmp/pages.txt" 2>/dev/null | grep -c '^Body ')"
check "pdf-clean: output has no furniture left" "0" \
    "$(bash "$P" "$tmp/pages.txt" 2>/dev/null | grep -cE '^(Journal of Tests|[0-9]+)$')"
check "pdf-clean: --report on paged input exits 0" 0 "$(status bash "$P" --report "$tmp/pages.txt")"

# T2-5a: no form feeds = no signal. --report must not certify it clean.
bash "$N" < "$tmp/pages.txt" > "$tmp/normalized.txt" 2>/dev/null
check "pdf-clean: --report on normalized input exits 3" 3 "$(status bash "$P" --report "$tmp/normalized.txt")"
check "pdf-clean: filter mode passes one page through" "same" \
    "$(bash "$P" "$tmp/normalized.txt" 2>/dev/null | cmp -s - "$tmp/normalized.txt" && echo same || echo differs)"
check "pdf-clean: filter mode on one page exits 0" 0 "$(status bash "$P" "$tmp/normalized.txt")"
check "pdf-clean: unknown flag exits 2" 2 "$(status bash "$P" --bogus < /dev/null)"
check "pdf-clean: missing file exits 2" 2 "$(status bash "$P" "$tmp/nope")"

# ── validate-archive.sh ──────────────────────────────────────────────────────
# A synthetic long-path pass: 25 paragraph lines of 1,100 bytes.
line="$(printf 'word %.0s' $(seq 1 220))"
for _ in $(seq 1 25); do printf '%s\n\n' "$line"; done > "$tmp/paper.md"
check "validate-archive: long body passes" 0 "$(status bash "$V" --quiet "$tmp/paper.md")"
check "validate-archive: no furniture reported clean" "ok" \
    "$(bash "$V" "$tmp/paper.md" | awk '/furniture:/ {print $1}')"
printf 'Page 2 of 4\n\n%s\n' "$line" >> "$tmp/paper.md"
check "validate-archive: 'Page N of M' is warned" "warn" \
    "$(bash "$V" "$tmp/paper.md" | awk '/furniture:/ {print $1}')"
check "validate-archive: furniture never decides the verdict" 0 "$(status bash "$V" --quiet "$tmp/paper.md")"
check "validate-archive: a directory exits 2" 2 "$(status bash "$V" "$tmp")"

echo ""
if [ "$fail" -gt 0 ]; then
    echo "${RED}$fail case(s) failed${NC}, $pass passed."
    exit 1
fi
echo "${GREEN}All $pass case(s) passed.${NC}"
