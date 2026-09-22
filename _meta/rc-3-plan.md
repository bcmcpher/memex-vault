# memex-vault v1.0.0-rc.3 — land trial 2's findings, then run trial 3

Written 2026-09-22 in the template, after the trial-2 skill campaign closed in the
brain-connectivity fork `~/Projects/memex-trial2`. Infrastructure doc — not a vault
node. No frontmatter, and nothing should link to it with a wikilink.

The evidence lives in the fork: `~/Projects/memex-trial2/_meta/skill-evaluation.md`
holds T2-1…T2-44, each with observed output, a root cause at file:line and a proposal,
and `~/Projects/memex-trial2/_meta/rc-2-plan.md` § Trial 2 resume point holds the
census and the deviation ledger. This file holds the *order* — the execution plan
that turns them into `v1.0.0-rc.3`. Every file:line below refers to this template at
`885498e` (tag `v1.0.0-rc.2`); the fork changed content only, so the references are
exact here.

## Context

Trial 2 (`~/Projects/memex-trial2`, branch `skill-campaign-2`, closed at `0a84542`) ran all
21 skills and produced **T2-1…T2-44** in `_meta/skill-evaluation.md`. `v1.0.0-rc.2` does not
graduate. rc.3 lands the fixes **in the template** `/home/bcmcpher/Projects/claude/memex-vault`
(branch `rc-2` @ `885498e` = tag rc.2, clean; tooling byte-identical to the fork, so every T2
file:line applies there), grouped by file, merged with rc-scoped trial-1 rows. Trial 3 then
runs against rc.3 on an expanded corpus, reusing trial 2's 12 extracts and deep-extracting 10
new papers fresh.

**Where changes land**
| Location | What |
|---|---|
| Template `/home/bcmcpher/Projects/claude/memex-vault`, branch `rc-3` | **All** skill, lint, schema, template, script, CI, doc and migration changes (Part A) |
| `~/Projects/memex-trial2` | **Nothing.** Read-only record; the migration dry run uses a `/tmp` copy |
| `~/Projects/memex-seed-corpus/v2/` | Corpus v2 (not git); v1 untouched |
| `~/Projects/memex-trial3` (new fork of tag rc.3) | Trial-3 content, ledger, and the one-off extract importer — trial-specific, never upstreamed |

**Decided with the user**
- Scope IN: all 44 T2 findings; R2 labelling half (archive SHA-256); every "Not in RC-2" row
  (`rc-2-plan.md:861-883`), including Finding 13 post-write assertions.
- Scope OUT (1.x): R1, R2 version model, R3, R4 remainder, R5-R7, R10-R13, M3/M4/M8.
  **R8 stays undecided with the user**; its per-write half (T2-20, T2-42) is in.
- T2-33: fix `memex-refactor` (successor carries `supersedes:: [[retired]]`) + lint direction check.
- T2-25: `part-of::` is topic-only.
- T2-24/T2-35: delete all 15 `skills/*/references/vault-schema.md`; skills read `$VAULT/_meta/schema.md`.
- T2-7 NFC via **perl `Unicode::Normalize`** (perl joins the toolchain; missing module = hard exit, never fallback).
- §7c rebased on **`published:`**, default 5 years.
- Corpus **+10 papers**; reused extracts **rewritten to the trial-3 seed date**.

**Defaults taken (from design; revisit only if wrong)**
- R2 field: frontmatter `archive-sha256:` on source notes, present iff `raw::`. Writers: seed,
  ingest, deep-extract mode A (when it creates an archive). `memex-save` writes no archive → no hash.
- T2-5b: `validate-archive.sh` *reports* leftover `Page N of M`; `normalize.sh` warns on stderr when it
  drops a form feed. No REJECT (would abort seed on 3 corpus archives).
- T2-19 §6d: relative — WARN at ≥ 8 live atoms and ≥ 50% of live atoms, or > 25. T2-32 empty-leaf
  WARN gated at ≥ 10 atoms vault-wide.
- `memex-glossary` and `memex-review` both write a log entry.
- T2-11: new mode B **step 0** reconciles concept slugs by rewriting extract `about:`/`## Concepts`
  through modify candidates (quotes untouched).
- Retirement is one derived rule in schema: *an atom named by some `supersedes::` is retired*;
  lint keeps one `RETIRED[]` table.
- Vimeo route only if a real oEmbed call returns 200 during implementation, else a Not-in-RC-3 row.
- T2-2 check greps `\$\{?([0-9]|ARGUMENTS)` in `skills/*/SKILL.md`.

