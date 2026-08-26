---
name: memex-trust-audit
description: Audit atom confidence against the claim-level evidence rubric, and record human sign-off in verified:. Use when atoms may be over- or under-confident, after major new sources are processed, or monthly. Triggers on: "audit confidence", "check atom trust", "review confidence levels", "trust audit [topic]", "are my atoms overconfident", "which atoms should be upgraded", "sign off on these atoms", "mark this atom verified". Accepts a topic name (scoped) or --vault flag (all atoms).
---

# Karpathy Wiki Trust Audit

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited.

This skill answers two separate questions about an atom, and keeps them separate:

1. **Is `confidence:` justified by the evidence behind it?** Measured against
   `_meta/schema.md` § Confidence Values — independent claims across independent
   sources, never a source count.
2. **Has a human ever checked it?** Recorded in `verified:`. This skill is that
   field's only writer.

It does not judge whether atom bodies are factually correct. Run it after bulk
ingest, after new sources challenge existing claims, or monthly as vault hygiene.

For the full relationship taxonomy, read: `references/vault-schema.md`

---

## Scope

- **Topic-scoped:** provide a topic filename (e.g., `deep-learning`) — audits only atoms declaring `part-of::` for that topic. Best for targeted review.
- **Vault-wide:** use `--vault` — audits all atoms. Use after bulk ingest or monthly.

One scope per session. For multiple topics, run again.

---

## Workflow

### 1. Scope selection

Ask the user: "Which topic should I audit, or use `--vault` for all atoms?"

If a topic name is given:
```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
# Membership is derived — read it off the atoms, not the topic file
grep -rlE "^part-of::.*\[\[<topic>\]\]" "$VAULT/atoms/"
```
Confirm the topic file itself exists under `topics/concepts/`, `topics/research/`, or `topics/projects/`. If no atom declares membership, report that and stop.

If `--vault`:
```bash
find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep"
```

---

### 2. Gather the evidence behind each atom

**The unit is a claim, not a citation and not a source.** Three sub-steps, in
order. Do not skip to the rubric with a citation count in hand — that is the
measure the rubric exists to replace.

#### 2a. Split citations into claims and bare sources

```bash
atom="$VAULT/atoms/<atom>.md"
# Every cites:: target, anchors preserved
grep -E '^cites::' "$atom" | grep -oE '\[\[[^]]+\]\]' | sed 's/^\[\[//; s/\]\]$//'
```

Each target is one of two things:

| Target shape | Means |
|---|---|
| `ext-<slug>#^cNN` | A **claim** — one proposition with a verbatim quote behind it |
| `<slug>` or `<slug>#Section` | A **bare source citation** — the atom rests on a document, not a sentence |

#### 2b. Resolve every claim back to its source, then count distinct sources

A block-anchored citation names an extract, and the extract names the source:

```bash
grep -m1 '^extracted-from::' "$VAULT/extracts/<ext>.md" \
  | grep -oE '\[\[[^]|]+' | tr -d '['
```

Now build the real tally: **distinct backing sources**, and **how many distinct
`^cNN` anchors** each one contributes.

This is where citation-counting goes wrong, and it is worth being explicit about:
three `cites::` lines pointing at `^c01`, `^c07`, and `^c12` of the *same*
extract are three claims from **one** source. That is `low`, not `high`. An atom
can have a dozen citations and one source.

#### 2c. Apply the independence test

Per `_meta/schema.md`, two sources are **not** independent when any of these
holds:

- one `cites::` the other, directly or through a chain in the vault;
- they share an author — compare `authors:`, `channel:`, `tool:`;
- one restates the other: a blog post about a paper, a talk given on a paper,
  vendor docs describing that vendor's own release.

```bash
# Shared-author check across the atom's backing sources
for s in <source-files>; do
  echo "$s: $(grep -m1 -E '^(authors|channel|tool):' "$s")"
done
# Does one cite another?
grep -E '^(cites|rebuts)::' <source-files>
```

**Where independence is unclear, treat the sources as dependent.** Overstating
independence is how `high` stops meaning anything, and `high` is the only value
that changes how anyone acts on a note.

This step is a judgement, not a grep. **Show your work in the report** — name the
sources you merged into one group and why. A collapsed group is the single most
likely place for the audit to be wrong, and it must be visible enough to argue
with.

#### 2d. Infer each independent group's tier

Never store this. It is read off fields the source already carries, so it stays
true as those fields are corrected:

| Tier | Inferred from |
|------|---------------|
| Reviewed | `medium: paper` with a `venue:` |
| Primary | `medium: paper` without a `venue:` (preprint), or `medium: video` of a talk by the work's own authors |
| Curated | `medium: docs` |
| Unreviewed | `medium: web`, and everything else |

"Reviewed or primary" in the rubric means the first two tiers.

---

### 3. Evaluate against the rubric

Compute the **justified** confidence, then compare it to the **declared** one.
Findings come out of that comparison rather than a table of thresholds.

