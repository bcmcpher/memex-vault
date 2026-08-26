#!/usr/bin/env bash
# memex-vault — Archive Text Normalizer
#
# Usage:
#   bash _meta/normalize.sh < raw.txt > .archive/2026-04-27-slug.md
#   bash _meta/normalize.sh raw.txt > .archive/2026-04-27-slug.md
#   bash _meta/normalize.sh --in-place .archive/2026-04-27-slug.md
#
# Why this exists
# ---------------
# `_meta/lint.sh` section 12 proves an extract's claims are grounded by running
# `grep -F` for each verbatim quote against the archived source text. That check
# is worthless against raw pdftotext or scraped-HTML output: paragraphs arrive
# hard-wrapped, words are split across line breaks with a hyphen, and ligatures,
# smart quotes, en/em dashes, soft hyphens and non-breaking spaces all differ
# from what a model transcribes. Every quote would fail, so the anti-fabrication
# guarantee would be noise.
#
# The fix is to normalize **once, at archive time**, and to extract quotes from
# the normalized artifact. Exact match then holds by construction, and a
# mismatch really is fabrication or post-hoc editing.
#
# Every skill that writes `.archive/` pipes through this script — `memex-ingest`
# and `memex-deep-extract` both do. Normalization must not be a step one writer
# performs and another skips, or grounding silently depends on which skill
# happened to save the file.
#
# Guarantees
# ----------
#   * Deterministic  — no locale, date, or randomness dependence (runs in LC_ALL=C).
#   * Idempotent     — normalize(normalize(x)) == normalize(x). Safe to re-run on
#                      an archive of unknown provenance, which is how a legacy
#                      archive gets brought up to standard.
#   * Lossless enough — folds presentation, never content. No text is dropped
#                      except zero-width and soft-hyphen characters.
#
# What it does
# ------------
#   1. CRLF → LF; strips BOM, zero-width joiners/spaces, and soft hyphens.
#   2. Folds ligatures (ﬁ ﬂ ﬀ ﬃ ﬄ ﬅ ﬆ), smart quotes, primes, ellipsis,
#      en/em/figure dashes and the Unicode minus, and every exotic space, to ASCII.
#   3. Tabs → space; collapses space runs; strips trailing space; collapses
#      blank-line runs to one.
#   4. Rejoins words split across a line break by hyphenation.
#   5. Unwraps each paragraph onto a single line. Headings, list items,
#      blockquotes, table rows, and fenced code blocks are never joined — they
#      carry structure, and joining them would destroy it.
#
# Steps 1–3 apply to every line, fenced code included: space runs collapse there
# too. That is deliberate. An archive is evidence to be grepped, not source to be
# compiled, and exempting fences would make whether a quote grounds depend on
# whether the scraper happened to emit a fence.
#
# Two rules follow for anyone writing quotes against the output, both stated in
# `_meta/schema.md` § Extract Claims:
#   * A quote is single-line. It cannot span a paragraph boundary.
#   * No ellipsis inside a quote. Emit two quote lines instead.

set -euo pipefail

in_place=""
if [ "${1:-}" = "--in-place" ]; then
    in_place="${2:-}"
    if [ -z "$in_place" ]; then
        echo "normalize.sh: --in-place requires a file argument" >&2
        exit 2
    fi
    if [ ! -f "$in_place" ]; then
        echo "normalize.sh: no such file: $in_place" >&2
        exit 2
    fi
    set -- "$in_place"
fi

export LC_ALL=C

