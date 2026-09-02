# memex-vault Improvement Roadmap

Revised: 2026-09-02, adding § Release Status for `v1.0.0-rc.1`. The findings and
phase detail below are from the 2026-08-25 revision and are unchanged by it, which
superseded 2026-07-09, which superseded 2026-05-07.

Infrastructure doc — not a vault node. No frontmatter, and nothing should link to
it with a wikilink.

Companions: `_meta/deep-extract-design.md` holds the full design for Phase 3, and
for Phase 5 (deferred). `_meta/okf-alignment.md` holds the full design for
Phases 8–9, plus the frontmatter changes they need from Phase 2.

`CHANGELOG.md` records what shipped in each release; this file records what has
not shipped yet. When the two disagree about a phase's status, the changelog is
the one tied to a tag.

---

## Release Status

**`v1.0.0-rc.1`, tagged 2026-09-02.** The first tagged release, cut at Phase 7.

A release *candidate* rather than a final for one reason: the verification debt
below. Four things are built and pass against fixtures but have never run over
real notes, and that cannot change inside this repository — it is a template and
ships with zero notes deliberately. The debt is discharged in the first fork that
puts real content through the skills, which is exactly what an RC is for.

What promotes it to `v1.0.0`: the four verification-debt rows exercised against a
real vault, and any bugs that surfaces fixed. **Phase 8 is not a blocker** — it
ships as `v1.1.0`. An exporter with nothing to export and no importer to feed
cannot be validated either, so holding the release for it would trade one kind of
unverified code for another.

Root `VERSION` carries the release into a fork, which GitHub's *Use this template*
otherwise strips along with the history and tags. `memex-init` logs it as
`template::`. Neither is edited by a fork.

---

## Summary Verdict

**As of 2026-08-25, seven of the ten phases are complete** — 0, 1, 2, 3, 4, 6, 7.
One remains: **Phase 8**, the OKF export layer. Two are deferred: Phase 5 (Anki,
unscheduled) and Phase 9 (OKF import, scheduled but waiting on a real consumer).
Everything a vault needs to be *used* is built; what is missing is the ability to
hand it to something that is not Obsidian.

The verdict this document opened with in May 2026 was:

> **Bones are excellent** — typed relations, candidate gating,
> schema-as-constitution, 17-skill lifecycle coverage. **Skin is missing** — no
> specialization path, no orchestrator.

Both halves of "skin is missing" are now built: `memex-init` (Phase 6) and
`memex-tend` (Phase 7). The skill count went 17 → 20 in the interval, which is
what made the orchestrator worth building rather than merely worth filing.

Three things were learned in the doing, none of which were on any list:

- **A fork was broken for a reason S3 never named.** Every skill hard-coded the
  template author's absolute vault path. The onboarding skill was the visible half
  of the problem; path portability was the half that mattered.
- **`lint.sh` was blind to any vocabulary a fork added.** It read tags and node
  types from `_meta/domain.md` but hard-coded the five source media, while the
  README claimed otherwise. A fork's new source folder got no checks at all,
  silently.
- **Lint is the vault's only executable state oracle.** `_meta/index.md` answers
  the same questions but only inside Obsidian. That constraint, discovered while
  designing Phase 7, is what determined the orchestrator's whole design.

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
| Vault root in skills | Resolved at run time — `${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}` — never hard-coded. A fork works at any path with no search-and-replace |
| Empty folders for unbuilt features | Never scaffolded. `anki/` and `_okf/` are both created by the thing that writes to them; only the `_okf` *exclusion* is written early, because it is ordering-sensitive |
| Orchestrator authority | `memex-tend` routes and reports; it never invokes `memex-deep-extract`, `memex-compose`, `memex-refactor`, or `memex-init`. Triage is its default mode |
| Vault state outside Obsidian | `_meta/lint.sh` is the only executable oracle. `_meta/index.md` answers the same questions in Dataview, which renders only in Obsidian, so no skill may depend on it |

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

*Status: fixed in Phase 6*, which also found the reason a fork actually broke and
the finding never named: 18 skills hard-coding the template author's absolute vault
path, on 54 lines. The onboarding skill was the visible half of S3; path
portability was the half that made a fork unusable.

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

*Status: fixed in Phase 1*, which absorbed it while rewriting the relation
handling. `skills/memex-reconcile/SKILL.md` runs the promotion pass; Phase 7
routes lint section 7's stale-`related::` findings to it. The status line was
never written at the time — recorded here 2026-08-25 during roadmap revision.

**P4. No orchestration layer — now more urgent.** 17 peer skills becomes 18.
Deep-extract is the most expensive skill in the vault and must never fire
automatically. Holding Anki to a `memex-compose` mode rather than a 19th skill is
a deliberate concession to this finding. *Fix:* `memex-tend`.