| Justified | Requires |
|-----------|----------|
| `low` | One supporting claim, or several tracing back to one source |
| `medium` | ≥ 2 claims from ≥ 2 independent sources, ≥ 1 reviewed or primary |
| `high` | ≥ 3 claims from ≥ 3 independent sources, ≥ 2 reviewed or primary, **and** no unaddressed `contradicts::` / `refutes::` |

**The cap.** An atom whose citations are all bare — no block anchors, so no
extract stands behind them — falls back to counting independent *sources* by the
same independence test, and **cannot exceed `medium`** however many it has. That
is not a penalty. Nobody has read those sources claim by claim, so the vault
genuinely cannot tell three corroborations from three restatements.

```bash
# Does this atom rest on specific sentences, or on filenames?
grep -cE '^cites::.*\[\[[^]|]+#\^' "$VAULT/atoms/<atom>.md"
```

Then collect the remaining signals, which are about the atom's situation rather
than its evidence:

| Finding | Condition |
|---------|-----------|
| OVERCONFIDENT | declared > justified |
| UPGRADE | declared < justified |
| UNGROUNDED | declared `high`, zero block-anchored citations — the cap, named |
| CONTRADICTED | declared `high` with a populated `contradicts::` / `refutes::` and no prose addressing it |
| STALE | incoming `challenges::` / `refutes::` dated after the atom's `updated:` |
| UNVALIDATED | every cited source is `stage: unread` |
| STALE SOURCES | newest cited source `saved:` more than 18 months ago |
| NEVER VERIFIED | no `verified:` key — feeds step 7, never a confidence change |
| STALE SIGN-OFF | newest `verified.at` earlier than `updated:` — someone signed off on a version that no longer exists |

```bash
# Incoming conflict relations, with the challenging atom's date
grep -rn "challenges::\|refutes::" "$VAULT/atoms/" | grep "\[\[<atom-name>\]\]"
# Existing sign-off history
sed -n '/^verified:/,/^[a-z]/p' "$VAULT/atoms/<atom>.md"
```

An atom can carry several findings. Collect all before presenting any.

**UNGROUNDED has exactly one remedy:** run `memex-deep-extract` mode A on the
atom's cited sources, then mode B to re-cite at claim granularity. That is the
only route to `high` in this vault. Say so with the finding — a finding whose fix
is not named is a complaint.

---

### 4. Source extraction completeness (G13)

For each source with `stage: processed` cited by an atom in scope:

```bash
grep -c "^introduces::" "$source_file"
grep -c "^supports::" "$source_file"
wc -l < "$source_file"
ls "$VAULT/extracts/ext-$(basename "$source_file")" 2>/dev/null
```

Body > 100 lines AND `introduces::` = 0 AND `supports::` < 2 → **UNDER-EXTRACTED**.

A long processed source with **no extract at all** is the clearest case: nobody
has read it claim by claim, so every atom citing it is capped at `medium` by
construction. Remedy: `memex-deep-extract` mode A.

Report under-extracted sources as their own group, never mixed with atom findings.

---

### 5. Present findings

Group by finding type, most actionable first. Every proposal states the tally it
rests on, so the user can check the arithmetic rather than trust it:

```
## Upgrade candidates
  atoms/attention-mechanism.md   confidence: low → medium
  - 4 claims / 3 independent sources / 2 reviewed
  - grouped as dependent: 2026-03-blog-on-vaswani restates 2017-vaswani-attention
  → Proposed: upgrade to medium

## Overconfident atoms
  atoms/scaling-laws.md          confidence: high → low
  - 5 claims, but all from ext-2020-kaplan-scaling — 1 independent source
  → Proposed: downgrade to low

## Ungrounded high-confidence atoms
  atoms/emergent-abilities.md    confidence: high → medium (capped)
  - 4 cites::, none block-anchored; no extract backs any cited source
  → Capped at medium until the evidence is claim-level
  → Run: memex-deep-extract mode A on the cited sources, then mode B

## Contradicted high-confidence atoms
  atoms/chinchilla-optimal.md
  - confidence: high with an unaddressed refutes:: from atoms/overtrained-models.md
  → high requires no unaddressed conflict; proposed: downgrade to medium

## Stale confidence
  atoms/some-other-atom.md
  - challenges:: from atoms/newer-atom.md (2026-01-15, atom updated 2025-08-01)
  → Review whether confidence still holds

## Unvalidated atoms
  atoms/speculative-atom.md
  - all 2 cited sources are stage: unread
  → Flag only — confidence cannot be evaluated until the sources are read

## Stale sources
  atoms/old-atom.md
  - newest cited source saved 2024-07-10 (22 months ago)
  → Consider newer sources; confidence may be outdated

## Under-extracted sources
  sources/paper/2026-01-01-big-survey.md
  - 187 lines, stage: processed, 0 introduces:: / 1 supports::, no extract
  → Run: memex-deep-extract mode A

## Never verified / stale sign-off
  atoms/attention-mechanism.md   — no verified: entry
  atoms/transformer.md           — signed off 2025-11-02, updated 2026-04-18
  → Offered for sign-off in step 7
```

