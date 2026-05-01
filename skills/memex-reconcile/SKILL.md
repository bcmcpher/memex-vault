---
name: memex-reconcile
description: Detect and repair bidirectional drift between atom part-of:: and topic covers:: fields. Use when running a vault health check, after bulk ingest, or when lint Section 7 surfaces asymmetry warnings. Triggers on: "reconcile my vault", "check graph integrity", "fix bidirectional links", "repair part-of covers mismatch", "sync part-of and covers".
---

# Karpathy Wiki Reconcile

**Vault root:** `/home/bcmcpher/Projects/claude/memex-llm-obsidian-template`

This skill finds and repairs bidirectional drift between atom `part-of::` fields and their corresponding topic `covers::` fields. These two fields are meant to be mirrors: if an atom says `part-of:: [[deep-learning]]`, then `topics/concepts/deep-learning.md` should say `covers:: [[atom-name]]`, and vice versa. Drift accumulates silently during ingest when one side is written but the other is forgotten.

For the full relationship taxonomy, read: `references/vault-schema.md`

---

## When to Run

- After bulk ingest of multiple sources (drift accumulates fastest here)
- When `_meta/lint.sh` Section 7a or 7b surfaces asymmetry WARNs
- Monthly, before running `memex-review` on a topic
- Before running `memex-compose` (composition depends on correct graph structure)

---

## Workflow

### 1. Discover asymmetries

Run two scans:

**Scan A — atoms with part-of:: not reflected in topic covers::**
```bash
VAULT=/home/bcmcpher/Projects/claude/memex-llm-obsidian-template
grep -rn "^part-of::" "$VAULT/atoms/"
```
For each `part-of:: [[Topic]]` found, verify the named topic file has `covers:: [[atom-name]]`. Collect every mismatch.

**Scan B — topics with covers:: not reflected in atom part-of::**
```bash
grep -rn "^covers::" "$VAULT/topics/"
```
For each `[[Atom]]` listed in `covers::`, verify the atom file has `part-of:: [[topic-name]]`. Collect every mismatch.

Extract wikilink targets by stripping `[[` and `]]`; ignore display-text aliases (anything after `|`).

### 2. Group and present mismatches

Present in two groups:

**Group A — atom claims membership, topic doesn't list it**
```
MISMATCH: atoms/transformer-architecture.md
  part-of:: [[deep-learning]]
  BUT topics/concepts/deep-learning.md covers:: does not include [[transformer-architecture]]
  → Proposed fix: add covers:: [[transformer-architecture]] to deep-learning.md
```

**Group B — topic lists atom, atom doesn't claim membership**
```
MISMATCH: topics/concepts/deep-learning.md
  covers:: [[attention-mechanism]]
  BUT atoms/attention-mechanism.md has no part-of:: [[deep-learning]]
  → Proposed fix: add part-of:: [[deep-learning]] to attention-mechanism.md
```

For each mismatch, check both files' `updated:` frontmatter date (or file modification time as fallback) and note which side is newer — the newer side is usually the intended state.

If there are no mismatches, report "Graph is consistent — no part-of/covers drift found." and stop.

### 3. Confirm each fix individually

Present one mismatch at a time. The user can:
- **Accept** — apply the proposed fix
- **Reject** — skip (asymmetry is intentional; e.g., an atom belongs to a sub-topic but the parent topic still lists it transitively)
- **Swap** — fix the opposite side instead (e.g., remove `covers::` from the topic rather than adding `part-of::` to the atom)

Never batch-apply all fixes. Never auto-repair without confirmation.

### 4. Apply accepted fixes

For each accepted fix:
- Add the missing field to the correct file in the `## Connections` section
- Update `updated:` in frontmatter to today's date if the file is an atom
- For topic files: append to the existing `covers::` line or add a new one

### 5. Log the session

Append to `_meta/log.md`:
```markdown
## [YYYY-MM-DD] reconcile | vault
url:: n/a
atoms:: [[Atom A]], [[Atom B]]
skill:: memex-reconcile
notes: N mismatches found, M fixes applied, K skipped
```

List every atom that was modified or whose topic counterpart was modified.

---

## What This Skill Does NOT Do

- Never removes existing links — only adds the missing side
- Never auto-repairs without explicit user confirmation per mismatch
- Does not resolve `related::` into more specific relation types (that belongs to `memex-review`)
- Does not touch source connection fields
- Does not detect or repair other relation field types (only `part-of::` ↔ `covers::`)

---

## Common Mistakes to Avoid

- Don't assume asymmetry is always a mistake — an atom can `part-of` a sub-topic while the grandparent topic still `covers` it; always show both sides and let the user decide
- Don't modify `covers::` on research or project topics without checking whether the atom's `part-of::` is meant to point there specifically
- Don't log entries for sessions where no fixes were applied
