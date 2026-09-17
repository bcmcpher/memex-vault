---
name: memex-save
description: Save a URL to the vault with a lightweight fetch — always gets the real title and a short summary draft. Use for any source the user wants to save, whether they've read it or not. Triggers on: "quick save", "just bookmark", "capture for later", "save this for later", "drop this in my inbox", "save without processing", "I've read this", "mark as read", "I skimmed this", "read but not processed", "I just read this", or any time the user shares a URL alongside saving intent. For full atom creation and graph wiring, use memex-ingest. For accumulated inbox notes, use memex-connect. For meeting notes (no URL), use memex-meeting.
---

# Karpathy Wiki Save

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited.

This skill gets a source into the vault with a real title and a short summary — enough to be useful immediately, without doing the full graph wiring that `memex-connect` handles. It always fetches the URL, asks whether the source has been read, and branches from there: unread sources land as clean inbox items; read sources optionally support a collaborative summary-building session to capture your understanding before you move on.

For meeting notes with no URL, use `memex-meeting` instead.

---

## Medium Detection

| Pattern | Medium | Folder |
|---------|--------|--------|
| `arxiv.org`, `biorxiv.org`, `medrxiv.org`, `doi.org`, `semanticscholar.org`, `openreview.net`, `pubmed.ncbi.nlm.nih.gov`, `ncbi.nlm.nih.gov/pmc`; publisher article pages — `nature.com`, `science.org`, `cell.com`, `pnas.org`, `sciencedirect.com`, `link.springer.com`, `onlinelibrary.wiley.com`, `ieeexplore.ieee.org`, `dl.acm.org`, `frontiersin.org`, `journals.plos.org`, `academic.oup.com`, `tandfonline.com`, `journals.sagepub.com`, `elifesciences.org`, `direct.mit.edu`; **any URL whose path contains a DOI** (`/10.NNNN/…`) | `paper` | `sources/paper/` |
| `youtube.com`, `youtu.be`, `vimeo.com` | `video` | `sources/video/` |
| `docs.*`, `*.readthedocs.io`, `*.dev/docs*`, `*.io/docs*`, official library reference pages | `docs` | `sources/docs/` |
| `github.com`, `gitlab.com`, `codeberg.org`, package registries, analysis/toolbox repos | `code` | `sources/code/` |
| Everything else | `web` | `sources/web/` |

The authoritative list is `_meta/domain.md` § Source Types, not this table — a
fork adds a medium there and the table above is only the URL heuristic for it.
Check that file when a URL fits nothing here.

**Test the `paper` row before falling through to `web`.** It used to list four
preprint and index domains, so every journal page — `nature.com`,
`frontiersin.org`, `sciencedirect.com`, Springer, IEEE — was filed as `web`. The DOI
rule catches publishers the domain list misses (`frontiersin.org/…/10.3389/…`); a
publisher path with no DOI in it (`nature.com/articles/…`) needs the domain entry.
If the step 2 fetch shows `citation_doi` or `citation_title` metadata on a page
routed to `web`, it is a paper: re-route it and say so.

**Only write a declared medium.** The heuristic can name one this vault does not
declare — the template declares no `code`. Then ask which declared medium to use,
or suggest re-running `memex-init` to add it. Lint does not check the `medium:`
value itself, but a note in an undeclared `sources/<medium>/` folder is skipped by
every per-medium check, and lint says only that the folder is undeclared.

If the URL is ambiguous, ask once, listing the media declared in
`_meta/domain.md` § Source Types: "Is this a paper, video, docs page, code
repository, or general article?"

---

## Workflow

### 1. Accept URL
Take the URL. Check for an existing source note first — avoid duplicates:
```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
grep -rl "<url>" "$VAULT/sources/"
```
If a match is found, show it and stop — no action needed. The rule is
`_meta/schema.md` § Source URLs: one source note per URL. `lint.sh` section 2b is
the backstop, so a duplicate that slips past this grep is caught at the next lint
rather than silently inflating the independent-source count.

**Strip credentials before the URL touches a note.** A signed link or a share
token copied out of an authenticated session — `?access_token=`, `?sig=`,
`https://user:pass@host/…` — gets committed the moment the note is written, and
`sources/` is tracked. Save the bare URL. If the resource is unreachable without
the token, say so in `## Why Saved` rather than putting it in `url:`. `lint.sh`
section 2c warns, but only after the commit that needs rewriting.

Detect medium from the URL pattern above.

### 2. Quick fetch
Fetch the URL immediately. Extract only what's needed for a useful stub:

- **All sources**: real title from `<title>` or `<h1>`; one-sentence summary draft from lead paragraph, abstract first sentence, or page description
- **Paper**: `authors` array and `published` from the abstract page — the year alone is fine here if that is all the page states plainly; `memex-connect` refines it
- **Video**: `channel` name. For YouTube, read it from the oEmbed endpoint — `https://www.youtube.com/oembed?url=<url>&format=json` returns JSON whose `author_name` is the channel and `title` the video title, with no API key. A plain fetch of the watch page does not reliably expose the channel; on the first real vault it left `channel:` empty. For other hosts, take it from the page, and leave `channel:` empty rather than guess
- **Docs**: `tool` name from subdomain or page title