*Status: fixed in Phase 7*, at 20 skills rather than 18 — the count grew through
Phases 6 and 7 while the finding sat open, which is the finding proving itself.

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
| **5** | Anki render mode on `memex-compose` | — | **Deferred** (2026-08-25) — low priority, unlikely to be revisited before more critical refactoring. Unblocked whenever it is wanted; the design is written. |
| **6** | `memex-init` onboarding skill | S3 | **Done.** Also made the 18 existing skills path-independent and taught lint to read § Source Types |
| **7** | `memex-tend` orchestrator | P4 | **Done.** Routes lint findings to skills; never invokes deep-extract, compose, refactor, or init |
| **8** | OKF export layer: `_meta/okf-export.py` + `memex-export` | O3 | Needs the schema settled (2), `extracts/` to exist (3), and `verified:` populated (4) |
| **9** | OKF import: `memex-import` | — | Scheduled but deferred — no consumer yet, and its shape depends on what real-world bundles look like |

Deferred, unscheduled: **Phase 5** (Anki), **M3** (temporal claim fields), **M4**
(typed open questions). M3 and M4 became cheap once Phase 3 existed; neither
blocks anything. Phase 9 is scheduled but deferred on the same footing.

Phase numbers are **not** reassigned when a phase is deferred. Phases 6–9 keep
their numbers with 5 skipped, because the numbers are referenced across
`_meta/deep-extract-design.md`, `_meta/okf-alignment.md`, several skill files,
and every commit message in the history. A tidier sequence is not worth
invalidating that.

---

## Where to Start Next

**Since `v1.0.0-rc.1`, the first move is a fork, not a phase.** Clearing the
verification debt below needs a vault with real notes, and building Phase 8 first
only adds a fifth unexercised thing to the list. Phase 8 is the next *build*.

**Phase 8 is the only unblocked phase.** Its full design is in
`_meta/okf-alignment.md`; the roadmap entry below carries three amendments made
while later phases shipped — extracts map onto OKF §5.1 footnote-keyed
attribution, the exporter must not duplicate `_meta/normalize.sh`, and it creates
`_okf/` itself because Phase 6 deliberately does not scaffold the empty folder.
It is also the first phase that is real code rather than a skill document.

Everything else outstanding is deferred: Phase 5 (Anki), Phase 9 (OKF import),
M3 (temporal claim fields), M4 (typed open questions). None blocks anything.

### Verification debt

Four things are built but never exercised. They are listed together because they
share one cause — **the vault has 0 atoms, 0 sources, 0 extracts, and 0 glossary
terms.** It is a template that has never been used as a vault, so every check that
needs content to act on has been proven only against fixtures.

| What | Since | How it gets verified |
|---|---|---|
| Every Dataview query in `_meta/index.md` | Phases 1–2 | Open the vault in Obsidian once there are notes |
| `memex-init`'s five-question flow | Phase 6 | The first real fork |
| `memex-tend`'s ordering | Phase 7 | The first vault with enough findings to sequence |
| `memex-deep-extract` end to end | Phase 3 | The first deep extraction of a real source |

These four rows are what the `-rc` in `v1.0.0-rc.1` refers to; see § Release
Status. Clearing them is what promotes the release, and none of them can be
cleared here — the work happens in the first fork with real notes in it.

This is not a defect list. Fixture-testing caught two real bugs in Phase 6 that a
content-ful vault would have caught the same way. But no amount of it substitutes
for one pass over real notes, and that pass has never happened.

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

### Phase 5 — Anki *(deferred, unscheduled)*

**Deferred 2026-08-25 at the user's call:** a low-priority idea, unlikely to be
revisited before more critical components are refactored. Nothing is lost by
waiting — the design below is complete, and its one real dependency (extract
claims to make cards from) landed in Phase 3, so this can be picked up whenever
it is wanted rather than needing to be re-derived.

Two notes for whoever resumes it. The **glossary half has no dependency at all**
— Basic cards from `stage: reviewed` terms work against today's vault — so it is
shippable on its own if the claim half still looks like too much. And Phase 6 no
longer scaffolds `anki/`; if this lands, `memex-init` needs that folder and its
`.obsidian/app.json` exclusion added back.

The design, unchanged:

`memex-compose` gains an `anki` render mode writing Obsidian_to_Anki plain text to
a versioned top-level `anki/`. Cloze cards from extract claims, Basic cards from
`stage: reviewed` glossary terms. Every card back carries the source link and the
verbatim quote. Card identity keys off the extract block id, so the plugin's
`<!--ID:-->` writeback makes re-export an update rather than a duplicate.

`_exports/` is unsuitable: `.gitignore` excludes the directory, so a
`!_exports/anki/` negation cannot re-include anything, and the note IDs are
durable state rather than an ephemeral render.

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
>
> *Phase 6 status:* `memex-init` now writes that exclusion into
> `.obsidian/app.json` at fork time, before anything can export. **The exporter
> creates `_okf/` itself on first run** — Phase 6 deliberately does not scaffold
> the empty folder. The exporter must therefore `mkdir -p` its own output, and
> must also verify the exclusion is present in a vault that predates `memex-init`,
> refusing to export rather than silently doubling the vault.

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
