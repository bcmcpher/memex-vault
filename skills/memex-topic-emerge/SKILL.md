---
name: memex-topic-emerge
description: Discover emerging topic clusters from existing atoms by scanning structural signals — shared tags, `part-of::` chains, and dense `related::` links. Use when atoms have accumulated in an area without a topic map, or when you want the graph to suggest what domains are forming. Triggers on: "what topics are emerging", "discover clusters in my vault", "bottom-up topics", "find natural groupings", "what domains have I built up", "suggest topic maps from my atoms", "what can I form into a topic". For creating a topic map you already have in mind, use memex-topic-init.
---

# Karpathy Wiki Topic Emerge

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited.

This skill scans `atoms/` for structural clustering signals and proposes topic maps from the bottom up. It complements `memex-topic-init` (which is human-directed: you know the domain, you scaffold it) with graph-directed discovery: the vault tells you what's clustering, you confirm it. Run it after accumulating 10+ atoms without a covering topic, or monthly as part of graph maintenance.

---

## When to Use This Skill

- You've ingested many atoms but haven't created topic maps yet
- You want to see what domains have naturally formed in your vault
- You suspect there are orphan atoms that belong together but aren't wired
- Lint section 6 flags a concept map as broad — the clusters inside it are its candidate sub-topics

For a domain you already have in mind, use `memex-topic-init` instead — it's faster when you know what you're building.

---

## Workflow

### Step 1 — Scan clustering signals

Collect three types of signals from `atoms/`:

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"

# Tags per atom
grep -rh "^tags:" "$VAULT/atoms/"

# part-of:: targets that have no topic file (count atoms per target)
grep -rh "^part-of::" "$VAULT/atoms/" | grep -oE '\[\[[^]|#]+' | sed 's/^\[\[//' | sort | uniq -c |
  while read -r n t; do
    [ -z "$(find "$VAULT/topics" -name "$t.md" -print -quit)" ] && echo "$n $t"
  done

