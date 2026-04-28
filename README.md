# Personal Knowledge Wiki

A Karpathy-style personal wiki for accumulating and connecting knowledge from web articles, videos, academic papers, technical documentation, and meetings. Inspired by [Andrej Karpathy's LLM wiki concept](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).

---

## Concept

This vault is a **layered knowledge graph**, not a flat bookmark list. Sources are never searched directly — instead, they feed upward into concept atoms, which feed upward into topic maps. Search flows top-down:

```
topics/concepts/  →  atoms/  →  sources/
  (broad domain)      (concept)   (specific reference)
```

Every connection between notes is typed (e.g., `extends::`, `supports::`, `cites::`), making the graph navigable by relationship kind — not just by link existence.

---

## Folder Structure

```
vault/
├── _templates/               # Templater input templates (not indexed)
│   ├── source-web.md
│   ├── source-video.md
│   ├── source-paper.md
│   ├── source-docs.md
│   ├── source-meeting.md
│   ├── atom.md
│   ├── glossary.md
│   ├── topic-concept.md
│   ├── topic-project.md
│   └── topic-research.md
│
├── _meta/                    # Infrastructure
│   ├── index.md              # Live Dataview catalog of all notes
│   ├── log.md                # Append-only ingest history
│   ├── schema.md             # Relationship types, naming conventions (authoritative)
│   └── lint.sh               # Programmatic health checks
│
├── sources/                  # One file per URL or meeting — summary only
│   ├── web/
│   ├── video/
│   ├── paper/
│   ├── docs/
│   └── meeting/
│
├── atoms/                    # One concept per file (Wikipedia stub granularity)
├── glossary/                 # One term definition per file
│
├── topics/
│   ├── concepts/             # Domain-level maps linking atoms
│   ├── projects/             # Project brainstorm workspaces
│   └── research/             # Research synthesis across multiple sources
│
├── canvas/                   # Optional visual maps (.canvas files)
└── .archive/                 # Gitignored; optional full-text source backups
```

---

## Node Types

| Type | Role | Granularity |
|------|------|-------------|
| `sources/` | URL + why-saved + short summary. Never full article text. | One per URL or meeting |
| `atoms/` | Concept-level synthesis. Holds claims, links sources, connects to other atoms. | One concept per file |
| `glossary/` | Precise term definitions. Lighter than atoms. | One term per file |
| `topics/concepts/` | Domain map — aggregates atoms, provides broad entry point. | One domain per file |
| `topics/projects/` | Brainstorm workspace for active work. | One project per file |
| `topics/research/` | Cross-source synthesis for a specific research question. | One question per file |

---

## Relationship Taxonomy

Connections are **Dataview inline fields** written in note bodies, not frontmatter:

```
extends:: [[Other Atom]]
cites:: [[source-filename]]
```

| Field | Direction | Meaning |
|-------|-----------|---------|
| `supports::` | source → atom/topic | Source provides evidence for this concept |
| `introduces::` | source → atom | Source is where this concept first appeared in vault |
| `demonstrates::` | source → atom | Source shows a concrete example |
| `extends::` | atom → atom | Builds on / specializes another concept |
| `uses::` | atom → atom | Applies or depends on another concept |
| `contradicts::` | atom → atom | Conflicts with another concept |
| `part-of::` | atom → atom | Component of a larger concept |
| `related::` | any → any | Loosely connected (fallback; refine monthly) |
| `cites::` | any → source | References a source as evidence |
| `defines::` | any → glossary | Elaborates or defines a glossary term |
| `covers::` | topic → atom | This topic map covers these atoms |

Full taxonomy and status values: `_meta/schema.md`

---

## Required Obsidian Plugins

### Core (built-in, enable in Settings → Core Plugins)

| Plugin | Why |
|--------|-----|
| **Backlinks** | See all notes that link to the current note — essential for reverse graph traversal |
| **Graph view** | Visualize the knowledge graph |
| **Properties** | Visual frontmatter editor |
| **Tags** | Tag-based filtering |

### Community (Settings → Community Plugins → Browse)

| Plugin | Why | Install name |
|--------|-----|--------------|
| **Templater** | Required — auto-fills `saved` date, file title, and Dataview queries in templates | `templater-obsidian` |
| **Dataview** | Required — powers `index.md` catalogs and inline relationship field queries | `dataview` |
| **Folder Notes** | Makes folder-level overview notes work cleanly | `folder-notes` |
| **Graph Analysis** | Adds co-citation and link prediction to the graph view | `graph-analysis` |

---

## Obsidian Configuration

### 1. Templater setup
`Settings → Templater`:
- **Template folder location:** `_templates`
- Enable **Trigger Templater on new file creation** (optional but recommended)
- Set a hotkey for **Create new note from template** (e.g., `Ctrl+T`)

### 2. Dataview setup
`Settings → Dataview`:
- Enable **Inline queries** — required for `extends::`, `cites::`, etc. to be queryable
- Enable **Dataview JS queries** (optional; needed only for advanced index queries)
- Set **Refresh interval** to `2500ms` or lower for responsive live tables

### 3. Exclude archive from indexing
Already configured in `.obsidian/app.json`. The `.archive/` folder will not appear in file explorer, graph, or search results. To verify: `Settings → Files & Links → Excluded files` should show `.archive`.

### 4. Graph view coloring (optional but recommended)
`Settings → Graph view → Groups`:
- Add group: `path:sources/` → color orange
- Add group: `path:atoms/` → color blue
- Add group: `path:glossary/` → color green
- Add group: `path:topics/` → color purple

This makes source/atom/topic layers visually distinct in the graph.

### 5. File naming
`Settings → Files & Links`:
- **Default location for new notes:** set to a sensible default or leave as vault root
- Templates auto-assign the correct folder — always use Templater to create notes

---

## Daily Workflow

### Ingesting a new source
1. Use Claude Code with the `karpathy-wiki-ingest` skill: *"save this article: [url] — [why you saved it]"*
2. Or manually: `Ctrl+T` → pick the right source template → fill in **Why Saved**, **Summary**, **Key Points**, and connection fields
3. Append an entry to `_meta/log.md`

### Promoting to atoms
After reading a source (`status: read`), consider:
- Does it introduce a concept not yet in `atoms/`? → Create an atom stub
- Does it define a term? → Add a glossary entry
- Does it support or contradict an existing atom? → Update that atom's connections

### Searching your knowledge
Use Claude Code with the `karpathy-wiki-search` skill: *"what do I know about [topic]?"*

Or manually: start at `topics/concepts/`, follow `covers::` to atoms, follow `cites::` to sources.

### Maintenance
- **Weekly:** Open `_meta/index.md` — review the "Stale Unread Sources" and "Orphan Atoms" tables
- **Monthly:** Run `bash _meta/lint.sh` for programmatic checks; run one LLM-assisted check category (see `_meta/schema.md` → Linting section)

---

## Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Sources (non-meeting) | `YYYY-MM-DD-kebab-title.md` | `2026-04-27-attention-is-all-you-need.md` |
| Meetings | `YYYY-MM-DD-kebab-context.md` | `2026-04-27-rag-architecture-sync.md` |
| Atoms | `kebab-concept-name.md` | `transformer-architecture.md` |
| Glossary | `term.md` | `self-attention.md` |
| Concept maps | `kebab-domain.md` | `deep-learning.md` |
| Projects | `proj-kebab-name.md` | `proj-rag-pipeline.md` |
| Research notes | `rq-kebab-question.md` | `rq-scaling-laws-llms.md` |

---

## Source Text Archival

Full article/transcript text is **not stored in the vault** by default. The `.archive/` folder provides an opt-in escape hatch:

1. Save full text to `.archive/YYYY-MM-DD-slug.md`
2. Add `raw:: .archive/YYYY-MM-DD-slug.md` to the source note

The archive is gitignored and excluded from Obsidian's indexer — it stays invisible to the graph and doesn't slow sync.

**When to use it:** High-value sources at risk of link rot; long-form content you expect to re-read in full; papers you need offline.

---

## Claude Code Skills

Two skills are installed at `~/.claude/skills/` for daily vault use:

| Skill | Trigger phrase | What it does |
|-------|---------------|--------------|
| `karpathy-wiki-ingest` | "save this", "add to wiki", "bookmark", "ingest" | Creates the correct source note, guides connections, seeds atoms |
| `karpathy-wiki-search` | "what do I know about", "find sources on", "search my wiki" | Navigates graph top-down, surfaces sources with citations |

---

## Further Reading

- [Karpathy's original LLM wiki concept](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
- [Extended memory hierarchy discussion](https://gist.github.com/rohitg00/2067ab416f7bbe447c1977edaaa681e2)
- [llm-atomic-wiki (linting patterns)](https://github.com/cablate/llm-atomic-wiki)
- [claude-obsidian (Obsidian integration)](https://github.com/AgriciDaniel/claude-obsidian)
