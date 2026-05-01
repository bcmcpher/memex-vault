---
name: memex-search
description: Search and navigate the personal Karpathy-style Obsidian wiki vault. Use this skill whenever the user wants to recall what they know about a topic, find sources they've saved, trace connections between concepts, answer a research question from their notes, explore what's covered in a domain, or verify a claim with citations. Triggers on: "what do I know about", "find sources on", "search my wiki", "what have I saved about", "what atoms cover", "trace this concept", "do I have notes on", "what's connected to", "find references for", or any research or recall question that should draw from saved knowledge. Also triggers when the user wants to understand the shape of a topic area ("what's in my deep learning notes?") or audit coverage ("what concepts link to X?").
---

# Karpathy Wiki Search

**Vault root:** `/home/bcmcpher/Projects/claude/memex-llm-obsidian-template`

The vault is a layered graph. Search always flows top-down — never scan all sources directly.

```
topics/concepts/  ──►  atoms/  ──►  sources/
  (broad domain)        (concept)     (specific reference)
```

For the full relationship taxonomy, read: `references/vault-schema.md`

---

## Search Workflow

### Step 1: Parse the query
Identify what kind of answer the user needs:

| Query type | Starting point |
|-----------|---------------|
| "What do I know about domain X?" | `topics/concepts/` |
| "What sources support concept Y?" | `atoms/Y.md` → `cites::` |
| "What's related to atom Z?" | `atoms/Z.md` → relationship fields |
| "Define term T" | `glossary/T.md` |
| "What's in my project notes for P?" | `topics/projects/proj-P.md` |
| "Find evidence for/against claim C" | atoms matching C → `contradicts::` |

### Step 2: Scan topic files (broad queries)
Check all three topic directories for matches on filename or `tags` frontmatter:
- `topics/concepts/` — domain concept maps (`covers::` → atoms)
- `topics/research/` — research synthesis notes (`covers::` → atoms, `question:` frontmatter)
- `topics/projects/` — project workspaces (`covers::` → atoms)

If all three are empty (new vault), skip to the grep fallback section below and note that the graph hasn't been populated yet.

Read matching topic files and extract:
- `covers::` — atom list for this domain
- `cites::` — high-level sources
- `related::` — adjacent domains

### Step 3: Read relevant atoms
For each candidate atom, read the file and assess:
- `Summary` — does this answer the query?
- `Detail` — depth needed?
- `cites::` — source files backing this concept
- `extends::` / `uses::` / `part-of::` — neighboring atoms to follow
- `contradicts::` — competing perspectives

Follow relationship chains up to 2 hops. Stop when you have enough material to answer or when the graph thins out.

### Step 4: Surface sources
For each relevant `cites::` link, read the source file and note:
- `url` — the actual reference
- `Summary` / `Key Points` — what the source says
- `status` — `processed` sources are fully integrated; `read` are partially integrated; `unread` are raw

Prefer `processed` sources for authoritative answers. Flag `unread` sources as unverified leads.

### Step 5: Return a structured answer

Always format the response as:

```markdown
## [Query restated]

### What the vault knows
<Synthesized answer, 2–5 sentences, drawn from atom Detail sections>

### Graph path taken
Concept: [[concept-name]] → Atom: [[atom-name]] → Source: [[source-file]]
(list each hop; if multiple paths, list them)

### Sources
| Title | URL | Status |
|-------|-----|--------|
| ...   | ... | processed/read/unread |

### Adjacent concepts worth exploring
- [[related-atom]] — via `extends::` on [[atom-name]]
- [[other-atom]] — via `related::` on [[atom-name]]

### Coverage gaps
(note if important sub-questions have no atoms or only unread sources)
```

---

## Relationship-Driven Queries

To answer specific structural questions, follow these chains:

| Question | Fields to follow |
|----------|-----------------|
| What specializes concept X? | Atoms where `extends:: [[X]]` |
| What depends on concept X? | Atoms where `uses:: [[X]]` |
| What conflicts with X? | `contradicts::` on X; atoms where `contradicts:: [[X]]` |
| What sources back atom X? | `cites::` on atom X → source files |
| What's in domain Y? | Concept map Y → `covers::` list |
| Where is term T defined? | `glossary/T.md` + atoms with `defines:: [[T]]` |
| What sources introduced concept X? | Sources where `introduces:: [[X]]` |

## Grep for When the Graph Comes Up Empty

If concept map and atom traversal yield no results, fall back to text search:

```bash
# Keyword in atom bodies
grep -ril "keyword" /home/bcmcpher/Projects/claude/memex-llm-obsidian-template/atoms/

# Keyword in glossary definitions
grep -ril "keyword" /home/bcmcpher/Projects/claude/memex-llm-obsidian-template/glossary/

# Keyword in source summaries
grep -ril "keyword" /home/bcmcpher/Projects/claude/memex-llm-obsidian-template/sources/

# Find all atoms in a domain by tag
grep -rl "tags:.*deep-learning" /home/bcmcpher/Projects/claude/memex-llm-obsidian-template/atoms/

# Find all uses of a specific relationship
grep -r "extends:: \[\[" /home/bcmcpher/Projects/claude/memex-llm-obsidian-template/atoms/
```

Always report when you fell back to grep, so the user knows the graph coverage is incomplete for this topic.

---

## Handling No Results

If the vault has nothing on the topic:
1. Say so clearly — don't fabricate connections
2. Check if the topic exists in `glossary/` as a bare definition
3. Check `_meta/log.md` for any recently ingested but unprocessed sources (`status: read` or `unread`) that touch the topic
4. Suggest running ingest for relevant URLs, or creating a stub atom to anchor future sources

## Reporting Confidence

When answering from the vault, signal confidence based on source status:
- Atom with multiple `processed` sources → high confidence
- Atom with `confidence: low` or only `unread` sources → flag as tentative
- No atom, only sources → summarize directly from sources and note the gap
