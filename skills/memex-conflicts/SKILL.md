---
name: memex-conflicts
description: Surface and document unacknowledged conflicts in the vault graph. Use when you want to see all tensions in the knowledge base, after major new sources challenge existing atoms, or before writing a research synthesis. Triggers on: "find conflicts", "what's in tension", "surface contradictions", "conflicts in my vault", "unacknowledged challenges", "show me what disagrees".
---

# Karpathy Wiki Conflicts

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited. **Confirm it resolved to a vault before writing
anything:** `[ -f "$VAULT/_meta/schema.md" ]`. If that fails, stop and tell the
user — a stale `MEMEX_VAULT`, or this skill invoked from an unrelated repository,
otherwise writes `sources/`, `atoms/` and `_meta/log.md` into *that* repository,
and the first sign is `git status` (roadmap R14).

This skill follows explicit conflict relation fields already in the graph — it does not infer conflicts from atom content. Its job is to distinguish acknowledged conflicts (tension described, both sides linked) from unacknowledged ones (link present but no explanation), and to help you document the ones that are bare.

Run it before `memex-compose` to ensure tensions are surfaced in exports, and after major rounds of ingest when new sources likely challenged existing claims.

For the conflict relation taxonomy, read: `references/vault-schema.md`

---

## Conflict Relation Fields

The four fields this skill tracks:

| Field | Strength | Notes |
|-------|----------|-------|
| `contradicts::` | Direct logical incompatibility | Strongest, and symmetric — the only field that needs a reciprocal link to count as acknowledged |
| `refutes::` | One atom or source directly counter-evidences another | Asymmetric is acceptable — one side may not yet be updated |
| `challenges::` | Weakens or questions without full contradiction | Common; softer than contradicts. Asymmetric is acceptable |
| `limits::` | Defines boundary conditions where the target breaks down | Directional by construction — `B limits:: A` asserts something different, and usually false. Never needs a reciprocal |

---

## Workflow

### 1. Scan for all conflict links

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
grep -rn "^contradicts::\|^refutes::\|^challenges::\|^limits::" "$VAULT/atoms/"
```

Collect every (source-atom, relation-type, target-atom) triple. This is the raw conflict graph.

### 2. Classify each conflict

For each conflict pair (A → B via relation R):

**Acknowledged** — meets both conditions:
1. At least one of A or B has prose text in its body describing the tension (not just field lines)
2. **For `contradicts::` only:** B has a reciprocal `contradicts::` pointing back to A

Reciprocity is required only where the relation is symmetric. `limits::` means "A defines boundary conditions where B breaks down" — directional by construction, so demanding `B limits:: A` is a category error. `challenges::` and `refutes::` are accepted asymmetric: one side may not yet be updated, and that is not a failure to acknowledge. The old rule required a reciprocal on all four fields and classified 13 of 13 pairs on the first real vault as unacknowledged, 11 of them `limits::` (roadmap M14).

**Unacknowledged** — any condition is unmet:
- `contradicts::` missing only its reciprocal → "one-sided contradiction"
- Missing prose in both atoms → "bare conflict link"
- Both missing (`contradicts::` only) → "undocumented conflict"

### 3. Identify cross-topic conflicts

For each conflict pair, read each atom's own `part-of::` — membership is declared
there, not listed on the topic:
```bash
grep -h "^part-of::" "$VAULT/atoms/<atom-name>.md"
```
Flag pairs where the two atoms belong to different topics — these cross-topic conflicts are especially worth documenting since they won't appear in a single-topic review.

### 4. Present findings

Group by severity, most actionable first:

```
## Direct contradictions (contradicts::)
  [UNACKNOWLEDGED — bare] atoms/atom-a.md ↔ atoms/atom-b.md
    A: "Attention is all you need"
    B: "Attention mechanisms are insufficient for long-range dependencies"
    Missing: explanatory prose in both atoms; B has no reciprocal link back to A
    Cross-topic: A is in [[deep-learning]], B is in [[transformer-architecture]]

  [ACKNOWLEDGED] atoms/atom-c.md ↔ atoms/atom-d.md
    Reciprocal `contradicts::` on both sides, and the tension is described. ✓

## Challenges (challenges::)
  [UNACKNOWLEDGED — bare] atoms/atom-e.md → atoms/atom-f.md
    ...
```

Show acknowledged conflicts in a summary count only — they require no action.

### 5. Address unacknowledged conflicts

For each unacknowledged conflict, present options:

**Missing prose:** Offer a draft tension description based on the atom bodies. Format:

> "Draft: [Atom A] claims [X], while [Atom B] argues [Y]. The tension is [Z]. Accept this draft, edit it, or skip?"

If accepted: insert the draft as a new paragraph in the atom body where the conflict field appears (above or below the `## Connections` section — user's choice).

**Missing reciprocal `contradicts::`:** Propose adding the reverse relation to the other atom:
> "Add `contradicts:: [[atom-a]]` to atoms/atom-b.md? (Accept / Skip)"

Never propose a reciprocal for `limits::`, `challenges::` or `refutes::` — see step 2.

Only add the missing side — never modify or remove existing links.

### 6. Apply accepted changes

Write only what the user accepted:
- Prose additions go into the atom body — either in the `## Detail` section or as a new `## Tensions` section if one doesn't exist
- Reciprocal links go into the appropriate atom's `## Connections` section
- Update `updated:` in frontmatter for any modified atom

### 7. Session summary

Report:
- N total conflict pairs found
- M acknowledged (no action needed)
- K unacknowledged (P documented this session, Q skipped)
- R cross-topic tensions (note how many were addressed)

No log entry unless at least one atom was modified; if so, append to `_meta/log.md`:
```markdown
## [YYYY-MM-DD] conflicts | vault
url:: n/a
atoms:: [[Atom A]], [[Atom B]]
skill:: memex-conflicts
notes: N conflict pairs found; M documented this session
```

---

## What This Skill Does NOT Do

- Does not infer conflicts from atom content — only follows explicit relation fields already in the graph
- Does not modify existing relation fields — only adds missing reciprocal links and prose
- Does not create new atoms or modify topic maps
- Does not evaluate whether a conflict is real or significant — only documents what is already asserted

---

## Common Mistakes to Avoid

- Don't treat `limits::` as a conflict requiring full contradiction prose — a sentence describing the boundary condition is enough
- Don't add reciprocal `contradicts::` links automatically — only if the user confirms the relationship is genuinely bidirectional
- Don't flag acknowledged conflicts as needing work — they're done; report them as a count only
- Don't generate tension descriptions for `limits::` pairs without reading both atom bodies — the boundary condition is usually specific
