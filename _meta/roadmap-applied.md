# memex-vault Roadmap — Applied Findings

Split out of `_meta/roadmap.md` on 2026-09-17, at `v1.0.0-rc.2`. **This file is a
record, not a work list.** Every finding here shipped; nothing in it is
outstanding. `_meta/roadmap.md` holds the work that is still open, and is the file
to read if that is the question.

The split exists because 25 of the roadmap's 43 findings were applied, and they
were the bulk of its length — so the one question the file is opened to answer,
"what is still open?", was the hardest one to answer from it.

**Original labels are kept deliberately.** `_meta/lint.sh`, `skills/memex-stale`
and seven other files cite `M11a`, `M13`, `M14`, `M16`, `M18`, `M20`, `M21` and
`M8` in comments that explain why the code is shaped the way it is. Those
citations point at the argument, not at a status, so shortening these entries to
one line each would take away the thing that made them worth citing. Nine of the
ten cited labels are in this file.

Tier headings are the ones the findings were filed under. They record the order the
findings were *judged* in, and they are the reason a reader can still follow a
commit message from 2026-07. § From the trial-1 skill campaign is a new grouping
for four findings that were physically stranded after § Where to Start Next in the
fork's copy — a filing accident, not a tier.

Status markers read the same way here as in `_meta/roadmap.md`: *Applied* names
where the change shipped.

**A bare label inside prose is the original numbering.** Both files argue by
cross-reference — `M19` explains why `M6`'s proposed fix would misfire, `M11a`
points at `M8`, `E1` absorbed `P2` — and rewriting every one of those sentences
into `R` numbers would have meant re-editing arguments to change a name. So
`L S E P M O` labels appearing mid-sentence mean what they always meant.
`_meta/roadmap.md` § Renumbering says which of the two files each one now lives
in; the rule of thumb is that anything not in that table is applied.

---

## Applied findings

### Tier 0 — Correctness

**L1. `lint.sh` never exits non-zero, and `FAIL` is indistinguishable from `WARN`.** *Applied — `rc.1`, Phase 0.*
`warn()` and `error()` incremented the same `issues` counter, the script had no
`exit 1`, and the summary reported both as "issue(s) found … Review warnings
above." The two genuine-corruption checks — source naming and archive mismatch —
gated nothing. Any hook or CI job shelling out to lint passed silently.

*Status: fixed in Phase 0.*

**L2. `lint.sh` and `_meta/index.md` disagreed on what an orphan atom is.** *Applied — `rc.1`, Phase 0.*
Lint section 4 used "no `cites::` and no `covers::` backlink in `topics/`." The
index query used "no `cites::` and `length(file.inlinks) = 0`." A source's
`introduces:: [[atom]]` creates an inlink, so the index cleared atoms that lint
still flagged.

Worse, and latent: `_meta/log.md` records `atoms:: [[Atom A]], [[Atom B]]` on every
ingest. Those are real wikilinks. On the first real log entry, `file.inlinks`
would become non-zero for every atom ever ingested and the index's orphan query
would return nothing, permanently, with no error.

*Status: fixed in Phase 0. Both now use the single definition in `schema.md`,
which counts inbound links only from curated folders.*

### Tier 1 — Specialization blockers

**S1. Constitution conflated with configuration in `schema.md`.** *Applied — `rc.1`, Phase 2.* Universal rules
(node types, relation types, status lifecycles) sit alongside domain-configurable
content (tag vocabulary). A historian forking this finds ML tags baked into the
constitution.

*Fix:* split into `_meta/schema.md` (constitution) + `_meta/domain.md` (tag vocab,
source subtypes, domain name). Lint reads tags from the domain config.

*Status: fixed in Phase 2.* `_meta/domain.md` holds the domain name, three tag
groups, the `medium:` vocabulary, and the folder→`type:` table; `_meta/lint.sh`
sections 10 and 11 read both from it. `README.md` § Specializing This Template is
the fork guide.

**S3. No specialization guide or onboarding skill.** *Applied — `rc.1`, Phase 6 (`memex-init`).* No "how to make this yours"
workflow. *Fix:* `memex-init` interactive skill.

*Status: fixed in Phase 6*, which also found the reason a fork actually broke and
the finding never named: 18 skills hard-coding the template author's absolute vault
path, on 54 lines. The onboarding skill was the visible half of S3; path
portability was the half that made a fork unusable.

### Tier 2 — Structural

**E1. No evidence layer.** *Applied — `rc.1`, Phase 3 (the evidence layer).* Sources are stored at document granularity. Nothing
records what a source said sentence by sentence. Consequences: confidence cannot
be anchored to evidence (P2), conflicts can never be *proposed* — only audited
once a human has already written the link, `lint.sh`'s "under-extracted source"
warning has no remediation path, and `.archive/` has no consumer at all.

*Fix:* an `extracts/` node type plus a `memex-deep-extract` skill. Full design in
`_meta/deep-extract-design.md`.

*Status: fixed in Phase 3.* `extracts/` holds quote-grounded claims addressable by
block reference; `_meta/lint.sh` section 12 `grep -F`s every quote against the
normalized archive, so fabrication is mechanically detectable. `.archive/` finally
has a consumer.

**P1. `covers::` / `part-of::` duplication.** *Applied — `rc.1`, Phase 1.* Same membership data in two places;
`memex-reconcile` exists solely to sync them. Make `covers::` a Dataview-generated
view from `part-of::`.

*Status: fixed in Phase 1.*

**P2. Confidence is unanchored — fix rewritten.** *Applied — `rc.1`, Phase 3; the rubric was cheapest to write while the schema was open.* Previously: "add source-type
weighting to the rubric." That treats the symptom. Source *count* is the wrong
unit no matter how it is weighted — three blog posts agreeing is not `high`. With
E1, confidence derives from **independent claims across independent sources**,
with source-type weighting as a secondary term. **P2 now depends on E1.**

*Status: fixed in Phase 3*, not Phase 4 as scheduled — extracts made the rubric
expressible and the schema was already open. `_meta/schema.md` § Confidence
Values: the unit is independent claims across independent sources, source tiers
are inferred at audit time and never stored, and an atom with no extract is capped
at `medium`.

**P3. `related::` will erode typed-relation value.** *Applied — `rc.1`, Phase 1.* No skill audits or promotes
`related::` links. *Fix:* a promotion pass in `memex-reconcile` surfacing links
older than 30 days for typed-relation assignment.

*Status: fixed in Phase 1*, which absorbed it while rewriting the relation
handling. `skills/memex-reconcile/SKILL.md` runs the promotion pass; Phase 7
routes lint section 7's stale-`related::` findings to it. The status line was
never written at the time — recorded here 2026-08-25 during roadmap revision.

**P4. No orchestration layer — now more urgent.** *Applied — `rc.1`, Phase 7 (`memex-tend`).* 17 peer skills becomes 18.
Deep-extract is the most expensive skill in the vault and must never fire
automatically. Holding Anki to a `memex-compose` mode rather than a 19th skill is
a deliberate concession to this finding. *Fix:* `memex-tend`.

*Status: fixed in Phase 7*, at 20 skills rather than 18 — the count grew through
Phases 6 and 7 while the finding sat open, which is the finding proving itself.

### Tier 3 — Missing concepts

**M1. No atom voice/claim style spec — now a hard prerequisite.** *Applied — `rc.1`, Phase 2.* "Wikipedia-stub
granularity" is a length cue, not a style cue. Deep-extract mode B writes atom
`## Detail` prose at volume; without a style spec it writes it inconsistently, at
scale, into every atom it touches.

*Status: fixed in Phase 2.* `_meta/schema.md` § Atom Writing Style — five rules,
each tied to an existing lint signal so the spec is checkable rather than
aspirational.

**M2. No disambiguation policy — promoted to blocker.** *Applied — `rc.1`, Phase 2.* `attention` (cognitive
science) vs. `attention` (transformers) collide under kebab naming. A paper cut
while a human names atoms by hand. Deep-extract's resolution pass handles dozens
of concept mentions per document and will emit `ambiguous` rows on day one with no
rule to settle them. **Must land before or with E1.**

