---
name: memex-reconcile
description: Repair dangling link targets — a part-of:: naming no topic, or any relation field naming a note that does not exist — and work the backlog of untyped related:: links, promoting each to a typed relation where one genuinely fits. Use when running a vault health check, after bulk ingest, or when lint Section 7a or 7h surfaces dangling-link warnings. Triggers on: "reconcile my vault", "check graph integrity", "fix dangling links", "part-of points nowhere", "cites points nowhere", "promote related links", "retype my related links".
---

# Karpathy Wiki Reconcile

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited. **Confirm it resolved to a vault before writing
anything:** `[ -f "$VAULT/_meta/schema.md" ]`. If that fails, stop and tell the
user — a stale `MEMEX_VAULT`, or this skill invoked from an unrelated repository,
otherwise writes `sources/`, `atoms/` and `_meta/log.md` into *that* repository,
and the first sign is `git status` (roadmap R14).

This skill runs three repair passes over the graph:

1. **Dangling `part-of::`** — an atom names a topic file that does not exist.
2. **Dangling everything else** — any other relation field naming a note that
   does not exist.
3. **Untyped `related::`** — a fallback link, worked as a backlog and resolved
   into a precise relation where one genuinely fits.

For the full relationship taxonomy, read: `references/vault-schema.md`

> **Topic membership is derived.** Atoms declare `part-of::`; topics discover
> their atoms by Dataview query. There is no `covers::` field and no bidirectional
> drift to reconcile — that was retired in roadmap Phase 1. A query cannot fall
> out of step with its source. What *can* break is a `part-of::` that points at
> nothing, which is Pass 1.

---

## When to Run

- After bulk ingest of multiple sources
- When `_meta/lint.sh` Section 7a surfaces orphan `part-of::` WARNs, or Section 7h
  surfaces `but no such note` WARNs
- When the user asks to work the `related::` backlog — Pass 3 has no schedule and
  no lint signal, so it runs only when invoked
- Before running `memex-compose` (composition depends on correct membership)

---

## Pass 1 — Dangling `part-of::`

### 1. Discover

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
grep -rn "^part-of::" "$VAULT/atoms/" "$VAULT/topics/"
```

Both sides carry `part-of::`: an atom names its topics, and a concept map names its
parent. A dangling parent is worse than a dangling atom — it detaches the whole
sub-tree from its root (`_meta/schema.md` § Topic Hierarchy).

Extract wikilink targets by stripping `[[` and `]]`; ignore display-text aliases
(anything after `|`). For each target, check whether a matching topic file exists:

```bash
find "$VAULT/topics" -name "<target>.md"
```

Every target with no matching file is a dangling link. The atom believes it
belongs to a topic; no topic will ever surface it.

### 2. Present

```
DANGLING: atoms/transformer-architecture.md
  part-of:: [[deep-lerning]]
  No topic file matches. This atom appears in no topic.
  Nearest existing topics: deep-learning, machine-learning
  → Proposed fix: retarget to part-of:: [[deep-learning]]
```

Always offer the nearest existing topic names — most dangling links are typos or
renamed topics, not missing ones. Compute nearest by simple slug similarity; do
not guess silently.

If there are none, report "No dangling part-of:: links found." and move to Pass 2.

### 3. Confirm each fix individually

Present one at a time. The user can:

- **Retarget** — point `part-of::` at an existing topic
- **Create** — the topic genuinely does not exist yet; hand off to
  `memex-topic-init` rather than writing a stub here
- **Remove** — drop the `part-of::` entirely; the atom belongs to no topic
- **Skip** — leave it

Never batch-apply. Never auto-repair without confirmation.

### 4. Apply

- Edit `part-of::` in the atom's `## Connections` section
- Update `updated:` in the atom's frontmatter to today

---

## Pass 2 — Dangling everything else

`part-of::` was the only field lint resolved until rc.2. Section 7h now resolves
every `field:: [[Target]]` on every layer, which is how a `cites::` pointing at a
source that was never written became visible
(`_meta/comparison-claude-obsidian.md` verdict 1). This pass is where those get
repaired.

**Take `cites::` first, and treat it differently from the rest.** A dangling
`related::` is a broken cross-reference. A dangling `cites::` is an atom that
*reads as grounded and is not* — and because Section 6b counts the field rather
than resolving it, that atom was also exempt from the orphan check for as long as
the bad link stood. Report the two groups separately and say which is which.

