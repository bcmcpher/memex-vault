# freshness

Section 7c, rebased in rc.3 on `published:` with a 5-year window (was `saved:`
against 18 months, which measured when the vault acquired a source, not how old
the evidence is). `test-lint.sh` pins `MEMEX_LINT_YEAR=2026`, so the window
starts at 2021.

- `old-only` — newest source published 2019-06 → WARN
- `mixed` — 2019 and 2024-03-02; the newest counts → silent
- `boundary` — published `2021`, exactly 5 years → silent (strictly older warns)
- `undated-only` — its only source has no `published:` → silent, no guess
