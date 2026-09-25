---
name: memex-reconcile
description: Repair dangling link targets — a part-of:: naming no topic, or any relation field naming a note that does not exist — and work the backlog of untyped related:: links, promoting each to a typed relation where one genuinely fits. Use when running a vault health check, after bulk ingest, or when lint Section 7a or 7h surfaces dangling-link warnings or Section 7j surfaces untyped related:: links. Triggers on: "reconcile my vault", "check graph integrity", "fix dangling links", "part-of points nowhere", "cites points nowhere", "promote related links", "retype my related links".
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

1. **Dangling `part-of::`** — an atom names a topic file that does not exist, or
   names an atom (`part-of::` is topic-only).
2. **Dangling everything else** — any other relation field naming a note that
   does not exist.
3. **Untyped `related::`** — a fallback link, worked as a backlog and resolved
   into a precise relation where one genuinely fits.

For the relationship taxonomy and field definitions, read `$VAULT/_meta/schema.md` § Relationship Types.

> **Topic membership is derived.** Atoms declare `part-of::`; topics discover
> their atoms by Dataview query. There is no `covers::` field and no bidirectional
> drift to reconcile — that was retired in roadmap Phase 1. A query cannot fall
> out of step with its source. What *can* break is a `part-of::` that points at
> nothing, which is Pass 1.

---

## When to Run

- After bulk ingest of multiple sources
- When `_meta/lint.sh` Section 7a surfaces `part-of::` WARNs, or Section 7h
  surfaces `but no such note` WARNs
- When Section 7j warns `untyped related:: link(s) and no typed atom relation` —
  Pass 3's backlog. 7j names only atoms with no typed relation at all, so the
  backlog Pass 3 finds is larger; 7j is the signal that it is worth running
- When the user asks to work the `related::` backlog
- Before running `memex-compose` (composition depends on correct membership)

---

## Pass 1 — Dangling `part-of::`

### 1. Discover

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
bash "$VAULT/_meta/lint.sh" 2>/dev/null | grep -E "part-of:: \[\[.*(but no matching topic file found|names an atom)"
```

Read the findings from Section 7a, as Pass 2 reads 7h, rather than grepping
`part-of::` lines: lint skips fenced code, aliases and frontmatter. rc.2's grep
here matched a documentation example inside a fence in `getting-started.md`, and
it resolved only because that example happened to name a real topic; the lines
beside it did not (T2-27).

Both sides carry `part-of::`: an atom names its topic, and a concept map names its
parent. A dangling parent is worse than a dangling atom — it detaches the whole
sub-tree from its root (`$VAULT/_meta/schema.md` § Topic Hierarchy).

7a reports two kinds:

- **`but no matching topic file found`** — the target is nothing. The atom believes
  it belongs to a topic; no topic will ever surface it.
- **`names an atom`** — the target exists but is an atom. `part-of::` is
  membership in a topic, never composition: an atom that is a component of
  another is `extends::` or `uses::` (§ Choosing Between Structural Relations).
  rc.2's Pass 3 could propose this form and Pass 1 then offered to delete it
  (T2-25).

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
not guess silently. For a `names an atom` finding, propose the structural type
the tree gives instead, and say whether the atom has another `part-of::` naming a
real topic.

If there are none, report "No dangling part-of:: links found." and move to Pass 2.

### 3. Confirm each fix individually

Present one at a time. The user can:

- **Retarget** — point `part-of::` at an existing topic
- **Retype** — `names an atom` only: the line becomes `extends::` or `uses::`
  naming the same atom
- **Create** — the topic genuinely does not exist yet; hand off to
  `memex-topic-init` rather than writing a stub here
- **Remove** — drop the `part-of::` entirely; the atom belongs to no topic
- **Skip** — leave it

Never batch-apply. Never auto-repair without confirmation.

### 4. Apply

Through candidates (§ Candidate Gating):

- A replace of the exact `part-of::` line — its new form, or the bare
  `part-of:: ` for **Remove**. A **Retype** is that replace plus filling the
  typed field's line
- A replace of the note's `updated:` line with today's date, where it carries one

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

- A replace candidate of the exact line holding the field, in the note's own
  `## Sources` or `## Connections` section (§ Candidate Gating)
- A replace of `updated:` with today, for any layer that carries it
- Re-run `bash "$VAULT/_meta/lint.sh"` at the end of the pass and confirm the
  `but no such note` lines are gone

---

## Pass 3 — `related::` promotion

