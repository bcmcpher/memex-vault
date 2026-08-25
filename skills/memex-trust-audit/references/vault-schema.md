# Vault Schema Reference

This is a condensed version of `_meta/schema.md` bundled for offline reference.
Tag vocabulary lives in `_meta/domain.md`.

## Node Types

`type:` is required on every curated node and is the single node-type
discriminator. `medium:` is the *sub*type of a source.

| Folder | `type:` | Other required fields |
|--------|---------|-----------------------|
| `sources/<medium>/` | `Source` | `title`, `url`, `medium`, `saved`, `stage` (meetings: `date` not `url`/`saved`) |
| `atoms/` | `Atom` | `title`, `created`, `confidence` |
| `glossary/` | `Glossary Term` | `title`, `term`, `domain`, `stage` |
| `topics/concepts/` | `Concept Map` | `title` |
| `topics/projects/` | `Project` | `title`, `stage` |
| `topics/research/` | `Research Question` | `title`, `question` |

`description:` (one sentence) is optional but expected on every node.
`topic-type:` was retired in roadmap Phase 2 — `type:` subsumes it.

## Relationship Fields (Dataview Inline)

Syntax: `relation:: [[Target]]` or `relation:: [[A]], [[B]]` in the note body (not frontmatter).

### Source → Atom/Topic — Affirmative
| Field | Meaning |
|-------|---------|
| `supports::` | Source provides evidence for a claim in this atom |
| `introduces::` | Source is where this concept first appears in the vault |
| `demonstrates::` | Source shows a concrete worked example |

### Source → Atom/Topic — Skeptical
| Field | Meaning |
|-------|---------|
| `challenges::` | Source questions or weakens a claim; describe the tension in the atom body |
| `refutes::` | Source provides direct counter-evidence; stronger than `challenges::` |

### Atom → Atom — Structural
| Field | Meaning |
|-------|---------|
| `extends::` | Builds on / specializes another concept |
| `uses::` | Applies or depends on another concept |
| `part-of::` | Component of a broader concept; drives concept map membership |

### Atom → Atom — Epistemic
| Field | Meaning |
|-------|---------|
| `contradicts::` | Direct logical conflict; document tension in both atoms |
| `challenges::` | Weakens or questions without direct contradiction |
| `supersedes::` | Replaces or obsoletes the target in modern understanding |
| `limits::` | Defines where the target breaks down or only partially applies |
| `contrasts-with::` | Alternative approach to the same problem; not contradictory |

### Any → Source
| Field | Meaning |
|-------|---------|
| `cites::` | References that source as evidence (affirmative or neutral) |
| `rebuts::` | References that source as counter-evidence |

### Any → Glossary
| Field | Meaning |
|-------|---------|
| `defines::` | Canonical definition for this term |

### Topic → Atoms

**Derived, not written.** Topic membership lives only on the atom's `part-of::`.
Topics do not list their atoms; `covers::` was retired in roadmap Phase 1. To get
a topic's atoms, reverse-lookup:

```bash
grep -rlE "^part-of::.*\[\[<topic-slug>\]\]" "$VAULT/atoms/"
```

### Navigational
| Field | Meaning |
|-------|---------|
| `related::` | Loosely connected; fallback only — refine monthly |

## Stage Values

`stage:` is the workflow field. It is **not** called `status:` — that key is
reserved for the Open Knowledge Format's document lifecycle (`draft` / `stable` /
`deprecated`) and is synthesized only at export. `status:` in a vault note is a
lint failure.

**Sources:** `unread` → `read` → `processed`  
**Meetings:** `unprocessed` → `processed`  
**Projects:** `active` / `paused` / `complete` / `abandoned`  
**Glossary:** `stub` → `reviewed`  
**Candidates:** `pending` → `reviewed`

Atoms have no `stage:`.

## Confidence Values

Atoms only. Measures evidence strength: `low` / `medium` / `high`.

Orthogonal to `verified:` — confidence is how much evidence stands behind a
claim, `verified:` is who checked it.

## Provenance

| Field | Written | Shape |
|-------|---------|-------|
| `generated:` | once, at creation | `{ by: <producer>/<version>, at: YYYY-MM-DD }` |
| `verified:` | appended on human sign-off | list of `{ by: human:<id>, at: YYYY-MM-DD }` |

Actor forms: `<producer>/<version>`, `human:<id>`, `process:<id>`.

## Tags

Controlled vocabulary lives in `_meta/domain.md` — *Domain Tags*, *Type Tags*,
*Stage Tags*. Read it before assigning `tags:`; lint warns on anything not
listed. Add the tag to `_meta/domain.md` first if it genuinely belongs.

## Naming Conventions

| Type | Pattern |
|------|---------|
| Sources (non-meeting) | `YYYY-MM-DD-kebab-title.md` |
| Meetings | `YYYY-MM-DD-kebab-context.md` |
| Atoms | `kebab-concept-name.md` |
| Glossary | `term.md` |
| Concept maps | `kebab-domain.md` |
| Projects | `proj-kebab-name.md` |
| Research | `rq-kebab-question.md` |
