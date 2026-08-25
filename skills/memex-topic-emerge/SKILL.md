---
name: memex-topic-emerge
description: Discover emerging topic clusters from existing atoms by scanning structural signals — shared tags, `part-of::` chains, and dense `related::` links. Use when atoms have accumulated in an area without a topic map, or when you want the graph to suggest what domains are forming. Triggers on: "what topics are emerging", "discover clusters in my vault", "bottom-up topics", "find natural groupings", "what domains have I built up", "suggest topic maps from my atoms", "what can I form into a topic". For creating a topic map you already have in mind, use memex-topic-init.
---

# Karpathy Wiki Topic Emerge

**Vault root:** `/home/bcmcpher/Projects/claude/memex-vault`

This skill scans `atoms/` for structural clustering signals and proposes topic maps from the bottom up. It complements `memex-topic-init` (which is human-directed: you know the domain, you scaffold it) with graph-directed discovery: the vault tells you what's clustering, you confirm it. Run it after accumulating 10+ atoms without a covering topic, or monthly as part of graph maintenance.

---

## When to Use This Skill

- You've ingested many atoms but haven't created topic maps yet
- You want to see what domains have naturally formed in your vault
- You suspect there are orphan atoms that belong together but aren't wired

For a domain you already have in mind, use `memex-topic-init` instead — it's faster when you know what you're building.

---

## Workflow

### Step 1 — Scan clustering signals

Collect three types of signals from `atoms/`:

```bash
VAULT=/home/bcmcpher/Projects/claude/memex-vault

# Tags per atom
grep -rh "^tags:" "$VAULT/atoms/"

# part-of:: targets (count occurrences of each target)
grep -rh "^part-of::" "$VAULT/atoms/" | grep -oP '\[\[.*?\]\]' | sort | uniq -c | sort -rn

# related:: links
grep -rh "^related::" "$VAULT/atoms/"
```

For each atom, record: filename, title, tags, `part-of::` targets, `related::` links.

### Step 2 — Build candidate clusters

Evaluate three signal types in order. An atom can appear in multiple candidate clusters.

**Tag clusters:** atoms sharing the same tag. Threshold: ≥ 3 atoms per tag.

**Part-of chains:** atoms pointing to the same `part-of::` target. Threshold: ≥ 3 atoms pointing to the same target (even if that target doesn't exist as an atom yet).

**Related density:** if atoms A, B, C each have `related::` links to two or more of the others, they form a cluster. Threshold: ≥ 3 atoms with ≥ 2 mutual links each.

Merge overlapping candidates: if two candidates share ≥ 50% of their atoms, merge them into one (use the union). Use the larger signal set to name it.

If no clusters meet any threshold, skip to the report: "No clusters found — the vault may need more atoms in an area before patterns emerge. Run `memex-ingest` or `memex-connect` to add more."

### Step 3 — Check for existing topic coverage

For each candidate cluster, check whether an existing topic already claims most of
its atoms. Membership is derived, so read it off the atoms themselves rather than
off the topic files:

```bash
grep -rh "^part-of::" "$VAULT/atoms/" 2>/dev/null
```

Tally which topic each cluster atom declares. If one existing topic already claims
≥ 60% of a cluster's atoms, flag it as **"possible extension"** rather than a new
topic creation. Show the existing topic name.

### Step 4 — Report findings

Present clusters in descending size order (most atoms first):

```
## Emerging Topics — YYYY-MM-DD

Found N candidate clusters:

### Cluster 1: [proposed title]
Atoms (N): [[atom-a]], [[atom-b]], [[atom-c]], ...
Signals: shared tags [X, Y] | M atoms in part-of:: chain | K mutual related:: links

→ Action: (1) Create new topic map  (2) Rename proposed title  (3) Skip

### Cluster 2: [proposed title]
Atoms (N): [[atom-d]], [[atom-e]], ...
Signals: shared tags [X]
Existing topic: [[existing-topic]] already claims M/N of these atoms

→ Action: (1) Extend existing topic  (2) Create separate topic  (3) Skip
```

For the proposed title: infer from the dominant tag, or the most common keyword across atom titles.

### Step 5 — Collect decisions

Ask for a decision on each cluster before writing anything. Accept all decisions, then proceed to write.

Options per cluster:
- **Create** — create a new topic map with the proposed title (or a renamed one)
- **Extend** — point the unclaimed atoms' `part-of::` at an existing topic
- **Skip** — no action for this cluster

### Step 6 — Write candidate files

For each confirmed **Create**: write a candidate file to `_meta/candidates/` before creating the topic file.

Topic file frontmatter:
```yaml
---
title: <confirmed title, Title Case>
topic-type: concept
created: YYYY-MM-DD
tags: [<dominant tag from cluster>]
---
```

Topic file body:
````markdown
## Overview
<!-- Scaffold — fill in with memex-compose or manually -->

## Core Concepts
<!-- Derived from each atom's part-of:: — do not maintain by hand. -->
```dataview
LIST FROM "atoms"
WHERE contains(row["part-of"], this.file.link)
```
````

The topic file carries no membership list. The cluster's atoms join it in Step 7,
by having their own `part-of::` set — that is the only write that creates
membership.

For each confirmed **Extend**: write candidate files proposing `part-of::` on each
unclaimed atom. No change is proposed to the existing topic file at all.

Confirm each candidate interactively before writing the vault file.

### Step 7 — Back-wire atoms

For each newly created or extended topic, add `part-of:: [[topic-name]]` to the `## Connections` section of any covered atom that doesn't already have a `part-of::` entry pointing to this topic.

Write a candidate file for each atom modification before writing. Confirm interactively.

Do not modify atom bodies beyond the `part-of::` append. Do not alter existing relations.

### Step 8 — Log

Append to `_meta/log.md`:
```markdown
## [YYYY-MM-DD] topic-emerge | N clusters found, M created, K extended
url:: n/a
atoms:: [[atom-a]], [[atom-b]], ...
skill:: memex-topic-emerge
notes: signals: <tag clusters / part-of chains / related density>; <M> new topics, <K> extensions, <skip count> skipped
```

### Step 9 — Confirm and close

Report: clusters found, topics created, topics extended, clusters skipped. One suggested next step:

- "Run `memex-reconcile` to check for dangling `part-of::` links across newly created topics."

---

## What This Skill Does NOT Do

- Does not create atoms — only discovers clusters from existing atoms
- Does not infer cluster membership from semantic content — only from structural signals (`tags:`, `part-of::`, `related::`)
- Does not decide topic type (concept vs. research vs. project) — defaults to `concept`; rename manually if needed
- Does not modify atom bodies beyond appending `part-of::` to `## Connections`
- Does not scan `sources/`, `topics/`, or `glossary/` — only `atoms/`
- Does not run `memex-reconcile` inline — suggests it as a follow-up

---

## Common Mistakes to Avoid

- Don't propose a cluster of fewer than 3 atoms — the signal is too weak
- Don't create duplicate topic maps — always check for existing coverage first (Step 3)
- Don't batch-apply candidates without user confirmation per cluster
- Don't infer topic type from keywords alone — default to `concept` and let the user correct it
- Don't write a membership list into a topic body, and don't modify an existing topic body at all on the Extend path — extension is an edit to atoms, not to topics
