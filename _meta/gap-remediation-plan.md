# Karpathy Wiki — Gap Remediation Plan

## Context

The vault template now has six Claude Code skills (capture, ingest, connect, topic-init, review, search) and a lint script. A lifecycle + extraction audit identified 10 structural gaps; a follow-up Opus evaluation confirmed those gaps, added 4 more, and corrected the sequencing priority. This plan addresses all 14 gaps in four active phases plus a deferred section.

The guiding principle from Opus: **build trustworthy reads before trustworthy writes-out**. Compose's value depends on graph integrity. The reconciler and trust audit must come before synthesis/export.

Gaps are numbered for traceability:
- G1–G10: original audit
- G11–G14: Opus additions

---

## Current State (Baseline)

Skills: capture, ingest, connect, topic-init, review, search  
Lint checks: naming, frontmatter, staleness (sources >30d), orphan atoms, archive mismatches, graph health (inbox-only, isolated, bloated atoms, oversized topic maps)  
Templates: atom, glossary, source-digital, source-meeting, topic-concept, topic-research, topic-project  
Schema: `_meta/schema.md` — authoritative relationship taxonomy, status values, naming conventions

---

## Phase 1 — Graph Integrity (trust the reads)

**Principle:** Silent corruption before missing capability. Fix what makes reads wrong before building reads-out.

### 1A. `karpathy-wiki-reconcile` (new skill)

**Addresses:** G4 (bidirectional drift), G14 (skill-schema coupling — partial)

**What it does:**
- Scans every atom's `part-of::` and verifies the referenced topic's `covers::` contains it; surfaces mismatches
- Scans every topic's `covers::` and verifies each referenced atom has matching `part-of::` set
- Presents each mismatch with both file paths and proposes which side to update (usually: the side that was written more recently)
- User confirms each fix; skill applies one at a time
- Writes a reconciliation log entry to `_meta/log.md` at session end

**What it does NOT do:**
- Never auto-repairs without confirmation — asymmetry can be intentional (e.g., an atom `part-of` a sub-topic while the parent topic still `covers` it transitively)
- Does not resolve `related::` into more specific relations (that belongs to `review`)
- Does not touch source connection fields

**Files:**
- Create: `skills/karpathy-wiki-reconcile/SKILL.md`
- Create: `skills/karpathy-wiki-reconcile/references/vault-schema.md` (copy from capture)

### 1B. Lint extensions (Section 7 additions to `_meta/lint.sh`)

**Addresses:** G4 (drift detection), G12 (atom freshness), G14 (taxonomy coupling)

New checks — all WARN severity:

| Check | Logic | Threshold |
|-------|-------|-----------|
| `part-of::` / `covers::` asymmetry | For each atom with `part-of::`, verify the named topic's `covers::` contains it | Any mismatch |
| `covers::` / `part-of::` asymmetry | For each topic entry in `covers::`, verify the atom has matching `part-of::` | Any mismatch |
| Atom freshness | Atom whose newest `cites::` source has `saved:` > 18 months ago | Any |
| Unvalidated atom | Atom where all cited sources still have `status: unread` | Any |
| Unknown relation field | Source/atom connection field not in the schema taxonomy | Any |

**Files:**
- Modify: `_meta/lint.sh` — add Section 7 "Structural Integrity"
- Modify: `_meta/schema.md` — enumerate all valid relation field names in a machine-readable list for the lint check

---

## Phase 2 — Trust Signals

**Principle:** Confidence is the primary signal for extraction trustworthiness. Currently static after initial assignment; needs a managed lifecycle.

### 2A. `karpathy-wiki-trust-audit` (new skill)

**Addresses:** G3 (confidence lifecycle), G12 (atom freshness — surfacing), G13 (source extraction completeness)

**What it does:**

*Scope:* one topic at a time (like `review`), or `--vault` flag to scan all atoms.

*Per-atom evaluation:*
- `confidence: high` with fewer than 3 cited sources → flag as overconfident
- `confidence: medium` with only one cited source → flag as overconfident
- `confidence: low` with 2+ independent processed sources → flag as upgrade candidate
- Atom has incoming `challenges::` or `refutes::` relations that postdate its `updated:` timestamp → flag as potentially stale confidence
- All cited sources still `status: unread` → flag as unvalidated (confidence based on unread material)
- Newest cited source `saved:` > 18 months → flag as potentially stale

