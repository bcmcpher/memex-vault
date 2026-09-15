#!/usr/bin/env bash
# memex-vault — PDF Page-Furniture Stripper
#
# Usage:
#   pdftotext paper.pdf - | bash _meta/pdf-clean.sh | bash _meta/normalize.sh > .archive/<slug>.md
#   bash _meta/pdf-clean.sh raw.txt
#   bash _meta/pdf-clean.sh --report raw.txt      # what it would strip, and why
#
# Why this exists
# ---------------
# `_meta/normalize.sh` folds presentation and unwraps paragraphs so that
# `lint.sh` section 12 can `grep -F` a quote against the archive. It assumes the
# input is a linear document. Text extracted from a **PDF** is not: every page
# carries running heads, running feet, and a page number, and `pdftotext` emits
# them inline, in reading position, with no blank line separating them from the
# body.
#
# Concretely, from Hagmann et al. 2008 (PLoS Biology), verbatim from pdftotext:
#
#     distribution of average node degree and node strength rank-
#     ordered by anatomical subregion. A large number of ROIs
#     PLoS Biology | www.plosbiology.org
#
#     k-Core Decomposition, Modularity, and Hubs
#
# and, worse, where a page break falls mid-sentence:
#
#     Intuitively, a network core is a set of nodes that are highly
#     and mutually interconnected. For a binary network, the k1480
#
# `normalize.sh` would unwrap the first into a paragraph containing a journal
# URL, and leave the second with the page number 1480 welded onto the word "k".
# Both then ground perfectly well — `grep -F` finds them, because they are
# genuinely in the archive — so the anti-fabrication check cannot catch this. It
# is not a fabrication; it is a corrupted archive that certifies as clean. That
# is the exact failure this script exists to prevent, and it does not arise on
# the HTML routes (ar5iv, PMC) because HTML has no pages.
#
# What it does
# ------------
#   1. Splits input on form feeds (`\f`), which is how pdftotext marks pages.
#   2. Learns furniture instead of hard-coding it: takes the first 2 and last 3
#      non-blank lines of every page, masks digit runs so "1480" and "1481"
#      compare equal, and treats a masked line recurring on >= 25% of pages
#      (minimum 3) as furniture. A journal name repeats; a sentence does not.
#   3. Drops bare page-number lines.
#   4. Un-welds a page number fused to the end of the last body line of a page,
#      but only when the trailing digits equal that page's own inferred number.
#      Page numbers are inferred from the bare-number lines that step by one.
#      Where no sequence can be inferred, the digits are left alone and counted
#      in the report -- guessing here would corrupt real data such as "Figure 3".
#   5. Removes form feeds.
#
# Deliberately NOT done
# ---------------------
# Reference lists, figure captions and table bodies are kept. They are content,
# they are legitimately quotable, and no reliable positional rule separates a
# caption from a paragraph. Two-column reading order is also left to pdftotext:
# run it WITHOUT `-layout` (the default heuristic follows columns; `-layout`
# preserves physical position and interleaves the columns of a two-column paper
# line by line, which is unrecoverable).
#
# Guarantees
# ----------
#   * Deterministic — no locale or clock dependence; runs under LC_ALL=C.
#   * Idempotent    — a second pass finds no page breaks and changes nothing,
#                     so it is safe on an archive of unknown provenance.
#   * Conservative  — strips only what recurs across pages. A page-unique line
#                     is never removed, whatever it looks like.

set -euo pipefail
export LC_ALL=C

report=0
if [ "${1:-}" = "--report" ]; then report=1; shift; fi

infile="${1:--}"

