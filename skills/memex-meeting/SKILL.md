---
name: memex-meeting
description: Save meeting notes to the vault as a structured source note. Use when the user wants to record a meeting, discussion, or conversation — not a URL. Triggers on: "log this meeting", "save my meeting notes", "record this discussion", "add meeting notes", "I just had a meeting about", "take notes on this conversation". For URL-based sources, use memex-capture or memex-ingest instead.
---

# Karpathy Wiki Meeting

**Vault root:** `/home/bcmcpher/Projects/claude/memex-vault`

This skill takes meeting notes — spoken, typed, or pasted — and creates a properly structured source note in `sources/meeting/`. It extracts decisions, action items, and follow-up sources, wires connections to existing atoms, and seeds stubs for new concepts that emerged. Unlike digital sources, meeting notes have no URL and use their own template.

---

## When to Use This Skill

- Recording notes from a meeting, discussion, or conversation
- Logging a research discussion with a collaborator
- Capturing a talk, lecture, or presentation attended in person (no recording URL)

For sources with a URL (video, paper, article), use `memex-capture` or `memex-ingest`.

---

## Workflow

### 1. Intake

Accept notes in any form: spoken description, bullet points, pasted raw notes, or a mix. Do not ask the user to reformat — extract structure from whatever is provided.

Confirm three things before proceeding (ask together in one question if not already clear):
- **Date** — when did the meeting occur? (default: today)
- **Attendees** — who was present? (names or roles; "solo" is valid)
- **Context** — one-phrase label for what this meeting was about (e.g., "team-rag-sync", "paper-reading-attention")

### 2. Determine filename

Pattern: `YYYY-MM-DD-kebab-context.md` in `sources/meeting/`

Use the meeting date (not today's date if the meeting was yesterday or earlier). Derive the slug from the context label. Confirm only if the slug is ambiguous.

Check for duplicates before creating:
```bash
VAULT=/home/bcmcpher/Projects/claude/memex-vault
ls "$VAULT/sources/meeting/" | grep "<date>"
```

### 3. Fill the meeting template

Create the file using `_templates/source-meeting.md` as the structure.

**Frontmatter:**
```yaml
---
title: <context label, title-cased>
medium: meeting
date: YYYY-MM-DD
attendees: [Name One, Name Two]
context: <one-phrase label>
tags: []
status: unprocessed
---
```

**Body sections — extract from the user's notes:**

```markdown
## Why Recorded
<one sentence: what was the purpose of this meeting?>

## Decisions Made
- <each concrete decision, one per bullet>

## Action Items
- [ ] <action item> — <owner if specified>

## Follow-up Sources Mentioned
- <any papers, articles, docs, or URLs discussed>

## Key Concepts Discussed
<prose summary of the main ideas, 2–5 sentences>

## Connections
supports:: 
introduces:: 
challenges:: 
related:: 
```

Where the user's notes are thin, draft placeholder text and ask them to review before writing.

### 4. Follow-up captures

For each source mentioned in `## Follow-up Sources Mentioned`, offer to create a capture stub immediately:

> "The meeting referenced [paper/article]. Want me to create a capture stub for it now? (Yes / Skip)"

If yes, run the capture workflow inline (just the URL intake and stub creation — no context switch needed). Add the resulting `[[source-filename]]` to the meeting note's `cites::` field under `## Connections`.

### 5. Wire atom connections

Search for existing atoms matching the key concepts discussed:
```bash
grep -ril "<concept-keyword>" "$VAULT/atoms/"
```

For each match, propose the appropriate connection field under `## Connections`:
- `supports::` — meeting reinforced or provided evidence for an existing claim
- `introduces::` — a new concept emerged that doesn't yet have an atom
- `challenges::` — discussion questioned or weakened an existing claim
- `related::` — conceptual adjacency; use as fallback

Confirm proposed connections before writing.

### 6. Atom stubs for new concepts

For each new concept that emerged (not yet in `atoms/`):

> "The concept [X] came up but has no atom yet. Want to create a stub? (Yes / Skip)"

Write a candidate file to `_meta/candidates/` before creating the atom. If yes, create `atoms/kebab-concept.md` with `confidence: low` and `cites:: [[meeting-filename#Key Concepts Discussed]]` (or `#Decisions Made` if the concept emerged from a decision). Add `introduces:: [[concept-name]]` to the meeting note's Connections.

Ask before creating each stub — do not auto-create.

### 6b. Glossary stubs for new terms

For each technical term that surfaced in the meeting that needs precise definition but doesn't warrant an atom — no claims, no evidence chain, just a stable definition:

> "The term [X] came up but has no glossary entry yet. Want to create a stub? (Yes / Skip)"

Write a candidate file to `_meta/candidates/` before creating the glossary entry. If yes, create `glossary/kebab-term.md`:
```markdown
---
title: Term Name
term: term name
aliases: []
domain: <inferred from discussion topic>
tags: []
created: YYYY-MM-DD
status: stub
---

## Definition
<draft from how the term was used in the meeting>

## Usage Notes
<!-- When/how the term is used; common confusions -->

## Source
cites:: [[meeting-filename]]
```

Then add `defines:: [[term-name]]` to the meeting note's `## Connections` section.

**Atom vs. glossary:** if the term has competing definitions, accumulated claims, or would naturally connect to multiple other concepts via structural relations — create an atom stub (Step 6) instead.

Ask before creating each stub — do not auto-create.

### 7. Status

Set `status: unprocessed` on creation. Note to the user:

> "This note is marked `unprocessed`. Update it to `processed` once action items are complete and any follow-up sources have been captured."

### 8. Log entry

Append to `_meta/log.md`:
```markdown
## [YYYY-MM-DD] meeting | <context label>
url:: n/a
atoms:: [[Atom A]], [[Atom B]]
skill:: memex-meeting
notes: <N> decisions, <M> action items, <K> follow-up sources mentioned
```

---

## What This Skill Does NOT Do

- Does not handle URL-based sources — use `memex-capture` or `memex-ingest` for those
- Does not create calendar events or external integrations
- Does not transcribe audio — paste or describe the content; transcription is out of scope
- Does not mark the note `processed` automatically — that requires the user to confirm action items are done

---

## Common Mistakes to Avoid

- Don't use today's date in the filename if the meeting was on a different day — always use the meeting date
- Don't add a `url:` field to meeting notes — the template doesn't include one
- Don't create atom stubs for every concept mentioned — only for concepts that warrant independent tracking (would be referenced from multiple future sources)
- Don't mark `status: processed` until follow-up sources are captured and action items are addressed