*Proposed transitions:* upgrade / downgrade / leave. User confirms each. Every accepted change updates atom frontmatter `confidence:` and `updated:`.

*Source extraction completeness (G13):*
- For sources with `status: processed` and body length > 100 lines but `introduces::` count = 0 and `supports::` count < 2 → WARN: "long source with few atom connections — may be under-extracted"

**What it does NOT do:**
- Never silently changes `confidence:` — every transition is user-approved and logged
- Does not introduce new status values
- Does not evaluate factual accuracy of atom content, only provenance structure
- Does not modify source files (read-only on sources)

**Files:**
- Create: `skills/karpathy-wiki-trust-audit/SKILL.md`
- Create: `skills/karpathy-wiki-trust-audit/references/vault-schema.md`

### 2B. Lint extensions (Section 8 additions to `_meta/lint.sh`)

**Addresses:** G3, G12, G13

New checks — all WARN severity:

| Check | Logic | Threshold |
|-------|-------|-----------|
| Overconfident atom | `confidence: high` with `cites::` count < 3 | Any |
| Underconfident atom | `confidence: low` with 2+ processed sources | Any |
| Unvalidated confidence | All sources cited by atom are `status: unread` | Any |
| Under-extracted source | `status: processed`, body > 100 lines, atom connections < 2 | Any |

**Files:**
- Modify: `_meta/lint.sh` — add Section 8 "Confidence and Coverage"

---

## Phase 3 — Extraction

**Principle:** Now that reads are trustworthy, build the extraction layer.

### 3A. `karpathy-wiki-conflicts` (new skill)

**Addresses:** G11 (cross-vault conflict surfacing)

**What it does:**
- Scans all atoms for `contradicts::`, `challenges::`, `limits::`, `refutes::` relations
- Groups conflicts by: acknowledged (both atoms have reciprocal links + body description of tension) vs. unacknowledged (link exists but no explanation text)
- For cross-topic conflicts: flags pairs of atoms that belong to different topic maps but are in tension
- Presents grouped by severity: direct contradiction > challenge/limit > refutation from source
- For each unacknowledged conflict: prompts user to write a tension description in the atom body; offers a draft
- Does not modify relation fields — only adds explanatory text where missing

**What it does NOT do:**
- Does not infer conflicts from atom content (no LLM judgment on whether two atoms "should" conflict)
- Only follows explicit relation fields already in the graph
- Does not create new atoms or modify topic maps

**Files:**
- Create: `skills/karpathy-wiki-conflicts/SKILL.md`

### 3B. `karpathy-wiki-compose` (new skill)

**Addresses:** G1 (synthesis/export)

**What it does:**
- Takes a topic node (concept / research / project) as input; optionally a sub-scope (specific atoms only)
- Walks: topic → `covers::` atoms → each atom's `cites::` / `supports::` / `demonstrates::` / `contradicts::` / `challenges::`
- Emits structured Markdown to `_exports/YYYY-MM-DD-topic-slug.md` with sections:
  - **Claims** — atom bodies grouped by structural relation (`extends::`, `uses::`, `contrasts-with::`)
  - **Evidence** — cited sources with summary excerpt and URL
  - **Tensions** — unresolved `contradicts::` / `challenges::` links with tension descriptions (if present)
  - **Confidence summary** — table: atoms by confidence level, sources by status
- Per-claim citation footnotes link back to vault notes and source URLs
- Writes output path to `_meta/log.md`

**What it does NOT do:**
- Never invents claims absent from atoms — every sentence traces to an atom or source body
- Never re-grades confidence (read-only on that field)
- Never modifies vault notes; output is one-way to `_exports/`
- No web fetching during composition
- Does not compose from `unread` sources without flagging them as unverified

**Scope guard:** `_exports/` added to `.gitignore`. No new schema fields.

**Files:**
- Create: `skills/karpathy-wiki-compose/SKILL.md`
- Modify: `.gitignore` — add `_exports/`
- Modify: `_meta/schema.md` — add `_exports/` folder description