If a scope has no findings, say so plainly and stop.

---

### 6. Confirm each confidence change

One question per proposed transition:

- **Accept** — apply
- **Reject** — leave as-is
- **Defer** — note for later; change nothing

Only upgrades and downgrades need confirmation. UNVALIDATED, STALE SOURCES,
NEVER VERIFIED, and STALE SIGN-OFF are informational and produce no file change
on their own.

For STALE findings, show the challenging atom and ask whether the confidence
still holds.

Apply each accepted transition as:
- `confidence:` → the new value
- `updated:` → today
- nothing else

---

### 7. Sign-off pass — writing `verified:`

**This is the only place in the vault that writes `verified:`.** It records that
a *person* checked a note. Four rules, and the first one is absolute.

**Never write a `verified:` entry on your own judgement.** `human:<id>` asserts
that a named human read the atom and found it accurate. Inferring that from an
audit result, from the user approving a confidence change, or from silence
forges a record about a person. If the user has not said yes to this atom, it
gets no entry.

**Ask separately from `confidence:`.** They are different questions — how much
evidence exists, versus who has looked. Bundled into one prompt, an "accept"
meant for a downgrade silently becomes a sign-off. Run this pass after step 6 has
finished, not interleaved with it.

**Offer sign-off only for atoms actually examined this session** — those that
produced a finding, or that the user asked about directly. Do not walk the whole
scope offering to certify atoms nobody looked at; that manufactures exactly the
false assurance the field exists to prevent.

**Establish the actor id once per session**, then reuse it:

```bash
git config user.email | cut -d@ -f1    # suggest as <id>; confirm before using
```

Confirm the suggestion with the user rather than assuming it. Actor form is
`human:<id>` — see `_meta/schema.md` § Actor strings.

For each accepted sign-off, **append** to the atom's frontmatter:

```yaml
verified:
  - by: human:bcmcpher
    at: 2026-08-25
```

If `verified:` already exists, add an entry to the list; never rewrite or remove
an existing one. If an entry with the same `by:` and the same `at:` is already
there, it is already recorded — skip it rather than duplicating.

**Do not touch `updated:`.** Checking a note is not revising it. Bumping the
timestamp would tell `memex-stale` the atom had been refreshed when it had only
been read, and would clear the atom's own STALE finding — so signing off on an
atom would erase the evidence that someone else disputed it. That is exactly
backwards.

---

### 8. Log the session

Append to `_meta/log.md`:
```markdown
## [YYYY-MM-DD] trust-audit | <scope>
url:: n/a
atoms:: [[Atom A]], [[Atom B]]
skill:: memex-trust-audit
notes: N atoms evaluated; M upgraded, K downgraded, S signed off, P flagged-only
```

List every atom whose file changed — `confidence:` transitions and sign-offs
both.

---

## What This Skill Does NOT Do

- Never silently changes `confidence:` — every transition is user-approved
- **Never writes `verified:` without an explicit human yes for that specific atom**
- Never rewrites or deletes an existing `verified:` entry — the field is append-only
- Never bumps `updated:` for a sign-off
- Does not evaluate factual accuracy of atom content — provenance structure only
- Does not modify source files (read-only on sources during this skill)
- Does not store a rigor score anywhere — tiers are inferred at audit time, every time
- Does not introduce new stage or confidence values beyond the three in schema
- Does not reprocess sources or add connections — that belongs to `memex-connect`

---

## Frequency

- Monthly for active topics
- After processing 5+ new sources in a topic area
- After `memex-deep-extract` mode B — new claim-level citations change the tally
- After `memex-reconcile` (graph must be consistent before evaluating confidence)
- Before running `memex-compose` (export quality depends on trustworthy confidence signals)

---

## Common Mistakes to Avoid

- **Don't count citations.** Three block anchors into one extract are one source. Resolve every anchor through `extracted-from::` before tallying anything
- **Don't let an atom reach `high` on bare citations.** No block anchors means no extract, which means the cap applies no matter how many sources agree
- **Don't assume independence.** Two sources are dependent until shown otherwise; say which ones you merged and why
- Don't treat `UNVALIDATED` as a confidence problem — it's a workflow state. Once the sources are read and processed, run trust-audit again
- Don't downgrade atoms just because sources are old — check whether the claim is foundational (timeless) or empirical (may have been superseded)
- Don't audit an atom that hasn't been through `memex-reconcile` — a disconnected graph produces misleading provenance
- **Don't read a `verified:` entry as agreement with `confidence:`.** They are orthogonal. A signed-off atom can still be overconfident, and a `low` atom a human has confirmed is correctly hedged is a perfectly good note
