# Domain

Instance vocabulary for this vault. **This is the file a fork edits.**

`_meta/schema.md` is the vault's *constitution* — structure that every memex-vault
shares (relation types, stage values, naming patterns). This file is the
*instance* — the subject matter, the tag vocabulary, and the OKF type names,
all of which change when someone forks the template for a different domain.

`_meta/lint.sh` reads its tag and node-type vocabulary from here, so extending a
vocabulary means editing this file and nothing else. Every block below is a
fenced list parsed line-by-line: one entry per line, blank lines and `#` comments
ignored. Keep the fences.

---

## Domain Name

One line, free text. Used in generated exports and by `memex-init` when
scaffolding a fork.

```
Machine learning, systems, and the science around them
```

---

## Domain Tags

Subject-matter tags. These are the ones a fork almost always replaces wholesale.

```
deep-learning
systems
statistics
mathematics
software-engineering
neuroscience
reinforcement-learning
natural-language-processing
computer-vision
```

---

## Type Tags

What *kind* of thing a note is, independent of subject. Usually survives a fork
unchanged.

```
foundational
applied
speculative
tutorial
reference
survey
```

---

## Stage Tags

Workflow signals attached as tags rather than frontmatter — used to flag notes
for a human pass. Distinct from the `stage:` frontmatter field, which is a
single closed value per node type (see `_meta/schema.md` § Stage Values).

```
needs-review
high-confidence
stale
```

---

## Source Types

Valid values for `medium:` on a source note. Each must have a matching folder
under `sources/`.

```
web
video
paper
docs
meeting
```

---

## OKF Types

Maps each vault folder to the `type:` string written in that folder's
frontmatter. `type:` is required on every node — it is the one field the Open
Knowledge Format makes mandatory (OKF §4.1), and it is what tells a non-Obsidian
reader what a file *is* when the folder layout is gone.

Format: `<folder>|<type>`. The folder is vault-relative and matched as a prefix,
longest match wins. Renaming a type here is a complete rename — `_meta/lint.sh`
validates against this table, and the Phase 8 exporter reads it rather than
hard-coding the strings.

```
sources/web|Source
sources/video|Source
sources/paper|Source
sources/docs|Source
sources/meeting|Source
atoms|Atom
glossary|Glossary Term
topics/concepts|Concept Map
topics/projects|Project
topics/research|Research Question
```

`medium:` remains the source subtype, so nothing is duplicated: a paper is
`type: Source` + `medium: paper`. `topic-type:` was retired in roadmap Phase 2 —
`type:` subsumed it exactly.
