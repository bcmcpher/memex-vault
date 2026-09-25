---
name: memex-connect
description: Wire captured sources into the knowledge graph. Use when the user wants to process their inbox, integrate accumulated unread notes, or add connections between existing notes. Triggers on: "process my inbox", "wire up my unread notes", "connect my captures", "integrate my sources", "link my notes to atoms", "I want to process what I've saved". Also triggers for targeted connection work: "add connections to this note", "wire this source into the graph", "link [note] to [concept]". This skill does not capture new sources — use memex-save or memex-ingest for that.
---

# Karpathy Wiki Connect

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited. **Confirm it resolved to a vault before writing
anything:** `[ -f "$VAULT/_meta/schema.md" ]`. If that fails, stop and tell the
user — a stale `MEMEX_VAULT`, or this skill invoked from an unrelated repository,
otherwise writes `sources/`, `atoms/` and `_meta/log.md` into *that* repository,
and the first sign is `git status` (roadmap R14).

This skill takes inbox-only captures and integrates them into the knowledge graph. It enriches metadata by fetching URLs, wires Dataview connection fields, promotes atoms, updates topic maps, and marks sources as processed. Analysis may cover a batch; confirmation and writes go one note at a time (§ Processing Mode).

For the relationship taxonomy and field definitions, read `$VAULT/_meta/schema.md` § Relationship Types.

---

## Workflow

### 1. Discovery
A source needs wiring when nothing connects it to the knowledge graph in either direction: none of its own relation fields names a target, **and** no atom links to it or to its extract. Stage is not part of the test. `stage:` records reading and links record wiring, so a source can be read and unwired — the normal state after `memex-save` with "I've read this".

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"

for f in "$VAULT"/sources/*/*.md; do
    [ -f "$f" ] || continue
    slug=$(basename "$f" .md)
    # outbound: a relation field with a real target, not the empty field the template ships
    grep -qE '^(supports|introduces|demonstrates|challenges|refutes|cites|rebuts|related|defines)::[[:space:]]*\[\[' "$f" && continue
    stage=$(awk '/^---$/ { n++; next } n == 1 && /^stage:/ { sub(/^stage:[[:space:]]*/, ""); print; exit }' "$f")
    # inbound: an atom citing the source, or a claim block of its extract
    if grep -rqE "\[\[(ext-)?$slug([]#|])" "$VAULT/atoms" --include='*.md' 2>/dev/null; then
        # lint 6a reads outbound fields only, so it still warns on an unread one
        case "$stage" in
            unread|unprocessed) echo "$stage	${f#"$VAULT"/}	atom-cited" ;;
        esac
        continue
    fi
    echo "${stage:-?}	${f#"$VAULT"/}"