This is a lightweight fetch — stop at the minimum. Full metadata enrichment (full author arrays, venue, version, structured Key Points) is `memex-connect`'s job.

**If the URL is a PDF or paywalled:** note the limitation clearly and ask the user for title and a brief summary. Do not block on this.

### 3. Derive filename
Use the real fetched title: `YYYY-MM-DD-kebab-title.md`. Drop articles, max ~6 words in the slug. **Always use today's date — never the publication date.**

Confirm with the user only if the slug would be ambiguous or too generic.

### 4. Ask two questions together
In a single prompt, ask:
1. **"Why are you saving this?"** — one sentence; this is the only context that won't be recoverable from the URL later
2. **"Have you read this?"** — Yes / Not yet

### 5. Branch on read stage

#### If "Not yet" → `stage: unread`
Write the source note (Step 6). No reactions, no summary session.

#### If "Yes" → `stage: read`

**5a. First-read reactions (optional)**
Ask: "Any quick reactions or highlights?" Accept 1–3 bullets, or skip entirely. Do not prompt again if the user passes.

**5b. Collaborative summary mode (optional)**
Ask: "Want to build a fuller summary together?" (Yes / Skip)

**If yes:**
Ask open-ended questions to draw out the user's understanding of the source. Base questions on the fetched content — but prompt the user to articulate, don't recite the content back:

- "What was the main claim or finding?"
- "What evidence or reasoning did they give?"
- "Anything you disagreed with or found weak?"
- "What would you want to remember most?"

Use their answers to draft `## Summary` (3–5 sentences) and `## Key Points` (3–6 bullets) in their own words. Show the draft and ask for edits before writing. This replaces the 1-sentence fetch placeholder with a user-informed summary.

**If skip:** write the 1-sentence fetch draft into `## Summary` as a placeholder for `memex-connect` to expand.

### 6. Write the note
Write a create candidate first (see Candidate Gating below), then create the file at the correct `sources/<medium>/` path using `_templates/source-digital.md` as the base.

**Frontmatter:**
```yaml
---
type: Source
title: <from fetch>
description: <one line from the fetched summary; leave blank if the fetch failed>
url: <url>
medium: <a medium declared in _meta/domain.md § Source Types>
saved: <today YYYY-MM-DD>
tags: []
stage: <unread|read>
generated:
  by: memex-save/claude-opus-5
  at: <today YYYY-MM-DD>
---
```

Add type-specific fields when extractable from the fetch: `authors: []` and `published:` for papers; `channel:` for video; `tool:` for docs; `repo:`, `language:`, and `license:` for code.

**Body:**
```markdown
## Why Saved
<user's one sentence>

## First Read
<YYYY-MM-DD>
- <reaction bullet>
- <reaction bullet>
```
*(Omit `## First Read` entirely if `stage: unread` or if no reactions were provided)*

```markdown
## Summary
<1-sentence fetch draft, or collaborative summary if built in step 5b>

## Key Points
- <from collaborative session, or leave empty for memex-connect>

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

Do not populate Dataview relation fields — full wiring is `memex-connect`'s job.

### 7. Log
Append to `_meta/log.md`:
```markdown
## [YYYY-MM-DD] saved | <title>
url:: <url>
atoms:: 
skill:: memex-save
notes: stage: <unread|read>; <"collaborative summary" | "reactions captured" | "no reactions">
```

### 8. Confirm and close
Report the file path and stage. Suggest next step in one line:
- If `unread`: "Run `memex-connect` when ready to enrich and wire this into the graph."
- If `read`: "Run `memex-connect` when ready to wire this into the graph."

---

## Candidate Gating

Before writing the source note, write a create candidate to `_meta/candidates/`. Use the session ID `YYYY-MM-DD-HHMM` from the start of this skill invocation.

```yaml
---
proposed: YYYY-MM-DD HH:MM
skill: memex-save
action: create
target: sources/<medium>/YYYY-MM-DD-slug.md
session: YYYY-MM-DD-HHMM
stage: pending
---
```
Body: the full note, as step 6 would write it.

Write candidate → show the user → write to vault → delete candidate. If the session ends first, the candidate persists for `memex-candidates`. This skill writes one file, so this is one candidate — but it is the most-invoked capture skill, and the collaborative summary in step 5b is user work that a dropped session would otherwise lose.

---

## What This Skill Does NOT Do

- Does not create atoms, glossary stubs, or Dataview connections
- Does not do full metadata extraction (full authors array, venue, version) — that's `memex-connect`
- Does not advance `stage:` past `read` — use `memex-connect` for full processing
- Does not handle meeting notes (no URL) — use `memex-meeting`
- Collaborative summary mode builds `## Summary` and `## Key Points` only — never touches relation fields

---

## Common Mistakes to Avoid
- Don't skip the fetch — even a rough title is better than a URL slug filename
- Don't ask for a full summary unprompted — only enter collaborative mode if the user says yes to step 5b
- Don't use the publication date in the filename — always use today's date
- Don't populate Dataview relation fields — leave all `::` fields empty for `memex-connect`
- Don't create a new note if the URL already exists in `sources/` — check first (step 1)
