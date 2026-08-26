---
name: memex-reconcile
description: Repair dangling part-of:: links and promote stale related:: links to typed relations. Use when running a vault health check, after bulk ingest, or when lint Section 7a surfaces orphan part-of warnings. Triggers on: "reconcile my vault", "check graph integrity", "fix dangling links", "part-of points nowhere", "promote related links", "retype my related links".
---

# Karpathy Wiki Reconcile

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited.

This skill runs two repair passes over the graph:

1. **Dangling `part-of::`** — an atom names a topic file that does not exist.
2. **Stale `related::`** — a fallback link that has sat untyped long enough to be
   worth resolving into a precise relation.

For the full relationship taxonomy, read: `references/vault-schema.md`

> **Topic membership is derived.** Atoms declare `part-of::`; topics discover
> their atoms by Dataview query. There is no `covers::` field and no bidirectional
> drift to reconcile — that was retired in roadmap Phase 1. A query cannot fall
> out of step with its source. What *can* break is a `part-of::` that points at
> nothing, which is Pass 1.

---

## When to Run

- After bulk ingest of multiple sources
- When `_meta/lint.sh` Section 7a surfaces orphan `part-of::` WARNs
- Monthly, for the `related::` promotion pass
- Before running `memex-compose` (composition depends on correct membership)

---

## Pass 1 — Dangling `part-of::`

### 1. Discover

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
grep -rn "^part-of::" "$VAULT/atoms/"
```

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

## Pass 2 — `related::` promotion

`related::` is the documented fallback for "loosely connected, refine later."
Without a pass that actually refines it, every hard call silently becomes
`related::` and the typed vocabulary decays into a single untyped edge.

### 1. Discover

```bash
grep -rn "^related::.*\[\[" "$VAULT/atoms/" "$VAULT/topics/" "$VAULT/sources/"
```

A link is **stale** when the note's `updated:` frontmatter (falling back to
`created:`, then file mtime) is more than 30 days old. A `related::` written last
week is still legitimately provisional; one written six months ago is a decision
nobody came back to.

### 2. Present with a proposed type

For each stale link, read both notes and propose a specific relation using the
decision tree in `references/vault-schema.md`. Show the reasoning:

```
STALE RELATED: atoms/flash-attention.md (updated 2026-03-02, 176 days)
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
- **Keep** — genuinely navigational; leave as `related::` and touch `updated:` so
  it does not resurface next month
- **Drop** — the link is not meaningful; remove it

### 4. Apply

- Remove the target from the `related::` line; add it to the typed field's line
  in the same `## Connections` section, creating the line if absent
- If `related::` ends up with no targets, leave the bare `related:: ` field —
  templates ship it empty and Dataview reads an empty field as absent
- Update `updated:` in frontmatter to today
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
notes: N dangling part-of fixed; M related:: promoted, K kept, J dropped
```

List every note that was modified. Do not log a session where nothing was applied.

---

## What This Skill Does NOT Do

- Does not create topic files — that is `memex-topic-init`
- Does not create or split atoms — that is `memex-refactor`
- Never auto-repairs without explicit user confirmation per item
- Does not touch source connection fields in Pass 1
- Does not reconcile topic membership in either direction; membership is derived
  from `part-of::` and cannot drift

---

## Common Mistakes to Avoid

- Don't propose a typed relation you cannot justify in one sentence — **Keep** is
  a valid outcome and a forced type is worse than an honest `related::`
- Don't treat a dangling `part-of::` as always a typo; a topic may have been
  deliberately deleted, in which case **Remove** is right
- Don't re-surface a link the user chose to **Keep** last month — touching
  `updated:` is what prevents that, so do not skip it
- Don't promote a `related::` on a source note into an atom→atom relation; check
  which node types are on each end first
- Don't log entries for sessions where no fixes were applied