`related::` is the documented fallback for "loosely connected, refine later."
Without a pass that actually refines it, every hard call silently becomes
`related::` and the typed vocabulary decays into a single untyped edge.

### 1. Discover

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
tmp=$(mktemp -d)

# Retired atoms: named by some atom's supersedes:: (schema.md § Retirement)
grep -h '^supersedes::' "$VAULT"/atoms/*.md 2>/dev/null \
    | grep -oE '\[\[[^]|#]+' | sed 's/^\[\[//' | sort -u > "$tmp/retired"

# One row per populated related:: target (note path, target), outside
# frontmatter and code fences
for f in "$VAULT"/atoms/*.md "$VAULT"/topics/*/*.md "$VAULT"/sources/*/*.md; do
    [ -f "$f" ] || continue
    grep -qxF "$(basename "$f" .md)" "$tmp/retired" && continue
    awk '
        FNR == 1 && /^---$/ { fm = 1; next }
        fm && /^---$/       { fm = 0; next }
        fm                  { next }
        /^```/              { fence = !fence; next }
        !fence && /^related::/ { print }' "$f" \
      | grep -oE '\[\[[^]|#]+' \
      | while read -r t; do printf '%s\t%s\n' "${f#"$VAULT"/}" "${t#??}"; done
done > "$tmp/backlog"

# Drop Keeps
grep -h '^kept::' "$VAULT/_meta/log.md" 2>/dev/null \
    | sed -E 's/^kept::[[:space:]]*(.*[^[:space:]])[[:space:]]*->[[:space:]]*\[\[([^]|#]+).*/\1\t\2/' > "$tmp/kept"
grep -vxFf "$tmp/kept" "$tmp/backlog" > "$tmp/open"

# Mark reciprocal pairs and retired targets
while IFS=$'\t' read -r path t; do
    printf '%s\t%s\n' "$(basename "$path" .md)" "$t"
done < "$tmp/open" > "$tmp/edges"
while IFS=$'\t' read -r path t; do
    kind=single; grep -qxF "$t"$'\t'"$(basename "$path" .md)" "$tmp/edges" && kind=pair
    flag=-;      grep -qxF "$t" "$tmp/retired" && flag=retired-target
    printf '%s\t%s\t%s\t%s\n' "$kind" "$flag" "$path" "$t"
done < "$tmp/open"
rm -rf "$tmp"
```

Each row is `pair|single`, a `retired-target` flag, the holding note, and the
target. Every populated `related::` is in the backlog; there is no age threshold.
The 30-day rule this pass used to apply excluded every link in a young vault and
said nothing about the link itself (roadmap M11). Typing now happens at write
time, in `memex-connect` and `memex-ingest`, so this pass handles what they left.

Three things this discovery does that rc.2's one-line grep did not:

- **Fences and frontmatter are skipped**, with the same toggle lint uses. Pass 2
  reads lint for exactly this reason; Pass 3 has no lint section that lists every
  link, so it carries the filter itself (T2-27).
- **Retired atoms are skipped as holders.** A retirement stub carries no relations
  by design; an older-shaped one that still holds `related::` describes a concept
  that no longer exists, and promoting its links types a tombstone (T2-26). A row
  whose *target* is retired is kept and flagged: the useful fix is usually to
  retarget it to the successor, the atom whose `supersedes::` names the target.
- **Reciprocal links are marked `pair`.** When A holds `related:: [[B]]` and B holds
  `related:: [[A]]`, the two rows are one item with one decision (step 3). In trial
  2, 21 of 44 linked pairs were reciprocal; presented separately, promoting both
  writes two directional edges asserting inverse things, and promoting one leaves
  the other re-offered forever.

**Keeps are dropped before anything is shown.** Keeps change no note; they are
recorded only as `kept:: <note path> -> [[target]]` lines in earlier reconcile
entries in `_meta/log.md`, which the `grep -vxFf` above reads. A kept link is a
decision, not a backlog item, and re-offering it is exactly the churn this record
prevents.

If the backlog is large, ask the user for a scope (a topic, a note, or a count)
rather than presenting all of it.

### 2. Present with a proposed type

For each link, read both notes and propose a specific relation using the
decision trees in `$VAULT/_meta/schema.md` (§ Choosing Between Structural Relations,
§ Choosing Between Skeptical Relations). Show the reasoning:

```
UNTYPED RELATED: atoms/flash-attention.md
  related:: [[attention-mechanism]]
  Both describe the same operation; flash-attention is an IO-aware
  reimplementation of it, not a separate idea.
  → Proposed: extends:: [[attention-mechanism]]