*Status: fixed in Phase 2.* `_meta/schema.md` § Disambiguation Policy. Homonyms
get suffixed slugs and the bare slug is left permanently unused; polysemous
senses stay one atom with per-sense `##` sections and section-anchored `cites::`.
The test is whether a change to one sense obliges a change to the other.

**M5. Source↔atom drift not audited — partially subsumed by E1.** *Applied — `rc.1`, Phase 3.* An extract's
claims make the source `supports::` ↔ atom `cites::` correspondence checkable
rather than merely assertable.

*Status: fixed in Phase 3*, to the extent E1 subsumes it. `memex-trust-audit`
gained an UNGROUNDED finding and an extract-existence check on G13; `memex-stale`
Check 4 surfaces processed sources that were never extracted.

**M9. A concurrency contract, so fan-out is planned rather than discovered.** *Applied — `rc.2` Stage 4, as `_meta/schema.md` § Concurrency. Every skill that can fan out now carries a `## Concurrency` section pointing at it.*
No skill states which of its steps may run simultaneously. The one nearby
sentence — deep-extract's "It never runs automatically or vault-wide" — governs
scope, not simultaneity: it forbids an unattended sweep and says nothing about
four attended runs at once. That gap matters now, because the retrieval backlog
is six papers and fanning out is the obvious response.

The rule that decides it, and that should live in `_meta/schema.md` so future
skills inherit it rather than re-deriving it:

> A step may run in parallel **iff** its writes are keyed to a single source slug
> and its reads do not depend on vault state another concurrent run is writing.

Under that rule deep-extract mode A qualifies — fetch, normalize, `.archive/`,
the extract file, the source's own `raw::` line, and concept resolution, which
reads `atoms/` precisely because mode A never writes `atoms/`. Mode B never
qualifies, and the disqualifying step is **confidence recomputation**, not file
contention. `_meta/schema.md` § Confidence Values counts independent claims
across independent sources, which is a whole-vault property; N concurrent
promoters each see the pre-fork state and each conclude they are adding an
independent source. Four of the six unread papers are Frässle et al. and share an
author, so that conclusion would be wrong in every run and wrong in a way each
run reports as correct. A wrong `confidence:` is the one vault output with no
second check on it, which is why this is worth fixing before it is needed rather
than after.

Two structural fixes fall out, both cheap: lift `_meta/log.md` appends out of the
workers so a coordinator writes all N serially — the alternative is a lost-update
race that finding 13 makes *silent* — and derive candidate session ids from the
worker, not the wall clock.

State the real payoff honestly in the skill: parallel mode A buys **context, not
wall time**. Each normalized archive runs 75-100 KB and the binding constraint is
fitting six of them in one window.

**M11. Five of five calibrated thresholds were wrong, and only two were a
size artifact.** *Applied — `rc.2` Stage 2, all four parts.* Every threshold the 2026-09-11 skill campaign exercised failed on
a real vault of 16 sources / 21 atoms. Separating them matters, because the
obvious diagnosis — "the vault is too small" — covers only two:

| Threshold | Size artifact? | At 200 sources |
|---|---|---|
| `memex-reconcile` Pass 2, `related::` stale after 30 days | yes, pure vault age | fires |
| `memex-stale` Check 1 (90d) and `lint.sh` section 3 (30d) | yes | fires |
| `lint.sh` 6c bloated atom, `lines > 100` | **no** — writing style | still never fires |
| `memex-topic-emerge` step 2 merge, `>= 50%` over `min()` | **no** — worse at scale | more tags, more bridges |
| `memex-conflicts` step 2 reciprocity on `limits::` | **no** — category error | 11 false flags becomes ~100 |

*Fix, four parts.* Skills and `lint.sh` cite these as `M11a`–`M11d`; the
parenthesised letters below are the same labels.

**(a) `M11a` — drop the temporal thresholds.** `memex-stale` Check 1 and `lint.sh`
section 3 ask the same question with different numbers (90 vs 30 days) and
neither produced a finding. Delete both. `memex-stale` Check 4 — processed but
never deep-extracted — carries no temporal term and was the only stale check that
fired, surfacing all five code repos; keep it, and see M8 for why its
recommendation is currently wrong for `medium: code`.

**(b) `M11b` — move `related::` typing to write time.** Dropping reconcile's 30-day rule
is right, but it removes the only thing suppressing a link the user deliberately
chose to **Keep** — the skill uses `updated:` for that, and the mechanism dies
with the threshold. Have `memex-deep-extract` mode B propose a typed relation when
it *writes* the link, while the reasoning is still at hand, and leave
`memex-reconcile` as an unthresholded manual backlog tool. This also closes the
three-way coverage hole recorded in M12.

**(c) `M11c` — replace the line count with body characters, computed against the
vault.**
Lines are a 1.5x spread across this vault's atoms (38-56) while body size is a
5.0x spread (1704-8528 characters, median 3816). The threshold `lines > 100` is
unreachable because the prose is one long-wrapped line per paragraph, and the
`cites::` line alone reaches 1756 characters — 21% of the largest body. Measure
**body characters excluding the `cites::` line**, and set the trigger at **2x the
vault's running median** rather than a constant, so it self-calibrates across
forks the way tag vocabulary already reads from `domain.md`.

**(d) `M11d` — replace `min()` with Jaccard in topic-emerge step 2.** See M13.

**M12. Nothing owns the untyped-relation problem.** *Applied — `rc.2` Stage 2, by dropping the promise rather than adding the check. With no age threshold a lint check could only flag every `related::` (78 in the fork), so `memex-tend`'s routing row is gone and reconcile's Keep is a `kept::` line in `_meta/log.md`.* The vault holds **78
`related::` links**, 21 of 21 atoms carry a populated `related::`, and
`contradicts::`, `supersedes::` and `defines::` are all **0**. That is precisely
the decay `memex-reconcile` Pass 2 exists to prevent. It is unreachable from
three directions at once:

1. `lint.sh` has **no stale-`related::` check at all** — section 7 is 7a/7c/7d/7e,
   there is no 7b, and the only `related` references in the script are the 6b/6c
   link counters;
