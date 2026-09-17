# memex-vault v1.0.0-rc.2 — apply the audit, then build one skill

Written 2026-09-11 in the brain-connectivity fork, after the trial-1 skill campaign
closed. **Moved to the template 2026-09-15**, when development moved here (Decision
3). Infrastructure doc — not a vault node. No frontmatter, and nothing should link
to it with a wikilink.

Third of three companions. The other two stay in the fork, because they are
trial-1 evidence and a template ships with none:
`~/Projects/memex/_meta/roadmap.md` holds *what* to do and why (M11–M22), and
`~/Projects/memex/_meta/skill-evaluation.md` holds the *evidence* that it needs
doing. This file holds the *order* — the execution plan that turns them into
`v1.0.0-rc.2` of this template. Delete it once `rc.2` is tagged and the trial has
started; the durable record is the other two, and Stage 8 ports the roadmap here.

Throughout, **"the fork"** is `~/Projects/memex` and bare paths are relative to
whichever repo the step names — the two repos share a layout.

---

## Context

The 2026-09-11 skill campaign ran all 20 skills over a real vault for the first
time and produced twelve findings (fork `_meta/roadmap.md` M11–M22), a rewrite of
M7, and a 20-row verdict table (fork `_meta/skill-evaluation.md` § Trial-1 Skill
Campaign). Nothing was retired.

**None of it has reached the template.** This repo was clean on `main` at
`v1.0.0-rc.1` and is missing even the fixes the trial already made: no
`.obsidian/graph.json`, no `_meta/pdf-clean.sh`, no `_meta/validate-archive.sh`,
a `lint.sh` without the M20 parser fix, and a 57 KB roadmap against the fork's
98 KB. So RC-2 is a back-port *plus* the new findings.

The outcome this aims at: a template a fresh fork can run the RC-2 bulk import
against — 12 documents, 12 disjoint author groups, two asymmetric branches
(`~/Projects/memex-seed-corpus/manifest.json`) — where the seeded hierarchy has
somewhere to land and `confidence:` reads as information rather than decoration.

**What promotes `v1.0.0`, restated.** Not "the RC-2 fixes work." A release
candidate graduates when a full trial against it **surfaces nothing new worth
fixing**. `v1.0.0-rc.1` was tagged on four verification-debt rows and the first
real trial returned twelve findings — so the criterion was too weak, and the tag
came early. Expect `rc.3` and `rc.4`: every trial that produces a finding
produces another RC, and that is the process working rather than failing.

**Decisions taken.**

1. RC-2 **includes D2** (topic→topic hierarchy) **and D3** (topics-only seed
   scaffold). The corpus is deliberately two branches and M21 shows three skills
   degrade on the flat topic layer; without D2 the test cannot test its own premise.
2. **One new skill** — a manifest-driven bulk seed. Reconcile, export and import
   are deferred.
3. **Fixes are developed here, in the template, on branch `rc-2`.** *(Reversed
   2026-09-15; it originally read "developed in the fork, then ported".)* The fork
   is test data only and no code is copied back into it: template code runs
   against fork content in place — see § Testing against the fork. Nothing in
   *writing* a fix needs notes; only *verifying* some of them does, and that does
   not need the code to live where the notes are.
4. **Every known finding is dispositioned before the trial.** *(Added
   2026-09-15.)* The gate is "a trial that surfaces nothing new", so an issue that
   is known but unrecorded would come back as a false "new" finding and make the
   gate unreadable. Everything not scheduled in Stages 1–8 is in § Not in RC-2,
   and trial-2 findings are checked against that table before they are logged.

---

## Two repos, and what moves between them

| | `~/Projects/memex` (fork) | `~/Projects/claude/memex-vault` (template) |
|---|---|---|
| role | evidence record + test data | the artifact being released; **all fixes written here** |
| branch | `rc-2` off `skill-campaign` | `rc-2` off `main` |
| carries | brain-connectivity `domain.md`, 22 atoms, 21 sources, 9 extracts, `skill-evaluation.md` | generic `domain.md`, zero notes |

**Stage 1 copies fork → template**, template-layer paths only: `skills/`,
`_templates/`, `.obsidian/` (config files, not `plugins/`), `README.md`,
`CHANGELOG.md`, `VERSION`, `.gitignore`, and `_meta/` *except* `domain.md`,
`log.md`, `candidates/` and `skill-evaluation.md`.

Never port: `_meta/domain.md` (fork vocabulary), `_meta/log.md`, any content
directory, `.obsidian/plugins/**` (21k lines of vendored Dataview/Templater — a
local install), `.obsidian/workspace.json` (per-machine UI state).

After Stage 1 nothing moves in either direction except the two Stage 4 files
noted below, copied to the fork for a render check and restored afterwards.

`skills/{memex-glossary,memex-ingest,memex-search}/evals/` exist only in the
template. Leave them; updating them for changed skills is out of scope and noted
in the roadmap instead.

### Testing against the fork

- **Lint:** `bash _meta/lint.sh ~/Projects/memex`, run from this repo. The vault
  path is `$1` (`lint.sh:38`), so this repo's lint checks the fork's notes and
  reads the fork's `domain.md`.
- **Skills:** start a session in this repo with `MEMEX_VAULT=~/Projects/memex`.
  All 20 skills resolve the vault from it, and each repo loads its own `skills/`
  through `.claude/skills -> ../skills`, so the session runs *these* skills over
  *those* notes.
- **Writing skills write into the fork.** Run them with the fork on its `rc-2`
  branch and `git -C ~/Projects/memex restore .` afterwards, unless the write is
  itself something the fork should keep.
- **The one exception is Obsidian.** The Stage 4 rollup must render in the fork's
  own Obsidian, which reads the fork's files: copy `_templates/topic-concept.md`
  and the one affected topic across for that check, then restore.
- **Stage 6 never touches the fork.** Seed testing is a `/tmp` clone of this repo
  plus the corpus.
- **Regression baseline:** `~/Projects/memex-seed-corpus/lint-baseline-rc1.txt` is
  the fork's lint output at `rc.1` with the M20 fix (exit 0, 8 warnings, 365
  quotes, 16 s), captured 2026-09-15. This repo has no notes, so that file is the
  only record of what lint says about real content before Stage 3 changes it.

---

## Stage 0 — persist this plan *(done)*

Committed in the fork as `e67342f` on 2026-09-11; moved here 2026-09-15, with the
fork's pointer lines updated to this path. Regression baseline captured.

---

## Stage 1 — back-port what the trial already fixed *(done)*

One commit here. Pure copy from the fork, no new design. This is M17 and its
neighbours, all already verified in the fork.

- **New files:** `_meta/pdf-clean.sh`, `_meta/validate-archive.sh`
- **Updated:** `_meta/normalize.sh` (step 0, C0 control bytes), `_meta/lint.sh`
  (the M20 provenance-parser fix — `f&&(/^[a-z]/||/^---[[:space:]]*$/){exit}` on
  all three parsers), `_templates/source-meeting.md` (rewritten sections),
  `_templates/source-digital.md`, `_templates/topic-research.md`
  (`this.file.link`, not a Templater-baked link), `skills/memex-save/SKILL.md` and
  `skills/memex-ingest/SKILL.md` (the `code` medium), `README.md` §3–§4 (graph
  filter vs global ignore; the graph menu is inside the graph pane, not under
  Settings)
- **`.obsidian/`:** add `graph.json` (configured search filter, `showOrphans:
  false`, five colour groups), `app.json`, `appearance.json`, `core-plugins.json`,
  `community-plugins.json`
- **`.gitignore`:** add `.obsidian/workspace.json` and `.obsidian/plugins/` —
  currently three lines, and nothing stops a fork committing a plugin binary

Checked 2026-09-15: that list is exactly the fork↔template diff on template-layer
paths, and every line present only in this repo's `roadmap.md` or `README.md` is
an rc.1 wording the fork has already superseded. The copy loses nothing.

Done 2026-09-15, with three additions the list above missed. **`.claude/skills ->
../skills`** — tracked in the fork, absent here, and § Testing against the fork
depends on it. **README de-forked** — the copied §3 named the fork's node count
("~49 real nodes") and §4 a fork date; both removed. **Paper names in script
comments kept** (`normalize.sh`, `pdf-clean.sh`, `validate-archive.sh`): they are
the reason the code exists, nothing parses them, and M18 rewrites the
`validate-archive.sh` calibration table in Stage 3.