normalize() {
    # ── 1–2. Character folding ───────────────────────────────────────────────
    # Byte-literal substitution, so the C locale is correct here as well as fast.
    sed -e 's/\r$//' \
        -e 's/\xef\xbb\xbf//g' \
        -e 's/\xe2\x80\x8b//g' -e 's/\xe2\x80\x8c//g' -e 's/\xe2\x80\x8d//g' \
        -e 's/\xc2\xad//g' \
        -e 's/\xef\xac\x83/ffi/g' -e 's/\xef\xac\x84/ffl/g' \
        -e 's/\xef\xac\x80/ff/g'  -e 's/\xef\xac\x81/fi/g' -e 's/\xef\xac\x82/fl/g' \
        -e 's/\xef\xac\x85/ft/g'  -e 's/\xef\xac\x86/st/g' \
        -e "s/\xe2\x80\x98/'/g" -e "s/\xe2\x80\x99/'/g" \
        -e "s/\xe2\x80\x9a/'/g" -e "s/\xe2\x80\x9b/'/g" \
        -e "s/\xe2\x80\xb2/'/g" \
        -e 's/\xe2\x80\x9c/"/g' -e 's/\xe2\x80\x9d/"/g' \
        -e 's/\xe2\x80\x9e/"/g' -e 's/\xe2\x80\x9f/"/g' \
        -e 's/\xe2\x80\xb3/"/g' \
        -e 's/\xe2\x80\xa6/.../g' \
        -e 's/\xe2\x80\x93/-/g' -e 's/\xe2\x80\x94/-/g' \
        -e 's/\xe2\x80\x92/-/g' -e 's/\xe2\x80\x95/-/g' \
        -e 's/\xe2\x88\x92/-/g' -e 's/\xe2\x80\x90/-/g' -e 's/\xe2\x80\x91/-/g' \
        -e 's/\xe2\x80\xa2/- /g' \
        -e 's/\xc2\xa0/ /g' \
        -e 's/\xe2\x80\x82/ /g' -e 's/\xe2\x80\x83/ /g' -e 's/\xe2\x80\x89/ /g' \
        -e 's/\xe2\x80\x87/ /g' -e 's/\xe2\x80\xaf/ /g' -e 's/\xe2\x81\xa0//g' \
        -e 's/\t/ /g' \
        -e 's/  */ /g' \
        -e 's/ *$//' |
    # ── 3–5. Hyphenation rejoin and paragraph unwrap ─────────────────────────
    awk '
        # Leading indentation is allowed: a nested list item is still a list
        # item, and joining it into the paragraph above would destroy the nesting.
        function is_structural(l) {
            return (l ~ /^[[:space:]]*#{1,6} / ||
                    l ~ /^[[:space:]]*>/ ||
                    l ~ /^[[:space:]]*[-*+] / ||
                    l ~ /^[[:space:]]*[0-9]+[.)] / ||
                    l ~ /^[[:space:]]*\|/ ||
                    l ~ /^[[:space:]]*\[\^/ ||
                    l ~ /^[[:space:]]*(-{3,}|={3,}|_{3,})[[:space:]]*$/)
        }
        function flush() {
            if (buf != "") { print buf; buf = "" }
        }
        BEGIN { buf = ""; fence = 0; pending_blank = 0 }
        {
            line = $0

            # Fenced code: verbatim, never joined. The fence markers themselves
            # end whatever paragraph preceded them.
            if (line ~ /^(```|~~~)/) {
                flush()
                if (pending_blank) { print ""; pending_blank = 0 }
                print line
                fence = !fence
                next
            }
            if (fence) {
                if (pending_blank) { print ""; pending_blank = 0 }
                print line
                next
            }

            if (line ~ /^[[:space:]]*$/) {
                flush()
                # Collapse runs of blank lines to one, and never emit a leading one.
                if (seen) pending_blank = 1
                next
            }

            seen = 1
            if (pending_blank) { print ""; pending_blank = 0 }

            if (is_structural(line)) { flush(); buf = line; next }
            if (buf == "")           { buf = line;          next }

            # A continuation line contributes its words, never its indentation.
            # Leaving it in would emit a double space and break idempotence.
            sub(/^[[:space:]]+/, "", line)

            # Hyphenation rejoin: a line ending in a letter-hyphen followed by a
            # line opening lowercase is a word split across the break. Anything
            # else keeps its hyphen and gets an ordinary space.
            if (buf ~ /[[:alpha:]]-$/ && line ~ /^[[:lower:]]/) {
                sub(/-$/, "", buf)
                buf = buf line
            } else {
                buf = buf " " line
            }
        }
        END { flush() }
    '
}

if [ -n "$in_place" ]; then
    tmp="$(mktemp "${in_place}.norm.XXXXXX")"
    normalize < "$in_place" > "$tmp"
    mv "$tmp" "$in_place"
elif [ "$#" -ge 1 ]; then
    normalize < "$1"
else
    normalize
fi