2. therefore `memex-tend` can never route to it, although its routing table
   promises exactly that ("section 7 | orphan `part-of::`, stale `related::` |
   `memex-reconcile`") — the table names a signal the linter cannot emit;
3. and reconcile's own 30-day rule excludes every link in a young vault.

The only reachable path today is `memex-review` Lens C, which is scoped to one
topic per session and explicitly described as reflective rather than routine.

*Fix:* M11b at write time, plus either a lint check that can actually fire or
the removal of the routing-table row that promises one.

**M13. `memex-topic-emerge` destroys its own best signal before using it.** *Applied — `rc.2` Stage 2. The highest-leverage single fix the campaign found.* The
tag signal works: nine clusters pass the `>= 3` threshold on 21 atoms, and they
are the domain's real sub-divisions. Step 2 then merges any two candidates sharing
`>= 50%` of their atoms, scored as `|A n B| / min(|A|,|B|)` — an asymmetric
*containment* measure — and applies it transitively. This vault's two halves are
bridged by exactly two edges at exactly 0.50:

```
network-neuroscience n effective-connectivity = 2 / min(9,4) = 0.50
network-neuroscience n fmri                   = 2 / min(9,4) = 0.50
```

Two shared atoms each, and they chain a clean two-way split into one 21-atom blob.
Step 3 then reports that blob as a 100%-covered extension of the existing topic,
so the skill proposes nothing.

*Fix:* score with Jaccard, `|A n B| / |A u B|`. On identical data that yields
**7 clusters at threshold 0.50 and 5 at 0.30**, each a recognizable sub-domain.

*This is independent of the topic-hierarchy question and does not wait on it.* The
collapse happens in step 2, before step 3 consults any topic, so repairing
`part-of::` would not fix it. It fires in any vault whose atoms carry two to four
overlapping tags — here, 9 atoms carry 3 tags, 6 carry 4, 5 carry 2.

**M14. `memex-conflicts` cannot acknowledge a directional relation.** *Applied — `rc.2` Stage 2.* Step 2 calls
a conflict acknowledged only if the *target* atom carries a reciprocal skeptical
link. Across 13 conflict pairs on 9 atoms — 2 `challenges::`, 11 `limits::`, 0
`contradicts::`, 0 `refutes::` — **all five target atoms have empty conflict
fields, so 13 of 13 classify as unacknowledged.** That includes
`streamline-smoothing challenges:: tractography-filtering`, the most carefully
documented tension in the vault, which `memex-deep-extract` wrote with a full
in-group caveat about four shared authors.

Requiring reciprocity for `limits::` is a category error: the field means "A
defines boundary conditions where B breaks down", which is directional by
construction, and `B limits:: A` asserts something different and usually false. 11
of the 13 pairs are `limits::`. The rule also contradicts the skill's own field
table, which says of `refutes::` that "asymmetric is acceptable — one side may not
yet be updated".

*Fix:* exempt `limits::` from the reciprocity condition entirely; treat asymmetry
as acceptable for `challenges::` and `refutes::`; require reciprocity only for
`contradicts::`.

*Also:* the step 3 cross-topic check cannot fire while every atom declares the
same `part-of::` targets — a third skill degraded by the flat topic layer, after
`memex-search` step 2 and M13.

**M15. The useful unit of vault size is the independent author group, not the
source.** *Applied — `rc.2` Stage 3 (`lint.sh` counts independent units) and Stage 6 (`memex-seed` reports them before writing anything).* Fitted from the trial-1 vault — 21 atoms, 5 contributing units, mean
1.476 units per atom — **each independent unit covers about 20% of the concept
pool** in its span (p = 0.196, implied pool ~32 concepts). The model reproduces
what was measured: it predicts 38% of atoms medium-eligible and 8% high-eligible
against an observed 33% and 10%.

Projecting, for units landing in the same sub-domain:

| units | ~sources | atoms | `>= 2` units | `>= 3` units |
|---|---|---|---|---|
| 3 | 8 | 15 | 21% | 2% |
| **5** | **14** | **21** | **38%** | **8%** (trial 1) |
| 8 | 22 | 26 | 59% | 24% |
| 12 | 32 | 29 | 77% | 46% |
| 16 | 43 | 31 | 88% | 65% |

**The knee is 8-12 independent units, roughly 22-32 sources.** Below about 15
sources the topic layer cannot split and `confidence:` reads `low` almost
everywhere, which is exactly the state trial 1 reached at 16 sources. The
`skill-evaluation.md` note to "re-assess after ~50 sources" was directionally
right and slightly conservative.

**The regime matters more than the count.** Read *broadly*, atoms accumulate at
about 4.2 per unit and the high-eligible fraction stays pinned near 10%
indefinitely — more sources produce a larger graph, not a better one. Read
*deeply*, atoms saturate near 31 for a given span while confidence climbs
steeply. The target is therefore not a vault-wide total but **8-12 independent
units per sub-domain worth caring about**.

Trial 1 reached only 5 units from 16 sources because the saves were correlated by
construction: four Frassle papers plus the rDCM repo are one unit, each method
paper was saved alongside its own repository, and Hagmann and Cammoun share six
authors. Nothing warns about this at save time.

*Fix:* record independent-unit count alongside source count in `lint.sh`'s
summary block, and have `memex-save` / `memex-ingest` report the author overlap
against existing sources at capture time — "this shares 4 authors with
`<source>`; it will not raise confidence in any atom they both support." The
information is already in `authors:`.

**M16. The 200-source ceiling is a constant factor in `lint.sh`, not an
architectural limit.** *Applied — `rc.2` Stage 3. Lint on the reference vault went 22 s → under 1 s; a filename-to-path map replaced the per-citation `find`.* Lint takes **22 seconds** on 21 atoms, 16 sources and 365
quotes. The driver is `backing_sources()` (`lint.sh:105-126`), which runs a
`find` over `sources/` **per citation**, and is called roughly five times per atom
(`:423`, `:433`, `:492`, `:510`, `:521`). With 272 `cites::` targets across 21
atoms, that is about 1,360 `find`/`grep` subprocess pairs per run. At 200 sources
— extrapolating 1.3 atoms per source and 20 citations per atom — it becomes
roughly 26,000 calls, each scanning 200 files instead of 16: **15 to 25 minutes**.
The quality cost is indirect and severe: a linter that takes twenty minutes stops
being run, and it is the vault's only executable state oracle.

*Fix:* compute `backing_sources()` once per atom and reuse it across sections 7c,
7d and 8; replace the per-citation `find` with a filename-to-path map built once
at startup. A 20-50x constant-factor win puts 200 sources back under a minute and
moves the practical ceiling into the thousands.

*The genuinely architectural limit is the topic layer*, and it binds far earlier:
`lint.sh` section 6d already fires at 15 atoms per topic, which is about 12
sources, not 200.

### Tier 4 — Interoperability

**O1. `status:` carries four different vocabularies, and collides with OKF.** *Applied — `rc.1`, Phase 2.*
One key means `unread|read|processed` on a source, `unprocessed|processed` on a
meeting, `active|paused|complete|abandoned` on a project, and `stub|reviewed` in
the glossary. That overload is a smell on its own terms — the field is a
*pipeline stage*, not a document lifecycle. It is also the one place where an
outside reader gets a **wrong** answer rather than a missing one: OKF §5.4 defines
`status` as a closed `draft|stable|deprecated` lifecycle, so `abandoned` should
read as `deprecated` and `stub` as `draft`, and neither does.

*Fix:* rename to `stage:` in Phase 2. Leaving `status:` unused means OKF's
"absent ⇒ stable" default applies, which is safe. The exporter synthesises the
real value.

*Status: fixed in Phase 2.* The rename is total — templates, 13 skills, eval
fixtures, `_meta/index.md`, `_meta/lint.sh`, and the candidate frontmatter the
original scope list missed. Lint 11c fails on any in-vault `status:`, and 11b
validates each `stage:` against the vocabulary for its node type.

**O2. No node-type discriminator in frontmatter.** *Applied — `rc.1`, Phase 2.* The node type is currently
implicit in the folder, plus `topic-type:` on topics and `medium:` on sources.
Nothing states it directly, so the type is unavailable to any Dataview query that
spans folders, and unavailable to any consumer that is not walking the tree. It
is also OKF's single required field (§4.1), which no template satisfies.

*Fix:* add `type:` in Phase 2; retire `topic-type:`, which it subsumes exactly.

*Status: fixed in Phase 2.* `type:` is on all seven templates and enforced by
lint 11a against `_meta/domain.md` § OKF Types. `topic-type:` is gone. The
cross-folder query O2 asks for now works — see `_meta/index.md` § Provenance.

### From the trial-1 skill campaign

**M17. The Obsidian setup the README describes does not exist, and half the
graph was infrastructure.** *Applied — `rc.2` Stage 1 (the `.obsidian/` files and the README rewrite) and Stage 4.* Found while discharging the last verification-debt
row on 2026-09-11. Three separate defects, all fixed in the brain-connectivity
fork and back-ported here in `rc.2` Stage 1, and all of which every previous fork
would have hit:

- **README section 4 pointed at a menu that is not there.** It said
  `Settings → Graph view → Groups`. Obsidian has no graph section under Settings;
  the panel lives inside the graph pane, behind the sliders icon in its own
  top-left corner. The instruction was unfollowable as written.
- **`.obsidian/graph.json` shipped empty** — `search: ""`, `colorGroups: []`,
  `showOrphans: true` — so the "optional but recommended" colouring was a manual
  task every fork repeated by hand, which is the same argument `domain.md` settles
  for tag vocabulary. Now shipped configured.
- **Infrastructure outnumbered knowledge on the graph, 60 files to 49.**
  `app.json` `userIgnoreFilters` excluded only `.archive` and `_okf`; `skills/`
  (40 files), `_meta/` (10) and `_templates/` (8) rendered as a large
  disconnected cloud around the real graph. Fixed with a **graph filter**, not a
  global ignore, because those folders should stay searchable and openable — the
  two exclusion mechanisms are not interchangeable and the README did not
  distinguish them.

*Also fixed:* `_templates/topic-research.md` used `this.file.link` for its atoms
query but a Templater-baked `[[<% tp.file.title %>]]` for its sources query — an
inconsistency inside one file. It resolves at creation time, so nothing was
broken, but it is a literal snapshot that breaks on rename (Obsidian does not
rewrite links inside code blocks) and it cannot be verified by observation on a
vault where no source `supports::` a topic. Both the template and the one topic
created from it now use `this.file.link`; 9 of 9 dataview self-references in the
vault are consistent.

*Generalizable:* `.obsidian/` is configuration a fork should inherit, not
re-derive. Anything the README tells a human to click through once is a candidate
for shipping pre-configured.

**M18. `_meta/validate-archive.sh` rejects short-genre papers and misses
drop-cap headings — 4 false negatives in 12.** *Applied — `rc.2` Stage 1 (the script) and Stage 3 (its calibration table).* Measured while building the RC-2
corpus. Every one was verified by reading the archive; all four are correct full
text and the check is wrong.

| archive | check that failed | what it actually is |
|---|---|---|
| Daducci & Schiavi 2025 | 17.9 KB prose < 25 KB floor | genuine 4-page commentary, abstract + affiliations + references |
| Rheault et al. 2025 | 24.2 KB prose < 25 KB floor | genuine 5-page commentary, same |
| Shailja et al. 2023 | 1 distinct heading (< 2) | IEEE drop-caps: `pdftotext` renders them `I. I NTRODUCTION` |
| Runge 2018 | 1 distinct heading (< 2) | 97 KB prose, 113 paragraphs, full text |

Two independent defects.

**The 25 KB prose floor cannot distinguish a short paper from a landing page.**
The floor exists to catch the FiberNeAT trap — an IEEE abstract page that
returned ~22 KB and reported success (M10). A 4-page commentary is the same size.
This collides directly with the RC-2 corpus requirement for adversarial evidence:
**disagreement in this field lives in commentary and correspondence, which is
precisely the genre the floor rejects.** Aydogan et al. passed at 27.9 KB — the
genre straddles the threshold, so no single number separates them.

*Fix:* stop using length as the landing-page test and use **structure** instead.
A landing page has no references section, no numbered sections and no author
affiliations block; a 4-page commentary has all three. Those are cheap to detect
and they discriminate on the thing that actually differs.

**Heading detection breaks on PDF typography.** `pdftotext` renders a drop-cap
capital as a detached letter, so `INTRODUCTION` arrives as `I NTRODUCTION` and
the section-heading pattern misses it. Both failures here are this, in two
different publishers' layouts.

*Fix:* normalise `^([A-Z]) ([A-Z]{2,})` to `\1\2` in `pdf-clean.sh` before the
structure test runs, and count numbered section markers (`I.`, `1.`, `A.`) as
headings independently of their text.

**M20. `lint.sh`'s provenance parser read body prose as provenance, and shipped
that way because `verified:` had never been written.** *Applied — `rc.2` Stage 1. The one finding in this list that had already shipped broken in a tagged release.* Surfaced the first time any
atom carried a real sign-off, 2026-09-11.

Section 13b captured the block with:

```awk
/^verified:/{f=1;next} f&&/^[a-z]/{exit} f{print}
```

which terminates at the next top-level key but **not at the frontmatter fence**.
`verified:` is conventionally the last key in the block, so the parser ran
**21-33 lines into the note body** on all five signed-off atoms and treated prose
as provenance. In `method-validation-without-ground-truth` it lifted
`confounded by: resolution,` out of a sentence and reported `resolution,` as an
invalid actor string.

**Four of the five were silent purely by luck** — their prose contains no second
`by:` before the first lowercase-initial line. A universal parser bug with a
data-dependent symptom is the worst shape available: it looks like a content
problem in one file.

*Why it survived to a tagged release.* `verified:` was 0 of 21 atoms until this
session, and 0 in the template by construction, so section 13b had **never
executed against a populated block** — only against files that skip the key
entirely, where it correctly does nothing. No fixture could have caught it; it
needed a human sign-off to exist first. Section 13c inherits the same block and
would have read any `at: YYYY-MM-DD` in prose as a sign-off date. Section 13a is
safe only incidentally, because it `exit`s on the first match.

*Fixed* by terminating on `/^---$/` as well as `/^[a-z]/`, applied to all three
provenance parsers. Lint returns to 7 warnings and a full diff against the
morning baseline shows the only change is the three trust-audit upgrades clearing
section 8.

*Generalizable, and worth stating as a rule:* **every optional frontmatter block
is an unexecuted code path until something writes one.** `verified:` is the only
field in the schema whose writer requires a human, which is exactly why it was
the last to be exercised and the last to be checked. Audit the other optional
blocks against a populated example before the next tag.

**M21. The flat topic layer blinds `memex-compose` and `memex-search` from
opposite directions.** *Applied — `rc.2` Stage 4 (the D2 topic hierarchy) and Stage 6 (a seeded scaffold with two branches).* Both were run for the first time in the campaign and both
degraded, but not in the same way, and the pair is more informative than either
alone.

- **`memex-search` step 1-2** is specified to flow top-down, `topics/` → `atoms/`
  → `sources/`. Starting at `topics/concepts/` returns all 22 atoms for every
  query, so it narrows nothing and every useful query short-circuits to the atom
  layer or the grep fallback. The documented entry point is dead weight.
- **`memex-compose` step 1** refuses a topic with no `part-of::` members — and
  correctly refused `topics/research/method-to-crane-mapping.md`, the vault's
  richest node: a real research question, 7 cited sources, a ranked comparison
  table, and 7 atoms referenced inline in prose. Zero atoms declare membership,
  because on 2026-09-04 the node **deliberately opted out**, reasoning in its own
  body that a third `part-of::` target on atoms already declaring
  `brain-connectivity` and `crane-method-integration` would "make the derived
  lists identical everywhere and stop discriminating."

That reasoning was right, and it is the trap. **The one topic whose membership
would carry information has no members, and the topic whose membership carries
none composes fine.** `brain-connectivity` exported 22 atoms, 241 footnotes and
16 tensions without difficulty, while being the node `lint.sh` 6d has flagged as
undifferentiated since 2026-09-04.

*Fix, two parts.* The hierarchy amendment addresses the cause. Independently,
`memex-compose` step 2 should **fall back to atoms wikilinked from the topic
body** when `part-of::` membership is empty, and state which basis it used —
a topic that relates its atoms in prose is not an empty topic, and treating it as
one discards the most considered node in the vault.

---

## Completed phases

Moved here with the applied findings, for the same reason: they are a record of
work that shipped. `_meta/roadmap.md` § Phase Detail keeps the phases that have not
— Phase 5 (Anki, deferred), Phase 8 (OKF export, open) and Phase 9 (OKF import,
deferred) — and § Implementation Order keeps the full table, including these, so
the sequence is still readable in one place.

Phase numbers are **not** reassigned. They are cited across
`_meta/deep-extract-design.md`, `_meta/okf-alignment.md`, several skill files and
every commit message in the history.

### Phase 0 — Lint integrity *(complete)*

1. `_meta/lint.sh` — separate `fails` from `issues`; `exit 1` when `fails > 0`;
   summary distinguishes failures from warnings.
2. `_meta/lint.sh` section 4 — orphan check now counts inbound wikilinks from
   `sources/`, `atoms/`, `topics/`, and `glossary/`, replacing the `covers::`-only
   grep. This also survives Phase 1, which removes manually-written `covers::`.
3. `_meta/index.md` — both `file.inlinks` queries filter to the same four curated
   folders, so `_meta/log.md` links no longer suppress the orphan lists.
4. `_meta/schema.md` — the orphan definition is stated once, normatively.

**Verification:** `bash _meta/lint.sh; echo $?` → `0` on a clean vault. Introduce a
source file without a date prefix → prints `FAIL`, exits `1`.

### Phase 1 — `covers::` → Dataview migration *(complete)*

Make `covers::` auto-derived from `part-of::` on atoms. Single source of truth.

1. `_meta/schema.md` — remove `covers::` from the Topic → Atoms table and from
   Valid Relation Fields; note that topic membership is derived via Dataview.
2. `_templates/topic-{concept,research,project}.md` — replace the `covers::`
   placeholder with a Dataview block; Templater injects the topic title.
3. `topics/concepts/getting-started.md` — same substitution.
4. `skills/memex-topic-init/SKILL.md` and `skills/memex-topic-emerge/SKILL.md` —
   stop writing `covers::`; keep writing `part-of::` to atoms.
5. `skills/memex-reconcile/SKILL.md` — remove the `part-of::` ↔ `covers::` drift
   check; replace with an orphan-`part-of::` check (points at a non-existent
   topic). Add the `related::` promotion pass from Phase 4.
6. `_meta/lint.sh` — 6d now counts atoms by reverse `part-of::` lookup; 7a keeps
   only the dangling-topic half; 7b retired outright (a query cannot drift).
7. `README.md` — note `covers::` is derived, not written.

**The list above under-scoped the work.** `covers::` was *written* by three skills
but *read* by eight more, and the per-skill schema reference is duplicated 13
times. The full set that had to change:

8. `skills/*/references/vault-schema.md` — 13 identical copies, all carrying the
   retired `Topic → Atoms` table. Kept byte-identical after the edit.
9. Reading skills switched to reverse lookup
   (`grep -rlE "^part-of::.*\[\[<topic>\]\]" atoms/`): `memex-compose`,
   `memex-review`, `memex-conflicts`, `memex-stale`, `memex-trust-audit`,
   `memex-search`, `memex-connect`.
10. `skills/memex-refactor/SKILL.md` — split and merge no longer rewrite any topic
    file; they carry `part-of::` onto the new atoms instead.
11. `_meta/ccm-mapping.md`, `_meta/deep-extract-design.md` — stale references.

**Phase 4 item 2 is already done.** The `related::` promotion pass landed here, as
step 5 directed. Phase 4 keeps only the confidence rubric and the trust-audit
rebuild.

**Verification:** `grep -r "covers::" skills/ _templates/ topics/` returns only
Dataview query blocks and schema notes.

**Dependency created for Phase 8.** Dataview-derived membership is invisible
outside Obsidian, so a non-Obsidian consumer would see every topic as empty. The
exporter must materialize `covers` by scanning atoms' `part-of::` — the same
traversal, done deterministically in Python. No work in this phase; recorded so it
is not discovered late.

### Phase 2 — Schema split + atom style spec + disambiguation + OKF frontmatter *(complete)*

**Schema work (S1, M1, M2):**

1. `_meta/schema.md` — replace the Tags section with a pointer to `_meta/domain.md`; add **Atom Writing Style** (3–5
   rules: present tense, hedge single-source claims, use relations not inline
   prose, one claim per atom) and a **Disambiguation Policy** (suffixed slugs for
   true homonyms, polysemous sections for related senses).
2. `_meta/domain.md` — new. Sections: *Domain Name*, *Domain Tags*, *Type Tags*,
   *Stage Tags*, *Source Types*, *OKF Types*. Each is a fenced list parsed one
   entry per line, the same shape `schema.md` § Valid Relation Fields already
   uses and lint already knows how to read.
3. `_meta/lint.sh` — read tag vocabulary from `_meta/domain.md` (section 10) and
   the folder→`type:` table from it as well (section 11).
4. `README.md` — add a "Specializing This Template" section.

**OKF frontmatter (O1, O2).** Additive except one rename. Nothing here costs
Obsidian or Dataview anything, and each item pays for itself independent of OKF.

5. **Add `type:`** to all seven templates and to
   `topics/concepts/getting-started.md`. Values: `Source`, `Atom`,
   `Glossary Term`, `Concept Map`, `Project`, `Research Question`. `medium:`
   stays the source subtype, so no fact is duplicated. The mapping lives in
   `_meta/domain.md` under `okf_types` so a fork can rename types without
   touching the exporter.
6. **Retire `topic-type:`** — `type:` subsumes it exactly. Touches
   `_templates/topic-{concept,project,research}.md`,
   `topics/concepts/getting-started.md`, `memex-topic-init`, `memex-topic-emerge`,
   `_meta/schema.md`.
7. **Rename `status:` → `stage:`.** Values unchanged; only the key moves, so no
   behaviour changes anywhere. The widest blast radius in the roadmap, so scope it
   explicitly: 4 templates (`source-digital`, `source-meeting`, `topic-project`,
   `glossary`); 13 skills at ~49 lines total — `memex-compose`, `-connect`,
   `-glossary`, `-ingest`, `-log-query`, `-meeting`, `-refactor`, `-review`,
   `-save`, `-search`, `-stale`, `-topic-init`, `-trust-audit`; `_meta/index.md`
   (6 Dataview references); `_meta/lint.sh` (22 hits); `_meta/schema.md`
   §Status Values → §Stage Values; `README.md`; the `TABLE` columns in
   `_templates/topic-research.md` and `topics/concepts/getting-started.md`; and
   the eval fixtures under `memex-ingest/evals/` and `memex-search/evals/`.
8. **Add `description:`** — optional, one sentence, all seven templates. Not
   conformance-only: it feeds Phase 8's `index.md` generator *and* lets
   `_meta/index.md` carry a summary column, which it cannot today. The existing
   `## Summary` / `## Definition` / `## Overview` prose is the drafting cue.
9. **Define `generated:` and `verified:`** in `_meta/schema.md`, with OKF's actor
   convention (`<producer>/<version>`, `human:<id>`, `process:<id>`). Writing
   skills start emitting
   `generated: { by: memex-ingest/claude-opus-5, at: <date> }`. A real gain, not
   just conformance — `skill::` currently exists only in `_meta/log.md`, so
   per-note authorship is unrecoverable. `verified:` is **defined** here and
   **written** in Phase 4. State explicitly that `confidence:` and `verified:`
   are orthogonal: confidence measures evidence strength, verified records who
   confirmed it.
10. `_meta/lint.sh` — three new checks, as section 11: `type:` present and
    matching the folder's entry in `domain.md`; `stage:` value valid for the node
    type; `status:` **absent** in-vault, since it is the exporter's output field
    and hand-writing it would diverge. Section 2 also gained the topic
    required-field checks it never had — `title` on all three topic kinds,
    `stage` on projects, `question` on research.

**Verification:** the invariant is about *frontmatter*, so match line-initial
keys — prose that names the retired fields in order to explain the retirement is
expected and desirable:

```bash
grep -rn '^topic-type:' _templates/ skills/ topics/ sources/ atoms/ glossary/
grep -rn '^status:'     _templates/ skills/ topics/ sources/ atoms/ glossary/
grep -rn 'status *='    _meta/index.md _templates/ topics/
```

All three return zero. `bash _meta/lint.sh` exits `0`. A note with `type: Nonsense`, or one carrying
`status:`, prints `FAIL` and exits `1`. In Obsidian: every `_meta/index.md`
Dataview table still renders, now with a `description` column, and a note created
from each of the seven templates shows `type` and `stage` in the property editor.

**Scope corrections found during implementation.** The step list above missed
four things, all of them found by doing the work rather than by re-reading the
plan:

11. **`_meta/candidates/` also carried `status:`.** Step 7 enumerated templates,
    skills, lint, and index, but not the candidate frontmatter documented in
    `_meta/schema.md` § Candidate Lifecycle and emitted by `memex-ingest`,
    `-connect`, and `-glossary`. Renamed there too. Keeping it would have forced
    a folder carve-out in the new lint check and made "`status:` is the
    exporter's output field" false in one place; the invariant is now total.
12. **`_meta/index.md` had the same hyphen bug Phase 1 fixed.** The
    uncategorized-atoms query read `WHERE !part-of`, which Dataview parses as
    subtraction and which therefore matched nothing — a silent empty table, not
    an error. Now `WHERE !row["part-of"]`, matching the membership query.
    `topics/concepts/getting-started.md` also still told the reader to write
    `part-of:: [[Getting Started]]`, the frontmatter title rather than the
    filename, which would never resolve. Both are the Phase 1 failure class,
    missed because Phase 1 fixed the queries it touched and not the prose.
13. **`_meta/lint.sh` aborted silently on any missing field.** Eleven
    `var=$(grep … | head -1 | sed …)` assignments run under `set -euo pipefail`,
    so `grep` finding nothing returned 1 and killed the script mid-run — a
    truncated report and `exit 1` with no failure printed. Surfaced immediately
    by the new `type:` check, since a note missing `type:` is exactly the case.
    All eleven now end `|| true`. Latent since the script was written; harmless
    only because the vault has no notes yet.
14. **Citation counts counted the empty template line.** `_templates/atom.md`
    ships a bare `cites:: ` prompt, which Dataview reads as absent — section 4
    documents this and matches `^cites::\s*\[\[`, but sections 6c, 7d, 8a, 8c,
    and 8d used `grep -c "^cites::"`. Every freshly-created atom therefore drew
    two bogus "all cited sources are unread" warnings. All counts now require a
    populated field.
15. **Relation counts counted lines, not targets** *(found 2026-09-02, after
    `v1.0.0-rc.1`)*. Item 14's fix added `\[\[` to those greps but left them as
    `grep -c`, which counts matching *lines*. § Orphans blesses
    `introduces:: [[A]], [[B]]` on one line and calls it "expected and correct",
    so every threshold check read a well-linked field as a single connection.
    Two checks were wrong in opposite directions: **8d** flagged a source with
    four atoms on one `introduces::` line as *under-extracted* — nagging exactly
    the sources the vault wants — and **6c** could only fire on six separate
    `cites::` lines, which nothing writes, so it had never fired at all. Fixed
    with a `count_links()` helper beside `backing_sources()`, which already
    parsed per-target correctly; 6c, 8d, and 8e now use it. Thresholds unchanged.

Items 13, 14, and 15 are lint defects rather than Phase 2 work, filed here
because this phase is what exposed the family and because a lint that dies
partway cannot gate anything — which was Phase 0's entire point. Item 15 was
found later, while verifying that nothing in the vault enforces one atom per
source; nothing does, and the wording that suggested otherwise
(`memex-ingest` step 6, `getting-started.md`, and the "one concept per file"
line in `README.md` / § Node Types) was corrected in the same change.

### Phase 3 — Evidence layer *(complete)*

See `_meta/deep-extract-design.md`. Summary: a new `extracts/` node type, one file
per deep-extracted source, holding quote-grounded claims addressable by Obsidian
block reference. A `memex-deep-extract` skill with `extract` and `promote` modes.
A grounding check in `lint.sh` that `grep -F`s every claim's verbatim quote
against the normalized `.archive/` text — making fabrication mechanically
detectable, which is only meaningful because Phase 0 made `FAIL` a real gate.

*OKF addendum:* `extracts/` gets `type: Extract` and a `description:`, registered
in `_meta/domain.md` with the rest. Record in `deep-extract-design.md` that
extract claims map onto OKF §5.1 footnote-keyed per-claim attribution
(`[^source-id]` joined to `sources[].id`) — the planned block-reference addressing
is the same idea, and the exporter renders one as the other. No design change;
recorded so Phase 8 does not reinvent it.

#### Design calls made during implementation (2026-08-25, confirmed with the user)

Five conflicts between `deep-extract-design.md` and this roadmap, resolved before
building. All five are reflected in the code and docs.

> The canonical write-up is now `_meta/deep-extract-design.md` § Implementation
> decisions, which carries these five plus a sixth found while testing — the lint
> section 5 clone case below. The summaries here are kept because the *conflict*
> was between the two documents, and this is the other side of it.

1. **Archive normalization gets its own script.** `memex-ingest` already wrote
   `.archive/` files with no normalization, so any extract taken from an
   ingest-written archive would have thrown false grounding FAILs. New
   `_meta/normalize.sh` (bash/awk, deterministic, idempotent); *every* skill that
   writes an archive pipes through it. Rejected: having deep-extract normalize in
   place on first use, which would leave the guarantee dependent on which skill
   saved the file.
2. **Anki is deferred entirely to Phase 5.** The design doc's change list included
   `anki/.gitkeep`, the `.obsidian/app.json` exclusion, and the `memex-compose`
   render mode; the roadmap makes Anki its own phase. Roadmap wins — Phase 3
   touches nothing Anki-related.
3. **The confidence rubric (P2) landed here, not in Phase 4.** Extracts make it
   expressible, so it was written while the schema was open. **Phase 4 therefore
   shrinks to the `memex-trust-audit` rebuild** — `related::` promotion already
   landed in Phase 1, so that phase now has one item.
4. **`grounded:` and `source:` dropped from extract frontmatter.** `grounded: true`
   is a cached lint verdict stored in the file it judges: it goes stale, and a
   fabricating writer can simply assert it. `source:` was a third copy of a fact
   the filename and `extracted-from::` already carry. `medium:` was dropped on the
   same reasoning. `claims:` survives with a lint cross-check, because Dataview
   cannot count block ids.
5. **Extract filenames take an `ext-` prefix.** The design mandated mirroring the
   source filename *exactly*, which collides head-on with Phase 2's own
   Disambiguation Policy — Obsidian resolves wikilinks by filename, so every
   `cites:: [[<source-slug>]]` already on an atom would silently go ambiguous the
   moment its extract appeared. Confirmed in a fixture: two files, one name.
   `extracts/ext-<source-slug>.md`.

#### Defect found while implementing

**`_meta/lint.sh` section 5 failed every fresh clone.** `.archive/` is gitignored,
so a clone has none of it, and the archive-mismatch check FAILed on the first
`raw::` it met — the exact trap `deep-extract-design.md` argues the *grounding*
check must avoid, already live one section earlier since Phase 0. Now split: if
`.archive/` is absent entirely that is the clone case and SKIPs; a file missing
while the folder exists is a real mismatch and still FAILs. The gate is preserved
everywhere it means anything.

#### What shipped

Branch `phase-3-evidence-layer`, merged to `main`. `bash _meta/lint.sh` exits 0.

- `_meta/normalize.sh` — new. Idempotence and folding tested against hyphenated
  line breaks, soft hyphens, ligatures, smart quotes, nested lists, code fences.
- `_templates/extract.md`, `extracts/.gitkeep` — new.
- `_meta/domain.md` — `extracts|Extract` in the OKF Types table.
- `_meta/schema.md` — Extract node type; `extracted-from::` / `mentions::`
  (also added to Valid Relation Fields); block anchors on `cites::`; new
  § Extract Claims; **rewritten § Confidence Values** (independent-claims rubric,
  inferred source tiers, `medium` cap without extracts); Archive section rewritten
  around `normalize.sh`; `ext-` in Naming Conventions; orphan definition now names
  `extracts/` as non-curated.
- `_meta/lint.sh` — section 2 extract fields; **section 5 clone fix**; section 7e
  scans `extracts/`; **new section 12** (12a `extracted-from::` resolves + filename
  matches, 12b `claims:` cross-check + duplicate ids, 12c every claim has a quote,
  12d `grep -F` grounding with ellipsis hint, 12e dangling block anchors,
  12f `high` without block-anchored `cites::`); extracts in the summary counts.
  Verified in a fixture vault: positive grounds, fabricated quote FAILs with
  exit 1, absent `.archive/` SKIPs with exit 0, missing-file-in-present-folder
  FAILs, `claims:` drift and duplicate ids fire.
- `_meta/index.md` — `## Extracts`, "extracts with unpromoted claims", "processed
  sources with no extract"; `extracts` added to the provenance and missing-`type:`
  queries; a pointer to lint 12f where Dataview cannot see block subpaths.
- `skills/memex-deep-extract/SKILL.md` — new, both modes.
- `skills/*/references/vault-schema.md` — 14 copies, byte-identical (verified:
  one md5).
- `skills/memex-ingest/SKILL.md` — archives written through `normalize.sh`.
- `skills/memex-search/SKILL.md` — extracts as a gap-finding surface only.
- `skills/memex-trust-audit/SKILL.md` — UNGROUNDED finding, independence test,
  extract-existence check on G13.
- `skills/memex-stale/SKILL.md` — Check 4, processed sources never extracted.
- `README.md` — layer diagram, folder tree, node types, `ext-` rationale, skill
  lifecycle and reference table, graph colouring, archival section.
- `_meta/deep-extract-design.md` — corrected to match what shipped, with an
  § Implementation decisions section recording all six divergences, an § OKF
  correspondence section for Phase 8, and both Open questions resolved.

**Still unverified, carried forward from Phases 1–2:** no Dataview query in
`_meta/index.md` has ever been executed — no Obsidian here, and the vault has 0
atoms and 0 extracts. The three new extract queries use the `meta(l).path` inlinks
idiom already present in the file, but they are unrun. **This is the first thing
to check when the vault is next opened in Obsidian.**

### Phase 4 — `memex-trust-audit` rebuild *(complete)*

**This phase came down to one item.** Both of its original two landed early: the
confidence rubric was written in Phase 3, where extracts first made it
expressible, and the `related::` promotion pass went in with Phase 1's
`memex-reconcile` rewrite. What was left was the skill that consumes the rubric —
and, as it turned out, five lint checks that had quietly stopped agreeing with it.

1. ~~`_meta/schema.md` — confidence derives from independent claims across
   independent sources; source-type weighting (peer-reviewed > preprint > curated
   blog > unreviewed post) as a secondary term.~~ **Done in Phase 3**, as
   `_meta/schema.md` § Confidence Values. Source tiers are *inferred* at audit
   time rather than stored — see the OKF addendum below, which is why.
2. ~~`skills/memex-reconcile/SKILL.md` — `related::` promotion pass for links
   older than 30 days.~~ **Done in Phase 1.**
3. ~~`skills/memex-trust-audit/SKILL.md` — rebuild checks on the claim-count
   rubric, and become the writer of `verified:` entries
   (`{ by: human:<id>, at: <date> }` on human sign-off), using the field defined
   in Phase 2.~~ **Done.**

#### What shipped

- `skills/memex-trust-audit/SKILL.md` — rebuilt. The six-check threshold table is
  replaced by *gather evidence → compute justified confidence → compare to
  declared*: citations are split into claims and bare sources, every block anchor
  is resolved through its extract's `extracted-from::`, sources are grouped by
  the independence test, and tiers are inferred per group. Findings fall out of
  the comparison. New: CONTRADICTED, NEVER VERIFIED, STALE SIGN-OFF.
- **The sign-off pass is new** — step 7, and the vault's only writer of
  `verified:`. Its first rule is that the skill may never write an entry on its
  own judgement: `human:<id>` asserts a named person read the atom, and inferring
  that from an audit result forges a record about a human. Sign-off is asked
  separately from `confidence:`, offered only for atoms actually examined that
  session, and never bumps `updated:`.
- `_meta/schema.md` § `verified:` — three normative rules (append-only, does not
  touch `updated:`, asked separately from `confidence:`), plus the stale-sign-off
  definition. Propagated to all 14 `skills/*/references/vault-schema.md` copies
  (verified: one md5).
- `_meta/lint.sh` — new **section 13** (13a `generated:` shape and actor form,
  13b `verified:` list shape and `human:` requirement, 13c stale sign-off); new
  **8e**, `high` with a live `contradicts::`/`refutes::`, which is the rubric's
  third requirement for `high` and had gone unchecked since Phase 3.
- `_meta/index.md` — a stale-sign-off query beside the never-verified one.
- `README.md` — `verified:` semantics, skill map, and trigger table.

#### Defect found while implementing

**Four lint checks could not see through an extract citation.** 7c, 7d, 8b and 8c
each resolved `cites::` targets straight against `sources/`, which was correct
until Phase 3 made `cites:: [[ext-slug#^cNN]]` the *preferred* form for
well-grounded atoms. On any atom citing an extract they resolved nothing: 7d and
8c then reported "all cited sources are stage: unread" on atoms whose sources
were processed — a false positive aimed squarely at the best-cited notes in the
vault — while 7c and 8b silently under-reported. 8a had the mirror problem: it
counted `cites::` *lines*, so three anchors into one extract read as three
sources and let a `low`-grade atom sit at `high`.

All five now share one `backing_sources()` helper that resolves anchors through
`extracted-from::` and deduplicates. Independence is deliberately *not* tested
there — it is a judgement, `memex-trust-audit` owns it, and the lint count is
an upper bound that can only under-report.

**`lint.sh` could exit 1 without reaching a verdict.** An unguarded `grep` inside
a command substitution in the new section 13 tripped `pipefail` and `set -e`; the
script died mid-section and returned 1 — which since Phase 0 means "this vault
has a FAIL." A linter bug was indistinguishable from vault corruption, and the
fixture that caught it looked exactly like a genuine failure. Fixed, and guarded:
an early exit now returns **2** with a message saying it is a bug in the linter,
so exit 1 keeps meaning what Phase 0 made it mean.

*OKF addendum:* the source-type weighting in step 1 is this vault's credibility
signal. OKF §5.1 stores exactly that — objective per-source signals (`author`,
`usage_count`, `last_modified`) — and explicitly refuses to store a score, on the
grounds that a score is subjective, unportable, and goes stale. That is P2's own
conclusion reached independently, so name the frontmatter fields to match rather
than inventing parallel ones.

### Phase 6 — `memex-init` *(complete)*

Interactive one-time specialization skill. Five questions (domain name, source
types, projects?, research questions?, initial tags) → write `_meta/domain.md`,
create a first topic stub, scaffold `extracts/`, update `getting-started.md`,
log the run.

`anki/` was on that scaffold list until Phase 5 was deferred. Scaffolding a
folder for a feature that may never ship leaves every generated vault with an
empty directory nothing writes to — add it back if and when Phase 5 lands.

*Phase 3 addendum:* scaffolding `extracts/` is not just the folder. A generated
vault also needs `_templates/extract.md`, the `extracts|Extract` row in the
generated `_meta/domain.md` § OKF Types, and the **`ext-<source-slug>` naming
rule** stated in the onboarding text — the prefix exists to keep extracts from
colliding with their own sources under Obsidian's filename-based wikilink
resolution, so a fork that drops it breaks every `cites::` the first time an
extract appears. See `_meta/deep-extract-design.md` § Implementation decisions 5.

Constraints: does not delete unused folders, does not modify `schema.md`,
re-runnable without overwriting the topic stub.

*OKF addendum:* also scaffolds the `okf_types` block in the generated
`_meta/domain.md` and adds `_okf/` to Obsidian's excluded-files list (see the
warning in Phase 8). ~~creates `_okf/`~~ — **superseded during implementation**:
the exclusion is written, the folder is not. See *Decisions* below.