### 3C. Lint extension (Section 9 in `_meta/lint.sh`)

**Addresses:** G11 (unacknowledged conflicts at scale)

| Check | Logic | Threshold |
|-------|-------|-----------|
| Bare conflict link | Atom has `contradicts::` or `refutes::` but no sentence describing the tension in the body | Any |

---

## Phase 4 — Mutation

**Principle:** Highest-mutation skill comes last, after structural guarantees are in place.

### 4A. `karpathy-wiki-refactor` (new skill)

**Addresses:** G2 (atom evolution), G9 (deprecation/supersession)

**Three sub-modes:**

**revise** — rewrite atom body in place
- User provides the revised content or describes the change
- Skill proposes the edit; user confirms
- Updates `updated:` in frontmatter
- If confidence should change: propose explicitly (feeds into trust-audit pattern)
- Appends revision note to `_meta/log.md`

**split** — A → A1 + A2
- User specifies the conceptual boundary
- Skill creates A1 and A2 with `confidence: low`, copies relevant `cites::` to each child
- Re-points each incoming `extends::`, `uses::`, `part-of::` from other atoms to the appropriate child
- Leaves A as a stub with `supersedes::` from each child (or archives A if user prefers)
- Updates any topic `covers::` that referenced A
- Confirms each step before writing

**merge** — A + B → C
- User provides the merged concept name
- Creates C inheriting all relations from A and B
- All incoming relations from other atoms that pointed to A or B now point to C
- A and B become stubs: `supersedes:: [[C]]` added to both; body replaced with "Merged into [[C]]"
- Topic maps updated if A or B were in `covers::`
- Confirms each step before writing

**Scope guards:**
- Never deletes atoms — stubbing with `supersedes::` is the soft-delete pattern
- Does not auto-detect split/merge candidates; lint's bloated-atom WARN is the trigger and the user decides
- Does not modify source bodies (only source connection sections if the source `introduces::` the refactored atom)
- Every operation requires a user-supplied reason; logged to `_meta/log.md`

**Files:**
- Create: `skills/karpathy-wiki-refactor/SKILL.md`
- Create: `skills/karpathy-wiki-refactor/references/vault-schema.md`

---

## Phase 5 — Content Gaps

### 5A. `karpathy-wiki-meeting` (new skill)

**Addresses:** G5 (meeting notes are second-class)

**What it does:**
- Takes meeting notes from user (spoken or pasted); not a URL
- Creates `sources/meeting/YYYY-MM-DD-kebab-context.md` using `_templates/source-meeting.md`
- Extracts: attendees, decisions made, action items, follow-up sources mentioned
- For each follow-up source mentioned: offers to create a capture stub immediately
- Wires connections to existing atoms for any concepts discussed
- Proposes atom stubs for new concepts that emerged
- Sets `status: unprocessed` initially; prompts for `processed` once action items are addressed
- Appends to `_meta/log.md`

**What it does NOT do:**
- Does not handle URL-based sources (those go to capture/ingest)
- Does not create calendar events or external integrations
- Does not transcribe audio

**Files:**
- Create: `skills/karpathy-wiki-meeting/SKILL.md`
- Modify: `skills/karpathy-wiki-capture/SKILL.md` — remove "this skill does not handle meeting notes" and route to `karpathy-wiki-meeting` instead

### 5B. `karpathy-wiki-log-query` (new skill)

**Addresses:** G7 (log is write-only)

**What it does:**
- Parses `_meta/log.md` to answer queries:
  - "What did I ingest this week/month?"
  - "Which sources are still unprocessed?"
  - "Which atoms were created from paper sources?"
  - "How many entries this month?"
  - "Show me everything tagged with [[atom-name]]"
- Returns structured results grouped by medium, date range, or atom
- Optionally cross-references current source status against log entries (log says processed → source still shows unread → flag)

**What it does NOT do:**
- Does not modify `log.md`
- Does not query atom or source files directly — only the log index
- Does not generate reports (that belongs to compose)

**Files:**
- Create: `skills/karpathy-wiki-log-query/SKILL.md`
- Modify: `_meta/log.md` header — add format spec note to make entries consistently machine-parseable

---

