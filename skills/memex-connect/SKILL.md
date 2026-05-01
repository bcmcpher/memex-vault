---
name: memex-connect
description: Wire captured sources into the knowledge graph. Use when the user wants to process their inbox, integrate accumulated unread notes, or add connections between existing notes. Triggers on: "process my inbox", "wire up my unread notes", "connect my captures", "integrate my sources", "link my notes to atoms", "I want to process what I've saved". Also triggers for targeted connection work: "add connections to this note", "wire this source into the graph", "link [note] to [concept]". This skill does not capture new sources — use memex-capture or memex-ingest for that.
---

# Karpathy Wiki Connect

**Vault root:** `/home/bcmcpher/Projects/claude/memex-vault`

This skill takes inbox-only captures and integrates them into the knowledge graph. It enriches metadata by fetching URLs, wires Dataview connection fields, promotes atoms, updates topic maps, and marks sources as processed. One note at a time, with user confirmation before any write.

For the relationship taxonomy and full field definitions, read: `references/vault-schema.md`

---

## Workflow

### 1. Discovery
Find all source notes that are `status: unread` or `status: unprocessed` AND have no populated Dataview relation fields in their `## Connections` block (inbox-only captures):

```bash
VAULT=/home/bcmcpher/Projects/claude/memex-vault

# Find unread sources
grep -rl "status: unread\|status: unprocessed" "$VAULT/sources/"

# From those, find ones with no wired connections
grep -rL "supports::\|introduces::\|cites::\|demonstrates::\|challenges::\|refutes::" "$VAULT/sources/"
```

Present the intersection grouped by medium. Include count and ask: "Which of these N notes would you like to process? (All, or name specific ones)"

If the user names a specific note not in the inbox list, process it directly regardless of status.

---

### 2. URL enrichment (fetch and fill metadata)
Before extracting concepts, fetch the URL and fill in missing metadata. This step replaces the URL-derived placeholder title and adds type-specific fields.

**Fetch the URL.** Then extract based on medium:

#### Web articles
Extract from page HTML:
- `title` — from `<title>` or `<h1>`
- `author` — from byline, meta author tag, or schema.org markup
- `saved` — already set; confirm publication date if visible (do not overwrite `saved`)
- `Summary` — offer a 2–3 sentence draft from the article lead or abstract

Update frontmatter `title`. Add `author:` field if found. Draft `## Summary` for user approval.

#### arXiv / academic papers
Fetch `https://arxiv.org/abs/<id>` or the DOI/journal page. Extract:
- `title` — from `<h1>`
- `authors` — from author list (write as YAML array)
- `year` — from submission date
- `venue` — from journal name or conference if present
- `Summary` — from the abstract

Update frontmatter `title`, add `authors: []`, `year:`, `venue:` fields. Write `## Summary` with the abstract.

#### YouTube / video
Fetch the YouTube page. Extract:
- `title` — from `<title>` (strip " - YouTube")
- `channel` — from channel link on the page

Update frontmatter `title`, add `channel:` field.

Note: **Full transcripts require an optional MCP server** (see README → Optional MCP Integrations). If a transcript MCP is available, fetch the transcript and offer a structured `## Key Points` with timestamps. If not, note this limitation and leave `## Key Points` empty for the user to fill after watching.

#### Docs pages
Fetch the page. Extract:
- `title` — from page heading
- `tool` — from URL subdomain or page title (e.g., `docs.pytorch.org` → `tool: pytorch`)
- `version` — from URL path if present (e.g., `/2.3/` → `version: "2.3"`)
- `section` — from page heading or breadcrumb

Update frontmatter `title`, add `tool:`, optionally `version:` and `section:`.

#### PDFs (URL ends in `.pdf`)
WebFetch cannot extract text from binary PDFs. Note this clearly:

> "This URL points to a PDF — automatic metadata extraction isn't available. Please provide: title, authors, year, and a brief summary. You can paste the abstract directly."

Ask for the required fields interactively, then proceed with user-provided content.

#### Paywalled / fetch-failed URLs
If the fetch returns an error or a login page, note it and ask the user to paste the title, authors (if paper), and a brief summary directly. Do not block processing — proceed with whatever the user provides.

**After enrichment:** Show a brief summary of what was extracted and what remains blank. Ask for approval before writing to the file.

---

### 3. Read the enriched note and identify concepts
With metadata now filled, read the full note. Extract the key concepts, claims, and contributions from `## Summary` and `## Key Points`.

Process notes **one at a time** — complete all steps for one note before moving to the next.

---

### 4. Atom matching
For each key concept, check `atoms/` for existing matches:

```bash
VAULT=/home/bcmcpher/Projects/claude/memex-vault
ls "$VAULT/atoms/" | grep -i "concept-keyword"
grep -rl "concept-keyword" "$VAULT/atoms/"
```

**For each concept:**
- **Match found** → propose the correct relation type; confirm before writing
- **No match, concept warrants an atom** → offer to create a stub (`confidence: low`); ask first
- **Boundary unclear** → use `related::` as a holding pattern; flag for monthly review

