---
name: memex-log-query
description: Query the vault's activity log for summaries of what was done and when. Use when you want to know what was saved or processed recently, what a skill produced, which entries touched an atom, or what came from a given medium. Triggers on: "what did I ingest this week", "what have I added recently", "log stats", "what's from paper sources", "query my log", "how many things did I add this month", "show me everything tagged with [atom]", "what did [skill] do". Which sources are still unread or unwired is a question about sources, not the log — use _meta/lint.sh or memex-connect for that.
---

# Karpathy Wiki Log Query

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited.

This skill parses `_meta/log.md` to answer activity questions about the vault. It does not modify the log, reads source notes only to resolve an entry's medium, and does not generate synthesis reports (that belongs to `memex-compose`).

The log records what a skill did and when. It is not a record of a source's current state — the note's own `stage:` is, and `_meta/lint.sh` checks it.

---

## Log Entry Format

Log entries follow this structure (as specified in `_meta/log.md`):

```
## [YYYY-MM-DD] <medium> | <title>
url:: <url-or-n/a>
atoms:: [[Atom A]], [[Atom B]]
skill:: <skill-name>
notes: <optional free-text>
```

The `## [YYYY-MM-DD]` header is the primary anchor for date-based queries. The `skill::` field enables operation-type filtering.

**The token before `|` is a label, not a reliable medium.** `_meta/log.md` calls it `<medium>`, but only some writers put one there: `memex-save` writes `saved`, `memex-deep-extract` writes `deep-extract/extract` or `deep-extract/promote`, and maintenance skills write their own names. On the first real vault 1 of 36 entries carried a medium in that position, so a filter on it returned almost nothing. Resolve medium from the source note instead (step 3).

---

## Supported Query Types

| Query | Fields used |
|-------|-------------|
| "What did I ingest this week/month?" | Date in `## [YYYY-MM-DD]` header |
| "What came from paper/video/web sources?" | `url::` → the source note's `medium:` |
| "What atoms were created from [medium] sources?" | `atoms::` field + medium filter |
| "How many entries this month?" | Count of `## [YYYY-MM-DD]` headers in date range |
| "Show entries involving [[atom-name]]" | `atoms::` field contains the wikilink |
| "What did [skill] produce?" | `skill::` field match |
| "Show reconcile/refactor sessions" | `skill::` = `memex-reconcile` or `memex-refactor` |

---

## Workflow

### 1. Parse the query

Identify the query type from the table above. A query may combine multiple filters (e.g., "paper sources I added this month that created atoms").

If the question is which sources are unread, unprocessed or unwired, go to step 4 instead.

### 2. Read and parse `_meta/log.md`

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
cat "$VAULT/_meta/log.md"
```

Parse the log into entries. Each entry starts at a `## [YYYY-MM-DD]` header and ends at the next such header or end of file.

Extract per entry:
- **date** — from `## [YYYY-MM-DD]`
- **label** — token before `|` in the header line (a medium on some entries, an operation name on others)
- **title** — token after `|` in the header line
- **url** — from `url::` field (strip `url:: `)
- **atoms** — from `atoms::` field (parse `[[Name]]` wikilinks)
- **skill** — from `skill::` field
- **notes** — from `notes:` line

### 3. Apply filters

Date range filters:
- "this week" = last 7 days from today
- "this month" = current calendar month
- "last month" = previous calendar month
- Specific date = exact match

Medium filter: for each entry whose `url::` is not `n/a`, find its source note and read `medium:` from the note's frontmatter:

```bash
f=$(grep -rlF "<url>" "$VAULT/sources/" --include='*.md' | head -1)
[ -n "$f" ] && awk '/^---$/ { n++; next } n == 1 && /^medium:/ { sub(/^medium:[[:space:]]*/, ""); print; exit }' "$f"
```

An entry with `url:: n/a` has no source to resolve: if its `skill::` is `memex-meeting` its medium is `meeting`; otherwise it is not a capture and matches no medium. An entry whose URL matches no note — renamed or deleted since — is reported as unresolved, not dropped silently.

Resolve media only when the query asks for one; it reads a file per entry.

Atom filter: check whether `[[atom-name]]` appears in the `atoms::` field (case-insensitive wikilink match).

Skill filter: exact match on `skill::` value.

### 4. Stage questions — point elsewhere

Which sources are unread, unprocessed or unwired is a question about the source notes, and three things already answer it:

- `_meta/lint.sh` section 6 — inbox-only sources
- `memex-stale` Check 2 — sources read but never integrated
- `memex-connect` step 1 — sources nothing links to, whatever their stage

Say so and point there. This skill used to cross-check log entries against `stage:`; that duplicated lint and caught less, because a log entry says a skill ran, not what state it left the note in.

### 5. Return structured results

Format results based on query type:

**Activity summary (date range):**
```
Log activity: 2026-04-22 → 2026-04-29

  2026-04-29  saved   | My Blog Post          → atoms: —
  2026-04-27  paper   | Attention Is All You Need → atoms: [[transformer-architecture]], [[self-attention]]
  2026-04-25  meeting | Team RAG Sync         → atoms: [[rag-pipeline]]

  3 entries | 3 skills | 3 atoms touched
```

**Medium filter:**
```
Paper sources (all time): 2 entries
  2026-04-27  Attention Is All You Need     (skill: memex-ingest)
  2026-03-15  Scaling Laws for Neural LMs   (skill: memex-save)
  Unresolved: 0
```

**Atom filter:**
```
Log entries involving [[transformer-architecture]]: 2
  2026-04-27  paper  | Attention Is All You Need    (skill: memex-ingest)
  2026-04-20  video  | Andrej Karpathy GPT lecture  (skill: memex-connect)
```

**Count:**
```
Entries in April 2026: 7
  memex-save: 3 | memex-ingest: 2 | memex-connect: 1 | memex-meeting: 1
```

### 6. No-results handling

If the log has no entries matching the filter:
- State clearly: "No log entries found for [filter]."
- If the log is empty overall, note: "The log has no entries yet. Entries are written by memex-ingest, memex-connect, and other processing skills."
- Suggest the relevant skill if the user seems to be looking for sources that were never logged.

---

## What This Skill Does NOT Do

- Does not modify `_meta/log.md` — read-only
- Does not read atom or source files, except a source note's `medium:` for a medium filter
- Does not answer stage questions — see step 4
- Does not generate synthesis reports — use `memex-compose` for that
- Does not query Obsidian's graph or Dataview — works only from the append-only log
- Does not surface glossary activity — `memex-glossary` sessions produce no log entry by design; to audit what terms were defined, scan `glossary/` directly or grep for `defines::` fields across atom and source notes

---

## Common Mistakes to Avoid

- Don't confuse "entries this week" with "sources saved this week" — an entry can cover multiple sources if they were processed in one session
- Don't filter on the header label as though it were a medium — resolve `medium:` from the source note
- Don't report a missing `skill::` field as an error — older log entries written before that field was added won't have it; treat those as `skill:: unknown`
