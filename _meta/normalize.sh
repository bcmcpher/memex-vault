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
#                      Deterministic for a given version of this script: change a
#                      step and the same input yields different bytes, so every
#                      `archive-sha256:` (`_meta/schema.md` § Source Archive Hash)
#                      computed under the old version stops matching. A change here
#                      ships with a migration that re-normalizes and re-hashes.
#   * Idempotent     — normalize(normalize(x)) == normalize(x). Safe to re-run on
#                      an archive of unknown provenance, which is how a legacy
#                      archive gets brought up to standard.
#   * Lossless enough — folds presentation, never content. No text is dropped
#                      except zero-width and soft-hyphen characters — and the
#                      hyphen of a compound split at a line break (step 4).
#
# Requires perl with Unicode::Normalize (a core module since perl 5.8). Missing
# either is a hard stop, exit 2: an archive normalized without NFC grounds
# differently from one normalized with it, and there is no fallback that is not
# exactly that.
#
# What it does
# ------------
#   0. Deletes C0 control bytes except tab and newline. These arrive from PDF
#      extraction, where pdftotext emits a raw 0x02 or 0x03 in place of a
#      superscript minus or a relational operator: "p , 10\x0210" is really
#      p < 10^-10. They are invisible in an editor, invisible in a terminal, and
#      invisible in a model's view of the file, so a quote that looks
#      byte-perfect fails `grep -F` for no visible reason. Found the hard way --
#      three quotes in the Hagmann 2008 extract failed on exactly this.
#      Form feed is one of them, and it is how pdftotext marks a page break —
#      the only signal `_meta/pdf-clean.sh` has. So this step warns on stderr
#      when it drops one: the input still had pages, pdf-clean has not run, and
#      after this nothing can find the page furniture (trial 2, T2-5).
#   0b. Unicode NFC, on every line that is valid UTF-8 (others pass through
#      byte-for-byte). Canonically equivalent characters become one code point,
#      so U+2126 OHM SIGN is U+03A9 GREEK CAPITAL LETTER OMEGA — the same
#      character by Unicode's own definition, and pixel-identical. Without it a
#      quote typed with the ordinary omega fails `grep -F` against an archive
#      holding the ohm sign, which trial 2 hit on 9 quotes in one paper (T2-7).
#      NFC and not NFKC: NFKC would also fold superscripts and fractions, which
#      are content.
#   1. CRLF → LF; strips BOM, zero-width joiners/spaces, and soft hyphens.
#   2. Folds ligatures (ﬁ ﬂ ﬀ ﬃ ﬄ ﬅ ﬆ), smart quotes, primes, ellipsis,
#      en/em/figure dashes and the Unicode minus, and every exotic space, to ASCII.
#   3. Tabs → space; collapses space runs; strips trailing space; collapses
#      blank-line runs to one.
#   4. Rejoins words split across a line break by hyphenation. **This has a
#      cost.** At a line break a hyphenation hyphen and a compound's own hyphen
#      are indistinguishable, and the hyphen is always dropped: a PDF that broke
#      "real-valued" after the hyphen archives "realvalued", and that is then
#      the only form a quote can ground on (trial 2 found "datadriven",
#      "illposed", "DesikanKilliany" among others, T2-8). Keeping the hyphen
#      instead would break every genuinely hyphenated word, which is the common
#      case; a dictionary check would add a dependency. Prefer a quote span that
#      does not cross such a join.
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

usage() {
    echo "normalize.sh: usage: [--in-place] <file>   or   normalize.sh < input" >&2
    exit 2
}

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
    [ "$#" -eq 2 ] || usage
    set -- "$in_place"
fi
# An unknown flag used to fall through as a filename, fail its redirect, and
# exit 0 — so a caller checking the status could not tell a typo from a
# normalized file (T2-3). Exit 2 is a usage error, as in validate-archive.sh.
case "${1:-}" in
    -*) [ -n "$in_place" ] || { echo "normalize.sh: unknown flag: $1" >&2; usage; } ;;
esac
[ "$#" -le 1 ] || usage
if [ "$#" -eq 1 ] && [ -z "$in_place" ] && [ ! -f "$1" ]; then
    echo "normalize.sh: no such file: $1" >&2
    exit 2
fi

if ! perl -MUnicode::Normalize -e 1 2>/dev/null; then
    echo "normalize.sh: needs perl with Unicode::Normalize (for NFC); not found" >&2
    exit 2
fi

export LC_ALL=C

normalize() {
    # ── 0. C0 controls ───────────────────────────────────────────────────────
    # Everything below 0x20 except tab and newline, plus DEL. Nothing in a text
    # archive should carry these, and when they appear they are undetectable by
    # eye -- which makes them the worst possible grounding failure.
    # Byte-oriented perl, so invalid UTF-8 survives as it did under tr. Step 0b
    # rides along: NFC on each line that decodes, byte-identical otherwise.
    perl -MUnicode::Normalize -ne '
        $ff += tr/\x0c//;
        tr/\x01-\x08\x0b\x0c\x0e-\x1f\x7f//d;
        if (utf8::decode($_)) { $_ = NFC($_); utf8::encode($_); }
        print;
        END {
            printf STDERR "normalize.sh: dropped %d form feed(s): the input still had page"
                . " breaks, so _meta/pdf-clean.sh has not run and can no longer find page"
                . " furniture after this\n", $ff if $ff;
        }' |
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
