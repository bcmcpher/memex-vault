# Vault Schema Reference

This is a condensed version of `_meta/schema.md` bundled for offline reference.

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
| Field | Meaning |
|-------|---------|
| `covers::` | This concept map covers these atoms |

### Navigational
| Field | Meaning |
|-------|---------|
| `related::` | Loosely connected; fallback only — refine monthly |

## Status Values

**Sources:** `unread` → `read` → `processed`  
**Meetings:** `unprocessed` → `processed`  
**Projects:** `active` / `paused` / `complete` / `abandoned`  
**Atoms (confidence):** `low` / `medium` / `high`

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
