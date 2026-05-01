---
name: memex-ingest
description: Ingest a new source into the personal Karpathy-style Obsidian wiki vault. Use this skill whenever the user wants to save a URL, bookmark an article, video, paper, or docs page, record meeting notes, or promote saved content into concept atoms or glossary terms. Triggers on: "save this", "add to wiki", "ingest", "bookmark this", "I want to remember this article/video/paper", "add this to my notes", "capture this link", "take notes on this meeting", or any time the user shares a URL alongside research intent. Also triggers when the user says "create an atom for X", "add a glossary term for Y", or "update my wiki with this".
---

# Karpathy Wiki Ingest

**Vault root:** `/home/bcmcpher/Projects/claude/memex-vault`

This vault uses a layered structure: raw sources feed concept atoms, which feed topic maps. Your job here is to create a well-formed source note, connect it to existing atoms, and optionally seed new atoms — keeping the graph growing without duplicating work.

For quick saves without graph wiring, use `memex-capture`. To process accumulated inbox notes, use `memex-connect`.

For the relationship taxonomy and full field definitions, read: `references/vault-schema.md`

---

## Quick Reference: Source Types

| Medium | Folder | Clues |
|--------|--------|-------|
| Web article / blog | `sources/web/` | General URLs, blog posts, newsletters |
| YouTube / video | `sources/video/` | `youtube.com`, `youtu.be`, Vimeo, conference talks |
| Academic paper | `sources/paper/` | `arxiv.org`, `doi.org`, journal sites |
| Docs / API reference | `sources/docs/` | `docs.*`, `*.readthedocs.io`, official library sites |
| Meeting / discussion | `sources/meeting/` | No URL; in-person or virtual conversation |

All digital sources use `_templates/source-digital.md`. Meetings use `_templates/source-meeting.md`.

---

## Workflow

### 1. Classify the source
Infer the medium from the URL or context. If genuinely ambiguous, ask.

### 2. Fetch the URL
Fetch the URL immediately to extract metadata. Use what you find to fill the template accurately.

**By medium:**
- **Web**: extract title, author, publication date, and offer a summary draft from the lead paragraphs
- **arXiv/paper**: fetch the abstract page; extract title, authors array, year, venue, and write the abstract as `## Summary`
- **YouTube/video**: extract title and channel name from the page; note that full transcripts require an optional MCP server (see README)
- **Docs**: extract title, tool name from subdomain/title, version from URL path if present
- **PDFs** (URL ends in `.pdf`): cannot extract via fetch — ask the user for title, authors, year, and a brief summary directly
- **Paywalled/failed**: ask the user to paste the key fields

### 3. Determine filename
Pattern: `YYYY-MM-DD-kebab-title.md`  
**Use today's date — never the publication date.**  
Derive the slug from the real title (now known from the fetch), drop articles, max ~6 words.

Confirm the filename before writing if there's any ambiguity.

### 4. Fill the template
Write the file to the correct subfolder using `_templates/source-digital.md` as the base.

Universal frontmatter fields (all digital sources):
```yaml
title: <from fetch>
url: <url>
medium: <web|video|paper|docs>
saved: <today YYYY-MM-DD>
tags: []
status: unread
```

Type-specific fields to add:
- **Paper**: `authors: []`, `year:`, optionally `venue:`
- **Video**: `channel:`
- **Docs**: `tool:`, optionally `version:`, `section:`

Ask the user for:
- **Why Saved** — what specific question or project prompted this? (1–3 sentences, their own words)
- **Summary** — offer a draft from the fetched content; ask them to edit
- **Key Points** — offer to draft from fetched content

Never reproduce full article text. Summaries only.

**Meeting notes** use `_templates/source-meeting.md` with `date` instead of `saved`, `attendees[]`, `context`, `status: unprocessed`. No URL.

### 5. Wire up connections
Ask which existing atoms or concepts this source relates to. Check for likely candidates:

```bash
VAULT=/home/bcmcpher/Projects/claude/memex-vault
ls "$VAULT/atoms/" | grep -i "keyword"
grep -rl "keyword" "$VAULT/atoms/"
```

Then write the Dataview inline fields under `## Connections`:

```
supports:: [[Relevant Atom]]
introduces:: [[New Concept]]
challenges:: [[Claim This Source Questions]]
refutes:: [[Claim With Counter-Evidence]]
cites:: [[Prior Work]]
related:: [[Adjacent Concept]]
```

Use `challenges::` when the source questions a claim without fully refuting it. Use `refutes::` when it provides direct counter-evidence. Use `related::` only as a fallback — it can be refined during the monthly review. See `references/vault-schema.md` for the full decision tree.

### 6. Promote to atoms (optional but encouraged)
If the source introduces a concept not yet in `atoms/`, offer to create a stub. A good atom candidate is any concept that:
- Appears in the source's title or abstract
- Would be referenced from multiple future sources
- Isn't already covered by an existing atom

Stub atom format (save to `atoms/kebab-concept.md`):
```markdown
---
title: Concept Name
aliases: []
tags: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
confidence: low
---

## Summary
<!-- One-sentence summary from this source -->

## Detail
<!-- Expand later -->

## Sources
cites:: [[source-filename]]

## Connections
part-of:: 
related:: 
```

Set `confidence: low` for single-source atoms. Upgrade to `medium` when two or more independent sources support it.

### 7. Add glossary terms (optional)

If the source defines a specific technical term precisely — and that term's value is the definition itself rather than a claim worth accumulating evidence for — offer a glossary stub.

**Glossary vs. atom decision:**
- **Glossary**: the term has a stable, non-controversial definition; other notes will reference it via `defines::` rather than `supports::` or `introduces::`
- **Atom**: the concept makes claims, can accumulate evidence from multiple sources, or connects structurally to other concepts → use Step 6 instead

For each glossary candidate, ask: "Create a glossary stub for '[term]'? (Yes / Skip)"

If yes, create `glossary/kebab-term.md`:
```markdown
---
title: Term Name
term: term name
aliases: []
domain: <inferred from topic area>
tags: []
created: YYYY-MM-DD
status: stub
---

## Definition
<one or two sentences — draft from the source's own language>

## Usage Notes
<!-- When/how the term is used; common confusions -->

## Source
cites:: [[source-filename]]
```

Then add `defines:: [[term-name]]` to the source note's `## Connections` section.

Ask before creating each stub — do not auto-create.

### 8. Update the ingest log
Append to `_meta/log.md`:
```markdown
## [YYYY-MM-DD] <medium> | <Title>
url:: <url or n/a>
atoms:: [[Atom A]], [[Atom B]]
skill:: memex-ingest
notes: <optional>
```

---

## Archive (optional)
If the user wants to preserve the full source text locally (for offline access or link-rot protection), save it to:
```
.archive/YYYY-MM-DD-slug.md
```
Then add to the source note: `raw:: .archive/YYYY-MM-DD-slug.md`

The `.archive/` folder is gitignored and excluded from Obsidian's indexer — it won't appear in the graph.

---

## Common Mistakes to Avoid
- Don't ingest a source that's already in `sources/` under a different filename — check before creating
- Don't create an atom for a term that already exists in `glossary/` or vice versa
- Don't leave `related::` as the only connection on every note — push for `supports::` or `introduces::` when the relationship is clear
- Meetings don't have `url` fields; don't add one
