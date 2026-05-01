# Ingest Log

Append-only. One entry per ingest session. Format:

```
## [YYYY-MM-DD] <medium> | <title>
url:: <url-or-n/a>
atoms:: [[Atom A]], [[Atom B]]
skill:: <skill-name-that-wrote-this>
notes: <optional free-text>
```

Fields:
- `url::` — source URL or `n/a` for meetings and reconcile/refactor operations
- `atoms::` — Dataview wikilinks to every atom created or modified; empty list is `atoms:: ` with no links
- `skill::` — the memex-* skill that wrote the entry; enables log-query to filter by operation type
- `notes:` — plain text; optional context, counts, or flags

---

<!-- Add new entries below this line, most recent first -->

