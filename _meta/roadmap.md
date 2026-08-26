# memex-vault Improvement Roadmap

Revised: 2026-08-25. Supersedes the 2026-07-09 revision, which superseded
2026-05-07.

Infrastructure doc — not a vault node. No frontmatter, and nothing should link to
it with a wikilink.

Companions: `_meta/deep-extract-design.md` holds the full design for Phase 3.
`_meta/okf-alignment.md` holds the full design for Phases 8–9, plus the
frontmatter changes they need from Phase 2.

---

## Summary Verdict

**Bones are excellent** — typed relations, candidate gating, schema-as-constitution,
17-skill lifecycle coverage. **Skin is missing** — no specialization path, no
orchestrator.

The 2026-07 revision adds two things:

- **The vault has no evidence layer.** Four findings previously filed separately
  (P2 confidence, M3 temporal claims, M5 drift, and lint 8d's unfixable warning)
  are all downstream of that single absence.
- **`lint.sh` cannot fail.** Its `FAIL` level is cosmetic. Independent of
  everything else here, and discovered while checking the evidence-layer design.

The 2026-08 revision adds one:

- **The vault has no interchange format, and one frontmatter key collides with an
  emerging standard.** Google's Open Knowledge Format v0.2 is architecturally the
  same object this vault is. The gap is small and almost entirely additive, and
  it is cheapest to close inside Phase 2, which already touches every template
  and every writing skill.

---

## Design Decisions (Resolved)

| Decision | Choice |
|----------|--------|
| Example vault | Skip for now — leave empty, documentation is sufficient |
| `covers::` duplication | Make `covers::` Dataview-derived from `part-of::` (breaking change) |
| Onboarding | Build interactive `memex-init` skill |
| Deep-extraction output | A new `extracts/` node type — never atoms |
| Extraction ontology | Reuse `schema.md`'s closed relation vocabulary; no second ontology |
| Anki delivery | Obsidian_to_Anki plain text; a `memex-compose` mode, not a new skill |
| Atom stubs from extraction | Threshold-gated at ≥ 3 claims |
| Claim-comparison inference | Lives in deep-extract (a proposing skill), never in `memex-conflicts` |
| Orphan definition | No `cites::` **and** no inbound link from `sources/`, `atoms/`, `topics/`, or `glossary/` |
| OKF scope | In-vault: additive keys plus one rename, nothing more. Everything Obsidian needs is translated at export, never changed in place |
| `status:` collision | Rename ours to `stage:`. `status:` goes unused in-vault, so OKF's "absent ⇒ stable" default applies — safe rather than wrong |
| Node-type discriminator | One `type:` key at node granularity. `medium:` stays the source subtype; `topic-type:` retired as a redundant second discriminator |
| Exporter language | Python 3, stdlib only. No pip, no venv |
| Export output | `_okf/`, git-tracked, with a mandatory Obsidian exclusion |

---

## Prioritized Findings

### Tier 0 — Correctness

**L1. `lint.sh` never exits non-zero, and `FAIL` is indistinguishable from `WARN`.**
`warn()` and `error()` incremented the same `issues` counter, the script had no
`exit 1`, and the summary reported both as "issue(s) found … Review warnings
above." The two genuine-corruption checks — source naming and archive mismatch —
gated nothing. Any hook or CI job shelling out to lint passed silently.

*Status: fixed in Phase 0.*

**L2. `lint.sh` and `_meta/index.md` disagreed on what an orphan atom is.**
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

**S1. Constitution conflated with configuration in `schema.md`.** Universal rules
(node types, relation types, status lifecycles) sit alongside domain-configurable
content (tag vocabulary). A historian forking this finds ML tags baked into the
constitution.

*Fix:* split into `_meta/schema.md` (constitution) + `_meta/domain.md` (tag vocab,
source subtypes, domain name). Lint reads tags from the domain config.

*Status: fixed in Phase 2.* `_meta/domain.md` holds the domain name, three tag
groups, the `medium:` vocabulary, and the folder→`type:` table; `_meta/lint.sh`
sections 10 and 11 read both from it. `README.md` § Specializing This Template is
the fork guide.

**S2. No worked example** — deferred by design decision above.

**S3. No specialization guide or onboarding skill.** No "how to make this yours"
workflow. *Fix:* `memex-init` interactive skill.

### Tier 2 — Structural

**E1. No evidence layer.** Sources are stored at document granularity. Nothing
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

**P1. `covers::` / `part-of::` duplication.** Same membership data in two places;
`memex-reconcile` exists solely to sync them. Make `covers::` a Dataview-generated
view from `part-of::`.

*Status: fixed in Phase 1.*

**P2. Confidence is unanchored — fix rewritten.** Previously: "add source-type
weighting to the rubric." That treats the symptom. Source *count* is the wrong
unit no matter how it is weighted — three blog posts agreeing is not `high`. With
E1, confidence derives from **independent claims across independent sources**,
with source-type weighting as a secondary term. **P2 now depends on E1.**

*Status: fixed in Phase 3*, not Phase 4 as scheduled — extracts made the rubric
expressible and the schema was already open. `_meta/schema.md` § Confidence
Values: the unit is independent claims across independent sources, source tiers
are inferred at audit time and never stored, and an atom with no extract is capped
at `medium`.

**P3. `related::` will erode typed-relation value.** No skill audits or promotes
`related::` links. *Fix:* a promotion pass in `memex-reconcile` surfacing links
older than 30 days for typed-relation assignment.

**P4. No orchestration layer — now more urgent.** 17 peer skills becomes 18.
Deep-extract is the most expensive skill in the vault and must never fire
automatically. Holding Anki to a `memex-compose` mode rather than a 19th skill is
a deliberate concession to this finding. *Fix:* `memex-tend`.

### Tier 3 — Missing concepts

**M1. No atom voice/claim style spec — now a hard prerequisite.** "Wikipedia-stub
granularity" is a length cue, not a style cue. Deep-extract mode B writes atom
`## Detail` prose at volume; without a style spec it writes it inconsistently, at
scale, into every atom it touches.

*Status: fixed in Phase 2.* `_meta/schema.md` § Atom Writing Style — five rules,
each tied to an existing lint signal so the spec is checkable rather than
aspirational.

**M2. No disambiguation policy — promoted to blocker.** `attention` (cognitive
science) vs. `attention` (transformers) collide under kebab naming. A paper cut
while a human names atoms by hand. Deep-extract's resolution pass handles dozens
of concept mentions per document and will emit `ambiguous` rows on day one with no
rule to settle them. **Must land before or with E1.**

*Status: fixed in Phase 2.* `_meta/schema.md` § Disambiguation Policy. Homonyms
get suffixed slugs and the bare slug is left permanently unused; polysemous
senses stay one atom with per-sense `##` sections and section-anchored `cites::`.
The test is whether a change to one sense obliges a change to the other.

**M3. No temporal model on claims — now tractable.** `supersedes::` handles atom
replacement, not time-bounded claims. Claims finally have a home: Hyper-Extract
carries `t_start` / `t_end` / `t_obs` per fact, and extract claims can carry the
same without imposing decay on atoms, which `memex-stale` deliberately refuses.

**M4. No first-class open questions.** `rq-*.md` is heavyweight. Extracts could
type an `open-question` claim, giving atom-level questions a home.

**M5. Source↔atom drift not audited — partially subsumed by E1.** An extract's
claims make the source `supports::` ↔ atom `cites::` correspondence checkable
rather than merely assertable.

*Status: fixed in Phase 3*, to the extent E1 subsumes it. `memex-trust-audit`
gained an UNGROUNDED finding and an extract-existence check on G13; `memex-stale`
Check 4 surfaces processed sources that were never extracted.

### Tier 4 — Interoperability

Measured against Open Knowledge Format v0.2. Full analysis in
`_meta/okf-alignment.md`. Lowest tier because nothing else here depends on it,
but O1 and O2 move up to Phase 2 the same way M1 and M2 did — they are cheap
only while that phase is already rewriting every template.

**O1. `status:` carries four different vocabularies, and collides with OKF.**
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

**O2. No node-type discriminator in frontmatter.** The node type is currently
implicit in the folder, plus `topic-type:` on topics and `medium:` on sources.
Nothing states it directly, so the type is unavailable to any Dataview query that
spans folders, and unavailable to any consumer that is not walking the tree. It
is also OKF's single required field (§4.1), which no template satisfies.

*Fix:* add `type:` in Phase 2; retire `topic-type:`, which it subsumes exactly.

*Status: fixed in Phase 2.* `type:` is on all seven templates and enforced by
lint 11a against `_meta/domain.md` § OKF Types. `topic-type:` is gone. The
cross-folder query O2 asks for now works — see `_meta/index.md` § Provenance.

**O3. The vault has no interchange format.** Wikilinks, Dataview-backed indices,
date-only timestamps, and typed relations are all load-bearing for Obsidian and
all unreadable outside it. Nothing can consume this vault but Obsidian and the
memex skills.

*Fix:* a deterministic export layer (Phase 8) that translates rather than
changes. Import (Phase 9) is the other half, deferred.

---

## Implementation Order

The original Phase 1→4 sequence still holds internally. E1 slots in after the
schema work it depends on. The OKF work splits across two points: the in-vault
half rides along with Phase 2, and the export layer lands at Phase 8, once
everything it serialises exists.

| Phase | Work | Closes | Why here |
|-------|------|--------|----------|
| **0** | Lint integrity: split `fails` from `warns`, `exit 1`, one orphan definition | L1, L2 | Small. Nothing downstream can treat lint as a gate until this lands. **Done.** |
| **1** | `covers::` → Dataview migration | P1 | Breaking; all skills must be consistent first. **Done.** |
| **2** | Schema split + atom style spec + disambiguation policy + OKF frontmatter | S1, M1, M2, O1, O2 | M1 and M2 are hard prereqs for Phase 3. O1 and O2 land here because this phase already rewrites every template and writing skill — separately means touching both twice. **Done.** |
| **3** | Evidence layer: `extracts/` + `memex-deep-extract` | E1, M5 | Depends on 0 (grounding gate), 1 (`part-of::` traversal), 2 (M1, M2). Also absorbed P2 — the rubric was cheapest to write while the schema was open. **Done.** |
| **4** | `memex-trust-audit` rebuild on the claim rubric | — | Shrunk: P2's rubric landed in Phase 3, P3's `related::` promotion in Phase 1. **Done.** |
| **5** | Anki render mode on `memex-compose` | — | Consumer of Phase 3. The glossary-only half has no dependency and can ship any time. |
| **6** | `memex-init` onboarding skill | S3 | Moved later so it scaffolds `extracts/` and `anki/` once, correctly |
| **7** | `memex-tend` orchestrator | P4 | Now sequencing 18 skills, one of them expensive |
| **8** | OKF export layer: `_meta/okf-export.py` + `memex-export` | O3 | Needs the schema settled (2), `extracts/` to exist (3), and `verified:` populated (4) |
| **9** | OKF import: `memex-import` | — | Scheduled but deferred — no consumer yet, and its shape depends on what real-world bundles look like |

Deferred, unscheduled: **M3** (temporal claim fields), **M4** (typed open
questions). Both become cheap once Phase 3 exists; neither blocks anything.
Phase 9 is scheduled but deferred on the same footing.

---

## Phase Detail

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

Items 13 and 14 are lint defects rather than Phase 2 work, fixed here because
this phase is what exposed them and because a lint that dies partway cannot gate
anything — which was Phase 0's entire point.

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

### Phase 5 — Anki

`memex-compose` gains an `anki` render mode writing Obsidian_to_Anki plain text to
a versioned top-level `anki/`. Cloze cards from extract claims, Basic cards from
`stage: reviewed` glossary terms. Every card back carries the source link and the
verbatim quote. Card identity keys off the extract block id, so the plugin's
`<!--ID:-->` writeback makes re-export an update rather than a duplicate.

`_exports/` is unsuitable: `.gitignore` excludes the directory, so a
`!_exports/anki/` negation cannot re-include anything, and the note IDs are
durable state rather than an ephemeral render.

### Phase 6 — `memex-init`

Interactive one-time specialization skill. Five questions (domain name, source
types, projects?, research questions?, initial tags) → write `_meta/domain.md`,
create a first topic stub, scaffold `extracts/` and `anki/`, update
`getting-started.md`, log the run.

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
`_meta/domain.md`, creates `_okf/`, and adds `_okf/` to Obsidian's excluded-files
list (see the warning in Phase 8).

### Phase 7 — `memex-tend`

Orchestration meta-skill. Sequences the maintenance skills after a batch ingest
and answers "what should I run now?" Must explicitly never auto-invoke
`memex-deep-extract`.

*OKF addendum:* sequences `memex-export` as a terminal step, and never before
`_meta/lint.sh` passes.

### Phase 8 — OKF export layer

Full design in `_meta/okf-alignment.md`. Summary: `_meta/okf-export.py`, Python 3
stdlib only, no LLM, deterministic — same invocation ergonomics and same `exit 1`
discipline as `lint.sh`.

```
python3 _meta/okf-export.py [--out _okf] [--include-archive]
```

Every OKF field is computed from what the vault already holds; nothing is
hand-maintained and nothing is duplicated into frontmatter. The four things
Obsidian needs — wikilinks, date-only timestamps, Dataview indices, typed
relations — are *translated* here rather than changed in place: wikilinks become
bundle-relative markdown links, dates gain `T00:00:00Z`, `index.md` is generated
per directory from `title` + `description`, and typed relations render as labelled
bullets under a `# Relations` heading. `sources[]` is derived from `cites::`,
`rebuts::`, and `raw::`; duplicating it into frontmatter would recreate exactly
the P1 sync problem Phase 1 exists to remove.

*Phase 3 addendum, two items.* **(a)** `extracts/` now exists and the exporter
must carry it: extract claims map onto OKF §5.1 footnote-keyed per-claim
attribution — `^c07` becomes the footnote key, `extracted-from::` resolves to the
`sources[].id`, and the claim's `quote:` sub-bullet becomes the footnote body.
Block-reference addressing and footnote attribution are the same idea, so this is
a rendering, not a redesign; the correspondence is written up in
`_meta/deep-extract-design.md` § OKF correspondence. **(b)** `_meta/normalize.sh`
already exists and is the vault's canonical text-folding implementation. The
exporter must call it or leave normalization alone entirely — a second,
Python-side copy of the folding rules would drift from the one lint greps
against, and the grounding guarantee is only worth what that agreement is worth.

Then a thin `skills/memex-export/SKILL.md` wrapping the script: run `lint.sh`
first, refuse to export a failing vault, run the exporter, write a `_meta/log.md`
entry. No generative work — the skill is a guard rail, not an author.

> **Hard requirement.** `_okf/` is a full second copy of every note and **must**
> be added to Obsidian's *Settings → Files & Links → Excluded files*, or every
> note appears twice in search, quick-switcher, graph view, and every Dataview
> query. This is the one way the OKF work could regress Obsidian functionality.

**Verification:** export, then assert §11's three MUSTs mechanically — every
non-reserved `.md` under `_okf/` has parseable frontmatter with a non-empty
`type:`; the root `index.md` carries `okf_version: "0.2"` and no other
frontmatter; `log.md` headings all match `^## \d{4}-\d{2}-\d{2}$`. Then: zero
`[[...]]` remain anywhere under `_okf/`; every markdown link target resolves in
the bundle or is an absolute URL; and exporting twice to separate directories
gives a clean `diff -r`, which is what proves determinism.

### Phase 9 — OKF import *(deferred)*

The other half of the IO layer. A `memex-import` skill consuming a third-party
OKF bundle: each concept becomes a source note under `sources/`, `sources[]`
entries become `cites::`, and `type:` routes to the right folder.

Deferred because it has no consumer yet and its shape depends on what real-world
OKF bundles look like once the format has adoption. Blocks nothing.
