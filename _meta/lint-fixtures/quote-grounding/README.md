# quote-grounding

**Section 12 — the anti-fabrication check, and the one with no LLM anywhere in
the verification loop.** Every claim in `extracts/` carries a verbatim quote, and
lint greps that quote in the source's normalized `raw::` archive. A quote that is
not there is a FAIL.

If any single check in this file should never regress silently, it is this one.
The whole confidence rubric rests on it: `confidence: high` requires
block-anchored citations, and a block anchor is only worth anything if the quote
behind it was checked against the bytes.

Pinned here:

- `^c01` — quote present verbatim → grounded, silent
- `^c02` — quote **absent** → FAIL, with the archive named and the quote excerpted
- `^c03` — quote contains an ellipsis → FAIL **with the ellipsis hint**, because a
  contiguous-quote rule is unenforceable if the error does not say so. The rule
  exists because a spanning quote cannot be grepped; two `quote:` lines can.

The archive is deliberately plain prose. Section 12 works only against normalized
text — raw `pdftotext` output is hard-wrapped and full of ligatures and smart
quotes, which is what `_meta/normalize.sh` exists to fix and why every skill that
writes an archive pipes through it.
