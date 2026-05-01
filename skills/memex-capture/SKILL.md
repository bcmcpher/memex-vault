---
name: memex-capture
description: Quick-save a source to the vault without wiring connections or promoting atoms. Use when the user wants to drop something in the inbox for later processing: "quick save this", "just bookmark this", "capture for later", "drop this in my inbox", "save without processing", or when they share a URL with no immediate intent to analyze it. For full ingest with atom promotion, use memex-ingest. To wire up accumulated inbox notes, use memex-connect.
---

# Karpathy Wiki Capture

**Vault root:** `/home/bcmcpher/Projects/claude/memex-vault`

This skill does one thing: get a URL into the vault as fast as possible. Metadata enrichment, summaries, and connection wiring all happen later in `memex-connect`. The only thing that can't be recovered later is *why* the user saved it — so that's the only thing worth asking.

---

## Medium Detection (from URL)

| Pattern | Medium | Folder |
|---------|--------|--------|
| `arxiv.org`, `doi.org`, `semanticscholar.org`, `openreview.net` | `paper` | `sources/paper/` |
| `youtube.com`, `youtu.be`, `vimeo.com` | `video` | `sources/video/` |
| `docs.*`, `*.readthedocs.io`, `*.dev/docs*`, `*.io/docs*`, official library reference pages | `docs` | `sources/docs/` |
| Everything else | `web` | `sources/web/` |

If the URL doesn't clearly resolve, ask once: "Is this a paper, video, docs page, or general article?" For meeting notes (no URL), use `memex-meeting` instead.

---

## Workflow

### 1. Take the URL
Accept the URL as-is. Do not fetch it yet — that's the connect step.

Detect medium from the URL using the table above.

### 2. Derive a filename placeholder
Use today's date and derive a kebab slug from whatever title is inferable from the URL itself (path segment, arXiv ID, video ID, domain + slug). This can be rough — it will be corrected during the connect step when the title is fetched.

Pattern: `YYYY-MM-DD-kebab-slug.md`

Examples from URL alone:
- `https://arxiv.org/abs/2307.09288` → `2026-04-29-arxiv-2307-09288.md`
- `https://youtube.com/watch?v=dQw4w9WgXcQ` → `2026-04-29-youtube-dqw4w9wgxcq.md`
- `https://blog.example.com/my-post-title` → `2026-04-29-my-post-title.md`

**Always use today's date — never the publication date.**

Confirm the filename with the user only if the slug is ambiguous or meaningless (e.g., a UUID in the path).

### 3. Ask one question
Ask only: **"Why are you saving this?"** — one sentence is enough. This is the only piece of context that can't be retrieved from the URL later.

If the user volunteers more context (a summary, key points), accept it and write it. But don't ask for it.

### 4. Write the note
Create the file at the correct path using `_templates/source-digital.md` as the structure.

Frontmatter — fill what can be inferred without fetching:
```yaml
---
title: (slug-derived placeholder, e.g. "arxiv-2307-09288" — will be corrected by connect)
url: <url>
medium: <detected medium>
saved: <today YYYY-MM-DD>
tags: []
status: unread
---
```

Body:
```markdown
## Why Saved
<user's one sentence>

## Summary
<!-- To be filled by memex-connect -->

## Key Points
- 

## Connections
supports:: 
introduces:: 
demonstrates:: 
challenges:: 
refutes:: 
cites:: 
rebuts:: 
related:: 
```

Do not add type-specific frontmatter fields (authors, channel, tool, etc.) — those require fetching and are added by the connect step.

### 5. Confirm and close
Report the file path. One line: note is in the inbox, run `memex-connect` to enrich and wire it.

---

## What This Skill Does NOT Do

- Does not fetch the URL or extract metadata
- Does not fill in `title` beyond a URL-derived placeholder
- Does not add type-specific fields (`authors`, `channel`, `tool`, etc.)
- Does not write any Dataview relation fields with values
- Does not create atom stubs or glossary stubs
- Does not update `_meta/log.md`
- Does not handle meeting notes (no URL) — use `memex-meeting` for those

---

## Common Mistakes to Avoid
- Don't ask for a summary, key points, or connection ideas — save all of that for the connect step
- Don't fetch the URL — even to get the title — that's connect's job
- Don't use the publication date in the filename — always use today's date
- Don't check for existing atoms or concepts
- Don't create a note if the URL is already in `sources/` — do a quick check first:
  `grep -rl "<url>" /home/bcmcpher/Projects/claude/memex-vault/sources/`