---

## Part A — rc.3 in the template

Branch `rc-3` off `rc-2`. One conventional commit per item; body lists T2/row ids. **Every lint
change that alters fixture output commits its reviewed `expect` diff in the same commit, quoted in
the body — never bulk `--update`.**

**WP0 — `_meta/rc-3-plan.md`.** Scope, decisions above, Not-in-RC-3 table.

**WP1 — hermetic lint harness (T2-1). First, so every later lint commit is measured.**
`_meta/test-lint.sh:53-58` copies a fixture-owned `_meta/lint-fixtures/domain.md` and builds
`sources/*` from its § Source Types; header comment `:12-16` explains why. CI step runs
test-lint with a foreign `domain.md`. Pass: 8/8 in template and on a copy of trial-2.

**WP2 — loader-safe skills (T2-2, T2-4).** `memex-seed` `:124,:131` read `"$MANIFEST"`, prose
`:179,:575` says "the first argument", `:52` detector prints one 0. `memex-tend` `:89-93` awk
without positional fields; `/tmp/tend-lint.out` → `mktemp`. New `_meta/check-skills.sh` (CI):
no positional params in skills; no `references/vault-schema` (enabled in WP5); later, every tend
route string exists in `lint.sh`.

**WP3 — archive scripts (T2-3, T2-5a/b, T2-7, T2-8, validate-archive holes).** Before any hashing.
`normalize.sh`: unknown flag → exit 2 (`:182-190`); perl NFC before folding; de-hyphenation
trade-off documented `:51`; form-feed stderr warning; header notes hashes change with normalize.
`pdf-clean.sh --report` on no-form-feed input → "cannot analyze", non-zero. `validate-archive.sh`
page-furniture report + limits header. New `_meta/test-tools.sh` (CI): idempotence, U+2126→U+03A9,
flag exit 2, pdf-clean report.

**WP4 — schema + templates.** `_meta/schema.md`: drop `part-of::` from Atom→Atom Structural
(`:119-124`, T2-25); structural half of the decision tree (T2-24b); `contrasts-with::` symmetric
(T2-26c); `supersedes::` direction + new § Retirement (T2-33); § Candidate Lifecycle — gate every
file in the write set (T2-42, T2-20) and the write protocol candidate→confirm→write→**assert**→
delete→log (Finding 13), filename `YYYY-MM-DD-HHMMSS-…`; § Concurrency scratch keyed via
`mktemp -d` (T2-6); Finding 8 sentence tied to `archive-sha256:`; define `archive-sha256:` (R2).
`_templates/source-digital.md`, `source-meeting.md` gain `defines::` (T2-21). `.gitignore`
`_meta/candidates/*` + `!…/.gitkeep`, commit `.gitkeep` (T2-18).

**WP5 — delete the 15 schema digests (T2-24a, T2-35), one atomic commit.** `git rm
skills/*/references/vault-schema.md`; header pointers → `$VAULT/_meta/schema.md`; in-body pointers
to named sections (`memex-connect:183`, `memex-reconcile:209`, `memex-review:156`, `memex-ingest:128`,
`memex-topic-init:18`). Enable the check-skills assertion.

**WP6 — `_meta/lint.sh`, no-output-change commits first.**
- 6a `printf` replaces `echo -e` in `warn/error/ok` (`:69,:77-79,:1672`); `RETIRED[]`; §4 cost comment. Fixture: backslash quote.
- 6b independence reader `:362` — `attendees:` (T2-23), `"Last, First"` + block-list authors.
- 6c §9 `:1183,:1189` + `challenges`/`limits`, `sources/` root (T2-17). Fixture `conflict-scope`.
- 6d §6d `:875` relative threshold, exclude retired, empty-leaf WARN (T2-19, T2-32), text "every direct member must move" (T2-34).
- 6e §7a names atom-target `part-of` as topic-only (T2-25); supersedes-direction check (T2-33); retired skipped in §4/§7c/§7d/§8. Fixture `retirement`.
- 6f untyped `related::` WARN (T2-12); glossary with 0 inbound `defines::` WARN (T2-21); namespace guard `:529-562` covers `topics/` (T2-37). Fixtures ×3.
- 6g §8d `:1142` measures `raw::` bytes, stages `read|processed` (T2-28 + trial-1 row); move §7d `:976-993` into §8 (T2-43). Fixture `under-extracted`.
- 6h §13 "N of M verified" + WARN on never-signed `high` (T2-13).
- 6i §7c on `published:`, 5 years, Lint Heuristics row updated.
- 6j §5 R2: WARN on missing / mismatched `archive-sha256:` (`sha256sum`, `shasum -a 256` fallback). Fixture `archive-hash`.

