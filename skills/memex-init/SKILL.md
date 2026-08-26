---
name: memex-init
description: Specialize a freshly forked memex-vault for its own subject matter. Use once, right after cloning the template, to replace the domain vocabulary and scaffold the folders a fork needs. Triggers on "initialize my vault", "set up this vault", "make this vault mine", "specialize this template", "I just forked this, now what", "onboard my vault", "configure the domain", "this vault is for [subject] now". Also triggers when someone asks how to adapt the template to a different field — law, medicine, internal docs. Re-runnable later to extend the tag or source-type vocabulary without touching anything already written.
---

# Memex Init

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited.

This skill turns the template into *someone's* vault. It asks five questions,
rewrites `_meta/domain.md` from the answers, scaffolds the folders that vocabulary
implies, seeds one topic to enter at, and leaves the vault passing `_meta/lint.sh`.

It is the answer to "I forked this — now what?" Everything it writes is
instance-specific by design. Everything it refuses to touch is the constitution.

**Never modifies `_meta/schema.md`.** That file is what every memex-vault shares:
relation types, stage values, naming patterns, the confidence rubric. A fork that
edits it has forked the format, not the domain. If the user wants a change there,
say so plainly and stop — that is a schema amendment, not an init.

**Never deletes a folder.** A fork that drops `video` from its source types keeps
`sources/video/`. Empty folders cost nothing; deleting one that turns out to hold
notes costs the notes. Report what is now unused and let the user remove it.

---

