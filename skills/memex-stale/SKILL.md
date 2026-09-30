---
name: memex-stale
description: Surface neglect in the vault — sources marked read but never integrated, topics where all atoms are still low-confidence, topics never populated, and processed sources never read claim by claim. Use when the user wants to audit what's gone stale, catch neglected captures, or prioritize what to process next. Triggers on: "find stale notes", "stale vault audit", "decay check", "what have I neglected", "what's overdue for processing", "show me what's been ignored". Read-only — surfaces findings and suggests which skill to run; makes no vault changes.
---

# Karpathy Wiki Stale Audit

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited. **Confirm it resolved to a vault before writing
anything:** `[ -f "$VAULT/_meta/schema.md" ]`. If that fails, stop and tell the
user — a stale `MEMEX_VAULT`, or this skill invoked from an unrelated repository,
otherwise writes `sources/`, `atoms/` and `_meta/log.md` into *that* repository,
and the first sign is `git status` (roadmap R14).

This skill is a read-only decay detector. It finds four categories of staleness and reports them as a prioritized list. It never modifies vault files — it tells you what to act on, and which skill to use.

Run it monthly, before a compose session, or whenever the vault feels like it has grown faster than it's been processed.

---

## Checks

### Check 1 — retired

"Long-unread sources (> 90 days)" was removed in rc.2 (roadmap M11a). How long a
source has sat unread measures the vault's age, not the source, and on the first
real vault it found nothing. The remaining checks keep their numbers.

### Check 2 — Read but not integrated
Sources with `stage: read` that have sat there for more than **14 days**. The user
consumed them but never processed them into atoms. The user can override the
threshold for a run ("stale audit, 30 days").

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
today=$(date +%s)
grep -rl --include='*.md' "^stage: read$" "$VAULT/sources/" | while IFS= read -r f; do
    saved=$(grep -m1 '^saved:' "$f" | sed 's/^saved:[[:space:]]*//')
    days=$(( (today - $(date -d "$saved" +%s)) / 86400 ))
    [ "$days" -gt 14 ] && printf '%s\t%s\t%s\n' "$days" "$saved" "$f"
done | sort -rn
```

Days elapsed counts from `saved:`, the only date a source carries. The threshold
applies to that column; the column is not just for display. A source saved and read
this morning is a work item, not neglect. In trial 2 the ungated check reported two
sources at 0 days as decay (T2-31). `memex-tend`'s post-ingest pass already sends new
sources to `memex-connect`, so this check only reports the ones that have been left.

Check 1 was retired because elapsed time since saving says nothing about a source
nobody has acted on. Here elapsed time is measured against a state someone set
deliberately, so it does mean something.

For each hit, read its title. List the oldest first. These are the highest-value
targets: the user already knows the content and only needs to wire it.

### Check 3 — Underconfident topics
Topics where every member atom has `confidence: low`.

```bash
ls "$VAULT/topics/concepts/" "$VAULT/topics/research/"
# Membership is derived — collect each topic's atoms by reverse lookup
grep -rlE "^part-of::.*\[\[<topic>\]\]" "$VAULT/atoms/"
```

For each topic, collect its member atoms, then check the `confidence:` field in each. If all are `confidence: low`, flag the topic as underconfident. A topic with no member atoms is not underconfident. It is empty, so skip it here; Check 5 reports it.

### Check 4 — Processed sources never deep-extracted

An extract records what a source said claim by claim. A source that is
`stage: processed` but has no extract has been summarized and wired, never read
at that grain — so nothing citing it can be grounded, and no atom resting on it
can reach `confidence: high`.

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
for f in "$VAULT"/sources/*/*.md; do
    grep -q "^stage: processed" "$f" || continue
    [ -f "$VAULT/extracts/ext-$(basename "$f")" ] && continue
    if grep -q "^medium: code" "$f"; then echo "code	$f"; else echo "prose	$f"; fi
done
```

Rank by how much the vault leans on the source: count the atoms citing it, and
report the most-cited first. A source three atoms depend on and nobody has read
closely is a much better use of an expensive skill than one nothing cites.

Report these; do not run anything. `memex-deep-extract` is the most expensive
skill in the vault and is user-invoked by design.

**Report `medium: code` sources apart, with no recommendation.** `memex-deep-extract`
assumes prose; pointed at a repository it would pull out claims about control flow
and I/O plumbing. Extraction from code is not designed yet (roadmap R3, was M8), so
recommending it sends the user into an operation that does not exist. List them
under their own heading as having *no extraction path yet*. The count is still worth
knowing: no atom resting only on them can reach `confidence: high`.

### Check 5 — Empty topics

Leaf concept maps with no live member atoms: created, then never filled. This is
the clearest kind of neglect this skill looks for. In trial 2, `parcellation` was
seeded as a leaf, had zero members for the whole trial, and nothing reported it
(T2-32).

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
for t in "$VAULT"/topics/concepts/*.md; do
    name=$(basename "$t" .md)
    # A concept map with sub-topics has already been split; it is not a leaf
    grep -rqE "^part-of::.*\[\[${name}\]\]" "$VAULT/topics/concepts" --include='*.md' && continue
    members=$(grep -rlE "^part-of::.*\[\[${name}\]\]" "$VAULT/atoms" --include='*.md')
    echo "$name	$(grep -m1 '^created:' "$t")	$members"
done
```

A member is **live** unless it is retired, meaning some atom names it in
`supersedes::` (`$VAULT/_meta/schema.md` § Retirement). A split's stub keeps its
`part-of::`, so drop retired members before counting. Otherwise a leaf whose only
atom was split away looks populated.

This is the same rule as lint section 6d's lower bound, which warns *"leaf concept
map with no live member atoms"*. Lint holds that warning until the vault has 10
live atoms, so that a freshly seeded scaffold does not warn on every leaf. Use the
same gate here: below 10 live atoms, report the count in one line and do not list
the topics.

Report each empty topic with its `created:` date. Route it to `memex-connect`,
which wires the sources that motivated the leaf into atoms. The remedy is
different from Check 3's `memex-trust-audit`, because there is nothing to audit yet.

---

## Output Format

Present findings grouped by check, most actionable first:

```
## Stale Vault Audit — YYYY-MM-DD

### Read but not integrated (Check 2) — N sources, read > 14 days
These are highest priority: you've already read them. Oldest first.
| Title | Saved | Days elapsed |
|-------|-------|-------------|
| ...   | ...   | ...         |
→ Run: memex-connect

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

#### Code sources — no extraction path yet — N sources
| Title | Atoms citing it |
|-------|-----------------|
| ...   | ...             |
Listed, not routed: extraction from code is undesigned (roadmap R3, was M8).

### Empty topics (Check 5) — N topics
| Topic | Created | Live member atoms |
|-------|---------|-------------------|
| ...   | ...     | 0                 |
→ Run: memex-connect (wire the sources that motivated the leaf)

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
- Don't overwhelm with findings — if a check returns > 20 items, cap its table at 10 and note the total count
