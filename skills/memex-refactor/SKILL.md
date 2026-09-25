---
name: memex-refactor
description: Evolve atom structure through revise, split, or merge operations. Use when lint flags a bloated atom (split candidate), when two atoms should be unified (merge), or when an atom's body needs updating without changing its identity (revise). Triggers on: "refactor atom [X]", "split [atom]", "merge [A] and [B]", "revise [atom]", "this atom is too broad", "combine these atoms", "update the body of [atom]", "atom [X] now covers two things".
---

# Karpathy Wiki Refactor

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited. **Confirm it resolved to a vault before writing
anything:** `[ -f "$VAULT/_meta/schema.md" ]`. If that fails, stop and tell the
user — a stale `MEMEX_VAULT`, or this skill invoked from an unrelated repository,
otherwise writes `sources/`, `atoms/` and `_meta/log.md` into *that* repository,
and the first sign is `git status` (roadmap R14).

This skill handles three types of atom evolution: **revise** (update body in place), **split** (one atom becomes two), and **merge** (two atoms become one). All three require a user-supplied reason and confirm each write step before executing. Atoms are never deleted. A retired atom becomes a body-only stub, and each successor carries `supersedes:: [[retired-atom]]` — the successor holds the field, naming what it replaced (`$VAULT/_meta/schema.md` § Retirement). Every write goes through a candidate first (§ Candidate Gating).

Triggers for when to run:
- **revise**: new information makes the current body wrong or incomplete
- **split**: lint Section 6 flags a bloated atom, or the atom clearly covers two independent concepts
- **merge**: two atoms describe the same concept from different angles, or one has been rendered redundant by the other

For the relationship taxonomy and field definitions, read `$VAULT/_meta/schema.md` § Relationship Types.

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
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
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
- Re-count `cites::` sources and their `stage:`
- If confidence should change, propose it explicitly as a separate question
- Do not bundle confidence and body changes into one silent update

**Step R5. Apply**
One rewrite candidate (§ Candidate Gating) carrying the whole revised file:
- the updated body
- `updated:` set to today's date
- `confidence:` changed only if the user confirmed it in R4