# related:: links
grep -rh "^related::" "$VAULT/atoms/"
```

For each atom, record: filename, title, tags, `part-of::` targets, `related::` links.

### Step 2 — Build candidate clusters

Evaluate three signal types in order. An atom can appear in multiple candidate clusters.

**Tag clusters:** atoms sharing the same tag. Threshold: ≥ 3 atoms per tag.

**Part-of chains:** atoms pointing to the same `part-of::` target **that has no topic file**. Threshold: ≥ 3 atoms pointing to the same target. A target with a topic file is not an emerging topic — it is existing coverage, which Step 3 reads. Counted as a signal, it proposes a topic's own membership back to it, and at the merge it absorbs the real clusters inside that topic: on the first real vault every atom named one concept map and one project, so the two part-of candidates held 22 and 20 of the 22 atoms.

**Related density:** if atoms A, B, C each have `related::` links to two or more of the others, they form a cluster. Threshold: ≥ 3 atoms with ≥ 2 mutual links each. **Mutual means reciprocal** — A lists B *and* B lists A. Counted in either direction, nearly every atom in a well-wired vault qualifies; on the first real vault that made the whole vault one candidate.

Merge overlapping candidates by **Jaccard similarity**, `|A ∩ B| / |A ∪ B|`: take the highest-scoring pair, and if it is ≥ 0.50 merge the two into their union; re-score the merged cluster against the rest and repeat until no pair reaches the cut. Always merge highest-first — at a tie on the cut, scanning in list order instead can chain a merge that highest-first would never make. Use the larger signal set to name it.

Do not score overlap as `|A ∩ B| / min(|A|, |B|)`. That measures *containment*: a 4-atom candidate sharing two atoms with a 9-atom one scores 0.50, and two such bridges chain a vault's real sub-domains into one blob. On the first real vault it merged ten tag candidates into a single cluster of every atom, so the skill proposed nothing (roadmap M13). Jaccard scores that pair 2/11 = 0.18. The 0.50 cut is a starting value — 0.30 gives fewer, broader clusters — so say which one you used.

If no clusters meet any threshold, skip to the report: "No clusters found — the vault may need more atoms in an area before patterns emerge. Run `memex-ingest` or `memex-connect` to add more."

### Step 3 — Check for existing topic coverage

For each candidate cluster, read which concept map each of its atoms names. Membership is derived, so read it off the atoms rather than the topic files:

```bash
grep -H "^part-of::" "$VAULT"/atoms/*.md 2>/dev/null
ls "$VAULT/topics/concepts/"
```

Count only concept maps (`topics/concepts/`). Projects and research questions sit outside the topic tree (`_meta/schema.md` § Topic Hierarchy), so a cluster that shares a project is not covered by it.

If one concept map claims ≥ 60% of a cluster's atoms, the cluster sits inside that map:

- **The cluster is a proper part of the map** → flag it as a **possible sub-topic** of that map, and show the map's name.
- **The cluster holds every atom the map has** → it is already covered. Report it and propose nothing, except **Extend** for any cluster atoms that name no concept map.

### Step 4 — Report findings

Present clusters in descending size order (most atoms first):

```
## Emerging Topics — YYYY-MM-DD

Found N candidate clusters:

### Cluster 1: [proposed title]
Atoms (N): [[atom-a]], [[atom-b]], [[atom-c]], ...
Signals: shared tags [X, Y] | M atoms in part-of:: chain | K mutual related:: links

→ Action: (1) Create new concept map  (2) Rename proposed title  (3) Skip

### Cluster 2: [proposed title]
Atoms (N): [[atom-d]], [[atom-e]], ...
Signals: shared tags [X]
Inside: [[existing-map]] claims M/N of these atoms

→ Action: (1) Sub-topic of [[existing-map]]  (2) Extend [[existing-map]] with the unclaimed atoms  (3) Skip
```

For the proposed title: infer from the dominant tag, or the most common keyword across atom titles.

### Step 5 — Collect decisions

Ask for a decision on each cluster before writing anything. Accept all decisions, then proceed to write.

Options per cluster:
- **Create** — a new concept map with no parent
- **Sub-topic** — a new concept map whose parent is the existing map; the cluster's atoms move onto it
- **Extend** — point unclaimed atoms (those naming no concept map) at an existing map
- **Skip** — no action for this cluster

### Step 6 — Write candidate files

For each confirmed **Create** or **Sub-topic**: write a create candidate to `_meta/candidates/` before creating the topic file.

Build the topic from `_templates/topic-concept.md`: its frontmatter, including `reviewed:` left empty, and **both** Dataview blocks — direct members, and members via sub-topics — copied verbatim. They are self-referential (`this.file.link`), so nothing needs substituting, and a hand-typed copy is how topic stubs drift from the template. Fill `title:` (Title Case), `description:` (one sentence naming what the cluster has in common) and `tags:` (the dominant tag), and add:

```yaml
generated:
  by: memex-topic-emerge/claude-opus-5
  at: YYYY-MM-DD
```

On the `## Sub-topics and Relations` line, `part-of::` names the parent map for a **Sub-topic** and stays empty for a **Create**.

The topic file carries no membership list. The cluster's atoms join it in Step 7, by having their own `part-of::` set — that is the only write that creates membership.

For each confirmed **Extend**: no change is proposed to the existing topic file at all. Step 7 writes the atoms.

Confirm each candidate interactively before writing the vault file.

### Step 7 — Back-wire atoms

An atom names one concept map, and it is a leaf (`_meta/schema.md` § Topic Hierarchy). For each atom in a confirmed cluster, write one modify candidate and confirm it:

| The atom's concept-map `part-of::` | Write |
|---|---|
| none | append `part-of:: [[new-map]]` (or the extended map) |
| the parent of a new **Sub-topic** | replace that link with `[[new-map]]` — the parent is now derived through the new map's own `part-of::` |
| any other concept map | nothing yet — show both maps and ask which one leaf the atom belongs on; skip it if the user is unsure |

**Never append a second concept map to an atom that already names one.** That puts the atom on two concept maps, or on a non-leaf once the new map has a parent, and lint section 7g warns on both. Links to projects and research questions are outside the tree: keep them as they are on the same line.

A replace is a modify candidate with `change: replace`, and `replaces:` holding the atom's current `part-of::` line exactly. The body is the new line:

```yaml
---
proposed: YYYY-MM-DD HH:MM
skill: memex-topic-emerge
action: modify
target: atoms/bundle-segmentation.md
section: "## Connections"
change: replace
replaces: "part-of:: [[brain-connectivity]], [[crane-method-integration]]"
session: YYYY-MM-DD-HHMM
stage: pending
---

part-of:: [[tractography-methods]], [[crane-method-integration]]
```

Do not modify atoms beyond the `part-of::` line. Do not alter other relations.

### Step 8 — Log

Append to `_meta/log.md`:
```markdown
## [YYYY-MM-DD] topic-emerge | N clusters found, M created, S sub-topics, K extended
url:: n/a
atoms:: [[atom-a]], [[atom-b]], ...
skill:: memex-topic-emerge
notes: signals: <tag clusters / part-of chains / related density>; cut <0.50|0.30>; <M> new topics, <S> sub-topics, <K> extensions, <skip count> skipped
```

### Step 9 — Confirm and close

Report: clusters found, topics created, sub-topics created, topics extended, clusters skipped. Suggested next steps:

- "Run `_meta/lint.sh`: section 7 should report no new topic-tree findings, and a map you split should no longer be flagged broad in section 6."
- "If section 7a reports a dangling `part-of::`, run `memex-reconcile`."

---

## What This Skill Does NOT Do

- Does not create atoms — only discovers clusters from existing atoms
- Does not infer cluster membership from semantic content — only from structural signals (`tags:`, `part-of::`, `related::`)
- Does not decide topic type (concept vs. research vs. project) — defaults to `concept`; rename manually if needed
- Does not modify atoms beyond each atom's `part-of::` line
- Does not scan `sources/` or `glossary/`; reads `topics/` only to learn which `part-of::` targets exist and which are concept maps
- Does not run `memex-reconcile` inline — suggests it as a follow-up

---

## Common Mistakes to Avoid

- Don't propose a cluster of fewer than 3 atoms — the signal is too weak
- Don't create duplicate topic maps — always check for existing coverage first (Step 3)
- Don't count a `part-of::` target that already has a topic file as an emerging cluster
- Don't append a concept map to an atom that already names one — replace it (Sub-topic) or ask (Step 7)
- Don't batch-apply candidates without user confirmation per cluster
- Don't infer topic type from keywords alone — default to `concept` and let the user correct it
- Don't write a membership list into a topic body, and don't modify an existing topic body at all — Extend and Sub-topic are edits to atoms (plus, for Sub-topic, one new topic file)
