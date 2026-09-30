---
name: memex-topic-init
description: Create and bootstrap a new topic node in the personal Karpathy-style Obsidian wiki vault. Use this skill whenever the user wants to start a new concept map, research note, or project workspace — and wire it into existing atoms and sources in one step. Triggers on: "create a new topic", "start a concept map for X", "I want a research note on Y", "set up a new project in my wiki", "initialize a topic", "create a topic for Z", "I'm starting to study X and want to track it", "new wiki topic", "add a domain to my vault". Also triggers when the user names a domain they've been accumulating sources on and wants a navigational hub for it.
---

# Karpathy Wiki Topic Init

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited. **Confirm it resolved to a vault before writing
anything:** `[ -f "$VAULT/_meta/schema.md" ]`. If that fails, stop and tell the
user — a stale `MEMEX_VAULT`, or this skill invoked from an unrelated repository,
otherwise writes `sources/`, `atoms/` and `_meta/log.md` into *that* repository,
and the first sign is `git status` (roadmap R14).

This skill creates a new topic node — a concept map, research note, or project workspace — and immediately wires it into the existing graph. The goal is to give a freshly named topic a meaningful starting structure rather than an empty shell: atoms already in the vault get linked, relevant sources get cited, and adjacent topics get connected.

For the topic hierarchy rules and the relationship taxonomy, read `$VAULT/_meta/schema.md` § Topic Hierarchy and § Relationship Types.

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
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
ls "$VAULT/topics/concepts/" "$VAULT/topics/research/" "$VAULT/topics/projects/" | grep -i "keyword"
```

If a close match exists, show it to the user and ask whether to extend the existing topic instead of creating a new one. Confirm the filename slug before writing.

Then check the slug against the **whole vault**, not just `topics/`:

```bash
find "$VAULT" -name "<slug>.md" -not -path '*/.archive/*' -not -path '*/.git/*'
```

This must print nothing. Atoms, glossary entries and topics share one wikilink
namespace, and a domain's name is very often the name of its most central atom. In
trial 2, three of the five domain-tag clusters had a tag that was also an atom's
filename (`tractography`, `diffusion-mri`, `structural-connectivity`) (T2-37). A topic
at that slug makes every `part-of:: [[<slug>]]` resolve to whichever file Obsidian
meets first. Lint section 1 FAILs the collision. If the slug is taken, name the map
for the domain rather than the concept, for example `tractography-methods`. Never
reuse the bare slug (`_meta/schema.md` § Disambiguation Policy).

### 2. Build a keyword set
Derive 3–5 search keywords from the topic title and description. Include synonyms and abbreviations — e.g., "transformers" → also search "attention", "self-attention". These keywords drive the atom and source search in the next steps.

### 3. Search for relevant atoms
```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"

# Match by filename
ls "$VAULT/atoms/" | grep -i "keyword"

# Match by content (title/tags)
grep -rl "keyword" "$VAULT/atoms/"
```

For each candidate atom, read its `title` and `## Summary` (one line is enough). Present grouped into:
- **Strong candidates** — title or summary directly matches the topic
- **Possible candidates** — content mentions the topic but may be peripheral

Ask the user which atoms belong to the topic. Default to including strong candidates; let the user drop any that don't fit. Membership is recorded on each atom's `part-of::` in step 7 — the topic file never lists its atoms.

### 4. Search for relevant sources
```bash
grep -rl "keyword" "$VAULT/sources/"
```

Read each hit's frontmatter (`title`, `medium`, `stage`) and `## Summary` (first sentence). Present the top matches — cap at 8; if more match, list them and ask the user to select.

These populate `cites::` on the new topic. Prefer `processed` sources; flag `unread` ones as unverified.

### 5. Find adjacent topics
```bash
ls "$VAULT/topics/concepts/"
ls "$VAULT/topics/research/"
```

Scan for topics that share atoms or keywords with the new one. Propose:
- `related::` — topics in the same general space
- `part-of::` — concept maps only: the one parent concept map, if the new map is clearly a sub-domain of an existing one. A concept map names at most one parent (`_meta/schema.md` § Topic Hierarchy)