done
```

Three tests this deliberately avoids, each of which failed on a real vault:

- **The bare field name.** `grep -L "supports::"` finds nothing, because the template ships every relation field empty on every source — the name is always present, so the query returned only `.gitkeep` files and reported "nothing to process" on a vault with work waiting. Match a field followed by `[[`.
- **Outbound fields alone.** `memex-deep-extract` writes `cites::` into atoms and never back onto the source, so a paper eight atoms cite can have an empty `## Connections`. Count inbound links from `atoms/` too — to the source, or to a block of `ext-<slug>`.
- **Any link from `extracts/`.** The only link an extract holds to its source is its own `extracted-from::` line, written by mode A, which wires nothing. Counting it removed every extracted source from this queue for good: in trial 2 discovery returned 0 of 12 while lint 6a sent all 12 here (T2-9). `extracts/` is not searched.

A row marked `atom-cited` is wired in, but its own `## Connections` is empty and it is still `unread`, which is exactly what lint 6a warns on. Either wire its outbound fields (steps 5–6) or, if it has been read, move its stage (step 9); both clear the warning. Listing it keeps this skill and lint from contradicting each other.

Links from `topics/` do not count: a project or research note citing a source is navigation, not atom wiring. Say when a listed source is cited by a topic, so the user can skip it knowingly.

Present the list grouped by medium, with stage as a column. Include count and ask: "Which of these N notes would you like to process? (All, or name specific ones)"

If the list is empty, say which kind of empty: no source notes exist yet, or every source is linked. They call for different next steps.

If the user names a specific note not in the list, process it directly regardless of stage or wiring.

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
- `published` — from the submission date, full `YYYY-MM-DD` when arXiv gives one; a journal page stating only a month is `YYYY-MM`. Never pad to a day (`_meta/schema.md` § Publication Dates)
- `venue` — from journal name or conference if present
- `Summary` — from the abstract

Update frontmatter `title`, add `authors: []`, `published:`, `venue:` fields. Write `## Summary` with the abstract.

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

**After enrichment:** Show a brief summary of what was extracted and what remains blank, and ask for approval. Hold the approved changes as drafts: they are written with the rest of this note's changes, through candidates, from step 5 on — so enriching a batch writes nothing until each note's turn.

---

### 3. Read the enriched note and identify concepts
With metadata now filled, read the full note. Extract the key concepts, claims, and contributions from `## Summary` and `## Key Points`.

With several notes selected, this and steps 2 and 4 may run across the batch; from step 5 on, finish one note before starting the next (§ Processing Mode).

---

### 4. Atom matching
For each key concept, check `atoms/` for existing matches:

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
ls "$VAULT/atoms/" | grep -i "concept-keyword"
grep -rl "concept-keyword" "$VAULT/atoms/"
```

**For each concept:**
- **Match found** → propose the correct relation type; confirm before writing
- **No match, concept warrants an atom** → offer to create a stub (`type: Atom`, `confidence: low`); ask first
- **Boundary unclear** → propose a typed relation now, while the reasoning is at hand; fall back to `related::` only when no type genuinely fits. Nothing is scheduled to come back and type it later, so an untyped link written here is usually permanent

**Atom promotion criteria:**
1. Concept appears in title, abstract, or key contributions → strong candidate
2. You'd naturally link to it from 3+ other notes → create atom
3. Better as a glossary definition → `glossary/` stub instead (see below)
4. Highly specific implementation detail unlikely to recur → leave as text, no atom

**When criterion 3 applies — glossary stub workflow:**

A term belongs in `glossary/` when its value is definitional rather than evidential: stable definition, no competing claims to track, referenced via `defines::` rather than `supports::` or `introduces::`.

Before proposing a stub, check whether the term already exists in the vault or as a pending candidate:
```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
ls "$VAULT/glossary/" | grep -i "term-keyword"
grep -rl "term: " "$VAULT/_meta/candidates/" 2>/dev/null | xargs grep -l "term-keyword" 2>/dev/null
```
If either check returns a match, show the existing entry and skip the creation prompt.

Ask: "Create a glossary stub for '[term]'? (Yes / Skip)"

If yes, create `glossary/kebab-term.md`:
```markdown
---
type: Glossary Term
title: Term Name
description: <the definition in one line>
term: term name
aliases: []
domain: <inferred from topic area>
tags: []
created: YYYY-MM-DD
stage: stub
generated:
  by: memex-connect/claude-opus-5
  at: YYYY-MM-DD
---

## Definition
<one or two sentences drafted from the source>

## Usage Notes
<!-- When/how the term is used; common confusions -->

## Source
cites:: [[source-filename]]
```

Then add `defines:: [[term-name]]` to the source note's `## Connections` section. Ask before creating each stub.

**Choosing the relation type** (excerpt — see `$VAULT/_meta/schema.md` § Choosing Between Structural Relations and § Choosing Between Skeptical Relations for the full trees, including atom→atom relations)**:**

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
If the note introduces or supports an atom that has no `part-of::`, offer to set one so the atom joins a concept map. Ask first. Topic files are never edited — membership is derived from the atom's own `part-of::`.

---

### 9. Stage
`stage:` records whether the source has been read and processed, not whether it is wired — the links written in steps 5–6 are the wiring record. Ask which applies:
- `→ processed` — read, and its connections and atoms are done
- `unread → read` — the user has read it, and processing is not finished
- `unprocessed → processed` (meetings)
- no change — nobody has read it yet. Wiring an unread source from its metadata is legitimate and does not make it read.

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

**Analyse in a batch, confirm and write one note at a time.** With several notes
selected, steps 2–4 may run across all of them first — enrichment and atom
matching are reads, and seeing the batch together is how a concept three sources
share gets one atom instead of three near-duplicates. Steps 5–10 then run per
note: that note's candidates, its confirmation, its writes and asserts, its log
entry, before the next note's first candidate is shown. The user never confirms
a batch of writes spanning notes, and a session that drops mid-batch leaves every
finished note complete and every unfinished one with its candidates on disk.

A recorded rc.2 deviation ran connect this way against the old "one note at a
time" wording, kept per-note candidates and writes, and nothing broke; this is
that practice written down.

---

## Candidate Gating

Before writing any vault change (step 2's enrichment, source note connections, atom back-wires, atom stubs, glossary stubs, stage), write a candidate file to `_meta/candidates/`. Use the session ID `YYYY-MM-DD-HHMM` from the start of this skill invocation.

**Create candidate** (new atom or glossary stub):
```yaml
---
proposed: YYYY-MM-DD HH:MM
skill: memex-connect
action: create
target: atoms/new-concept.md
session: YYYY-MM-DD-HHMM
stage: pending
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
stage: pending
---
```
Body: exact text to append.

**Replace candidate** (filling a field the template ships empty, moving `stage:`,
bumping `updated:` or `confidence:`):
```yaml
---
proposed: YYYY-MM-DD HH:MM
skill: memex-connect
action: modify
target: sources/paper/2026-04-27-attention-is-all-you-need.md
change: replace
replaces: "supports:: "
session: YYYY-MM-DD-HHMM
stage: pending
---
```
Body: the one line that replaces it — here `supports:: [[attention-mechanism#Summary]]`.

The source templates ship each relation field as an empty line (`supports:: `,
with its trailing space), so step 5 fills that line rather than appending a
second `supports::` under it; a field the note does not carry (older notes lack
`defines::`) is an append to `## Connections`. Frontmatter has no section to append to: step 6's
`updated:` and `confidence:` and step 9's `stage:` are each a replace of the
current line.

Write candidate → confirm with user → write to vault → **assert** → delete candidate
(`_meta/schema.md` § Candidate Lifecycle). The assert re-reads the target: a create's
file equals the candidate body; an append's lines sit under the named section; a
replace's new line is present and its `replaces:` line is gone. On a miss, stop, keep
the candidate, and leave that change out of the note's log entry — an edit tool can
report success on a write that did not happen (trial 1, finding 13). Step 10's log
entry is written last and names only asserted writes. If the session ends early,
candidates persist for `memex-candidates`.

---

## Common Mistakes to Avoid
- Don't skip the URL enrichment step — even partial metadata (just the real title) improves the note significantly
- Don't use `related::` as the only connection when a more specific type clearly fits
- Don't overwrite `saved:` with the publication date found during enrichment — `saved` is always the date it was added to the vault
- Don't modify topic maps without asking
- Don't log entries that aren't fully processed