*Plugin addendum (audit, 2026-08-25):* the onboarding text must state the
corrected plugin contract, not the pre-Phase-4 one. **Dataview is the only hard
requirement**, and core **Bases** does not replace it — Bases reads YAML
frontmatter, while every typed relation in this schema is a Dataview inline field
in the note body. Core **Canvas** matters only if the fork keeps `canvas/`.
**Templater is optional**: the shipped templates use only `tp.date.now` and
`tp.file.title`, both of which have core-Templates equivalents, and the skills
replace the placeholders themselves rather than invoking either plugin.
`memex-init` must **not** tell a fork to install **Folder Notes** or **Graph
Analysis** — both were listed as required through Phase 4 with zero dependents
anywhere in `_meta/`, `_templates/`, or the skills, and Graph Analysis has had no
release since January 2022. A fork that installs the old list pays four plugin
dependencies for one real one. See `README.md` § Obsidian Plugins.


**What shipped.**

1. `skills/memex-init/SKILL.md` — five questions (domain name, source types,
   projects?, research questions?, initial tags), then: rewrite the four
   instance-specific fenced blocks of `_meta/domain.md` **in place**, scaffold one
   `sources/<medium>/` per declared type, seed one concept map, rewrite
   `getting-started.md`, add the `_okf` exclusion, run lint, log. No
   `references/` directory and no fifteenth `vault-schema.md` copy — the skill
   writes vocabulary, not typed nodes, and the sync burden is real.
