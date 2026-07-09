# memex-vault Improvement Roadmap

Revised: 2026-07-09. Supersedes the 2026-05-07 revision.

Infrastructure doc — not a vault node. No frontmatter, and nothing should link to
it with a wikilink.

Companion: `_meta/deep-extract-design.md` holds the full design for Phase 3.

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

---

## Implementation Order

The original Phase 1→4 sequence still holds internally. E1 slots in after the
schema work it depends on, and two new phases bracket it.

| Phase | Work | Closes | Why here |
|-------|------|--------|----------|
| **0** | Lint integrity: split `fails` from `warns`, `exit 1`, one orphan definition | L1, L2 | Small. Nothing downstream can treat lint as a gate until this lands. **Done.** |
| **1** | `covers::` → Dataview migration | P1 | Breaking; all skills must be consistent first |
| **2** | Schema split + atom style spec + disambiguation policy | S1, M1, M2 | M1 and M2 move up from Tier 3 — both are hard prereqs for Phase 3 |
| **3** | Evidence layer: `extracts/` + `memex-deep-extract` | E1, M5 | Depends on 0 (grounding gate), 1 (`part-of::` traversal), 2 (M1, M2) |
| **4** | Confidence rubric grounded in claims + `related::` promotion | P2, P3 | P2's real fix only exists after Phase 3 |
| **5** | Anki render mode on `memex-compose` | — | Consumer of Phase 3. The glossary-only half has no dependency and can ship any time. |
| **6** | `memex-init` onboarding skill | S3 | Moved later so it scaffolds `extracts/` and `anki/` once, correctly |
| **7** | `memex-tend` orchestrator | P4 | Now sequencing 18 skills, one of them expensive |

Deferred, unscheduled: **M3** (temporal claim fields), **M4** (typed open
questions). Both become cheap once Phase 3 exists; neither blocks anything.

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

### Phase 2 — Schema split + atom style spec + disambiguation

1. `_meta/schema.md` — remove the Tags section; add **Atom Writing Style** (3–5
   rules: present tense, hedge single-source claims, use relations not inline
   prose, one claim per atom) and a **Disambiguation Policy** (suffixed slugs for
   true homonyms, polysemous sections for related senses).
2. `_meta/domain.md` — new: `domain_name`, `domain_tags`, `type_tags`,
   `status_tags`, `source_types`.
3. `_meta/lint.sh` — read tag vocabulary from `_meta/domain.md`.
4. `README.md` — add a "Specializing This Template" section.

### Phase 3 — Evidence layer

See `_meta/deep-extract-design.md`. Summary: a new `extracts/` node type, one file
per deep-extracted source, holding quote-grounded claims addressable by Obsidian
block reference. A `memex-deep-extract` skill with `extract` and `promote` modes.
A grounding check in `lint.sh` that `grep -F`s every claim's verbatim quote
against the normalized `.archive/` text — making fabrication mechanically
detectable, which is only meaningful because Phase 0 made `FAIL` a real gate.

### Phase 4 — Confidence rubric + `related::` promotion

1. `_meta/schema.md` — confidence derives from independent claims across
   independent sources; source-type weighting (peer-reviewed > preprint > curated
   blog > unreviewed post) as a secondary term.
2. `skills/memex-reconcile/SKILL.md` — `related::` promotion pass for links older
   than 30 days.
3. `skills/memex-trust-audit/SKILL.md` — rebuild checks on the claim-count rubric.

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

### Phase 7 — `memex-tend`

Orchestration meta-skill. Sequences the maintenance skills after a batch ingest
and answers "what should I run now?" Must explicitly never auto-invoke
`memex-deep-extract`.
