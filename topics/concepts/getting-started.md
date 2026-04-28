---
title: Getting Started
topic-type: concept
tags: [meta, vault, knowledge-management]
created: 2026-04-27
---

## Overview

This is both the entry point to the vault and a working example of the concept map format. Every domain in your wiki gets a file like this one — a navigational hub that aggregates atoms, surfaces key sources, and links to adjacent domains.

**The core workflow in one sentence:** save sources → promote them to atoms → connect atoms into topic maps like this one.

## Core Concepts

<!-- Add atom links below as you create them. Example:
covers:: [[source-types-and-when-to-use-them]]
covers:: [[typed-relationships-dataview]]
covers:: [[atom-confidence-levels]]
-->
covers:: 

## Key Sources

<!-- Link to high-value sources that shaped this domain's understanding -->
cites:: 

## Related Domains

part-of:: 
related:: 

---

## How the Vault Works (Orientation)

### Three layers, one graph

```
topics/concepts/  →  atoms/  →  sources/
```

You rarely navigate to `sources/` directly. Instead, you enter at a concept map (like this file), follow `covers::` to find relevant atoms, and follow each atom's `cites::` links to reach the actual references. This keeps the graph traversable as sources grow indefinitely.

### Creating a new source

Use Claude Code: *"save this article: [url] — [why you saved it]"*

Or manually with Templater (`Ctrl+T`):
- `source-web` for articles and blog posts
- `source-video` for YouTube and talks
- `source-paper` for academic papers and preprints
- `source-docs` for library/API documentation
- `source-meeting` for notes from discussions and calls

All source files go in `sources/<medium>/` with the naming pattern `YYYY-MM-DD-kebab-title.md`.

### Promoting to atoms

After reading a source, ask: does it introduce a concept worth tracking? If yes:
1. Create `atoms/concept-name.md` using the `atom` template
2. Set `confidence: low` for single-source atoms
3. Wire it back: add `cites:: [[source-filename]]` in the atom

### Connecting things

Connections live in the note body as Dataview inline fields:

```
extends:: [[parent-concept]]   ← this atom builds on that one
uses:: [[dependency]]          ← this atom requires that one
part-of:: [[getting-started]]  ← this atom belongs to this topic map
cites:: [[2026-04-27-source]]  ← this atom is backed by that source
```

Obsidian's graph view renders these as edges. Dataview queries (like the tables in `_meta/index.md`) can filter by relationship type.

### Finding things

Use Claude Code: *"what do I know about [topic]?"* — it will traverse the graph and surface atoms and sources for you.

Or manually: start here (or any concept map), follow `covers::`, read the atom, follow `cites::`.

---

## Maintenance

| Task | Frequency | How |
|------|-----------|-----|
| Ingest + summarize new sources | As needed | Templater or Claude Code `karpathy-wiki-ingest` |
| Process read sources into atoms | Weekly | Check `_meta/index.md` → "Read but Not Processed" table |
| Review orphan atoms | Weekly | Check `_meta/index.md` → "Orphan Atoms" table |
| Run programmatic lint | Weekly | `bash _meta/lint.sh` |
| LLM-assisted review | Monthly | Feed a section of the vault to Claude with `_meta/schema.md` as context |

See `_meta/schema.md` for the full linting guide and relationship taxonomy.

---

## Dataview: All Atoms in This Topic

```dataview
LIST FROM "atoms" WHERE contains(part-of, [[Getting Started]])
```

## Dataview: Recently Ingested Sources

```dataview
TABLE medium, saved, status
FROM "sources"
SORT saved DESC
LIMIT 10
```
