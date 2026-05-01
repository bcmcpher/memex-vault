---
name: memex-refactor
description: Evolve atom structure through revise, split, or merge operations. Use when lint flags a bloated atom (split candidate), when two atoms should be unified (merge), or when an atom's body needs updating without changing its identity (revise). Triggers on: "refactor atom [X]", "split [atom]", "merge [A] and [B]", "revise [atom]", "this atom is too broad", "combine these atoms", "update the body of [atom]", "atom [X] now covers two things".
---

# Karpathy Wiki Refactor

**Vault root:** `/home/bcmcpher/Projects/claude/memex-llm-obsidian-template`

This skill handles three types of atom evolution: **revise** (update body in place), **split** (one atom becomes two), and **merge** (two atoms become one). All three require a user-supplied reason and confirm each write step before executing. Atoms are never deleted — retired atoms become stubs with `supersedes::` pointing to their successors.

Triggers for when to run:
- **revise**: new information makes the current body wrong or incomplete
- **split**: lint Section 6 flags a bloated atom, or the atom clearly covers two independent concepts
- **merge**: two atoms describe the same concept from different angles, or one has been rendered redundant by the other

For the full relationship taxonomy, read: `references/vault-schema.md`

---

## Mode 1 — Revise

Update an atom's body content without changing its identity, relations, or graph position.

### When to use
- New evidence updates a claim
- An atom's summary was a placeholder and is now being written properly
- Confidence should change based on new sources (propose alongside body edit)

### Workflow

**Step R1. Read the current atom**
```bash
VAULT=/home/bcmcpher/Projects/claude/memex-llm-obsidian-template
cat "$VAULT/atoms/<atom-name>.md"
```

**Step R2. Ask for the change**
Ask the user: "What should change?" Accept:
- New body content pasted directly
- A description of the change ("remove the claim about X; add that Y applies instead")
- A request to draft from a specific source: "update from [[source-name]]"

**Step R3. Propose the edit**
Show the proposed new body as a diff or side-by-side. Ask for confirmation before writing.

**Step R4. Assess confidence**
If the change affects how many or which sources support the atom:
- Re-count `cites::` sources and their `status:`
- If confidence should change, propose it explicitly as a separate question
- Do not bundle confidence and body changes into one silent update

**Step R5. Apply**
- Write the updated body
- Update `updated:` in frontmatter to today's date
- Update `confidence:` only if user confirmed the change

**Step R6. Log**
```markdown
## [YYYY-MM-DD] refactor/revise | <atom-name>
url:: n/a
atoms:: [[atom-name]]
skill:: memex-refactor
notes: reason: <user-supplied reason>; confidence: <unchanged|low→medium|etc>
```

---

## Mode 2 — Split (A → A1 + A2)

Divide one atom into two when it covers distinct concepts that warrant separate nodes.

### When to use
- Lint Section 6c flags the atom as bloated (`cites::` > 5, `related::` > 4, body > 100 lines)
- The atom's title describes two things joined by "and" or "/"
- You find yourself saying "this atom covers X in context Y but also X in context Z"

### Workflow

**Step S1. Read the source atom**
```bash
cat "$VAULT/atoms/<atom-name>.md"
```

**Step S2. Define the split boundary**
Ask the user to name both children and describe the conceptual boundary:
- Child A1 name and concept scope
- Child A2 name and concept scope
- Which `cites::` sources go with each child (may overlap)

**Step S3. Identify incoming relations**
Find all atoms that point to the source atom:
```bash
grep -rn "\[\[<atom-name>\]\]" "$VAULT/atoms/"
grep -rn "\[\[<atom-name>\]\]" "$VAULT/topics/"
```
Collect: which atoms use `extends::`, `uses::`, `part-of::` to point here, and which topics list it in `covers::`.

**Step S4. Confirm the full plan**
Before writing anything, present the complete plan:
```
Will create:
  atoms/A1-name.md — confidence: low, cites:: [source list]
  atoms/A2-name.md — confidence: low, cites:: [source list]

Will stub:
  atoms/<atom-name>.md — supersedes:: [[A1]], [[A2]]; body → "Split into [[A1]] and [[A2]]"

Will re-point (each requires your confirmation):
  atoms/other-atom.md: extends:: [[atom-name]] → extends:: [[A1 or A2?]]
  topics/concepts/deep-learning.md: covers:: [[atom-name]] → covers:: [[A1]], [[A2]]
```
Ask for confirmation to proceed.

**Step S5. Create A1 and A2**
Use the atom template structure:
```markdown
---
title: <A1 title>
aliases: []
tags: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
confidence: low
---

## Summary
<drafted from source atom's body — user should review>

## Detail
<!-- Expand as sources are processed -->

## Sources
cites:: [[source-a]], [[source-b]]

## Connections
part-of:: <inherit from source atom if appropriate>
```
Set `confidence: low` regardless of parent's confidence — the split creates new, unvalidated nodes.