Then write → assert → delete candidate.

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
- Lint Section 6c flags the atom as bloated (`cites::` > 5, `related::` > 4, body > 2× the vault's median size)
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
- Which `cites::` go with each child (may overlap) — including block-anchored `[[ext-…#^cNN]]` citations, each of which needs a Promotion Log row (Step S6b)

**Step S3. Identify incoming relations**
Find every note that points to the source atom, including heading-anchored and aliased links:
```bash
grep -rnE "\[\[<atom-name>([]#|])" "$VAULT/atoms/" "$VAULT/sources/" "$VAULT/topics/" "$VAULT/glossary/"
```
Collect each relation line that names the atom — `extends::`, `uses::`, a source's `supports::` or `introduces::`, and so on. Keep the whole line: a re-point is a replace of that exact line. Concept maps list nothing, so a split or merge changes no concept map; a project or research note that links the atom in prose is reported, not edited.

**Step S4. Confirm the full plan**
Draft A1 and A2 in Step S5's shape first; the user reviews them as part of the plan. Before writing anything, present the complete plan:
```
Will create:
  atoms/A1-name.md — confidence: low, cites:: [source list]
  atoms/A2-name.md — confidence: low, cites:: [source list]

Each child carries:
  supersedes:: [[atom-name]]

Will stub (body only, every relation field removed):
  atoms/<atom-name>.md — body → "Split into [[A1]] and [[A2]]"

Will re-point (decide each one now):
  atoms/other-atom.md: extends:: [[atom-name]] → extends:: [[A1 or A2?]]

Will log (one Promotion Log row per claim citation a child takes):
  extracts/ext-<slug>.md: - ^c07 -> atoms/A1-name.md (cites, YYYY-MM-DD, split from atoms/<atom-name>.md)

Topic membership: A1 and A2 each need their own part-of::; carry over
  part-of:: [[deep-learning]] from the source atom unless told otherwise.
```
Walk the re-point list one line at a time, asking which child each should name — do not batch-assign; a relation may reference an aspect of the parent that belongs to one child only. Then ask for confirmation of the whole plan.

**Step S4b. Write every candidate**
Before any vault file changes, write one candidate per file the plan touches (§ Candidate Gating): a create for A1 and for A2, a replace for each re-pointed line, an append for each Promotion Log row, and a rewrite for the stub. A split interrupted after this step leaves the rest of itself on disk for `memex-candidates`; one interrupted with no candidates leaves two live children, a parent still claiming the concept, and nothing that says a split was under way — lint exits 0 on that, because a duplicated concept is not a schema violation (T2-20).

Steps S5–S7 then apply the candidates in order, each write → assert → delete.

**Step S5. Create A1 and A2**
Use the atom template structure:
```markdown
---
type: Atom
title: <A1 title>
description: <the split-out claim in one sentence>
aliases: []
tags: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
confidence: low
generated:
  by: memex-refactor/claude-opus-5
  at: YYYY-MM-DD
---

Carry the parent atom's `generated:` forward only if the split is purely
mechanical. A split that rewrites the claim has a new author — record this skill.

## Summary
<drafted from source atom's body — user should review>

## Detail
<!-- Expand as sources are processed -->

## Sources
cites:: [[source-a]], [[source-b]]

## Connections
part-of:: <inherit from source atom if appropriate>
supersedes:: [[<atom-name>]]
```
`supersedes::` goes on each child, naming the parent: under `$VAULT/_meta/schema.md` § Relationship Types, `A supersedes:: [[B]]` means A replaces B, and that line is what retires the parent. Set `confidence: low` regardless of parent's confidence — the split creates new, unvalidated nodes.

The user reviews the drafted summaries in S4, before the candidates are written.

**Step S6. Re-point incoming relations**
Apply each re-point decided in S4. Each is a replace candidate whose `replaces:` is the whole line as S3 found it — `uses:: [[a]], [[atom-name]]` becomes `uses:: [[a]], [[A1-name]]` — so a line edited since S3 fails the match and stops instead of being guessed at.

Carry the source atom's `part-of::` onto A1 and A2 (or whichever subset the user specifies). No topic file is edited — membership is derived from `part-of::`.

**Step S6b. Carry the Promotion Log**
For every block-anchored `cites:: [[ext-<slug>#^cNN]]` that A1 or A2 takes, append a row to that extract's `## Promotion Log`:
```
- ^cNN -> atoms/A1-name.md (cites, YYYY-MM-DD, split from atoms/<atom-name>.md)
```
Keep the parent's rows: they are the history of where each claim went. The rows were confirmed with the plan in S4 — they record the split rather than decide anything, so do not ask for each one again. Each is an append candidate on `## Promotion Log`.

Why: rows name atoms. The Promotion Log is how `memex-deep-extract` mode B knows a claim is already promoted, and `_meta/lint.sh` 12g warns on every block-anchored citation whose extract has no row naming the citing atom. A split that moves citations onto new atoms without new rows leaves the log describing atoms that no longer hold those claims. On the first real vault, the split that was considered would have done that to 29 rows.

**Step S7. Stub the source atom**
Last, through its rewrite candidate: keep the frontmatter (with `updated:` set to today) and replace everything below it with:
```markdown
## Note
Split into [[A1-name]] and [[A2-name]] on YYYY-MM-DD.
```
Do not delete the file — links into it must keep resolving. Remove every relation field, `cites::` and `part-of::` included, and add none: the children's `supersedes::` already retires it, and a stub that keeps `part-of::` or `cites::` still counts toward its topic and still claims evidence (`$VAULT/_meta/schema.md` § Retirement; lint 7i warns on both). rc.2 wrote `supersedes:: [[A1]], [[A2]]` on the stub, which under the schema's own definition retired the two children and left the tombstone live (T2-33).

**Step S8. Log**
Last, after every assert has passed, naming only what landed:
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
- Adding `supersedes:: [[atom-a]], [[atom-b]]` — C holds the field, naming both atoms it replaces
- Setting `confidence: low` (re-evaluated after merge via trust-audit)
- `created:` today; `updated:` today

**Step M3. Identify incoming relations**
Find everything pointing to A or B, as in S3:
```bash
grep -rnE "\[\[(<atom-a>|<atom-b>)([]#|])" "$VAULT/atoms/" "$VAULT/sources/" "$VAULT/topics/" "$VAULT/glossary/"
```

**Step M4. Confirm the full plan**
Present before writing:
```
Will create:
  atoms/C-name.md — confidence: low; supersedes:: [[atom-a]], [[atom-b]]

Will stub (body only, every relation field removed):
  atoms/atom-a.md — body → "Merged into [[C]]"
  atoms/atom-b.md — body → "Merged into [[C]]"

Will re-point (decide each one now):
  atoms/other.md: uses:: [[atom-a]] → uses:: [[C]]

Will log (one Promotion Log row per claim citation C takes):
  extracts/ext-<slug>.md: - ^c07 -> atoms/C-name.md (cites, YYYY-MM-DD, merged from atoms/<atom-a>.md)

Topic membership: C takes part-of:: from A and B (deduplicated); if they
  disagree, ask which topic C belongs to.
```
As in S4, decide each re-point one at a time, then confirm the plan. Then write every candidate before any vault file changes, as Step S4b; M5–M7 apply them in order, each write → assert → delete.

**Step M5. Create C**
Write `atoms/C-name.md` from its create candidate. The user reviewed the draft in M4.

**Step M6. Re-point incoming relations**
Apply each re-point decided in M4, as replace candidates on the exact line (Step S6).

Set C's `part-of::` from A's and B's, deduplicated. If A and B belonged to different topics, ask which one C belongs to — an atom belongs to one topic. No topic file is edited.

**Step M6b. Carry the Promotion Log**
As Step S6b: for every block-anchored `cites::` C takes from A or B, append `- ^cNN -> atoms/C-name.md (cites, YYYY-MM-DD, merged from atoms/<atom-a>.md)` to that extract's `## Promotion Log`, and keep A's and B's rows.

**Step M7. Stub A and B**
Last, for each of A and B, through its rewrite candidate: keep the frontmatter (`updated:` today) and replace everything below it with:
```markdown
## Note
Merged into [[C-name]] on YYYY-MM-DD.
```
Do not delete the file. Remove every relation field and add none — C's `supersedes::` retires both (Step S7). rc.2 wrote `supersedes:: [[C-name]]` on each stub, retiring the survivor (T2-33).

**Step M8. Log**
Last, after every assert has passed:
```markdown
## [YYYY-MM-DD] refactor/merge | <atom-a> + <atom-b>
url:: n/a
atoms:: [[atom-a]], [[atom-b]], [[C-name]]
skill:: memex-refactor
notes: reason: <user-supplied reason>; merged into [[C-name]]
```

---

## Candidate Gating

Every file this skill changes gets a candidate in `_meta/candidates/` before any file changes (`$VAULT/_meta/schema.md` § Candidate Lifecycle). Use the session ID `YYYY-MM-DD-HHMM` from the start of the invocation, so `memex-candidates` shows one operation as one group.

| Write | Candidate |
|---|---|
| A1, A2, C | create — body is the whole note |
| Re-pointed relation line | modify, `change: replace`, `replaces:` the exact line from S3/M3 |
| Promotion Log row | modify, `section: "## Promotion Log"`, `change: append` |
| Revised body (R5), retirement stub (S7, M7) | modify, `change: rewrite`, `was-sha256:` the target's hash now |

```bash
( sha256sum "$VAULT/atoms/<atom-name>.md" 2>/dev/null || shasum -a 256 "$VAULT/atoms/<atom-name>.md" ) | cut -d' ' -f1
```

A rewrite restates the whole file, so `memex-candidates` applies it only while the target still has that hash; an edit made in between stops it instead of being reverted.

Write candidate → confirm → write → **assert** → delete candidate. The assert re-reads the target: a create or rewrite equals the candidate body; an append's line sits under its section; a replace's new line is present and the old one gone. On a miss, stop, keep that candidate and the ones after it, and report what landed — an edit tool can report success on a write that did not happen (trial 1, finding 13). The log entry is written last.

rc.2 ran a six-file split with no candidate at any point (T2-20).

---

## What This Skill Does NOT Do

- **Never deletes atoms** — a body-only stub, retired by its successor's `supersedes::`, is the only retirement pattern
- **Does not auto-detect** split or merge candidates — lint's bloated-atom WARN is the trigger; the user decides when to act
- **Does not modify source bodies** — only updates source `introduces::` or `supports::` fields if they directly name a refactored atom (and only with confirmation)
- **Does not run without a reason** — every operation requires a user-supplied reason before any writes begin

---

## Scope Guards

- Always confirm the full plan (Steps S4 / M4) before any file writes
- Always confirm re-pointing decisions individually — never batch
- Always write every candidate before the first vault write, and assert each write before deleting its candidate
- After a split or merge, suggest running `memex-trust-audit` on the affected topic: confidence: low on new atoms is expected but should be revisited once sources are re-evaluated
- After a split or merge, suggest running `memex-reconcile` to catch any `part-of::` left pointing at a topic that does not exist

---

## Common Mistakes to Avoid

- Don't set `confidence:` higher than `low` on freshly split or merged atoms — they need re-evaluation via trust-audit
- Don't re-point incoming relations without checking the atom's body — the relation may reference a specific aspect of the old atom that belongs to A1, not A2
- Don't skip logging for revise operations that change confidence — those are the most important ones to track
- Don't write `supersedes::` on the stub. The successor holds it, naming the stub; the other way round retires the live atoms (T2-33)
- Don't merge atoms that are legitimately distinct — `contrasts-with::` is the right relation for alternatives, not merging
