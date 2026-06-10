# memex-vault Improvement Roadmap

Generated: 2026-05-07. Resume in the next session by referencing this file.

---

## Summary Verdict

**Bones are excellent** — typed relations, candidate gating, schema-as-constitution, 17-skill lifecycle coverage. **Skin is missing** — no specialization path, no orchestrator. Plus two structural issues that won't survive a long-running vault: `covers::` / `part-of::` duplication, and source-count confidence conflated with epistemic confidence.

---

## Design Decisions (Resolved)

| Decision | Choice |
|----------|--------|
| Example vault | Skip for now — leave empty, documentation is sufficient |
| `covers::` duplication | Make `covers::` Dataview-derived from `part-of::` (breaking change) |
| Onboarding | Build interactive `memex-init` skill |

---

## Prioritized Findings

### Tier 1 — Specialization blockers

**S1. Constitution conflated with configuration in `schema.md`**
`_meta/schema.md` mixes universal rules (node types, relation types, status lifecycles) with domain-configurable content (tag vocabulary). A historian forking this finds ML tags baked into the constitution.

Fix: Split into `_meta/schema.md` (constitution) + `_meta/domain.md` (tag vocab, source subtypes, domain name). Lint reads from domain config.

**S2. No worked example** — deferred by design decision above.

**S3. No specialization guide or onboarding skill**
No "how to make this yours" workflow. A user forking this doesn't know which tags to customize, which skills to keep, or which source types apply.

Fix: `memex-init` interactive skill (see Phase 3 below).

---

### Tier 2 — Structural problems

**P1. `covers::` / `part-of::` duplication**
Same membership data in two places. `memex-reconcile` exists solely to sync them. Make `covers::` a Dataview-generated view from `part-of::` — eliminates the sync problem entirely.

**P2. Confidence is unanchored**
`low/medium/high` defined by source count. Three blog posts agreeing isn't `high`. Fix: add source-type weighting to the rubric or simplify to 2-state.

**P3. `related::` will erode typed-relation value**
No skill audits or promotes `related::` links. Add a promotion pass to `memex-reconcile` surfacing links > 30 days old for typed-relation assignment.

**P4. No orchestration layer**
17 peer skills, no meta-skill. User faces decision paralysis after batch ingest. Fix: `memex-tend` orchestration skill, or at minimum a cadence checklist in `getting-started.md`.

---

### Tier 3 — Missing concepts

**M1. No atom voice/claim style spec** — "Wikipedia-stub granularity" is a length cue, not a style cue. Add 3–5 writing guidelines to `schema.md`.

**M2. No disambiguation policy** — `attention` (cogsci) vs `attention` (transformers) collide under kebab naming. Add suffixed-slug policy to `schema.md`.

**M3. No temporal model on claims** — `supersedes::` handles atom replacement, not time-bounded claims. Fast-moving domains need guidance.

**M4. No first-class open questions** — `rq-*.md` is heavyweight. Atom-level questions have no typed home.

**M5. Source↔atom drift not audited** — `memex-reconcile` covers `part-of` ↔ `covers` drift but not source `supports::` ↔ atom `cites::` drift.

---

## Implementation Plan

### Phase 1 — `covers::` → Dataview migration (do first)

**Goal:** Make `covers::` auto-derived from `part-of::` on atoms. Single source of truth.

Files to change:

1. **`_meta/schema.md`**
   - Remove `covers::` from Topic → Atoms relation table
   - Add note: "Topic membership is derived from atoms' `part-of::` via Dataview. Do not write `covers::` manually."
   - Remove `covers` from Valid Relation Fields list
   - Add lint heuristic: warn on manually-written `covers::` in topic files

2. **`_templates/topic-concept.md`, `topic-research.md`, `topic-project.md`**
   - Replace `covers:: ` placeholder with a Dataview block:
     ````
     ```dataview
     LIST FROM "atoms" WHERE contains(part-of, [[<topic-title>]])
     ```
     ````
   - Templater must inject the topic title at creation time

3. **`topics/concepts/getting-started.md`**
   - Replace the `covers::` line with the Dataview query block
   - Update "Connecting things" examples to remove `covers::` as a user-writable relation

4. **`skills/memex-topic-init/SKILL.md`**
   - Remove steps that write `covers::` to the topic file
   - Keep steps that write `part-of:: [[topic]]` to atoms (source of truth)

5. **`skills/memex-topic-emerge/SKILL.md`**
   - Same: remove `covers::` writes from candidate files; only write `part-of::` to atoms

6. **`skills/memex-reconcile/SKILL.md`**
   - Remove the `part-of::` ↔ `covers::` drift check (no longer needed)
   - Replace with: check for `part-of::` links pointing to non-existent topics (orphan part-of)
   - Add `related::` promotion pass (see Phase 4)

7. **`README.md`**
   - Update relationship taxonomy: note `covers::` is Dataview-derived, not manually written

**Verification:** `grep -r "covers::" skills/ _templates/ topics/` should return zero manual instances (only Dataview query blocks and schema notes).

---

### Phase 2 — Schema split + atom style spec

**Goal:** Separate universal constitution from domain-configurable content.

1. **`_meta/schema.md`** — remove Tags section; add:
   - Reference to `_meta/domain.md` for tag vocab
   - **Atom Writing Style** section (3–5 rules: present tense, hedge single-source claims, use relations not inline prose, one claim per atom)
   - **Disambiguation Policy** (suffixed slugs for true homonyms; polysemous sections for related senses)

2. **`_meta/domain.md`** — new file with:
   - `domain_name:`
   - `domain_tags:` list (ML tags as defaults, annotated as replaceable)
   - `type_tags:` list (domain-agnostic, keep or prune)
   - `status_tags:` list
   - `source_types:` list (web/video/paper/docs/meeting — remove unused)

3. **`_meta/lint.sh`** — update tag validation to read from `_meta/domain.md`

4. **`README.md`** — add "Specializing This Template" section pointing to `_meta/domain.md`

---

### Phase 3 — `memex-init` onboarding skill

**Goal:** Interactive one-time specialization skill.

**`skills/memex-init/SKILL.md`** — new skill

Workflow:
1. Ask 5 questions: domain name, source types (multi-select), projects?, research questions?, initial domain tags (suggest 5–8 terms)
2. Write `_meta/domain.md` with answers
3. Create first topic map stub at `topics/concepts/<domain-slug>.md`
4. Update `getting-started.md` to reference the new topic
5. Log the init run
6. Report and suggest: "Run `memex-ingest` or `memex-save` to add your first source."

Constraints: does not delete unused folders; does not modify `schema.md`; can re-run to update `domain.md` without overwriting topic stub.

---

### Phase 4 — `related::` promotion + confidence rubric

1. **`skills/memex-reconcile/SKILL.md`** — add pass: scan atoms for `related::` links > 30 days old; present each and ask for typed-relation assignment; write candidate file per promoted link.

2. **`_meta/schema.md`** — strengthen confidence rubric: add source-type weighting note (peer-reviewed > preprint > curated blog > unreviewed post); note 3 independent sources of similar weight needed for `high`.

---

## Final Implementation Order

1. **Phase 1** — `covers::` Dataview migration (all skills must be consistent first)
2. **Phase 2** — Schema split + atom style spec
3. **Phase 3** — `memex-init` skill
4. **Phase 4** — `related::` promotion + confidence rubric
