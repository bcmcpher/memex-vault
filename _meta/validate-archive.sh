#!/usr/bin/env bash
# memex-vault — Archive Plausibility Check
#
# Usage:
#   bash _meta/validate-archive.sh .archive/<slug>.md
#   bash _meta/validate-archive.sh --quiet f.md && echo ok      # exit status only
#
# Exit 0 = looks like a paper. Exit 1 = does not. Exit 2 = usage error.
#
# Why this exists
# ---------------
# `lint.sh` section 12 proves a quote appears in the archive. It cannot prove the
# archive is the *paper*. Those come apart whenever a retrieval route hands back
# something adjacent to the document:
#
#   * `zotero-cli get fulltext` on the FiberNeAT item returns ~22 KB and reports
#     success. It is a snapshot of the IEEE Xplore landing page — an abstract,
#     a reference list, and a footer of IEEE copyright text.
#   * The same happens for any Elsevier or IEEE item saved by a browser
#     connector without a PDF, which in a real library is common, not exotic.
#
# Archive one of those and every downstream check still passes. Quotes ground,
# because the text really is in the file. What actually happened is that claims
# got extracted from an abstract and a cookie notice, and nothing in the vault
# can tell. The grounding guarantee is intact and worthless, which is the worst
# available state — it looks checked and is not.
#
# So this is a *plausibility* check, run once at archive time, before the file
# is written. It is deliberately weak: it is trying to catch a landing page, not
# to grade a paper. Anything it passes still needs a human to read it.
#
# What it checks
# --------------
# Run it on the **normalized** archive, the file that will actually be written.
# Normalization unwraps each paragraph onto one line, which is what makes the
# central measurement possible: a body paragraph becomes a very long line, while
# navigation, menus and figure labels stay short. So "how much of this file is
# prose" is answerable with `awk`.
#
#   1. Prose volume — total bytes on lines of >= 200 characters. Not the *ratio*:
#      that was tried and it does not separate the cases, because a landing
#      page's reference list unwraps into long lines too and lifts it to 76%,
#      indistinguishable from a real paper's 84%. The absolute volume separates
#      cleanly, because a landing page has an abstract where a paper has a body.
#   2. Paragraph count — lines of >= 200 characters. An independent axis on the
#      same insight, and the one that fails most loudly on an abstract page.
#   3. Section skeleton — methods, results, discussion, references. Weak on its
#      own: a landing page carries a table of contents naming sections it does
#      not contain, which is exactly how FiberNeAT passes this check.
#
# Measured, on the five archives available when this was written:
#
#     Cliff et al.      (ar5iv)          63,356 B prose   58 paragraphs   PASS
#     multi-modal       (PMC)           101,115 B prose   90 paragraphs   PASS
#     Hagmann 2008      (Zotero PDF)     62,188 B prose   67 paragraphs   PASS
#     Cammoun 2012      (Zotero PDF)     54,359 B prose   43 paragraphs   PASS
#     FiberNeAT         (IEEE landing)   16,810 B prose   13 paragraphs   REJECT
#
# Publisher chrome is reported but **never** decides the verdict. Two earlier
# designs made it decide and both were wrong: rejecting on chrome in the tail
# rejects Cliff et al., a complete paper carrying one line of arXiv footer nav;
# and treating everything after the first chrome line as non-body rejects
# Cammoun 2012, because an Elsevier PDF prints "All rights reserved" on page 1.
# Chrome is a contaminant to trim, not evidence about what the document is.
#
# Known limits, stated so nobody trusts this further than it goes
# ---------------------------------------------------------------
#   * It cannot detect a *truncated* paper. A paper cut off at 40% has the same
#     skeleton as a whole one. `zotero-cli get fulltext` truncates -- it returned
#     41 KB where the PDF holds 72 KB -- so extract from the PDF via
#     `pdftotext | _meta/pdf-clean.sh`, never from the CLI's fulltext.
#   * It cannot detect the wrong paper, a supplement, or a corrigendum.
#   * A genuine short paper -- a 4-page conference note -- will fail rules 1 and
#     2 and needs a human override. This is the intended bias, but note the
#     sharp edge: it means the check cannot tell a landing page for a short
#     paper from the short paper itself. When overriding, read the file.

set -euo pipefail
export LC_ALL=C

quiet=0
if [ "${1:-}" = "--quiet" ]; then quiet=1; shift; fi
f="${1:-}"
if [ -z "$f" ] || [ ! -f "$f" ]; then
    echo "validate-archive.sh: usage: [--quiet] <file>" >&2
    exit 2
fi

say() { [ "$quiet" -eq 1 ] || printf '%s\n' "$*"; }

chrome_re='all rights reserved|privacy policy|use of cookies|cookie settings|accept all cookies|sign in to|institutional sign in|purchase (this )?(article|pdf)|subscribe to (this|the) journal|not-for-profit organization, IEEE|© ?copyright [0-9]{4}'

fail=0
total=$(wc -c < "$f")

# ── 1. prose volume ──────────────────────────────────────────────────────────
prose=$(awk 'length>=200{s+=length} END{print s+0}' "$f")
paras=$(awk 'length>=200' "$f" | wc -l)
if [ "$prose" -lt 25000 ]; then
    say "FAIL  prose: ${prose} bytes in paragraph-length lines (< 25000)"
    say "      -> ${total} bytes total, so this is an abstract page or a truncated fetch"
    fail=1
else
    say "ok    prose: ${prose} bytes of ${total} in paragraph-length lines"
fi

# ── 2. paragraph count ───────────────────────────────────────────────────────
if [ "$paras" -lt 20 ]; then
    say "FAIL  paragraphs: ${paras} lines of >= 200 chars (< 20)"
    fail=1
else
    say "ok    paragraphs: ${paras}"
fi

# ── 3. section skeleton ──────────────────────────────────────────────────────
sec_re='^[[:space:]]*(#+[[:space:]]*)?([0-9]+([.)][0-9]*)*[[:space:]]+)?(abstract|introduction|background|materials and methods|methods|methodology|results|discussion|conclusions?|references|bibliography|acknowledge?ments)\b'
distinct=$(grep -ioE "$sec_re" "$f" 2>/dev/null \
    | sed -E 's/^[[:space:]]*(#+[[:space:]]*)?([0-9]+([.)][0-9]*)*[[:space:]]+)?//' | tr 'A-Z' 'a-z' | sort -u | wc -l || true)
if [ "$distinct" -lt 2 ]; then
    say "FAIL  structure: ${distinct} distinct section heading(s) (< 2)"
    fail=1
else
    say "ok    structure: ${distinct} distinct section headings"
fi

# ── 4. publisher chrome — reported, never decisive ───────────────────────────
chrome_line=$(grep -niE "$chrome_re" "$f" | head -1 | cut -d: -f1 || true)
if [ -n "$chrome_line" ]; then
    say "warn  chrome: publisher boilerplate at line ${chrome_line} — trim if it is not the paper's own copyright line"
else
    say "ok    chrome: none found"
fi

if [ "$fail" -eq 0 ]; then
    say "PASS  $f is plausibly a full paper. A human still has to read it."
else
    say "REJECT  $f — do not archive. Fall through to another retrieval route."
fi
exit "$fail"