## Schema and Template Changes (pre-work, no skill required)

### Tag controlled vocabulary (G8 — partial fix now)

Add to `_meta/schema.md` a `## Tags` section with a controlled vocabulary — at minimum:
- Domain tags (e.g., `deep-learning`, `systems`, `statistics`)
- Type tags (e.g., `foundational`, `applied`, `speculative`)
- Status tags (e.g., `needs-review`, `high-confidence`)

Add to `_meta/lint.sh` Section 10: WARN on tags not in the controlled vocabulary (after vocabulary is defined).

This is a schema edit, not a skill build. Do it before any skill consumes tags.

---

## Files Summary

### New skills (7)
| Skill | Phase | Addresses |
|-------|-------|-----------|
| `karpathy-wiki-reconcile` | 1 | G4, G14 (partial) |
| `karpathy-wiki-trust-audit` | 2 | G3, G12, G13 |
| `karpathy-wiki-conflicts` | 3 | G11 |
| `karpathy-wiki-compose` | 3 | G1 |
| `karpathy-wiki-refactor` | 4 | G2, G9 |
| `karpathy-wiki-meeting` | 5 | G5 |
| `karpathy-wiki-log-query` | 5 | G7 |

### Modified files
| File | Change |
|------|--------|
| `_meta/lint.sh` | Add Sections 7 (structural integrity), 8 (confidence/coverage), 9 (bare conflict links), 10 (tag vocabulary) |
| `_meta/schema.md` | Add valid relation field list, `_exports/` folder, `## Tags` controlled vocabulary |
| `skills/karpathy-wiki-capture/SKILL.md` | Route meeting notes to `karpathy-wiki-meeting` |
| `_meta/log.md` header | Strengthen format spec for machine parseability |
| `.gitignore` | Add `_exports/` |

### Not changed
- All six existing skills (search, ingest, connect, topic-init, review) — no logic changes needed
- All templates — current structure supports all new workflows

---

## Deferred (revisit after 3+ months of vault use)

These gaps are real but require evidence of accumulation before building. Revisit when the vault has meaningful content.

### D1 — Glossary promotion path (G6)
**Condition to revisit:** 10+ glossary stubs with no atom equivalent and no `defines::` backlinks — evidence they're dead ends.  
**Likely shape:** Add a `promote` sub-mode to `karpathy-wiki-refactor` that converts a glossary entry into a full atom, re-pointing all `defines::` links.

### D2 — Tag skill (G8 — skill component)
**Condition to revisit:** Tag vocabulary defined in schema + evidence of tag drift (lint surfacing unknown-tag WARNs regularly).  
**Likely shape:** A lightweight sub-mode of `karpathy-wiki-connect` or `karpathy-wiki-ingest` that suggests controlled tags from the vocabulary during processing.

### D3 — Project lifecycle skill (G10)
**Condition to revisit:** 3+ active projects with meaningful atoms/sources accumulated.  
**Likely shape:** Sub-modes on `karpathy-wiki-refactor` or a new `karpathy-wiki-project` — "advance" (surface atoms relevant to open questions), "close" (archive atoms/sources, write retrospective using compose).

### D4 — Source extraction completeness skill (G13 — skill component)
**Condition to revisit:** Evidence of under-extracted sources surfaced regularly by trust-audit's extraction completeness check.  
**Likely shape:** A "re-process" sub-mode on `karpathy-wiki-connect` that re-opens a `status: processed` source and runs atom extraction again against current atoms.

### D5 — Skill-schema coupling enforcement (G14 — full)
**Condition to revisit:** Evidence of out-of-taxonomy fields appearing in vault notes (lint Section 7 surfacing unknown-relation WARNs repeatedly).  
**Likely shape:** A lint-only extension — no new skill needed. The schema's machine-readable relation list (added in Phase 1B) enables this check to evolve into an error rather than a warning.

---

## Verification

After each phase:
1. Run `bash _meta/lint.sh` — confirm new sections produce correct output on an empty vault and on a populated one
2. Test each new skill with a representative prompt before marking phase complete
3. Skill benchmarking (full eval suite) — run once after Phase 5 is complete, before treating the template as production-ready

Defer benchmarking until all phases are done.
