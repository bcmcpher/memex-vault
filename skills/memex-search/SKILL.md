---
name: memex-search
description: Search and navigate the personal Karpathy-style Obsidian wiki vault. Use this skill whenever the user wants to recall what they know about a topic, find sources they've saved, trace connections between concepts, answer a research question from their notes, explore what's covered in a domain, or verify a claim with citations. Triggers on: "what do I know about", "find sources on", "search my wiki", "what have I saved about", "what atoms cover", "trace this concept", "do I have notes on", "what's connected to", "find references for", or any research or recall question that should draw from saved knowledge. Also triggers when the user wants to understand the shape of a topic area ("what's in my deep learning notes?") or audit coverage ("what concepts link to X?").
---

# Karpathy Wiki Search

**Vault root:** `/home/bcmcpher/Projects/claude/memex-vault`

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
- `topics/concepts/` — domain concept maps
- `topics/research/` — research synthesis notes (`question:` frontmatter)
- `topics/projects/` — project workspaces

Topic files do not list their atoms. Membership is declared on each atom's
`part-of::` and surfaced by Dataview, so to walk from a topic to its atoms:

```bash
grep -rlE "^part-of::.*\[\[<topic>\]\]" "$VAULT/atoms/"
```

If all three are empty (new vault), skip to the grep fallback section below and note that the graph hasn't been populated yet.

Read matching topic files and extract:
- member atoms — by the reverse lookup above
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
- `stage` — `processed` sources are fully integrated; `read` are partially integrated; `unread` are raw

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
| What sources back atom X? | `cites::` on atom X → source files (a `#^cNN` anchor lands on one claim in an extract) |
| What exactly did source S say about X? | `extracts/ext-<S>.md` → the claim whose `about:` names X |
| What's in domain Y? | Atoms where `part-of:: [[Y]]` |
| Where is term T defined? | `glossary/T.md` + atoms with `defines:: [[T]]` |
| What sources introduced concept X? | Sources where `introduces:: [[X]]` |

## Grep for When the Graph Comes Up Empty

If concept map and atom traversal yield no results, fall back to text search:

```bash
# Keyword in atom bodies
grep -ril "keyword" /home/bcmcpher/Projects/claude/memex-vault/atoms/

# Keyword in glossary definitions
grep -ril "keyword" /home/bcmcpher/Projects/claude/memex-vault/glossary/

# Keyword in source summaries
grep -ril "keyword" /home/bcmcpher/Projects/claude/memex-vault/sources/

# Find all atoms in a domain by tag
grep -rl "tags:.*deep-learning" /home/bcmcpher/Projects/claude/memex-vault/atoms/

# Find all uses of a specific relationship
grep -r "extends:: \[\[" /home/bcmcpher/Projects/claude/memex-vault/atoms/
```

Always report when you fell back to grep, so the user knows the graph coverage is incomplete for this topic.

### Extracts: a gap-finding surface, never an answer surface

`extracts/` holds claim-level readings of sources — structured, typed, and
quote-grounded. That structure is why the usual objection to grepping sources
(unranked hits with no epistemic status) does not apply to them.

It does **not** make them an answer surface. Reach a claim the normal way, through
an atom's `cites:: [[ext-…#^cNN]]`. Searching extracts directly is a **last**
fallback, after atoms, glossary, and sources have all come up empty:

```bash
VAULT=/home/bcmcpher/Projects/claude/memex-vault
grep -ril "keyword" "$VAULT/extracts/"
```

Every hit is reported as **unpromoted evidence, not vault knowledge**:

> "No atom covers this. `extracts/ext-2026-04-27-lewis-rag.md` has 4 claims about
> it (`^c12`, `^c19`, `^c23`, `^c31`) — evidence was collected and never curated
> into a concept. Run `memex-deep-extract` mode B to promote it, or
> `memex-topic-emerge` if the same concepts recur across several extracts."

That framing is the whole point. It answers a question nothing else in the vault
can — *where has evidence been collected that no concept has been formed from?* —
while keeping the curation discipline intact. Presenting an extract hit as an
answer would quietly make the vault's knowledge whatever happened to get scraped.

---

## Handling No Results

If the vault has nothing on the topic:
1. Say so clearly — don't fabricate connections
2. Check if the topic exists in `glossary/` as a bare definition
3. Check `_meta/log.md` for any recently ingested but unprocessed sources (`stage: read` or `unread`) that touch the topic
4. Check `extracts/` last, and report any hit as unpromoted evidence (above)
5. Suggest running ingest for relevant URLs, or creating a stub atom to anchor future sources

## Reporting Confidence

When answering from the vault, signal confidence based on source stage:
- Atom with multiple `processed` sources → high confidence
- Atom with `confidence: low` or only `unread` sources → flag as tentative
- No atom, only sources → summarize directly from sources and note the gap
- No atom, only extracts → **unpromoted evidence**, never presented as knowledge

Note that source *count* is a weak signal: per `_meta/schema.md` § Confidence
Values, the unit is independent claims across independent sources, and three
posts about one paper are one piece of evidence. An atom whose `cites::` are
block-anchored (`[[ext-…#^cNN]]`) has been checked at claim level; one whose
citations are all bare has been counted, not checked. Say which.