### 1. Discover

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
bash "$VAULT/_meta/lint.sh" 2>/dev/null | grep "but no such note"
```

Read the findings from lint rather than re-deriving them: lint already skips
fenced code, aliases and frontmatter, and a second implementation of that parse
is a second thing that can disagree. Section 12e's `[[target#^anchor]]` findings
are the same defect at claim grain — work them in this pass too.

### 2. Present, grouped by field

```
DANGLING cites:: — the atom reads as grounded and is not
  atoms/connectome-node-definition.md
    cites:: [[2026-09-11-hagman-mapping-the-structural-core]]
    No note matches. Nearest: 2026-09-11-hagmann-mapping-the-structural-core
    → Proposed fix: retarget (one-character difference in the surname)

DANGLING related:: — a broken cross-reference
  atoms/bundle-segmentation.md
    related:: [[tractography-filtering]]
    No note matches, and nothing is close.
```

Offer nearest existing names by slug similarity, exactly as Pass 1 does. Most
dangling links are typos or renames; a genuinely missing note is the minority
case and should be stated as such rather than assumed.

### 3. Confirm each fix individually

Per finding, the user can:

- **Retarget** — point at the note that exists
- **Create** — the note genuinely does not exist; hand off to the skill that owns
  that layer (`memex-save` or `memex-ingest` for a source, `memex-ingest` for an
  atom, `memex-glossary` for a term). Never write the stub here
- **Remove** — drop the target. For `cites::`, say plainly that removing it may
  drop the atom to zero grounded sources and re-expose it to the Section 4 orphan
  check — that is the check working, not a new problem
- **Skip** — leave it

Never batch-apply. A dangling `cites::` in particular is evidence of how a claim
was made; deleting the link without deciding what it was *meant* to say loses the
only record that the atom ever claimed grounding.

### 4. Apply

- Edit the field in place, in the note's own `## Sources` or `## Connections`
  section
- Update `updated:` in the frontmatter to today, for any layer that carries it
- Re-run `bash "$VAULT/_meta/lint.sh"` at the end of the pass and confirm the
  `but no such note` lines are gone

---

## Pass 3 — `related::` promotion

`related::` is the documented fallback for "loosely connected, refine later."
Without a pass that actually refines it, every hard call silently becomes
`related::` and the typed vocabulary decays into a single untyped edge.

### 1. Discover

```bash
grep -rn "^related::.*\[\[" "$VAULT/atoms/" "$VAULT/topics/" "$VAULT/sources/"
```

Every populated `related::` is in the backlog; there is no age threshold. The
30-day rule this pass used to apply excluded every link in a young vault and said
nothing about the link itself (roadmap M11). Typing now happens at write time, in
`memex-connect` and `memex-ingest`, so this pass handles what they left.

Before presenting anything, drop every link the user has already chosen to
**Keep**. Keeps change no note; they are recorded only as `kept::` lines in earlier
reconcile entries in `_meta/log.md`:

```bash
grep -h "^kept::" "$VAULT/_meta/log.md"
```

Each line reads `kept:: <note path> -> [[target]]`. A kept link is a decision, not
a backlog item, and re-offering it is exactly the churn this record prevents.

If the backlog is large, ask the user for a scope (a topic, a note, or a count)
rather than presenting all of it.

### 2. Present with a proposed type

For each link, read both notes and propose a specific relation using the
decision tree in `references/vault-schema.md`. Show the reasoning:

```
UNTYPED RELATED: atoms/flash-attention.md
  related:: [[attention-mechanism]]
  Both describe the same operation; flash-attention is an IO-aware
  reimplementation of it, not a separate idea.
  → Proposed: extends:: [[attention-mechanism]]
```

Propose exactly one type. If no typed relation genuinely fits, say so and
recommend **Keep** — `related::` is a legitimate terminal state for a link that
is real but untypeable. Do not force a type to clear the queue.

### 3. Confirm each individually

- **Accept** — replace `related::` with the proposed typed relation
- **Choose** — user names a different type from the vocabulary
- **Keep** — genuinely navigational; leave the note untouched and record a
  `kept::` line in the session log, so the link is never offered again
- **Drop** — the link is not meaningful; remove it

### 4. Apply

- Remove the target from the `related::` line; add it to the typed field's line
  in the same `## Connections` section, creating the line if absent
- If `related::` ends up with no targets, leave the bare `related:: ` field —
  templates ship it empty and Dataview reads an empty field as absent
- Update `updated:` in frontmatter to today — not for **Keep**, which changes no note
- For `challenges::`, `refutes::`, `contradicts::`, `limits::`: the schema
  requires a sentence in the body explaining the tension. Write it, or the
  promotion is not complete

---

## Log the session

Append to `_meta/log.md`:

```markdown
## [YYYY-MM-DD] reconcile | vault
url:: n/a
atoms:: [[Atom A]], [[Atom B]]
skill:: memex-reconcile
kept:: atoms/flash-attention.md -> [[attention-mechanism]]
notes: N dangling part-of fixed; P other dangling targets fixed; M related:: promoted, K kept, J dropped
```

List every note that was modified. Write one `kept::` line per link kept this
session — Pass 3 reads them back, and they are the only record a Keep exists. Do
not log a session where nothing was applied or kept.

---

## What This Skill Does NOT Do

- Does not create topic files — that is `memex-topic-init`
- Does not create or split atoms — that is `memex-refactor`
- Never auto-repairs without explicit user confirmation per item
- Does not touch source connection fields in Pass 1. Pass 2 does, but only to
  repair a target that resolves to nothing — never to add, retype or remove a
  link that works
- Does not reconcile topic membership in either direction; membership is derived
  from `part-of::` and cannot drift

---

## Common Mistakes to Avoid

- Don't propose a typed relation you cannot justify in one sentence — **Keep** is
  a valid outcome and a forced type is worse than an honest `related::`
- Don't treat a dangling `part-of::` as always a typo; a topic may have been
  deliberately deleted, in which case **Remove** is right
- Don't re-surface a link the user chose to **Keep** — read the `kept::` lines
  first, and never skip writing one for a new Keep
- Don't promote a `related::` on a source note into an atom→atom relation; check
  which node types are on each end first
- Don't log entries for sessions where nothing was applied or kept
