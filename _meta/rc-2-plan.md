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
started; the durable record is the other two, and Stage 7 ports the roadmap here.

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
   gate unreadable. Everything not scheduled in Stages 1–7 is in § Not in RC-2,
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

## Stage 3 — `lint.sh` correctness and cost

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

---

## Stage 4 — D2 hierarchy and D3 scaffold

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

---

## Stage 5 — the remaining verdict fixes

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

`memex-glossary`, `memex-meeting`, `memex-review`, `memex-trust-audit` and
`memex-topic-init` need no changes. M7 is closed: the glossary is a **disjoint
set**, not a lossy view of `atoms/`, and retiring it would have deleted the only
place those four terms can live.

---

## Stage 6 — `memex-seed`, the one new skill

The corpus is already fetched, normalized and validated with a manifest, so the
missing path is not `memex-bulk-save` as specified (URL list → fetch) and not
`memex-save --batch` (whose whole design is fetch-and-ask-per-URL). It is:
**manifest + archives → source notes → topic scaffold → hand off.**

Input: a manifest path and an archive directory
(`~/Projects/memex-seed-corpus/manifest.json` is the reference shape: branch,
title, doi, year, venue, authors, surnames, route, version, archive, validation).

1. **Validate** — required keys present, every archive exists and passes the
   Stage-3 `validate-archive.sh`, **run at seed time**; report overrides
   explicitly rather than silently. Do not trust the manifest's `validation`
   field: it is `null` on all 12 reference rows, although the corpus README
   records 4 archives failing the pre-M18 validator. After Stage 3 all 12 should
   pass with no override; if one does not, that is a finding, not an override.
2. **Independence report (M15)** — pairwise surname intersection across the batch
   *and* against existing `sources/`; print the independent-unit count and refuse
   to proceed quietly when two documents are one unit. Trial 1 got 5 units from 16
   documents because the saves were correlated by construction, and nothing warned.
3. **Topic scaffold (D3/D2)** — propose the tree from the manifest's `branch` field
   and `domain.md`'s tag vocabulary; topics only, parents wired with `part-of::`.
4. **One shared question round** — default tags, stage, branch→topic map, with
   per-row override. Not N rounds.
5. **Write** — N source notes (`medium: paper`, `raw::` → `.archive/`,
   `stage: unread`) and **one** grouped log entry. The manifest's `version` is
   free text (`arXiv:2201.11941v2 (preprint, 2023-06-26)`); carry it into the
   provenance comment above `raw::`, not into a field — M6's `version:` field does
   not exist in RC-2.
6. **Hand off** — "N sources seeded across K topics, M independent units; run
   `memex-deep-extract` mode A."

**Candidate-gate the whole batch under one session id.** This is the longest
write sequence in the vault and therefore the one most likely to be interrupted —
the same argument that decides mode B's gating in Stage 5.

Non-goals, stated in the skill so it does not drift: no fetching, no atom
creation, no graph wiring, no confidence assignment.

---

## Stage 7 — docs and release

- Port the fork's `_meta/roadmap.md` (98 KB, carries M11–M22, the rewritten M7 and
  the amended corpus spec) over this repo's 57 KB copy; mark each finding applied,
  and each § Not in RC-2 item as deferred with its reason.
- Ship `_meta/skill-evaluation.md` as an **empty scaffold** with its header and
  usage note. Every fork should keep one; trial-1's evidence stays in the fork.
- `CHANGELOG.md` — an RC-2 entry naming the schema amendment.
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

---

## Not in RC-2

*(Added 2026-09-15.)* Every known finding that Stages 1–7 do not schedule, with
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