2. **All 18 pre-existing skills made path-independent.** They hard-coded
   `/home/bcmcpher/Projects/claude/memex-vault` on 54 lines, so a fork's skills
   pointed at the template author's vault — the actual thing that broke a fork,
   and not on any list. Now `VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"`,
   with the header of each skill saying so. `README.md`'s "editing **one file**"
   promise is true as of this phase; it was not before.
3. `_meta/lint.sh` sections 1 and 2 read § Source Types from `_meta/domain.md`
   instead of the literal `web video paper docs meeting`. A fork adding
   `sources/hearing/` got **zero** filename or frontmatter checking, silently,
   while `README.md` claimed lint reads all vocabulary from `domain.md`. Two new
   WARNs close both halves of the mismatch: a declared type with no folder, and a
   folder under `sources/` that § Source Types never declares. Falls back to the
   shipped five if the block is missing, so a half-edited `domain.md` degrades to
   the old behaviour rather than checking nothing.
4. `topics/concepts/getting-started.md` — the "Creating a new source" list named
   five templates (`source-web`, `source-video`, `source-paper`, `source-docs`,
   `source-meeting`). Four of them have never existed: there are two source
   templates and `medium:` is per note. Fixed, since `memex-init` step 10 rewrites
   this section and would have propagated the error into every fork.