`related::` goes on a concept map's `## Sub-topics and Relations` line. The research
and project templates have no such line, so propose it for concept maps only.

#### 5a. When a parent is proposed: the atoms it holds directly

Naming a parent makes it a non-leaf. An atom names one concept map, and it must be a
leaf (§ Topic Hierarchy). Every atom the parent holds **directly** is therefore
stranded the moment the new map exists, unless it moves. Lint section 7g warns
on each one: *"part-of:: [[parent]] has sub-topics; name the leaf this atom belongs
to"*. In trial 2 this skill split `structural-connectomics` as lint section 6d
asked. It moved the 5 atoms step 3 confirmed and left 15 behind, which traded one
lint warning for fifteen (T2-34).

List the parent's live direct atoms. Retired atoms (named in some `supersedes::`)
are skipped, as lint skips them:

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
parent=<parent-slug>
retired=$(grep -rhE '^supersedes::' "$VAULT/atoms" --include='*.md' | grep -oE '\[\[[^]|#]+' | sed 's/^\[\[//' | sort -u)
grep -lE "^part-of::.*\[\[${parent}\]\]" "$VAULT"/atoms/*.md | while IFS= read -r f; do
    printf '%s\n' "$retired" | grep -qxF "$(basename "$f" .md)" || echo "$f"
done
```

Also check whether the parent already has children:
`grep -lE "^part-of::.*\[\[<parent>\]\]" "$VAULT"/topics/concepts/*.md`.

- **The parent is a leaf with no live direct atoms.** Nothing is stranded. Go on.
- **The parent is a leaf with live direct atoms.** Before anything is written, get
  one of these outcomes from the user:
  - **(a) Every direct atom is re-homed.** Each one moves to the new map (add it to
    step 3's confirmed set) or to an existing child of the parent.
  - **(b) The siblings it needs are created in this session.** Some atoms fit
    neither the new map nor an existing child. For each sibling the user names, run
    step 1's slug and collision checks and step 6. Give it the same parent, and
    move its atoms onto it. Stop at 3 siblings in one session. A split needing more
    is `memex-review` Lens F's job.
  - **(c) The new map does not name the parent.** It becomes a root, or takes
    another parent, and the report says why.

  Leaving some atoms behind is a partial split, so do not write one. If the user
  wants to defer the rest, that is outcome (c): create the map without the parent
  now, and add `part-of::` later, once the parent's atoms have somewhere to go.
- **The parent already has children.** Its direct atoms already warn in section 7g,
  and this map does not add to that. List them and offer each one a move, as in
  (a), but do not require it.

### 6. Draft the topic file
Copy the template **verbatim**: `_templates/topic-concept.md`,
`_templates/topic-research.md` or `_templates/topic-project.md`. Then fill in only the
fields listed here. Do not retype the template's structure from memory. rc.2
printed a copy of the concept template here, and it went stale: it had one Dataview
block where the template has two. The copy was missing the `### Via sub-topics`
rollup, which is how a parent lists its children's atoms (T2-35). A list of fields
cannot drift from the template the way a second copy can.

| Type | Fill |
|---|---|
| Concept map | `title:`, `description:` (one sentence: what this domain is), `tags:`, `created:`, `## Overview` (1–2 sentences), `cites::`, `part-of::` (the parent from step 5, or empty on a root), `related::` |
| Research note | `title:`, `description:` (the question in one line), `question:`, `tags:`, `created:`, the `## Research Question` line, `cites::` |
| Project | `title:`, `description:`, `tags:`, `created:`, `## Goal`, `cites::` |

Replace each Templater placeholder (`<% tp.* %>`) with a real value. Leave `reviewed:`
empty. Add the provenance block to the frontmatter:

```yaml
generated:
  by: memex-topic-init/claude-opus-5
  at: YYYY-MM-DD
```

Leave every Dataview block exactly as the template has it. The blocks refer to their
own note (`this.file.link`), so nothing needs substituting. They are how the topic
shows its atoms. There is no membership list to write by hand.

### 7. Wire atom membership
This step is what actually creates the topic's membership — the Dataview block in
step 6 returns nothing until it runs.

For each atom confirmed in step 3, check which topics its `part-of::` already names.
An atom names **one leaf concept map**, plus any number of projects and research
questions (`_meta/schema.md` § Topic Hierarchy):

- **New topic is a project or research question** — membership is additive; offer
  to add `part-of:: [[new-topic]]` without touching the atom's concept map.
- **New topic is a concept map, atom names none** — offer to add it.
- **New topic is a concept map that is a sub-topic of the atom's current one** —
  offer to *move* the atom's concept-map membership down to the new, more specific
  leaf. It still counts toward the parent through the rollup.
- **Atom is a direct member of the parent, re-homed in step 5a** — move it to the
  leaf chosen there, which is the new map, an existing child, or a sibling from
  (b).
- **Atom names an unrelated concept map** — leave it.

Every edit here changes one line, the atom's `part-of::` line. Links to projects and
research questions on that line stay as they are. Each edit is a **replace**
candidate whose `replaces:` holds the current line exactly. On an atom that names no
topic, that is the template's empty `part-of::` line. Never append a second
`part-of::` line.

Report how many atoms were left pointing elsewhere, since those will not appear in
the new topic.

### 8. Flag coverage gaps
Based on what the confirmed sources discuss, are there obvious concepts that belong in this topic but have no atom yet? List up to 3 candidates. For each, offer to create a stub atom (`type: Atom`, `confidence: low`, no content — just title, `description:`, tags, and `part-of::`). Ask before creating. Run step 1's `find` collision check on each stub's slug.

This keeps the topic from starting as an isolated node — even stub atoms give the graph something to query.

### 9. Write: candidates first
Write a candidate for **every** file the session will change before changing any of
them (`_meta/schema.md` § Candidate Lifecycle, "Gate the whole write set"):

- a **create** candidate for the new topic, each sibling from 5a (b), and each stub
  from step 8, holding the whole file;
- a **replace** candidate for each atom `part-of::` edit from step 7.

Show the set and confirm it. Then apply the candidates in that order: topics first,
so no `part-of::` ever names a file that does not exist yet. Each one goes write →
**assert** → delete candidate. The assert re-reads the target. A create's file must
exist and equal the candidate body. A replace's new line must be present and its
`replaces:` line gone. On a miss, stop. Keep that candidate and every one after it,
report what landed, and do not log the rest. An edit tool can report success on a
write that did not happen (trial 1, finding 13).

### 10. Log
Last, after every assert has passed, append to `_meta/log.md`, naming only what
landed:
```markdown
## [YYYY-MM-DD] topic-created | <topic-title>
url:: n/a
atoms:: [[atom-one]], [[atom-two]]
skill:: memex-topic-init
notes: type: <Concept Map|Research Question|Project>; N atoms wired; M sources; L stubs created; parent: <[[parent]] — D direct atoms re-homed, S siblings created, 0 left | none>
```

### 11. Summary
Report:
- Topic file created at `<path>`, and any siblings
- M sources linked via `cites::`
- N atoms wired with `part-of::` (and K left pointing at another topic)
- L atom stubs created
- Adjacent topics connected (if any)
- **Atoms left directly on the parent:** zero is the only answer lint accepts. Any
  other number means a candidate failed its assert. Name those atoms.

---

## Common Mistakes to Avoid
- Don't create the topic if one already exists with the same or very similar name — check `topics/` first
- Don't wire `part-of::` on atoms that are only tangentially related; it's better to start sparse and grow than to pad the topic
- Don't hand-write a membership list into the topic file — the Dataview block is the only membership view, and a stale hand-written list is exactly what Phase 1 removed
- Don't give an atom a second concept map — it names one leaf. Move it to a more specific sub-topic, or leave it; projects and research questions are the only additive memberships
- Don't create more than 3 atom stubs in one init session; stubs without content accumulate and become noise
- Don't name a parent and leave its direct atoms on it — each one is a section 7g warning. Re-home them all, create the siblings they need, or don't name the parent (step 5a)
- Don't take a slug another note already has, in any folder — check with `find`, not `ls topics/`
- Don't retype a template — copy the file and fill the fields in step 6
