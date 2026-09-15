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
# Normalization unwraps each paragraph onto one line, so a body paragraph becomes
# a very long line while navigation, menus and figure labels stay short.
#
# A document passes on either of two paths:
#
#   LONG  — a body is present: >= 25,000 bytes on lines of >= 200 characters, in
#           >= 20 such lines. Every real landing page found is under 17 KB. This
#           is the path almost every full paper takes.
#   SHORT — a reference list is present AND the body cites into it: >= 30
#           reference-style author names ("Basser PJ,", "P. J. Basser,",
#           "Basser, P. J.,") and >= 15 in-text citations ("[12]", "et al.
#           2019", "Basser, 2019;") on paragraph-length lines that are not
#           themselves reference entries. This is how a 4-page commentary passes.
#
# Why these and not structure headings (roadmap M18). The first version used the
# 25 KB floor alone plus a count of section headings, and on the RC-2 corpus it
# rejected 4 genuine papers in 12: two short commentaries under the floor, and two
# papers whose headings pdftotext mangles (IEEE drop-caps arrive as
# "I. I NTRODUCTION"). The fix proposed in M18 — test for affiliations, numbered
# sections and a references heading — was measured before it was built and does
# not discriminate: "Access through <university>" puts an affiliation on 21 of 22
# landing pages, and numbered sections and a references heading each appear in
# only 3 of the 12 corpus papers. Commentary is exactly the genre where a field's
# disagreement lives, so rejecting it would hollow out any adversarial corpus.
#
# Joining drop-caps in pdf-clean.sh was measured too, and is not done: the
# proposed ^([A-Z]) ([A-Z]{2,}) join misses every numbered heading and corrupts
# real text ("A DCM" -> "ADCM", "P FIG. 1." -> "PFIG", hemisphere-region figure
# labels such as "R PCUG"). No heading test remains for it to serve.
#
# Calibrated 2026-09-15 on 12 RC-2 corpus papers, 9 trial-1 archives, 15 Zotero
# full texts, and 22 real landing pages (IEEE Xplore; Elsevier article preview,
# section snippets and abstract-only):
#
#     corpus + trial-1 papers    20 of 21 pass    (feng-bundlecleaner: no body,
#                                                  no reference list captured)
#     real landing pages          0 of 22 pass    nearest: 16,972 B prose;
#                                                  14 reference-style names
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
#   * A landing page showing body snippets AND a full reference list would pass
#     the SHORT path. ScienceDirect currently shows one reference; a synthetic
#     preview padded with a full list passes. No such real page was available.
#   * Rejection of an IEEE abstract + full reference-list page (the FiberNeAT
#     trap as first described) rests on a synthetic reconstruction: 4 body
#     citations against a threshold of 15.
#   * A short paper passes only if its reference list survived extraction with
#     author initials, and its body cites by number or author-year. Superscript
#     citations are invisible, and so is a reference list with full first names.
#   * The SHORT margins are thin on HTML short communications (one sits at 33
#     names and 16 citations). The LONG path is still a length test: a landing
#     page with > 25 KB of snippets in >= 20 paragraphs would pass.
#   * It cannot detect a *truncated* paper. `zotero-cli get fulltext` truncates --
#     it returned 41 KB where the PDF holds 72 KB -- so extract from the PDF via
#     `pdftotext | _meta/pdf-clean.sh`, never from the CLI's fulltext.
#   * It cannot detect the wrong paper, a supplement, or a corrigendum.
#   * A REJECT on a document you have read and know to be complete is a finding
#     about this script, not an override to apply silently. Record it.

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

total=$(wc -c < "$f")

# One pass. A line with 3+ reference-style author names is a reference entry;
# only the other paragraph-length lines are searched for citations, or a
# reference list's own "[12]" stubs would count as the body citing it.
# (No {n} intervals: not every awk supports them.)
read -r prose paras refauth bodycite < <(awk '
{
    L = $0; len = length(L)
    if (len >= 200) { prose += len; paras++ }
    c = L; ra  = gsub(/[A-Z][a-z][A-Za-z-]* [A-Z][A-Z]?[A-Z]?(,| \()/, "", c)                    # Basser PJ,
    c = L; ra += gsub(/[A-Z]\. ?([A-Z]\. ?)?[A-Z][a-z][A-Za-z-]+(,| and | et al)/, "", c)         # P. J. Basser,
    c = L; ra += gsub(/[A-Z][a-z][A-Za-z-]+, [A-Z]\.( ?[A-Z]\.)?(,| &| \(| et al|;)/, "", c)    # Basser, P. J.,
    refauth += ra
    if (len >= 200 && ra < 3) {
        c = L; ci  = gsub(/\[[0-9][0-9]?[0-9]?([,-] ?[0-9][0-9]?[0-9]?)*\]/, "", c)            # [12] [3,4] [5-7]
        c = L; ci += gsub(/\( [0-9][0-9]?[0-9]? [,)]/, "", c)                                   # ( 12 , (ScienceDirect HTML)
        c = L; ci += gsub(/et al\.?,? \(?(19|20)[0-9][0-9]/, "", c)                              # et al. 2019
        c = L; ci += gsub(/[A-Z][A-Za-z-]+,? (19|20)[0-9][0-9][a-z]?[;)]/, "", c)               # Basser, 2019;
        bodycite += ci
    }
}
END { print prose + 0, paras + 0, refauth + 0, bodycite + 0 }' "$f")

long=0;  [ "$prose" -ge 25000 ] && [ "$paras" -ge 20 ] && long=1
short=0; [ "$refauth" -ge 30 ] && [ "$bodycite" -ge 15 ] && short=1

# ── LONG: a body ─────────────────────────────────────────────────────────────
if [ "$long" -eq 1 ]; then
    say "ok    body: ${prose} bytes of ${total} in ${paras} paragraph-length lines"
else
    say "short body: ${prose} bytes in ${paras} paragraph-length lines (long path needs >= 25000 in >= 20)"
fi

# ── SHORT: a reference list the body cites ───────────────────────────────────
if [ "$short" -eq 1 ]; then
    say "ok    references: ${refauth} reference-style author names, ${bodycite} citations from body paragraphs"
else
    say "      references: ${refauth} reference-style author names, ${bodycite} citations from body paragraphs (short path needs >= 30 and >= 15)"
fi

# ── publisher chrome — reported, never decisive ──────────────────────────────
chrome_line=$(grep -niE "$chrome_re" "$f" | head -1 | cut -d: -f1 || true)
if [ -n "$chrome_line" ]; then
    say "warn  chrome: publisher boilerplate at line ${chrome_line} — trim if it is not the paper's own copyright line"
else
    say "ok    chrome: none found"
fi

if [ "$long" -eq 1 ]; then
    say "PASS  $f has a full body. A human still has to read it."
    exit 0
elif [ "$short" -eq 1 ]; then
    say "PASS  $f is a short paper: a reference list, cited from the body. A human still has to read it."
    exit 0
fi
say "REJECT  $f — no body and no cited reference list; looks like a landing page or a truncated fetch."
say "        Fall through to another retrieval route. If you have read it and it is complete, record that as a finding."
exit 1