5. `_meta/domain.md` § Source Types — documents the contract lint now enforces,
   and records that **`meeting` is the one reserved medium name** (checked for
   `date:` rather than `url:`/`saved:`).

**Decisions.**

- **`_okf/` is not scaffolded, only excluded.** The roadmap said create it; that
  contradicts the reasoning used to drop `anki/` one commit earlier. The
  *exclusion* is what is ordering-sensitive — it has to exist before the first
  export, or every note appears twice in search and graph. The folder is the
  exporter's to create. Same argument, same answer, now applied consistently.
- **`memex-init` does not call `memex-topic-init`.** That skill's value is
  searching existing atoms and sources; a fresh fork has none, so it would run
  five searches over empty folders to produce the same stub. Delegation would cost
  tokens and return less.
- **Nothing is ever deleted.** A dropped source type keeps its folder and earns a
  WARN. Deleting an empty folder is free; deleting one that turned out to hold
  notes is not, and the skill cannot tell the difference under `.gitignore`.
- **`_meta/schema.md` is off limits**, stated twice in the skill. A fork that edits
  the constitution has forked the format, not the domain.

**Still unverified:** no fork has been run end to end. The skill's steps are
individually exercised — lint's new source-media path was fixture-tested against a
vault declaring `web`/`hearing` — but the five-question flow has never been walked
by a user. First real fork is the test.

