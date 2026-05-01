---
name: memex-topic-init
description: Create and bootstrap a new topic node in the personal Karpathy-style Obsidian wiki vault. Use this skill whenever the user wants to start a new concept map, research note, or project workspace — and wire it into existing atoms and sources in one step. Triggers on: "create a new topic", "start a concept map for X", "I want a research note on Y", "set up a new project in my wiki", "initialize a topic", "create a topic for Z", "I'm starting to study X and want to track it", "new wiki topic", "add a domain to my vault". Also triggers when the user names a domain they've been accumulating sources on and wants a navigational hub for it.
---

# Karpathy Wiki Topic Init

**Vault root:** `/home/bcmcpher/Projects/claude/memex-vault`

This skill creates a new topic node — a concept map, research note, or project workspace — and immediately wires it into the existing graph. The goal is to give a freshly named topic a meaningful starting structure rather than an empty shell: atoms already in the vault get linked, relevant sources get cited, and adjacent topics get connected.

For the relationship taxonomy, read: `references/vault-schema.md`

---

## Topic Types

| Type | Folder | Filename pattern | Use when |
|------|--------|-----------------|----------|
| Concept map | `topics/concepts/` | `kebab-domain.md` | Aggregating atoms in a broad domain |
| Research note | `topics/research/` | `rq-kebab-question.md` | Pursuing a specific question across sources |
| Project | `topics/projects/` | `proj-kebab-name.md` | Tracking active work with open questions |

---

## Workflow

### 1. Determine type and name
Ask the user: what kind of topic (concept/research/project) and what is it called? If the intent is clear from context, infer the type rather than asking. A "concept map for deep learning" is obviously a concept; "researching whether LoRA beats full fine-tuning" is a research note.

For research notes, also ask for the research question (goes in `question:` frontmatter).
For projects, ask for the goal (goes in the `## Goal` section).

Check for an existing topic with the same or similar name before creating:
```bash
VAULT=/home/bcmcpher/Projects/claude/memex-vault
ls "$VAULT/topics/concepts/" "$VAULT/topics/research/" "$VAULT/topics/projects/" | grep -i "keyword"
```

If a close match exists, show it to the user and ask whether to extend the existing topic instead of creating a new one. Confirm the filename slug before writing.

### 2. Build a keyword set
Derive 3–5 search keywords from the topic title and description. Include synonyms and abbreviations — e.g., "transformers" → also search "attention", "self-attention". These keywords drive the atom and source search in the next steps.

### 3. Search for relevant atoms
```bash
VAULT=/home/bcmcpher/Projects/claude/memex-vault

# Match by filename
ls "$VAULT/atoms/" | grep -i "keyword"

# Match by content (title/tags)
grep -rl "keyword" "$VAULT/atoms/"
```

For each candidate atom, read its `title` and `## Summary` (one line is enough). Present grouped into:
- **Strong candidates** — title or summary directly matches the topic
- **Possible candidates** — content mentions the topic but may be peripheral

Ask the user which atoms belong in `covers::`. Default to including strong candidates; let the user drop any that don't fit.

### 4. Search for relevant sources
```bash
grep -rl "keyword" "$VAULT/sources/"
```

Read each hit's frontmatter (`title`, `medium`, `status`) and `## Summary` (first sentence). Present the top matches — cap at 8; if more match, list them and ask the user to select.

These populate `cites::` on the new topic. Prefer `processed` sources; flag `unread` ones as unverified.

### 5. Find adjacent topics
```bash
ls "$VAULT/topics/concepts/"
ls "$VAULT/topics/research/"
```

Scan for topics that share atoms or keywords with the new one. Propose:
- `related::` — topics in the same general space
- `part-of::` — only if the new topic is clearly a subdomain of an existing one

### 6. Create the topic file
Build the file from the appropriate template structure below. Populate all confirmed fields. Replace Templater placeholders (`<% tp.* %>`) with actual values.

The template structures below show which fields to populate. Use `_templates/topic-concept.md`, `_templates/topic-research.md`, or `_templates/topic-project.md` as the actual file base — copy the structure, then replace Templater placeholders (`<% tp.* %>`) with real values.

**Concept map** — key fields to fill:

    ---
    title: <Title>
    topic-type: concept
    tags: []
    created: <YYYY-MM-DD>
    reviewed:
    ---
    
    ## Overview
    <1–2 sentences: what this domain is and why it matters>
    
    ## Core Concepts
    covers:: [[atom-one]], [[atom-two]]
    
    ## Key Sources
    cites:: [[source-file]]
    
    ## Sub-topics and Relations
    part-of:: <if applicable>
    related:: <adjacent topics>

**Research note** — key fields to fill:

    ---
    title: <Title>
    topic-type: research
    question: <the specific research question>
    tags: []
    created: <YYYY-MM-DD>
    reviewed:
    ---
    
    ## Research Question
    <question restated in full>
    
    ## Current Understanding
    covers:: [[relevant-atom]]
    cites:: [[source-file]]

**Project** — key fields to fill:

    ---
    title: <Title>
    topic-type: project
    status: active
    tags: []
    created: <YYYY-MM-DD>
    reviewed:
    ---
    
    ## Goal
    <what you're trying to build or decide>
    
    ## Background
    covers:: [[relevant-atom]]
    cites:: [[source-file]]

All three templates include a Dataview live-query block at the bottom — copy it from the template file as-is, replacing `<% tp.file.title %>` with the actual topic title.

### 7. Back-wire atoms
For each atom confirmed in `covers::`, check whether it already has `part-of::` set. If it points elsewhere, leave it — an atom can only belong to one concept map. If `part-of::` is empty, offer to add `part-of:: [[new-topic]]`.

Ask before modifying any existing atom file.

### 8. Flag coverage gaps
Based on what the confirmed sources discuss, are there obvious concepts that belong in this topic but have no atom yet? List up to 3 candidates. For each, offer to create a stub atom (`confidence: low`, no content — just title, tags, and `part-of::`). Ask before creating.

This keeps the topic from starting as an isolated node — even stub atoms give the graph something to query.

### 9. Summary
Report:
- Topic file created at `<path>`
- N atoms linked via `covers::`
- M sources linked via `cites::`
- K atoms back-wired with `part-of::`
- L atom stubs created
- Adjacent topics connected (if any)

---

## Common Mistakes to Avoid
- Don't create the topic if one already exists with the same or very similar name — check `topics/` first
- Don't populate `covers::` with atoms that are only tangentially related; it's better to start sparse and grow the list than to pad it
- Don't set `part-of::` on an atom that already has one pointing somewhere else — an atom belongs to one topic
- Don't create more than 3 atom stubs in one init session; stubs without content accumulate and become noise
