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

**P1. `covers::` / `part-of::` duplication.** Same membership data in two places;
`memex-reconcile` exists solely to sync them. Make `covers::` a Dataview-generated
view from `part-of::`.

**P2. Confidence is unanchored — fix rewritten.** Previously: "add source-type
weighting to the rubric." That treats the symptom. Source *count* is the wrong
unit no matter how it is weighted — three blog posts agreeing is not `high`. With
E1, confidence derives from **independent claims across independent sources**,
with source-type weighting as a secondary term. **P2 now depends on E1.**

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

**M2. No disambiguation policy — promoted to blocker.** `attention` (cognitive
science) vs. `attention` (transformers) collide under kebab naming. A paper cut
while a human names atoms by hand. Deep-extract's resolution pass handles dozens
of concept mentions per document and will emit `ambiguous` rows on day one with no
rule to settle them. **Must land before or with E1.**

**M3. No temporal model on claims — now tractable.** `supersedes::` handles atom
replacement, not time-bounded claims. Claims finally have a home: Hyper-Extract
carries `t_start` / `t_end` / `t_obs` per fact, and extract claims can carry the
same without imposing decay on atoms, which `memex-stale` deliberately refuses.

**M4. No first-class open questions.** `rq-*.md` is heavyweight. Extracts could
type an `open-question` claim, giving atom-level questions a home.

**M5. Source↔atom drift not audited — partially subsumed by E1.** An extract's
claims make the source `supports::` ↔ atom `cites::` correspondence checkable
rather than merely assertable.

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

**O2. No node-type discriminator in frontmatter.** The node type is currently
implicit in the folder, plus `topic-type:` on topics and `medium:` on sources.
Nothing states it directly, so the type is unavailable to any Dataview query that
spans folders, and unavailable to any consumer that is not walking the tree. It
is also OKF's single required field (§4.1), which no template satisfies.

*Fix:* add `type:` in Phase 2; retire `topic-type:`, which it subsumes exactly.

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
| **1** | `covers::` → Dataview migration | P1 | Breaking; all skills must be consistent first |
| **2** | Schema split + atom style spec + disambiguation policy + OKF frontmatter | S1, M1, M2, O1, O2 | M1 and M2 are hard prereqs for Phase 3. O1 and O2 land here because this phase already rewrites every template and writing skill — separately means touching both twice |
| **3** | Evidence layer: `extracts/` + `memex-deep-extract` | E1, M5 | Depends on 0 (grounding gate), 1 (`part-of::` traversal), 2 (M1, M2) |
| **4** | Confidence rubric grounded in claims + `related::` promotion | P2, P3 | P2's real fix only exists after Phase 3 |
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

### Phase 1 — `covers::` → Dataview migration

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
6. `_meta/lint.sh` — section 6d and 7a/7b reference `covers::`; rework or retire.
7. `README.md` — note `covers::` is derived, not written.

**Verification:** `grep -r "covers::" skills/ _templates/ topics/` returns only
Dataview query blocks and schema notes.

**Dependency created for Phase 8.** Dataview-derived membership is invisible
outside Obsidian, so a non-Obsidian consumer would see every topic as empty. The
exporter must materialize `covers` by scanning atoms' `part-of::` — the same
traversal, done deterministically in Python. No work in this phase; recorded so it
is not discovered late.

### Phase 2 — Schema split + atom style spec + disambiguation + OKF frontmatter

**Schema work (S1, M1, M2):**

1. `_meta/schema.md` — remove the Tags section; add **Atom Writing Style** (3–5
   rules: present tense, hedge single-source claims, use relations not inline
   prose, one claim per atom) and a **Disambiguation Policy** (suffixed slugs for
   true homonyms, polysemous sections for related senses).
2. `_meta/domain.md` — new: `domain_name`, `domain_tags`, `type_tags`,
   `stage_tags`, `source_types`, `okf_types`.
3. `_meta/lint.sh` — read tag vocabulary from `_meta/domain.md`.
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
10. `_meta/lint.sh` — three new checks: `type:` present and drawn from
    `domain.md`; `stage:` value valid for the node type; `status:` **absent**
    in-vault, since it is the exporter's output field and hand-writing it would
    diverge.

**Verification:** `grep -rn 'topic-type'` and
`grep -rnE '(^|[^a-z-])status:' _templates/ skills/ _meta/` both return zero.
`bash _meta/lint.sh` exits `0`. A note with `type: Nonsense`, or one carrying
`status:`, prints `FAIL` and exits `1`. In Obsidian: every `_meta/index.md`
Dataview table still renders, now with a `description` column, and a note created
from each of the seven templates shows `type` and `stage` in the property editor.

### Phase 3 — Evidence layer

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

### Phase 4 — Confidence rubric + `related::` promotion

1. `_meta/schema.md` — confidence derives from independent claims across
   independent sources; source-type weighting (peer-reviewed > preprint > curated
   blog > unreviewed post) as a secondary term.
2. `skills/memex-reconcile/SKILL.md` — `related::` promotion pass for links older
   than 30 days.
3. `skills/memex-trust-audit/SKILL.md` — rebuild checks on the claim-count rubric,
   and become the writer of `verified:` entries (`{ by: human:<id>, at: <date> }`
   on human sign-off), using the field defined in Phase 2.

*OKF addendum:* the source-type weighting in step 1 is this vault's credibility
signal. OKF §5.1 stores exactly that — objective per-source signals (`author`,
`usage_count`, `last_modified`) — and explicitly refuses to store a score, on the
grounds that a score is subjective, unportable, and goes stale. That is P2's own
conclusion reached independently, so name the frontmatter fields to match rather
than inventing parallel ones.

### Phase 5 — Anki

`memex-compose` gains an `anki` render mode writing Obsidian_to_Anki plain text to
a versioned top-level `anki/`. Cloze cards from extract claims, Basic cards from
`status: reviewed` glossary terms. Every card back carries the source link and the
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