```

Propose exactly one type **and the note it belongs on**. The relation that fits
often runs the other way: of 19 links kept in trial 2, every one had a typed
relation that fit from the target, not from the note holding the `related::` —
`atoms/tractography.md related:: [[false-positive-streamlines]]` is
`false-positive-streamlines limits:: [[tractography]]` (T2-26). Test both
directions before recommending **Keep**.

```
UNTYPED RELATED (pair): atoms/diffusion-mri.md <-> atoms/tractography.md
  Tractography reconstructs pathways from diffusion MRI; it cannot be
  stated without it.
  → Proposed: tractography uses:: [[diffusion-mri]]  (on the target: Reverse)
  Both related:: lines are removed.
```

Never propose `part-of::` here: it is topic-only, and an atom target makes it a
7a warning (T2-25). `contrasts-with::` is the one symmetric field — a reciprocal
pair is one relation, written on either note or both (`$VAULT/_meta/schema.md`
§ Relationship Types).

If no typed relation genuinely fits in either direction, say so and
recommend **Keep** — `related::` is a legitimate terminal state for a link that
is real but untypeable. Do not force a type to clear the queue.

### 3. Confirm each individually

- **Accept** — write the proposed typed relation, on the note proposed
- **Choose** — user names a different type from the vocabulary
- **Reverse** — write the typed relation on the *target*, naming the holder, and
  remove the `related::` from the holder
- **Keep** — genuinely navigational; leave the note untouched and record a
  `kept::` line in the session log, so the link is never offered again
- **Drop** — the link is not meaningful; remove it

For a `pair`, one answer covers both rows: Accept, Choose or Reverse writes the one
typed relation and removes **both** `related::` targets; Keep records two `kept::`
lines; Drop removes both.

### 4. Apply

Every line below is a candidate (§ Candidate Gating):

- The holder's `related::` line, with the target removed — a replace of the exact
  line. For a `pair`, the target's `related::` line too
- The typed field's line on whichever note takes the relation — a replace of that
  line (the shipped-empty `uses:: ` included) with the target added, or an append
  to `## Connections` when the note has no such line
- If `related::` ends up with no targets, leave the bare `related:: ` field —
  templates ship it empty and Dataview reads an empty field as absent
- Update `updated:` to today on each note changed, as a replace of its current
  `updated:` line — not for **Keep**, which changes no note
- For `challenges::`, `refutes::`, `contradicts::`, `limits::`: the schema
  requires a sentence in the body explaining the tension. Write it, as an append
  candidate on the note taking the relation, or the promotion is not complete

---

## Candidate Gating

Every edit this skill makes is a candidate in `_meta/candidates/` before it
changes anything (`$VAULT/_meta/schema.md` § Candidate Lifecycle). rc.2 wrote
reconcile's edits directly, with no candidate at all (T2-20). Use one session ID,
`YYYY-MM-DD-HHMM`, from the start of the invocation.

Nearly every edit here is a **replace**: a relation line re-pointed, a target
removed, a shipped-empty field filled, `updated:` moved. The replace form matches
the exact line, so an edit made since discovery stops the write instead of
being guessed at:
```yaml
---
proposed: YYYY-MM-DD HH:MM
skill: memex-reconcile
action: modify
target: atoms/tractography.md
section: "## Connections"
change: replace
replaces: "uses:: "
session: YYYY-MM-DD-HHMM
stage: pending
---

uses:: [[diffusion-mri]]
```
Adding a line a note does not carry, or the body sentence an epistemic relation
needs, is an append (`change: append`, `section:`).

Write the candidates for one item, confirm, then write → **assert** → delete
candidate, item by item. The assert re-reads the target: the new line is present
and the `replaces:` line is gone; an append's lines are under their section. On a
miss, stop, keep the candidate, and leave that item out of the log — an edit tool
can report success on a write that did not happen (trial 1, finding 13).

---

## Log the session

Last, after every assert has passed, append to `_meta/log.md`:

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
- Don't recommend **Keep** until the relation has been tested in both directions
  — **Reverse** exists because the fitting type often sits on the target
- Don't present a reciprocal pair as two items, or promote a `related::` held by
  a retired atom
- Don't re-surface a link the user chose to **Keep** — read the `kept::` lines
  first, and never skip writing one for a new Keep
- Don't promote a `related::` on a source note into an atom→atom relation; check
  which node types are on each end first
- Don't log entries for sessions where nothing was applied or kept