**WP7 — skills, one commit each; Finding 13's assertion goes into each writing skill's commit.**
1. Capture: `memex-init` (T2-18), `memex-candidates` (`:35` stderr), `memex-seed` (R2; update step 6's
   predicted warning count), `memex-ingest` (R2; candidate filename `:260,:277`), `memex-save`
   (T2-22 PMC domain/path, fetch-failure = no evidence; 5a opt-in; Vimeo if verified), `memex-meeting`.
2. `memex-deep-extract` (2-3 commits: mode A / mode B steps 0,3,4 / step 5): T2-6, 8, 10, 11+16
   (step 0), 14, 15, 17, 21 (`defines::` as modify candidate), 33 wording `:423`, R2.
3. Graph: `memex-connect` (T2-9 inbound test drops `extracted-from::`; batch-analyse, confirm per
   note), `memex-refactor` (T2-20 candidates S5/S6b/S7/M8; T2-33), `memex-reconcile` (T2-20, 26
   reverse retype + pairs, 27 fence filter, skip retired, route from T2-12 WARN), `memex-conflicts` (T2-17).
4. Audits: `memex-trust-audit` (T2-28, 29, 30), `memex-stale` (T2-31 14-day gate, T2-32 Check 5).
5. Topic layer: `memex-topic-init` (T2-34, 35, 37), `memex-topic-emerge` (T2-36-39), `memex-review` (T2-40, 41, 25).
6. Readers: `memex-glossary` (T2-42 + log), `memex-compose` (T2-44, Retired heading).
7. `memex-tend` last (WARN strings frozen): route by WARN text; rows for every new WARN; §7g →
   `memex-topic-init` / review Lens F; drop "offer it, never schedule it" (T2-12, T2-43).

**WP8 — docs.** `roadmap.md` (R2 labelling applied; R8 premise sentence corrected per T2-20;
Not-in-RC-2 rows closed), `roadmap-applied.md`, README grounding wording, CHANGELOG with
§ Migrating from rc.2, `VERSION` → `1.0.0-rc.3`.

