---
name: memex-log-query
description: Query the ingest history log for activity summaries and cross-reference checks. Use when you want to know what was saved recently, which sources are still unprocessed, what came from a specific medium, or spot log/status inconsistencies. Triggers on: "what did I ingest this week", "show unprocessed sources", "what have I added recently", "log stats", "what's from paper sources", "query my log", "how many things did I add this month", "show me everything tagged with [atom]".
---

# Karpathy Wiki Log Query

**Vault root:** `/home/bcmcpher/Projects/claude/memex-llm-obsidian-template`

This skill parses `_meta/log.md` to answer activity and status questions about the vault. It does not modify the log, does not scan source files directly (except for cross-reference checks), and does not generate synthesis reports (that belongs to `memex-compose`).

The log is the single source of truth for what was processed and when. Cross-reference checks compare log entries against current vault state to surface inconsistencies.

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

The `## [YYYY-MM-DD]` header is the primary anchor for date-based queries. The `medium` field in the header (before `|`) enables medium-based filtering. The `skill::` field enables operation-type filtering.

---

## Supported Query Types

| Query | Fields used |
|-------|-------------|
| "What did I ingest this week/month?" | Date in `## [YYYY-MM-DD]` header |
| "Which sources are still unprocessed?" | Cross-reference: log entry vs. current source `status:` |
| "What came from paper/video/web sources?" | Medium in `## [YYYY-MM-DD] <medium>` header |
| "What atoms were created from [source type]?" | `atoms::` field + medium filter |
| "How many entries this month?" | Count of `## [YYYY-MM-DD]` headers in date range |
| "Show entries involving [[atom-name]]" | `atoms::` field contains the wikilink |
| "What did [skill] produce?" | `skill::` field match |
| "Show reconcile/refactor sessions" | `skill::` = `memex-reconcile` or `memex-refactor` |

---

## Workflow

### 1. Parse the query

Identify the query type from the table above. A query may combine multiple filters (e.g., "paper sources I added this month that created atoms").

### 2. Read and parse `_meta/log.md`

```bash
VAULT=/home/bcmcpher/Projects/claude/memex-llm-obsidian-template
cat "$VAULT/_meta/log.md"
```

Parse the log into entries. Each entry starts at a `## [YYYY-MM-DD]` header and ends at the next such header or end of file.

Extract per entry:
- **date** — from `## [YYYY-MM-DD]`
- **medium** — token before `|` in the header line
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

Medium filter: match the medium token in the header (e.g., `web`, `paper`, `video`, `meeting`, `reconcile`, `compose`).

Atom filter: check whether `[[atom-name]]` appears in the `atoms::` field (case-insensitive wikilink match).

Skill filter: exact match on `skill::` value.

### 4. Cross-reference check (optional)

When the query is "which sources are still unprocessed" or similar status-consistency questions:

For each log entry with a `url::` that is not `n/a`:
```bash
grep -rl "<url>" "$VAULT/sources/"
```
Find the corresponding source file. Read its current `status:`. Compare:
- Log entry implies processing happened (skill was ingest or connect) → source `status:` should be `processed` or `read`
- If source still shows `status: unread` → flag as inconsistency

Report inconsistencies as: "Log says [title] was processed on [date] by [skill], but `sources/medium/filename.md` still shows `status: unread`."

Cross-reference is slower (requires file reads per entry) — only run it when the user's query specifically asks about status consistency.

### 5. Return structured results

Format results based on query type:

**Activity summary (date range):**
```
Ingest activity: 2026-04-22 → 2026-04-29

  2026-04-29  web     | My Blog Post          → atoms: [[attention-mechanism]]
  2026-04-27  paper   | Attention Is All You Need → atoms: [[transformer-architecture]], [[self-attention]]
  2026-04-25  meeting | Team RAG Sync         → atoms: [[rag-pipeline]]

  3 entries | 3 mediums | 4 atoms touched
```

**Medium filter:**
```
Paper sources (all time): 2 entries
  2026-04-27  Attention Is All You Need
  2026-03-15  Scaling Laws for Neural LMs
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
  web: 3 | paper: 2 | video: 1 | meeting: 1
```

**Cross-reference inconsistencies:**
```
⚠ Status inconsistencies found: 1
  sources/paper/2026-04-27-attention-is-all-you-need.md
    Log says processed on 2026-04-27 (memex-ingest)
    Current status: unread
```

### 6. No-results handling

If the log has no entries matching the filter:
- State clearly: "No log entries found for [filter]."
- If the log is empty overall, note: "The log has no entries yet. Entries are written by memex-ingest, memex-connect, and other processing skills."
- Suggest the relevant skill if the user seems to be looking for sources that were never logged.

---

## What This Skill Does NOT Do

- Does not modify `_meta/log.md` — read-only
- Does not scan atom or source files directly (except for cross-reference status checks)
- Does not generate synthesis reports — use `memex-compose` for that
- Does not query Obsidian's graph or Dataview — works only from the append-only log
- Does not surface glossary activity — `memex-glossary` sessions produce no log entry by design; to audit what terms were defined, scan `glossary/` directly or grep for `defines::` fields across atom and source notes

---

## Common Mistakes to Avoid

- Don't confuse "entries this week" with "sources saved this week" — an entry can cover multiple sources if they were processed in one session
- Don't run cross-reference checks for simple count/activity queries — they're slow and unnecessary without a status-consistency question
- Don't report a missing `skill::` field as an error — older log entries written before that field was added won't have it; treat those as `skill:: unknown`
