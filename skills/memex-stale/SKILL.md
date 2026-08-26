---
name: memex-stale
description: Surface temporal decay in the vault — sources that have sat unread too long, atoms that haven't been updated in over a year, topics where all atoms are still low-confidence, and sources marked read but never integrated. Use when the user wants to audit what's gone stale, catch neglected captures, or prioritize what to process next. Triggers on: "find stale notes", "what's been sitting unread", "stale vault audit", "decay check", "what have I neglected", "what's overdue for processing", "show me what's been ignored". Read-only — surfaces findings and suggests which skill to run; makes no vault changes.
---

# Karpathy Wiki Stale Audit

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited.

This skill is a read-only decay detector. It finds four categories of staleness and reports them as a prioritized list. It never modifies vault files — it tells you what to act on, and which skill to use.

Run it monthly, before a compose session, or whenever the vault feels like it has grown faster than it's been processed.

---

## Checks

### Check 1 — Long-unread sources (> 90 days)
Sources saved with `stage: unread` where `saved:` is more than 90 days ago.

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"

# Find all unread sources with their saved dates
grep -rl "stage: unread" "$VAULT/sources/" | xargs grep -l "saved:" | while read f; do
  saved=$(grep "^saved:" "$f" | head -1 | awk '{print $2}')
  echo "$saved $f"
done | sort
```

Flag any source where the saved date is > 90 days before today. Report: filename, medium, title, saved date, days elapsed.

### Check 2 — Read but not integrated
Sources with `stage: read` — consumed but never processed into atoms.

```bash
grep -rl "stage: read" "$VAULT/sources/"
```

For each hit, read its title and saved date. These are the highest-value targets: the user already knows the content, they just need to wire it.

### Check 3 — Underconfident topics
Topics where every member atom has `confidence: low`.

```bash
ls "$VAULT/topics/concepts/" "$VAULT/topics/research/"
# Membership is derived — collect each topic's atoms by reverse lookup
grep -rlE "^part-of::.*\[\[<topic>\]\]" "$VAULT/atoms/"
```

For each topic, collect its member atoms, then check the `confidence:` field in each. If all are `confidence: low`, flag the topic as underconfident. A topic with no member atoms is not underconfident — it is empty; skip it.

### Check 4 — Processed sources never deep-extracted

An extract records what a source said claim by claim. A source that is
`stage: processed` but has no extract has been summarized and wired, never read
at that grain — so nothing citing it can be grounded, and no atom resting on it
can reach `confidence: high`.

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
for f in "$VAULT"/sources/*/*.md; do
    grep -q "^stage: processed" "$f" || continue
    [ -f "$VAULT/extracts/ext-$(basename "$f")" ] || echo "$f"
done
```

Rank by how much the vault leans on the source: count the atoms citing it, and
report the most-cited first. A source three atoms depend on and nobody has read
closely is a much better use of an expensive skill than one nothing cites.

Report these; do not run anything. `memex-deep-extract` is the most expensive
skill in the vault and is user-invoked by design.

---

## Output Format

Present findings grouped by check, most actionable first:

```
## Stale Vault Audit — YYYY-MM-DD

### Read but not integrated (Check 2) — N sources
These are highest priority: you've already read them.
| Title | Saved | Days elapsed |
|-------|-------|-------------|
| ...   | ...   | ...         |
→ Run: memex-connect

### Long-unread sources (Check 1) — N sources
| Title | Medium | Saved | Days elapsed |
|-------|--------|-------|-------------|
| ...   | ...    | ...   | ...         |
→ Run: memex-save (to mark as read and optionally build a summary) or memex-connect (to process directly)

### Underconfident topics (Check 3) — N topics
| Topic | Atom count | All confidence: low |
|-------|------------|---------------------|
| ...   | ...        | yes                 |
→ Run: memex-connect (add sources) or memex-trust-audit

### Processed sources never deep-extracted (Check 4) — N sources
| Title | Medium | Atoms citing it |
|-------|--------|-----------------|
| ...   | ...    | ...             |
→ Run: memex-deep-extract mode A (expensive — pick the most-cited first)

---
Total: N findings across 4 checks.
```

If a check finds nothing, say so in one line and move on — don't omit the section.

---

## After the Report

Do not propose changes or apply fixes. End with:

> "No changes made — this is a read-only audit. Use the suggested skills above to act on any findings."

If the user asks to act on a specific finding during this session, describe what skill to invoke and what to say to trigger it — but do not run it inline. Keep this skill scoped to detection only.

---

## What This Skill Does NOT Do

- Does not modify any vault file
- Does not update `stage:` or `confidence:` fields
- Does not write a log entry (read-only)
- Does not track atom age or flag atoms for temporal decay — atom freshness is domain-dependent and left to the user's judgment
- Does not flag sources in `stage: processed` regardless of age — processed is terminal

---

## Common Mistakes to Avoid
- Don't include `.archive/` or `_exports/` in any scan — those folders are not vault nodes
- Don't overwhelm with findings — if Check 1 returns > 20 sources, cap the table at 10 and note the total count