---

## Stage 2 — the miscalibrated thresholds (M11–M14) *(done)*

Every threshold the campaign exercised was wrong; only two were about vault size.

- **M11(a) drop the temporal thresholds.** Delete `memex-stale` Check 1
  (`skills/memex-stale/SKILL.md:20-33`, >90d unread) and `lint.sh` section 3
  (>30d unread). They ask one question with two numbers and neither produced a
  finding. Keep Check 4 — it was the only stale check that fired.
- **M11(b) move `related::` typing to write time.** `memex-deep-extract` mode B
  proposes a typed relation as it writes the link. `memex-reconcile` Pass 2 loses
  its 30-day rule (`skills/memex-reconcile/SKILL.md:104`) and becomes an
  unthresholded manual backlog tool.
- **M11(c) replace the bloat trigger.** `lint.sh` 6c's `lines > 100` is unreachable
  — prose is one long-wrapped line per paragraph. Measure **body characters
  excluding the `cites::` line**, trigger at **2× the vault's running median**, so
  it self-calibrates per fork the way tag vocabulary already reads from `domain.md`.
  Define the empty and tiny-vault case explicitly (no median below some atom
  count) — this repo has zero atoms and lint must still pass on it.
- **M13 Jaccard.** `skills/memex-topic-emerge/SKILL.md:57` merges candidates at
  `|A∩B| / min(|A|,|B|) ≥ 0.50`, transitively. Two bridge edges at exactly 0.50
  chain a clean split into one 21-atom blob, so the skill proposes nothing. Score
  `|A∩B| / |A∪B|` instead: **7 clusters at 0.50, 5 at 0.30** on identical data.
  This is the highest-leverage single fix the campaign found.
- **M14 reciprocity.** `skills/memex-conflicts/SKILL.md:50` calls a conflict
  acknowledged only if the target carries a reciprocal link, so 13 of 13 pairs
  classify unacknowledged. Exempt `limits::` entirely (directional by construction,
  and 11 of the 13), accept asymmetry for `challenges::`/`refutes::`, require
  reciprocity only for `contradicts::`.
- **M12 the untyped-relation orphan.** With (b) in place, either add a lint check
  that can fire on stale `related::` or delete the row in
  `skills/memex-tend/SKILL.md:112` that promises one. Do not ship a routing table
  naming a signal the linter cannot emit.

Done 2026-09-15. What differs from the list above, and what verification showed:

- **M11(b) targets `memex-connect` and `memex-ingest`, not deep-extract mode B** —
  mode B never writes `related::`; its relation vocabulary is already typed. The
  two skills that do write it now type at write time.
- **M12: the routing row is dropped**, not backed by a lint check — with no age
  threshold, a check could only flag every `related::` (78 in the fork).
  Reconcile's **Keep** is now a `kept::` line in `_meta/log.md` (documented in its
  header), replacing the `updated:` touch that died with the 30-day rule.
- **Numbering kept.** Lint §3 and `memex-stale` Check 1 are retired in place so no
  "section N" / "Check N" reference breaks. `_meta/index.md`'s 30-day query is gone.
- **M11(c):** SKIP below 10 atoms. Fork: median 3,947 body chars; fires on
  `connectome-edge-weighting` only (8,977 > 7,894). Fork lint otherwise equals the
  baseline minus §3; 365 quotes.