**Atom promotion criteria:**
1. Concept appears in title, abstract, or key contributions → strong candidate
2. You'd naturally link to it from 3+ other notes → create atom
3. Better as a glossary definition → `glossary/` stub instead (see below)
4. Highly specific implementation detail unlikely to recur → leave as text, no atom

**When criterion 3 applies — glossary stub workflow:**

A term belongs in `glossary/` when its value is definitional rather than evidential: stable definition, no competing claims to track, referenced via `defines::` rather than `supports::` or `introduces::`.

Ask: "Create a glossary stub for '[term]'? (Yes / Skip)"

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
<one or two sentences drafted from the source>

## Usage Notes
<!-- When/how the term is used; common confusions -->

## Source
cites:: [[source-filename]]
```

Then add `defines:: [[term-name]]` to the source note's `## Connections` section. Ask before creating each stub.

**Choosing the relation type** (excerpt — see `references/vault-schema.md` for the full decision tree including atom→atom epistemic relations)**:**

| Use | When |
|-----|------|
| `introduces::` | This source is where this concept first appears in the vault |
| `supports::` | Source provides evidence for a claim in an existing atom |
| `demonstrates::` | Source shows a concrete worked example |
| `challenges::` | Source questions or weakens a claim; describe tension in atom body |
| `refutes::` | Source provides direct counter-evidence against a claim |
| `cites::` | Source explicitly references another known work |
| `rebuts::` | Source references another source specifically as counter-evidence |
| `related::` | Loose connection; type unclear — fallback only |

---

### 5. Write connection fields
For each atom relationship, ask: **"Which section of this source best supports that connection? (Summary / Key Points / skip for bare link)"** Use heading anchors where a section is identifiable:

```
supports:: [[transformer-architecture#Key Points]], [[attention-mechanism#Summary]]
introduces:: [[flash-attention#Summary]]
challenges:: [[scaling-laws]]
cites:: [[2026-04-27-attention-is-all-you-need]]
```

Write a candidate file to `_meta/candidates/` before writing to the source note (see Candidate Gating below). Confirm proposed connections before writing. Multiple targets are fine.

---

### 6. Back-wire atoms
For every atom that gains a new source, write a candidate file before modifying the atom. Then:
- Add `cites:: [[source-filename#Section]]` to the atom's `## Sources` section — use the section anchor matched to this relationship
- Update `updated:` in atom frontmatter to today's date
- If a second independent source now supports this atom, upgrade `confidence: low → medium`

Ask before modifying existing atoms.

---

### 7. Check for missing source notes (multi-source entries)
Scan `cites::` targets written in step 5. For any target not yet a file in `sources/`, offer to create a capture stub for it before moving to the next note.

Example: a video cites three papers; if only one has a source note, offer to quickly capture the other two.

---

### 8. Topic map update
If the note introduces or supports an atom in an existing concept map, check whether that atom is in the map's `covers::`. If not, offer to add it. Ask before modifying topic maps.

---

### 9. Status promotion
Ask which transition applies:
- `unread → processed` (read and fully analyzed)
- `unread → read` (read but connections still incomplete)
- `unprocessed → processed` (meetings)

---

### 10. Log entry
After all changes are confirmed, append to `_meta/log.md`:
```markdown
## [YYYY-MM-DD] <medium> | <Title>
url:: <url or n/a>
atoms:: [[Atom A]], [[Atom B]]
skill:: memex-connect
notes: processed via memex-connect
```

---

### 11. Session summary
After all selected notes are processed, report:
- N sources enriched and processed
- M new atoms created
- K atoms updated
- L topic maps touched
- P capture stubs created for referenced works

---

## Processing Mode

One note at a time. Complete Steps 2–10 for one note before moving to the next.

---

## Candidate Gating

Before writing any vault change (source note connections, atom back-wires, atom stubs, glossary stubs), write a candidate file to `_meta/candidates/`. Use the session ID `YYYY-MM-DD-HHMM` from the start of this skill invocation.

**Create candidate** (new atom or glossary stub):
```yaml
---
proposed: YYYY-MM-DD HH:MM
skill: memex-connect
action: create
target: atoms/new-concept.md
session: YYYY-MM-DD-HHMM
status: pending
---
```
Body: full proposed file content.

**Modify candidate** (appending `cites::` to an existing atom, updating connection fields in source):
```yaml
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
```
Body: exact text to append.

Write candidate → confirm with user → write to vault → delete candidate. If session ends early, candidates persist for `memex-candidates`.

---

## Common Mistakes to Avoid
- Don't skip the URL enrichment step — even partial metadata (just the real title) improves the note significantly
- Don't use `related::` as the only connection when a more specific type clearly fits
- Don't overwrite `saved:` with the publication date found during enrichment — `saved` is always the date it was added to the vault
- Don't modify topic maps without asking
- Don't log entries that aren't fully processed