**WP9 — `_meta/migrate-rc2-rc3.sh`** (dry-run default, `--apply`, idempotent). Deterministic steps
in strict order: (1) `_meta/candidates/.gitkeep`; (2) re-normalize `.archive/*` to NFC; (3) pipe every
`quote:` through the same `normalize.sh`; (4) backfill `archive-sha256:`. Then a lint-driven
checklist for judgement steps: flip `supersedes::`, add `defines::` back-links, retype atom→atom
`part-of::`. Forks must `git rm` the digests themselves (path copies don't propagate deletes).

**WP10 — dry run, smoke test, tag.** See Verification; then tag `v1.0.0-rc.3`.

---

## Part B — trial 3

1. **Corpus v2** at `~/Projects/memex-seed-corpus/v2/` (v1 untouched): copy the 12 v1 archives,
   re-normalize with rc.3 (assert only Rosas changes), `SHA256SUMS`, README.
2. **+10 papers**, 2 each for parcellation, functional-connectomics, statistical-connectivity-inference,
   tractography-validation, reproducibility. Retrieve via `zquery.py` / installed `opencite` (not
   `uvx`); `pdftotext | pdf-clean.sh | normalize.sh` from rc.3; `validate-archive.sh` must pass.
   Author independence across all 22 from full Crossref author lists (lint's key + a manual
   surname pass). Paper selection is shown to the user before fetching.
3. **Manifest v2**: full `authors` (fix Cammoun's "et al."), `archive_sha256`, `branch` = target
   leaf slug; sub-topic papers get `branch: structural-connectomics` + informational
   `intended_subtopic`, so Stage 12's topic-init/emerge replay stays comparable.
4. **Fork** `~/Projects/memex-trial3` from tag rc.3: lint exit 0; test-lint all pass before and
   after `memex-init`; `check-skills.sh` passes.
5. **Pre-register predictions**, one per rc.3 change (e.g. seed detector prints one 0; tend step 1
   runs verbatim; connect discovery sees 22 not 0; 0 scratch collisions; 0 homoglyph misses;
   `defines::` count = glossary count; refactor kill drill leaves candidates; 0 supersedes-direction
   WARNs after a split). Mode B uses rc.3's T2-10 rule — no null-promotion deviation.
6. **`memex-seed`** on v2: 22 sources, root + 4 leaves, hashes match `SHA256SUMS`.
7. **Import the 12 extracts** — `_meta/trial3/import-trial2-extracts.sh`, committed in the fork:
   join trial-2 ↔ trial-3 sources on corpus slug from `raw::` (DOI cross-check); source text from
   `git -C ~/Projects/memex-trial2 show e752e85:extracts/…` (no Promotion Log rows); rewrite
   `extracted-from::` and filename to the trial-3 slug; keep `extracted:`/`generated.at`; pipe quotes
   through rc.3 `normalize.sh` and **assert exactly 9 lines change, all Rosas, U+2126→U+03A9**;
   assert no `2026-09-18-` remains, `claims:` = `^cNN` count; write 12 `deep-extract/extract` log
   entries marked IMPORTED. Pass: lint §12 **460 verified, 0 FAIL**. Ledger deviation **D1**:
   imported claims are not evidence about rc.3 mode A (they carry D4 and the claim-count prompt).
8. **Fresh mode A on the 10 new papers**: no self-verify block, no claim-count instruction.
9. **Campaign** mirroring trial-2 Stages 9-14, starting with mode B step 0 over all 22 extracts;
   findings T3-n in `_meta/skill-evaluation.md`; mode-A metrics reported over the 10 fresh papers only.

---

## Verification

- Template: `test-lint.sh` all pass (8 existing + ~9 new fixtures), CI foreign-`domain.md` step
  passes; `check-skills.sh`, `test-tools.sh`, `bash -n _meta/*.sh` pass; lint on empty vault exit 0.
- Greps all empty: `\$\{?([0-9]|ARGUMENTS)` in `skills/*/SKILL.md`; `find skills -name vault-schema.md`;
  `references/vault-schema` in skills/README; `YYYYMMDD-HHMMSS` in skills/schema; `echo -e` in lint.
- Corpus v1: validate-archive 12 PASS with furniture report on exactly Aydogan, Daducci, Rheault;
  normalize twice = byte-identical; rc.3 re-normalization changes only Rosas.
- **Dry run on `cp -a ~/Projects/memex-trial2 /tmp/t2-rc3`** (original untouched), rc.3 tooling
  ported: record each new WARN class count pre-migration; migrate steps 1-2 → §12 exactly 9 FAIL;
  step 3 → 460 verified, 0 FAIL; step 4 → 0 hash WARNs; supersedes flip → 0 direction WARNs;
  time lint vs rc.2. Results into `rc-3-plan.md` § Verification.
- Fresh-fork smoke: clone tag to `/tmp`, lint, `memex-init`, test-lint all pass, `memex-seed` on
  v1 manifest, `_meta/candidates/.gitkeep` present.

## Risks

- Fixture `expect` churn masking regressions → one check per commit, diffs in bodies.
- NFC rewrites archive bytes → NFC before hashes, strict migration order, importer asserts 9 lines.
- `memex-tend` keyed on WARN text makes WARN strings an API → freeze before WP7.7, check-skills asserts.
- Retirement semantics touch lint + 5 skills → one schema definition, one `RETIRED[]`.
- Seed's exact post-seed warning prediction → gate new WARNs or update step 6 in the same commit.
- Trial validity: imported extracts flatter mode A; corpus independence failures inflate `high`;
  census scripts call `/usr/bin/grep` (rtk wraps `grep`).

---

## Not in RC-3

| Item | Why it waits |
|---|---|
| R1 — interchange format (Phase 8) | 1.x; ships as `v1.1.0` |
| R2 — version model, `version:` field, `memex-deep-extract-reconcile` | 1.x; rc.3 ships only the labelling half (`archive-sha256:`) |
| R3 — conceptual extraction from code | 1.x, new capability |
| R4 remainder — Zotero tier, `fetch-fulltext.sh`, `resolve-citation.sh`, `repo-meta.sh` | 1.x, retrieval-side |
| R5, R6, R7 — temporal claims, open questions, worked example | 1.x |
| R8 — transactional multi-file writes | **Undecided, with the user.** rc.3 lands the per-write half (T2-20, T2-42); grouping, journal and recover need a runtime |
| R10–R13 — authority, session context, log growth, index | 1.x, pending evidence |
| M3, M4, M8, Phases 5/8/9, open question 4 | Already deferred |

## Verification results

*Filled in by WP10.*
