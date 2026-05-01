---
name: memex-conflicts
description: Surface and document unacknowledged conflicts in the vault graph. Use when you want to see all tensions in the knowledge base, after major new sources challenge existing atoms, or before writing a research synthesis. Triggers on: "find conflicts", "what's in tension", "surface contradictions", "conflicts in my vault", "unacknowledged challenges", "show me what disagrees".
---

# Karpathy Wiki Conflicts

**Vault root:** `/home/bcmcpher/Projects/claude/memex-llm-obsidian-template`

This skill follows explicit conflict relation fields already in the graph — it does not infer conflicts from atom content. Its job is to distinguish acknowledged conflicts (tension described, both sides linked) from unacknowledged ones (link present but no explanation), and to help you document the ones that are bare.

Run it before `memex-compose` to ensure tensions are surfaced in exports, and after major rounds of ingest when new sources likely challenged existing claims.

For the conflict relation taxonomy, read: `references/vault-schema.md`

---

## Conflict Relation Fields

The four fields this skill tracks:

| Field | Strength | Notes |
|-------|----------|-------|
| `contradicts::` | Direct logical incompatibility | Strongest; both atoms should have reciprocal links |
| `refutes::` | One atom or source directly counter-evidences another | Asymmetric is acceptable — one side may not yet be updated |
| `challenges::` | Weakens or questions without full contradiction | Common; softer than contradicts |
| `limits::` | Defines boundary conditions where the target breaks down | Not a true conflict but a tension worth surfacing |

---

## Workflow

### 1. Scan for all conflict links

```bash
VAULT=/home/bcmcpher/Projects/claude/memex-llm-obsidian-template
grep -rn "^contradicts::\|^refutes::\|^challenges::\|^limits::" "$VAULT/atoms/"
```

Collect every (source-atom, relation-type, target-atom) triple. This is the raw conflict graph.

### 2. Classify each conflict

For each conflict pair (A → B via relation R):

**Acknowledged** — meets all three conditions:
1. A has R pointing to B
2. B has a reciprocal skeptical relation pointing back to A (any of: `contradicts::`, `challenges::`, `limits::`, `refutes::`)
3. At least one of A or B has prose text in its body describing the tension (not just field lines)

**Unacknowledged** — any condition is unmet:
- Missing reciprocal link only → "one-sided conflict"
- Missing prose in both atoms → "bare conflict link"
- Both missing → "undocumented conflict"

### 3. Identify cross-topic conflicts

For each conflict pair, look up which topic's `covers::` list each atom appears in:
```bash
grep -r "covers::.*\[\[<atom-name>\]\]" "$VAULT/topics/"
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
    Both atoms have reciprocal links and tension descriptions. ✓

## Challenges (challenges::)
  [UNACKNOWLEDGED — one-sided] atoms/atom-e.md → atoms/atom-f.md
    ...
```

Show acknowledged conflicts in a summary count only — they require no action.

### 5. Address unacknowledged conflicts

For each unacknowledged conflict, present options:

**Missing prose:** Offer a draft tension description based on the atom bodies. Format:

> "Draft: [Atom A] claims [X], while [Atom B] argues [Y]. The tension is [Z]. Accept this draft, edit it, or skip?"

If accepted: insert the draft as a new paragraph in the atom body where the conflict field appears (above or below the `## Connections` section — user's choice).

**Missing reciprocal link:** Propose adding the reverse relation to the other atom:
> "Add `challenges:: [[atom-a]]` to atoms/atom-b.md? (Accept / Skip)"

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