### Phase 7 — `memex-tend` *(complete)*

Orchestration meta-skill. Sequences the maintenance skills after a batch ingest
and answers "what should I run now?" Must explicitly never auto-invoke
`memex-deep-extract`.

*OKF addendum:* sequences `memex-export` as a terminal step, and never before
`_meta/lint.sh` passes.

**What shipped.**

`skills/memex-tend/SKILL.md` — a router, not an author. It writes exactly one
thing, its own `_meta/log.md` entry; every vault change is made by the skill it
hands off to, under that skill's own confirmation rules.

1. **State comes from three executable sources**, not from `_meta/index.md`. The
   index is Dataview, which renders only inside Obsidian, and this skill runs where
   there is none. So: `_meta/lint.sh` for what is wrong, `_meta/candidates/` for
   what a previous session left unfinished, and `_meta/log.md` for when each skill
   last ran. One lint pass produces every signal, which is the efficiency argument
   for having an orchestrator at all — the alternative is five skills each scanning
   the vault to discover they have nothing to do.
2. **A routing table from lint section to skill**, covering all 13 sections.
   Findings with no skill are named as hand fixes rather than routed to a skill that
   cannot fix them — sections 1, 5, and 11 are mostly this.
3. **The order is a dependency chain, not a calendar.** `memex-candidates` first
   (unapplied proposals make every other skill read an incomplete vault), FAILs
   before any skill runs (a claim quoting text its source never contained makes
   trust-audit's evidence wrong, not merely incomplete), then connect → reconcile →
   trust-audit → conflicts → stale. Each step changes what the next one sees.
4. **Four modes**: triage (the default — report and stop), full pass, post-ingest,
   pre-share. Pre-share is the sequence `README.md` already recommended by hand.
5. **Re-lint after every writing skill**, and report the delta. A step that
   *increases* the finding count is a result, not an error: reconcile promoting
   `related::` to typed relations surfaces conflicts that were previously
   invisible.

**Decisions.**

- **Four skills are never invoked**, and the reasons differ. `memex-deep-extract` is
  the expensive one and the one lint 8 actively tempts an orchestrator toward — the
  under-extracted-source WARN is exactly the signal that would justify firing it, so
  the prohibition had to be written where that signal is routed, not only in a
  preamble. `memex-compose` is publishing, not maintenance. `memex-refactor` makes
  irreversible judgement calls about what a concept *is*. `memex-init` already ran.
- **Triage is the default mode.** "What should I run now?" is answered with a plan
  and a stop, not with a plan and a chain. The value of an orchestrator is deciding
  whether to spend the tokens, which it cannot do by spending them.
- **Proposing nothing is a valid outcome.** Skills whose lint sections are clean are
  marked skipped and not proposed. An eight-step plan on a healthy vault teaches the
  user to ignore the skill.

**Still unverified:** the routing table is written against lint's current 13
sections and was checked against real output on a fixture vault, but no tend pass
has been run on a vault with enough findings to exercise the ordering. The vault has
0 atoms.

---

## Verification debt — retired

The four rows below were `v1.0.0-rc.1`'s stated gate. All four are discharged, and
§ Release Status no longer refers to them: what replaced them is a standing
obligation rather than a checklist. Kept as the record of a retired gate.

Four things were built and proven only against fixtures, because this repository
is a template and ships with 0 atoms, 0 sources and 0 extracts by design. Every
check that needs content to act on could only be verified in a fork. The
brain-connectivity fork has now done that for all four.

| What | Since | Status |
|---|---|---|
| `memex-init`'s five-question flow | Phase 6 | **Discharged** 2026-09-03, `_meta/log.md` init entries |
| `memex-deep-extract` end to end | Phase 3 | **Discharged** 2026-09-04, 8 extracts, 365 quotes grounded |
| `memex-tend`'s ordering | Phase 7 | **Discharged** 2026-09-11, triage run in the skill campaign |
| Every Dataview query in `_meta/index.md` | Phases 1–2 | **Discharged** 2026-09-11, all 19 queries verified against precomputed counts |

**All four rows are discharged by the brain-connectivity fork**, the last on
2026-09-11. The Dataview row was verified by computing every query's expected row
count from the filesystem first and comparing: sources 16, atoms 21, extracts 8,
never-verified 21, and so on for all 19. The discriminating test for the silent
`row["part-of"]` failure (`_meta/schema.md:158-159`) is that `brain-connectivity`
returns 21 atoms and `crane-method-integration` returns 20 — a broken query and a
genuinely empty topic both render as nothing, so an empty topic proves nothing
unless a populated one renders alongside it.

**Discharging the rows turned out not to be what promotes the release at all.**
The exercise that discharged them surfaced M11-M22, which is why § Release Status
now asks for a trial that surfaces *nothing new* rather than for these four rows
plus a fix list. The rows did their job — they are what got a real vault in front
of the skills — and they are retired as a gate.

This is not a defect list. Fixture-testing caught two real bugs in Phase 6 that a
content-ful vault would have caught the same way. But no amount of it substitutes
for one pass over real notes.

*Status 2026-09-17.* That pass has now happened once, and the twelve findings it
returned are M11–M22. **The section is kept as a record of a retired gate, not as
outstanding work** — every row is discharged and § Release Status no longer refers
to them. What replaced the rows is a standing obligation rather than a checklist:
each RC gets a full trial, and a trial that finds something produces the next RC.
F3 is the same argument applied one level down — fixtures are not a substitute for
a real pass, and `lint.sh` still has neither.

---

## Where the rest went

| Status | Count | Labels | File |
|---|---:|---|---|
| Applied | 25 | this file | `_meta/roadmap-applied.md` |
| Open | 1 | `O3` → `R1` | `_meta/roadmap.md` |
| Deferred | 11 | `S2 M3 M4 M6 M8 F2`–`F8` → `R2`–`R14` | `_meta/roadmap.md` |
| Partially applied | 2 | `M10` → `R4`; `M19` merged into `R2` | `_meta/roadmap.md` |
| Closed | 1 | `M7` → `R15` | `_meta/roadmap.md` |
| Accepted | 1 | `M22` → `R16` | `_meta/roadmap.md` |

Eighteen live rows became sixteen `R` numbers because `M6`, `M19` and `F1` are one
finding described three times — a source has no version model, re-rendering is
indistinguishable from revision, and a content hash is what would tell them apart.
`_meta/roadmap.md` § Renumbering carries the full mapping.