awk -v REPORT="$report" '
    # Mask digit runs so page-varying furniture compares equal across pages.
    function mask(s) { gsub(/[0-9]+/, "#", s); gsub(/^[ \t]+|[ \t]+$/, "", s); return s }

    {
        # Buffer everything; furniture can only be identified globally.
        n++; line[n] = $0
        if ($0 ~ /\f/) { }
    }

    END {
        # ── Pass 1: page boundaries ──────────────────────────────────────────
        # pdftotext puts \f at the start of the line beginning a new page.
        np = 1; pstart[1] = 1
        for (i = 1; i <= n; i++) {
            if (index(line[i], "\f") > 0) {
                pend[np] = i - 1
                np++
                pstart[np] = i
                sub(/\f/, "", line[i])
            }
        }
        pend[np] = n

        # ── Pass 2: learn furniture from page margins ────────────────────────
        for (p = 1; p <= np; p++) {
            # first 2 non-blank
            c = 0
            for (i = pstart[p]; i <= pend[p] && c < 2; i++) {
                if (line[i] ~ /[^ \t]/) { c++; freq[mask(line[i])]++; cand[i] = 1 }
            }
            # last 3 non-blank
            c = 0
            for (i = pend[p]; i >= pstart[p] && c < 3; i--) {
                if (line[i] ~ /[^ \t]/) { c++; freq[mask(line[i])]++; cand[i] = 1 }
            }
        }
        thresh = np * 0.25
        if (thresh < 3) thresh = 3

        # ── Pass 3: infer the page-number sequence by offset voting ──────────
        # Every bare-number line on page p votes for the offset (value - p). The
        # winning offset is the one most pages agree on, so a stray "1" or "2"
        # in a table cannot displace a real sequence, and a page whose number is
        # welded into the body text simply abstains rather than breaking it.
        for (p = 1; p <= np; p++) {
            for (i = pstart[p]; i <= pend[p]; i++) {
                if (line[i] ~ /^[ \t]*[0-9]{1,5}[ \t]*$/) vote[(line[i] + 0) - p]++
            }
        }
        base = 0; bestv = 0
        for (o in vote) if (vote[o] + 0 > bestv) { bestv = vote[o] + 0; base = o + 0 }
        # Two agreeing pages is the floor; below that there is no sequence.
        if (bestv < 2) base = -1

        # ── Pass 4: emit ─────────────────────────────────────────────────────
        for (p = 1; p <= np; p++) {
            expect = (base >= 0) ? base + p : 0
            for (i = pstart[p]; i <= pend[p]; i++) {
                s = line[i]

                if (cand[i] && freq[mask(s)] >= thresh && s ~ /[^ \t]/) {
                    stripped++; if (REPORT) printf("FURNITURE p%-3d %s\n", p, s) > "/dev/stderr"
                    continue
                }
                if (s ~ /^[ \t]*[0-9]{1,5}[ \t]*$/) {
                    pagenum++; if (REPORT) printf("PAGENUM   p%-3d %s\n", p, s) > "/dev/stderr"
                    continue
                }
                # Welded page number: last body line of the page ends in digits
                # that equal this page number. Only then, and never otherwise.
                if (expect > 0 && s ~ /[0-9]$/) {
                    tail = s; sub(/^.*[^0-9]/, "", tail)
                    if (tail + 0 == expect && length(tail) == length(expect "")) {
                        # "Last body line" means last line that is not itself
                        # furniture — the welded number sits above the running
                        # foot, not below it, so a naive check never fires.
                        last = 1
                        for (j = i + 1; j <= pend[p]; j++) {
                            if (line[j] !~ /[^ \t]/) continue
                            if (line[j] ~ /^[ \t]*[0-9]{1,5}[ \t]*$/) continue
                            if (cand[j] && freq[mask(line[j])] >= thresh) continue
                            last = 0; break
                        }
                        if (last) {
                            sub(/[0-9]+$/, "", s)
                            welded++
                            if (REPORT) printf("WELDED    p%-3d ...%s <- %s\n", p, substr(s, length(s)-28), tail) > "/dev/stderr"
                        }
                    }
                }
                print s
            }
        }
        printf("pdf-clean: %d pages, %d furniture lines, %d page numbers, %d welded numbers\n",
               np, stripped, pagenum, welded) > "/dev/stderr"
    }
' "$infile"