Ask user to review the drafted summaries before writing.

**Step S6. Re-point incoming relations**
For each atom with a relation pointing to the source atom, propose which child it should now point to. Confirm each one individually — do not batch-assign. Write the change only after confirmation.

For topics with `covers:: [[atom-name]]`: replace with `covers:: [[A1]], [[A2]]` (or whichever subset the user specifies).

**Step S7. Stub the source atom**
Replace the source atom's body with:
```markdown
## Note
Split into [[A1-name]] and [[A2-name]] on YYYY-MM-DD.
```
Add to frontmatter or Connections:
```
supersedes:: [[A1-name]], [[A2-name]]
```
Do not delete the file. Do not remove existing relation fields — add `supersedes::` alongside them.

**Step S8. Log**
```markdown
## [YYYY-MM-DD] refactor/split | <atom-name>
url:: n/a
atoms:: [[atom-name]], [[A1-name]], [[A2-name]]
skill:: memex-refactor
notes: reason: <user-supplied reason>; split into [[A1-name]] and [[A2-name]]
```

---

## Mode 3 — Merge (A + B → C)

Combine two atoms into one when they describe the same concept or when one has been made redundant.

### When to use
- Two atoms have the same `extends::` parent and near-identical bodies
- One atom's scope has been absorbed into another's after successive revisions
- A glossary entry has grown into a full atom and needs to replace an existing stub

### Workflow

**Step M1. Read both source atoms**
```bash
cat "$VAULT/atoms/<atom-a>.md"
cat "$VAULT/atoms/<atom-b>.md"
```

**Step M2. Name and draft C**
Ask the user for the merged concept name and filename. Draft the merged body by:
- Combining both `Summary` sections (user reviews and trims)
- Taking the union of all relation fields from A and B
- Setting `confidence: low` (re-evaluated after merge via trust-audit)
- `created:` today; `updated:` today

**Step M3. Identify incoming relations**
Find everything pointing to A or B:
```bash
grep -rn "\[\[<atom-a>\]\]" "$VAULT/atoms/" "$VAULT/topics/"
grep -rn "\[\[<atom-b>\]\]" "$VAULT/atoms/" "$VAULT/topics/"
```

**Step M4. Confirm the full plan**
Present before writing:
```
Will create:
  atoms/C-name.md — confidence: low

Will stub:
  atoms/atom-a.md — supersedes:: [[C]]; body → "Merged into [[C]]"
  atoms/atom-b.md — supersedes:: [[C]]; body → "Merged into [[C]]"

Will re-point (each requires confirmation):
  atoms/other.md: uses:: [[atom-a]] → uses:: [[C]]
  topics/concepts/deep-learning.md: covers:: [[atom-a]], [[atom-b]] → covers:: [[C]]
```

**Step M5. Create C**
Write `atoms/C-name.md` with merged content. Ask user to review the draft before writing.

**Step M6. Re-point incoming relations**
For each atom with a relation pointing to A or B, propose re-pointing to C. Confirm individually.

For topics: replace both A and B entries in `covers::` with C (deduplicated).

**Step M7. Stub A and B**
For each source atom, replace body with:
```markdown
## Note
Merged into [[C-name]] on YYYY-MM-DD.
```
Add `supersedes:: [[C-name]]` to each. Do not delete, do not remove existing relation fields.

**Step M8. Log**
```markdown
## [YYYY-MM-DD] refactor/merge | <atom-a> + <atom-b>
url:: n/a
atoms:: [[atom-a]], [[atom-b]], [[C-name]]
skill:: memex-refactor
notes: reason: <user-supplied reason>; merged into [[C-name]]
```

---

## What This Skill Does NOT Do

- **Never deletes atoms** — stubbing with `supersedes::` is the only retirement pattern
- **Does not auto-detect** split or merge candidates — lint's bloated-atom WARN is the trigger; the user decides when to act
- **Does not modify source bodies** — only updates source `introduces::` or `supports::` fields if they directly name a refactored atom (and only with confirmation)
- **Does not run without a reason** — every operation requires a user-supplied reason before any writes begin

---

## Scope Guards

- Always confirm the full plan (Steps S4 / M4) before any file writes
- Always confirm re-pointing decisions individually — never batch
- After a split or merge, suggest running `memex-trust-audit` on the affected topic: confidence: low on new atoms is expected but should be revisited once sources are re-evaluated
- After a split or merge, suggest running `memex-reconcile` to catch any `part-of` / `covers::` drift introduced by the re-pointing

---

## Common Mistakes to Avoid

- Don't set `confidence:` higher than `low` on freshly split or merged atoms — they need re-evaluation via trust-audit
- Don't re-point incoming relations without checking the atom's body — the relation may reference a specific aspect of the old atom that belongs to A1, not A2
- Don't skip logging for revise operations that change confidence — those are the most important ones to track
- Don't merge atoms that are legitimately distinct — `contrasts-with::` is the right relation for alternatives, not merging
