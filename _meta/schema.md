# Schema

This file is the vault's constitution. Update it when adding or retiring relationship types, node types, status values, or naming conventions. All other notes defer to it.

---

## Node Types

| Type | Folder | Granularity | Required Fields |
|------|--------|-------------|-----------------|
| Source (web) | `sources/web/` | One file per URL | `title`, `url`, `medium`, `saved`, `status` |
| Source (video) | `sources/video/` | One file per URL | `title`, `url`, `medium`, `channel`, `saved`, `status` |
| Source (paper) | `sources/paper/` | One file per URL | `title`, `url`, `medium`, `authors`, `year`, `saved`, `status` |
| Source (docs) | `sources/docs/` | One file per URL | `title`, `url`, `medium`, `tool`, `saved`, `status` |
| Source (meeting) | `sources/meeting/` | One file per meeting | `title`, `medium`, `date`, `status` |
| Atom | `atoms/` | One concept per file | `title`, `created`, `confidence` |
| Glossary | `glossary/` | One term per file | `title`, `term`, `domain`, `status` |
| Concept map | `topics/concepts/` | One domain per file | `title`, `topic-type` |
| Project | `topics/projects/` | One project per file | `title`, `topic-type`, `status` |
| Research | `topics/research/` | One research question per file | `title`, `topic-type`, `question` |
| Export | `_exports/` | One file per compose session | (generated — no required frontmatter) |
| Candidate | `_meta/candidates/` | One file per proposed write | `proposed`, `skill`, `action`, `target`, `session`, `status` |

---

## Relationship Types (Dataview Inline Fields)

Syntax: `relation:: [[Target Note]]` or `relation:: [[A]], [[B]]` in note body.

Relationships are grouped by **epistemic role**: affirmative (source builds on target), skeptical (source questions or limits target), structural (hierarchy and dependency), and navigational (fallback / cross-domain).

### Source → Atom/Topic — Affirmative
| Field | Meaning |
|-------|---------|
| `supports::` | Source provides evidence for a claim in this atom |
| `introduces::` | Source is where this concept first appears in the vault |
| `demonstrates::` | Source shows a concrete worked example of the concept |

### Source → Atom/Topic — Skeptical
| Field | Meaning |
|-------|---------|
| `challenges::` | Source questions or weakens a claim without fully refuting it; the tension should be described in the atom body |
| `refutes::` | Source provides evidence directly against the claim; stronger than `challenges::` |

### Atom → Atom — Structural
| Field | Meaning |
|-------|---------|
| `extends::` | Builds on / specializes another concept (A is a subtype or elaboration of B) |
| `uses::` | Applies or depends on another concept (A requires B to function) |
| `part-of::` | Component of a broader concept; drives concept map membership |

### Atom → Atom — Epistemic
| Field | Meaning |
|-------|---------|
| `contradicts::` | Direct logical conflict with another concept or claim; document the tension in both atoms |
| `challenges::` | A weakens or questions B without direct contradiction; softer than `contradicts::` |
| `supersedes::` | A replaces or obsoletes B in modern understanding; B remains for historical context |
| `limits::` | A defines the boundary conditions or failure modes where B breaks down or only partially applies |
| `contrasts-with::` | A is an alternative approach to the same problem as B; not contradictory, just different |

### Any Note → Source
| Field | Meaning |
|-------|---------|
| `cites::` | This note references that source as evidence (affirmative or neutral) |
| `rebuts::` | This note references that source as counter-evidence to a claim |

**Provenance anchors:** Use `[[note#Section]]` heading anchors on `cites::` to record which section of a source supports the specific claim in this atom. Valid section names match the source note's `##` headings: `Summary`, `Key Points`, `Why Saved`, `Decisions Made`, `Key Concepts Discussed`. Example: `cites:: [[2026-04-27-flash-attention#Key Points]]`. Bare `[[note]]` remains valid when the whole source is relevant or the section is indeterminate. Multiple sources may mix anchored and bare forms on the same field.

### Any Note → Glossary
| Field | Meaning |
|-------|---------|
| `defines::` | This note elaborates or is the canonical definition for this term |

### Topic → Atoms
| Field | Meaning |
|-------|---------|
| `covers::` | This concept map / research note covers these atoms |

### Navigational (any → any)
| Field | Meaning |
|-------|---------|
| `related::` | Loosely connected; use as a fallback only — review monthly for a more precise type |

---

### Choosing Between Skeptical Relations

```
Source challenges an atom?
  └─ Is there direct empirical counter-evidence?
       ├─ Yes → refutes::
       └─ No  → challenges::

Atom A questions atom B?
  └─ Are they logically incompatible?
       ├─ Yes → contradicts::
       └─ No  → Does A define where B fails?
                  ├─ Yes → limits::
                  └─ No  → Is A an older version replaced by B?
                              ├─ Yes → B supersedes:: A
                              └─ No  → contrasts-with:: (different approach)
```

When using `challenges::`, `refutes::`, or `contradicts::`, always write a sentence in the note body explaining the specific tension. Bare link with no context is not useful.

---

## Status Values

### Sources
| Value | Meaning |
|-------|---------|
| `unread` | Saved, not yet read |
| `read` | Read, not yet processed into atoms |
| `processed` | Connections and atoms created |

### Meeting
| Value | Meaning |
|-------|---------|
| `unprocessed` | Notes taken, follow-ups not yet acted on |
| `processed` | Action items done, follow-up sources captured |

### Atoms
| Value (confidence) | Meaning |
|--------------------|---------|
| `low` | Single source, speculative |
| `medium` | Multiple sources or well-established |
| `high` | Extensively sourced, cross-validated |