## Before anything: is this vault already initialized?

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
grep -c "skill:: memex-init" "$VAULT/_meta/log.md" 2>/dev/null || echo 0
```

**Zero** — a fresh fork. Run the full workflow.

**One or more** — already initialized. Do **not** re-run steps 6, 7, or 8; they
would overwrite work. Say what the previous run set the domain to, then offer the
re-run subset only:

- extend Domain Tags, Type Tags, or Stage Tags (step 5 → step 6, vocabulary blocks only)
- add a source type (step 3 → step 6 → step 7, new folder only)

Confirm each addition individually. A re-run never removes a vocabulary entry —
notes already tagged with it would go unknown-tag on the next lint.

---

## The five questions

Ask all five before writing anything. The answers are interdependent — source
types shape the OKF Types table, and the domain name seeds the first topic — so a
half-answered init writes a half-consistent vault. Show the user the complete set
of answers and confirm once, then write.

### 1. Domain name
One line of free text, e.g. *"Case law and civil procedure"*. Goes in
`_meta/domain.md` § Domain Name, and into `getting-started.md`.

Also derive a **slug** from it (kebab-case, ≤ 4 words) for the first topic's
filename. Confirm the slug with the user — it becomes a wikilink target that
atoms will point at, and Obsidian resolves wikilinks by filename.

### 2. Source types
What kinds of thing will this vault save? The template ships
`web video paper docs meeting`.

Offer that list, and let the user add, drop, or rename. Two things to say out loud:

- **`meeting` is reserved.** Notes in `sources/meeting/` are checked for `date:`
  instead of `url:`/`saved:`, because a meeting has no URL. Renaming it keeps the
  notes legal and loses that one check.
- **Dropping a type does not delete its folder.** It stops being a legal `medium:`
  value, and lint will warn that the folder is undeclared until the user removes it.

### 3. Projects?
Will this vault track active work — things with a goal and a finish line? If no,
`topics/projects/` stays on disk but goes unmentioned in the onboarding text.

### 4. Research questions?
Will this vault pursue open questions across sources? Same handling as projects:
kept on disk, mentioned only if wanted.

### 5. Initial tags
Subject-matter tags for § Domain Tags — 5–10 is a good start. Push back on more:
an unused tag is indistinguishable from a typo at lint time, and the vocabulary is
trivial to extend later by re-running this skill.

Say explicitly that **Type Tags and Stage Tags are not being asked about** because
they survive a fork unchanged — `foundational`/`applied`/`survey` and
`needs-review`/`stale` describe *how you relate to a note*, not what it is about.
The user can still edit them by hand.

---

## Workflow

### 6. Rewrite `_meta/domain.md`

**Edit the fenced blocks in place. Do not regenerate the file.** The prose between
the blocks explains what each vocabulary controls and why lint reads it from here;
regenerating loses that and leaves a fork with a vocabulary it does not understand.

Four blocks change:

| Section | New content |
|---------|-------------|
| Domain Name | The answer to Q1, one line |
| Domain Tags | The answer to Q5, one per line |
| Source Types | The answer to Q2, one per line |
| OKF Types | One `sources/<medium>\|Source` row per Q2 answer, then the non-source rows unchanged |

Leave **Type Tags** and **Stage Tags** exactly as they are.

The OKF Types table is the one with a trap: it must gain a row for every new source
type and lose the rows for dropped ones, or `_meta/lint.sh` section 11a fails every
note in the new folder for having a `type:` its folder does not declare. The
non-source rows — `atoms`, `glossary`, `topics/*`, `extracts` — are part of the
format and stay. Renaming `Atom` to `Note` is legitimate here and nowhere else;
mention it only if the user asks.

### 7. Scaffold folders

For each source type from Q2:

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
mkdir -p "$VAULT/sources/<medium>"
touch "$VAULT/sources/<medium>/.gitkeep"
```

Then confirm the evidence layer exists — a fork cloned from a tag predating it may
not have it:

```bash
ls -d "$VAULT/extracts" && ls "$VAULT/_templates/extract.md"
```

If either is missing, create the folder with a `.gitkeep` and stop to say the
template copy is incomplete rather than inventing a template.

**Tell the user the `ext-` rule.** Extracts are named `ext-<source-slug>.md`.
The prefix is not decoration: Obsidian resolves wikilinks by filename across the
whole vault, so an extract named after its source collides with that source and
every `cites::` silently resolves to whichever file Obsidian picks first. A fork
that drops the prefix breaks its citations the first time it deep-extracts
anything. See `_meta/deep-extract-design.md` § Implementation decisions 5.

Do **not** create `anki/`. It belongs to a deferred phase and would leave the fork
with an empty folder nothing writes to.

### 8. First topic

Create one concept map at `topics/concepts/<slug>.md` from Q1, so the vault has a
door rather than an empty `topics/`:

    ---
    type: Concept Map
    title: <Domain Name>
    description: <one sentence: what this vault covers>
    tags: []
    created: <YYYY-MM-DD>
    generated:
      by: memex-init/claude-opus-5
      at: <YYYY-MM-DD>
    ---

    ## Overview
    <1–2 sentences from Q1>

    ## Core Concepts
    Membership is derived from each atom's `part-of::` — there is nothing to maintain
    here. Add `part-of:: [[<slug>]]` to an atom and it appears below.

    ```dataview
    LIST FROM "atoms"
    WHERE contains(row["part-of"], this.file.link)
    ```

    ## Key Sources
    cites::

    ## Related Domains
    part-of::
    related::

Copy the Dataview block verbatim from `_templates/topic-concept.md` — it is
self-referential (`this.file.link`), so nothing needs substituting.

**Never overwrite this file on a re-run.** If it exists, say so and move on.

Do not call `memex-topic-init` here. That skill's value is searching existing atoms
and sources to wire a new topic into them, and a fresh fork has none — it would run
five search steps over empty folders to produce this same stub. Point the user at
it for their *second* topic, which is where it starts paying.

### 9. Obsidian exclusion for `_okf/`

```bash
cat "$VAULT/.obsidian/app.json"
```

Add `_okf` to `userIgnoreFilters` alongside `.archive`, keeping the existing
entries:

```json
{
  "userIgnoreFilters": [
    ".archive",
    "_okf"
  ]
}
```

The exclusion goes in **before** anything exports, not after. `_okf/` holds a
translated copy of every note in the vault; unexcluded, it doubles every search
result and every graph node, and the duplicates link to each other. That is the one
way the export layer can regress the vault, and the fix is ordering — write the
filter now, while the folder is still empty.

Do not create `_okf/` itself. The exporter makes it on first run; an empty folder
for an unbuilt feature is exactly what this skill declines to scaffold elsewhere.

### 10. Rewrite `getting-started.md`

`topics/concepts/getting-started.md` is the orientation note. Most of it is
format-generic and stays. Three parts are domain-specific:

- **`## Overview`** — rewrite for this domain. It currently describes the template.
- **`### Creating a new source`** — the template list must match Q2. There are only
  two source templates, `source-digital.md` and `source-meeting.md`; `medium:` is
  set per note, not per template. Do not list one template per medium.
- **Projects and research questions** — mention only what Q3 and Q4 asked for.

Leave the three-layer diagram, the relationship-field examples, the maintenance
table, and the `part-of::` direction note alone. They describe the format.

Then state the plugin contract, because a fork will otherwise install what the old
README asked for:

- **Dataview is the only hard requirement.** Every `_meta/index.md` catalog and
  every relationship query runs on it.
- **Core Bases does not replace it.** Bases reads YAML frontmatter; every typed
  relation in this schema is a Dataview inline field in the note body. Bases can
  render the frontmatter-only catalogs and none of the graph queries.
- **Canvas** matters only if the fork keeps `canvas/`.
- **Templater is optional.** The shipped templates use `tp.date.now` and
  `tp.file.title`, both of which core Templates covers; every skill fills the
  placeholders itself.
- **Folder Notes and Graph Analysis are not required** and should not be installed
  on this vault's account. Nothing references either.

Full table: `README.md` § Obsidian Plugins.

### 11. Verify

```bash
bash "$VAULT/_meta/lint.sh"; echo "exit=$?"
```

**Must be 0.** A non-zero exit here means the init left the vault inconsistent —
almost always a source type without its OKF Types row, or a tag used in the seed
topic that Q5 never declared. Fix it before reporting success; do not hand the user
a vault that fails its own check on day one.

Exit status 2 is a linter bug, not a finding about the vault — report it as such.

### 12. Log

```markdown
## [YYYY-MM-DD] init | <Domain Name>
url:: n/a
atoms:: 
skill:: memex-init
notes: N source types (<list>); M domain tags; topic stub <slug>; projects: yes/no; research: yes/no
```

This entry is also the re-run detector at the top of this skill, so it must be
written on every run, including a partial one. If the user stops halfway, log what
was done and say which steps did not run.

### 13. Report

State, in this order:

1. Domain name and the slug of the topic created
2. Source types, and any folder now unused because a type was dropped
3. Vocabulary counts written to `_meta/domain.md`
4. `lint.sh` exit status
5. **What is left to do by hand**, which is always:
   - `README.md` — still describes the template's domain; the fork's front page
   - install Dataview in Obsidian, and set the template folder to `_templates`
   - `git remote set-url` if the fork still points at the template's origin

Do not claim the vault is "ready" while item 5 is outstanding. It is initialized;
those three are the difference between initialized and someone's.

---

## Common Mistakes to Avoid

- Don't edit `_meta/schema.md`. If the domain seems to need a new relation type,
  that is a schema amendment — raise it, don't smuggle it into an init.
- Don't delete `sources/<medium>/` for a dropped source type, or any other folder.
- Don't regenerate `_meta/domain.md` from scratch — the prose between the fenced
  blocks is instructions the fork will need, and it is not in git for them anymore
  once overwritten.
- Don't add a source type without its `sources/<medium>|Source` row in § OKF Types.
  Lint fails every note in the new folder, and the error names the note rather than
  the missing row.
- Don't scaffold `anki/` or `_okf/`. Empty folders for unbuilt features are noise;
  the `_okf` *exclusion* is the part that has to exist early.
- Don't seed more than one topic. The vault should start sparse — `memex-topic-emerge`
  discovers the rest from real notes rather than guesses.
- Don't skip the lint run because "nothing was written yet". The OKF Types table is
  exactly the kind of edit that looks right and fails.
