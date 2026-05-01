---
name: memex-trust-audit
description: Audit and update atom confidence levels based on provenance structure. Use when atoms may be over- or under-confident, after major new sources are processed, or monthly. Triggers on: "audit confidence", "check atom trust", "review confidence levels", "trust audit [topic]", "are my atoms overconfident", "which atoms should be upgraded". Accepts a topic name (scoped) or --vault flag (all atoms).
---

# Karpathy Wiki Trust Audit

**Vault root:** `/home/bcmcpher/Projects/claude/memex-vault`

This skill audits the provenance structure behind atom confidence levels. It does not judge whether atom bodies are factually correct — only whether the `confidence:` field is justified by the sources backing it. Run it after bulk ingest, after new sources challenge existing claims, or monthly as part of vault hygiene.

For the full relationship taxonomy, read: `references/vault-schema.md`

---

## Scope

- **Topic-scoped:** provide a topic filename (e.g., `deep-learning`) — audits only atoms in that topic's `covers::` list. Best for targeted review.
- **Vault-wide:** use `--vault` — audits all atoms. Use after bulk ingest or monthly.

One scope per session. For multiple topics, run again.

---

## Workflow

### 1. Scope selection

Ask the user: "Which topic should I audit, or use `--vault` for all atoms?"

If a topic name is given:
```bash
VAULT=/home/bcmcpher/Projects/claude/memex-vault
grep "^covers::" "$VAULT/topics/concepts/<topic>.md"
# Also check topics/research/ and topics/projects/ if not found in concepts/
```
Collect the `covers::` atom list. If the topic has no atoms, report that and stop.

If `--vault`:
```bash
find "$VAULT/atoms" -name "*.md" ! -name ".gitkeep"
```

### 2. Per-atom evaluation

For each atom, collect its metadata:
- `confidence:` value from frontmatter
- All `cites::` targets (resolve to source files; read each source's `status:` and `saved:` fields)
- Incoming `challenges::` and `refutes::` relations from other atoms:
  ```bash
  grep -rn "challenges::\|refutes::" "$VAULT/atoms/" | grep "\[\[<atom-name>\]\]"
  ```
- The atom's own `updated:` date

Apply these six checks per atom:

| Check | Condition | Finding label |
|-------|-----------|---------------|
| Overconfident (high) | `confidence: high` AND `cites::` count < 3 | OVERCONFIDENT |
| Overconfident (medium) | `confidence: medium` AND only 1 cited source | OVERCONFIDENT |
| Upgrade candidate | `confidence: low` AND 2+ cited sources with `status: processed` | UPGRADE |
| Stale confidence | Incoming `challenges::` or `refutes::` relation dated after atom's `updated:` | STALE |
| Unvalidated | All `cites::` sources are `status: unread` | UNVALIDATED |
| Stale sources | Newest cited source `saved:` date > 18 months ago | STALE SOURCES |

An atom can have multiple findings. Collect all before presenting.

### 3. Source extraction completeness (G13)

For each source with `status: processed` that is cited by an atom in scope, check:
```bash
grep -c "^introduces::" "$source_file"
grep -c "^supports::" "$source_file"
wc -l < "$source_file"
```
If body > 100 lines AND `introduces::` count = 0 AND `supports::` count < 2 → flag as **UNDER-EXTRACTED**: "long processed source with few atom connections — may have more concepts worth extracting."

Report under-extracted sources as a separate group, not mixed with atom findings.

### 4. Present findings

Group atoms by finding type, most actionable first:

```
## Upgrade candidates (confidence: low → medium or higher)
  atoms/attention-mechanism.md
  - 3 processed sources support this atom
  → Proposed: upgrade confidence: low → medium

## Overconfident atoms
  atoms/some-atom.md
  - confidence: high but only 1 cited source
  → Proposed: downgrade confidence: high → medium

## Stale confidence (challenged or refuted after last update)
  atoms/some-other-atom.md
  - challenges:: from atoms/newer-atom.md (dated 2026-01-15, atom updated 2025-08-01)
  → Review whether confidence still holds; proposed: downgrade to medium or leave

## Unvalidated atoms
  atoms/speculative-atom.md
  - all 2 cited sources are status: unread
  → No proposed change — flag only; confidence cannot be evaluated until sources are read

## Stale sources
  atoms/old-atom.md
  - newest cited source saved 2024-07-10 (22 months ago)
  → Consider finding newer sources; confidence may be outdated

## Under-extracted sources
  sources/paper/2026-01-01-big-survey.md
  - 187 lines, status: processed, 0 introduces:: 1 supports::
  → May have more extractable concepts
```

If a scope has no findings, report that clearly and stop.

### 5. User confirmation per change

For each proposed confidence change, confirm individually:
- **Accept** — apply the change
- **Reject** — leave as-is
- **Defer** — note for later; do not modify

Only upgrades and downgrades require confirmation. Unvalidated and stale-sources flags are informational — they produce no file changes unless the user explicitly requests one.

For stale confidence findings: show the challenging atom and ask whether the confidence should be reconsidered. If the user wants a downgrade, apply it.

### 6. Apply accepted changes

For each accepted transition:
- Update `confidence:` in atom frontmatter
- Update `updated:` to today's date
- Do not modify any other fields

### 7. Log the session

Append to `_meta/log.md`:
```markdown
## [YYYY-MM-DD] trust-audit | <scope>
url:: n/a
atoms:: [[Atom A]], [[Atom B]]
skill:: memex-trust-audit
notes: N atoms evaluated; M upgraded, K downgraded, P flagged-only
```

List only atoms where `confidence:` was actually changed.

---

## What This Skill Does NOT Do

- Never silently changes `confidence:` — every transition is user-approved
- Does not evaluate factual accuracy of atom content — provenance structure only
- Does not modify source files (read-only on sources during this skill)
- Does not introduce new status or confidence values beyond the three defined in schema
- Does not reprocess sources or add new connections — that belongs to `memex-connect`

---

## Frequency

- Monthly for active topics
- After processing 5+ new sources in a topic area
- After `memex-reconcile` (graph must be consistent before evaluating confidence)
- Before running `memex-compose` (export quality depends on trustworthy confidence signals)

---

## Common Mistakes to Avoid

- Don't treat `UNVALIDATED` as a confidence problem — it's a workflow state. The atom may have been created from memory; once the sources are read and processed, run trust-audit again
- Don't downgrade atoms just because sources are old — check whether the claim is foundational (timeless) vs. empirical (may have been superseded)
- Don't audit an atom that hasn't been through `memex-reconcile` — a disconnected graph produces misleading provenance counts
- Don't flag all `confidence: medium` atoms with 1 source as overconfident — only flag `confidence: high` with < 3 and `confidence: medium` with exactly 1 source