### Projects
| Value | Meaning |
|-------|---------|
| `active` | In progress |
| `paused` | On hold |
| `complete` | Finished |
| `abandoned` | Dropped |

### Glossary
| Value | Meaning |
|-------|---------|
| `stub` | Created opportunistically; definition drafted but not reviewed for operational precision |
| `reviewed` | Definition vetted for operational precision via `memex-glossary` workflow |

---

## Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Sources (all except meeting) | `YYYY-MM-DD-kebab-title.md` | `2026-04-27-attention-is-all-you-need.md` |
| Meetings | `YYYY-MM-DD-kebab-context.md` | `2026-04-27-team-rag-sync.md` |
| Atoms | `kebab-concept-name.md` | `transformer-architecture.md` |
| Glossary | `term.md` (lowercase, hyphenated) | `self-attention.md` |
| Concept maps | `kebab-domain.md` | `deep-learning.md` |
| Projects | `proj-kebab-name.md` | `proj-rag-pipeline.md` |
| Research | `rq-kebab-question.md` | `rq-scaling-laws-llms.md` |

---

## Archive

Full source text may optionally be saved to `.archive/YYYY-MM-DD-slug.md`. This folder is gitignored and excluded from Obsidian's indexer. Reference it from a source note with:

```
raw:: .archive/2026-04-27-slug.md
```

---

## Workflow Stages

Skills that write vault notes, and what they produce:

| Skill | What it creates | Graph wiring | Log entry |
|-------|----------------|--------------|-----------|
| `memex-capture` | Source note (metadata + summary) | None | No |
| `memex-ingest` | Source note + atoms + connections | Full | Yes |
| `memex-connect` | Updates existing unread notes | Full | Yes |
| `memex-meeting` | Meeting source note + atom/glossary stubs | Full | Yes |
| `memex-topic-init` | New topic map + atom back-wires | Full | No |
| `memex-refactor` | Rewrites/splits/merges existing atoms | Varies | No |
| `memex-glossary` | Glossary entries from existing notes | `defines::` only | No |
| `memex-candidates` | Applies pending candidates from `_meta/candidates/` | Varies | No |
| `memex-compose` | Export document in `_exports/` | None (read-only) | Yes |

---

## Candidate Lifecycle

Candidate files in `_meta/candidates/` are ephemeral proposals written by writing skills before each vault change. They make proposed content durable across session drops. Use `memex-candidates` to review and apply pending candidates.

**Two candidate types:**

*Create candidate* — full proposed file content in body:
```markdown
---
proposed: YYYY-MM-DD HH:MM
skill: memex-ingest
action: create
target: atoms/flash-attention.md
session: YYYY-MM-DD-HHMM
status: pending
---

[full file content to write]
```

*Modify candidate* — structured append to a specific section:
```markdown
---
proposed: YYYY-MM-DD HH:MM
skill: memex-connect
action: modify
target: atoms/attention-mechanism.md
section: "## Sources"
change: append
session: YYYY-MM-DD-HHMM
status: pending
---

cites:: [[2026-05-01-flash-attention#Key Points]]
```

**Lifecycle:** Candidate written → user confirms interactively → vault file written → candidate deleted. If session ends before confirmation, candidate persists. `memex-candidates` resurfaces pending candidates for approval or rejection.

**File naming:** `YYYY-MM-DD-HHMMSS-{action}-{target-slug}.md`

`_meta/candidates/` is gitignored — candidates are ephemeral working state, not vault history.

---

A source note with `status: unread` and no populated Dataview fields in `## Connections` is considered **inbox-only** — captured but not yet integrated into the graph. Run `memex-connect` to process inbox notes.

A source can legitimately have multiple targets on a single relation field (e.g., a conference talk citing several papers via `cites:: [[Paper A]], [[Paper B]]`). This is not a schema violation — multiple `cites::` entries on one source note are expected and correct.

---

## Lint Heuristics (Informational)

These thresholds are soft signals surfaced as WARNings, not hard failures. They flag candidates for human review, not automatic fixes.

| Check | Level | Threshold | Notes |
|-------|-------|-----------|-------|
| Source: unread + no Connections | Source | any | Inbox-only; run `memex-connect` |
| Atom: no populated relations | Atom | any | Fully isolated atom; check for orphan or missing wiring |
| Atom: bloated | Atom | `cites::` > 5 AND `related::` > 4 AND body > 100 lines | May cover multiple concepts; consider splitting |
| Topic map: too many atoms | Concept map | `covers::` > 15 entries | May span multiple domains; consider sub-topics |

Note: high `cites::` count on a **source** note is not a smell. A survey paper or conference talk legitimately references many prior works.

---

## Valid Relation Fields

Machine-readable list used by `_meta/lint.sh` Section 7 to detect unknown relation fields. Update this list when adding or retiring relation types.

```
supports
introduces
demonstrates
challenges
refutes
extends
uses
part-of
contradicts
supersedes
limits
contrasts-with
cites
rebuts
defines
covers
related
raw
```

---

## Tags

Controlled vocabulary for `tags:` frontmatter. Lint Section 10 warns on tags not in this list. Add new tags here before using them.

### Domain tags
- `deep-learning`
- `systems`
- `statistics`
- `mathematics`
- `software-engineering`
- `neuroscience`
- `reinforcement-learning`
- `natural-language-processing`
- `computer-vision`

### Type tags
- `foundational`
- `applied`
- `speculative`
- `tutorial`
- `reference`
- `survey`

### Status tags
- `needs-review`
- `high-confidence`
- `stale`