- **M13:** tag candidates give **8 clusters at 0.50** (the fork now has 22 atoms;
  the roadmap's 7 was measured on 21) and 5 at 0.30; `min()` gives 1–2.
  Verification found two spec gaps, both fixed in the skill: merge order
  (highest-scoring pair first — ties at the cut are order-dependent) and "mutual"
  `related::` links (reciprocal — either-direction makes the whole vault one
  candidate). **A third is deferred to Stage 4:** on the flat topic layer the
  part-of chain candidates are whole-vault (22 and 20 atoms) and absorb
  `structural-connectivity` at exactly 0.50, so an all-signal run still shows one
  22-atom cluster beside eight real ones. D2's one-leaf rule should make part-of
  candidates leaf-sized; **re-run topic-emerge on the fork after Stage 4.**
- **M14:** 13 pairs (11 `limits::`, 2 `challenges::`). Old rule 13/13
  unacknowledged; new rule **1** (`deterministic-vs-probabilistic-tractography
  limits:: tractometry` — neither body describes it), 2 under a stricter prose
  reading. The prose call is a judgement; a trial-2 count of 1 vs 2 is not a new
  finding.

---

## Stage 3 — `lint.sh` correctness and cost *(done)*

- **Finding 7 / section 8 — the noisiest check in the vault.** Lint counts
  `stage: processed` sources; `schema.md` counts *independent claims across
  independent sources*. Seven false positives in one run; trust-audit later
  confirmed 3 of 9 candidates and refused 6. Cheapest correct fix, and the data is
  already in frontmatter: walk `cites::` between the sources backing an atom and
  compare `authors:` before counting. Where independence cannot be decided, say
  **"N sources (independence unchecked)"** so the number stops reading as a verdict.
- **Finding 11 — 7c and 8 key on `stage: read`, the one stage no skill can
  verify.** *(Added 2026-09-15.)* Trial 2 will hit this on every paper: seed writes
  `stage: unread`, mode A may not touch it, and the atoms mode B then writes draw
  "confidence based on unread material" warnings on sources just read claim by
  claim. Keep the warning, change its test to verifiable evidence: the atom carries
  a block-anchored `cites:: [[ext-...#^cNN]]`, or a cited source has an inbound
  link from `extracts/`. `read` survives as an annotation nothing depends on. The
  skill half is in Stage 5 (`memex-deep-extract`).
- **Finding 10 guard — atom/glossary slug collision.** *(Added 2026-09-15.)*
  Section 1 FAILs on any filename shared between `atoms/` and `glossary/`, and
  WARNs when a glossary slug matches an atom `aliases:` entry. M7 keeps the
  glossary as a disjoint set; this is the guard that keeps it disjoint.
- **Finding 13, lint half — unlogged promotions.** *(Added 2026-09-15.)* WARN when
  an atom cites `[[ext-...#^cNN]]` and that extract's `## Promotion Log` has no row
  for `^cNN` — either a failed append or an unlogged promotion. Build it on the
  per-atom computation from M16, not as another per-citation scan. The skill half
  is deferred (§ Not in RC-2).
- **M16 performance.** `backing_sources()` (`lint.sh:105-126`) runs a `find` over
  `sources/` per citation and is called ~5× per atom — ~1,360 subprocess pairs at
  this size, ~26,000 at 200 sources, i.e. 15–25 minutes. Compute it **once per
  atom** and reuse across 7c/7d/8; build a filename→path map once at startup. A
  20–50× constant-factor win; lint is the vault's only executable state oracle and
  one that takes twenty minutes stops being run. **Do the refactor as its own
  commit, before the section-8 and finding-11 changes**, and diff its output
  against the baseline: a pure performance change must reproduce
  `lint-baseline-rc1.txt` exactly (modulo timing), or it changed behaviour.
- **M18 `validate-archive.sh` — 4 false negatives in 12, all verified by reading.**
  Stop using length as the landing-page test: a 4-page commentary and an IEEE
  landing page are both ~22 KB, and commentary is exactly the genre the RC-2 corpus
  needs for adversarial evidence. Test **structure** instead — references section,
  numbered sections, affiliations block. Separately, normalise `^([A-Z]) ([A-Z]{2,})`
  → `\1\2` in `pdf-clean.sh` (drop-caps arrive as `I NTRODUCTION`) and count
  numbered section markers as headings. The corpus archives are outside both repos
  (`~/Projects/memex-seed-corpus/archive/`), so this needs no fork at all.
- **M15 independent units.** Report independent-unit count alongside source count
  in lint's summary block.
- **M20's generalization, as a task not a code change:** every optional frontmatter
  block is an unexecuted code path until something writes one. Audit the remaining
  optional blocks against a populated example before tagging — the fork is the
  populated example.

Done 2026-09-15 — `9d86c94` … `2f6fe95`. What differs from the list above, with
the numbers that show it:

- **lint.sh requires bash 4** (user decision): associative arrays for M16's tables.
  A guard exits 2 with the fix named; `realpath --relative-to` (GNU-only) is gone.
- **M16** was checked against the post-Stage-2 output, not `lint-baseline-rc1.txt`
  (Stage 2 had already changed it): byte-identical on the fork, the template, an
  edge-case fixture and a 5× copy of the fork. Fork 18.2 s → 4.5 s; 5× 101 s →
  23 s, now linear. § 4 stays mildly superlinear — see § Not in RC-2.
- **Finding 7 / M15.** Independence is a shared author — first initial + surname,
  or `channel:`/`tool:` — or a `cites::` chain. Surname alone chained Frässle to
  Cammoun through two different people named Do. Fork: all six false 8b warnings
  clear; summary reads 8 independent units of 21 sources, 8 unchecked. **No
  template or skill writes `authors:`, `channel:` or `tool:`** — only the fork's
  hand-edited notes carry them, and the manifest's Cammoun row is `[Leila Cammoun,
  et al.]`. Stage 6 `memex-seed` must write full author lists or M15 reads zero.
- **Finding 11.** 7d warns for any atom whose evidence nobody read claim by claim;
  8c only when confidence is medium or high. Fork: one new warning
  (`white-matter-atlas`). `memex-trust-audit`'s UNVALIDATED uses the same test.
- **Finding 10** FAILs a shared atom/glossary filename and WARNs an alias match;
  **finding 13** (12g) checks Promotion Log rows. Fork: zero of either; all 555
  anchored citations are logged.
- **M18: the planned fix was measured first and did not hold.** Affiliations
  appear on 21 of 22 real landing pages ("Access through <university>"), and
  numbered sections and a references heading each on 3 of 12 corpus papers. The
  drop-cap join misses every numbered heading and corrupts real text, so it is not
  done (user decision). Rule instead: a body (≥ 25 KB in ≥ 20 paragraph lines) or a
  reference list the body cites into. 62 labelled samples all correct — corpus
  12/12 pass, trial-1 archives 8/9 (feng-bundlecleaner rejected before and after),
  22/22 IEEE and Elsevier landing pages rejected. Known holes are in the header.
- **M20 audit** found the same failure class in 8 more places — whole-file greps
  reading body lines, unnormalised values, empty values passing, unindented block
  lists dropped, `verified:` shape rejections, `extracts/` missing from § 11. All
  fixed through one frontmatter reader; 33 cases now report what YAML says.
- **Also fixed:** `[[slug|display]]` citations never resolved in
  `backing_sources`, a bug M16 had to preserve to stay byte-identical.

Fork lint now: exit 0, 4 warnings (video inbox item, `connectome-edge-weighting`
6c, `brain-connectivity` 6d, `white-matter-atlas` 7d), 365 quotes verified.

---

## Stage 4 — D2 hierarchy and D3 scaffold *(done)*

The schema amendment. `_meta/schema.md` is the one file `memex-init` refuses to
touch, so this is a template-level change by definition.

- **`_meta/schema.md`** — new § Topic Hierarchy: a topic may declare
  `part-of:: [[parent-topic]]`; an atom declares exactly one **leaf**; ancestors
  derive. State the cycle prohibition and the one-leaf rule explicitly.
- **`_meta/schema.md`, M9 concurrency rule.** *(Added 2026-09-15; rides along
  because the schema is already open.)* State once, for every skill to point at:
  *a step may run in parallel iff its writes are keyed to a single source slug and
  its reads do not depend on vault state another concurrent run is writing.*
  Trial 2 has 12 papers to extract, so fanning out is the obvious move, and the
  failure it prevents is a silently wrong `confidence:`. The deep-extract half is
  in Stage 5.
- **`_templates/topic-concept.md`** — two-hop rollup: direct members plus members
  of child topics. **Verify this renders in Obsidian before tagging.** Dataview
  fails silently, and M17 exists because nobody had looked.
- **`lint.sh`** — scope 6d (`:379-388`) to leaf topics, so a parent with children
  is exempt; extend 7a (`:397-409`) to topic files' own `part-of::` targets, which
  today neither lint nor `memex-reconcile` checks (`memex-reconcile/SKILL.md:43`
  greps `atoms/` only); add cycle detection; warn when an atom names a non-leaf.
- **`skills/memex-reconcile/SKILL.md`** — Pass 1 greps `topics/` as well as `atoms/`.
- **`_meta/index.md`** — a topic-tree query.
- **M21 two independent fixes.** `memex-compose` step 2 falls back to atoms
  wikilinked from the topic body when `part-of::` membership is empty, and states
  which basis it used — it correctly refused the vault's richest node, which had
  deliberately opted out of membership. `memex-search` steps 1–2 stop flowing
  top-down from `topics/`, which returns every atom for every query; the documented
  entry point is dead weight.
- **D3** — reverse `skills/memex-init/SKILL.md:338` ("don't seed more than one
  topic"). The scaffold creates **topics only**, never atom stubs: a topic asserts
  no evidence, so nothing can be over-confident or orphaned. This is a doctrine
  change; record it as such.

Done 2026-09-15 — `d6b8426`. What differs from the list above, with the numbers
that show it:

- **Only concept maps form the tree** (user decision). Projects and research
  questions sit outside it, and an atom's membership of them stays additive, so an
  atom on one leaf concept map plus a project is legal.
- **Lint.** 6d exempts a concept map with children; 7a also checks topics' own
  `part-of::` (target exists, only concept maps name a parent, the parent is a
  concept map); 7f flags two parents and cycles; 7g flags an atom on a non-leaf or
  on two concept maps. `part-of::` inside fenced code is ignored, as Dataview
  ignores it: the shipped `getting-started.md` has a fenced
  `part-of:: [[getting-started]]` example that first read as a self-cycle. A
  hierarchy fixture reports exactly its pre-written expectations; fork and template
  output are unchanged (fork re-run after the restore: exit 0, 4 warnings, 365
  quotes).
- **Render check passed** in the fork's Obsidian (checked by the user). A temporary
  `tractography-methods` concept map under `brain-connectivity`, with 8 of the 22
  atoms moved to it: `brain-connectivity` Core Concepts **14**, "Via sub-topics"
  one group, `tractography-methods`, **8**; `tractography-methods` Core Concepts
  **8**. 14 + 8 = 22, the filesystem count. Lint in that state exempted the parent
  from 6d and raised 7g on the 14 atoms left on the root. Fork restored.
- **`_meta/index.md`** gives Concept Maps a Parent column, sorted by parent, rather
  than a separate tree query.
- **D3** as planned; `memex-init` copies the template's Dataview blocks instead of
  its own hand-typed stub, which had drifted from the template. **M21** as planned.
- **Stage 2's deferred topic-emerge re-run is not done here.** The fork is still
  flat — `brain-connectivity` has no children — so its part-of candidate is
  whole-vault by construction and a re-run would reproduce Stage 2. D2 shrinks
  part-of candidates only on a vault that has a tree; trial 2, seeded by the new
  `memex-init`, is the first. Carried to trial 2.
- **Missed:** `memex-topic-emerge` Step 7 writes the finding 7g now raises.
  Added to Stage 5.

---

## Stage 5 — the remaining verdict fixes *(done)*

| Skill | Fix |
|---|---|
| **`memex-connect`** | **Worst defect found.** Discovery (`SKILL.md:30`) uses `grep -rL` against bare field names the template ships *empty on every note*, so it returns only `.gitkeep` and reports "nothing to process" on every vault ever created from the template. Match populated fields (`^supports:: *\[\[`), and decouple wiring state from `stage:` per finding 2 |
| `memex-save` | Medium heuristic knows no publishers — every journal domain falls through to `web`. Video branch cannot fill its own `channel:`. No candidate gating at all |
| `memex-tend` | Drop or back the section-7 routing row (M12); order topic-emerge before trust-audit, not after |
| `memex-log-query` | Medium filter cannot work — 0 of 23 entries carry a medium. Either write it at log time or drop the filter; the stage half duplicates lint and loses |
| `memex-candidates` | Writer list omits `memex-deep-extract`; the candidate format nests YAML in YAML and says so nowhere |
| `memex-refactor` | Its split trigger cannot fire (M11c). S2 predates the evidence layer: a split silently invalidates the extracts' `## Promotion Log` rows, which is finding 13's unverified-edit problem at its most damaging |
| `memex-init` | Drops the `reviewed:` field its own template ships; still duplicates `domain.md` vocabulary (finding 1) |
| `memex-ingest` | Has a candidate type its workflow never produces, so supporting an existing atom is evidentially silent until back-wired |
| `memex-stale` | Check 4's recommendation routes into an operation nothing has designed for `medium: code` (M8) — say so rather than recommending it |
| `memex-deep-extract` | *(Added 2026-09-15.)* Three things trial 2 will otherwise re-find. **(1) Sanction what mode B already does:** once claims are promoted, mode B sets `stage: processed` and fills `## Summary` / `## Key Points` — mode A's one-file rule stands, and the source template's placeholder already names this skill as a writer. **(2) Mode B candidate gating:** a batched up-front confirmation is allowed, but candidates are still written — approval and crash recovery are different properties, and mode B is the longest write sequence in the vault. **(3) `## Concurrency`**, pointing at the Stage 4 schema rule: mode A parallel-safe with log appends lifted to a coordinator; mode B never; candidate session ids derived from the worker, not the wall clock. M11(b) is already in Stage 2 |
| `memex-topic-emerge` | *(Added 2026-09-15; missed in Stage 4.)* Step 7 appends `part-of::` to every covered atom not already pointing at the new topic, so an atom already on a concept map gets a second one — lint 7g. Under D2 the new map is either a leaf the atom moves to (replace the atom's link) or a parent of the atom's current leaf (write the topic's own `part-of::`, leave the atom alone). The part-of chain signal still pools every atom that names a root |

`memex-glossary`, `memex-meeting`, `memex-review`, `memex-trust-audit` and
`memex-topic-init` need no changes. M7 is closed: the glossary is a **disjoint
set**, not a lossy view of `atoms/`, and retiring it would have deleted the only
place those four terms can live.

Done 2026-09-15 — `9470a70`. Each row was re-read against the skill and the fork's
per-skill campaign commit before editing. What differs from the table, with the
numbers that show it:

- **`memex-connect`.** The campaign re-run (fork `8405fcb`) found two faults, not one.
  The bare-field-name query returns only `.gitkeep`, and outbound fields alone miss
  papers that atoms cite, because deep-extract never writes back onto the source.
  Discovery now requires no outbound relation *and* no inbound link from `atoms/` or
  `extracts/`, whatever the stage; step 9 says stage records reading, not wiring.
  Fork: `crane` (`read`, cited only by a project and a research note) and the video
  (`unread`). Fresh clone: the new query reports no source notes; the old one returns
  five `.gitkeep` files.
- **`memex-save`.** The paper row gains 16 publisher and index domains plus a
  DOI-in-path rule. Against the fork's 21 URLs it reproduces 20 media and moves
  Moon et al. `web` → `paper`, the one filed wrong on purpose. The video channel comes
  from YouTube's oEmbed `author_name`, verified on the fork's video. Vimeo's endpoint
  404'd on the one test URL, so it is not documented. Adds one create candidate, and a
  declared-medium rule: the template declares no `code`, and lint checks folders, not
  `medium:` values.
- **`memex-tend`.** The M12 half was done in Stage 2. topic-emerge and review move to
  step 5, before trust-audit (topic-scoped) and conflicts (cross-topic pairs).
- **`memex-log-query` takes neither option in the table.** 1 of 36 fork log headers
  carries a medium (`memex-save` writes `saved`), so the medium filter now resolves
  `url::` to the source note's `medium:` rather than changing eleven writers' formats.
  The stage cross-check is dropped in favour of lint 6, stale Check 2 and connect
  step 1.
- **`memex-candidates`.**
  - The writer list now names seven skills.
  - Step 4 documents the two-frontmatter split. Tested: a naive split drops the
    note's own frontmatter.
  - New `change: replace` modify candidate, added to `schema.md` § Candidate
    Lifecycle for topic-emerge's moves.
- **`memex-refactor`.** S6b and M6b append a Promotion Log row for every
  block-anchored citation a child atom takes. Fixture: a child citing `^c01` gets a
  12g warning without the row and none with it.
- **`memex-init`.** `reviewed:` is restored. Q2 and Q5 read `domain.md` instead of
  reciting it, and Q2 offers `code`.
- **`memex-ingest`.** The campaign's reading was right (fork `8d86fe1`): the unused
  candidate type is the atom back-wire. New step 5b writes `cites::` onto existing
  atoms linked with `supports::`, `introduces::` or `demonstrates::`, and asks about
  confidence as a separate question. Skeptical links are not backing.
- **`memex-stale`.** Check 4 lists `medium: code` apart, with no route. Fork: 5 code
  sources, 2 prose.
- **`memex-deep-extract`.** The table's first premise was wrong: the skill never told
  mode B to set stage or fill Summary — the trial operator did it anyway (§ Deviations).
  - New mode B step 7 sanctions it: `stage: processed` is asked; Summary and Key Points
    are drafted only where they are empty, as candidates. The source template's
    placeholder now names this skill.
  - New § Candidate gating in mode B (a batched confirmation is allowed; candidates
    are still required) and § Concurrency, pointing at the schema.
  - **Also found:** the Promotion Log example used `→`, but 12g parses `->` only, and
    all 288 fork rows use `->`. A run that followed the skill literally would have
    raised one 12g warning per promoted citation.
- **`memex-topic-emerge`.**
  - Step 7 is a three-way rule — append, replace, or ask — and never writes a second
    concept map.
  - New Sub-topic option.
  - Step 6 builds topics from the template (both Dataview blocks, `reviewed:`).
  - **Part-of chains count only targets with no topic file**, which fixes Stage 2's
    whole-vault absorption directly: both fork targets exist, so the fork yields no
    part-of candidate, and a fixture with three atoms naming a missing target yields
    one. The Stage 4 note's re-run on a real tree still belongs to trial 2.
- README's trigger rows for log-query and stale no longer advertise removed behaviour.

Lint: template exit 0; fork output identical to post-Stage-4 (exit 0, 4 warnings, 365
quotes). Skill evals were not touched (out of scope, § Two repos); `memex-ingest`
eval 3 links to existing atoms, so step 5b now applies to it.

---

## Stage 6 — `memex-seed`, the one new skill *(done)*

The corpus is already fetched, normalized and validated with a manifest, so the
missing path is not `memex-bulk-save` as specified (URL list → fetch) and not
`memex-save --batch` (whose whole design is fetch-and-ask-per-URL). It is:
**manifest + archives → source notes → topic scaffold → hand off.**

Input: a manifest path. `~/Projects/memex-seed-corpus/manifest.json` is the
reference shape. *(Corrected 2026-09-17: the real keys are branch, title, doi,
year, venue, authors, surnames, route, zotero_key, pdf, overlap_with_trial1,
slug, archive, archive_bytes, version, retrieval_note, validate_pass and
validate_detail — nineteen, not the eleven listed here before, and there is no
`validation` key. A second "archive directory" input is a footgun: `archive`
values already resolve against the manifest's own directory, so derive it with
`dirname`.)*

1. **Validate** — required keys present, every archive exists and passes the
   Stage-3 `validate-archive.sh`, **run at seed time**; report overrides
   explicitly rather than silently. Do not trust the manifest's own verdict.
   *(Corrected: that verdict is `validate_pass` + `validate_detail`, not
   `validation`, and it is **`false` on 4 of 12 rows** rather than null — a
   snapshot of the retired pre-M18 validator, whose `FAIL` tokens no longer
   exist. The current validator passes all 12. The prediction that "after Stage 3
   all 12 should pass with no override" was right; the field name and value were
   not.)*
2. **Independence report (M15)** — across the batch *and* against existing
   `sources/`; print the independent-unit count and refuse to proceed quietly
   when two documents are one unit. Trial 1 got 5 units from 16 documents because
   the saves were correlated by construction, and nothing warned. *(Corrected:
   **not** "pairwise surname intersection". `lint.sh:281-426` computes connected
   components of a shares-a-person-key-or-cites relation, and dependence is
   transitive — an A–B–C author chain is one unit and no pairwise test finds it.
   The two rules agree on this corpus, where all 66 pairs are disjoint, and
   diverge the moment they are used on anything else.)*
3. **Topic scaffold (D3/D2)** — propose the tree from the manifest's `branch`
   field and `domain.md`'s tag vocabulary; topics only, parents wired with
   `part-of::`. *(Clarified: `domain.md` has no branch vocabulary and will not get
   one. `branch` is routing input for the question round and never lands on a
   note; the mapped topic slug does.)*
4. **One shared question round** — default tags, stage, branch→topic map, with
   per-row override. Not N rounds.
5. **Write** — N source notes (`medium: paper`, `raw::` → `.archive/`,
   `stage: unread`) and **one** grouped log entry. The manifest's `version` is
   free text (`arXiv:2201.11941v2 (preprint, 2023-06-26)`); carry it into the
   provenance comment above `raw::`, not into a field — M6's `version:` field does
   not exist in RC-2. *(Added: this step also has to **copy the archives into the
   vault and normalize them**, before the note that names them. `.archive/` and
   `_meta/candidates/` are both gitignored and so absent from the fresh clone seed
   runs on, and `lint.sh:694` FAILs on a `raw::` naming a missing file. The spec
   said where `raw::` points and never said how the file got there.)*
6. **Hand off** — "N sources seeded across K topics, M independent units; run
   `memex-deep-extract` mode A."

**Candidate-gate the whole batch under one session id.** This is the longest
write sequence in the vault and therefore the one most likely to be interrupted —
the same argument that decides mode B's gating in Stage 5. *(Added: gating cannot
cover the `_meta/log.md` append. No skill gates the log and `memex-candidates`
never writes one, so a run that dies after the notes leaves a complete-looking
vault with no history — and lint exits 0 on it, so nothing catches it. The skill
logs before reporting and documents the manual recovery.)*

Non-goals, stated in the skill so it does not drift: no fetching, no atom
creation, no graph wiring, no confidence assignment.

Done 2026-09-17 — `018af64`, with the schema amendment in `18153c6` and the
registration in `9b6fd10`. Decisions taken while writing it:

- **`year:` became `published:` vault-wide**, variable precision (`YYYY`,
  `YYYY-MM`, `YYYY-MM-DD`), its own commit. `year:` could only hold the coarsest
  of the three, so `memex-connect` reading a full arXiv submission date had
  nowhere to put it. Padding a partial date is forbidden: `2012-01-01` for a paper
  known only to be from 2012 is a fabricated day that reads as a measured one.
  `year:` was required by schema but **never checked by lint**, so nothing flags a
  note left on the old field — grepped instead. Touches `schema.md`,
  `source-digital.md`, `okf-alignment.md` and the `memex-save` /
  `memex-ingest` / `memex-connect` field lists.
- **A truncated `authors` is recovered from the archive head.** Exactly **one** of
  the twelve rows is truncated (`2012-cammoun`, `["Leila Cammoun", "et al."]`
  against nine `surnames`), and the full byline with given names is in the file
  seed already copies — a local read, not a fetch. This matters because `et al.`
  yields no person key, so the row would have entered every future independence
  check with one author instead of nine. The recovered byline includes
  **`Kim Q. Do`** — the exact name `lint.sh:291` cites for keying on first initial
  rather than bare surname.
- **Source filenames take today's date; archives keep the corpus slug.**
  `lint.sh:494` FAILs without a full `YYYY-MM-DD-` prefix and the manifest carries
  only a year, so a publication-dated filename would need a fabricated month and
  day. The archive keeps its own name so the file that was validated is the file
  that is named. The two differ on purpose and `raw::` is the link.
- **Provenance is a labelled multi-line HTML comment**, single colons, `version`
  last. Single colons because `lint.sh:909` scans body lines after the second
  `---` against `^[a-z][a-z-]*::`, so a `doi::` line would be an unknown-relation
  warning the skill created. `version` last because it is the one free-text value
  and may contain a colon, comma or parentheses, so it needs the position with no
  delimiter after it.
- **Manifest reading is a three-tier probe** — `jq`, else `python3`, else read it
  with the Read tool — all emitting one TSV, so one loop is authored. `jq` appears
  nowhere in this repo and no skill uses `python3`; the vault's zero-dependency
  guarantee stays literally true and tier 3 is stated to be legitimate rather than
  degraded.
- Registered in the four README surfaces, `schema.md` § Workflow Stages,
  `memex-candidates` (producer list **and** its frontmatter description, which
  enumerates producers separately and drives triggering), and `memex-tend`'s
  never-invokes list. Skill count 20 → 21 in `README.md` and the CHANGELOG's
  Unreleased entry. **The two "20 skills" lines inside the released `[1.0.0-rc.1]`
  section were left at 20** — they record what that tag shipped, and it did ship
  20.

§ Verification, run against a `/tmp` clone plus the corpus, fork never touched:

- Baseline clone — lint exit 0, `Concept maps: 1`, `Independent units: 0 of 0`,
  and neither `.archive/` nor `_meta/candidates/` present. That is the state the
  skill has to handle.
- Pre-flight — **12 PASS, 0 REJECT, 0 exit-2** against the manifest's claimed four
  failures. The instruction to ignore `validate_pass` is load-bearing, not
  cautious.
- Independence — **12 units of 12, 0 unchecked, no shared-key pair.**
- Seeded clone — lint **exit 0**, `Sources (paper): 12`,
  `Independent units: 12 of 12 sources`, `Concept maps: 4`, `Atoms: 0`, and **12
  warnings, every one section 6a inbox-only**. No other warning class appeared, so
  no unknown tag, no leaked `key::`, no naming failure, no dangling `raw::`.
- Structural — 12 notes, 12 archives, exactly one `raw::` per note and every
  target resolving, no `status:`, no `year:` residue, `reviewed:` on all three new
  topics, `part-of::` on both leaves and empty on the root, one
  `skill:: memex-seed` log line, `_meta/candidates/` empty, all 12 copied archives
  still passing the validator, and `normalize.sh --in-place` a diff-clean no-op.
- **Interruption drill** — killed after 6 of 12 notes: 6 notes, 12 archives
  (orphan archives are harmless, as the skill says), 6 candidates under one
  session id, **0 log entries, and lint exits 0 on that state** — which is
  precisely why the gap needed documenting rather than describing. Applying the
  candidates through `memex-candidates`' first-two-`---` split recovered all six
  with their own frontmatter intact and reached the same 12/12/4 shape.
- **Re-run drill** — matching the manifest by `doi` finds all **12 already
  present**; matching by slug finds **0 of 12** and would have re-seeded the whole
  corpus, because a filename carries the date of the run that wrote it. This is
  why the re-run guard specifies `doi`.

Not carried into `§ Not in RC-2` because nothing new was deferred; the log-append
gap is documented inside the skill, where a resumed session will actually read it.

---

## Stage 7 — conceptual comparison with claude-obsidian *(done)*

*(Added 2026-09-15, at the user's request.)* `claude-obsidian`
(<https://github.com/AgriciDaniel/claude-obsidian>) is a widely used vault-plus-skills
system that does the same job as memex with a different design. Before the tag,
decide which differences are gaps worth closing here. Compare organization,
evidence model and write safety; do not count features. The stage reads their
repo and writes one document. No code is ported in this stage.

**Pin it.** Compare against `32ac5a0` (v2.2.0, committed 2026-09-10), cloned to
`/tmp`, and record that commit in the output. The project moves fast, and a
verdict against a later release is a different verdict.

**Dimensions.** The claude-obsidian column comes from a first read of their tree
on 2026-09-15. Verify every cell before relying on it, and add any dimension the
read turns up.

| Dimension | claude-obsidian | memex |
|---|---|---|
| Product vs vault | Plugin checkout kept separate from the user's vault. The vault is picked by env var, `.claude-obsidian.json`, or one initialized ancestor; if none is certain, nothing is written | The template is the vault; forks carry the code; `MEMEX_VAULT` |
| Note ontology | `wiki/` concepts, entities, sources, questions, comparisons; `overview.md`; `hot.md` | atoms, sources, extracts, topics (concept / project / research), glossary |
| Filing methodology | Selectable modes (generic, LYT, PARA, Zettelkasten) plus domain scaffold profiles | One schema, `domain.md` vocabulary, the D2 topic tree |
| Evidence | Content-addressed raw copies. JSON source and claim ledgers, kept apart from the notes, record authority, freshness, `independence_key`, support, contradiction, confidence and review state | Archived source. Extracts hold `^cNN` quoted claims, which lint checks against the archive. Atoms `cites::` claim anchors. Confidence comes from independent units. `verified:` |
| Write safety | Plan, then an approved SHA-256, then apply. Transactions and a lock. Workers return drafts; one orchestrator applies them | Candidate files with interactive confirmation; the M9 concurrency rule |
| Enforcement | Python package, JSON contracts, tests, CI | `lint.sh` plus skill prose; fixtures diffed by hand |
| Retrieval and session context | BM25 with contextual prefixes and optional rerank; `hot.md` recent-context cache; `wiki-fold` log rollups | `memex-search` over atoms; `log.md` and `memex-log-query` |
| Obsidian surfaces | Bases, Canvas, CSS snippet | Dataview inline fields and queries |
| Hosts | Claude Code, Codex, Gemini, OpenCode, Cursor, Windsurf | Claude Code |
| Egress | `autoresearch` (bounded web research), `defuddle`, explicit network consent | `memex-save`, `pdf-clean.sh`, `validate-archive.sh`; Stage 6 seed fetches nothing |

**Method.** For each difference:
1. Name the problem their design solves.
2. Check whether memex has that problem, with evidence: a trial-1 finding, a
   roadmap M-number, a Stage 2–6 result, or a failure you can demonstrate. "They
   have it" is not evidence.
3. Give one verdict.

Then run the comparison the other way: what memex has that they lack (quote
grounding checked per claim, a topic tree, …). That is positioning, not work, but
it shows which of memex's costs buy something.

**Verdicts.**
- **Adopt in RC-2.** memex has the problem, and the fix can be verified before
  Stage 8. It gets its own commit and re-runs the § Verification checks of every
  stage it touches.
- **Roadmap.** The gap is real but too large, or needs a trial to justify it. It
  gets a § Not in RC-2 row now and goes into the roadmap in Stage 8.
- **Decline.** memex does not have the problem, or the design conflicts with a
  memex principle; name the principle.

**Guard.** Some verdicts would change the architecture: a Python runtime, a
ledger store that replaces fields in the notes, a separate product and vault, or
more hosts. Record those as Roadmap and put them to the user. They are not RC-2
work, however strong the case.

**Output:** `_meta/comparison-claude-obsidian.md`, an infrastructure doc like
this one. It records the pinned commit, the verified table, and a verdict with
evidence for every difference. Principle 4 applies: every difference needs a
verdict before Stage 8, or trial 2 will re-report it as new.

**Result (2026-09-17).** `_meta/comparison-claude-obsidian.md`, 515 lines, pinned
at `32ac5a02c4e082e4a5628ca810776375e134708e`. Fifteen differences, fifteen
verdicts: **3 Adopt, 7 Roadmap, 5 Decline.** Five cells of the dimension table
above were wrong or incomplete and are corrected in the output's own
§ Corrections rather than here, since that is the file Stage 8 and trial 2 read.

*The correction that mattered most:* their `independence_key` is **declared**, not
derived. `ledgers.py:797` computes connected components by union-find over the
declared key, the canonical origin URL and the payload SHA-256 — structurally the
same algorithm as `lint.sh:281-426`, arrived at independently, with different
inputs. And it binds in exactly one place (`ledgers.py:1130`, high-risk accepted
claims needing two sources), where memex applies its count to every atom.

**The three adoptions, all in `lint.sh`, all against demonstrated failures:**

1. **7h — dangling relation target.** Until rc.2 a link was resolved only for
   `part-of::` (7a) and for a *block*-anchored `cites::` (12e). Demonstrated:
   `cites:: [[ghost]]` and `cites:: [[ghost#Summary]]` each linted clean at exit 0
   **and silenced the section 4 orphan warning**, because 6b counts `cites::[[`
   without resolving it — so a fabricated citation read as evidence and suppressed
   the check that would have caught the atom. Only `confidence: high` caught it, via
   section 8. 7h resolves every field on every layer against one new `ANY_PATH`
   table; `part-of::` and `#^` links are excluded so 7a and 12e keep their own,
   better-worded findings.
2. **2b — two sources at one URL.** Demonstrated: two notes with an identical
   `url:` and no `authors:` lint clean and report `2 of 2 sources … unchecked`,
   inflating the number section 8 reads. Three capture skills had three different
   guards and none was in the oracle.
3. **2c — a credential in a saved URL.** Demonstrated: `?access_token=SECRET123`
   committed to a tracked `sources/` note at exit 0, with zero matches for
   `token|credential|secret|api_key` anywhere in `lint.sh` or the capture skills.
   Key vocabulary ported from their `url_safety.py`, not invented.

`memex-reconcile` gained **Pass 2** so 7h's findings have an owner; `_meta/schema.md`
gained § **Source URLs** so 2b and 2c have a rule, per this vault's own standard
that a check needs a rule and a field with a writer needs a check.

**Two architectural questions are recorded, not decided** (the stage's Guard): a
transaction runtime, which would put Python in a tree that is deliberately bash +
awk/sed/grep; and `AGENTS.md`-style multi-host support, which is cheaper before 21
skills accumulate host-specific prose than after. Both are in the output's § To put
to the user.

**The largest asymmetry runs the other way.** memex checks a claim's quote against
the archived bytes (§ 12, a FAIL); grepping their v2.2.0 for verbatim-quote
verification returns instructions only. Their `ledgers.py` verifies that a claim's
*anchor resolves* — never what it points at. Their apparatus is better; memex's
evidence checking is better. The three adoptions are precisely where memex's own
checking had a hole their linter happened to cover.

---

## Stage 8 — docs and release *(done)*

- Port the fork's `_meta/roadmap.md` (98 KB, carries M11–M22, the rewritten M7 and
  the amended corpus spec) over this repo's 57 KB copy; mark each finding applied,
  and each § Not in RC-2 item as deferred with its reason. Skills already cite
  roadmap M8, M11, M13, M14 and M21, and this repo's copy stops at M5: after the
  port, grep `roadmap M[0-9]+` in `skills/` and confirm every number exists.
- Ship `_meta/skill-evaluation.md` as an **empty scaffold** with its header and
  usage note. Every fork should keep one; trial-1's evidence stays in the fork.
- **Consolidate the findings convention, before the tag.** *(Added 2026-09-17, at
  the user's request, after Stage 7's verdict list made the scheme's cost
  visible.)* The port classifies all 35 findings as applied or deferred anyway, so
  renumbering is marginal work on top of work already required.

  What is wrong with the current scheme, so the replacement is judged against
  something concrete:
  1. **Six prefixes** — `L S E P M O` — whose meanings appear nowhere near the
     labels. They are historical revision markers, not categories.
  2. **`M` spans two tiers.** M1–M16 are Tier 3, M17–M22 are Tier 4. The prefix
     does not give the tier and the tier does not bound the number.
  3. **Numbers are chronological by discovery, not priority.** M20 is a parser bug
     that shipped in `rc.1`; M4 is a nice-to-have. M20 sorts last.
  4. **Ad-hoc sub-letters** (M11a, M11c, M6b) with no rule for when one exists.
  5. **No per-finding status.** Status lives in prose across § Summary Verdict,
     § Implementation Order, § Where to Start Next and § Phase Detail, so the
     findings list cannot answer "what is open?".
  6. **No way to merge.** Stage 7's item 4 *is* M6 + M19 and the scheme has no
     mechanism to say so.

  *Why before the tag rather than after.* The `v1.0.0` gate is "a trial that
  surfaces nothing new worth fixing", and trial 2 reads this file to decide what
  counts as new. A roadmap whose open set cannot be read makes that gate
  unreliable — the same failure mode as `rc.1`'s too-weak criterion, one level up.

  *Scope is deliberately undecided.* Whether applied findings keep a row or
  collapse into a short "Applied in rc.2" list is decided **after** the port has
  produced a real open/closed count, not against the current estimate (well under
  half of 35 open; a consolidated list plausibly 12–18 rows). Put it to the user
  then.

  *Cost, measured.* 16 citation sites across 9 files: `_meta/lint.sh` ×6,
  `skills/memex-stale` ×3, and one each in `_meta/schema.md`,
  `_meta/validate-archive.sh`, `memex-compose`, `memex-conflicts`,
  `memex-reconcile`, `memex-search`, `memex-topic-emerge`. Rewrite them in the same
  commit as the renumber, then re-grep to confirm every cited label resolves.

- Carry Stage 7's **Roadmap** verdicts into the ported roadmap, each pointing at
  `_meta/comparison-claude-obsidian.md`. **Record them; do not schedule them.**
  *(User, 2026-09-17: the seven additions are to be evaluated alongside other
  pending plans once RC-2 is finished.)* So each lands as a row in whatever scheme
  the consolidation settles on, carrying its evidence and its verdict, marked
  pending evaluation — not slotted into § Implementation Order and not given a
  priority. Two of the seven are cross-references rather than new items: Stage 7's
  source-version finding **is** M6 + M19, and gains only the "record the archive
  hash at capture" slice.
- `CHANGELOG.md` — an RC-2 entry naming the schema amendment, the Stage 7
  adoptions, and the findings-convention consolidation.
- `VERSION` → `1.0.0-rc.2`; tag `v1.0.0-rc.2`.
- README — the hierarchy, `memex-seed`, and the skill count 20 → 21.
- **Rewrite § Release Status's criterion.** This repo's copy still reads "the four
  verification-debt rows exercised against a real vault, and any bugs that
  surfaces fixed" — which `rc.1` met on the rows and still shipped twelve
  findings and a parser bug. The fork's roadmap already carries the replacement:
  **a full trial against this tag that surfaces nothing new worth fixing.** The
  roadmap port brings it; confirm it landed. Record the debt rows as discharged
  and demoted.

Tagging `rc.2` does not promote anything. `v1.0.0` waits on a *clean* trial, and
a trial that finds something means `rc.3`.

**"Stage 8 closes" means the tag exists**, with the roadmap ported, consolidated
and readable, and every Stage 7 verdict recorded. It does not mean any Stage 7
Roadmap item has been scheduled, costed or built.

**Result (2026-09-17).** Tagged `v1.0.0-rc.2`.

*The port.* `_meta/roadmap.md` went 991 → 1,952 lines carrying M6–M22 across, and
all 35 findings got a status marker: **25 Applied, 13 Deferred, 2 Partially
applied, 1 Open, 1 Closed, 1 Accepted** — 43 rows once Stage 7's eight were added.
Three stale claims were corrected in the port rather than carried forward, the
material one being § The RC-2 seed corpus, which described a manifest key that does
not exist (`validation`, null) and four validator failures a re-run does not
reproduce (the key is `validate_pass`, and the current validator returns 12 PASS).

*The consolidation.* The scope question was deferred to this point by the user and
answered with the real count in hand: **split into two files.** `_meta/roadmap.md`
keeps open work — sixteen `R` rows, 997 lines. `_meta/roadmap-applied.md` takes the
25 applied findings with their full arguments, the seven completed phases and the
retired verification-debt rows — 1,151 lines. Eighteen live rows became sixteen
because `M6`, `M19` and comparison verdict 1 were one problem stated three times;
`R2` merges them and keeps all three statements.

Two deliberate inconsistencies, both cheaper than the alternative. **Applied labels
were not renamed** — nine of the ten labels cited from code are applied ones, and
`lint.sh` cites `M11a`, `M11c`, `M16`, `M18` and `M20` in comments that explain why
the code is shaped as it is, so renaming would have meant editing sixteen sites to
point at entries saying less than the comments already do. **Bare labels in prose
still mean the old numbering**, because both files argue by cross-reference and
rewriting those sentences would have meant re-editing arguments to change a name.
Both headers state the rule. One citation did need updating: `memex-stale` cited
`roadmap M8` twice, now `R3`.

*What I got wrong.* I told the user the live file would land at roughly 600–700
lines. It is 997. § Phase Detail's completed phases and § Verification debt were
moved across for the same reason as the findings, which is what got it under 1,000
at all; the estimate did not account for § Release Status, § The RC-2 seed corpus
and `R2` being as long as they are.

*Fresh-fork test, on a `/tmp` clone of the tagged tree.* `VERSION` reads
`1.0.0-rc.2`; **lint exit 0 with 0 warnings** on zero notes; 21 skills, 8 templates,
`.claude/skills -> ../skills` intact. The shipped validator over the corpus:
**12 PASS, 0 REJECT, 0 exit-2**. Seeded to the Stage 6 shape: **exit 0,
`Sources (paper): 12`, `Independent units: 12 of 12 sources`, `Concept maps: 4`,
`Atoms: 0`, 12 warnings and every one section 6a inbox-only.**

*Standing gates.* Against the fork: exit 0, 4 warnings, **365 quotes verified** —
unchanged through every RC-2 stage. The fork's only dirty file is
`.obsidian/workspace.json`, per-machine UI state this work never wrote.

*Not done, deliberately.* `_meta/rc-2-plan.md` is **not** deleted. Its
§ Verification is what trial 2 checks the tag against, so it outlives the tag by one
step; the roadmap header now says so. And none of `R8`–`R14` is scheduled — the user
evaluates them alongside other pending plans now that RC-2 is finished.

---

## Not in RC-2

*(Added 2026-09-15.)* Every known finding that Stages 1–8 do not schedule, with
the reason. **Before logging a trial-2 finding as new, check it here.** A trial-2
re-occurrence of anything below is a known issue, not a new finding — unless
trial 2 shows it is worse than recorded, which is new.

| Item | Why it waits |
|---|---|
| Finding 13, skill half — post-write assertions in every writing skill | Cross-cutting across every skill that edits an existing file. The Stage 3 lint cross-check covers the most damaging case (Promotion Log) as a standing check |
| M6 / finding 9 — `version:` field and `memex-deep-extract-reconcile` | Depends on finding 5's `fetch-fulltext.sh` and on M19's normalised comparison. The corpus carries **one** preprint (Cliff, arXiv v2) — enough to observe the provenance path, not to exercise a version model |
| M10 / finding 15 — Zotero as first retrieval tier | Seed consumes pre-retrieved archives, so retrieval is off the trial-2 path. When built: query the local HTTP API, never `zotero-cli search` (M10 amendment) |
| Finding 4 — `resolve-citation.sh` | Capture-side; seed takes metadata from the manifest |
| Finding 5 — `fetch-fulltext.sh` | Retrieval-side; same reason as M10 |
| Finding 6 — `repo-meta.sh` | `medium: code` only; the corpus is all `medium: paper` |
| Finding 8 — `.archive/` gitignored, grounding not reproducible from a clone | Documentation caveat; trial 2 grounds against local archives. Wants a sentence in `schema.md` § Extract Claims when next open |
| Deviation — `memex-connect` "process notes one at a time", batched analysis instead | Not observed to cause harm; per-note candidates and writes were kept. Revisit if trial 2 re-hits it |
| Deviation — `memex-save` step 5a reactions prompt, skipped after two | `memex-save` is off the seed path; candidate for opt-in when `memex-save` is next revised |
| Open question 4 — `topics/research/` vs `topics/projects/` as distinct node types | Untriggered by any observation |
| M3, M4, M8, Phases 5/8/9 | Already deferred in the roadmap |
| M22 — graph labels are filenames | Accepted, no action (roadmap recommendation 3) |
| Lint § 8d `body > 100 lines` on sources — the same unreachable line count M11(c) fixed in 6c | Sources are long-wrapped too, so 8d silently never fires; it produced no false signal in trial 1. Fix the way 6c was when next open *(added Stage 3)* |
| Lint § 7c 18-month freshness is a temporal threshold, M11(a)'s class | Cannot fire on a vault younger than 18 months, so trial 2 cannot exercise it *(added Stage 3)* |
| Lint § 4 orphan check runs `grep -r` per atom — mildly superlinear | 0.22 s → 1.65 s at 5× the fork; not dominant. Revisit near 200 sources *(added Stage 3)* |
| `authors:` as "Last, First" or a flow list wrapped across lines is misparsed | The manifest and the skills write "First Last" on one line *(added Stage 3)* |
| `warn()`/`error()` use `echo -e`, so a backslash in quoted text is interpreted | Cosmetic; seen only in a synthetic quote *(added Stage 3)* |
| `stage: unread` as a reader-facing flag in memex-compose, -search, -topic-init, -review | Finding 11 changed the evidence test; these label workflow state for a reader, which `unread` still does honestly *(added Stage 3)* |
| `validate-archive.sh` holes: snippets + full reference list pass; superscript citations invisible; IEEE abstract + references rejection rests on a synthetic page | Recorded in the script header; no real page of either kind exists to test *(added Stage 3)* |
| Candidate filenames: `schema.md` says `YYYY-MM-DD-HHMMSS-…`, `memex-ingest` says `YYYYMMDD-HHMMSS-…` | Nothing parses the name; `memex-candidates` groups by `session:` *(added Stage 5)* |
| `memex-save` has no verified channel route for Vimeo | The one test URL 404'd; the trial's only video is YouTube, whose oEmbed route is verified *(added Stage 5)* |

Resolved elsewhere, listed so nothing looks missing: finding 1 → fixed, reaches
here via Stage 1, residue in Stage 5 `memex-init`; 2 → Stage 5 `memex-connect`;
3 and open question 3 → Stage 6; 7 → Stage 3; 10 → Stage 3 guard; 11 → Stages 3
and 5; 12 and open question 5 → M7 closed; 14 / M9 → Stages 4 and 5; open
question 1 → Stage 5 `memex-connect`; open question 2 → answered in the fork's
record. **Fork-only, before trial 2:** re-run `memex-trust-audit` on
`bundle-segmentation`, still `confidence: low` though now medium-eligible.

---

## Verification

**Template, after every stage:** `bash _meta/lint.sh` exits 0 on this repo's zero
notes. **Against the fork, after every stage that touches lint or a
content-reading skill:** `bash _meta/lint.sh ~/Projects/memex` exits 0 and section
12 still reports **365 quotes verified or more, never fewer**. Any drop means a fix
broke grounding.

**Per stage, the specific number that proves it** (run from this repo against the
fork unless noted):

- Stage 2 — topic-emerge (`MEMEX_VAULT=~/Projects/memex`) reports **7 clusters at
  0.50** (was 1 blob); conflicts reports **2 of 13** unacknowledged, not 13 of 13.
  Lint on this repo's zero notes still passes with M11(c)'s median undefined.
- Stage 3 — the M16 commit alone reproduces
  `~/Projects/memex-seed-corpus/lint-baseline-rc1.txt` exactly, modulo timing.
  After the section-8 and finding-11 commits, the diff against that baseline is
  only the intended removals: section 8 stops flagging `structural-core`,
  `bundle-segmentation` and the other Hagmann/Cammoun and same-group pairs.
  `time bash _meta/lint.sh ~/Projects/memex` drops from 16 s toward ~1 s. All 12
  corpus archives pass `validate-archive.sh` with no manual override (corpus
  only, no fork).
- Stage 4 — **in the fork's Obsidian**, with the two files copied across:
  `brain-connectivity`'s rollup renders and its count equals direct members plus
  child members, computed from the filesystem first. A broken Dataview query and a
  genuinely empty topic both render as nothing, so check a populated one alongside.
  Restore the fork afterwards.
- Stage 5 — the `memex-connect` proof needs both halves: discovery returns the
  right set on the fork **and** returns "nothing to process" for the right reason
  on a fresh clone of this repo.
- Stage 6 — on a `/tmp` clone plus the corpus, never the fork: the pre-flight
  validator loop reports **12 PASS, 0 REJECT** against the manifest's claimed four
  failures; the seed reports **12 independent units of 12, 0 unchecked**; and lint
  on the seeded clone exits 0 with `Independent units: 12 of 12 sources` and
  **12 warnings, all section 6a inbox-only** — any other warning class is a
  finding. Two drills carry their own numbers: killed after 6 notes the vault has
  6 notes, 6 candidates under one session id and **0 log entries while lint still
  exits 0**; and a re-run matched by `doi` finds **12 already present** where a
  slug match finds **0 of 12**.
- Stage 7 — every difference in `_meta/comparison-claude-obsidian.md` has exactly
  one verdict with its evidence. Each Adopt names its commit and passes the
  checks for the stages it touched, and each Roadmap has a § Not in RC-2 row.
  *Achieved:* 15 verdicts (3/7/5). Template lint **exit 0, 0 warnings**. Against
  the fork, before and after the three checks: **identical output** — the same 4
  pre-existing warnings, **365 quotes verified** either way, and **191 relation
  targets resolved with no findings**, at a cost of 13.45 s → 13.71 s (+1.9%). The
  Stage 6 post-conditions were rebuilt from the manifest and re-linted under the
  new checks: **exit 0, `Sources (paper): 12`, `Independent units: 12 of 12
  sources`, `Concept maps: 4`, 12 warnings, all section 6a inbox-only** — the three
  additions fire on nothing seed emits. Each check was also exercised against its
  own positive and negative cases, including ten realistic URLs where only the four
  credential-bearing ones warn (`?v=`, a DOI, an arXiv id and `?sortkey=` stay
  clean).

**Fresh-fork test before tagging:** clone this repo to `/tmp`, run
`_meta/lint.sh` (must pass with zero notes), run `memex-init`, then run
`memex-seed` against the 12-document corpus. This is a smoke test of the seed
path, not the trial — it proves `rc.2` is *tag-able*, nothing more.

**The trial is separate, and it is what the tag is for.** Run RC-2 the way the
campaign was run: a real reading pass over all 12 documents, every skill
exercised, findings appended to the fork's `_meta/skill-evaluation.md` in the
same observed → root-cause → proposal form, each checked first against § Not in
RC-2. Keep the verdict rubric — *ran to completion? what artifact? would the vault
be worse without it?* — so trials stay comparable. `v1.0.0` is warranted only when
that pass produces **zero new findings**; any finding is an `rc.3` entry, not a
v1.0.0 caveat.

**Port discipline:** the Stage 1 diff is reviewed path by path against the
exclusion list above. A fork's `domain.md` reaching the template is the one
mistake that would be invisible until someone else forked it.

---

## Trial 2 setup *(decided 2026-09-17)*

**Target: the `v1.0.0-rc.2` tag, which was moved to the head carrying `R9` and
`R14`.** The rule above — any change after the tag is an `rc.3` entry — was written
for changes a trial could measure. These two are a test harness and a pre-write
guard: they change how reliably the trial is measured, not what it measures. The
tag had not been pushed, so moving it cost nothing downstream, and `rc.2` now
means *the tree trial 2 runs against*. `CHANGELOG.md` and § Release Status both
record the move rather than leaving the tag's target unexplained.

**Fork: fresh, at its own path.** `~/Projects/memex-trial2`, cloned from this
repository at the tag. Not a branch of the trial-1 fork, for two mechanical
reasons, either sufficient on its own:

1. `.archive/` and `_meta/candidates/` are gitignored, so they do not switch with
   a branch. A "fresh" branch inside `~/Projects/memex` would inherit trial 1's
   nine archives, and lint § 12 would ground trial-2 quotes against trial-1 files
   — the one check whose whole value is that it cannot be satisfied by accident.
2. The trial-1 fork has **no shared history** with this template. Its root commit
   is `5e1dd42 chore: fork memex-vault template v1.0.0-rc.1`, a squashed copy, so
   there is no `rc.2` to branch from there without grafting unrelated histories.

The trial-1 fork therefore stays exactly as it is — 22 atoms, 11 papers, 8
extracts, 365 grounded quotes — which is also what makes it the baseline trial 2
is compared against. It is read-only for the duration.

Bootstrap:

```bash
git clone -b rc-2 --single-branch \
    /home/bcmcpher/Projects/claude/memex-vault ~/Projects/memex-trial2
cd ~/Projects/memex-trial2
git checkout v1.0.0-rc.2          # detached; memex-init makes the fork's own root
bash _meta/lint.sh                # must be exit 0 on zero notes
bash _meta/test-lint.sh           # 8/8, before the instrument is trusted
```

Then `memex-init` for the domain, `memex-seed` against
`~/Projects/memex-seed-corpus/manifest.json`, and the reading pass.

**One carried item is trial-1-fork-only:** the `memex-trust-audit` re-run on
`bundle-segmentation`, which is still `confidence: low` while now medium-eligible.
That note does not exist in a fresh fork, so either re-run it in `~/Projects/memex`
before freezing that fork, or accept that trial 2 re-tests the recalibrated
threshold against new content instead. The second is the better test; the first is
the cheaper confirmation that M13's recalibration actually moved a real note.
